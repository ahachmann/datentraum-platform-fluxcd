# Keycloak Group Mapper für Nextcloud

## Keycloak-Konfiguration

**Pfad:** Clients → `nextcloud` → Client scopes → `nextcloud-dedicated` → Mappers → Add mapper → By configuration → **Group Membership**

| Feld | Wert |
|------|------|
| Name | `groups` |
| Token Claim Name | `group` |
| Full group path | `OFF` |
| Add to ID token | `ON` |
| Add to access token | `ON` |
| Add to userinfo | `ON` |

> **Wichtig:** Der Claim heißt `group` (Singular), nicht `groups`.

## Nextcloud-Konfiguration

**Pfad:** Einstellungen → Administration → OpenID Connect → Provider bearbeiten

| Feld | Wert |
|------|------|
| Gruppen-Mapping | `group` |

## Verhalten

- Gruppen werden bei jedem Login synchronisiert
- Fehlende Gruppen werden in Nextcloud automatisch erstellt
- Wird ein User in Keycloak aus einer Gruppe entfernt, verliert er die Nextcloud-Gruppe beim nächsten Login
- Sync passiert nur beim Login, nicht in Echtzeit

## Weitere Provider-Einstellungen

| Einstellung | Wert | Beschreibung |
|-------------|------|--------------|
| Auto-Redirect | `ON` | Leitet direkt zu Keycloak weiter |
| allow_multiple_user_backends | `0` | Deaktiviert lokalen Passwort-Login |

> **Hinweis:** Einen lokalen Admin-User als Fallback behalten für den Fall eines Keycloak-Ausfalls.