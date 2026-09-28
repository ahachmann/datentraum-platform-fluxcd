<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<@layout.emailLayout title=msg("cvoExecuteActionsTitle") preheader=msg("cvoExecuteActionsPreheader")>
    <@layout.greeting/>
    <@layout.p>${msg("cvoExecuteActionsIntro", realmName)}</@layout.p>
    <#if requiredActions??>
    <ul style="margin:0 0 16px 0; padding-left:20px; font-size:14px; line-height:1.6; color:#374151;">
        <#list requiredActions as reqActionItem>
        <li>${msg("requiredAction.${reqActionItem}")}</li>
        </#list>
    </ul>
    </#if>
    <@layout.button href=link label=msg("cvoExecuteActionsCta")/>
    <@layout.muted>${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}</@layout.muted>
    <@layout.divider/>
    <@layout.muted>${msg("cvoExecuteActionsIgnore")}</@layout.muted>
    <@layout.linkFallback href=link/>
</@layout.emailLayout>
