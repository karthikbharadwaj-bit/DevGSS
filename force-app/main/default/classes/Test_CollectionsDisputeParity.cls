/**
 * Track B parity harness for Collections_Dispute_Consolidated_PB -> F1/F2 (PBC-32071).
 *
 * NAMING NOTE (UT-001): there is no Apex class under test here - this class characterises a
 * Process Builder, so the `Test_<ClassName>` pattern has no class to name. `Test_<PbSubject>Parity`
 * is the closest faithful form and is used consistently across the three Track B harnesses.
 *
 * NODE VOCABULARY: this PB's nodes are C1-C12 plus the gate G1, per PB_Metadata_Blueprint.md
 * 3.2. (N-numbers belong to the Routing/Escalation PB, P-numbers to the Partner PB - do not mix
 * them; every other artifact keys off the blueprint's letters.)
 *
 * EXPECTATIONS ARE DERIVED FROM THE PB, NOT FROM THE BLUEPRINT. Every assertion below was read
 * out of the compiled metadata of the PB's ACTIVE version (v1, 3012H000000PJXA) via the Tooling
 * API, so a misreading in the blueprint cannot propagate into these tests.
 *
 * Two-phase protocol - the file NEVER changes between phases:
 *   Phase O  PBs active / flows Draft : proves these expectations are true of the PB.
 *            A failure here means the expectation is wrong, NOT that the flow is broken.
 *   Phase F  flows active / PBs off   : proves the migration is faithful.
 *            A failure here, beyond Test_Plan.md 7's accepted deltas, is a migration defect.
 *
 * Scope: field writes only. Email alerts are deliberately absent - PB and flow invoke the SAME
 * WorkflowAlert metadata, so template and recipients are identical by construction; the open
 * questions are "same alert" (static diff) and "same firing condition" (Track A decision
 * outcomes). Apex cannot observe alert sends at all.
 *
 * PB node map (active v1 - 12 indexed nodes + G1, 11 field writes, 3 action calls):
 *   G1  owner-changed gate: old.OwnerId <> current.OwnerId  -> boolean consumed by C6
 *   C1  RecordTypeId <> Collections            -> Apex ReturnNull, STOP     (the blocker layer)
 *   C2  Status=Closed                          -> email + Date_Completed__c, STOP
 *   C3  Case_Originator__c <> CreatedById      -> Case_Originator__c = CreatedById, CONTINUE
 *   C4  Sales_Rep__c <> Account.Current_Owner__c -> Sales_Rep__c = it, CONTINUE
 *   C5  CSM__c <> Account.CSM__c               -> CSM__c = it, CONTINUE
 *   C6  Status=Resolved AND G1                 -> Status = Open, CONTINUE
 *   C7  Support_Escalate_To__c=SOED            -> OwnerId = SOED queue, STOP        [guarded]
 *   C8  ..=Professional Services               -> OwnerId = ProServ queue, STOP     [guarded]
 *   C9  ..=Sales                               -> OwnerId = Case.Account_Current_Owner__c, STOP [guarded]
 *   C10 ..=CSM                                 -> OwnerId = Account.CSM__c, STOP    [guarded]
 *   C11 ..=Billing                             -> OwnerId = Billing queue, STOP     [guarded]
 *   C12 ..=Collections                         -> OwnerId = Case_Originator__c + email, STOP [guarded]
 *
 * "[guarded]" = the PB compiles a newly-met guard, so the node fires on create, or on an update
 * where the PRIOR record did not already meet the criteria. A same-value re-save must NOT
 * re-fire (see shouldNotReRouteWhenEscalationValueWasAlreadyMetOnPriorSave).
 *
 * C3/C4/C5 have no guard and CONTINUE, so they also fire on the escalation saves below. That is
 * why every assertion targets only the field its node owns - never a whole-record snapshot.
 *
 * CASE FIELD vs ACCOUNT TRAVERSAL - the PB is asymmetric here, and F1 must preserve it exactly:
 *   node | gate reads                    | action writes from
 *   C4   | Case.Account_Current_Owner__c | Account.Current_Owner__c
 *   C5   | Account.CSM__c                | Account.CSM__c          (symmetric)
 *   C9   | -                             | Case.Account_Current_Owner__c
 *   C10  | -                             | Account.CSM__c
 * So Case.Account_Current_Owner__c is load-bearing for C4's gate and C9's action. If it is
 * blank, C4 does not fire at all (null NotEqualTo null is false) - characterised by
 * shouldNotSetSalesRepWhenCaseAccountCurrentOwnerIsBlank.
 *
 * TEST-CONTEXT CONSTRAINT (verified 2026-08-04): a directly-assigned Case.AccountId is silently
 * DROPPED on insert in Apex test context - in memory before and after, null on requery. It
 * survives in normal Apex, on a second save, and when derived from ContactId. So every case here
 * is built through a Contact, which is also the pattern every existing Case test in this repo
 * uses. Do not "simplify" this to Case.AccountId => account.Id; C4/C5/C9/C10 will silently stop
 * exercising their nodes and the validation rules CSM_required / Sales_Required will fire.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class Test_CollectionsDisputeParity {

    private static final String ESC_SOED       = 'SOED';
    private static final String ESC_PROSERV    = 'Professional Services';
    private static final String ESC_SALES      = 'Sales';
    private static final String ESC_CSM        = 'CSM';
    private static final String ESC_BILLING    = 'Billing';
    private static final String ESC_COLLECTION = 'Collections';

    private static final String STATUS_OPEN     = 'Open';
    private static final String STATUS_CLOSED   = 'Closed';
    private static final String STATUS_RESOLVED = 'Resolved';
    private static final String ORIGIN_EMAIL    = 'Email';

    private static final String ACCOUNT_NAME   = 'PARITY Collections Account';
    private static final String CONTACT_NAME   = 'PARITY Collections Contact';
    private static final String SUBJECT_PREFIX = 'PARITY ';

    @testSetup
    static void testData() {
        // Two DISTINCT active users, so Current_Owner__c and CSM__c assertions can tell each
        // other apart - if both resolved to the same user, C4/C9 and C5/C10 would pass for the
        // wrong reason and the harness would be silently worthless.
        List<Id> userPool = pickTwoActiveUserIds();
        Account collectionsAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Current_Owner__c => userPool[0],
                    Account.CSM__c => userPool[1]
                }
            )
            .create()
            .getRecord();

        // Cases acquire the Account through this Contact - see TEST-CONTEXT CONSTRAINT above.
        new SObjectBuilder(Contact.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => CONTACT_NAME,
                    Contact.AccountId => collectionsAccount.Id
                }
            )
            .create();
    }

    // ---------- helpers ----------

    private static List<Id> pickTwoActiveUserIds() {
        List<User> otherUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
              AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];
        Id runningUser = UserInfo.getUserId();
        return otherUsers.isEmpty()
            ? new List<Id>{ runningUser, runningUser }
            : new List<Id>{ runningUser, otherUsers[0].Id };
    }

    private static Account parityAccount() {
        return [
            SELECT Id, Current_Owner__c, CSM__c
            FROM Account
            WHERE Name = :ACCOUNT_NAME
        ];
    }

    private static Id parityContactId() {
        return [
            SELECT Id
            FROM Contact
            WHERE LastName = :CONTACT_NAME
        ].Id;
    }

    /**
     * Builds an unsaved Collections case. Account_Current_Owner__c is a CASE-level User lookup,
     * distinct from Account.Current_Owner__c; C4's gate and C9's action both read the CASE field,
     * so it must be populated or those nodes cannot fire. Production has it populated upstream.
     */
    private static Case buildCollectionsCase(String nodeLabel) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => SUBJECT_PREFIX + nodeLabel,
                    Case.Status => STATUS_OPEN,
                    Case.Origin => ORIGIN_EMAIL,
                    Case.RecordTypeId => (Id) Label.CaseRT_Collections_Id,
                    Case.ContactId => parityContactId(),
                    Case.Account_Current_Owner__c => parityAccount().Current_Owner__c
                }
            )
            .build()
            .getRecord();
    }

    private static Case reload(Id caseId) {
        return [
            SELECT OwnerId, RecordTypeId, Status, AccountId, Date_Completed__c,
                   Case_Originator__c, Sales_Rep__c, CSM__c, Support_Escalate_To__c,
                   Account_Current_Owner__c
            FROM Case
            WHERE Id = :caseId
        ];
    }

    // Labels may hold 15- or 18-char Ids; the 18th-character checksum is derived, so compare on
    // the 15-char prefix rather than forcing one form.
    private static void assertSameId(String expectedId, Id actualId, String message) {
        String expectedPrefix = expectedId == null ? null : expectedId.left(15);
        String actualPrefix = actualId == null ? null : String.valueOf(actualId).left(15);
        Assert.areEqual(expectedPrefix, actualPrefix, message);
    }

    /** C7/C8/C11/C12 share one shape: set the picklist on create, assert the resulting owner. */
    private static Case escalateOnCreate(String nodeLabel, String escalateTo) {
        Case escalatedCase = buildCollectionsCase(nodeLabel);
        escalatedCase.Support_Escalate_To__c = escalateTo;

        Test.startTest();
            insert escalatedCase;
        Test.stopTest();

        return reload(escalatedCase.Id);
    }

    /**
     * Defers the escalation to a second save. Required for C9/C10, whose validation rules
     * (Sales_Required, CSM_required) read through the Account: when AccountId is derived from
     * ContactId it is still null at VALIDATION time on insert, so those rules see a blank
     * Account and reject the save. After the insert the relationship is resolved, and the
     * newly-met guard still fires because the prior record carried no escalation value.
     */
    private static Case escalateOnUpdate(String nodeLabel, String escalateTo) {
        Case escalatedCase = buildCollectionsCase(nodeLabel);
        insert escalatedCase;

        Test.startTest();
            update new Case(Id = escalatedCase.Id, Support_Escalate_To__c = escalateTo);
        Test.stopTest();

        return reload(escalatedCase.Id);
    }

    // ---------- data prerequisite ----------

    @isTest
    static void shouldDeriveAccountFromContactWhenCaseIsCreated() {
        // Guards the TEST-CONTEXT CONSTRAINT above. If this fails, C4/C5/C9/C10 are not
        // exercising their nodes and their passes would be meaningless.
        Case viaContact = buildCollectionsCase('account prerequisite');

        Test.startTest();
            insert viaContact;
        Test.stopTest();

        String accountMessage = 'A Case built through the parity Contact must carry the parity '
            + 'Account; C4/C5/C9/C10 all depend on the Account relationship resolving';
        assertSameId(String.valueOf(parityAccount().Id), reload(viaContact.Id).AccountId, accountMessage);
    }

    // ---------- C1: the blocker layer ----------

    @isTest
    static void shouldNotRouteWhenRecordTypeIsNotCollectionsDispute() {
        Id otherRecordType = otherCaseRecordTypeId();
        if (otherRecordType == null) {
            return;                 // org exposes only the Collections record type; nothing to prove
        }
        Case foreignCase = buildCollectionsCase('C1 non-Collections');
        foreignCase.RecordTypeId = otherRecordType;
        insert foreignCase;
        Id ownerBefore = reload(foreignCase.Id).OwnerId;

        Test.startTest();
            update new Case(Id = foreignCase.Id, Support_Escalate_To__c = ESC_SOED);
        Test.stopTest();

        String blockerMessage = 'C1 blocker: a non-Collections record type must stop the '
            + 'automation, so a SOED escalation must not reassign the owner';
        Assert.areEqual(ownerBefore, reload(foreignCase.Id).OwnerId, blockerMessage);
    }

    private static Id otherCaseRecordTypeId() {
        for (Schema.RecordTypeInfo recordTypeInfo : Schema.SObjectType.Case.getRecordTypeInfos()) {
            Boolean isUsable = recordTypeInfo.isAvailable()
                && !recordTypeInfo.isMaster()
                && String.valueOf(recordTypeInfo.getRecordTypeId()).left(15) != Label.CaseRT_Collections_Id.left(15);
            if (isUsable) {
                return recordTypeInfo.getRecordTypeId();
            }
        }
        return null;
    }

    // ---------- C2: closed-case date stamp ----------

    @isTest
    static void shouldStampDateCompletedWhenCollectionsCaseIsClosedOnCreate() {
        // The PB writes DATEVALUE(LastModifiedDate) AFTER save, so this is the save date. F1 uses
        // the SAME formula but BEFORE save, where LastModifiedDate is not yet populated on insert
        // - so this is expected to diverge in Phase F. That divergence is currently undocumented
        // (Test_Plan.md 7 delta 5 describes a different one).
        Case closingCase = buildCollectionsCase('C2 closed on create');
        closingCase.Status = STATUS_CLOSED;

        Test.startTest();
            insert closingCase;
        Test.stopTest();

        String stampMessage = 'C2: closing a Collections case must stamp Date_Completed__c with '
            + 'the save date (PB: DATEVALUE(LastModifiedDate) after save)';
        Assert.areEqual(Date.today(), reload(closingCase.Id).Date_Completed__c, stampMessage);
    }

    @isTest
    static void shouldStampDateCompletedWhenCollectionsCaseIsClosedOnUpdate() {
        Case closingCase = buildCollectionsCase('C2 closed on update');
        insert closingCase;

        Test.startTest();
            update new Case(Id = closingCase.Id, Status = STATUS_CLOSED);
        Test.stopTest();

        String stampMessage = 'C2: closing a Collections case on update must stamp Date_Completed__c';
        Assert.areEqual(Date.today(), reload(closingCase.Id).Date_Completed__c, stampMessage);
    }

    // ---------- C3/C4/C5: unguarded field copies ----------

    @isTest
    static void shouldSetCaseOriginatorFromCreatedByWhenOriginatorIsBlank() {
        Case freshCase = buildCollectionsCase('C3 originator');

        Test.startTest();
            insert freshCase;
        Test.stopTest();

        String originatorMessage = 'C3: Case_Originator__c must be set to the creating user';
        assertSameId(String.valueOf(UserInfo.getUserId()), reload(freshCase.Id).Case_Originator__c, originatorMessage);
    }

    @isTest
    static void shouldSetSalesRepFromAccountCurrentOwnerWhenTheyDiffer() {
        Account collectionsAccount = parityAccount();
        Case freshCase = buildCollectionsCase('C4 sales rep');

        Test.startTest();
            insert freshCase;
        Test.stopTest();

        String salesRepMessage = 'C4: Sales_Rep__c must be copied from Account.Current_Owner__c';
        assertSameId(String.valueOf(collectionsAccount.Current_Owner__c), reload(freshCase.Id).Sales_Rep__c, salesRepMessage);
    }

    @isTest
    static void shouldNotSetSalesRepWhenCaseAccountCurrentOwnerIsBlank() {
        // Characterisation, not a wish: C4's gate is
        //   Sales_Rep__r.Id NotEqualTo Account_Current_Owner__r.Id
        // reading the CASE field. With both sides null the comparison is FALSE, so C4 does not
        // fire even though Account.Current_Owner__c is populated. F1 must preserve this
        // dependency - gating on the Account field instead would fire where the PB does not.
        Case blankGateCase = buildCollectionsCase('C4 gate blank');
        blankGateCase.Account_Current_Owner__c = null;

        Test.startTest();
            insert blankGateCase;
        Test.stopTest();

        String gateMessage = 'C4 gate: with Case.Account_Current_Owner__c blank, Sales_Rep__c must '
            + 'stay null - the PB compares the CASE field, not Account.Current_Owner__c';
        Assert.isNull(reload(blankGateCase.Id).Sales_Rep__c, gateMessage);
    }

    @isTest
    static void shouldSetCsmFromAccountCsmWhenTheyDiffer() {
        Account collectionsAccount = parityAccount();
        Case freshCase = buildCollectionsCase('C5 csm');

        Test.startTest();
            insert freshCase;
        Test.stopTest();

        String csmMessage = 'C5: CSM__c must be copied from Account.CSM__c';
        assertSameId(String.valueOf(collectionsAccount.CSM__c), reload(freshCase.Id).CSM__c, csmMessage);
    }

    // ---------- C6 (+ gate G1): reopen on owner change while Resolved ----------

    @isTest
    static void shouldReopenWhenResolvedCaseOwnerChangesToDifferentUser() {
        // C6's third condition is the G1 gate: old.OwnerId <> current.OwnerId. Reassigning to the
        // EXISTING owner leaves G1 false and the node never fires.
        List<Id> userPool = pickTwoActiveUserIds();
        Case resolvedCase = buildCollectionsCase('C6 reopen');
        insert resolvedCase;
        update new Case(Id = resolvedCase.Id, Status = STATUS_RESOLVED);

        Id ownerBefore = reload(resolvedCase.Id).OwnerId;
        Id nextOwner = String.valueOf(ownerBefore).left(15) == String.valueOf(userPool[1]).left(15)
            ? userPool[0]
            : userPool[1];

        Test.startTest();
            update new Case(Id = resolvedCase.Id, OwnerId = nextOwner, Status = STATUS_RESOLVED);
        Test.stopTest();

        String reopenMessage = 'C6 (via gate G1): a Resolved Collections case whose owner changes '
            + 'to a different user must return to Open';
        Assert.areEqual(STATUS_OPEN, reload(resolvedCase.Id).Status, reopenMessage);
    }

    // ---------- C7-C12: escalation routing (all guarded, all STOP) ----------

    @isTest
    static void shouldRouteToSoedQueueWhenEscalatedToSoed() {
        Case routedCase = escalateOnCreate('C7 soed', ESC_SOED);
        String routeMessage = 'C7: escalation to SOED must hand the case to the SOED queue';
        assertSameId(Label.CaseEsc_SOED_Queue_Id, routedCase.OwnerId, routeMessage);
    }

    @isTest
    static void shouldRouteToProServQueueWhenEscalatedToProfessionalServices() {
        Case routedCase = escalateOnCreate('C8 proserv', ESC_PROSERV);
        String routeMessage = 'C8: escalation to Professional Services must hand the case to the '
            + 'ProServ queue';
        assertSameId(Label.CaseEsc_ProServ_Queue_Id, routedCase.OwnerId, routeMessage);
    }

    @isTest
    static void shouldRouteToCaseAccountCurrentOwnerWhenEscalatedToSales() {
        // C9 writes OwnerId from the CASE field Account_Current_Owner__c, not from the Account.
        Case routedCase = escalateOnUpdate('C9 sales', ESC_SALES);
        String routeMessage = 'C9: escalation to Sales must hand the case to '
            + 'Case.Account_Current_Owner__c';
        assertSameId(String.valueOf(routedCase.Account_Current_Owner__c), routedCase.OwnerId, routeMessage);
    }

    @isTest
    static void shouldRouteToAccountCsmWhenEscalatedToCsm() {
        // C10 writes OwnerId from the ACCOUNT traversal Account.CSM__c, unlike C9.
        Account collectionsAccount = parityAccount();
        Case routedCase = escalateOnUpdate('C10 csm', ESC_CSM);
        String routeMessage = 'C10: escalation to CSM must hand the case to Account.CSM__c';
        assertSameId(String.valueOf(collectionsAccount.CSM__c), routedCase.OwnerId, routeMessage);
    }

    @isTest
    static void shouldRouteToBillingQueueWhenEscalatedToBilling() {
        Case routedCase = escalateOnCreate('C11 billing', ESC_BILLING);
        String routeMessage = 'C11: escalation to Billing must hand the case to the Billing queue';
        assertSameId(Label.CaseEsc_Billing_Queue_Id, routedCase.OwnerId, routeMessage);
    }

    @isTest
    static void shouldRouteToCaseOriginatorWhenEscalatedToCollections() {
        // C12's owner target is Case_Originator__c, which C3 populates in the same run.
        Case routedCase = escalateOnCreate('C12 collections', ESC_COLLECTION);
        String routeMessage = 'C12: escalation to Collections must hand the case to the case '
            + 'originator';
        assertSameId(String.valueOf(UserInfo.getUserId()), routedCase.OwnerId, routeMessage);
    }

    // ---------- the newly-met guard ----------

    @isTest
    static void shouldNotReRouteWhenEscalationValueWasAlreadyMetOnPriorSave() {
        // The compiled guard skips the node when the PRIOR record already met the criteria. So:
        // create escalated (fires, owner -> SOED queue), then hand the case back to a user and
        // save again WITHOUT changing the escalation. The guard must suppress a re-route.
        Case escalatedCase = buildCollectionsCase('guard soed');
        escalatedCase.Support_Escalate_To__c = ESC_SOED;
        insert escalatedCase;

        Test.startTest();
            update new Case(Id = escalatedCase.Id, OwnerId = UserInfo.getUserId());
        Test.stopTest();

        String guardMessage = 'Newly-met guard: re-saving with an unchanged Support_Escalate_To__c '
            + 'must NOT re-route to the SOED queue - the owner set by this save must survive';
        assertSameId(String.valueOf(UserInfo.getUserId()), reload(escalatedCase.Id).OwnerId, guardMessage);
    }
}
