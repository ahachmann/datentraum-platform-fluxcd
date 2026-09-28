<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<@layout.emailLayout title=msg("cvoEmailTestTitle") preheader=msg("cvoEmailTestPreheader")>
    <@layout.p>${msg("cvoEmailTestBody", realmName)}</@layout.p>
</@layout.emailLayout>
