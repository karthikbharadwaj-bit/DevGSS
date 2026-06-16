/*
    B-491 Taxes should be added into Quote on request
 */

public class EstimatedTaxesHandler {

    public static String localTaxesExtId = 'STATE_AND_LOCAL_TAXES_AND_FEES';
    public static String federalTaxesExtId = 'FEDERAL_UNIVERSAL_SERVICE_FUND';
    public static String vatTaxesExtId = 'VALUE_ADDED_TAX';
    public static String gstTaxesExtId = 'GOODS_AND_SERVICES_TAX';
    public final static String VARIABLE_TAXES = 'VARIABLE';
    public final static String FIXED_TAXES = 'FIXED';
    public final static String E911 = 'E911_SERVICE_FEE';
    public final static String CRF = 'COMPLIANCE_AND_ADMINISTRATIVE_COST_RECOVERY_FEE';

    public static Map<Integer, QuoteLineItem> billingIdToQli = new Map<Integer, QuoteLineItem>();
    public static Boolean qliTaxesRemoved = false;
    public static Boolean byPassQliUpdate = false;
    public static Map<Id, QuoteLineItem> quoteLineItemMapStatic = new Map<Id, QuoteLineItem>();
    public static Set<String> allTaxesIds = new Set<String> {
        localTaxesExtId, federalTaxesExtId,
        vatTaxesExtId, gstTaxesExtId
    };

    public static final String endpointUrl = EstimatedTaxesLinkSetting__c.getOrgDefaults().EstimatedTaxesLink__c;

    public messageDTO estimateTaxesAndAddQli(Id quoteId) {
        EstimatedTaxesHandlerHelper estTaxesHelper = new EstimatedTaxesHandlerHelper();
        EstimatedTaxesHandler.estimatedTaxesWrapper estTaxeswrapper = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO estTaxesDto = estTaxeswrapper.getEstimatedTaxesDTO(quoteId);
        String requestBody = JSON.serialize(estTaxesDto);
        messageDTO jsonDto;

        if (estTaxeswrapper.messageDto.status != 200) {
            return estTaxeswrapper.messageDto;
        }

        HttpRequest totalRequest = HttpHelper.prepareHttpRequest(endpointUrl, HttpHelper.METHOD_POST, requestBody);
        HttpResponse totalResponse = new Http().send(totalRequest);

        HttpResponse existingResponse = estTaxesHelper.prepareExistingRequest(estTaxesDto, estTaxesHelper);
        Map<String, Map<String, Decimal>> existingTaxes = estTaxesHelper.prepareTaxesAmount(existingResponse, estTaxesHelper);

        jsonDto = estTaxesHelper.processRespondMappingAndQliAdding(quoteId, totalResponse.getBody(), existingTaxes);

        return jsonDto;
    }

    public class EstimatedTaxesHandlerHelper {

        public responseEstimatedTaxesDTO responseMapping(String strBody) {
            responseEstimatedTaxesDTO mappedRespEstTaxDto;
            System.debug('##! Response estimated taxes from GW = ' + strBody);
            try {
                mappedRespEstTaxDto = (responseEstimatedTaxesDTO)JSON.deserialize(strBody, responseEstimatedTaxesDTO.class);
            } catch (exception e) {
                System.debug('##! Exeption occurs in mapping responseEstimatedTaxesDTO');
                System.debug(e.getMessage());
            }
            return mappedRespEstTaxDto;
        }

