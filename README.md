# /software könyvtárba a docker desktop fájlt le kell tölteni és bemásolni:
# A fájl neve: Docker Desktop Installer.exe
https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-win-amd64
# A jelszavakat tartalmazó fájl .env -ben tároljuk:
# tartalma: 
# MARIADB_ROOT_PASSWORD=RootJelszo123!
# MARIADB_DATABASE=web
# MARIADB_USER=webuser
# MARIADB_PASSWORD=WebJelszo123!
# Az egész docker indítása: projekt könyvtárból install.cmd fájlt indítani, ha minden feltelepült, akkor
# fusson windows alatt a docker desktop, utána powrshell-ben ahova a projekt be lett másolva: docker compose up -d --build
# leállítás: dcoker compose down
