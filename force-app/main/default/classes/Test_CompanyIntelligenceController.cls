/**
 * Verifies request mapping, authenticated callouts, grounded response parsing, and safe failures.
 */
@isTest
private class Test_CompanyIntelligenceController {
    private static final String TEST_ENDPOINT =
        'https://company-intelligence.example/api/v1/opportunity_summary';
    private static final String TEST_TOKEN = 'test-identity-token';
    private static final String SUCCESS_RESPONSE =
        '{"statusCode":200,"body":{"company_intelligence":{' +
        '"sources":[{"index":7,"display_label":"example.com","title":"Example",' +
        '"url":"https://vertexaisearch.cloud.google.com/grounding-api-redirect/token",' +
        '"domain":"example.com"}],' +
        '"derived_information":[{"text":"Supported claim","source_indices":[7]}],' +
        '"web_search_queries":["Example latest announcements"],' +
        '"summary":{"company_snapshot":["Public company"],' +
        '"latest_company_announcements":[],"executive_leadership_announcements":[],' +
        '"business_and_financial_signals":[],"competitive_and_market_context":[],' +
        '"opportunity_relevance":["Relevant signal"],"information_gaps":[]},' +
        '"search_entry_point":{"rendered_content":"<style>.x{color:blue}</style><svg></svg>"}' +
        '}}}';

    @isTest
    private static void shouldMapRequiredAndOptionalFieldsWhenAccountIsComplete() {
        String accountName = 'Microsoft Corporation';
        String website = 'https://www.microsoft.com';
        String industry = 'Enterprise Software';
        String opportunityType = 'Renewal';
        String username = 'salesforce_username';
        String city = 'Redmond';
        String state = 'Washington';
        String postalCode = '98052';
        String country = 'United States';
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, accountName)
            .setField(Account.Website, website)
            .setField(Account.Industry, industry)
            .setField(Account.BillingCity, city)
            .setField(Account.BillingState, state)
            .setField(Account.BillingPostalCode, postalCode)
            .setField(Account.BillingCountry, country)
            .build()
            .getRecord();
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .setField(Opportunity.Type, opportunityType)
            .build()
            .getRecord();
        String usernameMessage = 'The running user Username should map to username';
        String companyNameMessage = 'Account.Name should map to company_name';
        String websiteMessage = 'Account.Website should map to company_url';
        String addressMessage = 'Available billing fields should be joined in order';
        String contextMessage = 'Business context should include Industry and Opportunity.Type';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceRequest request =
                CompanyIntelligenceController.buildRequest(
                    opportunity,
                    account,
                    username
                );
        Test.stopTest();

