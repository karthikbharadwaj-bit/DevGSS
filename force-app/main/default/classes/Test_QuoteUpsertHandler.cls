@IsTest
private class Test_QuoteUpsertHandler {

    private static final List<String> serviceNames = new List<String>{
        Constants.CONST_OFFICE,
        Constants.CONST_RCCC,
        Constants.CONST_ENGAGE_VOICE,
        Constants.CONST_ENGAGE_DIGITAL,
        Constants.CONST_CC_PROSERV,
        Constants.CONST_PROSERV,
        Constants.CONST_MEETING,
        Constants.CONST_FAX,
        Constants.CONST_PROFESSIONAL,
        Constants.CONST_RC_EVENT
    };

    private static final Integer NUM_TECH_QUOTES = serviceNames.size();

    @TestSetup
    static void setup() {
        Triggers.switchOff();

        Feature_Toggle__c ft = new Feature_Toggle__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            EnableMultiProductUnifiedBilling__c = true,
            CalculateFSCInQW__c = true,
            Enable_Account_Based_Tax_Exemption__c = true
        );
        insert ft;

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Empty Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
            })
            .create()
            .getRecord();

        Opportunity testOpp2 = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
            })
            .create()
            .getRecord();

        // Create initial master quote
        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => testOpp2.Name + ' 1',
                Quote.OpportunityId => testOpp2.Id,
                Quote.Account__c => testOpp2.AccountId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => 'Draft',
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.QuotePosition__c => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();
    }

    @IsTest
    static void testInsertMasterAndTechQuote() {
        // Given
        Opportunity opp = [SELECT Id, Name, AccountId, BusinessIdentity__c FROM Opportunity WHERE Name = 'Empty Test Opportunity' LIMIT 1];

        QuoteUpsertHandler.QuoteRequest masterRequest = createQuoteRequest(opp, 'RingCentral MVP', true);

        // Add area code data
        BillingWrappers.AreaCodeData mainAreaCode = new BillingWrappers.AreaCodeData();
        mainAreaCode.country = 'USA';
        mainAreaCode.state = 'CA';
        mainAreaCode.city = 'San Francisco';
        mainAreaCode.areaCode = 415;
        mainAreaCode.type = 'Local';

        BillingWrappers.AreaCodeData faxAreaCode = new BillingWrappers.AreaCodeData();
        faxAreaCode.country = 'USA';
        faxAreaCode.state = 'CA';
        faxAreaCode.city = 'San Francisco';
        faxAreaCode.areaCode = 628;
        faxAreaCode.type = 'Local';

        masterRequest.mainAreaCodeInfo = mainAreaCode;
        masterRequest.faxAreaCodeInfo = faxAreaCode;

        QuoteUpsertHandler.QuoteRequest techRequest = createQuoteRequest(opp, QuoteHelper.NGBS_RCCC_PRODUCT, false);
        techRequest.serviceName = QuoteHelper.NGBS_RCCC_PRODUCT;

        List<QuoteUpsertHandler.QuoteRequest> requests = new List<QuoteUpsertHandler.QuoteRequest>{
            masterRequest,
            techRequest
        };

        String requestBody = JSON.serialize(requests);
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.requestBody = requestBody;

        QuoteUpsertHandler handler = new QuoteUpsertHandler();

        // When
        Test.startTest();
        ApiResponse response = handler.execute(apiRequest);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        // Query the created quotes from database
        List<Quote> allQuotes = [
            SELECT Id, Name, OpportunityId, Account__c, IsMultiProductTechnicalQuote__c,
                   RecordTypeId, BusinessIdentity__c, Approved_Status__c, Start_Date__c,
                   End_Date__c, Initial_Term_months__c, Term_months__c, Auto_Renewal__c,
                   Credit_Amount__c, Free_Service_Taxes__c, AverageDiscount__c, OverallDiscretion__c,
                   Ship_Attention_To__c, Shipping_Country__c, Shipping_City__c, Shipping_State__c,
                   MasterQuote__c, ServiceName__c, AreaCode__c, FaxAreaCode__c
            FROM Quote
            WHERE OpportunityId = :opp.Id
            ORDER BY IsMultiProductTechnicalQuote__c
        ];

        System.assertEquals(2, allQuotes.size(), 'Should have 2 quotes (1 master + 1 tech)');

        Quote masterQuote = allQuotes[0];
        Quote techQuote = allQuotes[1];

        // Verify master quote
        System.assertNotEquals(null, masterQuote, 'Master quote should exist');
        System.assertEquals(opp.Id, masterQuote.OpportunityId, 'Master quote should be linked to opportunity');
        System.assertEquals(opp.AccountId, masterQuote.Account__c, 'Master quote should be linked to account');
        System.assertEquals(false, masterQuote.IsMultiProductTechnicalQuote__c, 'Master quote should not be technical');
        System.assertEquals(QuoteHelper.RT_ID_BILLING, masterQuote.RecordTypeId, 'Master quote should have billing record type');
        System.assertEquals('{"currency":"USD","biId":"4"}', masterQuote.BusinessIdentity__c, 'Business identity should be set');
        System.assertEquals(QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED, masterQuote.Approved_Status__c, 'Approval status should be not required');

        // Verify contract fields on master quote
        System.assertEquals(Date.today(), masterQuote.Start_Date__c, 'Start date should be set');
        System.assertEquals(Date.today().addMonths(12), masterQuote.End_Date__c, 'End date should be set');
        System.assertEquals('12', masterQuote.Initial_Term_months__c, 'Initial term should be set');
        System.assertEquals('12', masterQuote.Term_months__c, 'Renewal term should be set');
        System.assertEquals(true, masterQuote.Auto_Renewal__c, 'Auto renewal should be set');

        // Verify financial fields
        System.assertEquals(100.00, masterQuote.Credit_Amount__c, 'Credit amount should be set');
        System.assertEquals(50.00, masterQuote.Free_Service_Taxes__c, 'Free service taxes should be set');
        System.assertEquals(10.00, masterQuote.AverageDiscount__c, 'Average discount should be set');
        System.assertEquals(15.00, masterQuote.OverallDiscretion__c, 'Overall discretion should be set');

        // Verify shipping fields
        System.assertEquals('John Doe', masterQuote.Ship_Attention_To__c, 'Ship attention to should be set');
        System.assertEquals('USA', masterQuote.Shipping_Country__c, 'Shipping country should be set');
        System.assertEquals('San Francisco', masterQuote.Shipping_City__c, 'Shipping city should be set');
        System.assertEquals('CA', masterQuote.Shipping_State__c, 'Shipping state should be set');

        // Verify area codes
        System.assertNotEquals(null, masterQuote.AreaCode__c, 'Main area code should be set');
        System.assertNotEquals(null, masterQuote.FaxAreaCode__c, 'Fax area code should be set');

        // Query and verify the actual area code records
        List<Area_Codes__c> areaCodes = [
            SELECT Id, Area_Code__c, City__c, State__c, Country__c
            FROM Area_Codes__c
            WHERE Id IN (:masterQuote.AreaCode__c, :masterQuote.FaxAreaCode__c)
            ORDER BY Area_Code__c
        ];
        System.assertEquals(2, areaCodes.size(), 'Should have 2 area code records');

        Area_Codes__c mainAreaCodeRecord = areaCodes[0];
        Area_Codes__c faxAreaCodeRecord = areaCodes[1];

        System.assertEquals(415, mainAreaCodeRecord.Area_Code__c, 'Main area code should be 415');
        System.assertEquals('San Francisco', mainAreaCodeRecord.City__c, 'Main area code city should match');
        System.assertEquals('CA', mainAreaCodeRecord.State__c, 'Main area code state should match');
        System.assertEquals('USA', mainAreaCodeRecord.Country__c, 'Main area code country should match');

        System.assertEquals(628, faxAreaCodeRecord.Area_Code__c, 'Fax area code should be 628');
        System.assertEquals('San Francisco', faxAreaCodeRecord.City__c, 'Fax area code city should match');
        System.assertEquals('CA', faxAreaCodeRecord.State__c, 'Fax area code state should match');
        System.assertEquals('USA', faxAreaCodeRecord.Country__c, 'Fax area code country should match');

        // Verify technical quote
        System.assertNotEquals(null, techQuote, 'Technical quote should exist');
        System.assertEquals(true, techQuote.IsMultiProductTechnicalQuote__c, 'Should be technical quote');
        System.assertEquals(masterQuote.Id, techQuote.MasterQuote__c, 'Technical quote should reference master quote');
        System.assertEquals(QuoteHelper.NGBS_RCCC_PRODUCT, techQuote.ServiceName__c, 'Service name should be set');

        // Verify opportunity fields updated
        Opportunity updatedOpp = [
            SELECT RCCCSyncStatus__c, ProvisioningDetails__c, SelfProvisioned__c,
                   NumberToBeRCMainNumber__c, NumberToBeCCNumber__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(IcbHelper.CC_SYNC_STATUS_NOT_STARTED, updatedOpp.RCCCSyncStatus__c, 'Sync status should be set');
        System.assertEquals('Test Provisioning Details', updatedOpp.ProvisioningDetails__c, 'Provisioning details should be set');
        System.assertEquals(true, updatedOpp.SelfProvisioned__c, 'Self provisioned should be set');
    }

    @IsTest
    static void testUpdateMasterAndInsert10TechQuotes() {

        Triggers.switchOff();
        Opportunity opp = [SELECT Id, Name, AccountId, BusinessIdentity__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Quote masterQuote = [SELECT Id FROM Quote WHERE OpportunityId = :opp.Id LIMIT 1];
        Triggers.switchOn();

        // Create update request for master + 10 tech quotes
        QuoteUpsertHandler.QuoteRequest masterRequest = createQuoteRequest(opp, 'RingCentral MVP', true);
        masterRequest.id = masterQuote.Id;
        masterRequest.specialTerms = 'Updated Special Terms';

        List<QuoteUpsertHandler.QuoteRequest> requests = new List<QuoteUpsertHandler.QuoteRequest>{ masterRequest };

        for (String serviceName : serviceNames) {
            QuoteUpsertHandler.QuoteRequest techRequest = createQuoteRequest(opp, serviceName, false);
            techRequest.serviceName = serviceName;
            requests.add(techRequest);
        }

        String requestBody = JSON.serialize(requests);
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.requestBody = requestBody;

        QuoteUpsertHandler handler = new QuoteUpsertHandler();

        // When
        Test.startTest();
        ApiResponse response = handler.execute(apiRequest);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        // Query updated master quote and created tech quotes from database
        Quote updatedMaster = [
            SELECT Id, Name, Special_Terms__c, IsMultiProductTechnicalQuote__c
            FROM Quote
            WHERE Id = :masterQuote.Id
        ];

        List<Quote> techQuotes = [
            SELECT Id, Name, IsMultiProductTechnicalQuote__c, MasterQuote__c,
                   ServiceName__c, OpportunityId, OwnerId
            FROM Quote
            WHERE OpportunityId = :opp.Id AND IsMultiProductTechnicalQuote__c = true
            ORDER BY ServiceName__c
        ];

        // Verify master quote was updated
        System.assertEquals(masterQuote.Id, updatedMaster.Id, 'Should be the same master quote');
        System.assertEquals('Updated Special Terms', updatedMaster.Special_Terms__c, 'Special terms should be updated');
        System.assertEquals(false, updatedMaster.IsMultiProductTechnicalQuote__c, 'Master quote should not be technical');

        // Verify technical quotes were created
        System.assertEquals(NUM_TECH_QUOTES, techQuotes.size(), 'Should have ' + NUM_TECH_QUOTES + ' technical quotes');

        for (Quote techQuote : techQuotes) {
            System.assertNotEquals(null, techQuote, 'Technical quote for ' + techQuote.ServiceName__c + ' should exist');
            System.assertEquals(true, techQuote.IsMultiProductTechnicalQuote__c, 'Should be technical quote');
            System.assertEquals(masterQuote.Id, techQuote.MasterQuote__c, 'Should reference master quote');
            System.assert(serviceNames.contains(techQuote.ServiceName__c), 'Service name should be in expected list');
            System.assertEquals(opp.Id, techQuote.OpportunityId, 'Should be linked to opportunity');

            // Verify technical quote has technical user as owner
            User technicalUser = UserHelper.getMultiproductTechnicalUser();
            if (technicalUser != null) {
                System.assertEquals(technicalUser.Id, techQuote.OwnerId, 'Technical quote should have technical user as owner');
            }
        }

        // Verify all quotes in database
        List<Quote> allQuotes = [
            SELECT Id, IsMultiProductTechnicalQuote__c, MasterQuote__c
            FROM Quote
            WHERE OpportunityId = :opp.Id
        ];
        System.assertEquals(NUM_TECH_QUOTES + 1, allQuotes.size(), 'Should have ' + (NUM_TECH_QUOTES + 1) + ' quotes total (1 master + ' + NUM_TECH_QUOTES + ' tech quotes)');
    }

    @IsTest
    static void testUpdate1MasterAndUpdate10TechQuotes() {

        Triggers.switchOff();
        Opportunity opp = [SELECT Id, Name, AccountId, BusinessIdentity__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Quote masterQuote = [SELECT Id, Name FROM Quote WHERE OpportunityId = :opp.Id LIMIT 1];

        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        Id techUserId = technicalUser != null ? technicalUser.Id : UserInfo.getUserId();


        List<String> quoteNames = new List<String>();
        for (String serviceName : serviceNames) {
            quoteNames.add(masterQuote.Name + ' [system: ' + serviceName + ']');
        }

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(quoteNames),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => 'Draft',
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => ValueProviderBuilder.provideList(serviceNames),
                Quote.OwnerId => techUserId,
                Quote.Special_Terms__c => 'Original Tech Terms'
            })
            .quantity(NUM_TECH_QUOTES)
            .create()
            .getRecords();

        Triggers.switchOn();

        // Create update requests for master + all technical quotes
        QuoteUpsertHandler.QuoteRequest masterRequest = createQuoteRequest(opp, 'RingCentral MVP', true);
        masterRequest.id = masterQuote.Id;
        masterRequest.specialTerms = 'Updated Special Terms V2';

        List<QuoteUpsertHandler.QuoteRequest> requests = new List<QuoteUpsertHandler.QuoteRequest>{
            masterRequest
        };

        // Add update requests for all technical quotes
        for (Integer i = 0; i < NUM_TECH_QUOTES; i++) {
            QuoteUpsertHandler.QuoteRequest techRequest = createQuoteRequest(opp, serviceNames[i], false);
            techRequest.id = techQuotes[i].Id;
            techRequest.serviceName = serviceNames[i];
            techRequest.specialTerms = 'Updated Tech Terms for ' + serviceNames[i];
            requests.add(techRequest);
        }

        String requestBody = JSON.serialize(requests);
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.requestBody = requestBody;

        QuoteUpsertHandler handler = new QuoteUpsertHandler();

        // When
        Test.startTest();
        ApiResponse response = handler.execute(apiRequest);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        // Query updated quotes from database
        Quote updatedMaster = [
            SELECT Id, Name, Special_Terms__c, Credit_Amount__c, IsMultiProductTechnicalQuote__c
            FROM Quote
            WHERE Id = :masterQuote.Id
        ];

        List<Quote> updatedTechQuotes = [
            SELECT Id, IsMultiProductTechnicalQuote__c, MasterQuote__c,
                   ServiceName__c, Special_Terms__c
            FROM Quote
            WHERE OpportunityId = :opp.Id AND IsMultiProductTechnicalQuote__c = true
            ORDER BY ServiceName__c
        ];

        // Verify master quote was updated
        System.assertEquals(masterQuote.Id, updatedMaster.Id, 'Should be the same master quote');
        System.assertEquals('Updated Special Terms V2', updatedMaster.Special_Terms__c, 'Special terms should be updated');
        System.assertEquals(false, updatedMaster.IsMultiProductTechnicalQuote__c, 'Master quote should not be technical');

        // Verify all technical quotes were updated
        System.assertEquals(NUM_TECH_QUOTES, updatedTechQuotes.size(), 'Should have ' + NUM_TECH_QUOTES + ' technical quotes');

        // Create a map for easier lookup
        Map<String, Quote> techQuotesByServiceName = new Map<String, Quote>();
        for (Quote tq : updatedTechQuotes) {
            techQuotesByServiceName.put(tq.ServiceName__c, tq);
        }

        for (Integer i = 0; i < NUM_TECH_QUOTES; i++) {
            String serviceName = serviceNames[i];
            Quote techQuote = techQuotesByServiceName.get(serviceName);

            System.assertNotEquals(null, techQuote, 'Technical quote for ' + serviceName + ' should exist');
            System.assertEquals(techQuotes[i].Id, techQuote.Id, 'Should be the same technical quote');
            System.assertEquals(true, techQuote.IsMultiProductTechnicalQuote__c, 'Should be technical quote');
            System.assertEquals(masterQuote.Id, techQuote.MasterQuote__c, 'Should reference master quote');
            System.assertEquals(serviceName, techQuote.ServiceName__c, 'Service name should match');
            System.assertEquals('Updated Tech Terms for ' + serviceName, techQuote.Special_Terms__c, 'Special terms should be updated');
        }

        // Verify no additional quotes were created
        List<Quote> allQuotes = [
            SELECT Id
            FROM Quote
            WHERE OpportunityId = :opp.Id
        ];
        System.assertEquals(NUM_TECH_QUOTES + 1, allQuotes.size(), 'Should still have ' + (NUM_TECH_QUOTES + 1) + ' quotes total (1 master + ' + NUM_TECH_QUOTES + ' tech quotes)');
    }

    // Helper method to create a quote request
    private static QuoteUpsertHandler.QuoteRequest createQuoteRequest(Opportunity opp, String productName, Boolean isPrimary) {
        QuoteUpsertHandler.QuoteRequest request = new QuoteUpsertHandler.QuoteRequest();

        request.opportunityId = opp.Id;
        request.accountId = opp.AccountId;
        request.isPOC = false;
        request.isPRMQuote = false;
        request.isQuoteHasErrors = false;
        request.isRemoveAreaCodes = false;
        request.enabledLBO = true;

        request.paymentMethod = 'Credit Card';
        request.freeShippingTerms = 'Free Shipping on orders over $100';
        request.specialTerms = 'Standard Terms';
        request.status = 'Draft';
        request.isPrimary = isPrimary;

        request.initialTerm = '12';
        request.renewalTerm = '12';
        request.autoRenewal = true;
        request.startDate = String.valueOf(Date.today());
        request.endDate = String.valueOf(Date.today().addMonths(12));
        request.expirationDate = String.valueOf(Date.today().addDays(30));
        request.updateContractTerms = false;

        request.justification = 'Test Justification';
        request.noteToCustomer = 'Test Note';

        request.creditAmount = 100.00;
        request.freeServiceTaxes = 50.00;
        request.averageDiscount = 10.00;
        request.overallDiscretion = 15.00;

        request.quoteType = QuoteHelper.QUOTE_TYPE_QUOTE;
        request.isTaxesAdded = false;
        request.isTermination = false;

        // Shipping fields
        request.shippingShipAttentionTo = 'John Doe';
        request.shippingCountry = 'USA';
        request.shippingCity = 'San Francisco';
        request.shippingState = 'CA';
        request.shippingAddressLine = '123 Main St';
        request.shippingPostalCode = '94102';
        request.shippingAdditionalAddressLine = 'Suite 100';
        request.shippingCustomerName = 'Test Customer';
        request.shippingShippingOption = 'Ground';
        request.shippingMultipleLocations = false;

        // Opportunity fields
        request.opportunityProvisioningDetails = 'Test Provisioning Details';
        request.rcAccountNumber = '12345';
        request.ccAccountNumber = '67890';
        request.opportunitySelfProvisioned = true;
        request.isTerminationOpportunity = false;

        // Package info
        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.productName = productName;
        packageInfo.packageInfo = new BillingWrappers.PackageInfo();
        packageInfo.packageInfo.id = '1234567890';
        packageInfo.packageInfo.displayName = productName + ' Package';
        packageInfo.packageInfo.oldPackageName = productName + ' Old Package';

        request.packageInfo = JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ packageInfo });

        return request;
    }
}