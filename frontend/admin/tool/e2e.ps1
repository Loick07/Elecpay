# Tests de bout en bout du back-office (Playwright ; PLAN.md « Tests », décision DA0.9).
#
# Usage (depuis frontend/admin, Docker lancé) :
#   .\tool\e2e.ps1                 tous les parcours (le back-office est reconstruit)
#   .\tool\e2e.ps1 -SkipBuild      sans reconstruire (.next déjà à jour avec le code)
#   .\tool\e2e.ps1 -Grep session   seulement les parcours dont le nom contient « session »
#
# 1. refuse si quelque chose écoute déjà sur le port 8010 (API de test) ou 3010 (back-office) :
#    le script lance SES deux serveurs et les arrête à la fin ;
# 2. SUPPRIME puis RECRÉE la base DÉDIÉE elecpay_admin_e2e (nom écrit en dur : aucun paramètre ne
#    peut viser une autre base ; jamais elecpay, elecpay_public, elecpay_e2e ni elecpay_admin_dev),
#    migrations, données de démo ;
# 3. API de test sur le port 8010, jetons d'accès d'UNE minute (session expirée) ;
# 4. back-office construit (npm run build) puis lancé (next start, port 3010) vers cette API ;
# 5. Playwright (Edge du PC) ; captures, traces, rapport et journaux : build/e2e/ (ignoré par git) ;
# 6. arrête toujours les deux serveurs. NE JAMAIS interrompre un passage pendant la préparation
#    de la base.
param([switch]$SkipBuild, [string]$Grep)
$ErrorActionPreference = 'Stop'

$database = 'elecpay_admin_e2e'
$apiPort = 8010
$sitePort = 3010

$admin = Split-Path $PSScriptRoot -Parent
$repo = Split-Path (Split-Path $admin -Parent) -Parent
$backend = Join-Path $repo 'backend'
$python = Join-Path $backend '.venv\Scripts\python.exe'
$uvicorn = Join-Path $backend '.venv\Scripts\uvicorn.exe'
$out = Join-Path $admin 'build\e2e'

function Test-Listening([int]$port) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try { return $client.ConnectAsync('127.0.0.1', $port).Wait(1000) }
    catch { return $false }
    finally { $client.Dispose() }
}

function Wait-Http([string]$url, [string]$what, [string]$log) {
    for ($i = 0; $i -lt 60; $i++) {
        try {
            Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 | Out-Null
            return
        } catch { Start-Sleep -Seconds 1 }
    }
    throw "$what injoignable (voir $log)."
}

# 1. Ports libres : jamais un serveur déjà lancé, qui viserait peut-être une autre base.
foreach ($port in @($apiPort, $sitePort)) {
    if (Test-Listening $port) {
        Write-Host "Refusé : le port $port est déjà utilisé. Ce script lance ses propres serveurs"
        Write-Host "(API de test sur $apiPort, back-office sur $sitePort) : arrêter l'autre d'abord."
        exit 1
    }
}

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force (Join-Path $out 'captures') | Out-Null

