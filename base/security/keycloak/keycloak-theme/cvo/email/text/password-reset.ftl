<#ftl output_format="plainText">
<#if user?? && user.firstName?? && user.firstName?has_content>${msg("cvoGreetingName", user.firstName)}<#else>${msg("cvoGreeting")}</#if>

${msg("cvoPasswordResetIntro", realmName)}

${link}

${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}

${msg("cvoPasswordResetIgnore")}

--
Carl von Ossietzky Gymnasium
${msg("cvoFooterNotice")}
