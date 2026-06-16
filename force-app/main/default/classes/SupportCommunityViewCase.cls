public with sharing class SupportCommunityViewCase {

    public static final String LABEL_CASE_DETAIL = 'caseDetail';
    public static final String LABEL_COMMENT_DETAIL = 'commentDetail';
    public static final String LABEL_ATTACHMENTS = 'attachments';
    public static final String LABEL_ATTACHMENT_DETAIL = 'attachmentDetail';
    public static final String LABEL_CURRENT_USER_ID = 'currentUserId';

    @AuraEnabled(cacheable=true)
    public static Response getCaseDetail(String request) {

        Response res = new Response();
        try {
            String caseId = ((Map<String, String>) JSON.deserialize(request, Map<String, String>.class)).get('caseId');
            SCWrappers.CaseDetail caseDetail = SCCaseService.retrieveCaseDetail(caseId);
            res.setData(LABEL_CASE_DETAIL, caseDetail);
            res.setData(LABEL_CURRENT_USER_ID, SCUserService.currentUser.Id);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response postComment(String request) {

        Response res = new Response();
        try {
            Map<String, String> requestData = (Map<String, String>) JSON.deserialize(request, Map<String, String>.class);
            String caseId = requestData.get('caseId');
            String commentBody = requestData.get('commentBody');
            SCWrappers.CommentWrapper newComment = SCCaseService.addComment(caseId, commentBody);
            res.setData(LABEL_COMMENT_DETAIL, newComment);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response getAttachments(String request) {

        Response res = new Response();
        try {
            Map<String, String> requestData = (Map<String, String>) JSON.deserialize(request, Map<String, String>.class);
            String caseId = requestData.get('caseId');
            List<SCWrappers.AttachmentWrapper> atts = SCCaseService.getAttachments(caseId);
            res.setData(LABEL_ATTACHMENTS, atts);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Response deleteAttachment(String request) {

        Response res = new Response();
        try {
            Map<String, String> requestData = (Map<String, String>) JSON.deserialize(request, Map<String, String>.class);
            String attachmentId = requestData.get('attachmentId');
            SCCaseService.deleteAttachment(attachmentId);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }
}