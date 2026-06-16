@isTest
public class Quote_PartnerQuoteEngageLegalTest {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_one() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        opp.Brand_Name__c = 'Avaya Cloud Office';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        
        
        quoteList[0].opportunity__c = opp.Id;
        update quoteList;
        
        Quote_PartnerQuoteEngageLegalController.createDealSupport(quoteList[0].Id);
        //Quote_PartnerQuoteEngageLegalController.createDealSupport(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.dealSupportExists(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.dealSupportExistsInternal(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.dealSupportExistsUpdate(quoteList[0].Id,'test legal comments');
        //List<Deal_Support__c> dealSupportExist = [Select Id,Type__c FROM Deal_Support__c];
        
        
        Deal_Support__c objDeal = new Deal_Support__c();
        objDeal.Type__c = 'Initial Order';
        objDeal.Partner_Quote__c = quoteList[0].Id;
        objDeal.status__c='Closed-Approved';
        //objDeal.OwnerId = testQueue.Id;
        insert objDeal;
        
        Quote_PartnerQuoteEngageLegalController.updateDealSupportData(quoteList[0].Id,true,true);
        Quote_PartnerQuoteEngageLegalController.updateDealSupportData(quoteList[0].Id,false,false);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_two() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        opp.Brand_Name__c = 'Avaya Cloud Office';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        
        
        quoteList[0].opportunity__c = opp.Id;
        update quoteList;
        
        Deal_Support__c objDeal = new Deal_Support__c();
        objDeal.Type__c = 'Initial Order';
        objDeal.Partner_Quote__c = quoteList[0].Id;
        objDeal.Status__c='Closed-Approved';
        //objDeal.OwnerId = testQueue.Id;
        insert objDeal;
        