        public messageDTO processRespondMappingAndQliAdding(Id quoteId, String responseBody, Map<String, Map<String, Decimal>> existingTaxes) {
            EstimatedTaxesHandler.messageDTO msgDto = new EstimatedTaxesHandler.messageDTO();
            //Replace reserved apex words
            responseBody = responseBody.replace('"type":', '"taxDetailsType":');
            responseEstimatedTaxesDTO respEstTaxDto = responseMapping(responseBody);
            if (respEstTaxDto != null) {
                if (respEstTaxDto.status.success) {
                    Map<String, Map<String, Decimal>> sumTaxes = new Map<String, Map<String, Decimal>>();
                    if ((respEstTaxDto.result.billingItems != null) && (respEstTaxDto.result.billingItems.size() > 0)) {
                        for (billingItemDTO billItem : respEstTaxDto.result.billingItems) {
                            //add new
                            Boolean add = false;
                            String plan;
                            if (Test.isRunningTest()){
                                plan = 'One - Time';
                            } else {
                                plan = billingIdToQli.get(billItem.billingItemId).Product2.Charge_Term__c;
                            }
                            Decimal localTaxes = 0;
                            Decimal federalTaxesExt = 0;
                            Decimal variableTaxesAmount = 0;
                            Decimal fixedTaxesAmount = 0;
                            Map<String, Decimal> ppTaxes = sumTaxes.containsKey(plan) ? sumTaxes.get(plan) : new Map<String, Decimal>();
                            if ((billItem.taxDetails != null) && (billItem.taxDetails.size() > 0)) {
                                for (taxDetailDTO taxDetail : billItem.taxDetails) {
                                    if (taxDetail.availableOnBrand) {
                                        if (taxDetail.descriptionId.equals(localTaxesExtId) || taxDetail.descriptionId.equals(federalTaxesExtId) || taxDetail.descriptionId.equals(vatTaxesExtId) || taxDetail.descriptionId.equals(gstTaxesExtId)){

                                            localTaxes += calculateLocalFederalTaxes(taxDetail, localTaxesExtId);
                                            federalTaxesExt += calculateLocalFederalTaxes(taxDetail, federalTaxesExtId);

                                            add = calculateTaxesAmount(taxDetail, ppTaxes);
                                        }
                                        Map <String, Decimal> taxesAmountMap = calculateVariableFixedTaxes(taxDetail);
                                        variableTaxesAmount += taxesAmountMap.get('amountVariable');
                                        fixedTaxesAmount += taxesAmountMap.get('amountFixed');
                                    }
                                }
                            }
                            if (add) {
                                sumTaxes.put(plan, ppTaxes);
                            }
                            //Populate quote line item fields
                            if (billingIdToQli.get(billItem.billingItemId) != null) {

                                billingIdToQli.get(billItem.billingItemId).Taxes__c = localTaxes + federalTaxesExt;
                                billingIdToQli.get(billItem.billingItemId).Variable_Taxes_Amount__c = variableTaxesAmount;
                                billingIdToQli.get(billItem.billingItemId).Fixed_Taxes_Amount__c = fixedTaxesAmount;

                                quoteLineItemMapStatic.put(billingIdToQli.get(billItem.billingItemId).Id,billingIdToQli.get(billItem.billingItemId));
                            }
                        }
                        //Update quote line items
                        if (!quoteLineItemMapStatic.isEmpty()) {
                            // Totals on Opportunity doesn't fire on quote line item update
                            // but quote line item update fires quote update, that fires updating opportunity - so we bypass that update.
                            // because in addTaxesQliToQuoteAndReturnMessageDto method new "taxes" quote line items will be inserted
                            // and totals on opportunity will be recalculated
                            OpportunityTotals.bypassOpportnuityUpdate = true;
                            update quoteLineItemMapStatic.values();
                            OpportunityTotals.bypassOpportnuityUpdate = false;
                        }
                    }
                    if (sumTaxes.keySet().size() > 0) {
                        for (String key : sumTaxes.keySet()) {
                            System.debug('##! sumTaxes key: '+ key + ', value = ' + sumTaxes.get(key));
                        }
                        msgDto = addTaxesQliToQuoteAndReturnMessageDto(quoteId, sumTaxes, existingTaxes);
                        return msgDto;
                    } else {
                        msgDto.status = 201;
                        msgDto.message = 'No taxes need to be added';
                    }
                } else {
                    msgDto.message = 'Status is not success';
                    msgDto.status = 500;
                }
            } else {
                msgDto.message = 'Response is not correct';
                msgDto.status = 503;
            }
            return msgDto;
        }

        public Double calculateLocalFederalTaxes(taxDetailDTO taxDetail, String taxesType) {
            Double taxAmount = taxDetail.descriptionId.equals(taxesType)
                            ? (taxDetail.amount != null ? taxDetail.amount : 0)
                            : 0;
            return taxAmount;
        }

        public Map <String, Decimal> calculateVariableFixedTaxes(taxDetailDTO taxDetail) {
            Map <String, Decimal> result = new Map <String, Decimal>{
                'amountVariable' => 0,
                'amountFixed' => 0
            };
            //Ignore E911 and CRF items
            if ((new Set<String>{E911, CRF}).contains(taxDetail.descriptionId)) {
                return result;
            }

            if(taxDetail.amountFixed != null && taxDetail.amountVariable != null) {
                result.put('amountVariable', taxDetail.amountVariable);
                result.put('amountFixed', taxDetail.amountFixed);

            } else {
                Decimal variableTaxes = taxDetail.taxDetailsType == VARIABLE_TAXES
                                        ? taxDetail.amount
                                        : 0;
                Decimal fixedTaxesAmount = taxDetail.taxDetailsType == FIXED_TAXES
                                        ? taxDetail.amount
                                        : 0;
                result.put('amountVariable', variableTaxes);
                result.put('amountFixed', fixedTaxesAmount);

            }
            return result;
        }

