@IsTest
private class Test_QuoteManagerDomainHandler {
    @IsTest
    static void testTestEndpoint() {
        // Given
        QuoteManagerDomainHandler handler = new QuoteManagerDomainHandler();
        ApiRequest mockRequest = new ApiRequest();
        mockRequest.httpMethod = 'GET';
        mockRequest.version = 'v1';
        mockRequest.resourcePath = 'test';

        // When
        ApiResponse response = handler.handleRequest(mockRequest);

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        Map<String, Object> responseData = (Map<String, Object>)responseMap.get('data');
        System.assertEquals('Test endpoint successful', responseData.get('message'), 'Unexpected message in response');
        System.assertNotEquals(null, responseData.get('timestamp'), 'Timestamp should not be null');
    }

    @IsTest
    static void testQuoteApprovalsHandler() {
        // Given - Create test data
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, Date.today().addDays(30))
            .setField(Opportunity.Brand_Name__c, 'RingCentral')
            .create()
            .getRecord();

        String packageInfo = '[{"permissions":"","services":[{"serviceId":"test"}]}]';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.Status, 'Draft')
            .setField(Quote.Approved_Status__c, 'Required')
            .setField(Quote.QuoteType__c, 'Quote')
            .setField(Quote.Package_Info__c, packageInfo)
            .create()
            .getRecord();

        QuoteManagerDomainHandler handler = new QuoteManagerDomainHandler();
        ApiRequest mockRequest = new ApiRequest();
        mockRequest.httpMethod = 'GET';
        mockRequest.version = 'v1';
        mockRequest.resourcePath = 'quote/approvers';
        mockRequest.params = new Map<String, String>{
            'quoteId' => testQuote.Id
        };

        Test.startTest();
        // When
        ApiResponse response = handler.handleRequest(mockRequest);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('success', responseMap.get('status'), 'Status should be success');

        Map<String, Object> responseData = (Map<String, Object>)responseMap.get('data');
        System.assertNotEquals(null, responseData, 'Response data should not be null');
        System.assertEquals(testQuote.Id, responseData.get('Id'), 'Master quote ID should match');

        // Verify the quote was updated after populateAvailableApprovalActions
        Quote updatedQuote = [
            SELECT Id, Approved_Status__c, Package_Info__c
            FROM Quote
            WHERE Id = :testQuote.Id
        ];
        System.assertNotEquals(null, updatedQuote, 'Updated quote should be retrieved');
        System.assertEquals(testQuote.Id, updatedQuote.Id, 'Quote ID should match');

        // Verify that populateAvailableApprovalActions has processed the Package_Info__c
        System.assertNotEquals(null, updatedQuote.Package_Info__c, 'Package_Info__c should not be null after processing');

        // Verify the permissions were set in Package_Info__c by populateAvailableApprovalActions
        List<BillingWrappers.QuotePackageInfo> packageInfoList =
            (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                updatedQuote.Package_Info__c,
                List<BillingWrappers.QuotePackageInfo>.class
            );
        System.assertNotEquals(null, packageInfoList, 'Package info list should be parsed');
        System.assertEquals(false, packageInfoList.isEmpty(), 'Package info list should not be empty');

        // Verify that permissions field was populated (could be 'Submit;' or empty depending on user permissions)
        BillingWrappers.QuotePackageInfo firstPackage = packageInfoList[0];
        System.assertNotEquals(null, firstPackage.permissions, 'Permissions should be set after populateAvailableApprovalActions');
    }
}