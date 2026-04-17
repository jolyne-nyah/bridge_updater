# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.


if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Error: This script must be run as Administrator."
    Pause; Exit
}

Write-Host "[1/4] Installing Python 3.14..." -ForegroundColor Yellow
winget install -e --id Python.Python.3.14 --scope machine --override "/passive PrependPath=1"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "[2/4] Installing pywin32..." -ForegroundColor Yellow
python -m pip install --upgrade pip
python -m pip install pywin32
python -m pywin32_postinstall -install

Write-Host "[3/4] Installing Vagrant (GitHub MSI)..." -ForegroundColor Yellow
$vagrantUrl = "https://github.com/hashicorp/vagrant/releases/download/2.4.10.dev%2B000781-f9e2630d/vagrant_2.4.10.dev_windows_amd64.msi"
$tempMsi = "$env:TEMP\vagrant_setup.msi"

try {
    Write-Host "Downloading file..."
    Invoke-WebRequest -Uri $vagrantUrl -OutFile $tempMsi
    Write-Host "Starting installation..."
    Start-Process msiexec.exe -ArgumentList "/i `"$tempMsi`" /passive /norestart" -Wait
    Remove-Item $tempMsi
} catch {
    Write-Error "Failed to download Vagrant. A VPN or proxy might be needed."
}

Write-Host "[4/4] Disabling Hyper-V and Sandbox..." -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue
Disable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -NoRestart -ErrorAction SilentlyContinue

Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "Restart your computer to complete the process." -ForegroundColor Yellow
$response = Read-Host "Restart now? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "Restarting..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Host "Please restart manually when ready." -ForegroundColor Yellow
}
