public class Case_recordType_selectioncomp {

    public static Map<Id, String> recordtypemap {get;set;}
    public static recordTyperesponseWrapper response = new recordTyperesponseWrapper();
    @AuraEnabled        
    public static List<String> fetchRecordTypeValues(){
        List<Schema.RecordTypeInfo> recordtypes = Case.SObjectType.getDescribe().getRecordTypeInfos();    
        recordtypemap = new Map<Id, String>();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master'){
                recordtypemap.put(rt.getRecordTypeId(), rt.getName());
            }
        }        
        return recordtypemap.values();
    }
    
    @AuraEnabled
    public static recordTyperesponseWrapper getRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
        response.recordTypeID     = recid;
         if (Schema.sObjectType.Case.fields.AccountId.isAccessible()) {
            response.accountId_access = true;
        }else{
            response.accountId_access = false;
        }
        if (Schema.sObjectType.Case.fields.ContactId.isAccessible()) {
            response.contactId_access = true;
        }else{
            response.contactId_access = false;
        }
        return response;
    }      
    
    public class recordTyperesponseWrapper{
        @AuraEnabled
        public String recordTypeID {get;set;}
        @AuraEnabled
        public boolean accountId_access {get;set;}
        @AuraEnabled
        public boolean contactId_access {get;set;}
        
        
    }
}