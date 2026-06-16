public without sharing class CaseDetailAPIController {

    public static final String LABEL_CASE_DETAIL = 'caseDetail';
    public static final String LABEL_COMMENT_DETAIL = 'commentDetail';

    public static final String SUCCESS_MESSAGE = 'Case detail provided';
    public static final String SUCCESS_MESSAGE_POST = 'Comment published.';

    public static Map<String, Object> getCaseDetail(String request) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);
            String caseId = (String) req.get('caseId');
            String uid = (String) req.get('uid');
            String email = (String) req.get('email');
            String lang = (String) req.get('lang');

            Contact contact = CaseAPIUtil.getContact(uid, email, new String[]{
                'Name','Id','AccountId','User_Id__c','Email'
            });

            SCWrappers.CaseDetail caseDetail = SCAPICaseService.retrieveCaseDetailFromAPIWithContact(caseId, contact);

            if(CaseDetailRestService.DEFAULT_LANG != lang) {
                caseDetail.translateValues(lang);
            }

            caseDetail.formatDescriptionGDPR();
            //When a Case es GDPR - Request the Description is formatted and put in descriptionGDPR.
            Map<String, Object> caseDetailJSON = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(caseDetail));
            if (caseDetail.isGdpr) {
                caseDetailJSON.remove('description');
            }
            
            res.put(LABEL_CASE_DETAIL, caseDetailJSON);
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        
        return res;
    }

    public static Map<String, Object> postComment(String request) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);

            String caseId = (String) req.get('caseId');
            String uid = (String) req.get('uid');
            String email = (String) req.get('email');
            String comment = (String) req.get('comment');
            Contact contact = CaseAPIUtil.getContact(uid, email, new String[]{
                'Name','Id','AccountId','User_Id__c','Email'
            });

            SCWrappers.CommentWrapper newComment = SCAPICaseService.addCommentFromAPIWithContact(
                caseId,
                getSerializedComment(uid, email, comment, contact), 
                contact
            );

            newComment.body = comment;

            res.put(LABEL_COMMENT_DETAIL, newComment);
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_POST);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        return res;
    }

    public static String getSerializedComment(String uid, String email, String comment, Contact contact) {
        String apiComment = SCApiService.AUTHOR_NAME_KEY + contact.Name + '\n' +
        SCApiService.COMMENT_KEY + comment.trim() + '\n' +
        SCApiService.UID_KEY + contact.User_Id__c + '\n' +
        SCApiService.EMAIL_KEY + email + '\n' +
        SCApiService.CREATED_BY_USER_KEY + UserInfo.getUserId() + '\n' +
        SCApiService.CREATED_BY_CONTACT_KEY + contact.Id;

        return apiComment;
    }

}