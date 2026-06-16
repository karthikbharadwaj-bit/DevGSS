@RestResource(urlMapping='/SignUpAccountWsBilling/*')
global class SignUpAccountWsBilling {
    public static final String STATUS_COMPLETED = 'COMPLETED';

    @HttpPut
    global static void handleFunnelSignUpResponse() {
        String body = RestContext.request.requestBody.toString();
        system.debug('body: ' + body);
        FunnelAPI.CallbackServiceBuilder callback = new FunnelAPI.CallbackServiceBuilder(body);
        String chatterMessage;
        system.debug('callback: ' + callback);
        String oppId = callback.oppId;
        Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectBillingOpportunity('Id = \'' + oppId + '\'')
                .selectFields(new List<String> {
                    'Account.Internal_Enterprise_Account_ID__c',
                    'Account.Id',
                    'OwnerId',
                    'MasterOpportunity__c',
                    'MasterOpportunity__r.OwnerId',
                    'MasterOpportunity__r.Id',
                    'isMultiproductTechnicalOpportunity__c',
                    'Tier_Name__c'
                })
                .executeQuery()
                .get(0);

        Account acc = opp.Account;
        acc.Internal_Enterprise_Account_ID__c = null;

        if (callback.orderStatus == STATUS_COMPLETED) {
            acc.Billing_ID__c = callback.billingId;
            if (String.isNotBlank(callback.enterpriseAccountId)) {
                acc.RC_User_ID__c = callback.enterpriseAccountId;
            }
            chatterMessage = getChatterMessage(callback.serviceName);
            System.enqueueJob(new ProcessBillingPackageSync(oppId, acc.Id, callback.billingId, callback.billingPackageId));
        } else if (callback.errorMessage != null) {
            chatterMessage = callback.errorMessage;
        }

        Opportunity oppToNotify = OpportunityHelper.getMasterOpportunity(opp);
        ChatterHelper.createChatterPost(oppToNotify.OwnerId, oppToNotify.Id, chatterMessage);
        update acc;
    }

    public static String getChatterMessage(String serviceName) {
        //String serviceName = opp.Tier_Name__c == OpportunityHelper.TIER_OFFICE ? OpportunityHelper.TIER_MVP : opp.Tier_Name__c;''
        String message = '{0} account has been created and activated for customer';
        if (serviceName == 'MVP') {
            return String.format(Label.FunnelResponseSuccessMessage, new List<String>{ serviceName });
        } else {
            return String.format(message, new List<String>{ serviceName });
        }  
    }
}