<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<@layout.emailLayout title=msg("cvoEmailVerificationTitle") preheader=msg("cvoEmailVerificationPreheader")>
    <@layout.greeting/>
    <@layout.p>${msg("cvoEmailVerificationIntro", realmName)}</@layout.p>
    <@layout.button href=link label=msg("cvoEmailVerificationCta")/>
    <@layout.muted>${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}</@layout.muted>
    <@layout.divider/>
    <@layout.muted>${msg("cvoEmailVerificationIgnore")}</@layout.muted>
    <@layout.linkFallback href=link/>
</@layout.emailLayout>
