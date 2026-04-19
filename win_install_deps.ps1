# Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
# This program comes with ABSOLUTELY NO WARRANTY.
# See <https://gnu.org> for details.


if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERROR: This setup script requires Administrator privileges."
    Pause; Exit
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

$rebootRequired = $false

Write-Host "[1/5] Checking Python..." -ForegroundColor Yellow

if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Python OK." -ForegroundColor Green
} else {
    Write-Host "Installing Python via winget..." -ForegroundColor Yellow
    winget install --id Python.Python --scope machine --exact --silent
    Refresh-Path
}

Write-Host "[2/5] Updating Pip and pywin32..." -ForegroundColor Yellow
python -m pip install --upgrade pip
python -m pip install pywin32

Write-Host "Running pywin32 post-install..." -ForegroundColor Gray
python -m pywin32_postinstall -install

Write-Host "[3/5] Checking VirtualBox..." -ForegroundColor Yellow

if (Get-Command vboxmanage -ErrorAction SilentlyContinue) {
    Write-Host "VirtualBox OK." -ForegroundColor Green
} else {
    Write-Host "Installing VirtualBox via winget..." -ForegroundColor Yellow
    winget install --id Oracle.VirtualBox --scope machine --exact --silent
    Refresh-Path
    $rebootRequired = $true
}

Write-Host "[4/5] Checking Vagrant..." -ForegroundColor Yellow
if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    Write-Host "Vagrant OK." -ForegroundColor Green
} else {
    $vagrantUrl = "https://github.com/hashicorp/vagrant/releases/download/2.4.10.dev%2B000781-f9e2630d/vagrant_2.4.10.dev_windows_amd64.msi"
    $tempMsi = "$env:TEMP\vagrant_setup.msi"
    
    Write-Host "Downloading Vagrant via curl.exe..." -ForegroundColor Gray
    
    curl.exe -L $vagrantUrl --output $tempMsi -C -

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Download failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pause; Exit 1
    }

    if (Test-Path $tempMsi) {
        Write-Host "Download complete. Starting installation..." -ForegroundColor Green
        
        $process = Start-Process msiexec.exe -ArgumentList "/i `"$tempMsi`" /qb /norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "Vagrant installed successfully!" -ForegroundColor Green
            Remove-Item $tempMsi -ErrorAction SilentlyContinue
            $rebootRequired = $true
        } else {
            Write-Host "Installation failed with code $($process.ExitCode)" -ForegroundColor Red
            Pause; Exit 1
        }
    } else {
        Write-Host "File not found after download!" -ForegroundColor Red
        Pause; Exit 1
    }
}


Write-Host "[5/5] Checking Hyper-V and Sandbox status..." -ForegroundColor Yellow
$features = @("Microsoft-Hyper-V-All", "Containers-DisposableClientVM")

foreach ($feature in $features) {
    $status = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
    if ($status -and $status.State -eq "Enabled") {
        Write-Host "Disabling $feature..." -ForegroundColor Gray
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
        $rebootRequired = $true
    } else {
        Write-Host "$feature is already disabled." -ForegroundColor Green
    }
}


Write-Host "`n=== Installation Finished ===" -ForegroundColor Green

if ($rebootRequired) {
    Write-Host "System changes detected. Restart is REQUIRED for VirtualBox/Hyper-V to work correctly." -ForegroundColor Red
    $response = Read-Host "Restart now? (y/n)"
    if ($response -in @("y", "Y", "yes", "Yes")) { Restart-Computer -Force }
} else {
    Write-Host "No changes detected. You are ready to go!" -ForegroundColor Green
    Pause
}