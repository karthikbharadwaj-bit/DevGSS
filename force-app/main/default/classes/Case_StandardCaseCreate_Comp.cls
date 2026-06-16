/*
* Created By     : Vishal
* Created Date   : 29-05-2020
* Description    : Controller for Case_StandardCase_Create component on Case in lightning experience

Change History
*******************************************************************************************************************************************
SCRUM/Jira ModifiedBy      Date        Description Tag
*******************************************************************************************************************************************

*******************************************************************************************************************************************
*/

public class Case_StandardCaseCreate_Comp {
    public static responseWrapperCase response = new responseWrapperCase();
    @AuraEnabled
    public static responseWrapperCase fetchRecordDetailsCase(String userId, String rectypeId, String accId, String contactId){
        checkfieldAccess();
        
        User userrec = new User();
        String profileName;
        List<CaseLayoutAssignment__c> layoutAssignmentSettings = CaseLayoutAssignment__c.getall().values();
        if(userrec != NULL){
            userrec = [SELECT id , profileId from User where id =: userId];
            profileName = [SELECT Id, Name FROM Profile WHERE Id = :userrec.profileId LIMIT 1].Name;
        } 
        String recTypeName = ((SObject)Type.forName('Case').newInstance()).getSObjectType().getDescribe().getRecordTypeInfosById().get(rectypeId).getName();
        
        Boolean isAllowedRecordType = false;
        for(CaseLayoutAssignment__c settingRecord : layoutAssignmentSettings) {
            system.debug('******'+settingRecord.RecordType_Name__c+recTypeName+settingRecord.Profile_Name__c+profileName);
            if(settingRecord.RecordType_Name__c == recTypeName && settingRecord.Profile_Name__c == profileName) {
                isAllowedRecordType = true;
            }
        }
        
        //Checking
        if (!isAllowedRecordType
            || !FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_ALTERNATIVE_CASE_CREATION)) {
                
                
                if(contactId != NULL){
                    response.accountIdComp = [select id, AccountId from Contact where id = : contactId].AccountId;
                    response.contactIdComp = contactId;
                    response.Url = 'STANDARD PAGE';
                }else{
                    
                    response.accountIdComp = accId;
                    response.Url = 'STANDARD PAGE';
                }
                
                
                
            }else{
                
                if(contactId != NULL){
                    response.accountIdComp = [select id, AccountId from Contact where id = : contactId].AccountId;
                    response.contactIdComp = contactId;
                    response.Url = 'apex/CaseCreation?def_account_id='+response.accountIdComp+'&RecordType='+rectypeId+'&def_contact_id='+contactId+'&retURL='+contactId+'&ent=Case&save_new=1&sfdc.override=1';
                }else if(accId != null){
                    response.Url = 'apex/CaseCreation?def_account_id='+accId+'&RecordType='+rectypeId+'&retURL='+accId+'&ent=Case&save_new=1&sfdc.override=1';
                }  
                else
                {
                    response.Url = 'apex/CaseCreation?RecordType='+rectypeId+'&ent=Case&save_new=1&sfdc.override=1';
                }
                response.baseUrl =  URL.getOrgDomainUrl().toExternalForm();
                
            }
        
        system.debug('response'+response);
        return response;
    }
    
    public static void checkfieldAccess(){
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
    }
    
    public class responseWrapperCase{
        @AuraEnabled
        public String accountIdComp {get;set;}
        @AuraEnabled
        public boolean accountId_access {get;set;}
        @AuraEnabled
        public String contactIdComp {get;set;}
        @AuraEnabled
        public boolean contactId_access {get;set;}
        @AuraEnabled
        public String Url {get;set;}  
        @AuraEnabled
        public String baseUrl {get;set;} 
        @AuraEnabled
        public boolean resource_access{get;set;}
        
    }
    
    
    @AuraEnabled
    public static Case fetchCaseCreatedByFields(String caserecId){
        
        Case csrec = new Case();
        try{
            
            csrec = [select id, createdById, createdDate, CreatedBy.Name, LastModifiedById , LastModifiedBy.Name , LastModifiedDate from Case where id = : caserecId];
            
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        return csrec;
    }
    
    
}