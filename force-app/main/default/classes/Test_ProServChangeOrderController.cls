@isTest private class Test_ProServChangeOrderController {

    @isTest
    static void testInvokeController() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'test',
                    Contact.LastName => 'test',
                    Contact.AccountId => testAcc.Id
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
                }
            )
            .create();

        Id stdPricebookId = Test.getStandardPricebookId();

        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => testAcc.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.OpportunityId => testOpp.Id,
                Order.Status => 'New',
                Order.EffectiveDate => Date.today(),
                Order.Pricebook2Id => stdPricebookId,
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => proservProject.Id,
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER
            })
            .create();

        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.standardController(proservProject);
            ProServChangeOrderController proServChangeOrderController = new ProServChangeOrderController(sc);
        Test.stopTest();
        
        System.assertNotEquals(null, proServChangeOrderController, 'Contrller should be created');
    }
}