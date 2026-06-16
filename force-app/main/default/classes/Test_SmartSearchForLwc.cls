@isTest
public with sharing class Test_SmartSearchForLwc {
    @TestSetup
    static void setUpData(){
        Id userId = UserInfo.getUserId();
        LeadSourceValuesForNewLead__c leadSourceValue = new LeadSourceValuesForNewLead__c(Name = 'Inbound Call');
        insert leadSourceValue;

        Id varOpportunityRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('VAR Opportunity').getRecordTypeId();
        Id opportunitySalesRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
       

        List<Campaign> campaignsToInsert = new List<Campaign>();
        Campaign brokenAttCamp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Name, 'Broken Attribution')
            .setField(Campaign.Intended_Product__c, 'AU General')
            .build()
            .getRecord();
        campaignsToInsert.add(brokenAttCamp);
        Campaign invocaWalkOn = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Name, 'Digital_Invoca_WalkOn')
            .setField(Campaign.Intended_Product__c, 'AU General')
            .build()
            .getRecord();
        campaignsToInsert.add(invocaWalkOn);
        Campaign invocaMissingAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Name, 'Digital_Invoca_Missing_Attribution')
            .setField(Campaign.Intended_Product__c, 'AU General')
            .setField(Campaign.DNIS__c, '1000')
            .build()
            .getRecord();
        campaignsToInsert.add(invocaMissingAtt);
        Campaign salesGenerated = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Name, 'Sales Generated')
            .setField(Campaign.Intended_Product__c, 'AU General')
            .setField(Campaign.BMID__c, 'BMID')
            .build()
            .getRecord();
        campaignsToInsert.add(salesGenerated);
        Campaign sgFacebook = (Campaign) new SObjectBuilder(Campaign.sObjectType)
        .setField(Campaign.Name, 'sgFacebookCampaign')
        .setField(Campaign.Intended_Product__c, 'AU General')
        .setField(Campaign.BMID__c, 'SGFACEBOOK')
        .setField(Campaign.IsActive, true)
        .build()
        .getRecord();
        campaignsToInsert.add(sgFacebook);
        insert campaignsToInsert;


        List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecords = new List<INVOCA_FOR_SF__Invoca_Call_Log__c>();
        INVOCA_FOR_SF__Invoca_Call_Log__c invoca2 = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.sObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, '23456')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__calling_phone_number__c, '8878966')
            .build()
            .getRecord();
        invocaRecords.add(invoca2);
        INVOCA_FOR_SF__Invoca_Call_Log__c invoca3 = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.sObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, '3365')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, 'TEST')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__calling_phone_number__c, '58558779')
            .build()
            .getRecord();
        invocaRecords.add(invoca3);

        Opportunity oppRelatedToContactWithoutAccount = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'TESTEANDING')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.RecordTypeId, varOpportunityRTId)
            .build()
            .getRecord();
        insert oppRelatedToContactWithoutAccount;
        Contact contactWithoutAccount = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'contact')
            .setField(Contact.Email, 'test@contactNoAcc.test')
            .setField(Contact.Phone, '666635554887')
            .create()
            .getRecord();
        OpportunityContactRole ctRole2 = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.ContactId, contactWithoutAccount.Id)
            .setField(OpportunityContactRole.OpportunityId, oppRelatedToContactWithoutAccount.Id)
            .create()
            .getRecord();

        List<Account> accsToInsert = new List<Account>();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .setField(Account.RC_User_ID__c, '123456')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .setField(Account.Current_Owner__c, userId)
            .build()
            .getRecord();
        accsToInsert.add(acc);
        Account testAccTwo = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test 2nd account')
            .setField(Account.RC_Account_Status__c, 'trial account')
            .setField(Account.RC_User_ID__c, '12245656')
            .build()
            .getRecord();
        accsToInsert.add(testAccTwo);
        Account thirdAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test 3rd account')
            .setField(Account.RC_Account_Status__c, 'trial account')
            .setField(Account.RC_User_ID__c, '51822110')
            .build()
            .getRecord();
        accsToInsert.add(thirdAcc);
        Account fullEmailMatchAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test fullEmailMatch account')
            .setField(Account.RC_Account_Status__c, 'trial acc')
            .setField(Account.RC_User_ID__c, '11000221')
            .build()
            .getRecord();
        accsToInsert.add(fullEmailMatchAcc);
        insert accsToInsert;

        INVOCA_FOR_SF__Invoca_Call_Log__c invoca1 = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.sObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, '1234')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, 'BMID')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__calling_phone_number__c, '15988587')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_2__c, acc.Id)
            .build()
            .getRecord();
        invocaRecords.add(invoca1);
        insert invocaRecords;


        List<Contact> contactsToInsert = new List<Contact>();
        Contact ct = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'testEmail@test.test')
            .setField(Contact.Phone, '24243465467')
            .build()
            .getRecord();
        contactsToInsert.add(ct);
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, acc.Id)
            .build()
            .getRecord();
        contactsToInsert.add(cont);
        Contact contactAllFieldsPopulated = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Smith')
            .setField(Contact.Email, 'test@testing.test')
            .setField(Contact.Phone, '099041191')
            .setField(Contact.AccountId, testAccTwo.Id)
            .build()
            .getRecord();
        contactsToInsert.add(contactAllFieldsPopulated);
        List<Contact> manyContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Amber')
            .setField(Contact.LastName, 'Ct')
            .setField(Contact.Email, 'test@testmanyContacts.test')
            .setField(Contact.Phone, '8487984818')
            .setField(Contact.AccountId, testAccTwo.Id)
            .quantity(10)
            .build()
            .getRecords();
        contactsToInsert.addAll(manyContacts);
        Contact contactRelatedToThirdAcc = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Mathew')
            .setField(Contact.LastName, 'Testing')
            .setField(Contact.AccountId, thirdAcc.Id)
            .build()
            .getRecord();
        contactsToInsert.add(contactRelatedToThirdAcc);
        Contact fullEmailSearchContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.Email, 'test@fullemailsearchtest.com')
            .setField(Contact.AccountId, fullEmailMatchAcc.Id)
            .build()
            .getRecord();
        contactsToInsert.add(fullEmailSearchContact);
        Contact statusOne = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.Email, 'asda@asda.sda')
            .setField(Contact.FirstName, 'Rick')
            .setField(Contact.LastName, 'Sanchez')
            .setField(Contact.Contact_Status__c, '1. New')
            .build()
            .getRecord();
        contactsToInsert.add(statusOne);
        insert contactsToInsert;
        
        Id salesLeadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId();
        List<Lead> leadsToInsert = new List<Lead>();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Test lead')
            .setField(Lead.LeadSource, 'Inbound Call')
            .setField(Lead.Phone, '12346578')
            .setField(Lead.CreatedDate, System.today().addDays(-40))
            .build()
            .getRecord();
        leadsToInsert.add(ld);
        Lead leadRelatedToAcc = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Test lead Related To Account')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .setField(Lead.Phone, '559848788')
            .setField(Lead.RecordTypeId, salesLeadRTId)
            .setField(Lead.Status, '2. Contacted')
            .setField(Lead.CreatedDate, System.today().addDays(-10))
            .build()
            .getRecord();
        Lead leadCreatedByOther = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Test lead Related To Account')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .setField(Lead.Phone, '559848788')
            .setField(Lead.RecordTypeId, salesLeadRTId)
            .setField(Lead.Status, '2. Contacted')
            .setField(Lead.CreatedDate, System.today().addDays(-10))
            .build()
            .getRecord();
        leadsToInsert.add(leadRelatedToAcc);
        insert leadsToInsert;

        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Name, 'Test account')
            .setField(Opportunity.RecordTypeId, opportunitySalesRTId)
            .build()
            .getRecord();
        oppsToInsert.add(oppty);
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Name, 'OppNameTesting')
            .setField(Opportunity.RecordTypeId, varOpportunityRTId)
            .build()
            .getRecord();
        oppsToInsert.add(opp);
        Opportunity unProtectedopp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.RecordTypeId, varOpportunityRTId)
            .setField(Opportunity.StageName, '0. Downgraded')
            .setField(Opportunity.Downgrade_Reason_Opp__c, 'No reason')
            .build()
            .getRecord();  
        oppsToInsert.add(unProtectedopp);
        Opportunity protectedOppActive = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccTwo.Id)
            .setField(Opportunity.Name, 'OppNameTesting')
            .setField(Opportunity.RecordTypeId, opportunitySalesRTId)
            .setField(Opportunity.StageName, '1. Qualify')
            .build()
            .getRecord();
        oppsToInsert.add(protectedOppActive);
        Opportunity wonOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccTwo.Id)
            .setField(Opportunity.RecordTypeId, opportunitySalesRTId)
            .setField(Opportunity.Name, 'Won Opportunity')
            .setField(Opportunity.StageName, '8. Closed Won')
    		.setField(Opportunity.CloseDate, System.today().addDays(-10))
            .build()
            .getRecord();
        oppsToInsert.add(wonOpp);
        Opportunity recentlyWonOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, thirdAcc.Id)
            .setField(Opportunity.RecordTypeId, opportunitySalesRTId)
            .setField(Opportunity.Name, 'Recently Won Opportunity')
            .setField(Opportunity.StageName, '8. Closed Won')
    		.setField(Opportunity.CloseDate, System.today())
            .build()
            .getRecord();
        oppsToInsert.add(recentlyWonOpp);
        Opportunity fullEmailMatchOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, fullEmailMatchAcc.Id)
            .setField(Opportunity.RecordTypeId, opportunitySalesRTId)
            .setField(Opportunity.Name, 'Recently Won Opportunity')
            .setField(Opportunity.StageName, '8. Closed Won')
    		.setField(Opportunity.CloseDate, System.today())
            .build()
            .getRecord();
        oppsToInsert.add(fullEmailMatchOpp);
        insert oppsToInsert;

        ByPassTrigger__c byPassValidation = new ByPassTrigger__c(ByPass_OppContactRole_Validation__c = true);
        insert byPassValidation;
        List<OpportunityContactRole> contactRolesToInsert = new List<OpportunityContactRole>();
        OpportunityContactRole contRole = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.ContactId, ct.Id)
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .build()
            .getRecord();
        contactRolesToInsert.add(contRole);
        OpportunityContactRole ctRole = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.ContactId, cont.Id)
            .setField(OpportunityContactRole.OpportunityId, oppty.Id)
            .build()
            .getRecord();
        contactRolesToInsert.add(ctRole);
        OpportunityContactRole contRoleUnprotectedOpp = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.ContactId, ct.Id)
            .setField(OpportunityContactRole.OpportunityId, unProtectedopp.Id)
            .build()
            .getRecord();
        contactRolesToInsert.add(contRoleUnprotectedOpp);
        OpportunityContactRole wonOppCtRole = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.ContactId, cont.Id)
            .setField(OpportunityContactRole.OpportunityId, wonOpp.Id)
            .build()
            .getRecord();
        contactRolesToInsert.add(wonOppCtRole);
        insert contactRolesToInsert;

        List<Profile> managersProfiles = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object> {'Sales Manager w Insidesales'})
            .executeQuery();
        Profile managerProfile = managersProfiles[0];
        Id managerProfileId = managerProfile.Id; 

        List<Profile> agentsProfiles = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object> {'Sales Agent SDR w Insidesales'})
            .executeQuery();
        Profile agentProfile = agentsProfiles[0];
        Id agentProfileId = agentProfile.Id; 

        List<User> users = new List<User>();
        User test = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'userTest2@testUsername.com')
            .setField(User.CommunityNickname, 'test1234')
            .build()
            .getRecord();
        users.add(test);
        User managerUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'managerUser@managerTest.moc')
            .setField(User.CommunityNickname, 'manager11234')
            .setField(User.ProfileId, managerProfileId)
            .build()
            .getRecord();
        users.add(managerUser);
        User agentUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'agentUser@agentTest.moc')
            .setField(User.CommunityNickname, 'agent11234')
            .setField(User.ProfileId, agentProfileId)
            .build()
            .getRecord();
        users.add(agentUser);
        insert users;
        
 
    }

    @isTest
    static void testGetCampaignSourceDrift() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"drift","ANI":"48627574","InvocaID":"1234",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894", "bmid" : "SGFACEBOOK"}}';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('sgFacebookCampaign', matchedCampaign.Name, 'The name of the matched campaign should be sgFacebookCampaign'); 
        Lead returnedLead = (Lead) result.get('Lead'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c,
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');    
    }

    @isTest
    static void testGetCampaignSourceDriftNonEmptyParameters() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"drift","ANI":"48627574","InvocaID":"1234",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894", "bmid" : "SGFACEBOOK", "fname":"test" ,"lname":"te" ,\n'
        + '"email": "test@test.com","phone":"1234","bmid": "T","rcvid" : "1234","atid": "1544","atid_history":"980",\n'
        + '"aid":"99","pid":"865","kcid":"4556","gclid":"9877","ecid":"5768"}}';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals('test', returnedLead.FirstName,
        'The field firstName of the returned lead should be equal to test'); 
        System.assertEquals('te', returnedLead.LastName,
        'The field lastName of the returned lead should be equal to te'); 
        System.assertEquals('test@test.com', returnedLead.Email, 
        'The field email of the returned lead should be equal to test@test.com'); 
        System.assertEquals('1234', returnedLead.phone, 
        'The field phone of the returned lead should be equal to 1234'); 
        System.assertEquals('T', returnedLead.bmid__c, 
        'The field bmid of the returned lead should be equal to T'); 
        System.assertEquals('1234', returnedLead.RC_Visitor_ID__c, 
        'The field RC_Visitor_ID__c of the returned lead should be equal to 1234'); 
        System.assertEquals('1544', returnedLead.Adobe_Target_Id__c, 
        'The field Adobe_Target_Id__c of the returned lead should be equal to 1544'); 
        System.assertEquals('980', returnedLead.Adobe_Target_Id_History__c, 
        'The field Adobe_Target_Id_History__c of the returned lead should be equal to 980'); 
        System.assertEquals('99', returnedLead.AID__c, 
        'The field AID__c of the returned lead should be equal to 99'); 
        System.assertEquals('865', returnedLead.PID__c,
        'The field PID__c of the returned lead should be equal to 865');  
        System.assertEquals('4556', returnedLead.KCID__c, 
        'The field KCID__c of the returned lead should be equal to 4556');  
        System.assertEquals('9877', returnedLead.GCLID__c, 
        'The field GCLID__c of the returned lead should be equal to 9877'); 
        System.assertEquals('5768', returnedLead.ECID__c, 
        'The field ECID__c of the returned lead should be equal to 5768'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');    
    }

    @isTest
    static void testGetLeadSourceValuesForNewLead() {
        Test.startTest();
        List<String> leadSourceValues = SmartSearchForLwc.getLeadSourceValuesForNewLead();
        Test.stopTest();

        System.assertEquals(1, leadSourceValues.size(), 'returned result size should be 1');
        System.assertEquals('Inbound Call', leadSourceValues[0], 'The returned Lead source should be Inbound Call'); 
    }

    @isTest
    static void testGetCampaignFromInvocaRecord() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"1234",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}}';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Sales Generated', matchedCampaign.Name, 'The name of the matched campaign should be Sales Generated'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testGetCampaignBrokenAttribution() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"3365",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals(matchedCampaign.Name, 'Broken Attribution', 'The name of the matched campaign should be Broken Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
    }

    @isTest
    static void testGetCampaignInvocaWalkOn() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"23456",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_WalkOn', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_WalkOn'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');   
    }

    @isTest
    static void testGetCampaignInvocaMissingAttribution() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"29877",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_Missing_Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_Missing_Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');       
    }

    @isTest
    static void testGetCampaignByDNISInvocaMissingAttribution() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_Missing_Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_Missing_Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');    
    }

    @isTest
    static void testGetCampaignByDNISWithoutMatches() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"988948","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_Missing_Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_Missing_Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testGetCampaignByDNISWithBlankDNIS() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_Missing_Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_Missing_Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Most_Recent_Campaign__c,
        'The field Most_Recent_Campaign__c of the returned lead should be equal to the id of the matchedCampaign'); 
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testGetCampaignByDNISInvocaMissingAttributionAnotherSource() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"another","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Digital_Invoca_Missing_Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Digital_Invoca_Missing_Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testGetCampaignByDNISBrokenAttributionAnotherSource() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"8984","range":"100-399","source":"another","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Broken Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Broken Attribution'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c,
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testGetCampaignWithNewLeadAndRcAccount() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(New List<Object> {'Test lead'})
            .executeQuery(); 
        Lead ld = leads[0];
        String ldId = '"' + ld.id + '"';
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"3365",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}, \n '
        + '"newLead":\n'
        + '{"Id" :' +  ldId +'}, \n'
        + '"rcAccount":\n'
        + '{"Id" :' + accId + ', "Name" : "Test account"}}';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Integer cantDML = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Broken Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Broken Attribution'); 
        System.assertEquals(1, cantDML, 'An update should have ocurred');
    }

    @isTest
    static void testGetCampaignWithNewLeadWithoutRcAccount() {
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(New List<Object> {'Test lead Related To Account'})
            .selectField(Lead.ZI_CDP_Account_Id__c)
            .executeQuery(); 
        Lead ld = leads[0];
        String ldId = '"' + ld.id + '"';
        String accRelatedToLeadId = '"' + ld.ZI_CDP_Account_Id__c + '"' ;
        String jsonParams = '{"params":\n'
        + '{"DNIS":"1000","range":"100-399","source":"invoca","ANI":"48627574","InvocaID":"3365",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}, \n '
        + '"newLead":\n'
        + '{"Id" :' +  ldId +', "ZI_CDP_Account_Id__c": '+ accRelatedToLeadId +'}}';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Integer cantDML = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Broken Attribution', matchedCampaign.Name, 'The name of the matched campaign should be Broken Attribution'); 
        System.assertEquals(1, cantDML, 'An update should have ocurred');
    }

    @isTest
    static void testGetCampaignBlankDNIS() {
        String jsonParams = '{"params":\n'
        + '{"DNIS":"","range":"100-399","source":"another","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(null, result.get('Campaign'), 'The getCampaignMethod should return a null campaign');
    }

    @isTest
    static void testGetCampaignNullDNIS() {
        String jsonParams = '{"params":\n'
        + '{"range":"100-399","source":"another","ANI":"48627574","InvocaID":"",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}} ';
        
        Test.startTest();
        Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The getCampaignMethod should return a map of size 3 ');
        Campaign matchedCampaign = (Campaign) result.get('Campaign');
        System.assertEquals('Sales Generated', matchedCampaign.Name, 'The name of the matched campaign should be Sales Generated'); 
        Lead returnedLead = (Lead) result.get('Lead');
        System.assertEquals(matchedCampaign.Id, returnedLead.Primary_Campaign__c, 
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');     
    }

    @isTest
    static void testExceptionInvalidJSON() {
        String jsonParams = '{{"params":\n'
        + '{"range":"100-399","source":"another","ANI":"48627574","InvocaID":"23456",\n'
        + '"UserID":"123456","skill":"156653","cid":"511894"}}} ';
        Boolean catchedExc = false;
        Test.startTest();
        try { 
            Map<String, sObject> result = SmartSearchForLwc.getCampaign(jsonParams);
        } catch (Exception e) {
            catchedExc = true;
        } 
        Test.stopTest();

        System.assertEquals(true, catchedExc, 'An exception should be thrown');     
    }


    @isTest
    static void testGetRCAccountFromLeadUserId() {
        SmartSearchForLWC.newLead = new Lead();
        Test.startTest();
        Account testAcc = SmartSearchForLWC.getRCAccount('123456', '');
        Test.stopTest();

        System.assertEquals('Test account', testAcc.Name, 'The getRCAccount method should return the Account created');
        System.assertEquals(testAcc.Id, SmartSearchForLWC.newLead.ZI_CDP_Account_Id__c, 'The new Lead should be populated with the Account id');
    }

    @isTest
    static void testGetRCAccountFromURL() {
        SmartSearchForLWC.newLead = new Lead();
        Test.startTest();
        Account testAcc = SmartSearchForLWC.getRCAccount('', '123456');
        Test.stopTest();

        System.assertEquals('Test account', testAcc.Name, 'The getRCAccount method should return the Account created');
        System.assertEquals(testAcc.Id, SmartSearchForLWC.newLead.ZI_CDP_Account_Id__c, 'The new Lead should be populated with the Account id');
    }

    @isTest
    static void testGetRCAccountReturnsNull() {
        SmartSearchForLWC.newLead = new Lead();
        Test.startTest();
        Account testAcc = SmartSearchForLWC.getRCAccount('654321', '654321');
        Test.stopTest();

        System.assertEquals(null, testAcc, 'The getRCAccount method should return null because RC_User_ID__c does not match');
        System.assertEquals(null, SmartSearchForLWC.newLead.ZI_CDP_Account_Id__c, 'The new Lead should be empty');
    }

    @isTest
    static void testGetUserInfo() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User newUser = users[0]; 

        Test.startTest();
        User matchedUser = SmartSearchForLwc.getUserInfo(newUser.Id);
        Test.stopTest();

        System.assertEquals(newUser.Id, matchedUser.Id, 'Id does not match');
    }

    @isTest
    static void testGetSalesManagerProfileId() { 
        Profile managerProfile = [SELECT Id,Name FROM Profile WHERE Name = 'Sales Manager w Insidesales' LIMIT 1];

        Test.startTest();
        Id matchedId = SmartSearchForLwc.getSalesManagerProfileId();
        Test.stopTest();

        System.assertEquals(managerProfile.Id, matchedId, 'Id does not match');
    }

    @isTest
    static void testGetSalesAgentProfileId() {
        Profile agentProfile = [SELECT Id,Name FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];

        Test.startTest();
        Id matchedId = SmartSearchForLwc.getSalesAgentProfileId();
        Test.stopTest();

        System.assertEquals(agentProfile.Id, matchedId, 'Id does not match');
    }

    @isTest
    static void testSearchAllFieldsEmpty() {
        String jsonParams = '{"params":' +
        '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' + 
        '"range":"1-19"}}';
        Boolean exceptionThrown = false;
        String exceptionMessage;

        Test.startTest();
        try {
            SmartSearchForLWC.search(jsonParams);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must enter at least one of these fields to search: Last Name, Company Name, Email Address, Contact Phone Number.',
            exceptionMessage,
            'An exception should have ocurred');
        
    }

    @isTest
    static void testSearchInvalidEmailFormat() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"123456789",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"@test,test","Agent_Email_Address__c":""}}';
        Boolean exceptionThrown = false;
        String exceptionMessage;

        Test.startTest();
        try {
            SmartSearchForLWC.search(jsonParams);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR The email entered is not in a valid format.',
            exceptionMessage,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testSearchToMatchContact() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"testEmail@test.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "Paid"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            true,
            response.get('matchedContactData').size() > 0,
            'there should be at least 1 contact in matchedContactData list');
    }
    
    @isTest
    static void testSearchToMatchUnprotectedLead() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"12346578",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"","Agent_Email_Address__c":""}}';
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(New List<Object> {'Test lead'})
            .executeQuery(); 
        Lead ld = leads[0];
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, ld.OwnerId)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

       
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('unprotectedLeadsData').size(),
            'there should be one lead in unprotectedLeadsData list');
    }

    @isTest
    static void testSearchToMatchProtectedLead() {
        Id salesLeadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId();
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"559848788",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"","Agent_Email_Address__c":""}}';

        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(New List<Object> {'Test lead Related To Account'})
            .executeQuery(); 
        Lead ld = leads[0];
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, ld.OwnerId)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();
        
        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

       
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedLeadData').size(),
            'there should be at least one lead in protectedLeadData list');
    }

    @isTest
    static void testSearchToMatchProtectedOpp() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"Test account","Email":"","Agent_Email_Address__c":""}}';
        List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunityByName('Test account')
            .executeQuery();
        Opportunity opp = opps[0];
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, opp.OwnerId)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();
        
        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsCurrentOwnersData').size(),
            'there should be at least one opportunity in protectedOppsCurrentOwnersData list');
    }
    
    @isTest
    static void testSearchToMatchProtectedOppActivePipe() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"OppNameTesting","Email":"","Agent_Email_Address__c":""}}';

        List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunityByName('OppNameTesting')
            .executeQuery();
        Opportunity opp = opps[0];
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, opp.OwnerId)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
    }

    @isTest
    static void testSearchToMatchUnprotectedOpp() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"Test Opportunity","Email":"","Agent_Email_Address__c":""}}';

        List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunityByName('Test Opportunity')
            .executeQuery();
        Opportunity opp = opps[0];
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, opp.OwnerId)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('unprotectedOppsData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
    }

    @isTest
    static void testSearchAllFieldsNotEmpty() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"John" ' 
        + ',"LastName":"Smith","Title":"","Company":"Test Opportunity","Email":"test@testing.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('unprotectedOppsData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in protectedOppsActivePipeData list');
    }
    
    @isTest
    static void testSearchOnlyFirstAndLastNameEmpty() {
        Test.startTest();
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        acc.Current_Owner__c = null;
        update acc;
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"Test Opportunity","Email":"test@testing.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
    }

    @isTest
    static void testSearchOnlyCompanyEmpty() {
        Test.startTest();        
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        acc.Current_Owner__c = null;
        update acc;
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"John" ' 
        + ',"LastName":"Smith","Title":"","Company":"","Email":"test@testing.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in protectedOppsActivePipeData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
    }

    @isTest
    static void testSearchOnlyPhoneEmpty() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
    

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"John" ' 
        + ',"LastName":"Smith","Title":"","Company":"OppNameTesting","Email":"test@testing.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
    }

    @isTest
    static void testSearchOnlyEmailEmpty() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"John" ' 
        + ',"LastName":"Smith","Title":"","Company":"OppNameTesting","Email":"","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
    }

    @isTest
    static void testSearchOnlyCompanyAndNamesEmpty() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"test@testing.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            2,
            response.get('protectedOppsCurrentOwnersData').size(),
            'there should be two opportunities in protectedOppsCurrentOwnersData list');
    }

    
    @isTest
    static void testSearchOnlyPhoneAndNamesEmptyMatchingTenContacts() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"OppNameTesting","Email":"test@testmanyContacts.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            10,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByNamesAndEmail() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Amber" ' 
        + ',"LastName":"Ct","Title":"","Company":"","Email":"test@testmanyContacts.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            10,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByCompanyAndPhone() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"NOMatches","Email":"","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }
    
    @isTest
    static void testSearchByNamesAndPhone() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099041191",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"John" ' 
        + ',"LastName":"Smith","Title":"","Company":"","Email":"","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }
    
    @isTest
    static void testSearchByCompanyAndNames() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"contact","Title":"","Company":"TESTEANDING","Email":"","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByEmail() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"test@testmanyContacts.test","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            10,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByPhone() {
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"8487984818",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            10,
            response.get('matchedContactData').size(),
            'there should be at least one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByCompany() {
        Test.startTest();
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 2nd account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        acc.Current_Owner__c = null;
        update acc;

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"Won Opportunity","Email":"","Agent_Email_Address__c":""}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('unprotectedOppsData').size(),
            'there should be at least one opportunity in unprotectedOppsData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByFirstAndLastName() {
        Test.startTest();
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test 3rd account'})
            .executeQuery();
        Account acc = accs[0];
        acc.Current_Owner__c = null;
        update acc;

        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Mathew" ' 
        + ',"LastName":"Testing","Title":"","Company":"","Email":"","Agent_Email_Address__c":""}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('protectedOppsActivePipeData').size(),
            'there should be at least one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchByFullEmail() {
        Segment_Data__c segmentDataRecord = new Segment_Data__c();
        segmentDataRecord.Attribute_1__c = 'fullemailsearchtest.com';
        insert segmentDataRecord;
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test fullEmailMatch account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"' + acc.Id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"test@fullemailsearchtest.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('protectedOppsCurrentOwnersData').size(),
            'there should be one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }

    @isTest
    static void testSearchInContactExtension() {
        Segment_Data__c segmentDataRecord = new Segment_Data__c();
        segmentDataRecord.Attribute_1__c = 'fullemailsearchtest.testing';
        insert segmentDataRecord;
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test fullEmailMatch account'})
            .selectField('Current_Owner__c')
            .executeQuery();
        Account acc = accs[0];
        String accId = '"' + acc.Id + '"';
        Employee__c incontactExtension = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setField(Employee__c.User__c, acc.Current_Owner__c)
            .setField(Employee__c.Extension__c, '54848899')
            .create()
            .getRecord();
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"test@fullemailsearchtest.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();

        System.assertEquals(
            1,
            response.get('protectedOppsCurrentOwnersData').size(),
            'there should be one opportunity in protectedOppsActivePipeData list');
        System.assertEquals(
            1,
            response.get('matchedContactData').size(),
            'there should be one contact in matchedContactData list');
        System.assertEquals(6, response.size(), '6 lists should have been returned');
    }
    
    @isTest
    static void testMergceToContactSelectInvocaByANI() {
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        Contact ct = cts[0];
        
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}}';
    
        Test.startTest();
        SmartSearchForLWC.mergeToContact(ct.Id, jsonParams);
        Test.stopTest();


        List<Contact> postUpdatects = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ct.Id})
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        ct = postUpdatects[0];

        System.assertEquals(
            'Test',
            ct.FirstName,
            'The first name of the Contact after the merge should be Test');
        System.assertEquals(
            'Smith',
            ct.LastName,
            'The last name of the Contact after the merge should be Smith');
       System.assertEquals(
            'Test title',
            ct.title,
            'The title of the Contact after the merge should be Test title');        
        System.assertEquals(
            'test@test.com',
            ct.email,
            'The email of the Contact after the merge should be test@test.com'); 
        System.assertEquals(
            '099411945',
            ct.phone,
            'The phone of the Contact after the merge should be 099411945');      
        
    }

    @isTest
    static void testMergeToContactSelectInvocaByInvocaId() {
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        Contact ct = cts[0];
        
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"3365","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}}';
    
        Test.startTest();
        SmartSearchForLWC.mergeToContact(ct.Id, jsonParams);
        Test.stopTest();

        cts = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ct.Id})
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        ct = cts[0];

        System.assertEquals(
            'Test',
            ct.FirstName,
            'The first name of the Contact after the merge should be Test');
        System.assertEquals(
            'Smith',
            ct.LastName,
            'The last name of the Contact after the merge should be Smith');
       System.assertEquals(
            'Test title',
            ct.title,
            'The title of the Contact after the merge should be Test title');        
        System.assertEquals(
            'test@test.com',
            ct.email,
            'The email of the Contact after the merge should be test@test.com'); 
        System.assertEquals(
            '099411945',
            ct.phone,
            'The phone of the Contact after the merge should be 099411945');      
    }

    @isTest
    static void testMergeToContactException() {
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        Contact ct = cts[0];
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660""ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"}' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}}';
    
        Boolean exceptionCatched = false;
        Test.startTest();
        try {
            SmartSearchForLWC.mergeToContact(ct.Id, jsonParams);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        Test.stopTest();

        System.assertEquals(
            true,
            exceptionCatched,
            'An exception processing the jsonParams should have ocurred');      
    }


    @isTest
    static void testMergeToContactWithRCAccount() {
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(new List<Object> {
                new List<String> {'Rick'},
                new List<String> {'Sanchez'},
                new List<String> {'asda@asda.sda'}
            })
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        Contact ct = cts[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        Boolean exceptionCatched = false;
        Test.startTest();
        try {
            SmartSearchForLWC.mergeToContact(ct.Id, jsonParams);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        Test.stopTest();

        
        List<Contact> postUpdate = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ct.Id})
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .selectField('Contact_Status__c')
            .executeQuery();
        ct = postUpdate[0];

        System.assertEquals(
            'Test',
            ct.FirstName,
            'The first name of the Contact after the merge should be Test');
        System.assertEquals(
            'Smith',
            ct.LastName,
            'The last name of the Contact after the merge should be Smith');
       System.assertEquals(
            'Test title',
            ct.title,
            'The title of the Contact after the merge should be Test title');        
        System.assertEquals(
            'test@test.com',
            ct.email,
            'The email of the Contact after the merge should be test@test.com'); 
        System.assertEquals(
            '099411945',
            ct.phone,
            'The phone of the Contact after the merge should be 099411945');   
        System.assertEquals(
            '2. Contacted',
            ct.Contact_Status__c,
            'The status of the Contact after the merge should be 2. Contacted');          
    }

    @isTest
    static void testClaimLeadOwnershipWithRCAccountMatchByInvocaId() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"23456","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}, '
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        System.runAs(us1){
            Test.startTest();
            SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.ownerId,
            'The owner of the lead after claiming the ownership should be us1');
    }

    @isTest
    static void testClaimLeadOwnershipWithRCAccountMatchByPhone() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"15988587",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}, '
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        System.runAs(us1){
            Test.startTest();
            SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.ownerId,
            'The owner of the lead after claiming the ownership should be us1');
    }

    @isTest
    static void testClaimLeadOwnershipWithRCAccountMatchByPhoneNoCampaign() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"58558779",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        System.runAs(us1){
            Test.startTest();
            SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.ownerId,
            'The owner of the lead after claiming the ownership should be us1');
    }

    
    @isTest
    static void testClaimLeadOwnershipNoCustomerInInvocaRecord() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"8878966",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        System.runAs(us1){
            Test.startTest();
            SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.ownerId,
            'The owner of the lead after claiming the ownership should be us1');
    }

    
    @isTest
    static void testClaimLeadOwnershipMatchCampaignByDNIS() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"1000","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"00044188",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        System.runAs(us1){
            Test.startTest();
            SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.ownerId,
            'The owner of the lead after claiming the ownership should be us1');
    }

    
    @isTest
    static void testClaimLeadOwnershipExceptionCampaigNotFound() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        List<Campaign> camp = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'Broken Attribution'})
            .setLimit(1)
            .executeQuery();
        delete camp;
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"1000","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"58558779",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';
        Boolean exceptionCatched;
        System.runAs(us1){
            Test.startTest();
            try {
                SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            } catch(Exception e) {
                exceptionCatched = true;
            }
            Test.stopTest();
        }

        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testClaimLeadOwnershipSourceNotInvocaCampNotFound() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
       
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"453444","source":"asdad","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"58558779",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';
        Boolean exceptionCatched;
        System.runAs(us1){
            Test.startTest();
            try {
                SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            } catch(Exception e) {
                exceptionCatched = true;
            }
            Test.stopTest();
        }

        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testClaimLeadOwnershipSourceNotInvoca() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
    
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"1000","source":"asdad","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"58558779",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';
        
        Boolean exceptionCatched;
        System.runAs(us1){
            Test.startTest();
            try {
                SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            } catch(Exception e) {
                exceptionCatched = true;
            }
            Test.stopTest();
        }

        List<Lead> postUpdatelead = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object> {ld.id})
            .selectField('OwnerId')
            .executeQuery();
        ld = postUpdatelead[0];
        System.assertEquals(
            us1.Id,
            ld.OwnerId,
            'The owner should have changed to us1');
    }

    
    @isTest
    static void testClaimLeadOwnershipSourceNotInvocaEmptyDNIS() {
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0]; 
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        Lead ld = leads[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
    
        String accId = '"'+ acc.id + '"';
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"asdad","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"58558779",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""},'
        + '"rcAccount":'
        + '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';
        Boolean exceptionCatched;
        System.runAs(us1){
            Test.startTest();
            try {
                SmartSearchForLWC.claimUnprotectedLeadOwnership(ld.Id, jsonParams);
            } catch(Exception e) {
                exceptionCatched = true;
            }
            Test.stopTest();
        }

        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testListResultCompareToMethod() {
        SmartSearchForLWC.ListResult a = new SmartSearchForLWC.ListResult('test', 'sdas', '5998822', null, null, System.now(),
                    System.now(), null, null, null, null, null, null, 'rcAccount.Name', null, null, null, 'Name', '/');
        SmartSearchForLWC.ListResult b = new SmartSearchForLWC.ListResult('test', 'sdas', '0990411', null, null, System.now(),
        System.now().addDays(-32), null, null, null, null, null, null, 'rcAccount.Name', null, null, null, 'Name', '/');
        Integer resultA = a.compareTo(b);
        Integer resultB = b.compareTo(a);

        System.assertEquals(-1, resultA, 'The compare to method returned a wrong value');
        System.assertEquals(1, resultB, 'The compare to method returned a wrong value');
    }

    @isTest
    static void testFindContactListException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findContactList(condString);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testFindOpportunitiesPerAccountsException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findOpportunitiesPerAccounts(condString, new Set<Id>());
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testFindOpportunitiesPerCompanyNameException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findOpportunitiesPerCompanyName(condString);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testFindContactPerOppRolesException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findContactPerOppRoles(condString, new List<Id>());
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testFindExistingProtectedLeadsException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findExistingProtectedLeads(condString);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testFindExistingUnprotectedLeadsException() {
        String condString = 'adabreakqueasdasry/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.findExistingUnprotectedLeads(condString);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testPrepareLeadListException() {
        String condString = '/breakquery/';
        Boolean exceptionCatched = false;
        try {
            SmartSearchForLWC.prepareLeadList(condString);
        } catch (Exception e) {
            exceptionCatched = true;
        }
        
        System.assertEquals(
            true,
            exceptionCatched,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadEmailEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"Test Company","Email":"","Title":"","Agent_Email_Address__c":"","Employees_Override__c":' +
        '"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":"","Industry":"Banking"' +
        ',"Website":""},"salesGeneratedStr":"", ' + 
        '"leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadCompanyEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"","Email":"test@test.com","Title":"","Agent_Email_Address__c":"","Employees_Override__c":' +
        '"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":"","Industry":"Banking"' +
        ',"Website":""},"salesGeneratedStr":"", ' + 
        '"leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadLastNameEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"","Company":"Test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"","Employees_Override__c":' +
        '"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":"","Industry":"Banking"' +
        ',"Website":""},"salesGeneratedStr":"", ' + 
        '"leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadLeadSourceEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"","Employees_Override__c":' +
        '"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":"","Industry":"Banking"' +
        ',"Website":""},"salesGeneratedStr":"", ' + 
        '"leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":""}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadEmployeesOverrideEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadIndustryEmpty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadEmployeesOverrideNone() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"--None--","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadInvalidEmail() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"asda@s@@test,test","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"asda@s@@test,test","searchedph":"48627574","searchedcomp":' + 
        '"test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR The email entered is not in a valid format.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadSupportEmailAddresEmptyWithDNIS() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"8775843307","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"","searchedph":"48627574","searchedcomp":' + 
        '"Test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  Support Agent Email Address is required when a call is transferred into this phone #=8775843307.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    
    @isTest
    static void testCreateNewLeadWithoutSearching() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":false,"searchedem":"","searchedph":"","searchedcomp":' + 
        '"","searchedfirst":"","searchedlast":"","searchedLeadSource":""}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR You must search with valid inputs first before creating a new lead.',
            exceptionMsg,
            'An exception should have ocurred');
    }
 
    @isTest
    static void testCreateNewLeadChangingEmailSinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"testtttt@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }
 
    @isTest
    static void testCreateNewLeadChangingPhoneSinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627548448574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }
     
    @isTest
    static void testCreateNewLeadChangingCompanySinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"testsdad","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }

     
    @isTest
    static void testCreateNewLeadChangingFirstNameSinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"test","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"tt","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }
     
    @isTest
    static void testCreateNewLeadChangingLastNameSinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadChangingLeadSourceSinceLastSearch() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'INFO  You must search again as fields have changed after your previous search attempt.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadCurrentSituationTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"' + longstr + '","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Current Situation Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadBenefitsInputTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"' + longstr + '","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Benefits Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadProblemsFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"' + longstr + '","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Problems Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadDecisionMakingFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"' + longstr + '","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Decision Making Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadImpactFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"' + longstr + '","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Impact Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadCompetitiveLandscapeFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"' + longstr + '","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Competitive Landscape Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadIdealSituationFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"' + longstr + '","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Ideal Situation Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadRelationshipBuildingExtrasFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"' + longstr + '",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Relationship Building Extras Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadNextStepsFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"' + longstr + '","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Next Steps Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadCoachingNotesFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"' + longstr + '","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Coaching Notes Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadContractAditionalInfoFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"' + longstr + '", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Contract Additional Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadDecisionMakersAdditionalInfoFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"' + longstr + '","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Decision Makers Additional Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadTimeframeAdditionalInfoFieldTooLong() {
        String longstr = '';
        while (longstr.length() < 32001) {
           longstr += 'A';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":"' + longstr + '"},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR Please enter only upto 32000 characters on Timeframe Additional Information.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadWithLeadSourceSalesGeneratedWithoutSalesGeneratedSource() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR You must select Sales Generated Source.',
            exceptionMsg,
            'An exception should have ocurred');
    }

    @isTest
    static void testCreateNewLeadSalesManagerWithoutRequiredField() {
        List<User> users = (List<User>) new UserSelector()
        .selectUserByUsername(new List<Object> {new List<String>{'managerUser@managerTest.moc'}})
        .executeQuery();    
        User manager = users[0];

        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@test.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"test","Benefits__c":"","Problems__c":"testp","Decision_Making_Process__c"' +
        ':"test","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"test company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        System.runAs(manager) {
            try {
                Test.startTest();
                SmartSearchForLWC.createNew(jsonParams);
                Test.stopTest();
            } catch(Exception e) {
                exceptionCatched = true;
                exceptionMsg = e.getMessage();
            }
        }
        
        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR One of the required(*) fields has not been filled in.',
            exceptionMsg,
            'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadGetCampaignByAniAndRCAccount() {
        List<User> users = (List<User>) new UserSelector()
        .selectUserByUsername(new List<Object> {new List<String>{'managerUser@managerTest.moc'}})
        .executeQuery();    
        User manager = users[0];
        List<Account> accs = (List<Account>) new AccountSelector()
            .selectAccountByName(new List<Object> {'Test account'})
            .executeQuery();
        Account acc = accs[0];
        String accId = '"'+ acc.id + '"';

        String jsonParams = '{"params":' + 
        '{"DNIS":"31","source":"invoca","skill":"5846","cid":"660","ANI":"15988587","InvocaID":"","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"User_Id__c":"123456","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call",' +
        '"rcAccount":' +
        '{"Id":'+ accId + ', "RC_User_ID__c": "123456", "RC_Account_Status__c": "trial acc"}}';

        String exceptionMsg;
        Boolean exceptionCatched = false;
        Id leadId;

        Test.startTest();
        leadId = SmartSearchForLWC.createNew(jsonParams);
        Test.stopTest();

        Lead matchedLead;
        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('ZI_CDP_Account_Id__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '15988587',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
        system.assertEquals(
            acc.Id,
            matchedLead.ZI_CDP_Account_Id__c,
            'The ZI_CDP_Account_Id__c does not match the expected one');
        //Assert that invoca record got updated
        InvocaSelector invocaSelectorInstance = new InvocaSelector();
        List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>)  invocaSelectorInstance
            .selectInvocaRecordByCallerId('15988587')
            .executeQuery();
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaCallRecord = !invocaRecordsList.isEmpty()
            ? invocaRecordsList[0]
            : null;
        system.assertEquals(
            matchedLead.Id,
            invocaCallRecord.INVOCA_FOR_SF__Lead__c,
            'The INVOCA_FOR_SF__Lead__c of the invoca record does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadGetCampaignByAniNoMatches() {
        List<User> users = (List<User>) new UserSelector()
        .selectUserByUsername(new List<Object> {new List<String>{'managerUser@managerTest.moc'}})
        .executeQuery();    
        User manager = users[0];

        String jsonParams = '{"params":' + 
        '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"13321540","InvocaID":"","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"User_Id__c":"123456","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';

        String exceptionMsg;
        Boolean exceptionCatched = false;
        Id leadId;

        Test.startTest();
        leadId = SmartSearchForLWC.createNew(jsonParams);
        Test.stopTest();

        Lead matchedLead;
        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('ZI_CDP_Account_Id__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '48627574',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadGetCampaignByAniMatchingInvocaRecordWithObjectValue3Empty() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"8878966","InvocaID":"","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"User_Id__c":"123456","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';

        String exceptionMsg;
        Boolean exceptionCatched = false;
        Id leadId;

        Test.startTest();
        leadId = SmartSearchForLWC.createNew(jsonParams);
        Test.stopTest();

        Lead matchedLead;
        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('Most_Recent_Campaign__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        List<Campaign> camps = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'Digital_Invoca_WalkOn'})
            .executeQuery();
        Campaign matchedCamp = camps[0];

        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '8878966',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
        System.assertEquals(
            matchedCamp.Id,
            matchedLead.Most_Recent_Campaign__c,
            'The most recent campaign does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadByAniMatchingInvocaRecordWithoutRelatedCampaign() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"58558779","InvocaID":"","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"User_Id__c":"123456","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';

        String exceptionMsg;
        Boolean exceptionCatched = false;
        Id leadId;

        Test.startTest();
        leadId = SmartSearchForLWC.createNew(jsonParams);
        Test.stopTest();

        Lead matchedLead;
        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('Most_Recent_Campaign__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        List<Campaign> camps = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'Broken Attribution'})
            .executeQuery();
        Campaign matchedCamp = camps[0];

        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '58558779',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
        System.assertEquals(
            matchedCamp.Id,
            matchedLead.Most_Recent_Campaign__c,
            'The most recent campaign does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadInvocaIdNotBlank() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"58558779","InvocaID":"1234","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"User_Id__c":"123456","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';

        String exceptionMsg;
        Boolean exceptionCatched = false;
        Id leadId;

        Test.startTest();
        leadId = SmartSearchForLWC.createNew(jsonParams);
        Test.stopTest();

        Lead matchedLead;
        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('Most_Recent_Campaign__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }

        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '15988587',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadOnlyLeadInfoOK() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"23","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        try {
            Test.startTest();
            leadId = SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '48627574',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
    }
    
    @isTest
    static void testCreateNewLeadAsAgentOnlyLeadInfoOK() {

        List<User> users = (List<User>) new UserSelector()
        .selectUserByUsername(new List<Object> {new List<String>{'agentUser@agentTest.moc'}})
        .executeQuery();    
        User agent = users[0];
        String jsonParams = '{"params":' + 
        '{"DNIS":"23","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"notEmpty","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        
        System.runAs(agent) {
            try {
                Test.startTest();
                leadId = SmartSearchForLWC.createNew(jsonParams);
                Test.stopTest();
            } catch(Exception e) {
                exceptionCatched = true;
                exceptionMsg = e.getMessage();
            }
        }

        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '48627574',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Inbound Call',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadSalesGeneratedNoCampaign() {
        String jsonParams = '{"params":' + 
        '{"source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Twitter", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        try {
            Test.startTest();
            leadId = SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        
        List<Campaign> camps = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'Broken Attribution'})
            .executeQuery();
        Campaign matchedCamp = camps[0];

        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '48627574',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Sales Generated',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadSalesGeneratedOK() {
        String jsonParams = '{"params":' + 
        '{"source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        try {
            Test.startTest();
            leadId = SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        List<Lead> lds = new LeadSelector()
                .selectLeadById(new List<Object>{leadId})
                .selectFields(new LeadSelector().getFieldsForLeadConversionMapping())
                .selectField('Primary_Campaign__c')
                .executeQuery();
        if (!lds.isEmpty()) {
            matchedLead = lds[0];
        }
        
        List<Campaign> camps = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'sgFacebookCampaign'})
            .executeQuery();
        Campaign matchedCamp = camps[0];

        System.assertEquals(false, exceptionCatched, 'None exception should have ocurred');
        System.assertEquals(
            '48627574',
            matchedLead.Phone,
            'The phone does not match the expected one');
        System.assertEquals(
            'fName',
            matchedLead.FirstName,
            'The phone does not match the expected one');
        System.assertEquals(
            'Test lastName',
            matchedLead.LastName,
            'The last name does not match the expected one');
        System.assertEquals(
            'Sales Generated',
            matchedLead.LeadSource,
            'The Lead source does not match the expected one');
        System.assertEquals(
            'test@test.com',
            matchedLead.Email,
            'The email does not match the expected one');
        System.assertEquals(
            'newtitle',
            matchedLead.Title,
            'The title does not match the expected one');
        System.assertEquals(
            '20-99',
            matchedLead.Employees_Override__c,
            'The Employees range does not match the expected one');
        System.assertEquals(
            'Banking',
            matchedLead.Industry,
            'The Industry does not match the expected one');
        System.assertEquals(
            'https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456',
            matchedLead.SmartSearchURL__c,
            'The smart search url does not match the expected one');
        System.assertEquals(
            matchedCamp.Id,
            matchedLead.Primary_Campaign__c,
            'The primary campaign does not match the expected one');
    }

    @isTest
    static void testCreateNewLeadExceptionOnLeadInsert() {
        String longStr = '"';
        while(longStr.length() < 22) {
            longStr += 'aa';
        }
        longStr += '"';
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas","Account_Number__c":' + longStr + 
        '",LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        try {
            Test.startTest();
            leadId = SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
    }
    
    @isTest
    static void testCreateNewLeadExceptionOnLeadQualificationInsert() {
        String longstr= '';
        while (longstr.length() < 260) {
            longstr += 'breakingleadinsert';
        }
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"48627574","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@test.com","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":""' +
        ',"Which_Radio__c":"' + longstr + '",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"test@test.com","searchedph":"48627574","searchedcomp":' + 
        '"Test company","searchedfirst":"fName","searchedlast":"Test lastName","searchedLeadSource":"Sales Generated"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        String leadId;
        Lead matchedLead;
        try {
            Test.startTest();
            leadId = SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
    }

    @isTest
    static void testSearchDriftSourceMatchEmail() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@contactNoAcc.test","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":"http://www.example.com/page"},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' +
        '"TimeframeAdditionalInfo__c":""}}';
        Map<String, List<SmartSearchForLWC.ListResult>> response;
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();
       

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        System.assertEquals(
            true,
            response.get('matchedContactData').size() == 1,
            'there should be 1 contact in matchedContactData list');    
    }

    @isTest
    static void testSearchDriftSourceMatchPhone() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"666635554887","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""}}';
        Map<String, List<SmartSearchForLWC.ListResult>> response;
        
        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();
        

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        system.debug(response.get('matchedContactData'));
        System.assertEquals(
            response.get('matchedContactData').size() ,
            1,
            'there should be 1 contact in matchedContactData list');     
    }

    @isTest
    static void testSearchDriftSourceMatchEmailPhone() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"666635554887","FirstName":"fName","LastName"' +
        ':"Test lastName","Company":"Test company","Email":"test@contactNoAcc.test","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' +
        '"TimeframeAdditionalInfo__c":""}}';
        Map<String,List<SmartSearchForLWC.ListResult>> response;

        Test.startTest();
        response = SmartSearchForLWC.search(jsonParams);
        Test.stopTest();
   

        System.assertEquals(6, response.size(), '6 lists should have been returned');
        system.debug(response.get('matchedContactData'));
        System.assertEquals(
            response.get('matchedContactData').size() ,
            1,
            'there should be 1 contact in matchedContactData list');        
    }

    @isTest
    static void testMergeToLeadClaimOwnershipDriftSourceMatchCampaignByBMID() {
        Test.startTest();
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0];
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","bmid":"SGFACEBOOK","ANI":"48627574","InvocaID":"7886","UserID":"123456",'+
        '"rcvid":"1234","atid":"1544","atid_history":"980","aid":"99","pid":"865","kcid":"4556","gclid":"9877","ecid":"5768"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"123456","FirstName":"fName","LastName"' +
        ':"lName","Company":"Test company","Email":"test@contactnoacc.test","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' +
        '"TimeframeAdditionalInfo__c":""}}';
        Lead aLead = (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'test lastname')
            .setField(Lead.firstName, 'test firstname')
            .setField(Lead.company, 'test company')
            .create()
            .getRecord();
        List<Campaign> camps = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {'sgFacebookCampaign'})
            .executeQuery();
        Campaign matchedCamp = camps[0];
        String claimedLeadId;
        system.runAs(us1) {
            SmartSearchForLWC.mergeToLead(aLead.Id,jsonParams,true);
        }
        Test.stopTest();
        aLead = (Lead) new LeadSelector().selectLeadWithCampaignFields(new List<Object>{aLead.Id}).executeQuery()[0];

        System.assertEquals('SGFACEBOOK', aLead.BMID__c, 'BMID should be SGFACEBOOK');
        System.assertEquals(aLead.FirstName, 'fName',
        'The field firstName of the returned lead should be equal to fName'); 
        System.assertEquals(aLead.LastName, 'lName',
        'The field lastName of the returned lead should be equal to lName'); 
        System.assertEquals(aLead.Email, 'test@contactnoacc.test',
        'The field email of the returned lead should be equal to test@contactnoacc.test'); 
        System.assertEquals(aLead.phone, '123456',
        'The field phone of the returned lead should be equal to 123456'); 
        System.assertEquals(aLead.LeadSource, 'Online Chat',
        'The field LeadSource of the returned lead should be equal to Online Chat'); 
        System.assertEquals(aLead.Employees_Override__c, '20-99',
        'The field employeesOverride of the returned lead should be equal to 20-99'); 
        System.assertEquals(aLead.RC_Visitor_ID__c, '1234',
        'The field RC_Visitor_ID__c of the returned lead should be equal to 1234'); 
        System.assertEquals(aLead.Adobe_Target_Id__c, '1544',
        'The field Adobe_Target_Id__c of the returned lead should be equal to 1544'); 
        System.assertEquals(aLead.Adobe_Target_Id_History__c, '980',
        'The field Adobe_Target_Id_History__c of the returned lead should be equal to 980'); 
        System.assertEquals(aLead.AID__c, '99',
        'The field AID__c of the returned lead should be equal to 99'); 
        System.assertEquals(aLead.PID__c, '865',
        'The field PID__c of the returned lead should be equal to 865');  
        System.assertEquals(aLead.KCID__c, '4556',
        'The field KCID__c of the returned lead should be equal to 4556');  
        System.assertEquals(aLead.GCLID__c, '9877',
        'The field GCLID__c of the returned lead should be equal to 9877'); 
        System.assertEquals(aLead.ECID__c, '5768',
        'The field ECID__c of the returned lead should be equal to 5768');
        System.assertEquals(aLead.OwnerId, us1.id,
        'The field owner should be testUser');          
        System.assertEquals(aLead.Primary_Campaign__c, matchedCamp.id,
        'The field primary campaign should be equal to the facebook campaign id');          
    }

    @isTest
    static void testMergeToLeadClaimOwnershipDriftSourceNoMatchesForCampaignByBMID() {
        Test.startTest();
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0];
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","bmid":"NOMATCHES","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"","FirstName":"","LastName"' +
        ':"","Company":"Test company","Email":"","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' +
        '"TimeframeAdditionalInfo__c":""}}';
        Lead aLead = (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'test lastname')
            .setField(Lead.firstName, 'test firstname')
            .setField(Lead.company, 'test company')
            .setField(Lead.Email,'test@contac.test')
            .setField(Lead.Phone, '12345')
            .setField(Lead.BMID__c, '')
            .create()
            .getRecord();
        String claimedLeadId;
        system.runAs(us1) {
            SmartSearchForLWC.mergeToLead(aLead.Id,jsonParams,true);
        }
        Test.stopTest();
        aLead = (Lead) new LeadSelector().selectLeadWithCampaignFields(new List<Object>{aLead.id}).executeQuery()[0];

        System.assertEquals(true, String.isBlank(aLead.BMID__c), 'BMID should be empty');
        System.assertEquals(aLead.FirstName, 'test firstname',
        'The field firstName of the returned lead should be equal to test firstname'); 
        System.assertEquals(aLead.LastName, 'test lastname',
        'The field lastName of the returned lead should be equal to test lastname'); 
        System.assertEquals(aLead.Email, 'test@contac.test',
        'The field email of the returned lead should be equal to test@contac.test'); 
        System.assertEquals(aLead.phone, '12345',
        'The field phone of the returned lead should be equal to 12345'); 
        System.assertEquals(aLead.OwnerId, us1.id,
        'The field owner should be testUser');          
    }

    
    @isTest
    static void testMergeToLeadClaimOwnershipDriftSourceNullBMID() {
        Test.startTest();
        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object> {new List<String>{'userTest2@testUsername.com'}})
            .executeQuery();
        User us1 = users[0];
        String jsonParams = '{"params":' + 
        '{"DNIS":"122131","source":"drift","skill":"5846","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Sales Generated","Primary_Campaign__c":"","Phone":"","FirstName":"","LastName"' +
        ':"","Company":"Test company","Email":"","Title":"newtitle","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":""},"salesGeneratedStr":"Facebook", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' +
        '"TimeframeAdditionalInfo__c":""}}';
        Lead aLead = (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'test lastname')
            .setField(Lead.firstName, 'test firstname')
            .setField(Lead.company, 'test company')
            .setField(Lead.Email,'test@contac.test')
            .setField(Lead.Phone, '12345')
            .setField(Lead.BMID__c, '')
            .create()
            .getRecord();
        String claimedLeadId;
        system.runAs(us1) {
            SmartSearchForLWC.mergeToLead(aLead.Id,jsonParams,true);
        }
        Test.stopTest();
        aLead = (Lead) new LeadSelector().selectLeadWithCampaignFields(new List<Object>{aLead.id}).executeQuery()[0];

        System.assertEquals(null, aLead.BMID__c, 'BMID should be empty');
        System.assertEquals(aLead.FirstName, 'test firstname',
        'The field firstName of the returned lead should be equal to test firstname'); 
        System.assertEquals(aLead.LastName, 'test lastname',
        'The field lastName of the returned lead should be equal to test lastname'); 
        System.assertEquals(aLead.Email, 'test@contac.test',
        'The field email of the returned lead should be equal to test@contac.test'); 
        System.assertEquals(aLead.phone, '12345',
        'The field phone of the returned lead should be equal to 12345'); 
        System.assertEquals(aLead.OwnerId, us1.id,
        'The field owner should be testUser');          
    }

    @isTest
    static void testMergeToContactSourceDriftAllFieldsPopulated() {
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField('FirstName')
            .selectField('LastName')
            .selectField('email')
            .selectField('title')
            .selectField('phone')
            .executeQuery();
        Contact ct = cts[0];
        
        String jsonParams = '{"params":' 
        + '{"DNIS":"122131","source":"drift","skill":"5846","bmid":"SGFACEBOOK","ANI":"48627574","InvocaID":"7886","UserID":"123456",'
        + '"rcvid":"1234","atid":"1544","atid_history":"980","aid":"99","pid":"865","kcid":"4556","gclid":"9877","ecid":"5768"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"","Phone":"099411945",' 
        + '"ZI_CDP_Account_Id__c":"","Ultimate_Parent_Account_ID__c":"","Employees_Override__c":"1-19",' 
        + '"Most_Recent_Campaign__c":"","Primary_Campaign__c":"","FirstName":"Test" ' 
        + ',"LastName":"Smith","Title":"Test title","Company":"","Email":"test@test.com","Agent_Email_Address__c":""}}';
    
        Test.startTest();
        SmartSearchForLWC.mergeToContact(ct.Id, jsonParams);
        Test.stopTest();


        List<Contact> postUpdatects = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ct.Id})
            .selectFields(new List<String> {
                'FirstName', 'LastName', 'Email',
                'Phone','NumberOfEmployees__c','BMID__c',
                'LeadSource', 'Lead_Entry_Source__c',
                'Adobe_Target_Id__c','Adobe_Target_Id_History__c','AID__c',
                'PID__c', 'GCLID__c','ECID__c'
            })
            .executeQuery();
        ct = postUpdatects[0];

        System.assertEquals(
            'Test',
            ct.FirstName,
            'The first name of the Contact after the merge should be Test');
        System.assertEquals(
            'Smith',
            ct.LastName,
            'The last name of the Contact after the merge should be Smith');
        System.assertEquals(
            'test@test.com',
            ct.email,
            'The email of the Contact after the merge should be test@test.com'); 
        System.assertEquals(
            '099411945',
            ct.phone,
            'The phone of the Contact after the merge should be 099411945');   
        System.assertEquals(
            '1-19',
            ct.NumberOfEmployees__c,
            'The number of employees field of the Contact after the merge should be 1-19');    
        System.assertEquals(
            'Online Chat',
            ct.LeadSource,
            'The leadsource field of the Contact after the merge should be Online Chat');    
        System.assertEquals(
            'RingBot Office',
            ct.Lead_Entry_Source__c,
            'The Lead Entry Source field of the Contact after the merge should be RingBot Office');  
        System.assertEquals(
            '1544',
            ct.Adobe_Target_Id__c,
            'The adobe target id field of the Contact after the merge should be 1544');  
        System.assertEquals(
            '980',
            ct.Adobe_Target_Id_History__c,
            'The adobe target history field of the Contact after the merge should be 980');  
        System.assertEquals(
            '99',
            ct.AID__c,
            'The aid field of the Contact after the merge should be 99');    
        System.assertEquals(
            '865',
            ct.PID__c,
            'The pid field of the Contact after the merge should be 865');    
        System.assertEquals(
            '9877',
            ct.GCLID__c,
            'The gclid field of the Contact after the merge should be 9877');    
        System.assertEquals(
            '5768',
            ct.ECID__c,
            'The ECID field of the Contact after the merge should be 5768');       
        System.assertEquals(
            'SGFACEBOOK',
            ct.BMID__c,
            'The bmid field of the Contact after the merge should be SGFACEBOOK');        
    }

    
    @isTest
    static void testMergeToContactSourceDriftAllFieldsEmptyChangesContactStatus() {
        Test.startTest();        
        List<Contact> cts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectFields(new List<String> {
                'FirstName', 'LastName', 'Email',
                'Phone','NumberOfEmployees__c','BMID__c',
                'LeadSource', 'Lead_Entry_Source__c', 'RC_Visitor_ID__c',
                'Adobe_Target_Id__c','Adobe_Target_Id_History__c','AID__c',
                'PID__c', 'GCLID__c','ECID__c','Contact_Status__c'
            })
            .executeQuery();
        Contact oldct = cts[0];
        oldct.BMID__c = null;
        oldct.Contact_Status__c = '1. New';
        update oldct;
        
        String jsonParams = '{"params":' 
        + '{"DNIS":"122131","source":"drift","skill":"5846","bmid":"NOMATCHES","ANI":"48627574","InvocaID":"7886"},' 
        + '"newLead":'  
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"","Phone":"",' 
        + '"ZI_CDP_Account_Id__c":"","Ultimate_Parent_Account_ID__c":"","Employees_Override__c":"",' 
        + '"Most_Recent_Campaign__c":"","Primary_Campaign__c":"","FirstName":"" ' 
        + ',"LastName":"","Title":"Test title","Company":"","Email":"","Agent_Email_Address__c":""}}';
    
        SmartSearchForLWC.mergeToContact(oldct.Id, jsonParams);
        Test.stopTest();


        List<Contact> postUpdatects = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{oldct.Id})
            .selectFields(new List<String> {
                'FirstName', 'LastName', 'Email',
                'Phone','NumberOfEmployees__c','BMID__c',
                'LeadSource', 'Lead_Entry_Source__c', 
                'Adobe_Target_Id__c','Adobe_Target_Id_History__c','AID__c',
                'PID__c', 'GCLID__c','ECID__c','Contact_Status__c'
            })
            .executeQuery();
        Contact newct = postUpdatects[0];

        System.assertEquals(
            oldct.FirstName,
            newct.FirstName,
            'The first name of the Contact after the merge should be equal to the value it had before');
        System.assertEquals(
            oldct.LastName,
            newct.LastName,
            'The last name of the Contact after the merge should be equal to the value it had before');
        System.assertEquals(
            oldct.email,
            newct.email,
            'The email of the Contact after the merge should be equal to the value it had before'); 
        System.assertEquals(
            oldct.phone,
            newct.phone,
            'The phone of the Contact after the merge should be equal to the value it had before');   
        System.assertEquals(
            oldct.NumberOfEmployees__c,
            newct.NumberOfEmployees__c,
            'The number of employees field of the Contact after the merge should be equal to the value it had before');    
        System.assertEquals(
            'Online Chat',
            newct.LeadSource,
            'The leadsource field of the Contact after the merge should be equal to Online Chat');    
        System.assertEquals(
            'RingBot Office',
            newct.Lead_Entry_Source__c,
            'The Lead Entry Source field of the Contact after the merge should be RingBot Office');  
        System.assertEquals(
            oldct.Adobe_Target_Id__c,
            newct.Adobe_Target_Id__c,
            'The adobe target id field of the Contact after the merge should be equal to the value it had before');  
        System.assertEquals(
            oldct.Adobe_Target_Id_History__c,
            newct.Adobe_Target_Id_History__c,
            'The adobe target history field of the Contact after the merge should be equal to the value it had before');  
        System.assertEquals(
            oldct.AID__c,
            newct.AID__c,
            'The aid field of the Contact after the merge should be equal to the value it had before');    
        System.assertEquals(
            oldct.PID__c,
            newct.PID__c,
            'The pid field of the Contact after the merge should be equal to the value it had before');    
        System.assertEquals(
            oldct.GCLID__c,
            newct.GCLID__c,
            'The gclid field of the Contact after the merge should be equal to the value it had before');    
        System.assertEquals(
            oldct.ECID__c,
            newct.ECID__c,
            'The ECID field of the Contact after the merge should be equal to the value it had before');        
        System.assertEquals(
            oldct.BMID__c,
            newct.BMID__c,
            'The BMID field of the Contact after the merge should be equal to the value it had before');     
        System.assertEquals(
            '2. Contacted',
            newct.Contact_Status__c,
            'The Contact status field of the Contact after the merge should be equal to 2. Contacted');      
    }
    @isTest
    static void testCreateNewLeadInvalidWebsite() {
        String jsonParams = '{"params":' + 
        '{"DNIS":"1000","source":"asdas","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"7886","UserID":"123456"},' + 
        '"newLead":' +
        '{"SmartSearchURL__c":"https://rc--box73--c.visualforce.com/apex/LeadSearchExtension?InvocaID=7886&UserID=123456",' + 
        '"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"asdas",' +
        '"LeadSource":"Inbound Call","Primary_Campaign__c":"701R0000000mkM9IAI","Phone":"48627574","FirstName":"","LastName"' +
        ':"Test lastName","Company":"test company","Email":"test@mail.com","Title":"","Agent_Email_Address__c":"",' + 
        '"Employees_Override__c":"20-99","NumberOfEmployees":"","No_of_Employees_needing_phones__c":"","Number_of_Locations__c":' +
        '"","Industry":"Banking","Website":"google.com"},"salesGeneratedStr":"", "leadQualificationObj": ' + 
        '{"QualityConversation__c":false,"Current_Situation__c":"","Benefits__c":"","Problems__c":"","Decision_Making_Process__c"' +
        ':"","Impact__c":"","Competitive_Landscape__c":"","Ideal_Situation__c":"","Relationship_Building_Extras__c":"",' +
        '"NextSteps__c"'+ 
        ':"","CoachingNotes__c":"","In_Contract__c":"","ContractExpiresInfo__c":"","ContractAdditionalInfo__c":"", ' + 
        '"Decision_makers_Additional_Information__c":"","NewTimeFrame__c":"","NewSolutionUpTimeFrame__c":"",' + 
        '"TimeframeAdditionalInfo__c":""},"searched":true,"searchedem":"asda@s@@test,test","searchedph":"48627574","searchedcomp":' + 
        '"test Company","searchedfirst":"","searchedlast":"Test lastName","searchedLeadSource":"Inbound Call"}';
        String exceptionMsg;
        Boolean exceptionCatched = false;
        
        try {
            Test.startTest();
            SmartSearchForLWC.createNew(jsonParams);
            Test.stopTest();
        } catch(Exception e) {
            exceptionCatched = true;
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionCatched, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR The website format you entered is invalid. Kindly correct the website to proceed.',
            exceptionMsg,
            'An exception should have ocurred');
    }
	  @isTest
    static void testSearchInvalidWebsiteFormat() {
        String jsonParams = '{"params":' 
        + '{"DNIS":"","source":"invoca","skill":"5846","cid":"660","ANI":"48627574","InvocaID":"1234","UserID":"123456",' 
        + '"range":"1-19"},' 
        + '"newLead":'
        + '{"inContact_Contact_ID__c":"660","inContact_Skill__c":"5846","Lead_System_Source__c":"invoca","Five9_DNIS__c":' 
        + '"","LeadSource":"Inbound Call","BMID__c":"BMID","Signup_Type__c":"Sign up","User_Type__c":"User Type",' 
        + '"User_ID__c":"123456","LTV__c":50,"GCLID__c":"GCLID","Recurring_Sales_Price__c":1000,"Plan__c":"Plan","Trial__c":' 
        + '"Trial","Total_Sales_Price__c":5000,"Tier__c":"Tier","Invoca_Call_Log__c":"a33R0000001DwtKIAS","Phone":"123456789",' 
        + '"ZI_CDP_Account_Id__c":"001R000002AtYTVIA3","Ultimate_Parent_Account_ID__c":"001R000002AtYTVIA3",' 
        + '"Most_Recent_Campaign__c":"701R0000000m55VIAQ","Primary_Campaign__c":"701R0000000m55VIAQ","FirstName":"" ' 
        + ',"LastName":"","Title":"","Company":"","Email":"testEmail@test.test","Agent_Email_Address__c":"","Website":"google.com"}}';
        Boolean exceptionThrown = false;
        String exceptionMessage;

        Test.startTest();
        try {
            SmartSearchForLWC.search(jsonParams);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should have ocurred');
        System.assertEquals(
            'ERROR The website format you entered is invalid. Kindly correct the website to proceed.',
            exceptionMessage,
            'An exception should have ocurred');
    }

}