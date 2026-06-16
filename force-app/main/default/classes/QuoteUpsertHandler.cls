public class QuoteUpsertHandler implements IResourceHandler {

    public class QuoteRequest {
        public Boolean enabledLBO;
        public Boolean isPOC;
        public Boolean isPRMQuote;
        public Boolean isQuoteHasErrors;
        public Boolean isRemoveAreaCodes;
        public Id accountId;
        public Id id;
        public Id opportunityId;
        public String dataRetentionDuration;
        public String freeShippingTerms;

        public String name;
        public String packageInfo;
        public String paymentMethod;
        public String recordTypeId;

        public String specialTerms;
        public String status;
        public String upsellStatus;
        public Boolean isPrimary;

        public BillingWrappers.AreaCodeData faxAreaCodeInfo {get;set;}
        public BillingWrappers.AreaCodeData mainAreaCodeInfo {get;set;}

        public String initialTerm;
        public String initialTermPOC;
        public String renewalTerm;
        public Boolean autoRenewal;
        public String startDate;
        public String endDate;
        public String expirationDate;
        public Boolean updateContractTerms;

        public String serviceName;

        public String justification;
        public String noteToCustomer;

        public Decimal creditAmount;
        public Decimal freeServiceTaxes;

        public String quoteType;
        public Boolean isTaxesAdded;

        public Decimal averageDiscount;
        public Decimal overallDiscretion;

        public Boolean isTermination;
        public Boolean isLBODealDeskProvision;
        public Boolean isSendOrderToNGBS;

        // Shipping fields
        public String shippingShipAttentionTo;
        public String shippingCountry;
        public String shippingCity;
        public String shippingState;
        public String shippingAddressLine;
        public String shippingPostalCode;
        public String shippingAdditionalAddressLine;
        public String shippingCustomerName;
        public String shippingShippingOption;
        public Boolean shippingMultipleLocations;

        // Opp fields
        public String opportunityProvisioningDetails;
        public String rcAccountNumber;
        public String ccAccountNumber;
        public Boolean opportunitySelfProvisioned;
        public Boolean isTerminationOpportunity;

        public Boolean isPOC() {
            return this.isPOC != null && this.isPOC;
        }
    }

    public ApiResponse execute(ApiRequest request) {
        try {
            List<QuoteRequest> quoteRequests = (List<QuoteRequest>)JSON.deserialize(
                request.requestBody,
                List<QuoteRequest>.class
            );

            verifyData(quoteRequests);

            Map<Id, Opportunity> opportunityMap = getOpportunityMap(quoteRequests);
            Map<Id, List<Package__c>> accountPackagesMap = getAccountPackagesMap(quoteRequests);

            List<Quote> quotes = processQuotes(quoteRequests, opportunityMap, accountPackagesMap);
            upsert quotes;

            /*
                These fields treats as fields on quote level in UQT but should be updated on the opportunity level.
                In order to reduce the number of http requests, we are updating the opportunity here.
            */
            Quote masterQuote = (Quote) new QuoteSelector()
                .selectQuoteByIdWithoutFields(quotes.get(0).Id)
                .selectFields(new Set<String>{'OpportunityId', 'isPrimary__c'})
                .executeQuery()
                .get(0);

            processOpportunity(quoteRequests, opportunityMap, masterQuote);

            return ApiResponse.success( getMappedQuotes(quotes) );

        } catch(Exception e) {
            return ApiResponse.error(e);
        }
    }

    private void verifyData(List<QuoteRequest> quoteRequests) {
        if (quoteRequests == null || quoteRequests.isEmpty()) {
            throw new IllegalArgumentException('No quotes provided in the request');
        }

        for (QuoteRequest req : quoteRequests) {
            if (String.isBlank(req.opportunityId)) {
                throw new IllegalArgumentException('Opportunity ID is required in the quote request');
            }
        }
    }

    private Map<Id, Opportunity> getOpportunityMap(List<QuoteRequest> quoteRequests) {
        Set<Id> oppIds = new Set<Id>();
        for(QuoteRequest req : quoteRequests) {
            oppIds.add(req.opportunityId);
        }

        List<Opportunity> opp = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesByIds(oppIds)
                .selectFields(new Set<String>{
                    'BusinessIdentity__c',
                    'Account.Active_Sales_Agreement__r.Start_Date__c',
                    'Account.Active_Sales_Agreement__r.End_Date__c',
                    'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
                    'Account.Active_Sales_Agreement__r.Term_months__c',
                    'Account.Active_Sales_Agreement__r.Auto_Renewal__c'})
                .subselect(
                    new QuoteSelector()
                        .selectQuotes()
                )
                .executeQuery();

        return new Map<Id, Opportunity>(opp);
    }

    private Map<Id, List<Package__c>> getAccountPackagesMap(List<QuoteRequest> quoteRequests) {
        Set<Id> accountIds = new Set<Id>();
        for (QuoteRequest req : quoteRequests) {
            if (String.isNotBlank(req.accountId)) {
                accountIds.add(req.accountId);
            }
        }

        List<Package__c> packages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountIds(new List<Id>(accountIds))
            .executeQuery();

        Map<Id, List<Package__c>> accountPackagesMap = new Map<Id, List<Package__c>>();
        for (Package__c p : packages) {
            if (!accountPackagesMap.containsKey(p.Account__c)) {
                accountPackagesMap.put(p.Account__c, new List<Package__c>());
            }
            accountPackagesMap.get(p.Account__c).add(p);
        }

        return accountPackagesMap;
    }

    private List<Quote> processQuotes(List<QuoteRequest> quoteRequests, Map<Id, Opportunity> opportunityMap, Map<Id, List<Package__c>> accountPackagesMap) {
        List<Quote> quotes = new List<Quote>();
        for(QuoteRequest quoteRequest : quoteRequests) {
            Opportunity opp = opportunityMap.get(quoteRequest.opportunityId);
            Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
            if (quotes.isEmpty()) {
                quotes.add(convertToQuote(quoteRequest, opp, accountPackagesMap, ft));
                if (quotes.get(0).Id == null) {
                    insert quotes;
                }
            } else {
                quotes.add(convertToTechQuote(quoteRequest, opp, quotes.get(0), accountPackagesMap, ft));
            }
        }
        return quotes;
    }

    private Quote convertToTechQuote(QuoteRequest req, Opportunity opp, Quote masterQuote, Map<Id, List<Package__c>> accountPackagesMap, Feature_Toggle__c ft) {

        BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(req.packageInfo);

        Quote quote = new Quote();

        quote.IsMultiProductTechnicalQuote__c = true;
        quote.MasterQuote__c = masterQuote.Id;
        quote.Name = getNameForTechnicalQuote(req, masterQuote);
        quote.BillingPackage__c = getBillingPackageIdForTechnicalQuote(pInfo, accountPackagesMap.get(opp.AccountId));

        // Only MP Lite tech quotes should inherit the primary status from the master quote.
        quote.isPrimary__c = req.opportunityId == masterQuote.OpportunityId ? false : masterQuote.isPrimary__c;

        quote.IsTermination__c = req.isTermination;

        populateTechnicalUser(quote);

        // core fields
        populateCoreFields(opp, quote, req);

        // Quote Status & Flags fields
        populateStatusAndFlagsFields(quote, req, ft);

        // Terms & Conditions
        populateTermsAndConditionsFields(quote, req);

        // Financial fields
        populateFinancialFields(quote, req, ft);

        // handle contract data
        // For tech quotes: populate terms only on initial creation, but dates always
        // Term synchronization is handled by:
        // - SyncDataFromMasterQuote trigger
        // - AdjustTechQuoteTermsOnMasterUpdate trigger
        Boolean isPopulateTerms = String.isBlank(req.id);
        populateContractDataFields(opp, quote, req, isPopulateTerms);

        // handle area codes
        populateAreaCodesFields(quote, req);

        // Shipping fields
        populateShippingFields(quote, req);

        // Based on Package Info fields
        populateFieldsBasedOnPackageInfo(quote, req);

        return quote;
    }

    private Quote convertToQuote(QuoteRequest req, Opportunity opp, Map<Id, List<Package__c>> accountPackagesMap, Feature_Toggle__c ft) {

        BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(req.packageInfo);

        Quote quote = new Quote();

        Integer pos = getPosition(opp);
        quote.Name = getName(req, opp, pos);
        quote.QuotePosition__c = String.isBlank(req.id) ? pos + 1 : pos;

        quote.BillingPackage__c = getBillingPackageIdForMainQuote(pInfo, accountPackagesMap.get(opp.AccountId));

        if (req.isPrimary != null) {
            quote.isPrimary__c = req.isPrimary;
        }

        // core fields
        populateCoreFields(opp, quote, req);

        // Quote Status & Flags fields
        populateStatusAndFlagsFields(quote, req, ft);

        // Terms & Conditions
        populateTermsAndConditionsFields(quote, req);

        // Financial fields
        populateFinancialFields(quote, req, ft);

        // handle contract data
        populateContractDataFields(opp, quote, req, true);

        // handle area codes
        populateAreaCodesFields(quote, req);

        // Shipping fields
        populateShippingFields(quote, req);

        // Based on Package Info fields
        populateFieldsBasedOnPackageInfo(quote, req);

        return quote;
    }

    private void populateCoreFields(Opportunity opp, Quote quote, QuoteRequest req) {
        if (!String.isBlank(req.id)) {
            quote.Id = req.id;
        }

        if (!String.isBlank(req.opportunityId)) {
            quote.OpportunityId = req.opportunityId;
        }

        if (!String.isBlank(req.accountId)) {
            quote.Account__c = req.accountId;
        }

        quote.RecordTypeId = QuoteHelper.RT_ID_BILLING;
        if (req.isPOC()) {
            quote.RecordTypeId = QuoteHelper.RT_ID_POC;
        }

        quote.Pricebook2Id = Pricebook2Helper.getStandardPricebookId();

        if (req.quoteType != null) {
            quote.QuoteType__c = req.quoteType;
        } else {
            quote.QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE;
        }

        if (String.isNotBlank(req.status)) {
            quote.Status = req.status;
        }

        if (String.isNotBlank(opp.BusinessIdentity__c)) {
            quote.BusinessIdentity__c = opp.BusinessIdentity__c;
        }

        quote.Package_Info__c = req.packageInfo;
    }

    private void populateStatusAndFlagsFields(Quote quote, QuoteRequest req, Feature_Toggle__c ft) {
        if (String.isBlank(req.id)) {
            quote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
        }
        quote.ExpirationDate = String.isNotBlank(req.expirationDate) ? Date.valueOf(req.expirationDate) : System.today().addDays(30);
        quote.Upsell_Status__c = getUpsellStatus(req);
        quote.NGBSTaxesAdded__c = BooleanHelper.toBoolean(req.isTaxesAdded);
        // TODO:
        // isTermination__c in case of termination flow
        if (ft.Enable_Account_Based_Tax_Exemption__c) {
            quote.NeedTaxesReestimation__c = false;
        }
        // IsShowSmokeModifiedMessage__c = false
        if (req.enabledLBO != null) {
            quote.Enabled_LBO__c = req.enabledLBO;
            if (req.enabledLBO) {
                quote.InvalidDiscountedPhonesQuantity__c = false;
            }
        }
        if (req.isPRMQuote != null) {
            quote.IsPRMQuote__c = req.isPRMQuote;
        }
        if (req.isQuoteHasErrors != null) {
            quote.IsQuoteHasErrors__c = req.isQuoteHasErrors;
        }
        if (req.enabledLBO != null && req.enabledLBO) {
            quote.InvalidDiscountedPhonesQuantity__c = false;
        }
        if (req.isLBODealDeskProvision != null) {
            quote.LBODealDeskProvision__c = req.isLBODealDeskProvision;
        }
        if (req.isSendOrderToNGBS != null) {
            quote.IsSendOrderToNGBS__c = req.isSendOrderToNGBS;
        }
    }

    private void populateTermsAndConditionsFields(Quote quote, QuoteRequest req) {
        quote.PaymentMethod__c = req.paymentMethod;
        quote.FreeShippingTerms__c = req.freeShippingTerms;
        quote.Special_Terms__c = req.specialTerms;
        quote.JustificationAndDescription__c = req.justification;
        quote.Note_To_Customer__c = req.noteToCustomer;
        quote.DataRetentionDuration__c = req.dataRetentionDuration;
    }

    private void populateFinancialFields(Quote quote, QuoteRequest req, Feature_Toggle__c ft) {
        if (ft.CalculateFSCInQW__c) {
            quote.Credit_Amount__c = req.creditAmount;
            quote.Free_Service_Taxes__c = req.freeServiceTaxes;
        }

        quote.OverallDiscretion__c = req.overallDiscretion;
        quote.AverageDiscount__c = req.averageDiscount;
    }

    private void populateContractDataFields(Opportunity opp, Quote quote, QuoteRequest req, Boolean isPopulateTerms) {
        // Set basic contract fields
        setBasicContractFields(quote, req, isPopulateTerms);

        // Apply contract-specific overrides if quote has contract
        if (QuoteHelper.isQuoteHasContract(quote)) {
            applyContractSpecificRules(opp, quote, req, isPopulateTerms);
        }

        // Apply product-specific overrides
        applyProductSpecificRules(opp, quote);

        // Set update flag
        quote.UpdateContractTerms__c = BooleanHelper.toBoolean(req.updateContractTerms);
    }

    private void setBasicContractFields(Quote quote, QuoteRequest req, Boolean isPopulateTerms) {
        // Always populate dates
        quote.Start_Date__c = String.isNotBlank(req.startDate) ? Date.valueOf(req.startDate) : null;
        quote.End_Date__c = String.isNotBlank(req.endDate) ? Date.valueOf(req.endDate) : null;

        if (req.autoRenewal != null) {
            quote.Auto_Renewal__c = req.autoRenewal;
        }

        quote.Initial_Term_POC__c = req.isPOC() ? req.initialTermPOC : null;

        // Only populate terms if requested
        if (isPopulateTerms) {
            quote.Initial_Term_months__c = req.initialTerm;
            quote.Term_months__c = req.renewalTerm;
        }
    }

    private void applyContractSpecificRules(Opportunity opp, Quote quote, QuoteRequest req, Boolean isPopulateTerms) {
        if (hasActiveSalesAgreement(opp)) {
            applyActiveSalesAgreementOverrides(opp, quote, req, isPopulateTerms);
        }
    }

    private Boolean hasActiveSalesAgreement(Opportunity opp) {
        return opp.Account.Active_Sales_Agreement__r != null;
    }

    private void applyActiveSalesAgreementOverrides(Opportunity opp, Quote quote, QuoteRequest req, Boolean isPopulateTerms) {
        SObject agreement = opp.Account.Active_Sales_Agreement__r;

        // Apply date field overrides: use request value if provided, otherwise use agreement value
        quote.Start_Date__c = getFieldOverride(req.startDate, (Date) agreement.get('Start_Date__c'));
        quote.End_Date__c = getFieldOverride(req.endDate, (Date) agreement.get('End_Date__c'));

        // Only apply term field overrides if requested
        if (isPopulateTerms) {
            quote.Initial_Term_months__c = getFieldOverride(req.initialTerm, (String) agreement.get('Initial_Term_months__c'));
            quote.Term_months__c = getFieldOverride(req.renewalTerm, (String) agreement.get('Term_months__c'));
            quote.Auto_Renewal__c = getFieldOverride(req.autoRenewal, (Boolean) agreement.get('Auto_Renewal__c'));
        }
    }

    private void applyProductSpecificRules(Opportunity opp, Quote quote) {
        // Handle NGBS Fax product - always use today as start date
        if (opp.Tier_Name__c == QuoteHelper.NGBS_FAX_PRODUCT) {
            quote.Start_Date__c = System.today();
        }
    }

    // Generic helper method for field overrides
    private String getFieldOverride(String requestValue, String defaultValue) {
        return String.isNotBlank(requestValue) ? requestValue : defaultValue;
    }

    private Boolean getFieldOverride(Boolean requestValue, Boolean defaultValue) {
        return requestValue != null ? requestValue : defaultValue;
    }

    private Date getFieldOverride(String requestDateValue, Date defaultValue) {
        return String.isNotBlank(requestDateValue) ? Date.valueOf(requestDateValue) : defaultValue;
    }

    private void populateAreaCodesFields(Quote quote, QuoteRequest req) {
        if (req.isRemoveAreaCodes != null && req.isRemoveAreaCodes) {
            quote.AreaCode__c = null;
            quote.FaxAreaCode__c = null;
        }
        if (req.mainAreaCodeInfo != null || req.faxAreaCodeInfo != null) {
            Map<String, Area_Codes__c> areaCodeByAreaId = getAreaCodes(req);
            Area_Codes__c mainAreaCode = req.mainAreaCodeInfo != null ? areaCodeByAreaId.get(AreaCodeService.getAreaId(req.mainAreaCodeInfo)) : null;
            Area_Codes__c faxAreaCode = req.faxAreaCodeInfo != null ? areaCodeByAreaId.get(AreaCodeService.getAreaId(req.faxAreaCodeInfo)) : null;
            quote.AreaCode__c = mainAreaCode != null ? mainAreaCode.Id : null;
            quote.FaxAreaCode__c = faxAreaCode != null ? faxAreaCode.Id : null;
        }
    }

    private void populateShippingFields(Quote quote, QuoteRequest req) {
        quote.Ship_Attention_To__c = req.shippingShipAttentionTo;
        quote.Shipping_Country__c = req.shippingCountry;
        quote.Shipping_City__c = req.shippingCity;
        quote.Shipping_State__c = req.shippingState;
        quote.Shipping_Address_Line__c = req.shippingAddressLine;
        quote.Shipping_Postal_Code__c = req.shippingPostalCode;
        quote.Shipping_Additional_Address_Line__c = req.shippingAdditionalAddressLine;
        quote.Shipping_Customer_Name__c = req.shippingCustomerName;
        quote.Shipping_Option__c = req.shippingShippingOption;
        quote.MultipleShippingLocations__c = BooleanHelper.toBoolean(req.shippingMultipleLocations);
    }

    private void populateFieldsBasedOnPackageInfo(Quote quote, QuoteRequest req) {
        quote.ServiceName__c = null;
        if (req.packageInfo == null) {
            return;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(req.packageInfo, List<BillingWrappers.QuotePackageInfo>.class);

        if (pInfos.isEmpty() || pInfos.size() != 1 || pInfos[0] == null) {
            return;
        }

        quote.ServiceName__c = pInfos[0].productName;
        if (pInfos[0].packageInfo != null) {
            quote.PackageNameNew__c = pInfos[0].packageInfo.displayName;
            quote.PackageNameOld__c = pInfos[0].packageInfo.oldPackageName;
        }
    }

    private void populateTechnicalUser(Quote quote) {
        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        if (technicalUser != null) {
            quote.OwnerId = technicalUser.Id;
        }
    }

    private String getName(QuoteRequest req, Opportunity opp, Integer pos) {
        String defaultName = opp.Name + ' ' + String.valueOf(pos + 1);
        return String.isNotBlank(req.name) ? req.name : defaultName;
    }

    private String getNameForTechnicalQuote(QuoteRequest req, Quote masterQuote) {
        return String.isNotBlank(req.name) ? req.name : String.format('{0} [system: {1}]', new List<Object> { masterQuote.Name, req.serviceName });
    }

    private Integer getPosition(Opportunity opp) {
        Integer pos = 0;
        for (Quote eqt : opp.Quotes) {
            if (eqt.QuotePosition__c != null && Integer.valueOf(eqt.QuotePosition__c) > pos) {
                pos = Integer.valueOf(eqt.QuotePosition__c);
            }
        }
        return pos;
    }

    private String getUpsellStatus(QuoteRequest req) {
        if (!String.isBlank(req.upsellStatus)) {
            return req.upsellStatus;
        }

        return String.isNotBlank(req.status)
            ? req.status
            : req.packageInfo != null
                ? QuoteHelper.STATUS_UPSELL
                : QuoteHelper.STATUS_NEW_CUSTOMER;
    }

    private String getBillingPackageIdForTechnicalQuote(BillingWrappers.QuotePackageInfo packageInfo, List<Package__c> accountPackages) {
        String billingPackageId = null;
        if (accountPackages == null || accountPackages.isEmpty()) {
            return billingPackageId;
        }
        if (String.isNotBlank(packageInfo?.packageInfo?.id)) {
            for (Package__c accountPackage : accountPackages) {
                if (accountPackage.Account_Package_Id__c == packageInfo.packageInfo.id) {
                    billingPackageId = accountPackage.Id;
                }
            }
        }
        return billingPackageId;
    }

    private String getBillingPackageIdForMainQuote(BillingWrappers.QuotePackageInfo packageInfo, List<Package__c> accountPackages) {
        String billingPackageId = null;
        if (accountPackages == null || accountPackages.isEmpty()) {
            return billingPackageId;
        }
        if (accountPackages.size() == 1) {
            Package__c singlePackage = accountPackages.get(0);
            if (packageInfo.packageInfo.id == singlePackage.Account_Package_Id__c) {
                billingPackageId = singlePackage.Id;
            }
        } else if (isProServicesProduct(packageInfo.productName)) {
            billingPackageId = getProServicesPackageId(accountPackages);
        }
        return billingPackageId;
    }

    private Boolean isProServicesProduct(String productName) {
        return productName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
    }

    private String getProServicesPackageId(List<Package__c> accountPackages) {
        for (Package__c accountPackage : accountPackages) {
            if (accountPackage.Service_Type__c == PackageHelper.PROSERV_SERVICE_TYPE) {
                return accountPackage.Id;
            }
        }
        return null;
    }

    private static Map<String, Object> getAreaCodeData(QuoteRequest quoteRequest) {
        Map<String, Object> areaCodeData = new Map<String, Object> {
            'countries' => new Set<String>(),
            'states'    => new Set<String>(),
            'cities'    => new Set<String>(),
            'areaCodes' => new Set<Integer>()
        };

        if (quoteRequest != null) {
            if (
                quoteRequest.mainAreaCodeInfo != null &&
                quoteRequest.mainAreaCodeInfo.country != null &&
                quoteRequest.mainAreaCodeInfo.areaCode != null
            ) {
                ((Set<String>) areaCodeData.get('countries')).add(quoteRequest.mainAreaCodeInfo.country);
                ((Set<String>) areaCodeData.get('states')).add(quoteRequest.mainAreaCodeInfo.state);
                ((Set<String>) areaCodeData.get('cities')).add(quoteRequest.mainAreaCodeInfo.city);
                ((Set<Integer>) areaCodeData.get('areaCodes')).add(quoteRequest.mainAreaCodeInfo.areaCode);
            }
            if (
                quoteRequest.faxAreaCodeInfo != null &&
                quoteRequest.faxAreaCodeInfo.country != null &&
                quoteRequest.faxAreaCodeInfo.areaCode != null &&
                AreaCodeService.getAreaId(quoteRequest.mainAreaCodeInfo) != AreaCodeService.getAreaId(quoteRequest.faxAreaCodeInfo)
            ) {
                ((Set<String>) areaCodeData.get('countries')).add(quoteRequest.faxAreaCodeInfo.country);
                ((Set<String>) areaCodeData.get('states')).add(quoteRequest.faxAreaCodeInfo.state);
                ((Set<String>) areaCodeData.get('cities')).add(quoteRequest.faxAreaCodeInfo.city);
                ((Set<Integer>) areaCodeData.get('areaCodes')).add(quoteRequest.faxAreaCodeInfo.areaCode);
            }
        }

        return areaCodeData;
    }

    private static List<Area_Codes__c> getAreaCodesForInsert(QuoteRequest quoteRequest, Map<String, Area_Codes__c> areaCodeByAreaId) {
        List<Area_Codes__c> areaCodes = new List<Area_Codes__c>();
        String faxAreaId = AreaCodeService.getAreaId(quoteRequest.faxAreaCodeInfo);
        String mainAreaId = AreaCodeService.getAreaId(quoteRequest.mainAreaCodeInfo);
        Area_Codes__c existingFaxAreaCode = areaCodeByAreaId.get(faxAreaId);
        Area_Codes__c existingMainAreaCode = areaCodeByAreaId.get(mainAreaId);
        Area_Codes__c newFaxAreaCode = AreaCodeService.buildAreaCode(quoteRequest.faxAreaCodeInfo);
        Area_Codes__c newMainAreaCode = AreaCodeService.buildAreaCode(quoteRequest.mainAreaCodeInfo);

        if (existingMainAreaCode == null && newMainAreaCode != null) {
            areaCodes.add(newMainAreaCode);
        }

        if (existingFaxAreaCode == null && newFaxAreaCode != null && faxAreaId != mainAreaId) {
            areaCodes.add(newFaxAreaCode);
        }

        return areaCodes;
    }

    private static Map<String, Area_Codes__c> getAreaCodes(QuoteRequest quoteRequest) {
        Map<String, Object> areaCodeData = getAreaCodeData(quoteRequest);
        String quoteId = quoteRequest.id;
        Map<String, Area_Codes__c> areaCodeByAreaId = AreaCodeService.getAreaCodeWithAreaId(areaCodeData, quoteId);
        List<Area_Codes__c> areaCodesForInsert = getAreaCodesForInsert(
            quoteRequest, areaCodeByAreaId
        );
        Database.insert(areaCodesForInsert, false);

        AreaCodeService.enrichAreaCodes(areaCodeByAreaId, areaCodesForInsert);

        return areaCodeByAreaId;
    }

    private Map<String, Object> getMappedQuotes(List<Quote> quotes) {
        List<Object> ids = new List<Object> { new Map<Id, Quote>(quotes).keySet() };

        List<Quote> allQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByIdsForUQT(ids)
            .executeQuery();

        Quote masterQuote;
        Map<String, Quote> techQuotes = new Map<String, Quote>();

        for(Quote q : allQuotes) {
            if(!q.IsMultiProductTechnicalQuote__c) {
                masterQuote = q;
            } else {
                if( q.ServiceName__c == null ) {
                    throw new IllegalArgumentException('ServiceName__c is null for quote: ' + q.Name);
                }
                techQuotes.put(q.ServiceName__c, q);
            }
        }

        return new Map<String, Object>{
            'masterQuote' => masterQuote,
            'techQuotes' => techQuotes
        };
    }

    private Map<Id, Opportunity> processOpportunity(List<QuoteRequest> quoteRequests, Map<Id, Opportunity> opportunityMap, Quote masterQuote) {
        // For MP Un use master quote request to update opportunity
        // For MP Lite update opportunities one by one if not already updated
        Map<Id, QuoteRequest> firstRequestPerOpp = new Map<Id, QuoteRequest>();
        for (QuoteRequest req : quoteRequests) {
            if (!firstRequestPerOpp.containsKey(req.opportunityId)) {
                firstRequestPerOpp.put(req.opportunityId, req);
            }
        }

        for (Id oppId : firstRequestPerOpp.keySet()) {
            QuoteRequest req = firstRequestPerOpp.get(oppId);
            Opportunity opp = opportunityMap.get(oppId);

            opp.ProvisioningDetails__c = req.opportunityProvisioningDetails;
            opp.SelfProvisioned__c = BooleanHelper.toBoolean(req.opportunitySelfProvisioned);
            opp.NumberToBeRCMainNumber__c = req.rcAccountNumber;
            opp.NumberToBeCCNumber__c = req.ccAccountNumber;
            opp.isTermination__c = BooleanHelper.toBoolean(req.isTerminationOpportunity);

            if (masterQuote.OpportunityId == oppId && masterQuote.isPrimary__c) {
                opp.RCCCSyncStatus__c = getSyncStatus(req, quoteRequests);
            }
        }

        Triggers.switchOff();
        upsert opportunityMap.values();
        Triggers.switchOn();

        return opportunityMap;
    }

    private String getSyncStatus(QuoteRequest req, List<QuoteRequest> quoteRequests) {
        return hasRCCC(quoteRequests) ? IcbHelper.CC_SYNC_STATUS_NOT_STARTED : IcbHelper.CC_SYNC_STATUS_NOT_APPLICABLE;
    }

    private Boolean hasRCCC(List<QuoteRequest> quoteRequests) {
        for (QuoteRequest req : quoteRequests) {
            if (req.serviceName == QuoteHelper.NGBS_RCCC_PRODUCT) {
                return true;
            }
        }
        return false;
    }

    private BillingWrappers.QuotePackageInfo getPackageInfo(String packageInfoJson) {
        if (String.isBlank(packageInfoJson)) {
            return null;
        }
        List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(packageInfoJson, List<BillingWrappers.QuotePackageInfo>.class);
        if (pInfos.isEmpty()) {
            return null;
        }
        return pInfos[0];
    }

}