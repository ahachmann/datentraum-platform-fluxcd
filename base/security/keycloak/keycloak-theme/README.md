# CVO Keycloak Theme

Custom Keycloak login theme für das **Carl von Ossietzky Gymnasium Poppenbüttel**.

## Verzeichnisstruktur

```
cvo/
└── login/
    ├── theme.properties          # Theme-Konfiguration
    ├── login.ftl                 # Haupt-Login-Template
    ├── template.ftl              # HTML-Layout-Wrapper
    ├── messages/
    │   ├── messages_de.properties
    │   └── messages_en.properties
    └── resources/
        ├── css/
        │   └── login.css         # CVO Branding (Farben, Layout)
        └── img/
            └── logo.jpg          # CVO Logo
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
| Farben | `resources/css/login.css` → CSS-Variablen in `:root {}` |
| Logo | `resources/img/logo.jpg` ersetzen |
| Texte (DE) | `messages/messages_de.properties` |
| Texte (EN) | `messages/messages_en.properties` |
| Layout / Felder | `login.ftl` |

## Getestete Keycloak-Versionen

- Keycloak 21.x
- Keycloak 22.x
- Keycloak 23.x / 24.x (Quarkus-basiert)

> **Hinweis:** Ab Keycloak 23+ wird für Production-Deployments `kc.sh build` benötigt, bevor Theme-Änderungen aktiv werden. Im Dev-Modus (`--optimized` deaktiviert) werden Themes automatisch neu geladen.
