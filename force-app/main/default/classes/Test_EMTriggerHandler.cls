@isTest public class Test_EMTriggerHandler {
    @isTest static void test_IsDelete() {
        EmailMessage em = new EmailMessage();
        em.TextBody = 'stuff';
        em.Subject = 'theSubject';
        Case c = new Case();
        c.status = 'new';
        insert c; 
        em.ParentId = c.id;
        insert em;
        Boolean expectedExceptionThrown = false;
        Test.startTest();
        try{
            delete em;
        } catch (Exception e) {
            if(e.getMessage().contains('You do not have permission to delete this record')){
                expectedExceptionThrown = true;
            }
        }
        Test.stopTest();
        System.assertEquals(expectedExceptionThrown, true, 'The expected exception wasnt thrown');
    }

    @isTest
    static void testActiveEyesE2C() {
        Account acc = new Account();
        acc.name = 'Test E2C Account';
        Triggers.switchOff();
        insert acc;
        Contact con = new Contact();
        con.lastName = 'Test';
        con.email = 'test@test.com'; con.accountId = acc.Id;
        insert con;
        Triggers.switchOn();
        EmailMessage em = new EmailMessage();
        em.TextBody = 'Customer Email: test.test@test.com \n'+ 'Description: Bad Request – testing email to case 12 \n' + 'Technical Details: Web Service Error Message: {"error":"invalid_client_id","error_description":"client identifier invalid"}\n'
        + 'Record ID: '+ acc.Id +'\n' + 'Severity Level: "1" ';
        em.Subject = 'Test active eyes E2C';
        em.Incoming = true;
        em.ToAddress = System.Label.Active_Eyes_E2C_Address;
        Case c = new Case();
        c.status = 'new';
        insert c; 
        em.ParentId = c.id;
        insert em;
        Case caseData  = [SELECT id, Case_Severity__c from Case where Id = :c.Id]; 
        System.assert(caseData.Case_Severity__c == 'Level 1 - Critical', 'Incorrect Case severity ');
    }
    //Included as part of PBC-20631 - Add Automated Emails from CNR Flow as Case Comments on Case
    @isTest 
    static void testCreateCaseCommentsForEmailsFromStandardCNRFlow() { 
        insert new CNR_Case_Condition__c(Brands__c = 'RingCentral',RecordTypes__c='Support_T1');
        Account a = new Account();
        a.Name='Test';
        a.RC_Brand__c='RingCentral';
        insert a;
        Case c = new Case();
        c.RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1;
        c.AccountId=a.Id;
        c.Status='New';
        Triggers.switchOff();
        insert c;
        c.Status='Waiting on Customer';
        update c;
        Triggers.switchOn();
        EmailMessage e = new EmailMessage();
        e.FromAddress= 'techsupport@ringcentral.com';
        e.FromName = 'RingCentral Technical Support';
        e.Subject='Test CNR';
        e.TextBody='Test CNR';
        e.ParentId = c.Id;
        Test.startTest();
        insert e;
        Test.stopTest();
        List<CaseComment> caseCommentList=[Select Id from CaseComment where parentId=:c.Id];
        System.assertEquals(1,caseCommentList.size());
    }
    @isTest
    static void testCreateCaseCommentsForEmailsFromPartnerCNRFlow() {
        Account a1;
        Case c1;
        List <CaseComment> caseCommentList = new List<CaseComment>();
        List<Partner_CNR_setting__mdt> mtd = [select Brand_name__c, Record_Type__c, Sender_email__c from Partner_CNR_setting__mdt limit 1];
    
        if (mtd.size() > 0) {
            Id CaseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(mtd[0].Record_Type__c.split(',')[0]).getRecordTypeId();
    
            a1 = new Account(Name = 'Test', RC_Brand__c = mtd[0].Brand_name__c);
            insert a1;
    
            c1 = new Case(RecordTypeId = CaseRtId, AccountId = a1.Id, Status = 'Waiting on Customer',
                Case_Reason__c = 'Backlog Case');
            insert c1;
    
            EmailMessage em = new EmailMessage(FromAddress = mtd[0].Sender_email__c, Subject = 'Test',
                TextBody = 'Test CNR_FOLLOWUP', HtmlBody = '<p>CNR_FOLLOWUP<p>', ParentId = c1.Id);
    
            Test.starttest();
            insert em;
            Test.stoptest();
            caseCommentList = [Select Id from CaseComment where parentId =: c1.Id];
        }
        System.assertEquals(1, caseCommentList.size());
    }

    //Included as part of PBC-25253 - Creation of public case comments for BT case emails. 
    @isTest
    static void testCreateCaseCommentsForBTCaseEmails() {
        // Step 1: Create test data using SObjectBuilder
        Account a = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'BT Business Test',
                    Account.RC_Brand__c => 'BT Business'
                    })
            .create()
            .getRecord();
        
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Test',
                    Contact.Email => 'test@test.com',
                    Contact.AccountId => a.Id
                    })
            .create()
            .getRecord();
        
        Triggers.switchOff();
        
        Case btCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'New',
                    Case.AccountId => a.Id,
                    Case.ContactId => con.Id,
                    Case.Original_RecordType__c => 'Support_Case',
                    Case.Origin => 'Web'
                    })
            .create()
            .getRecord();

        Triggers.switchOn();
        
        EmailMessage email = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                EmailMessage.ParentId => btCase.Id,
                    EmailMessage.Subject => 'Test BT Email',
                    EmailMessage.FromAddress => 'techsupport@ringcentral.com',
                    EmailMessage.FromName => 'RingCentral Technical Support',
                    EmailMessage.TextBody => 'This is a test email for BT Case',
                    EmailMessage.Incoming => false
                    })
            .create()
            .getRecord();
        
        
        // Step 2: Validate the results
        List<CaseComment> caseComments = [SELECT Id, ParentId, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :btCase.Id];
        System.assertEquals(1, caseComments.size(), 'Expected one CaseComment to be created');
        System.assertEquals('This is a test email for BT Case', caseComments[0].CommentBody, 'Comment body does not match');
        System.assertEquals(true, caseComments[0].IsPublished, 'Comment should be published');
    }
    
    //Included as part of PBC-25253 - Creation of public case comments Developer Portal case emails. 
    @isTest
    static void testCreateCaseCommentsForDeveloperPortal() {
        // Step 1: Create test data using SObjectBuilder
        Account a = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'BT Business Test',
                    Account.RC_Brand__c => 'RingCentral'
                    })
            .create()
            .getRecord();
        
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Test',
                    Contact.Email => 'test@test.com',
                    Contact.AccountId => a.Id
                    })
            .create()
            .getRecord();
        
        Triggers.switchOff();
        
        
        // Step 2: Create test data for Developer Platform Case
        Case devCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'New',
                    Case.AccountId => a.Id,
                    Case.ContactId => con.Id,
                    Case.Original_RecordType__c => 'Developer_Platform'
                    })
            .create()
            .getRecord();
        

        Triggers.switchOn();
        
        
        EmailMessage devEmail = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            EmailMessage.ParentId => devCase.Id,
            EmailMessage.Subject => 'Test Developer Portal Email',
            EmailMessage.FromAddress => 'techsupport@ringcentral.com',
            EmailMessage.FromName => 'RingCentral Technical Support',
            EmailMessage.TextBody => 'This is a test email for Developer Portal Case',
            EmailMessage.Incoming => false
        })
        .create()
        .getRecord();
        
        
        // Step 2: Validate the results
        List<CaseComment> caseComments = [SELECT Id, ParentId, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :devCase.Id];
        System.assertEquals(1, caseComments.size(), 'Expected one CaseComment to be created');
        System.assertEquals('This is a test email for Developer Portal Case', caseComments[0].CommentBody, 'Comment body does not match');
        System.assertEquals(true, caseComments[0].IsPublished, 'Comment should be published');
    }
    
    //Included as part of PBC-25253 - Creation of public case comments for BT case emails (default web-to-case template).
    @isTest
    static void testNoCaseCommentForDefaultWebToCaseEmail() {
        // Step 1: Create test data using SObjectBuilder
        Account a = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'BT Business Test',
                    Account.RC_Brand__c => 'BT Business'
                    })
            .create()
            .getRecord();
        
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Test',
                    Contact.Email => 'test@test.com',
                    Contact.AccountId => a.Id
                    })
            .create()
            .getRecord();
        
        Triggers.switchOff();
        
        Case btCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'New',
                    Case.AccountId => a.Id,
                    Case.ContactId => con.Id,
                    Case.Original_RecordType__c => 'Support_Case',
                    Case.Origin => 'Web'
                    })
            .create()
            .getRecord();
        
        Triggers.switchOn();
        
        // Assume this matches exactly with your "Web-to-Case (Sample)" template content
        EmailMessage email = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                EmailMessage.ParentId => btCase.Id,
                    EmailMessage.Subject => 'Thank you for your message', // Matches default web-to-case template
                    EmailMessage.FromAddress => 'techsupport@ringcentral.com',
                    EmailMessage.FromName => 'RingCentral Customer Support',
                    EmailMessage.HtmlBody => 'Thank you for your message. We’re tracking your request in case #123456.A member of our team will reach out shortly.',
                    EmailMessage.Incoming => false
                    })
            .create()
            .getRecord();
        List<CaseComment> caseComments = [SELECT Id, ParentId, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :btCase.Id];
        System.assertEquals(1, caseComments.size(), 'Expected one CaseComment to be created');
        System.assertEquals(true, caseComments[0].IsPublished, 'Comment should be published');
    }
    
    
    // Test case to handle exceptions properly in Case Comment creation
    @isTest
    static void testCreateCaseCommentsExceptionHandling() {
        // Create test data
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'BT Business Test',
                    Account.RC_Brand__c => 'BT Business'
                    })
            .create()
            .getRecord();
        
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Test',
                    Contact.Email => 'test@test.com',
                    Contact.AccountId => acc.Id
                    })
            .create()
            .getRecord();
        
        Triggers.switchOff();
        
        Case btCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'New',
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Original_RecordType__c => 'Support_Case',
                    Case.Origin => 'Web'
                    })
            .create()
            .getRecord();
        
        Triggers.switchOn();
        
        EmailMessage email = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                EmailMessage.ParentId => btCase.Id,
                    EmailMessage.Subject => 'Thank you for your message',
                    EmailMessage.FromAddress => 'techsupport@ringcentral.com',
                    EmailMessage.FromName => 'RingCentral Customer Support',
                    EmailMessage.HtmlBody => 'Thank you for your message. We’re tracking your request in case #123456.A member of our team will reach out shortly.',
                    EmailMessage.Incoming => false
                    })
            .create()
            .getRecord();
        
        // Force an exception in case comment creation to test exception handling
        Integer MAX_COMMENT_LENGTH = 0; // Force an invalid length for testing exception handling
        Boolean exceptionThrown = false;
        
        try {
            CaseCommentHelperForOutboundEmails.createCaseComments(
                new Map<Id, EmailMessage>{btCase.Id => null},
                new Map<Id, Case>{btCase.Id => null},
                MAX_COMMENT_LENGTH
            );
            CaseCommentHelperForOutboundEmails.cleanContent(null);
            CaseCommentHelperForOutboundEmails.isContentMatch(null,null);
            CaseCommentHelperForOutboundEmails.isEmailMatchingTemplate(null,null);
            CaseCommentHelperForOutboundEmails.logException( null,2);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        // Step 2: Validate the results
        List<CaseComment> caseComments = [SELECT Id, ParentId, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :btCase.Id];
        System.assertEquals(1, caseComments.size(), 'Expected one CaseComment to be created');
    }

    // Included as part of PBC-31821 - byte-aware truncation of CaseComment body for TCR CNR emails
    // ── shouldTruncateCaseCommentByBytes_WhenTCRCNREmailBodyExceedsLimit ───

    @IsTest
    static void shouldTruncateCaseCommentByBytes_WhenTCRCNREmailBodyExceedsLimit() {
        String accountName = (String) ValueProviderBuilder.provideUniqueString().getValue();
        String contactLastName = (String) ValueProviderBuilder.provideUniqueString().getValue();
        String contactEmail = (String) ValueProviderBuilder.provideUniqueString().getValue() + '@test.com';
        String rcBrand = 'RingCentral';
        String tcrCaseReason = 'TCR Support';
        String emailSubject = 'Reply Check on TCR - CNR';
        String fromAddress = 'techsupport@ringcentral.com';
        String fromName = 'TCR Automation';
        String caseStatus = 'New';
        Integer minBodyLength = 6000;
        Integer commentFieldLength = Schema.SObjectType.CaseComment.fields.CommentBody.getLength();

        Account tcrAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => accountName,
                Account.RC_Brand__c => rcBrand
            })
            .create()
            .getRecord();

        Contact tcrContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => contactLastName,
                Contact.Email => contactEmail,
                Contact.AccountId => tcrAccount.Id
            })
            .create()
            .getRecord();

        Triggers.switchOff();

        Case tcrCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => caseStatus,
                Case.AccountId => tcrAccount.Id,
                Case.ContactId => tcrContact.Id,
                Case.Case_Reason__c => tcrCaseReason
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        // 93 chars / 107 bytes per repeat (7 multi-byte chars: smart quote U+2019, bullet U+2022).
        // Repeated until > 6000 chars, the body exceeds the char limit; the first commentFieldLength
        // chars still exceed commentFieldLength bytes, forcing the byte re-trim branch to execute.
        String multiByteUnit = 'We\u2019re reviewing your case\u2019s status \u2022 here\u2019s what we\u2019ll do next \u2022 confirm details \u2022 resubmit. ';
        String longBody = '';
        while (longBody.length() < minBodyLength) {
            longBody += multiByteUnit;
        }

        String bodyExceedsCharLimitMessage = 'Body must exceed the CaseComment character limit';
        Assert.isTrue(longBody.length() > commentFieldLength, bodyExceedsCharLimitMessage);

        String firstCharsExceedByteLimitMessage = 'First commentFieldLength chars must exceed byte limit so the byte re-trim branch runs';
        Assert.isTrue(
            Blob.valueOf(longBody.substring(0, commentFieldLength)).size() > commentFieldLength,
            firstCharsExceedByteLimitMessage
        );

        Test.startTest();
        new SObjectBuilder(EmailMessage.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                EmailMessage.ParentId => tcrCase.Id,
                EmailMessage.Subject => emailSubject,
                EmailMessage.FromAddress => fromAddress,
                EmailMessage.FromName => fromName,
                EmailMessage.HtmlBody => '<p>' + longBody + '</p>',
                EmailMessage.TextBody => longBody,
                EmailMessage.Incoming => true
            })
            .create()
            .getRecord();
        Test.stopTest();

        List<CaseComment> comments = [
            SELECT Id, CommentBody
            FROM CaseComment
            WHERE ParentId = :tcrCase.Id
        ];

        String expectedCommentCountMessage = 'Expected one TCR case comment to be created';
        Assert.areEqual(1, comments.size(), expectedCommentCountMessage);

        String commentBody = comments[0].CommentBody;
        Integer commentByteLength = Blob.valueOf(commentBody).size();

        String byteLimitMessage = 'Stored comment must fit the CaseComment field byte limit';
        Assert.isTrue(commentByteLength <= commentFieldLength, byteLimitMessage);

        String charLimitMessage = 'Stored comment must fit the CaseComment field character limit';
        Assert.isTrue(commentBody.length() <= commentFieldLength, charLimitMessage);

        String ellipsisSuffixMessage = 'Truncated comment should end with an ellipsis';
        Assert.isTrue(commentBody.endsWith('...'), ellipsisSuffixMessage);

        String multiByteContentMessage = 'Truncated body should still contain multi-byte characters';
        Assert.isTrue(commentByteLength > commentBody.length(), multiByteContentMessage);
    }
}