        public messageDTO addTaxesQliToQuoteAndReturnMessageDto(Id quoteId, 
                                                                Map<String, Map<String,Decimal>> sumTaxes, 
                                                                Map<String, Map<String,Decimal>> existingTaxes) {
            messageDTO successMessage = new messageDTO(200, 'OK');
            if (!qliTaxesRemoved) {
                byPassQliUpdate = true;
                qliTaxesRemoved = EstimatedTaxesHandler.removeTaxesQli(quoteId);
            }
            Map<String, String> taxExtIdToProductName = new Map<String, String>();
            taxExtIdToProductName.put('State and local taxes and fees', localTaxesExtId);
            taxExtIdToProductName.put('Federal Universal Service Fund', federalTaxesExtId);
            taxExtIdToProductName.put('Value Added Tax', vatTaxesExtId);
            taxExtIdToProductName.put('Goods and services tax', gstTaxesExtId);

            //Case 05484691 "Not calculating taxes on service" https://rc.my.salesforce.com/5003400000uZPcn
            //As discussed with Stanislav Scherbakov - products with Monthly - Contract category should have taxes with "Monthly" category.
            if (sumTaxes.containsKey('Monthly - Contract')) {
                if (sumTaxes.get('Monthly') == null) {
                    sumTaxes.put('Monthly', new Map<String, Decimal>());
                }

                Map<String, Decimal> taxesForMonthlContr = sumTaxes.get('Monthly - Contract');

                for (String taxName : taxesForMonthlContr.keySet()) {
                    Decimal monthlySum = (sumTaxes.get('Monthly').get(taxName) == null) ? 0 : sumTaxes.get('Monthly').get(taxName);
                    Decimal monthlyContrSum = taxesForMonthlContr.get(taxName);
                    sumTaxes.get('Monthly').put(taxName, monthlyContrSum + monthlySum);
                }
            }


            if (sumTaxes.keySet().size() == 0) {
                messageDTO msg = new messageDTO(500, 'Map size is zero');
                System.debug(msg.message);
                return msg;
            }
            try {
                Quote quote = [SELECT Pricebook2Id FROM Quote WHERE Id=:quoteId LIMIT 1];
                List<PricebookEntry>pbeList = [SELECT Id, Product2Id, Product2.Name, Product2.Charge_Term__c
                                                FROM PricebookEntry
                                                WHERE Pricebook2Id = :quote.Pricebook2Id
                                                AND Product2.Family = 'Taxes'
                                                AND Product2.Charge_Term__c IN :sumTaxes.keySet()];
                System.debug('##! pbeList size ' + String.valueOf(pbeList.size()));
                List<QuoteLineItem> qliList = new List<QuoteLineItem>();
                for (PricebookEntry pbe : pbeList) {
                    // can be one Tax, should add qli only for contained taxes in map
                    System.debug('##! pbeId ' + String.valueOf(pbe.Id));
                    Map<String, Decimal> taxMapForPlan = sumTaxes.get(pbe.Product2.Charge_Term__c);
                    if (taxMapForPlan.containsKey(taxExtIdToProductName.get(pbe.Product2.Name))) {
                        //Calculate difference between paid and new taxes amounts
                        Decimal existingAmount = 0;

                        if (existingTaxes != null) {
                            if (!existingTaxes.isEmpty()) {
                                if (existingTaxes.containsKey(pbe.Product2.Charge_Term__c)) {
                                    String taxExtId = taxExtIdToProductName.get(pbe.Product2.Name);
                                    existingAmount = existingTaxes.get(pbe.Product2.Charge_Term__c).get(taxExtId);
                                }
                            } else {
                                successMessage.existingTaxesStatus = 300;
                            }
                        }
                        qliList.add(new QuoteLineItem(
                            Description = pbe.Product2.Name,
                            UnitPrice = taxMapForPlan.get(taxExtIdToProductName.get(pbe.Product2.Name)) - existingAmount,
                            QuoteId = quoteId,
                            PricebookEntryId = pbe.Id,
                            Product2Id = pbe.Product2Id,
                            Quantity = 1
                        ));
                    }
                }
                insert qliList;
                return successMessage;
            } catch (exception e) {
                messageDTO msg = new messageDTO(500, 'Cannot add qli items for Taxes');
                System.debug('##! ' + msg.message);
                return msg;
            }
        }

