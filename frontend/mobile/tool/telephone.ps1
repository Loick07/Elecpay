# Prépare le téléphone branché en USB pour joindre l'API du PC (voir docs/TELEPHONE.md).
# Usage (depuis frontend/mobile) : .\tool\telephone.ps1
$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $found = Get-Command adb -ErrorAction SilentlyContinue
    if ($null -eq $found) { Write-Host 'adb introuvable : installer les platform-tools du SDK Android.'; exit 1 }
    $adb = $found.Source
}

# 1. Téléphone branché et autorisé
$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
$ready = @($devices | Where-Object { $_ -match "`tdevice$" })
if ($ready.Count -eq 0) {
    Write-Host 'Aucun téléphone prêt. Vérifier le câble, le débogage USB et accepter la fenêtre sur le téléphone.'
    if ($devices) { Write-Host ($devices -join "`n") }
    exit 1
}
if ($ready.Count -gt 1) {
    Write-Host 'Plusieurs appareils branchés : en garder un seul (ou désactiver le débogage sans fil).'
    exit 1
}
$serial = ($ready[0] -split "`t")[0]
Write-Host "Téléphone : $serial"

# 2. Tunnel USB : port 8000 du téléphone -> port 8000 du PC
& $adb -s $serial reverse tcp:8000 tcp:8000 | Out-Null
Write-Host 'Tunnel USB ouvert (adb reverse tcp:8000 tcp:8000).'

# 3. Place libre (le mode debug a besoin d'environ 600 Mo)
$df = & $adb -s $serial shell df -k /data | Select-Object -Last 1
$freeKb = [long](($df -split '\s+')[3])
$freeMb = [math]::Round($freeKb / 1024)
if ($freeMb -lt 700) {
    Write-Host "Place libre sur le téléphone : $freeMb Mo. Utiliser : flutter run --profile"
} else {
    Write-Host "Place libre sur le téléphone : $freeMb Mo. flutter run (debug) ; en cas d'échec : flutter run --profile"
}

# 4. API joignable sur le PC
try {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/api/v1/health' -TimeoutSec 5
    Write-Host "API : $($health.status), base : $($health.database), mode démo : $($health.demo_mode)"
} catch {
    Write-Host "API injoignable sur http://127.0.0.1:8000 : la lancer d'abord (backend/README.md)."
    exit 1
}
