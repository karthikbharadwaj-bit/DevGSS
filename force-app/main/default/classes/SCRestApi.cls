@RestResource(UrlMapping='/SCApi/v1/userInfo/*')
global class SCRestApi {
    public static String UID = 'uid';
    public static String EMAIL = 'email';
    public static String CASE_LIMIT = 'caseLimit';
    public static String SUCCESS_MESSAGE = 'user info provided.';
    public static final String LANG_KEY = 'lang';
    public static final String DEFAULT_LANG = 'en_US';
    public static final String ACCOUNT_STATUS_CANCELED = 'Canceled'; //PBC-31596
    public static final String PROSERV_PROJECT_STATUS_IN_PROGRESS = 'In Progress'; //PBC-31596

    public static Integer DEFAULT_CASE_LIMIT = 5;
    public static Integer MAX_CASE_LIMIT = 5;

    @HttpGet
    global static void getUserInfo() {
        RestRequest req = RestContext.request;
        RestResponse res = CaseAPIUtil.initRestResponse(RestContext.response);
        // res.addHeader('Content-Type', 'application/json');
        try {
            Map<String,Object> response = populateAEMWrapper(req);

            res.responseBody = Blob.valueOf(JSON.serialize(response));
            CaseAPIUtil.validateMessageField(res, response, SUCCESS_MESSAGE);
        } catch(Exception ex) {
            CaseAPIUtil.constructErrorResponse(ex,RestContext.request, res);
        }
    }

    private static Map<String,Object> populateAEMWrapper(RestRequest req) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            validateGetRequest(req.params);

            String uid = req.params.get(UID);
            String email = req.params.get(EMAIL);
            String lang = req.params.containsKey(LANG_KEY) ? req.params.get(LANG_KEY) : DEFAULT_LANG;

            String[] fields = new String[]{
                'Account.Recordtype.Name','Account.Next_Renewal_Date__c','Account.Sales_Agreement_End_Date__c','Account.Invoice_Terms__c',
                'Account.Payment_Plan__c','Account_Tier__c','Account_Number_of_DLs__c','Account.Total_Account_DL_s__c',
                'Account.Current_Owner__r.Name','Account.Current_Owner__r.Email','Account.Current_Owner__r.Phone','AccountId','Id','Name',
                'Account.Segment_Name__r.Name','Job_Role__c','Email','Phone','Owner.Name','Account.BillingAddress','Account.CSM_Name__c',
                'Account.CSM_Email__c','Account.CSM__r.SmallPhotoUrl','Account.CSM__r.FullPhotoUrl','Account.CSM__r.Phone', 'Account.CSM__r.FirstName',
                'Account.CSM__r.LastName','Account.CSM__r.Email','Account.RC_Account_Status__c','Account_Brand__c','Package_Name__c','Implementation_Status__c',
                'Account.CreatedDate','Account.inContact_Cluster__c','Account.enterprise_Support_Start_Date__c','Account.enterprise_Support_End_Date__c',
                'Account.technical_Account_Manager__c','Account.UC_ES_Service_Level__c','ES_Designated_Contact__c','Account.RC_Brand__c',
                'Account.Enterprise_Support_Start_Date__c', 'Account.Total_MRR__c'
            };

            Contact contact = CaseAPIUtil.getContact(uid, email, fields);

            Integer caseLimit = req.params.containsKey(CASE_LIMIT) ?
                Integer.valueOf(req.params.get(CASE_LIMIT).trim()) :
                DEFAULT_CASE_LIMIT;

            Boolean isAdmin = SCApiService.isContactSCAdmin(contact);
            List<Case> allUserAccountCases = SCAPICaseService.getContactAccountCases(contact, caseLimit, true);
            List<Case> allCurrentUserCases = isAdmin ?
                allUserAccountCases :
                SCAPICaseService.getContactAccountCases(contact, caseLimit, false);

            List<Case> casesToShow = isAdmin ?
                allUserAccountCases :
                allCurrentUserCases;

            List<ProServ_Project__c> proServProjects = getInProgressProServProjects(contact.AccountId); //PBC-31596

            AEMWrappers.AEMWrapper aem = new AEMWrappers.AEMWrapper();
            aem.isAdmin = isAdmin;
            aem.totalUserCases = allCurrentUserCases.size();
            aem.totalAccCases = allUserAccountCases.size();
            aem.contactInfo = new AEMWrappers.AEMContactInfo(
                contact,
                lang,
                proServProjects //PBC-31596
            );
            aem.billing = isAdmin ? new AEMWrappers.AEMBilling(contact, lang) : null;
            aem.populateCaseDetails(casesToShow, lang);

            res = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(aem, true));

            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }

    //PBC-31596
    private static List<ProServ_Project__c> getInProgressProServProjects(Id accountId) {
        if (accountId == null) {
            return new List<ProServ_Project__c>();
        }

        return [
            SELECT Id,
                   Project_Name__c,
                   Project_Status__c,
                   ProServProjectManager__c,
                   ProServProjectManager__r.Name,
                   ProServProjectManager__r.Email,
                   ProServProjectManager__r.Phone
            FROM ProServ_Project__c
            WHERE Account__c = :accountId
            AND Account__r.RC_Account_Status__c != :ACCOUNT_STATUS_CANCELED
            AND Project_Status__c = :PROSERV_PROJECT_STATUS_IN_PROGRESS
        ];
    }

    private static void validateGetRequest(Map<String, String> req) {
        String lang = StringHelper.safeString(req.get(LANG_KEY)).toLowerCase();
        String caseLimit = req.containsKey(CASE_LIMIT) ?
            StringHelper.safeString(req.get(CASE_LIMIT)).trim() :
            null ;

        if (String.isNotBlank(lang) && !CaseHelper.isValidLanguage(lang)) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid lang parameter value.');
        }

        if (caseLimit != null && !caseLimit.isNumeric()) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid caseLimit parameter.');
        }
    }
}