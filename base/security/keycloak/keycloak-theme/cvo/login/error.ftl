<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        ${kcSanitize(msg("errorTitle"))?no_esc}
    <#elseif section = "form">

        <div id="kc-error-message">
            <p class="instruction">${kcSanitize(message.summary)?no_esc}</p>
            <#if traceId??>
                <p class="instruction trace-id" id="traceId">${msg("traceIdSupportMessage", traceId)}</p>
            </#if>
        </div>

        <#if !skipLink?? && client?? && client.baseUrl?has_content>
            <div class="kc-form-links">
                <a id="backToApplication" href="${client.baseUrl}">${msg("backToApplication")}</a>
            </div>
        </#if>

    </#if>
</@layout.registrationLayout>
