public with sharing class CaseCreateAPIController {

    public static final String CASE_APINAME = 'Case';
    public static final String ASSISTANCE_FIELD_NAME_1 = 'Product_Assistance__c';
    public static final String ASSISTANCE_FIELD_NAME_2 = 'Product_Assistance_Lvl2__c';
    public static final String ASSISTANCE_FIELD_NAME_3 = 'Product_Assistance_Lvl3__c';
    public static final String SUPPORT_RT = 'Support-Case';
    public static final String TIMEZONE_FIELD = 'Timezone__c';
    public static final String TIMEZONE_OPTIONS = 'timezoneOptions';
    public static final String TIMEZONE_OPTIONS_WITHTRANSLATIONS = 'timezoneOptionsWithTranslations';
    public static final String COMMUNICATION_PREFERENCE_FIELD = 'Communication_Preference__c';
    public static final String COMMUNICATION_PREFERENCE_OPTIONS = 'communicationPreferenceOptions';
    public static final String LABEL_AREA_OPTIONS = 'areaOptions';
    public static final String SUCCESS_MESSAGE_POST = 'Case created.';
    public static final String CASE_ID = 'caseId';
    public static final String CASE_NUMBER = 'caseNumber';
    public static final String MESSAGE_PICKLIST_VALUES_PROVIDED = 'Picklist values provided';
    public static final String LANG_KEY = 'lang';
    public static final String DEFAULT_LANG = 'en_US';
    public static final String RC_EVENTS_PRODUCT_VALUE = 'Events';
    public static final String PAYMENT_PLAN_FIELD = 'Payment_Plan__c';
    public static final String ROLE_FIELD = 'I_use_RingCentral_Events_as__c';
    public static final String EVENT_ORGANIZER_TYPE_FIELD = 'Event_Organizer_Type__c';
    
    public static final String ERROR_MESSAGE_INVALID_TIMEZONE_VALUE = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': Invalid timezone value.';
    public static final String ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': uid and userEmail are required parameters';
    public static final String ERROR_MESSAGE_NAME_EMAIL_ARE_REQUIRED = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': Name and email are required parameters';
    public static final String ERROR_MESSAGE_GDPR_REQUIRED = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': isGdpr parameter required';
    public static final String ERROR_MESSAGE_NOT_GDPR = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': subject, description, selectedProduct, timezone and severityLevel parameters are required when isGdpr = false';
    public static final String ERROR_MESSAGE_ISGDPR = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': firstName, lastName, gdprEmail and euCitizen parameters are required when case is GDPR';
    public static final String ERROR_MESSAGE_SALES_CUST_FORM = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': caseCategory, escalateTo, subject and description are required parameters.';
    public static final String ERROR_MESSAGE_DEVELOPER_PORTAL = CaseAPIUtil.BAD_REQUEST_MESSAGE + 
        ': origin, useCaseType, priority, uid, subject, type, ownerId and description are required parameters.';
    public static final String ERROR_MESSAGE_UID_INVALID = CaseAPIUtil.BAD_REQUEST_MESSAGE +
        ': Invalid UID and no account configured for orphan cases.';
    public static final String ERROR_MESSAGE_INVALID_SELECTED_PRODUCT = CaseAPIUtil.BAD_REQUEST_MESSAGE +
        ': selectedProduct parameter must be ' + HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR;
    public static final String ERROR_MESSAGE_INVALID_CUSTOM_METADATA = 'No product-category mappings found for BT Portal.';
    public static final String DSR_ERROR_MESSAGE_UID_INVALID = 
    'DSR Account not found for the given UID. Please ensure the fixed DSR account exists in the system.';
    public static final String DSR_ERROR_MESSAGE_CONTACT_NOT_FOUND = 
    'DSR Contact not found. Please ensure the fixed DRS contact exists in the system.';
    public static final String DSR_ERROR_MESSAGE_CUSTOM_METADATA_NOT_FOUND = 
    'Custom metadata record for fixed account or contact or FROM Email Address is missing or incomplete.';
    public static final String DSR_EMAIL_NOT_SENT =
    'Failed to send DSR Email. Please check email configuration.';
    public static final String ORG_WIDE_EMAIL_NOT_FOUND =
    'Org-Wide Email Address not found for this Email Address. Please verify Org-Wide Email settings.';
    public static final String RISE_ERROR_MESSAGE_CUSTOM_SETTING_NOT_FOUND = 
    'Custom setting record for Rise brand is not found';
    public static final String RISE_ERROR_MESSAGE_QUEUE_NAME_NOT_FOUND = 
    'Queue name is not found for Rerouting the Rise Brand Cases';
    public static final String RISE_ERROR_MESSAGE_RECORD_TYPE_NAME_NOT_FOUND = 
    'Record Type name is not found for assigning the Rise Brand Cases';
        
    public static final String CONTACT_CENTER_QUEUE_NAME_NOT_FOUND = 'Manila Contact Center Queue not found';
    public static final String ERROR_MESSAGE_INVALID_EXTENSION_NUMBER = CaseAPIUtil.BAD_REQUEST_MESSAGE +
        ': Customer Extension Number is null. Please provide Extension Number for case Creation';    
    
        public static final String SUPPORT_RT_ID = ((SObject)Type.forName(CASE_APINAME).newInstance()).getSObjectType().getDescribe().getRecordTypeInfosByName().get(SUPPORT_RT).getRecordTypeId();

    public static void validateGetRequest(Map<String, Object> req) {
        String lang = StringHelper.safeString(req.get('lang')).toLowerCase();

        if (String.isNotBlank(lang) && !CaseHelper.isValidLanguage(lang)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid lang parameter value.');
        }
        
    }

    public static Map<String, Object> retrieveCaseAreaPicklistHierarchy(String request) {

        Map<String, Object> res = new Map<String, Object>();

        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            validateGetRequest(req);

            // Extract language and portal parameters
            String lang = (String) (req.containsKey(LANG_KEY) ? req.get(LANG_KEY) : DEFAULT_LANG);           
            String accountUid = (String) (req.containsKey('uid') ? req.get('uid') : null);
            String email = (String) (req.containsKey('email') ? req.get('email') : null);
            
            String portal = null;
            // Validate contact if `uid` and `email` are provided
            if (String.isNotBlank(accountUid) && String.isNotBlank(email)) {
                Contact contact = CaseAPIUtil.getContact(accountUid, email);          
            
                // Fetch account using AccountSelector
                Set<String> bindings = new Set<String>{ accountUid };
                List<Account> accountRecords = (List<Account>) new AccountSelector()
                    .selectAccountsByUserIds(new List<Object>{ bindings })
                    .executeQuery();
                
                if (!accountRecords.isEmpty()) {
                    Account account = accountRecords[0];
                    
                    // Check if the account belongs to the 'BT Business' brand
                    if (account.RC_Brand__c == 'BT Business') {
                        portal = 'BT';
                    }
                }
            }

            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, MESSAGE_PICKLIST_VALUES_PROVIDED);
            res.put(LABEL_AREA_OPTIONS, getLabelAreaOptions(lang, portal));
            res.put(TIMEZONE_OPTIONS, getTimeZoneOptions());
            res.put(TIMEZONE_OPTIONS_WITHTRANSLATIONS, getPicklistValuesWithTranslations(lang, TIMEZONE_FIELD));
            res.put(COMMUNICATION_PREFERENCE_OPTIONS, getPicklistValuesWithTranslations(lang, COMMUNICATION_PREFERENCE_FIELD));
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch(Exception e) {
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, e.getMessage());
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, false);
        }

        return res;
    }

    public static List<String> getTimeZoneOptions() {
        List<String> tzOptions = new List<String>();
        for (String optionLabelLvl1 : SFDescribeHelper.getOptionsMap(CASE_APINAME, TIMEZONE_FIELD).keySet()) {
            tzOptions.add(optionLabelLvl1);
        }
        return tzOptions;
    }

    public static List<SCWrappers.BaseOption> getPicklistValuesWithTranslations(String lang, String field) {
        List<SCWrappers.BaseOption> options = new List<SCWrappers.BaseOption>();
        for (PicklistSiteopsController.Picklist pcklist : SFDescribeHelper.getPicklistOptions(CASE_APINAME, SUPPORT_RT, field, lang, false)) {
            for (SCWrappers.BaseOption option : pcklist.Options) {
                if (String.isNotBlank(option.Value)) {
                    options.add(new SCWrappers.BaseOption(option.value, option.label));
                }
            }
        }
        return options;
    }

    public static List<SCWrappers.ApiAreaOption> getLabelAreaOptions(String lang, String portal) {
        List<SCWrappers.ApiAreaOption> result = new List<SCWrappers.ApiAreaOption>();
        
        String fields = ASSISTANCE_FIELD_NAME_1 + ',' + ASSISTANCE_FIELD_NAME_2;

        Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(CASE_APINAME, SUPPORT_RT, lang, fields, true);
        
        SCWrappers.PicklistAPIOptions response1 = new SCWrappers.PicklistAPIOptions();
        response1.values = new List<SCWrappers.PicklistAPIValues>();
        Map<String, List<SCWrappers.BaseOption>> dependenciesLvl2= new Map<String, List<SCWrappers.BaseOption>>();
        Map<String, List<SCWrappers.BaseOption>> dependenciesLvl3= new Map<String, List<SCWrappers.BaseOption>>();
        
        //Start of PBC 23582 - Check if the portal is BT to fetch Product and Category values from custom metadata     
        if (portal == 'BT') {
            Map<String, List<String>> productCategoryMap = getProductCategoryMappings(false);
            
            for (String product : productCategoryMap.keySet()) {
                // Create a PicklistAPIValues object for the product
                SCWrappers.PicklistAPIValues productPicklistValue = new SCWrappers.PicklistAPIValues();
                productPicklistValue.value = product.trim();
                productPicklistValue.label = product.trim(); 
                
                // Add the product to response1
                response1.values.add(productPicklistValue);
                
                // Initialize ApiAreaOption for the product
                SCWrappers.ApiAreaOption productOption = new SCWrappers.ApiAreaOption(productPicklistValue);
                
                // Prepare the list of categories for dependenciesLvl2
                List<String> categories = productCategoryMap.get(product);
                List<SCWrappers.BaseOption> categoryOptions = new List<SCWrappers.BaseOption>();
                
                for (String category : categories) {
                    // Create a PicklistAPIValues object for the category
                    SCWrappers.PicklistAPIValues categoryPicklistValue = new SCWrappers.PicklistAPIValues();
                    categoryPicklistValue.value = category.trim();
                    categoryPicklistValue.label = category.trim(); 
                    
                    // Add the category to dependenciesLvl2
                    SCWrappers.BaseOption categoryOption = new SCWrappers.BaseOption(categoryPicklistValue.value, categoryPicklistValue.label);
                    categoryOptions.add(categoryOption);
                    
                    // Add the category as a sub-option to the product
                    SCWrappers.ApiSubLevelAreaOption subOption = new SCWrappers.ApiSubLevelAreaOption(categoryPicklistValue);
                    productOption.addSubOption(subOption);
                }
                
                // Add the product and its categories to dependenciesLvl2 and for BT Portal we are not populating dependenciesLvl3 as its not needed
                dependenciesLvl2.put(product.trim(), categoryOptions);
 
            }
        } 
        //For Non BT Portal 
        else{
            // Exclude newly added Product_Assistance__c values for BT Support to the Record Type 'Support-Case' as non BT Support 
            // uses field dependency to fetch values based on this record type
            Map<String, List<String>> excludedCategoryMap = getProductCategoryMappings(true);
            response1 = getAPIResponse(SUPPORT_RT_ID, ASSISTANCE_FIELD_NAME_1,translatedLabelByValue);
            
            // Normalize excludedCategories
            List<String> excludedCategories = new List<String>();
            for (String excluded : excludedCategoryMap.get('Excluded')) {
                excludedCategories.add(excluded.trim().toLowerCase());
            }
            
            // Filter out excluded values for Record Type 'Support-Case' 
            List<SCWrappers.PicklistAPIValues> filteredValues = new List<SCWrappers.PicklistAPIValues>();
            for (SCWrappers.PicklistAPIValues value : response1.values) {
                String normalizedValue = value.value.trim().toLowerCase();
                if (!excludedCategories.contains(normalizedValue)) {
                    filteredValues.add(value);
                } 
            }
            response1.values = filteredValues;
            
            dependenciesLvl2 = getDependenciesLvl(SUPPORT_RT_ID, ASSISTANCE_FIELD_NAME_2, translatedLabelByValue);
            dependenciesLvl3 = getDependenciesLvl(SUPPORT_RT_ID, ASSISTANCE_FIELD_NAME_3, translatedLabelByValue);
        }
        

        List<String> severityOptions = getSeverityOptions();
        List<SCWrappers.BaseOption> translatedSeverityOptions = getSeverityOptions(lang);

        for (SCWrappers.PicklistAPIValues optionLabelLvl1 : response1.values) {
            SCWrappers.ApiAreaOption optionLvl1 = new SCWrappers.ApiAreaOption(optionLabelLvl1);

            if (optionLvl1.value == RC_EVENTS_PRODUCT_VALUE) { // LTR-2556
                // This code block will execute only once as only one Events value is present
                Map<String, List<SCWrappers.BaseOption>> roleDependencies = getDependenciesLvl(SUPPORT_RT_ID, EVENT_ORGANIZER_TYPE_FIELD, translatedLabelByValue);
                optionLvl1.paymentPlanOptions = getPicklistValuesWithTranslations(lang, PAYMENT_PLAN_FIELD);
                
                // Get role options and convert to ApiSubLevelAreaOption for field dependency logic
                List<SCWrappers.BaseOption> baseRoleOptions = getPicklistValuesWithTranslations(lang, ROLE_FIELD);
                List<SCWrappers.ApiSubLevelAreaOption> roleOptions = new List<SCWrappers.ApiSubLevelAreaOption>();
                
                // Convert BaseOption to ApiSubLevelAreaOption and add field dependency logic
                for(SCWrappers.BaseOption baseRoleOption : baseRoleOptions) {
                    SCWrappers.ApiSubLevelAreaOption roleOption = new SCWrappers.ApiSubLevelAreaOption(baseRoleOption.value, baseRoleOption.label);
                    
                    if (roleDependencies.containsKey(baseRoleOption.value)) {
                        for (SCWrappers.BaseOption optionLvl2 : roleDependencies.get(baseRoleOption.value)) {
                            SCWrappers.ApiSubLevelAreaOption optionAPILvl2 = new SCWrappers.ApiSubLevelAreaOption(optionLvl2.value, optionLvl2.label);
                            
                            // Add level 3 dependencies if they exist
                            if (dependenciesLvl3.get(optionLvl2.value) != null) {
                                for (SCWrappers.BaseOption optionLvl3 : dependenciesLvl3.get(optionLvl2.value)) {
                                    optionAPILvl2.addSubOption(optionLvl3.value, optionLvl3.label);
                                }
                            }
                            
                            // Add the dependent field value as a sub-option to the role option
                            roleOption.addSubOption(optionLvl2.value, optionLvl2.label);
                        }
                    }
                    roleOptions.add(roleOption);
                }
                optionLvl1.roleOptions = roleOptions;
            }

            if (CaseAPIUtil.isGDPR(optionLvl1.value)) {
                optionLvl1.gdprOptions = CaseAPIUtil.getGdprOptionsList(lang);
            }

            if(CaseAPIUtil.hasSeverityOptions(optionLvl1.value)) {
                optionLvl1.severityOptions = severityOptions;
                optionLvl1.severityOptionsWithTranslations = translatedSeverityOptions;
                optionLvl1.supportsSubjectAndDescription = true;
            } else if (CaseAPIUtil.hasMessageOption(optionLvl1.value)) {
                optionLvl1.message = CaseAPIUtil.isSales(optionLvl1.value) ? CaseAPIUtil.SALES_MESSAGE : CaseAPIUtil.DOWNGRADE_MESSAGE;
            }
            if (dependenciesLvl2.containsKey(optionLabelLvl1.value)) {
                for (SCWrappers.BaseOption optionLvl2 : dependenciesLvl2.get(optionLabelLvl1.value)) {
                    SCWrappers.ApiSubLevelAreaOption optionAPILvl2 = new SCWrappers.ApiSubLevelAreaOption(optionLvl2.value, optionLvl2.label);
                    if (dependenciesLvl3.get(optionLvl2.value) != null) {
                        for (SCWrappers.BaseOption optionLvl3 : dependenciesLvl3.get(optionLvl2.value)) {
                            optionAPILvl2.addSubOption(optionLvl3.value, optionLvl3.label);
                        }
                    }
                    optionLvl1.addSubOption(optionAPILvl2);
                }
            }
            result.add(optionLvl1);
        }

        return result;
    }
    
    //PBC 23582 - Created a new method as a part of BT Support Product and Category Dependencies  
    public static Map<String, List<String>> getProductCategoryMappings(Boolean isExcluded) {
        Map<String, List<String>> productCategoryMap = new Map<String, List<String>>();
        
        try {
            // Query custom metadata
            List<BT_Support_Product_and_Categories__mdt> metadataRecords = [
                SELECT Product_Values__c, Category_Values__c, Is_Excluded__c
                FROM BT_Support_Product_and_Categories__mdt 
                WHERE Is_Excluded__c = :isExcluded
                ORDER BY Product_Order__c
            ];
            
            // Handle the case where no records are found
            if (metadataRecords.isEmpty()) {
                throw new HandledException(ERROR_MESSAGE_INVALID_CUSTOM_METADATA);
            }
            
            // Populate the map with product and category values           
            if (isExcluded) {
                // Handle excluded values differently: collect only categories
                List<String> excludedCategories = new List<String>();
                for (BT_Support_Product_and_Categories__mdt record : metadataRecords) {
                    if (String.isNotBlank(record.Category_Values__c)) {
                        excludedCategories.addAll(record.Category_Values__c.split(','));
                    }
                }
                productCategoryMap.put('Excluded', excludedCategories);
            } else {
                // Populate the map with product and category values for non-excluded records
                for (BT_Support_Product_and_Categories__mdt record : metadataRecords) {
                    String product = record.Product_Values__c;
                    
                    // Skip invalid or blank records
                    if (String.isNotBlank(product)) {
                        List<String> categories = String.isNotBlank(record.Category_Values__c)
                            ? record.Category_Values__c.split(',')
                            : new List<String>();
                        productCategoryMap.put(product, categories);
                    }
                }
            }
        }catch (Exception e) {
            throw new HandledException(ERROR_MESSAGE_INVALID_CUSTOM_METADATA);
        }
        
        return productCategoryMap;
    }

    private static Map<String,List<SCWrappers.BaseOption>> getDependenciesLvl(String rtId, String fieldName, Map<String, String> translatedLabelByValue) {
        SCWrappers.PicklistAPIOptions response = getAPIResponse(rtId, fieldName, translatedLabelByValue);

        Map<Integer,List<SCWrappers.BaseOption>> valuesByValidFor = fillValidForMap(response);

        Map<String,List<SCWrappers.BaseOption>> dependenciesLvl = getDependenciesMap(response, valuesByValidFor);

        return dependenciesLvl;
    }

    public static List<String> getSeverityOptions() {
        List<String> severityOptions = new List<String>();

        Map<String, Schema.PicklistEntry> picklistMap = SFDescribeHelper.getOptionsMap('Case','Case_Severity__c' );

        for (String fieldName : picklistMap.keySet()) {
            Boolean bannedValue = false;
            for (String caseSeverity : CaseHelper.getCaseSeverityOptions()) {
                if (fieldName.contains(caseSeverity)) {
                    bannedValue = true;
                    break;
                }
            }
            if (!bannedValue) {
                severityOptions.add(fieldName);
            }
        }

        return severityOptions;
    }

    public static List<SCWrappers.BaseOption> getSeverityOptions(String lang) {
        List<SCWrappers.BaseOption> severityOptions = new List<SCWrappers.BaseOption>();

        for (SCWrappers.BaseOption option : getPicklistValuesWithTranslations(lang, 'Case_Severity__c')) {
            Boolean bannedValue = false;
            for (String caseSeverity : CaseHelper.getCaseSeverityOptions()) {
                if (option.value.contains(caseSeverity)) {
                    bannedValue = true;
                    break;
                }
            }
            if (!bannedValue) {
                severityOptions.add(new SCWrappers.BaseOption(option.value, option.label));
            }
        }

        return severityOptions;
    }

    public static Map<String,List<SCWrappers.BaseOption>> getDependenciesMap(
        SCWrappers.PicklistAPIOptions options, 
        Map<Integer,List<SCWrappers.BaseOption>> validForMap
    ) {
        Map<String,List<SCWrappers.BaseOption>> dependenciesMap = new Map<String,List<SCWrappers.BaseOption>>();
        for (String key : options.controllerValues.keySet()) {
            Integer validFor = options.controllerValues.get(key);
            for (Integer valid : validForMap.keySet()) {
                if (validForMap.containsKey(validFor)) {
                    List<SCWrappers.BaseOption> dependents = validForMap.get(validFor);
                    dependenciesMap.put(key,dependents);
                } else {
                    dependenciesMap.put(key,new List<SCWrappers.BaseOption>());
                }
            }
        }
        return dependenciesMap;
    }

    public static Map<Integer,List<SCWrappers.BaseOption>> fillValidForMap(SCWrappers.PicklistAPIOptions options) {
        Map<Integer,List<SCWrappers.BaseOption>> valuesByValidFor = new Map<Integer,List<SCWrappers.BaseOption>>();
        for (SCWrappers.PicklistAPIValues picklistAPIValue : options.values) {
            for (Integer validFor : picklistAPIValue.validFor) {
                if(!valuesByValidFor.containsKey(validFor)) {
                    valuesByValidFor.put(validFor, new List<SCWrappers.BaseOption>());
                }
                valuesByValidFor.get(validFor).add(new SCWrappers.BaseOption(
                    picklistAPIValue.value, picklistAPIValue.label
                ));
            }
        }
        return valuesByValidFor;
    }

    public static HttpRequest prepareHttpRequest(Id recordTypeId, String fieldName) {
        String sfdcURL = URL.getOrgDomainUrl().toExternalForm();
        String restAPIURL =
            sfdcURL + '/services/data/v51.0/ui-api/object-info/Case/picklist-values/'+recordTypeId+'/'+fieldName;
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        httpRequest.setTimeout(20000);
        httpRequest.setEndpoint(restAPIURL);
        return httpRequest;
    }

    public static SCWrappers.PicklistAPIOptions getAPIResponse(Id recordTypeId, String fieldName, Map<String, String> translatedLabelByValue) {
        SCWrappers.PicklistAPIOptions response;

        HttpRequest request = prepareHttpRequest(recordTypeId, fieldName);

        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(request);
            if (httpResponse.getStatusCode() == 200 ) {
                response = (SCWrappers.PicklistAPIOptions) JSON.deserialize(httpResponse.getBody(), SCWrappers.PicklistAPIOptions.class);
            } else {
                throw new CalloutException(httpResponse.getBody());
            }
        } catch (Exception e) {
            throw e;
        }

        if (!translatedLabelByValue.isEmpty()) {
            for (SCWrappers.PicklistAPIValues picklistAPIValue : response.values) {
                picklistAPIValue.label = CaseHelper.getTranslatedLabel(translatedLabelByValue, picklistAPIValue.value);
            }
        }

        return response;
    }
    
    public static Map<String, Object> createCase(String request) {
        Map<String, Object> res = new Map<String, Object>();

        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            CaseCreateStrategy.ICaseCreateStrategy strategy = CaseCreateStrategy.getStrategy(req);

            strategy.validate(req);

            String createdCaseId = strategy.create(req);
            String createdCaseNumber = CaseCreateStrategy.caseNumber;
            
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_POST);
            res.put(CASE_ID, createdCaseId);
            if (String.isNotBlank(createdCaseNumber)) {
                res.put(CASE_NUMBER, createdCaseNumber);
            } 
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }
}