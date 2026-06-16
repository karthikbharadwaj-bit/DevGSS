@isTest
public class Test_PartnerDealSupport{

    private static void createTestRecords() {
        Account portalAccount1 = new Account(Name = 'TestAccount');
    	insert portalAccount1;

        Opportunity opp = new Opportunity(
            Name = 'test',
            AccountId = portalAccount1.Id,
            StageName = '5. Agreement'
        );
        insert opp;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Start_Date__c = System.today();
        quoteList[0].Opportunity__c = opp.Id;
        quoteList[0].Initial_Term__c = '12';
        insert quoteList;

        Partner_Quote__c quote = quoteList[0];

        Deal_Support__c dealsupport = new Deal_Support__c(
            partner_Quote__c = quote.Id,
            Type__c = 'Initial Order'
        );
        insert dealsupport;

        Deal_Support_Comments__c dscomment = new Deal_Support_Comments__c(
            Deal_Support__c = dealsupport.Id,
            Comments__c = 'Initial Comment'
        );
        insert dscomment;
    }

    @isTest
    static void testUpdateDSOwner() {
        createTestRecords();
        Deal_Support__c dealsupport = [SELECT Id FROM Deal_Support__c LIMIT 1];

        Test.startTest();
        Partner_DealSupport.updateDSOwner(dealsupport.Id, 'Discount Request');
        Test.stopTest();

        Deal_Support__c updatedDealSupport = [SELECT Id, OwnerId, Sub_Status__c FROM Deal_Support__c WHERE Id = :dealsupport.Id];
        System.assertNotEquals(null, updatedDealSupport.OwnerId);
        System.assertEquals('Pending RC Approval', updatedDealSupport.Sub_Status__c);
    }

