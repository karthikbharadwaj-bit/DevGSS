@IsTest
private class Test_LeadPartnerCommProcessQueueable {

	private static User createUser(String name){
	  User user = new User(
	      Username = name+'!user@gmail.com',
	      LastName = 'Test'+name,
	      Email = name+'_user@gmail.com',
	      Alias = 'test'+name,
	      TimeZoneSidKey = 'America/Los_Angeles',
	      LocaleSidKey = 'en_US',
	      EmailEncodingKey = 'UTF-8',
	      ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
	      LanguageLocaleKey = 'en_US'
	  );
	  insert user;
	  return user;
    }

    private static Map<Id, Lead> getLead() {
        return new Map<Id, Lead>([SELECT 
                                    Id, LastName, IsConverted, Status, 
                                    Avaya_Partnership_Lead__c, Lead_Brand_Name__c, Partner_Contact__c,
                                    Partner_Contact__r.Email, CreatedById, IsAvayaConverted__c
                                FROM Lead 
                                WHERE LastName = 'TestLead2' 
                                LIMIT 1]);
    }

    private static Contact getContact() {
        return [SELECT Id, Email FROM Contact WHERE LastName = 'TestContact1' LIMIT 1];
    }

    @TestSetup
    static void makeData(){
        insert new Emails__c(Name = 'rcsfsyncuser', Email_Address__c = 'trash@example.com');
        insert new Emails__c(Name = 'suniluser', Email_Address__c = 'trashsun@example.com');
        insert new Additional_Emails__c(Name = '1', Additional_Email__c = 'firsttest_user@gmaail.com', AvayaAdditional_Emails__c = 'secondtest_user@gmaail.com');

        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
        Lead testLead = (Lead) new SOBjectBuilder(Lead.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Lead.RecordTypeId => rtMapById.get('Partner Leads').getRecordTypeId(),
            Lead.Company => 'TestLead2',
            Lead.LastName => 'TestLead2',
            Lead.Email => 'TestLead2@test.com',
            Lead.Phone => '9810536322',
            Lead.Country => 'UK',
            Lead.Industry => 'Insurance',
            Lead.LeadSource => 'Inbound Call'
        })
        .create()
        .getRecord();

        Schema.DescribeSObjectResult resultAcc = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtAccMapById = resultAcc.getRecordTypeInfosByName();

        Account testAccount = (Account) new SOBjectBuilder(Account.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.RecordTypeId => rtAccMapById.get('Partner Account').getRecordTypeId(),
            Account.Partner_ID__c => '12346',
            Account.Name => 'Test Account',
            Account.Current_Owner_Email__c => [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email
        })
        .create()
        .getRecord();
        
        Schema.DescribeSObjectResult resultCon = Contact.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtConMapById = resultCon.getRecordTypeInfosByName();

        Contact testContact = (Contact) new SOBjectBuilder(Contact.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Contact.RecordTypeId => rtConMapById.get('Internal').getRecordTypeId(),
            Contact.AccountId => testAccount.Id,
            Contact.LastName => 'TestContact1',
            Contact.Email => 'TestContact1@test.com'
        })
        .create()
        .getRecord();
    }
    
    @isTest
    public static void testAtosLeadCreated() {
        User testUser = createUser('Firs');
        
        System.runAs(testUser) {
            Map<Id, Lead> oldTestLead = getLead();
            Contact testContact = getContact();
            Lead newTestLead = oldTestLead.values()[0].clone(true, true, true, false);

            Test.startTest();
            newTestLead.Lead_Brand_Name__c = 'Unify Office';
            newTestLead.Avaya_Partnership_Lead__c = true;
            newTestLead.Partner_Contact__c = testContact.Id;

            System.enqueueJob(new LeadPartnerCommunityProcessQueueable(new List<Lead>{newTestLead}, null));

            System.assertNotEquals(0, Limits.getQueueableJobs());
            Test.stopTest();    
        }
    }

    @isTest
    public static void testAtosIsLeadDowngraded() {
        User testUser = createUser('Firs');
        
        System.runAs(testUser) {
            Map<Id, Lead> oldTestLead = getLead();
            Contact testContact = getContact();
            Lead newTestLead = oldTestLead.values()[0].clone(true, true, true, false);

            Test.startTest();
            newTestLead.Lead_Brand_Name__c = 'Unify Office';
            newTestLead.Avaya_Partnership_Lead__c = true;
            newTestLead.Partner_Contact__c = testContact.Id;
            newTestLead.Status = '0. Downgraded';

            System.enqueueJob(new LeadPartnerCommunityProcessQueueable(new List<Lead>{newTestLead}, oldTestLead));

            System.assertNotEquals(0, Limits.getQueueableJobs());
            Test.stopTest();    
        }
    }

    @isTest
    public static void testRCIsLeadDowngraded() {
        User testUser = createUser('Firs');
        
        System.runAs(testUser) {
            Map<Id, Lead> oldTestLead = getLead();
            Contact testContact = getContact();
            Lead newTestLead = oldTestLead.values()[0].clone(true, true, true, false);

            Test.startTest();
            newTestLead.Lead_Brand_Name__c = 'RingCentral';
            newTestLead.Avaya_Partnership_Lead__c = true;
            newTestLead.Partner_Contact__c = testContact.Id;
            newTestLead.Status = '0. Downgraded';

            System.enqueueJob(new LeadPartnerCommunityProcessQueueable(new List<Lead>{newTestLead}, oldTestLead));

            System.assertNotEquals(0, Limits.getQueueableJobs());
            Test.stopTest();    
        }
    }

    @isTest
    public static void testRCLeadCreated() {
        User testUser = createUser('Firs');
        
        System.runAs(testUser) {
            Map<Id, Lead> oldTestLead = getLead();
            Contact testContact = getContact();
            Lead newTestLead = oldTestLead.values()[0].clone(true, true, true, false);

            Test.startTest();
            newTestLead.Lead_Brand_Name__c = 'RingCentral';
            newTestLead.Avaya_Partnership_Lead__c = true;
            newTestLead.Partner_Contact__c = testContact.Id;

            System.enqueueJob(new LeadPartnerCommunityProcessQueueable(new List<Lead>{newTestLead}, null));

            System.assertNotEquals(0, Limits.getQueueableJobs());
            Test.stopTest();    
        }
    }

    @isTest
    public static void testAvayaLeadCreated() {
        User testUser = createUser('Firs');
        
        System.runAs(testUser) {
            Map<Id, Lead> oldTestLead = getLead();
            Contact testContact = getContact();
            Lead newTestLead = oldTestLead.values()[0].clone(true, true, true, false);

            Test.startTest();
            newTestLead.Lead_Brand_Name__c = 'Avaya Cloud Office';
            newTestLead.Avaya_Partnership_Lead__c = true;
            newTestLead.Partner_Contact__c = testContact.Id;

            System.enqueueJob(new LeadPartnerCommunityProcessQueueable(new List<Lead>{newTestLead}, null));

            System.assertNotEquals(0, Limits.getQueueableJobs());
            Test.stopTest();    
        }
    }
}