        //Send the second request, if taxes was already paid previously,
        //and subtracts it from total taxes amount from previous request
        public HttpResponse prepareExistingRequest( EstimatedTaxesHandler.estimatedTaxesDTO currentTaxes,
                                                    EstimatedTaxesHandlerHelper estTaxesHelper ) {
            EstimatedTaxesHandler.estimatedTaxesDTO existingEstTaxesDto;

            if (currentTaxes != null) {
                for (EstimatedTaxesHandler.FeatureDTO dto : currentTaxes.featuresList) {
                    if (dto.hasEntitlement) {
                        String serializedTaxes = JSON.serialize(currentTaxes);
                        existingEstTaxesDto = (EstimatedTaxesHandler.estimatedTaxesDTO) JSON.deserialize(
                            serializedTaxes, 
                            EstimatedTaxesHandler.estimatedTaxesDTO.class
                        );
                        break;
                    }
                }
                if (existingEstTaxesDto != null) {
                    Map<String, String> chargeTermsMap = new Map<String, String>();

                    for (EstimatedTaxesHandler.FeatureDTO extDto : existingEstTaxesDto.featuresList) {
                        extDto.quantity = (Integer) NumberHelper.getNumberNullSafe(extDto.existingQuantity);
                        if (extDto.hasEntitlement) {
                            extDto.price = (Decimal) NumberHelper.getNumberNullSafe(extDto.entPrice);
                            for (ProductInfoForEstimatedTaxesDTO product : existingEstTaxesDto.discountItemsList.products) {
                                if (product.productFeature == extDto.featureType) {
                                    product.lineItems.get(0).discount = extDto.entDiscount;
                                    product.lineItems.get(0).discountType = extDto.entDiscountType;
                                    if (product.chargeTerm != null && extDto.chargeTerm != null) {
                                        chargeTermsMap.put(product.chargeTerm, extDto.chargeTerm);
                                    }
                                }
                            }
                            extDto.idTier = extDto.quoteTierId == null
                                            ? null
                                            : Integer.valueOf(extDto.quoteTierId);
                        }
                    }
                    String rawRequest = prepareRequestValues(JSON.serialize(existingEstTaxesDto), chargeTermsMap);
                    HttpRequest existingRequest = HttpHelper.prepareHttpRequest(endpointUrl, HttpHelper.METHOD_POST, rawRequest);
                    return new Http().send(existingRequest);
                }
            }
            return null;
        }

        //Calculate taxes amount for different types of taxes
        public Boolean calculateTaxesAmount(taxDetailDTO taxDetail, Map<String, Decimal> ppTaxes) {
            Boolean addItem = false;

            if (taxDetail != null) {
                Decimal taxDetailAmount = (Decimal) NumberHelper.getNumberNullSafe(taxDetail.amount);
                if (ppTaxes.containsKey(taxDetail.descriptionId)) {
                    taxDetailAmount += ppTaxes.get(taxDetail.descriptionId);
                }
                ppTaxes.put(taxDetail.descriptionId, taxDetailAmount);
                addItem = true;
            }
            return addItem;
        }

        //Preparing a map of taxes, which are already being paid
        public Map<String, Map<String, Decimal>> prepareExistingTaxes(String respBody) {
            Map<String, Map<String, Decimal>> sumTaxes = new Map<String, Map<String, Decimal>>();
            respBody = respBody.replace('"type":', '"taxDetailsType":');
            responseEstimatedTaxesDTO mappedResponse = responseMapping(respBody);

            if (mappedResponse != null && mappedResponse.status.success
                && mappedResponse.result.billingItems != null 
                && !mappedResponse.result.billingItems.isEmpty()) {

                for (billingItemDTO item : mappedResponse.result.billingItems) {
                    Boolean addItem = false;
                    String currentPlan = Test.isRunningTest() 
                                            ? 'One - Time' 
                                            : billingIdToQli.get(item.billingItemId)
                                                            .Product2
                                                            .Charge_Term__c;
                    Map<String, Decimal> taxes = sumTaxes.containsKey(currentPlan) 
                                                        ? sumTaxes.get(currentPlan) 
                                                        : new Map<String, Decimal>();
                    if (item.taxDetails != null) {
                        for (taxDetailDTO taxDetail : item.taxDetails) {
                            if (taxDetail.availableOnBrand && allTaxesIds.contains(taxDetail.descriptionId)) {
                                addItem = calculateTaxesAmount(taxDetail, taxes);
                            }
                        }
                        if (addItem) {
                            sumTaxes.put(currentPlan, taxes);
                        }
                    }
                } 
            } else if (mappedResponse != null && !mappedResponse.status.success) {
                return new Map<String, Map<String, Decimal>>();
            }
            return sumTaxes;
        }

