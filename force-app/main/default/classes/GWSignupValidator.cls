@RestResource(urlMapping='/GWSignupValidator/*')
global with sharing class GWSignupValidator {

	@HttpGet
    global static void doGet() {
    	RestRequest req = RestContext.request;
    	RestResponse res = RestContext.response;
	    String oppId = req.params.get('oppId');
	    String userId = req.params.get('userId');
        String quoteId = req.params.get('serviceOrderId');
        GWSignUpWrapper wrapper;
        try {
	        SalesFunnelStatus__c salesFunnelStatus = getSalesFunnelStatus(oppId, userId, quoteId);
            wrapper = getGWSignUpWrapper(salesFunnelStatus);
            if (wrapper.requestStatus){
                salesFunnelStatus.IsRequestOpen__c = false;
                update salesFunnelStatus;
            }
	    } catch (exception e) {
	        wrapper = new GWSignUpWrapper(e.getMessage());
	    }

    	res.addHeader('Content-Type', 'application/json');
    	res.responseBody = blob.valueOf(JSON.serialize(wrapper));
    	return;
    }

    public static SalesFunnelStatus__c getSalesFunnelStatus(Id oppId, Id userId, Id quoteId) {
        SalesFunnelStatus__c salesFunnelStatus;

        //TODO when quoteId will be sent for all services need to rework
        if (quoteId != null) {
            salesFunnelStatus = (SalesFunnelStatus__c)new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusesForGWValidator(oppId, userId, quoteId)
                .executeQuery()
            ).getFirst();
        } else {
            List<String> filterCondition = new List<String> {
                QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,QuoteHelper.RC_EVENT_SERVICES_PRODUCT
            };
            salesFunnelStatus = (SalesFunnelStatus__c) new ListOptional( new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusesForGWValidatorByFilter(oppId, userId, filterCondition)
                .executeQuery()
            ).getFirst();
        }

        return salesFunnelStatus;
    }

    public static GWSignUpWrapper getGWSignUpWrapper(SalesFunnelStatus__c salesFunnelStatus) {
        GWSignUpWrapper wrapper;
        if (salesFunnelStatus != null) {
            wrapper = new GWSignUpWrapper(salesFunnelStatus);
        } else {
            wrapper = new GWSignUpWrapper();
            wrapper.isRequestValid = false;
            wrapper.requestStatus = false;
            wrapper.description = 'Invalid Parameters';
            wrapper.errorExists = false;
        }

        return wrapper;
    }
}