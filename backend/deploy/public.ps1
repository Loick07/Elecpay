# API ElecPay de démonstration exposée par ngrok, sur CE PC (étape M1). Guide pas à pas :
# docs/DEPLOIEMENT.md, section 7. Depuis backend/ :
#   .\deploy\public.ps1 -Step preparer     # une fois : base dédiée + secrets tirés au hasard
#   .\deploy\public.ps1 -Step config       # vérifie la configuration (rien n'est modifié)
#   .\deploy\public.ps1 -Step migrer       # schéma de la base (avant chaque nouvelle version)
#   .\deploy\public.ps1 -Step seed         # une fois : comptes de démo (mot de passe secret)
#   .\deploy\public.ps1 -Step api          # l'API sur 127.0.0.1:8000 (fenêtre à laisser ouverte)
#   .\deploy\public.ps1 -Step taches       # tâches planifiées (fenêtre à laisser ouverte)
#   .\deploy\public.ps1 -Step sauvegarde   # copie de la base (14 gardées)
#   .\deploy\public.ps1 -Step restaurer -Fichier deploy\sauvegardes\<fichier>.sql
#   .\deploy\public.ps1 -Step verifier     # santé de l'API, en local puis par ngrok
#
# Sécurité :
# - une seule base touchée, `elecpay_public` (nom écrit EN DUR), avec son propre utilisateur
#   MySQL ; jamais `elecpay`, `elecpay_test` ni `elecpay_e2e` ; jamais `reset_db` ;
# - secrets tirés au hasard SUR CE PC, écrits dans deploy\ngrok.env (ignoré par git), JAMAIS affichés ;
# - l'API n'écoute que 127.0.0.1 : seul ngrok (lancé à part, par Loick) l'expose.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('preparer', 'config', 'migrer', 'seed', 'api', 'taches', 'sauvegarde', 'restaurer', 'verifier')]
    [string]$Step,
    # Fichier de configuration (par défaut deploy\ngrok.env ; autre chemin : tests du garde-fou).
    [string]$EnvFile,
    # Pour -Step restaurer : la sauvegarde à remettre en place.
    [string]$Fichier
)
$ErrorActionPreference = 'Stop'

$deploy = $PSScriptRoot
$backend = Split-Path $deploy -Parent
if (-not $EnvFile) { $EnvFile = Join-Path $deploy 'ngrok.env' }
$example = Join-Path $deploy 'ngrok.env.example'
$backups = Join-Path $deploy 'sauvegardes'
$publicDatabase = 'elecpay_public'   # EN DUR : la seule base que ce script touche
$publicUser = 'elecpay_public'
$domain = 'https://omnivore-pardon-sixth.ngrok-free.dev'
$container = 'elecpay-mysql'

# Python de l'environnement du projet (Windows : .venv\Scripts ; Linux, en CI : .venv/bin ou python).
$python = @(
    (Join-Path $backend '.venv\Scripts\python.exe'),
    (Join-Path $backend '.venv/bin/python')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $python) { $python = 'python' }

function Read-EnvFile([string]$path) {
    if (-not (Test-Path $path)) {
        throw "Refusé : $path introuvable. Lancer d'abord : .\deploy\public.ps1 -Step preparer"
    }
    $values = @{}
    foreach ($line in Get-Content -Encoding UTF8 $path) {
        $text = $line.Trim()
        if (-not $text -or $text.StartsWith('#')) { continue }
        $at = $text.IndexOf('=')
        if ($at -lt 1) { continue }
        $values[$text.Substring(0, $at).Trim()] = $text.Substring($at + 1).Trim()
    }
    return $values
}

# Garde-fou : configuration de PRODUCTION, base `elecpay_public` de CE PC, secrets présents.
function Assert-PublicConfig([hashtable]$values) {
    if ($values['APP_ENV'] -cne 'production') {
        throw 'Refusé : APP_ENV doit valoir production (garde-fous de sécurité imposés).'
    }
    if ($values['DEMO_MODE'] -cne 'true') {
        throw 'Refusé : DEMO_MODE doit valoir true (données simulées).'
    }
    $url = [string]$values['DATABASE_URL']
    $pattern = '^mysql\+pymysql://' + $publicUser + ':[^@/]+@(127\.0\.0\.1|localhost):\d+/' +
        $publicDatabase + '(\?[^/#]*)?$'
    if ($url -cnotmatch $pattern) {
        throw "Refusé : DATABASE_URL doit viser la base $publicDatabase de ce PC, avec l'utilisateur $publicUser."
    }
    foreach ($key in 'JWT_SECRET', 'TWO_FACTOR_KEY', 'PAYMENT_WEBHOOK_SECRET', 'DEMO_SEED_PASSWORD') {
        if (-not $values[$key]) { throw "Refusé : $key est vide dans $EnvFile." }
    }
}

