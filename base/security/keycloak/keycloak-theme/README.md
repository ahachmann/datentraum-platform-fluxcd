# CVO Keycloak Theme

Custom Keycloak Login- und E-Mail-Theme für das **Carl von Ossietzky Gymnasium Poppenbüttel**.

## Verzeichnisstruktur

```
cvo/
├── login/
│   ├── theme.properties          # parent=keycloak, styles, kc*Class-Overrides
│   ├── template.ftl              # gemeinsamer Rahmen: Karte, Logo, Titel, Meldung, Footer
│   ├── login.ftl                 # Anmeldung
│   ├── login-reset-password.ftl  # Passwort vergessen
│   ├── login-update-password.ftl # Neues Passwort vergeben
│   ├── login-verify-email.ftl    # E-Mail-Adresse bestätigen
│   ├── login-page-expired.ftl    # Seite abgelaufen
│   ├── info.ftl                  # generische Infoseite
│   ├── error.ftl                 # Fehlerseite
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
| Layout Login (alle Seiten) | `login/template.ftl` |
| Felder der Anmeldeseite | `login/login.ftl` |
| Farben (E-Mail) | `email/html/template.ftl` → `<#assign cvo... >` am Dateianfang |
| Texte E-Mail (DE/EN) | `email/messages/messages_{de,en}.properties` |
| Layout E-Mail | `email/html/template.ftl` (Makros `emailLayout`, `button`, `p`, `muted`, `divider`, `linkFallback`) |
| Neue Sprache | `messages_XX.properties` in `login/messages/` bzw. `email/messages/` anlegen **und** in `kustomization.yaml` als ConfigMap-Datei eintragen |

---

## Login-Theme

### Seitenaufbau

`template.ftl` ist der gemeinsame Rahmen aller Anmeldeseiten: Karte, Logo,
Seitentitel, Meldungsblock und Footer. Die einzelnen Seiten liefern nur ihren
Inhalt über die Abschnitte `header`, `form` und `info`.

Überschrieben und gebrandet sind:

| Datei | Seite |
|---|---|
| `login.ftl` | Anmeldung |
| `login-reset-password.ftl` | Passwort vergessen |
| `login-update-password.ftl` | Neues Passwort vergeben |
| `login-verify-email.ftl` | E-Mail-Adresse bestätigen |
| `login-page-expired.ftl` | Seite abgelaufen |
| `info.ftl` | generische Infoseite („E-Mail wurde gesendet") |
| `error.ftl` | Fehlerseite |

Alles andere (OTP, Passkey, Recovery-Codes, Profil vervollständigen,
Nutzungsbedingungen, Auswahl des zweiten Faktors) kommt aus dem Elternthema.

### parent=keycloak, nicht base

`theme.properties` hat bewusst `parent=keycloak`. Das Elternthema liefert die
`kc*Class`-Properties (`kcInputClass=pf-c-form-control`, `kcButtonClass=pf-c-button` …).
Mit `parent=base` wären diese Properties leer, und jede nicht überschriebene Seite
käme mit `class=""` im Markup – also komplett ungestylt. `login.css` bedient die
PatternFly-Klassennamen deshalb direkt (`.card-pf`, `.pf-c-form-control`,
`.pf-c-button.pf-m-primary`, `.btn-default` …).

Das PatternFly-**CSS** wird trotzdem nicht geladen: `template.ftl` rendert nur
`properties.styles`, nicht `stylesCommon`. Die geerbten Seiten bleiben damit in
der CVO-Formensprache statt im Keycloak-Standardlook.

`meta=` steht absichtlich leer in `theme.properties` – das Elternthema setzt dort
ein viewport-Meta, das `template.ftl` ohnehin selbst ausgibt.

### Texte

Message-Keys werden über die Kette cvo → keycloak → base aufgelöst; `messages_de.properties`
überschreibt nur, was abweichen soll. Das betrifft vor allem die Anrede: Keycloaks
deutsche Standardtexte siezen, das CVO-Theme duzt durchgängig.

> **Achtung bei HTML-Entities:** Templates laufen mit aktivem Auto-Escaping. Ein
> `&laquo;` in einer Properties-Datei erscheint als Text „&laquo;" auf der Seite –
> deshalb stehen echte Zeichen (`«`, `»`, `–`) in den Messages.

### Lokal rendern / Vorschau

```bash
./hack/keycloak-login-preview/preview.sh            # DE + EN, öffnet die Galerie im Browser
./hack/keycloak-login-preview/preview.sh --no-open  # nur rendern, Exit-Code != 0 bei Fehlern
./hack/keycloak-login-preview/preview.sh de         # nur eine Sprache
```

Rendert alle überschriebenen Seiten in Zuständen, die man sonst nur mit Mühe im
laufenden Keycloak provoziert – 21 Kombinationen je Sprache:

| Seite | Szenarien |
|---|---|
| Anmeldung | Standard · die vier Alert-Stile · vorausgefüllt · E-Mail als Benutzername · Realm ohne Self-Service |
| Passwort vergessen | Standard · Feldfehler · Realm ohne E-Mail-Login |
| Neues Passwort | Standard · Feldfehler (Bestätigung weicht ab) · aus der Account-Konsole (mit Abbrechen) |
| E-Mail bestätigen | Standard · aus der Account-Konsole |
| Infoseite | „E-Mail gesendet" · mit offenen Required Actions |
| Fehlerseite | Standard · mit Trace-ID |
| Seite abgelaufen | Standard |

Umschalter für Sprache und Viewport (Desktop / Tablet / Mobil) – letzteres trifft
den `@media (max-width: 480px)`-Breakpoint in `login.css`. `resources/` wird in die
Vorschau kopiert, Logo und CSS sind also echt.

Das Tool bildet die Theme-Kette nach: es lädt `keycloak-themes-<version>.jar` von
Maven Central nach `~/.cache/keycloak-mail-preview/` und löst Templates,
`theme.properties` und Messages in der Reihenfolge cvo → keycloak → base auf.
Ein `<#import>` auf eine geerbte Datei funktioniert damit genauso wie im Server.
Die Keycloak-Version steuert `KEYCLOAK_VERSION` (Default: passend zum StatefulSet).

FreeMarker läuft exakt wie in Keycloaks `DefaultFreeMarkerProvider`
(`HTMLOutputFormat`, `VERSION_2_3_32`), damit das Auto-Escaping dem Server entspricht.
Testdaten und Szenarien stehen in `hack/keycloak-login-preview/Render.java` →
`PAGES` und `model(...)`; `MessagesPerField` ist dort als Mock von Keycloaks
`MessagesPerFieldBean` nachgebaut.

Fehlende Message-Keys erscheinen als `??keyName??` statt still leer zu bleiben.

### Grenze der Vorschau

Die nicht überschriebenen Seiten (OTP, Passkey, Profil vervollständigen …) rendert
das Tool nicht. Sie hängen am User-Profile-Framework und an Beans, deren Mock mehr
verspräche als er halten kann. Ansehen lassen sie sich in einem Wegwerf-Keycloak
mit gemountetem Theme:

```bash
podman run --rm -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -v "$PWD/base/security/keycloak/keycloak-theme/cvo:/opt/keycloak/themes/cvo:ro,z" \
  quay.io/keycloak/keycloak:26.7.2 start-dev
```

Dann auf `http://localhost:8080` → Realm anlegen → Realm settings → Themes →
Login theme `cvo`. Im `start-dev`-Modus lädt Keycloak Theme-Änderungen ohne
Neustart nach, ein Reload im Browser genügt.

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
