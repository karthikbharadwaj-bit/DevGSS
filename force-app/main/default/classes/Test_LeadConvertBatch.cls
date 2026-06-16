@isTest
public class Test_LeadConvertBatch {
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
    static void testMethod1(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        User runAsSysAdmin = [Select id from user where username = 'Testttest21@test.com' limit 1];
        Test.startTest();
        system.runAs(runAsSysAdmin){
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;
            Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();        
            
            Lead leadTmpObj=new Lead(
                LastName='TestLast',
                FirstName='TestFirst',
                Company='Test',
                email='test@lister.com',
                Partner_Account__c = System.Label.Avaya_Partner_Account_Id,
                Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id,
                Deal_Registration__c = dealObj.Id,
                Avaya_Partnership_Lead__c = true,
                Status = '1. New',
                OwnerId = UserInfo.getUserId(),
                Lead_Brand_Name__c='Avaya Cloud Office',
                Number_of_Users__c = 30,
                Country = 'United States',
                NumberOfEmployees__c='20-99',
                Lead_Tier_Name__c='Office',
                Systems_Process_Stage__c = 'Route complete');
            Database.insert(leadTmpObj); 
            
        }
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            LeadConvertBatchScheduler sch = new LeadConvertBatchScheduler();
            String jobID1 = system.schedule('Avaya Convert Lead 1 - Do not stop'+system.now(), '0 0 * * * ?', sch);
        }
        Test.stopTest(); 
    }
}