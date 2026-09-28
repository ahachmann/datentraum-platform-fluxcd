import freemarker.template.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.text.MessageFormat;
import java.util.*;

/**
 * Rendert die Keycloak-E-Mail-Templates des cvo-Themes gegen Testdaten und
 * schreibt eine Vorschau-Galerie (index.html) daneben.
 *
 * Aufruf (siehe preview.sh):
 *   java -cp freemarker.jar Render.java <theme-email-dir> <out-dir> <locale>...
 */
public class Render {

    public static void main(String[] args) throws Exception {
        File themeDir = new File(args[0]);
        File outDir = new File(args[1]);
        String[] locales = Arrays.copyOfRange(args, 2, args.length);

        List<String> mails = new ArrayList<>();
        boolean failed = false;

        for (String locale : locales) {
            Properties msgs = loadMessages(new File(themeDir, "messages/messages_" + locale + ".properties"));
            File localeOut = new File(outDir, locale);
            localeOut.mkdirs();

            for (String dir : new String[]{"html", "text"}) {
                File srcDir = new File(themeDir, dir);
                if (!srcDir.isDirectory()) continue;

                Configuration cfg = new Configuration(Configuration.VERSION_2_3_34);
                cfg.setDirectoryForTemplateLoading(srcDir);
                cfg.setDefaultEncoding("UTF-8");
                cfg.setLocale(Locale.forLanguageTag(locale));
                cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);

                File[] files = srcDir.listFiles((d, n) -> n.endsWith(".ftl") && !n.equals("template.ftl"));
                Arrays.sort(files);

                for (File f : files) {
                    String name = f.getName().replace(".ftl", "");
                    if (dir.equals("html") && !mails.contains(name)) mails.add(name);

                    StringWriter out = new StringWriter();
                    try {
                        cfg.getTemplate(f.getName()).process(model(name, msgs), out);
                    } catch (Exception e) {
                        failed = true;
                        System.out.println("  FAIL  " + locale + "/" + dir + "/" + f.getName());
                        System.out.println("        " + e.getMessage().replace("\n", "\n        "));
                        continue;
                    }
                    String ext = dir.equals("html") ? ".html" : ".txt";
                    write(new File(localeOut, dir + "-" + name + ext), out.toString());
                    System.out.println("  ok    " + locale + "/" + dir + "/" + f.getName());
                }
            }
        }

        // password-reset ist die häufigste Mail -> als erstes in der Galerie
        if (mails.remove("password-reset")) mails.add(0, "password-reset");

