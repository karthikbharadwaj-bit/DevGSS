/*
* Name         : StartBilling
* Created By   : Alexander savickiy 
* Created Date : 29/March/2018
* Description  : B-4314 (Sprint 56 Moscow). 
* Dependencies : No
*/

global class StartBilling {

	/**
     * Method to process Approval creation/OrderItem fields update
     * @param orderItemId - OrderItem id
     * @return serialized JSON with list of errors if they exist
     */
	webservice static String processData(Id orderItemId) {
		OrderItem oiRecord = [SELECT Id, Billing_Start_Date__c, Quantity, TotalPrice,
									PriceBookEntry.Product2.Charge_Term__c, PriceBookEntry.Product2.Name,
									OrderId, Order.OpportunityId, PriceBookEntry.Product2.Sub_Category__c,
									Order.AccountId
								FROM OrderItem 
								WHERE Id =: orderItemId];
		//List of possible errors						
		List <String> errorMessages = new List <String>();

		//Check if user has custom permissions to start billing
		CustomPermissionHelper customhelper = new CustomPermissionHelper();
		if(!customhelper.hasPermission(CustomPermissionHelper.PERMISSION_START_BILLING)) {
			errorMessages.add('You do not have permission to Start Billing for recurring ProServ Products');
			return JSON.serialize(errorMessages);
		}
		if(oiRecord.Billing_Start_Date__c != null) {
			errorMessages.add('Billing was already enabled for this product');
		}
		if(oiRecord.PriceBookEntry.Product2.Charge_Term__c == 'One - Time') {
			errorMessages.add('Manual Billing is not needed for One - Time Products');
		}
		if(!(oiRecord.PriceBookEntry.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_PROSERV 
			|| oiRecord.PriceBookEntry.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CC_PROSERV)) {
			errorMessages.add('Manual billing start is required for recurring Professional Services Products only');
		}

		//Process data
		if(errorMessages.isEmpty()) {
			updateOrderItemFields(oiRecord);
			createApproval(oiRecord);
		} 
		return JSON.serialize(errorMessages);
	}
	@TestVisible
	private static void updateOrderItemFields(OrderItem oiRecord) {
		oiRecord.Billing_Start_Date__c = System.now();
		update oiRecord;
	}
@TestVisible
	private static void createApproval(OrderItem oiRecord) {
		Approval__c approvalToCreate = new Approval__c();
		approvalToCreate.Opportunity__c = oiRecord.Order.OpportunityId;
		approvalToCreate.recordTypeId = ApprovalHelper.RT_ID_FEATURE_ADD_ONS_APPROVAL;
		approvalToCreate.Proserv_Billing_Start__c = true;
		approvalToCreate.Account__c = oiRecord.Order.AccountId;

		String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
		approvalToCreate.AdditionalFeatures__c = 'Product Name: ' + oiRecord.PriceBookEntry.Product2.Name + ' \r\n'
												+ 'Quanitity: ' + oiRecord.Quantity + ' \r\n'
												+ 'Total Price: ' + oiRecord.TotalPrice + ' \r\n'
												+ 'Order: ' + baseUrl + '/' + oiRecord.OrderId;
		insert approvalToCreate;
		submitForApproval(approvalToCreate);
	}

	private static void submitForApproval (Approval__c appr) {
		Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
		request.setObjectId(appr.Id);
		request.setProcessDefinitionNameOrId('Approval_Process_for_Addit_l_FeaturesV7');
		Approval.ProcessResult apprvalProcessResult = Approval.process(request);
	}
}