        public String prepareRequestValues(String rawRequest, Map<String, String> requestValues) {
            if (requestValues != null) {
                for (String term : requestValues.keySet()) {
                    rawRequest = rawRequest.replace(term, requestValues.get(term));
                }
            }
            return rawRequest;
        }

        public Map<String, Map<String, Decimal>> prepareTaxesAmount(HttpResponse resp, 
                                                                    EstimatedTaxesHandlerHelper estTaxesHelper) {
            Map<String, Map<String, Decimal>> existingTaxes = null;
            String respBody;

            if (resp != null) {
                respBody = resp.getBody();
                existingTaxes = estTaxesHelper.prepareExistingTaxes(respBody);
            }
            return existingTaxes;
        }
    }

    private static String assignTierId( Quote q,
                                        QuoteLineItem qli,
                                        Entitlement__c ent ) {
        return (qli == null || String.isBlank(qli.Quote.PriceBook2.Tier_ID__c)
                ? (q.Pricebook2.Tier_ID__c != null
                    ? q.Pricebook2.Tier_ID__c
                    : ent.Product__r.ExtID__c.left(4))
                : qli.Quote.PriceBook2.Tier_ID__c);
    }

    public static Boolean removeTaxesQli(Id quoteId) {
        List<QuoteLineItem> qliList = [SELECT Id, Product2.Family FROM QuoteLineItem WHERE QuoteId=:quoteId];
        //Contains qoute line items with taxes
        List<QuoteLineItem> qliListWithTaxesToDelete = new List <QuoteLineItem>();
        //Contains all other quote line items
        List<QuoteLineItem> qliListToUpdate = new List <QuoteLineItem>();
        for(QuoteLineItem qli : qliList) {
            if (qli.Product2.Family == 'Taxes') {
                qliListWithTaxesToDelete.add(qli);
            } else {
                //When qlis with taxes are removed/updated/inserted Tases__c field should be emptied
                qli.Taxes__c = null;
                qli.Fixed_Taxes_Amount__c = null;
                qli.Variable_Taxes_Amount__c = null;
                qliListToUpdate.add(qli);
            }
        }
        //When qlis with taxes are removed/updated/inserted Free_Service_Taxes__c should be emptied
        if (!qliListWithTaxesToDelete.isEmpty()) {
            delete qliListWithTaxesToDelete;
        }

        if (!qliListToUpdate.isEmpty() && !byPassQliUpdate) {
            update qliListToUpdate;
        }
        return true;
    }

    public class responseEstimatedTaxesDTO{
        public responseStatusDTO status;
        public responseResultDTO result;
    }

    public class responseStatusDTO{
        public Boolean success;
        public Integer code;
        public String message;
    }

    public class responseResultDTO{
        public List<billingItemDTO> billingItems;
        public Decimal totalTaxesFixed;
        public Decimal totalTaxesVariable;
    }

    public class billingItemDTO{
        public Integer billingItemId;
        public Decimal price;
        public Decimal discount;
        public Decimal totalTaxes;
        public reqItemInfoDTO requestedItemInfo;
        public List<taxDetailDTO> taxDetails;
    }

    public class reqItemInfoDTO{
        public reqItemDTO item;
        public String sectionType;
        public Integer qtyOfDigitalLines;
    }

    public class reqItemDTO{
        public String zipCode;
        public String state;
        public String city;
        public Integer quantity;
        public Decimal price;
        public Integer idTier;
        public Integer idBrand;
        public Integer featureType;
        public String featureName;
        public String featureDescription;
        public String billingPlanDuration;
        public Integer billingItemId;
        public List<EstimatedTaxesHandler.DeviceInfoDTO>deviceInfoList;
    }

    public class taxDetailDTO{
        public Boolean availableOnBrand;
        public String taxDetailsType;
        public String description;
        public String descriptionId;
        public Decimal amount;
        public Decimal amountFixed;
        public Decimal amountVariable;
    }

    public class messageDTO {
        public String message;
        public Integer status;
        public Integer existingTaxesStatus;

        public messageDTO(){}
        public messageDTO(Integer status, String msg){
            this.status = status;
            this.message = msg;
            this.existingTaxesStatus = 200;
        }
    }

