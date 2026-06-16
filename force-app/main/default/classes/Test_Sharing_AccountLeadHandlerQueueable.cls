@isTest
public class Test_Sharing_AccountLeadHandlerQueueable {
    @testSetup
    static void setupData() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        
        List<Account> accLst = new List<Account>();
        List<Contact> contactLst = new List<Contact>();

        Account portalAccount1 = new Account(
            Name = 'TestAccount',
            RC_Brand__c ='Avaya Cloud Office'
        );
        accLst.add(portalAccount1);

        Account portalAccount2 = new Account(
            Name = 'TestAccount2',
            RC_Brand__c ='Avaya Cloud Office'
        );
        accLst.add(portalAccount2);

        Database.insert(accLst);

        portalAccount1.IsPartner = true;
        portalAccount1.type = 'Partner';
        portalAccount1.Avaya_partnership_account__c = true;
        portalAccount1.Partner_Account__c =portalAccount2.Id;
        portalAccount1.Permitted_Brands__c = 'Avaya Cloud Office';

        portalAccount2.IsPartner = true;
        portalAccount2.type = 'Partner';
        portalAccount2.Avaya_partnership_account__c = true;
        portalAccount2.Partner_Account__c = portalAccount1.Id;
        portalAccount2.Parent_Partner_Account__c = portalAccount1.Id;

        Database.update(accLst);

        Contact contact1 = new Contact(
            FirstName = 'Test',
            Lastname = 'McTesty',
            AccountId = portalAccount1.Id,
            Partner_Portal_View__c='Full',
            Email = System.now().millisecond() + 'test@1test.com'
        );
        contactLst.add(contact1);

        Contact contact2 = new Contact(
            FirstName = 'Test 2',
            Lastname = 'McTest2',
            AccountId = portalAccount2.Id,
            Partner_Portal_View__c='Full',
            Email = System.now().millisecond() + 'test@4test.com'
        );
        contactLst.add(contact2);

