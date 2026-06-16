global with sharing class OpportunityCreationFormController {

    public String brandValues         { get; set; }
    public String brandConfiguration  { get; set; }
    public String serviceValues       { get; set; }
    public String serviceDependencies { get; set; }
    public String recordTypeName      { get; set; }
    public String recordTypeId        { get; set; }
    public String retURL              { get; set; }
    public String tiers               { get; set; }
    public Opportunity opportunityObj { get; set; }
    public String taskId              { get; set; }
    public String fromContact         { get; set; }
    public String fromContactId       { get; set; }
    public String contactCenterUsers  { get; set; }
    public String engageDigitalUsers  { get; set; }
    public String engageVoiceUsers    { get; set; }
    public String globalOfficeUsers   { get; set; }
    public String officeUsers         { get; set; }
    public String rcVideoUsers        { get; set; }
    public String oppCreationFlow     { get; set; }
    public String billingWizardURL    { get; set; }
    public String origin              { get; set; }
    public String sId                 { get; set; }
    public String userId              { get; set; }
    public OpportunityContactRole opportunityContactRoleObj { get; set; }
    public String biValues           { get; set; }
    public String fromConversionContact   { get; set; }
    public String fromConversionContactId { get; set; }

    public static String NO_ACCOUNT_FOUND = 'Contact must be linked to an account.';
    public static String CONTACT_DOWNGRADED = 'Contact status should not be downgraded.';
    public static String USER_NOT_ACC_OWNER = 'You are not the Account Owner or Current Owner on the Account.';

    /**
     * Page Controller
     * @param  stdController
     */
    public OpportunityCreationFormController(ApexPages.StandardController stdController) {
        opportunityObj = (Opportunity) stdController.getRecord();
        opportunityContactRoleObj = new OpportunityContactRole();
        billingWizardURL = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sid = SettingsService.getSessionId();

        // Get record type name
        Map < Id, Schema.RecordTypeInfo > mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();
        recordTypeName = '';
        recordTypeId = opportunityObj.RecordTypeId;
        if (mapRT.containsKey(recordTypeId)) {
            recordTypeName = mapRT.get(recordTypeId).getName();
        }

        taskId = ApexPages.currentPage().getParameters().get('taskId');
        fromContact = ApexPages.currentPage().getParameters().get('fromContact');
        fromContactId = ApexPages.currentPage().getParameters().get('fromContactId');
        contactCenterUsers = ApexPages.currentPage().getParameters().get('contactCenterUsers');
        engageDigitalUsers = ApexPages.currentPage().getParameters().get('engageDigitalUsers');
        engageVoiceUsers = ApexPages.currentPage().getParameters().get('engageVoiceUsers');
        globalOfficeUsers = ApexPages.currentPage().getParameters().get('globalOfficeUsers');
        officeUsers = ApexPages.currentPage().getParameters().get('officeUsers');
        rcVideoUsers = ApexPages.currentPage().getParameters().get('rcVideoUsers');
        oppCreationFlow = ApexPages.currentPage().getParameters().get('oppCreationFlow');
        fromConversionContact = ApexPages.currentPage().getParameters().get('fromConversionContact');
        fromConversionContactId = ApexPages.currentPage().getParameters().get('fromConversionContactId');

        // Get picklist values
        brandValues = JSON.serialize(OpportunityHelper.getBrandOptions());
        brandConfiguration = JSON.serialize(LeadConversionConfiguration__c.getAll().values());
        serviceValues = JSON.serialize(OpportunityHelper.getTierNameOptions());
        serviceDependencies = JSON.serialize(OpportunityHelper.getServiceDependency());
        biValues = SettingsService.getBusinessIdentityMappingJSON();

        // Get tiers
        Map < String, String > tiersParams = new Map < String, String > {'recordTypeName' => recordTypeName};
        tiers = JSON.serialize(QuotingToolQuoteApexController.getTiers(tiersParams));

        // Return url for cancel button
        retURL = ApexPages.currentPage().getParameters().get('retURL');

        userId = UserInfo.getUserId();
    }

    /**
     * Action method to check for Supported record type
     * Redirects to old opportunity Contact Selection page with all GET parameters
     */
    public static PageReference checkRecordType() {
        // get Record Type name
        String recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        Map < Id, Schema.RecordTypeInfo > mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();
        String rtName = '';
        if (mapRT.containsKey(recordTypeId)) {
            rtName = mapRT.get(recordTypeId).getName();
        }
        // check record Type Name
        if (rtName != 'New Sales Opportunity' && rtName != 'VAR Opportunity') {
            Map < String, String > urlParams = ApexPages.currentPage().getParameters();
            PageReference opportunityContactSelection = new PageReference('/apex/OpportunityContactSelection');
            opportunityContactSelection.getParameters().putAll(urlParams);
            opportunityContactSelection.setRedirect(true);
            return opportunityContactSelection;
        }
        return null;

    }

    /**
     * Add products to Cart (QuoteLineItems)
     *
     * @param  params
     *             - pricebook2Id
     *             - quantity
     *             - quoteId
     *
     * @return message
     *             - status
     *             - message
     */
    @AuraEnabled
    public static Map < String, String > createAdditionalSoftphoneQLIs(Map < String, String > params) {
        Map < String, String > result = new Map < String, String > ();

        String pricebook2Id = params.get('pricebook2Id');
        Integer quantity = Integer.valueOf(params.get('quantity'));
        String quoteId = params.get('quoteId');
        //Id priceBookId;
        List < QuoteLineItem > qlisToInsert = new List < QuoteLineItem > ();
        List < Area_Code_Line_Item__c > aclisToInsert = new List < Area_Code_Line_Item__c > ();
        if(quantity > 0) {
            for (PriceBookEntry pBookEntry: [SELECT Id, Name, CurrencyIsoCode, Pricebook2Id, Product2Id, UnitPrice, Per_Line__c, Min_Quantity__c, Product2.Description, Pricebook2.Line_Range_Min__c
                    FROM PriceBookEntry
                    WHERE Pricebook2Id = : pricebook2Id
                    AND Product2.Feature__c = 11
                    AND Product2.Sub_Feature__c = -1
                    AND Product2.Family = 'Discounted Phones'
                ]) {
                QuoteLineItem newQ = new QuoteLineItem();
                newQ.ServiceDate = date.today();
                newQ.Description = pBookEntry.Product2.Description;
                newQ.UnitPrice = pBookEntry.UnitPrice;
                newQ.QuoteId = quoteId;
                newQ.PriceBookEntryId = pBookEntry.Id;
                newQ.Product2Id = pBookEntry.Product2Id;
                QuoteLineItemHelper.setQuantity(newQ, quantity);
                qlisToInsert.add(newQ);
            }
        }

        if (qlisToInsert.size() > 0) {

            try {
                insert qlisToInsert;

                if(params.containsKey('mainAreaCodeId') && !String.isBlank(params.get('mainAreaCodeId'))) {
                    for(QuoteLineItem qli : qlisToInsert) {
                        aclisToInsert.add(new Area_Code_Line_Item__c(
                            Area_Code__c = params.get('mainAreaCodeId'),
                            Quantity__c = QuoteLineItemHelper.getQuantity(qli),
                            Quote_Line_Item__c = qli.Id));
                    }
                }

                if(aclisToInsert.size() > 0) {
                    insert aclisToInsert;
                }

                result.put('status', 'success');
                result.put('message', 'Softphones added to cart');

            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }

        }

        return result;
    }


    @AuraEnabled
    public static Map < String, String > createOppty(Map < String, String > params) {
        Map < String, String > result = new Map < String, String > ();

        // Opportunity params
        Id contactId = params.get('contactId');

        // Create Opportunity
        Opportunity newOppty = new Opportunity(
            Name                = params.get('name'),
            CurrencyIsoCode     = RingCentralHelper.brandToCurrencyIsoCode(params.get('brandName')),
            AccountId           = params.get('accountId'),
            StageName           = params.get('stageName'),
            Brand_Name__c       = params.get('brandName'),
            Type                = params.get('type'),
            Tier_Name__c        = params.get('service'),
            RecordTypeId        = params.get('recordTypeId'),
            LeadSource          = params.get('leadSource'),
            CloseDate           = Date.valueOf(params.get('closeDate')),
            Forecasted_Users__c = Integer.valueOf(params.get('forecastedUsers')),
            Is_Billing_Opportunity__c      = Boolean.valueOf(params.get('isBillingOpportunity')),
            Primary_Opportunity_Contact__c = contactId,
            GoldfingerRetention__c = params.get('retention'),
            ProvisioningDetails__c = params.get('provisioningDetails'),
            Conversion_Contact__c	= params.get('conversionContactId')
        );

        OpportunityContactRole newOppContactRole = new OpportunityContactRole(
                    ContactId = contactId,
                    Role = params.get('contactRole')
                );

        try {
            insert newOppty;

            newOppContactRole.OpportunityId = newOppty.Id;

            List<OpportunityContactRole> rolesFound = [
                SELECT Id
                FROM OpportunityContactRole
                WHERE OpportunityId = :newOppty.Id
                AND Role = :OpportunityHelper.CONTACT_ROLE_SIGNATORY
                LIMIT 1
            ];

            if(!rolesFound.isEmpty()) {
                newOppContactRole.Id = rolesFound[0].Id;
            }

            upsert newOppContactRole;

            result.put('status', 'success');
            result.put('message', 'Opportunity successfully created.');
            result.put('opportunityId', newOppty.Id);

        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }

        return result;

    }

    @AuraEnabled
    public static Map < String, String > createQuote(Map < String, String > params) {
        Map < String, String > result = new Map < String, String >();

        // Quote Params
        String tierId = params.get('tierId');
        String upsellStatus = params.get('upsellStatus');
        Id mainAreaCodeId = params.get('mainAreaCodeId');
        String isMainPhoneVanity = params.get('isMainPhoneVanity');

        // Create Quote
        Map <String, String> quoteParams = new Map <String, String> {
            'opportunityId'         => params.get('opportunityId'),
            'pricebook2Id'          => tierId,
            'lines'                 => params.get('lines'),
            'mainAreaCodeId'        => mainAreaCodeId,
            'isMainPhoneVanity'     => params.get('isMainPhoneVanity'),
            'shippingCountry'       => params.get('shippingCountry'),
            'shippingCity'          => params.get('shippingCity'),
            'shippingState'         => params.get('shippingState'),
            'shippingAddressLine'   => params.get('shippingAddressLine'),
            'shippingPostalCode'    => params.get('shippingPostalCode'),
            'shippingShippingOption'        => params.get('shippingShippingOption'),
            'shippingShipAttentionTo'       => params.get('shippingShipAttentionTo'),
            'shippingAdditionalAddressLine' => params.get('shippingAdditionalAddressLine'),
            'shippingCustomerName'          => params.get('shippingCustomerName'),
            'shippingMultipleLocations'     => params.get('shippingMultipleLocations'),
            'isCC'                  => params.get('isCC')
        };

        if(String.isNotEmpty(mainAreaCodeId)){
            Boolean isMainNot800 = [
                SELECT COUNT()
                FROM Area_Codes__c
                WHERE Id = :mainAreaCodeId AND Area_Code__c != 800
                LIMIT 1
            ] > 0;
            if (isMainNot800) {
                quoteParams.put('faxAreaCodeId', mainAreaCodeId);
                quoteParams.put('isFaxPhoneVanity', isMainPhoneVanity);
            }
        }

        if (params.containsKey('upsellStatus')) {
            quoteParams.put('upsellStatus', upsellStatus);
        }

        System.debug('0');
        System.debug(quoteParams);
        String newQuoteId = QuotingToolQuoteApexController.saveQuote(quoteParams);
        System.debug('1000');

        result.put('status', 'success');
        result.put('message', 'Quote successfully created.');
        result.put('quoteId', newQuoteId);
        result.put('pricebook2Id', tierId);
        return result;
    }

    /**
     * Creates Quote Line Items On Quote From Entitlements
     *
     * @param params
     * @param params.quoteId
     * @param params.additionalForecastedUsers
     */
    @AuraEnabled
    public static List<QuoteLineItem> addEntitlementsAsLineItems(Map<String, String> params) {
        return addEntitlementsAsLineItems(params, true);
    }

    public static List<QuoteLineItem> addEntitlementsAsLineItems(Map<String, String> params, Boolean isDMLsNeeded) {
        String quoteId = params.get('quoteId');
        Decimal additionalLines = params.get('additionalForecastedUsers') == null
                ? null
                : Decimal.valueOf(params.get('additionalForecastedUsers'));

        List<QuoteLineItem> qlisToAdd = new List<QuoteLineItem>();
        if (quoteId != null) {

            Quote quote = [
                    SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, RecordType.Name,
                    (SELECT Id, Product2Id, Product_Type__c, Product2.Feature__c, Quantity,
                            Product2.Number_of_Minutes__c, QuoteId, Product2.Add_Overages__c, Zero_Quantity__c,
                            Entitlement__r.Id, Deactivated__c, Product2.Dependent_on_Feature__c FROM QuoteLineItems)
                    FROM Quote
                    WHERE Id = :quoteId
            ];

            List<Entitlement__c> queriedEntitlements = [
                    SELECT Id, Quantity__c, DisplayQuantity__c, Price__c, Discount__c, Discount_Type__c, Account__c,
                            Product__c, Product__r.Edition__c, Product__r.Number_of_Minutes__c,
                            Product__r.Family, Product__r.Product_Type__c, Product__r.Sub_Category__c,
                            Product__r.Name, Active__c, Product__r.ExtID__c, Product__r.Charge_Term__c
                    FROM Entitlement__c
                    WHERE Account__c = :quote.AccountId
                    AND Active__c = true
                    AND Product__r.Cart_Tab_Availability__c INCLUDES(:quote.RecordType.Name)
                    AND Product__r.Family != '' AND  Product__r.Family != :Product2Helper.FAMILY_FEE AND Product__r.Charge_Term__c != :Product2Helper.CHARGE_TERM_ONE_TIME
            ];

            List<Entitlement__c> entitlements = EntitlementHelper.filterEntitlementsByChargeTerm(queriedEntitlements);

            List<PricebookEntry> pricebookEntriesFromSF = [
                    SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                            Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                            Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                            Product2.Matcher_Formula__c, Product2.ExtID__c, Product2.Advanced_Matcher_Formula__c,
                            Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                            Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c, Pricebook2Id,
                            Pricebook2.isStandard, isActive, Product2.Upsell_Matcher_Formula__c
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :quote.Pricebook2Id
                    AND isActive = true
            ];

            if (entitlements.size() > 0) {
                EntitlementSync.EntitlementsParams ep = new EntitlementSync.EntitlementsParams();
                ep.pricebook2Id = quote.Pricebook2Id;
                ep.quoteId = quoteId;
                ep.additionalLines = additionalLines;
                ep.entitlements = entitlements;
                ep.pricebookEntries = pricebookEntriesFromSF;

                if(params.containsKey('type')) {
                    ep.quoteUpsellStatus = params.get('type');
                }

                qlisToAdd = EntitlementSync.createLineItemsFromEntitlements(ep);

                qlisToAdd.addAll(QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                        qlisToAdd,
                        pricebookEntriesFromSF,
                        entitlements,
                        quote.QuoteLineItems,
                        new List<Quote>{quote}
                ));

                if (isDMLsNeeded && qlisToAdd != null && qlisToAdd.size() > 0) {
                    insert qlisToAdd;
                }
            }
        }

        return qlisToAdd;
    }

    /**
    * Returns URL for redirecting to Opty creation page from task
    *
    * @param contactId - contact Id from Task's Who field
    * @return redirectURL - map with operation status & url to Opportunity creation page with Account & Contact defined
    */
    webService static String getUrlForTask(String contId, String taskId) {
        Map<String, String> result = new Map<String, String>();
        try {
            Contact[] contList = [SELECT Id, AccountId FROM Contact WHERE Id = :contId LIMIT 1];

            Map <String, Schema.RecordTypeInfo> mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
            Id rtId = mapRT.get('New Sales Opportunity').getRecordTypeId();

            String redirectUrl = '/apex/OpportunityCreationForm?RecordType=' + rtId + '&ent=Opportunity&save_new=1&sfdc.override=1&taskId=' + taskId;
            if(contList.size()>0) {
                redirectUrl+='&accid=' + contList[0].AccountId + '&conid=' + contList[0].Id;
            }
            result.put('status', 'success');
            result.put('message', 'Redirecting to opportunity creation page');
            result.put('redirectUrl', redirectUrl);

            return JSON.serialize(result);
        } catch (Exception e) {
            result.put('status', 'error');
            result.put('header', 'Error occurred during URL creation');
            result.put('message', e.getStackTraceString() + '<br/>' + e.getMessage());

            return JSON.serialize(result);
        }
    }
    webService static String getUrlForRetention(String accId) {
        Map<String, String> result = new Map<String, String>();
        try {
            Map <String, Schema.RecordTypeInfo> mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
            Id rtId = mapRT.get('New Sales Opportunity').getRecordTypeId();

            String redirectUrl = '/apex/OpportunityCreationForm?RecordType=' + rtId + '&ent=Opportunity&save_new=1&sfdc.override=1';

                redirectUrl+='&accid=' + accId;

            result.put('status', 'success');
            result.put('message', 'Redirecting to opportunity creation page');
            result.put('redirectUrl', redirectUrl);

            return JSON.serialize(result);
        } catch (Exception e) {
            result.put('status', 'error');
            result.put('header', 'Error occurred during URL creation');
            result.put('message', e.getStackTraceString() + '<br/>' + e.getMessage());

            return JSON.serialize(result);
        }
    }
    /**
    * Updates task's status to 'Completed with Opp'
    */
    @AuraEnabled
    public static void updateTask(Map<String, String> params) {
        String taskId = params.get('taskId');
        String opportunityId = params.get('opportunityId');
        if (String.isNotBlank(taskId)) {
            Task tsk = new Task(
                    Id = taskId,
                    WhatId = opportunityId,
                    Status = 'Completed with opp'
            );

            update tsk;
        }
    }

    /**
     * Fix number of Extended Enterprise Support products according to service plan
     *
     * @see Test_ExtendedEnterpriseSupport Test Class
     * @see QuotingToolQuoteApexController.handleExtendedEnterpriseSupport Wrapper
     * @see QuoteLineItemHelper.handleExtendedEnterpriseSupport Implementation
     *
     * @param quoteId
     */
    @AuraEnabled
    public static void handleExtendedEnterpriseSupport(Id quoteId) {
        QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(quoteId);
    }

    @AuraEnabled
    public static List<Entitlement__c> getEntitlementsSync(String accId) {
        return QuotingToolQuoteApexController.getEntitlementsSync(accId);
    }

    @AuraEnabled
    public static List<PriceBookEntry> getPriceBookEntry(List<Id> productsId) {
        return QuotingToolQuoteApexController.getPriceBookEntry(productsId);
    }

    @AuraEnabled
    public static List<PriceBookEntry> getProducts(Id pricebook2Id, String opportunityRecordTypeName) {
        List<PricebookEntry> prods = QuotingToolQuoteApexController.getProducts(pricebook2Id, true, opportunityRecordTypeName);
        List<PricebookEntry> filteredProds = new List<PricebookEntry>();

        List<OpportunityCreationProductsAvailability__c> settings = OpportunityCreationProductsAvailability__c.getAll().values();
        for (PricebookEntry p : prods) {
            for (OpportunityCreationProductsAvailability__c s : settings) {
                Boolean featureMatch = String.isBlank(s.Feature__c)
                    || Decimal.valueOf(s.Feature__c) == p.Product2.Feature__c;
                Boolean subcategoryMatch = String.isBlank(s.Sub_Category__c)
                    || s.Sub_Category__c == p.Product2.Sub_Category__c;
                Boolean familyMatch = String.isBlank(s.Family__c)
                    || s.Family__c == p.Product2.Family;

                if (featureMatch && subcategoryMatch && familyMatch) {
                    filteredProds.add(p);
                    break;
                }
            }
        }

        return filteredProds;
    }

    @AuraEnabled
    public static List<PricebookEntry> getServicePricebookEntryByAccountEnts(Id accountId) {
        Entitlement__c[] ents = QuotingToolQuoteApexController.getEntitlements(accountId);
        Entitlement__c serviceEnt = EntitlementHelper.getServiceEntitlement(QuoteHelper.RT_ID_SALES, ents);
        return (serviceEnt != null ? QuotingToolQuoteApexController.getPricebookEntry(new List<Id> { serviceEnt.Product__c }) : null);
    }

    public class AddProductsParams {
        @AuraEnabled public String quoteId;
        @AuraEnabled public List<ProductToAddParams> productsToAdd;
        @AuraEnabled public Map<Decimal, Decimal> featureToQuantityMap;
        @AuraEnabled public Map<String, String> qlisFromEntitlements;

        public Map<Id, Decimal> getPricebookEntryIdToQuantity() {
            Map<Id, Decimal> result = new Map<Id, Decimal>();

            for (ProductToAddParams p : productsToAdd) {
                result.put(p.pricebookEntryId, p.quantity);
            }

            return result;
        }

        public List<Area_Code_Line_Item__c> getAreaCodesForPBE(Id pbeId) {
            List<Area_Code_Line_Item__c> result = new List<Area_Code_Line_Item__c>();
            ProductToAddParams p = getProdParams(pbeId);

            if (p != null) {
                result = p.getAreaCodeLineItems();
            }

            return result;
        }

        private ProductToAddParams getProdParams(Id pbeId) {
            for (ProductToAddParams p : productsToAdd) {
                if (p.pricebookEntryId == pbeId) {
                    return p;
                }
            }
            return null;
        }
    }

    public class ProductToAddParams {
        @AuraEnabled public Id pricebookEntryId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public List<AreaCodeToAdd> areaCodesToAdd;

        public List<Area_Code_Line_Item__c> getAreaCodeLineItems() {
            List<Area_Code_Line_Item__c> result = new List<Area_Code_Line_Item__c>();
            for (AreaCodeToAdd ac : areaCodesToAdd) {
                result.add(new Area_Code_Line_Item__c(
                    Area_Code__c = ac.areaCodeId,
                    Quantity__c = ac.quantity
                ));
            }
            return result;
        }
    }

    public class AreaCodeToAdd {
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Id areaCodeId;
    }

    @AuraEnabled
    public static void addProductsWrapper(String p) {
        // Lightning fails to properly pass custom type variable. Have to convert it first
        // https://salesforce.stackexchange.com/questions/145357/salesforce-system-error-when-accessing-a-list-in-auraenabled-method
        // Salesforce issue W-3159538
        AddProductsParams pConverted = (AddProductsParams) JSON.deserialize(p, AddProductsParams.class);
        addProducts(pConverted);
    }

    @AuraEnabled
    public static void addProducts(addProductsParams p) {
        try {
            List<QuoteLineItem> qlis = QuotingToolQuoteApexController.createQuoteLineItems(
                p.quoteId,
                p.getPricebookEntryIdToQuantity(),
                p.featureToQuantityMap,
                p.qlisFromEntitlements);
            List<Area_Code_Line_Item__c> aclis = new List<Area_Code_Line_Item__c>();

            // Collect area codes and populate Quote Line Items
            for (QuoteLineItem q : qlis) {
                List<Area_Code_Line_Item__c> qliACLIs = p.getAreaCodesForPBE(q.PricebookEntryId);

                for (Area_Code_Line_Item__c acli : qliACLIs) {
                    acli.Quote_Line_Item__c = q.Id;
                }

                aclis.addAll(qliACLIs);
            }

            if (aclis.size() > 0) {
                upsert aclis;
            }

        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }
    }

    @AuraEnabled
    public static Response getDataOnInit(){
        Response r = new Response();

        r.setData('Feature_Toggle__c', Feature_Toggle__c.getInstance());
        r.setData('userCustomPermissions', new CustomPermissionHelper().getPermissionMap());

        return r;
    }

    @AuraEnabled
    public static void confirmAndCloseOppty(Id opportunityId, Id quoteId) {
        Boolean confirmAndClose = OpportunityHelper.isCustomerConfirmationEmailFlow(opportunityId);

        try {
            update new Opportunity(
                Id = opportunityId,
                ConfirmAndClose__c = confirmAndClose,
                StageName = OpportunityHelper.STAGE_NAME_ORDER,
                CW_Primary_Win_Reason__c = 'Existing Customer/Upsell',
                CW_Who_did_we_beat__c = 'Existing Customer',
                CW_Who_did_we_replace__c = 'Existing Customer'
            );

            update new Quote(
                Id = quoteId,
                Status = QuoteHelper.QUOTE_STATUS_PRESENTED
            );

        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }
    }

    @AuraEnabled
    public static String validateContact(Id ContactId) {
        try{
            Map<String,String> retMap = new Map<String,String>();
            Boolean isCurrentUser = false;
            Boolean hasError = false;
            List<Contact> contacts = new ContactSelector().selectAccountByContactId(new List<Object>{
                ContactId
            }).executeQuery();

            Contact contact = contacts[0];

            if(contact.AccountId == null){
                hasError = true;
                retMap.put('ERROR',NO_ACCOUNT_FOUND + ' - MSG');
            }

            if(contact.Contact_Status__c == '0. Downgraded'){
                hasError = true;
                retMap.put('ERROR',CONTACT_DOWNGRADED + ' - MSG');
            }

            if(contact.Account.OwnerId == UserInfo.getUserId() || contact.Account.Current_Owner__c == UserInfo.getUserId()){
                isCurrentUser = true;
            }

            if(!isCurrentUser){
                retMap.put('WARNING',USER_NOT_ACC_OWNER);
            }

            if(!hasError){
                retMap.put('RECORD',JSON.serialize(contact));
            }

            return JSON.serialize(retMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createPrimaryContactRole(Id acctId, Id contactId){
        try {
            AccountContactRole acr = new AccountContactRole(
                AccountId = acctId,
                ContactId = contactId,
                IsPrimary = true
            );
            insert acr;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void checkAcctContactRole(Id acctId, Id contactId){
        try {
            Boolean hasValidAcr = false;
            List<Object> bindings = new List<Object>();
            List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                    .selectPrimaryOrSignatoryContactRoles(new List<Id> { acctId }).executeQuery();

            if (acrList.isEmpty()) {
                createPrimaryContactRole(acctId,contactId);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Contact getContactRecord(String contactId){
        try{
            Id conId = (Id) contactId;
            List<Contact> contacts = new ContactSelector().selectAccountByContactId(new List<Object>{
                conId
            }).executeQuery();

            return contacts[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOpportunityFromContact(Id opportunityId, String contactId) {
        try{
            Contact con = getContactRecord(contactId);

            if(String.isNotBlank(opportunityId)){
                Opportunity opp = new Opportunity(
                    Id = opportunityId,
                    OwnerId = UserInfo.getUserId(),
                    BDR_Agent2__c = con.BDR_Agent2__c,
                    SDR_Agents__c = con.SDR_Agents__c
                );

                update opp;
            }

            DescribeSObjectResult sobjectResult = Lead_Qualification__c.SObjectType.getDescribe();
            List<String> fieldNames = new List<String>();
            Map<String,Schema.SObjectField> fields = sobjectResult.fields.getMap();
            for(String fld : fields.keySet()){
                Schema.DescribeFieldResult fld1 = fields.get(fld).getDescribe();
                if(fld1.isCreateable()){
                    fieldNames.add(fld);
                }
            }

            String query =' SELECT ' + String.join(fieldNames, ',' ) +' FROM Lead_Qualification__c WHERE Contact__c = :contactId';
            List<Lead_Qualification__c> existingLeadQual = Database.query(query);
            List<Lead_Qualification__c> insLq = new List<Lead_Qualification__c>();

            for(Lead_Qualification__c lq: existingLeadQual){
                Lead_Qualification__c clonedLq = lq.clone(false,true,false,false);
                clonedLq.Opportunity__c = opportunityId;
                clonedLq.Contact__c = null;
                insLq.add(clonedLq);
            }

            if(!insLq.isEmpty()){
                insert insLq;
            }

            if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached() && !System.isBatch()) {
                System.enqueueJob(new OpportunityCreationFormController.Queueable_ContactActivitiesInsert(contactId, opportunityId));
            } else {
                Contact_ActivitiesInsert(contactId, opportunityId);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void Contact_ActivitiesInsert(Id contactId, Id opportunityId) {

        DescribeSObjectResult describeResult = Task.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        String query =' SELECT ' + String.join( fieldNames, ',' ) +' FROM Task WHERE WhoId = :contactId AND CreatedDate = LAST_N_DAYS:180';
        List<Task> existingTasks = Database.query(query);
        List<Task> insTask = new List<Task>();

        for(Task t : existingTasks){
            Task clonedT = t.clone(false,true,false,false);
            clonedT.WhoId = null;
            clonedT.WhatId = opportunityId;
            insTask.add(clonedT);
        }

        if(!insTask.isEmpty()){
            TriggerHandler.BY_PASS_BEFORE = true;
            TriggerHandler.BY_PASS_AFTER = true;
            insert insTask;
        }

    }

    public class Queueable_ContactActivitiesInsert implements Queueable{
        public Id contactId;
        public Id opportunityId;
        public Queueable_ContactActivitiesInsert(Id contactId, Id opportunityId){
            this.contactId = contactId;
            this.opportunityId = opportunityId;
        }

        public void execute(QueueableContext context){
            Contact_ActivitiesInsert(contactId, opportunityId);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<GSP_Partner_Setup__c> getPartnerSettings() {
        return GSP_Partner_Setup__c.getAll().values();
    }
}