    public class DeviceDTO {
        public Integer billingItemId;
        public String billingPlanDuration;
        public Integer idBrand;
        public String city;
        public String state;
        public String zipCode;
        public Integer idTier;
        public List<DeviceInfoDTO> deviceInfoList;

        public DeviceDTO() {
            this.deviceInfoList = new List<EstimatedTaxesHandler.DeviceInfoDTO>();
        }

    }

    public class DeviceInfoDTO {
        public Integer deviceTypeId;
        public Integer dlFeatureType;
        public Integer featureType;
        public Integer quantity;
        public Integer sidecarCount;

        public DeviceInfoDTO(){}

        public DeviceInfoDTO(EstimatedTaxesHandler.PrecursorDeviceDTO precDevDto){
            this.deviceTypeId = precDevDto.deviceTypeId;
            this.dlFeatureType = precDevDto.dlFeatureType;
            this.featureType = precDevDto.featureType;
            this.quantity = precDevDto.quantity;
            this.sidecarCount = precDevDto.sidecarCount;
        }
    }

    public class PrecursorDeviceDTO {
        public Integer billingItemId;
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
        public Integer billingItemId;
        public String billingPlanDuration;
        public String city;
        public String featureDescription;
        public String featureName;
        public Integer featureType;
        public Integer deviceTypeId;
        public Integer sidecarCount;
        public Integer idBrand;
        public Integer idTier;
        public Decimal price;
        public Integer quantity;
        public Integer existingQuantity;
        public String state;
        public String zipCode;
        public Boolean phoneWithDL;
        public Boolean hasEntitlement;
        public Decimal entDiscount;
        public Decimal entPrice;
        public String entDiscountType;
        public String chargeTerm;
        public String quoteTierId;
    }

    public class estimatedTaxesDTO {
        public ApprovalWrapperForEstimatedTaxesDTO discountItemsList;
        public List<EstimatedTaxesHandler.FeatureDTO> featuresList;
        public Boolean exemptFromStateAndLocalTaxes;
        public Integer tierId;

        public String payCountry;
    }

    public class LineItemInfoForEstimatedTaxesDTO {
        public decimal discount;
        public string discountType;
    }

    public class ProductInfoForEstimatedTaxesDTO {
        public string chargeTerm;
        public decimal productFeature;
        public decimal productSubFeature;
        public List<LineItemInfoForEstimatedTaxesDTO> lineItems;

        public ProductInfoForEstimatedTaxesDTO(FlexibleDiscountRestApi.productInfo productInfo) {
            this.chargeTerm = productInfo.chargeTerm;
            this.productFeature = productInfo.productFeature;
            this.productSubFeature = productInfo.productSubFeature;

            this.lineItems = new List<LineItemInfoForEstimatedTaxesDTO>();
            LineItemInfoForEstimatedTaxesDTO liiToAdd = new LineItemInfoForEstimatedTaxesDTO();
            liiToAdd.discountType = productInfo.lineItems[0].discountType;
            liiToAdd.discount = productInfo.lineItems[0].discount;
            this.lineItems.add(liiToAdd);
        }

    }

    public class ApprovalWrapperForEstimatedTaxesDTO {
        public List<ProductInfoForEstimatedTaxesDTO> products;

        public ApprovalWrapperForEstimatedTaxesDTO(FlexibleDiscountRestApi.ApprovalWrapper approvalWrapper) {
            this.products = new List<ProductInfoForEstimatedTaxesDTO>();
            if (approvalWrapper.products != null) {
                if (approvalWrapper.products.size() > 0) {
                    for (FlexibleDiscountRestApi.productInfo prInfo : approvalWrapper.products){
                        if (!(prInfo.productFeature == null)) {                             // Check which FlexDiscProducts should be sent
                            this.products.add(new ProductInfoForEstimatedTaxesDTO(prInfo));
                        }
                    }
                }
            }
        }

    }

    public class requestParams {
        public String quoteId;
    }

    public class estimatedTaxesWrapper{
        public estimatedTaxesDTO estimatedTaxesDto;
        public messageDTO messageDto;

