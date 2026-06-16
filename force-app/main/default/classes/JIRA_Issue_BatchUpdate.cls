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

global class JIRA_Issue_BatchUpdate implements Database.Batchable<sObject>, Database.AllowsCallouts{

        public string sQuery;
        
        global Database.QueryLocator start(Database.BatchableContext BC){
            try{

                // Get the RecordTypeID of Issue in Jira custom Object
                ID RecTypId = Schema.SObjectType.JIRA_Case__c.getRecordTypeInfosByName().get('Issue').getRecordTypeId();   

                //Generate Query to be retrive in Jira Custom Object
                //sQuery = 'SELECT id, Issue_Id__c, Issue_Type__c, Status__c  FROM JIRA_Case__c WHERE Status__c != \'Closed\' AND RecordType.Name = \'Issue\' AND ID = \'a5M290000004HmM\' ';
                sQuery = 'SELECT id, Issue_Id__c, Issue_Type__c, Status__c  FROM JIRA_Case__c WHERE Status__c != \'Closed\' AND RecordType.Name = \'Issue\' ';

                system.debug('MY QUERY >>> ' + sQuery);
                system.debug('MY QUERY VALUE >>> ' + Database.getQueryLocator(sQuery));

                //Retrieve the list of Jira record.. This will be use to call out from Jira application
                return Database.getQueryLocator(sQuery);       

            }catch(Exception ex){
                system.debug('MY ERROR ON START - '+ex.getLineNumber() +' --- '+ex.getMessage() );
                system.debug('#### Error on line - '+ex.getLineNumber());
                system.debug('#### Error message - '+ex.getMessage());
                return null;
            }
        }

        global void execute(Database.BatchableContext BC, list<sObject> Scope){

            map<string, JIRA_Case__c> mIssueIdJira = new map<String, JIRA_Case__c>();
            string sIssueId = '';

            system.debug('MY SCOPE>>> ' + Scope);

            try{
                for(sObject objScope: Scope){
                    JIRA_Case__c jIssue = (JIRA_Case__c)objScope;
                    
                    if(jIssue.Issue_Id__c != NULL && jIssue.Issue_Id__c != ''){
                        if(sIssueId == ''){
                            sIssueId = jIssue.Issue_Id__c;
                        }else{
                            sIssueId = sIssueId + ',' + jIssue.Issue_Id__c;
                        }

                        mIssueIdJira.put(jIssue.Issue_Id__c, jIssue);
                    }

                }

                //Call Process Issue ID
                if(sIssueId != ''){ 

                    system.debug('MY ISSUE/JIRA >>> ' + mIssueIdJira);

                    ProcessIssue(sIssueId, mIssueIdJira);
                }

            }catch(Exception ex){
                system.debug('MY ERROR ON EXECUTE - '+ex.getLineNumber() +' --- '+ex.getMessage() );
                system.debug('#### Error on line - '+ex.getLineNumber());
                system.debug('#### Error message - '+ex.getMessage());
            }              
        }


        public void ProcessIssue(string sIssueId, map<string, JIRA_Case__c> mIssueIdJira){
            if(sIssueId!= ''){

                system.debug('MY ISSUE ID>>> ' + sIssueId);

                //Call the Middleware webservice
                httpResponse resUpdate = new httpResponse();
                resUpdate = GetJiraIssue(sIssueId);
                                
                system.debug('MY REST UPDATE>>> ' + resUpdate );

                //Deserialize Returned from JIRA middleware
                JIRA_JSONDeserialize responseData;
                if(test.isRunningTest()){
                    JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                    responseData = (JIRA_JSONDeserialize) System.JSON.deserialize(gm.getJasonString(), JIRA_JSONDeserialize.class); 
                }else{
                    responseData = (JIRA_JSONDeserialize) System.JSON.deserialize(resUpdate.getBody(), JIRA_JSONDeserialize.class); 
                }

                system.debug('MY RESPONSE DATA>>> ' + responseData );

                //Update JiraCase and Case
                Update_JiraCase_Case(responseData, mIssueIdJira);

            }
        }

        public httpResponse GetJiraIssue(string sIssueId){

            boolean bProd=false;
            httpResponse resUpdate = new httpResponse();
            JIRA_GlobalMethods gm = new JIRA_GlobalMethods();

            if(UserInfo.getOrganizationId() == HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2')) {
                bProd = true;
            }    

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
            return resUpdate;
        }

        public void Update_JiraCase_Case(JIRA_JSONDeserialize responseData, map<string, JIRA_Case__c> mIssueIdJira){    
        
            
            list<JIRA_Case__c> lJiraCaseforUpdate = new list<JIRA_Case__c>();
            list<Case> lCasesforUpdate = new list<Case>();

            for(JIRA_JSONDeserialize.cls_data cd: responseData.data){

                JIRA_Case__c jc = new JIRA_Case__c();

                system.debug('MY JIRA ID TO UPDATE>>> ' +  mIssueIdJira.get(cd.Id).Id);
                system.debug('MY JIRA TO UPDATE>>> ' +  mIssueIdJira.get(cd.Id));

                jc.Id = mIssueIdJira.get(cd.Id).Id;                               

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
                update lJiraCaseforUpdate;
                
                map<String,Id> mJKeyJiraId = new map<String, Id>();
                set<Id> JiraCaseId = new set<Id>();

                // Case 04516479 - Issue on Jira # not populating - START
                map<Id, string> mJiraCaseIssueKey = new map<Id,String>();
                
                for(JIRA_Case__c jc: lJiraCaseforUpdate){
                    JiraCaseId.add(jc.Id);
                    mJKeyJiraId.put(jc.Issue_Key__c, jc.Id);
                    mJiraCaseIssueKey.put(jc.Id, jc.Issue_Key__c);
                }

                list<Case> lCaseToUpdate = new list<Case>();
               
                for(Case c: [Select Id, CaseNumber, Jira_Case__c, Jira_Link__c, Jira__c from Case where Jira_Case__c IN: JiraCaseID]){
                    
                    boolean bProd=false;
                    JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
                    if(UserInfo.getOrganizationId() == HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2')) {
                        bProd = true;
                    }  
                    
                    if(c.Jira__c == mJiraCaseIssueKey.get(c.Jira_Case__c) 
                        && c.Jira_Case__c == mJKeyJiraId.get(c.Jira__c) 
                        && c.Jira_Link__c == gm.getJirBaseaURL(bProd) + c.Jira__c){
                        continue;
                    }
                    c.Jira__c = mJiraCaseIssueKey.get(c.Jira_Case__c);
                    c.Jira_Case__c = mJKeyJiraId.get(c.Jira__c);
                    c.Jira_Link__c = gm.getJirBaseaURL(bProd) + c.Jira__c;
                    lCaseToUpdate.add(c);                    
                }
                // Case 04516479 - Issue on Jira # not populating - END

                if(lCaseToUpdate.size()>0){
                    triggerHandler.BY_PASS_CASE_ON_UPDATE();    
                    update lCaseToUpdate;
                }
            }

        }

        global void finish(Database.BatchableContext BC){}


    }