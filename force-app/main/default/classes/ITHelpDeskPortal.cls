public with sharing class ITHelpDeskPortal {
    public ApexPages.StandardController controller {get;set;}
    public string caseSearchText {get;set;}
    List<Case> results;
    public boolean toShowMailPanel {get;set;}
    public String strFilter {get;set;}
    public List<WrLegalReqDetail> lstLegalReqDetail {get;set;}
    
    /****************************************************************************
     * @Description - Constructor Class.                                         * 
     * @params void                                                              *
     * @return void                                                              * 
     *****************************************************************************/
    public ITHelpDeskPortal(ApexPages.StandardController controller) {
        try {
            system.debug('Inside ITHelpDeskPortal');
            Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=10');
            this.controller = controller;
            results = new List<Case>();
            toShowMailPanel = true;
            getDefaultCasesForLoggedInUser();
            getDefaultLegalRequestForLoggedInUser();
            //System.debug('userCasesList size====>'+ userCasesList.size());
        } catch(Exception ex) {
            System.debug('updateAccountInformation @ '+ex.getlineNumber());
            System.debug('#### updateAccountInformation '+ex.getMessage());
        }
    }
    
    public static Map<String,String> getLegalRequestObjDetail(){
        Map<String,String> mapLegalReq = new Map<String,String>();
        SObjectType objToken = ((SObject)Type.forName('Legal_Requests__c').newInstance()).getSObjectType();
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap(); 
        
        Set<String> fieldSet = fields.keySet();
        for(String s : fieldSet)
        {
            SObjectField fieldToken = fields.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            mapLegalReq.put(selectedField.getName(),selectedField.getLabel());
        }
        return mapLegalReq;
    }
       
    public static List<String> getCaseFields(){
        
        List<String> fieldsList = new List<String>();
        SObjectType objToken = ((SObject)Type.forName('Case').newInstance()).getSObjectType();
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap(); 
        
        Set<String> fieldSet = fields.keySet();
        for(String s : fieldSet)  
        {
            SObjectField fieldToken = fields.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            fieldsList.add(selectedField.getName());
        }
        //fieldsList.add('Manager__r.Name');
        return fieldsList;
    } 
    
    public List<SelectOption> getFilterOptions(){
        List<SelectOption> lstFilterOption = new List<SelectOption>();
        lstFilterOption.add(new SelectOption('none','None'));
        lstFilterOption.add(new SelectOption('FOSS','FOSS'));
        lstFilterOption.add(new SelectOption('IT','IT'));
        lstFilterOption.add(new SelectOption('Invention','Invention'));
        return lstFilterOption;
    }
    
    public ITHelpDeskPortal() {}
    
    public Boolean getIsArticleDetailsPage(){
        String pageURL=ApexPages.currentPage().getUrl();
        if(pageURL!=null && pageURL.indexOf('TOCArticleRendererPkb')>-1){
            return true;
        }
        return false;
    }
    
    public List<WrCaseDetail> listWrCaseByText {get;set;}
    public List<WrCaseDetail> userCasesList{get;set;}
    public boolean toShowErrorMsg {get;set;}
    public string errorMsg {get;set;}
    String strContact;
    public boolean isUserHR {get;set;}
    
    public void getDefaultLegalRequestForLoggedInUser(){
        String loggedInUserId = UserInfo.getUserId();
        List<Legal_Requests_Watchers__c> lstWatcher = new List<Legal_Requests_Watchers__c>();
        lstWatcher = [SELECT Id, Legal_Requests__c FROM Legal_Requests_Watchers__c Where Advisor_Name__c =:loggedInUserId];
        List<String> lstIds = new List<String>();
        if(lstWatcher != null && lstWatcher.size() > 0){
            for(Legal_Requests_Watchers__c obj : lstWatcher){
                lstIds.add(obj.Legal_Requests__c);
            }
        }
        try{
            //if(lstIds != null && lstIds.size() > 0){   
                List<Legal_Requests__c> lstLegalReq = new List<Legal_Requests__c>();
                lstLegalReqDetail = new List<WrLegalReqDetail>();
                lstLegalReq = [SELECT Id, Name, Status__c, Draft_Date__c, Submitted_Date__c, Title_of_Invention__c, RecordType.Name, FOSS_Name__c  
                                        FROM Legal_Requests__c Where Id IN :lstIds OR OwnerId=:loggedInUserId order by createddate desc];
                for(Legal_Requests__c obj : lstLegalReq){
                    WrLegalReqDetail wrObj = new WrLegalReqDetail();
                    wrObj.id = obj.Id;
                    wrObj.objname = obj.Name;
                    wrObj.Status = obj.Status__c;
                    wrObj.DraftDate = obj.Draft_Date__c;
                    wrObj.SubmitDate = obj.Submitted_Date__c;
                    wrObj.recordTypeName = obj.RecordType.Name;
                    lstLegalReqDetail.add(wrObj);
                }
            //}
 
        }catch(Exception ex){
            system.debug('Exception === ' + ex.getMessage() + ' ' + ex.getlineNumber());
            ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'No Result Found.'));
            toShowErrorMsg = true;
            errorMsg = 'No Result Found.';
        }
    }
    
    /*******************************************************************************
     * @Description - Method to display all the Cases related to the loggedin user *
                     & all the atricles of "ITHelpDesk" on the page load. .        * 
     * @params void                                                                *
     * @return void                                                                * 
     *******************************************************************************/
     public  void getDefaultCasesForLoggedInUser() {
        try {
            //System.debug('no.of queries got executed getDefaultCasesForLoggedInUser'+limits.getqueries());
            system.debug('Inside getDefaultCasesForLoggedInUser');
            listWrCaseByText = new List<WrCaseDetail>();
            userCasesList = new List<WrCaseDetail>();
            String loggedInUserId;
            strContact = '';
            List<Case> caseList = new List<Case>();
            loggedInUserId = UserInfo.getUserId();
            system.debug('Enterprise Account Id====>'+ LoggedInUSerId);
            User userInfoObj = [select email,contactId from User where Id = :UserInfo.getUserId() limit 1];
            System.debug('userInfoObj.email====>'+ userInfoObj.email);
            System.debug('userInfoObj====>'+ userInfoObj);
            strContact = [SELECT Id,FirstName,AccountId,LastName,Phone,Email FROM Contact 
                            WHERE (Email =:userInfoObj.email.trim() OR Id =:userInfoObj.contactId) 
                            and Account.Name = 'RC Internal' limit 1].Id;
            System.debug('Contact email====>'+strContact);
            List<Employee__c> employeeUserInfo = [select Department__c from Employee__c where Email__c = :userInfoObj.email limit 1];
            if(employeeUserInfo != null && employeeUserInfo.size()> 0) {
                if(!string.isBlank(employeeUserInfo[0].Department__c) && employeeUserInfo[0].Department__c.containsIgnoreCase('HR')) {
                    isUserHR = true;
                }
            }
            /* results =[SELECT Id,CaseNumber,Subject,Status,ContactId,Priority, ClosedDate,CreatedDate,Contact.Name,Case.Owner.Name, 
                        Time_Since_Case_Opened__c FROM Case 
                        WHERE (ContactId =:strContact OR Additional_Case_Watcher__c = :strContact) AND 
                        (RecordType.Name = 'IT Helpdesk' OR  RecordType.Name = 'IT New Hire Request') order by createddate desc]; */

            results =[SELECT Id,CaseNumber,Subject,Status,ContactId,Priority, ClosedDate,CreatedDate,Contact.Name,Case.Owner.Name, 
                        Time_Since_Case_Opened__c FROM Case 
                        WHERE (ContactId =:strContact) AND 
                        (RecordType.Name = 'IT Helpdesk' OR  RecordType.Name = 'IT New Hire Request') order by createddate desc];  
            //System.debug('caseList size====>'+ results.size());
            for(Case caseObj : results) {
                WrCaseDetail searchCase = new WrCaseDetail();
                searchCase.id = caseObj.id;
                searchCase.contactname = caseObj.Contact.Name;
                searchCase.caseownernmame = caseObj.Owner.Name;
                searchCase.CaseNumber = caseObj.CaseNumber;
                searchCase.ClosedDate = caseObj.ClosedDate != null ? caseObj.ClosedDate.format() : '';
                searchCase.CreatedDate = caseObj.CreatedDate.format();
                searchCase.Priority = caseObj.Priority;
                searchCase.Subject= caseObj.Subject;
                searchCase.Status = caseObj.Status;
                if(caseObj.Time_Since_Case_Opened__c != null) {
                    Integer noOfDays = Integer.valueOf((caseObj.Time_Since_Case_Opened__c));
                    if(noOfDays >= 0 && noOfDays < 7) {
                        searchCase.TimeSinceCaseOpened = 'Green';
                    } else if(noOfDays >= 7 && noOfDays <= 9) {
                        searchCase.TimeSinceCaseOpened = 'Yellow';
                    } else if(noOfDays >9) {
                        searchCase.TimeSinceCaseOpened = 'Red';
                    }
                }
                listWrCaseByText.add(searchCase);
                userCasesList.add(searchCase);
            } 
        } catch(Exception ex){
            System.debug('getDefaultCasesForLoggedInUser @ '+ex.getlineNumber());
            System.debug('#### getDefaultCasesForLoggedInUser '+ex.getMessage()); 
        } 
            
        try {
            lstITArticle = new List<WrITArticles>();
            String  qryString ='SELECT Id, title, UrlName, ArticleNumber ,LastModifiedDate, LastPublishedDate,LastModifiedBy.Name, ' +
                                ' KnowledgeArticleId FROM KnowledgeArticleVersion WHERE '+
                               ' (PublishStatus = \'online\' and Language = \'en_US\' and ArticleType = \'Knowledge__kav\')';
            List<KnowledgeArticleVersion> articleList1 = Database.query(qryString);
            System.debug('>>>1111>>>' + articleList1);
            for(KnowledgeArticleVersion knwArticleVersionObj : articleList1) {
                WrITArticles wrObj = new WrITArticles();
                wrObj.strArticleModifiedBy = knwArticleVersionObj.LastModifiedBy.Name;
                wrObj.strArticleId = knwArticleVersionObj.KnowledgeArticleId;
                wrObj.strArticleNumber = knwArticleVersionObj.ArticleNumber;
                wrObj.strArticleURL = knwArticleVersionObj.UrlName;
                wrObj.strArticleTitle = knwArticleVersionObj.title;
                wrObj.strArticleModifiedDate = knwArticleVersionObj.LastModifiedDate.format('MM/dd/yyyy');
                lstITArticle.add(wrObj);
                System.debug('#######'+lstITArticle);
            }
        } catch(Exception ex) {
            System.debug('@@@@@@@@@@@@@@ '+ex.getlineNumber());
            System.debug('&&&&&&&&&&&&&&&&&& '+ex.getMessage()); 
        }    
    }
    /*******************************************************************************
     * @Description - Method to Search case by casenumber or                       *
                      subject and to search article.                               * 
     * @params void                                                                *
     * @return void                                                                * 
     *******************************************************************************/
    public PageReference searchCaseAndArticles() {
        try {
            errorMsg = '';
            toShowErrorMsg = false;
            System.debug('caseSearchText'+ caseSearchText);
            listWrCaseByText = new List<WrCaseDetail>();
            lstLegalReqDetail = new List<WrLegalReqDetail>();
            if(strFilter=='FOSS' || strFilter=='Invention'){ 
                findLegalRequest();
            } else if (strFilter=='IT'){ 
                findCases();
            } else {
                findLegalRequest();
                findCases();
            } 
            getArticles();        
        } catch(Exception ex) {           
            ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'No Result Found.'));
            ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, ex.getMessage()));
            toShowErrorMsg = true;
            errorMsg = 'No Result Found.';
        }
        return null;
    }
    
    public void findLegalRequest(){
        List<Legal_Requests__c> lstLegalReq = new List<Legal_Requests__c>();
        lstLegalReqDetail = new List<WrLegalReqDetail>();
        
        String loggedInUserId = UserInfo.getUserId();
        List<Legal_Requests_Watchers__c> lstWatcher = new List<Legal_Requests_Watchers__c>();
        lstWatcher = [SELECT Id, Legal_Requests__c FROM Legal_Requests_Watchers__c Where Advisor_Name__c =:loggedInUserId];
        Set<Id> requestIdSet = new Set<Id>();
        if(lstWatcher != null && lstWatcher.size() > 0){
            for(Legal_Requests_Watchers__c obj : lstWatcher){
                requestIdSet.add(obj.Legal_Requests__c);
            }
        }               
        
        string strQuery = 'SELECT Id, Name, Status__c, Draft_Date__c, Submitted_Date__c, Title_of_Invention__c, RecordType.Name, FOSS_Name__c  FROM Legal_Requests__c '+
                           ' WHERE (ID in : requestIdSet OR OwnerId =: loggedInUserId)';
        if(String.isNotBlank(caseSearchText) && !'Enter Keywords or Case Number to search for a Case'.equalsIgnoreCase(caseSearchText)) {
            if(strFilter=='Invention'){
                strQuery+=' AND (Title_of_Invention__c like \'%' + String.escapeSingleQuotes(caseSearchText.trim()) + '%\' )';
            } else if(strFilter=='FOSS'){
                strQuery+=' AND ( Foss_Name__c like \'%' + String.escapeSingleQuotes(caseSearchText.trim()) + '%\' )';
            }   
        } else if(strFilter != 'none') {
            strQuery+=' AND RecordType.Name =' + '\''+strFilter+'\'';
        }                          
        strQuery+=' ORDER BY createddate desc' ;
        system.debug('strQuery='+strQuery);
        lstLegalReq = Database.query(strQuery);
        for(Legal_Requests__c obj : lstLegalReq){
            WrLegalReqDetail wrObj = new WrLegalReqDetail();
            wrObj.id = obj.Id;
            wrObj.objname = obj.Name;
            wrObj.Status = obj.Status__c;
            wrObj.DraftDate = obj.Draft_Date__c;
            wrObj.SubmitDate = obj.Submitted_Date__c;
            wrObj.recordTypeName = obj.RecordType.Name;
            lstLegalReqDetail.add(wrObj);
        }
    }
    
    public void findCases(){
        if(String.isNotBlank(caseSearchText) && !'Enter Keywords or Case Number to search for a Case'.equalsIgnoreCase(caseSearchText)) {
            System.debug('casenumber1'+ caseSearchText);
            listWrCaseByText = new List<WrCaseDetail>();
            String strQuerys;
            strQuerys = caseSearchText.trim();
            /*  string strQuery = 'SELECT Id,CaseNumber,Additional_Case_Watcher__c,Status,CreatedDate,ClosedDate,Time_Since_Case_Opened__c,' +
                        ' Account.Name,Case_Severity__c,Product_Assistance__c,Priority,Subject,Contact.Name,Case.Owner.Name from Case '+
                        'where (RecordType.Name =' + '\'IT Helpdesk\' OR RecordType.Name =' + '\'IT New Hire Request\' )' +' and '+ 
                        'ContactId =' + '\'' + strContact + '\' and ' + 
                        '(CaseNumber LIKE \'%'+String.escapeSingleQuotes(strQuerys)+'%\' OR Subject LIKE \'%'+String.escapeSingleQuotes(strQuerys)+'%\') order by createddate desc' ; */

            string strQuery = 'SELECT Id,CaseNumber,Status,CreatedDate,ClosedDate,Time_Since_Case_Opened__c,' +
                        ' Account.Name,Case_Severity__c,Product_Assistance__c,Priority,Subject,Contact.Name,Case.Owner.Name from Case '+
                        'where (RecordType.Name =' + '\'IT Helpdesk\' OR RecordType.Name =' + '\'IT New Hire Request\' )' +' and '+ 
                        'ContactId =' + '\'' + strContact + '\' and ' + 
                        '(CaseNumber LIKE \'%'+String.escapeSingleQuotes(strQuerys)+'%\' OR Subject LIKE \'%'+String.escapeSingleQuotes(strQuerys)+'%\') order by createddate desc' ;  
             
            System.debug('######strQuery#######123'+ strQuery);                
            results = Database.Query(strQuery);
            for(Case caseObj : results) {
                WrCaseDetail searchCase = new WrCaseDetail();
                searchCase.id = caseObj.id;
                searchCase.CaseNumber = caseObj.CaseNumber;
                searchCase.ClosedDate = caseObj.ClosedDate != null ? caseObj.ClosedDate.format() : '';
                searchCase.CreatedDate = caseObj.CreatedDate.format();
                searchCase.Priority = caseObj.Priority;
                searchCase.Subject= caseObj.Subject;
                searchCase.Status = caseObj.Status;
               // searchCase.AdditionalCaseWatcher = caseObj.Additional_Case_Watcher__c;
                searchCase.contactname = caseObj.Contact.Name;
                searchCase.caseownernmame = caseObj.Owner.Name;
                searchCase.accountname = caseObj.Account.Name;
                searchCase.ProductAssistance = caseObj.Product_Assistance__c;
                if(caseObj.Time_Since_Case_Opened__c != null) {
                    Integer noOfDays = Integer.valueOf((caseObj.Time_Since_Case_Opened__c));
                    if(noOfDays >= 0 && noOfDays < 7) {
                        searchCase.TimeSinceCaseOpened = 'Green';
                    } else if(noOfDays >= 7 && noOfDays <= 9) {
                        searchCase.TimeSinceCaseOpened = 'Yellow';
                    } else if(noOfDays >9) {
                        searchCase.TimeSinceCaseOpened = 'Red';
                    }
                }
                listWrCaseByText.add(searchCase);
                System.debug('search@@@'+listWrCaseByText);
                System.debug('searchcase number@@@'+searchCase);
            }
 
 
        } else {
            getDefaultCasesForLoggedInUser();
        }
    }
    
    public Boolean getMyCasesSize(){
        if(listWrCaseByText != null && listWrCaseByText.size() > 0){
            return false;
        }else if(lstLegalReqDetail != null && lstLegalReqDetail.size() > 0){
            return false;
        }else{
            return true;
        }
    
    }
    
    public class WrLegalReqDetail {
        public String id {get;set;}
        public String objname {get;set;}
        public String Status {get;set;}
        public Date DraftDate {get;set;}
        public Date SubmitDate {get;set;}
        public string recordTypeName{get;set;}
        public WrLegalReqDetail() {}
    }    
    public void getArticles() {
        try{
            errorMsg = '';
            toShowErrorMsg = false;
            if(!String.isBlank(caseSearchText) && caseSearchText != 'Enter Keywords or Case Number to search for a Case') {
                lstITArticle = new List<WrITArticles>();    
                String qryString = 'SELECT Id, title, UrlName,ArticleNumber,LastModifiedDate,LastModifiedBy.Name, LastPublishedDate, KnowledgeArticleId FROM KnowledgeArticleVersion WHERE '+
                                ' (PublishStatus = \'online\' and Language = \'en_US\' and ArticleType = \'Knowledge__kav\' and '+
                                ' title Like \'%'+String.escapeSingleQuotes(caseSearchText.trim())+'%\')';
                List<KnowledgeArticleVersion> articleList1 = Database.query(qryString);
                System.debug('>>>1111>>>' + articleList1);
                for(KnowledgeArticleVersion knwArticleVersionObj : articleList1) {
                    WrITArticles wrObj = new WrITArticles();
                    wrObj.strArticleModifiedBy = knwArticleVersionObj.LastModifiedBy.Name;
                    wrObj.strArticleNumber = knwArticleVersionObj.ArticleNumber;
                    wrObj.strArticleId = knwArticleVersionObj.KnowledgeArticleId;
                    wrObj.strArticleURL = knwArticleVersionObj.UrlName;
                    wrObj.strArticleTitle = knwArticleVersionObj.title;
                    wrObj.strArticleModifiedDate = knwArticleVersionObj.LastModifiedDate.format('MM/dd/yyyy');
                    lstITArticle.add(wrObj);
                }
            } else {
                System.debug('@@@@@@');
                ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'Blank search will not work.Please Enter Some Value'));
                toShowErrorMsg = true;
                errorMsg = 'Blank search will not work.Please Enter Some Value';
                System.debug('ERROR MESSAGE'+errorMsg);
            } 
        } catch(Exception ex) {
             System.debug('>>ex>' + ex.getMessage());
             ApexPages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'No Result Found.'));
             toShowErrorMsg = true;
             System.debug('*******>>'+toShowErrorMsg);
             errorMsg = 'No Result Found.';
         }
    }
 
    public List<WrITArticles> lstITArticle {get;set;}
    public class WrITArticles {
        public string strFormatDate {get;set;}
        public string strArticleURL {get;set;}
        public string strArticleId {get;set;}
        public string strArticleModifiedDate {get;set;}
        public string strArticleTitle {get;set;}
        public string strArticleModifiedBy {get;set;}
        public string strArticleNumber {get;set;}
    }
    
     /***************************************************************************************
     * @Description - Method to trim the value entered in searchtext                        * 
     * @params String                                                                       *
     * @return String                                                                       * 
     ***************************************************************************************/
    public String callSetIterator(Set<string> strSet) {
       System.Debug('>>9>>'+strSet);
       String strReturn = null;
       for(string strObj : strSet) {
           if(strReturn == null) {
               strReturn = '' + '\''+ '' + strObj.trim() + '' +'\'';
           } else {
               strReturn = strReturn + ',' + '' + '\''+ '' + strObj.trim()+ '' +'\'';
           }                    
       }
       System.Debug('>>10>>'+strReturn);
       return strReturn;
    }
    //Getter And Setter for different fields of case
    public class WrCaseDetail {
        public string id {get;set;}
        public string CaseNumber {get;set;}
        public string Status {get;set;}
        public string CreatedDate {get;set;}
        public string ClosedDate {get;set;}
        public string ProductAssistance {get;set;}
        public string Priority {get;set;}
        public string Subject {get;set;}
        public string TimeSinceCaseOpened {get;set;}
        public string caseownernmame {get;set;}
        public string caseowneremail {get;set;}
        public string contactname {get;set;}
        public string accountname {get;set;}
        public string contactemail {get;set;}
        public string AdditionalCaseWatcher {get;set;}
        public string Severity {get;set;}
        public string description {get;set;}
        public string location {get;set;}
        public WrCaseDetail() {}
    }
}