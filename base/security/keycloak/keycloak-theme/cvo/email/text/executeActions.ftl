<#ftl output_format="plainText">
<#-- Verzweigung wie in html/executeActions.ftl, siehe Kommentar dort. -->
<#assign hasUpdatePassword = false>
<#assign hasVerifyEmail = false>
<#assign actionCount = 0>
<#if requiredActions??>
    <#list requiredActions as reqAction>
        <#assign actionCount = actionCount + 1>
        <#if reqAction == "UPDATE_PASSWORD"><#assign hasUpdatePassword = true></#if>
        <#if reqAction == "VERIFY_EMAIL"><#assign hasVerifyEmail = true></#if>
    </#list>
</#if>
<#assign isInvitation = hasUpdatePassword && hasVerifyEmail>
<#assign showActionList = requiredActions?? && (!isInvitation || actionCount gt 2)>
<#if user?? && user.firstName?? && user.firstName?has_content>${msg("cvoGreetingName", user.firstName)}<#else>${msg("cvoGreeting")}</#if>

${msg(isInvitation?then("cvoInviteIntro", "cvoExecuteActionsIntro"), realmName)}
<#if showActionList>
<#list requiredActions as reqActionItem>
- ${msg("requiredAction.${reqActionItem}")}
</#list>
</#if>

${link}

${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}

${msg(isInvitation?then("cvoInviteIgnore", "cvoExecuteActionsIgnore"))}

--
Carl von Ossietzky Gymnasium
${msg("cvoFooterNotice")}
