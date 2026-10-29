/**
 * Track B parity harness for Consolidated_Case_Routing_Escalation_PB -> F4/F5 (PBC-32071).
 *
 * NAMING NOTE (UT-001): there is no Apex class under test - this characterises a Process Builder,
 * so `Test_<ClassName>` has no class to name. `Test_<PbSubject>Parity` is used consistently
 * across the three Track B harnesses.
 *
 * NODE VOCABULARY: N1-N26 per PB_Metadata_Blueprint.md 1.2. (C-numbers are Collections,
 * P-numbers are Partner.) N27/CERT is deliberately absent - it exists only in the rolled-back
 * v5 and is out of scope per SO-4.
 *
 * EXPECTATIONS ARE DERIVED FROM THE PB, NOT FROM THE BLUEPRINT. Read from the compiled metadata
 * of the ACTIVE version (v4, 3012H000000DBdo) via the Tooling API.
 *
 * Two-phase protocol - the file NEVER changes between phases:
 *   Phase O  PBs active / flows Draft : proves these expectations are true of the PB.
 *   Phase F  flows active / PBs off   : proves the migration is faithful.
 *
 * COVERAGE BOUNDARY - only 6 of the 26 nodes are Apex-observable:
 *   N5, N6, N7, N8, N9, N26 write fields. The other 20 (N1-N4, N10-N25) are email-alert only,
 *   and Apex cannot observe alert sends at all. Those are covered by the static alert-name diff
 *   (PB actionCalls vs flow actionCalls) plus Track A's decision-outcome assertions. Do not read
 *   this class's pass count as coverage of the whole PB.
 *
 * Testable node map (active v4):
 *   N5  ISCHANGED(Route_To__c) AND Route_To__c='GSS GDPR Request'
 *         -> OwnerId=GSS GDPR queue, RecordTypeId=GDPR Request, Route_To__c=NULL, CONTINUE [guarded]
 *   N6  ISCHANGED(Support_Escalate_To__c) AND ..='IT'
 *         -> OwnerId=IT GSD USER, RecordTypeId=IT Helpdesk, Support_Escalate_To__c=NULL, CONTINUE [guarded]
 *   N7  Support_Escalate_To__c='Contact Center Support'
 *         -> OwnerId=Contact Center queue, RecordTypeId=Support T2, CONTINUE [guarded]
 *   N8  RecordTypeId=IBS AND Support_Escalate_To__c='SalesOps'
 *         -> OwnerId=SalesOps queue, RecordTypeId remains IBS, CONTINUE [guarded]
 *   N9  RecordTypeId=IBS AND Support_Escalate_To__c='SOED'
 *         -> OwnerId=SOED queue, RecordTypeId=Sales Order Except Desk, CONTINUE [guarded]
 *   N26 RecordType.DeveloperName='Support_T2' AND ..='Technical Account Engineering' AND NOT IsClosed
 *         -> OwnerId=TAE queue, STOP [guarded]
 *
 * N5 and N6 NULL OUT the very field that triggered them. Those null-outs are load-bearing for
 * their own firing conditions, which is why N5/N6 stay whole in F5 rather than splitting to
 * before-save (blueprint 1.5). The null-out is asserted explicitly - losing it in the migration
 * would let the nodes re-fire.
 *
 * N5/N6 gate on ISCHANGED, which is false on create, so their tests are insert-then-update.
 * N7/N8/N9/N26 gate on plain equality and fire on create (the guard permits create).
 *
 * ASSIGNMENT RULES: Case DML uses the active Case assignment rule (same header as the Case
 * layout "Assign using active assignment rules" checkbox). Routing owner and record-type
 * writes run in after-save F5, after assignment rules, so the routed queue remains final.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class Test_RoutingEscalationParity {

    private static final String ESC_IT       = 'IT';
    private static final String ESC_CCS      = 'Contact Center Support';
    private static final String ESC_SALESOPS = 'SalesOps';
    private static final String ESC_SOED     = 'SOED';
    private static final String ESC_TAE      = 'Technical Account Engineering';

    private static final String ROUTE_GSS_GDPR = 'GSS GDPR Request';

    private static final String STATUS_OPEN   = 'Open';
    private static final String STATUS_CLOSED = 'Closed';
    // Phone matches the Contact Center escalation save path and avoids Email-origin assignment
    // entries plus the unrelated 'Update Dummy Account for Email-to-Case and Chat Cases' PB.
    // None of the six nodes under test reads Origin.
    private static final String ORIGIN_PHONE  = 'Phone';

    private static final String SUBJECT_PREFIX = 'PARITY ';
    private static final String CALLBACK_CONTACT_ID = 'PARITY-CB-001';
    private static final String ACCOUNT_NAME = 'PARITY Routing Account';
    private static final String CONTACT_NAME = 'PARITY Routing Contact';

    @testSetup
    static void testData() {
        // None of the six testable nodes READS Account data - they gate purely on Case fields.
        // The Account exists for a different reason: an unrelated PB, "Update Dummy Account for
        // Email-to-Case and Chat Cases", stamps a hardcoded Account onto any Case whose AccountId
        // is blank, and that Account (001Hr00001jVN9x) is inaccessible in DevGss - so the save
        // hard-fails. Giving every case a real Account keeps that automation from firing.
        Account routingAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .quantity(1)
            .setFields(new Map<SObjectField, Object>{ Account.Name => ACCOUNT_NAME })
            .create()
            .getRecord();

        // Via Contact, not AccountId: a directly-assigned Case.AccountId is silently dropped on
        // insert in Apex test context (see Test_CollectionsDisputeParity for the full finding).
        new SObjectBuilder(Contact.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => CONTACT_NAME,
                    Contact.AccountId => routingAccount.Id
                }
            )
            .create();
    }

    private static Id routingContactId() {
        return [
            SELECT Id
            FROM Contact
            WHERE LastName = :CONTACT_NAME
        ].Id;
    }

    // ---------- helpers ----------

    /**
     * Builds an unsaved Case on the given record type, with NO Contact.
     *
     * Contact presence is a genuine trade-off in this org, not a style choice:
     *  - WITHOUT a Contact the Case has no Account, so the unrelated "Update Dummy Account for
     *    Email-to-Case and Chat Cases" PB tries to stamp an inaccessible hardcoded Account
     *    (001Hr00001jVN9x) and the save hard-fails - but only on an explicit OwnerId change.
     *  - WITH a Contact, N6 fails instead: it switches the record type to IT Helpdesk, whose
     *    ContactId lookup filter demands an INTERNAL contact ("Case Contact for IT Support Cases
     *    should be Internal").
     * So most nodes take no Contact, and only the tests that explicitly reassign OwnerId use
     * buildCaseWithContact(). None of the six nodes under test reads Account or Contact data.
     */
    private static Case buildCase(String nodeLabel, Id recordTypeId) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => SUBJECT_PREFIX + nodeLabel,
                    Case.Status => STATUS_OPEN,
                    Case.Origin => ORIGIN_PHONE,
                    Case.RecordTypeId => recordTypeId
                }
            )
            .build()
            .getRecord();
    }

    /** As buildCase, but linked to the parity Contact so the Case carries an Account. */
    private static Case buildCaseWithContact(String nodeLabel, Id recordTypeId) {
        Case linkedCase = buildCase(nodeLabel, recordTypeId);
        linkedCase.ContactId = routingContactId();
        return linkedCase;
    }

    private static Case reload(Id caseId) {
        return [
            SELECT OwnerId, RecordTypeId, Status, IsClosed,
                   Route_To__c, Support_Escalate_To__c
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

    /**
     * Applies the active Case assignment rule, matching UI DML that checks
     * "Assign using active assignment rules".
     */
    private static Database.DMLOptions assignmentRuleOptions() {
        AssignmentRule assignmentRule = [
            SELECT Id
            FROM AssignmentRule
            WHERE SobjectType = 'Case'
                AND Active = true
            LIMIT 1
        ];
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.assignmentRuleHeader.assignmentRuleId = assignmentRule.Id;
        return dmlOptions;
    }

    private static void insertWithAssignmentRules(Case caseRecord) {
        caseRecord.setOptions(assignmentRuleOptions());
        insert caseRecord;
    }

    private static void updateWithAssignmentRules(Case caseRecord) {
        caseRecord.setOptions(assignmentRuleOptions());
        update caseRecord;
    }

    private static Case escalateOnCreate(String nodeLabel, Id recordTypeId, String escalateTo) {
        Case escalatedCase = buildCase(nodeLabel, recordTypeId);
        escalatedCase.Support_Escalate_To__c = escalateTo;

        Test.startTest();
            insertWithAssignmentRules(escalatedCase);
        Test.stopTest();

        return reload(escalatedCase.Id);
    }

    private static Case escalateOnUpdate(String nodeLabel, Id recordTypeId, String escalateTo) {
        Case existingCase = buildCaseWithContact(nodeLabel, recordTypeId);
        insertWithAssignmentRules(existingCase);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = existingCase.Id, Support_Escalate_To__c = escalateTo)
            );
        Test.stopTest();

        return reload(existingCase.Id);
    }

    /**
     * Produces the owner chosen by the active assignment rule for an otherwise-unrouted control
     * Case. Negative routing tests compare to this exact result rather than merely checking that
     * the owner is not a routing queue.
     */
    private static Id assignmentRuleOwnerAfterUpdate(
        String nodeLabel,
        Id recordTypeId,
        Case caseUpdate
    ) {
        Case controlCase = buildCaseWithContact(nodeLabel, recordTypeId);
        insert controlCase;
        caseUpdate.Id = controlCase.Id;
        updateWithAssignmentRules(caseUpdate);
        return reload(controlCase.Id).OwnerId;
    }

    // ---------- N5: GDPR routing, with a load-bearing null-out ----------

    @isTest
    static void shouldRouteToGssGdprQueueWhenRouteToChangesToGssGdprRequest() {
        Case gdprCase = buildCase('N5 gdpr', (Id) Label.CaseRT_Support_T2_Id);
        insertWithAssignmentRules(gdprCase);

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = gdprCase.Id, Route_To__c = ROUTE_GSS_GDPR));
        Test.stopTest();

        Case routedCase = reload(gdprCase.Id);
        String ownerMessage = 'N5: Route_To__c changing to GSS GDPR Request must hand the case to '
            + 'the GSS GDPR queue';
        String recordTypeMessage = 'N5: the case must also switch to the GDPR Request record type';
        assertSameId(Label.CaseEsc_GSS_GDPR_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_GDPR_Request_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldClearRouteToWhenGdprRoutingFires() {
        // The null-out is load-bearing: it is what stops N5 re-firing on the next save, and it is
        // why N5 cannot move to before-save. If the migration drops it, N5 loops.
        Case gdprCase = buildCase('N5 nullout', (Id) Label.CaseRT_Support_T2_Id);
        insertWithAssignmentRules(gdprCase);

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = gdprCase.Id, Route_To__c = ROUTE_GSS_GDPR));
        Test.stopTest();

        String nullOutMessage = 'N5: Route_To__c must be nulled out by the action chain - this '
            + 'null-out is load-bearing for the node\'s own firing condition';
        Assert.isNull(reload(gdprCase.Id).Route_To__c, nullOutMessage);
    }

    // ---------- N6: IT escalation to a USER, with a load-bearing null-out ----------

    @isTest
    static void shouldRouteToItGsdUserWhenEscalatedToIt() {
        Case itCase = buildCase('N6 it', (Id) Label.CaseRT_Support_T2_Id);
        insertWithAssignmentRules(itCase);

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = itCase.Id, Support_Escalate_To__c = ESC_IT));
        Test.stopTest();

        Case routedCase = reload(itCase.Id);
        // N6's owner target is a USER, not a queue - the only such target among these six nodes.
        String ownerMessage = 'N6: escalation to IT must hand the case to the IT GSD user';
        String recordTypeMessage = 'N6: the case must also switch to the IT Helpdesk record type';
        assertSameId(Label.CaseEsc_IT_GSD_User_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_IT_Helpdesk_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldClearSupportEscalateToWhenItRoutingFires() {
        Case itCase = buildCase('N6 nullout', (Id) Label.CaseRT_Support_T2_Id);
        insertWithAssignmentRules(itCase);

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = itCase.Id, Support_Escalate_To__c = ESC_IT));
        Test.stopTest();

        String nullOutMessage = 'N6: Support_Escalate_To__c must be nulled out by the action chain '
            + '- load-bearing for the node\'s own firing condition';
        Assert.isNull(reload(itCase.Id).Support_Escalate_To__c, nullOutMessage);
    }

    @isTest
    static void shouldNotRouteGdprRequestOnCreateWhenIsChangedGateIsFalse() {
        Case gdprCase = buildCase('N5 create guard', (Id) Label.CaseRT_Support_T2_Id);
        gdprCase.Route_To__c = ROUTE_GSS_GDPR;

        Test.startTest();
            insertWithAssignmentRules(gdprCase);
        Test.stopTest();

        Case savedCase = reload(gdprCase.Id);
        String recordTypeMessage = 'N5 create guard: ISCHANGED(Route_To__c) must be false on '
            + 'create, so the Support T2 record type must remain';
        String fieldMessage = 'N5 create guard: Route_To__c must remain populated when N5 does not fire';
        assertSameId(Label.CaseRT_Support_T2_Id, savedCase.RecordTypeId, recordTypeMessage);
        Assert.areEqual(ROUTE_GSS_GDPR, savedCase.Route_To__c, fieldMessage);
    }

    @isTest
    static void shouldNotRouteItEscalationOnCreateWhenIsChangedGateIsFalse() {
        Case itCase = buildCase('N6 create guard', (Id) Label.CaseRT_Support_T2_Id);
        itCase.Support_Escalate_To__c = ESC_IT;

        Test.startTest();
            insertWithAssignmentRules(itCase);
        Test.stopTest();

        Case savedCase = reload(itCase.Id);
        String recordTypeMessage = 'N6 create guard: ISCHANGED(Support_Escalate_To__c) must be '
            + 'false on create, so the Support T2 record type must remain';
        String fieldMessage = 'N6 create guard: escalation must remain IT when N6 does not fire';
        assertSameId(Label.CaseRT_Support_T2_Id, savedCase.RecordTypeId, recordTypeMessage);
        Assert.areEqual(ESC_IT, savedCase.Support_Escalate_To__c, fieldMessage);
    }

    // ---------- N7: Contact Center Support ----------

    @isTest
    static void shouldRouteToContactCenterQueueWhenEscalatedToContactCenterSupport() {
        Case routedCase = escalateOnCreate('N7 ccs', (Id) Label.CaseRT_Internal_Business_Services_Id, ESC_CCS);

        String ownerMessage = 'N7: escalation to Contact Center Support must hand the case to the '
            + 'Contact Center queue after assignment rules run';
        String recordTypeMessage = 'N7: the case must also switch to the Support T2 record type';
        assertSameId(Label.CaseEsc_ContactCenter_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Support_T2_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldRouteToContactCenterQueueWhenExistingCaseIsEscalatedToContactCenterSupport() {
        // Matches the UI save: existing case, Escalate To changes to Contact Center Support,
        // assignment rules requested. F5 sets the Contact Center queue after assignment rules,
        // so the routed owner must remain.
        Case routedCase = escalateOnUpdate(
            'N7 ccs update',
            (Id) Label.CaseRT_Internal_Business_Services_Id,
            ESC_CCS
        );

        String ownerMessage = 'N7 update: assignment rules must leave the Contact Center queue '
            + 'owner set by routing';
        String recordTypeMessage = 'N7 update: the case must also switch to the Support T2 record type';
        assertSameId(Label.CaseEsc_ContactCenter_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Support_T2_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    // ---------- N8 / N9: IBS-gated escalations ----------

    @isTest
    static void shouldRouteToSalesOpsQueueWithoutChangingRecordTypeWhenIbsCaseEscalatedToSalesOps() {
        Case routedCase = escalateOnCreate('N8 salesops', (Id) Label.CaseRT_Internal_Business_Services_Id, ESC_SALESOPS);

        String ownerMessage = 'N8: an IBS case escalated to SalesOps must go to the SalesOps queue';
        String recordTypeMessage = 'N8: the inactive Sales Operations record type must not be assigned';
        assertSameId(Label.CaseEsc_SalesOps_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Internal_Business_Services_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldRouteExistingIbsCaseToSalesOpsQueueWithoutChangingRecordType() {
        Case routedCase = escalateOnUpdate(
            'N8 salesops update',
            (Id) Label.CaseRT_Internal_Business_Services_Id,
            ESC_SALESOPS
        );

        String ownerMessage = 'N8 update: an existing IBS case escalated to SalesOps must go to '
            + 'the SalesOps queue after assignment rules run';
        String recordTypeMessage = 'N8 update: the inactive Sales Operations record type must not '
            + 'be assigned';
        assertSameId(Label.CaseEsc_SalesOps_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Internal_Business_Services_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldNotRouteToSalesOpsWhenEscalatedCaseIsNotInternalBusinessServices() {
        // N8's record-type condition is the whole difference between firing and not. This is the
        // negative Track A structurally cannot express (no interview, no outcome to assert).
        Case nonIbsCase = buildCase('N8 blocked', (Id) Label.CaseRT_Support_T2_Id);
        insertWithAssignmentRules(nonIbsCase);
        Id ownerBefore = reload(nonIbsCase.Id).OwnerId;

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = nonIbsCase.Id, Support_Escalate_To__c = ESC_SALESOPS)
            );
        Test.stopTest();

        String blockedMessage = 'N8: a SalesOps escalation on a non-IBS case must not reassign the '
            + 'owner - the record-type condition blocks it';
        Case savedCase = reload(nonIbsCase.Id);
        String escalationMessage = 'N8 negative precondition: the SalesOps value must persist so '
            + 'an unchanged owner proves the record-type gate, not a discarded update';
        Assert.areEqual(ownerBefore, savedCase.OwnerId, blockedMessage);
        Assert.areEqual(ESC_SALESOPS, savedCase.Support_Escalate_To__c, escalationMessage);
    }

    @isTest
    static void shouldRouteToSoedQueueWhenIbsCaseEscalatedToSoed() {
        Case routedCase = escalateOnCreate('N9 soed', (Id) Label.CaseRT_Internal_Business_Services_Id, ESC_SOED);

        String ownerMessage = 'N9: an IBS case escalated to SOED must go to the SOED queue';
        String recordTypeMessage = 'N9: the case must also switch to the Sales Order Except Desk '
            + 'record type';
        assertSameId(Label.CaseEsc_SOED_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Sales_Order_Except_Desk_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    @isTest
    static void shouldRouteExistingIbsCaseToSoedQueueWhenEscalatedToSoed() {
        Case routedCase = escalateOnUpdate(
            'N9 soed update',
            (Id) Label.CaseRT_Internal_Business_Services_Id,
            ESC_SOED
        );

        String ownerMessage = 'N9 update: an existing IBS case escalated to SOED must go to the '
            + 'SOED queue after assignment rules run';
        String recordTypeMessage = 'N9 update: the case must switch to the Sales Order Except '
            + 'Desk record type';
        assertSameId(Label.CaseEsc_SOED_Queue_Id, routedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Sales_Order_Except_Desk_Id, routedCase.RecordTypeId, recordTypeMessage);
    }

    // ---------- N26: TAE escalation, gated on Support_T2 and not-closed ----------

    @isTest
    static void shouldRouteToTaeQueueWhenSupportT2CaseEscalatedToTechnicalAccountEngineering() {
        Case routedCase = escalateOnCreate('N26 tae', (Id) Label.CaseRT_Support_T2_Id, ESC_TAE);

        String ownerMessage = 'N26: an open Support T2 case escalated to Technical Account '
            + 'Engineering must go to the TAE queue';
        assertSameId(Label.CaseEsc_TAE_Queue_Id, routedCase.OwnerId, ownerMessage);
    }

    @isTest
    static void shouldRouteExistingSupportT2CaseToTaeQueueWhenEscalated() {
        Case routedCase = escalateOnUpdate(
            'N26 tae update',
            (Id) Label.CaseRT_Support_T2_Id,
            ESC_TAE
        );

        String ownerMessage = 'N26 update: an existing open Support T2 case escalated to '
            + 'Technical Account Engineering must go to the TAE queue after assignment rules run';
        assertSameId(Label.CaseEsc_TAE_Queue_Id, routedCase.OwnerId, ownerMessage);
    }

    @isTest
    static void shouldNotRouteToTaeQueueWhenCaseIsAlreadyClosed() {
        // N26's third condition is NOT IsClosed. IsClosed is derived from Status, so the case is
        // closed via Status rather than set directly.
        Case closedCase = buildCase('N26 closed', (Id) Label.CaseRT_Support_T2_Id);
        closedCase.Status = STATUS_CLOSED;
        // Tier_2_Close_Case_Contact_ID and Tier_2_WIP_Status both reject a closed Support T2 case
        // with a blank Callback Contact ID, so it has to be populated to reach the node at all.
        closedCase.Callback_Contact_ID__c = CALLBACK_CONTACT_ID;
        insertWithAssignmentRules(closedCase);
        Id ownerBefore = reload(closedCase.Id).OwnerId;

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = closedCase.Id, Support_Escalate_To__c = ESC_TAE));
        Test.stopTest();

        String blockedMessage = 'N26: a TAE escalation on a CLOSED Support T2 case must not '
            + 'reassign the owner - the NOT IsClosed condition blocks it';
        Case savedCase = reload(closedCase.Id);
        String escalationMessage = 'N26 closed precondition: the TAE value must persist so the '
            + 'owner assertion proves the IsClosed gate';
        Assert.areEqual(ownerBefore, savedCase.OwnerId, blockedMessage);
        Assert.areEqual(ESC_TAE, savedCase.Support_Escalate_To__c, escalationMessage);
    }

    @isTest
    static void shouldNotRouteToTaeQueueWhenRecordTypeIsNotSupportT2() {
        Case wrongTypeCase = buildCase('N26 wrongRT', (Id) Label.CaseRT_Internal_Business_Services_Id);
        insertWithAssignmentRules(wrongTypeCase);
        Id ownerBefore = reload(wrongTypeCase.Id).OwnerId;

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = wrongTypeCase.Id, Support_Escalate_To__c = ESC_TAE)
            );
        Test.stopTest();

        String blockedMessage = 'N26: a TAE escalation on a non-Support-T2 case must not reassign '
            + 'the owner - the RecordType.DeveloperName condition blocks it';
        Case savedCase = reload(wrongTypeCase.Id);
        String escalationMessage = 'N26 record-type precondition: the TAE value must persist so '
            + 'the owner assertion proves the record-type gate';
        Assert.areEqual(ownerBefore, savedCase.OwnerId, blockedMessage);
        Assert.areEqual(ESC_TAE, savedCase.Support_Escalate_To__c, escalationMessage);
    }

    // ---------- the newly-met guard ----------

    @isTest
    static void shouldNotReRouteWhenSoedEscalationWasAlreadyMetOnPriorSave() {
        // All six testable nodes carry a compiled newly-met guard. N9 stands in for the set - not
        // N8, whose target record type is inactive in DevGss and would mask the guard behind an
        // environment failure. Create escalated (fires), hand the case back to a user, save again
        // WITHOUT changing the escalation. The guard must suppress a re-route.
        Case escalatedCase = buildCaseWithContact('N9 guard', (Id) Label.CaseRT_Internal_Business_Services_Id);
        escalatedCase.Support_Escalate_To__c = ESC_SOED;
        insertWithAssignmentRules(escalatedCase);
        String routedPreconditionMessage = 'N9 guard precondition: the initial save must route to '
            + 'SOED before the unchanged-value save can verify suppression';
        assertSameId(
            Label.CaseEsc_SOED_Queue_Id,
            reload(escalatedCase.Id).OwnerId,
            routedPreconditionMessage
        );
        Id expectedAssignmentOwner = assignmentRuleOwnerAfterUpdate(
            'N9 guard control',
            (Id) Label.CaseRT_Sales_Order_Except_Desk_Id,
            new Case(OwnerId = UserInfo.getUserId())
        );

        Test.startTest();
            updateWithAssignmentRules(new Case(Id = escalatedCase.Id, OwnerId = UserInfo.getUserId()));
        Test.stopTest();

        String guardMessage = 'Newly-met guard: assignment rules may replace the requested user, '
            + 'and an unchanged escalation must leave the same owner as an unrouted control save';
        assertSameId(String.valueOf(expectedAssignmentOwner), reload(escalatedCase.Id).OwnerId, guardMessage);
    }

    // ---------- assignment-rule isolation ----------

    /**
     * Control: same case as N7, but WITHOUT the assignment-rule header. Isolates routing from
     * assignment rules so a routing failure cannot be blamed on assignment and vice versa.
     */
    @isTest
    static void shouldRouteToContactCenterQueueWhenAssignmentRulesAreNotRequested() {
        Case routedCase = buildCase('N7 no-AR', (Id) Label.CaseRT_Internal_Business_Services_Id);
        routedCase.Support_Escalate_To__c = ESC_CCS;

        Test.startTest();
            insert routedCase;
        Test.stopTest();

        String ownerMessage = 'N7 control: with no assignment rule requested, routing alone must '
            + 'leave the case on the Contact Center queue';
        String recordTypeMessage = 'N7 control: routing alone must also set the Support T2 record type';
        Case savedCase = reload(routedCase.Id);
        assertSameId(Label.CaseEsc_ContactCenter_Queue_Id, savedCase.OwnerId, ownerMessage);
        assertSameId(Label.CaseRT_Support_T2_Id, savedCase.RecordTypeId, recordTypeMessage);
    }

    /**
     * Characterises the UAT defect: assignment rules requested on an EDIT of an already-routed
     * case. Case assignment rules are not create-only - requesting them on update re-evaluates
     * every entry, and a no-match hands the case to the default owner, discarding the queue.
     */
    @isTest
    static void shouldDiscardRoutedQueueWhenAssignmentRulesAreRequestedOnUpdate() {
        Case routedCase = buildCase('N7 AR-on-update', (Id) Label.CaseRT_Internal_Business_Services_Id);
        routedCase.Support_Escalate_To__c = ESC_CCS;
        insert routedCase;

        Id ownerAfterRouting = reload(routedCase.Id).OwnerId;
        String preconditionMessage = 'Precondition: routing must put the case on the Contact '
            + 'Center queue before the assignment-rule save';
        assertSameId(Label.CaseEsc_ContactCenter_Queue_Id, ownerAfterRouting, preconditionMessage);
        Id expectedAssignmentOwner = assignmentRuleOwnerAfterUpdate(
            'N7 AR control',
            (Id) Label.CaseRT_Support_T2_Id,
            new Case(Subject = SUBJECT_PREFIX + 'N7 AR control edited')
        );

        // Escalate To is untouched, so no routing node can re-fire on this save. Assignment
        // rules are the only automation left that can move OwnerId.
        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = routedCase.Id, Subject = SUBJECT_PREFIX + 'N7 AR-on-update edited')
            );
        Test.stopTest();

        String overwriteMessage = 'Assignment rules requested on an update must produce the same '
            + 'owner as an unrouted control save - this is the UAT ownerAssignment overwrite';
        assertSameId(String.valueOf(expectedAssignmentOwner), reload(routedCase.Id).OwnerId, overwriteMessage);
    }

    // ---------- routing target validity ----------

    /**
     * Record types F5 assigns, keyed by label name so a failure names the offending label.
     * Sales Operations is absent by design: F5 no longer assigns it because it is inactive.
     */
    private static Map<String, String> routingRecordTypeTargets() {
        return new Map<String, String>{
            'CaseRT_GDPR_Request_Id' => Label.CaseRT_GDPR_Request_Id,
            'CaseRT_IT_Helpdesk_Id' => Label.CaseRT_IT_Helpdesk_Id,
            'CaseRT_Support_T2_Id' => Label.CaseRT_Support_T2_Id,
            'CaseRT_Sales_Order_Except_Desk_Id' => Label.CaseRT_Sales_Order_Except_Desk_Id
        };
    }

    /** Queues F5 assigns as Case owner, keyed by label name. */
    private static Map<String, String> routingQueueTargets() {
        return new Map<String, String>{
            'CaseEsc_GSS_GDPR_Queue_Id' => Label.CaseEsc_GSS_GDPR_Queue_Id,
            'CaseEsc_ContactCenter_Queue_Id' => Label.CaseEsc_ContactCenter_Queue_Id,
            'CaseEsc_SalesOps_Queue_Id' => Label.CaseEsc_SalesOps_Queue_Id,
            'CaseEsc_SOED_Queue_Id' => Label.CaseEsc_SOED_Queue_Id,
            'CaseEsc_TAE_Queue_Id' => Label.CaseEsc_TAE_Queue_Id
        };
    }

    /** Queue prefixes that admit F5 and drive N10-N25 email-notification branches. */
    private static Map<String, String> gdprNotificationQueueTargets() {
        return new Map<String, String>{
            'GDPR_HR_Ops_Queue_Prefix' => Label.GDPR_HR_Ops_Queue_Prefix,
            'GDPR_MOPS_Queue_Prefix' => Label.GDPR_MOPS_Queue_Prefix,
            'GDPR_Legal_Ops_Queue_Prefix' => Label.GDPR_Legal_Ops_Queue_Prefix,
            'GDPR_BD_Queue_Prefix' => Label.GDPR_BD_Queue_Prefix,
            'GDPR_SalesOps_Queue_Prefix' => Label.GDPR_SalesOps_Queue_Prefix,
            'GDPR_IT_Core_Queue_Prefix' => Label.GDPR_IT_Core_Queue_Prefix,
            'GDPR_BI_Queue_Prefix' => Label.GDPR_BI_Queue_Prefix,
            'GDPR_CRM_Queue_Prefix' => Label.GDPR_CRM_Queue_Prefix,
            'GDPR_Finance_Queue_Prefix' => Label.GDPR_Finance_Queue_Prefix,
            'GDPR_Integrations_Queue_Prefix' => Label.GDPR_Integrations_Queue_Prefix,
            'GDPR_PMM_Queue_Prefix' => Label.GDPR_PMM_Queue_Prefix,
            'GDPR_Live_Reports_Queue_Prefix' => Label.GDPR_Live_Reports_Queue_Prefix,
            'GDPR_Contact_Center_Queue_Prefix' => Label.GDPR_Contact_Center_Queue_Prefix,
            'GDPR_Cloud_Ops_Queue_Prefix' => Label.GDPR_Cloud_Ops_Queue_Prefix,
            'GDPR_RC_Platform_Queue_Prefix' => Label.GDPR_RC_Platform_Queue_Prefix,
            'GDPR_Channel_Queue_Prefix' => Label.GDPR_Channel_Queue_Prefix
        };
    }

    /** Category values consumed by F4, taken from the active PB decision criteria. */
    private static Set<String> salesEmailCategories() {
        return new Set<String>{
            'Sales - Account Cancellation',
            'Sales - Account General Inquiry',
            'Sales - Account Manager / Account Executive Concern',
            'Sales - Asking for Supervisor',
            'Sales - Customer Complaint',
            'Sales - Customer Education / Setting of Expectations',
            'Sales - Missed Commitment',
            'Sales - Price Alignment',
            'Sales - Sales Agreement'
        };
    }

    /** Category values consumed by F4, taken from the active PB decision criteria. */
    private static Set<String> gssEmailCategories() {
        return new Set<String>{
            'GSS - Billing',
            'GSS - Customer Appeasement',
            'GSS - Customer Education / Setting of Expectations',
            'GSS - Fraud Prevention',
            'GSS - Implementation',
            'GSS - Missed Commitment / Unresponsive Rep',
            'GSS - Number Porting',
            'GSS - Order Shipping',
            'GSS - Outage',
            'GSS - Product Question',
            'GSS - Supervisor Request',
            'GSS - Technical Issue',
            'GSS - Unauthorized Account Changes - Existing Customer',
            'GSS - Unauthorized Account Changes - New Customer',
            'GSS - Vanity Order',
            'GSS - Professional Services Project Admin'
        };
    }

    private static Set<String> delimitedLabelValues(String labelValue) {
        Set<String> values = new Set<String>(labelValue.split(';'));
        values.remove('');
        return values;
    }

    /** A queue can hold a Case only when QueueSobject links it to the Case object. */
    private static Set<String> caseOwningQueuePrefixes() {
        Set<String> queuePrefixes = new Set<String>();
        for (QueueSobject queueLink : [
            SELECT QueueId
            FROM QueueSobject
            WHERE SobjectType = 'Case'
        ]) {
            queuePrefixes.add(String.valueOf(queueLink.QueueId).left(15));
        }
        return queuePrefixes;
    }

    @isTest
    static void shouldFindEveryRoutingRecordTypeActiveWhenFlowCanAssignIt() {
        Map<Id, Schema.RecordTypeInfo> recordTypeInfoById = Schema.SObjectType.Case.getRecordTypeInfosById();
        Map<String, Id> recordTypeIdByPrefix = new Map<String, Id>();
        for (Id recordTypeId : recordTypeInfoById.keySet()) {
            recordTypeIdByPrefix.put(String.valueOf(recordTypeId).left(15), recordTypeId);
        }

        Map<String, String> recordTypeTargets = routingRecordTypeTargets();
        for (String labelName : recordTypeTargets.keySet()) {
            Id recordTypeId = recordTypeIdByPrefix.get(recordTypeTargets.get(labelName).left(15));

            String existsMessage = 'Routing target ' + labelName + ' must resolve to a Case '
                + 'record type that exists in this org';
            Assert.isNotNull(recordTypeId, existsMessage);

            // Assigning an inactive record type rejects the whole Case save with
            // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY: invalid record type.
            String activeMessage = 'Routing target ' + labelName + ' must be an ACTIVE record '
                + 'type - F5 assigns it, and an inactive one rejects the Case save';
            Assert.isTrue(recordTypeInfoById.get(recordTypeId).isActive(), activeMessage);
        }
    }

    @isTest
    static void shouldFindEveryRoutingQueueCaseEnabledWhenFlowCanAssignIt() {
        Set<String> caseQueuePrefixes = caseOwningQueuePrefixes();

        Map<String, String> queueTargets = routingQueueTargets();
        for (String labelName : queueTargets.keySet()) {
            String enabledMessage = 'Routing target ' + labelName + ' must be a queue enabled for '
                + 'Case - F5 makes it the owner, which fails if the queue cannot hold Cases';
            Assert.isTrue(caseQueuePrefixes.contains(queueTargets.get(labelName).left(15)), enabledMessage);
        }
    }

    @isTest
    static void shouldFindEveryGdprNotificationPrefixCaseEnabledWhenFlowCanEvaluateIt() {
        Set<String> caseQueuePrefixes = caseOwningQueuePrefixes();
        // Live Reports is one OR-arm of GDPR_Queue_Prefix_List (N21 / myRule_43). A missing
        // queue does not suppress HR Ops, MOPS, or the other 14 emails; it only makes that
        // one owner-change alert unreachable. DevGss has no Case-enabled queue for
        // GDPR_Live_Reports_Queue_Prefix (00G2H0000044gM8).
        Set<String> isolatedMissingPrefixes = new Set<String>{ 'GDPR_Live_Reports_Queue_Prefix' };

        Map<String, String> queueTargets = gdprNotificationQueueTargets();
        for (String labelName : queueTargets.keySet()) {
            Boolean queueExists = caseQueuePrefixes.contains(queueTargets.get(labelName).left(15));
            if (isolatedMissingPrefixes.contains(labelName)) {
                String isolatedMessage = 'GDPR_Live_Reports_Queue_Prefix is an isolated OR arm and '
                    + 'is absent in this org - that must not be treated as a shared GDPR-list failure';
                Assert.isFalse(queueExists, isolatedMessage);
                continue;
            }
            String enabledMessage = 'GDPR notification target ' + labelName + ' must resolve to a '
                + 'queue enabled for Case - otherwise its F5 owner-prefix branch is unreachable';
            Assert.isTrue(queueExists, enabledMessage);
        }
    }

    @isTest
    static void shouldKeepGdprEntryPrefixListAlignedWithDecisionLabels() {
        Set<String> expectedPrefixes = new Set<String>();
        for (String queuePrefix : gdprNotificationQueueTargets().values()) {
            expectedPrefixes.add(queuePrefix);
        }

        Set<String> entryPrefixes = new Set<String>(Label.GDPR_Queue_Prefix_List.split(';'));
        entryPrefixes.remove('');

        String alignmentMessage = 'GDPR_Queue_Prefix_List must contain exactly the 16 individual '
            + 'N10-N25 queue-prefix labels or F5 will suppress or admit the wrong owner changes';
        Assert.areEqual(expectedPrefixes, entryPrefixes, alignmentMessage);
    }

    @isTest
    static void shouldKeepEmailEntryCategoryLabelsAlignedWithPbCriteria() {
        String salesMessage = 'CaseCat_Sales_List must exactly match the 9 Sales categories F4 '
            + 'evaluates or an email branch becomes unreachable or admits the wrong Case';
        String gssMessage = 'CaseCat_GSS_List must exactly match the 16 GSS categories F4 '
            + 'evaluates or an email branch becomes unreachable or admits the wrong Case';

        Assert.areEqual(
            salesEmailCategories(),
            delimitedLabelValues(Label.CaseCat_Sales_List),
            salesMessage
        );
        Assert.areEqual(
            gssEmailCategories(),
            delimitedLabelValues(Label.CaseCat_GSS_List),
            gssMessage
        );
    }

    @isTest
    static void shouldFindItGsdUserActiveWhenFlowCanAssignIt() {
        // N6 is the only node whose owner target is a User rather than a queue.
        List<User> itGsdUsers = [
            SELECT IsActive
            FROM User
            WHERE Id = :Label.CaseEsc_IT_GSD_User_Id
        ];

        String existsMessage = 'CaseEsc_IT_GSD_User_Id must resolve to a real User';
        Assert.isFalse(itGsdUsers.isEmpty(), existsMessage);

        String activeMessage = 'CaseEsc_IT_GSD_User_Id must be an ACTIVE user - an inactive user '
            + 'cannot own the Case N6 hands it';
        Assert.isTrue(itGsdUsers[0].IsActive, activeMessage);
    }
}
