# LTR-4160: RCX Dialer for CSE Outbound (Salesforce side)

Loads qualifying CERT Cases into RingCX outbound campaigns through the Lead Loader (direct) API.

## Status of this package

- Built against the **production org's code** (read through the Salesforce connector), not the
  `master` branch: the GitLab repo was not reachable from where this was built. Check the
  `CaseObject` trigger and `Triggers`, `PlatformEvents`, `PlatformLog`, `PlatformEventsUtil`
  classes on master match production before merging.
- **Not compiled or deployed.** The Apex passed a syntax parser only. Validate in a sandbox first.
- Nothing on master was changed. All files are new, except one line to add to `CaseObject.trigger`
  (see `docs/CaseObject.trigger.change.md`).
- Ships **switched off**: every campaign mapping is inactive.

## Flow

1. `CaseObject` trigger (after insert) -> `RCXLeadCaseTriggerHelper` publishes `RCX_Lead_Request__e`
   for CERT Cases whose Subject has an active campaign mapping.
2. `RCXLeadRequest` trigger (runs as the integration user) -> `RCXLeadRequestTriggerHelper`
   enqueues `RCXLeadLoaderQueueable`.
3. The Queueable queries the Cases, builds leads (`RCXLeadBuilderSvc`), gets a token
   (`RCXAuthSvc`), posts one call per campaign chunk (`RCXClientSvc`) and writes one
   `RCX_Lead_Log__c` per Case (`RCXLeadLogSvc`).
4. Retry after failure: on HTTP 429 / 5xx / callout errors the job re-enqueues itself after
   1, 2, 4, 8 minutes (`Retry-After` wins when longer). After 5 tries the Case is logged `Failed`.
   There is no scheduled job.

## Components

| Type            | Name                                          | Purpose                                                     |
| --------------- | --------------------------------------------- | ----------------------------------------------------------- |
| Apex            | `RCXConfig`                                   | Subject -> account/campaign map and fixed request values    |
| Apex            | `RCXLeadCaseTriggerHelper`                    | Case after-insert handler, publishes events only            |
| Trigger         | `RCXLeadRequest`                              | Platform Event subscriber                                   |
| Apex            | `RCXLeadRequestTriggerHelper`                 | Enqueues the loader job                                     |
| Apex            | `RCXLeadLoaderQueueable`                      | Queries, build, send, retry, logging                        |
| Apex            | `RCXLeadBuilderSvc`, `RCXLead`                | Phone cleanup and payload                                   |
| Apex            | `RCXAuthSvc`                                  | RingCentral JWT grant, RingCX token exchange                |
| Apex            | `RCXClientSvc`                                | Lead Loader call, one 401 refresh                           |
| Apex            | `RCXLeadLogSvc`                               | Upserts one log per Case                                    |
| Tests           | `Test_RCX*`, `RCXTestData`                    | 26 test methods, no DML on Case/Account/Contact             |
| Event           | `RCX_Lead_Request__e`                         | Case Id, publish after commit                               |
| Object          | `RCX_Lead_Log__c`                             | Sent / Skipped / Rejected / Retrying / Failed per Case      |
| Metadata type   | `RCX_Campaign_Mapping__mdt`                   | Case Subject -> accountId + campaignId, with an active flag |
| Credentials     | `RCX_Dialer`, `RC_Platform`, `RingCX_API`     | Custom External Credential + 2 Named Credentials            |
| Permission sets | `RCX_Integration_Access`, `RCX_Lead_Log_Read` | Integration user; read-only for CERT                        |
| Config          | `RCXLeadRequestConfig`                        | Run-as user and batch size for the event trigger            |

## Field mapping (as built)

| RingCX field                                               | Source                                                                       |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------- |
| externId                                                   | Case.Id                                                                      |
| leadPhone                                                  | Case.ContactPhone, else Contact.Phone, else Contact.MobilePhone; 10 digits   |
| leadPhoneE164                                              | +1 + leadPhone                                                               |
| firstName, lastName                                        | Case Contact                                                                 |
| email                                                      | Case.ContactEmail, else Contact.Email                                        |
| state, zip                                                 | Account.BillingState, Account.BillingPostalCode                              |
| maxPasses                                                  | 3 (constant)                                                                 |
| auxData1, auxData2                                         | Case.Subject, Case.CaseNumber                                                |
| description                                                | `CERT - <Subject> - <UTC time>` (one list per call, so no single CaseNumber) |
| dialPriority, duplicateHandling, listState, timeZoneOption | Constants in `RCXConfig`: NORMAL, REMOVE_FROM_LIST, ACTIVE, NOT_APPLICABLE   |
| accountId, campaignId (URL)                                | `RCX_Campaign_Mapping__mdt`                                                  |

## Rules as built

- CERT record type only (`DeveloperName = 'CERT'`); Subject matched exactly, ignoring case and spaces.
- Only the Case's own Contact is used. No Contact, or no valid 10-digit phone: logged `Skipped`.
- Do Not Call flags in Salesforce are ignored. RingCX still applies its own DNC lists.
- Non US/CA numbers (not 10 digits after cleanup) are skipped.
- A Case with a Sent log is never sent again.
- On/off: the integration runs while at least one mapping is active. Deactivate all to stop it.

## Setup per org

1. Replace `REPLACE_WITH_INTEGRATION_USERNAME` in
   `platformEventSubscriberConfigs/RCXLeadRequestConfig...` with the integration user's username
   (it differs per org), then deploy.
2. External Credential `RCX_Dialer` -> principal `Integration` -> add secret parameters
   `client_id`, `client_secret`, `jwt` (not deployable, enter by hand).
3. Assign `RCX_Integration_Access` to the integration user.
4. Add the one line to `CaseObject.trigger`.
5. Smoke-test the token as the integration user.
6. Fill `Account_Id__c` and `Campaign_Id__c` on each `RCX_Campaign_Mapping` record and set
   `Is_Active__c = true`. This turns the integration on.

## Unconfirmed, check before go-live

- **Token flow** (`RCXAuthSvc`): RingCentral JWT grant with Basic client auth, then
  `POST /api/auth/login/rc/accesstoken` with `rcAccessToken`. Both shapes are assumptions to
  confirm with the RingCX team. Paths and request bodies are in `RCXAuthSvc`.
- **Basic header formula** in `RCXAuthSvc.BASIC_AUTH_FORMULA`: verify it resolves in the smoke test.
- **rejectedRows shape**: a rejected row is matched to a Case by finding the Case Id in the row.
  If RingCX returns a different shape, rejected leads show as Sent with a note in `Reason__c`.
- **Max leads per call**: `RCXConfig.CHUNK_SIZE` is 100 until RingCX states the limit.
- **Timeouts**: a timed-out call is retried, and RingCX may have accepted the first one.
  `REMOVE_FROM_LIST` is relied on to avoid double dialling.
- **Failed after 5 tries**: nothing re-sends these automatically. Re-run from Anonymous Apex:
  `System.enqueueJob(new RCXLeadLoaderQueueable(caseIds, 0));`