        write(new File(outDir, "index.html"), index(mails, Arrays.asList(locales)));
        System.out.println(failed ? "\nMit Fehlern beendet." : "\nAlle Templates gerendert.");
        if (failed) System.exit(1);
    }

    // ── Testdaten ────────────────────────────────────────────────────────────
    private static Map<String, Object> model(String mail, Properties msgs) {
        Map<String, Object> m = new HashMap<>();
        m.put("realmName", "CVO Elternrat");
        m.put("link", "https://iam.cvo-elternrat.de/realms/cvo/login-actions/action-token"
                + "?key=eyJhbGciOiJIUzUxMiJ9.DEMO-TOKEN&client_id=account-console");
        m.put("linkExpiration", 30);
        m.put("newEmail", "neue.adresse@cvo-elternrat.de");
        m.put("requiredActions", Arrays.asList("UPDATE_PASSWORD", "VERIFY_EMAIL"));

        // email-test wird von Keycloak ohne User-Kontext verschickt
        if (!mail.startsWith("email-test")) {
            Map<String, Object> user = new HashMap<>();
            user.put("firstName", "Anna");
            user.put("lastName", "Beispiel");
            user.put("email", "anna.beispiel@cvo-elternrat.de");
            user.put("username", "abeispiel");
            m.put("user", user);
        }

        m.put("msg", (TemplateMethodModelEx) list -> {
            String key = list.get(0).toString();
            String pattern = msgs.getProperty(key);
            if (pattern == null) return "??" + key + "??";   // fällt in der Vorschau auf
            if (list.size() == 1) return pattern;
            Object[] params = new Object[list.size() - 1];
            for (int i = 1; i < list.size(); i++) params[i - 1] = list.get(i).toString();
            return new MessageFormat(pattern).format(params);
        });
        m.put("linkExpirationFormatter", (TemplateMethodModelEx) list -> {
            int v = Integer.parseInt(list.get(0).toString());
            String key = "linkExpirationFormatter.timePeriodUnit.minutes" + (v == 1 ? ".1" : "");
            return v + " " + msgs.getProperty(key, "minutes");
        });
        m.put("properties", new HashMap<String, String>());
        return m;
    }

    private static Properties loadMessages(File f) throws IOException {
        Properties p = new Properties();
        try (Reader r = new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8)) {
            p.load(r);
        }
        return p;
    }

    private static void write(File f, String s) throws IOException {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(f), StandardCharsets.UTF_8)) {
            w.write(s);
        }
    }

    // ── Galerie ──────────────────────────────────────────────────────────────
    private static String index(List<String> mails, List<String> locales) {
        StringBuilder nav = new StringBuilder();
        for (int i = 0; i < mails.size(); i++) {
            nav.append("<button class=\"mail").append(i == 0 ? " active" : "")
               .append("\" data-mail=\"").append(mails.get(i)).append("\">")
               .append(mails.get(i)).append("</button>\n");
        }
        StringBuilder loc = new StringBuilder();
        for (int i = 0; i < locales.size(); i++) {
            loc.append("<button class=\"opt locale").append(i == 0 ? " active" : "")
               .append("\" data-value=\"").append(locales.get(i)).append("\">")
               .append(locales.get(i).toUpperCase()).append("</button>");
        }
        return TEMPLATE
                .replace("{{NAV}}", nav.toString())
                .replace("{{LOCALES}}", loc.toString())
                .replace("{{FIRST}}", mails.isEmpty() ? "" : mails.get(0));
    }

    private static final String TEMPLATE = String.join("\n",
    "<!DOCTYPE html>",
    "<html lang=\"de\"><head><meta charset=\"utf-8\">",
    "<title>CVO Keycloak - Mail-Vorschau</title>",
    "<style>",
    "  :root { --bg:#eef0f3; --panel:#fff; --line:#d5d9de; --blue:#1e4b74; --muted:#6b7280; }",
    "  * { box-sizing:border-box; }",
    "  body { margin:0; font:14px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;",
    "         background:var(--bg); color:#111827; display:grid; grid-template-columns:240px 1fr; height:100vh; }",
    "  aside { background:var(--panel); border-right:1px solid var(--line); padding:20px 14px; overflow:auto; }",
    "  aside h1 { font-size:13px; color:var(--blue); margin:0 0 4px; }",
    "  aside p { font-size:11px; color:var(--muted); margin:0 0 18px; }",
    "  button.mail { display:block; width:100%; text-align:left; background:none; border:0; padding:8px 10px;",
    "                border-radius:7px; font:inherit; font-size:13px; color:#374151; cursor:pointer; }",
    "  button.mail:hover { background:#f3f4f6; }",
    "  button.mail.active { background:var(--blue); color:#fff; }",
    "  main { display:flex; flex-direction:column; min-width:0; }",
    "  header { display:flex; gap:18px; align-items:center; padding:14px 20px; border-bottom:1px solid var(--line);",
    "           background:var(--panel); flex-wrap:wrap; }",
    "  .group { display:flex; gap:4px; background:#f3f4f6; padding:3px; border-radius:8px; }",
    "  .opt { border:0; background:none; padding:5px 12px; border-radius:6px; font:inherit; font-size:12px;",
    "         color:var(--muted); cursor:pointer; }",
    "  .opt.active { background:#fff; color:var(--blue); font-weight:500; box-shadow:0 1px 2px rgba(0,0,0,.08); }",
    "  .label { font-size:11px; color:var(--muted); text-transform:uppercase; letter-spacing:.06em; }",
    "  .stage { flex:1; overflow:auto; padding:28px; display:flex; justify-content:center; }",
    "  iframe { width:640px; max-width:100%; height:100%; min-height:600px; border:1px solid var(--line);",
    "           border-radius:10px; background:#fff; transition:width .15s; }",
    "  iframe.mobile { width:390px; }",
    "</style></head><body>",
    "<aside>",
    "  <h1>CVO Mail-Vorschau</h1>",
    "  <p>Gerendert aus cvo/email mit Testdaten</p>",
    "  {{NAV}}",
    "</aside>",
    "<main>",
    "  <header>",
    "    <span class=\"label\">Sprache</span>",
    "    <div class=\"group\" id=\"locales\">{{LOCALES}}</div>",
    "    <span class=\"label\">Format</span>",
    "    <div class=\"group\" id=\"formats\">",
    "      <button class=\"opt active\" data-value=\"html\">HTML</button>",
    "      <button class=\"opt\" data-value=\"text\">Text</button>",
    "    </div>",
    "    <span class=\"label\">Breite</span>",
    "    <div class=\"group\" id=\"widths\">",
    "      <button class=\"opt active\" data-value=\"desktop\">Desktop</button>",
    "      <button class=\"opt\" data-value=\"mobile\">Mobil</button>",
    "    </div>",
    "  </header>",
    "  <div class=\"stage\"><iframe id=\"frame\"></iframe></div>",
    "</main>",
    "<script>",
    "  let mail='{{FIRST}}', locale=document.querySelector('.locale').dataset.value, format='html';",
    "  const frame=document.getElementById('frame');",
    "  function show(){",
    "    const ext = format==='html' ? '.html' : '.txt';",
    "    frame.src = locale + '/' + format + '-' + mail + ext;",
    "  }",
    "  function pick(container, cb){",
    "    container.addEventListener('click', e => {",
    "      if(!e.target.dataset.value) return;",
    "      [...container.children].forEach(b => b.classList.remove('active'));",
    "      e.target.classList.add('active'); cb(e.target.dataset.value); show();",
    "    });",
    "  }",
    "  pick(document.getElementById('locales'), v => locale=v);",
    "  pick(document.getElementById('formats'), v => format=v);",
    "  document.getElementById('widths').addEventListener('click', e => {",
    "    if(!e.target.dataset.value) return;",
    "    [...e.target.parentNode.children].forEach(b => b.classList.remove('active'));",
    "    e.target.classList.add('active');",
    "    frame.classList.toggle('mobile', e.target.dataset.value==='mobile');",
    "  });",
    "  document.querySelectorAll('button.mail').forEach(b => b.addEventListener('click', () => {",
    "    document.querySelectorAll('button.mail').forEach(x => x.classList.remove('active'));",
    "    b.classList.add('active'); mail=b.dataset.mail; show();",
    "  }));",
    "  show();",
    "</script></body></html>");
}
