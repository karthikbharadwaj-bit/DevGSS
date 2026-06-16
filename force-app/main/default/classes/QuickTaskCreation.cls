public class QuickTaskCreation {
    
    public class QuickTaskWrapper {
        @AuraEnabled
        public String errorMsg { get; set; }
        @AuraEnabled
        public String quickTaskRecTypeId { get; set; }
    }

    @AuraEnabled(cacheable = true)
    public static QuickTaskWrapper getQuickTaskInfo(Id recId, String objectNm) {
        QuickTaskWrapper response = new QuickTaskWrapper();
        response.quickTaskRecTypeId  = '';
        response.errorMsg = 'success';
      	String eligibleProfiles = '';
        String eligibleRTs = '';
        
        List<Quick_Task_Setup__mdt> metadata = [SELECT DeveloperName,Values__c FROM Quick_Task_Setup__mdt]; 
        for (Quick_Task_Setup__mdt mdt : metadata) {
            if (mdt.DeveloperName == 'QuickTaskEligibleProfiles') {
                eligibleProfiles = mdt.Values__c;
            } else if (mdt.DeveloperName == 'QuickTaskEligibleRTs') {
                eligibleRTs = mdt.Values__c;
            }
        }
     
        String queryString = 'SELECT RecordTypeId FROM '+ objectNm + ' WHERE Id =:recId LIMIT 1';
		sObject obj = Database.query(queryString);
        Id recordTypeID = (Id) obj.get('RecordTypeId');
        
        if (eligibleProfiles.contains(UserInfo.getProfileId())) {
            if(eligibleRTs.contains(recordTypeID)) {
            	response.errorMsg = 'success';
            	response.quickTaskRecTypeId  = ((SObject)Type.forName('Task').newInstance()).getSObjectType().getDescribe().getRecordTypeInfosByName().get('Quick Task').getRecordTypeId();
        	} else {
            	response.errorMsg = System.Label.QuickTask_IneligibleRecordTypes_ErrorMsg + ' ' + objectNm;
            }
        } else {
            response.errorMsg = System.Label.QuickTask_IneligibleProfiles_ErrorMsg;
        }
        return response;
    }
}