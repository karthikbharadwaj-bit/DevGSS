@IsTest
private with sharing class Test_SlapFiveInvocable {

    @TestSetup
    private static void CreateCustomSetting() {
        SlapFiveFormURL__c setting = new SlapFiveFormURL__c(
            Name = 'FormURL',
            URL__c = 'https://example.com/api/endpoint'
        );
        insert setting;
    }

    private static Contact createContactForTest() {
        Account a = new Account(Name = 'Test Account - SlapFive');
        insert a;

        Contact c = new Contact(
            FirstName = 'Juan',
            LastName  = 'Berga',
            Email     = 'juan.berga@ringcentral.com',
            AccountId = a.Id
        );
        insert c;

        return c;
    }

    @IsTest
    private static void testSlapFiveHTTPRequest_Queueable_StatusNot200_DoesNotUpdateContact() {

        Contact c = createContactForTest();

        SlapFiveInvocableMethod.Request req = new SlapFiveInvocableMethod.Request();
        req.jsonPayloadList =
            '{"Firstname":"Juan","Lastname":"Berga","Email":"juan.berga@ringcentral.com","Id":"' +
            c.Id +
            '"}';

        List<SlapFiveInvocableMethod.Request> requests =
            new List<SlapFiveInvocableMethod.Request>{ req };

        Test.setMock(HttpCalloutMock.class, new SlapFiveCalloutMock(400, 'Bad Request'));

        Test.startTest();
        List<SlapFiveInvocableMethod.Response> responses =
            SlapFiveInvocableMethod.createHttpCallout(requests);

        System.assertEquals(1, responses.size());
        System.assertEquals('Queued', responses[0].status);
        System.assertNotEquals(null, responses[0].jobId);

        try {
            Test.stopTest();
            System.assert(false, 'Expected Queueable to fail due to non-200 status code.');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('SlapFive callout failed. StatusCode=400'),
                'Actual: ' + ex.getMessage()
            );
        }

        // Contact should not be updated
        Contact refreshed = [
            SELECT SlapFive_Customer_Nomination_Status__c
            FROM Contact
            WHERE Id = :c.Id
            LIMIT 1
        ];
        System.assertNotEquals('Sent', refreshed.SlapFive_Customer_Nomination_Status__c);
    }

    @IsTest
    private static void testSlapFiveQueueable_ThrowsWhenMissingId() {

        SlapFiveInvocableMethod.Request req = new SlapFiveInvocableMethod.Request();
        req.jsonPayloadList =
            '{"Firstname":"Juan","Lastname":"Berga","Email":"juan.berga@ringcentral.com"}';

        List<SlapFiveInvocableMethod.Request> requests =
            new List<SlapFiveInvocableMethod.Request>{ req };

        Test.setMock(HttpCalloutMock.class, new SlapFiveCalloutMock(200, 'OK'));

        Test.startTest();
        SlapFiveInvocableMethod.createHttpCallout(requests);

        try {
            Test.stopTest();
            System.assert(false, 'Expected Queueable to fail due to missing Contact Id in payload.');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Contact Id not found or invalid in payload JSON'),
                'Actual: ' + ex.getMessage()
            );
        }
    }
}