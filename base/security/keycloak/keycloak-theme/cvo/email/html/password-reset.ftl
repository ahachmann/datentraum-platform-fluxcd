<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<@layout.emailLayout title=msg("cvoPasswordResetTitle") preheader=msg("cvoPasswordResetPreheader")>
    <@layout.greeting/>
    <@layout.p>${msg("cvoPasswordResetIntro", realmName)}</@layout.p>
    <@layout.button href=link label=msg("cvoPasswordResetCta")/>
    <@layout.muted>${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}</@layout.muted>
    <@layout.divider/>
    <@layout.muted>${msg("cvoPasswordResetIgnore")}</@layout.muted>
    <@layout.linkFallback href=link/>
</@layout.emailLayout>
