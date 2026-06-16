@isTest
private class Test_NotesController {
    private static final String TEST_ACCOUNT_NAME = 'Test122';
    private static final String TEST_CASE_SUBJECT = 'Test Case';
    private static final String TEST_CONTACT_LAST_NAME = 'TEst1';
    private static final String TEST_OPPORTUNITY_NAME = 'Test Opportunity';

    @testSetup
    static void setup() {
        Account acctObjj2 = getAccount();
        insert acctObjj2;


        Contact contactObj2 = getContact();
        contactObj2.AccountId =  acctObjj2.id;
        insert contactObj2;


        Case caseObj2 = getCase();
        caseObj2.AccountId = acctObjj2.id;
        caseObj2.contactId = contactObj2.Id;       
        insert caseObj2;
    
        Opportunity oppObj2 = getOpportunity();
        oppObj2.AccountId = acctObjj2.Id;

        insert oppObj2;
    }

    @isTest
    static void testGetContentDocumentDetailForAccount() {
        Account testAcc = (Account) new ListOptional(
                new AccountSelector()
                    .selectAccountByName(new List<Object> {TEST_ACCOUNT_NAME})
                    .executeQuery()
            )
            .getFirst();

        Test.startTest();
            String getCDD1 = NotesController.getContentDocumentsDetail(testAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, getCDD1, 'Should not be null');
    }

    @isTest
    static void testGetContentDocumentDetailForCase() {
        Case testCase = (Case)  new ListOptional(
                new CaseSelector()
                    .newQueryFactory()
                    .setFactoryName('selectCaseBySubject')
                    .selectField(Case.Id)
                    .setCondition('Subject = :bind0')
                    .setQueryBindings(TEST_CASE_SUBJECT)
                    .executeQuery()
            )
            .getFirst();

        Test.startTest();
            String getCDD2 = NotesController.getContentDocumentsDetail(testCase.Id);
        Test.stopTest();

        System.assertNotEquals(null, getCDD2, 'Should not be null');
    }

    @isTest
    static void testGetContentDocumentDetailForContact() {
        Contact testContact = (Contact) new ListOptional(
                new ContactSelector()
                    .newQueryFactory()
                    .setFactoryName('selectContactByLastName')
                    .selectField(Contact.Id)
                    .setCondition('LastName = :bind0')
                    .setQueryBindings(TEST_CONTACT_LAST_NAME)
                    .executeQuery()
            )
            .getFirst();

        Test.startTest();
            String getCDD3 = NotesController.getContentDocumentsDetail(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, getCDD3, 'Should not be null');
    }

    @isTest
    static void testGetContentDocumentDetailForOpportunity() {
        Opportunity testopp = (Opportunity) new ListOptional(
                new OpportunitySelector()
                    .selectOpportunityByName(TEST_OPPORTUNITY_NAME)
                    .executeQuery()
            )
            .getFirst();

        Test.startTest();
            String getCDD4 = NotesController.getContentDocumentsDetail(testopp.Id);
        Test.stopTest();

        System.assertNotEquals(null, getCDD4, 'Should not be null');
    }

    public static Account getAccount(){
        Account acctObjj2 = new Account();
        acctObjj2.Name = TEST_ACCOUNT_NAME;
        acctObjj2.Number_of_DL_s__c = 2;
        acctObjj2.RC_Service_name__c = 'office123';
        acctObjj2.RC_Account_Status__c = 'Paid';
        acctObjj2.RC_Brand__c = 'Ringcentral';
        acctObjj2.Billing_Email__c='test@test.test';
        return acctObjj2;
    }

    public static Contact getContact(){
        Contact contactObj2 = new Contact();
        contactObj2.LastName= TEST_CONTACT_LAST_NAME;
        contactObj2.Email='test@test.test';
        contactObj2.isCustomer__c=True;
        contactObj2.Contact_Status__c='Closed Won';
        contactObj2.Contact_Funnel_Type__c='Customer';
        contactObj2.People_Segment__c='Customer';
        return contactObj2;
    }

    public static Case getCase(){
        Case caseObj2 = new Case();
        caseObj2.Subject = TEST_CASE_SUBJECT;
        caseObj2.Requesting_BU__c = 'Biz Serv';
        caseObj2.Case_Severity__c ='Level 1 - Critical';
        caseObj2.Application__c = 'Salesforce';
        caseObj2.origin = 'Portal';
        return caseObj2;
    }

    public static Opportunity getOpportunity() {
        Opportunity oppObj2 = new Opportunity();
        oppObj2.Name = TEST_OPPORTUNITY_NAME;
        oppObj2.Type = 'New Business';
        oppObj2.Brand_Name__c = 'RingCentral';
        oppObj2.Tier_Name__c = 'Professional';
        oppObj2.StageName = '1. Qualify';
        oppObj2.CloseDate = System.today();
        oppObj2.CurrencyIsoCode = 'USD';
        return oppObj2;
    }


}