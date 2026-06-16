public without sharing class CaseListAPIController {

    public static final String URL_SCAPI_V1_CASE = '/SCApi/v1/case';
    public static final String SUCCESS_MESSAGE = 'List of cases provided';
    public static final String CASES_LABEL = 'cases';
    public static final String NEXT_PAGE_URL = 'nextPageUrl';
    public static final String TOTAL_RECORDS = 'totalCases';
    public static final String TOTAL_ACCOUNT_RECORDS = 'totalAccountCases';
    public static final String CONTACT_VIEW = 'contact';
    public static final String ACCOUNT_VIEW = 'account';
    public static final String BAD_REQUEST_ONLY_VALID_FOR_ADMIN_USERS = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': view parameter is only valid for Admin users';
    public static final String BAD_REQUEST_INVALID_SORTBY_VALUE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid sortBy value. Supported values are caseNumber, subject, createdDate, contact, status and site';
    public static final String BAD_REQUEST_INVALID_SORTORDER_VALUE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid sortOrder value. Supported values are asc or desc';
    public static final String LANG_KEY = 'lang';
    public static final String DEFAULT_LANG = 'en_US';

    public static final Integer DEFAULT_LIMIT = 25;

    private static final List<String> CASES_PREVIEW_FIELDS = new List<String>{
        'Id',
        'CaseNumber',
        'ContactId',
        'Contact.Name',
        'Contact.Email',
        'Subject',
        'Case_Severity__c',
        'CreatedDate',
        'Status',
        'Site__c',
        'RecordTypeId',
        'recordtype.Name'
    };

    private static final Map<String,String> SORT_OPTIONS_MAP = new Map<String,String> {
        'casenumber' => 'CaseNumber',
        'subject' => 'Subject',
        'createddate' => 'CreatedDate',
        'contact' => 'Contact.Name',
        'status' => 'Status',
        'site' => 'Site__c'
    };

    private static final Map<String, Boolean> STATUS_FILTER_TO_IS_CLOSED_CONDITION_MAP = new Map<String, Boolean>{
        'Open Cases' => false,
        'Closed Cases' => true
    };

    private static final Map<String,QueryFactory.SortOrder> SORT_ORDER_MAP = new Map<String,QueryFactory.SortOrder> {
        'desc' => QueryFactory.SortOrder.DESCENDING,
        'asc' => QueryFactory.SortOrder.ASCENDING
    };

    public static Map<String, Object> getCasesInfo(String request) {

        Map<String, Object> res = new Map<String, Object>();

        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            validateRequest(req);

            String uid = (String) req.get('uid');
            String email = (String) req.get('email');
            String offsetString = (String) req.get('offset');
            Integer searchLimit = String.isNotBlank((String) req.get('searchLimit')) ?
                Math.min(
                    Integer.valueOf(StringHelper.asInteger((String) req.get('searchLimit'))),
                    2000
                ) :
                2000;
            String subject = (String) req.get('subject');
            String contactName = (String) req.get('contactName');
            String caseNumber = (String) req.get(CaseHelper.CASE_NUMBER);
            String view = (String) req.get('view');
            String site = (String) req.get('site');
            String sortBy = (String.isNotBlank((String) req.get('sortBy')))
                ? ((String) req.get('sortBy')).toLowerCase()
                : 'createddate';
            String sortOrder = (String.isNotBlank((String) req.get('sortOrder')))
                ? ((String) req.get('sortOrder')).toLowerCase()
                : 'desc';
            String lang = req.containsKey(LANG_KEY) ? ((String) req.get(LANG_KEY)) : DEFAULT_LANG;
            String statusFilter = (String) req.get('statusFilter');

            Contact contact = CaseAPIUtil.getContact(uid, email, new String[]{ 'AccountId', 'Id', 'Name', 'Email' });

            Id userContactAccountId = contact.AccountId;
            Id userContactId = contact.Id;
            String portalName = CaseHelper.isBTBrand(contact) ? 'BT Support Portal' : 'Main Support Portal';
            Set<String> caseRecordTypes = CaseHelper.getSCRecordTypes(portalName);

            List<Object> bindings = new List<Object>{ userContactAccountId, caseRecordTypes };

            String countQuery = 'SELECT COUNT() FROM Case';
            String whereCondition = ' WHERE RecordType.Name IN :caseRecordTypes AND AccountId = :userContactAccountId AND IsVisibleInSelfService = true';

            if (String.isNotBlank(statusFilter) && STATUS_FILTER_TO_IS_CLOSED_CONDITION_MAP.containsKey(statusFilter)) {
                whereCondition += ' AND IsClosed = ' + STATUS_FILTER_TO_IS_CLOSED_CONDITION_MAP.get(statusFilter);
            }

            FieldAndValueToSearch fieldAndValueToSearch = getFieldAndValueToSearch(subject, contactName, caseNumber, site);

            if (fieldAndValueToSearch.hasValue()) {
                whereCondition += ' AND ' + fieldAndValueToSearch.field + ' LIKE ' + '\'' + fieldAndValueToSearch.value + '\'';
            }

            Boolean isAdmin = SCApiService.isContactSCAdmin(contact);

            if (CONTACT_VIEW.equals(view) && !isAdmin) {
                throw new HandledException(BAD_REQUEST_ONLY_VALID_FOR_ADMIN_USERS);
            }

            if (isAdmin) {
                Integer recordsCountByAccount = Database.countQuery(countQuery + whereCondition);
                if (recordsCountByAccount > 0) {
                    res.put(TOTAL_ACCOUNT_RECORDS, recordsCountByAccount);
                }
            }

            if (!isAdmin || (isAdmin && CONTACT_VIEW.equals(view))) {
                bindings.add(userContactId);
                whereCondition += ' AND ContactId = :userContactId';
            }

            QueryFactory qfactory = new CaseSelector()
                .selectCasesForAPI(fieldAndValueToSearch, bindings, STATUS_FILTER_TO_IS_CLOSED_CONDITION_MAP.get(statusFilter))
                .selectFields(CASES_PREVIEW_FIELDS)
                .setLimit(searchLimit)
                .setOffset(String.isBlank(offsetString) ? 0 : Integer.valueOf(offsetString))
                .addOrdering(SORT_OPTIONS_MAP.get(sortBy), SORT_ORDER_MAP.get(sortOrder), true);

            List<Case> cases = qfactory.executeQuery();

            List<CaseWrapper> sortedCaseWrapperList = new List<CaseWrapper>();

            Map<String, List<Case>> casesByRecordTypeName = new Map<String, List<Case>>();

            Set<Id> contactIds = new Set<Id>();
            for (Case cs : cases) {
                if (!casesByRecordTypeName.containsKey(cs.recordType.Name)) {
                    casesByRecordTypeName.put(cs.recordType.Name, new Case[]{});
                }
                casesByRecordTypeName.get(cs.recordType.Name).add(cs);
                contactIds.add(cs.ContactId);
            }

            // If user looks at "Account Cases" view then the list may contain cases with contacts
            // that current user has no access to, to solve the issue we need to do additional SOQL in NO SHARING environment.
            if (isAdmin && !CONTACT_VIEW.equals(view)) {
                Map<Id, Contact> contactMap = (new NoSharing()).retrieveContactsByIds(contactIds);
                for (Case caseRecord : cases) {
                    Contact contactRecord = contactMap.get(caseRecord.ContactId);
                    if (caseRecord.Contact.Name == null) { // If user doesn't have access to contact
                        caseRecord.Contact = contactRecord;
                    }
                }
            }

            Map<Id, CaseWrapper> caseWrapperById = new Map<Id, CaseWrapper>();

            for (String recordTypeName : casesByRecordTypeName.keySet()) {
                Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(
                    'Case',
                    recordTypeName,
                    lang,
                    'Status,Case_Severity__c',
                    false
                );
                for (Case caseItem : casesByRecordTypeName.get(recordTypeName)) {
                    caseWrapperById.put(caseItem.Id, new CaseWrapper(caseItem, translatedLabelByValue));
                }
            }

            for (Case aCase : cases) {
                sortedCaseWrapperList.add(caseWrapperById.get(aCase.Id));
            }

            Integer totalCases = Database.countQuery(countQuery + whereCondition);

            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
            res.put(CASES_LABEL, sortedCaseWrapperList);
            res.put(TOTAL_RECORDS, totalCases);

            if (qfactory.getOffset() + sortedCaseWrapperList.size() < totalCases) {
                Integer remainingCases = totalCases - (qfactory.getOffset() + sortedCaseWrapperList.size());
                Integer newSearchLimit = searchLimit < remainingCases ? searchLimit : remainingCases;
                newSearchLimit = newSearchLimit > 2000 ? 2000 : newSearchLimit;
                res.put(NEXT_PAGE_URL, buildNextUrl(qfactory, uid, email, subject, caseNumber, newSearchLimit, contactName, view));
            }
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }

    private static Boolean isAValidNumber(Object obj) {
        return obj != null && StringHelper.safeString(obj).trim().isNumeric();
    }

    private static void validateRequest(Map<String, Object> req) {
        String offset = StringHelper.safeString(req.get('offset'));
        String searchLimit = StringHelper.safeString(req.get('searchLimit'));
        String caseNumber = StringHelper.safeString(req.get(CaseHelper.CASE_NUMBER));
        String view = StringHelper.safeString(req.get('view')).toLowerCase();
        String sortBy = StringHelper.safeString(req.get('sortBy'));
        String sortOrder = StringHelper.safeString(req.get('sortOrder')).toLowerCase();

        String lang = req.containsKey(LANG_KEY) ? ((String) req.get(LANG_KEY)) : DEFAULT_LANG;

        if (String.isNotBlank(view) && !CONTACT_VIEW.equals(view) && !ACCOUNT_VIEW.equals(view)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid view parameter value. Valid values: "contact" and "account"');
        }

        if (String.isNotBlank(sortBy) && !SORT_OPTIONS_MAP.containsKey(sortBy.toLowerCase())) {
            throw new HandledException(BAD_REQUEST_INVALID_SORTBY_VALUE);
        }

        if (String.isNotBlank(sortOrder) && !SORT_ORDER_MAP.containsKey(sortOrder)) {
            throw new HandledException(BAD_REQUEST_INVALID_SORTORDER_VALUE);
        }

        if (String.isNotBlank(lang) && !CaseHelper.isValidLanguage(lang.toLowerCase())) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid lang parameter value.');
        }

        if (String.isNotBlank(offset) && (!isAValidNumber(offset) || Integer.valueOf(offset) < 0)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid offset parameter value.');
        }

        if (String.isNotBlank(caseNumber) && (!isAValidNumber(caseNumber) || Integer.valueOf(caseNumber) <= 0)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid caseNumber parameter value.');
        }

        if (String.isNotBlank(searchLimit) && (!isAValidNumber(searchLimit) || Integer.valueOf(searchLimit) <= 0)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid searchLimit parameter value.');
        }
    }

    private static FieldAndValueToSearch getFieldAndValueToSearch(String subject, String contactName, String caseNumber, String site) {

        String field = null;
        String value = null;
        if (String.isNotBlank(subject)) {
            field = 'Subject';
            value = '%' + String.escapeSingleQuotes(subject) + '%';
        } else if (String.isNotBlank(contactName)) {
            field = 'Contact.Name';
            value = '%' + String.escapeSingleQuotes(contactName) + '%';
        } else if (String.isNotBlank(caseNumber)) {
            field = 'CaseNumber';
            value = '%' + String.escapeSingleQuotes(caseNumber) + '%';
        } else if (String.isNotBlank(site)) {
            field = 'Site__c';
            value = '%' + String.escapeSingleQuotes(site) + '%';
        }
        return new FieldAndValueToSearch(field, value);
    }

    private static String buildNextUrl(
        QueryFactory qfactory,
        String uid,
        String email,
        String subject,
        String caseNumber,
        Integer searchLimit,
        String contactName,
        String view
    ) {
        String nextUrl;
        if (qfactory.getOffset() == null || qfactory.getOffset() == 0) {
            nextUrl = URL_SCAPI_V1_CASE + '?uid='+uid+'&email='+email+'&offset='+qfactory.getLimit();
        } else if (qfactory.getOffset() > 0) {
            Integer startPoint = qfactory.getOffset() + qfactory.getLimit();
            nextUrl = URL_SCAPI_V1_CASE + '?uid='+uid+'&email='+email+'&offset='+startPoint;
        }

        if (String.isNotBlank(subject)) {
            nextUrl = nextUrl +'&subject='+subject;
        }

        if (String.isNotBlank(caseNumber)) {
            nextUrl = nextUrl +'&caseNumber='+caseNumber;
        }

        nextUrl = nextUrl +'&searchLimit='+searchLimit;

        if (String.isNotBlank(contactName)) {
            nextUrl = nextUrl +'&contactName='+contactName;
        }

        if (String.isNotBlank(view)) {
            nextUrl = nextUrl +'&view='+view;
        }
        return nextUrl;
    }

    private class CaseWrapper {

        String caseNumber;
        String caseSeverity;
        String contactId;
        Datetime createdDate;
        String id;
        String status;
        String subject;
        Id recordTypeId;
        ContactWrapper contact;
        String site;

        private CaseWrapper(Case caseItem, Map<String, String> translatedLabelByValue) {
            this.caseNumber = caseItem.CaseNumber;
            this.caseSeverity = CaseHelper.getTranslatedLabel(translatedLabelByValue, caseItem.Case_Severity__c);
            this.contactId = caseItem.ContactId;
            this.createdDate = caseItem.CreatedDate;
            this.id = caseItem.Id;
            this.status = CaseHelper.getTranslatedLabel(translatedLabelByValue, caseItem.Status);
            this.subject = caseItem.Subject;
            this.recordTypeId = caseItem.RecordTypeId;
            this.contact = String.isNotBlank(caseItem.ContactId) ?
                new ContactWrapper(JSON.serialize(caseItem.Contact)) :
                null;
            this.site = caseItem.Site__c;
        }
    }

    private class ContactWrapper {
        String email;
        String name;

        private ContactWrapper(String contactString) {
            Map<String,Object> contactMap = (Map<String,Object>) JSON.deserializeUntyped(contactString);
            this.email = (String) contactMap.get('Email');
            this.name = (STring) contactMap.get('Name');
        }
    }

    public class FieldAndValueToSearch {
        public String field;
        public String value;

        public FieldAndValueToSearch(String field, String value) {
            this.field = field;
            this.value= value;
        }

        public Boolean hasValue() {
            return this.value != null && this.field != null;
        }
    }

    private without sharing class NoSharing {

        public Map<Id, Contact> retrieveContactsByIds(Set<Id> contactIds) {
            return new Map<Id, Contact>(
                (List<Contact>) new ContactSelector()
                    .selectContactsByIds(new List<Object>{contactIds})
                    .executeQuery()
            );
        }
    }
}