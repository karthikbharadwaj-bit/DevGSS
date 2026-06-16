@isTest
public class Test_SaaSquatchUserCreation {
    
    public static string LEAD_COMMON_EMAIL = 'testsaasquatchuser@user.com';
   
    @testSetup
    public static void prepareData(){
        
        Lead newLead = new Lead();
        
        newLead.lastName = 'Test-Lead';
        newLead.Email = LEAD_COMMON_EMAIL;
        newLead.Industry = 'Insurance';
        newLead.Company = 'test company';
        newLead.LeadSource = 'ISV Generated';
        newLead.NumberOfEmployees__c = '40';
        
        insert newLead;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testUserCreation(){
                
        Lead newLead = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newLead);
        SaaSquatchUserCreationController user = new SaaSquatchUserCreationController(sc);
        
        user.firstName = 'Test 01';
        user.lastName = 'Test 01';
        user.email = 'test01@test.com';
        user.save();        
    }

	@isTest    
    public static void checkFirstNameNotNull(){
        
        Boolean messageFound = false;
          
        Lead newLead = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newLead);
        SaaSquatchUserCreationController user = new SaaSquatchUserCreationController(sc);
        
        user.firstName = null;
        user.lastName = 'Test 02';
        user.email = 'test02@test.com';
        user.save();
        List<ApexPages.Message> msgs =  ApexPages.getMessages();
        System.assertNotEquals(0, msgs.size());
        for(ApexPages.Message m: msgs){
            if(m.getDetail() == 'Please enter First name' && m.getSeverity() == ApexPages.severity.FATAL) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest
    public static void checkLastNameNotNull(){
        
        Boolean messageFound = false;
           
        Lead newLead = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newLead);
        SaaSquatchUserCreationController user = new SaaSquatchUserCreationController(sc);
        
        user.firstName = 'Test 02';
        user.lastName = null;
        user.email = 'test02@test.com';
        user.save();
        List<ApexPages.Message> msgs =  ApexPages.getMessages();
        System.assertNotEquals(0, msgs.size());
        for(ApexPages.Message m: msgs){
            if(m.getDetail() == 'Please enter Last name' && m.getSeverity() == ApexPages.severity.FATAL) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest
    public static void checkEmailNotNull(){
                
        Boolean messageFound = false;
           
        Lead newLead = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newLead);
        SaaSquatchUserCreationController user = new SaaSquatchUserCreationController(sc);
        
        user.firstName = 'Test 02';
        user.lastName = 'Test 02';
        user.email = null;
        user.save();
        List<ApexPages.Message> msgs =  ApexPages.getMessages();
        System.assertNotEquals(0, msgs.size());
        for(ApexPages.Message m: msgs){
            if(m.getDetail() == 'Please enter Email' && m.getSeverity() == ApexPages.severity.FATAL) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest
    public static void checkEmailPattern(){
        Boolean messageFound = false;
          
        Lead newLead = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newLead);
        SaaSquatchUserCreationController user = new SaaSquatchUserCreationController(sc);
        
        user.firstName = 'Test 04';
        user.lastName = 'Test04';
        user.email = 'test04';
        user.save();
        List<ApexPages.Message> msgs =  ApexPages.getMessages();
        System.assertNotEquals(0, msgs.size());
        for(ApexPages.Message m: msgs){
            if(m.getDetail() == 'Please enter Email in a valid format' && m.getSeverity() == ApexPages.severity.FATAL) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
}