@isTest
private class Test_CampaignInfluenceRLC {

	@testSetup static void prepareData() {
		Account acc = new Account(
    		Name = 'testAcc'
    	);

    	insert acc;

    	Opportunity opp = new Opportunity(
            Name = 'CIRLC-test',
            StageName = '1.Qualify'
        );

        insert opp;

        Contact contact = new Contact(
			Preferred_Language__c = 'en_US',
			AccountId = acc.Id,
			LastName = 'testName',
			Email = 'email@test.com1',
			Phone = '+123456789'
		);

		insert contact;

        Campaign c = new Campaign(
			name = 'testCamp'
		);

		insert c;

		List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
		OpportunityContactRole role = new OpportunityContactRole(
			OpportunityId = opp.Id,
			ContactId = contact.Id,
			Role = 'other'
		);
		roles.add(role);

		insert roles;

		CampaignInfluence campInf = new CampaignInfluence(
            OpportunityId = opp.Id,
            CampaignId = c.Id,
            ContactId = contact.Id,
            ModelId = [SELECT Id FROM CampaignInfluenceModel LIMIT 1].Id
        );

		insert campInf;
	}


    @isTest static void testNew() {
    	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    	List<OpportunityContactRole> roles = [SELECT id, OpportunityId, ContactId, Role FROM OpportunityContactRole];
    	CampaignInfluence campInf = [SELECT Id FROM CampaignInfluence LIMIT 1];

        PageReference pageRef = Page.CampaignInfluenceRelatedList;
        pageRef.getParameters().put('Id', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);

        CampaignInfluenceRelatedListController CIRLC = new CampaignInfluenceRelatedListController(new ApexPages.StandardController(opp));
    	CIRLC.newCampaignInfluence();

        System.assertEquals(true, CIRLC.shouldRedirect);
        System.assertEquals('/apex/campaigninfluence?retURL='+opp.Id+'&fromopp='+opp.Id, CIRLC.redirectURL);
    }

    @isTest static void testEdit() {
    	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    	List<OpportunityContactRole> roles = [SELECT id, OpportunityId, ContactId, Role FROM OpportunityContactRole];
    	CampaignInfluence campInf = [SELECT Id FROM CampaignInfluence LIMIT 1];

        PageReference pageRef = Page.CampaignInfluenceRelatedList;
        pageRef.getParameters().put('Id', String.valueOf(opp.Id));
        pageRef.getParameters().put('cId', String.valueOf(campInf.Id));
        Test.setCurrentPage(pageRef);

        CampaignInfluenceRelatedListController CIRLC = new CampaignInfluenceRelatedListController(new ApexPages.StandardController(opp));
    	CIRLC.editCampaignInfluence();

        System.assertEquals(true, CIRLC.shouldRedirect);
        System.assertEquals('/'+campInf.Id+'/e?retURL='+opp.Id, CIRLC.redirectURL);
    }

    @isTest static void testEmptyContactId() {
        Opportunity opp = [SELECT Id, CampaignId FROM Opportunity LIMIT 1];
        //deleting old campaign influences because they have contact ids
        delete [SELECT Id FROM CampaignInfluence];
        //creating a new campaign influence that has empty contact id
        createCampaignInfluenceEmptyContact();

        PageReference pageRef = Page.CampaignInfluenceRelatedList;
        pageRef.getParameters().put('Id', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);

        Integer numberOfSOQL = Limits.getQueries();
        CampaignInfluenceRelatedListController CIRLC = new CampaignInfluenceRelatedListController(new ApexPages.StandardController(opp));
        //verifying that queried only opportunity as campaign influence has empty contact id
        System.assertEquals(numberOfSOQL + 1, Limits.getQueries(), 'Expect to Query only opportunities.');
    }

