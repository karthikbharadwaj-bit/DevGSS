public class ConvertLeadController {

    private final static Integer ACCOUNT_RECORDS_LIMIT = 10;
    private final static Integer OPPORTUNITY_RECORDS_LIMIT = 10;
    private final static Integer CONTACT_RECORDS_LIMIT = 10;
    private final static Integer QUALIFICATION_RECORDS_LIMIT = 10;
    private final static String RING_CENTRAL = 'RingCentral';
    public static Boolean atmFlag = false;

    @AuraEnabled(Cacheable=true)
    public static Response getDataWave1(Id leadId) {
        Response result = new Response();
        Boolean isSelectPackagesByBusinessIdentity = Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c;
        result.setData(getSettings(leadId));
        Response leadResult = getLead(leadId);
        result.setData(leadResult);
        Lead lead = (Lead) getLead(leadId).data.get('lead');
        if (!LeadHelper.isAvaya(lead)) {
            result.setData(getAccounts(lead));
        }
        if (isSelectPackagesByBusinessIdentity) {
            result.setData(getSubBrandAndDefaultBI(lead));
        }
        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getDataWave2(Id leadId) {
        Response result = new Response();

        result.setData(getLegacyServices());
        result.setData(getLeadQualifications(leadId));

        return result;
    }

    public class ConvertParameters {
        @AuraEnabled public ConvertLead.ConvertLeadDTO ConvertData;
        @AuraEnabled public Integer partIndex = 1;
    }

    @AuraEnabled
    public static Response convertLeadWrapper(String convertParams) {
        ConvertParameters convertParamsParsed = (ConvertParameters)
            JSON.deserialize(convertParams, ConvertParameters.class);
        return convertLead(convertParamsParsed);
    }

    @AuraEnabled
    public static Response convertLead(ConvertParameters convertParams) {
        Response result = new Response();
        switchTriggers(true);
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        convertParams.ConvertData.validate();
        try {
            switch on convertParams.partIndex {
                when 0 {
                    result.setData(ConvertLead.prepareLeadRecord(convertParams.ConvertData));
                }
                when 1 {
                    result.setData(ConvertLead.convertPart1(convertParams.ConvertData));
                }
                when 2 {
                    result.setData(ConvertLead.convertPart2(convertParams.ConvertData));
                }
                when 3 {
                    result.setData(ConvertLead.convertPart3(convertParams.ConvertData));
                }
                when 4 {
                    result.setData(ConvertLead.convertPart4(convertParams.ConvertData));
                }
            }
            LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
                Limits.getCpuTime(),
                Limits.getQueries(),
                convertParams.ConvertData.accountId,
                convertParams.ConvertData.contactId,
                convertParams.ConvertData.opportunityId,
                convertParams.ConvertData.leadId,
                convertParams.partIndex,
                result.messages.isEmpty() ? null : result.messages[0].message,
                result.stackTrace,
                convertParams.ConvertData.isCreateAccount,
                convertParams.ConvertData.isCreateOpportunity,
                convertParams.ConvertData.isCreateQuote,
                convertParams.ConvertData.isElaAccount,
                ConvertLead.convertPartNode
            );
            switchTriggers(false);
        } catch (Exception ex) {
            LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
                Limits.getCpuTime(),
                Limits.getQueries(),
                convertParams.ConvertData.accountId,
                convertParams.ConvertData.contactId,
                convertParams.ConvertData.opportunityId,
                convertParams.ConvertData.leadId,
                convertParams.partIndex,
                ex.getMessage(),
                ex.getStackTraceString(),
                convertParams.ConvertData.isCreateAccount,
                convertParams.ConvertData.isCreateOpportunity,
                convertParams.ConvertData.isCreateQuote,
                convertParams.ConvertData.isElaAccount,
                ConvertLead.convertPartNode
            );
            AquivaHelper.throwAquivaException(ex);
        }
//        Id UserId = UserInfo.getUserId();
//        if(!atmFlag && result.getData('AccountId')!=null){
//            Id AccId = (Id)result.getData('AccountId');
//            System.debug(AccId);
//            System.debug([select Id, Name, Owner.Name from Account where Id =: AccId]);
//            System.debug(UserId);
//            accountTeamsCustomController.addCurrentUsertoAccountTeamMember(AccId, UserId);
//        }

        switchTriggers(false);
        return result;
    }

    @AuraEnabled
    public static void publishLimitsError(String leadId, String error, String errorType, String stacktrace) {
        PlatformEvents.publishPlatformEvent(new Lead_Conversion_Monitoring__e(
            LeadId__c = leadId,
            Error__c = error,
            Error_Type__c = errorType,
            Error_stacktrace__c = stacktrace
        ),
        'LeadConversionMonitoring');
    }

    public static Response getLead(Id leadId) {
        Response result = new Response();
        Lead lead = [
            SELECT Id, Name, Email, PhotoUrl, Company, Title, City, Phone, User_ID__c, Lead_Brand_Name__c, Partner_ID__c,
                Forecasted_Engage_Digital_Users__c, Forecasted_Engage_Voice_Users__c, Forecasted_Global_Office_Users__c, Forecasted_RingCentral_Video_Users__c,
                RecordType.Name, Forecasted_Contact_Center_Users__c, Number_of_Users__c, Lead_Tier_Name__c, VATNumber__c, Country__c,
                IsConverted, ConvertedOpportunityId, ConvertedContactId, ConvertedAccountId, LeadPartnerID__c, BusinessIdentity__c, Account__r.Billing_ID__c,
                Partner_Account__c, Partner_Account__r.CurrencyIsoCode, Partner_Account__r.ParentId, Partner_Account__r.Parent_Partner_Account__c,
                Partner_Account__r.Partner_ID__c, Partner_Account__r.Partner_Type__c, Partner_Account__r.NGBS_Partner_ID__c, Installation_Service_Provider__c, Estimated_Close_Date__c, (
                SELECT Id, Name, LastModifiedDate, Account__c, Account__r.Name, Opportunity__c, Opportunity__r.Name,
                    Lead__c, Lead__r.Name
                FROM Lead_Qualifications__r
                ORDER BY LastModifiedDate DESC
            )
            FROM Lead
            WHERE Id = :leadId
        ];
        result.setData('lead', lead);
        return result;
    }

    @AuraEnabled
    public static Response getDataForSalesLead(Id leadId, String leadCountry, String leadBrand) {
        Response result = new Response();
        String brand = getBrandForSalesLead(leadCountry, leadBrand);
        result.setData('brand', brand);
        result.setData('businessIdentities', SettingsService.getBusinessIdentityMappingJSON(String.valueOf(leadId)));
        result.setData(getSubBrandAndDefaultBI(leadId, brand, leadCountry));
        return result;
    }

    @AuraEnabled
    public static Response getCountriesForSalesLead(String leadCountry) {
        Response result = new Response();
        String country = leadCountry;
        Set<String> countries  = getCountriesList();
        if (country == null || !countries.contains(country)) {
            country = LeadHelper.DEFAULT_COUNTRY;
        }
        result.setData('countries', JSON.serialize(countries));
        result.setData('country', country);
        return result;
    }

    public static String getBrandForSalesLead(String leadCountry, String leadBrand) {
        String defaultBrand = 'RingCentral';
        List<Default_Business_Identity_Mapping__mdt> defaultBIMapping = SettingsService.getDefaultBusinessIdentityMapping();
        Map<String, List<String>> countryToBrandsMap = new Map<String, List<String>>();

        for (Default_Business_Identity_Mapping__mdt defaultBIMappingRec : defaultBIMapping) {
            if (defaultBIMappingRec.Country__c == leadCountry
                && String.isBlank(defaultBIMappingRec.Sub_Brand__c)
                && defaultBIMappingRec.Is_Core_Brand__c) {
                if (!countryToBrandsMap.containsKey(defaultBIMappingRec.Country__c)) {
                    countryToBrandsMap.put(defaultBIMappingRec.Country__c, new List<String>());
                }
                countryToBrandsMap.get(defaultBIMappingRec.Country__c).add(defaultBIMappingRec.Brand__c);
            }
        }

        if (countryToBrandsMap.containsKey(leadCountry)) {
            List<String> brands = countryToBrandsMap.get(leadCountry);
            if (brands.size() == 1) {
                return brands[0];
            }
            if (leadBrand != null && brands.contains(leadBrand)) {
                return leadBrand;
            }
        }
        return defaultBrand;
    }

    @AuraEnabled
    public static Response getDataForSelectedAccount(Id leadId, Id accountId){
        Response result = new Response();
        Map<String, String> subBrandBIMap = validateDataForSelectedAccount(SettingsService.getSubBrandAndDefaultBI(null, accountId));
        String defaultBI = subBrandBIMap.get('defaultBI');
        String subBrand = subBrandBIMap.get('subBrand');
        String country = subBrandBIMap.get('country');
        String brand = subBrandBIMap.get('brand');
        List<String> availableBIs = SettingsService.getAvailableBusinessIdentities(defaultBI, subBrand, country, brand);
        result.setData('defaultBI', defaultBI);
        result.setData('subBrand', subBrand);
        result.setData('availableBIs', JSON.serialize(availableBIs));
        result.setData('businessIdentities', SettingsService.getBusinessIdentityMappingJSON(String.valueOf(leadId)));
        return result;
    }

    public static Map<String, String> validateDataForSelectedAccount(Map<String, String> subBrandBIMap) {
        String defaultBI = subBrandBIMap.get('defaultBI');
        String subBrand = subBrandBIMap.get('subBrand');
        String country = subBrandBIMap.get('country');
        String brand = subBrandBIMap.get('brand');
        if (String.isBlank(defaultBI)) {
            return subBrandBIMap;
        }
        if (String.isBlank(subBrand)) {
            subBrand = null;
        }
        List<Default_Business_Identity_Mapping__mdt> defaultBIMapping = SettingsService.getDefaultBusinessIdentityMapping();
        for (Default_Business_Identity_Mapping__mdt defaultBIMappingRec : defaultBIMapping) {
            if (defaultBIMappingRec.Country__c == country
                && defaultBIMappingRec.Brand__c == brand
                && defaultBIMappingRec.Default_Business_Identity__c == defaultBI
                && defaultBIMappingRec.Sub_Brand__c == subBrand
            ) {
                String biValue = defaultBIMappingRec.Is_Core_Brand__c ? defaultBI : '';
                subBrandBIMap.put('defaultBI', biValue);
                break;
            }
        }
        return subBrandBIMap;
    }

    public static String getCurrentUserProfileName() {
        return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getLeadQualificationsPage(Id leadId, Integer offset) {
        return getLeadQualifications(leadId, offset, QUALIFICATION_RECORDS_LIMIT);
    }

    public static Response getLeadQualifications(Id leadId) {
        return getLeadQualifications(leadId, 0, QUALIFICATION_RECORDS_LIMIT);
    }

    public static Response getLeadQualifications(Id leadId, Integer offset, Integer queryLimit) {

        Response result = new Response();

        LeadQualificationSelector qualSelector = new LeadQualificationSelector();
        QueryFactory qualFactory = qualSelector.selectQualificationsForLeadConvert(leadId, offset, queryLimit + 1);
        List<Lead_Qualification__c> qualififcations = (List<Lead_Qualification__c>) qualFactory.executeQuery();
        Boolean hasMoreRecords = qualififcations.size() > queryLimit;

        if (hasMoreRecords) {
            qualififcations.remove(qualififcations.size() - 1);
        }

        result.setData('leadQualifications', qualififcations);
        result.setData('hasMoreQualifications', hasMoreRecords);

        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getAccountsPage(Id leadId, Integer offset) {
        return getAccounts((Lead) getLead(leadId).data.get('lead'), offset, ACCOUNT_RECORDS_LIMIT);
    }

    public static Response getAccounts(Lead leadObj) {
        return getAccounts(leadObj, 0, ACCOUNT_RECORDS_LIMIT);
    }

    public static Response getAccounts(Lead leadObj, Integer offset) {
        return getAccounts(leadObj, offset, ACCOUNT_RECORDS_LIMIT);
    }

    public static Response getAccounts(Lead leadObj, Integer offset, Integer queryLimit) {
        //These string fields uses also for dynamic SOQL
        String email = leadObj.Email;
        String newPhone = leadObj.Phone;
        String phone = leadObj.Phone;
        String userId = leadObj.User_ID__c;
        String partnerId = leadObj.LeadPartnerID__c;
        String customerType = AccountHelper.TYPE_CUSTOMER;
        Emails__c fakeEmails = Emails__c.getAll().get('fake');
        String fakeEmail =
            fakeEmails == null
                ? ''
                : fakeEmails.Email_Address__c;

        Boolean hasLeadEmail = String.isNotBlank(email);
        Boolean hasLeadPhone = String.isNotBlank(phone);
        Boolean isFakeEmail = hasLeadEmail && email == fakeEmail;
        Boolean isValidEmail = hasLeadEmail && !isFakeEmail;
        Boolean hasMoreRecords = false;

        String conditionQuery = getQuery(isValidEmail, hasLeadPhone);

        String query =
            'SELECT Name, RC_User_ID__c, RC_Account_Number__c, RC_Account_Status__c, Website, ' +
                    'NumberOfEmployees, Industry, No_of_Employees__c, Number_Of_Locations__c, ' +
                    'Billing_System__c, Package_Status__c, Package_Name__c, Billing_ID__c, RecordType.Name, ' +
                    'Service_Type__c, RC_Tier_ID__c, Payment_Plan__c, Number_of_DL_s__c, LastModifiedDate, ' +
                    'Current_Owner__c, Current_Owner__r.Name, EnabledLBO__c, ELA_Account_Type__c, VATNumber__c, ' +
                    'Master_Account__c, Master_Account__r.RC_Account_Status__c, Master_Account__r.Name, ' +
                    'Partner_Id__c, Partner_Type__c, BusinessIdentity__c, Partner_Account__r.NGBS_Partner_ID__c, ' +
                    'inContact_account_ID__c, AccMigrationFlag__c, ' +
                    '(SELECT Id, RC_Tier_ID__c, Service_Type__c FROM Service_Accounts__r) ' +
            'FROM Account ' +
            'WHERE RecordTypeId != \'' + AccountHelper.RT_ID_PARTNER_ACCOUNT + '\'' +
              (partnerId != null ?  ' AND Partner_Id__c = :partnerId ' : '') +
                'AND Id IN ' +
                '(SELECT AccountId ' +
                'FROM Contact ' +
                'WHERE ' + conditionQuery + ') ' +
            'ORDER BY Partner_Id__c NULLS LAST, LastModifiedDate DESC ' +
            'LIMIT ' + (queryLimit + 1) + ' ' +
            'OFFSET ' + offset;

        Response result = new Response();
        List<Account> accounts = new List<Account>();

        if (String.isNotBlank(conditionQuery)) {
            accounts = (List<Account>) Database.query(query);
            hasMoreRecords = accounts.size() > queryLimit;
            if (hasMoreRecords) {
                accounts.remove(accounts.size() - 1);
            }
        }

        result.setData('accounts', accounts);
        result.setData('hasMoreAccounts', hasMoreRecords);

        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getSettings(Id leadId) {
        Response result = new Response();

        result.setData('herokuEndpoint', EndpointsSettingsHandler.uqtServerEndpoint);
        result.setData('origin', Url.getOrgDomainUrl().toExternalForm());
        result.setData('sessionId', SettingsService.getSessionId());
        result.setData('featureToggle', Feature_Toggle__c.getInstance());
        result.setData('brandConfiguration', LeadConversionConfiguration__c.getAll().values());
        result.setData('userCustomPermissions', new CustomPermissionHelper().getPermissionMap());

        result.setData('brandOptionsSerialized', JSON.serialize(OpportunityHelper.getBrandOptions()));
        result.setData('serviceOptionsSerialized', JSON.serialize(OpportunityHelper.getTierNameOptions()));

        result.setData('businessIdentities', SettingsService.getBusinessIdentityMappingJSON(String.valueOf(leadId)));
        result.setData('packageLabels', SettingsService.getPackageLabelsMappingJSON());

        Map<String, List<String>> serviceDependency = OpportunityHelper.getServiceDependency();
        if (!serviceDependency.containsKey(OpportunityHelper.BRAND_AVAYA)) {
            serviceDependency.put(OpportunityHelper.BRAND_AVAYA, new List<String>{Product2Helper.PRODUCT_OFFICE});
        }
        result.setData('serviceDependenciesSerialized', JSON.serialize(serviceDependency));
        result.setData('PhoenixSettings', JSON.serialize(NGBS_Phoenix_Settings__c.getInstance()));

        result.setData('currentUserId', UserInfo.getUserId());
        result.setData('currentUserName', UserInfo.getUserName());
        result.setData('currentUserType', UserInfo.getUserType());
        result.setData('userProfileName', getCurrentUserProfileName());
        result.setData('userTimezoneOffset', UserHelper.getUserTZOffset());
        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getSubBrandAndDefaultBI(String leadId, String brand, String country) {
        Lead lead = (Lead) getLead(leadId).data.get('lead');
        lead.Lead_Brand_Name__c = brand;
        lead.Country__c = country;
        return getSubBrandAndDefaultBI(lead);
    }

    @AuraEnabled(Cacheable=true)
    public static Response getSubBrandAndDefaultBI(Lead leadRec) {
        Response result = new Response();
        Map<String, String> subBrandBIMap = SettingsService.getSubBrandAndDefaultBI(leadRec, null);
        String defaultBI = subBrandBIMap.get('defaultBI');
        String subBrand = subBrandBIMap.get('subBrand');
        String country = subBrandBIMap.get('country');
        String brand = subBrandBIMap.get('brand');
        List<String> availableBIs = SettingsService.getAvailableBusinessIdentities(defaultBI, subBrand, country, brand);
        result.setData('defaultBI', defaultBI);
        result.setData('subBrand', subBrand);
        result.setData('availableBIs', JSON.serialize(availableBIs));
        return result;
    }

    private static Set<String> getCountriesList() {
        Response result = new Response();
        List<Default_Business_Identity_Mapping__mdt> defaultBIMapping = SettingsService.getDefaultBusinessIdentityMapping();
        Set<String> countries = new Set<String>();
        for (Default_Business_Identity_Mapping__mdt defaultBIMappingRec : defaultBIMapping) {
            if (defaultBIMappingRec.is_Core_Brand__c) {
                countries.add(defaultBIMappingRec.Country__c);
            }
        }
        return countries;
    }

    @AuraEnabled(Cacheable=true)
    public static Response getLegacyServices() {
        Response result = new Response();
        result.setData('legacyServices', QuotingToolQuoteApexController.getTiers(new Map < String, String >{
            'recordTypeName' => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
            'isActivePricebook' => 'true'
        }));
        return result;
    }

    @TestVisible
    private static String getQuery(Boolean isValidEmail, Boolean hasLeadPhone) {
      return getQuery(isValidEmail, hasLeadPhone, null);
    }

    @TestVisible
    private static String getQuery(Boolean isValidEmail, Boolean hasLeadPhone, String rcId) {

        String result =
            isValidEmail
                ? hasLeadPhone
                ? '(Email = :email OR Phone = :phone ' +
                    'OR (Account.RC_User_ID__c = :userId '
                : '(Email = :email OR (Account.RC_User_ID__c = :userId '
                : hasLeadPhone
                ? '(Phone = :phone OR (Account.RC_User_ID__c = :userId '
                : null;

        return
            String.isNotBlank(result)
                ? result +=
                'AND Account.RC_User_ID__c != null)) ' +
                    'AND Account.Type = :customerType '
        : null;
    }

    @AuraEnabled
    public static Response getServiceEntitlement(Id accountId) {
        Response result = new Response();
        Entitlement__c serviceEnt = EntitlementHelper.getServiceEntitlement(
            QuoteHelper.RT_ID_SALES,
            QuotingToolQuoteApexController.getEntitlementsSync(accountId)
        );

        PricebookEntry servicePbe = null;
        if (serviceEnt != null) {
            List<PricebookEntry> pricebookEntries =
                QuotingToolQuoteApexController.getPriceBookEntry(new List<Id>{
                    serviceEnt.Product__r.Id
                });
            servicePbe = !pricebookEntries.isEmpty() ? pricebookEntries.get(0) : null;
        }

        result.setData('serviceEntitlement', serviceEnt);
        result.setData('servicePricebookEntry', servicePbe);
        return result;
    }
    @AuraEnabled
    public static Response hasTaxExemptionApprovals(Id accountId, String brand) {
        Response result = new Response();
        result.setData('approvals', ApprovalService.hasTaxExemptionApprovals(accountId, brand));
        result.setData('accountId', accountId);
        result.setData('brand', brand);
        return result;
    }

    @AuraEnabled
    public static Response rejectTaxExemptionApprovals(Id accountId, String brand) {
        Response result = new Response();
        result.setData('rejectApprovals', JSON.serialize(ApprovalService.rejectTaxExemptionApprovals(accountId, brand)));
        result.setData('accountId', accountId);
        return result;
    }

    @AuraEnabled
    public static Response checkAvailableVATNumberSF(Id accountId, Id leadId) {
        Response result = new Response();
        Lead leadToConvert = (Lead) getLead(leadId).data.get('lead');
        if (leadToConvert.VATNumber__c != null && accountId != null) {
            Account acc = (Account) new AccountSelector()
                    .selectAccountWithTaxExemptionApprovals(new List<Object>{new List<String>{accountId}})
                    .executeQuery()
                    .get(0);

            Boolean vatNumberMismatch = false;
            if (acc != null && acc.VATNumber__c != null && leadToConvert.VATNumber__c != acc.VATNumber__c) {
                vatNumberMismatch = true;
                result.warning(AccountHelper.VAT_NUMBER_EXCEPTION_ACCOUNT);
            }
            if (acc != null && !acc.Approvals__r.isEmpty()) {
                for (Approval__c app : acc.Approvals__r) {
                    if (app.VATNumber__c != null && leadToConvert.VATNumber__c != app.VATNumber__c) {
                        vatNumberMismatch = true;
                        break;
                    }
                }
                if (vatNumberMismatch) {
                    result.warning(AccountHelper.VAT_NUMBER_EXCEPTION_APPROVAL);
                }
            }
        }
        return result;
    }

    @TestVisible
    private static void switchTriggers(Boolean switchValue) {
        if (switchValue) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        } else {
            TriggerHandler.RESET_VARIABLES();
        }
    }

    @AuraEnabled
    public static Response getContacts(Id leadId, Id accId, Integer offset) {
        List<Contact> contacts = new List<Contact>();
        String queryCondition = '';
        Response result = new Response();
        List<Object> bindings = new List<Object>();
        bindings.add(leadId);
        Lead lead = (Lead) new LeadSelector().selectLeadById(bindings).executeQuery()[0];
        bindings.clear();
        bindings.add(accId);
        bindings.add(lead.Email);
        bindings.add(lead.Phone);
        if (lead.Email != null && lead.Phone != null) {
            queryCondition = 'AccountId = :bind0 AND (Email = :bind1 OR Phone = :bind2)';
        } else if (lead.Email != null) {
            queryCondition = 'AccountId = :bind0 AND Email = :bind1';
        } else if (lead.Phone != null ) {
            queryCondition = 'AccountId = :bind0 AND Phone = :bind2';
        }
        if(lead.Email != null || lead.Phone != null) {
            contacts = (List<Contact>) new ContactSelector()
                                        .selectContactsForLeadConversion(bindings, CONTACT_RECORDS_LIMIT + 1, offset,queryCondition)
                                        .executeQuery();
        }
        System.debug('#$#$ test contact list ' + contacts);
        Boolean hasMoreRecords = contacts.size() > CONTACT_RECORDS_LIMIT;
        if (hasMoreRecords) {
            contacts.remove(contacts.size() - 1);
        }
        result.setData('contacts', contacts);
        result.setData('hasMoreContacts', hasMoreRecords);
        return result;
    }

    @AuraEnabled
    public static Response getOpportunities(Id accId, Integer offset) {
        List<Opportunity> opps = new List<Opportunity>();
        Response result = new Response();
        Date lastYearSameDate = Date.newInstance(Date.today().year() - 1,
                                                 Date.today().month(),
                                                 Date.today().day());
        List<Object> bindings = new List<Object>();
        bindings.add(accId);
        bindings.add(lastYearSameDate);
        opps = (List<Opportunity>) new OpportunitySelector()
                                            .selectOpportunitiesByAccountId(bindings, OPPORTUNITY_RECORDS_LIMIT + 1, offset)
                                            .executeQuery();
        Boolean hasMoreRecords = opps.size() > OPPORTUNITY_RECORDS_LIMIT;
        if (hasMoreRecords) {
            opps.remove(opps.size() - 1);
        }

        result.setData('hasMoreOpportunities', hasMoreRecords);

        System.debug('#$#$ test opps list ' + opps);

        result.setData('opportunities', opps);

        return result;
    }

    @AuraEnabled
    public static Response getOppContactRoleInfo(Id oppId, Id conId) {
        List<OpportunityContactRole> oppConRoles = new List<OpportunityContactRole>();

        Response result = new Response();
        List<Object> bindings = new List<Object>();
        bindings.add(oppId);
        oppConRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector().selectOpportunityContactRolesByOppId(bindings).executeQuery();
        System.debug('#$#$ test opps list ' + oppConRoles);

        if (oppConRoles.isEmpty()) {
            result.setData('alreadyHasPrimary', false);
            result.setData('alreadyAContactRole', false);
        } else {
            for (OpportunityContactRole ocr : oppConRoles) {
                if (ocr.ContactId == conId) {
                    result.setData('alreadyAContactRole', true);
                    result.setData('role', ocr.Role);
                }
                if (ocr.isPrimary) {
                    result.setData('alreadyHasPrimary', true);
                }
            }
        }

        return result;
    }
}