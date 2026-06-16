public with sharing class NoteAttachment {
    	public Note notes { get; set; }
    	public Attachment attachments { get; set; }

    	public String name { get; set; }
    	public String title { get; set; }

    	public Id attachmentId { get; set; }
    	public Id noteId { get; set; }

    	public Datetime attachmentDt { get; set; }
    	public Datetime noteDt { get; set; }

    	public String attachmentCrBy { get; set; }
    	public String noteCrBy { get; set; }

    	public String attachmentType { get; set; }
    	public String noteType { get; set; }

    	public Boolean isNote { get; set; }

     	public  NoteAttachment(Attachment at){  
     	this.name = at.Name; 
     	this.attachmentId = at.Id;	
     	this.attachmentDt = at.LastModifiedDate;  
     	this.attachmentCrBy = at.CreatedBy.Name;  
     	this.attachmentType = 'Attachment';
     	this.isNote = false;
     	this.attachments = at;
    	}
    	public  NoteAttachment(Note no){  
     	this.title = no.Title; 	 
     	this.noteId = no.Id; 
     	this.noteDt = no.LastModifiedDate;
     	this.noteCrBy = no.CreatedBy.Name;
     	this.noteType = 'Note';
     	this.isNote = true;
     	this.notes = no;
    	}
	}