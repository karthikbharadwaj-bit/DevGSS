@isTest
public class Test_ProServProjectObj {

    @TestSetup
    static void makeData(){
        
        Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
        featureToogleSetting.NewProServObjectRelatedData__c = true;
        insert featureToogleSetting;
    }

    @isTest
    static void test_populateOrderProServIdOnInsert () {
        
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => System.today()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            ProServ_Project__c proServ = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        ProServ_Project__c.Order__c => ord.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, ProServProject__c 
                                    FROM Order 
                                    WHERE Id = :ord.Id];
        System.assertEquals(updatedOrder[0].ProServProject__c, proServ.Id, 'ProServProject__c field in Order did not insert correctly.');

    }

    @isTest
    static void test_populateOrderProServIdOnUpdate () {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => System.today()
                }
            )
            .create()
            .getRecord();
        ProServ_Project__c proServ = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    ProServ_Project__c.Order__c => ord.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            update proServ;
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, ProServProject__c 
                                    FROM Order 
                                    WHERE Id = :ord.Id];
        System.assertEquals(updatedOrder[0].ProServProject__c, proServ.Id, 'ProServProject__c field in Order did not insert correctly.');

    }

    @isTest
    static void test_populatePhaseProServIdOnInsert () {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote quo = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();        
        Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase_1',
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId()
                }
            )
            .create()
            .getRecord();

        phase.OriginalQuoteNumber__c =  quo.Id;        
        update phase;

        ProServ_Project__c proServ = new ProServ_Project__c();
        quo = [SELECT Id, QuoteNumber 
               FROM Quote 
               WHERE Id = :quo.Id];

        Test.startTest();
            proServ = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        ProServ_Project__c.PS_Quote_Number__c => quo.QuoteNumber
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Phase__c> updatedPhase = [SELECT ProServProject__c 
                                       FROM Phase__c 
                                       WHERE Id = :phase.Id];
        System.assertEquals(updatedPhase[0].ProServProject__c, proServ.Id, 'ProServProject__c field in Phase__c did not insert correctly.');
    }

    @isTest
    static void test_populatePhaseProServIdOnUpdate () {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote quo = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => opp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => opp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();        
        Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase_1',
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId()
                }
            )
            .create()
            .getRecord();

        phase.OriginalQuoteNumber__c =  quo.Id;
        update phase;

        ProServ_Project__c proServ = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.SObjectType)
            .create()
            .getRecord();

        quo = [SELECT Id, QuoteNumber 
               FROM Quote 
               WHERE Id = :quo.Id];
        proServ.PS_Quote_Number__c = quo.QuoteNumber;

        Test.startTest();
            update proServ;
        Test.stopTest();

        List<Phase__c> updatedPhase = [SELECT ProServProject__c 
                                       FROM Phase__c 
                                       WHERE Id = :phase.Id];
        System.assertEquals(updatedPhase[0].ProServProject__c, proServ.Id, 'ProServProject__c field in Phase__c did not insert correctly.');
    }

    @isTest
    static void test_FeatureToggleOff () {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => System.today()
                }
            )
            .create()
            .getRecord();

        ProServ_Project__c proServ = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.SObjectType)
            .create()
            .getRecord();
        proServ.Order__c = ord.Id;
        Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
        featureToogleSetting.NewProServObjectRelatedData__c = false;
        update featureToogleSetting;

        Test.startTest();
            update proServ;
        Test.stopTest();
        
        Id proServId = [SELECT ProServProject__c 
                        FROM Order 
                        WHERE Id = :ord.Id].ProServProject__c;

        System.assertEquals(proServId, null, 'The feature toggle did not stop the execution.');

    }

}