    @isTest
    static void testGetNewDealComments() {
        createTestRecords();
        Deal_Support__c dealsupport = [SELECT Id FROM Deal_Support__c LIMIT 1];

        String newComment = 'New Comment';
        Test.startTest();
        Deal_Support_Comments__c result = Partner_DealSupport.getNewDealComments(dealsupport.Id, newComment);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(newComment, result.Comments__c);
        System.assertEquals(dealsupport.Id, result.Deal_Support__c);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod2() {
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc = PartnerRecordsUtil.partnerAccount;
        Contact con = PartnerRecordsUtil.partnerContact;

        System.runAs(PartnerRecordsUtil.runAsSysAdmin) {
            Account portalAccount1 = new Account(Name = 'TestAccount');
            insert portalAccount1;

            Opportunity opp = new Opportunity(
                Name = 'test',
                AccountId = portalAccount1.id,
                StageName = '5. Agreement'
            );
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            insert quoteList;

            Partner_Quote__c quote = quoteList[0];

            Deal_Support__c dealsupport = new Deal_Support__c(
                partner_Quote__c = quote.Id,
                Type__c = 'Initial Order'
            );
            insert dealsupport;

            Test.startTest();
            Partner_DealSupport.updateQuoteStatus(dealsupport.Id, dealsupport.partner_Quote__c, 'Approve', 'Business Reason');
            Partner_DealSupport.updateQuoteStatus(dealsupport.Id, dealsupport.partner_Quote__c, 'Rejected', 'Business Reason');
            Test.stopTest();
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod3() {
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc = PartnerRecordsUtil.partnerAccount;
        Contact con = PartnerRecordsUtil.partnerContact;

        System.runAs(PartnerRecordsUtil.runAsSysAdmin) {
            Account portalAccount1 = new Account(Name = 'TestAccount');
            insert portalAccount1;

            Opportunity opp = new Opportunity(
                Name = 'test',
                AccountId = portalAccount1.id,
                StageName = '5. Agreement'
            );
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            insert quoteList;

            Partner_Quote__c quote = quoteList[0];

            Deal_Support__c dealsupport = new Deal_Support__c(
                partner_Quote__c = quote.Id,
                Type__c = 'Initial Order'
            );
            insert dealsupport;

            Test.startTest();
            Partner_DealSupport.updateDealSupportList(dealsupport.Id, 'In Progress', 30, false, 'Business Reason');
            Partner_DealSupport.updateDealSupportPocCheckbox(dealsupport);
            Partner_DealSupport.getFiles(dealsupport.Id);
            Test.stopTest();
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod4(){
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();  
            Deal_Support_Comments__c dealsupcomments = new Deal_Support_Comments__c(Comments__c='test',Deal_Support__c=dealsupport.Id);
            insert dealsupcomments;
            Test.startTest();        
            Partner_DealSupport.getAttachmentOppo(dealsupport.Id);
            Partner_DealSupport.PartnerDealSupportCommentsWrapper.getSupportComments(dealsupport.Id);
            Partner_DealSupport.getNewDealComments(dealsupport.Id,'testing');
            Partner_DealSupport.updateDSOwner(dealsupport.Id,'Discount Request');
            Test.stopTest();
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod10(){        
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        Test.startTest();      
        Partner_DealSupport.AccountListWrapper.getAccountList();
        Test.stopTest();
    }         
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod1(){
       PartnerRecordsUtil.createAvayaPartnerAccount();
       Account acc=PartnerRecordsUtil.partnerAccount;
       Contact con=PartnerRecordsUtil.partnerContact;
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();
            Test.startTest();
            Partner_DealSupport.DealSupportListWrapper pw = Partner_DealSupport.getDealSupportDataController(dealsupport.Partner_Account__c,dealsupport.Status__c,dealsupport.Type__c,1,10,'Name','Initial',false,false,false,false,false);
            //Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(dealsupport.Partner_Account__c,dealsupport.Status__c,dealsupport.Type__c,1,10,'Name','Initial',false,true,true,false);
            Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(null,null,null,1,10,'Name','Initial',false,false,false,false,false);
            Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(null,null,'Any',1,10,'Name','Initial',false,false,false,false,false);
            Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(null,'Any',null,1,10,'Name','Initial',false,false,false,false,false);
            //Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(dealsupport.Partner_Account__c,'Any','Any',1,10,'Name','Initial',false,false,true,false);
            //Partner_DealSupport.DealSupportListWrapper.getDealSupportDataController(dealsupport.Partner_Account__c,dealsupport.Status__c,dealsupport.Type__c,1,10,'Name','Initial',true,true,true,false);
            Test.stopTest();
        }        
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testgetDealSupportRecordList()
    {        
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();
         
         Test.startTest();
         Partner_DealSupport.DealSupportWrapper pw = Partner_DealSupport.getDealSupportRecordList(dealsupport.Id);
         Test.stopTest();
        }        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testinsertDealSupportNew(){ 
       PartnerRecordsUtil.createAvayaPartnerAccount();
       Account acc=PartnerRecordsUtil.partnerAccount;
       Contact con=PartnerRecordsUtil.partnerContact;      
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Partner_DealSupport.insertDealSupportNew('test ds','testing');
        }
    }    
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod5(){
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;      
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Test.startTest();
            Partner_DealSupport.getDataForViewAll('Any','Any',1,50,'Name','Initial',false,false,false,false,false);
            Partner_DealSupport.getDataForViewAll(null,null,1,50,'Name','Initial',false,false,false,false,false);
            Partner_DealSupport.getDataForViewAll(null,null,1,50,'Name','Initial',false,false,true,false,false);
            Test.stopTest();
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod6(){
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc1=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        Opportunity opp = PartnerRecordsUtil.createAvayaOpportunity();
        Deal_Support__c dealsupport=new Deal_Support__c();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Account acc= new Account();
            acc.Name='test';
            acc.Permitted_Brands__c = 'RingCentral';
            insert acc;
            dealsupport.Partner_Account__c= acc.Id;
            dealsupport.Name='Initial Order - Ab-soft';
            dealsupport.Type__c='Initial Order';
            dealsupport.Status__c='New';
            dealsupport.Discount__c=30;
            dealsupport.Opportunity__c=opp.Id;        
            Test.startTest();      
            Database.SaveResult sr= Database.Insert(dealsupport,true); 
            Partner_UpdateDSOwner.changeownerpartnerqueue(dealsupport.Id,'RingCentral');
            Partner_UpdateDSOwner.changeownerdealdesk(dealsupport.Id,'RingCentral');
            Partner_UpdateDSOwner.changeownerpartnerqueue(dealsupport.Id,'');
            Partner_UpdateDSOwner.changeownerdealdesk(dealsupport.Id,'');             
            Test.stopTest();            
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethod7(){     
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();      
            Test.startTest();      
            Partner_UpdateDSOwner.changeownerpartnerqueue(dealsupport.Id,'Avaya Cloud Office');
            Partner_UpdateDSOwner.changeownerdealdesk(dealsupport.Id,'Avaya Cloud Office');
            Partner_UpdateDSOwner.changeownerpartnerqueue(dealsupport.Id,'');
            Partner_UpdateDSOwner.changeownerdealdesk(dealsupport.Id,'');             
            Test.stopTest();  
        }
    }   
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testmethod8()
    {        
       PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();
         
         Test.startTest();
         Boolean pw = Partner_DealSupport.getShowAssignToRCButton(dealsupport.Id);
         Deal_Support__c pw2 = Partner_DealSupport.updateDSOwnerQueue(dealsupport.Id);
         Test.stopTest();
        }        
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testmethod9()
    {        
        PartnerRecordsUtil.createAvayaPartnerAccount();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        System.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {Deal_Support__c dealsupport = PartnerRecordsUtil.createDealSupport();
         
         Test.startTest();
         UserRecordAccess access=Partner_DealSupport.getUserRecordAccess(dealsupport.id);
         Partner_DealSupport.getFilesForLightning(dealsupport.id);
         Test.stopTest();
        }
    }   
}