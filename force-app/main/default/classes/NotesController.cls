public class NotesController {
    public static DescribeSObjectResult sObjectResult;
    public static String objectName;
    public class NotesWrapper{
        public string Title;
        public id recordid;
        //public id Parentid;
        public string downloadurl;
        //public string Body;
        //public datetime CreatedDate;
        public String LastModifiedDate;
        //public boolean IsPrivate;
        //public id Ownerid;
        //public string OwnerName;
        public string CreatedBy;
        //public string LastModifiedBy;
        public integer filesize;
        public string filetype;
        Public string NoteType;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getContentDocumentsDetail(Id recordId) {
        EUPrivacy eu = new EUPrivacy();
        if(eu.showComponent(recordId , 'NotesController')){
            Set<Id> contentDocumentId = new Set<Id>();   
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId]){
                contentDocumentId.add(cdl.ContentDocumentId);
            }
            
            List<ContentVersion> contentVersionList = [SELECT Id, Title, FileExtension, ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,
                                                       ContentDocumentId, ContentDocument.FileType,ContentDocument.LastModifiedDate, LastModifiedDate
                                                       FROM ContentVersion WHERE ContentDocumentId IN : contentDocumentId ORDER BY CreatedDate];
            
            List<Note> notesList = [SELECT id,Title,Createdby.Name,LastModifiedDate
                                    FROM Note where ParentId =:recordId ORDER BY CreatedDate];
            
            List<Attachment> attachmentList = [SELECT id,Name,Createdby.Name, LastModifiedDate,
                                               BodyLength FROM Attachment where ParentId =:recordId ORDER BY CreatedDate];
            String userTimeZoneID = UserInfo.getTimeZone().getID(); // get the user timezone to convert the LastModifiedDate to user time
            List<NotesWrapper> notesWrapperList = new List<NotesWrapper>();
            if(!contentVersionList.isEmpty()){
                for(ContentVersion c : contentVersionList) {
                    NotesWrapper Nw = new NotesWrapper();
                    Nw.recordid = c.id;
                    Nw.downloadurl = c.ContentDocumentId;
                    Nw.Title = c.Title+'.'+c.FileExtension;
                    Nw.CreatedBy = c.ContentDocument.CreatedBy.Name;
                    Nw.filetype = c.ContentDocument.FileType;
                    Nw.filesize = c.ContentDocument.ContentSize;
                    Nw.NoteType = 'CONTENT_VERSION';
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    notesWrapperList.add(Nw); 
                }
            }
            if(!NotesList.isEmpty()){
                for(Note c : notesList) {
                    NotesWrapper Nw = new NotesWrapper();
                    Nw.recordid = c.id;
                    //Nw.Parentid = c.parentid;
                    //Nw.Body = c.Body;
                    //Nw.CreatedDate = c.CreatedDate;
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    //Nw.IsPrivate = c.IsPrivate;
                    //Nw.Ownerid = c.OwnerId;
                    //Nw.OwnerName = c.Owner.Name;
                    //Nw.LastModifiedBy = c.LastModifiedBy.Name;
                    Nw.Title = c.Title;
                    Nw.CreatedBy = c.CreatedBy.Name;
                    Nw.NoteType = 'NOTE';
                    notesWrapperList.add(Nw); 
                }
            }
            if(!AttachmentList.isEmpty()){
                for(Attachment c : attachmentList) {
                    NotesWrapper Nw = new NotesWrapper();
                    Nw.recordid = c.id;
                    //Nw.Parentid = c.parentid;
                    Nw.Title = c.Name;
                    Nw.CreatedBy = c.CreatedBy.Name;
                    Nw.LastModifiedDate = c.LastModifiedDate.format('MM/dd/yyyy h:mm a',userTimeZoneID);
                    Nw.filesize = c.BodyLength;
                    Nw.NoteType = 'ATTACHMENT';
                    notesWrapperList.add(Nw); 
                }
            }
            System.debug('notesWrapperList--> '+notesWrapperList);
            return JSON.serialize(notesWrapperList);
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static String deleteDocuments(List<String> docIds){
        //try{
            system.debug('docIds :'+docIds);
            Set<Id> setFileIds = new Set<Id>();
            Set<Id> setAttIds = new Set<Id>();
            Set<Id> setNoteIds = new Set<Id>();
            for(String strId:docIds){
                Id newId = Id.valueOf(strId);
                Schema.SObjectType sobjectType = newId.getSObjectType();
                String sobjectName = sobjectType.getDescribe().getName();
                system.debug('sobjectName :'+sobjectName);
                if(sobjectName == 'ContentDocument'){
                    setFileIds.add(newId);
                }else if(sobjectName == 'Attachment'){
                    setAttIds.add(newId);
                }else if(sobjectName == 'Note'){
                    setNoteIds.add(newId);
                }
            }

            
            If(setFileIds.size()>0){
                delete [SELECT Id FROM ContentDocument WHERE Id=:setFileIds];
            }
            If(setAttIds.size()>0){
                delete [SELECT Id FROM Attachment WHERE Id=:setAttIds];
            }
            If(setNoteIds.size()>0){
                delete [SELECT Id FROM Note WHERE Id=:setNoteIds];
            }
            return 'SUCCESS';
        /*}
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }*/
    }
    // CRM-5858 - Introduction of Custom Notes in this component - Start
	@AuraEnabled
    public static String createCustomNote(String recordId, String title, String content) {
        ContentNote objCntNote = new ContentNote();
        if(String.isEmpty(title)){
            objCntNote.Title ='Untitled Note';
        }
        else{
            objCntNote.Title = title;
        }
        objCntNote.Content =Blob.valueOf(content);
        insert objCntNote; 
        ContentDocumentLink objCntDocLink = new ContentDocumentLink();
        objCntDocLink.LinkedEntityId = recordId; 
        objCntDocLink.ContentDocumentId = objCntNote.Id;  
        objCntDocLink.shareType = 'V'; 
        objCntDocLink.Visibility= 'InternalUsers';
        insert objCntDocLink;
        return 'SUCCESS';
	}
    // CRM-5858 - Introduction of Custom Notes in this component - End
}