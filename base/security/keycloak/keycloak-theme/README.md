# CVO Keycloak Theme

Custom Keycloak Login- und E-Mail-Theme für das **Carl von Ossietzky Gymnasium Poppenbüttel**.

## Verzeichnisstruktur

```
cvo/
├── login/
│   ├── theme.properties          # Theme-Konfiguration
│   ├── login.ftl                 # Haupt-Login-Template
│   ├── template.ftl              # HTML-Layout-Wrapper
│   ├── messages/
│   │   ├── messages_de.properties
│   │   └── messages_en.properties
│   └── resources/
│       ├── css/
│       │   └── login.css         # CVO Branding (Farben, Layout)
│       └── img/
│           └── logo.jpg          # CVO Logo
└── email/
    ├── theme.properties          # parent=base, locales=de,en
    ├── html/
    │   ├── template.ftl          # Layout-Wrapper + Makros (Button, Absatz, Footer)
    │   ├── password-reset.ftl
    │   ├── email-verification.ftl
    │   ├── executeActions.ftl
    │   ├── email-update-confirmation.ftl
    │   └── email-test.ftl
    ├── text/                     # Plaintext-Variante derselben Mails
    │   └── *.ftl
    └── messages/
        ├── messages_de.properties
        └── messages_en.properties
```

---

## Deployment

### Option A – Direktes Deployment (Keycloak Standalone)

1. Theme-Ordner in das Keycloak-Verzeichnis kopieren:

```bash
cp -r cvo/ /opt/keycloak/themes/
```

2. Keycloak neu starten (falls im Dev-Modus nicht nötig):

```bash
/opt/keycloak/bin/kc.sh start
```

3. Im Keycloak Admin UI:
   - **Realm Settings → Themes → Login Theme → `cvo`** auswählen
   - Speichern

---

### Option B – Kubernetes / Flux CD Deployment

Das Theme als ConfigMap oder als Init-Container-Volume mounten.

#### Als Kubernetes ConfigMap (für kleine Themes ohne Binärdateien):

```yaml
# Nur für CSS und FTL-Dateien – Logo separat über Secret oder PVC
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-theme-cvo
  namespace: keycloak
data:
  theme.properties: |
    parent=base
    import=common/keycloak
    styles=css/login.css
    kcHtmlClass=login-pf
    kcLoginClass=login-pf-page
    kcBodyClass=login-pf-bg
```

#### Als Init-Container (empfohlen für vollständige Themes):

```yaml
initContainers:
  - name: theme-provider
    image: busybox
    command:
      - sh
      - -c
      - |
        cp -r /theme/cvo /themes/
    volumeMounts:
      - name: theme-source
        mountPath: /theme
      - name: themes
        mountPath: /themes
volumes:
  - name: themes
    emptyDir: {}
  - name: theme-source
    configMap:
      name: keycloak-theme-cvo
```

#### Keycloak Deployment mit Theme-Volume:

```yaml
volumeMounts:
  - name: themes
    mountPath: /opt/keycloak/themes/cvo
```

---

### Option C – Keycloak Operator (Kubernetes)

Falls du den Keycloak Operator verwendest, kannst du das Theme über eine `KeycloakRealmImport`-Ressource referenzieren oder per Volume-Mount bereitstellen.

