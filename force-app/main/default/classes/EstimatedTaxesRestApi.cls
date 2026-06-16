@RestResource(urlMapping='/EstimatedTaxesRestApi')
global with sharing class EstimatedTaxesRestApi {

    /*
    Using: POST message to /services/apexrest/EstimatedTaxesRestApi with body {"quoteId":"...."}
    Returns blank obj with 3 nulls if errors and full estimatedTaxesDTO if all ok
    */

    public class DeviceDTO {
        public String billingPlanDuration;
        public String city;
        public Integer deviceTypeId;
        public Integer dlFeatureType;
        public Integer featureType;
        public Integer idBrand;
        public Integer idTier;
        public Integer quantity;
        public Integer sidecarCount;
        public String state;
        public String zipCode;
    }

    public class FeatureDTO {
        public String billingPlanDuration;
        public String city;
        public String featureDescription;
        public String featureName;
        public Integer featureType;
        public Integer idBrand;
        public Integer idTier;
        public Decimal price;
        public Integer quantity;
        public String state;
        public String zipCode;
    }

    public class billingPricesAndChargesRequestDTO {
        public Integer tierId;
        public List<EstimatedTaxesRestApi.DeviceDTO> devicesList;
        public List<EstimatedTaxesRestApi.FeatureDTO> featuresList;

    }

    public class estimatedTaxesDTO {
        public FlexibleDiscountRestApi.ApprovalWrapper flexibleDiscountItems;
        public Boolean taxExempt;
        public billingPricesAndChargesRequestDTO billingPricesAndChargesRequest;
    }

    public class estimatedTaxesWrapper{

        public estimatedTaxesDTO getEstimatedTaxesDTO(String quoteIdString) {
            estimatedTaxesDTO estTaxDto = new estimatedTaxesDTO();
            billingPricesAndChargesRequestDTO bilingPrChDto = new billingPricesAndChargesRequestDTO();
            List<DeviceDTO> devicesList = new List<DeviceDTO>();
            List<FeatureDTO> featuresList = new List<FeatureDTO>();
            Quote quote;
            Id quoteId;
            try {
                quoteId = Id.valueOf(quoteIdString);
                quote = [SELECT QuoteNumber, OpportunityId, Pricebook2.Tier_ID__c, Pricebook2.Plan__c, Pricebook2.Name,
                        Pricebook2.Brand__r.Brand_Id__c, Account.Tax_Exempt__c,
                        Account.BillingCity, Account.BillingState, Account.BillingPostalCode,
                        Account.RC_User_ID__c
                FROM Quote WHERE Id = :quoteId];
            } catch (Exception ex) {
                return new EstimatedTaxesDTO();
            }

            List<QuoteLineItem> qliList = [SELECT Id, Quantity, ListPrice, Product2.Family, Product2.Name, Product2.Feature__c,
                                            Product2.Sub_Feature__c, Product2.Description, Product2.SideCarCount__c
                                            FROM QuoteLineItem WHERE QuoteId = :quoteId];

            if (qliList.size()>0) {
                Integer dlFeatureType;
                for (QuoteLineItem qli : qliList) {
                    if (qli.Product2.Family.equals('Discounted Phones') || qli.Product2.Family.equals('Refurbished Phones') || qli.Product2.Family.equals('Rental Phones')) {
                        DeviceDTO device = new DeviceDTO();
                        device.billingPlanDuration = Quote.Pricebook2.Plan__c;
                        device.city = quote.Account.BillingCity;
                        device.deviceTypeId = Integer.valueOf(qli.Product2.Sub_Feature__c);
                        device.featureType = Integer.valueOf(qli.Product2.Feature__c);
                        device.idTier = Integer.valueOf(quote.Pricebook2.Tier_ID__c);
                        device.idBrand = Integer.valueOf(quote.Pricebook2.Brand__r.Brand_Id__c);
                        device.quantity = Integer.valueOf(qli.Quantity);
                        device.sidecarCount = Integer.valueOf(qli.Product2.SideCarCount__c);
                        device.state = quote.Account.BillingState;
                        device.zipCode = quote.Account.BillingPostalCode;

                        devicesList.add(device);
                    } else {
                        FeatureDTO feature = new FeatureDTO();
                        feature.billingPlanDuration = Quote.Pricebook2.Plan__c;
                        feature.city = quote.Account.BillingCity;
                        feature.featureDescription = qli.Product2.Description;
                        feature.featureName = qli.Product2.Name;
                        feature.featureType = Integer.valueOf(qli.Product2.Feature__c);
                        feature.idBrand = Integer.valueOf(quote.Pricebook2.Brand__r.Brand_Id__c);
                        feature.idTier = Integer.valueOf(quote.Pricebook2.Tier_ID__c);
                        feature.price = qli.ListPrice;
                        feature.quantity = Integer.valueOf(qli.Quantity);
                        feature.state = quote.Account.BillingState;
                        feature.zipCode = quote.Account.BillingPostalCode;

                        featuresList.add(feature);

                        if (qli.Product2.Family == 'Service') {
                            dlFeatureType = Integer.valueOf(qli.Product2.Feature__c);
                        }
                    }
                }
                if ((dlFeatureType != null) && devicesList.size() > 0) {
                    for (DeviceDTO device : devicesList) {
                        device.dlFeatureType = dlFeatureType;
                    }
                }
            }

            bilingPrChDto.tierId = Integer.valueOf(quote.Pricebook2.Tier_ID__c);
            bilingPrChDto.devicesList = devicesList;
            bilingPrChDto.featuresList = featuresList;

            FlexibleDiscountRestApi.ApprovalWrapper flexWrapper = new FlexibleDiscountRestApi.ApprovalWrapper();
            String rcUserId = String.valueOf(quote.Account.RC_User_ID__c);
            String approvalQuoteNumber = String.valueOf(quote.QuoteNumber);
            String tierIdString = String.valueOf(bilingPrChDto.tierId);
            String oppId = String.valueOf(quote.OpportunityId);
            flexWrapper = flexWrapper.generateJson(rcUserId, approvalQuoteNumber, tierIdString, oppId);

            estTaxDto.taxExempt = quote.Account.Tax_Exempt__c;
            estTaxDto.flexibleDiscountItems = flexWrapper;
            estTaxDto.billingPricesAndChargesRequest = bilingPrChDto;

            return estTaxDto;
        }
    }

    public class requestParams {
        public String quoteId;
    }

    @HttpPost
    global static void getEstimatedTaxes() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String requestBody = req.requestBody.toString();
        requestParams reqPar = (requestParams)JSON.deserialize(requestBody, requestParams.class);

        EstimatedTaxesRestApi.estimatedTaxesWrapper wrapper = new EstimatedTaxesRestApi.estimatedTaxesWrapper();
        EstimatedTaxesRestApi.estimatedTaxesDTO resultDto = wrapper.getEstimatedTaxesDTO(reqPar.quoteId);

        res.responseBody = blob.valueOf(JSON.serialize(resultDto));
        res.addHeader('Content-Type', 'application/json');

        return;
    }
}