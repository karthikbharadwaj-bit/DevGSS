@isTest
private class Test_SupportCommunityViewCase {

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = '<script>window.alert("Huh?")</script>';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final String CASE_INFO_ALTERNATE_EMAIL = 'test@alternate.re';
    private static final String CASE_INFO_CALLBACK_PHONE = '9999999999 ext.999';
    private static final Datetime CASE_INFO_CREATED_DATE = Datetime.newInstanceGmt(2007, 1, 1);

    private static final String USER_USERNAME = 'RC_SupportCommunityNewCaseTestUser@nvx.zn';
    private static final String USER_EMAIL = 'testerino@rc.com';
    private static final String USER_FIRST_NAME = 'Toaster';
    private static final String USER_LAST_NAME = 'McToast';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAdmin@nvx.zn';
    private static final String ADMIN_USER_EMAIL = 'testerinoadmin@rc.com';
    private static final String ADMIN_USER_FIRST_NAME = 'Admeeeno';
    private static final String ADMIN_USER_LAST_NAME = 'McAdmin';
    private static final String ADMIN_USER_LANGUAGE = 'en_US';

    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String COMMENT_BODY = 'Commento testomento';

    private static final String ATTACHMENT_NAME = 'Attachmento testomento';

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';
    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';
    private static final String CUSTOM_PERMISSION_NAME = 'Can_see_community_billing_info';

    private static User guestTestUser {
        get {
            if (guestTestUser == null) {
                guestTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId'})
                    .executeQuery()
                    .get(0);
            }
            return guestTestUser;
        }
        private set;
    }

    private static User adminTestUser {
        get {
            if (adminTestUser == null) {
                adminTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId'})
                    .executeQuery()
                    .get(0);
            }
            return adminTestUser;
        }
        private set;
    }

    private static Id insertCaseAsUser(User user) {

        Case newCase;
        System.runAs(user) {
            newCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                        Case.Subject => ValueProviderBuilder.provideUniqueString(CASE_INFO_SUBJECT),
                        Case.Case_Severity__c => CASE_INFO_SEVERITY_LEVEL,
                        Case.Product_Assistance__c => CASE_INFO_SELECTED_PRODUCT,
                        Case.Product_Assistance_Lvl2__c => CASE_INFO_SELECTED_PRODUCT2,
                        Case.Product_Assistance_Lvl3__c => CASE_INFO_SELECTED_PRODUCT3,
                        Case.Description => CASE_INFO_DESCRIPTION
                    }
                )
                .create()
                .getRecord();

