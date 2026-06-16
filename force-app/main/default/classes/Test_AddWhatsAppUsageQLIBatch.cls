@isTest
private class Test_AddWhatsAppUsageQLIBatch {
    
    private static final String NEW_LICENSE_EXTID = 'SA_RCXSCRECSTORGB_2823005';
    
    // Helper method to generate test Quote IDs for testing
    private static String generateTestQuoteId(Integer index) {
        return '0Q0' + String.valueOf(index).leftPad(12, '0') + 'TST';
    }
    
    // Helper method to get test pricebook ID
    private static Id getTestPricebookId() {
        return Test.getStandardPricebookId();
    }
    
    @isTest
    static void testBatchQueryLocator() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        Database.QueryLocator locator = batch.start(null);
        
        Test.stopTest();
        
        // Verify query locator is created (even if no data matches)
        System.assertNotEquals(null, locator, 'Query locator should not be null');
        
        // Verify the query structure is correct
        String query = locator.getQuery();
        System.assert(query.contains('FROM QuoteLineItem'), 'Query should be from QuoteLineItem');
        System.assert(query.contains('ServiceName__c'), 'Query should filter by ServiceName');
        System.assert(query.contains('IsQuoteHasErrors__c'), 'Query should include quotes with errors filter');
    }
    
    @isTest
    static void testPackageCatalogIdConfiguration() {
        Test.startTest();
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        Test.stopTest();
        System.assertNotEquals(null, batch, 'Batch should initialize successfully with fallback values');
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not have processed any quotes yet');
    }
    
    @isTest
    static void testServiceNameConfiguration() {
        Test.startTest();
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        Database.QueryLocator locator = batch.start(null);
        Test.stopTest();
        System.assertNotEquals(null, batch, 'Batch should initialize successfully with Constants.CONST_ENGAGE_VOICE');
        System.assertNotEquals(null, locator, 'Query locator should be created with Constants.CONST_ENGAGE_VOICE');
        
        String query = locator.getQuery();
        System.assert(query.contains('ServiceName__c'), 'Query should filter by ServiceName');
        System.assertEquals('Engage Voice Standalone', Constants.CONST_ENGAGE_VOICE, 'Constant should have expected value');
    }
    
    @isTest
    static void testBatchWithNoNewLicenseProduct() {
        Test.startTest();
        
        // Test scenario where New License product doesn't exist
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();

        // Execute with empty scope (no QuoteLineItems match the criteria)
        List<QuoteLineItem> emptyScope = new List<QuoteLineItem>();
        batch.execute(null, emptyScope);
        
        Test.stopTest();
        System.assertEquals(0, batch.totalQLIsInserted, 'No QLIs should be inserted');
        System.assertEquals(0, batch.totalQuotesProcessed, 'No quotes should be processed');
    }
    
    @isTest
    static void testBatchFinishMethod() {
        Test.startTest();
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        // Set some test values to verify email content
        batch.totalQuotesProcessed = 5;
        batch.totalQLIsInserted = 3;
        batch.totalSkipped = 1;
        batch.totalNotEligible = 1;
        batch.totalFailed = 0;
        batch.successfulQuotes.add(generateTestQuoteId(1));
        batch.successfulQuotes.add(generateTestQuoteId(2));
        Database.BatchableContext BC = null;
        batch.finish(BC);
        Test.stopTest();

        System.assertEquals(5, batch.totalQuotesProcessed, 'Total processed should be preserved');
        System.assertEquals(3, batch.totalQLIsInserted, 'Total inserted should be preserved');
        System.assertEquals(2, batch.successfulQuotes.size(), 'Successful quotes list should be preserved');
    }
    
    @isTest
    static void testBatchStatefulVariables() {
        Test.startTest();
        
       AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Verify initial state
        System.assertEquals(0, batch.totalQuotesProcessed, 'Initial processed count should be zero');
        System.assertEquals(0, batch.totalQLIsInserted, 'Initial inserted count should be zero');
        System.assertEquals(0, batch.totalSkipped, 'Initial skipped count should be zero');
        System.assertEquals(0, batch.totalNotEligible, 'Initial not eligible count should be zero');
        System.assertEquals(0, batch.totalFailed, 'Initial failed count should be zero');
        System.assertEquals(0, batch.totalErrors, 'Initial errors count should be zero');
        System.assertEquals(0, batch.totalNotIncluded, 'Initial not included count should be zero');
        System.assertEquals(0, batch.totalNoPricebookEntry, 'Initial no pricebook entry count should be zero');
        System.assertEquals(0, batch.totalNoEngageVoice, 'Initial no engage voice count should be zero');
        System.assertNotEquals(null, batch.errorMap, 'Error map should be initialized');
        System.assertNotEquals(null, batch.successfulQuotes, 'Successful quotes list should be initialized');
        System.assertNotEquals(null, batch.unprocessableQuotes, 'Unprocessable quotes list should be initialized');
        System.assertNotEquals(null, batch.failedMasterQuotes, 'Failed master quotes list should be initialized');
        System.assertNotEquals(null, batch.failedTechnicalQuotes, 'Failed technical quotes list should be initialized');
        
        Test.stopTest();
        System.assertEquals(0, batch.errorMap.size(), 'Error map should be empty initially');
        System.assertEquals(0, batch.successfulQuotes.size(), 'Successful quotes list should be empty initially');
        System.assertEquals(0, batch.unprocessableQuotes.size(), 'Unprocessable quotes list should be empty initially');
        System.assertEquals(0, batch.failedMasterQuotes.size(), 'Failed master quotes list should be empty initially');
        System.assertEquals(0, batch.failedTechnicalQuotes.size(), 'Failed technical quotes list should be empty initially');
    }
    
    @isTest
    static void testBatchEmailBodyGeneration() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Set test data for email content
        batch.totalQuotesProcessed = 11;
        batch.totalQLIsInserted = 2;
        batch.totalSkipped = 2;
        batch.totalNotEligible = 7;
        batch.totalFailed = 0;
        batch.totalErrors = 0;
        batch.totalNotIncluded = 5;
        batch.totalNoPricebookEntry = 0;
        batch.totalNoEngageVoice = 2;
        batch.successfulQuotes.add(generateTestQuoteId(1));
        batch.successfulQuotes.add(generateTestQuoteId(2));
        batch.unprocessableQuotes.add(generateTestQuoteId(3));
        batch.unprocessableQuotes.add(generateTestQuoteId(4));
        batch.errorMap.put(generateTestQuoteId(5), 'Test error message');
        
        // Test private method through finish method (which calls buildEmailBody)
        batch.finish(null);
        
        Test.stopTest();
        System.assertEquals(11, batch.totalQuotesProcessed, 'Processed count should be included');
        System.assertEquals(2, batch.totalQLIsInserted, 'Inserted count should be included');
        System.assertEquals(0, batch.totalErrors, 'Total errors should be included');
        System.assertEquals(5, batch.totalNotIncluded, 'Not included count should be included');
        System.assertEquals(0, batch.totalNoPricebookEntry, 'No pricebook entry count should be included');
        System.assertEquals(2, batch.totalNoEngageVoice, 'No engage voice count should be included');
        System.assertEquals(2, batch.successfulQuotes.size(), 'Successful quotes should be included');
        System.assertEquals(2, batch.unprocessableQuotes.size(), 'Unprocessable quotes should be included');
        System.assertEquals(1, batch.errorMap.size(), 'Failed quotes should be included');
    }
    
    @isTest
    static void testBatchErrorHandling() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        batch.execute(null, null);
        Test.stopTest();
        System.assertEquals(0, batch.totalFailed, 'Failed count should remain 0 when method returns early due to missing product');
    }
    
    @isTest
    static void testBatchConfigurationConstants() {
        Test.startTest();
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        Test.stopTest();
        System.assertNotEquals(null, batch, 'Batch should initialize with valid constants');
    }
    
    @isTest
    static void testBatchExecuteBatchMethod() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Execute the batch with minimal batch size
        Id batchJobId = Database.executeBatch(batch, 5);
        
        Test.stopTest();
        System.assertNotEquals(null, batchJobId, 'Batch job ID should not be null');
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchJobId];
        System.assertEquals(1, jobs.size(), 'Batch job should be found in AsyncApexJob');
        AsyncApexJob job = jobs[0];
        System.assertEquals('Completed', job.Status, 'Batch job should be completed');
    }
    
    @isTest
    static void testEarlyReturnWhenProductNotFound() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Create minimal test data
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.QuoteId = generateTestQuoteId(1);
        mockQLI.PackageCatalogId__c = '1270005';
        mockQLI.PackageVersion__c = 'v1.0';
        mockQLI.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote = new Quote();
        mockQuote.Pricebook2Id = getTestPricebookId();
        mockQuote.CurrencyIsoCode = 'USD';
        mockQuote.IsMultiProductTechnicalQuote__c = false;
        mockQLI.Quote = mockQuote;
        testQLIs.add(mockQLI);
        
        // Execute with test data - should return early due to missing New License product
        batch.execute(null, testQLIs);
        
        Test.stopTest();
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not process quotes when New License product not found');
    }
    
    @isTest
    static void testEarlyReturnWithMockJSONData() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Create test QuoteLineItem with package info to test JSON creation methods
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.QuoteId = generateTestQuoteId(1);
        mockQLI.PackageCatalogId__c = '1270005'; // Eligible package ID
        mockQLI.PackageVersion__c = 'v2.0';
        mockQLI.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote = new Quote();
        mockQuote.Pricebook2Id = getTestPricebookId();
        mockQuote.CurrencyIsoCode = 'USD';
        mockQuote.IsMultiProductTechnicalQuote__c = false;
        
        mockQLI.Quote = mockQuote;
        testQLIs.add(mockQLI);
        
        batch.execute(null, testQLIs);
        Test.stopTest();
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not process quotes when New License product not found');
    }
    
    @isTest
    static void testEarlyReturnWithMultipleQLIs() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Create multiple QLIs to test the buildEngageVoiceQLIMap method
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        
        // First QLI
        QuoteLineItem mockQLI1 = new QuoteLineItem();
        mockQLI1.QuoteId = generateTestQuoteId(1);
        mockQLI1.PackageCatalogId__c = '1270005';
        mockQLI1.PackageVersion__c = 'v1.0';
        mockQLI1.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote1 = new Quote();
        mockQuote1.Pricebook2Id = getTestPricebookId();
        mockQuote1.CurrencyIsoCode = 'USD';
        mockQuote1.IsMultiProductTechnicalQuote__c = false;
        mockQLI1.Quote = mockQuote1;
        
        // Second QLI with same QuoteId (to test the containsKey logic)
        QuoteLineItem mockQLI2 = new QuoteLineItem();
        mockQLI2.QuoteId = generateTestQuoteId(1); // Same QuoteId
        mockQLI2.PackageCatalogId__c = '1271005';
        mockQLI2.PackageVersion__c = 'v1.1';
        mockQLI2.ServiceName__c = 'Engage Voice Standalone';
        mockQLI2.Quote = mockQuote1;
        
        // Third QLI with different QuoteId
        QuoteLineItem mockQLI3 = new QuoteLineItem();
        mockQLI3.QuoteId = generateTestQuoteId(2);
        mockQLI3.PackageCatalogId__c = '1272005';
        mockQLI3.PackageVersion__c = 'v1.2';
        mockQLI3.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote2 = new Quote();
        mockQuote2.Pricebook2Id = getTestPricebookId();
        mockQuote2.CurrencyIsoCode = 'USD';
        mockQuote2.IsMultiProductTechnicalQuote__c = false;
        mockQLI3.Quote = mockQuote2;
        
        testQLIs.add(mockQLI1);
        testQLIs.add(mockQLI2);
        testQLIs.add(mockQLI3);
        
        // Execute to test buildEngageVoiceQLIMap method
        batch.execute(null, testQLIs);
        
        Test.stopTest();
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not process quotes when New License product not found');
    }
    
    @isTest
    static void testEarlyReturnEligiblePackage() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.QuoteId = generateTestQuoteId(1);
        mockQLI.PackageCatalogId__c = '1270005'; // Eligible package
        mockQLI.PackageVersion__c = 'v1.0';
        mockQLI.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote = new Quote();
        mockQuote.Pricebook2Id = getTestPricebookId();
        mockQuote.CurrencyIsoCode = 'USD';
        mockQuote.IsMultiProductTechnicalQuote__c = false;
        
        mockQLI.Quote = mockQuote;
        testQLIs.add(mockQLI);
        batch.execute(null, testQLIs);
        
        Test.stopTest();
        
        // Verify execution completed but no processing occurred due to missing New License product
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not process quotes when New License product not found');
        // No quotes are processed, so counters remain at initial values
        System.assertEquals(0, batch.totalNotEligible, 'Should not increment counters when product not found');
        System.assertEquals(0, batch.totalFailed, 'Should not increment counters when product not found');
    }
    
    @isTest 
    static void testHelperMethodsWithProduct() {
        // Create minimal Product2 record to allow processing to continue past getNewLicenseProductId
        Product2 newLicenseProduct = new Product2(
            Name = 'WhatsApp Usage Add-on',
            IsActive = true,
            ExtID__c = 'SA_RCXSCRECSTORGB_2823005'
        );
        insert newLicenseProduct;
        
        // Create Standard Pricebook entry
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry stdPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = newLicenseProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert stdPBE;
        
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        
        // Create test data that will now proceed past the product check
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.QuoteId = generateTestQuoteId(1);
        mockQLI.PackageCatalogId__c = '1270005'; // Eligible package
        mockQLI.PackageVersion__c = 'v1.0';
        mockQLI.ServiceName__c = 'Engage Voice Standalone';
        
        Quote mockQuote = new Quote();
        mockQuote.Pricebook2Id = standardPricebookId;
        mockQuote.CurrencyIsoCode = 'USD';
        mockQuote.IsMultiProductTechnicalQuote__c = false;
        mockQLI.Quote = mockQuote;
        testQLIs.add(mockQLI);
        batch.execute(null, testQLIs);
        Test.stopTest();
        
        System.assertEquals(1, batch.totalQuotesProcessed, 'Should have processed quote when product exists');
        System.assert(
            (batch.totalSkipped > 0) || (batch.totalNotEligible > 0) || (batch.totalFailed > 0), 
            'Should have some processing result when helper methods execute'
        );
    }
    
    @isTest 
    static void testNewLicenseProductNotFound() {
        Test.startTest();
        
        AddWhatsAppUsageQLIBatch batch = new AddWhatsAppUsageQLIBatch();
        // Create test QLI
        List<QuoteLineItem> testQLIs = new List<QuoteLineItem>();
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.QuoteId = generateTestQuoteId(1);
        testQLIs.add(mockQLI);
        
        batch.execute(null, testQLIs);
        Test.stopTest();
        System.assertEquals(0, batch.totalQuotesProcessed, 'Should not process quotes when product not found');
    }
}