@isTest
public class DQ_QuoteStatusTrackingBatch_Test {
	private static Id newSalesRecordTypeId =  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId();

    @testSetup static void setup() {

        User userRec = new User(Id = UserInfo.getUserId());
        userRec.SegmentPicklist__c = 'SOHO';
        userRec.Region__c = 'EU';
        update userRec;

        Segment_Master__c sg = new Segment_Master__c();
        sg.Name = 'SOHO';
        sg.Country__c = 'United States';
        sg.Max__c = 1;
        sg.Min__c = 10000;
        sg.Start_Date__c = Date.today();
        sg.CurrencyIsoCode = 'USD';
        insert sg;

    	Account ObjAcc = new Account();
        ObjAcc.Name = 'Test 1';
        ObjAcc.OwnerId = userRec.Id;
        ObjAcc.Segment_Name__c = sg.Id;
        insert ObjAcc;

        // insert Opp
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'Test 1';
        objOpp.StageName = '1. Qualify';
        objOpp.AccountId = objAcc.Id;
        objOpp.RecordTypeId = newSalesRecordTypeId;
        objOpp.Brand_Name__c =  'Avaya Cloud Office';
        insert objOpp;

        Product2 objProduct = new Product2(Name = 'Test product1', family = 'Cafe');
        insert objProduct;

        PriceBookEntry objPBE = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = Test.getStandardPricebookId(),
            Product2Id = objProduct.Id,
            IsActive = true
        );
        insert objPBE;

        List<Quote> lstQuote = new List<Quote>();
        lstQuote.add(
            new Quote(
                OpportunityId = objOpp.Id,
                Name = 'Test Quote',
                Pricebook2Id = Test.getStandardPricebookId(),
                Status = 'Review Pending',
                Approved_Status__c = 'Required'
            )
        );
        insert lstQuote;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void callBatchToUpdateStatusTracker() {
        DQ_QuoteStatusTrackingBatch objBatch = new DQ_QuoteStatusTrackingBatch();
        Test.startTest();
        Database.executeBatch(objBatch,10);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void callBatchToUpdateStatusTrackerExisting() {
        DQ_QuoteStatusTrackingBatch objBatch = new DQ_QuoteStatusTrackingBatch();
        List<Quote> quoteList = [SELECT Id FROM Quote];
        DQ_Quote_Status_Tracker__c objNEWTracker = new DQ_Quote_Status_Tracker__c();
        objNEWTracker.Quote__c = quoteList[0].Id;
        objNEWTracker.Quote_Status__c = 'Pending';
        insert objNEWTracker;
        Test.startTest();
        Database.executeBatch(objBatch,10);
        Test.stopTest();
    }
}