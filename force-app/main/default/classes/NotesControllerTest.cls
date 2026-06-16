@isTest
private class NotesControllerTest {    
    @isTest
    static void testInvokeController2() {
        
        Test.startTest();
        User testUser = EUPrivacyTest.getUser();
        insert testUser;
        
        Account acctObj2 = EUPrivacyTest.getAccount();
        acctObj2.RC_Brand__c = 'RingCentral UK';
        acctObj2.BillingCountry = 'France';
        insert acctObj2;		
        Account acctObj3 = [Select id from Account where id=:acctObj2.id];        
        Attachment att = CreateNotes(acctObj3.id);
        
        // CRM-5858 - Introduction of Custom Notes in this component - Start
        NotesController.createCustomNote(acctObj2.id,'Test Note Title', 'Test Note Content');
       	List<ContentDocumentLink> notesList=[SELECT ContentDocument.Title FROM ContentDocumentLink
            WHERE LinkedEntityId = :acctObj2.Id AND ContentDocument.FileType = 'SNOTE'];
        System.assertEquals(2, notesList.size(),'Note creation failed');
        // CRM-5858 - Introduction of Custom Notes in this component - End

        //System.runAs(testUser) {
            String getCDD1 = NotesController.getContentDocumentsDetail(acctObj3.Id);
            String deleteDocument = NotesController.deleteDocuments(new List<String>{att.Id});
        //}
        Test.stopTest();
    }
    
    public static Attachment CreateNotes(id recordid){
        
        ContentNote note=new ContentNote();
        note.Title='Test File';
        Blob noteBlob=Blob.valueOf('Unit Test ContentNote Body');
        note.Content=noteBlob;
        note.SharingPrivacy='N';
        insert note;
        
        ContentVersion content=new ContentVersion();
        content.Title='Test File';
        content.PathOnClient='Test File.snote';
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        content.VersionData=bodyBlob;
        content.Origin = 'H';
        content.SharingPrivacy='N';
        content.ContentDocumentId=note.Id;
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=recordid;
        contentlink.ContentDocumentId=[select ContentDocumentId from ContentVersion where Id =: content.Id].ContentDocumentId;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        if(recordid.getSObjectType().getDescribe().getName() != 'Case'){
            Note nt = new Note();
            nt.Title = 'nt Title';
            nt.Body = 'nt Body';
            nt.IsPrivate = false;
            nt.parentId = recordid;
            insert nt;
        }
        
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('Blob String');
        att.Name = 'Note_' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.txt';
        att.parentId = recordid;
        insert att;
        return att;
    }
    
}