        Assert.areEqual(username, request.username, usernameMessage);
        Assert.areEqual(accountName, request.companyName, companyNameMessage);
        Assert.areEqual(website, request.companyUrl, websiteMessage);
        Assert.areEqual(
            String.join(
                new List<String> { city, state, postalCode, country },
                ', '
            ),
            request.address,
            addressMessage
        );
        Assert.areEqual(industry, request.additionalContext.industry, contextMessage);
        Assert.areEqual(
            opportunityType,
            request.additionalContext.opportunityType,
            contextMessage
        );
    }

    @isTest
    private static void shouldOmitOptionalFieldsWhenAccountIsMinimal() {
        String accountName = 'Minimal Company';
        String username = 'salesforce_username';
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, accountName)
            .build()
            .getRecord();
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .build()
            .getRecord();
        String companyNameMessage = 'Required company_name should remain';
        String websiteMessage = 'Blank website should be omitted';
        String addressMessage = 'Blank billing address should be omitted';
        String contextMessage = 'Empty additional context should be omitted';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceRequest request =
                CompanyIntelligenceController.buildRequest(
                    opportunity,
                    account,
                    username
                );
            Map<String, Object> payload = CompanyIntelligenceController.toServicePayload(
                request
            );
        Test.stopTest();

        Assert.areEqual(accountName, payload.get('company_name'), companyNameMessage);
        Assert.isFalse(payload.containsKey('company_url'), websiteMessage);
        Assert.isFalse(payload.containsKey('address'), addressMessage);
        Assert.isFalse(payload.containsKey('additional_context'), contextMessage);
    }

    @isTest
    private static void shouldRejectRequestWhenAccountOrNameIsMissing() {
        String username = 'salesforce_username';
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .build()
            .getRecord();
        Account unnamedAccount = (Account) new SObjectBuilder(
                Account.SObjectType
            )
            .setField(Account.Name, null)
            .build()
            .getRecord();
        String accountMessage = 'A missing Account should not produce a request';
        String accountNameMessage = 'A missing Account name should not produce a request';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceRequest missingAccountRequest =
                CompanyIntelligenceController.buildRequest(
                    opportunity,
                    null,
                    username
                );
            CompanyIntelligenceController.CompanyIntelligenceRequest missingNameRequest =
                CompanyIntelligenceController.buildRequest(
                    opportunity,
                    unnamedAccount,
                    username
                );
        Test.stopTest();

        Assert.isNull(missingAccountRequest, accountMessage);
        Assert.isNull(missingNameRequest, accountNameMessage);
    }

    @isTest
    private static void shouldReturnTypedResultWhenGroundedEnvelopeSucceeds() {
        CapturingHttpMock mock = new CapturingHttpMock(200, SUCCESS_RESPONSE);
        Test.setMock(HttpCalloutMock.class, mock);
        String successMessage = 'A successful service envelope should produce a successful result';
        String sourceIndexMessage = 'The explicit source index should be retained';
        String sourceLabelMessage = 'The source display label should be retained';
        String claimIndexMessage = 'A claim should retain its explicit source index';
        String markupMessage = 'Search Suggestions markup should be retained without rewriting';
        String endpointMessage = 'The configured host should use the Company Intelligence path';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceResult result =
                CompanyIntelligenceController.executeRequest(
                    completeRequest(),
                    new CompanyIntelligenceController.AuthContext(
                        TEST_ENDPOINT,
                        TEST_TOKEN
                    )
                );
        Test.stopTest();

        Assert.isTrue(result.success, successMessage);
        Assert.areEqual(7, result.intelligence.sources[0].index, sourceIndexMessage);
        Assert.areEqual(
            'example.com',
            result.intelligence.sources[0].displayLabel,
            sourceLabelMessage
        );
        Assert.areEqual(
            7,
            result.intelligence.derivedInformation[0].sourceIndices[0],
            claimIndexMessage
        );
        Assert.areEqual(
            '<style>.x{color:blue}</style><svg></svg>',
            result.intelligence.searchEntryPoint.renderedContent,
            markupMessage
        );
        Assert.areEqual(
            'https://company-intelligence.example/api/v1/company_intelligence',
            mock.capturedEndpoint,
            endpointMessage
        );
    }

    @isTest
    private static void shouldSerializeOnlyCompanyFieldsWhenCallingService() {
        CapturingHttpMock mock = new CapturingHttpMock(200, SUCCESS_RESPONSE);
        Test.setMock(HttpCalloutMock.class, mock);
        String usernameMessage = 'Username should be sent';
        String companyMessage = 'Company name should be sent';
        String contextMessage = 'Relevant business context should be sent';
        String contactMessage = 'Contact names must not be sent';
        String emailMessage = 'Email addresses must not be sent';
        String phoneMessage = 'Phone numbers must not be sent';

        Test.startTest();
            CompanyIntelligenceController.executeRequest(
                completeRequest(),
                new CompanyIntelligenceController.AuthContext(
                    TEST_ENDPOINT,
                    TEST_TOKEN
                )
            );
        Test.stopTest();

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
            mock.capturedBody
        );
        Assert.areEqual('salesforce_username', payload.get('username'), usernameMessage);
        Assert.areEqual('Microsoft Corporation', payload.get('company_name'), companyMessage);
        Assert.isTrue(payload.containsKey('additional_context'), contextMessage);
        Assert.isFalse(payload.containsKey('contact_name'), contactMessage);
        Assert.isFalse(payload.containsKey('email'), emailMessage);
        Assert.isFalse(payload.containsKey('phone'), phoneMessage);
    }

    @isTest
    private static void shouldMapSafeMessagesWhenServiceReturnsKnownErrors() {
        Map<Integer, String> statusToExpectedMessageMap = new Map<Integer, String> {
            400 => Label.CompanyIntelligenceInvalidAccount,
            413 => Label.CompanyIntelligenceRequestTooLarge,
            422 => Label.CompanyIntelligenceNoReliableInformation,
            429 => Label.CompanyIntelligenceRateLimited,
            500 => Label.CompanyIntelligenceTemporaryFailure
        };
        Map<Integer, CompanyIntelligenceController.CompanyIntelligenceResult> statusToResultMap =
            new Map<Integer, CompanyIntelligenceController.CompanyIntelligenceResult>();
        String successMessage = 'Known error envelopes should not be successful';
        String statusMessage = 'Known service statuses should be retained';
        String safeMessage = 'Each status should map to its safe label';
        String privacyMessage = 'Raw service bodies must not be exposed';

        Test.startTest();
            for (Integer statusCode : statusToExpectedMessageMap.keySet()) {
                String response = JSON.serialize(
                    new Map<String, Object> {
                        'statusCode' => statusCode,
                        'body' => 'sensitive server exception and prompt'
                    }
                );
                statusToResultMap.put(
                    statusCode,
                    CompanyIntelligenceController.parseResponse(response)
                );
            }
        Test.stopTest();

        for (Integer statusCode : statusToExpectedMessageMap.keySet()) {
            CompanyIntelligenceController.CompanyIntelligenceResult result =
                statusToResultMap.get(statusCode);
            Assert.isFalse(result.success, successMessage);
            Assert.areEqual(statusCode, result.statusCode, statusMessage);
            Assert.areEqual(
                statusToExpectedMessageMap.get(statusCode),
                result.message,
                safeMessage
            );
            Assert.isFalse(result.message.contains('sensitive'), privacyMessage);
        }
    }

    @isTest
    private static void shouldMapRateLimitWhenHttpCallFails() {
        String responseBody = '{"token":"secret","prompt":"private"}';
        CapturingHttpMock mock = new CapturingHttpMock(429, responseBody);
        Test.setMock(HttpCalloutMock.class, mock);
        String successMessage = 'A non-200 HTTP response should fail';
        String statusMessage = 'HTTP 429 should retain the rate-limit status';
        String safeMessage = 'HTTP 429 should return a safe rate-limit message';
        String privacyMessage = 'The raw HTTP response must not be exposed';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceResult result =
                CompanyIntelligenceController.executeRequest(
                    completeRequest(),
                    new CompanyIntelligenceController.AuthContext(
                        TEST_ENDPOINT,
                        TEST_TOKEN
                    )
                );
        Test.stopTest();

        Assert.isFalse(result.success, successMessage);
        Assert.areEqual(429, result.statusCode, statusMessage);
        Assert.areEqual(Label.CompanyIntelligenceRateLimited, result.message, safeMessage);
        Assert.isFalse(result.message.contains('secret'), privacyMessage);
    }

    @isTest
    private static void shouldUseCurrentUsernameWhenOpportunityHasAccount() {
        String accountName = (String) new ValueProvider.UniqueStringProvider(
                'Integrated Company'
            )
            .getValue();
        String website = 'https://integrated.example';
        String industry = 'Software';
        String city = 'Denver';
        String country = 'United States';
        String opportunityType = 'Renewal';
        Triggers.switchOff();
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType)
            )
            .setField(Account.Name, accountName)
            .setField(Account.Website, website)
            .setField(Account.Industry, industry)
            .setField(Account.BillingCity, city)
            .setField(Account.BillingCountry, country)
            .create()
            .getRecord();
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .setFields(
                SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType)
            )
            .setField(Opportunity.AccountId, account.Id)
            .setField(Opportunity.CloseDate, Date.today().addDays(30))
            .setField(Opportunity.Type, opportunityType)
            .create()
            .getRecord();
        Triggers.switchOn();
        CapturingHttpMock mock = new CapturingHttpMock(200, SUCCESS_RESPONSE);
        Test.setMock(HttpCalloutMock.class, mock);
        CompanyIntelligenceController.authProvider = new StubAuthProvider();
        String successMessage = 'A valid Opportunity and Account should produce a callout';
        String usernameMessage = 'The current Salesforce Username should be sent';
        String companyMessage = 'The queried Account name should be sent';
        String addressMessage = 'Only populated address fields should be sent';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceResult result =
                CompanyIntelligenceController.requestCompanyIntelligence(
                    opportunity.Id
                );
        Test.stopTest();

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
            mock.capturedBody
        );
        Assert.isTrue(result.success, successMessage);
        Assert.areEqual(UserInfo.getUserName(), payload.get('username'), usernameMessage);
        Assert.areEqual(accountName, payload.get('company_name'), companyMessage);
        Assert.areEqual(
            String.join(new List<String> { city, country }, ', '),
            payload.get('address'),
            addressMessage
        );
    }

    @isTest
    private static void shouldReturnInvalidAccountWhenOpportunityHasNoAccount() {
        Triggers.switchOff();
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .setFields(
                SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType)
            )
            .setField(Opportunity.CloseDate, Date.today().addDays(30))
            .create()
            .getRecord();
        Triggers.switchOn();
        String successMessage = 'An Opportunity without an Account should fail safely';
        String statusMessage = 'A missing Account should map to status 400';
        String message = 'A missing Account should return the safe invalid-Account label';

        Test.startTest();
            CompanyIntelligenceController.CompanyIntelligenceResult result =
                CompanyIntelligenceController.requestCompanyIntelligence(
                    opportunity.Id
                );
        Test.stopTest();

        Assert.isFalse(result.success, successMessage);
        Assert.areEqual(400, result.statusCode, statusMessage);
        Assert.areEqual(Label.CompanyIntelligenceInvalidAccount, result.message, message);
    }

    private static CompanyIntelligenceController.CompanyIntelligenceRequest completeRequest() {
        String accountName = 'Microsoft Corporation';
        String website = 'https://www.microsoft.com';
        String industry = 'Enterprise Software';
        String city = 'Redmond';
        String state = 'Washington';
        String country = 'United States';
        String opportunityType = 'Renewal';
        String username = 'salesforce_username';
        Opportunity opportunity = (Opportunity) new SObjectBuilder(
                Opportunity.SObjectType
            )
            .setField(Opportunity.Type, opportunityType)
            .build()
            .getRecord();
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, accountName)
            .setField(Account.Website, website)
            .setField(Account.Industry, industry)
            .setField(Account.BillingCity, city)
            .setField(Account.BillingState, state)
            .setField(Account.BillingCountry, country)
            .build()
            .getRecord();
        return CompanyIntelligenceController.buildRequest(
            opportunity,
            account,
            username
        );
    }

    private class StubAuthProvider extends CompanyIntelligenceController.AuthProvider {
        public override CompanyIntelligenceController.AuthContext authenticate() {
            return new CompanyIntelligenceController.AuthContext(
                TEST_ENDPOINT,
                TEST_TOKEN
            );
        }
    }

    private class CapturingHttpMock implements HttpCalloutMock {
        private Integer responseStatus;
        private String responseBody;
        private String capturedEndpoint;
        private String capturedBody;

        private CapturingHttpMock(Integer responseStatus, String responseBody) {
            this.responseStatus = responseStatus;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            capturedEndpoint = request.getEndpoint();
            capturedBody = request.getBody();

            HttpResponse response = new HttpResponse();
            response.setStatusCode(responseStatus);
            response.setBody(responseBody);
            return response;
        }
    }
}
