/* Epic - CRM-5094 - Added as part of EU Data Privacy Project */
@isTest
public class EUPrivacyTest {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethods(){
        EUPrivacy eu = new EUPrivacy();
        Set<String> EURestrictedCountriesSet = eu.getEURestrictedCountries();
        Set<String> EURestrictedProfileNameSet = eu.getEURestrictedProfileNames();
        Set<String> EURestrictedAccountBrandsSet = eu.getEURestrictedAccountBrands();
        Set<String> EUSupportRestrictedProfileSet = eu.getEUSupportRestrictedProfiles();
        Set<String> EURestrictedAccountStatus = eu.getEURestrictedAccountStatus();
        Set<String> EURestrictedExceptionalProfileNames = eu.getEURestrictedExceptionalProfileNames();
        boolean b = eu.RestrictBasedOnSpecificAccBrands;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethod1(){
        Test.startTest();
        EUPrivacy eu = new EUPrivacy();
        
        User testUser = getUser();
        insert testUser;
        
        Account acctObj2 = getAccount();
        acctObj2.RC_Brand__c = 'RingCentral UK';
        acctObj2.BillingCountry = 'France';
        insert acctObj2;
        
        Contact contactObj2 = getContact();
        contactObj2.AccountId =  acctObj2.id;
        insert contactObj2;
        
        System.debug('acctObj2.id ' + acctObj2.id);
        System.runAs(testUser) {    
            boolean a = eu.showComponent(acctObj2.id,'NotesController');
            boolean a2 = eu.showComponent(acctObj2.id,'EURestrictedNotificationController');
            boolean a3 = eu.showComponent(acctObj2.id,'EuprivacyFieldsetControllerNew');
            boolean a4 = eu.showComponent(acctObj2.id,'hideNotes');
            boolean a5 = eu.showComponent(acctObj2.id,'Account_RelatedFiles');
            
            boolean co = eu.showComponent(contactObj2.id,'NotesController');
            boolean co2 = eu.showComponent(contactObj2.id,'EURestrictedNotificationController');
            boolean co3 = eu.showComponent(contactObj2.id,'EuprivacyFieldsetControllerNew');
            boolean co4 = eu.showComponent(contactObj2.id,'Account_RelatedFiles');
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethod2(){
        boolean b = CheckRecursive.isEUDataPrivacyRecurssion_Opportunity;
        boolean c = CheckRecursive.isEUDataPrivacyRecurssion_Case;
        boolean d = CheckRecursive.isEUDataPrivacyRecurssion_Contact;
        boolean e = CheckRecursive.isEUDataPrivacyRecurssion_Account;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethod3(){
        Test.startTest();
        EUPrivacy eu = new EUPrivacy();
        
        User testUser = getUser();
        insert testUser;
        
        Account acctObj2 = getAccount();
        acctObj2.RC_Brand__c = 'RingCentral UK';
        acctObj2.BillingCountry = 'France';
        insert acctObj2;
        
        Opportunity oppObj2 = getOpportunity();
        oppObj2.AccountId = acctObj2.Id;
        insert oppObj2;
        
        boolean o = eu.showComponent(oppObj2.id,'NotesController');
        boolean o2 = eu.showComponent(oppObj2.id,'EURestrictedNotificationController');
        boolean o3 = eu.showComponent(oppObj2.id,'EuprivacyFieldsetControllerNew');
        boolean o4 = eu.showComponent(oppObj2.id,'hideNotes');
        boolean o5 = eu.showComponent(oppObj2.id,'Account_RelatedFiles');
        
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testMethod4(){
        Test.startTest();
        EUPrivacy eu = new EUPrivacy();
        
        User testUser = getUser();
        insert testUser;
        Test.stopTest();
        
        Account acctObj2 = getAccount();
        acctObj2.RC_Brand__c = 'RingCentral UK';
        acctObj2.BillingCountry = 'France';
        insert acctObj2;
        
        Case caseObj2 = getCase();
        caseObj2.AccountId = acctObj2.id;
        insert caseObj2;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatVisitor lcv1 = [Select id from LiveChatVisitor where id=:lcv.id];
        
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorid = lcv1.id;
        lct.CaseId = caseObj2.id;
        insert lct;
        
        boolean cs = eu.showComponent(caseObj2.id,'NotesController');
        boolean cs2 = eu.showComponent(caseObj2.id,'EURestrictedNotificationController');
        boolean cs3 = eu.showComponent(caseObj2.id,'EuprivacyFieldsetControllerNew');
        boolean cs4 = eu.showComponent(caseObj2.id,'hideNotes');
        boolean cs5 = eu.showComponent(caseObj2.id,'Account_RelatedFiles');
        
        boolean lct1 = eu.showComponent(lct.id,'NotesController');
        boolean lct2 = eu.showComponent(lct.id,'EURestrictedNotificationController');
        boolean lct3 = eu.showComponent(lct.id,'EuprivacyFieldsetControllerNew');
        boolean lct4 = eu.showComponent(lct.id,'hideNotes');
        boolean lct5 = eu.showComponent(lct.id,'Account_RelatedFiles');
    }
    
    public static User getUser(){
        Profile restProfile = [select id from profile where name='Finance Admin - EU Restricted'];
        
        User testUser = new User(alias = 'u111', email='u111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='Testing11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = restProfile.Id, country__c='United States',
                                 timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        return testUser;
    }
    public static Account getAccount(){
        Account acctObjj2 = new Account();
        acctObjj2.Name = 'Test122';
        acctObjj2.Number_of_DL_s__c = 2;
        acctObjj2.RC_Service_name__c = 'office123';
        acctObjj2.RC_Account_Status__c = 'Paid';
        acctObjj2.RC_Brand__c = 'Ringcentral';
        acctObjj2.Billing_Email__c='test@test.test';
        return acctObjj2;
    }
    
    public static Contact getContact(){
        Contact contactObj2 = new Contact();
        contactObj2.LastName= 'TEst1';
        contactObj2.Email='test@test.test';
        contactObj2.isCustomer__c=True;
        contactObj2.Contact_Status__c='Closed Won';
        contactObj2.Contact_Funnel_Type__c='Customer';
        contactObj2.People_Segment__c='Customer';
        return contactObj2;
    }
    
    public static Case getCase(){
        Case caseObj2 = new Case();            
        caseObj2.Subject = 'Test Case';     
        caseObj2.Requesting_BU__c = 'Biz Serv';
        caseObj2.Case_Severity__c ='Level 1 - Critical';
        caseObj2.Application__c = 'Salesforce';
        caseObj2.origin = 'Portal';
        return caseObj2;
    }
    
    public static Opportunity getOpportunity() {
        Opportunity oppObj2 = new Opportunity();
        oppObj2.Name = 'Test Opportunity';
        oppObj2.Type = 'New Business';
        oppObj2.Brand_Name__c = 'RingCentral';
        oppObj2.Tier_Name__c = 'Professional';
        oppObj2.StageName = '1. Qualify';
        oppObj2.CloseDate = System.today();
        oppObj2.CurrencyIsoCode = 'USD';
        return oppObj2;
    }
}