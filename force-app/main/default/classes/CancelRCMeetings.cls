global with sharing class CancelRCMeetings {
    webService static String cancelMeetings(String params) {
        Map<String, String> paramsMap = (Map<String, String>) JSON.deserialize(params, Map<String, String>.class);
        String billingId = paramsMap.get('billingId');

        Map<String, String> result = new Map<String, String>();
        if (String.isBlank(billingId)) {
            result.put('status', 'error');
            result.put('header', 'An error occurred during RC Meetings cancellation');
            result.put('message', 'Account is not subscribed to RC Meetings');

            return JSON.serialize(result);
        }

        NGBS_Settings__c settings = NGBS_Settings__c.getInstance();
        if (settings == null || String.isBlank(settings.BaseEndpoint__c) || String.isBlank(settings.AccountManagerPath__c)) {
            result.put('status', 'error');
            result.put('header', 'An error occurred during RC Meetings cancellation');
            result.put('message', 'NGBS Settings\' BaseEndpoint not set');

            return JSON.serialize(result);
        }
        String accEndpoint = settings.BaseEndpoint__c + settings.AccountManagerPath__c + '/account/' + billingId;

        HttpResponse response;
        if (!Test.isRunningTest()) {
            response = NGBSAPI.requestNGBS(accEndpoint, HttpHelper.METHOD_GET);
        } else {
            response = new HttpResponse();
            response.setBody('{"packages":[{"id": 20001}]}');
            response.setStatusCode(200);
        }

        if (response.getStatusCode() != 200) {
            result.put('status', 'error');
            result.put('header', 'An error occurred during Billing API request');
            result.put('message', response.getStatus());

            return JSON.serialize(result);
        }
        BillingWrappers.NGBSAccount accInfo =
                (BillingWrappers.NGBSAccount) JSON.deserialize(
                        response.getBody(),
                        BillingWrappers.NGBSAccount.class
                );

        String billingEndpoint = accEndpoint + '/package/' + accInfo.packages.get(0).id + '/billinginfo';

        if (!Test.isRunningTest()) {
            response = NGBSAPI.requestNGBS(billingEndpoint, HttpHelper.METHOD_GET);
        } else {
            response = new HttpResponse();
            response.setBody(
                    '{"accountId":20001,"packageId":20001,"packageDescription":"RingCentral Fax1000","productLine":"RingCentral","previousBillingDate":null,"nextBillingDate":"2016-03-14T00:00Z[UTC]","packageProps":{},"creditBalance":0,"licenses":[{"licenseId":97001,"catalogId":"LC_SC_1","categoryId":"SC","description":"Subscription Fee","billingCycleDuration":"Monthly","qty":1,"price":24.99,"billingStartDate":"2016-03-14","billingEndDate":"2016-04-13","scheduledForRemoval":false,"replacement":null,"discount":null,"props":{},"searchCategories":{}},{"licenseId":98001,"catalogId":"LC_ALN_12","categoryId":"ALN","description":"Additional Local Number","billingCycleDuration":"Monthly","qty":1,"price":4.99,"billingStartDate":"2016-03-14","billingEndDate":"2016-04-13","scheduledForRemoval":false,"replacement":null,"discount":null,"props":{"phoneNumber":"16505551313"},"searchCategories":{}},{"licenseId":99001,"catalogId":"LC_ATN_13","categoryId":"ATN","description":"Additional Toll-Free Number","billingCycleDuration":"Monthly","qty":1,"price":4.99,"billingStartDate":"2016-03-14","billingEndDate":"2016-04-13","scheduledForRemoval":false,"replacement":null,"discount":null,"props":{"phoneNumber":"18005551414"},"searchCategories":{}}],"packageDuration":null,"packageExpirationDate":null}'
            );
            response.setStatusCode(200);
        }

        BillingWrappers.BillingInfo bInfo =
                (BillingWrappers.BillingInfo) JSON.deserialize(
                        response.getBody(),
                        BillingWrappers.BillingInfo.class
                );

        if (bInfo.licenses.size() == 0) {
            result.put('status', 'error');
            result.put('header', 'An error occurred during RC Meetings cancellation');
            result.put('message', 'Account is not subscribed to RC Meetings');

            return JSON.serialize(result);
        }

        try {
            String accId = paramsMap.get('accountId');
            Account acc = [
                    SELECT Id, Name, RC_Brand__c, CurrencyIsoCode, RC_Tier__c
                    FROM Account
                    WHERE Id = :accId
            ];
            Map<String, RecordTypeInfo> oppRtMapByName = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();

            Opportunity opp = new Opportunity();
            opp.AccountId = accId;
            opp.RecordTypeId = oppRtMapByName.get('Cancel Opportunity').getRecordTypeId();
            opp.Brand_Name__c = acc.RC_Brand__c;
            opp.CurrencyIsoCode = acc.CurrencyIsoCode;
            opp.Tier_Name__c = acc.RC_Tier__c;
            opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
            opp.Type = 'Existing Business';
            opp.CloseDate = System.today();
            opp.Name = acc.Name + ' rc meetings cancel';

            insert opp;

            Map<String, RecordTypeInfo> qtRtMapByName = Quote.SObjectType.getDescribe().getRecordTypeInfosByName();
            Quote qt = new Quote(
                    OpportunityId = opp.Id,
                    Account__c = accId,
                    Approval_Type__c = 'Sales Rep',
                    Approved_Status__c = 'Approved',
                    Start_Date__c = System.today(),
                    ExpirationDate = System.today(),
                    Initial_Term_months__c = '36',
                    Term_months__c = '36',
                    isPrimary__c = true,
                    isSalesAgreementExtension__c = false,
                    Name = 'Cancel Quote',
                    Pricebook2Id = Pricebook2Helper.getStandardPricebookId(),
                    QuoteType__c = 'Quote',
                    Status = 'Draft',
                    Upsell_Status__c = 'Upsell',
                    RecordTypeId = qtRtMapByName.get('Sales Quote v2').getRecordTypeId()
            );

            insert qt;

            BillingWrappers.Params serviceParams = new BillingWrappers.Params();
            serviceParams.quoteId = qt.Id;
            serviceParams.opportunityId = opp.Id;

            List<BillingWrappers.CartItem> items = new List<BillingWrappers.CartItem>();
            for (BillingWrappers.License lc : bInfo.licenses) {
                BillingWrappers.CartItem itm = new BillingWrappers.CartItem();
                itm.catalogId = lc.catalogId;
                itm.name = lc.description;
                itm.billingCycleDuration = lc.billingCycleDuration;
                itm.quantity = -lc.qty;
                itm.unitPrice = lc.price;
                itm.currencyIsoCode = acc.CurrencyIsoCode;
                itm.packageInfo = '{}'; // temporary
                itm.discount = 0;
                itm.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
                if (lc.discount != null) {
                    itm.discountType = lc.discount.value.unit == 'Money' ? QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
                    itm.discount = lc.discount.value.value;
                }

                items.add(itm);
            }

            List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();
            for (BillingWrappers.License lc : bInfo.licenses) {
                BillingWrappers.BillingProduct product = new BillingWrappers.BillingProduct();

                String goa = lc.labels != null ? lc.labels.GOA != null ? lc.labels.GOA : '' : '';

                product.catalogId = lc.catalogId;
                product.name = lc.description;
                product.currencyIsoCode = acc.CurrencyIsoCode;
                product.goa = goa;
                product.itemType = Product2Helper.PRODUCT_TYPE_BILLING_PRODUCT;
                product.categoryCode = lc.categoryId;

                products.add(product);
            }

            serviceParams.items = items;
            serviceParams.products = products;

            QuoteLineItemService.syncProducts(serviceParams.quoteId, serviceParams.products);
            QuoteLineItemService.insertQuoteLineItems(serviceParams.quoteId, serviceParams.items);

            result.put('status', 'success');
            result.put('header', 'RC Meetings has been cancelled');
            result.put('message', 'Redirecting to opportunity...');
            result.put('objectId', opp.Id);

            return JSON.serialize(result);
        } catch (Exception e) {
            result.put('status', 'error');
            result.put('header', 'An error occurred during RC Meetings cancellation');
            result.put('message', e.getMessage() + '<br/>' + e.getStackTraceString());

            return JSON.serialize(result);
        }
    }
}