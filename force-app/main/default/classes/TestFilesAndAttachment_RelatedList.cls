/*       
* Created By    : Saranya Rajagopal
* Created Date  : 14-06-2023
* Description   : Test class for FilesAndAttachment_RelatedList_Handler
*/

@isTest
public class TestFilesAndAttachment_RelatedList {
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
    static void testRelatedFiles()
    {
        List<Attachment> lstAttachmentsToInsert = new List<Attachment>();
        List<Note> lstNotesToInsert = new List<Note>();
        List<String> idDelete = new List<String>();

        
        Account acc = new Account();
        acc.Name = 'Test Account Related Files';
        insert acc;
        
        Contract cnt = new Contract();
        cnt.Original_Signed_Date__c = DateTime.newInstance(2020, 1, 1);
        cnt.Status = 'Draft';
        cnt.AccountId = acc.Id;
        insert cnt;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Open';
        opp.Name = 'Test Opp Related Files';
        opp.CloseDate = Date.today() + 30;
        insert opp;
        
        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.LastName = 'Test Related Files';
        insert c;
               
        
        Attachment attach = new Attachment();
        attach.Name = 'Attachment for Contract';
        attach.Body = Blob.valueOf('Attachment for Contract');
        attach.ParentId = cnt.Id;
        lstAttachmentsToInsert.add(attach);
        
        Attachment attach2 = new Attachment();
        attach2.Name = 'Attachment for Case';
        attach2.Body = Blob.valueOf('Attachment for Case');
        attach2.ParentId = c.Id;
        lstAttachmentsToInsert.add(attach2);
        
        insert lstAttachmentsToInsert;
        
        ContentVersion cv = new ContentVersion();
        cv.Title='Test Related Files';
        cv.PathOnClient ='Test Related Files';
        cv.VersionData = Blob.valueOf('Test Related Files');
        cv.IsMajorVersion = true;
        insert cv;
        
        ContentDocument cd = [Select Id from ContentDocument LIMIT 1];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = cnt.Id;
        cdl.ContentDocumentId = cd.Id;
        insert cdl;
        
        Note n = new Note();
        n.Title = 'Test Related Files';
        n.ParentId = cnt.Id;
        n.Body = 'Test Related Files';
        insert n;
        idDelete.add(cdl.id);
        
        Test.startTest();
        FilesAndAttachment_RelatedList_Handler.getFiles(cnt.Id);
        FilesAndAttachment_RelatedList_Handler.deleteFiles(idDelete);
        //FilesAndAttachment_RelatedList_Handler.checkDeletePermissionset();
        Test.stopTest();
    }
}