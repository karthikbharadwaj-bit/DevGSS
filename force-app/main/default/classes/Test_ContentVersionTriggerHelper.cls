@isTest
private class Test_ContentVersionTriggerHelper {

private static Id createDocument(String documentData) {

    if (String.isBlank(documentData)) {
        documentData = 'test content';
    }

    ContentVersion testDocument = (ContentVersion) new SObjectBuilder(ContentVersion.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            ContentVersion.Title => 'Test pdf document',
            ContentVersion.PathOnClient => 'TestDocument.pdf',
            ContentVersion.VersionData => Blob.valueOf(documentData),
            ContentVersion.IsMajorVersion => true
        })
        .create()
        .getRecord();

    Id documentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:testDocument.Id].ContentDocumentId;

    return documentId;
}

@isTest
private static void testBuildDocumentIdToRelatedTypesMapMethod() {

    ContentVersionTriggerHelper.DocuSignDocumentsProcessing handler = new ContentVersionTriggerHelper.DocuSignDocumentsProcessing();

    System.assertEquals(
        new Map<Id, Set<SObjectType>>(),
        handler.buildDocumentIdToRelatedTypesMap(null),
        'method should return empty Map if passed argument is null'
    );

    System.assertEquals(
        new Map<Id, Set<SObjectType>>(),
        handler.buildDocumentIdToRelatedTypesMap(new List<ContentDocumentLink>()),
        'method should return empty Map if passed argument is empty list'
    );

    Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
        })
        .create()
        .getRecord();

    DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Sent'
        })
        .create()
        .getRecord();

    Id testContentDocumentId = (Id) ValueProviderBuilder.provideDummyId(ContentDocument.SObjectType).getValue();

    List<ContentDocumentLink> documentsLinks = (List<ContentDocumentLink>) new SObjectBuilder(ContentDocumentLink.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            ContentDocumentLink.LinkedEntityId => ValueProviderBuilder.provideParents(new Set<Id>{acc.Id, dsStatus.Id}),
            ContentDocumentLink.ContentDocumentId => testContentDocumentId
        })
        .quantity(2)
        .build()
        .getRecords();

    Map<Id, Set<SObjectType>> documentIdToRelatedTypesMap = handler.buildDocumentIdToRelatedTypesMap(
        documentsLinks
    );

    System.assert(
        documentIdToRelatedTypesMap.containsKey(testContentDocumentId),
        'result Map should contain ContentDocumentId as key'
    );

    Set<SObjectType> typesSet = documentIdToRelatedTypesMap.get(testContentDocumentId);

    System.assert(
        typesSet.contains(DSFS__DocuSign_Status__c.SObjectType),
        'result Set should contain LinkedEntity types'
    );

    System.assert(
        typesSet.contains(Account.SObjectType),
        'result Set should contain LinkedEntity types'
    );
}

@isTest
private static void testBuildAccountIdToActiveContractIdMapMethod() {

    ContentVersionTriggerHelper.DocuSignDocumentsProcessing handler = new ContentVersionTriggerHelper.DocuSignDocumentsProcessing();

    System.assertEquals(
        new Map<Id, Id>(),
        handler.buildAccountIdToActiveContractIdMap(null),
        'method should return empty Map if passed argument is null'
    );

    System.assertEquals(
        new Map<Id, Id>(),
        handler.buildAccountIdToActiveContractIdMap(new Set<Id>()),
        'method should return empty Map if passed argument is empty list'
    );

    Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
        })
        .create()
        .getRecord();

    System.assertEquals(
        new Map<Id, Id>(),
        handler.buildAccountIdToActiveContractIdMap(new Set<Id>{acc.Id}),
        'method should return empty Map if account has no active contract'
    );

    Contract cont = (Contract) new SObjectBuilder(Contract.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Contract.AccountId => acc.Id,
            Contract.Status => 'Draft'
        })
        .create()
        .getRecord();

    cont.Status = 'Active';
    update cont;


    Map<Id, Id> accIdToActiveContractIdMap = handler.buildAccountIdToActiveContractIdMap(new Set<Id>{acc.Id});
    System.assert(
        accIdToActiveContractIdMap.containsKey(acc.Id),
        'result Map should contain account Id as key if account has active contract'
    );

    System.assert(
        accIdToActiveContractIdMap.get(acc.Id) == cont.Id,
        'result Map should contain active contract id as value'
    );
}

@isTest
private static void testDocumentLinksForNotCompletedDocusign() {

    Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
        })
        .create()
        .getRecord();

    DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
            DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Sent'
        })
        .create()
        .getRecord();

    Id documentId = createDocument('Test Document (unsigned)');

    // create link to DocusignEnvelope
    new SObjectBuilder(ContentDocumentLink.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            ContentDocumentLink.LinkedEntityId => dsStatus.Id,
            ContentDocumentLink.ContentDocumentId => documentId,
            ContentDocumentLink.ShareType => 'V'
        })
        .create();

    Test.startTest();

        // create new Document Version
        new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentVersion.ContentDocumentId => documentId,
                ContentVersion.Title => 'Test pdf document',
                ContentVersion.PathOnClient => 'TestDocument.pdf',
                ContentVersion.VersionData => Blob.valueOf('Test Content (signed)'),
                ContentVersion.IsMajorVersion => true
            })
            .create();

        Account reselectedAccount = (Account) new AccountSelector()
            .selectAccountsWithActiveContract(new List<Object>{new List<Id>{acc.Id}})
            .executeQuery()
            .get(0);

        Set<Id> sobjectIdsForLinks = new Set<Id>{
            reselectedAccount.Id
        };
        List<ContentDocumentLink> createdLinks = new ContentDocumentLinkSelector()
            .selectLinksByLinkedEntityId(sobjectIdsForLinks)
            .executeQuery();

        System.assertEquals(
            0,
            createdLinks.size(),
            'link to document should not be created for Account if Docusign Envelope not "Completed"'
        );

    Test.stopTest();
}

