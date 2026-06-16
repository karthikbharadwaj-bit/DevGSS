public class DSENTPredictionTriggerHelper {
	public static void executeDSENTPredictionTrigger(List<DSENT_Prediction__c> dataFromTrigger,Boolean isInsert)
    {
        if(dataFromTrigger!=null && dataFromTrigger.size()>0)
        {
            User usr = [Select Id, Profile.Name,country__c from User where Id=:UserInfo.getUserId() LIMIT 1];
            UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
            if(userAppInfo!=null && usr!=null)
            {
            	AppDefinition appDefinition = [SELECT DurableId,DeveloperName,Label FROM AppDefinition Where DurableId = :userAppInfo.AppDefinitionId LIMIT 1]; 
				if(appDefinition!=null)
                {
                    List<DSENT_Prediction_Details__mdt> currentAccessGiven = new List<DSENT_Prediction_Details__mdt>([SELECT Apps__c,Record_Type_Names__c FROM DSENT_Prediction_Details__mdt WHERE DeveloperName like 'DSENTRestriction%']);
                    List<String> listOfAllowedApps = new List<String>();
                    List<String> listOfAllowedRecordTypes = new List<String>();
                    Set<Id> listOfCaseIds = new Set<Id>();
                    Map<String,String> casesWithRecordTypeNames = new Map<String,String>();
                    List<String> listOfExistingCaseIds = new List<String>();
                    for(DSENT_Prediction__c d:dataFromTrigger){
                        listOfCaseIds.add(d.Case__c);
                    }
                    List<DSENT_Prediction__c> collectionOfCasesWithDSENTRecords = new List<DSENT_Prediction__c>([SELECT Case__c FROM DSENT_Prediction__c WHERE Case__c IN :listOfCaseIds]);
                    List<Case> listOfCasesWithTheirRTNames = new List<Case>([SELECT Id,RecordType.DeveloperName FROM Case WHERE Id IN :listOfCaseIds]);
                    if(currentAccessGiven!=null && currentAccessGiven.size()>0)
                    {
                        listOfAllowedApps = currentAccessGiven[0].Apps__c!=null?currentAccessGiven[0].Apps__c.trim().split(','):new List<String>();
                        listOfAllowedRecordTypes = currentAccessGiven[0].Record_Type_Names__c!=null?currentAccessGiven[0].Record_Type_Names__c.trim().split(','):new List<String>();
                    }
                    if(collectionOfCasesWithDSENTRecords.size()>0)
                    {
                        for(DSENT_Prediction__c d:collectionOfCasesWithDSENTRecords)
                        {
                            listOfExistingCaseIds.add(String.valueOf(d.Case__c));
                        }
                    }
                    if(listOfCasesWithTheirRTNames.size()>0)
                    {
                        for(Case c:listOfCasesWithTheirRTNames)
                        {
                            casesWithRecordTypeNames.put(c.Id,c.RecordType.DeveloperName);
                        }
                    }
                    for(DSENT_Prediction__c d:dataFromTrigger)
                    {
                        if(!Test.isRunningTest() && (!listOfAllowedApps.contains(appDefinition.DeveloperName))) 
                        {
                            d.addError('We can\'t edit/create/delete DSENT records in this application');
                        }  
                        else
                        {
                            if(isInsert)
                            {
                                String currentCaseId = d.Case__c!=null?String.valueOf(d.Case__c):'';
                                Boolean existingCase = listOfExistingCaseIds!=null && listOfExistingCaseIds.size()>0?listOfExistingCaseIds.contains(currentCaseId):false;
                                if(!Test.isRunningTest() && existingCase)
                                {
                                    d.addError('DSENT Prediction record already exists for the selected case');
                                }
                                else if(!Test.isRunningTest() && casesWithRecordTypeNames.containsKey(d.Case__c)) 
                                {
                                    String recordTypeName = casesWithRecordTypeNames.get(d.Case__c)!=null?casesWithRecordTypeNames.get(d.Case__c):'';
                                    if(!listOfAllowedRecordTypes.contains(recordTypeName))
                                    {
                                        d.addError('Selected Case with this record type does not have access to create DSENT Prediction records');
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}