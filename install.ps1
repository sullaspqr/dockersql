$ErrorActionPreference = "Stop"

$Source = Split-Path -Parent $MyInvocation.MyCommand.Path
$Target = "C:\Docker\php-dev"

$StateDir = "C:\ProgramData\PHP-Dev-Installer"
$StateFile = "$StateDir\state.txt"

$DockerInstaller = Join-Path $Source "software\Docker Desktop Installer.exe"

$ResumeTaskName = "PHP-Dev-Installer-Resume"


# ============================================================
# SEGÉDFÜGGVÉNYEK
# ============================================================

function Write-Step {
    param([string]$Text)

    Write-Host ""
    Write-Host "========================================"
    Write-Host $Text
    Write-Host "========================================"
}


function Test-WSL {

    try {
        $output = wsl.exe --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            return $true
        }

        return $false
    }
    catch {
        return $false
    }
}


function Test-Docker {

    try {
        docker version 2>$null | Out-Null

        if ($LASTEXITCODE -eq 0) {
            return $true
        }

        return $false
    }
    catch {
        return $false
    }
}


function Register-ResumeTask {

    Write-Host "Telepites folytatasanak beallitasa..."

    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Source\install.ps1`""

    $Trigger = New-ScheduledTaskTrigger -AtLogOn

    $Principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest

    Register-ScheduledTask `
        -TaskName $ResumeTaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Force | Out-Null

    Write-Host "Folytatasi feladat beallitva."
}


function Remove-ResumeTask {

    try {
        Unregister-ScheduledTask `
            -TaskName $ResumeTaskName `
            -Confirm:$false `
            -ErrorAction SilentlyContinue
    }
    catch {
    }
}


# ============================================================
# KEZDÉS
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " PHP FEJLESZTOI KORNYEZET TELEPITESE"
Write-Host "========================================"
Write-Host ""

# ============================================================
# 1. WSL2
# ============================================================

Write-Step "[1/6] WSL2 ellenorzese"

if (-not (Test-WSL)) {

    Write-Host ""
    Write-Host "A WSL2 nincs megfeleloen telepitve."
    Write-Host "WSL2 telepitese indul..."
    Write-Host ""

    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

    "WSL_INSTALLING" | Set-Content $StateFile

    Register-ResumeTask

    Write-Host ""
    Write-Host "WSL2 telepitese..."

    wsl.exe --install --no-distribution

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "A WSL2 telepitese hibaval leallt."
        Write-Host ""
        pause
        exit 1
    }

    Write-Host ""
    Write-Host "A WSL2 telepitese sikeres."
    Write-Host ""
    Write-Host "A gepet ujra kell inditani."
    Write-Host ""
    Write-Host "A telepito az ujrainditas utan automatikusan folytatodik."
    Write-Host ""

    Start-Sleep -Seconds 5

    Restart-Computer

    exit
}

Write-Host "WSL2 OK."


# ============================================================
# 2. DOCKER DESKTOP
# ============================================================

Write-Step "[2/6] Docker Desktop ellenorzese"

if (-not (Test-Docker)) {

    Write-Host ""
    Write-Host "A Docker Desktop nincs telepitve vagy nem fut."
    Write-Host ""

    if (-not (Test-Path $DockerInstaller)) {

        Write-Host "HIBA:"
        Write-Host "Nem talalhato:"
        Write-Host $DockerInstaller
        Write-Host ""

        pause
        exit 1
    }

    Write-Host "Docker Desktop telepitese..."
    Write-Host ""

    Start-Process `
        -FilePath $DockerInstaller `
        -Wait `
        -ArgumentList "install", "--backend=wsl-2", "--accept-license"

    Write-Host ""
    Write-Host "Docker Desktop telepitve."
}
else {

    Write-Host "Docker Desktop / Docker Engine OK."
}


# ============================================================
# 3. DOCKER DESKTOP INDÍTÁSA
# ============================================================

Write-Step "[3/6] Docker Desktop inditasa"

$DockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (Test-Path $DockerExe) {

    Write-Host "Docker Desktop inditasa..."

    Start-Process $DockerExe

}
else {

    Write-Host "A Docker Desktop program nem talalhato:"
    Write-Host $DockerExe
    Write-Host ""

    pause
    exit 1
}


# ============================================================
# 4. DOCKER ENGINE MEGVÁRÁSA
# ============================================================

Write-Step "[4/6] Docker Engine megvarasa"

$MaxAttempts = 60
$Attempt = 0

while (-not (Test-Docker)) {

    $Attempt++

    if ($Attempt -ge $MaxAttempts) {

        Write-Host ""
        Write-Host "HIBA: A Docker Engine nem indult el idoben."
        Write-Host ""

        Write-Host "Inditsd el a Docker Desktopot, majd futtasd ujra:"
        Write-Host "install.cmd"

        pause
        exit 1
    }

    Write-Host "Docker indulasa... $Attempt / $MaxAttempts"

    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "Docker Engine OK."


# ============================================================
# 5. PHP PROJEKT TELEPÍTÉSE
# ============================================================

Write-Step "[5/6] PHP fejlesztoi kornyezet telepitese"

New-Item `
    -ItemType Directory `
    -Force `
    -Path $Target | Out-Null

New-Item `
    -ItemType Directory `
    -Force `
    -Path "$Target\www" | Out-Null

New-Item `
    -ItemType Directory `
    -Force `
    -Path "$Target\backup" | Out-Null


Write-Host "Fajlok masolasa..."

Copy-Item `
    "$Source\compose.yaml" `
    "$Target\compose.yaml" `
    -Force

Copy-Item `
    "$Source\Dockerfile" `
    "$Target\Dockerfile" `
    -Force

Copy-Item `
    "$Source\.env" `
    "$Target\.env" `
    -Force

Copy-Item `
    "$Source\backup.ps1" `
    "$Target\backup.ps1" `
    -Force

Copy-Item `
    "$Source\www\index.php" `
    "$Target\www\index.php" `
    -Force


# ============================================================
# 6. DOCKER COMPOSE
# ============================================================

Write-Step "[6/6] Docker Compose inditasa"

Set-Location $Target

Write-Host "Compose konfiguracio ellenorzese..."

docker compose config | Out-Null

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "HIBA: A compose.yaml hibas."
    Write-Host ""

    pause
    exit 1
}

Write-Host "Compose konfiguracio OK."
Write-Host ""

Write-Host "Kontenerek epitese es inditasa..."

docker compose up -d --build

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "HIBA: A Docker Compose inditasa sikertelen."
    Write-Host ""

    pause
    exit 1
}


# ============================================================
# KÉSZ
# ============================================================

Start-Sleep -Seconds 5

Write-Step "TELEPITES SIKERES"

Write-Host ""
Write-Host "Apache + PHP:"
Write-Host "http://localhost:8080"
Write-Host ""

Write-Host "phpMyAdmin:"
Write-Host "http://localhost:8081"
Write-Host ""

Write-Host "Projekt:"
Write-Host "C:\Docker\php-dev"
Write-Host ""

Write-Host "Kontenerek:"
Write-Host ""

docker compose ps

Write-Host ""
Write-Host "========================================"
Write-Host " A RENDSZER HASZNALATRA KESZ"
Write-Host "========================================"
Write-Host ""


# ============================================================
# FOLYTATÁSI FELADAT TÖRLÉSE
# ============================================================

Remove-ResumeTask

if (Test-Path $StateFile) {
    Remove-Item $StateFile -Force
}

Write-Host "A telepitesi allapot torolve."
Write-Host ""

pause