            Test.setCreatedDate(newCase.Id, CASE_INFO_CREATED_DATE);
        }
        return newCase.Id;
    }

    @testSetup
    static void setup() {

        Profile guestProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{GUEST_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Profile adminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Account portalAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        List<Contact> portalContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_FIRST_NAME, ADMIN_CONTACT_FIRST_NAME}),
                    Contact.LastName => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_LAST_NAME, ADMIN_CONTACT_LAST_NAME}),
                    Contact.Email => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_EMAIL, ADMIN_CONTACT_EMAIL}),
                    Contact.Phone => ValueProviderBuilder.provideList(
                        new List<String>{CONTACT_PHONE, ADMIN_CONTACT_PHONE}),
                    Contact.Phone_Ext__c => ValueProviderBuilder.provideList(
                        new List<Decimal>{CONTACT_PHONE_EXT, ADMIN_CONTACT_PHONE_EXT}),
                    Contact.AccountId => ValueProviderBuilder.provideList(
                        new List<String>{portalAccount.Id, portalAccount.Id})
                }
            )
            .create()
            .getRecords();

        List<User> users = new SObjectBuilder(User.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ContactId => ValueProviderBuilder.provideList(
                        new List<String>{portalContacts[0].Id, portalContacts[1].Id}),
                    User.LastName => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME}),
                    User.FirstName => ValueProviderBuilder.provideList(
                        new List<String>{USER_FIRST_NAME, ADMIN_USER_FIRST_NAME}),
                    User.CommunityNickname => ValueProviderBuilder.provideList(
                        new List<String>{USER_LAST_NAME, ADMIN_USER_LAST_NAME}),
                    User.Email => ValueProviderBuilder.provideList(
                        new List<String>{USER_EMAIL, ADMIN_USER_EMAIL}),
                    User.Username => ValueProviderBuilder.provideList(new List<String>{USER_USERNAME, ADMIN_USER_USERNAME}),
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => ValueProviderBuilder.provideList(
                        new List<String>{guestProfile.Id, adminProfile.Id})
                }
            )
            .create()
            .getRecords();

        List<SetupEntityAccess> seas = (List<SetupEntityAccess>) new SetupEntityAccessSelector()
            .selectSetupEntityAccessByCustomPermissionName(new List<Object>{SCUserService.CUSTOM_PERMISSION_NAME})
            .executeQuery();
        Id commAdminPermSetId = seas[0].ParentId;
        for(SetupEntityAccess sea : seas){
            if(sea.ParentId.getSObjectType() == PermissionSet.SObjectType){
                commAdminPermSetId = sea.ParentId;
                break;
            }
        }

        System.runAs((User) new UserSelector()
                .selectUsersByIdNoFields(new List<Object>{new List<Id>{UserInfo.getUserId()}})
                .executeQuery()[0]) {
            new SObjectBuilder(PermissionSetAssignment.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PermissionSetAssignment.AssigneeId => users[1].Id,
                        PermissionSetAssignment.PermissionSetId => commAdminPermSetId
                    }
                )
                .create();
        }
    }

    @isTest
    static void testGetCaseDetail() {

        SCWrappers.CaseDetail caseDetail;

        Id newCaseId = insertCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {

            Test.setCreatedDate(newCaseId, CASE_INFO_CREATED_DATE);
            Triggers.switchOff();
            List<CaseComment> comments = (List<CaseComment>) new SObjectBuilder(CaseComment.SObjectType)
                .quantity(2)
                .setField(CaseComment.ParentId, newCaseId)
                .setField(CaseComment.IsPublished, true)
                .setField(CaseComment.CommentBody, 'Bambaleilaaaaa---')
                .create()
                .getRecords();
            Triggers.switchOn();
            Test.startTest();
            caseDetail = 
                (SCWrappers.CaseDetail) SupportCommunityViewCase.getCaseDetail('{"caseId":"' + newCaseId + '"}')
                    .data.get(SupportCommunityViewCase.LABEL_CASE_DETAIL);
            Test.stopTest();

        }

        System.assert(caseDetail != null, 'Case detail not received');
        System.assert(caseDetail.subject.contains(CASE_INFO_SUBJECT), 'Incorrent case subject');
        System.assertEquals('New', caseDetail.status, 'Incorrent case status');
        System.assertEquals(CASE_INFO_DESCRIPTION.escapeHtml4(), caseDetail.description, 'Incorrent case description');
        System.assertEquals(CASE_INFO_SEVERITY_LEVEL, caseDetail.severityLevel, 'Incorrent case severityLevel');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT, caseDetail.selectedProduct, 'Incorrent case selectedProduct');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT2, caseDetail.selectedProduct2, 'Incorrent case selectedProduct2');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT3, caseDetail.selectedProduct3, 'Incorrent case selectedProduct3');
        System.assertEquals(false, caseDetail.isClosed, 'Incorrent case isClosed flag');
        System.assertEquals(5, caseDetail.fileSizeLimit, 'Incorrent case file size limit');
        System.assertEquals(USER_FIRST_NAME + ' ' + USER_LAST_NAME, caseDetail.creatorName, 'Incorrent case creator');
        System.assertEquals(
            CASE_INFO_CREATED_DATE.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles'),
            caseDetail.createdDate,
            'Incorrent case created date'
        );
    }

    @isTest
    static void testGetCaseDetail_invalidId_shouldReturnError() {

        Response response;

        Id newCaseId = insertCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {

            Test.startTest();
            response = SupportCommunityViewCase.getCaseDetail('{"caseId":"random_string"}');
            Test.stopTest();
        }

        SCWrappers.CaseDetail caseDetail = (SCWrappers.CaseDetail) response.data.get(SupportCommunityViewCase.LABEL_CASE_DETAIL);
        Response.ResponseMessage errorMessage = response.messages[0];
    
        System.assert(caseDetail == null, 'Successful retrieval of case after sending invalid id');
        System.assert(
            errorMessage != null,
            'No error message on attempt to view case with invalid id'
        );
        System.assert(
            errorMessage.message.contains('Invalid Case Id'),
            'Wrong error message on get case details fail');
    }

    @isTest
    static void testPostComment_asCaseCreator() {

        Id newCaseId = insertCaseAsUser(guestTestUser);

        System.runAs(guestTestUser) {

            Test.startTest();

            SCWrappers.CommentWrapper comment = 
                (SCWrappers.CommentWrapper) SupportCommunityViewCase.postComment(
                    '{"caseId":"' + newCaseId + '", "commentBody":"' + COMMENT_BODY + '"}'
                )
                .data.get(SupportCommunityViewCase.LABEL_COMMENT_DETAIL);

            Test.stopTest();

            System.assert(comment != null, 'Comment not received');
            System.assertEquals(true, comment.isCurrentUser, 'Incorrent isCurrentUser flag');
            System.assertEquals(true, comment.isCaseCreator, 'Incorrent isCaseCreator flag');
            System.assertEquals(COMMENT_BODY, comment.body, 'Incorrent comment body');
            System.assert(comment.avatarUrl.contains('005/F'), 'Incorrent avatar url');
            System.assertEquals(USER_FIRST_NAME + ' ' + USER_LAST_NAME, comment.authorName, 'Incorrent author name');
        }
    }

    @isTest
    static void testPostComment_asGuest_shouldFailHaveNoPermission() {

        Id newCaseId = insertCaseAsUser(adminTestUser);

        Response response;
        System.runAs(guestTestUser) {
            Test.startTest();
            response = SupportCommunityViewCase.postComment(
                    '{"caseId":"' + newCaseId + '", "commentBody":"' + COMMENT_BODY + '"}'
            );
            Test.stopTest();
        }

        SCWrappers.CommentWrapper newComment = (SCWrappers.CommentWrapper) response
            .data.get(SupportCommunityViewCase.LABEL_COMMENT_DETAIL);
        Response.ResponseMessage errorMessage = response.messages[0];
    
        System.assert(newComment == null, 'Successful comment on case outside of user\'s visibility');
        System.assert(
            errorMessage != null,
            'No error message on attempt to comment on case outside of user\'s visibility'
        );
        System.debug('errorMessage >>>>> ' + errorMessage);
        System.assert(
            errorMessage.message.contains('Case does not exist or you have no permission to view it'),
            'Wrong comment message on comment fail');
    }

    @isTest
    static void testPostComment_asRCAdminUser() {

        SCWrappers.CommentWrapper comment;
        Id newCaseId = insertCaseAsUser(guestTestUser);

        System.runAs(adminTestUser) {

            Test.startTest();

            comment = 
                (SCWrappers.CommentWrapper) SupportCommunityViewCase.postComment(
                    '{"caseId":"' + newCaseId + '", "commentBody":"' + COMMENT_BODY + '"}'
                )
                .data.get(SupportCommunityViewCase.LABEL_COMMENT_DETAIL);

            Test.stopTest();
        }

        System.assert(comment != null, 'Comment not received');
        System.assertEquals(true, comment.isCurrentUser, 'Incorrent isCurrentUser flag');
        System.assertEquals(false, comment.isCaseCreator, 'Incorrent isCaseCreator flag');
        System.assertEquals(COMMENT_BODY, comment.body, 'Incorrent comment body');
        System.assert(comment.avatarUrl.contains('005/F'), 'Incorrent avatar url');
        System.assertEquals(
            ADMIN_CONTACT_FIRST_NAME + ' ' + ADMIN_CONTACT_LAST_NAME,
            comment.authorName,
            'Incorrent author name'
        );
    }

    @isTest
    static void testGetAttachments() {

        Id newCaseId = insertCaseAsUser(guestTestUser);
        Triggers.switchOff();
        Map<Id, Attachment> atts = new Map<Id, Attachment>(
            (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
                .quantity(2)
                .setField(Attachment.ParentId, newCaseId)
                .setField(Attachment.Name, ValueProviderBuilder.provideUniqueString(ATTACHMENT_NAME))
                .setField(Attachment.Body, Blob.valueOf('Attachment body'))
                .create()
                .getRecords()
        );
        Triggers.switchOn();

        List<SCWrappers.AttachmentWrapper> attsResponse;

        System.runAs(guestTestUser) {

            Test.startTest();

            attsResponse = 
                (List<SCWrappers.AttachmentWrapper>) SupportCommunityViewCase.getAttachments(
                    '{"caseId":"' + newCaseId + '"}'
                )
                .data.get(SupportCommunityViewCase.LABEL_ATTACHMENTS);

            Test.stopTest();
        }

        System.assert(attsResponse != null, 'Attachments not received');
        System.assertEquals(2, attsResponse.size(), 'Incorrent size of attachments');
        for (SCWrappers.AttachmentWrapper att : attsResponse) {
            System.assert(att.name.contains(ATTACHMENT_NAME), 'Incorrent attachment name');
            System.assert(att.url.contains(att.id), 'Incorrent url for attachment');
            System.assert(atts.containsKey(att.id), 'Incorrent attachment Id');
        }
    }

    @isTest
    static void testDeleteAttachment() {

        Id newCaseId = insertCaseAsUser(guestTestUser);
        Triggers.switchOff();
        List<Attachment> atts = 
            (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
                .quantity(2)
                .setField(Attachment.ParentId, newCaseId)
                .setField(Attachment.Name, ValueProviderBuilder.provideUniqueString(ATTACHMENT_NAME))
                .setField(Attachment.Body, Blob.valueOf('Attachment body'))
                .create()
                .getRecords();
        Triggers.switchOn();
        System.runAs(guestTestUser) {

            Test.startTest();
            SupportCommunityViewCase.deleteAttachment(
                '{"attachmentId":"' + atts[0].Id + '"}'
            );
            Test.stopTest();
        }

        List<Attachment> attsAfterDelete = new AttachmentSelector()
            .selectAttachmentsByParentId(new List<String>{newCaseId})
            .executeQuery();

        System.assertEquals(1, attsAfterDelete.size(), 'Attachment not deleted');
    }
}