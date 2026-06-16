public without sharing class AvayaStorefront_UploadTaxfile {
    
    @AuraEnabled
    public static List<ContentDocument> getFiles(string recordId){
        //get list of attachments to be displayed in record detail page for selected deal support
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>();
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];
        for(ContentDocumentLink cdLink:cdl){
            documentIds.add(cdLink.ContentDocumentId);
        }
        return [SELECT Id,Title,LatestPublishedVersionId,FileType,CreatedDate FROM ContentDocument WHERE id IN: documentIds];
    }
    
    @AuraEnabled
    public static UserRecordAccess getUserRecordAccess(String AccountChecklistId){
       String userId = UserInfo.getUserId();
       List<UserRecordAccess> recordAccess = [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess WHERE UserId = :userId and RecordId = :AccountChecklistId];
       return recordAccess[0];
    }

    @AuraEnabled
    public static List<Contract> getContractDetails(String accountId){
        List<Contract> listContract=new List<Contract>();
        if(accountId!=null || accountId!=''){   
            listContract = [Select Id,ContractNumber,Status,Source__c from Contract where Account.Id=:accountId];
        }
     return listContract;
    }
    
    @AuraEnabled
    public static List<Attachment> getAttachments(String parentId){
        List<Attachment> listAtt = new List<Attachment>();
        if(parentId!=null || parentId!=null){
            //Added contentType as part of fix to include files from Lightning
            listAtt = [select Name,Description,Parent.Name,contentType from Attachment where ParentId=:parentId];
        }
        return listAtt;
    }
    @AuraEnabled  
    public static List<ContentDocument> getContractFiles(string recordId){ 
        //get list of attachments to be displayed in record detail page for selected deal support
        Set<String> recordIds=new Set<String>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        system.debug('ids '+recordIds);
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];  
        for(ContentDocumentLink cdLink:cdl){
            documentIds.add(cdLink.ContentDocumentId);  
        }
        system.debug('ContentDocumentId '+cdl);
        List<ContentDocument> contentDocuments =[SELECT Id,Title,FileType FROM ContentDocument WHERE id IN: documentIds];
        system.debug('documents '+contentDocuments);
        return contentDocuments;  
    }

}