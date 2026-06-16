/*
Name: ITHelpDeskPortal.cls
Created by: Nikita Sergienko
Created date: 2/10/2016
Description: controller class for IT Helpdesk Portal main page
*/
public class ITHelpDeskPortalNew {

    //case pagination
    public Boolean hasPrevCases {get; set;}
    public Boolean hasNextCases {get; set;}
    public Integer currCasePage {get; set;}
    public Integer casePages {get; set;}
    public static Integer casePageSize = 10;

    //legal requests pagination
    public Boolean hasPrevRequests {get; set;}
    public Boolean hasNextRequests {get; set;}
    public Integer currRequestPage {get; set;}
    public Integer requestPages {get; set;}
    public static Integer requestPageSize = 10;

    //articles pagination
    public Boolean hasPrevArticles {get; set;}
    public Boolean hasNextArticles {get; set;}
    public Integer currArticlePage {get; set;}
    public Integer articlePages {get; set;}
    public static Integer articlePageSize = 10;

    //status color
    public String systemStatusColor {get; set;}
    public List<String> activeOutages {get; set;}
    public List<String> resolvedOutages {get; set;}

    public String strContact {get; set;}
    public Boolean isUserHR {get; set;}
    String loggedInUserId;

    public List<Case> results {get; set;}
    public List<WrCaseDetail> userCasesList {get; set;}
    List<String> listWatchers;
    public List<WrLegalReqDetail> lstLegalReqDetail {get; set;}
    public List<WrITArticles> lstITArticle {get;set;}

    //error info
    public String errorMsg {get; set;}
    public Boolean toShowErrorMsg {get; set;}

    //search
    public String searchText {get; set;}
    //to prevent searches with the same request
    String prevSearchText;

    //For creating new cases
    public String newCaseSubject {get; set;}
    public String newCaseDescription {get; set;}

    //support classes
    //Case layout class
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
        public string recordtypename {get;set;}
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

    //Legal Request layout class
    public class WrLegalReqDetail {
        public String id {get;set;}
        public String objname {get;set;}
        public String Status {get;set;}
        public Date DraftDate {get;set;}
        public Date SubmitDate {get;set;}
        public String recordTypeName{get;set;}
        public WrLegalReqDetail() {}
    }

    //Article layout class
    public class WrITArticles {
        public string strFormatDate {get;set;}
        public string strArticleURL {get;set;}
        public string strArticleId {get;set;}
        public string strArticleModifiedDate {get;set;}
        public string strArticleTitle {get;set;}
        public string strArticleModifiedBy {get;set;}
        public string strArticleNumber {get;set;}
    }           

    //Constructor
    public ITHelpDeskPortalNew(){
        getUserInfo();
        getCases(true);
        getLegalRequestWatchers();
        getArticles(true);
        getStatusColor();
    }

    //Getting user's info. strContact and loggedInUserId are used for search
    //isUserHR is selfexplanatory. Use this to hide/show HR-only buttons
    public void getUserInfo(){
        loggedInUserId = UserInfo.getUserId();
        User userInfoObj = [select email,contactId from User where Id = :loggedInUserId limit 1];


        strContact = [SELECT Id,FirstName,AccountId,LastName,Phone,Email FROM Contact 
                        WHERE (Email =:userInfoObj.email.trim() OR Id =:userInfoObj.contactId) 
                        and Account.Name = 'RC Internal' limit 1].Id;

        List<Employee__c> employeeUserInfo = [select Department__c from Employee__c where Email__c = :userInfoObj.email limit 1];

        if(employeeUserInfo != null && employeeUserInfo.size()> 0) {
            if(!string.isBlank(employeeUserInfo[0].Department__c) && employeeUserInfo[0].Department__c.containsIgnoreCase('HR')) {
                isUserHR = true;
            }
        }
    }

