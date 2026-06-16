/*
* Name         : Close Opportunity
* Created By   : Alexander Savickiy
* Created Date : 01/October/2018
* Description  : B-6207(Sprint 69 Moscow).
* Dependencies : No
*/

global class CloseOpportunity {
	/**
     * Method to process Close opportunity action
     * @param opportunityId - Opportunity id
     * @return serialized JSON with list of errors if they exist
     */
	webservice static String processData(Id opportunityId) {
		//List of possible errors
		List <ErrorWrapper> errorMessagesList = new List <ErrorWrapper>();
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        if (!featureToggle.Area_Codes_Check_On_Opportunity_Close__c) {
            return JSON.serialize(errorMessagesList);
        }

		if (opportunityId == null) {
			ErrorWrapper error = new ErrorWrapper('Opportunity Id is blank',
    			'Please provide opportunity Id');
			errorMessagesList.add(error);
			return JSON.serialize(errorMessagesList);
		}
        
		List<Quote> quoteList = [
			SELECT Id, (SELECT Id, Product2.Feature__c, Product2.Family, Zero_Quantity__c, NewQuantity__c, Quantity 
				FROM QuoteLineItems WHERE isDeleted = false)
        	FROM Quote
        	WHERE isPrimary__c = true
        	AND OpportunityId = :opportunityId
        ];

        if (quoteList.isEmpty()) {
        	ErrorWrapper error = new ErrorWrapper('No quotes',
    			'To close the opportunity, you must have at least 1 primary quote');
			errorMessagesList.add(error);
			return JSON.serialize(errorMessagesList);
        }

        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>();
        for (Quote qt : quoteList) {
        	for (QuoteLineItem qli : qt.QuoteLineItems) {
        		qliMap.put(qli.Id, qli);
        	}
        }

        if (qliMap.isEmpty()) {
        	ErrorWrapper error = new ErrorWrapper('0 items in the cart',
    			'To close the opportunity, you must have at least 1 item in the cart');
			errorMessagesList.add(error);
			return JSON.serialize(errorMessagesList);
        }

        List<Area_Code_Line_Item__c> areaCodeLineItemList = [
        	SELECT Id, Quote_Line_Item__c
        	FROM Area_Code_Line_Item__c
        	WHERE Quote_Line_Item__c IN :qliMap.keyset()
        ];

        Map<Id, List<Area_Code_Line_Item__c>> qliIdToAcliListMap = buildQliIdToAcliListMap(areaCodeLineItemList);

        for (QuoteLineItem qli : qliMap.values()) {

        	Boolean isGlobalOfficeLimitedExtensionProduct = (new Set<Decimal>{
        		Product2Helper.FEATURE_GLOBAL_OFFICE_LIMITED_EXTENSION,
        		Product2Helper.FEATURE_GLOBAL_OFFICE,
        		Product2Helper.FEATURE_LIMITED_EXTENSION}).contains(qli.Product2.Feature__c);

        	Boolean isAdditionalNumber = Product2Helper.FEATURE_ADDITIONAL_LOCAL_NUMBER == qli.Product2.Feature__c;
            Boolean isDiscountedPhone = qli.Product2.Family == Product2Helper.FAMILY_DISCOUNTED_PHONES;
        	Boolean isRefurbishedPhone = qli.Product2.Family == Product2Helper.FAMILY_REFURBISHED_PHONES;

        	if (!isGlobalOfficeLimitedExtensionProduct
        		&& (isAdditionalNumber || isDiscountedPhone || isRefurbishedPhone)
                && !qli.Zero_Quantity__c
                && qli.Quantity > 0
                && qli.NewQuantity__c != 0
        		&& qliIdToAcliListMap.get(qli.Id) == null) {

    			ErrorWrapper error = new ErrorWrapper('You can\'t Close this Opportunity',
    				'Area Codes are missing. Please select Area Codes for all Discounted or Refurbished Phones and all Additional Numbers on the Primary Quote');
				errorMessagesList.add(error);
				return JSON.serialize(errorMessagesList);
        	}
        }

		return JSON.serialize(errorMessagesList);
	}

	private static Map<Id, List<Area_Code_Line_Item__c>> buildQliIdToAcliListMap (List<Area_Code_Line_Item__c> acliList) {
		Map<Id, List<Area_Code_Line_Item__c>> qliIdToAcliListMap = new Map<Id, List<Area_Code_Line_Item__c>>();

		for (Area_Code_Line_Item__c acli : acliList) {
			if (!qliIdToAcliListMap.containsKey(acli.Quote_Line_Item__c)) {
				qliIdToAcliListMap.put(acli.Quote_Line_Item__c, new List<Area_Code_Line_Item__c>());
			}
			qliIdToAcliListMap.get(acli.Quote_Line_Item__c).add(acli);
		}
		return qliIdToAcliListMap;
	}

	public class ErrorWrapper {
		public String header;
		public string message;

		public ErrorWrapper (String header, String message) {
			this.header = header;
			this.message = message;
		}
	}


}