Empfehlung: Theme als OCI-Image packen und als Init-Container deployen (Keycloak-Dokumentation: [Server Development Guide – Themes](https://www.keycloak.org/docs/latest/server_development/#_themes)).

---

## Anpassungen

| Was | Wo |
|---|---|
| Farben (Login) | `login/resources/css/login.css` → CSS-Variablen in `:root {}` |
| Logo | `login/resources/img/logo.jpg` ersetzen |
| Texte Login (DE/EN) | `login/messages/messages_{de,en}.properties` |
| Layout / Felder Login | `login/login.ftl` |
| Farben (E-Mail) | `email/html/template.ftl` → `<#assign cvo... >` am Dateianfang |
| Texte E-Mail (DE/EN) | `email/messages/messages_{de,en}.properties` |
| Layout E-Mail | `email/html/template.ftl` (Makros `emailLayout`, `button`, `p`, `muted`, `divider`, `linkFallback`) |
| Neue Sprache | `messages_XX.properties` in `login/messages/` bzw. `email/messages/` anlegen **und** in `kustomization.yaml` als ConfigMap-Datei eintragen |

---

## E-Mail-Theme

### Aktivieren

Admin-Konsole → **Realm Settings → Themes → Email Theme → `cvo`**.
Zusätzlich muss unter **Realm Settings → Email** ein SMTP-Server konfiguriert sein
(Testmail über den Button *Test connection* → rendert `email-test.ftl`).

### Gestaltete Mails

| Template | Anlass |
|---|---|
| `password-reset.ftl` | Passwort vergessen |
| `email-verification.ftl` | E-Mail-Adresse bestätigen (Registrierung) |
| `executeActions.ftl` | Required Actions, z. B. „Passwort aktualisieren" per Admin ausgelöst |
| `email-update-confirmation.ftl` | Bestätigung einer geänderten E-Mail-Adresse |
| `email-test.ftl` | SMTP-Testmail aus der Admin-Konsole |

Alle übrigen Mails (`event-*.ftl`, `identity-provider-link.ftl`, `org-invite.ftl` …) erbt
das Theme von `parent=base`. Sie laufen durch denselben CVO-Rahmen, weil sie
`<@layout.emailLayout>` aus `email/html/template.ftl` importieren – nur die Texte stammen
dann aus dem Keycloak-Standardbundle. Bei Bedarf einfach eine gleichnamige Datei in
`email/html/` + `email/text/` anlegen.

### Designregeln für die Mail-Templates

E-Mail-Clients (v. a. Outlook) können kein externes CSS, kein Flexbox und keine
CSS-Variablen. Deshalb:

* Tabellen-Layout mit festen 480 px (`max-width:100%` für Mobile),
* ausschließlich **Inline-Styles**, Farben als `<#assign>`-Konstanten in `template.ftl`,
* Buttons als Tabelle mit `bgcolor` + verlinktem `display:block`-`<a>`,
* zusätzlich immer der rohe Link als Fallback (`<@layout.linkFallback>`),
* kein Logo-Bild: E-Mail-Clients blockieren externe Bilder standardmäßig, und das
  Theme-`resources/`-Verzeichnis ist aus einer Mail heraus nicht zuverlässig erreichbar.
  Der Kopfbereich ist deshalb eine Typo-Wortmarke in CVO-Blau.
* `<#ftl output_format="HTML">` in allen HTML-Templates → FreeMarker escaped
  Links und Benutzereingaben automatisch (`&` → `&amp;`).
* Zu jedem HTML-Template gehört eine Plaintext-Variante in `email/text/`.

### Lokal rendern / Vorschau

Ohne Keycloak-Start lassen sich die Templates mit FreeMarker gegen Testdaten rendern –
das ist der schnellste Weg, Syntax- und Platzhalterfehler zu finden:

```bash
curl -sO https://repo1.maven.org/maven2/org/freemarker/freemarker/2.3.34/freemarker-2.3.34.jar
# kleines Render-Harness (Model: link, linkExpiration, realmName, user, requiredActions, msg)
java -cp freemarker-2.3.34.jar Render.java cvo/email de
```

Alternativ direkt im Cluster: Passwort-Reset in der Account-Konsole auslösen.


Ohne laufenden Keycloak lassen sich alle Mails gegen Testdaten rendern – der
schnellste Weg, Layout-, Syntax- und Platzhalterfehler zu finden:

```bash
./hack/keycloak-mail-preview/preview.sh            # DE + EN, öffnet die Galerie im Browser
./hack/keycloak-mail-preview/preview.sh --no-open  # nur rendern, Exit-Code != 0 bei Fehlern
./hack/keycloak-mail-preview/preview.sh de         # nur eine Sprache
```

Das Skript lädt FreeMarker einmalig nach `~/.cache/keycloak-mail-preview/`, rendert
HTML- **und** Text-Variante je Sprache nach `hack/keycloak-mail-preview/.preview/`
(gitignored) und baut eine `index.html` mit Umschaltern für Mail, Sprache, Format und
Desktop-/Mobilbreite. Testdaten (Link, Ablaufzeit, Realm, User, Required Actions) stehen
in `hack/keycloak-mail-preview/Render.java` → `model(...)`.

Fehlende Message-Keys erscheinen in der Vorschau als `??keyName??`, statt still
leer zu bleiben.

Echte Zustellung testen: **Realm Settings → Email → Test connection** (rendert
`email-test.ftl`) oder einen Passwort-Reset in der Account-Konsole auslösen.

## Getestete Keycloak-Versionen

- Keycloak 21.x
- Keycloak 22.x
- Keycloak 23.x / 24.x (Quarkus-basiert)

> **Hinweis:** Ab Keycloak 23+ wird für Production-Deployments `kc.sh build` benötigt, bevor Theme-Änderungen aktiv werden. Im Dev-Modus (`--optimized` deaktiviert) werden Themes automatisch neu geladen.
