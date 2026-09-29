<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('password','password-confirm'); section>
    <#if section = "header">
        ${msg("updatePasswordTitle")}
    <#elseif section = "form">

        <form id="kc-passwd-update-form" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">

            <div class="form-group">
                <label for="password-new">${msg("passwordNew")}</label>
                <input type="password" id="password-new" name="password-new" class="form-control"
                       autofocus autocomplete="new-password" placeholder="••••••••"
                       aria-invalid="<#if messagesPerField.existsError('password','password-confirm')>true</#if>" />
                <#if messagesPerField.existsError('password')>
                    <span id="input-error-password" class="field-error" aria-live="polite">${kcSanitize(messagesPerField.get('password'))?no_esc}</span>
                </#if>
            </div>

            <div class="form-group">
                <label for="password-confirm">${msg("passwordConfirm")}</label>
                <input type="password" id="password-confirm" name="password-confirm" class="form-control"
                       autocomplete="new-password" placeholder="••••••••"
                       aria-invalid="<#if messagesPerField.existsError('password-confirm')>true</#if>" />
                <#if messagesPerField.existsError('password-confirm')>
                    <span id="input-error-password-confirm" class="field-error" aria-live="polite">${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</span>
                </#if>
            </div>

            <div class="form-group login-pf-settings">
                <div class="checkbox">
                    <label>
                        <input type="checkbox" id="logout-sessions" name="logout-sessions" value="on" checked>
                        ${msg("logoutOtherSessions")}
                    </label>
                </div>
            </div>

            <div id="kc-form-buttons" class="form-group">
                <input name="login" class="btn btn-primary btn-block btn-lg" type="submit" value="${msg("doSubmit")}" />
                <#if isAppInitiatedAction??>
                    <button class="btn btn-secondary btn-block" type="submit" name="cancel-aia" value="true">${msg("doCancel")}</button>
                </#if>
            </div>

        </form>

    </#if>
</@layout.registrationLayout>
