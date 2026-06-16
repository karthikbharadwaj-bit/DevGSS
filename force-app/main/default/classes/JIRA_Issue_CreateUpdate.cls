/****************************************************************************************** 

UPDATE:
by              eugenebasianomutya
date            4/12/2016
case            04516479
description     
                NEW FIELDS:
                Affects Versions - comma-separated value
                Exists on Productions - Boolean
                Released Fixed - String

                BUG FIXED:
                Salesforce Jira# field not updating when the scheduled job runs

                NEW FEATURE:
                Future call when Case Jira # field is populated/updated
                Remove/Hide Description and Action Taken(comments)

******************************************************************************************/

global class JIRA_Issue_CreateUpdate{


    public static map<string, JIRA_Case__c> mIssueIdJira = new map<String, JIRA_Case__c>();
    public static map<string, list<Case>> mIssueIdCases = new map<string, list<Case>>();
    public static Case myCase = new Case();
    public static Jira_case__c myJiraCase = new Jira_Case__c();


    @future(callout=true)
    public static void fromTrigger(String JiraKey, Id CaseId){
        CreateUpdate_Issue(JiraKey, CaseId);
    }


    webService static string CreateUpdate_Issue(String JiraKey, Id CaseID) {     
        boolean bUpdate = false;
        string sIssueId='';

        Id RecTypId;


        RecTypId = Schema.SObjectType.JIRA_Case__c.getRecordTypeInfosByName().get('Issue').getRecordTypeId();   

        list<Jira_case__c> lJiraCase = new list<Jira_case__c>();
        list<Case> lCase = new list<Case>();

        lJiraCase = [Select Id, Issue_Id__c, Issue_Key__c FROM JIRA_Case__c WHERE RecordTypeID =: RecTypId AND Issue_Key__c =: JiraKey limit 1];
        lCase = [Select Id, Jira__c, JIRA_Case__c, Jira_Link__c FROM Case c WHERE Id =: CaseID];

        myCase = lCase[0];
        sIssueId = myCase.Jira__c;
        
        if(lJiraCase.size()>0){
            bUpdate = true;
            myJiraCase = lJiraCase[0];
        }


        boolean bProd=false;            
        JIRA_GlobalMethods gm = new JIRA_GlobalMethods();

        if(UserInfo.getOrganizationId() == HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2')){
            bProd = true;
        }    

        httpResponse resUpdate = new httpResponse();
        JIRA_HTTPCallout jCall = new JIRA_HTTPCallout();
        jCall.SetBaseURL(gm.GetBaseURL(bProd));
        jCall.SetEndPoint('webservice/jirasfdc/');
        jCall.SetAction('issue-multiple');
        jCall.SetMethod('POST');

        list<String> lHeader = new list<string>();
        lHeader.add('apikey~' + gm.GetAPIKey(bProd));   
        lHeader.add('Content-type~application/x-www-form-urlencoded');
        jCall.SetHeader(lHeader);    

        list<String> lBody = new list<string>();
        lBody.add('issue_id=' + sIssueId);         
        jCall.SetBody(lBody);

        resUpdate = jCall.callout();

        string sDeserializeResult = '';

        if(Test.isRunningTest()){            
            sDeserializeResult = Update_JiraCase_Case(gm.getJasonString(), bUpdate, RecTypId);  
            sDeserializeResult = errHandler(gm.getJasonStringError());            
        }else{
            sDeserializeResult = Update_JiraCase_Case(resUpdate.getBody(), bUpdate, RecTypId);      
            if(sDeserializeResult != 'Success'){
                sDeserializeResult = errHandler(resUpdate.getBody());   
            } 
        }   

        return sDeserializeResult;

    }

    webservice static string errHandler(String sJson){
        System.debug(' ** JSON RETURNING ' + sJson);
        string sResult = 'Jira connection failed';
        try{                
            JIRA_JSONDeserialize_errHandler responseDataErr;
            responseDataErr = (JIRA_JSONDeserialize_errHandler) System.JSON.deserialize(sJson, JIRA_JSONDeserialize_errHandler.class); 

            if(responseDataErr.Status == 'success'){                    
                for(JIRA_JSONDeserialize_errHandler.cls_data cd: responseDataErr.data){
                    Boolean result=cd.message.contains('Failed to get issue:');                        
                    if(result){
                        sResult = 'The Jira number you have entered is invalid';
                    }
                    break;
                }
            }
            return sResult;               
        }Catch(exception ex){
            System.debug(' ### ERROR IS FOUND = ' + ex);
            return sResult;     
        }
    }

    webService static string Update_JiraCase_Case(String sJson, Boolean bUpdate, ID RecTypId){
        
        try{
            JIRA_JSONDeserialize responseData;
            responseData = (JIRA_JSONDeserialize) System.JSON.deserialize(sJson, JIRA_JSONDeserialize.class); 
            
            list<JIRA_Case__c> lJiraCaseforUpdate = new list<JIRA_Case__c>();

            string JcToCreate;

            for(JIRA_JSONDeserialize.cls_data cd: responseData.data){

                    JIRA_Case__c jc = new JIRA_Case__c();

                    if(bUpdate){
                        jc.Id = myJiraCase.Id;  
                    }

                    jc.Name = cd.Key;
                    jc.Status__c = cd.status.Name;
                    jc.Priority__c = cd.priority.name;

                    JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                    jc.Created_Date__c = gm.FormatDate(cd.created);
                    jc.Resolution_Date__c = gm.FormatDate(cd.resolutionDate);

                    jc.Summary__c = cd.summary;
                    
                    // Case - 04516479  -  Remove/Hide Description - Start
                    // jc.Description__c = cd.description;
                    // Case - 04516479  -  Remove/Hide Description - End
                    
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
                    jc.RecordTypeID = RecTypId;

                    // Case - 04516479  -  New Fields - Start
                    jc.Exist_on_Production__c = cd.exist_on_production == 'Yes' ? True : False;
                    jc.Release_Fixed__c = cd.release_fixed;
                    // Case - 04516479  -  New Fields - End                                                       

                    // Case - 04516479  -  Remove/Hide Action Taken - Start
                    // I rather not copy the value to Salesforce 
                    /*
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
                    */
                    // Case - 04516479  -  Remove/Hide Action Taken - END
                    
                    // Case - 04516479  - (proposed change) show all as comma-separated values - START
                    if(cd.fixVersions != NULL){

                        string sFixVers = ''; 
                        for(Integer i = 0; i < cd.fixVersions.size(); i++){
                            if(sFixVers==''){
                                sFixVers = cd.fixVersions[i].name;
                            }else{
                                 sFixVers = sFixVers + ', ' +  cd.fixVersions[i].name;
                            }                    
                        }
                        jc.Fix_Versions__c = sFixVers;                   
                    }           
                    // Case - 04516479  - (proposed change) show all as comma-separated values - END

                    // Case - 04516479  - New field version - START
                    if(cd.versions != NULL){
                        string sVers = ''; 
                        for(Integer i = 0; i < cd.versions.size(); i++){
                            if(sVers==''){
                                sVers = cd.versions[i].name;
                            }else{
                                 sVers = sVers + ', ' +  cd.versions[i].name;
                            }                    
                        }
                        jc.Affects_Version_s__c = sVers;
                    }
                    // Case - 04516479  - New field version - END

                    // Case - 04516479 - Get only resoulution name - Start
                    if(cd.resolution != NULL){
                        if(cd.resolution.name != NULL){ 
                            jc.Resolution__c = cd.resolution.name;    
                        }else{
                            jc.Resolution__c = 'Unresolved';    
                        }   
                    }
                    // Case - 04516479 - Get only resoulution name - End

                    lJiraCaseforUpdate.add(jc);

            }

            if(lJiraCaseforUpdate.size()>0){
                upsert lJiraCaseforUpdate;
            }

            boolean bProd=false;
            JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
            if(UserInfo.getOrganizationId() == HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2')){
                bProd = true;
            }  

            //Update the Case
            myCase.Jira__c = lJiraCaseforUpdate[0].Issue_Key__c;
            myCase.Jira_Link__c = gm.getJirBaseaURL(bProd) + lJiraCaseforUpdate[0].Issue_Key__c;
            myCase.JIRA_Case__c = lJiraCaseforUpdate[0].Id;        
            update myCase;

            return 'Success';

        }catch (exception e){
            return 'Jira connection failed';        
        }
    
    }

}