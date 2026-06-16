@isTest
private class Test_BatchJob_OpportunityRenewal {
    private static final Integer DAYS_TILL_CLOSE_DATE = 0;
    private static final Integer MRR_THRESHOLD = 400;
    private static final Decimal TOTAL_CONTRACT_VALUE = 10.0;

    private static final String RENEWAL_OPPORTUNITY_OWNER = 'renewalOpportunityOwner';
    private static final String CONTACT_LASTNAME = 'testContactLastName';

    private static final String BRAND_NAME = OpportunityHelper.BRAND_RINGCENTRAL;
    private static final String TIER_NAME = OpportunityHelper.TIER_BT_OFFICE;
    private static final String CW_CATEGORIES_WHO_DID_WE_BEAT = 'CW_Categories_Who_did_we_beat__c';
    private static final String CW_CATEGORIES_WHO_DID_WE_REPLACE = 'CW_Categories_Who_did_we_replace__c';
    private static final String CW_PRIMARY_WIN_REASON = 'CW_Primary_Win_Reason__c';
    private static final String CW_SECONDARY_WIN_REASON = 'CW_Secondary_Win_Reason__c';
    private static final String CW_WHO_DID_WE_BEAT = 'CW_Who_did_we_beat__c';
    private static final String CW_WHO_DID_WE_REPLACE = 'CW_Who_did_we_replace__c';
    private static final String CW_WIN_REASON_AWARDS = 'CW_Win_Reason_Awards__c';
    private static final String CW_WIN_REASON_FEATURES = 'CW_Win_Reason_Features__c';
    private static final String CW_WIN_REASON_INTEGRATIONS = 'CW_Win_Reason_Integrations__c';
    private static final String CW_WIN_REASON_SAVINGS = 'CW_Win_Reason_Savings__c';

    private static final String NO_CREATED_ACCOUNTS_ERROR = 'No created accounts';
    private static final String FOUND_UNEXPECTED_OPPORTUNITIES_ERROR = 'Found unexpected opportunities';
    private static final String NO_CREATED_RENEWAL_OPPORTUNITY_ERROR = 'No created renewal opportunity';
    private static final String RENEWAL_OPPTY_SHOULD_HAVE_TYPE_EQUAL_RENEWAL_ERROR = 'Renewal oppty should have type equal renewal';
    private static final String RenewalOpptyHasWrongOwner = 'Renewal oppty has wrong owner';

