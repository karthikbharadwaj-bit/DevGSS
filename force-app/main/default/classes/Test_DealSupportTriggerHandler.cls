/*
        * Created By    : Ishwarya
        * Created Date  : 26-02-2020
        * Description   : Test class for DealSupportTriggerHandler

Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_DealSupportTriggerHandler {
    public static List<Deal_Support__c> listDealSupp{get;set;}
    @isTest
    public static void createDealSupportRecord(){
        Account acc=new Account(Name='Test Acc');
        Deal_Support__c dealsupport=new Deal_Support__c();
        Deal_Support_Comments__c dscom=new Deal_Support_Comments__c();
        ContentDocumentLink contentLink=new ContentDocumentLink();
        PartnerRecordsUtil objutil=new PartnerRecordsUtil();
        dealsupport.Partner_Account__c=PartnerRecordsUtil.partnerAccount.Id;
        dealsupport.Partner_Contact__c=PartnerRecordsUtil.partnerContact.Id;
        dealsupport.Name='New Contract Request - Ab-soft';
        dealsupport.Type__c='New Contract Request';
        dealsupport.Status__c='Ready for Signature';
        dealsupport.Discount__c=30;
        Opportunity opp=PartnerRecordsUtil.createAvayaOpportunity();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            insert acc;

            Triggers.switchOff();
            List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => acc.Id,
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{AccountHelper.SERVICE_TYPE_OFFICE, AccountHelper.SERVICE_TYPE_RCCC}),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'11111111111', '2222222222'})
            })
            .quantity(2)
            .create()
            .getRecords();
            Triggers.switchOn();

            opp.AccountId=acc.Id;
            update opp;

            Contract contractobj=new Contract(Name='Test contract',
                                              accountid=acc.Id);
            insert contractobj;
            dealsupport.Customer_Account__c=opp.AccountId;
            dealsupport.Opportunity__c=opp.Id;

            Database.SaveResult sr= Database.Insert(dealsupport,true);
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
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            cdl.Visibility='AllUsers';

            Test.startTest();
            try{
                cdl.LinkedEntityId =dealsupport.Id;
                insert cdl;

                dealsupport.Name='New Contract Request - Test Acc';
                dealsupport.Status__c='Signature Complete';
                update dealsupport;

                contentLink.ContentDocumentId = documents[0].Id;
                contentLink.LinkedEntityId =contractobj.Id;
                insert contentLink;
            }
            catch(Exception ex){
                system.debug('error>>' +ex);
            }
            Test.stopTest();

            System.assertEquals(documents.size(), 1);
            System.assertEquals(cdl.LinkedEntityId, dealsupport.Id);
            System.assertEquals(contentLink.LinkedEntityId, contractobj.Id);
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test01(){
        listDealSupp = new List<Deal_Support__c>();

        Account partner = new Account();
        partner.Name = 'Test Partner 01';
        partner.Type = 'Partner';
        partner.Partner_Country__c = 'Canada';
        insert partner;

        Account customer = new Account();
        customer.Name = 'Test Customer 01';
        customer.Type = 'Customer';
        customer.CurrencyIsoCode = 'GBP';
        //customer.Partner_Country__c = 'United Kingdom';
        insert customer;

        Account customer2 = new Account();
        customer2.Name = 'Test Customer 01';
        customer2.Type = 'Customer';
        customer2.CurrencyIsoCode = 'AUD';
        customer2.Partner_Country__c = 'Australia';
        insert customer2;

        Lead ld = new Lead();
        ld.LastName = 'Test Lead';
        ld.Country__c = 'Canada';
        ld.Email = 'fake@email.com';
        ld.Company = 'Test 01';
        insert ld;

        Lead ld1 = new Lead();
        ld1.LastName = 'Test Lead2';
        ld1.Email = 'fake@email.com';
        ld1.Company = 'Test 01';
        ld1.CurrencyIsoCode = 'GBP';
        insert ld1;

        Deal_Support__c ds1 = new Deal_Support__c();
        ds1.Type__c = 'Initial Order';
        ds1.Partner_Account__c = partner.Id;
        listDealSupp.add(ds1);

        Deal_Support__c ds2 = new Deal_Support__c();
        ds2.Type__c = 'Initial Order';
        ds2.Customer_Account__c = customer2.Id;
        listDealSupp.add(ds2);

        Deal_Support__c ds3 = new Deal_Support__c();
        ds3.Type__c = 'Initial Order';
        ds3.Customer_Account__c = customer.Id;
        listDealSupp.add(ds3);

        Deal_Support__c ds4 = new Deal_Support__c();
        ds4.Type__c = 'Initial Order';
        ds4.Lead__c = ld.Id;
        listDealSupp.add(ds4);

        Deal_Support__c ds5 = new Deal_Support__c();
        ds5.Type__c = 'Initial Order';
        ds5.Lead__c = ld1.Id;
        listDealSupp.add(ds5);

        Test.startTest();
        	insert listDealSupp;
        Test.stopTest();
    }

    @IsTest
    static void testPopulateDealSupportFieldsWithPackageFields() {
        Triggers.switchOff();
        Triggers.except('DealSupportTriggerHandler.PopulateDealSupportFieldsWithPackageFields');

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc1',
                Account.RC_Account_Status__c => 'POC'
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.RC_Signup_Type__c => 'Try Now',
                Package__c.Service_Type__c => 'Office',
                Package__c.RC_Signup_Funnel__c => 's-office-web-rc-self-us',
                Package__c.RC_Tier_ID__c => '1234567'
            })
            .create()
            .getRecord();    
            
        Test.startTest();
            Deal_Support__c testDealSupport = (Deal_Support__c) new SObjectBuilder(Deal_Support__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Deal_Support__c.Name => 'Test Deal Support',
                Deal_Support__c.Customer_Account__c => testAcc.Id           
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Deal_Support__c resultDealSupport = (Deal_Support__c) new DealSupportSelector()
            .selectDealSupports()
            .setCondition('Id IN :bind0')
            .selectFields(new List<String>{'User_ID__c'})
            .setQueryBindings(new List<Object>{ new Set<Id>{ testDealSupport.Id } })
            .executeQuery()
            .get(0);

        Assert.areEqual(resultDealSupport.User_ID__c, testPackage.RC_Tier_ID__c, 'User ID should be populated with Tier ID');
    }
}