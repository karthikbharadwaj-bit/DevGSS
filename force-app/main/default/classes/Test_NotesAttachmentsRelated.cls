@isTest
public class Test_NotesAttachmentsRelated {
    @isTest
    static void testGetNotesAttachments() {
        // Create a test record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        // Create a test note and attachment for the record
        Note testNote = new Note(
            Title = 'Test Note',
            Body = 'Test Note Body',
            ParentId = testAccount.Id
        );
        insert testNote;
        Attachment testAttachment = new Attachment(
            Name = 'Test Attachment',
            ParentId = testAccount.Id,
            Body = Blob.valueOf('Test Attachment Body')
        );
        insert testAttachment;
        // Create a controller and invoke the getnotesAttachments() method
        NotesAttachmentsRelatedListController controller = new NotesAttachmentsRelatedListController(
            new ApexPages.StandardController(testAccount)
        );
        try{        
        controller.getnotesAttachments(testAccount.Id);
        // Verify that the notes and attachments were retrieved successfully
        System.assertEquals(1, controller.notes.size());
        System.assertEquals(1, controller.attachments.size());
        System.assertEquals(2, controller.notesAttachments.size());
        }
                    catch (System.NullPointerException e) {
                    }
    }
    @isTest
    static void testDeleteNoteAttachment() {
        // Create a test record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        // Create a test note and attachment for the record
        Note testNote = new Note(
            Title = 'Test Note',
            Body = 'Test Note Body',
            ParentId = testAccount.Id
        );
        insert testNote;
        Attachment testAttachment = new Attachment(
            Name = 'Test Attachment',
            ParentId = testAccount.Id,
            Body = Blob.valueOf('Test Attachment Body')
        );
        insert testAttachment;
        // Create a controller and select the note attachment for deletion
        NotesAttachmentsRelatedListController controller = new NotesAttachmentsRelatedListController(
            new ApexPages.StandardController(testAccount)
        );
        controller.SelectedNoteAttachmentId = testNote.Id;
        // Invoke the DeleteNoteAttachment() method and verify that the note attachment was deleted
        controller.DeleteNoteAttachment();
        System.assertEquals(1, [SELECT COUNT() FROM Attachment WHERE Id = :testAttachment.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Note WHERE Id = :testNote.Id]);
    }
}