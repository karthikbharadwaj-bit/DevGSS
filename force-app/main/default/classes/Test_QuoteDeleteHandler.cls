@IsTest
private class Test_QuoteDeleteHandler {

    @IsTest
    static void testExecuteSuccess_DeleteMultipleQuotes() {
        // Given - Create test data: Account, Opportunity, and multiple Quotes
        Triggers.switchOff();

        // Create test account
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        // Create test opportunity
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today().addDays(30)
            })
            .create()
            .getRecord();

        // Create test quotes
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Test Quote 1',
                    'Test Quote 2',
                    'Test Quote 3'
                }),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();

        // Prepare request with quote IDs to delete
        List<Id> quoteIdsToDelete = new List<Id> {
            testQuotes[0].Id,
            testQuotes[1].Id,
            testQuotes[2].Id
        };

        ApiRequest request = new ApiRequest();
        request.requestBody = JSON.serialize(quoteIdsToDelete);

        QuoteDeleteHandler handler = new QuoteDeleteHandler();

        Test.startTest();

        // When
        ApiResponse response = handler.execute(request);

        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Should return success status code');

        // Verify quotes were deleted
        List<Quote> remainingQuotes = [SELECT Id FROM Quote WHERE Id IN :quoteIdsToDelete];
        System.assertEquals(0, remainingQuotes.size(), 'All quotes should be deleted');

        // Verify response contains deleted quote IDs
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
        Map<String, Object> responseData = (Map<String, Object>) responseMap.get('data');
        List<Object> deletedIdsObjects = (List<Object>) responseData.get('deletedQuoteIds');
        System.assertEquals(3, deletedIdsObjects.size(), 'Response should contain 3 deleted quote IDs');

        Set<Id> deletedIdsSet = new Set<Id>();
        for (Object idObj : deletedIdsObjects) {
            deletedIdsSet.add((Id) idObj);
        }
        Set<Id> expectedIdsSet = new Set<Id>(quoteIdsToDelete);
        System.assertEquals(expectedIdsSet, deletedIdsSet, 'Response should contain all deleted quote IDs');
    }

    @IsTest
    static void testExecuteError_NoQuoteIdsProvided() {
        // Given - Empty list of quote IDs
        List<Id> emptyQuoteIds = new List<Id>();

        ApiRequest request = new ApiRequest();
        request.requestBody = JSON.serialize(emptyQuoteIds);

        QuoteDeleteHandler handler = new QuoteDeleteHandler();

        Test.startTest();

        // When
        ApiResponse response = handler.execute(request);

        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(400, response.statusCode, 'Should return error status code');

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
        String errorMessage = (String) responseMap.get('message');
        System.assert(errorMessage.contains('No quote IDs provided'), 'Error message should indicate no quote IDs provided');
    }
}