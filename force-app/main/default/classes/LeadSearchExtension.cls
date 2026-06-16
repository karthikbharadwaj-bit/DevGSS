/*************************************************
LeadSearchExtension class
Along with LeadSearchQualification.page allows users to search for existing leads and opp's based on contact information
Shows results broken up by main defining factor of protected or not protected.
If all fields are available the search will use last name, company, email and phone to match existing records
/************************************************/
public class LeadSearchExtension  {

    public String dnis {get; set;}
    public String errorRelatedItemOps {get; set;}
    String inContactId;
    String skillName;
    String phoneNumber;
    String formattedNumber;
    String plusOnePhoneFormat;
    String campaignName;
    String invocaTransactionId;
    public String leadSysSourceUrl {get; private set;}
    public String campaignProduct {get; set;}
    String campaignDescription;
    Campaign campObj;
    Boolean callCounted = false;
    public string companyName{get; set;}
    public Integer numOfRecordsShown{get; set;}
    String searchedfirst;
    String searchedlast;
    String searchedcomp;
    @TestVisible String searchedem;
    String searchedph;
    String searchedLeadSource = null;

    String strNoteDescription {get;set;}

    /*****************Pagination members*****************/
    public Integer procRowCount{get; set;}
    public Integer unprocRowCount{get; set;}
    public Integer rowsToSkip{get; set;}
    final Integer LIMITED_ROWS = 50;
    public String protectedLeadPaginationQuery{get; set;}
    public String unprotectedLeadPaginationQuery{get; set;}


    public Boolean showButtons{get; set;}
    public Boolean disabledPLBeginning{get; set;}
    public Boolean disabledPLNext{get; set;}
    public Boolean disabledPLEnd{get; set;}
    public Boolean disabledPLPrevious{get; set;}

    public Boolean disabledULBeginning{get; set;}
    public Boolean disabledULNext{get; set;}
    public Boolean disabledULEnd{get; set;}
    public Boolean disabledULPrevious{get; set;}

    public List<ListResult> opportunityList = new List<ListResult>();
    public List<ListResult> opportunityNoCOList = new List<ListResult>();
    public List<ListResult> parterOpportunityList = new List<ListResult>();
    public List<ListResult> unprotectedOpportunityList = new List<ListResult>();
    public List<ListResult> leadList = new List<ListResult>();
    public List<ListResult> protectedLeadList = new List<ListResult>();
    public List<ListResult> unprotectedLeadList = new List<ListResult>();
    public List<ListResult> matchedContactList = new List<ListResult>();

    transient public List<Lead> paginationProtectedLeadList = new List<Lead>();
    transient public List<Lead> paginationUnprotectedLeadList = new List<Lead>();

    public Integer procLeadTotalPages{get; set;}
    public Integer unProcLeadTotalPages{get; set;}

    public Integer procLeadPaginationNumber{get; set;}
    public Integer unProcLeadPaginationNumber{get; set;}

    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Lead.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static final String RT_NAME_PARTNER_LEAD = 'Partner Leads';
    public static final String RT_NAME_SALES_LEAD = 'Sales Leads';

    public static final Id RT_ID_PARTNER_LEAD = RT_INFO_BY_NAME.get(RT_NAME_PARTNER_LEAD).getRecordTypeId();
    public static final Id RT_ID_SALES_LEAD = RT_INFO_BY_NAME.get(RT_NAME_SALES_LEAD).getRecordTypeId();
    public static String USERLOCALE = UserInfo.getTimeZone().toString();
    public static String USDATEFORMAT = 'MM/dd/y';

    /*****************************END PAGINATION MEMBERS***************************/

    Transient Map<String,Model_Usage_featureDependencyClass> Model_Usage_featureDependencyClassMap{get;set;} //As/simplion/Q2
    Transient list<Lead> leadListTemp = new list<Lead>();
    Transient set<Id> oppListIdSet = new set<Id>();
    Transient set<Id> oppNoCOListIdSet = new set<Id>();
    Transient set<Id> oppParterListIdSet = new set<Id>();
    Transient set<Id> oppUnProtectedListIdSet = new set<Id>();
    map<Id,List<CampaignMember>> leadCampaignMemMap = new map<Id,List<CampaignMember>>();
    Transient map<Id,List<CampaignMember>> contactCampaignMap = new map<Id,List<CampaignMember>>();
    Transient set<Id> contactIdSet = new set<Id>();
    Transient set<Id> leadownerIdSet = new set<Id>();
    Transient Set<Id> oppAndAccountOwnerId = new Set<Id>();
    public string strcustomlabel = system.label.Sales_Generated_Source;
    public String strSalesgenerated{get;set;}
    String strDnis = ApexPages.currentPage().getParameters().get('dnis');

    public Lead_Qualification__c leadQualificationObj {get;set;}
    Boolean searched = false;
    Boolean emptyfield = false;
    Boolean emptySearch = false;
    Boolean emailNotFormated = false;
    Boolean searchFirst = false;
    Boolean fieldsChanged = false;
    Boolean phoneNotFormated = false;

    public Boolean searchNeeded {get;set;}
    public Boolean searchButtonDisabled {get;set;}
    public Boolean createNewLeadButtonDisabled {get;set;}

    Boolean partnerRep = false;
    //SolveThenSell
    Boolean agentEmailChk = false;
    Boolean dnisChk = false;
    public Lead newLead{get;set;}

    public String isConsole {get;set;}

    // LeadSpace API Enrichment Variable
    static String apiKey = '046170802f344a0ccd98621d947cb9cfad04a531e1b6fc3f7de6c707bbd7ebb2';
    static String endPointUrl = 'https://api.leadspace.com/v1/enrichments/';
    static String API_Method = 'POST';
    static Integer reqTimeMs = 120000;
    public decimal responseTime {get;set;}
    public LeadSpaceWrapperCls responseData {get;set;}
    public List<Account_Hierarchy__c> accountHierarchyList;
    public String strEnrich {get;set;}
    public boolean isEnriched {get;set;}
    public boolean isEmployeeRequired{get;set;}
    public string enrichedEmail;
    public string domain;
    public boolean isFreeDomain;
    public string enrichedName;
    public string enrichedCompany;
    public set<string> industrySet = new set<string>();
    public string optionValue{get;set;}
    public String numOfEmployees{get;set;}

    /****************************Bills Project variable declaration Starts***************************/
    public String selBusinessDriver { get; set; } // Bills Project
    public map<string,set<string>> driverReasonMap = new map<string,set<string>>();// Bills Project
    Set<string> driverSet = new Set<String>();// Bills Project
    Public List<string> leftselected{get;set;}// Bills Project
    Public List<string> rightselected{get;set;}// Bills Project
    public Set<string> leftvalues = new Set<string>();// Bills Project
    public Set<string> rightvalues = new Set<string>();// Bills Project
    public String lineBreakText {get;set;}// Bills Project
    /****************************Bills Project variable declaration Ends***************************/

    public static final string LEAD_RECORD_TYPE_SALES_LEAD = 'Sales Leads';
    public static final string LEAD_RECORD_TYPE_LEADBB = 'LeadBB';
    public static final String SEPARATOR {get{
            return ';;,;;;';
    } private set;}//a complex separator to avoid issues on splitting

    public static final String USER_ROLE_NAME_VISTA_PRINT_US = 'Vista Print US';
    public Id PROFILE_ID_SALES_MANAGER_INSIDESALES { get; private set; }
    public Id PROIFLE_ID_SALES_AGENT_SDR_W_INSIDESALES { get; private set; }
    public Id PROFILE_ID_SALES_AGENT_SDR_W_INSIDESALES_EU_RESTRICTED { get; private set; } //Added for EU Privacy Phase 3 Sales Profiles Changes
    public Id CurrentUserProfileId { get; private set; }

    public Account rcAccount {get; set;}
    public String rcUserId {get; set;}
    //
    @testVisible private CompanyProcessorSvc leadCompanyProcessorSvcInstance = new LeadCompanyProcessorSvc();

    @testVisible transient protected InvocaSelector invocaSelectorInstance;
    public static INVOCA_FOR_SF__Invoca_Call_Log__c invocaCallRecord;
    /*
    Get DNIS and ANI parameters from URL to find matching campaign and do initial search with ANI.
    */

    public String userId { get; private set; }

