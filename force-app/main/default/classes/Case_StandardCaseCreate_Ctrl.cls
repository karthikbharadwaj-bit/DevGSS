public class Case_StandardCaseCreate_Ctrl {
    @AuraEnabled
    public static List<RecordType> getInitialData(Id recordId) {
        Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>([
            SELECT Description, Name
            FROM RecordType
            WHERE SobjectType =: 'Case'
            AND IsActive = TRUE
        ]);
        System.debug('Record Type '+recordTypesMap);
        return recordTypesMap.values();
    }
    
    @AuraEnabled
    public static Account getAccntData(Id recordId) {
        
        return [Select Name, RC_Brand__c FROM Account Where Id =:recordId LIMIT 1];
    }
    
     @AuraEnabled
    public static string getBrandName(string recordId) {
        string res;
        string brandName;
        
        if (recordId.startsWith('001')) {
            List<Account> acclist = [Select Name, RC_Brand__c FROM Account Where Id =:recordId LIMIT 1];
            brandName = acclist[0].RC_Brand__c;
        }
        if (recordId.startsWith('006')) {
        	List<Opportunity> opplist = [select Name, Brand_Cancel__c from Opportunity where Id =:recordId LIMIT 1];
            brandName = opplist[0].Brand_Cancel__c;
        }
        if (recordId.startsWith('003')) {
        	List<Contact> conlist = [select Name, Account_Brand__c from Contact where Id =:recordId LIMIT 1];
            brandName = conlist[0].Account_Brand__c;
        }
        
        return brandName;
    }
    
    @AuraEnabled
    public static ResponseWrapper checkfieldAccess(){
        ResponseWrapper responseWrapperRec = new ResponseWrapper();
        if (Schema.sObjectType.Case.fields.AccountId.isAccessible()) {
            responseWrapperRec.accountId_accessible = true;
        }
        else{
            responseWrapperRec.accountId_accessible = false;
        }
        if (Schema.sObjectType.Case.fields.ContactId.isAccessible()) {
            responseWrapperRec.contactId_accessible = true;
        }else{
            responseWrapperRec.contactId_accessible = false;
        }
        return responseWrapperRec;
    }
    
    public class ResponseWrapper {
        @AuraEnabled
        public boolean accountId_accessible {get;set;}
        @AuraEnabled
        public boolean contactId_accessible {get;set;}
    }
}