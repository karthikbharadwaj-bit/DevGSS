public with sharing class SCCaseService {

    public static final Integer STORAGE_LIMIT = 26214400;
    public static final Integer FILE_SIZE_LIMIT = 10485760;

    public static final Integer MAXIMUM_COMMENT_SIZE = 4000;
    public static final Integer MAXIMUM_SUBJECT_SIZE = 255;
    public static final Integer MAXIMUM_DESCRIPTION_SIZE = 32000;
    public static final String DATE_FORMAT = 'h:mm a z, MM/dd/yyyy';
    public static final String TIMEZONE = 'America/Los_Angeles';

    public static final Integer MIN_SEARCH_LENGTH = 3;
    public static final Integer MAX_SEARCH_LENGTH = 255;
    public static final Set<String> FIELD_TO_RETRIEVE = new Set<String>{'Contact.Name'};
    public static final Integer MAX_OFFSET = 2000;
    public static final Integer DEFAULT_LIMIT = 50;
    public static final Integer DEFAULT_OFFSET = 0;
    public static final String DEFAULT_ORDER_BY_FIELD = 'CreatedDate';
    public static final String SEARCH_CONDITION = ' LIKE {0}';
    public static final String ADMIN_CONDITION = 'AccountId = :bind0';
    public static final String GUEST_CONDITION = 'ContactId = :bind0';

    public static final String IGNORE_RT_CONDITION = 'RecordType.Name != \'Maintenance\'';
    public static final String ACCOUNT_CASES = 'accountCases';
    public static final Set<Integer> LIMIT_VALUES = new Set<Integer>{-1,25,50,100,200};
    public static final Map<String, String> ORDER_BY_FIELDS = new Map<String, String>{
        CaseHelper.CASE_NUMBER => 'CaseNumber',
        'subject' => 'Subject',
        'dateCreated' => 'CreatedDate',
        'mainContact' => 'Contact.Name',
        'caseStatus' => 'Status'
    };
    public static final Map<String, String> SEARCH_BY_FIELDS = new Map<String, String>{
        'subject' => 'Subject',
        CaseHelper.CASE_NUMBER => 'CaseNumber',
        'contact' => 'Contact.Name'
    };

    private static final List<String> CASE_STATUSES = new List<String> {
        'Duplicate', 'Invalid', 'Cancelled', 'Closed - Endorsed', 'Closed', 'Closed - No Response',
        'Closed - No Contact', 'Closed - No Issue', 'Requirement Not Met', 'Unsupported'};

    public static List<Case> getUserAccountCases(User currentUser) {

        if (currentUser == null || currentUser.Contact == null || String.isBlank(currentUser.Contact.AccountId)) {
            AquivaHelper.throwAquivaException(SCUserService.ERROR_NO_USER_WAS_FOUND);
        }

        List<String> CASE_FIELDS = new List<String> {
            'Id', 'CaseNumber', 'Contact.Name', 'Contact.Email', 'Subject', 'Case_Severity__c',
            'CreatedDate', 'Status', 'Contact.AccountId'};

        return (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(CASE_FIELDS)
            .setCondition('AccountId = :bind0 AND RecordType.Name != \'Maintenance\' AND Status NOT IN :bind1')
            .setQueryBindings(new List<Object>{currentUser.Contact.AccountId, CASE_STATUSES})
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery();
    }

    public static SCWrappers.CaseDetail retrieveCaseDetail(String caseId) {

        Id cId = convertToId(caseId);
        Case caseObj = new NoSharing().retrieveCaseWithCommentsAttachmentsAndContactData(cId);

        Map<Id, User> commentators = buildCommentatorsMap(caseObj);

        return new SCWrappers.CaseDetail(caseObj, commentators);
    }

    public static SCWrappers.CaseListView getCasesForCaseListView(SCWrappers.CaseSearchRequest request) {
        return request.offset <= MAX_OFFSET ? getCases(request) : getCasesWithHugeOffset(request);
    }

    public static List<Case> getCasesForCSV(SCWrappers.CaseSearchRequest request) {
        List<Case> cases = (List<Case>) new NoSharing().getCases(request.searchPart, request.orderByField,
            request.listView, request.searchByField, request.descending, -1, -1
        );

        return !cases.isEmpty() ? cases : new List<Case>();
    }

    public static List<SCWrappers.AttachmentWrapper> getAttachments(String caseId) {

        Id cId = convertToId(caseId);
        return new NoSharing().getAttachments(cId);
    }

    public static Integer getAttachmentStorageSpaceLeft(String caseId) {

        Id cId = convertToId(caseId);
        return new NoSharing().getAttachmentStorageSpaceLeft(cId);
    }

    public static SCWrappers.CommentWrapper addComment(String caseId, String commentBody) {

        Id cId = convertToId(caseId);
        if (String.isBlank(commentBody)) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Detail_empty_comment_body);
        }
        if (commentBody.length() > MAXIMUM_COMMENT_SIZE) {
            AquivaHelper.throwAquivaException(String.format(
                Label.SC_Case_Detail_too_large_comment,
                new List<String>{String.valueOf(MAXIMUM_COMMENT_SIZE)}));
        }

        Case caseObj = new NoSharing().retrieveCaseWithCommentsAttachmentsAndContactData(cId);

        CaseComment newCaseComment = new NoSharing().insertComment(cId, commentBody);

        SCWrappers.CommentWrapper newComment = new SCWrappers.CommentWrapper();
        newComment.id = newCaseComment.Id;
        newComment.body = commentBody;
        if (SCUserService.currentUser.Contact == null) {
            newComment.authorName = SCUserService.currentUser.Name;
            newComment.avatarUrl = SCUserService.currentUser.FullPhotoUrl;
        } else {
            newComment.authorName = SCUserService.currentUser.Contact.Name;
            newComment.avatarUrl = SCUserService.currentUser.Contact.Account.CSM__r.FullPhotoUrl == null
                ? SCUserService.currentUser.FullPhotoUrl
                : SCUserService.currentUser.Contact.Account.CSM__r.FullPhotoUrl;
        }
        newComment.dateTimeStamp = System.now().format(DATE_FORMAT, TIMEZONE);
        newComment.isCaseCreator = caseObj.CreatedById == SCUserService.currentUser.Id;
        newComment.isCurrentUser = true;

        return newComment;
    }

    public static void addAttachment(String caseId, Attachment att) {

        Id cId = convertToId(caseId);
        new NoSharing().insertAttachment(cId, att);
    }

    public static void deleteAttachment(Id attId) {

        if (attId == null) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Detail_invalid_attachment_id);
        }
        new NoSharing().deleteAttachment(attId);
    }

    private static Map<Id, User> buildCommentatorsMap(Case caseObj) {

        if (caseObj == null || caseObj.CaseComments == null) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Detail_invalid_case_for_comment);
        }

        Set<String> commentatorIds = new Set<String>();
        for (CaseComment comment : caseObj.CaseComments) {
            commentatorIds.add(comment.CreatedById);
        }

        return new NoSharing().retrieveUsersByIdWithContactInfo(commentatorIds);
    }

    private static SCWrappers.CaseListView getCases(SCWrappers.CaseSearchRequest request) {
        validateRequest(request);
        List<SCWrappers.CaseDetail> caseDetails = new List<SCWrappers.CaseDetail>();
        List<Case> casesToReturn = new List<Case>();
        Integer totalCases = 0;

        casesToReturn = (List<Case>) new NoSharing().getCases(
            request.searchPart, request.orderByField, request.listView, request.searchByField,
            request.descending, request.searchLimit, request.offset
        );

        for (Case foundCase : casesToReturn) {
            caseDetails.add(new SCWrappers.CaseDetail(foundCase));
        }

        if (request.count) {
            totalCases = new NoSharing().getCases(request.searchPart, request.orderByField, request.listView,
                request.searchByField, request.descending, -1, -1).size();
        } else {
            totalCases = -1;
        }

        return new SCWrappers.CaseListView(caseDetails, totalCases);
    }

    private static SCWrappers.CaseListView getCasesWithHugeOffset(SCWrappers.CaseSearchRequest request) {
        List<Case> casesToReturn = new List<Case>();
        List<SCWrappers.CaseDetail> caseDetails = new List<SCWrappers.CaseDetail>();
        List<Case> cases = (List<Case>) new NoSharing().getCases(request.searchPart, request.orderByField,
            request.listView, request.searchByField, request.descending, -1, -1
        );

        Integer currentLimit = request.offset + request.searchLimit;
        if (currentLimit > cases.size()) {
            currentLimit = cases.size();
        }

        for (Integer i = request.offset; i < currentLimit; i++) {
            casesToReturn.add(cases.get(i));
        }

        for (Case foundCase : casesToReturn) {
            caseDetails.add(new SCWrappers.CaseDetail(foundCase));
        }

        return new SCWrappers.CaseListView(caseDetails, cases.size());
    }

    private static void validateRequest(SCWrappers.CaseSearchRequest request) {

        if (request.searchPart == null) {
            return;
        }

        if (String.isBlank(request.searchPart) || request.searchPart.length() < MIN_SEARCH_LENGTH) {
            AquivaHelper.throwAquivaException(String.format(
                Label.SC_Case_Management_search_too_short,
                new List<String>{String.valueOf(MIN_SEARCH_LENGTH)})
            );
        }

        if (request.searchPart.length() > MAX_SEARCH_LENGTH) {
            AquivaHelper.throwAquivaException(String.format(
                Label.SC_Case_Management_search_too_long,
                new List<String>{String.valueOf(MAX_SEARCH_LENGTH)})
            );
        }

        if (String.isBlank(request.searchByField)) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Management_wrong_search_by_value);
        }
    }

    private static Id convertToId(String caseId) {

        if (String.isBlank(caseId)) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Detail_invalid_case_id);
        }
        try {
            return (Id) caseId;
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException(Label.SC_Case_Detail_invalid_case_id);
        }
        return null;
    }

    private without sharing class NoSharing {

        public Map<Id, User> retrieveUsersByIdWithContactInfo(Set<String> userIds) {
            return new Map<Id, User>(
                (List<User>) new UserSelector()
                    .selectUsersByIdWithContactInfo(new List<Object>{userIds})
                    .executeQuery()
            );
        }

        public Map<Id, User> retrieveUsersByIdWithContactInfoForAPI(Set<String> userIds) {
            return new Map<Id, User>(
                (List<User>) new UserSelector()
                    .selectUsersByIdWithContactInfoForAPI(new List<Object>{userIds})
                    .executeQuery()
            );
        }

        public Case retrieveCaseWithCommentsAttachmentsAndContactData(Id caseId) {

            List<Case> cases = (List<Case>) new CaseSelector()
                .selectCaseByIdWithCommentsAttachmentsAndContactData(new List<String>{String.valueOf(caseId)})
                .executeQuery();
            if (cases.isEmpty() || !isAllowedToViewCase(cases[0])) {
                AquivaHelper.throwAquivaException(Label.SC_Case_Detail_no_case_or_no_permission);
            }
            return cases[0];
        }

        public Case retrieveCaseWithCommentsAttachmentsAndContactDataByUser(Id caseId, User user) {

            List<Case> cases = (List<Case>) new CaseSelector()
                .selectCaseByIdWithCommentsAttachmentsAndContactData(new List<String>{String.valueOf(caseId)})
                .executeQuery();
            if (cases.isEmpty() || !isUserAllowedToViewCase(cases[0], user)) {
                AquivaHelper.throwAquivaException(Label.SC_Case_Detail_no_case_or_no_permission);
            }
            return cases[0];
        }

        public List<Case> getCases(String searchPart, String orderByField, String listView, String searchByField,
            Boolean descending, Integer searchLimit, Integer offset) {

            User currentUser = SCUserService.currentUser;
            String contactId = currentUser.ContactId;
            String accId = currentUser.Contact.AccountId;

            if (String.isBlank(listView)) {
                AquivaHelper.throwAquivaException(Label.SC_Case_Management_no_listview);
            }

            Boolean isAccountCases = SCUserService.isCurrentUserSCAdmin && listView.equalsIgnoreCase(ACCOUNT_CASES);
            checkUserPermissionsToAccessListView(listView);
            List<String> bindings = isAccountCases ? new List<String>{accId} : new List<String>{contactId};

            searchLimit = searchLimit == null ? DEFAULT_LIMIT : searchLimit;
            offset = offset == null ? DEFAULT_OFFSET : offset;
            QueryFactory.SortOrder sortOrder = descending == true
                ? QueryFactory.SortOrder.DESCENDING
                : QueryFactory.SortOrder.ASCENDING;

            if (!LIMIT_VALUES.contains(searchLimit)) {
                AquivaHelper.throwAquivaException(String.format(
                    Label.SC_Case_Management_wrong_limit_value,
                    new List<String>{String.valueOf(searchLimit)})
                );
            }

            if (String.isEmpty(orderByField)) {
                orderByField = DEFAULT_ORDER_BY_FIELD;
            } else if (ORDER_BY_FIELDS.containsKey(orderByField)) {
                orderByField = ORDER_BY_FIELDS.get(orderByField);
            } else {
                AquivaHelper.throwAquivaException(Label.SC_Case_Management_wrong_order_by_value);
            }

            QueryFactory qf = new CaseSelector()
                .selectCasesDefaultDetailed(new List<Object>{bindings})
                .selectFields(FIELD_TO_RETRIEVE)
                .withoutSelectorOrderByIncluded()
                .addOrdering(orderByField, sortOrder, descending);

            if (offset != -1) {
                qf.setOffset(offset);
            }

            if (searchLimit != -1) {
                qf.setLimit(searchLimit);
            }

            String caseVisibilityCondition = IGNORE_RT_CONDITION + ' AND '
                + (isAccountCases ? ADMIN_CONDITION : GUEST_CONDITION);
            if (String.isNotBlank(searchPart)) {
                String searchExpression = '\'%' + String.escapeSingleQuotes(searchPart) + '%\'';
                String condition =
                    String.format(getSearchCondition(searchByField), new List<String>{searchExpression}) +
                    ' AND ' + caseVisibilityCondition;
                qf.setCondition(condition);
            } else {
                qf.setCondition(caseVisibilityCondition);
            }
            List<Case> caseToReturn = qf.executeQuery();
            return caseToReturn.isEmpty() ? new List<Case>() : caseToReturn;
        }

        public CaseComment insertComment(Id caseId, String commentBody) {

            CaseComment newCaseComment = new CaseComment();
            newCaseComment.ParentId = caseId;
            newCaseComment.CommentBody = commentBody;
            newCaseComment.IsPublished = true;

            insert newCaseComment;
            return newCaseComment;
        }

        public List<SCWrappers.AttachmentWrapper> getAttachments(Id caseId) {

            List<SCWrappers.AttachmentWrapper> result = new List<SCWrappers.AttachmentWrapper>();
            for (Attachment att : (List<Attachment>) new AttachmentSelector()
                    .selectAttachmentsByParentId(new List<String>{caseId})
                    .executeQuery()) {

                result.add(new SCWrappers.AttachmentWrapper(att));
            }
            return result;
        }

        public Integer getAttachmentStorageSpaceLeft(Id caseId) {

            Integer result = STORAGE_LIMIT;
            for (Attachment att : (List<Attachment>) new AttachmentSelector()
                    .selectAttachmentsByParentId(new List<String>{caseId})
                    .executeQuery()) {

                result -= att.BodyLength;
            }
            return result;
        }

        public void insertAttachment(Id caseId, Attachment att) {

            Attachment attachObj = att;
            att.ParentId = caseId;
            insert attachObj;
        }

        public void deleteAttachment(Id attId) {

            List<Attachment> attachments = (List<Attachment>) new AttachmentSelector()
                .selectAttachmentsById(new List<Object>{new List<String>{attId}})
                .executeQuery();

            if (attachments.isEmpty()) {
                AquivaHelper.throwAquivaException(Label.SC_Case_Detail_no_attachment_to_delete);
            }

            delete attachments[0];
        }

        private Boolean isAllowedToViewCase(Case caseObj) {

            return SCUserService.currentUser.Id == caseObj.CreatedById
                || (caseObj.ContactId != null && caseObj.ContactId == SCUserService.currentUser.ContactId)
                || (SCUserService.isCurrentUserSCAdmin
                && (caseObj.AccountId != null && caseObj.AccountId == SCUserService.currentUser.Contact.AccountId));
        }

        private Boolean isUserAllowedToViewCase(Case caseObj, User user) {

            return user.Id == caseObj.CreatedById
                || (caseObj.ContactId != null && caseObj.ContactId == user.ContactId)
                || (SCUserService.isUserSCAdmin(user.Id)
                && (caseObj.AccountId != null && caseObj.AccountId == user.Contact.AccountId));
        }

        private String getSearchCondition(String searchByField) {
            String searchCondition;
            if (String.isNotBlank(searchByField) && SEARCH_BY_FIELDS.containsKey(searchByField)) {
                return SEARCH_BY_FIELDS.get(searchByField) + SEARCH_CONDITION;
            } else {
                AquivaHelper.throwAquivaException(Label.SC_Case_Management_wrong_search_by_value);
            }
            return searchCondition;
        }

        private void checkUserPermissionsToAccessListView(String listViewName) {
            if (listViewName.equalsIgnoreCase(ACCOUNT_CASES) && !SCUserService.isCurrentUserSCAdmin) {
                AquivaHelper.throwAquivaException(Label.SC_Case_Management_no_permissions_to_access_list_view);
            }
        }
    }
}