    public LeadSearchExtension(ApexPages.StandardController controller) {
        fillProfileVariables();

        procRowCount =  0;
        unprocRowCount = 0;
        showButtons = false;
        disabledPLBeginning = false;
        disabledPLNext = false;
        disabledPLPrevious = false;
        disabledPLEnd = false;

        disabledULBeginning = false;
        disabledULNext = false;
        disabledULPrevious = false;
        disabledULEnd = false;

        procLeadTotalPages = 1;
        unProcLeadTotalPages = 1;

        resetPaginationNumber();

        rowsToSkip = 0;

        /* disable buttons until page loaded and initial processes completed */
        searchButtonDisabled = true;
        createNewLeadButtonDisabled = true;

        /*
        There is special consideration for VistaPrint reps.
        We want to make sure if there is a protected record from another vistaprint rept that user sees that in seperate section on page.
        */
        strSalesgenerated = '';
        isEnriched = false;
        optionValue = 'YES';
        isFreeDomain = false;

        isEmployeeRequired = false;
        //---------------------------List holding all selected picklist values in database-----------------------
        getBusinessAgilitySelectedResons = new List<String>();
        getBusinessresponsivenessSelectedResons  = new List<String>();
        getBusinessVendorSelectedResons   =  new List<String>();
        //---------------------------List Holding all current system info values in database---------------------
        getSelectedCurrentSystemInfo = new List<String>();
        //---------------------------Initialization and setting values of wrapper class BussinessDriverReasonClass--------------

        //---------------------------Intialization of the list properties for new leadQualification Information section starts----------------
        getSelectedCallFlowModelValues = new List<String>();
        getSelectedFeaturesRequestdByCustomerValues = new List<String>();
        getSelectedUsagesLevelValues = new List<String>();
        //---------------------------Intialization of the list properties for new leadQualification Information section Ends--------------------

        User currentUser = [
            SELECT UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()];

        if (currentUser.UserRole.Name == USER_ROLE_NAME_VISTA_PRINT_US) {
            partnerRep = true;
        }

        
        fillUserId();

        dnis = ApexPages.currentPage().getParameters().get('dnis');
        phoneNumber = ApexPages.currentPage().getParameters().get('ani');

        inContactId = ApexPages.currentPage().getParameters().get('cid');
        skillName = ApexPages.currentPage().getParameters().get('skill');

        invocaTransactionId = ApexPages.currentPage().getParameters().get('InvocaID');
        newLead = new Lead();

        newLead.SmartSearchURL__c = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + Apexpages.currentPage().getUrl();

        industrySet = getPickValues(newLead,'Industry');

        newLead.inContact_Contact_ID__c = (String.isBlank(inContactId) ? '' : inContactId);
        newLead.inContact_Skill__c = (String.isBlank(skillName) ? '' : skillName);

        String strRange = '';
        strRange = ApexPages.currentPage().getParameters().get('range');
        Set<String> range = LeadTriggerHelperExt.getEmployeeRange();
        Boolean isValidValue = false;
        if(!String.isBlank(strRange)) {
            for(String rangeValue : range) {
                if(range.contains(strRange.trim())){
                    isValidValue = true;
                    break;
                }
            }
        }

        /****************Effectve Number of employee change****************/
        if(isValidValue) {
            newLead.Employees_Override__c = strRange.trim();
        }
        /****************************************************************/

        /******As Per Additional Source Field Case*******/
        leadSysSourceUrl = (String.isNotBlank(ApexPages.currentPage().getParameters().get('source')) ?
                                ApexPages.currentPage().getParameters().get('source')
                                : '');

        newLead.Lead_System_Source__c = (!String.isBlank(leadSysSourceUrl) ?
                                            leadSysSourceUrl.trim() :
                                            '');
        /*******End*************************/

        leadQualificationObj = new Lead_Qualification__c();

        /**********************************New Lead Distribution Code*****************************/
        newLead.Five9_DNIS__c = dnis;

        if ( (!String.isBlank(dnis)) || (!String.isBlank(inContactId)) || (!String.isBlank(skillName)) ){
            newLead.LeadSource = 'Inbound Call';
        }

        dnisChk = true;
        campaignName = 'Campaign not found.';
        List<Campaign> campaignList = new List<Campaign>();
        // https://www.lucidchart.com/invitations/accept/16e2c7e8-3072-4855-961d-abd010404246
        if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
            if (String.isNotBlank(invocaTransactionId)) {
                invocaSelectorInstance = new InvocaSelector();
                List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                    .selectInvocaRecordById(invocaTransactionId)
                    .executeQuery();
                invocaCallRecord  = !invocaRecordsList.isEmpty()
                    ? invocaRecordsList[0]
                    : null;
                if (invocaCallRecord != null) {
                    newLead = (Lead) assignInvocaValues(newLead, invocaCallRecord, 'assignInvocaValues');
                    populateRCAccount(newLead);
                    if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                        campObj = getCampaignFromInvocaCall(invocaCallRecord);
                        if (String.isNotBlank(campObj.Id)) {
                            newLead.Most_Recent_Campaign__c = campObj.Id;
                        } else {
                            campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                            newLead.Most_Recent_Campaign__c = campObj.Id;
                        }
                    } else {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                        newLead.Most_Recent_Campaign__c = campObj.Id;
                    }
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
                    newLead.Most_Recent_Campaign__c = campObj.Id;
                }
            } else {
                campObj = setCampaignByDNISOrderedByCreatedDate();
                newLead.Most_Recent_Campaign__c = campObj.Id;
            }
        } else if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
            Map<String, String> upperCaseParamsMap = new Map<String, String>();
            for (String param : ApexPages.currentPage().getParameters().keyset()) {
                String key = param.toUpperCase();
                String value = ApexPages.currentPage().getParameters().get(param);
                upperCaseParamsMap.put(key, value);
            }
            newLead.FirstName = upperCaseParamsMap.get('FNAME') != null ? upperCaseParamsMap.get('FNAME') : newLead.FirstName;
            newLead.LastName = upperCaseParamsMap.get('LNAME') != null ? upperCaseParamsMap.get('LNAME') : newLead.LastName;
            newLead.Email = upperCaseParamsMap.get('EMAIL') != null ? upperCaseParamsMap.get('EMAIL') : newLead.Email;
            newLead.Phone = upperCaseParamsMap.get('PHONE') != null ? upperCaseParamsMap.get('PHONE') : newLead.Phone;
            newLead.BMID__c = upperCaseParamsMap.get('BMID') != null ? upperCaseParamsMap.get('BMID') : newLead.BMID__c;
            newLead.LeadSource = 'Online Chat';
            newLead.Lead_Entry_Source__c = 'RingBot Office';
            newLead.RC_Visitor_ID__c = upperCaseParamsMap.get('RCVID') != null ? upperCaseParamsMap.get('RCVID') : newLead.RC_Visitor_ID__c;
            newLead.Adobe_Target_Id__c = upperCaseParamsMap.get('ATID') != null ? upperCaseParamsMap.get('ATID') : newLead.Adobe_Target_Id__c;
            newLead.Adobe_Target_Id_History__c = upperCaseParamsMap.get('ATID_HISTORY') != null ? upperCaseParamsMap.get('ATID_HISTORY') : newLead.Adobe_Target_Id_History__c;
            newLead.AID__c = upperCaseParamsMap.get('AID') != null ? upperCaseParamsMap.get('AID') : newLead.AID__c;
            newLead.PID__c = upperCaseParamsMap.get('PID') != null ? upperCaseParamsMap.get('PID') : newLead.PID__c;
            newLead.KCID__c = upperCaseParamsMap.get('KCID') != null ? upperCaseParamsMap.get('KCID') : newLead.KCID__c;
            newLead.GCLID__c = upperCaseParamsMap.get('GCLID') != null ? upperCaseParamsMap.get('GCLID') : newLead.GCLID__c;
            newLead.ECID__c = upperCaseParamsMap.get('ECID') != null ? upperCaseParamsMap.get('ECID') : newLead.ECID__c;
            if (String.isNotBlank(newLead.BMID__c)) {
                List<Campaign> campaigns = (List<Campaign>) new CampaignSelector()
                    .selectCampaignByBMID(new List<Object>{newLead.BMID__c})
                    .setLimit(1)
                    .executeQuery();
                if (!campaigns.isEmpty()) {
                    campObj = campaigns[0];
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                }
            } else {
                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNSALESGENERATED);
            }
        } else if(ApexPages.currentPage().getParameters().get('dnis') != null){
            if(!String.isBlank(dnis)) {
                campaignList = [SELECT Id,Name,DNIS__c,BMID__c,AID__c,PID__c,Description,Non_Attributable__c,Intended_Product__c
                                FROM Campaign
                                WHERE (DNIS__c != NULL AND DNIS__c=:dnis)
                                ORDER BY LastModifiedDate DESC
                                LIMIT 1];
                if(campaignList!=null && campaignList.size() > 0){
                    campObj = campaignList[0];
                }else{
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                }
            }else{
                campObj = fetchCampaignByName('Inbound Call/Chat');
            }
        } else {
            campObj = fetchCampaignByName(LeadHelper.CAMPAIGNSALESGENERATED);
        }

        /**********************End of New Lead Distribution code***************************************/
        if (invocaCallRecord != null && String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c)) {
            phoneNumber = invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c;
        }
        searchNeeded = false;
        if( (!leadSysSourceUrl.equalsIgnoreCase('drift')) && (phoneNumber!=null && phoneNumber!='')){
            newLead.Phone = phoneNumber.trim();
            newLead.FirstName='';
            newLead.LastName='';
            newLead.Company ='';
            newLead.Email='';
            searchNeeded = true;
        } else if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
            newLead.Phone = String.isBlank(newLead.Phone) ? '' : newLead.Phone;
            newLead.FirstName = String.isBlank(newLead.FirstName) ? '' : newLead.FirstName;
            newLead.Company = '';
            newLead.LastName = String.isBlank(newLead.LastName) ? '' : newLead.LastName;
            newLead.Email = String.isBlank(newLead.Email) ? '' : newLead.Email;
            searchNeeded = String.isNotBlank(newLead.Phone) || 
                (String.isNotBlank(newLead.FirstName) && String.isNotBlank(newLead.LastName)) || 
                String.isNotBlank(newLead.Email);
        }
        //Set strNoteDescription to blank
        strNoteDescription= '';
        
        if(campObj != null){
            newLead.Primary_Campaign__c = campObj.Id;
            if (!campObj.Non_Attributable__c
                && (!leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) && (!leadSysSourceUrl.equalsIgnoreCase('drift'))
                && (String.isNotBlank(dnis) || (String.isNotBlank(inContactId) || String.isNotBlank(skillName))) ){

                newLead.AID__c = (String.isNotBlank(campObj.AID__c) ? campObj.AID__c : newLead.AID__c);
                newLead.BMID__c = (String.isNotBlank(campObj.BMID__c) ? campObj.BMID__c : newLead.BMID__c);
                newLead.PID__c = (String.isNotBlank(campObj.PID__c) ? campObj.PID__c : newLead.PID__c);
            }
            campaignName = campObj.Name;
            campaignProduct = campObj.Intended_Product__c;
            campaignDescription = campObj.Description;
        }

        /********************************** Bills Project Constructor code Starts **************************/
        list<SelectOption> busReasonList = getbusinessDriverList();
                for(SelectOption sp : busReasonList){
                    driverSet.add(sp.getLabel());
                }
                for(String setItem : driverSet){
                    if(setItem == 'Business growth/Change'){
                        set<string> se = new set<string>();
                        List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Business_Change_Reasons__c');
                        for(Schema.Picklistentry reasonEntry : pickListValues){
                            se.add(reasonEntry.getLabel());
                        }
                        driverReasonMap.put(setItem,se);
                    } else if(setItem == 'Improved customer responsiveness'){
                        set<string> se = new set<string>();
                        List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Customer_Responsiveness_Reasons__c');
                        for(Schema.Picklistentry reasonEntry : pickListValues){
                            se.add(reasonEntry.getLabel());
                        }
                        driverReasonMap.put(setItem,se);
                    } else if(setItem == 'Dissatisfied with current vendor'){
                         set<string> se = new set<string>();
                        List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Dissatisfaction_with_Current__c');
                        for(Schema.Picklistentry reasonEntry : pickListValues){
                            se.add(reasonEntry.getLabel());
                        }
                        driverReasonMap.put(setItem,se);
                    } else {

                    }
                }
                selBusinessDriver = leadQualificationObj.X50_249_Business_Drivers__c;
                if(leadQualificationObj.Reasons__c != null){
                    rightvalues.addAll(string.valueof(leadQualificationObj.Reasons__c).split(';'));
                }
                leftselected = new List<String>();
                rightselected = new List<String>();
                set<string> tempSet = new set<string>();
                if(driverReasonMap.containsKey(selBusinessDriver)){
                    tempSet = driverReasonMap.get(selBusinessDriver);
                }
                for(string s : rightvalues){
                    if(tempSet.contains(s)){
                        tempSet.remove(s);
                    }
                }
                for(string ss : tempSet){
                    if(ss != ''){
                        leftvalues.addAll(tempSet);
                    }
                }
        /********************************** Bills Project Constructor code Ends **************************/
    }

    private void fillProfileVariables() {
        this.CurrentUserProfileId = UserInfo.getProfileId();

        Map<Id, Profile> salesProfiles = new Map<Id, Profile>([
                SELECT Name
                FROM Profile
                WHERE Name IN (:ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES,
                :ProfileHelper.PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES
                              )]);

        for (Profile entry : salesProfiles.values()) {
            if (entry.Name == ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES) {
                PROFILE_ID_SALES_MANAGER_INSIDESALES = entry.Id;
            }
            else if(entry.Name == ProfileHelper.PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES)  {
                PROIFLE_ID_SALES_AGENT_SDR_W_INSIDESALES = entry.Id;
            }
        }
    }

    @TestVisible
    private sObject assignInvocaValues(sObject sObj, INVOCA_FOR_SF__Invoca_Call_Log__c invocaCall, String process) {
        if (invocaCall.Id != null) {
            FieldMappingEngine assignInvoca = new FieldMappingEngine(process, invocaCall, sObj);
            assignInvoca.processFieldsMappings();
            String objName = sObj.getSObjectType().getDescribe().getName();
            if (
                'Lead'.Equals(objName) &&
                String.isNotBlank(sObj.Id) &&
                String.isBlank(invocaCall.INVOCA_FOR_SF__Lead__c)
            ) {
                invocaCall.INVOCA_FOR_SF__Lead__c = sObj.Id;
                Lead sObjLead = (Lead) sObj;
                if (rcAccount != null) {
                    invocaCall.INVOCA_FOR_SF__Account__c = rcAccount.Id;
                } else if (String.isNotBlank(sObjLead.ZI_CDP_Account_Id__c)) {
                    invocaCall.INVOCA_FOR_SF__Account__c = sObjLead.ZI_CDP_Account_Id__c;
                }
                update invocaCall;
            } else if (
                'Contact'.Equals(objName) &&
                String.isNotBlank(sObj.Id) &&
                String.isBlank(invocaCall.INVOCA_FOR_SF__Contact__c)
            ) {
                invocaCall.INVOCA_FOR_SF__Contact__c = sObj.Id;
                if (rcAccount != null) {
                    invocaCall.INVOCA_FOR_SF__Account__c = rcAccount.Id;
                }
                update invocaCall;
            }
        }

        return sObj;
    }

    public void loadMatchedContactList() {
        if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
            List<String> distinctPhoneFormats;
            if (String.isBlank(newLead.Phone)) {
                distinctPhoneFormats = new List<String>();
            } else {
                distinctPhoneFormats = String.isBlank(formattedNumber) ? new List<String>{newLead.Phone,plusOnePhoneFormat} 
                    : new List<String>{formattedNumber,newLead.Phone,plusOnePhoneFormat};
            }
            List<String> emailList = String.isBlank(newLead.Email) ? new List<String>() : new List<String>{newLead.Email};
            for (Contact cont : (List<Contact>) new ContactSelector()
                .selectContactsMatchedBySearch(new List<Object>{emailList,distinctPhoneFormats})
                .executeQuery()) {
                matchedContactList.add(new ListResult(cont.Name, cont.Email, cont.Phone, null, cont.Contact_Status__c, cont.CreatedDate,
                    cont.LastModifiedDate, null, cont.Id, null, null, null, null, null, String.isBlank(cont.AccountId) ? null : cont.Account.Name, 
                    null, null, null, String.isBlank(cont.AccountId) ? null : cont.Account.RecordType.Name));
            }
        } else if (rcAccount != null && String.isNotBlank(rcAccount.RC_Account_Status__c)
            && (rcAccount.RC_Account_Status__c.EqualsIgnoreCase('Paid') || rcAccount.RC_Account_Status__c.containsIgnoreCase('trial'))
        ) {
            for (Contact cont : (List<Contact>) new ContactSelector()
                .selectContactsByAccountIdAndEmailOrPhone(new object[]{rcAccount.Id, newLead.Email, newLead.Phone})
                .selectFields(new List<String>{
                    'Name',
                    'Email',
                    'Phone',
                    'Contact_Status__c',
                    'CreatedDate',
                    'LastModifiedDate'
                })
                .executeQuery()
            ) {
                matchedContactList.add(new ListResult(cont.Name, cont.Email, cont.Phone, null, cont.Contact_Status__c, cont.CreatedDate,
                    cont.LastModifiedDate, null, cont.Id, null, null, null, null, null, rcAccount.Name, null, null, null, rcAccount.RecordType.Name
                ));
            }
        }
    }

    public void populateRCAccount(Lead ld) {
        if (ld != null && String.isNotBlank(ld.User_Id__c)) {
            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByUserIds(new Object[]{new String[]{ld.User_Id__c}})
                .selectFields(new List<Schema.SObjectField>{
                    Account.Name,
                    Account.RC_User_Id__c,
                    Account.CreatedDate,
                    Account.RC_Account_Status__c,
                    //Ultimate Parent Account Id Population on lead
                    Account.Ultimate_Parent_Account_ID__c
                })
                .selectField('Recordtype.Name')
                .setLimit(1)
                .executeQuery();

            if (!accounts.isEmpty()) {
                rcAccount = accounts[0];
                rcUserId = accounts[0].RC_User_Id__c;
                ld.ZI_CDP_Account_Id__c = rcAccount.Id;
                //Ultimate Parent Account Id Population on lead
                ld.Ultimate_Parent_Account_ID__c = rcAccount.Ultimate_Parent_Account_ID__c;
            } else {
                populateRCAccountFromURL(ld);
            }
        } else {
            populateRCAccountFromURL(ld);
        }
    }

    public void populateRCAccountFromURL(Lead ld) {
        String strUserId = ApexPages.currentPage().getParameters().get('UserID');
        if (ld != null && String.isNotBlank(strUserId)) {
            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByUserIds(new Object[]{new String[]{strUserId}})
                .selectFields(new List<Schema.SObjectField>{
                    Account.Name,
                    Account.RC_User_Id__c,
                    Account.CreatedDate,
                    Account.RC_Account_Status__c,
                    Account.Ultimate_Parent_Account_ID__c
                })
                .selectField('Recordtype.Name')
                .setLimit(1)
                .executeQuery();

            if (!accounts.isEmpty()) {
                rcAccount = accounts[0];
                rcUserId = accounts[0].RC_User_Id__c;
                ld.ZI_CDP_Account_Id__c = rcAccount.Id;
                ld.Ultimate_Parent_Account_ID__c = rcAccount.Ultimate_Parent_Account_ID__c;
                ld.User_Id__c = accounts[0].RC_User_Id__c;
            } else {
                rcAccount = null;
                rcUserId = strUserId;
            }
        }
    }

    /**************Method to set Primary Campaign to the Inbound Chat Leads.****************/
    public String inboundChatParams{get;set;}

    //Parse string param to the fields map
    public Map<String,String> splitIntoFields(Map<String,String> result, List<String> paramsList){
        List<String> fields = new List<String>();
        for(String param:paramsList){
            if (String.isBlank(param)) {
                continue;
            }
            fields = param.split(':');
            result.put(fields.get(0), fields.get(1));
        }
        return result;
    }

    //Parse newly obtained values from action function to lead object
    public void parseFieldsToObject(sObject sObj, Map<String,String> fieldValues){
        for(String objField : fieldValues.KeySet()){
            sObj.put((objField.trim()).toLowerCase(), checkFieldLength(fieldValues.get(objField), 100));
        }
    }

    //Validate mandatory field length
    public String checkFieldLength(String text, Integer maxLength){
        if (text != null){
            text = text.substring(0, text.length() > maxLength ? maxLength : text.length());
        }
        return text;
    }

    //Validate if values is empty
    public Boolean isValueNotEmpty(String val){
        return (val != null && val.trim() != '' && val!='null');
    }

    /**************Method to Get Campaign By Passing Name as Parameter.****************/
    public Campaign fetchCampaignByName(String campName){
        List <Campaign> campaignList = [SELECT Id,Name,DNIS__c,Description,Non_Attributable__c,AID__c,BMID__c,PID__c,Intended_Product__c
                                        FROM Campaign
                                        WHERE Name=:campName
                                        ORDER BY LastModifiedDate DESC
                                        LIMIT 1];
        if(campaignList != null && campaignList.size() > 0){
            return campaignList[0];
        }else{
            return null;
        }
    }
    /*********************************************************************************/


    /********************************* Methods FOR BILLS PEOJECT Starts Here***************************/
    public List<selectOption> productAssistanceItems {get;set;}
    public List<selectOption> productAssistanceItemsLvl2 {get;set;}
    public PageReference selectclick(){
        rightselected.clear();
        for(String s : leftselected){
            leftvalues.remove(s);
            rightvalues.add(s);
        }
        return null;
    }
    public PageReference unselectclick(){
        leftselected.clear();
        for(String s : rightselected){
            rightvalues.remove(s);
            leftvalues.add(s);
        }
        return null;
    }
    public List<SelectOption> getSelectedValues(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        tempList.sort();
        for(String s : tempList) {
            options1.add(new SelectOption(s,s));
        }
        return options1;
    }
    public List<SelectOption> getunSelectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvalues);
        tempList.sort();
        for(string s : tempList) {
            options.add(new SelectOption(s,s));
        }
        return options;
    }
    public List<SelectOption> getbusinessDriverList() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new selectOption('','--None--'));
            Schema.DescribeFieldResult productAssistance = Lead_Qualification__c.X50_249_Business_Drivers__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList = productAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : productAssistanceList) {
                options.add(new selectOption(schObj.getValue(),schObj.getLabel()));
            }
            if(test.isRunningTest()){
                integer i = 2/0;
            }
        } catch(Exception ex) {}
        return options;
    }

    public void populateBMIDValueOnLead(){
        leadSysSourceUrl = (String.isNotBlank(ApexPages.currentPage().getParameters().get('source')) ?
                                ApexPages.currentPage().getParameters().get('source')
                                : '');
        String strCustomlabel = System.label.Sales_Generated_Source;
        List<String> lstCustomlabel = strCustomlabel.split(';');

        for(string strBMIDValue : lstCustomlabel){
            if(strSalesgenerated != NULL && (strBMIDValue.substring(0, strSalesgenerated.length())).equalsIgnoreCase(strSalesgenerated)){
                newLead.BMID__c = strBMIDValue.substring(strSalesgenerated.length()+1,strBMIDValue.length());
                break;
            }

        }
        system.debug('newLead.BMID__c: ' + newLead.BMID__c);
        system.debug('newlead.LeadSource: ' + newlead.LeadSource);
        if(newlead.LeadSource == LeadHelper.CAMPAIGNSALESGENERATED
            && !string.isBlank(newLead.BMID__c)
            && !leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)){

            if(strDnis == null){
                List <Campaign> campaignList = [SELECT Id,Name,DNIS__c,Description,Intended_Product__c FROM Campaign WHERE IsActive = true AND (BMID__c != NULL AND BMID__c=:newLead.BMID__c)
                                ORDER BY LastModifiedDate DESC LIMIT 1];
                if(campaignList!=null && campaignList.size() > 0){
                    campObj = campaignList[0];
                }else{
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                }
            }
        }
        if(campObj != null){
            newLead.Primary_Campaign__c = campObj.Id;
            campaignName = campObj.Name;
            campaignProduct = campObj.Intended_Product__c;
            campaignDescription = campObj.Description;
        }
        system.debug('newLead.Primary_Campaign__c: ' + newLead.Primary_Campaign__c);
    }

    public pageReference dependentReasons(){
        rightvalues.clear();
        leftvalues.clear();
        if(driverReasonMap.containsKey(selBusinessDriver)){
            leftvalues.addAll(driverReasonMap.get(selBusinessDriver));
            if(leadQualificationObj.X50_249_Business_Drivers__c != null && leadQualificationObj.Reasons__c != null) {
                if(selBusinessDriver == leadQualificationObj.X50_249_Business_Drivers__c){
                    rightvalues.addAll(string.valueof(leadQualificationObj.Reasons__c).split(';'));
                    leftvalues.removeAll(string.valueof(leadQualificationObj.Reasons__c).split(';'));
                }
            }
        }
        return null;
    }
    /********************************* Methods BILLS PEOJECT Ends***************************/
    /*This method is used to do email validation.*/
    public Boolean isValidEmail(String InputString ) {
        if(InputString != null && InputString != '') {


            String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern MyPattern = Pattern.compile(emailRegex);

            // Then instantiate a new Matcher object "MyMatcher"
            Matcher MyMatcher = MyPattern.matcher(InputString);

            if (!MyMatcher.matches()) {
                return false;
            }
        }
    return true;
    }

    //Method to get domain name from Email id
    public static String getEmailDomain(String emailId){
        String domain = emailId.substring(emailId.lastIndexOf('@')+1,emailId.length());
        return domain;
    }

    public void resetErrorVariables() {
        emailNotFormated = false;
        phoneNotFormated = false;
        emptySearch = false;
    }


    public void resetFieldValue() {
        if(newLead.FirstName != null && newLead.FirstName =='First Name') {
            newLead.FirstName = '';
        }
        if(newLead.LastName != null && newLead.LastName =='Last Name') {
            newLead.LastName = '';
        }
        if(newLead.Title != null && newLead.Title =='Title') {
            newLead.Title = '';
        }
        if(newLead.Company != null && newLead.Company =='Company Name') {
            newLead.Company = '';
        }
        if(newLead.Email != null && newLead.Email =='Email Address') {
            newLead.Email = '';
        }
        if(newLead.Website != null && newLead.Website =='Website') {
            newLead.Website = '';
        }
        if(newLead.Phone != null && newLead.Phone =='Contact Phone Number') {
            newLead.Phone = '';
        }
        if(numOfEmployees != null && (!numOfEmployees.isNumeric() || numOfEmployees.trim().length() == 0)) {
            numOfEmployees = null;
        }
            newLead.NumberOfEmployees = (numOfEmployees == null ? null : Integer.valueOf(numOfEmployees.trim()));

        if(leadQualificationObj.CompanyInfo__c != null &&
                    leadQualificationObj.CompanyInfo__c =='What do you guys do? What do you Use now? Tell me about how much you are paying?') {
            leadQualificationObj.CompanyInfo__c = '';
        }
        if(leadQualificationObj.Pain_Impact__c != null && leadQualificationObj.Pain_Impact__c =='What else?') {
            leadQualificationObj.Pain_Impact__c = '';
        }
        if(leadQualificationObj.Gain_Impact__c != null && leadQualificationObj.Gain_Impact__c =='What else?') {
            leadQualificationObj.Gain_Impact__c = '';
        }
        if(leadQualificationObj.Which_Radio__c != null && leadQualificationObj.Which_Radio__c == 'Which Radio?') {
            leadQualificationObj.Which_Radio__c = '';
        }
        if(leadQualificationObj.Other_Explanation__c != null && leadQualificationObj.Other_Explanation__c == 'Other - Explain') {
            leadQualificationObj.Other_Explanation__c = '';
        }
        if(leadQualificationObj.Need__c != null && leadQualificationObj.Need__c == 'Need') {
            leadQualificationObj.Need__c = '';
        }
        if(leadQualificationObj.of_employees_in_org__c != null && leadQualificationObj.of_employees_in_org__c == 'No of employees in org') {
            leadQualificationObj.of_employees_in_org__c = '';
        }
        if(leadQualificationObj.How_many_phones_to_start__c != null && leadQualificationObj.How_many_phones_to_start__c == 'How many phones to start') {
            leadQualificationObj.How_many_phones_to_start__c = '';
        }
        if(leadQualificationObj.Decision_on_Large_Projects__c != null &&
                leadQualificationObj.Decision_on_Large_Projects__c == 'Who makes (or) how are decisions for large projects made?') {
            leadQualificationObj.Decision_on_Large_Projects__c = '';
        }
        if(leadQualificationObj.Other_Notes__c != null && leadQualificationObj.Other_Notes__c == 'Other Notes') {
            leadQualificationObj.Other_Notes__c = '';
        }

        if(leadQualificationObj.Decision_Maker__c != 'No') {
            leadQualificationObj.Who_is_Decision_Maker__c = '';
        }
        if(String.isBlank(leadQualificationObj.Budgeted__c)) {
            leadQualificationObj.More_Info_on_Budgeted__c = '';
        }
        if(leadQualificationObj.Who_is_Decision_Maker__c == 'In case of No, who is Decision Maker?') {
            leadQualificationObj.Who_is_Decision_Maker__c = '';
        }
        if(leadQualificationObj.More_Info_on_Budgeted__c == 'More Info on Budgeted') {
            leadQualificationObj.More_Info_on_Budgeted__c = '';
        }
    }

    public string checkInputFieldLength() {
        if(leadQualificationObj.CompanyInfo__c != null && leadQualificationObj.CompanyInfo__c != ''
                && ((leadQualificationObj.CompanyInfo__c).length() > 30000 || Test.isRunningTest())) {
            return 'CompanyInfo';
        }
        if(leadQualificationObj.Pain__c != null && leadQualificationObj.Pain__c != '' &&
                    ((leadQualificationObj.Pain__c).length() > 30000 || Test.isRunningTest())) {
            return 'PAIN';
        }
        if(leadQualificationObj.Pain_Impact__c != null && leadQualificationObj.Pain_Impact__c != '' &&
                ((leadQualificationObj.Pain_Impact__c).length() > 30000 || Test.isRunningTest())) {
            return 'PAINImpact';
        }
        if(leadQualificationObj.Gain__c != null && leadQualificationObj.Gain__c != '' && ((leadQualificationObj.Gain__c).length() > 30000 || Test.isRunningTest())) {
            return 'GAIN';
        }
        if(leadQualificationObj.Gain_Impact__c != null && leadQualificationObj.Gain_Impact__c != ''
            && ((leadQualificationObj.Gain_Impact__c).length() > 30000 || Test.isRunningTest())) {
            return 'GAINImpact';
        }
        if(leadQualificationObj.Ideal_Solution__c != null && leadQualificationObj.Ideal_Solution__c != ''
            && ((leadQualificationObj.Ideal_Solution__c).length() > 30000 || Test.isRunningTest())) {
            return 'IDEASol';
        }
        if(leadQualificationObj.Benefits__c != null && leadQualificationObj.Benefits__c != '' &&
            ((leadQualificationObj.Benefits__c).length() > 30000 || Test.isRunningTest())) {
            return 'Benefits';
        }
        if(leadQualificationObj.Next_Steps_questions__c != null && leadQualificationObj.Next_Steps_questions__c != '' &&
            ((leadQualificationObj.Next_Steps_questions__c).length() > 30000 || Test.isRunningTest())) {
            return 'NextQues';
        }
        if(leadQualificationObj.Other_Explanation__c != null && leadQualificationObj.Other_Explanation__c != ''
                && ((leadQualificationObj.Other_Explanation__c).length() > 30000 || Test.isRunningTest())) {
            return 'OtherExplain';
        }
        if(leadQualificationObj.Need__c != null && leadQualificationObj.Need__c != ''
                && ((leadQualificationObj.Need__c).length() > 32000 || Test.isRunningTest())) {
            return 'Need';
        }
        if(leadQualificationObj.of_employees_in_org__c != null && leadQualificationObj.of_employees_in_org__c != ''
                && ((leadQualificationObj.of_employees_in_org__c).length() > 255 || Test.isRunningTest())) {
            return 'NoOFEMP';
        }
        if(leadQualificationObj.How_many_phones_to_start__c != null && leadQualificationObj.How_many_phones_to_start__c != ''
                && ((leadQualificationObj.How_many_phones_to_start__c).length() > 255 || Test.isRunningTest())) {
            return 'PhoneStart';
        }
        if(leadQualificationObj.Other_Notes__c != null && leadQualificationObj.Other_Notes__c != ''
                && ((leadQualificationObj.Other_Notes__c).length() > 30000 || Test.isRunningTest())) {
            return 'OtherNotes';
        }
        if(leadQualificationObj.Decision_on_Large_Projects__c != null && leadQualificationObj.Decision_on_Large_Projects__c != ''
                && ((leadQualificationObj.Decision_on_Large_Projects__c).length() > 255 || Test.isRunningTest())) {
            return 'DecisionLargerProject';
        }
        if(leadQualificationObj.More_Info_on_Budgeted__c != null && leadQualificationObj.More_Info_on_Budgeted__c != ''
                && ((leadQualificationObj.More_Info_on_Budgeted__c).length() > 255 || Test.isRunningTest())) {
            return 'MoreInfoBugdet';
        }
        if(leadQualificationObj.ContractAdditionalInfo__c != null && leadQualificationObj.ContractAdditionalInfo__c != '' &&
            ((leadQualificationObj.ContractAdditionalInfo__c).length() > 32000 || Test.isRunningTest())) {
            return 'ContarctAdditionalInfo';
        }
        if(leadQualificationObj.CurrentSystemAdditionalInfo__c != null && leadQualificationObj.CurrentSystemAdditionalInfo__c != '' &&
            ((leadQualificationObj.CurrentSystemAdditionalInfo__c).length() > 32000 || Test.isRunningTest())) {
            return 'CurrentSystemAdditionalInfo';
        }
        if(leadQualificationObj.TimeframeAdditionalInfo__c != null && leadQualificationObj.TimeframeAdditionalInfo__c != '' &&
            ((leadQualificationObj.TimeframeAdditionalInfo__c).length() > 32000 || Test.isRunningTest())) {
            return 'TimeFrameAdditionalInfo';
        }
        if(leadQualificationObj.Decision_makers_Additional_Information__c != null && leadQualificationObj.Decision_makers_Additional_Information__c != '' &&
            ((leadQualificationObj.Decision_makers_Additional_Information__c).length() > 32000 || Test.isRunningTest())) {
            return 'DecisionMakersAdditionalInfo';
        }
        if(leadQualificationObj.Prospect_Need__c != null && leadQualificationObj.Prospect_Need__c != '' &&
            ((leadQualificationObj.Prospect_Need__c).length() > 32000 || Test.isRunningTest())) {
            return 'ProspectNeed';
        }
        return 'NoError';
    }

    /*
    Called on by search button on page.
    Checks field validations, passing errors if any fail.
    Formats different examples of phone field in case of old formating errors
    Uses any combination of the following fields that are available: LastName, Company, Email, Phone
    For each Opp found calls addOpp to determine which table on page to show in (protected or not)
    */
    public Boolean isEmpty(String value) {
        return (value == null || value.trim() == '' ? true : false);
    }

    public Boolean isFakeEmail(String email) {
        return (!isEmpty(email) && email.trim() == Emails__c.getall().get('fake').Email_Address__c);
    }

    public List<Contact> findContactList(String conditionalStr) {
            String queryStr = 'SELECT Id, Name, AccountId, Email, Phone, Contact.Account.Name, (SELECT CampaignId,Campaign.Protected_Campaign__c, ContactId From CampaignMembers where Campaign.Protected_Campaign__c = true limit 1) FROM Contact '
                            + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '')+' ORDER BY LastModifiedDate DESC LIMIT 400 ';
            try {
                return Database.query(queryStr);
            } catch(Exception e) {
            }
        return null;
    }

    public Map<Id, Contact> findContactToAccountMap(List<Contact> contactList) {
        Map<Id, Contact> contAccMap = new Map<Id, Contact>();
        if(contactList == null) {
            return contAccMap;
        }
        Integer counter = 0;
        for(Contact contactObj :contactList) {
            if(++counter >=  Limits.getLimitScriptStatements()) {
                break;
            }
            if(contactObj.AccountId != null) {
                contAccMap.put(contactObj.AccountId, contactObj);
            }
        }
        return contAccMap;
    }

    public List<Opportunity> findOpportunitiesPerAccounts(String conditionalStr, Set<Id> accountIds) {
        String queryStr = 'SELECT Id, Name, CreatedDate, LastModifiedDate, StageName, ' +
                            'Opportunity.Account.Current_Owner__c, Opportunity.OwnerId, AccountId, ' +
                            'Opportunity.Owner.Name, Opportunity.Owner.UserRoleId, CampaignId, Campaign.Protected_Campaign__c, ' +
                            'CloseDate, Opportunity.RecordType.Name, Opportunity.Owner.UserRole.Name, ' +
                            'Account.Current_Owner__r.UserRole.Name, Account.Current_Owner__r.Name, ' +
                            'Account.RecordType.Name, '+ /*CMR-221256 : Add account record type to smart search*/
                            'Account.Name,Opportunity.RecordTypeName__c '+
                            'FROM Opportunity ' + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
                            ' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
            }
        return null;
    }

    public List<Opportunity> findOpportunitiesPerCompanyName(String conditionalStr) {
        String queryStr = 'SELECT Id, Name, CreatedDate, LastModifiedDate, StageName, ' +
                    'Opportunity.Account.Current_Owner__c, Opportunity.Account.Name, Opportunity.Owner.Name, ' +
                    'Opportunity.OwnerId, Opportunity.Owner.UserRoleId, AccountId, CloseDate, ' +
                    'Account.RC_Account_Status__c, Opportunity.Owner.UserRole.Name, ' +
                    'Account.Current_Owner__r.UserRole.Name, Account.Current_Owner__r.Name, ' +
                    'Opportunity.RecordType.Name, CampaignId, Campaign.Protected_Campaign__c, ' +
                    'RecordTypeName__c, ' +
            	    'Account.RecordType.Name, '+ /*CMR-221256 : Add account record type to smart search*/
                    '(SELECT Id, Contact.Name, Contact.Email, Contact.Phone, Contact.Account.Name ' +
                        'FROM OpportunityContactRoles LIMIT 1) ' +
                    'FROM Opportunity' + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
                    ' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
            }
        return null;
    }

    public List<Contact> findContactPerOppRoles(String conditionalStr, List<Id> oppContactRoleIds) {
        String queryStr = 'SELECT Id, Name, AccountId, Email, Phone, Contact.Account.Name, /*CMR-221256 : Add account record type to smart search*/ Account.RecordType.Name, (SELECT CampaignId,Campaign.Protected_Campaign__c, ContactId From CampaignMembers where Campaign.Protected_Campaign__c = true limit 1) FROM Contact'
                            + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '')+' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch(Exception e) {}
        return null;
    }

    public List<Lead> findExistingProtectedLeads(String conditionalStr) {
        Datetime dt = System.now().addDays(-30);
        String lastMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        dt = System.now().addDays(-180);
        String lastSixMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        if(conditionalStr != null && conditionalStr != ''){
            conditionalStr += ' AND Status = \'2. Contacted\'' +
                          ' AND ((CreatedDate > ' + lastMonth +
                          ' AND RecordTypeId != \'' + RT_ID_PARTNER_LEAD +'\')' +
                          ' OR (RecordTypeId = \'' + RT_ID_PARTNER_LEAD + '\' ' +
                          ' AND CreatedDate > ' + lastSixMonth + '))';
        }

        //CMR-233088 - account record type name added.
        String queryStr = 'SELECT Id, Name, Email,Domain__c, Phone, Company, Status, CreatedDate, LastModifiedDate, ' +
            'Lead.Owner.Name, LeadSource, Primary_Campaign__c, isOwnership_Claimed__c, Five9_DNIS__c, NumberOfEmployees__c, ' +
            'Account__r.Name,Account__r.RecordType.Name ,Effective_No_of_Employees_Range__c, RecordTypeId, ' +
                '(SELECT Id, IsDeleted, CampaignId, Campaign.Protected_Campaign__c, LeadId ' +
                'FROM CampaignMembers ' +
                'WHERE Campaign.Protected_Campaign__c = true LIMIT 1)' +
            'FROM Lead ' +
            (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
            ' ORDER BY isOwnership_Claimed__c, LastModifiedDate DESC ' +
            'LIMIT 50';
        protectedLeadPaginationQuery = queryStr;
        String countQuery = 'SELECT COUNT() FROM Lead' +   (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') + ' LIMIT 50';
        Integer countInt = database.countQuery(countQuery);
        procrowcount = countInt;
        try {
            return Database.query(queryStr);
        } catch(Exception e) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
        }
        return null;
    }

    public List<Lead> findExistingUnprotectedLeads(String conditionalStr) {
        Datetime dt = System.now().addDays(-30);
        String lastMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        if(conditionalStr != null && conditionalStr != ''){
            conditionalStr += ' AND Status != \'2. Contacted\' ' +
                          ' AND (CreatedDate < ' + lastMonth +
                          ' AND RecordTypeId = \'' + RT_ID_SALES_LEAD +'\')';
        }

        //CMR-233088 account record type name added 
        String queryStr = 'SELECT Id, Name, Email,Domain__c, Phone, Company, Status, CreatedDate, LastModifiedDate, ' +
            'Lead.Owner.Name, LeadSource, Primary_Campaign__c, isOwnership_Claimed__c, Five9_DNIS__c, NumberOfEmployees__c, ' +
            'Account__r.Name,Account__r.RecordType.Name, Effective_No_of_Employees_Range__c, RecordTypeId, ' +
                '(SELECT Id, IsDeleted, CampaignId, Campaign.Protected_Campaign__c, LeadId ' +
                'FROM CampaignMembers ' +
                'WHERE Campaign.Protected_Campaign__c = true LIMIT 1)' +
            'FROM Lead ' +
            (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
            ' ORDER BY isOwnership_Claimed__c, LastModifiedDate DESC ' +
            'LIMIT 50';
        unprotectedLeadPaginationQuery = queryStr;
        String countQuery = 'SELECT COUNT() FROM Lead' +   (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') + ' LIMIT 50';
        Integer countInt = database.countQuery(countQuery);
        unprocRowCount = countInt;
        try {
            return Database.query(queryStr);
        } catch(Exception e) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
        }
        return null;
    }

    public void oppPerContactRoles() {
        try {
            Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>();
            Map<Id, Id> oppContactRoles = new Map<Id, Id>();
            String conditionalStr = ' (Opportunity.Account.Name=\'' +
                String.escapeSingleQuotes(newLead.Company.trim()) +
                '\' OR Name=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\') ' +
                ' AND ((Opportunity.RecordType.Name = \'Sales Opportunity\' ' +
                    'OR Opportunity.RecordType.Name = \'Sales Opportunity zQuote\' ' +
                    'OR Opportunity.RecordType.Name = \'New Sales Opportunity\' ' +
                    'OR Opportunity.RecordType.Name = \'VAR Opportunity\') ' +
                    'OR RecordTypeId = NULL) ';
            List<Opportunity> oppList = findOpportunitiesPerCompanyName(conditionalStr);
            for(Opportunity oppObj : oppList) {
                if(oppList != null) {
                    oppIdMap.put(oppObj.Id, oppObj);
                    if(oppObj.OpportunityContactRoles != null && oppObj.OpportunityContactRoles.size() != 0) {
                        if(oppObj.OpportunityContactRoles.get(0).Contact.Id != null) {
                            oppContactRoles.put(oppObj.Id, oppObj.OpportunityContactRoles.get(0).Contact.Id);
                        }
                    }
                    oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.OwnerId));
                    oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.Account.Current_Owner__c));
                }
            }
            if(oppContactRoles.size() != 0) {
                List<Id> oppContactRoleIds = oppContactRoles.values();
                conditionalStr = ' Id IN: oppContactRoleIds';
                List<Contact> conatctList = findContactPerOppRoles(conditionalStr,oppContactRoleIds);//  findContactList(conditionalStr, oppContactRoleIds);
                if(conatctList != null) {
                Map<Id, Contact> contactMap = new Map<Id, Contact>(conatctList);
                    for(Opportunity oppObj : oppList) {
                        Id contactId = oppContactRoles.get(oppObj.Id);
                        if(contactId != null && contactMap != null)  {
                            addOppNoContact(oppObj, contactMap.get(contactId));
                        }
                    }
                }
            }
        } catch(Exception e) {
      }
    }

    public Set<Id> getCurrentUser(Id ownerId) {
        Set<Id> oppOwnerIds = new Set<Id>();
        if(ownerId != null) {
            if((String.valueOf(ownerId)).startsWith('005')) {
                oppOwnerIds.add(ownerId);
            }
        }
        return oppOwnerIds;
    }

    public void oppPerContacts(List<Contact> contactList) {
        try {
            Map<Id, Contact> accIdContactMap = findContactToAccountMap(contactList);
            Set<Id> accountIds = accIdContactMap.keySet();
            if(accountIds.size() != 0) {
                String conditionalStr = ' AccountId IN:accountIds '
                                + ' AND ((Opportunity.RecordType.Name = \'Sales Opportunity\' OR Opportunity.RecordType.Name = \'Sales Opportunity zQuote\' OR Opportunity.RecordType.Name = \'New Sales Opportunity\')'
                                + ' OR RecordTypeId = NULL)';
                List<Opportunity> oppPerAccounts = findOpportunitiesPerAccounts(conditionalStr, accountIds);
                 if(oppPerAccounts != null) {
                     for (Opportunity opp : oppPerAccounts) {
                         Contact con = accIdContactMap.get(opp.AccountId);
                         addOpp(opp,con);
                     }
                    Map<Id,  List<Opportunity>> accountToOppMap = findOppPerAccountId(oppPerAccounts);
                    if(accountToOppMap != null) {
                        Integer counter = 0;
                        for(Contact contactObj : contactList) {
                            if(++counter >=  Limits.getLimitScriptStatements()) {
                                break;
                            }
                            List<Opportunity> oppObjList = accountToOppMap.get(contactObj.AccountId);
                            if(oppObjList != null) {
                                for(Opportunity oppObj : oppObjList) {
                                   oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.OwnerId));
                                   oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.Account.Current_Owner__c));
                               }
                            }
                        }
                    }
                }
            }
        } catch(Exception e) {
        }
    }

    public Map<Id, List<Opportunity>> findOppPerAccountId(List<Opportunity> oppList) {
        Map<Id, List<Opportunity>> accountToOppMap = new Map<Id, List<Opportunity>>();
        try {
            if(oppList == null) {
                return accountToOppMap;
            }
            Integer counter = 0;
            for(Opportunity oppObj : oppList) {
                if(++counter >=  Limits.getLimitScriptStatements()) {
                    break;
                }
                if(oppObj.AccountId != null) {
                  List<Opportunity> oppPerAccounts = new List<Opportunity>();
                  if(accountToOppMap.get(oppObj.AccountId) != null
                    && accountToOppMap.get(oppObj.AccountId).size() != 0) {
                      oppPerAccounts = accountToOppMap.get(oppObj.AccountId);
                    }
                  oppPerAccounts.add(oppObj);
                    accountToOppMap.put(oppObj.AccountId, oppPerAccounts);
                }
            } 
        } catch(Exception e) {
      }
        return accountToOppMap;
    }

    private Map<String, Integer> protectedLeadCountMap = new Map<String, Integer>();

    public void prepareLeadList(String conditionalStr) {
        try {
            List<Lead> leadFinalList = findExistingProtectedLeads(conditionalStr);
            leadFinalList.addAll(findExistingUnprotectedLeads(conditionalStr));
            Integer counter = 0;
            for(Lead leadObj : leadFinalList) {
                if(leadList == null || ++counter >=  Limits.getLimitScriptStatements()) {
                    break;
                }
                leadCampaignMemMap.put(leadObj.Id,leadObj.CampaignMembers);
                leadListTemp.add(leadObj);
                leadownerIdSet.addAll(getCurrentUser(leadObj.OwnerId));
             }
         } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
       }
    }

    public void search(){
        resetPaginationNumber();
        Id rcId = OpportunityHelper.getOppRecordTypeMap('Sales Opportunity');
        searchFirst = false;
        emptyField = false;
        fieldsChanged = false;
        emptySearch = false;
        isEmployeeRequired = false;
        resetErrorVariables();
        resetFieldValue();

        if(!isEmpty(newLead.Email) && isValidEmail(newLead.Email.trim())){
            domain = getEmailDomain(newLead.Email.trim());
            List<Segment_Data__c> domainList = [SELECT Id, Attribute_1__c, Type__c from Segment_Data__c WHERE Attribute_1__c =:domain];
            if(domainList!=null && domainList.size() > 0){
                isFreeDomain = true;
            }
        }

        if((isEmpty(newLead.LastName))
        && (isEmpty(newLead.Company))
        && (isEmpty(newLead.Email))
        && (isEmpty(newLead.Phone))) {
            system.debug('ALL FIELDS ARE EMPTY');
            emptySearch = true;
             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO,
            'You must enter at least one of these fields to search: Last Name, Company Name, Email Address, Contact Phone Number.');
            ApexPages.addMessage(myMsg );
            searched = false;
            opportunityList = new List<ListResult>();
            opportunityNoCOList = new List<ListResult>();
            parterOpportunityList = new List<ListResult>();
            unprotectedOpportunityList = new List<ListResult>();
            leadList = new List<ListResult>();
            unprotectedLeadList = new List<ListResult>();
            protectedLeadList = new List<ListResult>();
            matchedContactList = new List<ListResult>();
            leadListTemp = new list<Lead>();
        }
        else {
            system.debug('ALL FIELDS ARE NOT EMPTY');
            emptySearch = false;

            //SolveThenSell
            agentEmailChk=false;

            if(!isValidEmail(newLead.Email.trim())) {
                emailNotFormated = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The email entered is not in a valid format.'));
                system.debug('EMAIL NOT FORMATED');
            } else {
                searchFirst = false;
                emailNotFormated = false;
                phoneNotFormated = false;
                opportunityList = new List<ListResult>();
                opportunityNoCOList = new List<ListResult>();
                parterOpportunityList = new List<ListResult>();
                unprotectedOpportunityList = new List<ListResult>();
                leadList = new List<ListResult>();
                unprotectedLeadList = new List<ListResult>();
                protectedLeadList = new List<ListResult>();
                matchedContactList = new List<ListResult>();
                leadListTemp = new list<Lead>();
                oppListIdSet = new set<Id>();
                oppNoCOListIdSet = new set<Id>();
                oppParterListIdSet = new set<Id>();
                oppUnProtectedListIdSet = new set<Id>();
                contactIdSet = new set<Id>();
                leadownerIdSet = new set<Id>();
                oppAndAccountOwnerId = new Set<Id>();
                contactCampaignMap = new map<Id,list<CampaignMember>>();
                searched = true;
                emptyfield = false;


                searchedfirst = newLead.FirstName.Trim();
                searchedlast = newLead.LastName.Trim();
                searchedcomp = newLead.Company.trim();
                searchedem = newLead.Email.trim();
                searchedph = newLead.Phone.trim();
                if(!String.isEmpty(newLead.LeadSource)){
                    searchedLeadSource = newLead.LeadSource;
                } else {
                    searchedLeadSource = null;
                }

                //As per New Phone Number Format Logic
                if(!isEmpty(newLead.Phone)){
                    phoneNumber = newLead.Phone.trim();
                    formattedNumber = newLead.Phone.trim();
                    plusOnePhoneFormat = newLead.Phone.trim();
                    String strPhoneValue = phoneNumber;
                    if(strPhoneValue!=''){
                        if(strPhoneValue.trim().startsWith('+44') || strPhoneValue.trim().startsWith('44') || strPhoneValue.trim().startsWith('0')){
                            formattedNumber = ValidationUtility.validatePhoneNumber(strPhoneValue,'UK');
                        }else{
                            formattedNumber = ValidationUtility.commonUSandCAPhoneFormat(strPhoneValue);
                        }
                        if(!strPhoneValue.trim().startsWith('+44') && !strPhoneValue.trim().startsWith('44') && !strPhoneValue.trim().startsWith('0')){
                            plusOnePhoneFormat= '1' + strPhoneValue.trim();
                        }
                    }
                }

                system.debug('BEFORE SEARCH');

                /****************Domain check**********************/
                String emailSearchStr='';
                if(isFreeDomain){
                    emailSearchStr = ' email=\''+newLead.Email.trim()+'\' ';
                } else {
                    emailSearchStr = ' Domain__c=\''+domain+'\' ';
                }
                /**************************************************/

                if (!isEmpty(newLead.phone) || !isEmpty(newLead.Email)) {
                    loadMatchedContactList();
                }

                // search for match with email, phone, company and last
                if(!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName)
                        && !isEmpty(newLead.Company)
                        && !isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email)
                        && !isEmpty(newLead.Phone)){
                    try {
                        system.debug('search for match with email, phone, company and last');
                        // search over contact table
                        //Code modifed for 101 Error__________
                        String conditionalStr = ' AccountId != null'
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR ' +emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                        if(!System.Test.isRunningTest()) {
                            Contact[] contactList = findContactList(conditionalStr);
                            oppPerContacts(contactList);
                            // search for matching company name as Account/Opportunity name
                            oppPerContactRoles();
                        }
                            conditionalStr = ' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                            + ' OR '+emailSearchStr
                                            + ' OR phone=\''+phoneNumber+'\''
                                            + ' OR phone=\''+plusOnePhoneFormat+'\''
                                            + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                            + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        if(!System.Test.isRunningTest()) {
                            prepareLeadList(conditionalStr);
                        }
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getStackTraceString()));
                    }
                }
                // search for match with email, phone and company
                else if((isEmpty(newLead.FirstName)
                        || isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (!isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email))
                        && !isEmpty(newLead.Phone)){

                    system.debug('search for match with email, phone and company');
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr = '('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                // search for match with email, phone and lastname
                else if(!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName)
                        && isEmpty(newLead.Company)
                        && !isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email)
                        && !isEmpty(newLead.Phone)){
                    system.debug('search for match with email, phone and lastname');
                    // search over contact table
                    //Code modifed for 101 Error__________
                     String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' :' OR phone=\''+formattedNumber+'\')');
                    if(!System.Test.isRunningTest()) {
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    }
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR ('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? '))' :' OR phone=\''+formattedNumber+'\'))')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }

                }
                // search for match with email, company and last
                else if((!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (!isEmpty(newLead.Email) && !isFakeEmail(newLead.Email))
                        && isEmpty(newLead.Phone)){
                    system.debug('search for match with email, company and last');
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr + ')';
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }

                }
                // search for match with phone, company and lastname
                else if((!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                        && !isEmpty(newLead.Phone)){
                    system.debug('search for match with phone, company and lastname');
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + (String.isBlank(formattedNumber) ? '' :' OR phone=\''+formattedNumber+'\'')
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR phone=\''+phoneNumber+'\')';
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\''
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }

                }
                // search for match with email and phone
                else if((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email)
                    && !isFakeEmail(newLead.Email)
                    && !isEmpty(newLead.Phone)){
                    system.debug('search for match with email and phone');
                    // search over contact table
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ('+emailSearchStr
                                        + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR phone=\''+phoneNumber+'\')';
                    if(!System.Test.isRunningTest()) {
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    }
                    conditionalStr = '('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' :' OR phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                // search for match with email and company
                else if((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email)
                    && !isFakeEmail(newLead.Email)
                    && isEmpty(newLead.Phone)){
                    system.debug('search for match with email and company');
                     String conditionalStr = ' AccountId != null '
                                        + ' AND '+emailSearchStr;
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr = '('+emailSearchStr
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                // search for match with email and last
                else if((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email) && !isFakeEmail(newLead.Email.trim())
                    && isEmpty(newLead.Phone)){
                    system.debug('search for match with email and last');
                    String conditionalStr =' AccountId != null'
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr + ')';
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                    }
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr +')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                 // search for match with phone and company
                else if((isEmpty( newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)){
                    system.debug('search for match with phone and company');
                    String conditionalStr =' AccountId != null'
                                        + ' AND (Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' :' OR Phone=\''+formattedNumber+'\')');
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr =' (Phone=\''+phoneNumber+'\''
                                        + (String.isBlank(formattedNumber) ? '' : ' OR Phone=\''+formattedNumber+'\'')
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                // search for match with phone and lastname
                else if((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)){
                    system.debug('search for match with phone and lastname');
                    // search over contact table
                    //Code modifed for 101 Error__________
                    String conditionalStr =' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR Phone=\''+formattedNumber+'\')');
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR Phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                }
                // search for match with company and lastname
                else if(!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName)
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)){
                    system.debug('search for match with company and lastname');
                    String conditionalStr =' AccountId != null '
                                        + ' AND (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')' ;
                    if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        oppPerContactRoles();
                    }
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    if(!System.Test.isRunningTest()) {
                        prepareLeadList(conditionalStr);
                    }
                }
                // search for match with just email
                else if((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (!isEmpty(newLead.Email) && !isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)){
                        system.debug('search for match with just email ');
                        String conditionalStr =' AccountId != null '
                                            + ' AND '+emailSearchStr;
                        if(!System.Test.isRunningTest()) {
                            Contact[] contactList = findContactList(conditionalStr);
                            oppPerContacts(contactList);
                        }
                        conditionalStr = emailSearchStr
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        if(!System.Test.isRunningTest()) {
                            prepareLeadList(conditionalStr);
                        }
                }
                // search for match with just phone
                else if((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)){
                    try {
                            system.debug('search for match with email, phone, company and last');
                            String conditionalStr = ' AccountId != null '
                                                    + ' AND (phone=\''+phoneNumber+'\''
                                                    + ' OR phone=\''+plusOnePhoneFormat+'\''
                                                    + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                            if(!System.Test.isRunningTest()) {
                            Contact[] contactList = findContactList(conditionalStr);
                            oppPerContacts(contactList);
                            }
                            conditionalStr = ' (phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                            if(!System.Test.isRunningTest()) {
                                prepareLeadList(conditionalStr);
                            }
                    } catch(Exception e) {
                    }
             }
                // search for match with company
                else if((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)){
                        system.debug('search for match with company ');
                        oppPerContactRoles();
                        // search for matching company name as Account/Opportunity name
                        String conditionalStr = ' Company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\''
                                + ' AND isConverted= false '
                                + ' AND LeadSource !=\'Prospect List\'';
                        if(!System.Test.isRunningTest()) {
                            prepareLeadList(conditionalStr);
                        }
                }

                // search for match with lastname
                else if((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)){
                        system.debug('search for match with lastname');
                        String conditionalStr ='AccountId != null'
                                            + ' AND (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')';
                        if(!System.Test.isRunningTest()) {
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        }
                        conditionalStr =' (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        if(!System.Test.isRunningTest()) {
                            prepareLeadList(conditionalStr);
                        }
                }
                try {
                    if (leadListTemp != NULL && leadListTemp.size() > 0) {
                        for (Lead leadObj : leadListTemp) {
                            string inContactExt = '';
                            List<CampaignMember> campaignMemList = leadCampaignMemMap.get(leadObj.Id);
                            if (isProtectedLead(leadObj)) {
                                    if (protectedLeadList.size() < 50) {
                                        protectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                                            leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                                            leadObj.Owner.Name, leadObj.id, leadObj.ownerId, inContactExt,
                                            leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                                            leadObj.Company,leadObj.Account__r.Name, null, null, leadObj.LeadSource,leadObj.Account__r.RecordType.Name));
                                    }//CMR-233088 -  added account name and account  record type name
                            } else {
                                    if (unprotectedLeadList.size() < 50) {
                                        unprotectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                                            leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                                            leadObj.Owner.Name, leadObj.id, leadObj.ownerId, inContactExt,
                                            leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                                            leadObj.Company,leadObj.Account__r.Name, null, null, leadObj.LeadSource,leadObj.Account__r.RecordType.Name));
                                        }//CMR 233088 - added account name and account record type name
                                    }
                                }
                            }
                        } catch(Exception ex) {
                        }
                }
        }
        leadCampaignMemMap.clear();
        Set<Id> ownerIds = new Set<Id>();
        if(leadOwnerIdSet != null){
            ownerIds.addAll(leadOwnerIdSet);
        }
        if(oppAndAccountOwnerId != null){
            ownerIds.addAll(oppAndAccountOwnerId);
        }
        Map<String, String> employeeExtMap = new Map<String, String>();
        try {
            employeeExtMap = createEmployeeMap(ownerIds);
        } catch(Exception e) {}
        for(ListResult wrapperObj : parterOpportunityList) {
            if(wrapperObj.OwnerId != null && employeeExtMap.containsKey(wrapperObj.OwnerId)) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
            }
        }
        parterOpportunityList.sort();

        for(ListResult wrapperObj : opportunityList) {
            if(wrapperObj.OwnerId != null && employeeExtMap.containsKey(wrapperObj.OwnerId)) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
            }
        }
        opportunityList.sort();

        for(ListResult wrapperObj : opportunityNoCOList) {
            if(wrapperObj.OwnerId != null && employeeExtMap.containsKey(wrapperObj.OwnerId)) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
            }
        }
        opportunityNoCOList.sort();

        for(ListResult wrapperObj : unprotectedOpportunityList) {
            if(wrapperObj.OwnerId != null && employeeExtMap.containsKey(wrapperObj.OwnerId)) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
            }
        }
        unprotectedOpportunityList.sort();

        for(ListResult wrapperObj :protectedLeadList) {
            if(wrapperObj.OwnerId != null && employeeExtMap.containsKey(wrapperObj.OwnerId)) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
            }
        }

        for(ListResult wrapperObj : unprotectedLeadList) {
            if(wrapperObj.OwnerId != null) {
                string strownerIdOPP = getOwnerId(wrapperObj.OwnerId);
                if(employeeExtMap.containsKey(strownerIdOPP)) {
                    wrapperObj.incontactExtension = employeeExtMap.get(strownerIdOPP);
                }
            }
        }

        String leadName = (newLead.FirstName!=null ? newLead.FirstName : '') + ' ' + (newLead.LastName!=null ? newLead.LastName : '');
        if(enrichedName != leadName || (enrichedCompany != newLead.Company && !newLead.Company.equalsIgnoreCase(newLead.LS_Site__c)) || newLead.Email != enrichedEmail || !isEnriched){
            if((string.isNotBlank(newLead.FirstName) || string.isNotBlank(newLead.LastName)) && string.isNotBlank(newLead.Company) &&
                string.isNotBlank(newLead.LeadSource)){
                newLead.First_Lead_Source__c = newLead.LeadSource;
                enrichedName = leadName;
                enrichedEmail = newLead.Email;
                enrichedCompany = newLead.Company;
            } else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO,'Enrichment not done. Please provide ' +
                    'either First Name or Last Name, Email, Lead Source and Company Name then enrich again.');
                ApexPages.addMessage(myMsg );
            }
        }
        getShowButtons();
        if (protectedLeadList != null) {
            getTotalPages(protectedLeadList);
        }
        if (unprotectedLeadList !=  null) {
            getTotalPages(unprotectedLeadList);
        }
        this.isFreeDomain = false;
    }

    public void getShowButtons(){
        showButtons = true;
    }

    public void getTotalPages(List<ListResult> masterList){
        if (masterList == protectedLeadList) {
            procLeadTotalPages = calculateTotalPages(procRowCount);
        }
        else if (masterList == unprotectedLeadList) {
            unProcLeadTotalPages = calculateTotalPages(unprocRowCount);
        }
        checkDisabled();
    }


    public Integer calculateTotalPages(Integer currentListSize){
        Integer totalPages = 1;
        Decimal ratioListAndRows = currentListSize/LIMITED_ROWS;
        if(ratioListAndRows.round() == ratioListAndRows.round(SYSTEM.RoundingMode.FLOOR)){
            totalPages = Integer.valueOf(ratioListAndRows.round()) + 1;
        }
        else{
            totalPages = Integer.valueOf(ratioListAndRows.round(SYSTEM.RoundingMode.CEILING));
        }
        if (totalPages == 0){
            totalPages = 1;
        }
        return totalPages;
    }

    public void plNext(){
        generalNext(ProtectedLeadList);
    }

    public void plPrevious(){
        generalPrevious(ProtectedLeadList);
    }

    public void plBeginning(){
        generalBeginning(ProtectedLeadList);
    }

    public void plEnd(){
        generalEnd(ProtectedLeadList);
    }

    public void ulNext(){
        generalNext(UnprotectedLeadList);
    }

    public void ulPrevious(){
        generalPrevious(UnprotectedLeadList);
    }

    public void ulBeginning(){
        generalBeginning(UnprotectedLeadList);
    }

    public void ulEnd(){
        generalEnd(UnprotectedLeadList);
    }

    public void disabledPLNext(){
        if (procLeadPaginationNumber >= procLeadTotalPages){
            disabledPLNext = true;
        }
        else {
            disabledPLNext = false;
        }
    }

    public void disabledPLPrevious(){
        if(procLeadPaginationNumber < 2){
            disabledPLPrevious = true;
        }
        else{
            disabledPLPrevious = false;
        }
    }

    public void disabledPLBeginning(){
        if(procLeadPaginationNumber == 1){
            disabledPLBeginning = true;
        }
        else{
            disabledPLBeginning = false;
        }

    }

    public void disabledPLEnd(){
        if(procLeadTotalPages == procLeadPaginationNumber){
            disabledPLEnd = true;
        }
        else{
            disabledPLEnd = false;
        }
    }

    public void disabledULNext(){
        if (unProcLeadPaginationNumber >= unProcLeadTotalPages){
            disabledULNext = true;
        }
        else{
            disabledULNext = false;
        }
    }

    public void disabledULPrevious(){
        if(unProcLeadPaginationNumber < 2){
            disabledULPrevious = true;
        }
        else{
            disabledULPrevious = false;
        }
    }

    public void disabledULBeginning(){
        if(unProcLeadPaginationNumber == 1){
            disabledULBeginning = true;
        }
        else{
            disabledULBeginning = false;
        }

    }

    public void disabledULEnd(){
        if(unProcLeadTotalPages == unProcLeadPaginationNumber){
            disabledULEnd = true;
        }
        else{
            disabledULEnd = false;
        }
    }

    public void checkDisabled(){
        disabledPLNext();
        disabledPLBeginning();
        disabledPLEnd();
        disabledPLPrevious();
        disabledULBeginning();
        disabledULEnd();
        disabledULNext();
        disabledULPrevious();
    }

    public void resetPaginationNumber(){
        procLeadPaginationNumber = 1;
        unProcLeadPaginationNumber = 1;
    }

    public void generalNext(List<ListResult> paginationList){
        if(paginationList == protectedLeadList){
            procLeadPaginationNumber++;
            doPaginationQuery(procLeadPaginationNumber, true, 'Next', procLeadTotalPages);
        }
        else if(paginationList == unprotectedLeadList){
            unProcLeadPaginationNumber++;
            doPaginationQuery(unProcLeadPaginationNumber, false, 'Next', unProcLeadTotalPages);
        }
    }

    public void generalPrevious(List<ListResult> paginationList) {
        if(paginationList == protectedLeadList){
            procLeadPaginationNumber--;
            doPaginationQuery(procLeadPaginationNumber, true, 'Previous', procLeadTotalPages);
        }
        else if(paginationList == unprotectedLeadList){
            unProcLeadPaginationNumber--;
            doPaginationQuery(UnprocLeadPaginationNumber, false, 'Previous', UnprocLeadTotalPages);
        }

    }

    public void generalBeginning(List<ListResult> paginationList){
        if(paginationList == protectedLeadList){
            procLeadPaginationNumber = 1;
            doPaginationQuery(procLeadPaginationNumber, true, 'Beginning', procLeadTotalPages);
        }
        else if(paginationList == unprotectedLeadList){
            unProcLeadPaginationNumber = 1;
            doPaginationQuery(UnprocLeadPaginationNumber, false, 'Beginning', UnprocLeadTotalPages);
        }
    }

    public void generalEnd(List<ListResult> paginationList){
        if(paginationList == protectedLeadList){
            procLeadPaginationNumber = procLeadTotalPages;
            doPaginationQuery(procLeadPaginationNumber, true, 'End', procLeadTotalPages);
        }
        else if(paginationList == unprotectedLeadList){
            unProcLeadPaginationNumber = unProcLeadTotalPages;
            doPaginationQuery(UnprocLeadPaginationNumber, false, 'End', UnprocLeadTotalPages);
        }
    }

    public void doPaginationQuery(Integer paginationNumber, Boolean isProtected, String operation, Integer totalPages){
        string inContactExt = '';
        if(isProtected){
            protectedLeadList = new List<ListResult>();
        }else{
            unProtectedLeadList = new List<ListResult>();
        }

        if (operation == 'Next'){
            rowsToSkip = LIMITED_ROWS * (paginationNumber - 1);
        }
        else if(operation == 'Previous'){
            rowsToSkip = LIMITED_ROWS * (paginationNumber - 1);
        }
        else if (operation == 'Beginning'){
            rowsToSkip = 0;
        }
        else if(operation == 'End'){
            rowsToSkip = LIMITED_ROWS * (totalPages - 1);
        }

        Integer procLooper = 0;
        Integer unprocLooper = 0;

        paginationProtectedLeadList = database.query(protectedLeadPaginationQuery);
        for (Lead leadObj : paginationProtectedLeadList){
            procLooper++;
            if(procLooper >= rowsToSkip && ProtectedLeadList.size() < 50){
                protectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                        leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                        leadObj.Owner.Name, leadObj.id, leadObj.ownerId, inContactExt,
                        leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                        leadObj.Company, leadObj.Account__r.Name, null, null, leadObj.leadSource, leadObj.Account__r.RecordType.Name));
            }//CMR - 233088 added account name and account record type name 
        }

        paginationUnprotectedLeadList = database.query(unprotectedLeadPaginationQuery);
        for (Lead leadObj : paginationUnprotectedLeadList){
            unprocLooper++;
            if(unprocLooper >= rowsToSkip && unprotectedLeadList.size() <50){
                unprotectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                        leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                        leadObj.Owner.Name, leadObj.id, leadObj.ownerId, inContactExt,
                        leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                        leadObj.Company, leadObj.Account__r.Name, null, null, leadObj.leadSource, leadObj.Account__r.RecordType.Name));
            }//CMR-233088 - added account name and account record type name
        }
        checkDisabled();
    }

    public Boolean isProtectedLead(Lead leadObj){
        Boolean rtn = false;
        if(leadObj.status != null
            && leadObj.recordTypeId != null
            && Schema.SObjectType.Lead.getRecordTypeInfosById()
            .get(leadObj.recordTypeId).getName() != null){
            if(((leadObj.status == '2. Contacted')
                && (leadObj.CreatedDate.Date() > Date.Today().addDays(-30))
                && Schema.SObjectType.Lead.getRecordTypeInfosById()
                    .get(leadObj.recordtypeid).getname() != 'Partner Leads')
                || (Schema.SObjectType.Lead.getRecordTypeInfosById()
                    .get(leadObj.recordtypeid).getname() == 'Partner Leads'
                    && leadObj.CreatedDate.Date() > Date.Today().addDays(-180))){
                rtn = true;
            }
        }
        return rtn;
    }

    /************END************/


    public Map<String, String> createEmployeeMap(Set<Id> ownerIds ) {
        Map<String, String> employeeExtMap = new  Map<String, String>();
        try {
            if(ownerIds != null && ownerIds.size()>0) {
                for(Employee__c empObj : [SELECT UserID18Digit__c,Extension__c from Employee__c where UserID18Digit__c IN : ownerIds]) {
                    if(empObj.UserID18Digit__c != null) {
                        employeeExtMap.put(empObj.UserID18Digit__c, empObj.Extension__c);
                    }
                }
            }
        } catch(Exception ex) { }
        return employeeExtMap;
    }

    public  string getOwnerId(string ownerId) {
        string strOwnerId = '';
        if((String.valueOf(ownerId)).startsWith('005')) {
            strOwnerId = ownerId;
        }
        return strOwnerId;
    }

    public boolean toShowWhoisDecisionMkr {get;set;}

    public void getDecisionMaker() {
        if(leadQualificationObj.Decision_Maker__c != null && leadQualificationObj.Decision_Maker__c == 'No') {
            toShowWhoisDecisionMkr = true;
        } else {
            toShowWhoisDecisionMkr = false;
        }
    }

    public boolean toShowMoreInfobudget {get;set;}

    public void showMoreInfoBudget() {
        if(!String.isBlank(leadQualificationObj.Budgeted__c)) {
            toShowMoreInfobudget = true;
        } else {
            toShowMoreInfobudget = false;
        }
    }

    //Claim Ownership
    public PageReference claimLeadOwnership(){
        try{
            String claimedLeadId = ApexPages.currentPage().getParameters().get('claimedLeadId');
            List<Lead> claimedLead = [SELECT id,Status from Lead where id=:claimedLeadId];
            if(claimedLead.size()>0){
                claimedLead[0].status='2. Contacted';
                claimedLead[0].OwnerId=Userinfo.getUserId();
                claimedLead[0].isOwnership_Claimed__c=true;
                claimedLead[0].inContact_Contact_ID__c=inContactId;
                claimedLead[0].inContact_Skill__c=skillName;
                claimedLead[0].Five9_DNIS__c=dnis;
                claimedLead[0].LeadSource='Inbound Call';
                upsert claimedLead;
            }
            PageReference newPage = new PageReference('/'+claimedLeadId).setRedirect(true);
            return newPage;
            } catch(DMLException dx) {
                ApexPages.addMessages(dx);
                return null;
            } catch(Exception ex) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                    'Error while processing the request. Please try later..!!');
                ApexPages.addMessage(myMsg);
            return null;
        }
    }

    /*
    Make sure that latest information has been searched with and that all fields are valid.
    Insert newLead and return page reference to it
    */
    public PageReference createNew(){
        leadSysSourceUrl = (String.isNotBlank(ApexPages.currentPage().getParameters().get('source')) ?
                                ApexPages.currentPage().getParameters().get('source')
                                : '');
        if (!leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) ){
            populateBMIDValueOnLead();
        }

        resetErrorVariables();
        resetFieldValue();
        emptyField = false;
        agentEmailChk=false;

        if (getIsSalesManagerInsideProfile() || getIsSaleAgentInsideProfile())  {
            if (checkLeadQualificationNotEmpty(getIsSaleAgentInsideProfile()) == false) {
                return null;
            }
        }

        if((newlead.LeadSource == LeadHelper.CAMPAIGNSALESGENERATED) && strSalesgenerated == 'None'){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                'You must select Sales Generated Source.');
                ApexPages.addMessage(myMsg);
                return null;
        }

        /**************************************************************************************************************
        @Date:27-Feb-2014
        @Description: Updating code to making No.ofEmployee field Required[Case no:02405171]
        @updateBy:India Team
        ****************************************************************************************************************/
        try {
            if((isEmpty(newLead.Employees_Override__c) && String.isBlank(newLead.LS_Company_Size_Range__c))){
                isEmployeeRequired = true;
            }
            if(isEmpty(newLead.Email)
                || isEmpty(newLead.Company)
                || isEmpty(newLead.LastName)
                || isEmpty(newLead.LeadSource)
                || isEmpty(newLead.Employees_Override__c)
                || newLead.Employees_Override__c == '--None--'
                || string.isBlank(newlead.Industry)){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                    'Please fill all Last Name, Company Name, Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.');
                    ApexPages.addMessage(myMsg);
                    emptyField = true;
                   if(isEmpty(newLead.Email)
                    || isEmpty(newLead.Company)
                    || isEmpty(newLead.LastName)
                    || isEmpty(newLead.LeadSource)) {
                        searched = false;
            }
                return null;
            }
        } catch(Exception e) {}
        /*************************************end************************************************************************/
        try {
            if(!isValidEmail(newLead.Email.trim()) ){
                emailNotFormated = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                'The email entered is not in a valid format.');
                ApexPages.addMessage(myMsg );
                searched = false;
                emptyField = false;
                return null;
            }
        } catch(Exception e) { }

        try {
            //Check for SolveThenSell if dnis is coming in URL
            if(dnis == '8775843307' && newLead.Agent_Email_Address__c == ''){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO,
                'Support Agent Email Address is required when a call is transferred into this phone #=8775843307.');
                ApexPages.addMessage(myMsg );
                searchFirst = false;
                agentEmailChk = true;
                return null;
            }
        } catch(Exception e) { }

        emptyField = false;
        emailNotFormated = false;
        if(searched != true){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
            'You must search first before creating a new lead.');
            ApexPages.addMessage(myMsg );
            searchFirst = true;
            return null;
        }
        system.debug('about to create lead');
        try {
            if(newLead.Email.trim()!=searchedem
                    || newLead.Phone.trim()!=searchedph
                    || newLead.Company.trim()!=searchedcomp
                    || newLead.FirstName.Trim()!=searchedfirst
                    || newLead.LastName.Trim()!=searchedlast
                    || newLead.LeadSource != searchedLeadSource){
                fieldsChanged = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO,
                'You must search again as fields have changed after your previous search attempt.');
                ApexPages.addMessage(myMsg );
                return null;
            }
         } catch(Exception e) {}

        string errorMsg = checkInputFieldLength();
        if(errorMsg != null && errorMsg != 'NoError') {
            ApexPages.Message myMsg;
            if(errorMsg == 'CompanyInfo') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Company Information.');
            } else if(errorMsg == 'PAIN') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Pain Information.');
            } else if(errorMsg == 'PAINImpact') {
                 myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Pain Impact Information.');
            }else if(errorMsg == 'GAIN') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Gain Information.');
            } else if(errorMsg == 'GAINImpact') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Gain Impact Information.');
            } else if(errorMsg == 'IDEASol') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Ideal Solution Information.');
            } else if(errorMsg == 'Benefits') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Benefit Information.');
            } else if(errorMsg == 'NextQues') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Next Steps Information.');
            } else if(errorMsg == 'OtherExplain') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Other Explanation.');
            } else if(errorMsg == 'Need') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 32000 characters on Need (SDR Information).');
            } else if(errorMsg == 'ProspectNeed') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 32000 characters on Need Additional Info.');
            } else if(errorMsg == 'NoOFEMP') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 255 characters on No Of Employees.');
            } else if(errorMsg == 'PhoneStart') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 255 characters on How many phone to start.');
            } else if(errorMsg == 'OtherNotes') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30,000 characters on Other Notes.');
            } else if(errorMsg == 'DecisionLargerProject') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 255 characters on Decision on Larger Projects.');
            } else if(errorMsg == 'MoreInfoBugdet') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 255 characters on More Info on Budgeted.');
            } else if(errorMsg == 'ContarctAdditionalInfo') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Contract Additional Info.');
            } else if(errorMsg == 'CurrentSystemAdditionalInfo') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Current System Additional Info.');
            } else if(errorMsg == 'TimeFrameAdditionalInfo') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Timeframe Additional Info.');
            } else if(errorMsg == 'DecisionMakersAdditionalInfo') {
                myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Please enter only upto 30000 characters on Decision Makers Additional Info.');
            }
            ApexPages.addMessage(myMsg);
            return null;
        }

        newLead.Lead_Score__c = 'A';
        newLead.ownerId=UserInfo.getUserId();
        newLead.Status='2. Contacted';

        //populate Notes from this field and set it to blank so that Notes
        newLead.Notes__c = leadQualificationObj.Other_Notes__c;
        String strNoteDescription = (newLead.Notes__c == null ? '' : newLead.Notes__c.trim());
        newLead.Description = strNoteDescription;
        newLead.Time_Frame__c = leadQualificationObj.Timeframe__c;


        try{
            if(!isEnriched && ((string.isNotBlank(newLead.FirstName) || string.isNotBlank(newLead.LastName)) && string.isNotBlank(newLead.Company))){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO,
                    'Enrichment not done. Please provide either First Name or Last Name, Email and Company Name then enrich again.');
                    ApexPages.addMessage(myMsg );
            }
            if(optionValue == 'YES'){
                copyEnrichData();
            }

            if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
                // scenario where Invoca record is created after the screenpop
                if (String.isBlank(ApexPages.currentPage().getParameters().get('InvocaId'))) {
                    Campaign doubleCheckCampaign = new Campaign();

                    invocaSelectorInstance = new InvocaSelector();
                    List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>)  invocaSelectorInstance
                        .selectInvocaRecordByCallerId(ApexPages.currentPage().getParameters().get('ani'))
                        .executeQuery();
                    invocaCallRecord = !invocaRecordsList.isEmpty()
                        ? invocaRecordsList[0]
                        : null;
                    if (invocaCallRecord != null) {
                        // this is almost the same as the constructor logic, as an improvemente move it to a method
                        newLead = (Lead) assignInvocaValues(newLead, invocaCallRecord, 'assignInvocaValues');
                        populateRCAccount(newLead);
                        if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                            doubleCheckCampaign = getCampaignFromInvocaCall(invocaCallRecord);
                            if (doubleCheckCampaign.Id != null) {
                                campObj = doubleCheckCampaign;
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            } else {
                                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            }
                        } else {
                            campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                            newLead.Most_Recent_Campaign__c = campObj.Id;
                        }
                    } else {
                        campObj = setCampaignByDNISOrderedByCreatedDate();
                        newLead.Most_Recent_Campaign__c = campObj.Id;
                    }
                } else {
                    invocaSelectorInstance = new InvocaSelector();
                    List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                        .selectInvocaRecordById(ApexPages.currentPage().getParameters().get('InvocaId'))
                        .executeQuery();
                    invocaCallRecord = !invocaRecordsList.isEmpty()
                        ? invocaRecordsList[0]
                        : null;
                }
            }

            if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) && invocaCallRecord != null) {
                phoneNumber = invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c == null ?
                            phoneNumber : invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c;
            }
            newLead.Phone = phoneNumber;
            if (String.IsNotBlank(ApexPages.currentPage().getParameters().get('dnis'))) {
                newLead.Five9_DNIS__c = ApexPages.currentPage().getParameters().get('dnis');
            }
            if (campObj != null && String.isNotBlank(campObj.Id)) {
                newLead.Primary_Campaign__c = campObj.Id;
            }
            newLead.Lead_Created_via_Smart_Search__c=true;//CMR-288769 Checking the flag true to identify smart search leads for gating
            insert newLead;
            leadCompanyProcessorSvcInstance.processAccountHierarchy(new List<Lead>{newLead}, null);
            if (invocaCallRecord != null) {
                invocaCallRecord.INVOCA_FOR_SF__Lead__c = newLead.Id;
                update invocaCallRecord;
            }
        }catch(Exception e){
            system.debug('Exception on Lead Insert '+e.getMessage()+'='+e.getLineNumber());
        }


        //create a Note only if There is some entry in Notes text field
        if(newLead.Id != null && strNoteDescription <> ''){
            Note objNote=new Note();
            objNote.Title='Notes from Original Call';
            objNote.Body=strNoteDescription;
            objNote.ParentId=newLead.Id;
            objNote.OwnerId=UserInfo.getUserId();
            insert objNote;
        }
        if(newLead.Id != null) {
            try {

                leadQualificationObj.lead__c = newLead.Id;

                /*****************For Bills project Starts***********************/
                string reasonsSave = '';
                for(string s : rightvalues){
                    if(reasonsSave == ''){
                        reasonsSave = reasonsSave.trim();
                        reasonsSave = s+';';
                    }else{
                        reasonsSave = reasonsSave+s+';';
                    }
                }
                leadQualificationObj.Reasons__c = reasonsSave;
				//Modified for PBC-17723 Rise 2.0 Access Controls
                if (newLead.Sub_Brand__c != null) {
                    leadQualificationObj.Brand_Identifier__c = newLead.Sub_Brand__c;
                } else if (newLead.BusinessIdentity__c != null) {
                    leadQualificationObj.Brand_Identifier__c = newLead.BusinessIdentity__c;
                } else {
                    leadQualificationObj.Brand_Identifier__c = newLead.Lead_Brand_Name__c;
                }
                leadQualificationObj.X50_249_Business_Drivers__c = selBusinessDriver ;
                /*****************For Bills project Ends***********************/
                 //-----------------------------Setting new values to current system info and Reasons, collected from page-------------
                leadQualificationObj = (Lead_Qualification__c)SaveDriverResons(leadQualificationObj);
                leadQualificationObj = (Lead_Qualification__c)saveCurrentSystemInfovalues(leadQualificationObj);
                /*****************For Bills project Ends***********************/

                //-----------------------------Setting new values to call flow models,features,usages starts-------------
                leadQualificationObj = (Lead_Qualification__c)saveCallFlowModelValues(leadQualificationObj);
                leadQualificationObj = (Lead_Qualification__c)saveFeaturesRequestdByCustomerValues(leadQualificationObj);
                leadQualificationObj = (Lead_Qualification__c)saveUsagesLevelvalues(leadQualificationObj);

                insert leadQualificationObj;
            } catch(Exception ex) {}
        }
        if(newLead.Id == null ) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The lead could not be created due to error occured!');
            ApexPages.addMessage(myMsg);
            return null;
        }

        PageReference leadPage = new ApexPages.StandardController(newLead).view();
        leadPage.setRedirect(true);
        return leadPage;
    }


    public PageReference cancel(){
        PageReference leadPage = new ApexPages.StandardController(new Lead()).view();
        leadPage.setRedirect(true);
        return leadPage;
    }

    public class ListResult implements Comparable{
        public String name {get; set;}
        public String email {get; set;}
        public String phone {get; set;}
        public String company {get; set;}
        public String stage {get; set;}
        public String dateCreated {get; set;}
        public String dateModified {get; set;}
        public String ownerName {get; set;}
        public String id {get; set;}
        public String incontactExtension {get;set;}
        public String ownerId {get;set;}
        public String dnis {get; set;}
        public String companySize {get; set;}
        public String companyName {get; set;}
        public String accountName {get; set;}
        public String accountRecordType {get; set;} /*CMR-221256 : Add account record type to smart search*/
        public String closedDate {get; set;}
        public String companyGrade {get; set;}
        public String leadSource {get; set;}
        public Integer modifiedYear {get; set;}
        public Integer modifiedMonth {get; set;}
        public Integer modifiedDay {get; set;}

        public ListResult(String contact, String email, String phone, String company, String stage, DateTime created,
            DateTime modified, String owner, String id, string OwnerId, string incontactExtension, string dnis,
            String companySize, String companyName, String accountName, DateTime closedDate, String companyGrade,
             String leadSource, String accountRecordType) {/*CMR-221256*/
            this.modifiedYear = (modified == null ? (Datetime.now()).year() : modified.year());
            this.modifiedMonth = (modified == null ? (Datetime.now()).month() : modified.month());
            this.modifiedDay = (modified == null ? (Datetime.now()).day() : modified.day());
            this.name = contact;
            this.email = email;
            this.phone = phone;
            this.company = company;
            this.stage = stage;
            this.dateCreated = (created == null ?  Datetime.now().format(USDATEFORMAT, USERLOCALE) : created.format(USDATEFORMAT, USERLOCALE));
            this.dateModified = (modified == null ? Datetime.now().format(USDATEFORMAT, USERLOCALE) : modified.format(USDATEFORMAT, USERLOCALE));
            this.ownerName = owner;
            this.id = id;
            this.incontactExtension = incontactExtension;
            this.ownerId = ownerId;
            this.dnis = dnis;
            this.companySize = companySize;
            this.companyName = companyName;
            this.accountName = accountName;
            this.accountRecordType = accountRecordType; /*CMR-221256 : Add account record type to smart search*/
            this.closedDate = (closedDate == null ? '' : closedDate.format(USDATEFORMAT));
            this.companyGrade = companyGrade;
            this.leadSource = leadSource;
        }

        public Integer compareTo(Object compareTo) {
            ListResult compareToOppy = (ListResult) compareTo;
            Integer returnValue = 0;
            Date dateModif;
            Date dateToCompare;
            dateModif =  Date.valueOf(this.modifiedYear + '-' + this.modifiedMonth + '-' + this.modifiedDay);
            dateToCompare =  Date.valueOf(compareToOppy.modifiedYear + '-' + compareToOppy.modifiedMonth + '-' + compareToOppy.modifiedDay);
            if (dateModif < dateToCompare) {
                returnValue = 1;
            } else if (dateModif > dateToCompare) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    /*
    Take a Opportunity and its related Contact
    Add Opportunity to correct list based on rules
    1. If Opp owner and current user are VP reps then list on partnerOpportunityList
    2. If Opportunities Account has a current owner list on partnerOpportunityList or opportunityList
    3. If Opportunity is ActivePipe or closed within last 4 days then add to opportunityNoCOList
    4. If Opportunity has VAR recordType, is not Downgraded or linked with Account with Status 'Paid' or null and that
        is not Canelled add to opportunityNoCOList. If Opportunity is Downgraded add to unprotectedOpportunityList
    5. Add all others to unprotectedOpportunityList
    */

    /*New Opt code on 11/14/2011  Updated on 16 August 2018 */

     public void addOpp(Opportunity oppObj, Contact contactObj) {

        if(!contactIdSet.contains(contactObj.Id)) {
            contactCampaignMap.put(contactObj.Id, contactObj.CampaignMembers);
            contactIdSet.add(contactObj.Id);
        }

        string incontactExtensionOPPOwner = '';
        string incontactExtensionAccountCurrentOwner = '';
        string strownerIdOPP = '';
        string strAccountCurrentOwnerId = '';

        list<CampaignMember> campaignMemList = contactCampaignMap.get(contactObj.Id);

        if (oppObj.RecordTypeName__c == 'VAR Opportunity') {
            if (oppObj.StageName == '0. Downgraded') {
                if (unprotectedOpportunityList.size() < 50) {
                    unprotectedOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                    contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                    oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, incontactExtensionOPPOwner, '', '', '',
                    oppObj.Account.Name, oppObj.CloseDate, null, null,oppObj.Account.Recordtype.Name));
                    oppUnProtectedListIdSet.add(oppObj.Id);
                }

            } else if (opportunityNoCOList.size() < 50) {
                opportunityNoCOList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                    contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                    oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, incontactExtensionOPPOwner, '', '', '',
                    oppObj.Account.Name, oppObj.CloseDate, null, null, oppObj.Account.Recordtype.Name));
                oppNoCOListIdSet.add(oppObj.Id);
            }
        } else if ((oppObj.Owner.UserRole.Name == USER_ROLE_NAME_VISTA_PRINT_US) && partnerRep == true &&
            OpportunityHelper.isActiveOpp(oppObj.StageName)) {

            if (!oppParterListIdSet.contains(oppObj.Id)) {
                parterOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                    contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                    oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, incontactExtensionOPPOwner, '', '', '',
                        oppObj.Account.Name, oppObj.CloseDate, null, null,''));
                oppParterListIdSet.add(oppObj.Id);
            }
        }
        else if ((oppObj.Account.Current_Owner__c != null) || (oppObj.CampaignId != null &&
            oppObj.Campaign.Protected_Campaign__c == true) || (campaignMemList != NULL && campaignMemList.size() > 0)) {

            if ((oppObj.Account.Current_Owner__c != null && USER_ROLE_NAME_VISTA_PRINT_US == oppObj.Account.Current_Owner__r.UserRole.Name)
                && partnerRep == true && OpportunityHelper.isActiveOpp(oppObj.StageName)) {
                if (!oppParterListIdSet.contains(oppObj.Id)) {
                    parterOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Account.Current_Owner__r.Name, oppObj.id, oppObj.Account.Current_Owner__c,
                        incontactExtensionAccountCurrentOwner, '', '', '',
                        oppObj.Account.Name, oppObj.CloseDate, null, null,''));
                    oppParterListIdSet.add(oppObj.Id);
                }
            } else {
                if (!oppListIdSet.contains(oppObj.Id) && opportunityList.size() < 50) {
                    opportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Account.Current_Owner__r.Name, oppObj.id, oppObj.Account.Current_Owner__c,
                        incontactExtensionAccountCurrentOwner, '', '', '',
                        oppObj.Account.Name, oppObj.CloseDate, null, null,oppObj.Account.Recordtype.Name));
                    oppListIdSet.add(oppObj.Id);
                }
            }
        }
        else if (OpportunityHelper.isActiveOpp(oppObj.StageName) || (OpportunityHelper.isClosedOpp(oppObj.StageName)
                    && oppObj.CloseDate > Date.today().addDays(-4))) {
            if (!oppNoCOListIdSet .contains(oppObj.Id)) {
                if (opportunityNoCOList.size() < 50) {
                    opportunityNoCOList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, incontactExtensionOPPOwner, '', '', '',
                        oppObj.Account.Name, oppObj.CloseDate, null, null,oppObj.Account.Recordtype.Name));
                    oppNoCOListIdSet.add(oppObj.Id);
                }
            }
        }
        else {
            if (!oppUnProtectedListIdSet.contains(oppObj.Id)) {
                if (unprotectedOpportunityList.size() < 50) {
                    unprotectedOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, incontactExtensionOPPOwner, '', '', '',
                        oppObj.Account.Name, oppObj.CloseDate, null, null,oppObj.Account.Recordtype.Name));
                    oppUnProtectedListIdSet.add(oppObj.Id);
                }
            }
        }
    }

    /*
    Same as addOpp except used for special circumstance
    Called by seach method.
    This is called if Opportunity was found through matching Account/Opportunity name as Company name without going through related Contact
    */
    public void addOppNoContact(Opportunity oppObj, Contact contactList) {
        if(contactList.Id != null) {
            if(!contactIdSet.contains(contactList.Id)) {
                contactCampaignMap.put(contactList.Id,contactList.CampaignMembers);
                contactIdSet.add(contactList.Id);
            }
            if(contactList != null && contactList.Id != null) {
                addOpp(oppObj, contactList);
            }
        }
    }

    public PageReference redirectPartnerUser() {
        PageReference rtnPage;
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        string recordTypeId =  ApexPages.currentPage().getParameters().get('RecordType');
        if(UserInfo.getUserType() == 'PowerPartner') {
            string partnerExProfileId = [select Id from Profile where Name = 'RC Partner Express' limit 1].id;
            if(UserInfo.getProfileId() == partnerExProfileId) {
                rtnPage = new PageReference('/apex/LeadCreationPartnerExpress');
            } else {
                rtnPage = new PageReference('/apex/LeadCreationPartner');
            }
            rtnPage.setRedirect(true);
            return rtnPage;
        } else {
            if(recordTypeId != null && rtMapByName.get(recordTypeId).getName() == 'Partner Leads') {
                rtnPage = new PageReference('/apex/LeadCreationPartnerVAR');
                string strRtnUrl = ApexPages.currentPage().getParameters().get('retURL');
                if(strRtnUrl != null) {
                    rtnPage.getParameters().put('rtnURL',strRtnUrl);
                }
                rtnPage.setRedirect(true);
                return rtnPage;
            } else {
                for(Schema.RecordTypeInfo rtInfo : rtMapByName.values()) {
                    if(rtInfo.isDefaultRecordTypeMapping() && rtInfo.getName() == 'Partner Leads') {
                        rtnPage = new PageReference('/apex/LeadCreationPartnerVAR');
                        string strRtnUrl = ApexPages.currentPage().getParameters().get('retURL');
                        if(strRtnUrl != null) {
                            rtnPage.getParameters().put('rtnURL',strRtnUrl);
                        }
                        rtnPage.setRedirect(true);
                        return rtnPage;
                    }
                }
            }
        }
        return null;
    }

    public String getcampaignName(){
        return campaignName;
    }

    public String getcampaignDescription(){
        return campaignDescription;
    }

    public Boolean getFieldsChangedAfterSearch(){
        return fieldsChanged;
    }

    public PageReference resetSearchfirst(){
        searchFirst=false;
        return ApexPages.currentPage();
    }

    public Boolean getOppResults(){
        if((searched==true) && (opportunityList.size()==0)){
            return true;
        }
        return false;
    }

    public Boolean getOppNoOCResults(){
        if((searched==true) && (opportunityNoCOList.size()==0)){
            return true;
        }
        return false;
    }

    public Boolean getPartnerOppResults(){
        if((searched==true) && (parterOpportunityList.size()!=0)){
            return true;
        }
        return false;
    }

    public Boolean getUnprotectedResults(){
        if((searched==true) && (unprotectedOpportunityList.size()==0)){
            return true;
        }
        return false;
    }

   public Boolean getLeadResults(){
        if((searched==true) && (leadList.size()==0)){
            return true;
        }
        return false;
    }

    public Boolean getUnProtectedLeadResults(){
        if((searched==true) && (unprotectedLeadList.size()==0)){
            return true;
        }
        return false;
    }

    public Boolean getShowUnprotectedLeadsList(){
        if((searched==true) && protectedLeadList.size()>0){
            return false;
        }
        return true;
    }

    public Boolean getProtectedLeadResults(){
        if((searched==true) && (protectedLeadList.size()==0)){
            return true;
        }
        return false;
    }

    public Boolean getEmptyField(){
        return emptyField;
    }

    //SolveThenSell
    public Boolean getagentEmailChk(){
        return agentEmailChk;
    }
    public Boolean getdnisChk(){
        return dnisChk;
    }
    //----

    public Boolean getSearched(){
        return searched;
    }

    public Boolean getEmptySearch(){
        return emptySearch;
    }

    public Boolean getEmailNotFormated(){
        return emailNotFormated;
    }

    public Boolean getPhoneNotFormated(){
        return phoneNotFormated;
    }

    public Boolean getSearchFirst(){
        return searchFirst;
    }

    public List<ListResult> getOpportunities(){
        return opportunityList;
    }

    public List<ListResult> getOpportunitiesNoCO(){
        return opportunityNoCOList;
    }

    public List<ListResult> getParterOpportunities(){
        return parterOpportunityList;
    }

    public List<ListResult> getUnprotectedOpportunities(){
        return unprotectedOpportunityList;
    }

    public List<ListResult> getLeadList(){
        return leadList;
    }

    public List<ListResult> getunprotectedLeadList(){
        return unprotectedLeadList;
    }

    public List<ListResult> getprotectedLeadList(){
        return protectedLeadList;
    }

    public Lead getnewLead(){
        return newLead;
    }

    public void setNewLead(Lead l){
        this.newLead = l;
    }

    //------------------------------------------code for Business Drivers and Reasons dependency,user interaction nd for save starts-----------------------

    //------------------------------------------Generalize method to get picklist values from an object's field-------------------------

    public List<Schema.PicklistEntry> getPickListValueFromObject(String objName,String FieldName){
      List<Schema.PicklistEntry> picklistValues = new List<Schema.PicklistEntry>();
      String[] types = new String[]{objName};
      Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
      Schema.DescribeSobjectResult res = results[0];
      picklistValues =   res.fields.getMap().get(FieldName).getDescribe().getPicklistValues();
      return picklistValues;
   }    //-------------------------------------------------------------As/simplion/for 4/17/2014 end----------------------------------------------
    //-------------------------------------------------------Method to set All varriable values in the BussinessDriverReasonClass starts-------------------------------

    //-------------------------------------------------------Method to set All varriable values in the BussinessDriverReasonClass Ends-------------------------------

    public List<String> getBusinessAgilitySelectedResons {get;set;}
    public List<String> getBusinessresponsivenessSelectedResons {get;set;}
    public List<String> getBusinessVendorSelectedResons {get;set;}
     //-------------------------------------------------List giving All Reasons related to Agility Driver Starts-------------------------------------------------------------------
    public List<SelectOption> getBusinessAgilityResons {get{
         getBusinessAgilityResons = new List<SelectOption>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Business_Change_Reasons__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
             if(reasonEntry.getLabel() != 'Hard to adapt to business changes') {
                getBusinessAgilityResons.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
             }
         }
         return getBusinessAgilityResons;
    }set;}
    //-------------------------------------------------List giving All Reasons related to Agility Driver Ends-------------------------------------------------------------------
    //-------------------------------------------------List giving All Reasons related to Responsiveness Driver starts-------------------------------------------------------------------
    public List<SelectOption> getBusinessresponsivenessResons{get{
         getBusinessresponsivenessResons = new List<SelectOption>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Customer_Responsiveness_Reasons__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
             if(reasonEntry.getLabel() != 'Call transfers slow and difficult') {
                getBusinessresponsivenessResons.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
             }
         }
         return getBusinessresponsivenessResons;
    }set;}
    //-------------------------------------------------List giving All Reasons related to Responsiveness Driver Ends-------------------------------------------------------------------
    //-------------------------------------------------List giving All Reasons related to Vendor Driver starts-------------------------------------------------------------------
    public List<SelectOption> getBusinessVendorResons {get{
         getBusinessVendorResons = new List<SelectOption>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Dissatisfaction_with_Current__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
             if(reasonEntry.getLabel()!= 'Complex to manage and change' && reasonEntry.getLabel() != 'Costly to manage'
                                && reasonEntry.getLabel() != 'Outside IT service provider issues') {
                getBusinessVendorResons.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
             }
         }
         return getBusinessVendorResons;
    }set;}

    //-------------------------------------------------List giving All Reasons related to Vendor Driver Ends-------------------------------------------------------------------
    public static String getMultipickListString( List<String> valueList){
          String valueString = '';
          if(valueList.size() >0){
             for(String temp : valueList){
                valueString += temp+';';
             }
             valueString = valueString.Substring(0,valueString.length()-1);
          }
          return valueString;
     }

    //-----------------------------------------------Method to save Drivers and Resons multipicklist values to Record starts------------------------------------
    public Lead_Qualification__c SaveDriverResons(Lead_Qualification__c objectinstance){
        List<String> driverListToSave = new List<String>();
        if(getBusinessAgilitySelectedResons.size()>0){
           driverListToSave.add('Business Growth, Change, Agility');
        }
        if(getBusinessresponsivenessSelectedResons.size()>0){
           driverListToSave.add('Improved customer responsiveness');
        }
        if(getBusinessVendorSelectedResons.size()>0){
           driverListToSave.add('Dis-satisfied with current vendor');
        }

        //----------------------------------------------Code to seperate reason save according to users selection---------------------
        String driverString = '';
        String businessChangeResonsString ='';
        String customerResponsivenessResonsString = '';
        String dissatisfactionwithCurrentResonsString = '';
        businessChangeResonsString = getMultipickListString(getBusinessAgilitySelectedResons);
        customerResponsivenessResonsString = getMultipickListString(getBusinessresponsivenessSelectedResons);
        dissatisfactionwithCurrentResonsString = getMultipickListString(getBusinessVendorSelectedResons);
        driverString = getMultipickListString(driverListToSave);
        if(objectinstance != null){
            objectinstance.Business_Driver__c = driverString;
            objectinstance.Business_Change_Reasons__c = businessChangeResonsString;
            objectinstance.Customer_Responsiveness_Reasons__c = customerResponsivenessResonsString;
            objectinstance.Dissatisfaction_with_Current__c = dissatisfactionwithCurrentResonsString;
         }
        return objectinstance;
    }
    //-----------------------------------------------Method to save Drivers and Resons multipicklist values to Record Ends------------------------------------

    //-----------------------------------------------Wrapper class to manage All Dependencies between two multipicklist's starts-------------------------------------
    //-----------------------------------------------Wrapper class to manage All Dependencies between two multipicklist's Ends-------------------------------------

    //---------------------------------------------------code for Business Drivers and Reasons dependency,user interaction nd for save Ends-------------------------------------
    //---------------------------------------------------Code for Handeling All Functionality of Current System Information gatering and updation starts------------------------
    public List<String> getSelectedCurrentSystemInfo{get;set;}
    //-------------------------------------------------property giving all the picklist values of current system info field------------------------------------------------
    public List<Selectoption>  getAllCurrentSystemInfoValues {get{
        List<Selectoption> currentSystemInfo =new List<Selectoption>();
        List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','CurrentSystemInfo__c');
        for(Schema.Picklistentry reasonEntry : pickListValues){
            currentSystemInfo.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
        }
        return currentSystemInfo;
      }set;
    }
    //-------------------------------------------------Method to save new updated values of current system info to database------------------------------------------------
    public Lead_Qualification__c saveCurrentSystemInfovalues(Lead_Qualification__c objectInstance){
        String currentSystemInfString ='';
        currentSystemInfString = getMultipickListString(getSelectedCurrentSystemInfo);
        objectInstance.CurrentSystemInfo__c = currentSystemInfString;
        return objectInstance;
    }

    //------------------------------------------Code for Handeling All Functionality of Current System Information gatering and updation ends------------------------

    //-------------------------------------------------------------As/simplion/for 4/17/2014 start----------------------------------------------





    //--------------------------------------------Code section to controll new lead Qualification information section starts---------------------------------
    //-----------------------List containing users selection
     public List<String> getSelectedCallFlowModelValues{get;set;}
     public List<String> getSelectedFeaturesRequestdByCustomerValues{get;set;}
     public List<String> getSelectedUsagesLevelValues{get;set;}


    //List containing all the picklist values in the Call_Flow_Models_Features__c field in Lead_Qualification__c object
    public List<ModelValueBindingsClass> getCallFlowModelValues{get{
         getCallFlowModelValues = new List<ModelValueBindingsClass>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Call_Flow_Models_Features__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
                getCallFlowModelValues.add(new ModelValueBindingsClass(false,reasonEntry.getLabel()));
         }
         return getCallFlowModelValues;
    }set;}

    public Map<Integer,String> getCallFlowModelValues2{get{
         getCallFlowModelValues2 = new Map<Integer,String>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Call_Flow_Models_Features__c');
         Integer countval = 0;
         for(Schema.Picklistentry reasonEntry : pickListValues){
                getCallFlowModelValues2.put(countval++,reasonEntry.getLabel());
         }
         return getCallFlowModelValues2;
    }set;}

    //List containing all the picklist values in the Features_Requested_by_Customer__c field in Lead_Qualification__c object
    public List<SelectOption> getFeaturesRequestdByCustomerValues{get{
         getFeaturesRequestdByCustomerValues = new List<Selectoption>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Features_Requested_by_Customer__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
                getFeaturesRequestdByCustomerValues.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
         }
         return getFeaturesRequestdByCustomerValues;
    }set;}

    //List containing all the picklist values in the Usage_Levels__c field in Lead_Qualification__c object
    public List<SelectOption> getUsagesLevelValues{get{
         getUsagesLevelValues = new List<Selectoption>();
         List<Schema.Picklistentry> pickListValues = getPickListValueFromObject('Lead_Qualification__c','Usage_Levels__c');
         for(Schema.Picklistentry reasonEntry : pickListValues){
                getUsagesLevelValues.add(new SelectOption(reasonEntry.getLabel(),reasonEntry.getLabel()));
         }
         return getUsagesLevelValues;
    }set;}

    //------------------------------------Methods saving users selection to the lead_Qualification Object starts-------------------------------
    public Lead_Qualification__c saveCallFlowModelValues(Lead_Qualification__c objectInstance){
        String callFlowModelValueString ='';
        if(!string.isBlank(ApexPages.currentPage().getParameters().get('modelValue'))){

            callFlowModelValueString = ApexPages.currentPage().getParameters().get('modelValue');
        }

        objectInstance.Call_Flow_Models_Features__c = callFlowModelValueString;
        return objectInstance;
    }

     public Lead_Qualification__c saveFeaturesRequestdByCustomerValues(Lead_Qualification__c objectInstance){
        String FeaturesString ='';
        FeaturesString = getMultipickListString(getSelectedFeaturesRequestdByCustomerValues);
        objectInstance.Features_Requested_by_Customer__c = FeaturesString;
        return objectInstance;
    }

     public Lead_Qualification__c saveUsagesLevelvalues(Lead_Qualification__c objectInstance){
        String usagesLevelString ='';
        usagesLevelString = getMultipickListString(getSelectedUsagesLevelValues);
        objectInstance.Usage_Levels__c = usagesLevelString;
        return objectInstance;
    }
    //------------------------------------Methods saving users selection to the lead_Qualification Object ends-------------------------------

    public class ModelValueBindingsClass{
        public boolean isSelected{get;set;}
        public String value{get;set;}

        public ModelValueBindingsClass(boolean ischeck,String val){
            isSelected = ischeck;
            value = val;
        }
    }

    //------------------------------------section to controll dependency of call flow model,usage level and feature requested by customer starts-------------------------------

    public class Model_Usage_featureDependencyClass{

        public String ParentName{get;set;}
        public boolean isUsageLevel{get;set;}
        public List<String> childList{get;set;}

        public Model_Usage_featureDependencyClass(){
            ParentName = '';
            isUsageLevel = false;
            childList = new List<String>();

        }
    }

    private void setModelUsageFeatureDependencyClass(){
        Model_Usage_featureDependencyClass model_Usage_featureDependencyCls;
        List<CallFlow_usageAndFeaturesRelationship__c> CallFlow_usage_featuresList = CallFlow_usageAndFeaturesRelationship__c.getAll().values();
        Model_Usage_featureDependencyClassMap = new Map<String,Model_Usage_featureDependencyClass>();
        String modelValue = '';
        for(ModelValueBindingsClass s : getCallFlowModelValues){
                modelValue = s.value;
                Set<String> tempset;
            for(CallFlow_usageAndFeaturesRelationship__c relationvalue : CallFlow_usage_featuresList){

                if(!string.isBlank(relationvalue.Call_Flow_Model__c)){
                    tempset =  new Set<String>(relationvalue.Call_Flow_Model__c.split(';'));
                    if(tempset.contains(modelValue)){

                        if(Model_Usage_featureDependencyClassMap.keyset().contains(modelValue)){
                             model_Usage_featureDependencyCls = Model_Usage_featureDependencyClassMap.get(modelValue);
                             model_Usage_featureDependencyCls.childList.add(relationvalue.childName__c);
                        }
                        else{
                            model_Usage_featureDependencyCls = new Model_Usage_featureDependencyClass();
                            model_Usage_featureDependencyCls.ParentName = modelValue;
                            model_Usage_featureDependencyCls.childList.add(relationvalue.childName__c);
                            model_Usage_featureDependencyCls.isUsageLevel = relationvalue.isUsages__c;
                            Model_Usage_featureDependencyClassMap.put(modelValue,model_Usage_featureDependencyCls);
                        }
                    }
                }
            }
        }
    }

    public String getDependencyList{get{
        setModelUsageFeatureDependencyClass();
        return JSON.serialize(Model_Usage_featureDependencyClassMap);
    }set;}

    public void copyEnrichData(){
        if(string.isNotBlank(newLead.LS_Title__c)){
            newLead.Title = newLead.LS_Title__c;
        }
        if(string.isNotBlank(newLead.LS_Site__c)){
            newLead.Company = newLead.LS_Site__c;
        }
        if(string.isNotBlank(newLead.LS_Company_Industry__c) && industrySet.contains(newLead.LS_Company_Industry__c.toUpperCase())){
            newLead.Industry = newLead.LS_Company_Industry__c;
        }
        if(string.isBlank(numOfEmployees) || numOfEmployees == 'No. of Employees'){
            numOfEmployees = string.valueOf(integer.valueOf(newLead.LS_Company_Size__c));
        }
        if(string.isBlank(newLead.Website) || newLead.website == 'Website'){
            newLead.website = newLead.LS_Company_Website__c;
        }
        resetFieldValue();
    }

    public set<string> getPickValues(Sobject object_name, String field_name) {
        Set<string> picklistValueSet = new Set<String>();
        Schema.sObjectType sobject_type = object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            picklistValueSet.add(a.getValue().toUpperCase());
        }
        return picklistValueSet;
    }

    public PageReference claimUnprotectedLeadOwnership() {
        String leadId = ApexPages.currentPage().getParameters().get('claimedUpLeadId');
        String dnis = ApexPages.currentPage().getParameters().get('claimedUpLeadDnis');
        leadSysSourceUrl = (String.isNotBlank(ApexPages.currentPage().getParameters().get('source') ) ?
                            ApexPages.currentPage().getParameters().get('source') : '');

        Boolean isConsole = false;
        if(!String.isBlank(ApexPages.currentPage().getParameters().get('claimedUpLeadIsConsole'))){
            isConsole = Boolean.valueOf(ApexPages.currentPage().getParameters().get('claimedUpLeadIsConsole'));
        }
        System.debug('dnis:::' + dnis);
        System.debug('leadId:::' + leadId);
        System.debug('isConsole:::' + isConsole);
        System.debug('source:::' + leadSysSourceUrl);
        System.debug('newLead.LeadSource:::' + newLead.LeadSource);

        Boolean flagForDTRecordWithNullBMID = false;
        Lead leadToUpdate = (Lead) new LeadSelector()
            .selectLeadWithCampaignFields(new List<Object>{leadId})
            .executeQuery()
            .get(0);
        if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) ){
            invocaSelectorInstance = new InvocaSelector();
            List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = new List<INVOCA_FOR_SF__Invoca_Call_Log__c>();
            if (String.isNotBlank(invocaTransactionId)) {
                invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                    .selectInvocaRecordById(invocaTransactionId)
                    .executeQuery();
            } else {
                invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                    .selectInvocaRecordByCallerId(phoneNumber)
                    .executeQuery();
            }
            invocaCallRecord = !invocaRecordsList.isEmpty()
                    ? invocaRecordsList[0]
                    : null;
            if (invocaCallRecord != null) {
                if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                    campObj = getCampaignFromInvocaCall(invocaCallRecord);
                    if (String.isBlank(campObj.Id)) {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                    }
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                    flagForDTRecordWithNullBMID = true;
                }
            } else {
                campObj = setCampaignByDNISOrderedByCreatedDate();
            }
            if(String.isBlank(campObj.Id) ){
                errorRelatedItemOps = 'Error taking ownership, campaign not found for InvocaId: '+ invocaTransactionId;
                return null;
            }

            List<CampaignMember> cms = [SELECT Id
                                        FROM CampaignMember
                                        WHERE CampaignId =: campObj.Id AND LeadId =: leadToUpdate.Id];
            if (cms.size() == 0) {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campObj.Id;
                cm.LeadId = leadToUpdate.Id;
                insert cm;
            }

            if (invocaCallRecord!= null) {
                leadToUpdate = (Lead) assignInvocaValues(leadToUpdate, invocaCallRecord, 'assignInvocaValues');
                populateRCAccount(leadToUpdate);
            }
            leadToUpdate.OwnerId = UserInfo.getUserId();

            if (!flagForDTRecordWithNullBMID || (flagForDTRecordWithNullBMID && String.isBlank(leadToUpdate.BMID__c))) {
                leadToUpdate.Most_Recent_Campaign__c = campObj.Id;
                leadToUpdate.Primary_Campaign__c = campObj.Id;
            }

            if (String.IsNotBlank(dnis)) {
                leadToUpdate.Five9_DNIS__c = dnis;
            }
            update leadToUpdate;
            PageReference ref =  new PageReference('/' + leadId);
            ref.setRedirect(true);
            return ref;
        } else if (dnis != null && dnis != '' && newLead.LeadSource == 'Inbound Call') {
            List<Campaign> campaigns = [SELECT DNIS__c, AID__c, BMID__c, PID__c, Id
                FROM Campaign WHERE DNIS__c =: dnis];

            if(campaigns.size() == 0){
                errorRelatedItemOps = 'Error taking ownership, campaign not found for dnis:' + dnis;
                return null;
            }

            Campaign cmp = campaigns.get(0);
            leadToUpdate.Five9_DNIS__c = cmp.DNIS__c;
            leadToUpdate.AID__c = cmp.AID__c;
            leadToUpdate.BMID__c = cmp.BMID__c;
            leadToUpdate.PID__c = cmp.PID__c;
            leadToUpdate.Most_Recent_Campaign__c = cmp.Id;
            leadToUpdate.LeadSource = 'Inbound Call';
            leadToUpdate.OwnerId = UserInfo.getUserId();

            List<CampaignMember> cms = [SELECT Id
                FROM CampaignMember
                WHERE CampaignId =: cmp.Id AND LeadId =: leadToUpdate.Id];
            if (cms.size() == 0) {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = cmp.Id;
                cm.LeadId = leadToUpdate.Id;
                insert cm;
            }

            update leadToUpdate;

            PageReference ref =  new PageReference('/' + leadId);
            ref.setRedirect(true);
            return ref;

        } else if(isConsole) {
            if(updateLeadFromAgentChat(leadId, campaignName, campObj, newLead)){
                PageReference ref =  new PageReference('/' + leadId);
                ref.setRedirect(true);
                return ref;
            }
        } else {
            errorRelatedItemOps = 'Error taking ownership, not applicable: LeadSource:' + newLead.LeadSource +
                ' ,dnis:' + dnis + ' ,leadId:' + leadId + ' ,isConsole:' + isConsole;
        }

        return null;
    }

    @TestVisible
    private Boolean updateLeadFromAgentChat(String LeadId, String campaignName, Campaign campObj, Lead newLead) {
        List<Campaign> campaigns = new List<Campaign>();

        if ( !isEmpty( campObj.Id ) ) {
            campaigns = [SELECT Id, DNIS__c, AID__c, BMID__c, PID__c FROM Campaign WHERE Id = :campObj.Id ];
        } else {
            campaigns = [SELECT Id, DNIS__c, AID__c, BMID__c, PID__c FROM Campaign WHERE Name = :campaignName ];
        }

        if(campaigns.isEmpty()){
            errorRelatedItemOps = 'Error taking ownership, campaign not found for id:' + campObj.Id +
                ' ,name:' + campaignName;
        }

        if ( !campaigns.isEmpty() ) {
            Lead ld = [SELECT Id FROM Lead WHERE Id = :LeadId ];
            Campaign cmp = campaigns.get(0);

            ld.Most_Recent_Campaign__c = cmp.Id;
            ld.LeadSource = newLead.LeadSource;
            ld.Chat_Key__c = newLead.Chat_Key__c;
            ld.OwnerId = UserInfo.getUserId();

            List<String> paramsList = inboundChatParams.split(SEPARATOR);
            parseFieldsToObject(ld, splitIntoFields(new Map<String,String>(), paramsList));

            List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE CampaignId = :cmp.Id AND LeadId = :ld.Id];
            if ( cms.isEmpty() ) {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = cmp.Id;
                cm.LeadId = ld.Id;

                insert cm;
            }

            update ld;
            return true;
        }
        return false;
    }

    //-------------section to controll dependency of call flow model,usage level and feature requested by customer ends-----/
    //-------------Code section to controll new lead Qualification information section ends---------------------------------/
    public Boolean getIsSalesManagerInsideProfile() {
        return this.CurrentUserProfileId == PROFILE_ID_SALES_MANAGER_INSIDESALES;
    }

    public Boolean getIsSaleAgentInsideProfile() {
        return (this.CurrentUserProfileId == PROIFLE_ID_SALES_AGENT_SDR_W_INSIDESALES || 
                this.CurrentUserProfileId == PROFILE_ID_SALES_AGENT_SDR_W_INSIDESALES_EU_RESTRICTED //--- Added as part of EU Privacy Phase 3 Sales Profiles Changes
               );
    }

    public Boolean checkLeadQualificationNotEmpty(Boolean verifyOnlyNextSteps) {
        Boolean result = true;
        if (verifyOnlyNextSteps == false) {
            result &= String.IsNotBlank(leadQualificationObj.Current_Situation__c);
            result &= String.IsNotBlank(leadQualificationObj.Problems__c);
            result &= String.IsNotBlank(leadQualificationObj.Decision_Making_Process__c);
        }
        result &= String.IsNotBlank(leadQualificationObj.NextSteps__c);

        if (!result) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'One of the required(*) fields has not been filled in.'));
        }

        return result;
    }

    public void enableButtons(){
        searchButtonDisabled = false;
        createNewLeadButtonDisabled = false;
    }

    private static Campaign getCampaignFromInvocaCall(INVOCA_FOR_SF__Invoca_Call_Log__c invocaCallFromInvocaID){

        CampaignWrapper campaignWrapperDT = new CampaignWrapper(null, invocaCallFromInvocaID.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, null, null, null, false); // AID, BMID, PID, DNIS, Primary Campaign, isPartnerLead, criteriaToCamapaignMap

        Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogic(campaignWrapperDT,
            CampaignAssignmentHelper.findCampaingsLogic(new List<CampaignWrapper>{campaignWrapperDT}) );

        return (campaignObj != null ?
                    campaignObj :
                    new Campaign() );
    }

    public Campaign setCampaignByDNISOrderedByCreatedDate() {
        CampaignSelector campaignSelector = new CampaignSelector();
        Campaign campObj = new Campaign();
        List<Campaign> campaignList = new List<Campaign>();
        String pageDNIS = ApexPages.currentPage().getParameters().get('dnis');
        if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
            if (!String.isBlank(pageDNIS)) {
                campaignList = campaignSelector.selectCampaignForLeadSearch_ByCreatedDate(new List<Object>{
                    pageDNIS
                })
                    .executeQuery();
                if (campaignList.isEmpty()) {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
                } else {
                    campObj = campaignList[0];
                }
            } else {
                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
            }
        }
        return campObj;
    }

	private void fillUserId(){
        this.userId = UserInfo.getUserId();
    }
    
}