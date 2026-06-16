/*       
        * Created By    : 
        * Created Date  : 27-02-2020
        * Description   : Test class for PartnerDetailsController class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
/*       
* Created By    : 
* Created Date  : 27-02-2020
* Description   : Test class for PartnerDetailsController class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerDetailsController {
    
  
    @isTest static void testMethod2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
        Test.startTest();
        PartnerDetailsController.PartnerRequestListWrapper prlw = PartnerDetailsController.loadPartnerRegistrations(1,1);
        System.assertEquals(1, prlw.pageSize_pr);
        Test.stopTest();
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod3(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
        Test.startTest();
        String accountID=PartnerRecordsUtil.partnerAccount.id;
        PartnerDetailsController.ContactListWrapper contactsLst= PartnerDetailsController.loadListContact(accountID);
        PartnerDetailsController.loadAccount(accountID);
        //System.assertEquals(accountID, contactsLst[0].accountid);
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testMethod4(){        
        // setupData();
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){        
            Test.startTest();
            PartnerDetailsController.PartnerWrapper pw = PartnerDetailsController.loadPartnersAndUsers('c','Name',1,1);
            System.assertEquals(1, pw.pageSize);
            Test.stopTest();
        }
    }
    @isTest static void testMethod5(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaMasterRole){
            PartnerDetailsController.UserWrapper uw = PartnerDetailsController.checkUserRole();
            System.assertEquals(true, uw.isMasterAgent);
        }
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            PartnerDetailsController.UserWrapper uw = PartnerDetailsController.checkUserRole();
            System.assertEquals(false, uw.isMasterAgent);
        }
        Test.stopTest();
    }
    
    @isTest static void testMethod6(){
        
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
        Contact contactObj = new Contact();
        contactObj.FirstName = 'Test Contact';
        contactObj.LastName = 'Test Contact';
        contactObj.accountid =PartnerRecordsUtil.partnerAccount.id;
        contactObj.Email = '';
        contactObj.Phone = '';
        contactObj.RC_Customer_Role__c = '';
        contactObj.Target_Account_Primary_Member__c = false;
        
        Deal_Support__c dealSupp = new Deal_Support__c();
        dealSupp.Partner_Account__c = contactObj.AccountId;
        dealSupp.Partner_Contact__c = contactObj.Id;
        dealSupp.Type__c = 'New Contact Request';
        dealSupp.Name ='New Contact Request - ' +contactObj.FirstName +' ' +contactObj.LastName; 
        dealSupp.Brand_Name__c = contactObj.Account_Brand__c;
        
        Test.startTest();
        Map<String, String> mapContact = PartnerDetailsController.createContactRecord(contactObj); 
  
        System.assertEquals('error', mapContact.get('status'));
        Test.stopTest();
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest static void testMethod7(){
        List<Contact> conList = new List<Contact>();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        String accountID=PartnerRecordsUtil.partnerAccount.id;
		Contact contact = PartnerRecordsUtil.partnerContact;
        Map<String,String> getCountryCurrency=new Map<String,String>();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            String userContact = PartnerDetailsController.createUserForContact(contact, accountID, conList, ''); 
            CountryCurrencyCode.getCountryCurrencyMap();
        }  
        //System.assertEquals('error', userContact.get('status'));
        
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
   @isTest static void testMethod8(){
    List<Contact> conList = new List<Contact>();
    PartnerRecordsUtil util = new PartnerRecordsUtil();
    String accountID=PartnerRecordsUtil.partnerAccount.id;
    Contact contact = PartnerRecordsUtil.partnerContact;
    Map<String,String> getCountryCurrency=new Map<String,String>();
    Test.startTest();
    system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
        String userContact = PartnerDetailsController.createUserForContact(contact, accountID, conList, ''); 
        CountryCurrencyCode.getCountryCurrencyMap();
    }  
    //System.assertEquals('error', userContact.get('status'));
    
    Test.stopTest();
}
@isTest static void testMethod9(){
    
    Test.startTest();
    List<String> businessPicklist = PartnerDetailsController.getBusinessPicklistvalues('Partner_Request__c', 'BusinessIdentity__c', true); 
    List<String> businessPicklist1 = PartnerDetailsController.getBusinessPicklistvalues('Partner_Request__c', 'BusinessIdentity__c', false); 

    System.assert(businessPicklist != null);
    Test.stopTest();
    
}
@isTest static void testMethod10(){
    
    Test.startTest();
    PartnerDetailsController.PickListWrapperForCountry picklistWrapper = PartnerDetailsController.getBusinessCountryStateMap();
    System.assert(picklistWrapper != null);
    Test.stopTest();    
}
@isTest static void testMethod11(){
    PartnerRecordsUtil util = new PartnerRecordsUtil();
    String accountID=PartnerRecordsUtil.partnerAccount.id;
    Test.startTest();
    string str = PartnerDetailsController.getNGBSPartnerHierarchy(accountID);   
    System.assert(str != null);
    Test.stopTest();    
}
@isTest static void testMethod12(){
    PartnerRecordsUtil util = new PartnerRecordsUtil();
    Test.startTest();
    CommunityInfo.Translationswrap data = PartnerDetailsController.getTranslations('account');   
    System.assert(data != null);
    Test.stopTest();    
}
        static void setupData() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Account> accList = [SELECT Id FROM Account Limit 1];        
            List<Contact> conList = [SELECT Id FROM Contact];        
            PortalAccessTestUtil portalAccessUtil = new PortalAccessTestUtil(accList.get(0),conList);
        }        
    }
}
/*@isTest
public class Test_PartnerDetailsController {

    
    @isTest static void testMethod2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
       	PartnerDetailsController.PartnerRequestListWrapper prlw = PartnerDetailsController.loadPartnerRegistrations(1,1);
        System.assertEquals(1, prlw.pageSize_pr);
        Test.stopTest();
    }
    
    @isTest static void testMethod3(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        String accountID=PartnerRecordsUtil.partnerAccount.id;
        Test.startTest();
       	PartnerDetailsController.ContactListWrapper contactsLst= PartnerDetailsController.loadListContact(accountID);
        PartnerDetailsController.loadAccount(accountID);
        //System.assertEquals(accountID, contactsLst[0].accountid);
        Test.stopTest();
    }
    
    @isTest static void testMethod4(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        PartnerDetailsController.PartnerWrapper pw = PartnerDetailsController.loadPartnersAndUsers('a','Name',1,1);
        System.assertEquals(1, pw.pageSize);
        Test.stopTest();
    }
    
    @isTest static void testMethod5(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaMasterRole){
            PartnerDetailsController.UserWrapper uw = PartnerDetailsController.checkUserRole();
            System.assertEquals(true, uw.isMasterAgent);
        }
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            PartnerDetailsController.UserWrapper uw = PartnerDetailsController.checkUserRole();
            System.assertEquals(false, uw.isMasterAgent);
        }
        Test.stopTest();
    }
    
      @isTest static void testMethod6(){
         PartnerRecordsUtil util = new PartnerRecordsUtil();
         Contact contactObj = new Contact();
         contactObj.FirstName = 'Test Contact';
         contactObj.LastName = 'Test Contact';
         contactObj.accountid =PartnerRecordsUtil.partnerAccount.id;
         contactObj.Email = '';
         contactObj.Phone = '';
         contactObj.RC_Customer_Role__c = '';
         contactObj.Target_Account_Primary_Member__c = false;
         Test.startTest();
         Map<String, String> mapContact = PartnerDetailsController.createContactRecord(contactObj); 
         System.assertEquals('error', mapContact.get('status'));
         
         Test.stopTest();
    }
}*/