# Prépare le téléphone pour joindre l'API du PC (voir docs/TELEPHONE.md), en USB ou en débogage sans fil.
# Usage (depuis frontend/mobile) : .\tool\telephone.ps1
#   ou, pour choisir l'appareil : .\tool\telephone.ps1 -Device 192.168.1.73:38473
# En sans fil, connecter d'abord le téléphone : adb pair <IP:port d'association> <code>, puis
# adb connect <IP:port affiché sur l'écran « Débogage sans fil »>.
param([string]$Device)
$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $found = Get-Command adb -ErrorAction SilentlyContinue
    if ($null -eq $found) { Write-Host 'adb introuvable : installer les platform-tools du SDK Android.'; exit 1 }
    $adb = $found.Source
}

# 1. Téléphone connecté et autorisé (USB ou sans fil)
$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
$ready = @($devices | Where-Object { $_ -match "`tdevice$" } | ForEach-Object { ($_ -split "`t")[0] })
if ($ready.Count -eq 0) {
    Write-Host 'Aucun téléphone prêt. USB : câble, débogage USB, fenêtre « Autoriser » sur le téléphone.'
    Write-Host 'Sans fil : adb pair puis adb connect (voir docs/TELEPHONE.md).'
    if ($devices) { Write-Host ($devices -join "`n") }
    exit 1
}
if ($Device) {
    if ($ready -notcontains $Device) {
        Write-Host "Appareil « $Device » absent ou pas prêt. Entrées vues :"
        Write-Host ($devices -join "`n")
        exit 1
    }
    $serial = $Device
    Write-Host "Téléphone choisi : $serial"
} else {
    # En sans fil, le même téléphone apparaît souvent plusieurs fois (adresse IP, nom annoncé sur le
    # réseau, parfois deux noms annoncés) : on compare les numéros de série matériels pour ne compter
    # qu'une fois chaque téléphone. Une entrée dont le numéro est illisible est ignorée.
    $entries = foreach ($d in $ready) {
        $hw = ''
        try { $hw = "$(& $adb -s $d shell getprop ro.serialno 2>$null)".Trim() } catch { }
        [pscustomobject]@{ Entry = $d; Hardware = $hw }
    }
    $phones = @($entries | Where-Object { $_.Hardware } | Group-Object Hardware)
    if ($phones.Count -ne 1) {
        Write-Host 'Impossible de choisir un seul téléphone. Entrées vues (entrée -> numéro de série) :'
        $entries | ForEach-Object { Write-Host "  $($_.Entry) -> $($_.Hardware)" }
        Write-Host 'Relancer avec : .\tool\telephone.ps1 -Device <entrée>'
        exit 1
    }
    # Préférer l'adresse IP:port (plus stable que le nom annoncé), sinon la première entrée.
    $serial = @($phones[0].Group.Entry |
        Sort-Object { if ($_ -match '^\d+\.\d+\.\d+\.\d+:\d+$') { 0 } else { 1 } })[0]
    Write-Host "Téléphone : $serial ($($phones[0].Name))"
}

# 2. Tunnel : port 8000 du téléphone -> port 8000 du PC (marche aussi en sans fil)
& $adb -s $serial reverse tcp:8000 tcp:8000 | Out-Null
Write-Host 'Tunnel ouvert (adb reverse tcp:8000 tcp:8000).'

# 3. Place libre (le mode debug a besoin d'environ 600 Mo)
$df = & $adb -s $serial shell df -k /data | Select-Object -Last 1
$freeKb = [long](($df -split '\s+')[3])
$freeMb = [math]::Round($freeKb / 1024)
if ($freeMb -lt 700) {
    Write-Host "Place libre sur le téléphone : $freeMb Mo. Utiliser : flutter run --profile -d $serial"
} else {
    Write-Host "Place libre sur le téléphone : $freeMb Mo. flutter run -d $serial (debug) ; en cas d'échec : --profile"
}

# 4. API joignable sur le PC
try {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/api/v1/health' -TimeoutSec 5
    Write-Host "API : $($health.status), base : $($health.database), mode démo : $($health.demo_mode)"
} catch {
    Write-Host "API injoignable sur http://127.0.0.1:8000 : la lancer d'abord (backend/README.md)."
    exit 1
}