@isTest
private class TestLeadCreationPartnerVAR {

    enum PortalType { CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess }
    private final static string SIA_PERMISSION_SET_LABEL = 'SIA Users';

    public static User getPortalUser(PortalType portalType, User userWithRole, Boolean doInsert ,string profileId, string ranDomStr) {
        /* Make sure the running user has a role otherwise an exception
           will be thrown. */
        if(userWithRole == null) {
            if(UserInfo.getUserRoleId() == null) {
                UserRole r = new UserRole(name = 'TEST ROLE');
                Database.insert(r);

                userWithRole = new User(alias = 'hasrole', email='userwithrole@roletest1.com', userroleid = r.id,
                                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                    localesidkey='en_US', profileid = UserInfo.getProfileId(),
                                    timezonesidkey='America/Los_Angeles', username='userwithrole@testorg.com');
            } else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }

            System.assert(userWithRole.userRoleId != null,
                          'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }

        Account acc1;
        Account acc2;
        Contact contact1;
        Contact contact2;
        System.runAs(userWithRole) {
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

            acc1 = new Account();
            acc1.Name = 'Test Account';
            acc1.Partner_ID__c = '12344';
            acc1.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
            Database.insert(acc1);

            acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.Partner_ID__c = '12345';
            acc2.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
            Database.insert(acc2);

            contact1 = new Contact(AccountId = acc1.id, lastname = 'lastname1',email='testcontact1@test.com');
            Database.insert(contact1);

            contact2 = new Contact(AccountId = acc2.id, lastname = 'lastname2',email='testcontact2@test.com');
            Database.insert(contact2);
        }

        /* Get any profile for the given type.*/
        Profile p = [select id from profile where Id  = :profileId limit 1];

        String testemail = 'puser000@amamama.com';
        User pu;
        if(ranDomStr == 'A') {
            pu = new User(profileId = p.id, username = ranDomStr + testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = contact1.id);
        } else if(ranDomStr == 'B') {
            pu = new User(profileId = p.id, username = ranDomStr + testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = contact2.id);
        }

        if(doInsert) {
            Database.insert(pu);
        }
        return pu;
    }

    @isTest
    static void myUnitTest1() {
        try {
            ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
            LeadCreationPartnerVAR leadObj = new LeadCreationPartnerVAR(sc);
            Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
            Profile p1 = [select id ,name from profile where name = 'RC Partner User'
                            limit 1];

            Profile p2 = [select id, name from profile  where name = 'RC Partner Express'
                            limit 1];

            User pu = getPortalUser(PortalType.PowerPartner,null,true,p1.id,'A'); /// RC Partner User
            User pu1 = getPortalUser(PortalType.PowerPartner,null,true,p2.id,'B'); /// RC Partner User Express
            Test.startTest();
            leadObj.newLead.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
            leadObj.newLead.FirstName= 'AbcTest';
            leadObj.newLead.LastName='Last11';
            leadObj.newLead.Company='Company11';
            leadObj.newLead.Phone='9810546382';
            leadObj.newLead.Email='abc@simplion.com';
            leadObj.newLead.LeadSource = 'Inbound Call';
            leadObj.newLead.Notes__c = 'Test Notes';
            leadObj.newLead.Website = 'asb';
            leadObj.newLead.NumberOfEmployees = 123;
            leadObj.newLead.Industry = 'Test';
            leadObj.newLead.NumberOfEmployees__c = '2-19';
            leadObj.newLead.Number_of_Locations__c = '2-4';
            leadObj.newLead.Description ='testing this ';
            leadObj.newLead.Country = 'United state';
            leadObj.newLead.Country__c = 'United state';
            leadObj.newLead.State = 'california';
            leadObj.newLead.State__c = 'california';
            leadObj.newLead.City = 'california';
            leadObj.newLead.PostalCode='345678';
            leadObj.newLead.LeadPartnerID__c ='12344';
            leadObj.newLead.Lead_Brand_Name__c = 'RingCentral Canada';
            leadObj.newLead.Lead_Tier_Name__c = 'Fax';
            leadObj.newLead.Estimated_Close_Date__c = system.today();
            leadObj.newLead.How_did_you_acquire_this_Lead__c ='Test123';
            leadObj.newLead.Street = '2221 Richter Suite 112';

            //Case 07420246: Full Description field not carrying over to duplicate lead case
            String s = '';
            for(Integer i=0; i<3200; i++){
                s += '1234567890';
            }
            leadObj.newLead.Description = s;
            leadObj.rcUsers = '10';
            leadObj.PartnerAccountType = 'Master Agent';

            leadObj.createNew();
            leadObj.checkInputFieldLength();
            leadObj.getCurrentUser(pu.id);
            leadObj.checkLeadEmailAlreadyExists();
            leadObj.newLead.Email='abc@simplionasdasd.com';
            leadObj.createCaseForPartnerLead(new Contact());

            //Case 07420246: Full Description field not carrying over to duplicate lead case
            Case c = getCase(leadObj.newLead.Id);
            system.assertNotEquals(c, null, 'Case should be created. So, it shouldn\'t be null');
            system.assertEquals(c.Partner_Lead_Description__c.length(), 32000, 'Case.Partner_Lead_Description__c should have length as 32000 symbols');
            System.assertEquals(leadObj.newLead.Street, c.Address_Street_Name__c, 'Case.Address_Street_Name should be equal to Lead.Street');

            leadObj.cancel();
            leadObj.populatePartnerId();
            leadObj.createNew();

            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();

            Account accountObj = new Account();
            accountObj.Name = 'TestAcc';
            accountObj.Partner_ID__c= '140001';
            Schema.DescribeSObjectResult schemaL = Schema.SObjectType.Account;
            Map<String,Schema.RecordTypeInfo> aRecordTypeInfo = schemaL.getRecordTypeInfosByName();
            accountObj.RecordTypeId = aRecordTypeInfo.get('Partner Account').getRecordTypeId();
            insert accountObj;

            Contact conObj = new Contact();
            conObj.FirstName = 'TestFNameconvert';
            conObj.LastName = 'TestLNameconvert';
            conObj.Email = 'Testnameconvert@test.com';
            conObj.AccountId = accountObj.Id;
            conObj.Relayware_Portal_User__c = 'Approved';
            insert  conObj;

            leadObj.newLead.Partner_Contact__c = conObj.id;

            leadObj.createNew();

            accountObj.Partner_ID__c= '12344';
            update accountObj;
            leadObj.createNew();

            leadObj.populatePartnerId();
            Test.stopTest();
        } catch(Exception ex) {}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest2() {
        ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
        LeadCreationPartnerVAR leadObj = new LeadCreationPartnerVAR(sc);
        leadObj.createNew();
    }

    @isTest
    static void testIsValidEmail() {
       ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
       LeadCreationPartnerVAR lcpv = new LeadCreationPartnerVAR(sc);
       Emails__c email = new Emails__c(
          Name = 'fake',
          Email_Address__c = 'fake@email.com');
       insert email;
       String validEmail = 'test@test.com';
       String invalidEmail = 'test[o]email';
       Boolean isValid = false;
       isValid = lcpv.isValidEmail(validEmail);
       system.assertEquals(isValid, true);
       isValid = lcpv.isValidEmail(invalidEmail);
       system.assertEquals(isValid, false);
       Boolean isFake = true;
       isFake = lcpv.isFakeEmail(validEmail);
       system.assertEquals(isValid, false);
    }

    @isTest
    static void testPartnerWrapper() {
        LeadCreationPartnerVAR.partnerWrapper pw = new LeadCreationPartnerVAR.partnerWrapper('000','111','222','333','444','555','666','777','888','999','aaa');
        system.assertEquals(pw.partnerId, '000');
        system.assertEquals(pw.accSignupLink, '333');
        system.assertEquals(pw.accCurrentOwner, '666');
        system.assertEquals(pw.accVarterritory, '999');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMainFlow() {

        ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
        LeadCreationPartnerVAR lcpv = new LeadCreationPartnerVAR(sc);
        lcpv.rcUsers = '1';
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

        Account accountObj = new Account();
        accountObj.Name = 'TestAcc';
        accountObj.Partner_ID__c= '140001';
        Schema.DescribeSObjectResult schemaL = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> aRecordTypeInfo = schemaL.getRecordTypeInfosByName();
        accountObj.RecordTypeId = aRecordTypeInfo.get('Partner Account').getRecordTypeId();
        insert accountObj;

        List<Contact> cons = new List<Contact>();
        Contact partnerContact = new Contact();
        partnerContact.FirstName = 'TestFNameconvert';
        partnerContact.LastName = 'TestLNameconvert';
        partnerContact.Email = 'Testnameconvert@test.com';
        partnerContact.AccountId = accountObj.Id;
        partnerContact.Relayware_Portal_User__c = 'Approved';
        cons.add(partnerContact);

        Contact duplicate = new Contact();
        duplicate.FirstName = 'Dup';
        duplicate.LastName = 'Testov';
        duplicate.Email = 'abc@simplion.com';
        duplicate.AccountId = accountObj.Id;
        duplicate.Relayware_Portal_User__c = 'Approved';
        cons.add(duplicate);

        insert cons;

        lcpv.newLead.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
        lcpv.newLead.FirstName= 'AbcTest';
        lcpv.newLead.LastName='Last11';
        lcpv.newLead.Company='Company11';
        lcpv.newLead.Phone='9810546382';
        lcpv.newLead.Email='abc@simplion.com';
        lcpv.newLead.LeadSource = 'Inbound Call';
        lcpv.newLead.Notes__c = 'Test Notes';
        lcpv.newLead.Website = 'http://test.com';
        lcpv.newLead.NumberOfEmployees = 123;
        lcpv.newLead.Industry = 'Test';
        lcpv.newLead.NumberOfEmployees__c = '2-19';
        lcpv.newLead.Number_of_Locations__c = '2-4';
        lcpv.newLead.Description ='testing this ';
        lcpv.newLead.Country = 'United state';
        lcpv.newLead.Country__c = 'United state';
        lcpv.newLead.State = 'california';
        lcpv.newLead.State__c = 'california';
        lcpv.newLead.City = 'california';
        lcpv.newLead.PostalCode='345678';
        lcpv.newLead.LeadPartnerID__c ='140001';
        lcpv.newLead.Lead_Brand_Name__c = 'RingCentral Canada';
        lcpv.newLead.Lead_Tier_Name__c = 'Fax';
        lcpv.newLead.Estimated_Close_Date__c = system.today();
        lcpv.newLead.How_did_you_acquire_this_Lead__c ='Test123';
        lcpv.newLead.Partner_Contact__c = partnerContact.Id;

        Test.startTest();
            lcpv.createNew();
        Test.stopTest();
    }

    //Case 07140743 (QW) Duplicate lead case updates
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCaseTOPartnerLead(){
        Profile p = [select id ,name from profile where name = 'RC Partner User' limit 1];
        User u = getPortalUser(PortalType.PowerPartner,null,true,p.id,'A');

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.Current_Owner__c => u.Id
                }
            )
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Case c = new Case(
            Status = 'New',
            Subject = 'Test',
            Description = 'Test Desc',
            AccountId = acc.Id,
            ContactId = con.Id,
            Partner_Contact__c = con.Id,
            Partner_Lead_Owner__c = u.Id,
            Partner_Lead_LastName__c = 'Test',
            Partner_Lead_Company__c = 'Test',
            Partner_Lead_Email__c = 'fake@email.com',
            Resolution__c = 'Test Resolution',
            Partner_Lead_Fields__c = '{"Website" : "www.bblrealestate.com","State" : "CALIFORNIA","RC_Term" : null,"RC_Edition" : null,"Partner_Lead_Source" : null,"OwnerId" : "'+HardcodedIdsMapper.getMatchedObjectId('00580000006b0u9AAA')+'","LeadSource" : "Partner","Lead_Tier_Name" : "Office","Lead_Brand_Name" : "RingCentral","Industry" : "Real Estate: Property Management","Estimated_Close_Date" : "2014-07-21","Country" : "United States","City" : "San Diego"}',
            RecordTypeId = CaseHelper.RT_INFO_BY_NAME.get('Partner Lead').getRecordTypeId()
        );
        insert c;

        Test.startTest();
            ApexPages.currentPage().getParameters().put('id', c.Id);
            CaseTOPartnerLead casetoPartnerLeadObj = new CaseTOPartnerLead(new ApexPages.Standardcontroller(c));
            casetoPartnerLeadObj.createPartnerLead();
        Test.stopTest();

        List<Lead> leads = new List<Lead>(
        [
            SELECT Id, Duplicate_Lead_Case__c
            FROM Lead
        ]);
        //system.assertEquals(leads.size(), 1, 'Should be created only one Lead');
        //system.assertEquals(leads[0].Duplicate_Lead_Case__c, c.Id, 'Duplicate Lead Case should store related Case Id');
    }

    private static Case getCase(Id leadPartnerId){
        try{
            return [SELECT Partner_Lead_Description__c, Address_Street_Name__c FROM Case LIMIT 1];
        }
        catch(Exception ex){
            return null;
        }
    }

    @isTest
    static void testRoleContainsSIA() {
      Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
          .build()
          .getRecord();
      LeadCreationPartnerVAR lc = new LeadCreationPartnerVAR(new ApexPages.StandardController(lead));

      UserRole userRole = (UserRole) new SObjectBuilder(UserRole.sObjectType)
          .setField(UserRole.Name, 'SDR - SIA')
          .create()
          .getRecord();
      User userSIA = (User) new SObjectBuilder(User.SObjectType)
          .setField(User.UserRoleId, userRole.Id)
          .create()
          .getRecord();

      Test.startTest();
      Boolean result = lc.roleContainsSIA(userSIA.Id);
      Test.stopTest();

      System.assertEquals(true, result,
                        'Partner Lead Creation couldnt identify the user with SIA role.');
    }

    @isTest
    static void testUserIsInSIAPermissionSet() {
        List<Object> bindings = new List<Object>();
        bindings.add(SIA_PERMISSION_SET_LABEL);
        List<PermissionSet> permissionSet = (List<PermissionSet>) new PermissionSetSelector()
                                                    .selectPermissionSetByLabel(bindings).executeQuery();
        User userSIA = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();

        PermissionSetAssignment psSIA = (PermissionSetAssignment) new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setField(PermissionSetAssignment.PermissionSetId, permissionSet[0].Id)
            .setField(PermissionSetAssignment.AssigneeId, userSIA.Id)
            .create()
            .getRecord();

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
          .build()
          .getRecord();
        LeadCreationPartnerVAR lc = new LeadCreationPartnerVAR(new ApexPages.StandardController(lead));

        Test.startTest();
        ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'selectPermissionSetAssignmentByLabel');
        Boolean result = lc.userIsInSIAPermissionSet(userSIA.Id);
        Test.stopTest();

        System.assertEquals(true, result,
                          'Partner Lead Creation couldnt identify the user in SIAs permission set.');
    }
    @isTest
    static void testMainFlowValidateWebsite() {

       ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
       LeadCreationPartnerVAR lcpv = new LeadCreationPartnerVAR(sc);
       lcpv.rcUsers = '1';
       Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
       Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

       Account accountObj = new Account();
       accountObj.Name = 'TestAcc';
       accountObj.Partner_ID__c= '140001';
       Schema.DescribeSObjectResult schemaL = Schema.SObjectType.Account;
       Map<String,Schema.RecordTypeInfo> aRecordTypeInfo = schemaL.getRecordTypeInfosByName();
       accountObj.RecordTypeId = aRecordTypeInfo.get('Partner Account').getRecordTypeId();
       insert accountObj;

       List<Contact> cons = new List<Contact>();
       Contact partnerContact = new Contact();
       partnerContact.FirstName = 'TestFNameconvert';
       partnerContact.LastName = 'TestLNameconvert';
       partnerContact.Email = 'Testnameconvert@test.com';
       partnerContact.AccountId = accountObj.Id;
       partnerContact.Relayware_Portal_User__c = 'Approved';
       cons.add(partnerContact);

       Contact duplicate = new Contact();
       duplicate.FirstName = 'Dup';
       duplicate.LastName = 'Testov';
       duplicate.Email = 'abc@simplion.com';
       duplicate.AccountId = accountObj.Id;
       duplicate.Relayware_Portal_User__c = 'Approved';
       cons.add(duplicate);

       insert cons;

       lcpv.newLead.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
       lcpv.newLead.FirstName= 'AbcTest';
       lcpv.newLead.LastName='Last11';
       lcpv.newLead.Company='Company11';
       lcpv.newLead.Phone='9810546382';
       lcpv.newLead.Email='test@simplion.com';
       lcpv.newLead.Website = 'google.com';
       lcpv.newLead.Country = 'United state';
       lcpv.newLead.Street = 'Test';
       lcpv.newLead.Country__c = 'United state';
       lcpv.newLead.State = 'california';
       lcpv.newLead.State__c = 'california';
       lcpv.newLead.City = 'california';
       lcpv.newLead.PostalCode='345678';
       lcpv.rcUsers='10';
       lcpv.newLead.LeadPartnerID__c ='140001';
       lcpv.strSelectedBrand = 'Unify Office';
       lcpv.newLead.Lead_Tier_Name__c = 'Office';
       lcpv.newLead.Estimated_Close_Date__c = system.today();
       lcpv.newLead.How_did_you_acquire_this_Lead__c ='Test123';
       lcpv.newLead.Partner_Contact__c = partnerContact.Id;
       Boolean exceptionThrown = false;
       String exceptionMessage; 
        Test.startTest();
        try {
            lcpv.createNew();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(null, lcpv.newLead.Id, 'Lead not should be created with errors');
    }
   @isTest
   static void testMainFlowValidateWebsiteWarningMsg() {
       
       ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
       LeadCreationPartnerVAR lcpv = new LeadCreationPartnerVAR(sc);
       lcpv.rcUsers = '1';
       Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
       Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
       
       Account accountObj = new Account();
       accountObj.Name = 'TestAcc';
       accountObj.Partner_ID__c= '140001';
       Schema.DescribeSObjectResult schemaL = Schema.SObjectType.Account;
       Map<String,Schema.RecordTypeInfo> aRecordTypeInfo = schemaL.getRecordTypeInfosByName();
       accountObj.RecordTypeId = aRecordTypeInfo.get('Partner Account').getRecordTypeId();
       insert accountObj;
       
       List<Contact> cons = new List<Contact>();
       Contact partnerContact = new Contact();
       partnerContact.FirstName = 'TestFNameconvert';
       partnerContact.LastName = 'TestLNameconvert';
       partnerContact.Email = 'Testnameconvert@test.com';
       partnerContact.AccountId = accountObj.Id;
       partnerContact.Relayware_Portal_User__c = 'Approved';
       cons.add(partnerContact);
       
       Contact duplicate = new Contact();
       duplicate.FirstName = 'Dup';
       duplicate.LastName = 'Testov';
       duplicate.Email = 'abc@simplion.com';
       duplicate.AccountId = accountObj.Id;
       duplicate.Relayware_Portal_User__c = 'Approved';
       cons.add(duplicate);
       
       insert cons;
       
       lcpv.newLead.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
       lcpv.newLead.FirstName= 'AbcTest';
       lcpv.newLead.LastName='Last11';
       lcpv.newLead.Company='Company11';
       lcpv.newLead.Phone='9810546382';
       lcpv.newLead.Email='test@simplion.com';
       lcpv.newLead.Country = 'United state';
       lcpv.newLead.Street = 'Test';
       lcpv.newLead.Country__c = 'United state';
       lcpv.newLead.State = 'california';
       lcpv.newLead.State__c = 'california';
       lcpv.newLead.City = 'california';
       lcpv.newLead.PostalCode='345678';
       lcpv.rcUsers='10';
       lcpv.newLead.LeadPartnerID__c ='140001';
       lcpv.strSelectedBrand = 'Unify Office';
       lcpv.newLead.Lead_Tier_Name__c = 'Office';
       lcpv.newLead.Estimated_Close_Date__c = system.today();
       lcpv.newLead.How_did_you_acquire_this_Lead__c ='Test123';
       lcpv.newLead.Partner_Contact__c = partnerContact.Id;
       Boolean exceptionThrown = false;
       String exceptionMessage; 
       lcpv.createNew();
       Test.startTest();
       try {
           lcpv.createNew();
       } catch (AuraHandledException e) {
           exceptionThrown = true;
           exceptionMessage = e.getMessage();
       }
       Test.stopTest();
       System.assertEquals(null, lcpv.newLead.Id, 'Lead not should be created with errors');
   }

    @isTest
    private static void testGetAvayaTiersOnInitialize() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        String allAvayaTiers = '--None--' + ';' +
            String.join(SFDescribeHelper.getDependentOptions(
                'Lead', 'Lead_Brand_Name__c', 'Lead_Tier_Name__c'
            ).get(OpportunityHelper.BRAND_AVAYA), ';');

        Test.startTest();

        LeadCreationPartnerVAR lc = new LeadCreationPartnerVAR(
            new ApexPages.StandardController(lead)
        );

        Test.stopTest();

        System.assertEquals(
            allAvayaTiers,
            lc.avayaTiers,
            'Incorrect Lead Tier Names was retrieved'
        );
    }

