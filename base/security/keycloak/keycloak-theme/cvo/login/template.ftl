<#--
  CVO Login Theme - gemeinsames Layout aller Anmeldeseiten.
  Karte, Logo, Seitentitel, Meldungsblock und Footer stehen hier, damit die
  einzelnen Seiten (login.ftl, login-reset-password.ftl, ...) nur noch ihr
  Formular beisteuern.
-->
<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayWide=false displayRequiredFields=false>
<!DOCTYPE html>
<html class="${properties.kcHtmlClass!}">

<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="robots" content="noindex, nofollow">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <#if properties.meta?has_content>
        <#list properties.meta?split(' ') as meta>
            <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
        </#list>
    </#if>

    <title>${msg("loginTitle",(realm.displayName!''))}</title>
    <link rel="icon" href="${url.resourcesPath}/img/logo.jpg" />

    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>

    <#if properties.scripts?has_content>
        <#list properties.scripts?split(' ') as script>
            <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
        </#list>
    </#if>

    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
</head>

<body class="${properties.kcBodyClass!}<#if bodyClass?has_content> ${bodyClass}</#if>">
    <div class="${properties.kcLoginClass!}">
        <div id="kc-container">
            <div id="kc-form-wrapper">

                <!-- Logo & Schulname -->
                <div id="kc-header">
                    <div id="kc-header-wrapper">
                        <img src="${url.resourcesPath}/img/logo.jpg" alt="CVO Logo" />
                        <span class="kc-logo-subtitle">Carl von Ossietzky Gymnasium</span>
                    </div>
                </div>

                <!-- Seitentitel -->
                <div id="kc-page-title">
                    <#nested "header">
                </div>

                <!-- Fehler- / Infomeldung -->
                <#if displayMessage && message?? && message.summary?has_content>
                    <div class="alert alert-${message.type}">
                        <#if message.type = 'warning'><span class="pficon pficon-warning-triangle-o" aria-hidden="true"></span></#if>
                        <#if message.type = 'error'><span class="pficon pficon-error-circle-o" aria-hidden="true"></span></#if>
                        <#if message.type = 'success'><span class="pficon pficon-ok" aria-hidden="true"></span></#if>
                        <#if message.type = 'info'><span class="pficon pficon-info" aria-hidden="true"></span></#if>
                        <span class="kc-feedback-text">${kcSanitize(message.summary)?no_esc}</span>
                    </div>
                </#if>

                <#nested "form">

                <#if displayInfo>
                    <div id="kc-info">
                        <#nested "info">
                    </div>
                </#if>

                <!-- Footer -->
                <div class="kc-footer">
                    <p>Geschützter Bereich &ndash; nur für Elternratsmiglieder des CvO</p>
                    <div class="kc-badge">
                        <span class="kc-dot"></span>
                        Gesichert durch Keycloak
                    </div>
                </div>

            </div>
        </div>
    </div>
</body>
</html>
</#macro>
