public with sharing class PDFTemplateHelper {

    public static final String NEW_ORDER = OrderHelper.TYPE_NEW_ORDER;
    public static final String CHANGE_ORDER = 'Change Order';

    public static final String REQUIREMENT_SHOW_IF_LESS_THAN_DLS = 'Show If Less Than DLs';
    public static final String REQUIREMENT_SHOW_IF_MORE_THAN_DLS = 'Show If More Than DLs';
    public static final String REQUIREMENT_HAS_DOCUSIGN_CLM_ACCESS = 'Has Docusign CLM Access';
    public static final String REQUIREMENT_HAS_BOB_ACCOUNT = 'Has Bill-on-Behalf Account';
    public static final String REQUIREMENT_HAS_WHOLESALE_ACCOUNT = 'Has Wholesale Account';
    public static final String REQUIREMENT_HAS_MULTIPRODUCT_ACCOUNT = 'Has MultiProduct Account';
    public static final String REQUIREMENT_HAS_PROFESSIONAL_SERVICES = 'Has Professional Services';

    public static final String AVAILABILITY_COUNTRY_USA = 'United States';
    public static final String AVAILABILITY_COUNTRY_CANADA = 'Canada';
    public static final String AVAILABILITY_COUNTRY_UK = 'United Kingdom';
    public static final String AVAILABILITY_COUNTRY_AUSTRALIA = 'Australia';
    public static final String PHOENIX = 'Phoenix';
    public static final String FREYJA = 'Freyja';

    public PDFTemplateHelper() {}

    class CustomException extends Exception {}

    public static List<RC_Quote_Template__c> getPdfTemplates(Id oppId, Id quoteId) {
        List<Quote> quoteObjList = new List<Quote>();

        try {
            quoteObjList = new QuoteSelector()
                .selectQuoteForPdfTemplates(oppId)
                .executeQuery();
        } catch (DMLException e) {
            throw new CustomException(e.getDmlMessage(0));
        }

        Quote quoteObj = QuoteHelper.getQuoteById(quoteObjList, quoteId);
        String quoteApprovedBICountry = QuoteHelper.getApprovedBICountryFromQuote(quoteObj);

        List<Quote> technicalQuotes = new QuoteSelector()
            .selectServiceQuotesForMasterQuote(quoteObj.Id)
            .executeQuery();

        Quote proServTechnicalQuote;
        for (Quote techQuote : technicalQuotes) {
            if (techQuote.ServiceName__c == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                proServTechnicalQuote = techQuote;
            }
        }

        List<RC_Quote_Template__c> templateRecordList = new List<RC_Quote_Template__c>();

        if (quoteObj != null){

            Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();

            if (!DQGoa.isDQGoaEnabled()) {
                if (quoteObj.Approved_Status__c == 'Pending L1 Approval' ||
                quoteObj.Approved_Status__c == 'Pending L2 Approval' ||
                quoteObj.Approved_Status__c == 'Pending L3 Approval' ||
                quoteObj.Approved_Status__c == 'Pending L4 Approval' ||
                quoteObj.Approved_Status__c == 'Pending L5 Approval') {

                    throw new CustomException('Cannot do this operation as this quote is pending for approval.');

                }
                if(quoteObj.Approved_Status__c == 'Rejected'
                        || quoteObj.Approved_Status__c == 'Required'
                        || quoteObj.Approved_Status__c == 'Recalled'
                        || quoteObj.Approved_Status__c == null) {

                    throw new CustomException('Cannot do this operation as this quote requires approval.');

                }
            }

            String opportunityId = quoteObj.OpportunityId;

            Boolean isPartnerOperationsLogExists = QuoteHelper.isPartnerOperationsLogExists(quoteObj);

            String engineVer = featureCS.PDF_Engine_1_0__c ? '' : 'AND (Template_Engine__c != \'PDF Engine 1.0\' AND Template_Engine__c != null) ';
            engineVer += featureCS.PDF_Engine_2_0__c ? '' : 'AND Template_Engine__c != \'PDF Engine 2.0\' ';

            String query = 'SELECT Id, Name, LastModifiedDate, Sorting_Order__c, Description__c, Brand__c, Size__c, ' +
                    'Opportunity_Record_Type__c, Type__c, Active__c, Order_Type__c, Quote_Record_Type__c, ProductLabels__c, ' +
                    'Products__c, Language__c, Template_Engine__c, Requirements__c, Service__c, ' +
                    'Available_For_Countries__c, Available_For_Billing_Countries__c, NotAvailableForBICountries__c, ' +
                    'External_ID__c ' +
                    'FROM RC_Quote_Template__c ' +
                    'WHERE Brand__c != NULL AND Type__c != NULL AND Active__c = true ' + engineVer +
                    'ORDER BY Sorting_Order__c ASC NULLS LAST, LastModifiedDate DESC';

            Integer countApprovals = [SELECT COUNT() FROM Approval__c WHERE Opportunity__c = :opportunityId
                        AND RecordType.Name = 'Engage Legal'
                        AND Status__c = 'Completed'
                        LIMIT 1];

            for(RC_Quote_Template__c templateObj : Database.Query(query)) {
                Set<String> brandSet = new Set<String>(StringHelper.safeSplit(templateObj.Brand__c, ';'));
                Set<String> templateTypesSet = new Set<String>(StringHelper.safeSplit(templateObj.Opportunity_Record_Type__c, ';'));
                Set<String> billingCountrySet = new Set<String>(StringHelper.safeSplit(templateObj.Available_For_Billing_Countries__c, ';'));

                String orderType = getOrderType(quoteObj.Account);

                Account quoteAccountObj = quoteObj.Account;
                String quoteObjRecordTypeName = quoteObj.RecordType == null ? null : quoteObj.RecordType.Name;

                Map<String, String> quoteParamsMap = new Map<String, String>{
                        'orderType'         => orderType,
                        'quoteRecordType'   => quoteObjRecordTypeName,
                        'quoteProducts'     => quoteObj.Products__c
                };

                Map<String, String> templateParamsMap = new Map<String, String>{
                        'orderType'         => templateObj.Order_Type__c,
                        'quoteRecordType'   => templateObj.Quote_Record_Type__c,
                        'quoteProducts'     => templateObj.Products__c
                };

                Boolean isEngine2 = TemplateEngine.PDF_ENGINE_2_0.equalsIgnoreCase(templateObj.Template_Engine__c);
                Boolean paramIsEqual = false;
                for (String param : quoteParamsMap.keySet()) {
                    if (param == 'orderType') {
                        if (quoteParamsMap.get(param).contains(CHANGE_ORDER)
                            && templateParamsMap.get(param) != null
                            && templateParamsMap.get(param).contains(CHANGE_ORDER)) {
                            paramIsEqual = true;
                        } else if (quoteParamsMap.get(param).contains(NEW_ORDER)
                            && templateParamsMap.get(param) != null
                            && templateParamsMap.get(param).contains(NEW_ORDER)) {
                            paramIsEqual = true;
                        } else {
                            paramIsEqual = false;
                            break;
                        }
                    }

                    if (param == 'quoteRecordType') {
                        String qParam = quoteParamsMap.get(param);
                        String tParam = templateParamsMap.get(param);

                        if (compareRT(qParam, tParam, QuoteHelper.RT_NAME_SALES, true)) {
                            paramIsEqual = true;
                        } else if (compareRT(qParam, tParam, QuoteHelper.RT_NAME_PROSERV, false)) {
                            paramIsEqual = true;
                        } else if (compareRT(qParam, tParam, QuoteHelper.RT_NAME_CC_PROSERV, false)) {
                            paramIsEqual = true;
                        } else if (compareRT(qParam, tParam, QuoteHelper.RT_NAME_BILLING, false)) {
                            paramIsEqual = true;
                        } else if (compareRT(qParam, tParam, QuoteHelper.RT_NAME_POC_QUOTE, false)) {
                            paramIsEqual = true;
                        } else { 
                            paramIsEqual = false; 
                            break; 
                        }
                    }

                    if (!isEngine2) {
                        if (param == 'quoteProducts') {
                            if (String.isNotBlank(quoteParamsMap.get(param))) {
                                if (quoteParamsMap.get(param).contains('Contact Center')
                                        && templateParamsMap.get(param) == 'RingCentral;Contact Center') {
                                    paramIsEqual = true;
                                } else if (quoteParamsMap.get(param).contains('RingCentral')
                                        && !quoteParamsMap.get(param).contains('Contact Center')
                                        && templateParamsMap.get(param) == 'RingCentral') {
                                    paramIsEqual = true;
                                } else if (quoteParamsMap.get(param) == 'Professional Services'
                                        && templateParamsMap.get(param) == 'Professional Services') {
                                    paramIsEqual = true;
                                } else {
                                    paramIsEqual = false;
                                    break;
                                }
                            } else if (String.isBlank(templateParamsMap.get(param))) {
                                paramIsEqual = true;
                            } else {
                                paramIsEqual = false;
                            }
                        }
                    }
                }

                // Check if custom Requirements met for this template
                Boolean isRequirementsPass = true;
                if (String.isNotBlank(templateObj.Requirements__c)) {
                    // B-2140 Enterprise Agreement PDF
                    if (templateObj.Requirements__c.contains('Has No Completed Engage Legal Approval')){
                        isRequirementsPass = (countApprovals <= 0);
                    } else if (templateObj.Requirements__c.contains('Has Completed Engage Legal Approval')){
                        isRequirementsPass = (countApprovals > 0);
                    }

                    if (templateObj.Requirements__c.contains('Has Active Sales Agreement') &&
                        String.isEmpty(quoteObj.Account.Active_Sales_Agreement__c)) {
                        isRequirementsPass = false;

                    } else if (templateObj.Requirements__c.contains('Has No Active Sales Agreement') &&
                        String.isNotEmpty(quoteObj.Account.Active_Sales_Agreement__c)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains('Has Bound Account') &&
                        String.isEmpty(quoteObj.Account.Master_Account__c)) {
                        isRequirementsPass = false;
                    } else if (templateObj.Requirements__c.contains('Has No Bound Account') &&
                        String.isNotEmpty(quoteObj.Account.Master_Account__c)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains('Has ProServ Engaged') &&
                        !OpportunityHelper.isProServEngaged(quoteObj.Opportunity)) {
                        isRequirementsPass = false;
                    } else if (templateObj.Requirements__c.contains('Has No ProServ Engaged') &&
                        OpportunityHelper.isProServEngaged(quoteObj.Opportunity)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains('Has Contact Center Products') &&
                        !QuoteHelper.isHasContactCenterProductsInCart(quoteObjList, quoteObj)) {
                        isRequirementsPass = false;

                    } else if (templateObj.Requirements__c.contains('Has No Contact Center Products') &&
                        QuoteHelper.isHasContactCenterProductsInCart(quoteObjList, quoteObj)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains(REQUIREMENT_HAS_DOCUSIGN_CLM_ACCESS)
                        && quoteObj.Opportunity.IsDocusignCLMEnabled__c
                    ) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains(REQUIREMENT_HAS_BOB_ACCOUNT)
                        && (!QuoteHelper.hasBillOnBehalfAccount(quoteObj) || QuoteHelper.hasBillOnBehalfAccount(quoteObj) && isPartnerOperationsLogExists)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains(REQUIREMENT_HAS_WHOLESALE_ACCOUNT) &&
                        (!AccountHelper.isWholesaleAccount(quoteObj.Account) && !isPartnerOperationsLogExists)) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains(REQUIREMENT_HAS_MULTIPRODUCT_ACCOUNT) &&
                        technicalQuotes.isEmpty()) {
                        isRequirementsPass = false;
                    }

                    if (templateObj.Requirements__c.contains(REQUIREMENT_HAS_PROFESSIONAL_SERVICES) &&
                        (!technicalQuotes.isEmpty() && proServTechnicalQuote == null 
                            || technicalQuotes.isEmpty() && quoteObj.ServiceName__c != QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)) {
                        isRequirementsPass = false;
                    }

                    if (isRequirementsPass && !isDLTresholdRequirementPass(templateObj, quoteObj)){
                        isRequirementsPass = false;
                    }
                }

                Boolean isTemplateAvailableInThisService = true;
                if (
                    QuoteHelper.isNewBillingQuote(quoteObj)
                    && (
                        String.isBlank(templateObj.Service__c)
                        || !templateObj.Service__c.containsIgnoreCase(QuoteHelper.getBillingQuoteProductName(quoteObj))
                       )
                ) {
                    isTemplateAvailableInThisService = false;
                }

                Boolean isTemplateAvailableForPhoenix = true;

                if(!String.isBlank(templateObj.ProductLabels__c) && !templateObj.ProductLabels__c.contains(PHOENIX)) {
                    isTemplateAvailableForPhoenix = false;
                }

                Boolean isTemplateAvailableForCountry = getIsTemplateAvailableForBICountry(
                    quoteApprovedBICountry,
                    templateObj.Available_For_Countries__c,
                    templateObj.NotAvailableForBICountries__c
                );

                Boolean isTemplateAvailableForBillingCountry = true;
                if (billingCountrySet.size() > 0) {
                    isTemplateAvailableForBillingCountry = false;

                    if(billingCountrySet.contains(quoteAccountObj.BillingCountry)) {
                        isTemplateAvailableForBillingCountry = true;
                    }
                }

                Boolean isBoBRequirementsPassed = !QuoteHelper.hasBillOnBehalfAccount(quoteObj)
                    || (QuoteHelper.hasBillOnBehalfAccount(quoteObj) && isPartnerOperationsLogExists)
                    || (String.isNotBlank(templateObj.Requirements__c) && templateObj.Requirements__c.contains(REQUIREMENT_HAS_BOB_ACCOUNT));

                Boolean isWholesaleRequirementsPassed = !AccountHelper.isWholesaleAccount(quoteObj.Account) && !isPartnerOperationsLogExists ||
                (String.isNotBlank(templateObj.Requirements__c) && templateObj.Requirements__c.contains(REQUIREMENT_HAS_WHOLESALE_ACCOUNT));

                Boolean isMultiProductRequirementsPassed = technicalQuotes.isEmpty() ||
                (String.isNotBlank(templateObj.Requirements__c) && templateObj.Requirements__c.contains(REQUIREMENT_HAS_MULTIPRODUCT_ACCOUNT));

                if ((String.isBlank(quoteObj.Brand__c) || brandSet.contains(quoteObj.Brand__c))
                        && (templateTypesSet.contains(quoteObj.Opportunity.RecordType.Name))
                        && (quoteObj.QuoteType__c == null || templateObj.Type__c.contains(quoteObj.QuoteType__c))
                        && (paramIsEqual)
                        && isRequirementsPass
                        && isTemplateAvailableInThisService
                        && isTemplateAvailableForCountry
                        && isTemplateAvailableForBillingCountry
                        && isTemplateAvailableForPhoenix
                        && isWholesaleRequirementsPassed
                        && isMultiProductRequirementsPassed
                        && isBoBRequirementsPassed) {
                    templateRecordList.add(templateObj);
                }
            }
        }
        return templateRecordList;
    }

    // here we asssume that Available_For_Countries__c and NotAvailableForBICountries__c are concurrent fields
    // and can't be populated at the same time (see RC_Quote_Template.OnlyOneBIFilterIsPopulated validation rule)
    @TestVisible
    private static Boolean getIsTemplateAvailableForBICountry(
        String quoteApprovedBICountry,
        String availableForBICountries,
        String notAvailableForBICountries
    ) {
        Map<String, String> countryCodesMapping = SettingsService.getCountryCodes();

        if (String.isNotBlank(availableForBICountries)) {
            Boolean isAvailableforBIcountry = false;
            Set<String> availableForBICountriesSet = new Set<String>(StringHelper.safeSplit(availableForBICountries, ';'));

            for (String afc : availableForBICountriesSet) {
                if (
                    countryCodesMapping.get(afc.toLowerCase()) != null
                    && countryCodesMapping.get(afc.toLowerCase()).equalsIgnoreCase(quoteApprovedBICountry)
                ) {
                    isAvailableforBIcountry = true;
                }
            }

            return isAvailableforBIcountry;

        } else if (String.isNotBlank(notAvailableForBICountries)) {
            Boolean isNotAvailableforBIcountry = false;
            Set<String> notAvailableForBICountriesSet = new Set<String>(StringHelper.safeSplit(notAvailableForBICountries, ';'));

            for (String nafc : notAvailableForBICountriesSet) {
                if (
                    countryCodesMapping.get(nafc.toLowerCase()) != null
                    && countryCodesMapping.get(nafc.toLowerCase()).equalsIgnoreCase(quoteApprovedBICountry)
                ) {
                    isNotAvailableforBIcountry = true;
                }
            }

            return !isNotAvailableforBIcountry || String.isBlank(quoteApprovedBICountry);
        }

        // if both filters are empty – return true (means that both filters are ignored)
        return true;
    }

    @TestVisible
    private static String getOrderType(Account acc) {
        Boolean hasAccount = String.isNotBlank(acc.RC_User_ID__c);
        Boolean isFree = String.isNotBlank(acc.RC_Account_Status__c) && acc.RC_Account_Status__c.containsIgnoreCase('trial');
        Boolean isPocToPaid = AccountHelper.isPOCToPaid(acc);

        return hasAccount && !isFree && !isPocToPaid ? CHANGE_ORDER : NEW_ORDER;
    }

    private static Boolean compareRT(String quote_rt_names, String template_rt_names, String recordTypeName, Boolean canBeEmpty) {
        List<String> quote_rt_list = (quote_rt_names != null) ? quote_rt_names.split(';') : null;
        List<String> template_rt_list = (template_rt_names != null) ? template_rt_names.split(';') : null;

        Boolean sub_c1 = quote_rt_list == null || quote_rt_list.contains(recordTypeName);
        Boolean sub_c2 = quote_rt_list != null && quote_rt_list.contains(recordTypeName);

        Boolean c1 = canBeEmpty ? sub_c1 : sub_c2;
        Boolean c2 = template_rt_list != null && template_rt_list.contains(recordTypeName);

        return c1 && c2;
    }

    private static Boolean isDLTresholdRequirementPass(RC_Quote_Template__c templateObj, Quote quoteObj) {
        Boolean result = true;
        Boolean showLess = templateObj.Requirements__c.contains(REQUIREMENT_SHOW_IF_LESS_THAN_DLS);
        Boolean showMore = templateObj.Requirements__c.contains(REQUIREMENT_SHOW_IF_MORE_THAN_DLS);
        if (!showMore && !showLess) {
            return result;
        }
        Decimal dlAmount = QuoteLineItemHelper.getDLAmount(quoteObj.QuoteLineItems);
        Decimal threshold = NumberHelper.toNumber(
            RingCentralVariousSettings__c.getInstance().TemplatePreselectedDLThreshold__c
        );
        if (showLess) {
            result = dlAmount <= threshold;
        } else if (showMore) {
            result = dlAmount > threshold;
        }
        return result;
    }
}