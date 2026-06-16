public with sharing class SCApiService {

    public static String CONTACT_NOT_FOUND = 'Contact not found';
    public static String ACR_NOT_DEFINED = 'AccountContactRole not defined';
    public static String ADMIN_ROLE = 'RC Admin User';
    
    public static final String AUTHOR_NAME_KEY = 'authorName: ';
    public static final String COMMENT_KEY = 'comment: ';
    public static final String UID_KEY = 'uid: ';
    public static final String EMAIL_KEY = 'email: ';
    public static final String CREATED_BY_USER_KEY = 'createdByUser: ';
    public static final String CREATED_BY_CONTACT_KEY = 'createdByContact: ';

    public static Boolean isContactSCAdmin(String email, String uid) {
        return Database.countQuery('SELECT COUNT() FROM AccountContactRole WHERE' + 
            ' Contact.Email = \'' + email  + '\'' +
            ' AND Account.RC_User_Id__c = \'' + uid + '\'' +
            ' AND Role = \''+ ADMIN_ROLE  + '\''
        ) > 0;
    }
    
    public static Boolean isContactSCAdmin(Contact contact) {
        return Database.countQuery('SELECT COUNT() FROM AccountContactRole WHERE' + 
            ' ContactId = \'' + contact.Id + '\'' +
            ' AND AccountId = \'' + contact.AccountId + '\'' +
            ' AND Role = \''+ ADMIN_ROLE  + '\''
        ) > 0;
    }

    public static boolean isJsonComment(String str) {
        try {
            SCWrappers.CaseCommentAPI comment = (SCWrappers.CaseCommentAPI) JSON.deserialize(
                str, SCWrappers.CaseCommentAPI.class);
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    public static boolean isApiComment(String str) {
        return str.contains(AUTHOR_NAME_KEY) &&
            str.contains(COMMENT_KEY) &&
            str.contains(UID_KEY) &&
            str.contains(EMAIL_KEY) &&
            str.contains(CREATED_BY_USER_KEY) &&
            str.contains(CREATED_BY_CONTACT_KEY);
    }
}