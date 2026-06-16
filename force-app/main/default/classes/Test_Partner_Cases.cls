@isTest
public class Test_Partner_Cases {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testListView()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Account acc = new Account();
        acc.Name = 'Test23';
        acc.type = 'Customer';
        acc.Avaya_Partnership_Account__c = true;
        acc.RC_Brand__c = 'Avaya Cloud Office';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert acc;
        }
        Case caseRec = new Case();
        caseRec.AccountId = acc.Id;
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Collections Dispute').getRecordTypeId();
        system.debug('recordTypeId - '+recordTypeId);
        caseRec.recordTypeId = recordTypeId;        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getListView('Test23', 'Subject', 1, 10);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectedCase()
    {        
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getSelectedCase(caseRec.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCaseComments()
    {        
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        /*CaseComment caseComment = new CaseComment();
        caseComment.CommentBody = 'Test23';
        caseComment.IsPublished = true;
        caseComment.ParentId = caseRec.Id;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseComment;
        }*/
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getCaseComments(caseRec.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCaseEmails()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseRec.Id; 
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert email;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getCaseEmails(caseRec.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCaseEmail()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseRec.Id; 
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert email;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getCaseEmail(email.Id);
        Test.stopTest();
    }   
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAttachments()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
        }
        Attachment attachment = new Attachment();
        attachment.Name = 'test23';
        attachment.Body = Blob.valueOf('Test Data');
        attachment.ParentId = caseRec.Id; 
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert attachment;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getAttachments(caseRec.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLightningFiles()
    {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        Case caseRec = new Case();
        caseRec.Subject = 'Test23';
        caseRec.Issue_Type__c = 'Taxes';
        caseRec.Description = 'Test23';
        caseRec.Value_of_Invoices_under_Dispute__c = 100;
        caseRec.Status = 'New';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin)
        {
            insert caseRec;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'I';
            cdl.Visibility='AllUsers';
            cdl.LinkedEntityId =caseRec.Id; 
            insert cdl;
        }
        
        Test.startTest();
        Partner_Cases partnerCases = new Partner_Cases();
        Partner_Cases.getLightningFiles(caseRec.Id);
        Test.stopTest();
    }
    
}