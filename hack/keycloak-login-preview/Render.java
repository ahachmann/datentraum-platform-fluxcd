import freemarker.cache.FileTemplateLoader;
import freemarker.cache.MultiTemplateLoader;
import freemarker.cache.TemplateLoader;
import freemarker.core.HTMLOutputFormat;
import freemarker.template.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.text.MessageFormat;
import java.util.*;
import java.util.function.Consumer;

/**
 * Rendert die Keycloak-Login-Templates des cvo-Themes gegen Testdaten und
 * schreibt eine Vorschau-Galerie (index.html) daneben.
 *
 * Die Theme-Kette wird nachgebildet: Templates, theme.properties und Messages
 * werden in der Reihenfolge cvo -> keycloak -> base aufgelöst, genau wie im
 * Server. FreeMarker läuft mit derselben Konfiguration wie in Keycloaks
 * DefaultFreeMarkerProvider (HTMLOutputFormat, VERSION_2_3_32).
 *
 * Aufruf (siehe preview.sh):
 *   java -cp freemarker.jar Render.java <cvo-login-dir> <base-themes-dir> <out-dir> <locale>...
 */
public class Render {

    record Scenario(String id, String label, Consumer<Map<String, Object>> tweak) {}
    record Page(String template, String label, List<Scenario> scenarios) {}

    static final Scenario STANDARD = new Scenario("standard", "Standard", m -> {});

    static final List<Page> PAGES = List.of(
        new Page("login.ftl", "Anmeldung", List.of(
            STANDARD,
            new Scenario("fehler", "Fehlermeldung", m ->
                m.put("message", message("error", "Ungültiger Benutzername oder ungültiges Passwort."))),
            new Scenario("warnung", "Warnung", m ->
                m.put("message", message("warning", "Dein Passwort läuft in 3 Tagen ab."))),
            new Scenario("erfolg", "Erfolgsmeldung", m ->
                m.put("message", message("success", "Dein Passwort wurde aktualisiert."))),
            new Scenario("info", "Info-Hinweis", m ->
                m.put("message", message("info", "Bitte melde dich an, um fortzufahren."))),
            new Scenario("ausgefuellt", "Vorausgefüllt", m ->
                m.put("login", map("username", "anna.beispiel", "rememberMe", true))),
            new Scenario("email-login", "E-Mail als Benutzername", m ->
                realmOf(m).put("registrationEmailAsUsername", true)),
            new Scenario("ohne-selfservice", "Ohne Self-Service", m -> {
                realmOf(m).put("rememberMe", false);
                realmOf(m).put("resetPasswordAllowed", false);
            }))),

        new Page("login-reset-password.ftl", "Passwort vergessen", List.of(
            STANDARD,
            new Scenario("feldfehler", "Feldfehler", m ->
                m.put("messagesPerField", new MessagesPerField(
                    Map.of("username", "Ungültiger Benutzername oder ungültige E-Mail-Adresse.")))),
            new Scenario("nur-benutzername", "Nur Benutzername", m ->
                realmOf(m).put("loginWithEmailAllowed", false)))),

        new Page("login-update-password.ftl", "Neues Passwort", List.of(
            STANDARD,
            new Scenario("feldfehler", "Feldfehler", m ->
                m.put("messagesPerField", new MessagesPerField(
                    Map.of("password-confirm", "Die Passwortbestätigung ist nicht identisch.")))),
            new Scenario("aia", "Aus der Account-Konsole", m ->
                m.put("isAppInitiatedAction", true)))),

        new Page("login-verify-email.ftl", "E-Mail bestätigen", List.of(
            STANDARD,
            new Scenario("aia", "Aus der Account-Konsole", m -> {
                m.put("isAppInitiatedAction", true);
                m.remove("verifyEmail");
            }))),

        new Page("info.ftl", "Infoseite", List.of(
            new Scenario("standard", "E-Mail gesendet", m ->
                m.put("message", message("info",
                    "Du erhältst in Kürze eine E-Mail mit weiteren Anweisungen."))),
            new Scenario("required-actions", "Offene Aktionen", m -> {
                m.put("message", message("info", "Folgende Schritte sind noch offen"));
                m.put("requiredActions", List.of("UPDATE_PASSWORD", "VERIFY_EMAIL"));
            }))),

        new Page("error.ftl", "Fehlerseite", List.of(
            new Scenario("standard", "Standard", m ->
                m.put("message", message("error",
                    "Wir konnten deine Anfrage nicht verarbeiten. Bitte versuche es erneut."))),
            new Scenario("trace-id", "Mit Trace-ID", m -> {
                m.put("message", message("error", "Unerwarteter Fehler beim Anmelden."));
                m.put("traceId", "a1b2c3d4e5f60718");
            }))),

        new Page("login-page-expired.ftl", "Seite abgelaufen", List.of(STANDARD))
    );

