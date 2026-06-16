@isTest
public class EscalateCaseController_Test {
    private static final String SUPPORT_AGENT_T1_PROFILE_NAME = 'Support T1';

    private static final String USER_USERNAME = 'RC_SupportCommunityCaseListTestUser@rc.com';
    private static final String USER_EMAIL = 'useremail@rc.com';
    private static final String USER_FIRST_NAME = 'firstname';
    private static final String USER_LAST_NAME = 'lastname';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static User supportAgenteT1UserTest {
        get {
            if (supportAgenteT1UserTest == null) {
                supportAgenteT1UserTest = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return supportAgenteT1UserTest;
        }
        private set;
    }
    @TestSetup
    static void testSetup(){
        Profile apiOnlyProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{SUPPORT_AGENT_T1_PROFILE_NAME})
            .executeQuery()
            .get(0);

        new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => USER_LAST_NAME,
                    User.FirstName => USER_FIRST_NAME,
                    User.CommunityNickname => USER_LAST_NAME,
                    User.Email => USER_EMAIL,
                    User.Username => USER_USERNAME,
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => apiOnlyProfile.Id
                }
            )
            .create();
    }

    private static Case createCase(Boolean isEscalated) {

        return (Case) new sObjectBuilder(Case.sObjectType)
            .setFields(
                new Map<sObjectField, Object>{
                    Case.IsEscalated => isEscalated,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Test case',
                    Case.Status => 'New',
                    Case.OwnerId => supportAgenteT1UserTest.Id
                }
            )
            .create()
            .getRecord();
    }
    @isTest
    public static void escalateCase_whenJustificationIsNotCompleted_shouldThrowAnError() {
        Case cs = createCase(false);
        Test.setCreatedDate(cs.Id, Datetime.now().addDays(-10));
        PageReference pr = new PageReference('/apex/EscalateCase');
        Test.setCurrentPage(pr);

        Pagereference pg = new Pagereference('/apex/test');

        EscalateCaseController escalateCaseCtr;
        Test.startTest();
            ApexPages.StandardController controller = new ApexPages.standardController(cs);
            escalateCaseCtr = new EscalateCaseController(controller);
            escalateCaseCtr.isEscalatable = true;
            escalateCaseCtr.justification = '';
            pg = escalateCaseCtr.escalateCase();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have a message');
        System.assert(
            ApexPages.getMessages().get(0).getDetail().contains(EscalateCaseController.JUSTIFICATION_TOO_SHORT),
            'Bad error message: ' +ApexPages.getMessages().get(0).getDetail()
        );
        System.assertEquals(null, pg, 'The method should return a null value');
    }
    @isTest
    public static void openEscalateCase_whenCaseIsAlreadyEsclated_shouldThrowAnError() {
        Case cs = createCase(true);
        PageReference pr = new PageReference('/apex/EscalateCase');
        Test.setCurrentPage(pr);

        Pagereference pg = new Pagereference('/apex/test');

        EscalateCaseController escalateCaseCtr;
        Test.startTest();
            ApexPages.StandardController controller = new ApexPages.standardController(cs);
            escalateCaseCtr = new EscalateCaseController(controller);
            escalateCaseCtr.justification = 'Justification must be at least 50 characters. test test test';
            pg = escalateCaseCtr.escalateCase();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have a message');
        System.assertEquals(null, pg, 'The method should return a null value');
        System.assertEquals(
            CaseHelper.CASE_IS_ALREADY_ESCALATED_TEXT, 
            escalateCaseCtr.cannotBeEscalatedReason, 
            'The variable cannotBeEscalatedReason must be ' + CaseHelper.CASE_IS_ALREADY_ESCALATED_TEXT
        );
        System.assert(
            ApexPages.getMessages().get(0).getDetail().contains(CaseHelper.CASE_IS_ALREADY_ESCALATED_TEXT),
            'Bad error message: ' + ApexPages.getMessages().get(0).getDetail()
        );
    }
    @isTest
    public static void escalateCase_whenAllTheRequerimentsAreOk_shouldCreateCaseCommentAndUpdateCase() {
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = true;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = true;
        
        Case cs = createCase(false);
        PageReference pr = new PageReference('/apex/EscalateCase');
        Test.setCurrentPage(pr);

        Pagereference pg = new Pagereference('/apex/test');

        Test.setCreatedDate(cs.Id, Datetime.now().addDays(-3));

        EscalateCaseController escalateCaseCtr;
        Test.startTest();
            System.runAs(supportAgenteT1UserTest) {
                ApexPages.StandardController controller = new ApexPages.standardController(cs);
                escalateCaseCtr = new EscalateCaseController(controller);
                escalateCaseCtr.justification = 'Justification must be at least 50 characters. test test test';
                pg = escalateCaseCtr.escalateCase();
            }
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have a message, Messages: ' + ApexPages.getMessages());
        System.assertEquals(null, pg, 'The method should not return a null value');
        System.assertEquals(null, escalateCaseCtr.cannotBeEscalatedReason, 'The variable cannotBeEscalatedReason must be null');
        System.assert(  
            ApexPages.getMessages().get(0).getDetail().contains(EscalateCaseController.CASE_HAS_BEEN_ESCALATED),
            'Bad error message: ' + ApexPages.getMessages().get(0).getDetail()
        );

        List<CaseComment> csComments = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{cs.Id})
            .executeQuery();


        system.assertEquals(1, csComments.size(), 'Justification and comment body field must be the same');
        system.assertEquals(escalateCaseCtr.justification, csComments[0].CommentBody, 'Justification and comment body field must be the same');

        cs = (Case) new CaseSelector()
            .selectCaseForEscalating(new Object[]{cs.Id})
            .executeQuery()[0];

        System.assertEquals(true, cs.IsEscalated, 'The case must be escalated.');
    }
}