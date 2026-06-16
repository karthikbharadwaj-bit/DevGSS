public class NotesAttachmentsRelatedListController {
    public List<Attachment> attachments { get; set; }
    public List<Note> notes { get; set; }
    public List<NoteAttachment> notesAttachments { get; set; }

    private sObject currentSobj;
    public Id sObjectId { get; set; }    
    public String sObjName { get; set; }

	public Boolean buttonsAvailable { get; set; }
	public Id SelectedNoteAttachmentId { get; set; }

	public void getnotesAttachments(Id sObjId){
        notesAttachments = new List<NoteAttachment>();
        User userObj = [SELECT Id, Profile.Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        //EU Phase 3 - IT Profile changes - START
        /* Set<String> avaliableProfiles = new Set<String>{'Legal Team (View All Data)',
        												'Legal Team AD Auth',
        												'Sales Manager - Business Processing',
        												'System Administrator'}; */
		Set<String> avaliableProfiles  = new Set<String>(); 
		List<EU_Component_reference__mdt> profileList = [Select DeveloperName, Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%NotesAttachmentsRelatedListController%'
                                                        																		and DeveloperName = 'Legal_Team_AD_Auth'];
		 for(EU_Component_reference__mdt profRec:profileList){
			avaliableProfiles.addall(profRec.Values__c.split(','));
		}
		//EU Phase 3 - IT Profile Changes - END
        buttonsAvailable = avaliableProfiles.contains(userObj.Profile.Name);

        /*buttonsAvailable = userObj.Profile.Name == 'Legal Team (View All Data)' ||
+                             userObj.Profile.Name == 'Legal Team AD Auth ' ||
+                             userObj.Profile.Name == 'Sales Manager - Business Processing' ||
+                             userObj.Profile.Name == 'System Administrator';*/


        for(Attachment a : (List<Attachment>)getObjects(sObjId, 'Name', 'Attachment')) {
        	notesAttachments.add(new NoteAttachment(a));
        }
        for(Note n : (List<Note>)getObjects(sObjId, 'Title', 'Note')) {
        	notesAttachments.add(new NoteAttachment(n));
        }
	}

	public List<sObject> getObjects(Id sObjId, String name, String sObjName){
		String query = 'SELECT Id, '+ name +', LastModifiedDate, CreatedBy.Name ' +
	                     + ' FROM ' + sObjName + 
	                     + ' WHERE ParentId = \'' + sObjId + '\'';
	    return database.query(query);
	}

    public NotesAttachmentsRelatedListController(ApexPages.StandardController stdController) {
  		currentSobj = (sObject) stdController.getRecord();
	    sObjectId = currentSobj.Id;
        sObjName = currentSobj.Id.getSObjectType().getDescribe().getName();
        getnotesAttachments(sObjectId);

    }

    public void DeleteNoteAttachment(){
		delete [select id from Attachment where id =: SelectedNoteAttachmentId];
		delete [select id from Note where id =: SelectedNoteAttachmentId];
		getnotesAttachments(sObjectId);

	}
}