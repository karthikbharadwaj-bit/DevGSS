@isTest
public without sharing class Test_AccountsPayableChangeController {
	public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';
  	@testSetup
  	static void setup() {
		Triggers.switchOff();
		insert new RingCentralVariousSettings__c(
                            Director_BO_Invoice_Billing_Approver__c = DIRECTOR_BO_NAME,
                            Treasure_Manager_Invoice_Billing_Approve__c = TREASURE_MANAGER_NAME,
                            Treasurer_Invoice_Billing_Approve__c = TREASURER_NAME,
                            Controller_Invoice_Billing_Approver__c = CONTROLLER_NAME,
                            Controller_for_Invoice_Request__c  = INVOICE_CONTROLLER);
		Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
			.setField(Account.Name, 'TestAccount')
			.setField(Account.BillingStreet, 'Wall street')
			.setField(Account.BillingCity, 'NYC')
			.setField(Account.BillingState, 'NY')
			.setField(Account.BillingPostalCode, '123890')
			.setField(Account.BillingCountry, 'AUT')
			.setField(Account.TaxExemptionApprovals__c, true)
			.setField(Account.Current_Owner__c, UserInfo.getUserId())
			.create()
			.getRecord();

		Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
			.setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
			.setField(Contact.AccountId, testAccount.Id)
			.create()
			.getRecord();

		AccountContactRole payableContactRole = new AccountContactRole();
		payableContactRole.AccountId = testAccount.Id;
		payableContactRole.ContactId = contact.Id;
		payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
		insert payableContactRole;

		Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
				Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
				Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
				Opportunity.CloseDate => system.today().addMonths(1),
				Opportunity.AccountId => testAccount.Id})
			.create()
			.getRecord();
		Triggers.switchOn();
		Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
			.setField(Approval__c.Name, 'Invoice APC Change test')
			.setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICING_REQUEST)
			.setField(Approval__c.Account__c, testAccount.Id)
			.setField(Approval__c.Status__c, ApprovalHelper.STATUS_NEW)
			.setField(Approval__c.Contact__c, contact.Id)
			.setField(Approval__c.Opportunity__c, opp.Id)
			.setField(Approval__c.Invoice_Terms__c, '3')
			.setField(Approval__c.Payment_Terms__c, '7')
			.setField(Approval__c.Potential_Users__c, 1)
			.setField(Approval__c.Accounts_Payable_Email_Address__c, 'test@example.com')
			.setField(Approval__c.Reason_Customer_is_Requesting_Invoicing__c, 'Test')
			.setField(Approval__c.Why_RingCentral_Should_Invoice_Customer__c, 'Test')
			.setField(Approval__c.Initial_Number_of_Users__c, 1)
			.setField(Approval__c.Initial_Number_of_Devices__c, 1)
			.setField(Approval__c.Price_per_User__c, 1)
			.setField(Approval__c.Sign_Up_Purchase_Limit__c, 1)
			.setField(Approval__c.Monthly_Credit_Limit__c, 1)
			.setField(Approval__c.AccountPayableContact__c, contact.Id)
			.create()
			.getRecord();
  	}

	@isTest
	static void verifyNotApprovedRecordIsNotReturnedByGetApprovalInfo() {
		Approval__c approval  = getApproval();

		Test.startTest();
		Response approvalInfo = AccountsPayableChangeController.getApprovalInfo(approval.Id);

		System.assertEquals(Response.STATUS_ERROR, approvalInfo.status, 'status should be \'error\' on not approved record');
		System.assertEquals(
			'Approval must be approved first',
			approvalInfo.messages[0].messageDetails,
			'message should contain info about status'
		);
		Test.stopTest();
	}

	@isTest
	static void verifyApprovedRecordIsReturnedByGetApprovalInfo() {

		Test.startTest();
		Approval__c approval  = getApproval();

		approval.Status__c = ApprovalHelper.STATUS_APPROVED;
		Triggers.switchOff();
		update approval;
		Triggers.switchOn();

		Response approvalInfo = AccountsPayableChangeController.getApprovalInfo(approval.Id);

		System.assertEquals(Response.STATUS_SUCCESS, approvalInfo.status, 'status should be \'success\' on approved record');
		System.assertEquals(
			approval.OwnerId,
			((AccountsPayableChangeController.ApprovalInfoWrapper) approvalInfo.getData('approvalInfo'))?.ownerId,
			'approvalInfo should contain all required info'
		);
		Test.stopTest();
	}

	@isTest
	static void verifyRecordIsUnlockedByUnlockRecord() {
		Approval__c approval  = getApproval();

		Test.startTest();
        AccountsPayableChangeController.lockRecord(approval.Id);
		Response unlockResult = AccountsPayableChangeController.unlockRecord(approval.Id);
		Test.stopTest();

		System.assertEquals(Response.STATUS_SUCCESS, unlockResult.status, 'status should be \'success\' on unlocked record');
	}

	@isTest
	static void verifyRecordIsUpdatedByUpdateApproval() {
		Approval__c approval  = getApproval();

		AccountsPayableChangeController.ApprovalUpdateParams updateParams
			= new AccountsPayableChangeController.ApprovalUpdateParams();
		updateParams.recordId = approval.Id;
		updateParams.selectedAccountPayableId = approval.AccountPayableContact__c;

		Test.startTest();
		Response updateResult = AccountsPayableChangeController.updateApproval(JSON.serialize(updateParams));
		Test.stopTest();

		System.assertEquals(Response.STATUS_SUCCESS, updateResult.status, 'status should be \'success\' on updated record');

		approval = getApproval();
		System.assertEquals(
			ApprovalHelper.GOTOTHEFINALSTEP,
			approval.InvoiceApprovalType__c,
			'D&B Helper field should equal to ' + ApprovalHelper.GOTOTHEFINALSTEP
		);
	}

	@isTest
	static void verifyRecordIsSubmittedBySubmitRecord() {
		Approval__c approval  = getApproval();
        approval.Status__c = ApprovalHelper.STATUS_REQUIRED;
		approval.InvoiceApprovalType__c = ApprovalHelper.GOTOTHEFINALSTEP;
		Triggers.switchOff();
		update approval;
		Triggers.switchOn();

		AccountsPayableChangeController.SubmitApprovalParams submitParams
			= new AccountsPayableChangeController.SubmitApprovalParams();
		submitParams.recordId = approval.Id;
		submitParams.ownerId = approval.OwnerId;

		Test.startTest();
		Response submitResult = AccountsPayableChangeController.submitRecord(JSON.serialize(submitParams));
		Test.stopTest();

		System.assertEquals(Response.STATUS_SUCCESS, submitResult.status, 'status should be \'success\' on submitted record');

		approval = getApproval();
		System.assertEquals('PendingL1Approval', approval.Status__c, 'approval status should already pending');

		List<ProcessInstance> processInstances = (List<ProcessInstance>) new ProcessInstanceSelector()
			.selectProcessInstancesForApproval(new List<Object> { new List<Id>{ approval.Id } })
			.executeQuery();

		for (ProcessInstance p : processInstances) {
			System.debug(p);
		}
	}

	private static Approval__c getApproval() {
		return (Approval__c) new ApprovalSelector()
			.selectApprovals()
			.selectFields(
                new Set<SObjectField>{
                    Approval__c.OwnerId,
                    Approval__c.Account__c,
                    Approval__c.InvoiceApprovalType__c,
                    Approval__c.AccountPayableContact__c
                }
            )
            .setCondition('Accounts_Payable_Email_Address__c =\'test@example.com\'')
			.executeQuery()
			.get(0);
	}
}