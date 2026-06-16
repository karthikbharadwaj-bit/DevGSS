@isTest
public class Test_FileShareLinkTrigger {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testFileShare01() {
        Account acc = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral');
        insert acc;

        Contact con = new Contact(LastName='Opty test contact',
                                    Preferred_Language__c='en_US',
                                    AccountId=acc.Id,
                                    Email='test@test.com',
                                    Phone='+18885550505',
                                    CurrencyIsoCode='USD');
        insert con;
        Opportunity opp = new Opportunity(Name='Test Opportunity',
                                            CurrencyIsoCode='USD',
                                            AccountId=acc.Id,
                                            StageName='4. Proof',
                                            RecordTypeId=OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                            Primary_Opportunity_Contact__c = con.Id,
                                            Tier_Name__c='Fax1000',
                                            Brand_Name__c='RingCentral',
                                            Forecasted_Users__c=23,
                                            Avaya_Partnership_Opportunity__c=true);
        insert opp;
        
        Deal_Support__c ds = new Deal_Support__c(Name='Test Deal Support',
                                                Partner_Account__c=acc.Id,
                                                Partner_Contact__c=con.Id);
        insert ds;
        
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
        cdl.LinkedEntityId = opp.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCasesFiles()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'I';
            cdl.Visibility='AllUsers';
            cdl.LinkedEntityId =caseRec.Id; 
            insert cdl;
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest static void testContractFileShare() {
        Account acc = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral',
                                    Avaya_Partnership_Account__c = true);
        insert acc;

        Contract con = new Contract(Status='Draft',AccountId=acc.Id);
        insert con;
        
        
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
        cdl.LinkedEntityId = con.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
    }
}