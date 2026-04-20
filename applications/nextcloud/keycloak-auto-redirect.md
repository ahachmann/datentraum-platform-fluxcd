# Keycloak Auto-Redirect & lokalen Login deaktivieren

## Verhalten

Wenn aktiviert, leitet Nextcloud beim Login-Aufruf direkt zu Keycloak weiter.
Der lokale Nextcloud-Login (Benutzername/Passwort) ist dann nicht mehr erreichbar.

## Aktivieren

**Pfad:** Einstellungen → Administration → OpenID Connect → Provider bearbeiten

| Einstellung | Wert |
|-------------|------|
| Automatisch zum Identity Provider weiterleiten | `ON` |

Lokalen Login deaktivieren via `occ`:
```bash
php /var/www/html/occ config:app:set user_oidc allow_multiple_user_backends --value=0
```

Make KC user to be NC admin

php /var/www/html/occ user:setting hachmann settings admin_user 1
php /var/www/html/occ group:adduser admin hachmann

## Deaktivieren (Notfall / Keycloak nicht erreichbar)

Lokalen Login wieder aktivieren via `occ`:
```bash
php /var/www/html/occ config:app:set user_oidc allow_multiple_user_backends --value=1
```

Auto-Redirect deaktivieren via `occ`:
```bash
php /var/www/html/occ config:app:set user_oidc auto_redirect_on_logout --value=0
```

Danach ist der lokale Login wieder über `https://DOMAIN/login` erreichbar.

## Notfall-Login ohne occ

Falls kein `occ`-Zugriff möglich ist, kann der lokale Login durch direkten URL-Aufruf umgangen werden:

```
https://cloud.cvo-elternrat.de/login?direct=1
```

Dieser Parameter zeigt die Nextcloud-eigene Login-Seite, auch wenn Auto-Redirect aktiv ist.

> **Hinweis:** Einen lokalen Admin-User immer als Fallback behalten.
