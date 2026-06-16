public class Partner_Cases {
    
    @AuraEnabled
    public static CaseDataTableWrapper getListView(String searchKeyWord, String searchBy, Decimal pageNumber, Decimal pageSize)
    {
        try {
            Integer pSize = (Integer)pageSize;
            Integer pNumber = (Integer)pageNumber;
            Integer totalRecords;
            String AvayaOffice='';
            CommunityInfo comm = new CommunityInfo();   
            Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
            List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
            Set<Id> setUserId = new Set<Id>();
            setUserId.add(UserInfo.getUserId());
            
            if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
                AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
            }
            if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
                totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
            } else {
                totalRecords=1000;
            }
            Integer offset = (pNumber - 1) * pSize; 
            
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Collections Dispute').getRecordTypeId();
            
            String query = '';
            
            query = 'select count() from Case where Account.type='+'\'Customer\' and RecordTypeId = : recordTypeId and Account.Avaya_Partnership_Account__c = true and Account.RC_Brand__c IN: brandNamesList';
            
            if(null!= searchKeyWord && searchKeyWord != ''){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                query += ' And '+ searchBy+ ' Like '+searchKey;
            }  
            Integer totSize = Database.countquery(query);
            
            if(totSize<totalRecords){
                totalRecords = totSize;
            }
            
            Integer recordEnd = pSize * pNumber;
            CaseDataTableWrapper objDT =  new CaseDataTableWrapper();  
            objDT.pageSize = pSize;
            objDT.pageNumber = pNumber;
            objDT.recordStart = offset + 1;
            objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
            objDT.totalRecords = totalRecords;
            objDT.communityDetailsRecord=comDetail;
            
            query = 'select CaseNumber,	Account.Name, Account.BusinessIdentity__c, Account.Payment_Method__c, RC_User_Id__c, Priority, Owner.Name, Contact.Name, toLabel(Status), Subject, Support_Escalate_To__c,'+
                ' Dispute_Details__c, Corrective_Actions__c, CreatedDate, CreatedBy.Name, Age_Date__c, Value_of_Invoices_under_Dispute__c,CurrencyIsoCode'+
                ' FROM Case Where Account.type= '+'\'Customer\' and RecordTypeId = : recordTypeId and Account.Avaya_Partnership_Account__c = true and Account.RC_Brand__c IN: brandNamesList';
            
            if(null!= searchKeyWord && searchKeyWord != '') {
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                query += ' And '+ searchBy+ ' Like '+searchKey;
            }
            
            query += ' ORDER BY Account.Name LIMIT :pSize OFFSET :offset'; 
            objDT.caseList = Database.query(query);
            objDT.partnerCommunityName = brandNamesList;
            return objDT;
        }
        catch (Exception e) {
            System.debug('failure - ' + e.getMessage()); 
            return null;
        }
    }
    
    //Translation Start
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }    
    
    //Translation End
    
    @AuraEnabled
    public static Case getSelectedCase(String caseId)
    {
        try { 
            List<Case> caseRecs = new List<Case>();
            Case caseRec = new Case();
            String query = '';
            query = 'select Id, CaseNumber,	Account.Name, RC_User_Id__c,toLabel(Priority), Owner.Name, Contact.Name, toLabel(Status), Subject, Support_Escalate_To__c,'+
                ' Dispute_Details__c, Origin, Corrective_Actions__c, CreatedDate, CreatedBy.Name, Age_Date__c, Value_of_Invoices_under_Dispute__c, CurrencyIsoCode,'+
                ' Description, Instructions_for_Collections__c, LastModifiedBy.Name, LastModifiedDate'+
                ' FROM Case Where Id = : caseId';
            caseRecs = Database.query(query);
            caseRec = caseRecs[0];
            return caseRec;
        }
        catch (Exception e) {
            System.debug('failure - ' + e.getMessage()); 
            return null;
        }
    }
    
    @AuraEnabled  
    public static List<ContentVersion> getLightningFiles(string recordId){ 
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        return [SELECT Id,Title,FileType,ContentDocument.LatestPublishedVersionId, LastModifiedDate, CreatedBy.Name FROM ContentVersion WHERE contentDocumentId IN: documentIds];  
    }
    
    @AuraEnabled
    public static List<Attachment> getAttachments(string recordId){
        Set<Id> recordIds=new Set<Id>{recordId};
            List<Attachment> attachmentList =[Select Id,Name,ContentType, LastModifiedDate, CreatedBy.Name FROM Attachment WHERE ParentId IN:recordIds];  
        if(!attachmentList.isEmpty()&&attachmentList!=null){  
            return attachmentList;  
        } else {
            return null; 
        }
    }
    
    @AuraEnabled
    public static List<CaseComment> getCaseComments(string recordId){
        Set<Id> recordIds=new Set<Id>{recordId};
            List<CaseComment> caseCommentList =[Select Id, CommentBody, LastModifiedDate, CreatedBy.Name from CaseComment where ParentId IN:recordIds and IsDeleted = false];  
        if(!caseCommentList.isEmpty() && caseCommentList != null){  
            return caseCommentList; 
        } else {
            return null; 
        }
    }
        
    @AuraEnabled
    public static List<EmailMessage> getCaseEmails(string recordId){
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        List<caseEmailWrapper> emailWrappers = new List<caseEmailWrapper> ();
        List<EmailMessage> emailMessages = [select Id, FromAddress, CreatedDate, FromName, Subject, ToAddress, CcAddress, BccAddress, TextBody, MessageDate, HasAttachment, EmailTemplateId, ContentDocumentIds, ActivityId from EmailMessage where ParentId IN:recordIds];
        return emailMessages;        
    }
    
    @AuraEnabled
    public static caseEmailWrapper getCaseEmail(string recordId){
        List<EmailMessage> emailMessages = [select Id, FromAddress, FromName, CreatedDate, Subject, ToAddress, CcAddress, BccAddress, TextBody, HtmlBody, MessageDate, HasAttachment, EmailTemplateId, ContentDocumentIds, ActivityId from EmailMessage where Id  = :recordId];
        EmailMessage emailMessage = emailMessages[0];
        List<Attachment> emailAttachments =[Select Id,Name,ContentType, LastModifiedDate, CreatedBy.Name FROM Attachment WHERE ParentId = : emailMessage.Id];  
        
        Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl = [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : emailMessage.Id];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        List<ContentVersion> emailFiles = [SELECT Id,Title,FileType,ContentDocument.LatestPublishedVersionId, LastModifiedDate, CreatedBy.Name FROM ContentVersion WHERE contentDocumentId IN: documentIds]; 
        
        caseEmailWrapper emailWrapper = new caseEmailWrapper();
        emailWrapper.emailMessage = emailMessage;
        emailWrapper.emailAttachments = emailAttachments;
        emailWrapper.emailFiles = emailFiles;
        return emailWrapper;        
    }
    
    public class CaseDataTableWrapper {
        @AuraEnabled
        public Integer pageSize {get;set;}
        @AuraEnabled
        public Integer pageNumber {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled
        public Integer recordEnd {get;set;}
        @AuraEnabled
        public List<Case> caseList {get;set;} 
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}   
    }
    
    public class caseEmailWrapper {
        @AuraEnabled
        public EmailMessage emailMessage {get;set;}
        @AuraEnabled
        public List<Attachment> emailAttachments {get;set;}
        @AuraEnabled
        public List<ContentVersion> emailFiles {get;set;}
    }
    
    
}