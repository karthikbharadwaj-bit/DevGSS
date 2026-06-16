@IsTest
private class Test_CaseQueueable {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        Map<Id, Account> accIdTOAccount = new Map<Id, Account>();
        List<Opportunity> opps = new List<Opportunity>();

        Id ownerId = UserInfo.getUserId();

        for (Integer index = 0; index < 10; index++) {
            Account newTestAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'testAcc' + index,
                    Account.Changes__c => ('success;' + CaseQueueable.ACCOUNT_FILED_RC_USER_ID),
                    Account.Most_Recent_Opportunity_Owner__c => ownerId
                })
                .build()
                .getRecord();

            accounts.add(newTestAccount);
        }
        insert accounts;

        Triggers.switchOff();
        for (Account acc : accounts) {
            accIdTOAccount.put(acc.Id, acc);
            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CloseDate => System.today().addMonths(1)
                })
                .build()
                .getRecord();
            opps.add(opp);
        }
        insert opps;

        for (Opportunity opp : opps) {
            Account acc = accIdTOAccount.get(opp.AccountId);
            acc.Funnel_not_supported__c = 'Account: "https://rc.my.salesforce.com/' + acc.Id + '"\n'
                + 'Opportunity: "https://rc.my.salesforce.com/' + opp.Id + '"';
        }
        update accIdTOAccount.values();
        Triggers.switchOn();

        List<Contact> contacts = new List<Contact>();

        String userEmail = UserInfo.getUserEmail();
        String firstName = UserInfo.getFirstName();
        String lastName = UserInfo.getLastName();

        for (Integer index = 0; index < 10; index++) {
            Contact newTestContact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Contact.FirstName => firstName,
                    Contact.LastName => lastName,
                    Contact.Email => userEmail
                })
                .build()
                .getRecord();

            contacts.add(newTestContact);
        }

        if (contacts.size() > 0) {
            insert contacts;
        }
    }

    @IsTest
    static void testCaseQueueableForFunnelNotSupported() {
        Test.startTest();
        Account testAccount = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name'
            })
            .executeQuery()
            .get(0);

        CaseQueueable queueable = new CaseQueueable(new Set<Id>{testAccount.Id}, new List<DealDeskCaseDescription__c>());
        System.enqueueJob(queueable);
        Test.stopTest();

        Account testAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name'
            })
            .setCondition('Name LIKE \'testAcc%\'')
            .executeQuery()
            .get(0);

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        System.assert(testAcc != null);
        System.assertEquals(testAcc.Changes__c, 'success', 'Field changes must be null');
        System.assertEquals(caseList.size(), 1, 'CreateDealDeskCase should properly create cases for Funnel_not_supported__c');
    }

    @IsTest
    static void testCaseQueueableForFunnelNotSupported_excludeMPUB() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Test.startTest();
        Account testAccount = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name', 'IsMultiProductTechnicalAccount__c', 'Master_Account__c'
            })
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        update testAccount;
        Triggers.switchOn();

        CaseQueueable queueable = new CaseQueueable(new Set<Id>{testAccount.Id}, new List<DealDeskCaseDescription__c>());
        System.enqueueJob(queueable);
        Test.stopTest();

        Account testAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name'
            })
            .setCondition('Name LIKE \'testAcc%\'')
            .executeQuery()
            .get(0);

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        System.assert(testAcc != null);
        System.assertEquals(testAcc.Changes__c, 'success;' + CaseQueueable.ACCOUNT_FILED_RC_USER_ID, 'Field changes must be null');
        System.assertEquals(caseList.size(), 0, 'CreateDealDeskCase should not create cases for Funnel_not_supported__c if Account is Unified Billing');
    }

    @IsTest
    static void testCaseQueueableForDealDeskCaseDescription() {
        Test.startTest();
        Id ownerId = UserInfo.getUserId();
        Account testAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name'
            })
            .executeQuery()
            .get(0);

        Opportunity testOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .setCondition('AccountId = :bind0')
            .setQueryBindings(new List<Object>{testAcc.Id})
            .executeQuery()
            .get(0);

        String description = 'Account: https://rc.my.salesforce.com/' + testAcc.Id + '\n'
            + 'Opportunity: https://rc.my.salesforce.com/' + testOpp.Id + '\n';
        DealDeskCaseDescription__c caseDescription =
            (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DealDeskCaseDescription__c.CaseDescription__c => description,
                DealDeskCaseDescription__c.Account__c => testAcc.Id,
                DealDeskCaseDescription__c.Subject__c => CaseHelper.CASE_SUBJECT_MANUAL_SHIPPING,
                DealDeskCaseDescription__c.CaseOwner__c => ownerId
            })
            .create()
            .getRecord();

        CaseQueueable queueable = new CaseQueueable(new Set<Id>(), new List<DealDeskCaseDescription__c> {caseDescription});
        System.enqueueJob(queueable);
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new Set<String>{'Opportunity_Reference__c'})
            .executeQuery();

        System.assertEquals(caseList.size(), 1, 'CaseQueueable should properly create cases for DealDeskCaseDescription__c');
        System.assertEquals(caseList.get(0).Opportunity_Reference__c, testOpp.Id,
            'CaseQueueable should properly fill Opportunity_Reference__c on Cases');
    }

    @IsTest
    static void testCaseQueueableForDealDeskCaseDescriptionWithoutReference() {
        Test.startTest();
        Id ownerId = UserInfo.getUserId();
        Account testAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String>{
                'Changes__c', 'RC_USER_ID__c', 'Most_Recent_Opportunity_Owner_Email__c', 'Name'
            })
            .executeQuery()
            .get(0);

        Opportunity testOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .setCondition('AccountId = :bind0')
            .setQueryBindings(new List<Object>{testAcc.Id})
            .executeQuery()
            .get(0);

        DealDeskCaseDescription__c caseDescription =
            (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DealDeskCaseDescription__c.CaseDescription__c => null,
                DealDeskCaseDescription__c.Account__c => testAcc.Id,
                DealDeskCaseDescription__c.Subject__c => CaseHelper.CASE_SUBJECT_MANUAL_SHIPPING,
                DealDeskCaseDescription__c.CaseOwner__c => ownerId
            })
            .create()
            .getRecord();

        CaseQueueable queueable = new CaseQueueable(new Set<Id>(), new List<DealDeskCaseDescription__c> {caseDescription});
        System.enqueueJob(queueable);
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new Set<String>{'Opportunity_Reference__c'})
            .executeQuery();

        System.assertEquals(caseList.size(), 1, 'CaseQueueable should properly create cases without Opportunity_Reference__c');
        System.assertEquals(caseList.get(0).Opportunity_Reference__c, null, 'CaseQueueable should properly handle empty CaseDescription__c');
    }
}