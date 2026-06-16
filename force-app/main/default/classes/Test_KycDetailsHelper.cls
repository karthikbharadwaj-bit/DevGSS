@isTest
private class Test_KycDetailsHelper {
    @testSetup
    static void setup() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity',
                    Account.BillingPostalCode => 'testPC',
                    Account.BillingStreet => 'testStreet',
                    Account.BillingState => 'AP'
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 22072021',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_NAME_INR,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
                }
            )
            .create()
            .getRecord();
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    NGBS_Settings__c.Login__c => 'salesforce',
                    NGBS_Settings__c.Password__c => 'salesforce'
                }
            )
            .create();
    }

    @isTest
    static void testGetStates() {
        List<BillingWrappers.CountryStates> result;
        Test.setMock(HttpCalloutMock.class, new CountryStatesCalloutMock());
        Test.startTest();
        result = KycDetailsHelper.getStates('37');
        Test.stopTest();
        System.assertEquals('Andhra Pradesh', result[0].stateName, 'Country state should be Andhra Pradesh');
    }

    @isTest
    static void testIsValidAccountState() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CountryStatesCalloutMock());
            List<BillingWrappers.CountryStates> response = KycDetailsHelper.getStates('37');
            Boolean result = KycDetailsHelper.isValidBillingState('AP', response?.get(0));
        Test.stopTest();
        System.assertEquals(true, result, 'Account state should be valid');
    }

    @isTest
    static void testValidateAccountStatePositive() {
        Response resp;
        Test.setMock(HttpCalloutMock.class, new CountryStatesCalloutMock());
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'testAcc22072021'
            })
            .executeQuery()
            .get(0);
        String params = '{"accountId":"' + acc.Id + '","gstNo":"28", "billingState": "AP"}';
        Test.startTest();
            resp = KycDetailsHelper.validateBillingState(params);
        Test.stopTest();
        System.assert(!resp.data.values().isEmpty(), 'Response shouldn\'t be empty');
        System.assertEquals(true, resp.data.get('isValidState'), 'Response should be with isValidState=true');
        System.assertEquals(true, resp.data.get('isValidGstNoForState'), 'Response should be with isValidGstNoForState=true');
        System.assertEquals('AP', resp.data.get('alpha2Code'), 'Response should be with alpha2Code=AP');
    }

    @isTest
    static void testValidateAccountStateNegative() {
        Response resp;
        Test.setMock(HttpCalloutMock.class, new CountryStatesCalloutMock());
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'testAcc22072021'
            })
            .executeQuery()
            .get(0);
        String params = '{"accountId":"' + acc.Id + '","gstNo":"33", "billingState": "AP"}';
        Test.startTest();
            resp = KycDetailsHelper.validateBillingState(params);
        Test.stopTest();
        System.assert(!resp.data.values().isEmpty(), 'Response shouldn\'t be empty');
        System.assertEquals(true, resp.data.get('isValidState'), 'Response should be with isValidState=true');
        System.assertEquals(false, resp.data.get('isValidGstNoForState'), 'Response should be with isValidGstNoForState=false');
        System.assertEquals('TN', resp.data.get('alpha2Code'), 'Response should be with alpha2Code=TN');
    }

    @isTest
    static void testValidateAccountStateIncorrectGstNo() {
        Response resp;
        Test.setMock(HttpCalloutMock.class, new CountryStatesCalloutMock());
        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'testAcc22072021'
            })
            .executeQuery()
            .get(0);
        String params = '{"accountId":"' + acc.Id + '","gstNo":"t33", "billingState": "AP"}';
        Test.startTest();
            resp = KycDetailsHelper.validateBillingState(params);
        Test.stopTest();
        System.assert(!resp.data.values().isEmpty(), 'Response shouldn\'t be empty');
        System.assertEquals(false, resp.data.get('isValidGstNoForState'), 'Response should be with isValidGstNoForState=false');
    }

    @IsTest
    static void testGetData() {
        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);
        Test.startTest();
        Approval__c kycApproval = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
            .executeQuery()
            .get(0);

        Map<Id,Document__c> docMap = new Map<Id,Document__c>(
            (List<Document__c>) new DocumentKYCSelector()
                .selectDocumentsByApprovalId(new List<Set<Id>>{
                    new Set<Id>{kycApproval.Id}
                })
                .executeQuery()
        );
        /* Parent entities for files */
        List<Id> entityIds = new List<Id>{kycApproval.Id};
        entityIds.addAll(docMap.keySet());
        Map<Integer,Id> fileIdMap = createFiles(entityIds);
        /* File ids are stored on approval object */
        kycApproval.KycFiles__c = String.join((new String[]{
            fileIdMap.get(0) + ';',
            fileIdMap.get(1) + ';',
            fileIdMap.get(2) + ';',
            ';',
            ';',
            ';',
            ';',
            fileIdMap.get(3)}),''
        );
        update kycApproval;
        Response resp = KycDetailsHelper.getData(kycApproval.Id);
        Test.stopTest();
        Approval__c selectedApproval = (Approval__c) resp.data.get('approval');
        System.assertEquals(kycApproval.Id, selectedApproval.Id, 'KYC approval record should be selected');

        String filesSerialized = (String) resp.data.get('files');
        System.assertNotEquals('', filesSerialized, 'There should be files in the response');

        List<KycDetailsHelper.FileWrapper> files = (List<KycDetailsHelper.FileWrapper>) JSON.deserialize(filesSerialized, List<KycDetailsHelper.FileWrapper>.class);
        System.assertEquals(4, files.size(), 'Incorrect amount of files was returned');
    }

    @IsTest
    static void testGetParentIdSet() {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .executeQuery();
        Test.startTest();
            Set<Id> parentIdSet = KycDetailsHelper.getParentIdSet(kycApprovals[0]);
        Test.stopTest();
        System.assertEquals(4, parentIdSet.size(), 'Wrong amount of parents were collected');
        System.assert(parentIdSet.contains(kycApprovals[0].Id), 'Approval Id is expected to be in the list');
    }

    @IsTest
    static void testSaveDocuments() {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .executeQuery();

        List<KycDetailsHelper.DocumentsWrapper> docWrapperList = new List<KycDetailsHelper.DocumentsWrapper>();
        for (Document__c doc : kycApprovals[0].Documents__r) {
            KycDetailsHelper.DocumentsWrapper dw = new KycDetailsHelper.DocumentsWrapper(
                doc.Id,
                doc.Approval__c,
                system.today(),
                'testNo',
                'testIssuingAuthority',
                'testPlaceOfIssue',
                doc.Type__c
            );
            docWrapperList.add(dw);
        }

        Test.startTest();
            KycDetailsHelper.saveDocuments(JSON.serialize(docWrapperList));
        Test.stopTest();

        List<Document__c> documents = (List<Document__c>) new DocumentKYCSelector()
            .selectDocumentsByApprovalId(new List<Object>{new List<Id>{kycApprovals[0].Id}})
            .executeQuery();
        for (Document__c doc : documents) {
            System.assertEquals(system.today(), doc.DateOfIssue__c, 'Wrong date of issue is saved');
            System.assertEquals('testNo', doc.DocumentNo__c, 'Wrong document no is saved');
            System.assertEquals('testIssuingAuthority', doc.IssuingAuthority__c, 'Wrong issuing no is saved');
            System.assertEquals('testPlaceOfIssue', doc.PlaceOfIssue__c, 'Wrong place of issue is saved');
        }
    }

    @IsTest
    static void testDeleteFiles() {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .executeQuery();

        List<Id> entityIds = new List<Id>{kycApprovals[0].Id};
        Map<Id, Document__c> documentMap = new Map<Id, Document__c>(kycApprovals[0].Documents__r);
        entityIds.addAll(documentMap.keySet());
        
        Triggers.switchOff();
        Map<Integer,Id> contentDocumentMap = createFiles(entityIds);
        Triggers.switchOn();

        Test.startTest();
            KycDetailsHelper.FileToDeleteWrapper deleteWrapper = new KycDetailsHelper.FileToDeleteWrapper();
            deleteWrapper.approvalId = kycApprovals[0].Id;
            deleteWrapper.contentDocumentIdSet = new Set<Id>(contentDocumentMap.values());

            KycDetailsHelper.deleteFiles(JSON.serialize(deleteWrapper));
        Test.stopTest();
        List<ContentVersion> contentVersions = (List<ContentVersion>) new ContentVersionSelector()
            .selectContentVersions()
            .executeQuery();

        System.assert(contentVersions.isEmpty(),'Content Versions with related Content Documents should be removed');
    }

    @IsTest
    static void testCreateFiles() {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .executeQuery();

        Test.startTest();
            /* Uploading file content to SF through Salesforce Rest API
             * So in test ContentVersion is created manually
             */
            ContentVersion cvFile = new ContentVersion(
                PathOnClient = '/Test File',
                Title = 'Test File',
                VersionData = EncodingUtil.base64Decode('Test Content')
            );
            insert cvFile;

            Map<String, Object> file = new Map<String, Object>{
                'status' => 'success',
                'cvFileId' => cvFile.Id,
                'entityId' => kycApprovals[0].Id
            };

            Response resp = KycDetailsHelper.createContentDocumentLink(file);
        Test.stopTest();

        List<ContentVersion> contentVersions = (List<ContentVersion>) new ContentVersionSelector()
            .selectContentVersions()
            .selectFields(new List<String>{'Title', 'VersionData'})
            .executeQuery();

        System.assert(!contentVersions.isEmpty(), 'Content Version should be created');
        System.assertEquals('Test File', contentVersions[0].Title, 'Content Version name is incorrect');
    }

    @IsTest
    static void testUpdateApproval() {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .executeQuery();

        List<Id> entityIds = new List<Id>{kycApprovals[0].Id};
        Map<Id, Document__c> documentMap = new Map<Id, Document__c>(kycApprovals[0].Documents__r);
        entityIds.addAll(documentMap.keySet());
        
       
        Triggers.switchOff();
        Map<Integer,Id> contentDocumentMap = createFiles(entityIds);
        /* Case when Document files are uploaded */
        kycApprovals[0].KycFiles__c = String.join((new String[]{
            contentDocumentMap.get(0) + ';',
            contentDocumentMap.get(1) + ';',
            contentDocumentMap.get(2) + ';',
            ';',
            ';',
            ';',
            ';'}),''
        );
        update kycApprovals;
        Triggers.switchOn();

        Test.startTest();
            /* Case when Document files should be removed and a new file should be uploaded to the Approval */
            KycDetailsHelper.UpdateApprovalWrapper wrapper = new KycDetailsHelper.UpdateApprovalWrapper(
                new KycDetailsHelper.ApprovalWrapper(kycApprovals[0].Id),
                new List<String>{
                    contentDocumentMap.get(0), contentDocumentMap.get(1), contentDocumentMap.get(2)
                },
                new Map<String, List<String>>{
                    '7' => new List<String>{
                        contentDocumentMap.get(3)
                    }
                }
            );
            KycDetailsHelper.updateApproval(JSON.serialize(wrapper));
        Test.stopTest();
        List<Approval__c> approvalList = new ApprovalSelector()
            .selectKYCRequestApprovalForNotesAttachmentsById(new List<Object>{new Set<Id>{wrapper.approval.approvalId}})
            .executeQuery();

        List<String> sections = approvalList[0].KycFiles__c.split(';',-1);
        for (Integer i = 0; i < sections.size(); i++) {
            List<String> sectionFiles = sections[i].split(',');
            switch on i {
                /* Check if there are no Document file ids stored on KYC Approval */
                when 0,1,2 {
                    System.assert(sectionFiles.size() == 1, 'File reference should be deleted from this(documents) section');
                }
                /* Check if new file is stored on KYC Approval */
                when 7 {
                    System.assert(sectionFiles.size() == 2, 'New file reference should be added to the last(7) section');
                }
            }
        }
    }

    @IsTest
    private static void testCheckingPermissionsForEditingKycApprovalAfterApproved() {
        Profile crmProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{new Set<String>{ProfileHelper.CRM_PROFILES.iterator().next()}})
            .executeQuery()
            .get(0);
        User crmUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    User.ProfileId => crmProfile.Id,
                    User.LastName => 'TestUser'
                })
            .create()
            .getRecord();

        Test.startTest();
        Boolean result = false;
        System.runAs(crmUser) {
            result = KycDetailsHelper.isUserProfileHasPermissionToEditKYCRequestAfterFinalAction();
        }
        Test.stopTest();

        System.assertEquals(true, result, 'User with CRM profile can edit KYC Approval after final action');
    }

    private static Map<Integer,Id> createFiles(List<Id> entityIdList) {
        List<ContentVersion> cvList = (List<ContentVersion>) new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentVersion.Title => ValueProviderBuilder.provideList(new List<String> {'0','1','2','3'}),
                ContentVersion.VersionData => ValueProviderBuilder.provideList(new List<Blob> {
                    Blob.valueOf('Approval Content'),
                    Blob.valueOf('Document PhotoId Content'),
                    Blob.valueOf('Document Authorisation letter Content'),
                    Blob.valueOf('Document Identity Document Content')}),
                ContentVersion.PathOnClient => 'path'
            })
            .quantity(4)
            .create()
            .getRecords();
        Map<Id,Id> cvIdToEntityId = new Map<Id,Id>();
        for (Integer i = 0; i<4; i++) {
            cvIdToEntityId.put(cvList[i].Id, entityIdList[i]);
        }
        /* Need to reselect content versions to get ContentDocumentId*/
        Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>(cvList);
        List<ContentVersion> reselectedCvList = new ContentVersionSelector()
            .selectContentVersionById(new List<Object>{cvMap.keySet()})
            .executeQuery();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        Map<Integer,Id> cdMap = new Map<Integer,Id>();
        for (ContentVersion cv : reselectedCvList) {

            cdMap.put(Integer.valueOf(cv.Title), cv.ContentDocumentId);

            ContentDocumentLink cdl = (ContentDocumentLink) new SObjectBuilder(ContentDocumentLink.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    ContentDocumentLink.ContentDocumentId => cv.ContentDocumentId,
                    ContentDocumentLink.LinkedEntityId => cvIdToEntityId.get(cv.Id)
                })
                .build()
                .getRecord();
            cdlList.add(cdl);
        }
        insert cdlList;
        return cdMap;
    }

    @IsTest
    private static void testIsUserHasPermissionSetToReadKYCApprovalRequest() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestUser'
                })
            .create()
            .getRecord();

        PermissionSet kycApprovalReadPermissionSet = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetByLabel(new List<Object>{KycDetailsHelper.KYC_APPROVAL_READ_PERMISSION_SET_NAME})
            .executeQuery()
            .get(0);

        PermissionSetAssignment testPsa = (PermissionSetAssignment) new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => kycApprovalReadPermissionSet.Id
                })
            .create()
            .getRecord();

        Boolean result = false;
        Test.startTest();
            System.runAs(testUser) {
                result = KycDetailsHelper.isUserProfileHasPermissionToEditKYCRequestAfterFinalAction();
            }
        Test.stopTest();

        System.assertEquals(true, result, 'User with permission set KYC Approval read can only read KYC Approval');
    }

    @isTest
    static void testValidateGstNumber_ValidGst_ReturnsTrue() {
        String validGstNumber = '29ABCDE1234F2Z5';
        Test.setMock(HttpCalloutMock.class, new MockGstValidResponse());
        Test.startTest();
        Boolean result = KycDetailsHelper.validateGstNumber(validGstNumber);
        Test.stopTest();
        System.assertEquals(true, result, 'Should return true for valid GST number');
    }
    
    @isTest
    static void testValidateGstNumber_InvalidGst_ReturnsFalse() {
        String invalidGstNumber = 'INVALID123';
        Test.setMock(HttpCalloutMock.class, new MockGstInvalidResponse());
        Test.startTest();
        Boolean result = KycDetailsHelper.validateGstNumber(invalidGstNumber);
        Test.stopTest();
        System.assertEquals(false, result, 'Should return false for invalid GST number');
    }

    public class MockGstValidResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_cd":"1","GstnStatus":"Active"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockGstInvalidResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status_cd":"0","message":"Invalid GST Number"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class CountryStatesCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('[{"stateName":"Andhra Pradesh","alpha2Code":"AP","primaryTaxCode":"37","alternateTaxCode":"28"},{"stateName": "Tamil Nadu","alpha2Code": "TN","primaryTaxCode": "33"}]');
            response.setStatusCode(200);
            return response;
        }
    }
}