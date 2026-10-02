<#ftl output_format="HTML">
<#import "template.ftl" as layout>
<#--
  Zwei Tonlagen in einer Mail: Keycloak verschickt executeActions sowohl für
  eine Einladung (neues Konto -> Passwort setzen UND E-Mail bestätigen) als
  auch für einzelne Nachforderungen an ein bestehendes Konto. Enthält der
  Action-Token beide Aktionen, ist es praktisch immer ein neuer Zugang.

  Der Betreff verzweigt NICHT mit: Keycloak löst executeActionsSubject ohne
  Parameter vor dem Template auf. Er ist deshalb neutral gehalten.
-->
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
<#-- Bei einer Einladung nennt der Text die beiden Schritte schon; die Liste
     kommt nur, wenn darüber hinaus noch etwas zu tun ist. -->
<#assign showActionList = requiredActions?? && (!isInvitation || actionCount gt 2)>

<@layout.emailLayout
        title=msg(isInvitation?then("cvoInviteTitle", "cvoExecuteActionsTitle"))
        preheader=msg(isInvitation?then("cvoInvitePreheader", "cvoExecuteActionsPreheader"))>

    <@layout.greeting/>
    <@layout.p>${msg(isInvitation?then("cvoInviteIntro", "cvoExecuteActionsIntro"), realmName)}</@layout.p>

    <#if showActionList>
    <ul style="margin:0 0 16px 0; padding-left:20px; font-size:14px; line-height:1.6; color:#374151;">
        <#list requiredActions as reqActionItem>
        <li>${msg("requiredAction.${reqActionItem}")}</li>
        </#list>
    </ul>
    </#if>

    <@layout.button href=link label=msg(isInvitation?then("cvoInviteCta", "cvoExecuteActionsCta"))/>
    <@layout.muted>${msg("cvoLinkExpiration", linkExpirationFormatter(linkExpiration))}</@layout.muted>
    <@layout.divider/>
    <@layout.muted>${msg(isInvitation?then("cvoInviteIgnore", "cvoExecuteActionsIgnore"))}</@layout.muted>
    <@layout.linkFallback href=link/>

</@layout.emailLayout>
