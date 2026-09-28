<#ftl output_format="HTML">
<#--
  CVO E-Mail Theme - Carl von Ossietzky Gymnasium
  Layout-Wrapper fuer alle HTML-Mails. Farben/Spacing analog login.css.

  Hinweis: E-Mail-Clients unterstuetzen kein <link>/Flexbox/CSS-Variablen.
  Deshalb tabellenbasiertes Layout mit Inline-Styles.
-->

<#-- Farbpalette (vgl. resources/css/login.css) -->
<#assign cvoBlue        = "#1e4b74">
<#assign cvoBlueDark    = "#163a5c">
<#assign cvoBg          = "#d9dde2">
<#assign cvoWhite       = "#ffffff">
<#assign cvoBorder      = "#b8bec6">
<#assign cvoText        = "#111827">
<#assign cvoTextMuted   = "#6b7280">
<#assign cvoTextSecond  = "#374151">
<#assign cvoFont        = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif">

<#--
  Haupt-Layout.
  Alle Parameter sind optional, damit auch die vom base-Theme geerbten
  Templates (die <@layout.emailLayout> ohne Argumente aufrufen) funktionieren.
-->
<#macro emailLayout title="" preheader="">
<!DOCTYPE html>
<html lang="${.locale?replace("_","-")}" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="x-apple-disable-message-reformatting" />
    <meta name="color-scheme" content="light only" />
    <meta name="supported-color-schemes" content="light only" />
    <title>${title}</title>
</head>
<body style="margin:0; padding:0; background-color:${cvoBg}; color:${cvoText}; font-family:${cvoFont}; font-size:16px; -webkit-font-smoothing:antialiased;">

    <#if preheader?has_content>
    <div style="display:none; font-size:1px; color:${cvoBg}; line-height:1px; max-height:0; max-width:0; opacity:0; overflow:hidden;">
        ${preheader}
    </div>
    </#if>

    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color:${cvoBg}; margin:0; padding:0;">
        <tr>
            <td align="center" style="padding:32px 16px;">

                <!-- Card -->
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="480" style="width:480px; max-width:100%; background:${cvoWhite}; border:1px solid ${cvoBorder}; border-radius:12px; overflow:hidden;">

                    <!-- Kopfbereich -->
                    <tr>
                        <td align="center" style="padding:28px 32px 20px 32px; border-bottom:1px solid #d1d5db;">
                            <div style="font-size:15px; font-weight:500; color:${cvoBlue}; letter-spacing:0.01em; line-height:1.4;">
                                Carl von Ossietzky Gymnasium
                            </div>
                            <#if title?has_content>
                            <div style="font-size:14px; color:${cvoTextMuted}; margin-top:6px; line-height:1.4;">
                                ${title}
                            </div>
                            </#if>
                        </td>
                    </tr>

                    <!-- Inhalt -->
                    <tr>
                        <td style="padding:28px 32px 24px 32px; font-size:14px; line-height:1.6; color:${cvoTextSecond};">
                            <#nested>
                        </td>
                    </tr>

                </table>

                <!-- Footer -->
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="480" style="width:480px; max-width:100%;">
                    <tr>
                        <td align="center" style="padding:20px 16px 0 16px; font-size:11px; line-height:1.6; color:#9ca3af;">
                            ${msg("cvoFooterNotice")}<br />
                            <span style="display:inline-block; margin-top:6px;">
                                <span style="display:inline-block; width:6px; height:6px; border-radius:3px; background:${cvoBlue}; opacity:0.5;">&nbsp;</span>
                                &nbsp;${msg("cvoFooterBadge")}
                            </span>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>
</#macro>

<#-- Anrede -->
<#macro greeting>
<p style="margin:0 0 16px 0; font-size:14px; line-height:1.6; color:${cvoText};">
    <#if user?? && user.firstName?? && user.firstName?has_content>${msg("cvoGreetingName", user.firstName)}<#else>${msg("cvoGreeting")}</#if>
</p>
</#macro>

<#-- Absatz -->
<#macro p>
<p style="margin:0 0 16px 0; font-size:14px; line-height:1.6; color:${cvoTextSecond};"><#nested></p>
</#macro>

<#-- Kleingedrucktes -->
<#macro muted>
<p style="margin:16px 0 0 0; font-size:12px; line-height:1.6; color:${cvoTextMuted};"><#nested></p>
</#macro>

<#-- Trennlinie -->
<#macro divider>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin:20px 0;">
    <tr><td style="border-top:1px solid #d1d5db; font-size:0; line-height:0;">&nbsp;</td></tr>
</table>
</#macro>

<#-- Button (tabellenbasiert, damit Outlook ihn rendert) -->
<#macro button href label>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin:4px 0 8px 0;">
    <tr>
        <td align="center" bgcolor="${cvoBlue}" style="background:${cvoBlue}; border-radius:8px;">
            <a href="${href}" target="_blank"
               style="display:block; padding:11px 20px; font-family:${cvoFont}; font-size:14px; font-weight:500; color:${cvoWhite}; text-decoration:none; border-radius:8px;">
                ${label}
            </a>
        </td>
    </tr>
</table>
</#macro>

<#-- Fallback fuer Clients, die den Button nicht anzeigen -->
<#macro linkFallback href>
<p style="margin:16px 0 0 0; font-size:12px; line-height:1.6; color:${cvoTextMuted};">
    ${msg("cvoLinkFallback")}<br />
    <a href="${href}" target="_blank" style="color:${cvoBlue}; text-decoration:underline; word-break:break-all;">${href}</a>
</p>
</#macro>