# Charge la configuration dans les variables de CE processus (et des commandes qu'il lance).
function Use-PublicConfig {
    $values = Read-EnvFile $EnvFile
    Assert-PublicConfig $values
    foreach ($key in $values.Keys) { Set-Item -Path "env:$key" -Value $values[$key] }
    return $values
}

function Invoke-Backend([string[]]$arguments) {
    Push-Location $backend
    try {
        # alembic et les commandes écrivent aussi sur stderr (informations) : avec 'Stop',
        # Windows PowerShell 5.1 en ferait une erreur. Le code de sortie décide.
        $ErrorActionPreference = 'Continue'
        & $python @arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($code -ne 0) { throw "Échec : python $($arguments -join ' ') (code $code)." }
    } finally { Pop-Location }
}

function New-Secret {
    $value = & $python -c 'import secrets; print(secrets.token_urlsafe(48))'
    if ($LASTEXITCODE -ne 0 -or -not $value) { throw 'Impossible de tirer un secret (python).' }
    return $value.Trim()
}

function Invoke-MySqlRoot([string]$sql) {
    $ErrorActionPreference = 'Continue' # mysql avertit sur stderr (mot de passe en ligne de commande)
    $sql | docker exec -i $container mysql -uroot -proot 2>$null
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($code -ne 0) { throw "MySQL a refusé la commande (Docker et $container lancés ?)." }
}