        public estimatedTaxesDTO getEstimatedTaxesDTO(String quoteIdString) {
            estimatedTaxesDTO estTaxDto = new estimatedTaxesDTO();
            List<PrecursorDeviceDTO> precursorDevicesList = new List<PrecursorDeviceDTO>();
            List<FeatureDTO> featuresList = new List<FeatureDTO>();
            Map<Id, Entitlement__c> entsByProducts = new Map<Id, Entitlement__c>();
            Quote quote;
            Id quoteId;
            try {
                quoteId = Id.valueOf(quoteIdString);
                quote = [SELECT QuoteNumber, OpportunityId, Pricebook2.Tier_ID__c, Pricebook2.Plan__c, Pricebook2.Name,
                        Pricebook2.Brand__r.Brand_Id__c, Pricebook2.Edition__c, Account.Tax_Exempt__c,
                        Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                        Account.RC_User_ID__c, AccountId
                FROM Quote WHERE Id = :quoteId];
            } catch (Exception ex) {
                System.debug('##! Exeption in quering in EstimatedTaxesHandler ' + ex.getMessage());
                this.messageDto = new messageDTO(202, 'Exeption in quering in EstimatedTaxesHandler');
                this.estimatedTaxesDto = new EstimatedTaxesDTO();
                return this.estimatedTaxesDto;
            }

            if (quote.Account.BillingCity == null || quote.Account.BillingState == null ||
                quote.Account.BillingPostalCode == null || quote.Account.BillingCountry == null) {
                this.messageDto = new messageDTO(202, 'Please fill Account Billing Address fields');
                this.estimatedTaxesDto = new EstimatedTaxesDTO();
                return this.estimatedTaxesDto;
            }

            for (Entitlement__c ent : [
                SELECT  Product__r.ExtID__c, Product__c,
                        Price__c, Discount__c, Discount_Type__c,
                        Quantity__c, ChargeTerm__c
                FROM Entitlement__c
                WHERE Account__c = :quote.AccountId
                AND Active__c = true
                AND Product__r.Feature__c != null
                AND Product__c != null
            ]) {
                entsByProducts.put(ent.Product__c, ent);
            }

            List<QuoteLineItem> qliList = [
                SELECT Id, Quantity, NewQuantity__c, UnitPrice, CurrencyIsoCode,
                    Product2.Family, Product2.FeatureName__c, Product2.Feature__c,
                    Product2.Sub_Feature__c, Product2.FDescription__c, 
                    Product2.SideCarCount__c, Product2Id, Product2.Name,
                    Product2.Charge_Term__c, PriceBookEntry.Monthly_Contract_Discount__c,
                    Entitlement__c, Entitlement__r.Active__c, Entitlement__r.Quantity__c,
                    Entitlement__r.Price__c, Entitlement__r.Discount__c, 
                    Entitlement__r.Discount_Type__c, Entitlement__r.ChargeTerm__c,
                    Quote.PriceBook2.Tier_ID__c
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
            ];

            // filter qli to devices precursors (discphones, refph, rentph), digitallines features and other features
            if (qliList.size()>0) {
                Integer dlFeatureType;
                Integer billingItemIdCounter = 1;

                // B-1998
                Map<String, Decimal> mcDiscounts = FlexibleDiscountRestApi.getDiscount(new Map<Id, QuoteLineItem>(qliList));

                for (QuoteLineItem qli : qliList) {
                    if (qli.Product2.Family == 'Service') {
                        dlFeatureType = Integer.valueOf(qli.Product2.Feature__c);
                    }
                    if (qli.Product2.Feature__c != null) {
                        FeatureDTO feature = new FeatureDTO();
                        feature.billingItemId = billingItemIdCounter;
                        feature.billingPlanDuration = (Quote.Pricebook2.Plan__c == 'Monthly - Contract') ? 'Monthly' : Quote.Pricebook2.Plan__c;
                        feature.city = quote.Account.BillingCity;
                        feature.featureDescription = qli.Product2.FDescription__c;
                        feature.featureName = qli.Product2.FeatureName__c;
                        feature.featureType = Integer.valueOf(qli.Product2.Feature__c);
                        feature.deviceTypeId = qli.Product2.Sub_Feature__c != null ? Integer.valueOf(qli.Product2.Sub_Feature__c) : 0;
                        feature.sidecarCount = qli.Product2.SideCarCount__c != null ? Integer.valueOf(qli.Product2.SideCarCount__c) : 0;
                        feature.idBrand = Integer.valueOf(quote.Pricebook2.Brand__r.Brand_Id__c);
                        feature.idTier = Integer.valueOf(quote.Pricebook2.Tier_ID__c);
                        feature.hasEntitlement = false;

                        //b-979 adding monthly-contract difference
                        Decimal dsc = 0;
                        if (qli.Product2.Charge_Term__c == 'Monthly - Contract' &&
                            !(qli.Product2.Feature__c == 17 && (quote.PriceBook2.Edition__c == 'Google Apps' ||
                                                                    quote.PriceBook2.Edition__c == 'Unlimited'))){
                            String fkey = qli.Product2.Feature__c + '%' + qli.Product2.Sub_Feature__c;
                            if (mcDiscounts.containsKey(fkey)){
                                dsc = mcDiscounts.get(fkey);
                            } else {
                                fkey = qli.Product2.Feature__c + '%' + null;
                                if (mcDiscounts.containsKey(fkey)) {
                                    dsc = mcDiscounts.get(fkey);
                                }
                            }
                        }
                        //b-979

                        feature.price = qli.UnitPrice + dsc;
                        feature.quantity = Integer.valueOf(qli.NewQuantity__c);
                        feature.state = quote.Account.BillingState;
                        feature.zipCode = quote.Account.BillingPostalCode;

                        //b-979
                        if (qli.Product2.Family != 'Phones' &&
                            (qli.Product2.Feature__c == 11 ||
                            qli.Product2.Feature__c == 34 ||
                            qli.Product2.Feature__c == 39)) {
                            feature.phoneWithDL = true;
                        }
                        if (qli.Product2.Family == 'Phones' && qli.Product2.Feature__c == 11){
                            feature.phoneWithDL = false;
                        }
                        //b-979

                        if (qli.Entitlement__c != null && qli.Entitlement__r.Active__c) {
                            feature.existingQuantity = (Integer) qli.Entitlement__r.Quantity__c;
                            feature.hasEntitlement = true;
                            feature.entDiscount = qli.Entitlement__r.Discount__c;
                            feature.entDiscountType = qli.Entitlement__r.Discount_Type__c;
                            feature.entPrice = qli.Entitlement__r.Price__c;
                            feature.chargeTerm = qli.Entitlement__r.ChargeTerm__c;
                            feature.quoteTierId = String.isBlank(qli.Quote.PriceBook2.Tier_ID__c)
                                                    ? quote.Pricebook2.Tier_ID__c
                                                    : qli.Quote.PriceBook2.Tier_ID__c;
                        } else if (entsByProducts.containsKey(qli.Product2Id)) {
                            Entitlement__c currentEnt = entsByProducts.get(qli.Product2Id);

                            feature.existingQuantity = (Integer) currentEnt.Quantity__c;
                            feature.hasEntitlement = true;
                            feature.entDiscount = currentEnt.Discount__c;
                            feature.entDiscountType = currentEnt.Discount_Type__c;
                            feature.entPrice = currentEnt.Price__c;
                            feature.chargeTerm = currentEnt.ChargeTerm__c;
                            feature.quoteTierId = assignTierId(quote, qli, currentEnt);
                        }
                        featuresList.add(feature);
                        billingIdToQli.put(billingItemIdCounter, qli);
                        billingItemIdCounter++;
                    }
                }
            }

            // convert precursors to needed format for general web

            // for now we can have only one dlFeatureType, so we dont need to filter deviceDTO separately for 'Monthly'/'Annual'/so on
            // and we don`t need to calculate dl quantity and tied devices to this dl`s
            List<DeviceDTO> listDeviceDTO = new List<DeviceDTO>();

            FlexibleDiscountRestApi.ApprovalWrapper flexWrapper = new FlexibleDiscountRestApi.ApprovalWrapper();
            String rcUserId = String.valueOf(quote.Account.RC_User_ID__c);
            String approvalQuoteNumber = String.valueOf(quote.QuoteNumber);
            String tierIdString = String.valueOf(quote.Pricebook2.Tier_ID__c);
            String oppId = String.valueOf(quote.OpportunityId);
            flexWrapper.isTaxesRequested = true;
            flexWrapper = flexWrapper.generateJson(rcUserId, approvalQuoteNumber, tierIdString, oppId);
            ApprovalWrapperForEstimatedTaxesDTO filteredFlexWrapper = new ApprovalWrapperForEstimatedTaxesDTO(flexWrapper);

            estTaxDto.exemptFromStateAndLocalTaxes = quote.Account.Tax_Exempt__c;
            estTaxDto.discountItemsList = filteredFlexWrapper;
            estTaxDto.featuresList = featuresList;
            estTaxDto.tierId = Integer.valueOf(quote.Pricebook2.Tier_ID__c);

            estTaxDto.payCountry = quote.Account.BillingCountry;

            this.estimatedTaxesDto = estTaxDto;
            this.messageDto = new messageDTO(200, 'OK');
            return estTaxDto;
        }
    }

}