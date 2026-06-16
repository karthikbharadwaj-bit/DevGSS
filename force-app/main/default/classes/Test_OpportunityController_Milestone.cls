@isTest
private class Test_OpportunityController_Milestone {
    @isTest
	public static void testCompleteMilestoneCase1() {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName(); 
        Account acctest5 = new Account();
        acctest5.Name = 'TestAccount1';
        acctest5.RecordTypeId  = rtMapByName.get('Customer Account').getRecordTypeId(); 
        acctest5.RC_Service_name__c = 'FAX';
        acctest5.RC_Brand__c = 'RingCentral';
        insert acctest5; 

        Contact contObj5 = new Contact();
        contObj5.AccountId =  acctest5.Id;
        contObj5.Email = 'abc2@test5.com';
        contObj5.LastName = 'Test Last2';
        contObj5.FirstName = 'Test First2';
        insert contObj5;

        Entitlement entObj5 = new Entitlement();
        entObj5.AccountId = acctest5.id;
        entObj5.Name = 'Test Ent5';
        insert entObj5; 

        Test.startTest();

        Contact oContact = [select id from Contact limit 1];
        String contactId;
        if (oContact != null) {
            contactId = oContact.Id;
        }
        Entitlement entl = [select id from Entitlement limit 1];
        String entlId;
        if (entl != null) {
            entlId = entl.Id;
        }
        List<Case> cases = new List<Case>{};
        if (entlId != null) {
            Case c = new Case(Subject = 'Test Case with Entitlement ', EntitlementId = entlId, ContactId = contactId);
            cases.add(c);
        }

        // Insert the Account records that cause the trigger to execute.
        List<Id> caseIds;
        if(cases.isEmpty()==false) {
            insert cases;
            caseIds = new List<Id>();
            for (Case cL : cases) {
                
                caseIds.add(cL.Id);
            }
            milestoneUtils.completeMilestone(caseIds, 'First Response', System.now());
        }
        Test.stopTest();

        System.assertEquals([
            SELECT count()
            FROM CaseMilestone
            WHERE CaseId IN: caseIds 
            AND MilestoneType.Name = 'First Response'
        ],
        0);
    }
    @isTest
	public static void CreateOktaUsertest() {
        RecordType rcType = [SELECT Id, Name FROM RecordType WHERE Name='Partner Account'];
        Account accountobj = new Account();
        accountobj.Name = 'Test Okta';
        accountobj.RecordTypeId = rcType.Id;
        accountobj.Partner_ID__c = 'PARTNER001';
        insert accountobj;

        Contact contactObj = new Contact();
        contactObj.AccountId = accountobj.id;
        contactObj.Email = 'Test@simplion.com';
        contactObj.LastName = 'Test Okta Con';
        contactObj.Phone = '1234567890';
        insert contactObj;
        User testUser = new User(alias = 'u1', email='u1234@testorg.com',
                            emailencodingkey='UTF-8', lastname='Testing', OKTAUserID__c='', ProfileId=[SELECT Id FROM Profile WHERE Name='RC Partner User' LIMIT 1].Id, languagelocalekey='en_US',
                            localesidkey='en_US', country='United States',
                            timezonesidkey='America/Los_Angeles', username=UserHelper.getUniqueUserName(),
                            ContactId=contactObj.id, IsActive=true);

        insert testUser;
        ApexPages.StandardController controller=new ApexPages.StandardController(contactObj);   
        CreateOktaUser objCreateOktaUser=new CreateOktaUser(controller);
        objCreateOktaUser.cancel();
        objCreateOktaUser.validateUser();
        objCreateOktaUser.resetOktaPassword(testUser.id);
        objCreateOktaUser.makeOktaUser(testUser);
        CreateOktaUser.Profile objProfile=new CreateOktaUser.Profile();
        CreateOktaUser.OktaUser objOktaUser=new CreateOktaUser.OktaUser();
        objCreateOktaUser.validateUser();
        Contact contactObj1 = new Contact();
        contactObj1.AccountId = accountobj.id;
        contactObj1.Email = 'TestMyAccount@simplion.com';
        contactObj1.LastName = 'Test Okta Con2';
        contactObj1.Phone = '1234567891';
        insert contactObj1;
        controller=new ApexPages.StandardController(contactObj1);   
        objCreateOktaUser=new CreateOktaUser(controller);
        PageReference testValidatePage = objCreateOktaUser.validateUser();

        System.assertEquals(testValidatePage, null);
    }
}