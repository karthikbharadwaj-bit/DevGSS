# Technical Documentation
## Salesforce Case Management — code level

**Audience:** Salesforce engineers who will build on, operate and change Case Management.
**Scope:** Case Management, System Optimisation, System Maintenance & Operations — described from the code.
**Verified against:** commit `85839f2`. Re-checked at `7d60439` (2026-09-17); the Case path is unchanged between the two, so every path and line number below is current.

**This document does not restate Jira or Confluence.** Where a wiki page or ticket already covers something, it is linked, not summarised — follow the link for requirements, process and history, and read this for what the code does. Same for documentation already in this repo: the trigger framework is [`TRIGGERS_ARCHITECTURE.md`](../TRIGGERS_ARCHITECTURE.md) and the ticketing and deployment process is [`docs/jira-process.md`](jira-process.md). Neither is repeated.

Its companion is `KT-Handover-Salesforce-Case-Management-LTR-PBC.md`, the documentation-level view of the same system. This uses the same section numbering so the two read side by side. Where the code contradicts it, the passage is marked **[differs from handover]**.

**Read §0 and §1.3 first.** Routing is where the complexity is and where incidents originate.

---

## 0. Orientation — the code map

One SObject, five automation paradigms, two generations of Jira integration, eight intake paths, one trigger.

| File | Lines | What it is |
|---|---|---|
| `triggers/CaseObject.trigger` | 113 | The only Case trigger. 60 handler bindings across two dispatch blocks. |
| `classes/CaseTriggerHandler.cls` | 2,661 | 56 inner handler classes. All Apex Case behaviour. |
| `classes/CaseHelper.cls` | 1,144 | Constants and shared logic. 63 record-type names, 49 resolved IDs, 278 static members. Read before writing any Case code. |
| `classes/Triggers.cls` | 388 | Dispatch framework — see [`TRIGGERS_ARCHITECTURE.md`](../TRIGGERS_ARCHITECTURE.md). |
| `classes/CaseRouting.cls` | 95 | Entitlement-driven web-case routing. |
| `classes/QueueHelper.cls` | 42 | Queue name constants, name→Id resolution. |
| `classes/CreateJiraController.cls` | 366 | Current Jira integration; `Create Jira` / `Link Jira`. |
| `flows/` | 491 files | 136 Case-triggered, 120 Active. |

**Repo scope.** This is a partial metadata export. Absent: `profiles/`, `permissionsets/`, `layouts/`, `customMetadata/` records, `namedCredentials/`, `remoteSiteSettings/`; `assignmentRules/` and `settings/` are empty; `objects/` holds only `Jira_Case_Comment__c`, so there is no Case object folder, no Case field definitions and no validation rules. §3.4 lists what is missing and how to retrieve it.

Only `main` exists here. Per PBC-32259, GCI and BISUAT are 14,000–18,500 commits diverged. **Nothing here describes those environments.**

---

# 1. Case Management

## 1.1 The Case object in code

63 record-type names are declared as `RT_NAME_*` constants at `CaseHelper.cls:8-74`; 49 are resolved to IDs at `:172-222`, by name:

```apex
public static final Id RT_ID_SUPPORT_CASE = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_CASE).getRecordTypeId();
```
— `CaseHelper.cls:187`

**No hardcoded record-type IDs in Case Apex.** Follow this pattern.

That constant block is the closest thing to a Case taxonomy register — read it from source, not from a copy. It carries no owner, queue, SLA or deprecation flag; that gap is G1 in the handover.

Two properties to know before renaming a record type:

1. Resolution happens in a **static initialiser with no null check**. Rename or delete any of the 49 and `.getRecordTypeId()` throws during initialisation of `CaseHelper`, which every Case transaction touches. One rename stops all Case processing in that org.
2. 14 of the 63 names are never resolved to an ID.

Declarative automation does **not** follow this pattern — flows reference record types by hardcoded ID (§2.2).

Case field definitions are not in this repo. As a usage floor: `CaseTriggerHandler` writes 41 distinct Case fields, `CaseSelector` queries 63 custom fields, and the 136 Case flows reference 122.

## 1.2 Intake channels — code entry points

| # | Channel | Entry point | Behaviour |
|---|---|---|---|
| 1 | Support Site web case | `CaseTriggerHandler.WebCaseRouting` (`:830-880`, before insert) | Filters `Origin == 'Web'`, groups accounts by entitlement, delegates to `CaseRouting.execute()` |
| 2 | Email-to-Case | 12 `Messaging.InboundEmailHandler` classes | `createCaseFromEmail`, `CreateCaseFromCustomerFeedback`, `createCaseFromFeedback`, `GenericE2Csetup` (driven by `Generic_E2C_setting__mdt`), `InboundEmailService`, `PartnerCommissionEmailServiceCase`, `DQApprovalEmailService`, + 5 lead-side |
| 3 | Partner Portal (Ignite / AAA) — [LTR-1873](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1103588781) | `lwc/prmCaseCreateLayout/` via `/partner-create-case` (`lwc/clHeader/clHeader.js:73`) → `PrmCaseCreateHelper.createCases` | Resolves record type **by name at runtime** to `Deal and Order Support` (`prmCaseCreateLayout.js:45`); **applies** the first active assignment rule via `DMLOptions` (`PrmCaseCreateHelper.cls:17-24`). **[differs from handover]** — sets no Case Category, and targets *Deal and Order Support*, not *Reseller - VAR & Partners*. |
| 4 | SCP → Support Site (RISE 2.0) | `CaseTriggerHandler.MakeCallOutToSCP` (`:2393`, after insert) | Outbound callout on insert |
| 5 | UQT / PRM redirects | `CaseCreateLWCController.cls:93-94` | Applies an assignment rule explicitly |
| 6 | Quoting Wizard (ProServ) | `CaseTriggerHandler.ChangeOwnerForProfessionalServices` (`:478-613`, before insert) | ProServ queue map — §1.3 layer 6 |
| 7 | E-bonding | `PartnerNetworkConnectionHelper`, `TelusExternalSharingHelperCls`, `ICBAPI` | §1.6 |
| 8 | API / middleware | `@RestResource` classes | `CaseCreateStrategy` dispatches on record type |

**REST case creation** uses a strategy map keyed on record type (`CaseCreateStrategy.cls:3-13`): `Developer Platform` → `CaseCreateDeveloperPortal`, `Sales - Customer Issue Form` → `CaseCreateSalesCustForm`, `GDPR Request` → `CaseCreateGDPR`, fallback `CaseCreateDefault` (`:129`). An unrecognised record type returns 400 listing valid values (`:15-16`).

