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

        <#if !skipLink??>
            <div class="kc-form-links">
                <#if pageRedirectUri?has_content>
                    <a href="${pageRedirectUri}">${msg("backToApplication")}</a>
                <#elseif actionUri?has_content>
                    <a href="${actionUri}">${msg("proceedWithAction")}</a>
                <#elseif (client.baseUrl)?has_content>
                    <a href="${client.baseUrl}">${msg("backToApplication")}</a>
                </#if>
            </div>
        </#if>

    </#if>
</@layout.registrationLayout>
