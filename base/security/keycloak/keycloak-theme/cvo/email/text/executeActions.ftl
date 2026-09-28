<#ftl output_format="plainText">
<#if user?? && user.firstName?? && user.firstName?has_content>${msg("cvoGreetingName", user.firstName)}<#else>${msg("cvoGreeting")}</#if>

${msg("cvoExecuteActionsIntro", realmName)}
<#if requiredActions??>
<#list requiredActions as reqActionItem>
- ${msg("requiredAction.${reqActionItem}")}
</#list>
</#if>

${link}

${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}

${msg("cvoExecuteActionsIgnore")}

--
Carl von Ossietzky Gymnasium
${msg("cvoFooterNotice")}
