# KISS – modernisert infoskjermsystem

Videreutviklet fra https://github.com/nuxis/KISS, commit
`7c8543942ea53c57e5c26cddee6e5a3957200371`. Opprinnelig MIT-lisens er bevart i LICENSE.

## Hva følger med?

- Skjermer, HTML-lysbilder og norsk Django-administrasjon.
- Spilleliste med eksplisitt rekkefølge, aktivering og varighet 1–86400 sekunder.
- Lokal HTML-editor med formateringsknapper og isolert forhåndsvisning.
- Spiller uten fullside-oppfriskning; endringer hentes hvert 15. sekund.
- Ulike skjermer/faner har uavhengig avspilling. Tomme spillelister håndteres.
- Innlogging for skjermoversikt og administrasjon. Spillerlenker har tilfeldig UUID.
- Docker Compose, Gunicorn, WhiteNoise, vedvarende SQLite og import av gammel database.

## Nytt: bakgrunner og media

Mediebiblioteket tar imot JPG, PNG, WebP, GIF og MP4 med H.264-video. Bilder
kontrolleres med Pillow; videoer kontrolleres med ffprobe (følger med Docker).
Standard maks filstørrelse er 100 MB. Endres med `MAX_UPLOAD_MB` i `.env`.
En eventuell ekstern proxy/Cloudflare kan ha en lavere grense.

1. Åpne **Administrasjon → Mediebibliotek → Legg til mediefil**.
2. Skriv navn og last opp fil. Filen får en forhåndsvisning etter lagring.
3. Opprett eller rediger et lysbilde:
   - **Tekst / HTML**: Velg bakgrunnsbilde og skriv vanlig tekst. HTML er valgfritt.
   - **Bilde**: Velg bildefil. Vanlig tekst/HTML kan også legges oppå.
   - **Video**: Velg MP4-fil. Video vises uten tekst eller bakgrunn over.
4. Velg **Fyll skjermen** (beskjærer kantene) eller **Vis hele bildet**
   (svarte felt der formatet ikke passer).
5. For video: **Fast varighet** bruker spillelistens sekunder og gjentar videoen.
   **Spill hele videoen** går videre ved videoslutt. All video er uten lyd.
6. Lagre og åpne **Forhåndsvis lagret lysbilde** før du legger det i spillelisten.

Du kan sette inn bilder i HTML fra nedtrekkslisten i editoren. Den lille
HTML-forhåndsvisningen viser kun HTML; lenken for lagret lysbilde viser også
bakgrunn, tekst, bildetilpasning og video. Editor er ikke full WYSIWYG.
Mediefiler som brukes av lysbilder (også som innlimt intern bilde-URL i HTML)
kan ikke slettes før referansene fjernes. Opplastede filer er uforanderlige;
last opp en ny fil for å erstatte innhold og velg den på lysbildet.
Ved sletting av en ubrukt fil fjernes også filen fra disken.

Opplastinger ligger i `/data/media` i samme vedvarende Docker-volum som databasen.
Mediefiler serveres med korrekt MIME-type og støtte for HTTP Range for video.
Medielenker inneholder tilfeldige UUID-er og kan åpnes uten innlogging; de er
ikke egnet for hemmelige filer. Bytte av spillerlenke opphever ikke medielenkene.
Innhold kan ligge i nettleserens cache i inntil én time etter sletting.

### Oppdatere fra første versjon

Ta backup først. Pakk ut over den gamle prosjektmappen, men **behold `.env`,
samme prosjektmappe/Compose-prosjektnavn og Docker-volumet**. Kjør:

```sh
docker compose up -d --build
```

Databasemigreringen beholder eksisterende skjermer, spillelister og HTML.
Eksisterende lysbilder blir typen Tekst / HTML. Du trenger ikke opprette ny
administrator. Ikke kjør `down -v`.

Systemet har fortsatt ikke tidsplanlegging eller skjermovervåkning.

## Kom i gang med Docker

Krever Docker Engine/Desktop med Compose v2. Pakk ut og åpne terminal i mappen.

1. Lag konfigurasjon med `python3 setup_env.py` (Windows: `py setup_env.py`).
   Hvis Python ikke er installert: kopier `.env.example` til `.env` og erstatt
   SECRET_KEY med minst 32 tilfeldige tegn. Behold nøkkelen mellom omstarter.
2. Start:

```sh
docker compose up -d --build
docker compose exec kiss python manage.py createsuperuser
```

3. Åpne http://localhost:8088/admin/ og logg inn.
4. Opprett et lysbilde. Eksempel:

```html
<section style="padding:8vh;background:#142a40;min-height:84vh">
  <p style="color:#74e5c2;font-size:24px">VELKOMMEN</p>
  <h1 style="font-size:80px">KISS infoskjerm</h1>
  <p style="font-size:36px">Her kommer dagens informasjon.</p>
</section>
```

5. Opprett en skjerm. Legg til lysbildene i spillelisten, med rekkefølge og sekunder.
6. Lagre, og velg **Åpne spiller**. Bruk F11 eller nettleserens kioskmodus.
   Spilleren har ingen synlig fullskjermknapp.

SQLite lagres i Docker-volumet `kiss_data`. Ikke bruk `docker compose down -v`
med mindre du vil slette databasen.

## Tilgang fra andre maskiner

Standard binder kun localhost. For lokalnett: sett `BIND_ADDRESS=0.0.0.0`
og legg serverens IP eller DNS-navn til `ALLOWED_HOSTS`, f.eks.
`localhost,127.0.0.1,192.168.10.50`. Start på nytt med `docker compose up -d`.
Porten er 8088 og kan endres i `.env`. IP-adressen er bare et eksempel.

## Cloudflare Tunnel (valgfritt)

