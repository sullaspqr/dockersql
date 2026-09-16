$BackupDir = "C:\Docker\php-dev\backup"
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$File = "$BackupDir\web_$Date.sql"

# .env beolvasása
$envFile = "C:\Docker\php-dev\.env"

$envData = @{}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()

    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2

        if ($parts.Count -eq 2) {
            $envData[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

$DBUser = $envData["MARIADB_USER"]
$DBPassword = $envData["MARIADB_PASSWORD"]
$DBName = $envData["MARIADB_DATABASE"]

Write-Host "Adatbázis: $DBName"
Write-Host "Felhasználó: $DBUser"

# Backup könyvtár
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Backup
docker exec mariadb mariadb-dump "-u$DBUser" "-p$DBPassword" "$DBName" > $File

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup sikeres:"
    Write-Host $File
}
else {
    Write-Host "HIBA: a backup nem sikerült!"
    Remove-Item $File -ErrorAction SilentlyContinue
    exit 1
}

# 7 napnál régebbi mentések törlése
Get-ChildItem $BackupDir -Filter "web_*.sql" |
    Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-7)
    } |
    Remove-Item