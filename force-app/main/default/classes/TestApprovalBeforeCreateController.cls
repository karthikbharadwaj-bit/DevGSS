@isTest
private class TestApprovalBeforeCreateController {
    @testSetup
    static void createTestData() {
        Triggers.switchOff();
        Account a = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact c = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => a.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();    
		Opportunity o = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Opportunity.Name => 'Test Opportunity 2016',
					Opportunity.Type => 'Syndicated - New',
					Opportunity.StageName => 'Planning',
					Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
					Opportunity.AccountId => a.Id,
					Opportunity.Primary_Opportunity_Contact__c => c.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10,
                    Opportunity.Forecasted_Users__c => 2
				}
			)
			.create()
			.getRecord();
        Triggers.switchOn();
    }

    @isTest
    static void createMethodPositive() {
        Opportunity currentOpportunity = getOpportunity();

        PageReference pageRef = Page.ApprovalBeforeCreateForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('OpportunityId', currentOpportunity.Id);
        ApprovalBeforeCreateController ctrl = new ApprovalBeforeCreateController();

        ctrl.ReasonForSharing = 'krible';
        ctrl.CustomerLocation = 'krable';
        ctrl.JustifyAndDescr = 'bums';

        Test.startTest();
        ctrl.create();
        Test.stopTest();

        Approval__c[] approvals = getApprovals();

        System.assert(approvals.size() > 0, 'At least one Approval__c should be created');
        System.assertEquals(ctrl.ReasonForSharing, approvals[0].Reason_for_Sharing__c, 'Reason for sharing values must be equal');
        System.assertEquals(ctrl.CustomerLocation, approvals[0].Customer_Location__c, 'Customer Location values must be equal');
        System.assertEquals(ctrl.JustifyAndDescr, approvals[0].JustificationandDescription__c, 'Justification and Description values must be equal');
        System.assertEquals(ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL, approvals[0].RecordTypeId, 'Approval was created with inappropriate record type ');

        ProcessInstance[] pi = [
            SELECT Id, Status
            FROM ProcessInstance
            WHERE TargetObjectId = :approvals[0].Id
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, pi.size(), 'Could not find started approval process!');
        System.assertEquals('Pending', pi[0].Status, 'Approval process in incorrect status');
    }

    @isTest
    static void createMethodNegative_RequiredFieldsNotFilled() {
        Opportunity currentOpportunity = getOpportunity();
        PageReference pageRef = Page.ApprovalBeforeCreateForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('OpportunityId', currentOpportunity.Id);
        ApprovalBeforeCreateController ctrl = new ApprovalBeforeCreateController();
        ctrl.create();
        Approval__c[] approvals = getApprovals();
        System.assertEquals(0, approvals.size(), 'Approval object should not be created');
    }

    @isTest
    static void createMethodNegative_OpportunityInvalid() {
        Opportunity currentOpportunity = getOpportunity();
        currentOpportunity.Forecasted_Users__c = null;
        update currentOpportunity;

        PageReference pageRef = Page.ApprovalBeforeCreateForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('OpportunityId', currentOpportunity.Id);
        ApprovalBeforeCreateController ctrl = new ApprovalBeforeCreateController();

        Test.startTest();

        ctrl.create();
        Approval__c[] approvals = getApprovals();

        System.assertEquals(0, approvals.size(), 'Approval object should not be created because of ' +
            'Opportunity.Forecasted_Users__c absence');

        currentOpportunity.Forecasted_Users__c = 2;
        update new sObject[]
        {
            currentOpportunity
        };

        ctrl.create();

        approvals = getApprovals();

        System.assertEquals(0, approvals.size(), 'Approval object should not be created because of ' +
            'Opportunity.Effective_No_of_Employees_Range__c absence');

        Test.stopTest();
    }

    @isTest
    static void createMethodNegative_DuplicateApproval() {
        Opportunity currentOpportunity = getOpportunity();

        PageReference pageRef = Page.ApprovalBeforeCreateForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('OpportunityId', currentOpportunity.Id);
        ApprovalBeforeCreateController ctrl = new ApprovalBeforeCreateController();

        ctrl.ReasonForSharing = 'krible';
        ctrl.CustomerLocation = 'krable';
        ctrl.JustifyAndDescr = 'bums';
        
        Test.startTest();
        ctrl.create();
        ctrl.create();
        Test.stopTest();

        Approval__c[] approvals = getApprovals();

        System.assertEquals(1, approvals.size(), 'Duplicate Approval__c should not be created');
    }

    static Approval__c[] getApprovals() {
        return [
            SELECT Reason_for_Sharing__c, Customer_Location__c, JustificationandDescription__c,
                RecordTypeId
            FROM Approval__c
        ];
    }

    static Opportunity getOpportunity() {
        return [SELECT Effective_No_of_Employees_Range__c, Forecasted_Users__c FROM Opportunity LIMIT 1];
    }
}