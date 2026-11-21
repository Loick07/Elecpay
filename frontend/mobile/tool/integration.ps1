# Tests d'intégration sur le téléphone (aux JALONS seulement, jamais en CI : pas de téléphone dans
# GitHub Actions). Ils complètent le regard de Loick sur le téléphone, ils ne le remplacent pas.
#
# Usage (depuis frontend/mobile, Docker lancé, téléphone connecté en adb) :
#   .\tool\integration.ps1 -Device 192.168.1.71:46735
#   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/glass_perf_test.dart `
#       -Driver test_driver/perf_driver.dart
#
# 1. refuse si une API tourne déjà sur le port 8000 (les tests lancent la leur) ;
# 2. SUPPRIME puis RECRÉE la base DÉDIÉE `elecpay_e2e` (DROP / CREATE DATABASE, nom écrit en dur),
#    puis migrations (alembic upgrade head) et seed : la base de démo `elecpay` n'est JAMAIS touchée ;
# 3. lance l'API sur cette base, avec des jetons d'accès d'UNE minute (session expirée) ;
# 4. ouvre le tunnel (tool/telephone.ps1) et joue les tests en profile (flutter drive) ;
# 5. arrête l'API de test, même en cas d'échec. Captures et journaux : build/integration/ (jamais
#    commités : /build/ est ignoré par git).
param(
    [Parameter(Mandatory = $true)][string]$Device,
    [string]$Target = 'integration_test/auth_flows_test.dart',
    [string]$Driver = 'test_driver/integration_driver.dart',
    [string]$DatabaseUrl = 'mysql+pymysql://elecpay:elecpay@127.0.0.1:3307/elecpay_e2e?charset=utf8mb4',
    # Vérifie seulement le garde-fou de la base, puis s'arrête (test/tool/integration_guard_test.dart).
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'

# Seule base que ce script supprime et recrée. Écrite EN DUR : jamais tirée de -DatabaseUrl.
$e2eDatabase = 'elecpay_e2e'

$mobile = Split-Path $PSScriptRoot -Parent
$repo = Split-Path (Split-Path $mobile -Parent) -Parent
$backend = Join-Path $repo 'backend'
$python = Join-Path $backend '.venv\Scripts\python.exe'
$uvicorn = Join-Path $backend '.venv\Scripts\uvicorn.exe'
$out = Join-Path $mobile 'build\integration'
$health = 'http://127.0.0.1:8000/api/v1/health'

# Garde-fou : jamais la base de démo (ni une autre) touchée par erreur de paramètre. Le NOM de la
# base est lu strictement (juste après l'hôte, avant « ? ») : « …/elecpay?x=/elecpay_e2e » vise
# `elecpay` et est refusé (l'ancienne règle l'acceptait). Hôte : ce PC seulement.
$parsed = [regex]::Match($DatabaseUrl, '^mysql\+pymysql://[^/@]+@(127\.0\.0\.1|localhost):\d+/([^/?#]+)(\?[^/#]*)?$')
if (-not $parsed.Success -or $parsed.Groups[2].Value -cne $e2eDatabase) {
    Write-Host "Refusé : les tests d'intégration tournent uniquement sur la base $e2eDatabase de ce PC ($DatabaseUrl)."
    exit 1
}
if ($CheckOnly) {
    Write-Host "Garde-fou : base $e2eDatabase acceptée."
    exit 0
}

# 1. Port 8000 libre
$running = $true
try { Invoke-RestMethod -Uri $health -TimeoutSec 3 | Out-Null } catch { $running = $false }
if ($running) {
    Write-Host 'Une API tourne déjà sur le port 8000 : l''arrêter d''abord (les tests lancent la leur,'
    Write-Host 'sur la base elecpay_e2e, avec des jetons d''une minute, et l''arrêtent à la fin).'
    exit 1
}

# 2. Base dédiée : créée si besoin (même fichier qu'à la création du volume MySQL), vidée, remplie.
# Variables réservées à ce script et aux processus qu'il lance (migrations, seed, API de test).
$env:DATABASE_URL = $DatabaseUrl
$env:ACCESS_TOKEN_MINUTES = '1'
$api = $null
$code = 1
try {
    # Base SUPPRIMÉE puis RECRÉÉE entière à chaque passage (décision de Loick, jalon F10) : un
    # passage interrompu ne peut plus laisser une base à moitié remise à zéro (vu le 21/11/2026).
    Write-Host "== Base $($e2eDatabase) : supprimée, recréée, migrations, données de démo"
    $recreate = @"
DROP DATABASE IF EXISTS $e2eDatabase;
CREATE DATABASE $e2eDatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON $e2eDatabase.* TO 'elecpay'@'%';
FLUSH PRIVILEGES;
"@
    $ErrorActionPreference = 'Continue' # mysql écrit un avertissement sur stderr (mot de passe)
    $recreate | docker exec -i elecpay-mysql mysql -uroot -proot 2>$null
    $created = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($created -ne 0) { throw "Impossible de recréer $e2eDatabase (Docker et elecpay-mysql lancés ?)." }
    Push-Location $backend
    try {
        # Erreurs Python affichées EN ENTIER (avec 'Stop', PowerShell ne gardait que la première
        # ligne de la trace : vu au jalon F10). Le code de sortie décide.
        $ErrorActionPreference = 'Continue'
        & $python -m alembic upgrade head 2>&1 | ForEach-Object { "$_" }
        $migrateCode = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($migrateCode -ne 0) { throw 'Migrations (alembic upgrade head) en échec (trace ci-dessus).' }
        $ErrorActionPreference = 'Continue'
        & $python -m scripts.seed 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 15
        $seedCode = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($seedCode -ne 0) { throw 'seed a échoué (trace ci-dessus).' }
    } finally { Pop-Location }

    # 3. API de test (base elecpay_e2e, jetons d'une minute)
    if (Test-Path $out) { Remove-Item -Recurse -Force $out }
    New-Item -ItemType Directory -Force $out | Out-Null
    $api = Start-Process -FilePath $uvicorn -NoNewWindow -PassThru `
        -ArgumentList 'app.main:app', '--host', '127.0.0.1', '--port', '8000' `
        -WorkingDirectory $backend `
        -RedirectStandardOutput (Join-Path $out 'api-sortie.log') `
        -RedirectStandardError (Join-Path $out 'api.log')
    $ready = $false
    for ($i = 0; $i -lt 30 -and -not $ready; $i++) {
        try { Invoke-RestMethod -Uri $health -TimeoutSec 2 | Out-Null; $ready = $true }
        catch { Start-Sleep -Seconds 1 }
    }
    if (-not $ready) { throw "API de test injoignable (voir $out\api.log)." }
    Write-Host '== API de test prête (base elecpay_e2e, jetons d''une minute)'

    # 4. Tunnel puis tests
    & (Join-Path $PSScriptRoot 'telephone.ps1') -Device $Device
    if ($LASTEXITCODE -ne 0) { throw 'Téléphone non prêt (tool/telephone.ps1).' }
    Push-Location $mobile
    # PowerShell 5.1 : avec « Stop », la moindre ligne que flutter écrit sur stderr devient une erreur
    # fatale. Le résultat se lit dans le code de sortie.
    $ErrorActionPreference = 'Continue'
    try {
        flutter drive --profile --driver=$Driver --target=$Target -d $Device
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = 'Stop'
        Pop-Location
    }
} finally {
    # 5. Toujours arrêter l'API de test et effacer les variables du passage
    if ($api) {
        Stop-Process -Id $api.Id -Force -ErrorAction SilentlyContinue
        Write-Host '== API de test arrêtée'
    }
    Remove-Item Env:DATABASE_URL, Env:ACCESS_TOKEN_MINUTES -ErrorAction SilentlyContinue
}

if ($code -eq 0) { Write-Host "== Tests réussis. Captures : $out" }
else { Write-Host "== ÉCHEC des tests (code $code). Captures et journaux : $out" }
exit $code