The strategy performs a plain `insert` (`:193`, `:306`). **No external ID, no upsert, no duplicate window on any REST case-creation path** — a retrying caller creates a second Case. This is the mechanism behind PBC-32836.

`/ws/rest/intapi/case`, named in the handover, **is not an Apex REST endpoint** — Apex REST serves under `/services/apexrest/` and no `urlMapping` matches. Whatever serves it fronts an endpoint in §1.6.

## 1.3 Routing and assignment — how an owner is decided

Six layers over the Salesforce save order. **32 active automations write `Case.OwnerId`.**

### The pipeline

Case **insert**:

| Step | What runs | Count |
|---|---|---|
| 2 | Before-save flows | 7 Active |
| 3 | Trigger, before insert | 28 handlers — block 1 (14), block 2 (14) |
| 5 | Duplicate rules | *not in repo* |
| 7 | Trigger, after insert | 8 handlers |
| **8** | **Assignment rules** | *not in repo* |
| 10 | Workflow rules | **0** — `workflows/Case.workflow-meta.xml` has no `<rules>` |
| 12 | After-save flows + PBs | **90 Active flows + 4 Active PBs** |

**Update:** 4 before-save flows, 30 handlers at step 3, 10 at step 7, 76 after-save flows. Assignment rules fire at step 8 only if `AssignmentRuleHeader` is set.

**No Case flow sets `<triggerOrder>`** — ordering among the 90 after-save flows is undefined. Apex order *is* deterministic: handlers run in `bind()` registration order, i.e. source order in the trigger.

### Layer 1 — record type and origin

Set at intake (§1.2). Determines which downstream branches can match.

### Layer 2 — assignment rules

Standard Salesforce, fires only when requested. Two paths request it: `PrmCaseCreateHelper.cls:17-24` and `CaseCreateLWCController.cls:93-94`, both taking the first active Case assignment rule. The ProServ path passes no `DMLOptions`, so rules never fire there — the bypass PBC-31986 describes is achieved by omission, not by a flag. **Adding `DMLOptions` to that path silently re-enables the rules.** The rules themselves are not in this repo.

### Layer 3 — `Support_Escalate_To__c`

Referenced by 17 Apex classes and 31 flows, consumed three ways.

**(a) Queue resolved by name at runtime** — the correct pattern:

```apex
if (!context.groupsByName.containsKey(this.queueNameToAssign)) {
    throw new CaseRoutingException('Queue not found: ' + this.queueNameToAssign);
}
caseObj.OwnerId = context.groupsByName.get(this.queueNameToAssign).Id;
```
— `CaseRouting.cls:36-39`. Portable, and fails loudly.

**(b) Queue ID in a Custom Label** — the migration target. Eight `CaseEsc_*` labels in `labels/CustomLabels.labels-meta.xml`: `Billing`, `ContactCenter`, `GSS_GDPR`, `IT_GSD_User`, `ProServ`, `SOED`, `SalesOps`, `TAE`.

**(c) Dynamic record reference** — owner is a user named on the record.

**29 escalation values across 5 active flows:**

| Value | Owner becomes | Also sets | Where |
|---|---|---|---|
| `IT` | `$Label.CaseEsc_IT_GSD_User_Id` (a user) | RT → IT Helpdesk; **nulls `Support_Escalate_To__c`** | `Case_Routing_Escalation_After_Save` N6 |
| `Contact Center Support` | `$Label.CaseEsc_ContactCenter_Queue_Id` | RT → Support T2 | same, N7 |
| `SalesOps` | `$Label.CaseEsc_SalesOps_Queue_Id` | RT unchanged (IBS) | same, N8 |
| `SOED` | `$Label.CaseEsc_SOED_Queue_Id` | RT → Sales Order Except Desk | same, N9 |
| `Technical Account Engineering` | `$Label.CaseEsc_TAE_Queue_Id` | **STOP** — no later node runs | same, N26 |
| `Route_To__c` = `GSS GDPR Request` | `$Label.CaseEsc_GSS_GDPR_Queue_Id` | RT → GDPR Request; **nulls `Route_To__c`** | same, N5 |
| `SOED` (Collections RT) | `$Label.CaseEsc_SOED_Queue_Id` | — | `Case_Collections_Dispute_After_Save` `myRule_15` |
| `Professional Services` | `$Label.CaseEsc_ProServ_Queue_Id` | — | same, `myRule_17` |
| `Sales` | `$Record.Account_Current_Owner__r.Id` | — | same, `myRule_19` |
| `CSM` | `$Record.Account.CSM__r.Id` | — | same, `myRule_21` |
| `Billing` | `$Label.CaseEsc_Billing_Queue_Id` | — | same, `myRule_23` |
| `Collections` | `$Record.Case_Originator__c` | — | same, `myRule_25` |
| The 9 SE queues — `SE - RC Video`, `SE - RCX`, `SE - AI - RingSense`, `SE - Events`, `SE - Messaging`, `SE - Platform - Integration`, `SE - Analytics`, `SE - RC Apps`, `Service Engineer` | queue resolved by name at runtime | **RT → hardcoded `01280000000UGuR`, all nine** | `Platform_Service_Engineering_Case_Process` |
| `Dev Support Tier 2`, `Biz Serv Dev Team`, `Biz Serv Tableau Team`, `Escalate to QRT`, `Partners Escalations`, `RC Engage Voice Support`, `Reseller Team`, `Special Support Team` | raw ID literals | — | `Case_Escalation_Router_After_Save` |
| `Dev Support Tier 2`, `Reseller - VAR & Partners` | raw ID literals | — | `Case_Escalation_Router_Before_Save` |

The nine SE values are the nine `Escalate to` queues in the handover's queue→Jira project table, so this flow is the Salesforce half of that mapping.

Three behaviours that will surprise you:

- **N5 and N6 null the field that triggered them.** Load-bearing for their own firing conditions; splitting either breaks re-entrancy. Noted at `Test_RoutingEscalationParity.cls:39-40`.
- **N26 stops the flow.** A case escalated to Technical Account Engineering skips every later node.
- **`Dev Support Tier 2` is handled twice** — before-save (step 2) and after-save (step 12), with assignment rules in between. Both Active, both writing `OwnerId`, `RecordTypeId`, `Status`.

### Layer 4 — Apex

