global class JIRA_CreateUpdate_Termination{

    public static String sBaseURL ='';
    public static String sEndPoint = '';
    public static String sAction = '';
    public static String sMethod = '';
    public static String sApi = '';
    public static String sCType ='';
    public static Boolean bProd = false;

    static JIRA_JSONDeserialize responseData {get;set;}
    public static map<String, Id> mJiraCaseIssue = new map<String, Id>();


    @future(callout=true)
    public static void fromTrigger(Id CaseId){
        CreateUpdate_Termination(CaseId);
    }

    webService static string CreateUpdate_Termination(Id CaseId) {     
         
        try{

            if(UserInfo.getOrganizationId() == HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2')) {
                bProd = true;
            }

            Case myCase = [SELECT Id, Subject,  CaseNumber, Description,                                
                                    (SELECT Termination_Case__c, Status__c, Priority__c, Created_Date__c, 
                                        Action_Taken__c, Resolution_Date__c, 
                                        Issue_Id__c, Issue_Key__c, Issue_Type__c,
                                        Project_Id__c, Project_Key__c, Project_Name__c, 
                                        Reporter_Name__c, Reporter_Email__c, Reporter_Display_Name__c, 
                                        Assignee_Name__c, Assignee_Email__c, Assignee_Display_Name__c
                                    FROM JIRA_Cases__r)
                                FROM CASE
                                WHERE Id =: CaseId limit 1];

            list<JIRA_Case__c> lJiraCase = myCase.getsObjects('JIRA_Cases__r');

            String sIssueKeyToUpdate = '';
            boolean bCreateOnly = false;

            if(lJiraCase != NULL && lJiraCase.size() > 0){
                for(JIRA_Case__c jc: lJiraCase){
                    if(sIssueKeyToUpdate == ''){
                        sIssueKeyToUpdate = jc.Issue_Key__c;
                        mJiraCaseIssue.put(jc.Issue_Id__c,jc.Id);
                    }else{
                        sIssueKeyToUpdate = sIssueKeyToUpdate + ',' + jc.Issue_Key__c;
                        mJiraCaseIssue.put(jc.Issue_Id__c,jc.Id);

                    }
                }
            }else{
                bCreateOnly = true;
            }
          
            system.debug('MY CASE >>> ' + myCase);
            system.debug('MY CREATE ONLY >>> ' + bCreateOnly);
            system.debug('MY ISSUE KEY TO UPDATE >>> ' + sIssueKeyToUpdate);
            system.debug('MY MAP JIRA >>> ' + mJiraCaseIssue);

            string StrResult ='';
            if(bCreateOnly || sIssueKeyToUpdate != ''){                
                StrResult = CreateUpdateJiraCases(myCase, bCreateOnly, sIssueKeyToUpdate);
            }

            return StrResult ;

        }Catch (exception e){
            return 'Unable to Create/Update Jira Cases.';
        }

    }
    

    webService static string CreateUpdateJiraCases(Case c, boolean bCreateOnly, String sIssueKeyToUpdate){
        
        string strResult = 'Jira Cases are Created/Updated.';
        
        httpResponse resCreate = new httpResponse();
        httpResponse resUpdate = new httpResponse();

        if(bCreateOnly){
            PopulateVariable('Create'); 
            JIRA_HTTPCallout jCall = new JIRA_HTTPCallout();
            jCall.SetBaseURL(sBaseURL);
            jCall.SetEndPoint(sEndPoint);
            jCall.SetAction(sAction + '/' + c.CaseNumber);
            jCall.SetMethod(sMethod);

            list<String> lHeader = new list<string>();
            lHeader.add(sApi);
            lHeader.add(sCType);
            jCall.SetHeader(lHeader);    

            resCreate = jCall.callout();            
        }

        if(sIssueKeyToUpdate != ''){
 
            PopulateVariable('Update'); 
            JIRA_HTTPCallout jCall = new JIRA_HTTPCallout();
            jCall.SetBaseURL(sBaseURL);
            jCall.SetEndPoint(sEndPoint);
            jCall.SetAction(sAction);
            jCall.SetMethod(sMethod);

            list<String> lHeader = new list<string>();
            lHeader.add(sApi);
            lHeader.add(sCType);
            jCall.SetHeader(lHeader);    

            list<String> lBody = new list<string>();
            lBody.add('issue_id=' + sIssueKeyToUpdate);         
            jCall.SetBody(lBody);

            resUpdate = jCall.callout();
         
        }


        list<JIRA_Case__c> lJiraCaseCreate = new list<JIRA_Case__c>();
        list<JIRA_Case__c> lJiraCaseUpdate = new list<JIRA_Case__c>();


        if(bCreateOnly){
            if(Test.isRunningTest()){
                JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                lJiraCaseCreate = GetJiraCase(gm.getJasonString(), c, false);  
            }else{
                lJiraCaseCreate = GetJiraCase(resCreate.getBody(), c, false);      
                if(lJiraCaseCreate.size() <= 0){
                    strResult = 'Unable to Create/Update Jira Cases.';
                } 
            }    
        }        

        if(sIssueKeyToUpdate != ''){
            if(Test.isRunningTest()){
                JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                lJiraCaseUpdate = GetJiraCase(gm.getJasonString(), c,true);    
            }else{
                lJiraCaseUpdate = GetJiraCase(resUpdate.getBody(), c,true);   
                if(lJiraCaseUpdate.size() <= 0){
                    strResult = 'Unable to Create/Update Jira Cases.';
                }        
            }   
                  
        }

        system.debug('MY LIST JIRA TO CREATE >>> ' + lJiraCaseCreate);
        system.debug('MY LIST JIRA TO UPDATE >>> ' + lJiraCaseUpdate);


        if(lJiraCaseCreate.size()>0){
            insert lJiraCaseCreate;
        }
        if(lJiraCaseUpdate.size()>0){
            update lJiraCaseUpdate;
        }
        
        return strResult;

    }   


    webService static void PopulateVariable(String myAction){


        JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
        sBaseURL =gm.GetBaseURL(bProd);
        sApi = 'apikey~' + gm.GetAPIKey(bProd);
       
        if(myAction == 'Create'){
            sAction = 'issue-sfsearch';
            sMethod = 'POST';
        }
        if(myAction == 'Update'){
            sAction = 'issue-multiple';
            sMethod = 'POST';
        }

        sEndPoint = 'webservice/jirasfdc/';
        sCType ='Content-type~application/x-www-form-urlencoded';
    }



    webService static list<JIRA_Case__c> GetJiraCase(String sJson, Case c, Boolean bUpdate){
        
        responseData = (JIRA_JSONDeserialize) System.JSON.deserialize(sJson, JIRA_JSONDeserialize.class); 

        system.debug('MY RESPONSE DATA >>> ' + responseData);

        list<JIRA_Case__c> lJiraCase = new list<JIRA_Case__c>();

        for(JIRA_JSONDeserialize.cls_data cd: responseData.data){

                JIRA_Case__c jc = new JIRA_Case__c();

                if(bUpdate){
                    if(mJiraCaseIssue.containsKey(cd.Id)){
                        jc.Id = mJiraCaseIssue.get(cd.Id);
                    }
                }
                jc.Name = cd.Key;
                jc.Termination_Case__c = c.Id;
                jc.Status__c = cd.status.Name;
                jc.Priority__c = cd.priority.name;

                JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                jc.Created_Date__c = gm.FormatDate(cd.created);
                jc.Resolution_Date__c = gm.FormatDate(cd.resolutionDate);

                jc.Summary__c = cd.summary;
                jc.Description__c = cd.description;
                
                jc.Issue_Id__c = cd.Id;
                jc.Issue_Key__c = cd.Key;
                jc.Issue_Type__c = cd.issueType.name;
                
                jc.Project_Id__c = cd.project.id;
                jc.Project_Key__c = cd.project.key;
                jc.Project_Name__c = cd.project.name;

                jc.Reporter_Name__c = cd.reporter.name;
                jc.Reporter_Email__c = cd.reporter.email;
                jc.Reporter_Display_Name__c = cd.reporter.displayName;

                jc.Assignee_Name__c = cd.assignee.name;
                jc.Assignee_Email__c = cd.assignee.email;
                jc.Assignee_Display_Name__c = cd.assignee.displayName;
                               
                if(cd.Comments != NULL){

                    string sComments = ''; 
                    for(Integer i = 0; i < cd.Comments.size(); i++){

                        sComments = sComments + 'NAME: ' + cd.Comments[i].name;
                        sComments = sComments + ' EMAIL: ' + cd.Comments[i].email;
                        sComments = sComments + ' DISPLAY NAME: ' + cd.Comments[i].displayName + ' \n';
                        sComments = sComments + cd.Comments[i].body + ' \n';
                        sComments = sComments + 'CREATED DATE: ' + cd.Comments[i].created + ' \n';
                        sComments = sComments + 'UPDATED DATE: ' + cd.Comments[i].updated + ' \n';
                        sComments = sComments + '--------------------------------------------------------------'; 
                        sComments = sComments + '-------------------------------------------------------------- \n \n';
                    }    

                    jc.Action_Taken__c = sComments;               
                }                
                
                if(cd.fixVersions != NULL){
                    jc.Fix_Versions__c = cd.fixVersions[0].name;               
                }  

                // Case - 04516479 - Get only resoulution name - Start
                if(cd.resolution.name != ''){ 
                    jc.Resolution__c = cd.resolution.name;    
                }else{
                    jc.Resolution__c = 'Unresolved';    
                }   
                // Case - 04516479 - Get only resoulution name - End

                /*    
                if(cd.resolutions != NULL){
                    string sRes = ''; 
                    for(Integer i = 0; i < cd.resolutions.size(); i++){

                        sRes = sRes + 'SELF: ' + cd.resolutions[i].self + ' \n';
                        sRes = sRes + ' ID: ' + cd.resolutions[i].id + ' \n';
                        sRes = sRes + ' DESCRIPTION: ' + cd.resolutions[i].description + ' \n';
                        sRes = sRes + 'NAME: ' + cd.resolutions[i].name + ' \n';
                        sRes = sRes + '--------------------------------------------------------------'; 
                        sRes = sRes + '-------------------------------------------------------------- \n \n';
                    }    

                    jc.Resolution__c = sRes;     
                }
                */

                lJiraCase.add(jc);
        }


        return  lJiraCase;
    }


}