        Database.insert(contactLst);
    }

    private static User createSysAdminUser() {

        List<Profile> profilesByNames = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{'System Administrator'}})
            .executeQuery();
        
        User userSysAdmin = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ProfileId => profilesByNames[0].Id,
                    User.Username => System.now().millisecond()+ 'test21351521456@test.com',
                    User.Alias => 'batndfw',
                    User.Email => 'John.Doe@testemail.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.Firstname => 'John',
                    User.Lastname => 'Doe',
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.TimeZoneSidKey => 'America/Chicago',
                    User.Country__c => 'United States'
                }
            )
            .create()
            .getRecord();
        return userSysAdmin;
    }

    private static User createPortalUser(Id contactId) {

        List<Profile> profilesByNames = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{'Partner Community - Partner Admin'}})
            .executeQuery();
        
        User usr = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ProfileId => profilesByNames[0].Id,
                    User.Username => System.now().millisecond()+ 'test21351521456@test.com',
                    User.Alias => 'batndfw',
                    User.Email => 'John.Doe@testemail.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.Firstname => 'John',
                    User.Lastname => 'Doe',
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.TimeZoneSidKey => 'America/Chicago',
                    User.Country__c => 'United States',
                    User.ContactId => contactId
                }
            )
            .create()
            .getRecord();
        return usr;
    }
    
    public static Deal_Registration__c createAvayaDeal(Id partnerContactId, Id partnerAccountId){
        User portalUser = createPortalUser(partnerContactId);

        Deal_Registration__c dealRegObj = new Deal_Registration__c();
        dealRegObj.Partner_Contact__c = partnerContactId;
        dealRegObj.Partner_Account__c = partnerAccountId;
        dealRegObj.First_Name__c = 'Test';
        dealRegObj.Last_Name__c = 'DealReg';
        dealRegObj.Business_Title__c = 'Consultant';
        dealRegObj.Company_Name__c = 'Test Company';
        dealRegObj.Email_Address__c = 'testdealreg@mail.com';
        dealRegObj.Phone_Number__c = '123456';
        dealRegObj.Address__c = 'ABC street';
        dealRegObj.City__c = 'abc city';
        dealRegObj.State__c = 'ALASKA';
        dealRegObj.Postal_Code__c = '123456';
        dealRegObj.Country__c = 'United States';
        dealRegObj.Forecasted_Users__c = 5;
        dealRegObj.Brand_Name__c = 'Avaya Cloud Office';
        dealRegObj.Tier_Name__c = 'Office';
        dealRegObj.Edition__c = 'Standard';
        dealRegObj.Term__c = 'Annual';
        dealRegObj.Number_of_Employees__c = '20-99'; // for UAT
        dealRegObj.Number_of_Locations__c = '5-9';
        dealRegObj.Industry__c = 'Banking';
        dealRegObj.Estimated_Close_Date__c = System.today()+90;
        dealRegObj.Website__c = 'www.testsite.com';
        dealRegObj.How_did_you_acquire_this_Lead__c = 'Testing Acquisition';
        dealRegObj.Description__c = 'Test Deal Reg description';
        dealRegObj.Budget_available_for_project__c = 'Yes'; 
        dealRegObj.Existing_Solution_Provider__c = 'Avaya';
        dealRegObj.Competitor_s__c = 'Avaya';
        dealRegObj.What_s_prompting_change__c = 'Other';
        dealRegObj.Whats_prompting_change__c = 'Other';
        dealRegObj.Decision_Maker__c = 'Other';
        dealRegObj.Currently_in_a_contract__c = 'Yes'; 
        dealRegObj.Sales_Notes__c = 'Test Sales notes';
        dealRegObj.Avaya_Partnership_Deal__c = true;
        dealRegObj.Status__c = 'Approved';
        dealRegObj.Avaya_Cloud_Specialist__c = partnerContactId;
        dealRegObj.RC_Overlay__c = 'test';
        system.runAs(portalUser){
            Database.insert(dealRegObj);  
            System.debug('** Deal '+dealRegObj);
        }        
        return dealRegObj;
    }
    
    public static Lead createLeadRecord(Deal_Registration__c dealObj, Account acc, Contact con) {
        Lead leadObj = new Lead(
                LastName='TestLast',
                FirstName='TestFirst',
                Company='Test',
                email='test@lister.com',
                Status='1. New',
                Deal_Registration__c = dealObj.Id,
                Avaya_Partnership_Lead__c = true,
                Lead_Brand_Name__c='Avaya Cloud Office',
            	Estimated_Close_Date__c = dealObj.Estimated_Close_Date__c,
                Partner_Account__c = acc.Id,
                Partner_Contact__c = con.Id
            );
        Database.insert(leadObj);
        
        leadObj.Avaya_Cloud_Specialist__c = 'test';
                
        return leadObj;
    }
    
    @isTest
    private static void testSharingAOCOnLeadConvertFuture() {
        List<Lead> leadLst = new List<Lead>();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount'][0];
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'McTesty'][0];

        User userSysAdmin = createSysAdminUser();

        List<Deal_Support__c> dealSupportLst = new List<Deal_Support__c>();
        Deal_Registration__c dealObj = createAvayaDeal(con.Id, acc.Id);
        Test.startTest();
        
        Lead leadObj = createLeadRecord(dealObj, acc, con);
            
        System.runAs(userSysAdmin){
            Triggers.switchOff();
            TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        	TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
            
            PartnerLeads.CovertedLeadWrapper clw = PartnerLeads.convertLeadRecord(leadObj);
            Sharing_AccountLeadHandlerQueueable sq = new Sharing_AccountLeadHandlerQueueable(clw.Lead.id);
            System.enqueueJob(sq);
        }
        
        Test.stopTest();
        List<LeadShare> result = [SELECT Id FROM LeadShare];
        System.assertNotEquals(null, result, 'Share record must be exist');   
    }
    
    @isTest
    private static void testSharingAOCOnLeadConvertFuture_withACR() {
        List<Lead> leadLst = new List<Lead>();
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount'][0];
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'McTesty'][0];

        User userSysAdmin = createSysAdminUser();

        List<Deal_Support__c> dealSupportLst = new List<Deal_Support__c>();
        Deal_Registration__c dealObj = createAvayaDeal(con.Id, acc.Id);
        Test.startTest();
        
        Lead leadObj = createLeadRecord(dealObj, acc, con);
        
        System.runAs(userSysAdmin){
            Triggers.switchOff();
            TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        	TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

            PartnerLeads.CovertedLeadWrapper clw = PartnerLeads.convertLeadRecord(leadObj);
            
            Lead convertedLead = [SELECT Id, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id =: clw.Lead.id][0];
            insert new AccountContactRole(
            	AccountId = convertedLead.ConvertedAccountId,
            	ContactId = convertedLead.ConvertedContactId
       		);
            
            Sharing_AccountLeadHandlerQueueable sq = new Sharing_AccountLeadHandlerQueueable(clw.Lead.id);
            System.enqueueJob(sq);
        }
        
        Test.stopTest();
        List<LeadShare> result = [SELECT Id FROM LeadShare];
        System.assertNotEquals(null, result, 'Share record must be exist');   
    }
}