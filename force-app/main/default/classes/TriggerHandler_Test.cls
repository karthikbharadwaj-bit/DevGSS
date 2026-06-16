@isTest
private class TriggerHandler_Test {
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testUseCases(){
        
		TriggerHandler.HIDE_VALIDATION_ERROR_ON_IMPLEMENTATION();
        TriggerHandler.BY_PASS_CARRIERDATA_ON_INSERT();
        TriggerHandler.BY_PASS_CARRIERDATA_ON_UPDATE();        
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
		TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
		TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT();
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();        
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_CONVERT();
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT();
        TriggerHandler.BY_PASS_CASE_ON_UPDATE();
        TriggerHandler.BY_PASS_CASE_ON_INSERT();
        TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE();
        TriggerHandler.BY_PASS_LINEITEM_ON_INSERT();
        TriggerHandler.BY_PASS_RCQUOTE_ON_UPDATE();
        TriggerHandler.BY_PASS_RCQUOTE_ON_INSERT();
        TriggerHandler.BY_PASS_EVENT_ON_INSERT();
		TriggerHandler.BY_PASS_EVENT_ON_UPDATE();
		TriggerHandler.BY_PASS_CASECOMMENT_ON_UPDATE();
		TriggerHandler.BY_PASS_CASECOMMENT_ON_INSERT();
		TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE();
		TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT();
        TriggerHandler.ALLOW_TRIGGER_REQUEST_ONCE();
        TriggerHandler.RESET_VARIABLES();
        
        List<String> byPassNames = new List<String>();
        byPassNames.add('BY_PASS_BEFORE');
        byPassNames.add('BY_PASS_AFTER');
        byPassNames.add('BY_PASS_ACCOUNT_ON_AFTER');
		byPassNames.add('BY_PASS_ACCOUNT_ON_BEFORE');
		byPassNames.add('BY_PASS_IMPLEMENTATION_ON_AFTER');
		byPassNames.add('BY_PASS_IMPLEMENTATION_ON_BEFORE');
		byPassNames.add('BY_PASS_EVENT_ON_BEFORE');
		byPassNames.add('BY_PASS_EVENT_ON_AFTER');
		byPassNames.add('BY_PASS_PARTNER_ACCOUNT_ON_AFTER');
		byPassNames.add('BY_PASS_PARTNER_ACCOUNT_ON_BEFORE');
		byPassNames.add('BY_PASS_CONTACT_ON_AFTER');
		byPassNames.add('BY_PASS_CONTACT_ON_BEFORE');
		byPassNames.add('BY_PASS_ACCOUNT_ON_UPDATE');
		byPassNames.add('BY_PASS_ACCOUNT_ON_INSERT');
		byPassNames.add('BY_PASS_CONTACT_ON_UPDATE');
		byPassNames.add('BY_PASS_CONTACT_ON_INSERT');
		byPassNames.add('BY_PASS_OPPORTUNITY_ON_UPDATE');
		byPassNames.add('BY_PASS_OPPORTUNITY_ON_INSERT');
		byPassNames.add('BY_PASS_OPPORTUNITY_ON_CONVERT');
		byPassNames.add('BY_PASS_QUOTE_ON_CONVERT');
		byPassNames.add('BY_PASS_CASE_ON_UPDATE');
		byPassNames.add('BY_PASS_CASE_ON_INSERT');
		byPassNames.add('BY_PASS_LINEITEM_ON_INSERT');
		byPassNames.add('BY_PASS_LINEITEM_ON_UPDATE');
		byPassNames.add('BY_PASS_LINEITEM_ON_INSERT');
		byPassNames.add('BY_PASS_RCQUOTE_ON_UPDATE');
		byPassNames.add('BY_PASS_RCQUOTE_ON_INSERT');
		byPassNames.add('BY_PASS_Approver_Trigger');
		byPassNames.add('ALLOW_TRIGGER_REQUEST_ONCE');
		byPassNames.add('BY_PASS_CARRIERDATA_ON_INSERT');
		byPassNames.add('BY_PASS_CARRIERDATA_ON_UPDATE');
		byPassNames.add('BY_PASS_CASE_Trigger');
		byPassNames.add('UPDATE_CONTACT_BMID');
		byPassNames.add('BY_PASS_LEAD_UPDATE');
		byPassNames.add('BY_PASS_CASECOMMENT_ON_UPDATE');
		byPassNames.add('BY_PASS_CASECOMMENT_ON_INSERT');
		byPassNames.add('BY_PASS_PARTNERCOMM_ON_UPDATE');
		byPassNames.add('BY_PASS_PARTNERCOMM_ON_INSERT');
		byPassNames.add('BY_PASS_EVENT_ON_INSERT');
		byPassNames.add('BY_PASS_EVENT_ON_UPDATE');
		byPassNames.add('BY_PASS_TOTAL_ESTIMATE_CALCULATION');
        
        TriggerHandler.bypassTrigger(byPassNames, true);              
        
	}
}