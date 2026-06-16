@isTest
public class DQ_CreateDQAndHistoryBatch_Test {
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

        Opportunity objOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test 1',
                Opportunity.Brand_Name__c => 'Avaya Cloud Office',
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => objAcc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1)
            })
            .create()
            .getRecord();
        
        Product2 objProduct = new Product2(Name = 'Test product1', family = 'Cafe');
                                                    
        insert objProduct;
       
        PriceBookEntry objPBE = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = Test.getStandardPricebookId(),
                                                        Product2Id = objProduct.Id, IsActive = true);
                                                               
        
        insert objPBE;
        List<Quote> lstQuote = new List<Quote>();
        lstQuote.add(new Quote(Initial_Term_months__c='12',OpportunityId = objOpp.Id, Name = 'Test Quote', Pricebook2Id = Test.getStandardPricebookId(), Status = 'Review Pending'));
        insert lstQuote;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void callBatchToUpdateStatusTracker() {
        DQ_CreateDQAndHistoryBatch objBatch = new DQ_CreateDQAndHistoryBatch();
        Test.startTest();
        Database.executeBatch(objBatch,10);
        Test.stopTest();
    }
}