    @isTest static void testDelete() {
    	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    	List<OpportunityContactRole> roles = [SELECT id, OpportunityId, ContactId, Role FROM OpportunityContactRole];
    	CampaignInfluence campInf = [SELECT Id FROM CampaignInfluence LIMIT 1];

        PageReference pageRef = Page.CampaignInfluenceRelatedList;
        pageRef.getParameters().put('Id', String.valueOf(opp.Id));
        pageRef.getParameters().put('cId', String.valueOf(campInf.Id));
        Test.setCurrentPage(pageRef);

        CampaignInfluenceRelatedListController CIRLC = new CampaignInfluenceRelatedListController(new ApexPages.StandardController(opp));
    	CIRLC.deleteCampaignInfluence();

    	System.assertEquals(true, CIRLC.shouldRedirect);
        System.assertEquals('/'+opp.Id, CIRLC.redirectURL);
    }

    @isTest static void testCampaignInfluenceRelatedItemFieldspopulation() {
        Campaign camp = [
            SELECT Id, Non_Attributable__c
            FROM Campaign
            LIMIT 1
        ];
        Contact contact = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.FirstName => 'testFirst',
                    Lead.Phone => '1234567',
                    Lead.LeadSource => 'Inbound Call',
                    Lead.NumberOfEmployees => 123,
                    Lead.Industry => 'Other',
                    Lead.NumberOfEmployees__c => '50-249',
                    Lead.Number_of_Locations__c => '50+',
                    Lead.Agent_Email_Address__c => 'test@test.com',
                    Lead.Status => '2. Contacted',
                    Lead.Country__c => 'USA',
                    Lead.Zip_Code__c => '100'
                }
            )
            .create()
            .getRecord();

        CampaignMember member = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CampaignMember.CampaignId => camp.Id,
                    CampaignMember.LeadId => lead.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.id);

            LeadStatus convertStatus = [
                SELECT Id, MasterLabel
                FROM LeadStatus
                WHERE IsConverted = true
                LIMIT 1
            ];

            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);

            Lead convertedLead = [
                SELECT Id, ConvertedOpportunityId
                FROM Lead
                WHERE Id = :lead.Id
            ];

            Opportunity convertedOpp = [
                SELECT Id
                FROM Opportunity
                WHERE Id = :convertedLead.ConvertedOpportunityId
                LIMIT 1
            ];

            CampaignInfluence campInf = new CampaignInfluence(
                OpportunityId = convertedOpp.Id,
                CampaignId = camp.Id,
                ModelId = [SELECT Id FROM CampaignInfluenceModel LIMIT 1].Id,
                ContactId = lcr.getContactId()
            );
            insert campInf;

            PageReference pageRef = Page.CampaignInfluenceRelatedList;
            pageRef.getParameters().put('Id', String.valueOf(convertedOpp.Id));
            pageRef.getParameters().put('cId', String.valueOf(campInf.Id));
            Test.setCurrentPage(pageRef);

            CampaignInfluenceRelatedListController controller =
                new CampaignInfluenceRelatedListController(new ApexPages.StandardController(convertedOpp));
            CampaignInfluenceRelatedListController.CampaignInfluenceRelatedItem relatedItem =
                controller.cInfluenceRList.get(0);
        Test.stopTest();

        CampaignMember insertedMember = [
            SELECT Id, CreatedDate
            FROM CampaignMember
        ];

        System.assertEquals(true, relatedItem.isPrimaryCampaignSource,
            'Primary Campaign Source field should be equal to true');
        System.assertEquals(camp.Non_Attributable__c, relatedItem.isNonAttributable,
            'Non Attributable Campaign field should be equal to Non_Attributable__c field on related Campaign');
        System.assertEquals(insertedMember.CreatedDate.format(), relatedItem.memberFirstAssociatedDate,
            'Member First Associated Date field should be equal to CreatedDate field on related Campaign Member');
    }

    private static void createCampaignInfluenceEmptyContact() {
        Opportunity opp = [SELECT Id, CampaignId FROM Opportunity LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        CampaignInfluence campInf = new CampaignInfluence(
            OpportunityId = opp.Id,
            CampaignId = camp.Id,
            ModelId = [SELECT Id FROM CampaignInfluenceModel LIMIT 1].Id
        );
        insert campInf;
    }
}