        Quote_PartnerQuoteEngageLegalController.getPartnerContractTypes(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper> objWrapperList = Quote_PartnerQuoteEngageLegalController.getCustomMetaData(quoteList[0].Id);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_three() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        opp.Brand_Name__c = 'Avaya Cloud Office';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        
        
        quoteList[0].opportunity__c = opp.Id;
        update quoteList;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;   
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = quoteList[0].id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        List<Id> filesIdSet = new List<Id>();
        filesIdSet.add(documents[0].id);
        Quote_PartnerQuoteEngageLegalController.getAllFilesOnsObjectRecord(quoteList[0].id);
        Quote_PartnerQuoteEngageLegalController.deleteFiles(JSON.serialize(filesIdSet));
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_four() {
        
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        Id RecordTypeIdopp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('VAR Opportunity').getRecordTypeId();
                
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = RecordTypeIdopp;
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        opp.Brand_Name__c = 'Avaya Cloud Office';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        
        
        quoteList[0].opportunity__c = opp.Id;
        update quoteList;
       
        Partner_Contract__c objPartnerContract = new Partner_Contract__c();
        objPartnerContract.Partner_Quote__c = quoteList[0].Id;
        insert objPartnerContract;
        
        Partner_Contract_Detail__c objContractDetail = new Partner_Contract_Detail__c();
        objContractDetail.Partner_Contract__c = objPartnerContract.Id;
        objContractDetail.Term__c = 'Free Services (Credit) 1 month';
        objContractDetail.Number_Input_Value__c = 1;
        insert objContractDetail;
        
        
        Partner_Contract_Service__c objContractService = new Partner_Contract_Service__c();
        objContractService.Partner_Contract_Detail__c = objContractDetail.Id;
        insert objContractService;

        List<Quote_PartnerQuoteEngageLegalController.PartnerContractTypeWrapper> objContractTypeList= Quote_PartnerQuoteEngageLegalController.getPartnerContractTypes(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c ='Elasticity Clause for Office Services';
        update objContractDetail;
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c = 'Business Downturn Elasticity';
        update objContractDetail;
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c = 'Feature Addition';
        update objContractDetail;
         Deal_Support__c objDeal = new Deal_Support__c();
        objDeal.Type__c = 'Initial Order';
        objDeal.Partner_Quote__c = quoteList[0].Id;
        objDeal.Status__c='Closed-Approved';
        //objDeal.OwnerId = testQueue.Id;
        insert objDeal;
        
        Test.startTest();
        Triggers.switchOff();
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper> objWrapperList = Quote_PartnerQuoteEngageLegalController.getCustomMetaData(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper objPartnerContract1 = new Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper(true,true,true,'term',
                                                                                                                                                                null,null,null,true,true,'test','test',objDeal);
        Quote_PartnerQuoteEngageLegalController.ContractUserInputWrapper objContactWrap = new Quote_PartnerQuoteEngageLegalController.ContractUserInputWrapper();
        objContactWrap.freeCredit = 2.2;
        objContactWrap.digitalLines = 2.3;
        objContactWrap.elasticityPercent = 22.1;
        objContactWrap.elasticityDigitalLines = 2.9;
        objContactWrap.featureAdditionEdition = 'Edition';
        objContactWrap.featureAdditions = 'test';
        objContactWrap.priceProtectionPercent = 1.1;
        /*objPartnerContract1.isSelected = true;
objPartnerContract1.isGridInputNeeded = true;
objPartnerContract1.isNumberInputNeeded = true;
objPartnerContract1.term = 'test';*/
        Quote_PartnerQuoteEngageLegalController.createPartnerContractRecords(JSON.serialize(new List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper>{objPartnerContract1}),JSON.serialize(objContractTypeList),quoteList[0].Id,true,objPartnerContract.Id,
                                                                             new List<Partner_Contract_Service__c>{objContractService},'Non-Standard','test','test','test',null,null,null,JSON.serialize(objContactWrap),'testing legal com');

        Approval__c objApp = new Approval__c();
        objApp.Standard_Terms__c = false;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;   
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = quoteList[0].id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        List<Id> filesIdSet = new List<Id>();
        filesIdSet.add(documents[0].id);
        Triggers.switchOn();
        Quote_PartnerQuoteEngageLegalController.ResponseWrapper record = Quote_PartnerQuoteEngageLegalController.createPartnerContractRecords(JSON.serialize(new List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper>{objPartnerContract1}),JSON.serialize(objContractTypeList),quoteList[0].Id,true,null,
                                                                           new List<Partner_Contract_Service__c>{objContractService},'Non-Standard','test','test','test',objApp,filesIdSet,'three',JSON.serialize(objContactWrap),'testing legal com');
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_five() {
        Group testGroup = new Group(Name='Avaya Queue', Type='Queue');
        insert testGroup;
        
        System.RunAs(new User(Id=UserInfo.getUserId())){  
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Deal_Support__c');
        	insert testQueue;
            
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;
            
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            opp.Brand_Name__c = 'Avaya Cloud Office';
            insert opp;
            
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            
            
            quoteList[0].opportunity__c = opp.Id;
            update quoteList;
            
            Quote_PartnerQuoteEngageLegalController.createDealSupport(quoteList[0].Id);
            Quote_PartnerQuoteEngageLegalController.createDealSupport(quoteList[0].Id);
            Quote_PartnerQuoteEngageLegalController.dealSupportExists(quoteList[0].Id);
            Quote_PartnerQuoteEngageLegalController.dealSupportExistsInternal(quoteList[0].Id);
            Quote_PartnerQuoteEngageLegalController.dealSupportExistsUpdate(quoteList[0].Id,'test legal comments');
            //List<Deal_Support__c> dealSupportExist = [Select Id,Type__c FROM Deal_Support__c];
            
            Deal_Support__c objDeal = new Deal_Support__c();
            objDeal.Type__c = 'New Contract Request';
            objDeal.OwnerId = testGroup.Id;
            insert objDeal;
            
            Quote_PartnerQuoteEngageLegalController.updateDealSupportData(quoteList[0].Id,true,true);
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_six() {        
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;       
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        
        Partner_Contract__c objPartnerContract = new Partner_Contract__c();
        objPartnerContract.Partner_Quote__c = quoteList[0].Id;
        insert objPartnerContract;
        Quote_PartnerQuoteEngageLegalController.submitForApproval(objPartnerContract.Id);
        Quote_PartnerQuoteEngageLegalController.recallApprovalController(objPartnerContract.Id);
        Partner_Contract_Detail__c objContractDetail = new Partner_Contract_Detail__c();
        objContractDetail.Partner_Contract__c = objPartnerContract.Id;
        objContractDetail.Term__c = 'Free Services (Credit) 1 month';
        objContractDetail.Number_Input_Value__c = 1;
        insert objContractDetail;
        
        
        Partner_Contract_Service__c objContractService = new Partner_Contract_Service__c();
        objContractService.Partner_Contract_Detail__c = objContractDetail.Id;
        insert objContractService;
        
        List<Quote_PartnerQuoteEngageLegalController.PartnerContractTypeWrapper> objContractTypeList= Quote_PartnerQuoteEngageLegalController.getPartnerContractTypes(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c ='Elasticity Clause for Office Services';
        update objContractDetail;
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c = 'Business Downturn Elasticity';
        update objContractDetail;
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        objContractDetail.Term__c = 'Feature Addition';
        update objContractDetail;
        
        Deal_Support__c objDeal = new Deal_Support__c();
        objDeal.Type__c = 'Initial Order';
        objDeal.Partner_Quote__c = quoteList[0].Id;
        objDeal.status__c='Closed-Approved';
        //objDeal.OwnerId = testQueue.Id;
        insert objDeal;
        Test.startTest();
        Quote_PartnerQuoteEngageLegalController.getPartnerContractDetails(quoteList[0].Id);
        List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper> objWrapperList = Quote_PartnerQuoteEngageLegalController.getCustomMetaData(quoteList[0].Id);
        Quote_PartnerQuoteEngageLegalController.partnerContractMappingsWrapper objContMapp = new Quote_PartnerQuoteEngageLegalController.partnerContractMappingsWrapper('test','test',true,'test');
        Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper objPartnerContract1 = new Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper(true,true,true,'term',null,
                                                                                                                                                                new List<Quote_PartnerQuoteEngageLegalController.partnerContractMappingsWrapper>{objContMapp},null,true,true,'test','test',objDeal);
        Quote_PartnerQuoteEngageLegalController.ContractUserInputWrapper objContactWrap = new Quote_PartnerQuoteEngageLegalController.ContractUserInputWrapper();
        objContactWrap.freeCredit = 2.2;
        objContactWrap.digitalLines = 2.3;
        objContactWrap.elasticityPercent = 22.1;
        objContactWrap.elasticityDigitalLines = 2.9;
        objContactWrap.featureAdditionEdition = 'Edition';
        objContactWrap.featureAdditions = 'test';
        objContactWrap.priceProtectionPercent = 1.1;

        Quote_PartnerQuoteEngageLegalController.ResponseWrapper record = Quote_PartnerQuoteEngageLegalController.createPartnerContractRecords(JSON.serialize(new List<Quote_PartnerQuoteEngageLegalController.PartnerContractWrapper>{objPartnerContract1}),JSON.serialize(objContractTypeList),quoteList[0].Id,true,null,                                                                            new List<Partner_Contract_Service__c>{objContractService},'Non-Standard','test','test','test',null,null,null,JSON.serialize(objContactWrap),'testing legal com');
        Test.stopTest();
    }
}