    //Get list of user's cases
    //@Param newSearch indicates if pagination should be recalculated. 
    //True - new search, pagination starts from 1. False - aquiring prev/next page in selection
    public void getCases(Boolean newSearch){
        results = new List<Case>();
        userCasesList = new List<WrCaseDetail>();
        try{
            String sfilter = '';

            if (searchText != null && searchText != ''){
                sfilter = 'AND (CaseNumber LIKE \'%' + String.escapeSingleQuotes(searchText.trim()) + '%\' OR Subject LIKE \'%' +String.escapeSingleQuotes(searchText.trim()) + '%\')';
            }

            if (newSearch){
                currCasePage = 1;
                hasPrevCases = false;

                String cquery = 'SELECT count(id) FROM Case '+
                                'WHERE (ContactId =\'' + strContact + '\' ) ' +
                                'AND (RecordType.Name = \'IT Helpdesk\' OR  RecordType.Name = \'IT New Hire Request\' OR  RecordType.Name = \'Internal Business Services\') ' + sfilter;

                AggregateResult[] ar = Database.query(cquery);
                Integer caseCount = Integer.valueOf(ar[0].get('expr0'));
                casePages = (caseCount / casePageSize) + ((Math.mod(caseCount, casePageSize) > 0) ? 1 : 0);
                hasNextCases = (currCasePage < casePages);
            }

            Integer offset = casePageSize * (currCasePage - 1);

            String squery = 'SELECT Id,CaseNumber,Subject,Status,ContactId,Priority, ClosedDate,CreatedDate,Contact.Name,Case.Owner.Name,Case.RecordType.Name,' +
                            'Time_Since_Case_Opened__c, Request_Subtype_2__c, Description FROM Case ' +
                            'WHERE (ContactId =\'' + strContact + '\') ' +
                            'AND (RecordType.Name = \'IT Helpdesk\' OR  RecordType.Name = \'IT New Hire Request\' OR  RecordType.Name = \'Internal Business Services\') ' + sfilter + 
                            ' order by createddate desc LIMIT ' + casePageSize + ' OFFSET ' + offset;

            results = Database.query(squery);

            for(Case caseObj : results) {
                WrCaseDetail searchCase = new WrCaseDetail();
                searchCase.id = caseObj.id;
                searchCase.caseownernmame = caseObj.Owner.Name;
                searchCase.recordtypename = caseObj.RecordType.Name;
                searchCase.CaseNumber = caseObj.CaseNumber;
                searchCase.Subject= caseObj.Subject;
                searchCase.Status = caseObj.Status;

                userCasesList.add(searchCase);
            }
        }catch(Exception e){
            System.debug(e + '(' + e.getLineNumber() + ')');
        }
    }

    //Pagination
    public PageReference getNextCases(){
        if (hasNextCases){
            currCasePage ++;
            getCases(false);
            hasNextCases = (currCasePage >= casePages) ? false : true;
            hasPrevCases = true;
        }
        return null;        
    }

    //Pagination
    public PageReference getPrevCases(){
        if (hasPrevCases){
            currCasePage --;
            getCases(false);
            hasPrevCases = (currCasePage > 1);
            hasNextCases = true;
        }
        return null;        
    }

    //Get list of legal request watchers' Ids
    //Used in getLegalRequests(), but should be run once
    public void getLegalRequestWatchers(){
        List<Legal_Requests_Watchers__c> lstWatcher = new List<Legal_Requests_Watchers__c>();
        lstWatcher = [SELECT Id, Legal_Requests__c FROM Legal_Requests_Watchers__c Where Advisor_Name__c =:loggedInUserId];
        listWatchers = new List<String>();
        if(lstWatcher != null && lstWatcher.size() > 0){
            for(Legal_Requests_Watchers__c obj : lstWatcher){
                listWatchers.add(obj.Legal_Requests__c);
            }
        }
    }

    //Get list of user's legal requests
    //@Param newSearch indicates if pagination should be recalculated. 
    //True - new search, pagination starts from 1. False - aquiring prev/next page in selection
    public void getLegalRequests(Boolean newSearch){
        List<Legal_Requests__c> lstLegalReq = new List<Legal_Requests__c>();
        lstLegalReqDetail = new List<WrLegalReqDetail>();
        try{
            String sfilter = '';

            if (searchText != null && searchText != ''){
                sfilter = 'AND (CaseNumber LIKE \'%' + String.escapeSingleQuotes(searchText.trim()) + '%\' OR Subject LIKE \'%' + String.escapeSingleQuotes(searchText.trim()) + '%\')';
            }

            String watchersQuery = (listWatchers.size()>0) ? ('Id IN ' + listWatchers + ' OR ') : '';

            if (newSearch){
                currRequestPage = 1;
                hasPrevRequests = false;
                String cquery = 'SELECT count(id) FROM Legal_Requests__c '+
                                'Where ('+ watchersQuery +'OwnerId=\'' + loggedInUserId + '\') ' + sfilter;
                AggregateResult[] ar = Database.query(cquery);
                Integer requestCount = Integer.valueOf(ar[0].get('expr0'));
                requestPages = (requestCount / requestPageSize) + ((Math.mod(requestCount, requestPageSize)>0)?1:0);
                hasNextRequests = (currRequestPage < requestPages);
            }

            Integer offset = requestPageSize * (currRequestPage - 1);

            String squery = 'SELECT Id, Name, Status__c, Draft_Date__c, Submitted_Date__c, Title_of_Invention__c, RecordType.Name, FOSS_Name__c' +
                            ' FROM Legal_Requests__c Where ('+ watchersQuery +'OwnerId=\'' + loggedInUserId + '\') ' + sfilter + 
                            ' order by createddate desc LIMIT ' + requestPageSize + ' OFFSET ' + offset;
            
            lstLegalReq = Database.query(squery);

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
        }catch(Exception e){
            System.debug(e + '(' + e.getLineNumber() + ')');
        }
    }

