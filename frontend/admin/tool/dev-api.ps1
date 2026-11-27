# API de DÉVELOPPEMENT du back-office (décision de Loick du 27/11/2026, avant A1) : en
# développement, le back-office ne vise JAMAIS l'API publique (port 8000, base elecpay_public).
#
# Usage (depuis frontend/admin, Docker lancé) :
#   .\tool\dev-api.ps1           base créée et remplie (données de démo) la première fois, puis gardée
#   .\tool\dev-api.ps1 -Reset    base SUPPRIMÉE puis recréée (données de démo neuves)
# L'API reste au premier plan (arrêt : Ctrl+C). Dans un autre terminal : npm run dev
# (frontend/admin/.env.local : ELECPAY_API_URL=http://127.0.0.1:8001, modèle env.local.example).
#
# Base et port ÉCRITS EN DUR (aucun paramètre ne peut viser une autre base ni le port 8000) :
# jamais `elecpay` (démo du mobile), `elecpay_public` (API publique), `elecpay_test` ni les bases
# des tests de bout en bout.
param([switch]$Reset)
$ErrorActionPreference = 'Stop'

$database = 'elecpay_admin_dev'
$port = 8001

$admin = Split-Path $PSScriptRoot -Parent
$repo = Split-Path (Split-Path $admin -Parent) -Parent
$backend = Join-Path $repo 'backend'
$python = Join-Path $backend '.venv\Scripts\python.exe'
$uvicorn = Join-Path $backend '.venv\Scripts\uvicorn.exe'
$health = "http://127.0.0.1:$port/api/v1/health"

# 1. Déjà lancée ?
$running = $true
try { Invoke-RestMethod -Uri $health -TimeoutSec 3 | Out-Null } catch { $running = $false }
if ($running) {
    Write-Host "Une API répond déjà sur le port $port (l'API de développement) : rien à faire."
    exit 0
}

# 2. Base dédiée : créée si elle n'existe pas (ou recréée avec -Reset), puis migrations.
$ErrorActionPreference = 'Continue' # mysql écrit un avertissement sur stderr (mot de passe)
$existing = "SHOW DATABASES LIKE '$database';" | docker exec -i elecpay-mysql mysql -uroot -proot -N 2>$null
$found = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($found -ne 0) { throw 'MySQL injoignable : lancer Docker puis « docker compose up -d ».' }
$fresh = $Reset -or -not $existing
$sql = @"
$(if ($Reset) { "DROP DATABASE IF EXISTS $database;" })
CREATE DATABASE IF NOT EXISTS $database CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON $database.* TO 'elecpay'@'%';
FLUSH PRIVILEGES;
"@
$ErrorActionPreference = 'Continue'
$sql | docker exec -i elecpay-mysql mysql -uroot -proot 2>$null
$created = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($created -ne 0) { throw "Impossible de préparer la base $database." }

$env:DATABASE_URL = "mysql+pymysql://elecpay:elecpay@127.0.0.1:3307/$database" + '?charset=utf8mb4'
Push-Location $backend
try {
    $ErrorActionPreference = 'Continue'
    & $python -m alembic upgrade head 2>&1 | ForEach-Object { "$_" }
    $migrated = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($migrated -ne 0) { throw 'Migrations (alembic upgrade head) en échec (trace ci-dessus).' }
    if ($fresh) {
        Write-Host "== Base $database neuve : données de démo (comptes fictifs, mot de passe Demo2026!)"
        $ErrorActionPreference = 'Continue'
        & $python -m scripts.seed 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 15
        $seeded = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($seeded -ne 0) { throw 'seed a échoué (trace ci-dessus).' }
    }
    # 3. API au premier plan (Ctrl+C pour l'arrêter).
    Write-Host "== API de développement : http://127.0.0.1:$port (base $database). Arrêt : Ctrl+C."
    & $uvicorn app.main:app --host 127.0.0.1 --port $port
} finally {
    Pop-Location
    Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue
}
