@isTest
private class TestEmailMessageTriggerHandler {

    @isTest
    static void testPopulateFirstResponseFieldOnRelatedCase() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Total_MRR__c => 100
                }
            )
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.AccountId => testAcc.Id,
                    Case.Opportunity_Reference__c => testOpp.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        new SObjectBuilder(EmailMessage.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    EmailMessage.ParentId => testCase.Id,
                    EmailMessage.Subject => 'Test subject',
                    EmailMessage.MessageIdentifier => 'TESTMSGID300',
                    EmailMessage.ThreadIdentifier => 'TESTTRDID100'
                }
            )
            .create();

        Case reselectedCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
        ).getFirst();

        System.assertNotEquals(null, reselectedCase.FirstResponseTime__c, 'FirstResponseTime Field should be populated on related case record');

        Test.stopTest();
    }

    
    @isTest
    static void testCaseCommentForCLPCases_whenEmailMeetsTheRequeriments_shouldCreateCaseComments(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();
            
        insert new Owner_Assignment_for_Relationship_Cases__c();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP,
                    Case.AccountId => testAcc.Id
                }
            )
            .create()
            .getRecord();

        string textBody = 'Comment' +
        '________________________________' +
        'From: Nicolas Gomez <nicolas.gomez@ringcentral.com>' +
        'Sent: Thursday, November 2, 2023 12:24' +
        'To: Nicolas Gomez <nicolas.gomez@ringcentral.com>' +
        'Subject: Re: Sandbox: Contacting you regarding your recent Relationship Survey Response taken on 11/2/2023' +
        'Test 1 email' +
        '________________________________' +
        'From: testtt <nicolas.gomez@ringcentral.com>' +
        'Sent: Thursday, November 2, 2023 12:20' +
        'To: Nicolas Gomez <nicolas.gomez@ringcentral.com>' +
        'Subject: Sandbox: Contacting you regarding your recent Relationship Survey Response taken on 11/2/2023' +
        'Hello,  My name is Nicolas Gomez and I am a Customer Experience Manager at RingCentral. I would like to thank you for taking the time to take our Customer Relationship survey.' +
        'We are a new team within RingCentral that is dedicated specifically to working with customers who have taken the time to provide us feedback. My goal is to promptly find answers and provide resolutions to any issues or questions you may have.' +
        'Would you be willing to provide a bit of additional detail regarding your feedback?  That will help us start to better address your specific concerns.  I hope to hear back from you to learn more about what improvements would be beneficial to your business.' +
        'I would love to hold a quick call with you to discuss the current dissatisfaction with RingCentral - Can you please let me know when you will be available, and I can set up a meeting so we can discuss your concerns?' +
        'I look forward to working with you. Again, we appreciate you as our customer and the time you spent to give us critical feedback. Thank you!' +
        'Nicolas Gomez' +
        'ref:!00DD509QDV.!500D50BwYWQ:ref';

        Test.startTest();
            new SObjectBuilder(EmailMessage.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        EmailMessage.ParentId => testCase.Id,
                        EmailMessage.Subject => 'Test subject',
                        EmailMessage.MessageIdentifier => 'TESTMSGID300',
                        EmailMessage.ThreadIdentifier => 'TESTTRDID100',
                        EmailMessage.Incoming => true,
                        EmailMessage.TextBody => textBody
                    }
                )
                .quantity(5)
                .create();
        Test.stopTest();

        List<CaseComment> caseComments = (CaseComment[]) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new Object[]{testCase.Id})
            .executeQuery();

        System.assertEquals(5, caseComments.size());
        for (CaseComment csComment : caseComments) {
            System.assertEquals('Comment', csComment.CommentBody, 'Invalid comment body');
        }

        List<Case> cases = (Case[]) new CaseSelector()
            .selectCasesDefault()
            .selectField(Case.Status)
            .executeQuery();

        System.assertEquals(CaseHelper.CASE_STATUS_UPDATED_BY_CUSTOMER, cases[0].Status);
    }
}