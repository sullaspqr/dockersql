$ErrorActionPreference = "Stop"

$Source = Split-Path -Parent $MyInvocation.MyCommand.Path
$Target = "C:\Docker\php-dev"

Write-Host ""
Write-Host "========================================"
Write-Host " PHP fejlesztoi kornyezet telepitese"
Write-Host "========================================"
Write-Host ""

# -----------------------------------------
# 1. WSL ellenorzese
# -----------------------------------------

Write-Host "[1/6] WSL2 ellenorzese..."

try {
    $wslVersion = wsl --version 2>$null

    if ($LASTEXITCODE -ne 0) {
        throw "WSL nem erheto el."
    }

    Write-Host "WSL elerheto."
}
catch {
    Write-Host ""
    Write-Host "HIBA: A WSL2 nem erheto el."
    Write-Host ""
    Write-Host "Ezen a gepen eloszor telepiteni kell a WSL2-t."
    Write-Host ""
    pause
    exit 1
}

# -----------------------------------------
# 2. Docker ellenorzese
# -----------------------------------------

Write-Host ""
Write-Host "[2/6] Docker ellenorzese..."

try {
    docker version | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Docker nem erheto el."
    }
}
catch {
    Write-Host ""
    Write-Host "HIBA: A Docker Desktop nem fut vagy nincs telepitve."
    Write-Host ""
    pause
    exit 1
}

Write-Host "Docker OK."

# -----------------------------------------
# 3. Projektkonyvtarak
# -----------------------------------------

Write-Host ""
Write-Host "[3/6] Projektkonyvtarak letrehozasa..."

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path "$Target\www" | Out-Null
New-Item -ItemType Directory -Force -Path "$Target\backup" | Out-Null

# -----------------------------------------
# 4. Fajlok masolasa
# -----------------------------------------

Write-Host ""
Write-Host "[4/6] Projektfajlok masolasa..."

Copy-Item "$Source\compose.yaml" "$Target\compose.yaml" -Force
Copy-Item "$Source\Dockerfile" "$Target\Dockerfile" -Force
Copy-Item "$Source\.env" "$Target\.env" -Force
Copy-Item "$Source\backup.ps1" "$Target\backup.ps1" -Force
Copy-Item "$Source\www\index.php" "$Target\www\index.php" -Force

Write-Host "Fajlok masolva."

# -----------------------------------------
# 5. Compose ellenorzese
# -----------------------------------------

Write-Host ""
Write-Host "[5/6] Docker Compose ellenorzese..."

Set-Location $Target

docker compose config | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Hibas Docker Compose konfiguracio."
}

Write-Host "Compose konfiguracio OK."

# -----------------------------------------
# 6. Kontenerek inditasa
# -----------------------------------------

Write-Host ""
Write-Host "[6/6] Docker kontenerek inditasa..."

docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    throw "A Docker Compose inditasa sikertelen."
}

Write-Host ""
Write-Host "========================================"
Write-Host " TELEPITES SIKERES!"
Write-Host "========================================"
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
docker compose ps

Write-Host ""
Write-Host "========================================"
Write-Host " A rendszer hasznalatra kesz."
Write-Host "========================================"
Write-Host ""

pause