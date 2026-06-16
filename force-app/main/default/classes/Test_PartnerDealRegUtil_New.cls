/*       
* Created By    : 
* Created Date  : 26-02-2020
* Description   : Test class for PartnerDealRegistrationUtil class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
/*       
* Created By    : 
* Created Date  : 26-02-2020
* Description   : Test class for PartnerDealRegistrationUtil class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerDealRegUtil_New {
     @testsetup
     static void createTestData(){
         Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            User userSysAdmin = new User(
                ProfileId = profile1.Id,
                Username = 'Testttest21@test.com',
                Alias = 'batndfw',
                Email='bruce.wayne@wayneenterprises2f234.com',
                EmailEncodingKey='UTF-8',
                Firstname='Bruce',
                Lastname='Wayne',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago',
                Country__c='United States'
            );
        Database.insert(userSysAdmin);

    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod2(){
        String AVAYA_PARTNER_ACCOUNT_ID =System.Label.Avaya_Partner_Account_Id;
        PartnerDealRegistrationUtil utilp = new PartnerDealRegistrationUtil();
        PartnerRecordsUtil util = new PartnerRecordsUtil();        
        User runAsSysAdmin = [Select id from user where username = 'Testttest21@test.com' limit 1];
        system.runAs(runAsSysAdmin){
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true, Bypass_Account_Trigger__c = true);
            insert bpt;
            Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();            
            List<Deal_Registration__c> lstDeal = new List<Deal_Registration__c>();
            lstDeal.add(dealObj);       
            Test.startTest(); 
            List<Lead> leadLst = PartnerDealRegistrationUtil.AddDealAsLead(lstDeal);
            if(leadLst.size() > 0){
                PartnerDealRegistrationUtil.PartnerLeadConvertResult plcr = PartnerDealRegistrationUtil.convertPartnerLead(leadLst.get(0),false);
            }
        }
        Test.stopTest();
        
    }  

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetCurrentUserPartnerAccount(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            String test = PartnerDealRegistrationUtil.getCurrentUserPartnerAccount();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetCurrentUserPartnerContactAccess(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            String test = PartnerDealRegistrationUtil.getCurrentUserPartnerContactAccess();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetCurrentUserPartnerContact(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            List<Contact> test = PartnerDealRegistrationUtil.getCurrentUserPartnerContact();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetCurrentUserPartnerContactforSysAdmin(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Contact> test = PartnerDealRegistrationUtil.getCurrentUserPartnerContact();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetSelectedPartnerId(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            String test = PartnerDealRegistrationUtil.getSelectedPartnerId();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testgetSelectedPartnerId1(){
        Test.startTest();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            String test = PartnerDealRegistrationUtil.getSelectedPartnerId();
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethodpopulateOppRecordType(){
        PartnerDealRegistrationUtil.populateOppRecordType('Partner_Leads');
        PartnerDealRegistrationUtil.populateOppRecordType('Sales_Leads');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethodsetCampaignInfluence(){
        PartnerRecordsUtil util=new PartnerRecordsUtil();
        User runAsSysAdmin = [Select id from user where username = 'Testttest21@test.com' limit 1];
        Test.startTest();
        Deal_Registration__c dealObj = new Deal_Registration__c();
        system.runAs(runAsSysAdmin){
        ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
        insert bpt;
        dealObj = PartnerRecordsUtil.createAvayaDeal();
        dealObj.Phone_Number__c = '123456789';
        update dealObj;
        }
        Lead leadObj=PartnerRecordsUtil.createAvayaLead(dealObj);
        Opportunity oppObj=PartnerRecordsUtil.createAvayaOpportunity();
        PartnerDealRegistrationUtil.setCampaignInfluence(leadObj,oppObj);
        
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmapOpportunityContactRole() {
        
        String AVAYA_PARTNER_ACCOUNT_ID =System.Label.Avaya_Partner_Account_Id;
        PartnerDealRegistrationUtil utilp = new PartnerDealRegistrationUtil();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
            User runAsSysAdmin = [Select id from user where username = 'Testttest21@test.com' limit 1];
            system.runAs(runAsSysAdmin){
             ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true, Bypass_Account_Trigger__c = true, Bypass_Contact_Trigger__c = true);
                insert bpt;
            Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();             
                     
            List<Deal_Registration__c> lstDeal = new List<Deal_Registration__c>();
            lstDeal.add(dealObj); 
            Test.startTest();  
            List<Lead> leadLst = PartnerDealRegistrationUtil.AddDealAsLead(lstDeal);
            leadlst[0].Agent_Email_Address__c='testagent@mail.com';
            Id partnerOwnerId = UserInfo.getUserId();
             
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(leadlst[0].id);
            lc.setOwnerId(partnerOwnerId);
            lc.setConvertedStatus('2. Contacted');
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            PartnerDealRegistrationUtil.updateExOpportunityContactRole(lcr);
            Lead_Qualification__c leadQualObj = new Lead_Qualification__c();
            leadQualObj.Decision_Maker_Partner__c = 'Details Below';
            leadQualObj.Decision_Maker_First_Name__c = 'Test';
            leadQualObj.Decision_Maker_Last_Name__c = 'Test';
            leadQualObj.Decision_Maker_Email__c = 'test@test.com';
            leadQualObj.Decision_Maker_Phone__c = '123456789';
            leadQualObj.Decision_Maker_Business_Title__c = 'test';
            insert leadQualObj;
            if(leadLst.size() > 0){
                PartnerDealRegistrationUtil.mapOpportunityContactRole(lcr,leadQualObj, leadLst.get(0));
                leadQualObj.Decision_Maker_Partner__c = 'Same as Contact';
                PartnerDealRegistrationUtil.mapOpportunityContactRole(lcr,leadQualObj, leadLst.get(0));
                Test.stopTest();
            }
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testPerformDuplicateCheck() {
        PartnerRecordsUtil util = new PartnerRecordsUtil();
         User runAsSysAdmin = [Select id from user where username = 'Testttest21@test.com' limit 1];
        Test.startTest(); 
        system.runAs(runAsSysAdmin){
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);    
            insert bpt;
            Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();
            dealObj.Phone_Number__c = '123456789';
            update dealObj;
            Set<Id> dealIds = new Set<Id>();
            dealIds.add(dealObj.Id);
            PartnerDealRegistrationUtil.performDuplicateCheck(dealIds);
        }
        Test.stopTest();
    }
}