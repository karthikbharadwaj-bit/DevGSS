@isTest
private class DealRegistrationSubmissionCls_Test {
    
    public class MockTestHTTPAppAnnie implements HttpCalloutMock {
      public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
            //res.setStatus('Internal Error');
            return res;
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        //By Pass Triggers
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        
        // TO DO: implement unit test
        Test.setMock(HttpCalloutMock.class, new MockTestHTTPAppAnnie());
        // TO DO: implement unit test
        String partnerAgentName;
        String partnerAgentId;
        String company;
        String firstName;
        String lastName;
        String email;
        String phone;
        String numberOfEmployees;
        String zipCode;
        String salespersonsName;
        String salespersonsEmail;
        String salespersonsPhone;
        String Subsector;
        String Sector;
        RcDealHealper helperObj = new RcDealHealper();
        RcDealHealper.searchResultClass searchResult;
        
        partnerAgentName = '';
        partnerAgentId = '';
        company = 'Test';
        firstName = 'FName';
        lastName = 'LName';
        phone = '091000010101';
        numberOfEmployees = '24';
        zipCode = 'A001';
        salespersonsName = '';
        salespersonsEmail = '';
        salespersonsPhone = '091000010101';
        Subsector = '';
        Sector = '';
        
        List<Segment_Data__c> lstSegment = new List<Segment_Data__c>();
        List<Lead> lstLead = new List<Lead>();
        List<Contact> lstContact = new List<Contact>();
        
        lstSegment.add(new Segment_Data__c(Attribute_1__c = 'ringcentral.com', Type__c = 'Franchise'));
        insert lstSegment;

        //Insert Account
        Account acc = new Account(Name = 'Test', RC_Account_Status__c = 'Paid');
        insert acc; 

        //Insert Leads
        lstLead.add(new Lead(LastName = 'LName', Email = 'lead1@approved.com', Company = 'Company1', PartnerDeal_Status__c = 'BT Approved', PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2014-11-01')));
        lstLead.add(new Lead(LastName = 'LName', Email = 'lead2@protected.com', Company = 'Company2', PartnerDeal_Status__c = 'BT Approved', Status = '2. Contacted' , PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2013-06-01')));
        lstLead.add(new Lead(LastName = 'LName', Email = 'lead1@expired.com', Company = 'Company3', PartnerDeal_Status__c = 'BT Approved', PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2014-03-01')));
        lstLead.add(new Lead(LastName = 'LName', Email = 'lead4@notbtregistered.com', Company = 'Company4'));
        insert lstLead;
        
        lstContact.add(new Contact(LastName = 'LName', Email = 'Contact1@approved.com', PartnerDeal_Status__c = 'BT Approved', PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2014-11-01')));
        lstContact.add(new Contact(AccountId= acc.Id, LastName = 'LName', Email = 'Contact2@protected.com', PartnerDeal_Status__c = 'BT Approved', PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2013-06-01')));
        lstContact.add(new Contact(LastName = 'LName', Email = 'Contact3@protected.com'));
        lstContact.add(new Contact(AccountId= acc.Id, LastName = 'LName', Email = 'Contact4@notbtregistered.com'));
        lstContact.add(new Contact(LastName = 'LName', Email = 'Contact5@expired.com', PartnerDeal_Status__c = 'BT Approved', PartnerDeal_Registration_Expiration_Date__c = Date.valueOf('2014-03-01')));
        insert lstContact;

        email = 'find@approved.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        
                                                    
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        lstOpportunity.add(new Opportunity(Name = 'Opportunity 1', StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON, CloseDate = system.today()));
        lstOpportunity.add(new Opportunity(Name = 'Opportunity 2', StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON, CloseDate = system.today()));
        insert lstOpportunity;

        List<OpportunityContactRole> lstOCR = new List<OpportunityContactRole>();
        lstOCR.add(new OpportunityContactRole(ContactId = lstContact.get(2).Id, OpportunityId = lstOpportunity.get(0).Id, IsPrimary = true));
        lstOCR.add(new OpportunityContactRole(ContactId = lstContact.get(2).Id, OpportunityId = lstOpportunity.get(1).Id, IsPrimary = true));
        insert lstOCR;
                
        //Testing for Protected.
        email = 'find@protected.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        //Testing for Expired.
        email = 'find@expired.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        Test.startTest();
        //Testing for Not BT Registered.
        email = 'find@notbtregistered.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        //Testing for Missing Required Fields.
        email = '';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        //Testing for Invalid Email Id.
        email = 'find2expired.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        //Testing for If no matching record found.
        email = 'find@notfound.com';
        DealRegistrationSubmissionCls.submitDealRegistration(partnerAgentName, partnerAgentId, company, firstName,
                                                                lastName, email, phone, numberOfEmployees, zipCode, salespersonsName, salespersonsEmail, salespersonsPhone, Subsector, Sector, null);
        
        Test.stopTest();
    }
    }