switch ($Step) {
    'preparer' {
        if (Test-Path $EnvFile) {
            throw "Refusé : $EnvFile existe déjà (secrets en place). Rien n'est modifié."
        }
        $dbPassword = New-Secret
        Invoke-MySqlRoot @"
CREATE DATABASE IF NOT EXISTS $publicDatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS '$publicUser'@'%' IDENTIFIED BY '$dbPassword';
ALTER USER '$publicUser'@'%' IDENTIFIED BY '$dbPassword';
GRANT ALL PRIVILEGES ON $publicDatabase.* TO '$publicUser'@'%';
FLUSH PRIVILEGES;
"@
        $seedPassword = & $python -c "import secrets; print('ElecPay-' + secrets.token_urlsafe(12) + '-' + str(secrets.randbelow(90) + 10))"
        $filled = @{
            'DATABASE_URL'           = "mysql+pymysql://${publicUser}:$dbPassword@127.0.0.1:3307/${publicDatabase}?charset=utf8mb4"
            'JWT_SECRET'             = New-Secret
            'TWO_FACTOR_KEY'         = New-Secret
            'PAYMENT_WEBHOOK_SECRET' = New-Secret
            'DEMO_SEED_PASSWORD'     = $seedPassword.Trim()
        }
        $lines = foreach ($line in Get-Content -Encoding UTF8 $example) {
            $key = ($line -split '=', 2)[0]
            if ($filled.ContainsKey($key)) { "$key=$($filled[$key])" } else { $line }
        }
        [IO.File]::WriteAllLines($EnvFile, [string[]]$lines, (New-Object Text.UTF8Encoding $false))
        Write-Host "Base $publicDatabase et utilisateur $publicUser prêts."
        Write-Host "Configuration écrite dans $EnvFile (secrets tirés au hasard, NON affichés)."
        Write-Host 'Étape suivante : .\deploy\public.ps1 -Step config'
    }
    'config' {
        $null = Use-PublicConfig
        # Valide TOUTE la configuration comme au démarrage de l'API (garde-fous de production).
        # Pas de guillemets doubles : Windows PowerShell 5.1 les retire des arguments.
        Invoke-Backend @('-c', 'from app.core.config import get_settings; s = get_settings(); print(''Configuration valide :'', s.app_env, s.receipt_verify_url, s.cors_origins, s.trusted_proxies)')
    }
    'migrer' {
        $null = Use-PublicConfig
        Invoke-Backend @('-m', 'alembic', 'upgrade', 'head')
        Write-Host "Base $publicDatabase à jour."
    }
    'seed' {
        $null = Use-PublicConfig
        Invoke-Backend @('-m', 'scripts.seed')
    }
    'api' {
        $null = Use-PublicConfig
        $uvicorn = @(
            (Join-Path $backend '.venv\Scripts\uvicorn.exe'),
            (Join-Path $backend '.venv/bin/uvicorn')
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        Write-Host "API sur http://127.0.0.1:8000 (Ctrl+C pour l'arrêter). Exposée par ngrok : $domain"
        Push-Location $backend
        try {
            # Mêmes options que l'image Docker ; 127.0.0.1 seulement : ngrok seul l'expose.
            & $uvicorn app.main:app --host 127.0.0.1 --port 8000 --no-server-header --no-proxy-headers --no-access-log
        } finally { Pop-Location }
    }
    'taches' {
        $null = Use-PublicConfig
        Write-Host 'Tâches planifiées : chaque minute (paiements, e-mails, annonces) ; chaque jour dès 6 h'
        Write-Host '(relevés simulés puis alertes). Ctrl+C pour arrêter.'
        $lastDaily = $null
        while ($true) {
            $ErrorActionPreference = 'Continue' # une tâche en échec n'arrête pas les autres
            foreach ($task in 'check_pending_payments', 'send_emails', 'send_announcements') {
                Push-Location $backend
                & $python -m "scripts.$task" | Out-Null
                if ($LASTEXITCODE -ne 0) { Write-Host "$(Get-Date -Format HH:mm) $task : échec (code $LASTEXITCODE)" }
                Pop-Location
            }
            $now = Get-Date
            if ($now.Hour -ge 6 -and $lastDaily -ne $now.Date) {
                foreach ($task in 'daily_tick', 'daily_alerts') {
                    Push-Location $backend
                    & $python -m "scripts.$task"
                    Pop-Location
                }
                $lastDaily = $now.Date
            }
            $ErrorActionPreference = 'Stop'
            Start-Sleep -Seconds 60
        }
    }
    'sauvegarde' {
        $null = Use-PublicConfig
        New-Item -ItemType Directory -Force $backups | Out-Null
        $name = "$publicDatabase-$(Get-Date -Format 'yyyyMMdd-HHmm').sql"
        $ErrorActionPreference = 'Continue'
        docker exec $container mysqldump -uroot -proot --single-transaction --routines --triggers `
            --databases $publicDatabase --result-file="/tmp/$name" 2>$null
        $code = $LASTEXITCODE
        if ($code -eq 0) { docker cp "${container}:/tmp/$name" (Join-Path $backups $name) | Out-Null; $code = $LASTEXITCODE }
        docker exec $container rm -f "/tmp/$name" | Out-Null
        $ErrorActionPreference = 'Stop'
        if ($code -ne 0) { throw "Sauvegarde impossible (Docker et $container lancés ?)." }
        # On garde les 14 plus récentes (une par jour : deux semaines).
        Get-ChildItem $backups -Filter "$publicDatabase-*.sql" | Sort-Object Name -Descending |
            Select-Object -Skip 14 | Remove-Item
        Write-Host "Sauvegarde : $(Join-Path $backups $name)"
    }
    'restaurer' {
        $null = Use-PublicConfig
        if (-not $Fichier -or -not (Test-Path $Fichier)) { throw 'Préciser la sauvegarde : -Fichier deploy\sauvegardes\<fichier>.sql' }
        if ((Split-Path $Fichier -Leaf) -notlike "$publicDatabase-*.sql") {
            throw "Refusé : seules les sauvegardes de $publicDatabase se restaurent ici."
        }
        Write-Host "La base $publicDatabase va être REMPLACÉE par $Fichier (API et tâches arrêtées d'abord)."
        if ((Read-Host 'Taper RESTAURER pour continuer') -cne 'RESTAURER') { Write-Host 'Annulé.'; return }
        $ErrorActionPreference = 'Continue'
        docker cp $Fichier "${container}:/tmp/restauration.sql" | Out-Null
        docker exec $container sh -c 'mysql -uroot -proot < /tmp/restauration.sql' 2>$null
        $code = $LASTEXITCODE
        docker exec $container rm -f /tmp/restauration.sql | Out-Null
        $ErrorActionPreference = 'Stop'
        if ($code -ne 0) { throw 'Restauration en échec.' }
        Write-Host "Base $publicDatabase restaurée."
    }
    'verifier' {
        $local = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/api/v1/health' -TimeoutSec 5
        Write-Host "Local : $($local | ConvertTo-Json -Compress)"
        # En-tête ngrok-skip-browser-warning : sans lui, ngrok répond par sa page d'avertissement.
        $public = Invoke-RestMethod -Uri "$domain/api/v1/health" -TimeoutSec 15 `
            -Headers @{ 'ngrok-skip-browser-warning' = '1' }
        Write-Host "Par ngrok : $($public | ConvertTo-Json -Compress)"
    }
}
