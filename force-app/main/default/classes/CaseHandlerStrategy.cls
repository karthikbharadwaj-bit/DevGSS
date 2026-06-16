public with sharing class CaseHandlerStrategy {

    public interface ICaseHandler {
        void validate(Map<String,Object> req);
        Map<String,Object> execute(Map<String,Object> req);
    }

    private static Map<String, ICaseHandler> strategyByName = new Map<String, ICaseHandler>{
        // 'reopen' => new CaseHandlerReopen(),
        // 'escalate' => new CaseHandlerEscalate(),
        'close' => new CaseHandlerClose()
    };

    public static final String INVALID_ACTION = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid action value. Valid values: ' + strategyByName.keySet();
    public static final String NO_CASE_FOUND =  + 'no case found';
    public static final String INVALID_CONTACT_ACCOUNT =  'Case\'s contact is not associated with Case\'s Account';
    public static final String CONTACT_NO_RELATED_TO_CASE =  'Case\'s contact\'s email is not the same as email value sent';
    public static final String ACCOUNT_NO_RELATED_TO_CASE =  'Case\'s account\'s uid is not the same as uid value sent';

    public static ICaseHandler getStrategy(String action) {
        if (!strategyByName.containsKey(action.toLowerCase())) {
            throw new HandledException(INVALID_ACTION);
        }

        return strategyByName.get(action.toLowerCase());
    }

    public static Case getCase(String email, String uid, String caseId) {
        Case[] cases = (Case[]) new CaseSelector()
            .selectCasesByIds(new Set<Id>{caseId})
            .setCondition('Id IN :bind0 AND IsVisibleInSelfService = true')
            .selectFields(new String[]{
                'Contact.Email',
                'Account.RC_User_Id__c',
                'Contact.AccountId',
                'AccountId',
                'ContactId',
                'isClosed'
            })
            .executeQuery();
            
            
        if (cases.isEmpty()) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + NO_CASE_FOUND);
        }
        
        Case aCase = cases[0];
        Boolean isAdmin = SCApiService.isContactSCAdmin(email, uid); 

        if (!isAdmin) {
            if (aCase.Contact?.AccountId != aCase.AccountId) {
                throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + INVALID_CONTACT_ACCOUNT);
            }
        
        
            if (aCase.Contact?.Email != email) {
                throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + CONTACT_NO_RELATED_TO_CASE);
            }
        }

        if (aCase.Account?.RC_User_Id__c != uid) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE + ': ' + ACCOUNT_NO_RELATED_TO_CASE);
        }

        return aCase;
    }
}