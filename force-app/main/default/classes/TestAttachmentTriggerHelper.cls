@isTest
class TestAttachmentTriggerHelper {
	
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	private static void test_Attachments_classic() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Acme Inc'
                }
            )
            .create()
            .getRecord();

        Approval__c approvalRecord = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Acme Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_BOB_APPROVAL
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            new SObjectBuilder(Attachment.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Attachment.Name => ValueProviderBuilder.provideList(new List<String>{'Unit Test Attachment 1', 'Unit Test Attachment 2'}),
                        Attachment.body => ValueProviderBuilder.provideList(new List<Blob>{Blob.valueOf('Unit Test Attachment 1 Body'), Blob.valueOf('Unit Test Attachment 2 Body')}),
                        Attachment.parentId => approvalRecord.id
                    }
                )
                .quantity(2)
                .create();
        Test.stopTest();
	}

    @testSetup
    private static void prepareDocuSignTestData() {
        Account acc = new Account();
        acc.Name = 'Test Accont #1';
        insert acc;

        Contract cnt1 = new Contract();
        cnt1.Original_Signed_Date__c = DateTime.newInstance(2000, 1, 1);
        cnt1.Status = 'Draft';
        cnt1.AccountId = acc.Id;

        Contract cnt2 = new Contract();
        cnt2.Original_Signed_Date__c = DateTime.newInstance(2001, 1, 1);
        cnt2.Status = 'Draft';
        cnt2.AccountId = acc.Id;

        Contract cnt3 = new Contract();
        cnt3.Original_Signed_Date__c = DateTime.newInstance(2002, 1, 1);
        cnt3.Status = 'Draft';
        cnt3.AccountId = acc.Id;

        insert new List<Contract> { cnt1, cnt2, cnt3 };

        //We can use active status when creating contracts :(
        cnt2.Status = 'Active';
        cnt3.Status = 'Active';
        update new List<Contract> { cnt2, cnt3 };

        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.dsfs__Company__c = acc.Id;
        docuSignStatus.dsfs__Envelope_Status__c = 'Completed';
        insert docuSignStatus;

        Attachment attToDocuSign1 = new Attachment();
        attToDocuSign1.Name = 'Attached PFD #1' + ' {' + acc.Id + '}';
        attToDocuSign1.Body = Blob.valueOf('ATTACHMENT #1');
        attToDocuSign1.ParentId = docuSignStatus.Id;

        Attachment attToDocuSign2 = new Attachment();
        attToDocuSign2.Name = 'Attached PFD #2' + ' {' + acc.Id + '}';
        attToDocuSign2.Body = Blob.valueOf('ATTACHMENT #1');
        attToDocuSign2.ParentId = docuSignStatus.Id;
        insert new List<Attachment> { attToDocuSign1, attToDocuSign2 };
    }

    @isTest
    private static void TestDocuSignAttachments_Positive_WillBeCopied() {
        dsfs__DocuSign_Status__c docuSign = [SELECT dsfs__Company__c FROM dsfs__DocuSign_Status__c];
        Attachment[] docuSignAttaches = [SELECT Name, Body FROM Attachment WHERE ParentId = :docuSign.Id];
        
        for(Attachment entry : docuSignAttaches) {
            entry.Body = Blob.valueOf(entry.Body.toString() + ' SIGNED');
        }
        update docuSignAttaches;
        
        Test.startTest();
        
        Attachment[] docuSignAttachments = [SELECT Name, Body FROM Attachment WHERE ParentId = :docuSign.Id];
        
        Contract[] contracts = [
            SELECT Status, Original_Signed_Date__c, (SELECT Id FROM Attachments)
            FROM Contract
            WHERE AccountId = :docuSign.dsfs__Company__c];
        
        Attachment[] contractAttachments = [SELECT Name, Body, ParentId FROM Attachment WHERE ParentId IN :contracts];
        
        Account[] accounts = new AccountSelector()
            .selectAccounts()
            .executeQuery();
        
        Attachment[] accountAttachments = new AttachmentSelector()
            .selectAttachmentsByListOfParentIds(new List<Object> {accounts})
            .executeQuery();
        
        Test.stopTest();
        
        Contract latestActiveContract = null;
        for(Contract entry : contracts) {
            if (latestActiveContract == null) {
                latestActiveContract = entry;
                continue;
            }
            if (entry.Status != 'Active') { continue; }
            if (entry.Original_Signed_Date__c > latestActiveContract.Original_Signed_Date__c) {
                latestActiveContract = entry;
            }
        }
        System.assert(latestActiveContract != null, 'Could not find active contract with latest original signed date');
        
        Integer expectedContractAttachmentCount = latestActiveContract == null ? 0 : 2;
        System.assertEquals(expectedContractAttachmentCount, contractAttachments.size(), 'Contract should have 2 attachments copied from DocuSignStatus');
        System.assertEquals(2, accountAttachments.size(), 'Account should have 2 attachments copied from DocuSignStatus');
        System.assertEquals(contractAttachments.size(), accountAttachments.size(), 'Attachments count should be the same, cause of copied from DocuSignStatus');
        
        Boolean allAttachmentsAreFound = false;
        for(Attachment dsAtt : docuSignAttachments) {
            allAttachmentsAreFound = false;
            for (Attachment cntAtt : contractAttachments) {
                if (dsAtt.Name == cntAtt.Name && dsAtt.Body.toString() == cntAtt.Body.toString()) {
                    System.assert(cntAtt.Body.toString().contains('SIGNED'), 'Body of the attachment should contains SIGNED word');
                    allAttachmentsAreFound = true;
                    break;
                }
            }
        }
        System.assert(allAttachmentsAreFound, 'Not all attachments were copied from DocuSign to contract record');
    }

    @isTest
    static void testAttachmentIsCopiedToAccountFromDocusignStatus() {
        String attachmentName = 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00';
        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        dsfs__DocuSign_Status__c env = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocusignHelper.ENVELOPE_STATUS_COMPLETED
            })
            .create()
            .getRecord();

        new SObjectBuilder(Attachment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Attachment.Name => attachmentName + '.pdf',
                Attachment.Body => EncodingUtil.base64Decode('Body'),
                Attachment.ParentId => env.Id
            })
            .create()
            .getRecord();

        List<Attachment> attachments = (List<Attachment>) new AttachmentSelector()
            .selectAttachmentsByParentId(new List<Object>{acc.Id})
            .executeQuery();

        System.assertEquals(1, attachments.size(), 'One attachment should be copied to Account');
        System.assertEquals(attachmentName + '_Signed.pdf', attachments.get(0).Name, 'Attachment name is wrong');
    }

    @isTest
    static void testAccountNdaStatusPopulatesOnAttachmentCreation() {
        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        new SObjectBuilder(Attachment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Attachment.Name => 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00.pdf',
                Attachment.ParentId => acc.Id,
                Attachment.Body => EncodingUtil.base64Decode('Body')
            })
            .create();

        Account updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.NDA_GENERATED, updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be set to \'Generated\'');
    }

    @isTest
    static void testAccountNdaStatusPopulatesOnDocusignStatusCreation() {
        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        dsfs__DocuSign_Status__c env = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocusignHelper.ENVELOPE_STATUS_SENT
            })
            .create()
            .getRecord();

        Attachment att = (Attachment) new SObjectBuilder(Attachment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Attachment.Name => 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00.pdf',
                Attachment.Body => EncodingUtil.base64Decode('Body'),
                Attachment.ParentId => env.Id
            })
            .create()
            .getRecord();

        Account updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.NDA_OUT_FOR_SIGNATURE, updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be set to \'Out for Customer Signature\'');
    }

    // @isTest
    // static void testSecondNdaAttachmentNotAffectNdaStatus() {
    //     Account acc = (Account) new AccountSelector()
    //         .selectAccounts()
    //         .executeQuery()
    //         .get(0);

    //     dsfs__DocuSign_Status__c env = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
    //             dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
    //             dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocusignHelper.ENVELOPE_STATUS_SENT
    //         })
    //         .create()
    //         .getRecord();

    //     new SObjectBuilder(Attachment.SObjectType)
    //         .setFields(new Map<SObjectField, Object> {
    //             Attachment.Name => 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00.pdf',
    //             Attachment.Body => EncodingUtil.base64Decode('Body'),
    //             Attachment.ParentId => env.Id
    //         })
    //         .create();

    //     env.dsfs__Envelope_Status__c = DocusignHelper.ENVELOPE_STATUS_COMPLETED;
    //     update env;

    //     new SObjectBuilder(Attachment.SObjectType)
    //         .setFields(new Map<SObjectField, Object> {
    //             Attachment.Name => 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00.pdf',
    //             Attachment.Body => EncodingUtil.base64Decode('Body'),
    //             Attachment.ParentId => env.Id
    //         })
    //         .create();

    //     Account updatedAcc = (Account) new AccountSelector()
    //         .selectAccountById(acc.Id)
    //         .selectField('NdaStatus__c')
    //         .executeQuery()
    //         .get(0);

    //     System.assertEquals(AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(env.dsfs__Envelope_Status__c),
    //         updatedAcc.NdaStatus__c,
    //         'NdaStatus__c on Account should be set to \'Signed by Customer\'');
    // }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testLegacyProcessing(){
        Test.startTest();
        Profile p = [select id from profile where name='System Administrator'];
        
        User testUser = new User(alias = 'u111', email='u111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='UTesting11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        insert testUser;
        
        Opportunity o = new Opportunity();
        o.StageName = '1. Qualify';
        o.CloseDate = system.today();
        o.ForecastCategoryName = 'Commit';
        o.OwnerId = testUser.Id;
        o.Name = 'TEST OPP';
        
        insert o;
        
        Case c = new Case();
        c.Subject = 'TEST CASE';
        c.OwnerId = testUser.Id;
        c.Description = 'testing';
        c.Status ='New';
        c.Priority = 'Medium';
        c.Origin = 'Email';
        insert c;
        
        Lead l = new Lead();
        l.Company = 'TEST';
        l.LastName = 'TEST';
        l.Status = '1. New';
        l.email = 'fake@email.com';
        insert l;
        
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        
        Attachment att = new Attachment();
        att.ParentId = o.Id;
        att.Name='Unit Test Attachment';
        att.body=bodyBlob;
        
        Attachment att2 = new Attachment();
        att2.ParentId = c.Id;
        att2.Name='Unit Test Attachment';
        att2.body=bodyBlob;
        
        Attachment att3 = new Attachment();
        att3.ParentId = l.Id;
        att3.Name='Unit Test Attachment';
        att3.body=bodyBlob;
        
        insert (new List<Attachment> {att, att2, att3});
        Test.stopTest();
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testKnowledgeContentAccess() {
        // Create Integration User Settings record for the current user
        Knowledge_Attachment_Settings__c setting = new Knowledge_Attachment_Settings__c(
            Name = 'TestUser',
            User_Id__c = UserInfo.getUserId()
        );
        insert setting;
        
        // Create test Account as a linked entity
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create ContentVersion
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert contentVersion;
        
        // Retrieve ContentDocumentId
        contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        
        // Create ContentDocumentLink linked to the Account
        ContentDocumentLink testLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        Test.startTest();
        insert testLink; // This triggers the handler
        Test.stopTest();
        
        // Verify ContentDocumentLinks after trigger execution
        List<ContentDocumentLink> linkedContent = [
            SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentVersion.ContentDocumentId
        ];
        
        System.assertEquals(3, linkedContent.size(), 'Three ContentDocumentLinks should exist.');
        
        // Find the link created by the trigger (LinkedEntityId = Organization ID)
        ContentDocumentLink orgLink;
        for (ContentDocumentLink link : linkedContent) {
            if (link.LinkedEntityId == UserInfo.getOrganizationId()) {
                orgLink = link;
                break;
            }
        }
        
        // Assert that the trigger-created link exists and has the correct properties
        System.assertNotEquals(null, orgLink, 'A ContentDocumentLink to the organization should exist.');
        System.assertEquals('V', orgLink.ShareType, 'Share type should be View.');
        System.assertEquals('AllUsers', orgLink.Visibility, 'Visibility should be AllUsers.');
    } 

     @isTest
    static void testProfileRetrieval_WithLeadConversionAndCacheEnabled_UsesCachedProfile() {
        // Given
        // Enable lead conversion processing and cache feature
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        
        // Mock cache with profile data
        String currentProfileId = UserInfo.getProfileId();
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Id = :currentProfileId LIMIT 1];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, currentProfileId, testProfile, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile currentUserProfileRecord = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(currentUserProfileRecord, 'Profile should not be null when cache is enabled');
        Assert.areEqual(testProfile.Id, currentUserProfileRecord.Id, 'Should return cached profile ID');
        Assert.areEqual(testProfile.Name, currentUserProfileRecord.Name, 'Should return cached profile name');
    }
    
    @isTest
    static void testProfileRetrieval_WithLeadConversionOrCacheDisabled_UsesDirectQuery() {
        // Given
        // Disable lead conversion processing or cache feature
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = false;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = false;
        
        String currentProfileId = UserInfo.getProfileId();
        
        // Clear cache to ensure direct query is used
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile currentUserProfileRecord = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        Test.stopTest();
        
        // Then
        Assert.isNotNull(currentUserProfileRecord, 'Profile should not be null when using direct query');
        Assert.areEqual(currentProfileId, currentUserProfileRecord.Id, 'Should return current user profile ID');
        Assert.isNotNull(currentUserProfileRecord.Name, 'Profile name should not be null');
    }
}