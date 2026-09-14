/**
 * Track B parity harness for Partner_Case_Status_Case_Comment -> F6 (PBC-32071).
 *
 * NAMING NOTE (UT-001): there is no Apex class under test - this characterises a Process Builder,
 * so `Test_<ClassName>` has no class to name. `Test_<PbSubject>Parity` is used consistently
 * across the three Track B harnesses.
 *
 * NODE VOCABULARY: P1-P5 per PB_Metadata_Blueprint.md 2.2. (N-numbers are Routing/Escalation,
 * C-numbers are Collections.)
 *
 * EXPECTATIONS ARE DERIVED FROM THE PB, NOT FROM THE BLUEPRINT. Read from the compiled metadata
 * of the ACTIVE version (v9, 301Hr000000prHZ) via the Tooling API.
 *
 * Two-phase protocol - the file NEVER changes between phases:
 *   Phase O  PBs active / flows Draft : proves these expectations are true of the PB.
 *   Phase F  flows active / PBs off   : proves the migration is faithful.
 *
 * COVERAGE: unusually good here - all five nodes are Apex-observable. The PB posts comments via
 * the quickAction `Case.Case_Comment`, and F6 uses a Create Records element instead; that is a
 * structural change with an identical assertable outcome, a CaseComment row. So this harness
 * asserts CommentBody and IsPublished, which is the entire behaviour of this PB.
 *
 * Node map (active v9 - 5 nodes, 0 field writes, 5 quickActions, all unguarded, all STOP):
 *   shared gate on every node: AccountId NOT blank, Brand_Account__c NOT starting 'Rise',
 *                              Brand_Identifier__c IS blank
 *   P1  + Original_RecordType__c <> 'Support_Customer_ebonding' + ISCHANGED(Partner_Case_Status__c)
 *         -> "Partner Case Status Updated To: <value>"
 *   P2  + same exclusion + ISCHANGED(Case_Severity__c)
 *         -> "Case Severity Updated To: <value>"
 *   P3  + same exclusion + ISCHANGED(OwnerId) + BEGINS(OwnerId,'00G')
 *         -> "Case Owner Updated To: <Queue.Name>"
 *   P4  + same exclusion + ISCHANGED(OwnerId)          [no owner-type clause]
 *         -> "Case Owner Updated To: <User.Full_Name__c>"
 *   P5  + ISCHANGED(Status) + Original_RecordType__c IN ('Support_Charter_SMB','Support_Charter')
 *         -> "Status Updated To: <value>", IsPublished = TRUE (hardcoded)
 *
 * IsPublished is a formula on P1-P4: TRUE when Original_RecordType__c is one of
 * Support_Purolator / Support_Charter_SMB / Support_Charter, else FALSE. On P5 it is hardcoded
 * TRUE. Both branches are asserted.
 *
 * SO-3 IS PROVABLY A NON-ISSUE, and this harness pins it: P1-P4 carry the explicit
 * 'Support_Customer_ebonding' exclusion while P5 does not - but P5 instead REQUIRES
 * Support_Charter_SMB or Support_Charter, and a case cannot be both. The exclusion is therefore
 * redundant for P5, so F6 porting it as-is is equivalent rather than a judgement call.
 *
 * Every node gates on ISCHANGED, so every test is insert-then-update.
 *
 * Cases are built through a Contact rather than by assigning Case.AccountId: a directly-assigned
 * AccountId is silently dropped on insert in Apex test context (see Test_CollectionsDisputeParity
 * for the full finding). Since every node here requires AccountId NOT blank, getting this wrong
 * would make all five silently stop firing.
 *
 * ASSIGNMENT RULES: Case creation and all non-owner qualifying saves invoke the active Case
 * assignment rule. P3/P4 deliberately use direct owner reassignment without that header because
 * assignment rules would replace the requested queue/user before F6 evaluates the final OwnerId.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
private class Test_PartnerCommentParity {

    private static final String BRAND_NON_RISE = 'RingCentral';
    private static final String BRAND_RISE     = 'Rise America';

    private static final String RT_CHARTER  = 'Support_Charter';
    private static final String RT_EBONDING = 'Support_Customer_ebonding';
    private static final String RT_PLAIN    = 'Support_T2';

    private static final String STATUS_OPEN        = 'Open';
    private static final String STATUS_IN_PROGRESS = 'In Progress';
    private static final String ORIGIN_EMAIL       = 'Email';
    private static final String ORIGIN_PHONE       = 'Phone';

    private static final String PARTNER_STATUS_IN_PROGRESS = 'In Progress';
    private static final String SEVERITY_HIGH              = 'Level 3 - High';

    private static final String BODY_PARTNER_STATUS = 'Partner Case Status Updated To: ';
    private static final String BODY_SEVERITY       = 'Case Severity Updated To: ';
    private static final String BODY_OWNER          = 'Case Owner Updated To: ';
    private static final String BODY_STATUS         = 'Status Updated To: ';

    private static final String ACCOUNT_NAME      = 'PARITY Partner Account';
    private static final String RISE_ACCOUNT_NAME = 'PARITY Rise Account';
    private static final String CONTACT_NAME      = 'PARITY Partner Contact';
    private static final String RISE_CONTACT_NAME = 'PARITY Rise Contact';
    private static final String SUBJECT_PREFIX    = 'PARITY ';
    private static final String BRAND_IDENTIFIER  = 'PARITY-BRAND';

    @testSetup
    static void testData() {
        // Two brands: the shared gate excludes accounts whose Brand_Account__c begins with 'Rise'.
        // Brand_Account__c is a formula over the Account, so the brand is steered from here.
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.addAll(
            (List<Account>) new SObjectBuilder(Account.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.RC_Brand__c => BRAND_NON_RISE
                    }
                )
                .create()
                .getRecords()
        );
        partnerAccounts.addAll(
            (List<Account>) new SObjectBuilder(Account.SObjectType)
                .quantity(1)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => RISE_ACCOUNT_NAME,
                        Account.RC_Brand__c => BRAND_RISE
                    }
                )
                .create()
                .getRecords()
        );

        Map<String, Id> accountIdByName = new Map<String, Id>();
        for (Account partnerAccount : partnerAccounts) {
            accountIdByName.put(partnerAccount.Name, partnerAccount.Id);
        }

        new SObjectBuilder(Contact.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => CONTACT_NAME,
                    Contact.AccountId => accountIdByName.get(ACCOUNT_NAME)
                }
            )
            .create();
        new SObjectBuilder(Contact.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => RISE_CONTACT_NAME,
                    Contact.AccountId => accountIdByName.get(RISE_ACCOUNT_NAME)
                }
            )
            .create();
    }

    // ---------- helpers ----------

    private static Id contactIdByLastName(String lastName) {
        return [
            SELECT Id
            FROM Contact
            WHERE LastName = :lastName
        ].Id;
    }

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

    /** Builds and inserts a partner case; the insert itself must not post a comment (ISCHANGED). */
    private static Case createPartnerCase(String nodeLabel, String originalRecordType, String contactLastName) {
        Case partnerCase = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => SUBJECT_PREFIX + nodeLabel,
                    Case.Status => STATUS_OPEN,
                    Case.Origin => ORIGIN_EMAIL,
                    Case.RecordTypeId => (Id) Label.CaseRT_Support_T2_Id,
                    Case.ContactId => contactIdByLastName(contactLastName),
                    Case.Original_RecordType__c => originalRecordType
                }
            )
            .build()
            .getRecord();
        insertWithAssignmentRules(partnerCase);
        return partnerCase;
    }

    /**
     * Comments posted by THIS PB only.
     *
     * Raw CaseComment count is not a clean signal: other active automation in this org also posts
     * comments (Case Comments Creation for Direct Customer Cases, ... for RISE Partners, Case
     * Comments public for Charter and Enterprise records). Asserting on a total count therefore
     * measures the whole org, and a negative test can fail on somebody else's comment. Every
     * assertion here filters on the body prefix the node under test produces.
     */
    private static Id otherActiveUserId(Id currentOwnerId) {
        List<User> otherUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
              AND Id != :UserInfo.getUserId()
              AND Id != :currentOwnerId
              AND Profile.UserLicense.Name = 'Salesforce'
            LIMIT 1
        ];
        String preconditionMessage = 'P4 needs an active Salesforce user distinct from both the '
            + 'running user and the assignment-rule owner';
        Assert.isFalse(otherUsers.isEmpty(), preconditionMessage);
        return otherUsers[0].Id;
    }

    private static Id caseOwnerId(Id caseId) {
        return [
            SELECT OwnerId
            FROM Case
            WHERE Id = :caseId
        ].OwnerId;
    }

    private static List<CaseComment> commentsOn(Id caseId, String bodyPrefix) {
        List<CaseComment> matching = new List<CaseComment>();
        for (CaseComment comment : [
            SELECT CommentBody, IsPublished
            FROM CaseComment
            WHERE ParentId = :caseId
            ORDER BY CreatedDate ASC
        ]) {
            if (comment.CommentBody != null && comment.CommentBody.startsWith(bodyPrefix)) {
                matching.add(comment);
            }
        }
        return matching;
    }

    // ---------- P1: partner case status ----------

    @isTest
    static void shouldPostPartnerStatusCommentWhenPartnerCaseStatusChanges() {
        Case partnerCase = createPartnerCase('P1 status', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = partnerCase.Id, Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        List<CaseComment> comments = commentsOn(partnerCase.Id, BODY_PARTNER_STATUS);
        String countMessage = 'P1: a Partner_Case_Status__c change must post exactly one comment';
        String bodyMessage = 'P1: the comment body must be "' + BODY_PARTNER_STATUS
            + '" followed by the new partner status';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.areEqual(BODY_PARTNER_STATUS + PARTNER_STATUS_IN_PROGRESS, comments[0].CommentBody, bodyMessage);
    }

    @isTest
    static void shouldPublishCommentWhenOriginalRecordTypeIsPartnerFacing() {
        Case partnerCase = createPartnerCase('P1 published', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = partnerCase.Id, Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        List<CaseComment> comments = commentsOn(partnerCase.Id, BODY_PARTNER_STATUS);
        String countMessage = 'P1: the published-path save must post exactly one status comment';
        String publishedMessage = 'P1: IsPublished must be TRUE when Original_RecordType__c is one '
            + 'of Support_Purolator / Support_Charter_SMB / Support_Charter';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.isTrue(comments[0].IsPublished, publishedMessage);
    }

    @isTest
    static void shouldNotPublishCommentWhenOriginalRecordTypeIsNotPartnerFacing() {
        Case internalCase = createPartnerCase('P1 unpublished', RT_PLAIN, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = internalCase.Id, Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        List<CaseComment> comments = commentsOn(internalCase.Id, BODY_PARTNER_STATUS);
        String countMessage = 'P1: the comment must still be posted for a non-partner-facing record '
            + 'type - only its visibility differs';
        String unpublishedMessage = 'P1: IsPublished must be FALSE when Original_RecordType__c is '
            + 'not one of the three partner-facing values';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.isFalse(comments[0].IsPublished, unpublishedMessage);
    }

    @isTest
    static void shouldNotPostCommentWhenOriginalRecordTypeIsEbonding() {
        // The exclusion that P1-P4 carry and P5 does not (SO-3).
        Case ebondingCase = createPartnerCase('P1 ebonding', RT_EBONDING, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = ebondingCase.Id, Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        String excludedMessage = 'P1: an ebonding case must post no comment - '
            + 'Original_RecordType__c <> Support_Customer_ebonding is part of the gate';
        Assert.areEqual(0, commentsOn(ebondingCase.Id, BODY_PARTNER_STATUS).size(), excludedMessage);
    }

    // ---------- P2: case severity ----------

    @isTest
    static void shouldPostSeverityCommentWhenCaseSeverityChanges() {
        Case partnerCase = createPartnerCase('P2 severity', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = partnerCase.Id, Case_Severity__c = SEVERITY_HIGH)
            );
        Test.stopTest();

        List<CaseComment> comments = commentsOn(partnerCase.Id, BODY_SEVERITY);
        String countMessage = 'P2: a Case_Severity__c change must post exactly one comment';
        String bodyMessage = 'P2: the comment body must be "' + BODY_SEVERITY
            + '" followed by the new severity';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.areEqual(BODY_SEVERITY + SEVERITY_HIGH, comments[0].CommentBody, bodyMessage);
    }

    @isTest
    static void shouldPostOnlyPartnerStatusCommentWhenPrioritizedFieldsChangeTogether() {
        Case partnerCase = createPartnerCase('P1 priority', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(
                    Id = partnerCase.Id,
                    Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS,
                    Case_Severity__c = SEVERITY_HIGH,
                    Status = STATUS_IN_PROGRESS
                )
            );
        Test.stopTest();

        String p1Message = 'Priority: P1 must post exactly one partner-status comment when P1, '
            + 'P2, and P5 all match the same save';
        String p2Message = 'Priority: P2 must not post after P1 wins the first-match decision';
        String p5Message = 'Priority: P5 must not post after P1 wins the first-match decision';
        Assert.areEqual(1, commentsOn(partnerCase.Id, BODY_PARTNER_STATUS).size(), p1Message);
        Assert.areEqual(0, commentsOn(partnerCase.Id, BODY_SEVERITY).size(), p2Message);
        Assert.areEqual(0, commentsOn(partnerCase.Id, BODY_STATUS).size(), p5Message);
    }

    // ---------- P3 / P4: owner changes, split by owner type ----------

    @isTest
    static void shouldPostQueueOwnerCommentWhenOwnerChangesToQueue() {
        // P3 adds BEGINS(OwnerId,'00G') and STOPs, so a queue owner is handled here, never by P4.
        Case partnerCase = createPartnerCase('P3 queue owner', RT_CHARTER, CONTACT_NAME);
        Group expectedQueue = [
            SELECT Name
            FROM Group
            WHERE Id = :Label.CaseEsc_SOED_Queue_Id
        ];

        Test.startTest();
            // Explicit owner reassignment is the real P3 event. Requesting assignment rules on
            // this same DML would replace the requested queue before F6 evaluates OwnerId.
            update new Case(Id = partnerCase.Id, OwnerId = (Id) Label.CaseEsc_SOED_Queue_Id);
        Test.stopTest();

        List<CaseComment> comments = commentsOn(partnerCase.Id, BODY_OWNER);
        String countMessage = 'P3: an owner change to a QUEUE must post exactly one comment';
        String bodyMessage = 'P3: the comment body must name the queue that owns the Case';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.areEqual(BODY_OWNER + expectedQueue.Name, comments[0].CommentBody, bodyMessage);
    }

    @isTest
    static void shouldPostUserOwnerCommentWhenOwnerChangesToUser() {
        // P4 has no owner-type clause; it only ever sees non-queue owners because P3 stops first.
        Case partnerCase = createPartnerCase('P4 user owner', RT_CHARTER, CONTACT_NAME);
        // A DIFFERENT user: the case is already owned by the running user, so reassigning to
        // UserInfo.getUserId() is a no-op and ISCHANGED(OwnerId) would stay false.
        Id nextOwner = otherActiveUserId(caseOwnerId(partnerCase.Id));
        User expectedUser = [
            SELECT Full_Name__c
            FROM User
            WHERE Id = :nextOwner
        ];

        Test.startTest();
            // Explicit owner reassignment is the real P4 event. Assignment rules are deliberately
            // not requested because they would replace nextOwner before F6 evaluates OwnerId.
            update new Case(Id = partnerCase.Id, OwnerId = nextOwner);
        Test.stopTest();

        List<CaseComment> comments = commentsOn(partnerCase.Id, BODY_OWNER);
        String countMessage = 'P4: an owner change to a USER must post exactly one comment';
        String bodyMessage = 'P4: the comment body must name the user who owns the Case';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.areEqual(BODY_OWNER + expectedUser.Full_Name__c, comments[0].CommentBody, bodyMessage);
    }

    // ---------- P5: status change, Charter-only, always published ----------

    @isTest
    static void shouldPostPublishedStatusCommentWhenStatusChangesOnCharterCase() {
        Case charterCase = createPartnerCase('P5 charter', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = charterCase.Id, Status = STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        List<CaseComment> comments = commentsOn(charterCase.Id, BODY_STATUS);
        String countMessage = 'P5: a Status change on a Charter case must post exactly one comment';
        String bodyMessage = 'P5: the comment body must be "' + BODY_STATUS
            + '" followed by the new status';
        String publishedMessage = 'P5: IsPublished is hardcoded TRUE on this node, unlike the '
            + 'formula used by P1-P4';
        Assert.areEqual(1, comments.size(), countMessage);
        Assert.areEqual(BODY_STATUS + STATUS_IN_PROGRESS, comments[0].CommentBody, bodyMessage);
        Assert.isTrue(comments[0].IsPublished, publishedMessage);
    }

    @isTest
    static void shouldNotPostStatusCommentWhenStatusChangesOnNonCharterCase() {
        // P5 requires Support_Charter_SMB or Support_Charter. This is also what makes P5's missing
        // ebonding exclusion harmless (SO-3): ebonding can never satisfy this positive filter.
        Case plainCase = createPartnerCase('P5 non-charter', RT_PLAIN, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = plainCase.Id, Status = STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        String gateMessage = 'P5: a Status change on a non-Charter case must post no comment - the '
            + 'positive record-type filter is the gate, and it also subsumes the ebonding exclusion';
        Assert.areEqual(0, commentsOn(plainCase.Id, BODY_STATUS).size(), gateMessage);
    }

    // ---------- the shared gate ----------

    @isTest
    static void shouldNotPostCommentWhenAccountBrandIsRise() {
        Case riseCase = createPartnerCase('gate rise', RT_CHARTER, RISE_CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(Id = riseCase.Id, Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS)
            );
        Test.stopTest();

        String riseMessage = 'Shared gate: a Rise-branded account must post no comment - every node '
            + 'requires NOT BEGINS(Brand_Account__c, "Rise")';
        Assert.areEqual(0, commentsOn(riseCase.Id, BODY_PARTNER_STATUS).size(), riseMessage);
    }

    @isTest
    static void shouldNotPostCommentWhenBrandIdentifierIsPopulated() {
        Case brandedCase = createPartnerCase('gate brandId', RT_CHARTER, CONTACT_NAME);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(
                    Id = brandedCase.Id,
                    Brand_Identifier__c = BRAND_IDENTIFIER,
                    Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS
                )
            );
        Test.stopTest();

        String brandIdMessage = 'Shared gate: a populated Brand_Identifier__c must post no comment '
            + '- every node requires ISBLANK(Brand_Identifier__c)';
        Assert.areEqual(0, commentsOn(brandedCase.Id, BODY_PARTNER_STATUS).size(), brandIdMessage);
    }

    @isTest
    static void shouldNotPostCommentWhenCaseHasNoAccount() {
        Case noAccountCase = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => SUBJECT_PREFIX + 'gate no account',
                    Case.Status => STATUS_OPEN,
                    Case.Origin => ORIGIN_PHONE,
                    Case.RecordTypeId => (Id) Label.CaseRT_Support_T2_Id,
                    Case.Original_RecordType__c => RT_CHARTER
                }
            )
            .build()
            .getRecord();
        insertWithAssignmentRules(noAccountCase);

        Test.startTest();
            updateWithAssignmentRules(
                new Case(
                    Id = noAccountCase.Id,
                    Partner_Case_Status__c = PARTNER_STATUS_IN_PROGRESS
                )
            );
        Test.stopTest();

        String accountMessage = 'Shared gate: a Case without an Account must post no partner '
            + 'comment even when Partner_Case_Status__c changes';
        Assert.areEqual(0, commentsOn(noAccountCase.Id, BODY_PARTNER_STATUS).size(), accountMessage);
    }
}