    @isTest
    private static void testGetAvayaOfficeValue() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        Test.startTest();
            String avayaOffice = new LeadCreationPartnerVAR(
                new ApexPages.StandardController(lead)
            ).AVAYA_OFFICE;
        Test.stopTest();

        System.assertEquals(
            OpportunityHelper.BRAND_AVAYA,
            avayaOffice,
            'Incorrect Avaya Office value on the page'
        );
    }

    @isTest
    private static void testGetAtosOfficeValue() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        Test.startTest();
            String atosOffice = new LeadCreationPartnerVAR(
                new ApexPages.StandardController(lead)
            ).ATOS_OFFICE;
        Test.stopTest();

        System.assertEquals(
            OpportunityHelper.BRAND_ATOS,
            atosOffice,
            'Incorrect Atos Office value on the page'
        );
    }

    @isTest
    private static void testGetRainbowOfficeValue() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        Test.startTest();
            String rainbowOffice = new LeadCreationPartnerVAR(
                new ApexPages.StandardController(lead)
            ).RAINBOW_OFFICE;
        Test.stopTest();

        System.assertEquals(
            OpportunityHelper.BRAND_RAINBOW,
            rainbowOffice,
            'Incorrect Rainbow Office value on the page'
        );
    }

    @isTest
    static void testNoneValueIsNotAddedToPicklists() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        LeadCreationPartnerVAR leadCreation = new LeadCreationPartnerVAR(new ApexPages.StandardController(lead));
        SelectOption[] competitorOptions = leadCreation.getLeadCompetitors();
        SelectOption[] promptingChangeOptions = leadCreation.getLeadPromptingChange();

        for (SelectOption option : competitorOptions) {
            System.assert(option.getValue() != '', '--None-- option is added to Lead Competitiors picklist');
            System.assert(option.getLabel() != leadCreation.PICKLIST_NONE, '--None-- option is added to Lead Competitiors picklist');
        }

        for (SelectOption option : promptingChangeOptions) {
            System.assert(option.getValue() != '', '--None-- option is added to Lead Prompting Change picklist');
            System.assert(option.getLabel() != leadCreation.PICKLIST_NONE, '--None-- option is added to Lead Prompting Change picklist');
        }
    }

    @isTest
    static void testNoneValueIsAddedToCompetitorPicklist() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        LeadCreationPartnerVAR leadCreation = new LeadCreationPartnerVAR(new ApexPages.StandardController(lead));
        SelectOption[] solutionProviderOptions = leadCreation.getLeadExistingSolutionProvider();
        SelectOption[] decisionMakersOptions = leadCreation.getLeadDecisionMakers();
        SelectOption[] currentlyInContractOptions = leadCreation.getLeadCurrentlyInContract();
        SelectOption[] projectBudgetOptions = leadCreation.getLeadProjectBudget();

        Boolean isNoneAddedToExistingSolutionProvider = false;
        Boolean isNoneAddedToDecisionMakers = false;
        Boolean isNoneAddedToCurrentlyInContract = false;
        Boolean isNoneAddedToProjectBudget = false;

        for (SelectOption option : solutionProviderOptions) {
            if (option.getValue() == '' && option.getLabel() == leadCreation.PICKLIST_NONE) {
                isNoneAddedToExistingSolutionProvider = true;
            }
        }
        System.assert(isNoneAddedToExistingSolutionProvider, '--None-- option is not added to Lead Existing Solution Provider picklist');

        for (SelectOption option : decisionMakersOptions) {
            if (option.getValue() == '' && option.getLabel() == leadCreation.PICKLIST_NONE) {
                isNoneAddedToDecisionMakers = true;
            }
        }
        System.assert(isNoneAddedToDecisionMakers, '--None-- option is not added to Lead Decision Makers picklist');

        for (SelectOption option : currentlyInContractOptions) {
            if (option.getValue() == '' && option.getLabel() == leadCreation.PICKLIST_NONE) {
                isNoneAddedToCurrentlyInContract = true;
            }
        }
        System.assert(isNoneAddedToCurrentlyInContract, '--None-- option is not added to Lead Currently In Contract picklist');

        for (SelectOption option : projectBudgetOptions) {
            if (option.getValue() == '' && option.getLabel() == leadCreation.PICKLIST_NONE) {
                isNoneAddedToProjectBudget = true;
            }
        }
        System.assert(isNoneAddedToProjectBudget, '--None-- option is not added to Lead Budget Options picklist');
    }

    @isTest
    static void testFieldsAreAddedToPartnerLeadSourcesPicklist() {
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .build()
            .getRecord();

        LeadCreationPartnerVAR leadCreation = new LeadCreationPartnerVAR(new ApexPages.StandardController(lead));
        SelectOption[] options = leadCreation.getPartnerLeadSources();

        Boolean partnerOptionIsAdded = false;
        Boolean siaOptionIsAdded = false;

        for (SelectOption option : options) {
            if (option.getValue() == 'Partner' && option.getLabel() == 'Partner') {
                partnerOptionIsAdded = true;
            }
            if (option.getValue() == 'SIA' && option.getLabel() == 'SIA') {
                siaOptionIsAdded = true;
            }
        }

        System.assert(partnerOptionIsAdded, 'Partner option is not added to Partner Lead Sources');
        System.assert(siaOptionIsAdded, 'SIA option is not added to Partner Lead Sources');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testTiersForOtherBrands(){

        ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
        LeadCreationPartnerVAR lcpv = new LeadCreationPartnerVAR(sc);

        Test.startTest();
        lcpv.newLead.Lead_Brand_Name__c = 'RingCentral mit ecotel';
        lcpv.getTiersForOtherBrandsNames();
        Test.stopTest();

    }

    @isTest
    static void testCreateNew() {
        new SObjectBuilder(Default_Partner_Owner__c.sObjectType)
            .setField(Default_Partner_Owner__c.UserId__c, '00580000006cHa8')
            .create();

        ApexPages.StandardController sc = new ApexPages.standardController(new Lead());
        LeadCreationPartnerVAR leadObj = new LeadCreationPartnerVAR(sc);
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.Permitted_Brands__c => RingCentralHelper.BRAND_RINGCENTRAL_CANADA,
                    Account.Partner_Id__c => '12344'
                }
            )
            .create()
            .getRecord();

        Contact conObj = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test',
                    Contact.LastName => 'Test',
                    Contact.Email => 'test@test.test',
                    Contact.AccountId => testAccount.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        leadObj.newLead.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
        leadObj.newLead.FirstName= 'AbcTest';
        leadObj.newLead.LastName='Last11';
        leadObj.newLead.Company='Company11';
        leadObj.newLead.Phone='9810546382';
        leadObj.newLead.Email='abc@simplion.com';
        leadObj.newLead.LeadSource = 'Inbound Call';
        leadObj.newLead.Notes__c = 'Test Notes';
        leadObj.newLead.Website = 'http://www.example.com/page';
        leadObj.newLead.Country = 'United state';
        leadObj.newLead.Country__c = 'United state';
        leadObj.newLead.State = 'california';
        leadObj.newLead.State__c = 'california';
        leadObj.newLead.City = 'california';
        leadObj.newLead.PostalCode='345678';
        leadObj.newLead.LeadPartnerID__c ='12344';
        leadObj.newLead.Lead_Brand_Name__c = RingCentralHelper.BRAND_RINGCENTRAL_CANADA;
        leadObj.newLead.Lead_Tier_Name__c = 'Fax';
        leadObj.newLead.Street = '2221 Richter Suite 112';
        leadObj.rcUsers = '10';
        leadObj.PartnerAccountType = 'Test';
        leadObj.newLead.Partner_Contact__c = conObj.id;
        leadObj.strSelectedBrand = RingCentralHelper.BRAND_RINGCENTRAL_CANADA;

        leadObj.createNew();

        Test.stopTest();
        System.assertNotEquals(null, leadObj.newLead.Id, 'Lead should be created without errors');
    }
}