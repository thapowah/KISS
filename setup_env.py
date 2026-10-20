from pathlib import Path
import secrets
p=Path('.env')
if p.exists():
    raise SystemExit('.env finnes allerede og ble ikke endret.')
p.write_text(Path('.env.example').read_text().replace('REPLACE_WITH_RANDOM_SECRET_AT_LEAST_32_CHARACTERS',secrets.token_urlsafe(48)))
print('Opprettet .env med tilfeldig SECRET_KEY. Tilpass nettverksinnstillinger før oppstart.')
