@IsTest
public class Test_DialogflowUpdateCase {
    
    @IsTest
    static void testUpdateCasePriority() {
        Case c = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Priority = 'Medium'
        );
        insert c;
        List<Case> insertedCases = [SELECT Id, CaseNumber FROM Case WHERE Id IN :new List<Id>{c.Id}];
		String caseNum = insertedCases[0].CaseNumber;

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser114434341231okokfortest@example.com',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/DialogflowUpdateCase';
        req.httpMethod = 'POST';

        Map<String, Object> requestBody = new Map<String, Object>{
            'salesforceUserId' => u.Id,
            'caseNumber' => caseNum,
            'priority' => 'High'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        System.runAs(u) {
            DialogflowUpdateCase.updateCasePriority();
        }
        Test.stopTest();

        Case updatedCase = [SELECT Priority FROM Case WHERE Id = :c.Id];
        System.assertEquals('High', updatedCase.Priority);
    }

}