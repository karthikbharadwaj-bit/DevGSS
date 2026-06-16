/*       
* Created By    : Vishal
* Created Date  : 07-05-2020
* Description   : Controller class for Case_Create_Update_JIRA_Issue lightning component
* Test Class    :  Test_Case_RC_AccountController    

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public  class Case_Create_Update_JIRAController {
    @AuraEnabled
    public static String loadUserAndCase(String userId, String recordId){
        User usr = new User();
        Case cse =  new Case();
        String resultmessage;
        String resultstate;
        String combinedresult;
        try{
            if(userId != NULL && recordId != NULL){
                usr = [select id, name, ProfileId, profile.Name from User where id =: userId];
                cse = [select id, Jira__c from Case where id=: recordId];
            }
            String profname = usr.profile.Name;
            //Addin logic as part of profile consolidation-- To check if user's permission set has Custom Permission
            Boolean hasCustomPermissionERT = FeatureManagement.checkPermission('Support_Agent_ERT_permission');
			system.debug('hasCustomPermissionERT'+hasCustomPermissionERT);
            Boolean hasCustomPermissionDirector = FeatureManagement.checkPermission('Support_Director_permission');
			system.debug('hasCustomPermissionDirector'+hasCustomPermissionDirector);
            Boolean hasCustomPermissionUSEnterprise = FeatureManagement.checkPermission('Support_US_Enterprise_Permission');
			system.debug('hasCustomPermissionUSEnterprise'+hasCustomPermissionUSEnterprise);
            
            //EU phase 3 Changes - START
            List<String> allProfValues=new List<String>();//------ created to store service Engr, sales operations lighng and their EU restricted profiles
            List<EU_Component_reference__mdt> profileList = new  List<EU_Component_reference__mdt>([ Select DeveloperName, Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%Case_Create_Update_JIRAController%']);
            for(EU_Component_reference__mdt currProfData: profileList){
                if(currProfData.DeveloperName=='Service_Engineer_Manager'){
                    allProfValues.addAll(currProfData.Values__c.split(','));
                } 
            }
            
            if(profname == 'Service Engineer - Agent'
               //|| profname == 'Service Engineer - Manager' 
               || allProfValues.contains(profname)
               || profname == 'Support Agent - T1 USA'
               || profname == 'Support T3'
               || profname == 'Support Agent - T3 (Data Capture)'
               || profname == 'Support Agent- T3 USA'
               || profname == 'System Administrator'
               //|| profname == 'Sales Operations Lightning'
               //|| profname == 'Sales Operations Lightning - EU Restricted'
               //EU Phase 3 Changes - END
               || profname == 'Support T2' ||  hasCustomPermissionERT ||  hasCustomPermissionDirector || profname == 'Support T3'
               ||  hasCustomPermissionUSEnterprise
              )
              {
                  
                  if(String.isBlank(cse.Jira__c)){
                      resultstate = 'ERROR';
                      resultmessage = 'Please provide Jira #';
                      combinedresult = resultstate+'/'+resultmessage;
                      return combinedresult;
                  }else{
                      String jiraname = cse.Jira__c;                      
                      resultmessage = JIRA_Issue_CreateUpdate.CreateUpdate_Issue(jiraname, cse.id);
                      combinedresult = '/'+resultmessage;
                      return combinedresult;                    
                  }
              }else{
                  resultstate = 'ERROR';
                  resultmessage = 'You are not allowed for this transation';
                  combinedresult = resultstate+'/'+resultmessage;
                  return combinedresult;                                                          
              }
        }catch(Exception e){
            resultstate = 'ERROR';
            resultmessage = 'Unable to create or update Jira issue. Error during processing.';
            combinedresult = resultstate+'/'+resultmessage;
            return combinedresult;
        }
    }
}