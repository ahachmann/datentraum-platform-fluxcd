<#ftl output_format="plainText">
<#if user?? && user.firstName?? && user.firstName?has_content>${msg("cvoGreetingName", user.firstName)}<#else>${msg("cvoGreeting")}</#if>

${msg("cvoEmailUpdateIntro", realmName, newEmail)}

${link}

${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}

${msg("cvoEmailUpdateIgnore")}

--
Carl von Ossietzky Gymnasium
${msg("cvoFooterNotice")}
