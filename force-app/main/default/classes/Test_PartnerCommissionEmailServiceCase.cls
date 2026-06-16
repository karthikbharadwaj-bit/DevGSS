@isTest
public class Test_PartnerCommissionEmailServiceCase {
    
    @TestSetup
    static void setupData() {
        
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => account.Id,
                Contact.Email => 'abc2@test.com',
                Contact.LastName => 'Test Last2',
                Contact.FirstName => 'Test First2'
            })
            .create()
            .getRecord();

        
        Group groupName = (Group) new SObjectBuilder(Group.SobjectType)
            .setFields(new Map<SObjectField, Object>{
                Group.Name => 'Partner Commissions',
            	Group.Type => 'Queue'
            })
            .create()
            .getRecord();
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
        
        System.runAs(testUser) {
        QueuesObject testQueueSObject = (QueueSObject) new SObjectBuilder(QueueSObject.getSObjectType())
                .setFields(
                    new Map<SObjectField, Object>{
                        QueueSObject.QueueID => groupName.Id,
                        QueueSObject.SObjectType => 'Case'
                    })
                .create()
                .getRecord();
        }   
    }
    
    @IsTest
    static void testHandleInboundEmail() {
        // Prepare the inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Email Subject';
        email.fromAddress = 'testcontact@example.com';
        email.fromName = 'Test Contact';
        email.plainTextBody = 'This is the body of the test email.';
        email.Htmlbody= 'This is the Html body of the test email.';
        email.toAddresses = new List<String>{'testcontact@example.com'};
        
        // Prepare binary attachments
        Messaging.InboundEmail.BinaryAttachment testAttachment = new Messaging.InboundEmail.BinaryAttachment();
        testAttachment.fileName = 'TestAttachment.pdf';
        testAttachment.body = Blob.valueOf('This is a test attachment.');
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{ testAttachment };
            
        // Prepare text attachments
        Messaging.InboundEmail.TextAttachment testtextAttachment = new Messaging.InboundEmail.TextAttachment();
        testtextAttachment.fileName = 'TesttextAttachment.txt';
        testtextAttachment.body = 'This is a text test attachment.';
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{ testtextAttachment };    
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testcontact@example.com';
        
        // Instantiate the email service handler
        PartnerCommissionEmailServiceCase emailService = new PartnerCommissionEmailServiceCase();
        
        // Call the handleInboundEmail method and capture the result
        Test.startTest();
        Messaging.InboundEmailResult result = emailService.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        // Query the created case
        Case createdCase = [SELECT Id, Subject, Description, SuppliedEmail, SuppliedName, OwnerId, RecordTypeId FROM Case WHERE SuppliedEmail = 'testcontact@example.com' LIMIT 1];
        
        // Verify the Case was created correctly
        System.assertNotEquals(null, createdCase, 'Case should be created');
        System.assertEquals('Test Email Subject', createdCase.Subject, 'Case subject should match the email subject');
        System.assertEquals('This is the body of the test email.', createdCase.Description, 'Case description should match the email body');
        System.assertEquals('testcontact@example.com', createdCase.SuppliedEmail, 'Supplied email should match');
        System.assertEquals('Test Contact', createdCase.SuppliedName, 'Supplied name should match');
        
        // Verify the Case Owner is set correctly
        Id expectedOwnerId = [SELECT Id FROM Group WHERE Name = 'Partner Commissions' LIMIT 1].Id;
        System.assertEquals(expectedOwnerId, createdCase.OwnerId, 'Owner should match the Partner Commissions group');
        
        // Verify the Record Type
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Partner Commissions' LIMIT 1].Id;
        System.assertEquals(recordTypeId, createdCase.RecordTypeId, 'RecordType should match Partner Commissions');

        // Query the created attachment
        List<Attachment> attachments = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId = :createdCase.Id];
        System.assertEquals(2, attachments.size(), 'Two attachments should be created'); 
        
        Boolean binaryAttachmentFound = false; 
        Boolean textAttachmentFound = false; 
        
        for (Attachment attachment : attachments) { 
            if (attachment.Name == 'TestAttachment.pdf') { 
                binaryAttachmentFound = true; 
            } else if (attachment.Name == 'testTextAttachment.txt') { 
                textAttachmentFound = true;  
            } 
        } 
        System.assert(binaryAttachmentFound, 'Binary attachment should be found'); 
        System.assert(textAttachmentFound, 'Text attachment should be found');
    }

    @isTest
    static void testTruncateEmail_NullText() {
        String truncatedText = PartnerCommissionEmailServiceCase.truncateEmail('Case', 'Description', null);
        System.assertEquals(null, truncatedText, 'The result should be null for null input');
    }

    @isTest
    static void testTruncateEmail_BlankText() {
        String truncatedText = PartnerCommissionEmailServiceCase.truncateEmail('Case', 'Description', '');
        System.assertEquals('', truncatedText, 'The result should be blank for blank input');
    }
    
    @isTest 
    static void testTruncateEmail_InvalidObject() { 
        try { 
            PartnerCommissionEmailServiceCase.truncateEmail('InvalidObject', 'Description', 'Test'); 
            System.assert(false, 'An exception should have been thrown for invalid object API name'); 
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid object API name'), 'The exception should indicate an invalid object API name'); 
        } 
    } 
    
    @isTest 
    static void testTruncateEmail_InvalidField() { 
        try { 
            PartnerCommissionEmailServiceCase.truncateEmail('Case', 'InvalidField', 'Test'); 
            System.assert(false, 'An exception should have been thrown for invalid field API name'); 
        } catch (IllegalArgumentException e) { 
            System.assert(e.getMessage().contains('Invalid field API name'), 'The exception should indicate an invalid field API name'); 
        } 
    }
}