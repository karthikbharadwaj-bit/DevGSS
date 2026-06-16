/*       
* Created By    : Namitha
* Created Date  : 14-09-2020
* Description   : Controller class for Account_RelatedFiles lightning component
* Test Class    : Test_Account_RelatedFilesController.cls

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     		Description                             
CRM-5807			Jerslin 		May 16 2023		Add EU Restriction Logic to hide the EUDP enforced objects(case/oppty/contact) 
													files for EU Restricted profile users for EU records
********************************************************************************************************************

*/
public class Account_RelatedFilesController {   
    @AuraEnabled
    public static RelatedFilesWrapper getRelatedFilesList(Id accId) {
        
        RelatedFilesWrapper relFilesWrapper = new RelatedFilesWrapper();
        List<FileDetailWrapper> fileDetailsList = new List<FileDetailWrapper>();
        List<String> lstRelatedIds = new List<String>();
        Set<Id> setContentDocumentIds = new Set<Id>();
        Map<Id,String> mapContentDocIdNLinkedEntityId = new Map<Id,String>();
        Map<Id,String> mapContentDocIdNLinkedEntityName = new Map<Id,String>();      
        
        //CRM-5807 - RelatedFiles Component - EU Privacy Logic addition - START
        EUPrivacy eu = new EUPrivacy();
        Boolean canViewEUDPObjectFiles = eu.showComponent(accId, 'Account_RelatedFiles'); // EU Restriction Logic
        
        List<String> EUDPObjects = new List<String>();
        // Objects that should be enforced EUDP are stored in custom metadata
        List<EU_Privacy_Setup__mdt> EUPrivacyList = [SELECT Restricted__c from EU_Privacy_Setup__mdt where DeveloperName = 'EUDPEnforcedAcctRelatedObjects'];
		if(EUPrivacyList != null && EUPrivacyList.size()>0)
        {
			for(String s : EUPrivacyList[0].Restricted__c.Split(','))
            {
                    EUDPObjects.add(s.trim().toLowercase());
            }
        }

        for(Account acc : [Select Id,(Select Id from Opportunities),(Select Id from Contacts),(Select Id from Contracts),(Select Id from Cases),(Select Id from Orders),(Select Id from Tasks),(Select Id from Events) from account where Id=:accId])
        {
            if(!EUDPObjects.contains('opportunity') || (EUDPObjects.contains('opportunity') && canViewEUDPObjectFiles))
            {
                for(Opportunity opp : acc.Opportunities)
            	{
                	lstRelatedIds.add(opp.Id);
            	}
            }
            if(!EUDPObjects.contains('contact') || (EUDPObjects.contains('contact') && canViewEUDPObjectFiles))
            {
                for(Contact con : acc.Contacts)
                {
                    lstRelatedIds.add(con.Id);
                }
            }
            if(!EUDPObjects.contains('case') || (EUDPObjects.contains('case') && canViewEUDPObjectFiles))
            {
                for(Case cse : acc.Cases)
                {
                    lstRelatedIds.add(cse.Id);
                }
            }
            if(!EUDPObjects.contains('contract') || (EUDPObjects.contains('contract') && canViewEUDPObjectFiles))
            {
                for(Contract contr : acc.Contracts)
                {
                    lstRelatedIds.add(contr.Id);
                }
            }
            if(!EUDPObjects.contains('order') || (EUDPObjects.contains('order') && canViewEUDPObjectFiles))
            {
                for(Order ord : acc.Orders)
                {
                    lstRelatedIds.add(ord.Id);
                }
            }
            if(!EUDPObjects.contains('task') || (EUDPObjects.contains('task') && canViewEUDPObjectFiles))
            {
                for(Task tsk : acc.Tasks)
                {
                    lstRelatedIds.add(tsk.Id);
                }
            }
            if(!EUDPObjects.contains('event') || (EUDPObjects.contains('event') && canViewEUDPObjectFiles))
            {
                for(Event evt : acc.Events)
                {
                    lstRelatedIds.add(evt.Id);
                }
            }
        }
        
        Integer totalAttachmentRecords = [SELECT COUNT() FROM Attachment WHERE ParentId in :lstRelatedIds];
        Integer totalFileRecords = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId in :lstRelatedIds];
        Integer totalNoteRecords = [SELECT COUNT() FROM Note WHERE ParentId in :lstRelatedIds];
        Integer totalRecords = totalAttachmentRecords+totalFileRecords+totalNoteRecords;
        
