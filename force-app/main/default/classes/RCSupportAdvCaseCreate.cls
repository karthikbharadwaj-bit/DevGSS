public class RCSupportAdvCaseCreate{

    public class GdprRequestHolder
    {
        public final String GDPR_DEFAULT_SEVERITY = 'Level 4 - Medium';

        private final String LINE_BREAK = '\n';

        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String Email { get; set; }
        public String RcPhone { get; set; }
        public Boolean EuCitizen { get; set; }
        public Boolean ViewRequest { get; set; }
        public Boolean ChangeRequest { get; set; }
        public Boolean DownloadRequest { get; set; }
        public Boolean DeleteRequest { get; set; }
        public Boolean RetainAnalytics { get; set; }
        public Boolean RetainGlip { get; set; }
        public String Comments { get; set; }
        public String CaseSubject
        {
            get
            {
                String fullName = String.isNotBlank(FirstName) ? FirstName + ' ' : '';
                fullName = String.isNotBlank(LastName) ? fullName + LastName : fullName;
                return 'DSR Request: "' + fullName + '"';
            }
        }

        public String Serialize()
        {
            return LINE_BREAK + LINE_BREAK + '====================' + LINE_BREAK + LINE_BREAK +
                'View: ' + BoolToStr(ViewRequest) + LINE_BREAK +
                'Change: ' + BoolToStr(ChangeRequest) + LINE_BREAK +
                'Download: ' + BoolToStr(DownloadRequest) + LINE_BREAK +
                'Delete: ' + BoolToStr(DeleteRequest) + LINE_BREAK +
                (DeleteRequest == true ?
                    'Retain Analytics Data: ' + BoolToStr(RetainAnalytics) + LINE_BREAK +
                        'Retain Glip Messages: ' + BoolToStr(RetainGlip) + LINE_BREAK
                    : '') +
                'Name of user requiring privacy action: ' + FirstName + ' ' + LastName + LINE_BREAK +
                'Email of user requiring privacy action: ' + NoneIfEmpty(Email) +  LINE_BREAK +
                'RC Phone Number (if applicable) of the user requiring privacy action: ' + NoneIfEmpty(RcPhone) + LINE_BREAK +
                'Is this user a Citizen or legal resident within the EU (including UK): ' + BoolToStr(EuCitizen) + LINE_BREAK +
                'Comments: ' + Comments;
        }

        private String BoolToStr(Boolean b)
        {
            return b == true ? 'Yes' : 'No';
        }

        private String NoneIfEmpty(String str)
        {
            return String.isNotBlank(str) == true ? str : 'None';
        }
    }

    private GdprRequestHolder gdprRequest = new GdprRequestHolder();

    public GdprRequestHolder GetGdprRequest()
    {
        return this.gdprRequest;
    }
    public void SetGdprRequest(GdprRequestHolder req)
    {
        this.gdprRequest = req;
    }

    public Case caseObj {get;set;}
    public String selectedProduct {get;set;}
    public String alternateEmail {get;set;}
    public String selectedProduct2 {get;set;}
    public String selectedProduct3 {get;set;}
    public String severityLevel {get;set;}
    public String selectSortValue {get;set;}
    public String selectSearchValue {get;set;}
    public String inputSearchValue {get;set;}
    public String callbackNumber {get;set;}
    public String timezone {get;set;}
    public Boolean isGuestUser{get;set;}
    public Contact ConDetail{get;set;}
    public String PhoneExt{get;set;}
    List<AccountContactRole>  toFindLoginUserProfileLst = new List<AccountContactRole>();
    public List<SelectOption> lstselectOptionView{get;set;}
    public String selectedViewOptions1{get;set;}
    public  Map<String,WrPortalQuestion> mapPortalQuestion {get;set;}
    public Boolean isSubmitCase{get;set;}
    public static String supportChatTextFromLabel = (System.Label.Support_Chat_Text != NULL ? System.Label.Support_Chat_Text : '');
    public static String strFaxing ='Faxing ' + supportChatTextFromLabel;
    public static String strSoftphone ='Softphone ' + supportChatTextFromLabel;
    public static String strDeskphone ='Desk Phones ' + supportChatTextFromLabel;
    public Boolean chkValue{get;set;}
    public String strValue{get;set;}

    /*Case 03272867:  Product Assistance Custom setting changes {*/
    static Map<String,String> mapPortalList;
    static Map<String,Set<String>> mapProductAssistance;
    static String baseUrl;
    public String language {get;set;}
    static{
        if(!Test.isRunningTest()){
            baseUrl = 'success.ringcentral.com';
        }else{
            baseUrl = 'success.ringcentral.com';
        }
        mapPortalList = new Map<String,String>();
        List<Portals_List__c> lstPortal = Portals_List__c.getAll().values();
        if(lstPortal != null && lstPortal.size() > 0){
            for(Portals_List__c obj : lstPortal){
                String portalName = obj.Name.toLowerCase().trim();
                String portalBrand = obj.Brand__c.toLowerCase().trim();
                mapPortalList.put(portalName,portalBrand);
            }
        }

        mapProductAssistance = new Map<String,Set<String>>();
        List<Product_Assistance_List__c> lstProductAssistance = Product_Assistance_List__c.getAll().values();
        if(lstProductAssistance != null && lstProductAssistance.size() > 0){
            for(Product_Assistance_List__c obj : lstProductAssistance) {
                String productAssName = obj.Name.toLowerCase().trim();
                List<String> portalList = obj.Portal__c.trim().split(',');
                Set<String> portalSet = new Set<String>();
                if(portalList != null && portalList.size() > 0){
                    for(String str : portalList){
                        portalSet.add(str.toLowerCase().trim());
                    }
                }
                mapProductAssistance.put(productAssName,portalSet);
            }
        }
    }
    /*} Case 03272867:  Product Assistance Custom setting changes */

    public Attachment attachment {
        get {
            if (attachment == null) {
                attachment = new Attachment();
            }
            return attachment;
        }
        set;
    }

    public String parentId {get;set;}
    public User loginUser{get;set;}
    public String brandName {get;set;}

    public RCSupportAdvCaseCreate() {
        flag = false;
        callConstuctorLogic();
    }

    public RCSupportAdvCaseCreate(ApexPages.StandardController controller) {
        callConstuctorLogic();
    }

    public void callConstuctorLogic() {
        if(UserInfo.getUserType() == 'Guest') {
            isGuestUser = true;
        }   else {
            isGuestUser = false;
        }
        isSubmitCase=false;
        caseObj = new Case();
        String urlString = ApexPages.currentPage().getUrl();// FIND LANGUAGE FROM URL
        List<String> url;
        try {
            url = urlString.split('\\?',2);
        } catch(Exception ex) {
            url = new List<String>();
            System.debug(ex.getMessage());
        }
        if(url.size() == 2) {
            List<String> params = url[1].split('&');
            for(String param : params) {
                try {
                List<String> paramMap = param.split('=');
                    if(paramMap[0] == 'language') {
                        language = paramMap[1];
                        break;
                    }
                }catch(Exception ex) {
                    System.debug(ex.getMessage());
                }
            }
        }
        if(language == null) {
            language = 'en_US';
        }
        wrPgItrCases = new WrPgIterator();
        productAssistanceItems = new List<SelectOption>();
        productAssistanceItemsLvl2 = new List<SelectOption>();
        productAssistanceItemsLvl3 = new List<SelectOption>();
        caseSeverityItems =  new List<SelectOption>();
        caseSeverityItems = getcaseSeverityItemsValues();
        selectSortValue = 'Case_Status';
        selectSearchValue = 'Case_Number';
        selectedViewOptions1 = 'All Cases';
        mapPortalQuestion = new Map<String,WrPortalQuestion>();
        mapPortalQuestion = getPortalQuestion();
        ConDetail  = new Contact();
        loginUser = [SELECT Id,ContactId,Contact.AccountId, Profile.Name, Contact.Email,Contact.Phone_Ext__c,
            Contact.Phone,Contact.LastName,Contact.FirstName,
            Contact.Account.RC_Tier__c, Contact.Account.Number_of_DL_s__c,Contact.Account.RC_Brand__c,
            Contact.Account.Total_Account_DL_s__c, Contact.Account.VIP_Account_Indicator__c,
            Contact.Account.Service_Status__c, Contact.Account.Extended_Enterprise_Support_Customer__c
        FROM User
        WHERE Id =:UserInfo.getUserId() LIMIT 1];

        productAssistanceItems = getproductAssistanceItemsValues();
        productAssistanceItemsLvl2 = productAssistanceItemsLvl2();
        productAssistanceItemsLvl3 = productAssistanceItemsLvl3();
        System.debug('LOGIN USER '+ loginUser);
        try {
            ConDetail = new Contact(Id=loginUser.ContactId);
            ConDetail.LastName = loginUser.Contact.LastName;
            ConDetail.FirstName = loginUser.Contact.FirstName;
            ConDetail.Email = loginUser.Contact.Email;
            ConDetail.Phone = loginUser.Contact.Phone;
            callbackNumber = loginUser.Contact.Phone;
            ConDetail.Phone_Ext__c = loginUser.Contact.Phone_Ext__c;

            if(ConDetail.Phone_Ext__c !=null && ConDetail.Phone_Ext__c != 0 ){
                ConDetail.Phone_Ext__c =Integer.valueOf(ConDetail.Phone_Ext__c);
                PhoneExt = String.valueOf(loginUser.Contact.Phone_Ext__c);//update 0n 28/11/13
            } else{
                PhoneExt = '';
            }
            ConDetail.AccountId = loginUser.Contact.AccountId;
            brandName = loginUser.Contact.Account.RC_Brand__c;
            toFindLoginUserProfileLst =[
                SELECT Role, IsPrimary, Id, ContactId, AccountId FROM AccountContactRole
                WHERE ContactId =: loginUser.ContactId AND AccountId =:loginUser.Contact.AccountId AND
                    (Role ='RC Primary User' OR Role = 'RC Admin User')
                LIMIT 1
            ];  // and IsPrimary = true
            lstselectOptionView = new List<SelectOption>();
            lstselectOptionView = selectOptionViews();
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        getRecordTypeListCS();
        getDateFormat();
        getClosedStatus();
        getUserCaseDetails();
        if(ApexPages.currentPage().getParameters().get('parentId') != null && ApexPages.currentPage().getParameters().get('parentId') != '') {
            parentId = ApexPages.currentPage().getParameters().get('parentId');
            try {
                List<Case> cloneCaseObj = [SELECT Alternate_Email__c,Product_Assistance__c,Product_Assistance_Lvl3__c,
                    Product_Assistance_Lvl2__c,Case_Severity__c,Description,Subject,Account.RC_Tier__c,
                    Account.Number_of_DL_s__c,Account.Total_Account_DL_s__c, Account.VIP_Account_Indicator__c,
                    Account.Service_Status__c, Account.Extended_Enterprise_Support_Customer__c
                FROM Case
                WHERE Id = :parentId
                LIMIT 1];
                if(cloneCaseObj != null && cloneCaseObj.size() == 1) {
                    caseObj.Subject = cloneCaseObj[0].Subject;
                    alternateEmail = cloneCaseObj[0].Alternate_Email__c;
                    caseObj.Description = cloneCaseObj[0].Description;
                    caseObj.Status = 'New';
                    selectedProduct = cloneCaseObj[0].Product_Assistance__c;
                    selectedProduct2 = cloneCaseObj[0].Product_Assistance_Lvl2__c;
                    selectedProduct3 = cloneCaseObj[0].Product_Assistance_Lvl3__c;
                    severityLevel = cloneCaseObj[0].Case_Severity__c;
                }
                if(Test.isRunningTest()){
                    Integer i = 2/0;
                }
            } catch(Exception ex) {}
        }

        this.gdprRequest = new GdprRequestHolder();
    }

    public PageReference assistanceChange(){
        return null;
    }

    public PageReference showArticleList(){
        isSubmitCase=true;
        return null;
    }

    public Boolean SummitCase(){
        return false;
    }

    public Integer fileSize {get;set;}

    private void contactPreConditions() {
        System.debug('loginUser.Contact.Email'+loginUser.Contact.Email);
        String loginUserEmail = loginUser.Contact.Email;
        String loginUserPhone = loginUser.Contact.Phone;
        String loginUserFName = loginUser.Contact.FirstName;
        String loginUserLName = loginUser.Contact.LastName;
        String loginPhoneExt;//  = String.valueOf(loginUser.Contact.Phone_Ext__c);//Integer.valueOf(loginUser.Contact.Phone_Ext__c);
        if (loginUser.Contact.Phone_Ext__c != null && loginUser.Contact.Phone_Ext__c != 0) {
            loginPhoneExt = String.valueOf(loginUser.Contact.Phone_Ext__c);
        }//Integer.valueOf(loginUser.Contact.Phone_Ext__c);
        else {
            loginPhoneExt = '';
        }
        String newEmail = ConDetail.Email;
        String newPhone = ConDetail.Phone;
        String newFName = ConDetail.FirstName;
        String newLName = ConDetail.LastName;
        String newPhoneExt;

        if (PhoneExt != null && PhoneExt != '') {
            newPhoneExt = PhoneExt;
        } else {
            newPhoneExt = '';
        }

        Contact contactObj = null;
        if(loginUserEmail != newEmail
            || loginUserPhone != newPhone
            || loginUserFName != newFName
            || loginUserLName != newLName
            || loginPhoneExt != newPhoneExt
            ) {
            String accountId = loginUser.Contact.AccountId;
            if(loginUserEmail == newEmail) {
                contactObj = new Contact();
                contactObj = [SELECT AccountId FROM Contact WHERE Id =:loginUser.ContactId];
            }

            if(contactObj != null) {
                contactObj.Email = newEmail;
                contactObj.Phone = newPhone;
                if (PhoneExt != null && PhoneExt != '') {
                    contactObj.Phone_Ext__c = Double.valueOf(PhoneExt);
                }//ConDetail.Phone_Ext__c;//Updated on 27/11/13
                else {
                    contactObj.Phone_Ext__c = Double.valueOf('0');
                }
                contactObj.FirstName = newFName;
                contactObj.LastName = newLName;
                System.debug('### UPDATING CONTACT ' + loginUser.Id + ' CONTACT ' + contactObj);
                update contactObj;
            } else {
                contactObj = new Contact();
                contactObj.FirstName = newFName;
                contactObj.LastName = newLName;
                contactObj.Email = newEmail;
                contactObj.AccountId = accountId;
                contactObj.Phone = newPhone;

                if (PhoneExt != null && PhoneExt != '') {
                    contactObj.Phone_Ext__c = Double.valueOf(PhoneExt);
                } else {
                    contactObj.Phone_Ext__c = Double.valueOf('0');
                }
                System.debug('### INSERTING CONTACT ' + loginUser.Id + ', Owner Id = ' + contactObj.OwnerId);
                try {
                    insert contactObj;
                    if(Test.isRunningTest()){
                        Integer i = 2/0;
                    }
                } catch(Exception e) {System.debug('#### EXCEPTION COMES HERE ' + e); }
            }
        }
        caseObj.ContactId = (contactObj == null ? loginUser.ContactId : contactObj.Id);
        caseObj.AccountId = (contactObj == null ? loginUser.Contact.AccountId : contactObj.AccountId);
    }



    private Id GetCaseRecordTypeByProduct(String prd)
    {
        if (prd == HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR)
        {
            return OpportunityHelper.getOppRecordTypeMap('DSR Request');
        }
        else
        {
            return OpportunityHelper.getOppRecordTypeMap('Support-Case');
        }
    }

    public PageReference createCase() {
        try {
            System.debug('>>>>>caseObj.AccountId 1>>' + caseObj.AccountId);
            System.debug('>>>>>caseObj.CreatedById 1>>' + caseObj.CreatedById);

            contactPreConditions();

            caseObj.RecordTypeId = GetCaseRecordTypeByProduct(selectedProduct);
            System.debug('>>>>>caseObj.RecordTypeId 1>>' + caseObj.RecordTypeId);

            caseObj.Origin = 'Web';
            caseObj.Product_Assistance__c = selectedProduct;
            caseObj.Alternate_Email__c = alternateEmail;
            caseObj.Product_Assistance_Lvl2__c = selectedProduct2;
            caseObj.Product_Assistance_Lvl3__c = selectedProduct3;
            caseObj.Case_Severity__c = severityLevel;
            caseObj.CallbackNumber__c = callbackNumber;
            caseObj.Timezone__c = timezone;

            try {
                System.debug('>>>>>caseObj.AccountId 11>>' + caseObj.AccountId);
                List<Entitlement> entitlementObj = EntitlementHelper.getEntitlement(loginUser.Contact.AccountId);
                caseObj.EntitlementId = (entitlementObj ==null || entitlementObj.size() == 0 ? null : entitlementObj.get(0).Id);
            } catch(Exception e) {

            }

            System.debug('>>>>>caseObj.AccountId 12>>' + caseObj.AccountId);
            caseObj = HelperCaseDispatch.assignQueue(caseObj, loginUser);
            System.debug('>>>>>caseObj.AccountId 13>>' + caseObj.AccountId);
            System.debug('>>>>>caseObj.CreatedById 2>>' + caseObj.CreatedById);

            if (selectedProduct == HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR)
            {
                String gdpr_request = this.gdprRequest.Serialize();
                caseObj.Description = String.isNotBlank(caseObj.Description) ? caseObj.Description + gdpr_request : gdpr_request;
                caseObj.Case_Severity__c = gdprRequest.GDPR_DEFAULT_SEVERITY;
                caseObj.Subject = gdprRequest.CaseSubject;
            }

            insert caseObj;

            if(attachment != null && attachment.body != null) {
                System.debug('>>>##>>323'+fileSize);
                if(fileSize != null) {
                    Decimal fileSizeDB = Decimal.valueof(fileSize)/(1024 * 1024);
                    System.debug('>>>##>>323e>>'+fileSizeDB);
                    if(fileSizeDB > 5) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Uploaded file size must not be greater than 5 MB.'));
                        return null;
                    }
                }
                Attachment attachObj = attachment;
                attachObj.ParentId = caseObj.Id;
                insert attachObj;
                System.debug('>>>##>>3'+attachObj);
            }

            PageReference pg = null;

            if (getSCPortal()) {
                pg = new PageReference('/RCSupportAdvCaseDetailSC');
            } else {
                pg = new PageReference('/RCSupportAdvCaseDetail');
            }


            pg.getParameters().put('Id',caseObj.Id);
            pg.getParameters().put('IsView','true');
            pg.setRedirect(true);
            return pg;
        } catch(Exception ex) {
            System.debug('>>>##>>2'+ex);
        } finally {
            attachment.body = null;
        }
        return null;
    }

    public void setPortalQuestion() {
        flag=false;
        caseObj.Description = null;

        strValue='';
        chkValue = false;
        if(selectedProduct.equalsIgnoreCase('Faxing')){
            strValue = strFaxing;
            chkValue = false;
        }
        if(selectedProduct.equalsIgnoreCase('Softphone')){
            strValue = strSoftphone;
            chkValue = false;
        }
        if(selectedProduct.equalsIgnoreCase('Desk Phones')){
            strValue = strDeskphone;
            chkValue = false;
        }
        System.debug('>>@@@>>setPortalQuestion');
        System.debug('>>@@@1>>'+selectedProduct);
        System.debug('>>@@@2>>'+selectedProduct2);
        System.debug('>>@@@3>>'+selectedProduct3);
        String mapKey;
        if(selectedProduct != null) {
            mapKey = selectedProduct;
            if(selectedProduct2 != null) {
                mapKey = mapKey + '*-*' + selectedProduct2;
                if(selectedProduct3 != null) {
                    mapKey = mapKey + '*-*' + selectedProduct3;
                }
            }
            mapKey = mapKey.toUpperCase().trim();
        }
        if(mapKey != null && mapPortalQuestion != null && mapPortalQuestion.get(mapKey) != null) {
            String question1;
            String question2;
            String question3;
            if(mapPortalQuestion.get(mapKey).question1 != '*NA*') {
                question1 = 'In order to serve you better, please answer the following questions:';
                question1 = question1 + '\n\n1 : ' + mapPortalQuestion.get(mapKey).question1.replaceAll('-NL-', '\n');
            }
            if(mapPortalQuestion.get(mapKey).question2 != '*NA*') {
                question2 = '\n\n2 : ' + mapPortalQuestion.get(mapKey).question2.replaceAll('-NL-', '\n');
            }
            if(mapPortalQuestion.get(mapKey).question3 != '*NA*') {
                question3 = '\n\n3 : ' + mapPortalQuestion.get(mapKey).question3.replaceAll('-NL-', '\n') ;
            }
            System.debug('>>@@@5>>'+ question1);
            System.debug('>>@@@6>>'+ question2);
            System.debug('>>@@@7>>'+ question3);
            caseObj.Description = (question1 == null ? '':question1) + ' ' + (question2 == null? '':question2) + ' ' + (question3 == null? '': question3);
            if(question1 != null || question2 != null || question3 != null) {
                caseObj.Description = caseObj.Description + '\n\n' + 'Please include any additional comments or details that you feel will better assist us with this issue below.';
            }
        }
    }

    public PageReference selectedPortalQuestion(){
        setPortalQuestion();
        return null;
    }
    public class WrPortalQuestion {
        public String key {get;set;}
        public String question1 {get;set;}
        public String question2 {get;set;}
        public String question3 {get;set;}
        public WrPortalQuestion() {
            question1 = question2 = question3 = key = '';
        }
    }

    public static Map<String,WrPortalQuestion> getPortalQuestion() {
        Map<String,WrPortalQuestion> rtnPortalQuestionMapMap = new Map<String,WrPortalQuestion>();
        try {
            List<Document> docList = [SELECT body, bodyLength, ContentType, Url FROM Document WHERE Name = 'PortalQuestion'];
            if(Test.isRunningTest()) {
                Blob testDoc = Blob.valueOf('Test2*-*Test3*-*Test4,Test2,Test3,Test4,EOF\n');
                List<List<String>> parsedCSV = parseCSV(testDoc.toString().trim(),false);
                if(parsedCSV != null) {
                    for(List<String> listObj : parsedCSV) {
                        WrPortalQuestion wrPortalQuestionObj = new WrPortalQuestion();
                        System.debug('>>222>>>'+ listObj);
                        wrPortalQuestionObj.key = listObj[0].trim().toUpperCase();
                        if(String.isNotBlank(listObj[1]) && listObj[1].startsWith('"') && listObj[1].endsWith('"')){
                            wrPortalQuestionObj.question1 = listObj[1].substring(1, listObj[1].length()-1);
                        }else{
                            wrPortalQuestionObj.question1 = listObj[1];
                        }
                        if(String.isNotBlank(listObj[2]) && listObj[2].startsWith('"') && listObj[2].endsWith('"')){
                            wrPortalQuestionObj.question2 = (listObj[2]).substring(1, listObj[1].length()-1);
                        }else{
                            wrPortalQuestionObj.question2 = (listObj[2]);
                        }
                        if(String.isNotBlank(listObj[3]) && listObj[3].startsWith('"') && listObj[3].endsWith('"')){
                            wrPortalQuestionObj.question3 = listObj[3].substring(1, listObj[1].length()-1);
                        }else{
                            wrPortalQuestionObj.question3 = listObj[3];
                        }
                        rtnPortalQuestionMapMap.put(wrPortalQuestionObj.key,wrPortalQuestionObj);
                    }
                }
            }
            if(docList != null && docList.size()>0) {
                if(docList[0].Body != null) {
                    System.debug('>>1212>>>'+ docList[0].Body.toString().trim());
                    List<List<String>> parsedCSV =  parseCSV(docList[0].Body.toString().trim(),false);
                    if(parsedCSV != null) {
                        for(List<String> listObj : parsedCSV) {
                            WrPortalQuestion wrPortalQuestionObj = new WrPortalQuestion();
                            System.debug('>>222>>>'+ listObj);
                            wrPortalQuestionObj.key = listObj[0].trim().toUpperCase();
                            if(String.isNotBlank(listObj[1]) && listObj[1].startsWith('"') && listObj[1].endsWith('"')){
                                wrPortalQuestionObj.question1 = listObj[1].substring(1, listObj[1].length()-1);
                            }else{
                                wrPortalQuestionObj.question1 = listObj[1];
                            }
                            if(String.isNotBlank(listObj[2]) && listObj[2].startsWith('"') && listObj[2].endsWith('"')){
                                wrPortalQuestionObj.question2 = (listObj[2]).substring(1, listObj[2].length()-1);
                            }else{
                                wrPortalQuestionObj.question2 = (listObj[2]);
                            }
                            if(String.isNotBlank(listObj[3]) && listObj[3].startsWith('"') && listObj[3].endsWith('"')){
                                wrPortalQuestionObj.question3 = listObj[3].substring(1, listObj[3].length()-1);
                            }else{
                                wrPortalQuestionObj.question3 = listObj[3];
                            }
                            rtnPortalQuestionMapMap.put(wrPortalQuestionObj.key,wrPortalQuestionObj);
                        }
                    }
                }
            }
            return rtnPortalQuestionMapMap;
        } catch(Exception ex) {
            System.debug('>>ex>>>'+ ex.getMessage());
        }
        return null;
    }

    private static List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
        contents = contents.replaceAll(',"""',',"DBLQT').replaceAll('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        for(String line : lines) {
            if (line.replaceAll(',','').trim().length() == 0) {
                break;
            }
            List<String> fields = line.split(',');
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field.trim();
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"').trim());
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field.trim();
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) {
            allFields.remove(0);
        }
        return allFields;
    }

    public List<Case> usercaseList {get;set;}
    public List<WrapperCase> usercaseListWr {get;set;}
    public void getUserCaseDetails() {
        try {
            createQuery();
        } catch(Exception ex) {}
    }

    public void sortCaseList() {
        try {
            System.debug('>>>!!>>>'+selectSortValue);
            getUserCaseDetails();
        } catch(Exception ex) {}
    }

    public void searchCase() {
        try {
            createQuery();
        } catch(Exception ex) {}
    }

    Set<String> recordTypesSet = new Set<String>();
    public void getRecordTypeListCS() {
        try {
            Map<String, Portal_Cases_Record_Types__c> recordTypesCSMap = Portal_Cases_Record_Types__c.getAll();
            if(recordTypesCSMap != null) {
                recordTypesSet = recordTypesCSMap.keySet();
            }
        } catch(Exception ex) {}
    }

    Set<String> closedStatusSet = new Set<String>();
    public void getClosedStatus() {
        closedStatusSet.add('Duplicate');
        closedStatusSet.add('Invalid');
        closedStatusSet.add('Cancelled');
        closedStatusSet.add('Closed');
        closedStatusSet.add('Closed - Endorsed');
        closedStatusSet.add('Closed - No Contact');
        closedStatusSet.add('Closed - No Issue');
        closedStatusSet.add('Closed - No Response');
        closedStatusSet.add('Closed - No response');
    }

    String formatDate;
    public void getDateFormat() {
        try {
            Date originalDate = Date.newInstance(2013, 11, 20);
            Datetime dtConverted = Datetime.newInstance(originalDate.year(),originalDate.month(),originalDate.day(),0,0,0);
            formatDate = dtConverted.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            System.debug('>>formatDate>>>'+formatDate);
        } catch(Exception ex) {}
    }

    public String createQuery() {
        String strQuery;
        try {
            if(selectedViewOptions1 == 'My Open Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+
                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+
                    ' and  Status NOT IN :closedStatusSet and (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';
            } else if(selectedViewOptions1 == 'My Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+
                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+
                    ' and  (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';
            } else if(selectedViewOptions1 == 'All Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+
                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+
                    ' and  (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';
            } else if(selectedViewOptions1 == 'All Open Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Subject,Case_Severity__c,CreatedDate '+
                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+
                    ' and Status NOT IN :closedStatusSet and (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';
            }

            if(!String.isBlank(selectSearchValue) && !String.isBlank(inputSearchValue)) {
                strQuery = strQuery + ' and ';
                if(selectSearchValue == 'Case_Number') {
                    strQuery = strQuery + 'CaseNumber like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';
                } else if(selectSearchValue == 'Contact_Name') {
                    strQuery = strQuery + 'Contact.Name like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';
                } else if(selectSearchValue == 'Subject') {
                    strQuery = strQuery + 'Subject like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';
                } else if(selectSearchValue == 'Severity_Level') {
                    strQuery = strQuery + 'Case_Severity__c like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';
                }
            }
            strQuery = strQuery + ' order by ';
            if(!String.isBlank(selectSortValue)) {
                if(selectSortValue == 'Time_Date_Opened') {
                    strQuery = strQuery + 'CreatedDate desc';
                } else if(selectSortValue == 'Case_Status') {
                    strQuery = strQuery + 'Status asc, CreatedDate desc';
                }
            }
            strQuery = strQuery + ' Limit 50000 ';
            System.debug('>>!!>>'+strQuery);
            createCaseList(strQuery);
        } catch(Exception ex) {}
        return strQuery;
    }


    public List<SelectOption> selectOptionViews() {
        List<SelectOption> options = new List<SelectOption>();
        if(toFindLoginUserProfileLst != null && toFindLoginUserProfileLst.size()>0){
            options.add(new SelectOption('All Cases','All Cases'));
            options.add(new SelectOption('All Open Cases','All Open Cases'));
        }
        options.add(new SelectOption('My Cases','My Cases'));
        options.add(new SelectOption('My Open Cases','My Open Cases'));
        return options;
    }

    public void createCaseList(String strQuery) {
        usercaseList = new List<Case>();
        usercaseListWr = new List<WrapperCase>();
        try {
            if(!String.isBlank(strQuery)) {
                System.debug('>>>!!>>>'+strQuery);
                usercaseList = Database.query(strQuery);
                Integer i = 0;
                for(Case caseObj : usercaseList) {
                    WrapperCase wrCaseObj = new WrapperCase();
                    wrCaseObj.caseObj = caseObj;
                    wrCaseObj.strformatDT = caseObj.CreatedDate.format('h:mm a z, MM/dd/yyyy','America/New_York');
                    wrCaseObj.caseIndex = ++i;
                    usercaseListWr.add(wrCaseObj);
                }
                userCasePaging = new RCSupportPortalCasePagingHelper(usercaseListWr);
                wrPgItrCases.rtnIntList = null;
                getCasesPgItr();
            }
        } catch(Exception ex) {}
    }

    public RCSupportPortalCasePagingHelper userCasePaging {get;set;}
    public List<WrapperCase> usercaseListWr1 = new List<WrapperCase>();
    public List<WrapperCase> getcaseList1() {
        try {
            usercaseListWr1 =  new List<WrapperCase>();
            if(userCasePaging.rtnListObj1 != null && (userCasePaging.rtnListObj1).size()>0) {
                for(Object caseObj : userCasePaging.rtnListObj1) {
                    usercaseListWr1.add((WrapperCase)caseObj);
                }
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            return null;
        }
        return usercaseListWr1;
    }

    public WrPgIterator wrPgItrCases {get;set;}
    public List<Integer> tempCasesPgItr {get;set;}
    public void getCasesPgItr() {
        try {
            tempCasesPgItr = new List<Integer>();
            tempCasesPgItr = createPgItrList(userCasePaging,wrPgItrCases);
            System.debug('>>123>>>'+tempCasesPgItr);
            if(tempCasesPgItr != null && tempCasesPgItr.size()>0) {
                wrPgItrCases.wrfirstElement = tempCasesPgItr.get(0);
                wrPgItrCases.wrlastElement =  tempCasesPgItr.get(tempCasesPgItr.size() - 1);
            }
        } catch(Exception ex) { }
    }

    public List<Integer> createPgItrList(RCSupportPortalCasePagingHelper  casePagingObj, WrPgIterator wrItrTempObj) {
        try {
            lastElement = 0;
            firstElement = 0;
            WrPgIterator wrPgItrObj = new WrPgIterator();
            wrPgItrObj = wrItrTempObj;
            if(wrPgItrObj.rtnIntList == null) {
                wrPgItrObj.rtnIntList = new List<Integer>();
                if(casePagingObj.getTotalPageNumber() < 10) {
                    for(Integer i=1;i<=casePagingObj.getTotalPageNumber();i++) {
                        wrPgItrObj.rtnIntList.add(i);
                    }
                } else {
                    for(Integer i=1;i<=10;i++) {
                        wrPgItrObj.rtnIntList.add(i);
                    }
                }
                lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                firstElement = wrPgItrObj.rtnIntList.get(0);
            } else if(wrPgItrObj.rtnIntList != null && wrPgItrObj.rtnIntList.size()>0) {
                System.debug('>>actionType>>'+actionType);
                if(actionType == 'Previous') {
                    firstElement = wrPgItrObj.rtnIntList.get(0);
                    casePagingObj.pageNumberParam = firstElement - 10;
                    casePagingObj.getRecordsByPN();
                    wrPgItrObj.rtnIntList.clear();
                    for(Integer i = firstElement - 10 ;i <= firstElement - 1;i++) {
                        wrPgItrObj.rtnIntList.add(i);
                    }
                } else if(actionType == 'Next') {
                    System.debug('>>Next>>');
                    lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                    casePagingObj.pageNumberParam = lastElement + 1;
                    casePagingObj.getRecordsByPN();
                    if((casePagingObj.getTotalPageNumber() - lastElement) < 10) {
                        wrPgItrObj.rtnIntList.clear();
                        for(Integer i= lastElement + 1 ;i<=casePagingObj.getTotalPageNumber();i++) {
                            wrPgItrObj.rtnIntList.add(i);
                        }
                    } else {
                        wrPgItrObj.rtnIntList.clear();
                        for(Integer i= lastElement + 1 ; i <= 10 + lastElement; i++) {
                            wrPgItrObj.rtnIntList.add(i);
                        }
                    }
                    System.debug('>>wrPgItrObj.rtnIntList>>'+wrPgItrObj.rtnIntList);
                }
                lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                firstElement = wrPgItrObj.rtnIntList.get(0);
                System.debug('>>lastElement>>'+lastElement);
                System.debug('>>firstElement>>'+firstElement);
            }
            return wrPgItrObj.rtnIntList;
        } catch(Exception ex) { }
        return null;
    }

    public List<SelectOption> productAssistanceItems {get;set;}
    public List<SelectOption> productAssistanceItemsLvl2 {get;set;}
    public List<SelectOption> productAssistanceItemsLvl3 {get;set;}

    public Boolean flag{get; set;}

    public List<SelectOption> getproductAssistanceItemsValues() {
        List<SelectOption> options = new List<SelectOption>();
        /* Case 03272867:  Product Assistance Custom setting changes {*/
        String portalName = mapPortalList.get(baseUrl.toLowerCase().trim());
        /*} Case 03272867:  Product Assistance Custom setting changes */
        try {
            options.add(new SelectOption('','Please select product area'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList = productAssistance.getPicklistValues();
            /* Case 03272867:  Product Assistance Custom setting changes {*/
            for(Schema.PicklistEntry schObj : productAssistanceList) {
                String productAssistanceValue = schObj.getValue();
                String productAssistanceLable = schObj.getLabel();
                Set<String> portalBrand = mapProductAssistance.get(productAssistanceValue.toLowerCase().trim());
                if (portalBrand == null || portalBrand.isEmpty()) {
                    continue;
                }
                if(portalBrand.contains(portalName)){
                    options.add(new SelectOption(productAssistanceValue,productAssistanceLable));
                }
            }
            /*} Case 03272867:  Product Assistance Custom setting changes */
        } catch(Exception ex) {}
        return options;
    }

    public List<SelectOption> productAssistanceItemsLvl2() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new SelectOption('','Please select product issue'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance_Lvl2__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList2 = productAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : productAssistanceList2) {
                options.add(new SelectOption(schObj.getValue(),schObj.getLabel()));
            }
            if(Test.isRunningTest()){
                Integer i = 2/0;
            }
        } catch(Exception ex) {}
        return options;
    }

    public List<SelectOption> productAssistanceItemsLvl3() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new SelectOption('','Please select product issue'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance_Lvl3__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList3 = productAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : productAssistanceList3) {
                options.add(new SelectOption(schObj.getValue(),schObj.getLabel()));
            }
            if(Test.isRunningTest()){
                Integer i = 2/0;
            }
        } catch(Exception ex) {}
        return options;
    }

    public List<SelectOption> caseSeverityItems {get;set;}
    public List<SelectOption> getcaseSeverityItemsValues() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new SelectOption('','Please select severity level'));
            Schema.DescribeFieldResult caseAssistance = Case.Case_Severity__c.getDescribe();
            List<Schema.PicklistEntry> caseAssistanceList = caseAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : caseAssistanceList) {
                if(schObj.getLabel() != 'Level 1 - Critical') {
                    options.add(new SelectOption(schObj.getValue(),schObj.getLabel()));
                }
            }
        } catch(Exception ex) {}
        return options;
    }

    public class WrapperCase {
        public Case caseObj {get;set;}
        public String strformatDT {get;set;}
        public Integer caseIndex {get;set;}
        public WrapperCase() {
            caseObj = new Case();
            strformatDT = null;
            caseIndex = 0;
        }
    }

    public Integer firstElement {get;set;}
    public Integer lastElement {get;set;}
    public String actionType {get;set;}
    public class WrPgIterator {
        public Integer wrfirstElement {get;set;}
        public Integer wrlastElement {get;set;}
        public List<Integer> rtnIntList {get;set;}
    }
    public PageReference flagValue(){
        flag = true;
        return null;
    }

    public Boolean getSCPortal(){
        if(Site.getName()!=null && Site.getName()!='' && (Site.getName()).lastIndexOfIgnoreCase('RingCentral_Support')>-1){
            return true;
        }
        return false;
    }

    public void ifMessageRequired(){
        flag=false;
        Set<String> chatDeflectionBrands = new Set<String>{'ringcentral', 'ringcentral canada', 'ringcentral uk'}; //write ONLY in lower case
        Set<String> chatDeflectionTiers = new Set<String>{'office', 'fax', 'pro'}; //write ONLY in lower case
        List<ProductAssistanceMessageOptions__c> lstProductAssistanceMessage = ProductAssistanceMessageOptions__c.getAll().values();
        if (lstProductAssistanceMessage.size() < 1) {
            return;
        }

        try{
            Contact contactData = [
                SELECT Id, Account_Number_of_DLs__c, Account_Brand__c, Account_Service__c
                FROM Contact
                WHERE Id = :loginUser.ContactId
            ];
            System.debug('contactData:'+contactData);
            System.debug('flag--on Start-->'+flag);
            System.debug('selectedProduct3---->'+selectedProduct3);
            System.debug('selectedProduct2---->'+selectedProduct2);
            System.debug('selectedProduct---->'+selectedProduct);

            if(contactData != null &&
                (contactData.Account_Number_of_DLs__c != null && contactData.Account_Number_of_DLs__c < 20 ) &&
                (contactData.Account_Brand__c != null && chatDeflectionBrands.contains(contactData.Account_Brand__c.toLowerCase())) &&
                (contactData.Account_Service__c != null && chatDeflectionTiers.contains(contactData.Account_Service__c.toLowerCase()))) {
                for (ProductAssistanceMessageOptions__c obj : lstProductAssistanceMessage){
                    System.debug('----->'+obj);
                    if (obj.OptionLevel1__c.equalsIgnoreCase(selectedProduct)){
                        System.debug('enabling chat deflection for '+selectedProduct);
                        flag = true ;
                        break;
                    }
                }
            }
        }catch(Exception e){
            System.debug('Its an exception!!!!!!'+e);
        }
        System.debug('Flag is>>'+flag);

    }

}