    @TestSetup
    static void makeData() {
        Triggers.switchOff();
        Contact testcontact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, CONTACT_LASTNAME)
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.MRR__c => MRR_THRESHOLD,
                    Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                    Account.Billing_ID__c => 'fakeId',
                    Account.RC_Brand__c => BRAND_NAME,
                    Account.OwnerId => UserInfo.getUserId()
                })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => BRAND_NAME,
                    Opportunity.Tier_Name__c => TIER_NAME,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CW_Categories_Who_did_we_beat__c => CW_CATEGORIES_WHO_DID_WE_BEAT,
                    Opportunity.CW_Categories_Who_did_we_replace__c => CW_CATEGORIES_WHO_DID_WE_REPLACE,
                    Opportunity.CW_Primary_Win_Reason__c => CW_PRIMARY_WIN_REASON,
                    Opportunity.CW_Secondary_Win_Reason__c => CW_SECONDARY_WIN_REASON,
                    Opportunity.CW_Who_did_we_beat__c => CW_WHO_DID_WE_BEAT,
                    Opportunity.CW_Who_did_we_replace__c => CW_WHO_DID_WE_REPLACE,
                    Opportunity.CW_Win_Reason_Awards__c => CW_WIN_REASON_AWARDS,
                    Opportunity.CW_Win_Reason_Features__c => CW_WIN_REASON_FEATURES,
                    Opportunity.CW_Win_Reason_Integrations__c => CW_WIN_REASON_INTEGRATIONS,
                    Opportunity.CW_Win_Reason_Savings__c => CW_WIN_REASON_SAVINGS,
                    Opportunity.Total_Contract_Value__c => TOTAL_CONTRACT_VALUE,
                    Opportunity.Primary_Opportunity_Contact__c => testcontact.Id,
                    Opportunity.StageName => OpportunityHelper.OPPORTUNITY_STAGES.containsKey('7') ? OpportunityHelper.OPPORTUNITY_STAGES.get('7'):OpportunityHelper.STAGE_NAME_CLOSED_WON
                })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => Date.today().addDays(90),
                    Quote.Auto_Renewal__c => true
                })
            .create()
            .getRecord();

        testAcc.Active_Sales_Agreement__c = testQuote.Id;
        update testAcc;



        OpportunityRenewalSettings__c renewalSettings = (OpportunityRenewalSettings__c) new SObjectBuilder(OpportunityRenewalSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityRenewalSettings__c.DefaultOwnerId__c => UserInfo.getUserId(),
                OpportunityRenewalSettings__c.MRRThreshold__c => MRR_THRESHOLD,
                OpportunityRenewalSettings__c.Days_Till_Opportunity_Close_Date__c => DAYS_TILL_CLOSE_DATE,
                OpportunityRenewalSettings__c.DaysTillAgreementEnd__c => DAYS_TILL_CLOSE_DATE,
                OpportunityRenewalSettings__c.BrandsForRenewal__c =>  OpportunityHelper.BRAND_RINGCENTRAL_CA + ';' + BRAND_NAME,
                OpportunityRenewalSettings__c.AccountStatus__c => AccountHelper.PAID_STATUS,
                OpportunityRenewalSettings__c.Name => 'test'
            })
            .create()
            .getRecord();

        new SObjectBuilder(User.SObjectType)
            .setField(User.LastName, RENEWAL_OPPORTUNITY_OWNER)
            .setField(User.Country__c , 'United States')
            .create();

        Triggers.switchOn();
    }

    private static QueryFactory getOpportunityQueryFactory(String accId) {

        return new OpportunitySelector()
            .selectOpportunities()
            .setCondition('AccountId = :bind0 AND Type = \'Renewal\'')
            .setQueryBindings(new List<Object> {accId})
            .selectFields(
                new List<String> {'Id', 'Brand_Name__c', 'Tier_Name__c', 'OwnerId', 'CW_Categories_Who_did_we_beat__c',
                    'CW_Categories_Who_did_we_replace__c', 'CW_Primary_Win_Reason__c', 'CW_Secondary_Win_Reason__c',
                    'CW_Who_did_we_beat__c', 'CW_Who_did_we_replace__c', 'CW_Win_Reason_Awards__c',
                    'CW_Win_Reason_Features__c', 'CW_Win_Reason_Integrations__c', 'CW_Win_Reason_Savings__c',
                    'Primary_Opportunity_Contact__r.LastName'
                }
            );
    }

    @isTest
    private static void test_renewalOpportunityCreated() {
        Test.startTest();
        List<Account> accList = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.Id
            })
            .executeQuery();
        System.assertEquals(1, accList.size(), NO_CREATED_ACCOUNTS_ERROR);

        QueryFactory opportunitySelector = getOpportunityQueryFactory(accList[0].Id);
        List<Opportunity> oppsList = opportunitySelector.executeQuery();
        System.assertEquals(0, oppsList.size(), FOUND_UNEXPECTED_OPPORTUNITIES_ERROR);


        Database.executeBatch(new BatchJob_OpportunityRenewal());
        Test.stopTest();

        oppsList = opportunitySelector.executeQuery();
        System.assertEquals(1, oppsList.size(), NO_CREATED_RENEWAL_OPPORTUNITY_ERROR);
        Opportunity renewalOppty = oppsList[0];

        System.assertEquals(true, renewalOppty.Is_Billing_Opportunity__c);
        System.assertEquals(BRAND_NAME, renewalOppty.Brand_Name__c);
        System.assertEquals(TIER_NAME, renewalOppty.Tier_Name__c);
        System.assertEquals(CW_CATEGORIES_WHO_DID_WE_BEAT, renewalOppty.CW_Categories_Who_did_we_beat__c);
        System.assertEquals(CW_CATEGORIES_WHO_DID_WE_REPLACE, renewalOppty.CW_Categories_Who_did_we_replace__c);
        System.assertEquals(CW_PRIMARY_WIN_REASON, renewalOppty.CW_Primary_Win_Reason__c);
        System.assertEquals(CW_SECONDARY_WIN_REASON, renewalOppty.CW_Secondary_Win_Reason__c);
        System.assertEquals(CW_WHO_DID_WE_BEAT, renewalOppty.CW_Who_did_we_beat__c);
        System.assertEquals(CW_WHO_DID_WE_REPLACE, renewalOppty.CW_Who_did_we_replace__c);
        System.assertEquals(CW_WIN_REASON_AWARDS, renewalOppty.CW_Win_Reason_Awards__c);
        System.assertEquals(CW_WIN_REASON_FEATURES, renewalOppty.CW_Win_Reason_Features__c);
        System.assertEquals(CW_WIN_REASON_INTEGRATIONS, renewalOppty.CW_Win_Reason_Integrations__c);
        System.assertEquals(CW_WIN_REASON_SAVINGS, renewalOppty.CW_Win_Reason_Savings__c);
        System.assertNotEquals(null, renewalOppty.Primary_Opportunity_Contact__c);
        System.assertEquals(CONTACT_LASTNAME, renewalOppty.Primary_Opportunity_Contact__r.LastName);
    }

    @isTest
    private static void test_settingsInvalidUserId() {
        OpportunityRenewalSettings__c renewalSettings = OpportunityRenewalSettings__c.getall().values();
        renewalSettings.DefaultOwnerId__c = 'InvalidId';
        update renewalSettings;

        try {
            BatchJob_OpportunityRenewal batch = new BatchJob_OpportunityRenewal();
            System.assert(false, 'Exception should be thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(
                'Invalid one of renewal opportunity owner id'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }

    @isTest
    private static void test_SchedulerTest() {
        Test.startTest();
        List<Account> accList = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {Account.Id})
            .executeQuery();
        System.assertEquals(1, accList.size(), NO_CREATED_ACCOUNTS_ERROR);

        QueryFactory opportunitySelector = getOpportunityQueryFactory(accList[0].Id);
        List<Opportunity> oppsList = opportunitySelector.executeQuery();
        System.assertEquals(0, oppsList.size(), FOUND_UNEXPECTED_OPPORTUNITIES_ERROR);

        BatchJob_OpportunityRenewal batchScheduler = new BatchJob_OpportunityRenewal();
        batchScheduler.execute(null);
        Test.stopTest();
        oppsList = opportunitySelector.executeQuery();
        System.assertEquals(1, oppsList.size());
    }

    @isTest
    private static void test_disabledAssignmentLogic() {
        Test.startTest();
        List<Account> accList = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {Account.Id})
            .executeQuery();
        System.assertEquals(1, accList.size(), NO_CREATED_ACCOUNTS_ERROR);

        QueryFactory opportunitySelector = getOpportunityQueryFactory(accList[0].Id);
        List<Opportunity> oppsList = opportunitySelector.executeQuery();
        System.assertEquals(0, oppsList.size(), FOUND_UNEXPECTED_OPPORTUNITIES_ERROR);

        User defaultOwnerId = (User) new UserSelector()
            .selectUserByLastName(new List<Object> {new List<String> {RENEWAL_OPPORTUNITY_OWNER}})
            .executeQuery()
            .get(0);

        OpportunityRenewalSettings__c renewalSettings = OpportunityRenewalSettings__c.getall().values();
        renewalSettings.DefaultOwnerId__c = defaultOwnerId.Id;
        update renewalSettings;

        Database.executeBatch(new BatchJob_OpportunityRenewal());
        Test.stopTest();

        oppsList = opportunitySelector.executeQuery();
        System.assertEquals(1, oppsList.size(), NO_CREATED_RENEWAL_OPPORTUNITY_ERROR);
        Opportunity renewalOppty = oppsList[0];

        System.assertEquals(
            OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
            renewalOppty.Type,
            RENEWAL_OPPTY_SHOULD_HAVE_TYPE_EQUAL_RENEWAL_ERROR
        );
        System.assertEquals(
            renewalSettings.DefaultOwnerId__c,
            renewalOppty.OwnerId,
            RenewalOpptyHasWrongOwner
        );
    }

    @isTest
    private static void testRunNextBatch() {
        Test.startTest();
        Id nextbatchJobId = BatchJob_OpportunityRenewal.runNextBatch();
        Test.stopTest();

        List<AsyncApexJob> jobs = (new AsyncApexJobSelector()).selectBatchById(nextbatchJobId).executeQuery();

        System.assert(!jobs.isEmpty(), 'Unable to find next batch job');
        System.assertEquals(BatchJob_CloseRenewalOpportunity.class.getName(), jobs[0].ApexClass.Name,
            'Wrong next batch job executed.');
    }
}