/*       
* Created By    : Namitha
* Created Date  : 22-09-2020
* Description   : Test class for Account_RelatedFilesController
*/
@isTest
public class Test_Account_RelatedFilesController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testRelatedFiles()
    {
        List<Attachment> lstAttachmentsToInsert = new List<Attachment>();
        List<Note> lstNotesToInsert = new List<Note>();
        
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
        cdl.LinkedEntityId = opp.Id;
        cdl.ContentDocumentId = cd.Id;
        insert cdl;
        
        Note n = new Note();
        n.Title = 'Test Related Files';
        n.ParentId = opp.Id;
        n.Body = 'Test Related Files';
        insert n;
        
        Test.startTest();
        Account_RelatedFilesController.getRelatedFilesList(acc.Id);
        Account_RelatedFilesController.deleteAttachment(attach.Id,'Attachment');
        Test.stopTest();
    }
}