| Handler | Context | Rule |
|---|---|---|
| `AssignOwnerForClosedLoopRelationshipCases` (`:470`) | before insert | Round-robin from a custom setting holding the last-assigned owner |
| `ChangeOwnerForProfessionalServices` (`:504`, `:557`) | before insert | ProServ queue map, keyed on quote record type, currency, category, opportunity-owner segment |
| `CaseCreationOnPRM` (`:892`) | before insert | Reseller Team RT → Reseller Team queue |
| `HandleEngageDigitalCaseUpdates` (`:1082`) | before insert/update | Escalate-to `RC Engage Digital Support` → Engage Digital group |
| `ProcessT1ShippingAndUpdateDetails` (`:1134`) | before insert | Owner from a user resolved by email |
| `ChangeCaseOwnerForSupportT1User` (`:1814`) | before update | On escalation to `Tier 1`, owner → `CreatedById`; gated on the T1 profile **or** a custom permission |
| `UpdateSupportCNRCases` (`:2297`) | before update | CNR reassignment |
| `RoundRobinAssignment` (`:2623`) | before insert/update | CERT / Customer Success round-robin over `Case_Assignee__c` |
| `CaseRouting.applyTo` (`CaseRouting.cls:39`) | before insert, via `WebCaseRouting` | Entitlement-based web routing |

`RC Support Agent` — the catch-all owner in PBC-33131 — is a constant at `CaseTriggerHandler.cls:21`, but Apex only **reads** it, as a guard in `ProcessT1ShippingAndUpdateDetails` (`:1147-1148`). Nothing here assigns it. It comes from the assignment rules, which are not in source control — which is why that defect cannot be root-caused from code alone.

### Layer 5 — entitlement routing

`CaseRouting` builds a sorted rule list from `CaseRoutingBySupportType__mdt` (`:60-70`), each rule carrying `ExecutionOrder__c`, `SupportType__c`, `Owner__c` (queue developer name), `CaseRecordType__c`, `IsCaseCategoryOverride__c`. First applicable rule for the account's entitlement wins. `applyTo` sets `OwnerId`, optionally `RecordTypeId`, optionally overwrites `Case_Category__c` with the support type (`:39-45`). CMDT rows not in this repo.

### Layer 6 — the ProServ queue map

`QueueHelper.PROSERV_QUEUES` (`:19-30`) holds ten queue names; `getPSQueuesMap()` (`:32-42`) resolves them by name. `ChangeOwnerForProfessionalServices` reads that map at 15 decision points.

**A missing queue does not throw here.** `psQueuesMap.get(name)` returns null, `psCase.OwnerId = null` (`:557`), and in before-insert Salesforce defaults the owner to the running user — the case silently lands on its creator. Nine of the ten names are queues PBC-31776 deleted; its acceptance criteria required removing exactly these references, and it is Closed. **[differs from handover]**

## 1.4 Automation inventory and field ownership

### The trigger

`CaseObject.trigger` has **two dispatch blocks**, and the difference is the most important structural fact about Case Apex.

`:3-7` — `ByPassTrigger__c` hierarchy custom setting; when set, **all** Case Apex is skipped for that user or profile.

**Block 1** (`:9-47`) always runs: 14 before-insert, 2 after-insert, 13 before-update, 5 after-update.

**A recursion gate** (`:49-62`) checks `TriggerHandler.BY_PASS_BEFORE` / `BY_PASS_AFTER`, returns if set, otherwise sets them.

**Block 2** (`:64-112`) therefore runs **at most once per context per transaction**: 14 before-insert, 6 after-insert, 17 before-update, 5 after-update, 1 after-delete.

Block 2 handlers that do **not** re-run on a second save: `WebCaseRouting`, `CaseCreationOnPRM`, `MakeCallOutToSCP`, `CreateUpdateJuraIssue` (sic — the typo is in the class name), `ChangeCaseOwnerForSupportT1User`, and five survey handlers. Since 90 after-save flows can re-save a Case, this matters constantly.

The framework itself — `Handler`, `Evt`, `bind()`, `manage()` routing, `switchOff()`/`except()`, the field-change helpers, the cache hook — is in [`TRIGGERS_ARCHITECTURE.md`](../TRIGGERS_ARCHITECTURE.md). Two Case-relevant consequences are not:

- **`manage()` has no try/catch** (`Triggers.cls:93-149`). A handler that throws aborts the transaction and every handler after it never runs — up to 29 others on before-update.
- **Case adds three bypass mechanisms on top of the framework's two.** Beyond `switchOff()`/`except()` and per-handler `bypass()`, Case uses `ByPassTrigger__c` (`CaseObject.trigger:3`), the `TriggerHandler.BY_PASS_*` statics (`:49-62` — a different class from the framework), and `CaseTriggerHandler.bypassForRCEvents` (`:29`, read at `:833`). Five mechanisms, no single place listing them.

### Flows and Process Builders

136 Case-triggered: **120 Active, 6 Draft, 10 Obsolete**. 127 record-triggered flows, 9 Process Builders (`processType: Workflow`). Only 7 are before-save — everything else runs after assignment rules.

**Active Process Builders:**

| Process Builder | API | Does |
|---|---|---|
| `Consolidated_case_notification_PB` | 49.0 | 10 email alerts on case creation, BT brand, 10 record types (PBC-32990). Replacement flow `Case_Consolidated_case_notification_PB` (API 67.0) is **Draft**. |
| `B_10495_Web_Case_segmentation` | 49.0 | Writes `OwnerId` |
| `Billing_Cases` | 51.0 | Writes `OwnerId` |
| `Send_Medallia_Invitation_triggered_from_Case` | 58.0 | 2 Apex invocations |

**Active before-save flows and what they write:**

| Flow | Writes |
|---|---|
| `Case_Escalation_Router_Before_Save` | `OwnerId`, `RecordTypeId`, `Status`, `CreatedDateEscalateTo__c` |
| `Case_Status_Closed_Flow_Migration_Before_Save` | `First_Response_Timestamp_QoS__c`, `First_Response_Timestamp_T3__c` |
| `Case_Collections_Dispute_Before_Save` | Assignment-rule-independent updates carried over from `Collections_Dispute_Consolidated_PB` |
| `Case_Last_key_fields_update` | via record updates |
| `Case_Remove_Account_Contact_for_Subpoena_case` | Clears account/contact on subpoena cases |
| `Make_Partner_system_Id_null_for_child_cases` | Nulls partner system Id on child cases |
| `Qualtrics_Closeloop_Feedback_Cases_Assignment` | Close-loop feedback assignment |

To regenerate the full inventory, parse `flows/*.flow-meta.xml` for `<start><object>Case</object>` and read `<status>`, `<triggerType>`, `<recordTriggerType>`. Do not keep a copy — 120 Active flows change faster than a document.

