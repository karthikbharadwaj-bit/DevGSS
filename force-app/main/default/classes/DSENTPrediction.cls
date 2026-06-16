public class DSENTPrediction {
    // getCurrentUserDetailsForLWC - to get the fields to be displayed for the DSENT Prediction record form when trying to create record from the case object
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getCurrentUserDetailsForLWC(String recordId){
        Map<String,String> mapWithDetails=new Map<String,String>();
        if(recordId != null)
        {
            List<DSENT_Prediction_Details__mdt> currentAccessGiven = new List<DSENT_Prediction_Details__mdt>([SELECT Apps__c,Profiles__c,Object_Name__c,Component_Title__c,Record_Type_Names__c,Fields__c FROM DSENT_Prediction_Details__mdt WHERE DeveloperName='DSENTRestriction']);
            if(UserInfo.getUserId()!=null){
                UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
                User usr = [Select Id, Profile.Name,country__c from User where Id=:UserInfo.getUserId()];
                if(userAppInfo!=null && usr!=null){
                    AppDefinition appDefinition = [SELECT DurableId,DeveloperName,Label FROM AppDefinition Where DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
                    if(appDefinition!=null){
                        Case checkRecordTypeOfCase = new Case();
                        checkRecordTypeOfCase = [SELECT Id,RecordType.DeveloperName FROM Case WHERE Id=:recordId LIMIT 1][0];
                        if(currentAccessGiven.size()>0 && currentAccessGiven != null)
                        {
                            String objectApiName = currentAccessGiven[0].Object_Name__c!=null?currentAccessGiven[0].Object_Name__c.trim():'';
                            String componentTitle = currentAccessGiven[0].Component_Title__c!=null?currentAccessGiven[0].Component_Title__c.trim():'';
                            mapWithDetails.put('objectApiName',objectApiName);
                            mapWithDetails.put('componentTitle',componentTitle);  
                            String fieldsToDisplay=currentAccessGiven[0].Fields__c.replace('\r\n','').trim();
                            mapWithDetails.put('fieldsToDisplay',fieldsToDisplay);
                            Boolean isRecordTypePresent = ((currentAccessGiven[0].Record_Type_Names__c != null)&&(checkRecordTypeOfCase!=null))?(((currentAccessGiven[0].Record_Type_Names__c.replace('\r\n','').trim().split(',').contains(checkRecordTypeOfCase.RecordType.DeveloperName)))?true:false):false;
                            Boolean isAppPresent = currentAccessGiven[0].Apps__c !=null?(((currentAccessGiven[0].Apps__c.replace('\r\n','').trim().split(',').contains(appDefinition.DeveloperName)) && (currentAccessGiven[0].Apps__c != null))?true:false):false;
                            Boolean isProfilePresent = currentAccessGiven[0].Profiles__c !=null?((currentAccessGiven[0].Profiles__c.replace('\r\n','').trim().split(',').contains(usr.Profile.Name))?true:false):false;
                            mapWithDetails.put('isAppPresent',String.valueOf(isAppPresent));
                            mapWithDetails.put('isProfilePresent',String.valueOf(isProfilePresent));
                            mapWithDetails.put('isRecordTypePresent',String.valueOf(isRecordTypePresent));
                        }
                        
                    }
                }
            	
            }
        }
        return mapWithDetails;
    }
    // getCurrentCaseDSENTRecordsForLWC - get the existing DSENT Prediction record for the current case record if it exists
    @AuraEnabled(cacheable=true)
    public static List<DSENT_Prediction__c> getCurrentCaseDSENTRecordsForLWC(String recordId){ 
        List<DSENT_Prediction__c> currentCaseDSENTRecords = new List<DSENT_Prediction__c>();
        if(recordId != null)
        {
            String query='SELECT Id,Name'+' FROM DSENT_Prediction__c WHERE Case__c'+' = :recordId ORDER BY LastModifiedDate desc LIMIT 1';
            currentCaseDSENTRecords = query!=null?Database.query(query):currentCaseDSENTRecords;
        }
        return currentCaseDSENTRecords;
    }
}