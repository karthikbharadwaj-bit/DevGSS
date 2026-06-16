/*       
        * Created By    : 
        * Created Date  : 23-02-2020
        * Description   : Test class for Partner_OpportunitiesMain class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_Partner_OpportunitiesMain {
    
    @TestSetup
    static void makeData(){
        PartnerRecordsUtil.createAvayaPartnerAccount();
    }

    @isTest static void testMethod2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppTmpObj = PartnerRecordsUtil.createAvayaOpportunity();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaMasterRole){
        Partner_OpportunitiesMain.AccountListWrapper accountList = Partner_OpportunitiesMain.getAccountList();
        System.assertEquals(true,accountList.isMaster);
        }
        Test.stopTest();
    }
    
    /* @isTest static void testMethod3(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        Partner_OpportunitiesMain.OppListWrapper oppList = Partner_OpportunitiesMain.getOppDataController(System.Label.Avaya_Partner_Account_Id,1,1,'Name','a','USD');
        System.assertEquals(1, oppList.pageSize);
        oppList = Partner_OpportunitiesMain.getDataForViewAll(1,1,'Name','a','USD');
        System.assertEquals(1, oppList.pageSize);
        Test.stopTest();
    }*/
    
    @isTest static void testMethod4(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppTmpObj = PartnerRecordsUtil.createAvayaOpportunity();
        Test.startTest();
        String quoteId=Partner_OpportunitiesMain.getPartnerQuote(oppTmpObj.Id);
        System.assertNotEquals(null, quoteId);
        Test.stopTest();
    }
    
    @isTest static void testMethod5(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppTmpObj = PartnerRecordsUtil.createAvayaOpportunity();
        Test.startTest();
        Partner_OpportunitiesMain.OppWrapper oppList = Partner_OpportunitiesMain.getOppRecordList(oppTmpObj.Id);
		System.assertEquals(true, oppList.oppty!= null);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod6(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppTmpObj = PartnerRecordsUtil.createAvayaOpportunity();
        Test.startTest();
        Partner_Quote__c partnerQuoteObj =  Partner_OpportunitiesMain.createPartnerQuoteForUpsell(oppTmpObj.Partner_Account__c);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod7(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppTmpObj = PartnerRecordsUtil.createAvayaOpportunity();
        Test.startTest();
       	String msg =  Partner_OpportunitiesMain.updateOpportunity(oppTmpObj);
        Test.stopTest();
    }
    
    @isTest static void testMethod8(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test a Opportunity';
        oppObj.StageName = '1. Qualify';
        oppObj.CloseDate = System.today()+1;
        Test.startTest();
       	Partner_OpportunitiesMain.OppResponseWrapper orw = Partner_OpportunitiesMain.createOpportunity(oppObj,PartnerRecordsUtil.partnerAccount.id,contact.Lastname);
        System.assertNotEquals(null, orw.opp);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod9(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test a Opportunity';
        oppObj.StageName = '1. Qualify';
        oppObj.CloseDate = System.today()+1;
        Test.startTest();
        //getOppDataController(String selectedPartnerAccount, Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord)
       	Partner_OpportunitiesMain.OppListWrapper olw = Partner_OpportunitiesMain.getOppDataController(PartnerRecordsUtil.partnerAccount.id,1,1,'Name', 'avaya');
        //System.assertNotEquals(null, orw.opp);
        Test.stopTest();
    }
    
    //getDataForViewAll(Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord)
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod10(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test a Opportunity';
        oppObj.StageName = '1. Qualify';
        oppObj.CloseDate = System.today()+1;
        Test.startTest();
       	Partner_OpportunitiesMain.OppListWrapper olw = Partner_OpportunitiesMain.getDataForViewAll(1,1,'Name', 'avaya');
        Quote_PartnerDetailController.AccountCheckListWrapper acctlist = Partner_OpportunitiesMain.checkPartnerQuoteExistFORAccount(PartnerRecordsUtil.partnerAccount.id);
        //Partner_OpportunitiesMain.updateAccountChecklist();
        //System.assertNotEquals(null, orw.opp);
        Test.stopTest();
    }

     @isTest
    static void testIsShowUnifiedQuotingWizard() {
        User sysAdmin = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        PermissionSet pSet = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetsByName(new Object[]{new String[]{'IgniteUQTFlow'}})
            .executeQuery()[0];

        insert new PermissionSetAssignment(AssigneeId = sysAdmin.Id, PermissionSetId = pSet.Id);

        Boolean showQW;
        System.runAs(sysAdmin) {
            Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setField(Account.IsMultiProductTechnicalAccount__c, false)
                .create()
                .getRecord();
    
            Opportunity testNewOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setField(Opportunity.AccountId, testAccount.Id)
                .setField(Opportunity.Name, 'TestOpportunity')
                .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
                .setField(Opportunity.PartnerProgram__c, 'Ignite')
                .create()
                .getRecord();
    
            Opportunity testExistingBusinessOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setField(Opportunity.AccountId, testAccount.Id)
                .setField(Opportunity.Name, 'TestOpportunity')
                .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
                .setField(Opportunity.Brand_Name__c, RingCentralHelper.BRAND_RINGCENTRAL)
                .create()
                .getRecord();
                
            showQW = Partner_OpportunitiesMain.isShowUnifiedQuotingWizard(testExistingBusinessOpportunity.Id);
        }

        System.assert(showQW, 'Quoting Wizard should be shown');
    }

    @isTest
    static void testWrappersCreated() {
        Boolean isSuccess = true;
        try {
            Partner_OpportunitiesMain.OppListWrapper oppListWrapperObj = new Partner_OpportunitiesMain.OppListWrapper();
            oppListWrapperObj.pageSize = 10;
            oppListWrapperObj.pageNumber = 1;
            oppListWrapperObj.totalRecords = 100;
            oppListWrapperObj.recordStart = 1;
            oppListWrapperObj.recordEnd = 10;
            oppListWrapperObj.oppList = new List<Opportunity>{new Opportunity(Name='Test Opportunity 1'), new Opportunity(Name='Test Opportunity 2')};

            Partner_OpportunitiesMain.OppResponseWrapper oppResponseWrapperObj = new Partner_OpportunitiesMain.OppResponseWrapper();
            oppResponseWrapperObj.responseMessage = 'Success';
            oppResponseWrapperObj.opp = new Opportunity(Name='Test Opportunity');

            Partner_OpportunitiesMain.OppWrapper oppWrapperObj = new Partner_OpportunitiesMain.OppWrapper();
            oppWrapperObj.isAvaya = true;
            oppWrapperObj.isMaster = false;
            oppWrapperObj.isReadOnly = true;
            oppWrapperObj.oppty = new Opportunity(Name='Test Opportunity');
            oppWrapperObj.isSingleLogin = false;
            oppWrapperObj.partnerCommunityName = new List<String>{'Community1', 'Community2'};
            oppWrapperObj.hasReadAccess = true;
            oppWrapperObj.isIgnite = false;
            oppWrapperObj.communityDetailsRecord = new Community_Details__mdt();
            oppWrapperObj.accCountry = 'USA';
            oppWrapperObj.salesQuote = new Quote(Name='Test Quote');
            oppWrapperObj.isProcessOrderRequestExist = true;
            oppWrapperObj.dealSupportRec = new Deal_Support__c(Name='Test Deal Support Record');

            Partner_OpportunitiesMain.AccountListWrapper accountListWrapperObj = new Partner_OpportunitiesMain.AccountListWrapper();
            accountListWrapperObj.isAvaya = false;
            accountListWrapperObj.isMaster = true;
            accountListWrapperObj.isSingleLogin = true;
            accountListWrapperObj.partnerCommunityName = new List<String>{'Community1', 'Community2'};
            accountListWrapperObj.communityDetailsRecord = new Community_Details__mdt();
            accountListWrapperObj.listUserAccountMap = new List<User_Account_Mapping__c>{new User_Account_Mapping__c(), new User_Account_Mapping__c()};
            accountListWrapperObj.listPartnerAccounts = new List<Account>{new Account(Name='Test Account 1'), new Account(Name='Test Account 2')};
        } catch(Exception e) {
            isSuccess = false;
        }

        System.assert(isSuccess, 'Wrappers should be created without exceptions');
    }

    @isTest
    static void testIsExistingBusiness(){
        Test.startTest();
        Partner_OpportunitiesMain.getDOSCaseRecordTypeId();
        Account acc = [Select id,RC_Brand__c,RC_User_ID__c,Billing_ID__c from Account where name = 'TestAccount'];
        acc.RC_User_ID__c = 'randomEnterpriseId';
        acc.Billing_ID__c = 'randomBillingId';
        update acc;
        
        Boolean isExistingBusiness = Partner_OpportunitiesMain.IsExistingBusiness(acc.Id);
        Test.stopTest();
        Assert.isTrue(isExistingBusiness);
    }
}