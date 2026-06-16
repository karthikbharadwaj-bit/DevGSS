@RestResource(urlMapping='/FlexibleDiscountRestApi')
global with sharing class FlexibleDiscountRestApi {

    //Error Fields
    public boolean errorExists{get;set;}
    public string errorMsg{get;set;}

    //Approval Fields
    public string approvalName{get;set;}
    public string approvalStatus{get;set;}
    public string approvalID{get;set;}
    public string accountUserId{get;set;}

    //Opportunity Fields
    public string opportunityId{get;set;}
    public string opportunityName{get;set;}

    //Product Lists
    public List<productInfo> products{get;set;}

    //Boolean Variables
    public boolean isRequestValid{get;set;}
    public boolean isApproved{get;set;}
    public boolean isServiceProduct{get;set;}
    public boolean isTierExists{get;set;}
    public boolean isWithInRange{get;set;}
    public string description{get;set;}

    //Products Fields
    public class productInfo{

        public string productFullName{get;set;}
        public string productId{get;set;}
        public string productCategory{get;set;}
        public string productSubCategory{get;set;}
        public string chargeTerm{get;set;}
        public string productType{get;set;}
        public string serviceType{get;set;}
        public decimal productFeature{get;set;}
        public decimal productSubFeature{get;set;}

        public List<lineItemInfo> lineItems{get;set;}

        public productInfo(string productFullName,string productId,string productCategory,string productSubCategory,string chargeTerm,string productType,
                            string serviceType,decimal productFeature,decimal productSubFeature,List<lineItemInfo> lineItems){
            this.productFullName = productFullName;
            this.productId = productId;
            this.productCategory = productCategory;
            this.productSubCategory = productSubCategory;
            this.chargeTerm = chargeTerm;
            this.productType = productType;
            this.serviceType = serviceType;
            this.productFeature = productFeature;
            this.productSubFeature = productSubFeature;
            this.lineItems = lineItems;
        }
    }

    //Line Item Fields
    public class lineItemInfo{

        public string lineItemId{get;set;}
        public string lineItemName{get;set;}
        public decimal effectivePrice{get;set;}
        public decimal listPrice{get;set;}
        public decimal quantity{get;set;}
        public string subCategory{get;set;}
        public decimal totalInitialPrice{get;set;}
        public decimal totalMonthlyPrice{get;set;}
        public decimal totalPrice{get;set;}
        public string str_category{get;set;}
        public string str_currency{get;set;}
        public decimal discount{get;set;}
        public string discountType{get;set;}
        public decimal effectiveDiscount{get;set;}

        public lineItemInfo(string lineItemId,string lineItemName,decimal effectivePrice,decimal listPrice,decimal quantity,string subCategory,
                            decimal totalInitialPrice,decimal totalMonthlyPrice,decimal totalPrice,string str_category,string str_currency,
                            decimal discount,string discountType,decimal effectiveDiscount){
            this.lineItemId = lineItemId;
            this.lineItemName = lineItemName;
            this.effectivePrice = effectivePrice;
            this.listPrice = listPrice;
            this.quantity = quantity;
            this.subCategory = subCategory;
            this.totalInitialPrice = totalInitialPrice;
            this.totalMonthlyPrice = totalMonthlyPrice;
            this.totalPrice = totalPrice;
            this.str_category = str_category;
            this.str_currency = str_currency;
            this.discount = discount;
            this.discountType = discountType;
            this.effectiveDiscount = effectiveDiscount;
        }
    }

    //Wrapper for GW Request Parameters
    public class GWRequestCall{

        public string rcUserID;
      public string quoteTierID;
        public string approvalID;
        public string oppID;

        public GWRequestCall(string rcUserID, string quoteTierID, string approvalID, String oppID){
            this.rcUserID = rcUserID;
            this.quoteTierID = quoteTierID;
            this.approvalID = approvalID;
            this.oppID = oppID;
        }
    }

    public class ApprovalWrapper{
        //Error Fields
        public boolean errorExists{get;set;}
        public string errorMsg{get;set;}

        //Approval Fields
        public string approvalName{get;set;}
        public string approvalStatus{get;set;}
        public string approvalID{get;set;}
        public string accountUserId{get;set;}

        //Opportunity Fields
        public string opportunityId{get;set;}
        public string opportunityName{get;set;}

        //PriceBook Fields
        public string tierId{get;set;}

        //Product Lists
        public List<productInfo> products{get;set;}

        //Boolean Variables
        public boolean isRequestValid{get;set;}
        public boolean isApproved{get;set;}
        public boolean isServiceProduct{get;set;}
        public boolean isTierExists{get;set;}
        public boolean isWithInRange{get;set;}
        public string description{get;set;}

        //Flag if taxes are requested
        public boolean isTaxesRequested{get;set;}

        public ApprovalWrapper(){
            this.isRequestValid = false;
            this.isApproved = false;
            this.isServiceProduct = false;
            this.isTierExists = false;
            this.isWithInRange = false;
            this.isTaxesRequested = false;
        }

        public ApprovalWrapper generateJson(String userID, String ApprovalQuoteNumber, String tierID, String oppID){

            Map<Id, QuoteLineItem> lineItemsMap;
            Map<Id, Product2> productsMap;
            Map<Id, List<lineItemInfo>> productsLineItemMap;
            Map<String, QuoteLineItem> currentDiscounts = new Map<String, QuoteLineItem>();
            Set<Decimal> oneTimeFeatureTypes = new Set<Decimal>{4,5,11,22,29,37,39,43,35,46};
            Set<Decimal> withoutSubFeatureTypes = new Set<Decimal>{39};

            Set<Id> entitlementsIdSet = new Set<Id>();

            try{
                Quote approvedQuote = Database.Query('SELECT Id, ' +
                                                          'Name, ' +
                                                          'AccountId, ' +
                                                          'QuoteNumber, ' +
                                                          'Status, ' +
                                                          'CurrencyIsoCode, ' +
                                                          'OpportunityId, ' +
                                                          'Approved_Status__c, ' +
                                                          'Total_Number_of_Digital_Lines__c, ' +
                                                          'InvalidDiscountedPhonesQuantity__c, ' +
                                                          'InvalidGlobalOfficePhonesQuantity__c, ' +
                                                          'InvalidLimitedExtensionPhonesQuantity__c, ' +
                                                          'Invalid_GO_LE_Phones_Quantity__c, ' +
                                                          'Opportunity.Name, ' +
                                                          'Opportunity.AccountId, ' +
                                                          'Opportunity.Account.RC_User_ID__c, ' +
                                                          'PriceBook2.Service__c, ' +
                                                          'PriceBook2.Tier_ID__c, ' +
                                                          'PriceBook2.Plan__c, ' +
                                                          'PriceBook2.Brand__c, ' +
                                                          'PriceBook2.Edition__c, ' +
                                                          'PriceBook2.Line_Range_Max__c, ' +
                                                          'PriceBook2.Line_Range_Min__c ' +
                                                   'FROM Quote ' +
                                                   'WHERE QuoteNumber=:ApprovalQuoteNumber AND (OpportunityId=:oppID OR Opportunity.Account.RC_User_ID__c=:userID) LIMIT 1');
                this.isRequestValid = true;
                this.isApproved = false;
                this.approvalID = approvedQuote.Id;
                this.approvalName = approvedQuote.QuoteNumber;
                this.approvalStatus = approvedQuote.Approved_Status__c;
                this.tierId = approvedQuote.PriceBook2.Tier_ID__c;

                this.accountUserId = (approvedQuote.Opportunity.AccountId != null ? approvedQuote.Opportunity.Account.RC_User_ID__c : null);
                this.opportunityId = approvedQuote.OpportunityId;
                this.opportunityName = (approvedQuote.Opportunity != null ? approvedQuote.Opportunity.Name : null);

                Decimal monthlyTierEntryUnitPrice = 0;

                if(approvedQuote.PriceBook2.Plan__c == 'Monthly - Contract'){
                    PriceBookEntry monthlyTierEntry = new PriceBookEntry();
                    try{
                        monthlyTierEntry = [SELECT UnitPrice FROM PriceBookEntry WHERE Pricebook2.Tier_ID__c =: approvedQuote.PriceBook2.Tier_ID__c AND  Pricebook2.Service__c =: approvedQuote.PriceBook2.Service__c
                                            AND PriceBook2.Brand__c =: approvedQuote.PriceBook2.Brand__c AND PriceBook2.Edition__c =: approvedQuote.PriceBook2.Edition__c AND PriceBook2.Line_Range_Max__c =: approvedQuote.PriceBook2.Line_Range_Max__c
                                            AND PriceBook2.Line_Range_Min__c =: approvedQuote.PriceBook2.Line_Range_Min__c  AND Pricebook2.Plan__c = 'Monthly' AND (Product2.Family = 'Tier' OR Product2.Family = 'Service') AND CurrencyIsoCode =: approvedQuote.CurrencyIsoCode
                                            LIMIT 1];
                        monthlyTierEntryUnitPrice = monthlyTierEntry.UnitPrice;
                    }catch(Exception ex){
                        system.debug('There is no montly pricebook entries with the same Service, Brand and Tier Id and currency');
                        system.debug('tier: ' + approvedQuote.PriceBook2.Tier_ID__c);
                        system.debug('service: ' + approvedQuote.PriceBook2.Service__c );
                        system.debug('brand: ' + approvedQuote.PriceBook2.Brand__c);
                        system.debug('edition: ' + approvedQuote.PriceBook2.Edition__c);
                        system.debug('max: ' + approvedQuote.PriceBook2.Line_Range_Max__c);
                        system.debug('min: ' + approvedQuote.PriceBook2.Line_Range_Min__c);
                        system.debug('IsoCode: ' + approvedQuote.CurrencyIsoCode);
                    }
                }

                if((approvedQuote.Approved_Status__c == 'Approved' || isTaxesRequested)
                  && !approvedQuote.InvalidDiscountedPhonesQuantity__c
                  && !approvedQuote.InvalidGlobalOfficePhonesQuantity__c
                  && !approvedQuote.InvalidLimitedExtensionPhonesQuantity__c
                  && !approvedQuote.Invalid_GO_LE_Phones_Quantity__c){
                    //If feature in featureList - don't send discount in Flexible Discount API
                    String features;
                    List <Decimal> featureList = new List <Decimal>();
                    if ( Features__c.getall().get('restrictedFeature') != null && String.isNotBlank(Features__c.getall().get('restrictedFeature').FeatureSet__c) ){
                        features = Features__c.getall().get('restrictedFeature').FeatureSet__c ;
                        List <String>  str =  features.split(',');
                        for(String s : str) {
                            featureList.add(Decimal.valueOf(s));
                            }
                    }

                    this.isApproved = true;
                    lineItemsMap = new Map<Id,QuoteLineItem>([SELECT Id,
                                                                     QuoteId,
                                                                     Discount,
                                                                     Subtotal,
                                                                     ListPrice,
                                                                     UnitPrice,
                                                                     Quantity,
                                                                     TotalPrice,
                                                                     TotalInitialPrice__c,
                                                                     EffectivePrice__c,
                                                                     Discount_number__c,
                                                                     Discount_Type__c,
                                                                     Discount_Value__c,
                                                                     CurrencyIsoCode,
                                                                     Entitlement__c,
                                                                     Product2Id,
                                                                     Product2.Name,
                                                                     Product2.Family,
                                                                     Product2.Feature__c,
                                                                     Product2.Sub_Feature__c,
                                                                     Product2.Sub_Category__c,
                                                                     Product2.Charge_Term__c,
                                                                     Quote.OpportunityId,
                                                                     PriceBookEntry.PriceBook2.Plan__c,
                                                                     PriceBookEntry.PriceBook2.Tier_ID__c,
                                                                     PriceBookEntry.Monthly_Contract_Discount__c,
                                                                     PriceBookEntry.Unitprice
                                                               FROM QuoteLineItem
                                                               WHERE QuoteId=:approvedQuote.Id
                                                               AND Product2.Feature__c Not IN : featureList
                                                               AND Product2.Feature__c!=null]);

                    if(lineItemsMap!=null && lineItemsMap.size() > 0){

                        // B-1998
                        Map<String, Decimal> mcDiscounts = getDiscount(lineItemsMap);

                        Set<Id> ProductsIds = new Set<Id>();
                        productsLineItemMap = new Map<Id,List<lineItemInfo>>();

                        for(Id qliId : lineItemsMap.keySet()) {

                            if(lineItemsMap.get(qliId).Entitlement__c != null) {
                                entitlementsIdSet.add(lineItemsMap.get(qliId).Entitlement__c);
                            }

                            ProductsIds.add(lineItemsMap.get(qliId).Product2Id);
                            QuoteLineItem tempLineItem = lineItemsMap.get(qliId);
                            if(!productsLineItemMap.containsKey(tempLineItem.Product2Id)){
                                productsLineItemMap.put(tempLineItem.Product2Id, new List<lineItemInfo>());
                            }
                            List<lineItemInfo> lineItemList =  productsLineItemMap.get(tempLineItem.Product2Id);

                            Decimal discountDiffernce = 0;
                            Decimal discount = 0;

                            //b-979 adding monthly-contract difference
                            Decimal dsc = 0;
                            if (tempLineItem.Product2.Charge_Term__c == 'Monthly - Contract'&&
                                !(tempLineItem.Product2.Feature__c == 17 &&
                                (approvedQuote.PriceBook2.Edition__c == 'Google Apps' ||
                                    approvedQuote.PriceBook2.Edition__c == 'Unlimited'))){
                                String fkey = tempLineItem.Product2.Feature__c + '%' + tempLineItem.Product2.Sub_Feature__c;
                                if (mcDiscounts.containsKey(fkey)){
                                    dsc = mcDiscounts.get(fkey);
                                } else {
                                    fkey = tempLineItem.Product2.Feature__c + '%' + null;
                                    if (mcDiscounts.containsKey(fkey)) {
                                        dsc = mcDiscounts.get(fkey);
                                    }
                                }
                            }
                            //b-979

                            if(tempLineItem.Product2.Charge_Term__c == 'Monthly - Contract'){
                                Decimal monthlyContractDiscount = (tempLineItem.PriceBookEntry.Monthly_Contract_Discount__c == null) ? 0 : tempLineItem.PriceBookEntry.Monthly_Contract_Discount__c;
                                if(tempLineItem.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE && monthlyTierEntryUnitPrice != 0){
                                    discount = ((tempLineItem.UnitPrice * tempLineItem.Discount/100 + monthlyContractDiscount) * 100 / (tempLineItem.UnitPrice + monthlyContractDiscount)).setScale(2,System.RoundingMode.HALF_UP);
                                } else if (tempLineItem.Discount_type__c != QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {
                                    discount = (tempLineItem.Discount_number__c!=null ? tempLineItem.Discount_number__c : 0) + monthlyContractDiscount;
                                }
                                discountDiffernce = dsc;
                            }


                            lineItemInfo lineItemObj = new lineItemInfo(tempLineItem.Id, tempLineItem.Product2.Name,
                                                                        (tempLineItem.TotalPrice/tempLineItem.Quantity), discountDiffernce + tempLineItem.UnitPrice,
                                                                        tempLineItem.Quantity, tempLineItem.Product2.Sub_Category__c,
                                                                        tempLineItem.TotalInitialPrice__c, (tempLineItem.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL ? (tempLineItem.TotalInitialPrice__c / 12) : tempLineItem.TotalInitialPrice__c),
                                                                        tempLineItem.TotalInitialPrice__c, (tempLineItem.Product2.Family == 'Tier' ? 'Service' : tempLineItem.Product2.Family),
                                                                        tempLineItem.CurrencyIsoCode, discount != 0 ? discount : ((templineItem.Discount_number__c != null ? templineItem.Discount_number__c : 0) + discountDiffernce),
                                                                        tempLineItem.Discount_type__c, tempLineItem.UnitPrice - (tempLineItem.TotalPrice/tempLineItem.Quantity) + discountDiffernce);
                            lineItemList.add(lineItemObj);
                            productsLineItemMap.put(tempLineItem.Product2Id, lineItemList);

                            String feature = (SetApprovalTypeHelper.isValueNotEmpty(tempLineItem.Product2.Feature__c) ? '_' + String.ValueOf(Integer.ValueOf(tempLineItem.Product2.Feature__c)) : '');
                            String subfeature = (SetApprovalTypeHelper.isValueNotEmpty(tempLineItem.Product2.Sub_Feature__c) ? '_' + String.ValueOf(Integer.ValueOf(tempLineItem.Product2.Sub_Feature__c)) : '');
                            if(SetApprovalTypeHelper.isValueNotEmpty(feature) || SetApprovalTypeHelper.isValueNotEmpty(subfeature)){
                                String key = tempLineItem.QuoteId + feature + (SetApprovalTypeHelper.isValueNotEmpty(subfeature) && SetApprovalTypeHelper.featureWithSubfeature.contains(feature) ? subfeature : '');
                                currentDiscounts.put(key, tempLineItem);
                            }
                        }

                        if(ProductsIds.size() > 0){
                            productsMap = new Map<Id, Product2>([SELECT Id,
                                                                        Name,
                                                                        Family,
                                                                        Sub_Category__c,
                                                                        Charge_Term__c,
                                                                        Product_Type__c,
                                                                        Feature__c,
                                                                        Sub_Feature__c,
                                                                        (SELECT id, Min_Quantity__c, Max_Quantity__c, PriceBook2.Tier_Id__c FROM PricebookEntries)
                                                                 FROM Product2
                                                                 WHERE Id IN: ProductsIds]);
                        }

                        if(productsMap!=null && productsMap.size() > 0){
                            Set<String> alreadySentItems = new Set<String>();
                            List<productInfo> productsList = new List<productInfo>();
                            Decimal quoteDigitalLines = approvedQuote.Total_Number_of_Digital_Lines__c;
                            for(Id pId : productsMap.keySet()){
                                if(productsMap.get(pId).Family == 'Tier' || productsMap.get(pId).Family == 'Service'){
                                    this.isServiceProduct = true;
                                    if(productsMap.get(pId).PricebookEntries != null && productsMap.get(pId).PricebookEntries.size() > 0){
                                        for(PriceBookEntry pbe : productsMap.get(pId).PricebookEntries){
                                            this.isWithInRange = true;
                                            if(string.isNotBlank(tierID)){
                                                if(pbe.PriceBook2.Tier_Id__c == tierID){
                                                    this.isTierExists = true;
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }

                                if(!this.isServiceProduct || (this.isTierExists && this.isWithInRange)){
                                    List<lineItemInfo> lineItemList = new List<lineItemInfo>();
                                    if(productsLineItemMap.get(pId)!=null){
                                        lineItemList = productsLineItemMap.get(pId);
                                    }
                                    productInfo productObj = new productInfo(productsMap.get(pId).Name,
                                                                             productsMap.get(pId).Id,
                                                                             (productsMap.get(pId).Family == 'Tier' ? 'Service' : productsMap.get(pId).Family),
                                                                             productsMap.get(pId).Sub_Category__c,
                                                                             (productsMap.get(pId).Charge_Term__c == 'Monthly - Contract' ? 'Monthly' : productsMap.get(pId).Charge_Term__c),
                                                                             productsMap.get(pId).Product_Type__c,
                                                                             (productsMap.get(pId).Family == 'Tier' || productsMap.get(pId).Family == 'Service' ? approvedQuote.PriceBook2.Service__c : null) ,
                                                                             productsMap.get(pId).Feature__c,
                                                                             (!withoutSubFeatureTypes.contains(productsMap.get(pId).Feature__c) ? productsMap.get(pId).Sub_Feature__c : null) ,
                                                                             lineItemList);

                                    if( productObj.chargeTerm == 'One - Time' ) {
                                        productObj.chargeTerm = trimSpaces(productObj.chargeTerm);
                                    }

                                    String feature = (SetApprovalTypeHelper.isValueNotEmpty(productsMap.get(pId).Feature__c) ? String.ValueOf(Integer.ValueOf(productsMap.get(pId).Feature__c)) : '');
                                    String subfeature = (SetApprovalTypeHelper.isValueNotEmpty(productsMap.get(pId).Sub_Feature__c) && !withoutSubFeatureTypes.contains(productsMap.get(pId).Feature__c) ? '_' + String.ValueOf(Integer.ValueOf(productsMap.get(pId).Sub_Feature__c)) : '');
                                    String key = feature + subfeature;
                                    System.debug('alreadySentItems:' + alreadySentItems);
                                    if(!alreadySentItems.contains(key)){
                                        productsList.add(productObj);
                                        alreadySentItems.add(key);
                                    }
                                }
                            }

                            Map<String, productInfo> productInfoMap = getProductInfoFromEntitlements(approvedQuote.AccountId, approvedQuote, entitlementsIdSet, currentDiscounts, oneTimeFeatureTypes, withoutSubFeatureTypes);
                            if(productInfoMap != null) {
                                for(String k :productInfoMap.keySet()) {
                                    if(!alreadySentItems.contains(k)) {
                                        productInfo productObj = productInfoMap.get(k);
                                        productsList.add(productObj);
                                        alreadySentItems.add(k);
                                    }
                                }
                            }

                            if(!this.isServiceProduct){
                                this.description = 'Quote doesnt have Tier Product.';
                            } else if(!this.isTierExists){
                                this.description = 'Provided TierId does not exist.';
                            } else if(!this.isWithInRange){
                                this.description = 'Invalid range for provided TierId.';
                            }

                            if(!this.isServiceProduct || (this.isTierExists && this.isWithInRange)) {

                                productsList = createExtensionForFeature17(productsList, lineItemsMap);

                                this.products = productsList;
                            }
                        }
                    }
                }else{
                    this.isApproved = false;
                    this.description = 'Quote is not approved.';
                }
            }catch(Exception ex){
                this.errorExists = true;
                this.description = 'Invalid Quote Number or Opportunity Id.';
                this.errorMsg = ex.getMessage() + ' in line: ' + ex.getLineNumber();
            }

            return this;
        }

        private String trimSpaces(String str) {
            return str.replaceAll( '\\s+', '');
        }


        @TestVisible
        private Map<String, productInfo> getProductInfoFromEntitlements(Id accountId, Quote approvedQuote, Set<Id> entitlementIdSet, Map<String, QuoteLineItem> currentDiscounts, Set<Decimal> oneTimeFeatureTypes, Set<Decimal> withoutSubFeatureTypes) {

            /*
                B-4063 6.1: "Replace existing logic that forms a list of existing discounts in FlexibleDiscountsRestAPI
                    from Quote and Current Discount fields to use Entitlements instead of Current Discount fields."
            */

            if(accountId == null) {
                System.debug('accountId is NULL');
                return null;
            }

            if(oneTimeFeatureTypes == null || withoutSubFeatureTypes == null) {
                System.debug('oneTimeFeatureTypes or withoutSubFeatureTypes is NULL');
                return null;
            }

            String queryString = 'select Id, Discount_Type__c, Discount__c, ' +
                'Product__c, Product__r.Name, Product__r.Family, Product__r.Sub_Category__c, ' +
                'Product__r.Charge_Term__c, Product__r.Product_Type__c, ' +
                'Product__r.Feature__c, Product__r.Sub_Feature__c ' +
                'from Entitlement__c ' +
                'where Account__c = :accountId';

            if(entitlementIdSet != null && !entitlementIdSet.isEmpty()) {
                queryString += ' and Id not in :entitlementIdSet';
            }

            List<Entitlement__c> entitlementList = Database.query(queryString);

            if(entitlementList.isEmpty()) {
                System.debug('entitlements not found');
                return null; // we have no entitlements
            }

            List<Entitlement__c> filteredEntitlementList = new List<Entitlement__c>();

            for(Entitlement__c entl : entitlementList) {

                String feature = (SetApprovalTypeHelper.isValueNotEmpty(entl.Product__r.Feature__c) ? '_' + String.ValueOf(Integer.ValueOf(entl.Product__r.Feature__c)) : '');
                String subfeature = (SetApprovalTypeHelper.isValueNotEmpty(entl.Product__r.Sub_Feature__c) ? '_' + String.ValueOf(Integer.ValueOf(entl.Product__r.Sub_Feature__c)) : '');

                if(SetApprovalTypeHelper.isValueNotEmpty(feature) || SetApprovalTypeHelper.isValueNotEmpty(subfeature)){
                    String key = approvedQuote.Id + feature + (SetApprovalTypeHelper.isValueNotEmpty(subfeature) && SetApprovalTypeHelper.featureWithSubfeature.contains(feature) ? subfeature : '');
                    if(currentDiscounts == null || !currentDiscounts.containsKey(key)) {
                        filteredEntitlementList.add(entl);
                    }
                }
            }

            if(filteredEntitlementList.isEmpty()) {
                System.debug('no entitlements after filtering');
                return null;
            }

            return buildProductInfoMap(filteredEntitlementList, approvedQuote.PriceBook2.Service__c, approvedQuote.PriceBook2.Plan__c, approvedQuote.CurrencyIsoCode, oneTimeFeatureTypes, withoutSubFeatureTypes);
        }

        private Map<String, productInfo> buildProductInfoMap(List<Entitlement__c> entitlementList, String pbService, String pbPlan, String quoteCurrencyIsoCode, Set<Decimal> oneTimeFeatureTypes, Set<Decimal> withoutSubFeatureTypes) {

            if(entitlementList == null || entitlementList.isEmpty()) {
                System.debug('entitlementList is null or empty');
                return null;
            }

            if(oneTimeFeatureTypes == null || withoutSubFeatureTypes == null) {
                System.debug('oneTimeFeatureTypes or withoutSubFeatureTypes is null');
                return null;
            }

            Map<String, productInfo> productInfoMap = new Map<String, productInfo>();

            for(Entitlement__c entl : entitlementList) {

                Decimal feature = entl.Product__r.Feature__c;
                Decimal subfeature = entl.Product__r.Sub_Feature__c;

                if((feature != null || subfeature != null) && entl.Discount_Type__c != '' && !(feature == 28 && pbService == 'Office')) {

                    String chargeTerm;
                    if(oneTimeFeatureTypes.contains(feature)){
                        chargeTerm = trimSpaces('One - Time');
                    }else{
                        if(pbPlan == 'Annual'){
                            chargeTerm = Product2Helper.CHARGE_TERM_ANNUAL;
                        }else if(pbPlan == 'Monthly' || pbPlan == 'Monthly - Contract'){
                            chargeTerm = 'Monthly';
                        }
                    }

                    List<lineItemInfo> lineItemList = new List<lineItemInfo>();
                    lineItemList.add(
                        new lineItemInfo(
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            quoteCurrencyIsoCode,
                            entl.Discount__c,
                            entl.Discount_Type__c,
                            entl.Discount__c
                        )
                    );

                    productInfo productInfoItem = new productInfo(
                        null,
                        null,
                        null,
                        null,
                        chargeTerm,
                        null,
                        null,
                        feature,
                        !withoutSubFeatureTypes.contains(feature) ? subfeature : null,
                        lineItemList
                    );

                    String f = (SetApprovalTypeHelper.isValueNotEmpty(feature) ? String.ValueOf(feature) : '');
                    String sub = (SetApprovalTypeHelper.isValueNotEmpty(subfeature) && !withoutSubFeatureTypes.contains(feature) ? '_' + String.ValueOf(subfeature) : '');
                    String key = f + sub;

                    productInfoMap.put(key, productInfoItem);
                }
            }

            return productInfoMap;
        }


        private List<productInfo> createExtensionForFeature17(List<productInfo> productList, Map<Id,QuoteLineItem> lineItemsMap) {

            List<productInfo> feature17ProductList = filterProductsByFeature(productList, 17);

            if( feature17ProductList != null ) {

                productInfo feature17ProductInfo = feature17ProductList[0];

                productInfo virtualExtension = createVirtualExtensionProduct(feature17ProductInfo, lineItemsMap);

                System.debug('found ProductInfo with feature 17 >>> ' + feature17ProductInfo);
                System.debug('created virtualExtension >>> ' + virtualExtension);

                productList.add( virtualExtension );
            }

            return productList;
        }

        private List<productInfo> filterProductsByFeature(List<productInfo> productListToFilter, Decimal feature) {

            if(productListToFilter == null) {
                return null;
            }

            List<productInfo> filtered = new List<productInfo>();

            for(productInfo productInfoItem : productListToFilter) {

                if( productInfoItem != null && (productInfoItem.productFeature == feature) ) {

                    filtered.add(productInfoItem);
                }
            }

            if(filtered.size() > 0) {
                return filtered;
            }else{
                return null;
            }
        }


        private productInfo createVirtualExtensionProduct(productInfo productToMakeVirtual, Map<Id,QuoteLineItem> lineItemsMap) {

            List<lineItemInfo> lineItemList = new List<lineItemInfo>();

            for(lineItemInfo item : productToMakeVirtual.lineItems) {
                lineItemInfo virtualLineItemInfo = new lineItemInfo(
                    item.lineItemId,
                    VIRTUAL_PRODUCT_FULL_NAME,
                    item.effectivePrice,
                    item.listPrice,
                    item.quantity,
                    item.subCategory,
                    item.totalInitialPrice,
                    item.totalMonthlyPrice,
                    item.totalPrice,
                    VIRTUAL_PRODUCT_CATEGORY,
                    item.str_currency,
                    getVirtualExtensionDiscountInPercents(lineItemsMap.get(item.lineItemId)),
                    QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    item.effectiveDiscount
                );

                lineItemList.add( virtualLineItemInfo );
            }

            productInfo virtualExtensionProduct = new productInfo(
                VIRTUAL_PRODUCT_FULL_NAME,
                productToMakeVirtual.productId,
                VIRTUAL_PRODUCT_CATEGORY,
                productToMakeVirtual.productSubCategory,
                productToMakeVirtual.chargeTerm,
                productToMakeVirtual.productType,
                VIRTUAL_SERVICE_TYPE,
                VIRTUAL_PRODUCT_FEATURE,
                productToMakeVirtual.productSubFeature,
                lineItemList
            );

            return virtualExtensionProduct;
        }


        private Decimal getVirtualExtensionDiscountInPercents(QuoteLineItem qli) {
          Decimal result = qli.Discount;

          if (qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
            Decimal monthlyContractDiscount = qli.PriceBookEntry.Monthly_Contract_Discount__c == null ? 0 : qli.PriceBookEntry.Monthly_Contract_Discount__c;
            if (qli.UnitPrice != null && qli.Discount != null) {
              Decimal currencyDiscountWithMcd = (qli.UnitPrice * qli.Discount / 100 + monthlyContractDiscount);
              result = (currencyDiscountWithMcd * 100 / (qli.UnitPrice + monthlyContractDiscount)).setScale(2,System.RoundingMode.HALF_UP);
            }
          }

          return result;
        }
    }

    public static final String VIRTUAL_PRODUCT_FULL_NAME = 'Active Virtual Extensions';
    public static final String VIRTUAL_PRODUCT_CATEGORY = 'Add - Ons';
    public static final String VIRTUAL_SERVICE_TYPE = null;
    public static final Decimal VIRTUAL_PRODUCT_FEATURE = 58;

    public static Map<String, Decimal> getDiscount(Map<Id, QuoteLineItem> qlisMap) {
        Map<String, Decimal> discountsMap = new Map<String, Decimal>();
        for(QuoteLineItem qli : qlisMap.values()) {
            String fkey = qli.Product2.Feature__c + '%' + qli.Product2.Sub_Feature__c;
            discountsMap.put(fkey, qli.PriceBookEntry.Monthly_Contract_Discount__c == null ? 0 : qli.PriceBookEntry.Monthly_Contract_Discount__c);
        }

        System.debug(' getDiscount >>> ' + discountsMap);
        return discountsMap;
    }

    @HttpPost
    global static void getDiscountApproval() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        ApprovalWrapper wrapperObj = new ApprovalWrapper();
        String requestBody = req.requestBody.toString();
        GWRequestCall requestParams = (GWRequestCall)JSON.deserialize(requestBody, GWRequestCall.class);
        res.addHeader('Content-Type', 'application/json');
        wrapperObj = wrapperObj.generateJson(requestParams.rcUserID, requestParams.approvalID, requestParams.quoteTierID, requestParams.oppID);
        res.responseBody = blob.valueOf(JSON.serialize(wrapperObj));
        return;
    }
}