        List<Attachment> attachList = [SELECT Id,ParentId,createdby.name,name,parent.name,CreatedDate
                                                     FROM Attachment
                                                     WHERE ParentId in :lstRelatedIds ORDER BY CreatedDate DESC];
        
        List<ContentDocumentLink> lstContentDocLink = [SELECT ContentDocumentId, LinkedEntityId,LinkedEntity.Name  FROM ContentDocumentLink where LinkedEntityId in :lstRelatedIds];
        for(ContentDocumentLink cdl : lstContentDocLink)
        {
            setContentDocumentIds.add(cdl.ContentDocumentId);
            mapContentDocIdNLinkedEntityId.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
            mapContentDocIdNLinkedEntityName.put(cdl.ContentDocumentId,cdl.LinkedEntity.Name);
        }
        
        List<ContentDocument> lstContentDocs = [SELECT Id,Title,CreatedBy.Name,CreatedDate from ContentDocument where Id in :setContentDocumentIds ORDER BY CreatedDate DESC];
        
        List<Note> lstNotes = [SELECT Id,CreatedBy.Name,ParentId,Parent.Name,Title,CreatedDate from Note where ParentId in :lstRelatedIds ORDER BY CreatedDate DESC];
        
        Boolean isAttachmentDeletable = Schema.sObjectType.Attachment.isDeletable();
        Boolean isNoteDeletable = Schema.sObjectType.Note.isDeletable();
        Boolean isFileDeletable = Schema.sObjectType.ContentDocument.isDeletable();
        for(Attachment a : attachList)
        {
            FileDetailWrapper fdw = new FileDetailWrapper();
            fdw.recId = a.Id;
            fdw.name = a.Name;
            fdw.relatedToId = a.ParentId;
            fdw.relatedToName = a.Parent.Name;
            fdw.type = 'Attachment';
            fdw.createdByName = a.CreatedBy.Name;
            fdw.createdByDateTime = a.CreatedDate;
            fdw.checkdeleteAccess = isAttachmentDeletable;
            fileDetailsList.add(fdw);
        }
        for(ContentDocument cd : lstContentDocs)
        {
            FileDetailWrapper fdw = new FileDetailWrapper();
            fdw.recId = cd.Id;
            fdw.name = cd.Title;
            fdw.relatedToId = mapContentDocIdNLinkedEntityId.get(cd.Id);
            fdw.relatedToName = mapContentDocIdNLinkedEntityName.get(cd.Id);
            fdw.type = 'File';
            fdw.createdByName = cd.CreatedBy.Name;
            fdw.createdByDateTime = cd.CreatedDate;
            fdw.checkdeleteAccess = isFileDeletable;
            fileDetailsList.add(fdw);
        }
        for(Note n : lstNotes)
        {
            FileDetailWrapper fdw = new FileDetailWrapper();
            fdw.recId = n.Id;
            fdw.name = n.Title;
            fdw.relatedToId = n.ParentId;
            fdw.relatedToName = n.Parent.Name;
            fdw.type = 'Note';
            fdw.createdByName = n.CreatedBy.Name;
            fdw.createdByDateTime = n.CreatedDate;
            fdw.checkdeleteAccess = isNoteDeletable;
            fileDetailsList.add(fdw);
        }
        
        relFilesWrapper.fileDetailsList = fileDetailsList;        
        relFilesWrapper.totalRecords = totalRecords;
        return relFilesWrapper;
    }    
    @AuraEnabled
    public static String deleteAttachment(Id attachId, String attType)
    {
        String resultMessage;
        try{
            if(attachId != null){
                String objName = 'Attachment';
                if(attType == 'File')
                {
                    objName = 'ContentDocument';
                }
                else if(attType == 'Note')
                {
                    objName = 'Note';
                }
                SObject fileDetail = ((SObject) Type.forName(objName).newInstance()).getSObjectType().newSobject();
                fileDetail.put('Id',attachId);
                delete fileDetail;
                resultMessage = 'success';
            }
            
            
        }
        catch(exception e){
            resultMessage = 'Error';
           
        }    
        return  resultMessage;
    }    
    public class RelatedFilesWrapper{
        @AuraEnabled
        public List<FileDetailWrapper> fileDetailsList{get;set;}        
        @AuraEnabled
        public Integer totalRecords {get;set;}            
    }
    public class FileDetailWrapper{
        @AuraEnabled
        public String recId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String relatedToId {get;set;}
        @AuraEnabled
        public String relatedToName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public String createdByName {get;set;}
        @AuraEnabled
        public DateTime createdByDateTime {get;set;}
        @AuraEnabled
        public Boolean checkdeleteAccess {get;set;}
    }
}