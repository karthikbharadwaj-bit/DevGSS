public class PartnerRequestDuplicateAccountSearcher {
    private static final Integer MAX_DIFF_IN_ADDRESS = 5;
    private static final String PARTNER_ACCOUNT_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Partner Account').getRecordTypeId();
    private static final Integer MAX_DUPLICATES_FOUND = 20;
    private static final List<String> DOMAINS_TO_EXCLUDE = new List<String>();


    public static SearchResult findDuplicates(Partner_Request__c[] requestsToSearchBy) {
        if (requestsToSearchBy == null) {
            System.debug('PartnerRequestDuplicateAccountSearcher.findDuplicates incoming null as parameter requestsToSearchBy');
            return null;
        }
        List<PartnerAccountEmailDomain__c> partnerAccountEmailDomainList = (List<PartnerAccountEmailDomain__c>) new PartnerAccountEmailDomainSelector()
            .selectPartnerAccountEmailDomainRecords()
            .executeQuery();
        for (PartnerAccountEmailDomain__c record : partnerAccountEmailDomainList) {
            DOMAINS_TO_EXCLUDE.add(record.Email_Domain__c);
        }

        Set<String> accountNames = new Set<String>();
        Set<String> emailDomains = new Set<String>();
        Set<String> addrCountries = new Set<String>();
        Set<String> addrPostalCodes = new Set<String>();
        Set<String> addrStates = new Set<String>();
        Set<String> addrCities = new Set<String>();

        for (Partner_Request__c entry : requestsToSearchBy) {
            accountNames.add(String.escapeSingleQuotes(entry.Partner_Company_Name__c.toUpperCase()));
            emailDomains.add(String.escapeSingleQuotes(getEmailDomain(entry.Partner_Email_Address__c).toUpperCase()));
            addToSetIfNotNull(addrCountries, entry.Partner_Country__c);
            addToSetIfNotNull(addrPostalCodes, entry.Partner_Zip__c);
            addToSetIfNotNull(addrStates, entry.Partner_State__c);
            addToSetIfNotNull(addrCities, entry.Partner_City__c);
        }

        String soqlQueryForAccounts = getSoqlSearchQueryForAccounts(emailDomains, 'accountNames', 'addrCountries', 'addrPostalCodes',
            'addrStates', 'addrCities');

        String soqlQueryForContacts = getSoqlSearchQueryForContacts(emailDomains, 'addrCountries', 'addrPostalCodes',
            'addrStates', 'addrCities');

        List<Account> foundDuplicateAccounts = new List<Account>();
        for (Account duplicateAccount : Database.query(soqlQueryForAccounts)) {
            foundDuplicateAccounts.add(duplicateAccount);
        }

        Set<Contact> foundContacts = new Set<Contact>();
        for (Contact entry : Database.query(soqlQueryForContacts)) {
            foundContacts.add(entry);
        }

        SearchResult result = new SearchResult(foundDuplicateAccounts, foundContacts, requestsToSearchBy);
        return result;
    }

    private static void addToSetIfNotNull(Set<String> valueSet, String value) {
        if (String.IsNotBlank(value)) {
            valueSet.add(String.escapeSingleQuotes(value));
        }
    }

    private static String getSoqlSearchQueryForAccounts(Set<String> emails, String accountsVarName, String countriesVarName,
        String postcalCodesVarName, String statesVarName, String citiesVarName)
    {
        String soqlTemplate = 
            'SELECT Name, Contact_Email__c, BillingCountry, BillingPostalCode, BillingState, BillingCity, BillingStreet ' +
            'FROM Account ' +
            'WHERE ' +
            '    RecordTypeId = :PARTNER_ACCOUNT_RT_ID ' +
            '    AND (' +
            '        Name IN :' + accountsVarName + ' ' +
            + getQueryConditionForEmail('Contact_Email__c', emails) +
            '        OR (BillingCountry IN :' + countriesVarName + ' AND ' +
            '            BillingPostalCode IN :' + postcalCodesVarName + ' AND ' +
            '            BillingState IN :' + statesVarName + ' AND ' +
            '            BillingCity IN :' + citiesVarName + ') ' +
            '    )';

        return soqlTemplate;
    }

    private static String getSoqlSearchQueryForContacts(Set<String> emails, String countriesVarName,
        String postcalCodesVarName, String statesVarName, String citiesVarName)
    {
        String soqlTemplate = 
            'SELECT AccountId, Email, MailingCountry, MailingPostalCode, MailingState, MailingCity, MailingStreet ' +
            'FROM Contact ' +
            'WHERE ' +
            '    Account.RecordTypeId = :PARTNER_ACCOUNT_RT_ID AND ' +
            //'    (' + getQueryConditionForEmail('Email', emails) + ' OR ' +
            '        (MailingCountry IN :' + countriesVarName + ' AND ' +
            '         MailingPostalCode IN :' + postcalCodesVarName + ' AND ' +
            '         MailingState IN :' + statesVarName + ' AND ' +
            '         MailingCity IN :' + citiesVarName  + ') ' +
            'LIMIT 2000';

        return soqlTemplate;
    }

    private static String getQueryConditionForEmail(String fieldName, Set<String> emails) {
        String result = '';
        if (emails.size() == 0) {
            return result;
        }
        for (String email : emails) {
            if (DOMAINS_TO_EXCLUDE.contains(email.toLowerCase())) {
                continue;
            }
            result += ' OR ' + fieldName + ' LIKE \'%' + email.toLowerCase() + '\' ';
        }
        return result;
    }


    private static String getEmailDomain(String val) {
        Integer i = val.indexOf('@');
        return (i > -1 ? val.substring(i + 1) : val);
    }
 

    public class SearchResult {
        public Map<Id, Account> FoundByNameAccounts { get; private set; }
        public Map<Partner_Request__c, Set<Id>> AllFoundAccounts { get; private set; }

        public SearchResult(Account[] foundAccs, Set<Contact> foundCncts, Partner_Request__c[] requestsToSearchBy)
        {
            prepareSearchResult(foundAccs, foundCncts, requestsToSearchBy);
        }

        private void prepareSearchResult(Account[] foundAccs, Set<Contact> foundCncts,
            Partner_Request__c[] requestsToSearchBy)
        {
            if (foundAccs == null) {
                System.debug('PartnerRequestDuplicateAccountSearcher->SearchResult.prepareSearchResult ' +
                    'incoming null as parameter foundAccs');
                return;
            }
            if (requestsToSearchBy == null) {
                System.debug('PartnerRequestDuplicateAccountSearcher->SearchResult.prepareSearchResult ' +
                    'incoming null as parameter requestsToSearchBy');
                return;
            }

            this.FoundByNameAccounts = new Map<Id, Account>();
            this.AllFoundAccounts = new Map<Partner_Request__c, Set<Id>>();

            processFoundAccounts(foundAccs, requestsToSearchBy, this.AllFoundAccounts, this.FoundByNameAccounts);

            if (foundCncts != null) {
                processFoundContacts(foundCncts, requestsToSearchBy, this.AllFoundAccounts);
            }
        }

        private void processFoundAccounts(Account[] foundAccs, Partner_Request__c[] requestsToSearchBy,
            Map<Partner_Request__c, Set<Id>> storeToSaveAllAccounts, Map<Id, Account> storeToSaveAccountsByName)
        {
            for (Account acc : foundAccs) {
                for (Partner_Request__c req : requestsToSearchBy) {
                    Set<Id> accStore = storeToSaveAllAccounts.get(req);
                    if (accStore == null) {
                        storeToSaveAllAccounts.put(req, new Set<Id>());
                        accStore = storeToSaveAllAccounts.get(req);
                    }
                    if (acc.Name.equalsIgnoreCase(req.Partner_Company_Name__c) || 
                        (!String.isBlank(acc.Contact_Email__c) && getEmailDomain(acc.Contact_Email__c).equalsIgnoreCase(getEmailDomain(req.Partner_Email_Address__c)))
                    ) {
                        accStore.add(acc.Id);
                        if (!storeToSaveAccountsByName.containsKey(acc.Id)) {
                            storeToSaveAccountsByName.put(acc.Id, acc);
                        }
                    } else if (CompareAddresses(req, acc.BillingCountry, acc.BillingPostalCode, acc.BillingState,
                        acc.BillingCity, acc.BillingStreet))
                    {
                        accStore.add(acc.Id);
                    }
                }
            }
        }

        private void processFoundContacts(Set<Contact> foundCntcs, Partner_Request__c[] requestsToSearchBy,
            Map<Partner_Request__c, Set<Id>> storeToSaveAllAccounts)
        {
            for (Contact cntEntry : foundCntcs) {
                for (Partner_Request__c req : requestsToSearchBy) {
                    Set<Id> accStore = storeToSaveAllAccounts.get(req);
                    if (accStore == null) {
                        storeToSaveAllAccounts.put(req, new Set<Id>());
                        accStore = storeToSaveAllAccounts.get(req);
                    }
                    String domain = PartnerRequestDuplicateAccountSearcher.getEmailDomain(req.Partner_Email_Address__c);
                    if (toString(cntEntry.Email).containsIgnoreCase(domain)) {
                        accStore.add(cntEntry.AccountId);
                    } else if (CompareAddresses(req,
                        toString(cntEntry.MailingCountry),
                        toString(cntEntry.MailingPostalCode),
                        toString(cntEntry.MailingState), 
                        toString(cntEntry.MailingCity),
                        toString(cntEntry.MailingStreet)))
                    {
                        accStore.add(cntEntry.AccountId);
                    }
                }
            }
        }

        private String toString(Object val) {
            return val != null ? (String)val : '';
        }

        private Boolean CompareAddresses(Partner_Request__c req, String country, String postalCode,
            String state, String city, String street)
        {
            Boolean result = false;

            if (String.IsBlank(country)
                && String.IsBlank(postalCode)
                && String.IsBlank(state)
                && String.IsBlank(city)
                && String.IsBlank(street))
            {
                return result;
            }

            if (country == null || req.Partner_Country__c.equalsIgnoreCase(country)) {
                if (postalCode == null || req.Partner_Zip__c.equalsIgnoreCase(postalCode)) {
                    if (state == null || req.Partner_State__c.equalsIgnoreCase(state)) {
                        if (city == null || req.Partner_City__c.equalsIgnoreCase(city)) {
                            Integer distance = 0;
                            if (String.IsNotBlank(street)) {
                                if (String.IsNotBlank(req.Partner_Address2__c)) {
                                    distance = street.getLevenshteinDistance(req.Partner_Address1__c + ' ' +
                                        req.Partner_Address2__c);
                                } else {
                                    distance = street.getLevenshteinDistance(req.Partner_Address1__c);
                                }
                            }
                            //addresses are equals or need extra space to add to be equals (>=1), 
                            //but no more MAX_DIFF_IN_ADDRESS modifications
                            result = (distance == 0) || (distance >= 1 && distance < MAX_DIFF_IN_ADDRESS);
                        }
                    } 
                }
            }

            return result;
         }
    }
}