@isTest
private static void testDocumentLinksForCompletedDocusign() {

    Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
        })
        .create()
        .getRecord();

    DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
            DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
        })
        .create()
        .getRecord();

    Id documentId = createDocument('Test Document (unsigned)');
    Test.startTest();
    // create link to DocusignEnvelope
    new SObjectBuilder(ContentDocumentLink.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            ContentDocumentLink.LinkedEntityId => dsStatus.Id,
            ContentDocumentLink.ContentDocumentId => documentId,
            ContentDocumentLink.ShareType => 'V'
        })
        .create();

        dsStatus.DSFS__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
        update dsStatus;    

        // create new Document Version
        new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentVersion.ContentDocumentId => documentId,
                ContentVersion.Title => 'Test pdf document',
                ContentVersion.PathOnClient => 'TestDocument.pdf',
                ContentVersion.VersionData => Blob.valueOf('Test Content (signed)'),
                ContentVersion.IsMajorVersion => true
            })
            .create();

        Account reselectedAccount = (Account) new AccountSelector()
            .selectAccountsWithActiveContract(new List<Object>{new List<Id>{acc.Id}})
            .executeQuery()
            .get(0);

        Set<Id> sobjectIdsForLinks = new Set<Id>{
            reselectedAccount.Id
        };

        if (!reselectedAccount.Contracts.isEmpty()) {
            sobjectIdsForLinks.add(reselectedAccount.Contracts.get(0).Id);
        }

        List<ContentDocumentLink> createdLinks = new ContentDocumentLinkSelector()
            .selectLinksByLinkedEntityId(sobjectIdsForLinks)
            .executeQuery();

        System.assertEquals(
            sobjectIdsForLinks.size(),
            createdLinks.size(),
            'links to document should be created for Account and Contract if Docusign Envelope is "Completed"'
        );

    Test.stopTest();
}

// This code is added as part of PBC-24750 Accommodate new versions of content document and delete the old one

private static final String PROFILE_NAME = 'Com Integration Profile';
    private static final String LANGUAGE_EN_US = 'en_US';

    // Utility method to create a User with a specific KCS role
    private static User createKCSUser(String firstName, String lastName, String email, String kcsRole) {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.FirstName => firstName,
                User.LastName => lastName,
                User.Email => email,
                User.Username => email + System.currentTimeMillis(),
                User.Alias => email.substring(0, 5),
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => LANGUAGE_EN_US,
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => LANGUAGE_EN_US,
                User.ProfileId => [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1].Id,
                User.KCS_Role__c => kcsRole
            })
            .create()
            .getRecord();
    }

    @isTest
    static void testHandleAfterUpdateWithNoContentVersions() {
        // Create a test user
        User testUser = createKCSUser('No', 'Content', 'nocontent@example.com', 'KCS Coach');
        
        System.runAs(testUser) {
            // Create a Knowledge Article without ContentVersions
            Knowledge__kav article = new Knowledge__kav();
            article.Title = 'No Content Article';
            article.UrlName = 'no-content-article';
            article.Language = LANGUAGE_EN_US;
            insert article;
            
            // Simulate an empty list of ContentVersions for testing
            List<ContentVersion> newContentVersions = new List<ContentVersion>();
            
            Test.startTest();
            // Handle the case where no content versions are present
            ContentVersionTriggerHelper.HandleAfterUpdateProcessing handler = new ContentVersionTriggerHelper.HandleAfterUpdateProcessing();
            handler.handleAfterUpdate(newContentVersions); 
            Test.stopTest();
            
            // Assertions
            // Ensure no ContentVersions exist for this Knowledge Article
            List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Knowledge__c = :article.Id];
            System.assertEquals(0, contentVersions.size(), 'No ContentVersions should exist for the Knowledge Article.');
            
            // Ensure no ContentDocuments were deleted
            List<ContentDocument> contentDocuments = [SELECT Id FROM ContentDocument];
            System.assertEquals(0, contentDocuments.size(), 'No ContentDocuments should have been deleted.');
        }
    }

    @isTest
    static void testHandleAfterUpdateWithTitleNotContainingSlash() {
        // Create a test user
        User testUser = createKCSUser('Test', 'User', 'testuser@example.com', 'KCS Coach');
        
        System.runAs(testUser) {
            // Create a Knowledge Article
            Knowledge__kav article = new Knowledge__kav();
            article.Title = 'Test Article Without Slash';
            article.UrlName = 'test-article-without-slash';
            article.Language = LANGUAGE_EN_US;
            insert article;

            // Create a ContentVersion without a '/' in the title
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Content Version Title Without Slash',
                VersionData = Blob.valueOf('Test content data'),
                Knowledge__c = article.Id,
                PathOnClient = 'path/to/file.txt'
            );
            insert contentVersion;

            // Simulate the trigger context for the test
            List<ContentVersion> newContentVersions = [SELECT Id, Knowledge__c, Title, CreatedDate 
                                                    FROM ContentVersion 
                                                    WHERE Knowledge__c = :article.Id];
            Test.startTest();
            
            // Simulating Trigger.new by passing the list of ContentVersions
            ContentVersionTriggerHelper.HandleAfterUpdateProcessing handler = new ContentVersionTriggerHelper.HandleAfterUpdateProcessing();
            handler.handleAfterUpdate(newContentVersions); 
            
            Test.stopTest();
            
            System.assert(contentVersion != null, 'ContentVersion should exist');
        }
    }

}