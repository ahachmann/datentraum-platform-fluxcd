<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=!isAppInitiatedAction??; section>
    <#if section = "header">
        ${msg("emailVerifyTitle")}
    <#elseif section = "form">

        <p class="instruction">
            <#if verifyEmail??>
                ${msg("emailVerifyInstruction1", verifyEmail)}
            <#else>
                ${msg("emailVerifyInstruction4", user.email)}
            </#if>
        </p>

        <#if isAppInitiatedAction??>
            <form id="kc-verify-email-form" action="${url.loginAction}" method="post">
                <div id="kc-form-buttons" class="form-group">
                    <#if verifyEmail??>
                        <input class="btn btn-primary btn-block btn-lg" type="submit" value="${msg("emailVerifyResend")}" />
                    <#else>
                        <input class="btn btn-primary btn-block btn-lg" type="submit" value="${msg("emailVerifySend")}" />
                    </#if>
                    <button class="btn btn-secondary btn-block" type="submit" name="cancel-aia" value="true" formnovalidate>${msg("doCancel")}</button>
                </div>
            </form>
        </#if>

    <#elseif section = "info">
        ${msg("emailVerifyInstruction2")}
        <a href="${url.loginAction}">${msg("doClickHere")}</a> ${msg("emailVerifyInstruction3")}
    </#if>
</@layout.registrationLayout>
