# Tests d'intégration sur le téléphone (aux JALONS seulement, jamais en CI : pas de téléphone dans
# GitHub Actions). Ils complètent le regard de Loick sur le téléphone, ils ne le remplacent pas.
#
# Usage (depuis frontend/mobile, Docker lancé, téléphone connecté en adb) :
#   .\tool\integration.ps1 -Device 192.168.1.71:46735
#   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/glass_perf_test.dart `
#       -Driver test_driver/perf_driver.dart
#
# 1. refuse si une API tourne déjà sur le port 8000 (les tests lancent la leur) ;
# 2. prépare la base DÉDIÉE `elecpay_e2e` (docker/mysql/init/02-e2e-database.sql), la remet à zéro et
#    la remplit (reset_db + seed) : la base de démo `elecpay` n'est JAMAIS touchée par ces tests ;
# 3. lance l'API sur cette base, avec des jetons d'accès d'UNE minute (session expirée) ;
# 4. ouvre le tunnel (tool/telephone.ps1) et joue les tests en profile (flutter drive) ;
# 5. arrête l'API de test, même en cas d'échec. Captures et journaux : build/integration/ (jamais
#    commités : /build/ est ignoré par git).
param(
    [Parameter(Mandatory = $true)][string]$Device,
    [string]$Target = 'integration_test/auth_flows_test.dart',
    [string]$Driver = 'test_driver/integration_driver.dart',
    [string]$DatabaseUrl = 'mysql+pymysql://elecpay:elecpay@127.0.0.1:3307/elecpay_e2e?charset=utf8mb4'
)
$ErrorActionPreference = 'Stop'

$mobile = Split-Path $PSScriptRoot -Parent
$repo = Split-Path (Split-Path $mobile -Parent) -Parent
$backend = Join-Path $repo 'backend'
$python = Join-Path $backend '.venv\Scripts\python.exe'
$uvicorn = Join-Path $backend '.venv\Scripts\uvicorn.exe'
$e2eSql = Join-Path $repo 'docker\mysql\init\02-e2e-database.sql'
$out = Join-Path $mobile 'build\integration'
$health = 'http://127.0.0.1:8000/api/v1/health'

# Garde-fou : jamais la base de démo (ni une autre) remise à zéro par erreur de paramètre.
if ($DatabaseUrl -notmatch '/elecpay_e2e(\?|$)') {
    Write-Host "Refusé : les tests d'intégration tournent uniquement sur la base elecpay_e2e ($DatabaseUrl)."
    exit 1
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
# Variables réservées à ce script et aux processus qu'il lance (reset_db, seed, API de test).
$env:DATABASE_URL = $DatabaseUrl
$env:ACCESS_TOKEN_MINUTES = '1'
$api = $null
$code = 1
try {
    Write-Host '== Base elecpay_e2e : création si besoin, remise à zéro, données de démo'
    $ErrorActionPreference = 'Continue' # mysql écrit un avertissement sur stderr (mot de passe)
    Get-Content -Raw $e2eSql | docker exec -i elecpay-mysql mysql -uroot -proot 2>$null
    $created = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($created -ne 0) { throw 'Impossible de préparer elecpay_e2e (Docker et elecpay-mysql lancés ?).' }
    Push-Location $backend
    try {
        & $python -m scripts.reset_db
        if ($LASTEXITCODE -ne 0) { throw 'reset_db a échoué.' }
        & $python -m scripts.seed | Select-Object -Last 2
        if ($LASTEXITCODE -ne 0) { throw 'seed a échoué.' }
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
