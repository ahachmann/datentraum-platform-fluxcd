<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username'); section>
    <#if section = "header">
        ${msg("emailForgotTitle")}
    <#elseif section = "form">

        <p class="instruction">
            <#if realm.duplicateEmailsAllowed>${msg("emailInstructionUsername")}<#else>${msg("emailInstruction")}</#if>
        </p>

        <form id="kc-reset-password-form" action="${url.loginAction}" method="post">

            <div class="form-group">
                <label for="username">
                    <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                </label>
                <input type="text" id="username" name="username" class="form-control" autofocus dir="ltr"
                       value="${(auth.attemptedUsername!'')}"
                       aria-invalid="<#if messagesPerField.existsError('username')>true</#if>" />
                <#if messagesPerField.existsError('username')>
                    <span id="input-error-username" class="field-error" aria-live="polite">${kcSanitize(messagesPerField.get('username'))?no_esc}</span>
                </#if>
            </div>

            <div id="kc-form-buttons" class="form-group">
                <input class="btn btn-primary btn-block btn-lg" type="submit" value="${msg("doSubmit")}"/>
            </div>

            <div class="kc-form-links">
                <a href="${url.loginUrl}">${msg("backToLogin")}</a>
            </div>

        </form>

    </#if>
</@layout.registrationLayout>
