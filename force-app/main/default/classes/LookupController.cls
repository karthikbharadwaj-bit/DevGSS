public with sharing class LookupController {
    public static Set <Id> usersIdsSet = new Set<Id>();

    public static List <String> proservProfileSet = new List<String>();

    public LookupController() {

    }

    public class LookupResult {

        public LookupResult(String Id, String Text, String Meta, sObject RecordObj) {
            this.Id         = Id;
            this.Text       = Text;
            this.Meta       = Meta;
            this.RecordObj  = RecordObj;
        }

        @AuraEnabled public String  Id        { get; set; }
        @AuraEnabled public String  Text      { get; set; }
        @AuraEnabled public String  Meta      { get; set; }
        @AuraEnabled public sObject RecordObj { get; set; }
    }

  @AuraEnabled
  public static List<LookupResult> getContacts(String searchText, Integer queryLimit) {

    List<LookupResult> result = new List<LookupResult>();

    String query = '';
    String queryFields = 'Id, Name, Account.Name';
    String queryObject = 'Contact';
    String qLimit = queryLimit != null ? 'LIMIT ' + queryLimit : 'LIMIT 5';

    query = 'SELECT '+queryFields+' FROM '+queryObject;

    if( String.isNotBlank(searchText) ) {
      searchText = '%'+searchText+'%';
      query += ' WHERE Name LIKE :searchText ORDER BY Name ASC '+qLimit;
    } else {
      query += ' WHERE LastViewedDate != null ORDER BY LastViewedDate DESC '+qLimit;
    }

        List<Contact> contactList = Database.query(query);

        for (Integer i = 0; i < contactList.size(); i++) {
            LookupResult item = new LookupResult(
                contactList[i].Id,
                contactList[i].Name,
                contactList[i].Account.Name,
                contactList[i]
            );

            result.add(item);
        }

        return result;
    }

    /**
     * Search For Area Codes
     *
     * @see {@link https://rc.my.salesforce.com/a2034000003MJv6} B-2189 Area Codes Filtering and Validations
     * @see {@link https://rc.my.salesforce.com/a2034000003NOOP} B-2342 UX Improvements for Area Codes population
     *
     * @param searchText    User Text to search. Must be longer than one character
     * @param recordId      Area Code Id
     * @param queryLimit    Limit number of records to return (Default 5)
     * @param params        Additional params for filtering results
     *              family  Product2.Family
     *              feature Product2.Feature__c
     *              brand   Brand.Name
     *              type    Lookup type ('Fax')
     *              categoryCode NGBS item package info code (MLFN, HDR...)
     *
     * @return              List of results suitable for Lookup Aura Component
     *                      Format:
     *                      City, State, Country (123)
     *                      Type: Local
     */
    @AuraEnabled
    public static List<LookupResult> getAreaCodes(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if (params == null) {
            params = new Map<String, String>();
        }
        List <LookupResult> result = new List<LookupResult>();
        List <Area_Codes__c> areaCodesList = new List < Area_Codes__c >();

        String query = '';
        String w = ''; // WHERE ...
        String fields = 'Id, Name, Country__c, City__c, State_Abbreviation__c, Area_Code__c, Type__c';
        String obj = 'Area_Codes__c';
        String qLimit = queryLimit != null ? 'LIMIT ' + queryLimit : 'LIMIT 5';
        Boolean isSearch = false;

        // Custom Filtering B-2189
        String family = params.get('family');
        String feature = params.get('feature');
        String brand = params.get('brand');
        String type = params.get('type');
        String categoryCode = params.get('categoryCode');

        Set <String> phoneFamilies = new Set <String> {'Discounted Phones', 'Rental Phones', 'Refurbished Phones', 'Common Phones'};

        Map < String, List<String> > brandToCountries = new Map < String, List<String> > {
            RingCentralHelper.BRAND_AVAYA               => new String [] {'United States', 'Canada'},
            RingCentralHelper.BRAND_RINGCENTRAL         => new String [] {'United States', 'Canada'},
            RingCentralHelper.BRAND_RINGCENTRAL_CANADA  => new String [] {'Canada', 'United States'},
            RingCentralHelper.BRAND_RINGCENTRAL_UK      => new String [] {'United Kingdom'},
            RingCentralHelper.BRAND_RINGCENTRAL_EU      => new String []{
                'Austria', 'Belgium', 'Denmark', 'France', 'Germany', 'Ireland', 'Netherlands', 'Norway', 'Portugal',
                'Spain', 'Sweden', 'Switzerland', 'United Kingdom'
            },
            RingCentralHelper.BRAND_RINGCENTRAL_AU      => new String [] {'Australia'},
            RingCentralHelper.BRAND_ATOS                => new String [] {'France', 'Belgium', 'Austria', 'Denmark',
                'Ireland', 'Italy', 'Netherlands', 'Norway', 'Portugal', 'Spain', 'Sweden', 'Switzerland', 'Finland'},
            RingCentralHelper.BRAND_RAINBOW             => new String [] {'Belgium', 'Italy', 'Spain', 'Ireland',
                'Netherlands', 'Germany', 'Austria', 'France'}
        };
        List <String> countries = String.isNotEmpty(brand) && brandToCountries.containsKey(brand) ?
                brandToCountries.get(brand) :
                new List<String> ();

        if (countries.size() > 0) {

            if (phoneFamilies.contains(family) || feature == '3' || AreaCodeHelper.CATEGORY_CODES_LOCAL_AREA_CODES.contains(categoryCode)) {
                w = 'Country__c IN :countries AND Type__c = \'Local\'';
            } else if (feature == '2' || AreaCodeHelper.CATEGORY_CODES_TOLL_FREE_AREA_CODES.contains(categoryCode)) {
                w = 'Country__c IN :countries AND Type__c = \'Toll-Free\'';
            } else {
                w = 'Country__c IN :countries';
            }

        }

        switch on type {
            when 'fax' {
                w += String.isEmpty(w) ? '' : ' AND ' ;
                w += '(Name != \'800\' OR Area_Code__c != 800)';
            }
            when 'default' {
                w += String.isEmpty(w) ? '' : ' AND ' ;
                w += 'Type__c != \'Toll-Free\'';
            }
        }

        if (String.isNotBlank(searchText) && searchText.length() > 1 && String.isBlank(recordId)) {
            searchText = searchText.replaceAll('\\s', '* ') + '*';
            w = String.isNotEmpty(w) ? 'WHERE ' + w : w;
            query = 'FIND :searchtext IN ALL FIELDS RETURNING '+ obj +' ('+ fields +' '+ w +') ' + qLimit;
            isSearch = true;
        } else if (String.isNotBlank(recordId)){
            query = 'SELECT '+ fields +' FROM '+ obj +' WHERE Id = :recordId ' + qLimit + ' FOR VIEW';
        } else {
            w = String.isNotEmpty(w) ? 'AND ' + w : w;
            query = 'SELECT '+ fields +' FROM '+ obj +' WHERE LastViewedDate != null ' + w + ' ORDER BY LastViewedDate DESC ' + qLimit;
        }

        try {
            areaCodesList = isSearch ? Search.query(query)[0] : Database.query(query);
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }

        for (Area_Codes__c ac : areaCodesList) {

            String text = '';
            text += String.isNotBlank(ac.City__c)    ? ac.City__c + ', '    : '';
            text += String.isNotBlank(ac.State_Abbreviation__c)   ? ac.State_Abbreviation__c + ', '   : '';
            text += String.isNotBlank(ac.Country__c) ? ac.Country__c + ' '  : '';
            text += String.isNotBlank(ac.Name)       ? '('+ ac.Name + ') ' : '';

            String meta = String.isNotBlank(ac.Type__c) ? 'Type: '+ ac.Type__c : '';

            LookupResult item = new LookupResult( ac.Id, text, meta, ac);

            result.add(item);
        }
        return result;
    }

    /**
     * Search for Users
     * All fields used for search
     *
     * B-3094 ProServ Quotes Layout update
     * https://rc.my.salesforce.com/a2034000003Unzv
     *
     * @param searchText
     * @param recordId
     * @param queryLimit
     * @param params
     *
     * @return List of results suitable for Lookup Aura Component
     *         Format:
     *         Name
     *         Email
     */
    @AuraEnabled
    public static List<LookupResult> getUsers(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if (params == null) {
            params = new Map<String, String>();
        }
        List <LookupResult> result = new List<LookupResult>();

        String fields = 'Id, Name, Email';
        String additionalConditions = '';

        if (!params.isEmpty() && params.get('filterByProservProfile') != null) {
            /* EU Phase 3 - inclusion of restricted profiles - START */
            List<EU_Component_reference__mdt> ProfMetaData = [Select DeveloperName, Values__c from EU_Component_reference__mdt where DeveloperName like '%Professional_Services_Proserv_Lightning%'];
            for (EU_Component_reference__mdt prof : ProfMetaData)
            {
                proservProfileSet.addall(prof.Values__c.contains(',')?prof.Values__c.split(','):new List<String>{prof.Values__c});
            }
            /* EU Phase 3 - inclusion of restricted profiles - END */
            additionalConditions = 'Profile.Name IN : proservProfileSet';
        }
        if (!params.isEmpty() && params.get('permissionName') != null) {
            usersIdsSet = UserHelper.getUsersByPermissionSetAssignees(params.get('permissionName'));
            additionalConditions = 'Id IN : usersIdsSet';
        }

        // Get records
        List<User> usersList =
            (List<User>) queryRecords(searchText, 'User', fields, additionalConditions, queryLimit, recordId);

        // Prepare result
        for (User usr : usersList) {

            String text = usr.Name;
            String meta = usr.Email;

            LookupResult item = new LookupResult( usr.Id, text, meta, usr);

            result.add(item);
        }
        return result;
    }

    @AuraEnabled
    public static List<LookupResult> getRecords(String sObjectName, String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if (params == null) {
            params = new Map<String, String>();
        }

        if (params.get('sObjectName') != null ) {
            sObjectName = params.get('sObjectName');
        }

        List <LookupResult> result = new List<LookupResult>();

        String nameFieldName = SFDescribeHelper.getNameField(sObjectName).getName();
        String fields = 'Id, '+ nameFieldName;

        System.debug(sObjectName + '<->' +fields);
        // Get records
        List<sObject> recordList = queryRecords(searchText, sObjectName, fields, '', queryLimit, recordId);

        // Prepare result
        for (sObject record : recordList) {

            String text = String.valueOf(record.get(nameFieldName));
            String recId = String.valueOf(record.get('Id'));

            LookupResult item = new LookupResult( recId, text, '', record);

            result.add(item);
        }
        return result;
    }

    /**
     * Builds query and perform search for records
     * SOQL 1) if recordId specified
     *      2) if searchText or recordId are empty. Will return list of last viewed items
     *
     * SOSL 1) if searchText text specified and recordId is empty
     *
     * @param searchText
     * @param recordId      specify record id to get specific record
     * @param w             WHERE soql clause
     * @param obj           sObject Name
     * @param qLimit        Limit number of records to return
     *
     * @return
     */
    private static List<sObject> queryRecords(String searchText, String obj, String fields, String w, Integer queryLimit, Id recordId) {
        List<sObject> resultList = new List<sObject>();
        String qLimit = queryLimit != null && queryLimit >= 0
            ? 'LIMIT ' + queryLimit
            : 'LIMIT 5';

        if (String.isNotBlank(searchText) && searchText.length() > 1 && String.isBlank(recordId)) {
            searchText = searchText.replaceAll('\\s', '* ') + '*';
            w = String.isNotEmpty(w) ? 'WHERE ' + w : w;
            String query = 'FIND \'' + String.escapeSingleQuotes(searchText) + '\' IN ALL FIELDS RETURNING ' + obj + ' (' + fields + ' ' + w + ') ' + qLimit;
            resultList = LookupController.makeSearchQuery(query);

        } else if (String.isNotBlank(recordId)) {
            String query = 'SELECT '+ fields +' FROM '+ obj +' WHERE Id = \'' + recordId + '\' ' + qLimit;
            resultList = LookupController.makeDatabaseQueryForView(query);

        } else {
            w = String.isNotEmpty(w) ? 'AND ' + w : w;
            String query = 'SELECT '+ fields +' FROM '+ obj +' WHERE LastViewedDate != null ' + w + ' ORDER BY LastViewedDate DESC ' + qLimit;
            resultList = LookupController.makeDatabaseQuery(query);
        }

        return resultList;
    }

    private static List<SObject> makeSearchQuery(String query) {
        List<SObject> queriedRecords = new List<SObject>();
        try {
            System.debug('query = ' + query);
            queriedRecords = Search.query(query)[0];
        } catch (QueryException e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }
        return queriedRecords;
    }

    private static List<SObject> makeDatabaseQuery(String query) {
        List<SObject> queriedRecords = new List<SObject>();
        try {
            System.debug('query = ' + query);
            queriedRecords = Database.query(query);
        } catch (QueryException e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }
        return queriedRecords;
    }

    private static List<SObject> makeDatabaseQueryForView(String query) {
        List<SObject> queriedRecords = new List<SObject>();
        try {
            System.debug('query = ' + query);
            queriedRecords = Database.query(query + ' FOR VIEW');
        } catch (QueryException e) {
            queriedRecords = LookupController.makeDatabaseQuery(query);
        }
        return queriedRecords;
    }

    @AuraEnabled
    public static List<LookupResult> getContacts(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if (params == null) {
            params = new Map<String, String>();
        }
        List <LookupResult> result = new List<LookupResult>();
        String w = ''; // WHERE ...
        String fields = 'Id, Name, Account.Id, Account.Name, Email, Phone';
        Boolean isPrimaryBoolean =  BooleanHelper.toBoolean(params.get('isPrimary'));
        Id primConId;
        Id primaryAccountId = params.get('accountId');

        // 1. Change Contact Selector logic to show only Primary and Signatory contact from the Account.
        // 1.1. Do not show non-Primary and/or non-Signatory Contacts at all.
        if (BooleanHelper.toBoolean(params.get('applyContactRoleFilter'))
            && String.isNotBlank(params.get('accountId'))
        ) {

            List<AccountContactRole> crs;
            if (BooleanHelper.toBoolean(params.get('isPayableOnly'))) {
                crs = (List<AccountContactRole>) new AccountContactRoleSelector()
                    .selectAccountPayableContactRolesByAccount(
                        new List<Object> { params.get('accountId'), params.get('existingContact') }
                    )
                    .executeQuery();
            } else if(isPrimaryBoolean) {
                crs = (List<AccountContactRole>) new AccountContactRoleSelector()
                    .selectPrimaryOrSignatoryContactRolesForLookup(new List<Object> { params.get('accountId') })
                    .executeQuery();
            } else {
                crs = (List<AccountContactRole>) new AccountContactRoleSelector()
                    .selectConversionContactsForLookup(new List<Object> { params.get('accountId') })
                    .executeQuery();
            }
        Set<Id> contactIDs = new Set<Id>();
        for (AccountContactRole cr : crs) {
            if (isPrimaryBoolean) {
                contactIDs.add(cr.ContactId);
            } else if (cr.isPrimary) {
                primConId = cr.ContactId; 
              }
           }

            w = String.format('ID IN ({0})', new List<String>{
                '\'' + String.join(new List<Id>(contactIDs), '\', \'') + '\''
            });

        } else if (String.isNotBlank(params.get('accountId'))) {
            Id accountId = params.get('accountId');
            w = 'AccountId = \'' + accountId + '\'';
        }

        List<Contact> contactList = new List<Contact>();
        contactList = queryRecords(searchText, 'Contact', fields, w, queryLimit, recordId);

    if (!isPrimaryBoolean && primaryAccountId != null) {
        List<Contact> conversionCons = (List<Contact>) new ContactSelector()
            .selectConversionContactsByAccount(primaryAccountId, primConId)
            .executeQuery();
        contactList.addAll(conversionCons);
    }

        for (Contact c : contactList) {

            String text = c.Name;
            String meta = String.isNotBlank(c.Email) ? c.Email : '';
            meta += String.isNotBlank(c.Phone) ? ' • ' + c.Phone : '';

            LookupResult item = new LookupResult( c.Id, text, meta, c);

            result.add(item);
        }
        return result;
    }

    @AuraEnabled
    public static List<LookupResult> getAccounts(String searchText, String recordId, Integer queryLimit, Map<String, String> params, Boolean hideMultiProductTechAccounts) {
        if (params == null) {
            params = new Map<String, String>();
        }
        List <LookupResult> result = new List<LookupResult>();
        System.debug(params);

        String w = ''; // WHERE ...
        String fields = 'Id';

        if (String.isNotBlank(params.get('partnerOnly'))) {
            w += 'RecordTypeId = ' + '\'' + AccountHelper.RT_ID_PARTNER_ACCOUNT + '\' '
                + ' AND BusinessIdentity__c = ' + '\'' + params.get('businessIdentity') + '\' '
                + ' AND PartnerStatus__c = ' + '\'' + 'Active' + '\' ';

            if (params.containsKey('partnerBobOrWholesale')) {
                List<String> partners = new List<String>();
                if (Boolean.valueOf(params.get('partnerBobOrWholesale'))) {
                    partners = params.containsKey('engagePartners') && Boolean.valueOf(params.get('engagePartners'))
                        ? new List<String>{AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF}
                        : getPartnersList(AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS, AccountHelper.ACCOUNT_WHOLESALE_PARTNERS);
                } else if (params.containsKey('engagePartners') && Boolean.valueOf(params.get('engagePartners'))) {
                    partners = AccountHelper.ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES;
                }
                w += !partners.isEmpty()
                    ? 'AND Partner_Type__c IN ' + '(\'' + String.join(partners, '\',\'') + '\'' + ')'
                    : '';
            }

            if (String.isNotBlank(params.get('currentPartnerId'))) {
                w += ' AND Id != ' + '\'' + params.get('currentPartnerId') + '\' ';
            }

        } else if (String.isNotBlank(params.get('filterOutPartnerAccounts')))  {
            w += 'RecordTypeId != ' + '\'' + AccountHelper.RT_ID_PARTNER_ACCOUNT + '\' ' + ' AND RecordTypeId != ' + '\'' + AccountHelper.RT_ID_ZI_ACCOUNT + '\' ';
        }
        if (params.containsKey('partnerLead') && Boolean.valueOf((String) params.get('partnerLead'))) {
            Id leadId = (Id) params.get('leadId');
            String partnerId = [SELECT LeadPartnerID__c FROM Lead WHERE Id = :leadId].LeadPartnerID__c;
            if (partnerId != null) {
                w += ' AND Partner_Id__c = \'' + partnerId + '\' ';
            }
        }
        if (String.isNotBlank(params.get('partnerId'))
            && String.isNotBlank(params.get('partnerType'))
            && params.get('partnerType') == AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF) {
            w += 'Partner_Id__c = ' + '\'' + params.get('partnerId') + '\' '
                + ' AND Partner_Type__c = ' + '\'' + params.get('partnerType') + '\' ';
        }

        List <Account> accountList =
                (List<Account>) queryRecords(searchText, 'Account', fields, w, queryLimit, recordId);

        // Get accounts with additional info that can't be retrieved via sosl
        Map<Id, Account> accMap = new Map<Id, Account>(accountList);
        accountList = [
                SELECT Id, Name, RC_User_ID__c, RC_Tier_ID__c, RC_Tier__c, RC_Brand__c, Payment_Plan__c, RC_Service_name__c,
                        Number_of_DL_s__c, Sales_Agreement_Start_Date__c, Sales_Agreement_End_Date__c, Service_Type__c,
                        Billing_ID__c, BillingAddress, BillingCity, BillingCountry, BillingPostalCode, BillingStreet,
                        BillingState, Active_Sales_Agreement__c, Package_Name__c, Package_Status__c, Billing_System__c,
                        RecordTypeId, CurrencyIsoCode, EnabledLBO__c, ELA_Account_Type__c, RC_Account_Status__c,
                        Master_Account__c, Master_Account__r.RC_Account_Status__c, isFedRamp__c, NGBS_Partner_ID__c,
                        Partner_ID__c, Partner_Type__c, Partner_Account__c, Partner_Account_Name__c, Ultimate_Partner_Name__c,
                        BusinessIdentity__c, Partner_Account__r.NGBS_Partner_ID__c, inContact_account_ID__c,
                        OwnerId, Parent_Partner_Account__c, CSM__c, AccMigrationFlag__c,
                            (SELECT Id, NumberOfPrimaryUserLicenses__c, Package_Status__c, Service_Type__c, RC_Tier_ID__c, Enterprise_Account_ID__c FROM Service_Accounts__r),
                            (SELECT Id, ContactId, Role, IsPrimary FROM AccountContactRoles),
                    (SELECT Id FROM Master_Accounts__r WHERE IsMultiProductTechnicalAccount__c = true)
                FROM Account
                WHERE Id IN :accMap.keySet()
                ORDER BY LastViewedDate DESC
        ];

        Set<Id> multiproductAccountIds = new Set<Id>();
        if (BooleanHelper.toBoolean(hideMultiProductTechAccounts)) {
            for (Account account : accountList) {
                if (account.Master_Accounts__r.isEmpty()) {
                    continue;
                }
                multiproductAccountIds.add(account.Id);

                for (Account techAcc : account.Master_Accounts__r) {
                    multiproductAccountIds.add(techAcc.id);
                }
            }
        }

        for (Account a : accountList) {
            if (multiproductAccountIds.contains(a.Id)) {
                continue;
            }
            String text = a.Name;
            List<String> metaEntities = new List<String>();
            if (String.isBlank(params.get('partnerOnly'))) {
                if (String.isNotBlank(a.RC_Tier__c)) {
                    metaEntities.add(a.RC_Tier__c);
                }
                if (String.isNotBlank(a.ELA_Account_Type__c)) {
                    metaEntities.add('ELA Type: ' + a.ELA_Account_Type__c);
                }
            } else {
                if (String.isNotBlank(a.Partner_Type__c)) {
                    metaEntities.add(a.Partner_Type__c);
                }
            }
            String meta = String.join(metaEntities, ' • ');

            LookupResult item = new LookupResult(a.Id, text, meta, a);

            result.add(item);
        }
        return result;
    }

    public static List<String> getPartnersList(List<String> billOnBehalfPartners, List<String> wholesalePartners) {
        List<String> partners = new List<String>();
        partners.addAll(billOnBehalfPartners);
        partners.addAll(wholesalePartners);
        return partners;
    }

    @AuraEnabled
    public static List<LookupResult> getEngageLegalApprovals(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if(params == null) {
            params = new Map<String, String>();
        }

        String whereClause = 'RecordType.Name = \'Engage Legal\'';

        if(params.containsKey('accountId') && String.isNotBlank(params.get('accountId'))) {
            whereClause = String.join(new List<String> { whereClause, 'Account__c = \'' + params.get('accountId') + '\''}, ' AND ');
        }

        List<Approval__c> engageLegalList = (List<Approval__c>) queryRecords(searchText, 'Approval__c', 'Name, Approval_ID__c', whereClause, queryLimit, recordId);

        List<LookupResult> result = new List<LookupResult>();
        for(Approval__c engageLegal: engageLegalList) {
            result.add(new LookupResult(engageLegal.Id, engageLegal.Approval_ID__c, engageLegal.Name, engageLegal));
        }

        return result;
    }

    @AuraEnabled
    public static List<LookupResult> getQuotes(
        String searchText,
        String recordId,
        Integer queryLimit,
        Map<String, String> params) {

        if (params == null) {
            params = new Map<String, String>();
        }

        List<LookupResult> result = new List<LookupResult>();

        String query = '';
        /* WHERE ... */
        String w = '';
        String qFields = ' Id, Opportunity.Name, Opportunity.CreatedDate ';
        String qObject = 'Quote';
        String qLimit = queryLimit != null ? ' LIMIT ' + queryLimit : ' LIMIT 5 ';
        String order = '';

        /* Custom Filtering */
        String accountId = params.get('accountId');
        String isPrimary = params.get('isPrimary');
        String isNotPOC = params.get('isNotPOC');

        w += isPrimary != null ? 'isPrimary__c = ' + isPrimary : '';
        if (accountId != null) {
            w += String.isEmpty(w)
                ? 'Opportunity.Account.Id = \'' + accountId + '\''
                : ' AND ' + 'Opportunity.Account.Id = \'' + accountId + '\'';
        }

        if (isNotPOC != null) {
            w += String.isEmpty(w)
                ? 'RecordTypeId != \'' + QuoteHelper.RT_ID_POC + '\''
                : ' AND ' + 'RecordTypeId != \'' + QuoteHelper.RT_ID_POC + '\'';
        }

        if ( String.isNotBlank(searchText) ) {
            searchText = '%' + searchText + '%';
            w += String.isEmpty(w)
                ? ' Opportunity.Name LIKE \'' + searchText + '\''
                :  ' AND ' + ' Opportunity.Name LIKE \'' + searchText + '\'';

            order += ' ORDER BY Name ASC, ';
        }

        if (String.isNotBlank(recordId)) {
            w += String.isEmpty(w)
                ? ' Id = \'' + recordId + '\''
                : ' AND ' + 'Id = \'' + recordId + '\'';
        }

        order += String.isEmpty(order) ? ' ORDER By LastViewedDate DESC' : ' LastViewedDate DESC';
        query = 'SELECT ' + qFields + ' FROM ' + qObject + ' WHERE ' + w + order + qLimit;
        System.debug('Get quotes query -> ' + query);
        List<Quote> quoteList = Database.query(query);

        for (Quote qt : quoteList) {
            LookupResult item = new LookupResult(
                qt.Id,
                qt.Opportunity.Name,
                qt.Opportunity.CreatedDate.format('MMM d yyyy'),
                qt
            );
            result.add(item);
        }

        return result;
    }

    @AuraEnabled
    public static List<LookupResult> getProducts(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        List<LookupResult> result = new List<LookupResult>();

        if (params == null) {
            params = new Map<String, String>();
        }

        String obj = 'Product2';
        String fields = 'Id, Name, GOA_Group_V3__c, Sub_Category__c';
        String productCategory = params.get('productCategory');
        String w = '';
        String qLimit = '';

        List<Product2> records;
        if (String.isNotBlank(recordId)) {
            records = (List<Product2>) queryRecords(searchText, 'Product2', fields, w, queryLimit, recordId);
        } else if (String.isNotBlank(searchText)) {
            String query = 'FIND :searchtext IN ALL FIELDS RETURNING '+ obj +' ('+ fields +') ' + qLimit;
            records = Search.query(query)[0];
        } else {
            String query = 'SELECT ' + fields + ' FROM ' + obj;
            records = Database.query(query);
        }

        // Prepare result
        for (Product2 prod : records) {

            String text = prod.Name;
            String meta = '';

            LookupResult item = new LookupResult( prod.Id, text, meta, prod);

            String goaGroupV3Regular = Product2Helper.getGoaGroup(prod.GOA_Group_V3__c);

            Boolean isDefaultCategory = productCategory == Product2Helper.DEFAULT_CATEGORY;
            Boolean isNotCCSubcategoryEmptyGOA = String.isBlank(prod.GOA_Group_V3__c) && prod.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER;

            Boolean isApplicableCategory = String.isBlank(productCategory) || goaGroupV3Regular == productCategory;

            if ((isDefaultCategory && isNotCCSubcategoryEmptyGOA) || (!isDefaultCategory && isApplicableCategory)) {
                result.add(item);
            }
        }

        return result;
    }

    @AuraEnabled
    public static List<LookupResult> getQueuesSObjects(String searchText, String recordId, Integer queryLimit, Map<String, String> params) {
        if (params == null) {
            params = new Map<String, String>();
        }
        List <LookupResult> result = new List<LookupResult>();
        String fields = 'Id, QueueId, Queue.Name, SobjectType';
        String additionalConditions = '';

        if (!params.isEmpty() && params.get('nameOfQueueSupportObject') != null) {
            additionalConditions = 'SobjectType = ' + '\'' + params.get('nameOfQueueSupportObject') + '\'';
        }

        // Get records
        List<QueueSobject> queueSObjects =
            (List<QueueSobject>) queryQueuesSObjectsRecords(searchText, 'QueueSobject', fields, additionalConditions, queryLimit, recordId);

        // Prepare result
        for (QueueSobject queueSBoject : queueSObjects) {

            String text = queueSBoject.Queue.Name;
            String meta = '';

            LookupResult item = new LookupResult( queueSBoject.QueueId, text, meta, queueSBoject);

            result.add(item);
        }
        return result;
    }

    private static List<sObject> queryQueuesSObjectsRecords(String searchText, String obj, String fields, String w, Integer queryLimit, Id recordId) {
        List<sObject> resultList = new List<sObject>();
        String qLimit = queryLimit != null && queryLimit >= 0
            ? 'LIMIT ' + queryLimit
            : 'LIMIT 5';

        if (String.isNotBlank(searchText) && searchText.length() > 1 && String.isBlank(recordId)) {
            searchText = '\'' + searchText + '%\'';
            w = String.isNotEmpty(w) ? 'WHERE ' + w : w;
            String query = 'SELECT '+ fields +' FROM '+ obj +' ' + w + ' AND Queue.Name LIKE ' + searchText + ' ' + qLimit;
            resultList = LookupController.makeDatabaseQuery(query);
        } else if (String.isNotBlank(obj)) {
            w = String.isNotEmpty(w) ? w : w;
            String query = 'SELECT '+ fields +' FROM '+ obj +' WHERE ' + w + ' ' + qLimit;
            resultList = LookupController.makeDatabaseQuery(query);
        }

        return resultList;
    }

}