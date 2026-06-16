@isTest
public with sharing class Test_CaseService {
    @isTest
    private static void testCreateCase(){
        BillingWrappers.CaseCreateParams params = generateCaseParams();

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            CaseService.handleRequest();
        Test.stopTest();
        List<Case> cases = new CaseSelector().selectCasesDefault().executeQuery();
        System.assertEquals(
            1,
            cases.size(),
            'Case was not created'
        );
    }

    @isTest
    private static void testCreateCaseFromProServ() {
        BillingWrappers.CaseCreateParams params = generateCaseParams();
        params.isFromProServ = true;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            CaseService.handleRequest();
        Test.stopTest();
        List<Case> cases = new CaseSelector().selectCasesDefault().executeQuery();
        System.assertEquals(
            1,
            cases.size(),
            'Case was not created'
        );
    }

    @isTest
    private static void testGetProServCases() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Total_MRR__c => 100,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .create()
            .getRecord();

        List<Case> requestCases = (List<Case>) new SObjectBuilder(Case.sObjectType)
            .quantity(2)
            .setFields(new Map<sObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Opportunity_Reference__c => opp.Id,
                Case.Quote_Approval_ID__c => qt.Id,
                Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                Case.Category__c => CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES,
                Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                Case.Subject => ValueProviderBuilder.provideList(
                    new List<String>{
                        CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED,
                        CaseHelper.SUBJECT_PS_CC_QUOTE_REQUESTED
                    }
                )
            })
            .create()
            .getRecords();

        List<Case> cancellationCases = (List<Case>) new SObjectBuilder(Case.sObjectType)
            .quantity(2)
            .setFields(new Map<sObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Opportunity_Reference__c => opp.Id,
                Case.Quote_Approval_ID__c => qt.Id,
                Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                Case.Category__c => CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES,
                Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                Case.Subject => ValueProviderBuilder.provideList(
                    new List<String>{
                        CaseHelper.SUBJECT_PS_UC_QUOTE_CANCELATION + ' for',
                        CaseHelper.SUBJECT_PS_CC_QUOTE_CANCELATION + ' for'
                    }
                )
            })
            .create()
            .getRecords();
       	Triggers.switchOn();
        
        Test.setCreatedDate(requestCases[0].Id, DateTime.now().addDays(-1));
        Test.setCreatedDate(requestCases[1].Id, DateTime.now().addDays(-1));

        BillingWrappers.CaseCreateParams params = new BillingWrappers.CaseCreateParams();
        params.action = 'getProServCases';
        params.opportunityId = opp.Id;
        params.quoteApprovalId = qt.Id;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            CaseService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
        Map<String, Object> data = (Map<String, Object>) parsedBody.get('data');

        Map<String, Object> latestUCCase = (Map<String, Object>) data.get('latestUCCase');
        Map<String, Object> latestCCCase = (Map<String, Object>) data.get('latestCCCase');
        Map<String, Object> latestUCCancelationCase = (Map<String, Object>) data.get('latestUCCancelationCase');
        Map<String, Object> latestCCCancelationCase = (Map<String, Object>) data.get('latestCCCancelationCase');
        Boolean isProservCancelationFlow = (Boolean) data.get('isProservCancelationFlow');

        System.assertEquals(requestCases.get(0).Id, latestUCCase.get('Id'));
        System.assertEquals(requestCases.get(1).Id, latestCCCase.get('Id'));
        System.assertEquals(cancellationCases.get(0).Id, latestUCCancelationCase.get('Id'));
        System.assertEquals(cancellationCases.get(1).Id, latestCCCancelationCase.get('Id'));
        System.assertEquals(true, isProservCancelationFlow);
    }

    private static BillingWrappers.CaseCreateParams generateCaseParams(){
        BillingWrappers.CaseCreateParams params = new BillingWrappers.CaseCreateParams();
        params.subject = 'subject';
        params.accountId = (String) ValueProviderBuilder.provideCommonParent(Account.SObjectType).getValue();
        params.contactId = (String) ValueProviderBuilder.provideCommonParent(Contact.SObjectType).getValue();
        params.description = 'Description';

        return params;
    }
}