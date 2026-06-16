@isTest
public class Test_PartnerOperationsHelper {
	@isTest
	static void verifyPartnerScenarioIsCreatedAndIncompleted() {
		PartnerOperationsHelper.PartnerScenarioStep step  = new PartnerOperationsHelper.PartnerScenarioStep(
			'CREATE_WHOLESALE_OPPTY',
			'Create New Wholesale Opportunity',
			'You will be redirected to a new Opportunity Creation Page. ',
			'Create New Opportunity',
			1,
			false
		);

		PartnerOperationsHelper.PartnerScenario scenario = new PartnerOperationsHelper.PartnerScenario(
			new List<PartnerOperationsHelper.PartnerScenarioStep>{ step }
		);

		System.assertEquals(1, scenario.steps.size(), 'Scenario should have 1 step');
		System.assertEquals(false, scenario.isCompleted, 'Scenario shoulbe be incompleted');
	}

	@isTest
	static void verifyPartnerScenarioIsCreatedAndCompleted() {
		PartnerOperationsHelper.PartnerScenarioStep step  = new PartnerOperationsHelper.PartnerScenarioStep(
			'CREATE_WHOLESALE_OPPTY',
			'Create New Wholesale Opportunity',
			'You will be redirected to a new Opportunity Creation Page. ',
			'Create New Opportunity',
			1,
			true
		);

		PartnerOperationsHelper.PartnerScenario scenario = new PartnerOperationsHelper.PartnerScenario(
			new List<PartnerOperationsHelper.PartnerScenarioStep>{ step }
		);

		System.assertEquals(true, scenario.isCompleted, 'Scenario shoulbe be completed');
	}

	@isTest
	static void verifyPartnerOperationIsCreated() {
		Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
			.create()
            .getRecord();

		Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
			.create()
            .getRecord();


		PartnerOperationsLog__c partnerLog = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Account__c => account.Id,
                PartnerOperationsLog__c.Opportunity__c => opportunity.Id,
                PartnerOperationsLog__c.PartnerInfo__c => '{ "id":"456", "ngbsPartnerId": "123"}',
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .create()
            .getRecord();

		PartnerOperationsHelper.PartnerOperation operation = new PartnerOperationsHelper.PartnerOperation(partnerLog);

		System.assertEquals(partnerLog.Id, operation.id, 'Operation should be inserted');
		System.assertEquals(account.Id, operation.account, 'Operation should be created with Account\'s Id');
		System.assertEquals(opportunity.Id, operation.opportunity, 'Operation should be created with Opportunity\'s Id');
		System.assertEquals(false, operation.status, 'Operation should be created incompleted');

		PartnerOperationsHelper.PartnerInfo partnerInfo = (PartnerOperationsHelper.PartnerInfo)
            JSON.deserialize(partnerLog.PartnerInfo__c, PartnerOperationsHelper.PartnerInfo.class);

		System.assertEquals('456', partnerInfo.id, 'Partner Info should contain Partner Account\'s Id');
		System.assertEquals(
			123,
			Decimal.valueOf(partnerInfo.ngbsPartnerId),
			'Partner Info should contain Partner Account\'s NGBS Partner Id'
		);
	}
}