/*       
* Created By    : 
* Created Date  : 23-02-2020
* Description   : Test class for PartnerLeads class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerLeads {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod1() {
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

        System.runAs(sysAdmin) {
            try {
			    Lead leadObj = new Lead(LastName='Last11', Company='Company11', Phone='34556221', Email='lead@triggertest11.com', Status = 'Open - Not Contacted');
        	    insert leadObj;

                PartnerLeads.LeadRecordWrapper lrw = PartnerLeads.getLeadDetail(leadObj.Id);

                Test.startTest();
                PartnerLeads.CovertedLeadWrapper clw = PartnerLeads.convertLeadRecord(leadObj);

                Test.stopTest();
            } catch (Exception e) {
            }
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCountryState() {
	    PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            Test.startTest();

		    Lead leadObj = new Lead(LastName='Last11', Company='Company11', Phone='34556221', Email='lead@triggertest11.com', Status = 'Open - Not Contacted');
            insert leadObj;
            String msg = PartnerLeads.requestToConvertLead(leadObj.Id);

            PartnerLeads.getCountryStateMap('Avaya Cloud Office');
        
            Test.stopTest();
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void testnullCountryState(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            Test.startTest();
            PartnerLeads.getCountryStateMap('');
            Test.stopTest();
        }
    }
    @isTest static void testMethod2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        Account acc = PartnerRecordsUtil.partnerAccount;
        System.debug('Acc - '+acc);
        PartnerLeads.LeadListWrapper lw = PartnerLeads.getLeadDataController(acc.Id, 1, 1,'t','Name');
        System.assertEquals(1, lw.pageSize);
        lw = PartnerLeads.getDataForViewAll(1, 1,'t','Name');
        System.assertEquals(1, lw.pageSize);
        Test.stopTest();
    }
    @isTest static void testMethod3(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaMasterRole){
            PartnerLeads.AccountListWrapper alw = PartnerLeads.getAccountList();
            System.assertEquals(true, alw.isMaster);
        }
        Test.stopTest();
    }
    @isTest 
    static void testgetTranslations() {
        Test.startTest();
        CommunityInfo.Translationswrap translation = PartnerLeads.getTranslations('Opportunity');
        Test.stopTest();
        System.assertNotEquals(null, translation, 'Response can not be null');
    }
    @isTest static void testGetLeadDataController(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        Account acc = PartnerRecordsUtil.partnerAccount;
        User_Account_Mapping__c userAcc = new User_Account_Mapping__c();
        userAcc.Partner_Account__c = acc.Id;
        userAcc.Partner_User__c = UserInfo.getUserId();
        System.debug('Acc - '+acc);
        PartnerLeads.LeadListWrapper lw = PartnerLeads.getLeadDataController(acc.Id, 1, 1,'t','Name');
        System.assertEquals(1, lw.pageSize);
        lw = PartnerLeads.getDataForViewAll(1, 1,'t','Name');
        System.assertEquals(1, lw.pageSize);
        Test.stopTest();
    }
}