# Variables réservées à ce passage et aux processus qu'il lance.
$env:DATABASE_URL = "mysql+pymysql://elecpay:elecpay@127.0.0.1:3307/$database" + '?charset=utf8mb4'
$env:ACCESS_TOKEN_MINUTES = '1'
$env:ELECPAY_API_URL = "http://127.0.0.1:$apiPort"
$env:ELECPAY_E2E_DATABASE = $database
# Écran d'essai des composants (A2.3) : seulement pendant les parcours, jamais en ligne.
$env:ELECPAY_ESSAI = '1'
$env:NEXT_TELEMETRY_DISABLED = '1'
$api = $null
$site = $null
$code = 1
try {
    # 2. Base SUPPRIMÉE puis RECRÉÉE entière (un passage interrompu ne laisse jamais une base à
    # moitié remise à zéro).
    Write-Host "== Base $database : supprimée, recréée, migrations, données de démo"
    $recreate = @"
DROP DATABASE IF EXISTS $database;
CREATE DATABASE $database CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON $database.* TO 'elecpay'@'%';
FLUSH PRIVILEGES;
"@
    $ErrorActionPreference = 'Continue' # mysql écrit un avertissement sur stderr (mot de passe)
    $recreate | docker exec -i elecpay-mysql mysql -uroot -proot 2>$null
    $created = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($created -ne 0) { throw "Impossible de recréer $database (Docker et elecpay-mysql lancés ?)." }
    Push-Location $backend
    try {
        # Erreurs Python affichées EN ENTIER ; le code de sortie décide.
        $ErrorActionPreference = 'Continue'
        & $python -m alembic upgrade head 2>&1 | ForEach-Object { "$_" }
        $migrated = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($migrated -ne 0) { throw 'Migrations (alembic upgrade head) en échec (trace ci-dessus).' }
        $ErrorActionPreference = 'Continue'
        & $python -m scripts.seed 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 5
        $seeded = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($seeded -ne 0) { throw 'seed a échoué (trace ci-dessus).' }
    } finally { Pop-Location }

    # 3. API de test
    $api = Start-Process -FilePath $uvicorn -NoNewWindow -PassThru `
        -ArgumentList 'app.main:app', '--host', '127.0.0.1', '--port', "$apiPort" `
        -WorkingDirectory $backend `
        -RedirectStandardOutput (Join-Path $out 'api-sortie.log') `
        -RedirectStandardError (Join-Path $out 'api.log')
    Wait-Http "http://127.0.0.1:$apiPort/api/v1/health" 'API de test' (Join-Path $out 'api.log')
    Write-Host "== API de test prête (port $apiPort, base $database, jetons d'une minute)"

    # 4. Back-office construit puis lancé (serveur de production : CSP stricte, comme en ligne)
    Push-Location $admin
    try {
        if (-not $SkipBuild) {
            Write-Host '== Construction du back-office (npm run build)'
            $ErrorActionPreference = 'Continue'
            npm run build 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 8
            $built = $LASTEXITCODE
            $ErrorActionPreference = 'Stop'
            if ($built -ne 0) { throw 'Construction du back-office en échec (trace ci-dessus).' }
        }
        $node = (Get-Command node).Source
        $site = Start-Process -FilePath $node -NoNewWindow -PassThru `
            -ArgumentList 'node_modules/next/dist/bin/next', 'start', '--hostname', '127.0.0.1', '--port', "$sitePort" `
            -WorkingDirectory $admin `
            -RedirectStandardOutput (Join-Path $out 'site.log') `
            -RedirectStandardError (Join-Path $out 'site-erreurs.log')
        Wait-Http "http://127.0.0.1:$sitePort/connexion" 'Back-office' (Join-Path $out 'site-erreurs.log')
        Write-Host "== Back-office prêt (port $sitePort, relié à l'API de test)"

        # 5. Parcours
        $arguments = @('playwright', 'test')
        if ($Grep) { $arguments += @('--grep', $Grep) }
        $ErrorActionPreference = 'Continue'
        & npx @arguments
        $code = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
    } finally { Pop-Location }
} finally {
    # 6. Toujours arrêter les deux serveurs et effacer les variables du passage
    foreach ($process in @($site, $api)) {
        if ($process) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($api -or $site) { Write-Host '== Serveurs de test arrêtés' }
    Remove-Item Env:DATABASE_URL, Env:ACCESS_TOKEN_MINUTES, Env:ELECPAY_API_URL, `
        Env:ELECPAY_E2E_DATABASE, Env:ELECPAY_ESSAI, Env:NEXT_TELEMETRY_DISABLED `
        -ErrorAction SilentlyContinue
}

if ($code -eq 0) { Write-Host "== Parcours réussis. Captures et rapport : $out" }
else { Write-Host "== ÉCHEC des parcours (code $code). Traces, rapport et journaux : $out" }
exit $code