Med cloudflared på samme vert: pek tunnelen til `http://localhost:8088`.
Hvis cloudflared kjører i Docker, må den være på samme Docker-nettverk og bruke
`http://kiss:8000`, eller nå vertens tilgjengelige IP og publiserte port.
`localhost` inni cloudflared-containeren peker ikke til KISS.

Sett eksempelvis:

```dotenv
ALLOWED_HOSTS=localhost,127.0.0.1,kiss.dittdomene.no
CSRF_TRUSTED_ORIGINS=https://kiss.dittdomene.no
TRUST_PROXY=true
SECURE_COOKIES=true
```

Aktiver TRUST_PROXY bare bak en betrodd proxy som setter X-Forwarded-Proto.
Med sikre cookies må administrasjonen åpnes via HTTPS; lokal HTTP-innlogging
fungerer da ikke. Bruk `docker compose up -d` etter endringer i `.env`.
Cloudflared er valgfritt og følger ikke med som tjeneste.

## Innhold og tilgang

Spillerlenken gir lesetilgang til skjermens HTML uten innlogging. Behandle den som
en hemmelig lenke. Handlingen **Bytt spillerlenker** i skjermadministrasjonen
opphever gamle lenker ved neste polling. Det er ikke en erstatning for VPN eller
sterk autentisering hvis du skal vise konfidensielt innhold.

HTML kjøres i en sandbox-iframe uten JavaScript, skjemaer eller tilgang til
administrasjonens cookies. Eksterne bilder over HTTPS og data-URL-er støttes.
Skript, embeds og eksterne stilark fra gammel HTML virker derfor ikke automatisk.
Video kjøres i spillerens eget videoelement, separat fra HTML-sandboxen.
Innhold skaleres med egen HTML/CSS; det er ikke en fast 1920×1080-editor.
Ved forbindelsesbrudd fortsetter allerede innlastet spilleliste i minnet. Etter
full omstart trenger spilleren nett igjen; dette er ikke en offline-klient.

## Import fra KISS 2014

Ikke legg gammel database direkte i det nye volumet. Ta en kopi først.
Opprett en ny installasjon uten skjermer/lysbilder; administratorbruker kan finnes.

```sh
docker compose cp ./gammel-db.sqlite3 kiss:/tmp/legacy.sqlite3
docker compose exec kiss python manage.py import_legacy /tmp/legacy.sqlite3
```

Importen leser kun originalens `slides_slide`, `slides_screen` og
`slides_screen_slides`. Nye interne ID-er og spillerlenker opprettes. Brukere og
sesjoner importeres ikke. Varighet blir 5 sekunder som i originalen, og gammel
koblingsrekkefølge brukes siden originalen ikke hadde eksplisitt sortering.
Importen er atomisk og avvises hvis målet allerede har skjermer eller lysbilder.

## Backup og oppdatering

Ta konsistent SQLite-backup med Python sin backup-funksjon:

```sh
docker compose exec kiss python -c "import sqlite3; s=sqlite3.connect('/data/db.sqlite3'); d=sqlite3.connect('/data/backup.sqlite3'); s.backup(d); d.close(); s.close()"
docker compose cp kiss:/data/backup.sqlite3 ./backup.sqlite3
```

Ta også backup av mediefilene:

```sh
docker compose cp kiss:/data/media ./media-backup
```

Stans opplasting/redigering mens database og media sikkerhetskopieres, slik at
kopiene samsvarer. For full restore: stopp tjenesten, gjenopprett databasen som
`/data/db.sqlite3` og mediemappen som `/data/media` i volumet, og sørg for at
containerbrukeren UID 10001 eier filene før oppstart.

Ta også vare på `.env`. Ved oppdatering behold `.env` og volumet, bytt kildekoden,
og kjør `docker compose up -d --build`. Migreringer kjøres før serveren starter.

## Utvikling og tester

Ved lokal kjøring må ffmpeg/ffprobe installeres (Debian: `sudo apt install ffmpeg`).
Python 3.12 eller 3.13 anbefales; Docker bruker 3.13. `.env` leses av Compose,
ikke automatisk av Python/Django ved direkte kjøring. Eksporter variablene lokalt.

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
export SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export DEBUG=true
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
python manage.py test
```

Produksjonsavhengigheter er versjonslåst i requirements.txt. Gjennomgå og oppdater
sikkerhetspatcher regelmessig. SQLite passer et lite oppsett med få redaktører og
én server; større installasjoner bør flyttes til PostgreSQL.

## Endringer fra originalen

Django 1.6/Python 2 er erstattet med Django 5.2/Python 3. Gammel URL-konfigurasjon,
settings og modellmetoder er modernisert. Hardkodet hemmelighet og DEBUG=true er
fjernet. django-wysiwyg/YUI, argparse og wsgiref er fjernet. Serverbasert
sesjon/paginering og meta-refresh er erstattet med uavhengig nettleserspiller.

## Verifisering av denne leveransen

12 Django-tester dekker opplasting, ugyldige filer, MP4/H.264, filstørrelse,
Range/HEAD, slettesperre, fysisk sletting, bakgrunn i feed, adminopplasting,
forhåndsvisning, tilgangskontroll, gammel import og eksisterende spillerfunksjoner.
JavaScript-testen dekker bakgrunn, tekstescaping, lokal media-CSP, videoslutt,
fast videovarighet og tømming av spilleliste. Kjør `node player-test.cjs`.

Oppgradering fra v1 med eksisterende innhold er kontrollert separat.
Docker-daemon er ikke tilgjengelig i testmiljøet, så selve containerbygget og
Cloudflare Tunnel er ikke kjørt her. Visuell nettleser- og kioskprøve gjenstår;
nettlesernedlastingen i testmiljøet feilet.
