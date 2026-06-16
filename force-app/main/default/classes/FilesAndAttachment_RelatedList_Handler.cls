public without sharing class FilesAndAttachment_RelatedList_Handler {
    public static String objectName;
    public class fileWrapper{
        @AuraEnabled
        public string Title;
        @AuraEnabled
        public id recordId;
        @AuraEnabled
        public String LastModifiedDate;
        @AuraEnabled
        public string CreatedBy;
        @AuraEnabled
        public integer filesize;
         @AuraEnabled
        public string filetype;
        @AuraEnabled
        Public string NoteType;
        @AuraEnabled
        public Boolean hasDeletePermission;
        
    }
    
   @AuraEnabled  
    public static List<fileWrapper> getFiles(string recordId){     
        
         Set<Id> contentDocumentId = new Set<Id>();   
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId]){
                contentDocumentId.add(cdl.ContentDocumentId);
            }
         
            List<ContentDocument> contentDocumentList = [SELECT Id, Title,CreatedById,FileExtension,CreatedBy.Name,ContentSize,
 FileType,LastModifiedDate FROM ContentDocument WHERE id IN : contentDocumentId ORDER BY CreatedDate];
            
            List<Note> notesList = [SELECT id,Title,CreatedById,Createdby.Name,LastModifiedDate
                                    FROM Note where ParentId =:recordId ORDER BY CreatedDate];
            
            List<Attachment> attachmentList = [SELECT id,Name,CreatedById,Createdby.Name, LastModifiedDate,
                                               BodyLength FROM Attachment where ParentId =:recordId ORDER BY CreatedDate];
            String userTimeZoneID = UserInfo.getTimeZone().getID(); // get the user timezone to convert the LastModifiedDate to user time
            List<fileWrapper> fileWrapperList = new List<fileWrapper>();
            if(!contentDocumentList.isEmpty()){
                for(ContentDocument c : contentDocumentList) {
                    fileWrapper Nw = new fileWrapper();
                    Nw.recordId = c.id;
                    Nw.Title = c.Title+'.'+c.FileExtension;
                    Nw.CreatedBy = c.CreatedBy.Name;
                    Nw.filetype = c.FileType;
                    Nw.filesize = c.ContentSize;
                    Nw.NoteType = 'ContentDocument';
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    Nw.hasDeletePermission=checkDeletePermissionset(c.CreatedById);
                    fileWrapperList.add(Nw); 
                }
            }
            if(!NotesList.isEmpty()){
                for(Note c : notesList) {
                    fileWrapper Nw = new fileWrapper();
                    Nw.recordId = c.id;               
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    Nw.Title = c.Title;
                    Nw.CreatedBy = c.CreatedBy.Name;
                    Nw.NoteType = 'NOTE';
                    Nw.hasDeletePermission=checkDeletePermissionset(c.CreatedById);
                    fileWrapperList.add(Nw); 
                }
            }
            if(!AttachmentList.isEmpty()){
                for(Attachment c : attachmentList) {
                    fileWrapper Nw = new fileWrapper();
                    Nw.recordId = c.id;
                    Nw.Title = c.Name;
                    Nw.CreatedBy = c.CreatedBy.Name;
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    Nw.filesize = c.BodyLength;
                    Nw.NoteType = 'ATTACHMENT';
                    Nw.hasDeletePermission=checkDeletePermissionset(c.CreatedById);
                    fileWrapperList.add(Nw); 
                }
            }
            //return JSON.serialize(fileWrapperList);
          return fileWrapperList;

       }
                
    @AuraEnabled  
    public static String deleteFiles(List<String> sdocumentId){ 
            Set<Id> setFileIds = new Set<Id>();
            Set<Id> setAttIds = new Set<Id>();
            Set<Id> setNoteIds = new Set<Id>();
            for(String strId:sdocumentId){
                Id newId = Id.valueOf(strId);
                Schema.SObjectType sobjectType = newId.getSObjectType();
                String sobjectName = sobjectType.getDescribe().getName();
                if(sobjectName == 'ContentDocument'){
                    setFileIds.add(newId);
                }else if(sobjectName == 'Attachment'){
                    setAttIds.add(newId);
                }else if(sobjectName == 'Note'){
                    setNoteIds.add(newId);
                }
            }
            
            If(setFileIds.size()>0){
                delete [SELECT Id FROM ContentDocument WHERE Id=:sdocumentId];
            }
            If(setAttIds.size()>0){
                delete [SELECT Id FROM Attachment WHERE Id=:sdocumentId];
            }
            If(setNoteIds.size()>0){
                delete [SELECT Id FROM Note WHERE Id=:sdocumentId];
            }
            return 'SUCCESS';
    }  
    
    public static Boolean checkDeletePermissionset (String createdUserId){
        Boolean isSysAdmin=profilehelper.isCurrentUserSysAdmin();
        if(createdUserId == UserInfo.getUserId() || FeatureManagement.checkPermission('Delete_Attachments_Access') || isSysAdmin){
             return true;
         }
         return false;
     }
}