<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        <#if messageHeader??>${kcSanitize(msg("${messageHeader}"))?no_esc}<#else>${msg("infoTitle")}</#if>
    <#elseif section = "form">

        <div id="kc-info-message">
            <p class="instruction">
                ${kcSanitize(message.summary)?no_esc}<#if requiredActions??><#list requiredActions>: <b><#items as reqActionItem>${kcSanitize(msg("requiredAction.${reqActionItem}"))?no_esc}<#sep>, </#items></b></#list></#if>
            </p>
        </div>

        <#--
          Weiterführender Link. Keycloak liefert pageRedirectUri nur, wenn der
          Flow mit einem redirect_uri gestartet wurde (z. B. execute-actions-email
          mit client_id + redirect_uri). Sonst setzt es skipLink und die Seite
          wäre eine Sackgasse - dagegen steht cvoAfterActionUrl aus
          theme.properties als eigener Ausweg.
        -->
        <#assign exitLink = "">
        <#assign exitLabel = "">

        <#if !skipLink??>
            <#if (pageRedirectUri!'')?has_content>
                <#assign exitLink = pageRedirectUri>
                <#assign exitLabel = msg("backToApplication")>
            <#elseif (actionUri!'')?has_content>
                <#assign exitLink = actionUri>
                <#assign exitLabel = msg("proceedWithAction")>
            <#elseif (client.baseUrl!'')?has_content>
                <#assign exitLink = client.baseUrl>
                <#assign exitLabel = msg("backToApplication")>
            </#if>
        </#if>

        <#if !exitLink?has_content && (properties.cvoAfterActionUrl!'')?has_content>
            <#assign exitLink = properties.cvoAfterActionUrl>
            <#assign exitLabel = msg("cvoAfterActionLink")>
        </#if>

        <#if exitLink?has_content>
            <div class="kc-form-links">
                <a href="${exitLink}">${exitLabel}</a>
            </div>
        </#if>

    </#if>
</@layout.registrationLayout>
