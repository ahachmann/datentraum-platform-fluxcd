<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=social.displayInfo displayWide=(realm.password && social.providers??); section>
    <#if section = "header">
        ${msg("loginTitle",(realm.displayName!''))}
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">

                <!-- Logo & Org Name -->
                <div id="kc-header">
                    <div id="kc-header-wrapper">
                        <img src="${url.resourcesPath}/img/logo.jpg" alt="CVO Logo" />
                        <span class="kc-logo-subtitle">Carl von Ossietzky Gymnasium</span>
                    </div>
                </div>

                <!-- Subtitle -->
                <div id="kc-page-title">
                    ${msg("loginAccountTitle")}
                </div>

                <!-- Error / info messages -->
                <#if message?has_content>
                    <div class="alert alert-${message.type}">
                        <#if message.type = 'warning'><span class="pficon pficon-warning-triangle-o" aria-hidden="true"></span></#if>
                        <#if message.type = 'error'><span class="pficon pficon-error-circle-o" aria-hidden="true"></span></#if>
                        <#if message.type = 'success'><span class="pficon pficon-ok" aria-hidden="true"></span></#if>
                        <#if message.type = 'info'><span class="pficon pficon-info" aria-hidden="true"></span></#if>
                        <span class="kc-feedback-text">${kcSanitize(message.summary)?no_esc}</span>
                    </div>
                </#if>

                <#if realm.password>
                    <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">

                        <!-- Username field -->
                        <div class="form-group">
                            <label for="username">
                                <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                            </label>
                            <#if usernameEditDisabled??>
                                <input tabindex="1" id="username" class="form-control" name="username" value="${(login.username!'')}" type="text" disabled />
                            <#else>
                                <input tabindex="1" id="username" class="form-control" name="username" value="${(login.username!'')}" type="text" autofocus autocomplete="off" placeholder="<#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>" />
                            </#if>
                        </div>

                        <!-- Password field -->
                        <div class="form-group">
                            <label for="password">${msg("password")}</label>
                            <input tabindex="2" id="password" class="form-control" name="password" type="password" autocomplete="off" placeholder="••••••••" />
                        </div>

                        <!-- Remember me + Forgot password -->
                        <div class="form-group login-pf-settings">
                            <#if realm.rememberMe && !usernameEditDisabled??>
                                <div class="checkbox">
                                    <label>
                                        <#if login.rememberMe??>
                                            <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                        <#else>
                                            <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                        </#if>
                                    </label>
                                </div>
                            </#if>
                            <#if realm.resetPasswordAllowed>
                                <a tabindex="5" href="${url.loginResetCredentialsUrl}" id="forgot-password">${msg("doForgotPassword")}</a>
                            </#if>
                        </div>

                        <!-- Submit -->
                        <div id="kc-form-buttons" class="form-group">
                            <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>/>
                            <input tabindex="4" class="btn btn-primary btn-block btn-lg" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                        </div>

                    </form>
                </#if>

                <!-- Footer -->
                <div id="kc-info">
                    <p>Geschützter Bereich &ndash; nur für autorisierte Nutzer</p>
                    <div class="kc-badge">
                        <span class="kc-dot"></span>
                        Gesichert durch Keycloak
                    </div>
                </div>

            </div>
        </div>
    </#if>
</@layout.registrationLayout>
