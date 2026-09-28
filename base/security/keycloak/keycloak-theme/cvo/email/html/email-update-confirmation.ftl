<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<@layout.emailLayout title=msg("cvoEmailUpdateTitle") preheader=msg("cvoEmailUpdatePreheader")>
    <@layout.greeting/>
    <@layout.p>${msg("cvoEmailUpdateIntro", realmName, newEmail)}</@layout.p>
    <@layout.button href=link label=msg("cvoEmailUpdateCta")/>
    <@layout.muted>${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}</@layout.muted>
    <@layout.divider/>
    <@layout.muted>${msg("cvoEmailUpdateIgnore")}</@layout.muted>
    <@layout.linkFallback href=link/>
</@layout.emailLayout>