    public static void main(String[] args) throws Exception {
        File cvoDir = new File(args[0]);       // cvo/login
        File themesDir = new File(args[1]);    // entpacktes theme/ aus keycloak-themes.jar
        File outDir = new File(args[2]);
        String[] locales = Arrays.copyOfRange(args, 3, args.length);

        File kcLogin = new File(themesDir, "keycloak/login");
        File baseLogin = new File(themesDir, "base/login");

        // theme.properties der Kette überlagern: base -> keycloak -> cvo
        Properties themeProps = new Properties();
        themeProps.putAll(load(new File(baseLogin, "theme.properties")));
        themeProps.putAll(load(new File(kcLogin, "theme.properties")));
        themeProps.putAll(load(new File(cvoDir, "theme.properties")));

        copyTree(new File(cvoDir, "resources"), new File(outDir, "resources"));

        boolean failed = false;
        for (String locale : locales) {
            Properties msgs = new Properties();
            msgs.putAll(load(new File(baseLogin, "messages/messages_" + locale + ".properties")));
            msgs.putAll(load(new File(kcLogin, "messages/messages_" + locale + ".properties")));
            msgs.putAll(load(new File(cvoDir, "messages/messages_" + locale + ".properties")));

            File localeOut = new File(outDir, locale);
            localeOut.mkdirs();

            Configuration cfg = new Configuration(Configuration.VERSION_2_3_32);
            cfg.setOutputFormat(HTMLOutputFormat.INSTANCE);
            cfg.setTemplateLoader(chain(cvoDir, kcLogin, baseLogin));
            cfg.setDefaultEncoding("UTF-8");
            cfg.setLocale(Locale.forLanguageTag(locale));
            cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);

            for (Page page : PAGES) {
                if (!new File(cvoDir, page.template()).isFile()) {
                    System.out.println("  SKIP  " + page.template() + " (nicht im cvo-Theme)");
                    continue;
                }
                String name = page.template().replace(".ftl", "");
                for (Scenario sc : page.scenarios()) {
                    Map<String, Object> model = model(themeProps, msgs);
                    sc.tweak().accept(model);

                    StringWriter out = new StringWriter();
                    try {
                        cfg.getTemplate(page.template()).process(model, out);
                    } catch (Exception e) {
                        failed = true;
                        System.out.println("  FAIL  " + locale + "/" + name + "/" + sc.id());
                        System.out.println("        " + e.getMessage().replace("\n", "\n        "));
                        continue;
                    }
                    write(new File(localeOut, name + "-" + sc.id() + ".html"), out.toString());
                    System.out.println("  ok    " + locale + "/" + name + "/" + sc.id());
                }
            }
        }

