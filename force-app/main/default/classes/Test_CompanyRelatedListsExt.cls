@isTest
private class Test_CompanyRelatedListsExt {
    private static final Integer NUM_OF_RECORDS = 6;

    private static Account_Hierarchy__c getCompany() {
        Account_Hierarchy__c company = new Account_Hierarchy__c();
        insert company;
        return company;
    }

    private static Lead getLead() {
        Lead ld = new Lead(Email = 'fake@email.com',
                            LastName = 'Test_Name',
                            Company = 'Test_Company');
        insert ld;
        return ld;
    }

    private static Contact getContact() {
        Contact con = new Contact(LastName = 'Test_Contact');
        insert con;
        return con;
    }

    private static List<Company_Persons__c> getCompanyPersons(Id companyId, 
                                                                Integer numberOfRecords,
                                                                Id leadId,
                                                                Id contactId) {
        List<Company_Persons__c> persons = new List<Company_Persons__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            persons.add(new Company_Persons__c(Company__c = companyId,
                                                Lead__c = leadId,
                                                Contact__c = contactId));
        }
        insert persons;
        return persons;
    }

    private static List<Task> getTasks(Id leadId, 
                                        Id contactId, 
                                        Integer numberOfRecords) {
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            tasks.add(new Task(WhoId = Math.mod(i, 2) == 0 ? contactId : leadId));
        }
        insert tasks;
        return tasks;
    }

    private static List<OpportunityContactRole> getOpportunityContactRoles(Integer numberOfRecords,
                                                                            List<Opportunity> opps,
                                                                            Id contactId) {
        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        for (Opportunity opp : opps) {
            for (Integer i = 0; i < numberOfRecords; i++) {
                roles.add(new OpportunityContactRole(OpportunityId = opp.Id,
                                                    ContactId = contactId));
            }
        }
        insert roles;
        return roles;
    }

    private static List<Opportunity> getOpportunities(Integer numberOfRecords) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            opps.add(new Opportunity(Name = 'Test_Opp' + i,
                                    StageName = '1. Qualify'));
        }
        insert opps;
        return opps;
    }

    private static List<CampaignMember> getCampaignMembers(Integer numberOfRecords,
                                                            Id contactId,
                                                            Id leadId,
                                                            List<Campaign> campaigns) {
        List<CampaignMember> members = new List<CampaignMember>();
        for (Campaign mem : campaigns) {
            for (Integer i = 0; i < numberOfRecords; i++) {
                if (Math.mod(i, 2) == 0) {
                    members.add(new CampaignMember(LeadId = leadId,
                                                    CampaignId = mem.Id));
                } else {
                   members.add(new CampaignMember(ContactId = contactId,
                                                    CampaignId = mem.Id));
                }
            }
        }
        Database.insert(members, false);
        return members;
    }

    private static List<Campaign> getCampaigns(Integer numberOfRecords) {
        List<Campaign> campaigns = new List<Campaign>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            campaigns.add(new Campaign(Name = 'Test_Camp_' + i));
        }
        insert campaigns;
        return campaigns;
    }

    private static CompanyRelatedListsExt getController(ApexPages.StandardController stdController) {
        return new CompanyRelatedListsExt(stdController);
    }

    private static PageReference getPage(Id currentId, Id returnId, String objectType) {
        PageReference pageRef = Page.OpportunitiesRelatedListOnCompany;
        pageRef.getParameters().put('cId', String.valueOf(currentId));
        pageRef.getParameters().put('sobj', String.valueOf(objectType));
        pageRef.getParameters().put('Id', String.valueOf(returnId));
        return pageRef;
    }


    @isTest 
    private static void testActivityList() {
        Account_Hierarchy__c company = getCompany();
        Lead ld = getLead();
        Contact con = getContact();
        List<Task> tasks = getTasks(ld.Id, con.Id, NUM_OF_RECORDS);
        List<Company_Persons__c> persons = getCompanyPersons(company.Id, NUM_OF_RECORDS, ld.Id, con.Id);
        Test.startTest();
            CompanyRelatedListsExt controller = getController(new ApexPages.StandardController(company));
            
            System.assertEquals(controller.getActivities().size(), 
                                NUM_OF_RECORDS,
                                'Tasks was created and received incorrectly.');
        Test.stopTest();
    }

    @isTest 
    private static void testOpportunitiesList() {
        Account_Hierarchy__c company = getCompany();
        CompanyRelatedListsExt controller = getController(new ApexPages.StandardController(company));
        controller.getOpportunities();
        Contact con = getContact();
        Lead ld = getLead();
        List<Company_Persons__c> persons = getCompanyPersons(company.Id, NUM_OF_RECORDS, ld.Id, con.Id);
        List<Opportunity> opps = getOpportunities(NUM_OF_RECORDS);
        List<OpportunityContactRole> roles = getOpportunityContactRoles(NUM_OF_RECORDS, opps, con.Id);
        Test.startTest();
            controller = getController(new ApexPages.StandardController(company));
            
            System.assertEquals(controller.getOpportunities().size(), 
                                NUM_OF_RECORDS,
                                'Opportunities was created and received incorrectly.');
        Test.stopTest();
    }

    @isTest
    private static void testCampaignsList() {
        Account_Hierarchy__c company = getCompany();
        CompanyRelatedListsExt controller = getController(new ApexPages.StandardController(company));
        controller.getCampaigns();
        Lead ld = getLead();
        Contact con = getContact();
        List<Company_Persons__c> persons = getCompanyPersons(company.Id, NUM_OF_RECORDS, ld.Id, con.Id);
        List<Campaign> campaigns = getCampaigns(NUM_OF_RECORDS);
        List<CampaignMember> members = getCampaignMembers(NUM_OF_RECORDS, con.Id, ld.Id, campaigns);
        Test.startTest();
            controller = getController(new ApexPages.StandardController(company));
            
            System.assertEquals(controller.getCampaigns().size(), 
                                NUM_OF_RECORDS,
                                'Campaigns was created and received incorrectly.');
        Test.stopTest();
    }

    @isTest
    private static void testDeleteItems() {
        Account_Hierarchy__c company = getCompany();
        Contact con = getContact();
        Lead ld = getLead();
        List<Company_Persons__c> persons = getCompanyPersons(company.Id, NUM_OF_RECORDS, ld.Id, con.Id);
        List<Opportunity> opps = getOpportunities(NUM_OF_RECORDS);
        Test.startTest();
            CompanyRelatedListsExt controller = getController(new ApexPages.StandardController(company));
            PageReference pageRef = getPage(opps.get(0).Id, company.Id, 'FakeOpportunity');
            Test.setCurrentPage(pageRef);
            controller.deleteItem();
            PageReference newPageRef = getPage(opps.get(0).Id, company.Id, 'Opportunity');
            Test.setCurrentPage(newPageRef);
            controller.deleteItem();

            System.assertEquals(controller.redirect,
                                true,
                                'Item was deleted mistakenly.');
            System.assertEquals(controller.redirectUrl,
                                String.valueOf('/' + company.Id),
                                'Item was deleted mistakenly.');
        Test.stopTest();
    }

    @isTest
    private static void testEditAndShowItems() {
        Account_Hierarchy__c company = getCompany();
        Contact con = getContact();
        Lead ld = getLead();
        List<Company_Persons__c> persons = getCompanyPersons(company.Id, NUM_OF_RECORDS, ld.Id, con.Id);
        List<Opportunity> opps = getOpportunities(NUM_OF_RECORDS);
        Test.startTest();
            CompanyRelatedListsExt controller = getController(new ApexPages.StandardController(company));
            PageReference pageRef = getPage(opps.get(0).Id, company.Id, 'Opportunity');
            Test.setCurrentPage(pageRef);
            controller.editItem();

            System.assertEquals(controller.redirect,
                                true,
                                'Item was edited mistakenly.');
            System.assertEquals(controller.redirectUrl,
                                String.valueOf('/' + opps.get(0).Id + 
                                                '/e?retURL=' + '/' + company.Id),
                                'Item was edited mistakenly.');

            controller.showAllRecords();

            System.assertEquals(controller.showFullTable,
                                true,
                                'Full table was not shown.');
        Test.stopTest();
    }
}