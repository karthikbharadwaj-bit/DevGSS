public with sharing class CaseInfoAPIController {

    public static final String SUCCESS_MESSAGE = 'Contact info provided';
    public static final String LABEL_CONTACT_INFO = 'contactInfo';
    public static final String LABEL_CONTACT_ID = 'contactId';
    public static final String SUCCESS_MESSAGE_POST = 'Contact upsert done.';

    public static Map<String, Object> getContactInfo(String request) {

        Map<String, Object> res = new Map<String, Object>();
        try{
            Contact cont = getContact(request);

            res.put(LABEL_CONTACT_INFO, new SCWrappers.ContactInfo(cont));
            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }
        return res;
    }

    public static Map<String, Object> upsertRelatedUser(String request) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Contact cont = getContact(request);

            SCWrappers.ContactInfoAPIPostRequest contactInfo = getContactInfoPostRequest(request);

            res.put(CaseAPIUtil.MESSAGE_FIELD_NAME, SUCCESS_MESSAGE_POST);
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
            res.put(LABEL_CONTACT_ID, contactInfo.upsertContact(cont));
            res.put(CaseAPIUtil.SUCCESS_FIELD_NAME, true);
        } catch (Exception e) {
            CaseAPIUtil.addErrorMessage(res, e.getMessage());
        }

        return res;
    }

    private static SCWrappers.ContactInfoAPIPostRequest getContactInfoPostRequest(String request) {
        return (SCWrappers.ContactInfoAPIPostRequest) JSON.deserialize(request, SCWrappers.ContactInfoAPIPostRequest.class);
    }

    private static Contact getContact(String request) {
        Map<String, Object> req = CaseAPIUtil.deserializeRequest(request);
        String uid = (String) req.get('uid');
        String email = (String) req.get('email');
        return CaseAPIUtil.getContact(uid, email, new String[]{
            'Id',
            'Phone_ext__c',
            'Email',
            'Phone',
            'FirstName',
            'LastName',
            'accountId'
        });
    }
}