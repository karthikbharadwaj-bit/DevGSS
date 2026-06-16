@isTest
public class Test_DialogflowUpdateCaseSubject {

    @isTest
    static void testUpdateCaseOwner() {
        triggers.switchOff();
        Case c = new Case(subject = 'Test Subject', description = 'Test Description');
        insert c;
        List<Case> insertedCases = [SELECT Id, CaseNumber FROM Case WHERE Id IN :new List<Id>{c.Id}];
		String caseNum = insertedCases[0].CaseNumber;
        triggers.switchOn();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/UpdateCaseSubject';
        req.httpMethod = 'GET';
        req.addParameter('casenumber', caseNum);
        req.addParameter('caseSubject', 'New Subject');
        req.addParameter('salesforceUserId', UserInfo.getUserId());

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DialogflowUpdateCaseSubject.updateSubject();
        Test.stopTest();

        Case updatedCase = [SELECT Id, Subject FROM Case WHERE Id = :c.Id];
        System.assertEquals('New Subject', updatedCase.Subject);
    }

}