        write(new File(outDir, "index.html"), index(Arrays.asList(locales)));
        System.out.println(failed ? "\nMit Fehlern beendet." : "\nAlle Templates gerendert.");
        if (failed) System.exit(1);
    }

    static TemplateLoader chain(File... dirs) throws IOException {
        List<TemplateLoader> loaders = new ArrayList<>();
        for (File d : dirs) if (d.isDirectory()) loaders.add(new FileTemplateLoader(d));
        return new MultiTemplateLoader(loaders.toArray(new TemplateLoader[0]));
    }

    // ── Testdaten ────────────────────────────────────────────────────────────

    static Map<String, Object> model(Properties themeProps, Properties msgs) {
        Map<String, Object> m = new HashMap<>();

        Map<String, Object> url = new HashMap<>();
        url.put("resourcesPath", "../resources");      // relativ zu <out>/<locale>/
        url.put("resourcesCommonPath", "../resources");
        url.put("loginAction", "#");
        url.put("loginUrl", "#");
        url.put("loginResetCredentialsUrl", "#");
        url.put("loginRestartFlowUrl", "#");
        url.put("registrationUrl", "#");
        m.put("url", url);

        m.put("realm", realm());
        m.put("properties", toMap(themeProps));
        m.put("login", new HashMap<String, Object>());
        m.put("auth", map("selectedCredential", "", "attemptedUsername", "anna.beispiel"));
        m.put("social", map("displayInfo", false));
        m.put("client", map("name", "Account Console", "baseUrl", "#"));
        m.put("user", map("email", "anna.beispiel@cvo-elternrat.de",
                          "firstName", "Anna", "lastName", "Beispiel"));
        m.put("verifyEmail", "anna.beispiel@cvo-elternrat.de");
        m.put("messagesPerField", new MessagesPerField(Map.of()));
        m.put("pageRedirectUri", "");
        m.put("actionUri", "");
        // message / isAppInitiatedAction / requiredActions / traceId / skipLink /
        // messageHeader / usernameEditDisabled bleiben ungesetzt - die Templates
        // prüfen mit ?? bzw. ?has_content darauf.

        m.put("msg", (TemplateMethodModelEx) list -> {
            String key = list.get(0).toString();
            String pattern = msgs.getProperty(key);
            if (pattern == null) return "??" + key + "??";   // fällt in der Vorschau auf
            if (list.size() == 1) return pattern;
            Object[] params = new Object[list.size() - 1];
            for (int i = 1; i < list.size(); i++) params[i - 1] = list.get(i).toString();
            return new MessageFormat(pattern).format(params);
        });
        m.put("advancedMsg", m.get("msg"));
        // Das echte kcSanitize entfernt gefährliches HTML; für die Vorschau reicht
        // die Identität - die Testtexte sind ohnehin harmlos.
        m.put("kcSanitize", (TemplateMethodModelEx) list -> list.get(0).toString());
        return m;
    }

    static Map<String, Object> realm() {
        Map<String, Object> r = new HashMap<>();
        r.put("displayName", "CVO Elternrat");
        r.put("displayNameHtml", "CVO Elternrat");
        r.put("name", "cvo");
        r.put("password", true);
        r.put("loginWithEmailAllowed", true);
        r.put("registrationEmailAsUsername", false);
        r.put("duplicateEmailsAllowed", false);
        r.put("rememberMe", true);
        r.put("resetPasswordAllowed", true);
        r.put("registrationAllowed", false);
        r.put("internationalizationEnabled", true);
        return r;
    }

    @SuppressWarnings("unchecked")
    static Map<String, Object> realmOf(Map<String, Object> model) {
        return (Map<String, Object>) model.get("realm");
    }

    static Map<String, Object> message(String type, String summary) {
        return map("type", type, "summary", summary);
    }

    static Map<String, Object> map(Object... kv) {
        Map<String, Object> m = new HashMap<>();
        for (int i = 0; i < kv.length; i += 2) m.put((String) kv[i], kv[i + 1]);
        return m;
    }

    /** Nachbau von org.keycloak.forms.login.freemarker.model.MessagesPerFieldBean. */
    public static class MessagesPerField {
        private final Map<String, String> errors;

        public MessagesPerField(Map<String, String> errors) {
            this.errors = errors;
        }

        public boolean existsError(String... fields) {
            for (String f : fields) if (errors.containsKey(f)) return true;
            return false;
        }

        public boolean exists(String field) {
            return errors.containsKey(field);
        }

        public String get(String field) {
            return errors.getOrDefault(field, "");
        }

        public String getFirstError(String... fields) {
            for (String f : fields) if (errors.containsKey(f)) return errors.get(f);
            return "";
        }

        public String printIfExists(String field, String text) {
            return errors.containsKey(field) ? text : "";
        }
    }

    // ── Hilfsmittel ──────────────────────────────────────────────────────────

    static Properties load(File f) throws IOException {
        Properties p = new Properties();
        if (!f.isFile()) return p;
        try (Reader r = new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8)) {
            p.load(r);
        }
        return p;
    }

    static Map<String, Object> toMap(Properties p) {
        Map<String, Object> m = new HashMap<>();
        for (String k : p.stringPropertyNames()) m.put(k, p.getProperty(k));
        return m;
    }

    static void copyTree(File src, File dst) throws IOException {
        if (!src.isDirectory()) return;
        Path from = src.toPath(), to = dst.toPath();
        try (var walk = Files.walk(from)) {
            for (Path p : (Iterable<Path>) walk::iterator) {
                Path target = to.resolve(from.relativize(p));
                if (Files.isDirectory(p)) Files.createDirectories(target);
                else {
                    Files.createDirectories(target.getParent());
                    Files.copy(p, target, StandardCopyOption.REPLACE_EXISTING);
                }
            }
        }
    }

    static void write(File f, String s) throws IOException {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(f), StandardCharsets.UTF_8)) {
            w.write(s);
        }
    }

    // ── Galerie ──────────────────────────────────────────────────────────────

    static String index(List<String> locales) {
        StringBuilder nav = new StringBuilder();
        boolean first = true;
        for (Page page : PAGES) {
            nav.append("<div class=\"grp\">").append(page.label()).append("</div>\n");
            for (Scenario sc : page.scenarios()) {
                String file = page.template().replace(".ftl", "") + "-" + sc.id();
                nav.append("<button class=\"pg").append(first ? " active" : "")
                   .append("\" data-file=\"").append(file).append("\">")
                   .append(sc.label()).append("</button>\n");
                first = false;
            }
        }
        StringBuilder loc = new StringBuilder();
        for (int i = 0; i < locales.size(); i++) {
            loc.append("<button class=\"opt locale").append(i == 0 ? " active" : "")
               .append("\" data-value=\"").append(locales.get(i)).append("\">")
               .append(locales.get(i).toUpperCase()).append("</button>");
        }
        String firstFile = PAGES.get(0).template().replace(".ftl", "") + "-"
                         + PAGES.get(0).scenarios().get(0).id();
        return TEMPLATE.replace("{{NAV}}", nav).replace("{{LOCALES}}", loc)
                       .replace("{{FIRST}}", firstFile);
    }

    static final String TEMPLATE = String.join("\n",
    "<!DOCTYPE html>",
    "<html lang=\"de\"><head><meta charset=\"utf-8\">",
    "<title>CVO Keycloak - Login-Vorschau</title>",
    "<style>",
    "  :root { --bg:#eef0f3; --panel:#fff; --line:#d5d9de; --blue:#1e4b74; --muted:#6b7280; }",
    "  * { box-sizing:border-box; }",
    "  body { margin:0; font:14px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;",
    "         background:var(--bg); color:#111827; display:grid; grid-template-columns:250px 1fr; height:100vh; }",
    "  aside { background:var(--panel); border-right:1px solid var(--line); padding:20px 14px; overflow:auto; }",
    "  aside h1 { font-size:13px; color:var(--blue); margin:0 0 4px; }",
    "  aside p { font-size:11px; color:var(--muted); margin:0 0 18px; }",
    "  .grp { font-size:10px; text-transform:uppercase; letter-spacing:.07em; color:var(--muted);",
    "         margin:16px 0 6px 10px; }",
    "  button.pg { display:block; width:100%; text-align:left; background:none; border:0; padding:7px 10px;",
    "              border-radius:7px; font:inherit; font-size:13px; color:#374151; cursor:pointer; }",
    "  button.pg:hover { background:#f3f4f6; }",
    "  button.pg.active { background:var(--blue); color:#fff; }",
    "  main { display:flex; flex-direction:column; min-width:0; }",
    "  header { display:flex; gap:18px; align-items:center; padding:14px 20px; border-bottom:1px solid var(--line);",
    "           background:var(--panel); flex-wrap:wrap; }",
    "  .group { display:flex; gap:4px; background:#f3f4f6; padding:3px; border-radius:8px; }",
    "  .opt { border:0; background:none; padding:5px 12px; border-radius:6px; font:inherit; font-size:12px;",
    "         color:var(--muted); cursor:pointer; }",
    "  .opt.active { background:#fff; color:var(--blue); font-weight:500; box-shadow:0 1px 2px rgba(0,0,0,.08); }",
    "  .label { font-size:11px; color:var(--muted); text-transform:uppercase; letter-spacing:.06em; }",
    "  .stage { flex:1; overflow:auto; padding:24px; display:flex; justify-content:center; }",
    "  iframe { width:100%; max-width:1280px; height:100%; min-height:640px; border:1px solid var(--line);",
    "           border-radius:10px; background:#fff; transition:max-width .15s; }",
    "  iframe.tablet { max-width:768px; }",
    "  iframe.mobile { max-width:390px; }",
    "</style></head><body>",
    "<aside>",
    "  <h1>CVO Login-Vorschau</h1>",
    "  <p>Gerendert aus cvo/login mit Testdaten</p>",
    "  {{NAV}}",
    "</aside>",
    "<main>",
    "  <header>",
    "    <span class=\"label\">Sprache</span>",
    "    <div class=\"group\" id=\"locales\">{{LOCALES}}</div>",
    "    <span class=\"label\">Breite</span>",
    "    <div class=\"group\" id=\"widths\">",
    "      <button class=\"opt active\" data-value=\"desktop\">Desktop</button>",
    "      <button class=\"opt\" data-value=\"tablet\">Tablet</button>",
    "      <button class=\"opt\" data-value=\"mobile\">Mobil</button>",
    "    </div>",
    "    <span class=\"label\" id=\"current\"></span>",
    "  </header>",
    "  <div class=\"stage\"><iframe id=\"frame\"></iframe></div>",
    "</main>",
    "<script>",
    "  let file='{{FIRST}}', locale=document.querySelector('.locale').dataset.value;",
    "  const frame=document.getElementById('frame');",
    "  function show(){",
    "    frame.src = locale + '/' + file + '.html';",
    "    document.getElementById('current').textContent = file;",
    "  }",
    "  function pick(id, cb){",
    "    document.getElementById(id).addEventListener('click', e => {",
    "      if(!e.target.dataset.value) return;",
    "      [...e.target.parentNode.children].forEach(b => b.classList.remove('active'));",
    "      e.target.classList.add('active'); cb(e.target.dataset.value);",
    "    });",
    "  }",
    "  pick('locales', v => { locale=v; show(); });",
    "  pick('widths', v => { frame.className = v==='desktop' ? '' : v; });",
    "  document.querySelectorAll('button.pg').forEach(b => b.addEventListener('click', () => {",
    "    document.querySelectorAll('button.pg').forEach(x => x.classList.remove('active'));",
    "    b.classList.add('active'); file=b.dataset.file; show();",
    "  }));",
    "  show();",
    "</script></body></html>");
}