### Field ownership

19 Case fields have more than one active writer:

| Field | Writers |
|---|---|
| `OwnerId` | **32** — 9 Apex sites + 29 flows + 2 Process Builders |
| `Status` | 19 — 1 Apex handler + 18 flows |
| `RecordTypeId` | 13 — 3 Apex + 12 flows, mostly by hardcoded ID |

Also multi-writer: `Case_Category__c` (5), `AccountId` (5), `Support_Escalate_To__c` (4), `ContactId` (2), seven CNR fields.

**Before changing anything that writes `OwnerId`, assume something else writes it in the same transaction.**

## 1.5 Jira sync

Design, requirements and the cadence question: [LTR-2329](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1103588199), [LTR-3111](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1103588271), [COOPS SF→Jira Case Integration](https://wiki.ringcentral.com/pages/viewpage.action?pageId=915398793). Operations: [Jira to SFDC Integration Process Runbook](https://wiki.ringcentral.com/pages/viewpage.action?pageId=582679012). Not repeated here.

Two integrations, built a decade apart, both present.

### Current path — Boomi via Named Credentials

`CreateJiraController.createJira(caseId)` (`:68-147`), in order:

1. Record-type permission check via `JiraAccessPermissionService` (`:73`)
2. Existing-link guard — `ERROR_JIRA_TICKET_EXISTS` if `Jira_Case__c` or `Jira__c` is set (`:86`)
3. Blank-queue guard (`:90-92`)
4. Project lookup — `Jira_Queue_Mapping__mdt WHERE Label = :cs.Support_Escalate_To__c`, value `Jira_Project_Mapping__c` (`:94-99`). **[differs from handover]** — Custom *Metadata*, not Custom Settings.
5. Payload from `JiraJsonBuilder.build()` (`:106`)
6. POST to `callout:Jira_Create`, 120 s timeout (`:108-115`)
7. 2xx check (`:117`), then body-level `Notice: 'Error Occured'` check (`:123`)
8. Creates and links the `Jira_Case__c` record (`:135`)
9. `finally` logs any exception to exception history (`:142-146`)

`linkJira` validates the key against `^[A-Z][A-Z0-9]*-\d+$` (`:171`), calls `callout:Jira_Link`, and on success writes `Jira_Case__c = null, Jira__c = jiraKey, Jira_Link__c = jiraUrl` (`:226-228`) — the lookup clears as part of the relink. The UI mirrors the server guard: `createJiraButton.js:30-33` wires `Jira__c` into `jiraExists`.

**Access control** is entirely config-driven — `JiraAccessPermissionService.cls:225-228` reads `SF_Jira_Profile_RecordType_Permission__mdt` with `Operation_Type__c` (`create`/`link`/`both`), `Profile_Name__c`, `RecordType_Name__c` (CSV, parsed at `:248`). The enabled record types are CMDT rows, not code, so the count cannot be confirmed here.

**Outbound payload** (`JiraJsonBuilder.cls:10-31`) — 12 Case fields plus the project key: `Id`, `CaseNumber`, `AccountId`, `Subject`, `Description`, `CreatedDate`, `Brand_Account__c`, `Case_Severity__c`, `Account_Name__c`, `CaseUID__c`, `Number_of_DLs_Account__c`, `Tier_Account__c`.

Comments and attachments go as **flags and counts only** — `Attachment: 'Yes'/'No'`, `AttachmentSize`, `Comments: 'Yes'/'No'`, `CommentsCount` (`:24-29`). Their content is never sent from Salesforce.

**[differs from handover]** on two counts. The FDD describes comments and attachments moving with no field updates, which is close to the inverse. And the payload carries `Subject`, `Description` and `Account_Name__c` unredacted, against the documented no-PII constraint; inbound, the batch stores reporter and assignee emails and display names. If PII exclusion and the EU-brand filter exist, they are in Boomi — `Brand_Account__c` is passed out, so the filter has what it needs there. The `Salesforce Case# : … | Commentor email : …` comment format is likewise built in Boomi; Salesforce stores the email as a discrete field (`Jira_Case_Comment__c.Jira_Commentor_Email__c`).

### Legacy path — direct HTTP

`JIRA_HTTPCallout`, `JIRA_GlobalMethods`, `JIRA_Issue_CreateUpdate`, `JIRA_Issue_BatchUpdate`, `JIRA_Issue_BatchUpdate_Scheduler`, `JIRA_CreateUpdate_Termination`, `JIRA_JSONDeserialize`.

No Named Credential. Endpoint and API key are built in Apex (`JIRA_GlobalMethods.cls:12-26`) against `http://apps.ringdemo.com/` — plaintext HTTP. `JIRA_HTTPCallout.CallOut()` (`:27-67`) performs no status check and returns `null` under test (`:60-61`), so no test exercises response handling. Security consequences in §3.1.

**Jira → SFDC.** `JIRA_Issue_BatchUpdate` (`Database.Batchable`, `AllowsCallouts`, scope 10) queries `JIRA_Case__c WHERE Status__c != 'Closed' AND RecordType.Name = 'Issue'` (`:34`) — no last-modified filter, no brand filter. Writes ~25 fields to `JIRA_Case__c` (`:161-254`), then `Jira__c`, `Jira_Case__c`, `Jira_Link__c` back to the Case (`:293-295`). Jira's *description* is deliberately not stored (`:170-172`, commented out).

**The schedule is not in the code.** `JIRA_Issue_BatchUpdate_Scheduler.cls` has no cron expression and no `System.schedule` call anywhere references it — it was scheduled imperatively. Recovery query in §3.2. Note the Apex batch and the Boomi execution plan are two different clocks, which is the likely reason the documented cadences disagree.

A third entry point: flow `Case_to_Jira` (Active, API 57.0, Update-triggered) invokes `Case.CaseToJiraTicket`, filtered on `Biz_Serv_Stage__c` and `RecordTypeName__c`.

## 1.6 Other integrations touching Case

| Integration | Code | Auth | Reference |
|---|---|---|---|
| SF-to-SF e-bonding | `PartnerNetworkConnectionHelper`, `PartnerNetworkRecordConnectionSelector`, `BatchJob_StopSharingCases` | Platform | — |
| Telus | `TelusExternalSharingHelperCls` (schedules its own job, `:572`), `HandleCaseForTelus` (`:265`), `MapContactOnTelusSharedCases` (`:815`), `UpdateAddressAndContactInfoFieldsForTelusBrand` (`:1696`) | Platform | LTR-3495 |
| NICE inContact | `ICBAPI`, `IcbHelper`, `CaseCreateServiceICB`, `CaseEventServiceICB`, `CasePollServiceICB`, `/rccc/nic/case/create` | JWT via named certificate — `HttpHelper.prepareJWTAuthHeader()` (`:86-93`), certs `ICB` / `CCB` | [NICE E-Bonding Solution](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1125979123) |
| n8n | `Case_Created_n8n`, `Case_Updated_n8n`, `Case_Comment_n8n` — 3 Active flows, API 56.0 | — | [SOED→DOS RPA runbook](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1139818725) |
| Knowledge sync | AEM and RC 411 batches | — | [AEM](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1103588345), [RC 411](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1103588513) |
| GCP / AI assist | `GCPCalloutForSimilarJiras`, `lwc/similarJirasByGCP`, `/getCaseDetailsForGCP`, `/getCaseCommentsForGCP`, `/getKnowledgeArticlesForGCP` | `callout:N8n_Similar_Jiras` | [AI Support Assist design](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1096301006) |

The n8n surface is broader than the runbook describes: the three flows fire on **every** Case create, every Case update and every Case comment, not on an SOED subset.

**Workato has zero references in this repo.** If the NICE replacement is Workato-based, none of it has landed in Salesforce.

**Named Credentials in use** (definitions not in repo): `Jira_Create`, `Jira_Link`, `NGBS_API`, `Open_AI`, `N8n_Similar_Jiras`, `Tooling_API`, `Slack_Webhooks`, `DeloitteBoultOnGSTValidation`.

**REST endpoints that write Cases:** `/SCApi/v1/case-new/*`, `/SCApi/v1/case/*`, `/SCApi/v1/caseHandler/*`, `/SCApi/v1/caseEscalate/*`, `/SCApi/v1/caseReopen/*`, `/SCApi/v1/case-events-new/*`, `/rccc/nic/case/create`, `/sf-imp-case-close/*`, `/updateCases`, `/updateCaseSubject`, `/updateCaseDescription`. 68 classes carry `@RestResource` in total.

**Callout behaviour, all paths:** timeouts are set everywhere (`HttpHelper.cls:3-4` — 120 s max, 60 s default). **Retries, backoff and rate-limit handling do not exist** on any Case path — no 429 check, no `Limits.getCallouts()` guard. A transient failure loses the work.

---

# 2. System Optimisation

In-flight scope, priorities and sizing: [Q3 2026 Committed Project Tracker](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1126461807) and the handover §2.1. This section covers only what is visible in the code.

## 2.1 Migrations part-done on this branch

Each has both the old and the new implementation deployed, which is why they need finishing rather than leaving.

### Process Builder → Flow (PBC-32990)

| Subject | Old | New | State |
|---|---|---|---|
| Routing escalation | `Consolidated_Case_Routing_Escalation_PB` (285 KB, 24 email alerts, 81 hardcoded IDs) | `Case_Routing_Escalation_After_Save` (API 67.0) | **Done** — PB Obsolete |
| Collections dispute | `Collections_Dispute_Consolidated_PB` (113 KB) | `Case_Collections_Dispute_After_Save` + `_Before_Save` | **Done** — PB Obsolete |
| Case notification | `Consolidated_case_notification_PB` (API 49.0) | `Case_Consolidated_case_notification_PB` (API 67.0) | **Not done** — PB Active, flow **Draft** |
| Case comments | — | `Case_Comments_Consolidated_PB` | Draft |

Two further Process Builders remain Active and write `OwnerId` — `B_10495_Web_Case_segmentation` (API 49.0) and `Billing_Cases` (API 51.0) — with no replacement flow in the repo.

### Before-save → after-save routing

Commit `85839f2` moved Collections Dispute and Routing Escalation to after-save so queue, status and record type are applied **after** active assignment rules rather than before. `Case_Routing_Escalation_Before_Save` was deleted; `Case_Collections_Dispute_Before_Save` was reduced to assignment-rule-independent updates.

The reason is worth internalising: a before-save flow that sets an owner is overwritten at step 8. Anything deciding ownership must run after step 8, or set `DMLOptions` deliberately.

**`Case_Escalation_Router_Before_Save` has not had this treatment** — still Active, still before-save, still writing `OwnerId`, `RecordTypeId` and `Status`, and overlapping `Case_Escalation_Router_After_Save` on `Dev Support Tier 2`. It is the next candidate.

### The parity test harness

`Test_RoutingEscalationParity.cls` (816 lines, 57 methods), `Test_CollectionsDisputeParity.cls`, `Test_PartnerCommentParity.cls`. Built to make the migration verifiable, and the quality bar for this codebase:

```apex
assertSameId(Label.CaseEsc_SOED_Queue_Id, routedCase.OwnerId, ownerMessage);
```
— `:422`, plus 12 more `OwnerId` assertions

The expected value is a **Custom Label**, so the test is valid in every environment. `assertSameId` (`:157-161`) normalises both sides to 15 characters. Negative cases assert the owner is *unchanged* when an entry condition should block (`:411`, `:487`).

The two-phase protocol is documented at `:15-17` and the file does not change between phases. It also states its own limit (`:19-23`): only 6 of 26 routing nodes write fields and are observable from Apex; the other 20 are email-alert only. **Do not read the pass count as coverage of the whole flow.**

## 2.2 Technical debt in the code

The debt *backlog* lives in the PBC Epics under LTR-3070 (see handover §2.2.1). What follows is what the code shows.

### Cross-environment ID portability

**6,114 hardcoded Salesforce ID literals**: 5,365 in `flows/`, 644 in `classes/`, 49 in `labels/`, the rest in `aura`, `lwc`, `pages`, `components`, `triggers`. Routing-relevant: **703 record-type, 191 user, 187 queue, 27 profile**.

The clearest demonstration that these are not portable is one Active flow. `Case_Record_Type_Router_After_Save.flow-meta.xml` hardcodes record-type IDs across three different org-instance segments (`:388`–`:697`) — `0122H…`, `01234…`, `01280…`. At least two of the three cannot be valid in any single org, and a record-type comparison against a non-existent ID does not error; the branch simply never fires.

Worst offenders: `Consolidated_Case_Routing_Escalation_PB` (81, Obsolete), `Case_Email_Auto_Assignment_and_Routing_Flow` (29), `Billing_Cases` (29, Active PB), `Case_Status_Closed_Flow_Migration` (25), `Case_Record_Type_Router_After_Save` (23), `Collections_Dispute_Consolidated_PB` (21, Obsolete), `B_10495_Web_Case_segmentation` (12, Active PB), `Platform_Service_Engineering_Case_Process` (9), `Case_Escalation_Router_After_Save` (9).

**The mitigation fails open, two ways.** `HardcodedIdsMapper.cls` loads a `;`-delimited `IdMapping` static resource and translates an ID to its per-environment equivalent; 68 classes use it.

```apex
String res = HARDCODED_IDS_MAP.get(hardcodedValue);
return String.isBlank(res) ? hardcodedValue: res;
```
— `:43-44`

An unmapped ID passes through unchanged, so a missing mapping is indistinguishable from a correct one. And `loadDataFromStaticResource()` catches every exception and returns an **empty map** (`:36-38`) — a missing or malformed static resource means every ID org-wide silently falls through. It does not apply to flows at all.

**The target pattern is already proven here**: the eight `CaseEsc_*` Custom Labels. Extending it is mechanical, and `Platform_Service_Engineering_Case_Process` is the highest-leverage file — one record-type ID, nine escalation paths.

### The ProServ queue constants (PBC-31776)

`QueueHelper.cls:8-16` declares all nine deleted queues, `PROSERV_QUEUES` (`:19-30`) collects them, and `ChangeOwnerForProfessionalServices` consumes them at 15 sites. Failure is silent — §1.3 layer 6 — and the tests cannot detect it (below).

### Automation convergence

32 automations write `OwnerId`, 19 write `Status`, 13 write `RecordTypeId`, and no Case flow declares `<triggerOrder>`. No automation "owns" any field, so every routing change is a change to an undocumented multi-writer contract.

Two moves, in order:

1. **Declare the order.** Setting `<triggerOrder>` on the 29 `OwnerId`-writing flows is metadata-only, carries no logic risk, and makes behaviour testable.
2. **Reduce the writers.** Only safe after step 1.

### API versions (LTR-3615)

Classes span API 20.0 → 67.0; triggers 16.0 → 64.0.

| Band | Classes | Triggers |
|---|---|---|
| ≤ 30.0 | 244 | 19 |
| 31.0 – 40.0 | 246 | 22 |
| 41.0 – 50.0 | 950 | 38 |
| 51.0 – 60.0 | 722 | 37 |
| 61.0 – 67.0 | 297 | 6 |

The **263 components below API 31.0** are the real work — a bump there changes sharing defaults, type coercion and null handling, so each needs a test. The 268 in the 31–40 band are usually mechanical. `CaseObject.trigger` and `CaseTriggerHandler` are both 58.0.

### Dead and duplicated metadata

- **10 Obsolete Case flows**, including the two largest files in `flows/`: `Consolidated_Case_Routing_Escalation_PB` (285 KB) and `Collections_Dispute_Consolidated_PB` (113 KB). Still deployed, still in every grep.
- **6 Draft Case flows**, including the PBC-32990 replacement.
- `SFDC_JIRA_Integration_test_flow` is **Active** (API 61.0) — a flow named "test flow" in the Jira integration path.
- **203 non-test classes** are never named in any test class.
- Two parallel Jira integrations (§1.5).

### Test estate (LTR-3294 / PBC-28273)

| Signal | Value |
|---|---|
| Apex test classes | 1,098 |
| …with zero assertions | **225 (20.5%)** |
| `@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')` | **1,207 occurrences across 392 classes** |
| Flow tests on disk | 89, covering 6 flows |
| Flow tests **in version control** | **0** — `.gitignore` excludes `force-app/main/default/flowtests/*` |

Not all suppressions are wrong: the three parity classes suppress the rule because they assert through a private helper PMD does not recognise. The other ~389 silenced it rather than satisfying it.

**Two specific defects to fix before trusting the suite:**

*Assertions that compare a value to itself.* `Test_CaseTriggerHandler.cls:2646-2650` and seven siblings assert `psQueuesMap.get(QUEUE_PS_CONTACT_CENTER)` against a value the method under test derives from the same map. Delete the queue and both sides are `null`, so the test passes in exactly the environment where routing is broken. Fix: look the queue up independently and `Assert.isNotNull` the expectation first.

*An assertion that cannot fail.* `:3047` — `Assert.isTrue(c.OwnerId != null, …)`. `OwnerId` is never null on a saved Case. It should assert the owner is unchanged from its pre-update value.

Sixteen zero-assertion test classes touch Case, Jira, routing or queues, including `Test_CreateCaseFromEmail` (5 suppressions) and `Test_CreateCoopsJiraController`.

The eight Prod Test Class Fix sets (PBC-30268, 30699, 31040, 31115, 31207, 31304, 31306, 31691) are all Closed/Done, but five classes they covered still contain zero assertions: `TestLeadClonePageController`, `EUPrivacyTest`, `Quote_PartnerDetailController_Test`, `Quote_PartnerQuoteEngageLegalTest`, `Test_IgniteLoginFormController`. Those tickets restored deployability, not verification.

### Error handling that hides failures

| Location | Behaviour |
|---|---|
| `CaseTriggerHandler.cls:894-896` | `CaseCreationOnPRM` catches `Exception`, sets `Sales_Owner_Manager_Email__c = null` |
| `CaseTriggerHandler.cls:2655-2657` | `RoundRobinAssignment.getAssignees` catches `Exception`, returns empty → case silently unrouted (`:2613`) |
| `HardcodedIdsMapper.cls:36-38` | Catches `Exception`, returns empty map → every ID org-wide untranslated |
| `CreateJiraController.cls:160-162` | `isJiraLinked` catches `Exception`, returns `false` → UI offers "Create Jira" on a linked case |

Only `CreateJiraController` logs (`:142-146`).

### What is not a problem

Recorded so it does not get "fixed":

- **No SOQL or DML in loops** in the Case trigger path — the handlers are bulkified. The one apparent hit, `JIRA_Issue_BatchUpdate.cls:280`, is a SOQL for-loop, which is correct.
- **`@isTest(SeeAllData=true)` appears once** in 2,459 classes, not on the Case path.
- **Record-type resolution in Apex is by name throughout.**
- **Injection surface is well controlled** — 176 `String.escapeSingleQuotes` sites against 159 `Database.query` sites, only 9 of which concatenate.

## 2.3 Code-level sequence

Complements the handover §4 prioritisation, which is business-weighted. This is dependency order.

1. Fix the eight vacuous ProServ assertions — the tripwire for everything below.
2. Remove the nine ProServ queue constants; collapse to the single `Professional Services` queue.
3. Add `Assert.isNotNull` before every queue-ID assignment on the Case path; `CaseRouting.cls:36-38` is the model.
4. Unignore `flowtests/`; commit the 69 live tests, delete the 20 orphaned ones targeting the deleted before-save flow.
5. Replace the hardcoded record-type ID in `Platform_Service_Engineering_Case_Process` with a Custom Label — nine paths, one edit.
6. Set `<triggerOrder>` on the 29 `OwnerId`-writing flows.
7. Migrate `Case_Escalation_Router_Before_Save` to after-save, resolving the overlap.
8. Finish the notification PB→Flow migration.
9. Then consolidate the `OwnerId` writers.

---

# 3. System Maintenance & Operations

## 3.1 Security and access

Policy and in-flight security work: handover §3.1, [LTR-1968 — Limit Record Type Access to Support Agents](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1100347223), and [RingCentral Salesforce Partner Portals](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1150956576) for the partner-side sharing model. This section covers what the code enforces.

### Access decisions made in Apex

Case-path access is decided against **profile names and IDs**, so renaming a profile changes Apex behaviour silently.

`ProfileHelper.cls` holds 78 profile constants in named sets:

| Set | Size | Purpose |
|---|---|---|
| `ADMIN_OR_CRM_PROFILES` (`:123-150`) | 27 | Broad admin/CRM grouping |
| `CRM_PROFILES` (`:151-159`) | 7 | Comment at `:158` — "Added New Integration Profile to **Skip Validation**" |
| `EXCLUSION_PROFILES` (`:161-166`) | 4 | System Administrator, CRM Developer, CRM QA Engineer, CRM Support Engineer |

Two entries in `ADMIN_OR_CRM_PROFILES` are worth checking against the org because their names understate the grouping: `PROFILE_NAME_READ_ONLY` (`:147`) and `PROFILE_NAME_MINIMUM_ACCESS_SALESFORCE` (`:144`). The same set carries eleven API and integration profiles — directly relevant to the LTR-3615 "integration users to No Access" workstream, since moving any of them changes whatever branches on membership.

Case-path profile gates: `CaseTriggerHandler.cls:903` and `:914` (sysadmin), `:1811` (`isSupportT1Profile` **or** a custom permission — note the `or`; the profile alone is not the whole grant), `CaseHelper.cls:984` (deal desk).

Two profile IDs are hardcoded through `HardcodedIdsMapper`: `PROFILE_ID_SYSADMIN` (`ProfileHelper.cls:4`, referenced **72 times**) and `PROFILE_ID_CUSTOMER_PORTAL_USER` (`:8`, 16 times). If `IdMapping` lacks a row, `isSysAdmin()` (`:214`) compares against another org's ID and returns false for everyone, at all 72 call sites.

### Sharing

| Declaration | Classes |
|---|---|
| `with sharing` | 574 |
| `without sharing` | 128 |
| `inherited sharing` | 142 |
| none declared | ~1,615 |

`CaseTriggerHandler` and `CaseRouting` are `with sharing`. `HardcodedIdsMapper` is `without sharing`, appropriately.

Review the community- and portal-facing `without sharing` classes first, because that is where over-exposure becomes external: `SupportCommunityNewCase`, `PrmCaseCreateHelper`, `SCCaseService`, `SCAPICaseService`, `PurchaseCase`, `RCSupportAdvCaseDetail`, `DeserializeCaseCommentBody`, `DealDeskCaseDescriptionHelper`.

### Credentials

Current integrations use Named Credentials or JWT-with-named-certificate (§1.6). **The legacy Jira path does not** — `JIRA_GlobalMethods.cls:20-26` returns hardcoded production and staging API keys, used against `http://apps.ringdemo.com/` (`:14`), plaintext. The production key is repeated in comments at `JIRA_HTTPCallout.cls:109` and `:132`.

Both keys are in git history. **Treat the production key as compromised and rotate it**, independently of whether the legacy path still executes. There is no credential inventory or rotation procedure (handover G13).

### The kill switch

```apex
ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
if (bypassTrigger != null && bypassTrigger.Bypass_Case_Trigger__c == true) {
    System.debug('$$$ ByPassTrigger__c Active For Case Credit $$$');
    return;
}
```
— `CaseObject.trigger:3-7`

A hierarchy custom setting that disables **all** Case Apex for a user or profile. `Bypass_Case_Trigger__c` is referenced in exactly one place in the repo — that line — and its purpose is recoverable only from the debug string: it exists so the Agent Credit process can bypass the trigger. No test asserts it is off; no audit of who may set it.

**When Case automation "just stops working" for one user or profile, check this first.**

## 3.2 Operating the system

No case-routing runbook exists (handover G10). This section is the code-level substitute. For the Jira interface, the process runbook — restart procedure, Boomi process reporting, L1/L2 incidents, escalation path — is [Jira to SFDC Integration Process Runbook](https://wiki.ringcentral.com/pages/viewpage.action?pageId=582679012); use it for process and this for where the behaviour comes from.

### Diagnosing a misrouted case

Work the pipeline in save order, because later steps overwrite earlier ones.

| Check | How |
|---|---|
| 1. Is the trigger running at all? | `ByPassTrigger__c` for that user/profile (§3.1). Also `TriggerHandler.BY_PASS_*` if something upstream set them in-transaction. |
| 2. Did a before-save flow set the owner? | 7 Active before-save flows; `Case_Escalation_Router_Before_Save` is the one that writes `OwnerId`. |
| 3. Did Apex set it? | 9 Apex sites (§1.3 layer 4). Field history on `OwnerId` plus debug logs on handler order. |
| 4. **Did an assignment rule overwrite it?** | Step 8. Most common cause. Rules are not in source control — check in Setup. A case on `RC Support Agent` is almost always this. |
| 5. Did an after-save flow overwrite it? | 29 flows write `OwnerId`, unordered. Hardest step, and why `<triggerOrder>` matters. |
| 6. Was the queue resolvable? | For a ProServ queue, a deleted queue yields a **null** owner and the case falls to its creator with no error (§1.3 layer 6). |

Field history on `OwnerId` is the fastest single signal — it shows the sequence of writes, not just the final state.

### Diagnosing a Jira sync failure

| Symptom | Where to look |
|---|---|
| "Create Jira" returns an error string | `createJira` returns typed messages: `ERROR_JIRA_TICKET_EXISTS`, `ERROR_ESCALATE_TO_QUEUE_BLANK`, `Error: No Jira project mapping found for queue: {0}` (missing CMDT row), `Jira creation failed with status {0}` (non-2xx from Boomi) |
| Button unavailable / access denied | `JiraAccessPermissionService` — the profile/record-type CMDT rows (§1.5) |
| Exception with no message | Exception history — `logToExceptionHistory(e, caseId, 'createJira')`, `CreateJiraController.cls:144` |
| Jira → SFDC updates missing | The batch, whose cadence is not in the code — query below |
| Transient failure lost the work | Expected. No retry, no queue, no dead-letter on any Case callout (§1.6). Re-trigger manually. |

```sql
SELECT CronJobDetail.Name, CronExpression, NextFireTime, PreviousFireTime, State
FROM CronTrigger WHERE CronJobDetail.Name LIKE '%JIRA%'
```

### Diagnosing duplicate cases

No idempotency guard exists on REST case creation (§1.2), so duplicates under retry are expected behaviour, not a defect to hunt. The durable fix is an external ID plus `upsert` at `CaseCreateStrategy.cls:193` and `:306`.

### What has no alerting

No monitoring or alerting configuration exists in this repo for any Case automation, and the four silent-failure paths in §2.2 produce no signal. The cheapest detective control is a saved report of cases owned by the catch-all queue, or unassigned, beyond a threshold — reviewed daily.

## 3.3 Routine administration

Ticketing, hierarchy, deployment lifecycle and comment conventions: [`docs/jira-process.md`](jira-process.md). Project closure: [Closure. Project Jira Management](https://wiki.ringcentral.com/spaces/CRM/pages/1014304771/Closure.+Project+Jira+Management). Merge calendar: [QTC GCI Merge Schedule 2026 Q3](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1157973539). Data retention: [Salesforce Data Archival and Retention](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1078451925), [SFDC Data Retention Policy](https://wiki.ringcentral.com/pages/viewpage.action?pageId=964022090), [Support Case retention and purging](https://wiki.ringcentral.com/pages/viewpage.action?pageId=560762652). None repeated here.

### Changing Case automation safely

1. **Check the field-ownership table** (§1.4) before writing any field. Assume another automation writes it too.
2. **Check which trigger block** a handler sits in (§1.4). Block 2 does not re-run on a second save.
3. **Never delete a `.bind()` line** without a failing test proving it mattered. Each of the 60 bindings is a single line whose removal compiles, deploys and fails silently — this is the PBC-33007 shape. The CERT path (`CaseObject.trigger:23`, `:40`) is the one binding with asserting tests behind it.
4. **Resolve queues and record types by name**, or via a Custom Label. Never add an ID literal to a flow.
5. **Assert on the routing outcome**, not on coverage. `Test_RoutingEscalationParity` is the model.

### Build and deploy

`sourceApiVersion` 66.0 (`sfdx-project.json`); `manifest/package.xml` is the retrieve manifest.

`.husky/pre-commit` runs `lint-staged` (`package.json:16`). Prettier covers Apex, Aura, LWC, XML and Markdown via `@prettier/plugin-xml` (`:13-14`); ESLint covers `aura` and `lwc` JavaScript only (`:7`). **Nothing in the hook chain runs Apex tests or PMD**, which is why the assertion-suppression pattern in §2.2 was never caught at commit time.

Test naming is `Test_<ClassName>`, with `SObjectBuilder` / `SObjectFactory` / `ValueProvider` as fixture helpers (PBC-28273). Suites are in `force-app/main/default/testSuites/`. Before relying on a green run, note that 20.5% of test classes assert nothing.

GCI and BISUAT are separate codebases in practice (PBC-32259). A change validated here is not validated there.

## 3.4 What is not in source control

The most important operational fact in this document. These cannot be reviewed, diffed or rolled back through this repo — and several are the layers where routing incidents originate.

| Missing | Why it matters | How to get it |
|---|---|---|
| **Assignment rules** | Save-order step 8; the usual cause of a case landing on `RC Support Agent` | `sf project retrieve start -m AssignmentRules:Case` |
| Escalation, auto-response, duplicate, matching rules | Steps 5, 9, 11 | `-m EscalationRules:Case,AutoResponseRules:Case,DuplicateRule,MatchingRule` |
| **Case object, fields, validation rules, record types** | No field definitions, no validation rules, no `Jira__c` / `Jira_Link__c` / `Jira_Case__c` / `Jira_Comments_Tab_Visible__c` | `-m CustomObject:Case` |
| Profiles, permission sets, FLS | The Jira field lock, integration-user access, everything in §3.1 the code does not decide | `-m Profile,PermissionSet` |
| **CMDT records** — `Jira_Queue_Mapping__mdt`, `CaseRoutingBySupportType__mdt`, `SF_Jira_Profile_RecordType_Permission__mdt`, `Generic_E2C_setting__mdt` | The routing table, the Jira project map and the Jira access list are configuration with no version history | `-m CustomMetadata` |
| Named Credentials, Remote Site Settings | Every integration endpoint and auth mode | `-m NamedCredential,RemoteSiteSetting` |
| Page layouts, flexipages, list views, reports | Needed for any unused-field analysis | `-m Layout,FlexiPage,Report` |
| Email-to-Case routing addresses | The CERT addresses and every other E2C entry point | `SELECT EmailAddress, CaseOwnerId FROM EmailToCaseRoutingAddress` |
| Scheduled job cadences | The Jira batch and every other `Schedulable` | `SELECT CronJobDetail.Name, CronExpression, State FROM CronTrigger` |
| **Flow tests** | 89 files exist on disk; `.gitignore` excludes `force-app/main/default/flowtests/*` | Remove the ignore line |

Queries that answer questions this repo cannot:

```sql
-- Case field count and limit headroom
SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Case'

-- Who has broad Case access
SELECT Parent.Profile.Name, PermissionsRead, PermissionsEdit, PermissionsModifyAllRecords
FROM ObjectPermissions WHERE SobjectType = 'Case'

-- FLS on the Jira fields
SELECT Parent.Profile.Name, Field, PermissionsRead, PermissionsEdit
FROM FieldPermissions WHERE SobjectType = 'Case' AND Field LIKE 'Case.Jira%'
```

For genuine unused-field analysis use the Tooling API `MetadataComponentDependency` object — it returns real reference edges. A code-only scan gives a wrong answer here, because Case is manipulated far more by 136 flows and by page layouts than by Apex.

---

## Provenance

Read from `main` at commit `85839f2`, re-verified at `7d60439` (2026-09-17) — the Case path is unchanged between them. Jira statuses quoted were pulled from `jira.ringcentral.com` on 2026-09-15.

Six passages are marked **[differs from handover]**. The two that change how you operate the system are the Jira sync payload (§1.5) and the ProServ queue constants (§1.3 layer 6).
