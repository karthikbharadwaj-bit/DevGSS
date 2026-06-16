@RestResource(UrlMapping='/PromotionService/*')
global with sharing class PromotionService {

    @HttpPost
    global static void promotion() {
        Response res = new Response();
        String result = '';
        String body = RestContext.request.requestBody.toString();

        BillingWrappers.Params paramsData = (BillingWrappers.Params)JSON.deserialize(body, BillingWrappers.Params.class);

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        try {
            if (paramsData.action == 'getQuotePromo') {
                List<Promotion__c> promotionList = getPromotion(paramsData.quoteId);
                res.setData('promotionList', promotionList);
            } else if (paramsData.action == 'deletePromo') {
                deletePromotions(paramsData);
            } else if (paramsData.action == 'createPromo') {
                res.setData('promotionList', insertPromotions(paramsData));
            }
        } catch(Exception e) {
            PlatformLog.logException('Promotions error: ', e);
        }

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
    }

    @TestVisible
    private static List<Promotion__c> getPromotion(String quoteId) {
        List<Promotion__c> promoList = (List<Promotion__c>) new PromotionSelector()
            .selectPromotionByQuoteId(new List<Object>{new Set<Id>{quoteId}})
            .executeQuery();
        return promoList;
    }

    @TestVisible
    private static List<Promotion__c> insertPromotions(BillingWrappers.Params params) {
        List<BillingWrappers.Promotion> promotionlist = params.promotionList;

        List<Promotion__c> promotionsToCreate = new List<Promotion__c>();
        for (BillingWrappers.Promotion promoWrapper : promotionlist) {
            Promotion__c promo =  new Promotion__c (
                Description__c = promoWrapper.description,
                Name = promoWrapper.name,
                Start_Date__c = promoWrapper.startDate != null ? Datetime.valueOfGmt(promoWrapper.startDate) : null,
                End_Date__c = promoWrapper.endDate != null ? Datetime.valueOfGmt(promoWrapper.endDate) : null,
                Discount_Templates__c = promoWrapper.discountTemplates,
                Promo_Code__c = promoWrapper.promoCode,
                Quote__c = promoWrapper.quoteId,
                Promo_Code_Id__c = promoWrapper.promoCodeId,
                Priority__c = promoWrapper.priority
            );
            promotionsToCreate.add(promo);
        }
        
        insert promotionsToCreate;
        return promotionsToCreate;
    }

    @TestVisible
    private static void deletePromotions(BillingWrappers.Params params) {
        List<BillingWrappers.Promotion> promotionlist = params.promotionList;

        List<Promotion__c> promotionsToDelete = new List<Promotion__c>();
        for (BillingWrappers.Promotion promoWrapper : promotionlist) {
            promotionsToDelete.add(new Promotion__c (Id = promoWrapper.id));
        }
        delete promotionsToDelete;
    }
}