    //Pagination
    public PageReference getNextRequests(){
        if (hasNextRequests){
            currRequestPage ++;
            getLegalRequests(false);
            hasNextRequests = (currRequestPage >= requestPages) ? false : true;
            hasPrevRequests = true;
        }
        return null;        
    }

    //Pagination
    public PageReference getPrevRequests(){
        if (hasPrevRequests){
            currRequestPage --;
            getLegalRequests(false);
            hasPrevRequests = (currRequestPage > 1);
            hasNextRequests = true;
        }
        return null;        
    }

    //Get list of articles based on search request. If search request is null then no articles are returned
    //@Param newSearch indicates if pagination should be recalculated. 
    //True - new search, pagination starts from 1. False - aquiring prev/next page in selection
    public void getArticles(Boolean newSearch) {
        lstITArticle = new List<WrITArticles>();
        List<KnowledgeArticleVersion> articleList1 = new List<KnowledgeArticleVersion>();
        try{
            String sfilter = '';

            if (searchText != null && searchText != ''){
                sfilter = ' and title Like \'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'' ;
            }

            if (newSearch){
                currArticlePage = 1;
                hasPrevArticles = false;
                String cquery = 'SELECT count(id) FROM KnowledgeArticleVersion ' +
                                'WHERE (PublishStatus = \'online\' and Language = \'en_US\' and ArticleType = \'Knowledge__kav\') ' + sfilter;
                AggregateResult[] ar = Database.query(cquery);
                Integer articleCount = Integer.valueOf(ar[0].get('expr0'));
                articlePages = (articleCount / articlePageSize) + ((Math.mod(articleCount, articlePageSize) > 0) ? 1 : 0);
                hasNextArticles = (currArticlePage < articlePages);
            }

            Integer offset = articlePageSize * (currArticlePage - 1);
            
            

            String squery = 'SELECT Id, title, UrlName,ArticleNumber,LastModifiedDate,LastModifiedBy.Name, LastPublishedDate, KnowledgeArticleId ' +
                  'FROM KnowledgeArticleVersion ' +
                  'WHERE PublishStatus = \'online\' and Language = \'en_US\' and ArticleType = \'Knowledge__kav\'' + sfilter + 
                          ' LIMIT ' + requestPageSize + ' OFFSET ' + offset;
            articleList1 = Database.query(squery);

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
        }catch(Exception e){
            System.debug(e + '(' + e.getLineNumber() + ')');
        }
    }

    //Pagination
    public PageReference getNextArticles(){
        if (hasNextArticles){
            currArticlePage++;
            getArticles(false);
            hasNextArticles = (currArticlePage >= articlePages) ? false : true;
            hasPrevArticles = true;
        }
        return null;        
    }

    //Pagination
    public PageReference getPrevArticles(){
        if (hasPrevArticles){
            currArticlePage--;
            getArticles(false);
            hasPrevArticles = (currArticlePage > 1);
            hasNextArticles = true;
        }
        return null;        
    }

    //Performs a search through cases, legal requests and articles based on a single search request
    public PageReference searchAll(){
        if (searchText != prevSearchText){
            prevSearchText = searchText;
            getCases(true);
            getArticles(true);
        }
        System.debug('casePages ' + casePages);
        return null;
    }                                               

    //Calculating status color based on open/resolved cases with type 'Outage'
    public void getStatusColor(){
        activeOutages = new List<String>();
        resolvedOutages = new List<String>();
        this.systemStatusColor = 'green';
        String info;

        List<Case> caselist =   [SELECT Id, Subject, CaseNumber, Status, Request_Subtype_2__c FROM Case 
                                WHERE (ContactId =:strContact)
                                AND (RecordType.Name ='IT Helpdesk' OR  RecordType.Name ='IT New Hire Request') AND Request_Subtype_2__c='Outage'];

        if ((caselist != null) && (caselist.size() != 0)){
            this.systemStatusColor = 'green';
            for (Case cs : caselist){

                if (cs.Subject!=null){
                    info = String.valueOf(cs.Subject);
                    info = (info.length() > 90) ? (info.substring(0, 89) + '...') : info;
                }else{
                    info = cs.CaseNumber;
                }
                if (cs.Request_Subtype_2__c == 'Outage'){
                    if (cs.Status != 'Resolved' && cs.Status != 'Closed'){
                        activeOutages.add(info);
                    }
                    else if (cs.Status == 'Resolved'){
                        resolvedOutages.add(info);
                    }
                }
            }
            if (activeOutages.size() > 0) {
                this.systemStatusColor = 'red';
            } else if (resolvedOutages.size() > 0) {
                this.systemStatusColor = 'yellow';
            }
        }
    }
}