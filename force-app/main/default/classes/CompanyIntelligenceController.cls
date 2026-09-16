/**
 * Builds public-company context from an Opportunity and invokes the grounded intelligence service.
 */
public with sharing class CompanyIntelligenceController {
    private static final Integer SUCCESS_STATUS = 200;
    private static final Integer INVALID_REQUEST_STATUS = 400;
    private static final Integer REQUEST_TOO_LARGE_STATUS = 413;
    private static final Integer NO_RELIABLE_INFORMATION_STATUS = 422;
    private static final Integer RATE_LIMIT_STATUS = 429;
    private static final Integer INTERNAL_FAILURE_STATUS = 500;
    private static final Integer CALLOUT_TIMEOUT_MS = 120000;
    private static final Integer QUERY_LIMIT = 1;
    private static final String AUTH_CONFIG_NAME = 'opportunitySummary';
    private static final String ENDPOINT_PATH = '/api/v1/company_intelligence';
    private static final String ID_CONDITION = 'Id = :bind0';

    @TestVisible
    private static AuthProvider authProvider = new AuthProvider();

    @AuraEnabled(cacheable=false)
    public static CompanyIntelligenceResult requestCompanyIntelligence(
        Id recordId
    ) {
        if (recordId == null) {
            return failure(INVALID_REQUEST_STATUS);
        }

        try {
            Opportunity opportunity = getOpportunity(recordId);
            if (opportunity == null || opportunity.AccountId == null) {
                return failure(INVALID_REQUEST_STATUS);
            }

            Account account = getAccount(opportunity.AccountId);
            CompanyIntelligenceRequest request = buildRequest(
                opportunity,
                account,
                UserInfo.getUserName()
            );
            if (request == null) {
                return failure(INVALID_REQUEST_STATUS);
            }

            AuthContext authContext = authProvider.authenticate();
            return executeRequest(request, authContext);
        } catch (Exception ignored) {
            return failure(INTERNAL_FAILURE_STATUS);
        }
    }

    @TestVisible
    private static Opportunity getOpportunity(Id opportunityId) {
        List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .withoutSelectorFieldsIncluded()
            .selectFields(
                new List<Schema.SObjectField> {
                    Opportunity.Id,
                    Opportunity.AccountId,
                    Opportunity.Type
                }
            )
            .setCondition(ID_CONDITION)
            .setQueryBindings(new List<Object> { opportunityId })
            .setLimit(QUERY_LIMIT)
            .executeQuery();

        if (opportunities.isEmpty()) {
            return null;
        }
        List<SObject> readableOpportunities = stripReadable(opportunities);
        return readableOpportunities.isEmpty()
            ? null
            : (Opportunity) readableOpportunities[0];
    }

    @TestVisible
    private static Account getAccount(Id accountId) {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .withoutSelectorFieldsIncluded()
            .selectFields(
                new List<Schema.SObjectField> {
                    Account.Id,
                    Account.Name,
                    Account.Website,
                    Account.Industry,
                    Account.BillingStreet,
                    Account.BillingCity,
                    Account.BillingState,
                    Account.BillingPostalCode,
                    Account.BillingCountry
                }
            )
            .setCondition(ID_CONDITION)
            .setQueryBindings(new List<Object> { accountId })
            .setLimit(QUERY_LIMIT)
            .executeQuery();

        if (accounts.isEmpty()) {
            return null;
        }
        List<SObject> readableAccounts = stripReadable(accounts);
        return readableAccounts.isEmpty()
            ? null
            : (Account) readableAccounts[0];
    }

    @TestVisible
    private static CompanyIntelligenceRequest buildRequest(
        Opportunity opportunityRecord,
        Account accountRecord,
        String username
    ) {
        String accountName = stringField(accountRecord, Account.Name);
        if (String.isBlank(username) || String.isBlank(accountName)) {
            return null;
        }

        CompanyIntelligenceRequest request = new CompanyIntelligenceRequest();
        request.username = username;
        request.companyName = accountName;

        String website = stringField(accountRecord, Account.Website);
        if (String.isNotBlank(website)) {
            request.companyUrl = website;
        }

        String address = buildAddress(accountRecord);
        if (String.isNotBlank(address)) {
            request.address = address;
        }

        AdditionalContext additionalContext = new AdditionalContext();
        additionalContext.industry = stringField(
            accountRecord,
            Account.Industry
        );
        additionalContext.opportunityType = stringField(
            opportunityRecord,
            Opportunity.Type
        );
        if (
            String.isNotBlank(additionalContext.industry) ||
            String.isNotBlank(additionalContext.opportunityType)
        ) {
            request.additionalContext = additionalContext;
        }

        return request;
    }

    private static String buildAddress(Account accountRecord) {
        List<String> addressParts = new List<String>();
        for (
            Schema.SObjectField field : new List<Schema.SObjectField> {
                Account.BillingStreet,
                Account.BillingCity,
                Account.BillingState,
                Account.BillingPostalCode,
                Account.BillingCountry
            }
        ) {
            String value = stringField(accountRecord, field);
            if (String.isNotBlank(value)) {
                addressParts.add(value.trim());
            }
        }
        return String.join(addressParts, ', ');
    }

    @TestVisible
    private static Map<String, Object> toServicePayload(
        CompanyIntelligenceRequest request
    ) {
        Map<String, Object> payload = new Map<String, Object> {
            'username' => request.username,
            'company_name' => request.companyName
        };
        if (String.isNotBlank(request.companyUrl)) {
            payload.put('company_url', request.companyUrl);
        }
        if (String.isNotBlank(request.address)) {
            payload.put('address', request.address);
        }
        if (request.additionalContext != null) {
            Map<String, Object> additionalContext = new Map<String, Object>();
            if (String.isNotBlank(request.additionalContext.industry)) {
                additionalContext.put(
                    'industry',
                    request.additionalContext.industry
                );
            }
            if (String.isNotBlank(request.additionalContext.opportunityType)) {
                additionalContext.put(
                    'opportunity_type',
                    request.additionalContext.opportunityType
                );
            }
            if (!additionalContext.isEmpty()) {
                payload.put('additional_context', additionalContext);
            }
        }
        return payload;
    }

    @TestVisible
    private static CompanyIntelligenceResult executeRequest(
        CompanyIntelligenceRequest request,
        AuthContext authContext
    ) {
        if (
            authContext == null ||
            String.isBlank(authContext.endpoint) ||
            String.isBlank(authContext.idToken)
        ) {
            return failure(INTERNAL_FAILURE_STATUS);
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(buildEndpoint(authContext.endpoint));
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Authorization', 'Bearer ' + authContext.idToken);
        httpRequest.setBody(JSON.serialize(toServicePayload(request)));
        httpRequest.setTimeout(CALLOUT_TIMEOUT_MS);

        HttpResponse httpResponse = new Http().send(httpRequest);
        if (httpResponse.getStatusCode() != SUCCESS_STATUS) {
            return failure(normalizeStatus(httpResponse.getStatusCode()));
        }
        return parseResponse(httpResponse.getBody());
    }

    @TestVisible
    private static String buildEndpoint(String configuredEndpoint) {
        String endpoint = configuredEndpoint.trim();
        Integer apiPathIndex = endpoint.toLowerCase().indexOf('/api/v1/');
        if (apiPathIndex >= 0) {
            endpoint = endpoint.substring(0, apiPathIndex);
        }
        while (endpoint.endsWith('/')) {
            endpoint = endpoint.left(endpoint.length() - 1);
        }
        return endpoint + ENDPOINT_PATH;
    }

    @TestVisible
    private static CompanyIntelligenceResult parseResponse(
        String responseBody
    ) {
        if (String.isBlank(responseBody)) {
            return failure(INTERNAL_FAILURE_STATUS);
        }

        try {
            Object rawResponse = JSON.deserializeUntyped(responseBody);
            if (!(rawResponse instanceof Map<String, Object>)) {
                return failure(INTERNAL_FAILURE_STATUS);
            }

            Map<String, Object> envelope = (Map<String, Object>) rawResponse;
            Integer serviceStatus = integerValue(envelope.get('statusCode'));
            if (serviceStatus != SUCCESS_STATUS) {
                return failure(normalizeStatus(serviceStatus));
            }

            Object rawBody = envelope.get('body');
            if (!(rawBody instanceof Map<String, Object>)) {
                return failure(INTERNAL_FAILURE_STATUS);
            }

            Map<String, Object> body = (Map<String, Object>) rawBody;
            Object rawIntelligence = body.get('company_intelligence');
            if (!(rawIntelligence instanceof Map<String, Object>)) {
                return failure(INTERNAL_FAILURE_STATUS);
            }

            CompanyIntelligenceResult result = new CompanyIntelligenceResult();
            result.success = true;
            result.statusCode = SUCCESS_STATUS;
            result.intelligence = toFrontendIntelligence(
                (Map<String, Object>) rawIntelligence
            );
            return result;
        } catch (Exception ignored) {
            return failure(INTERNAL_FAILURE_STATUS);
        }
    }

    private static CompanyIntelligence toFrontendIntelligence(
        Map<String, Object> serviceIntelligence
    ) {
        CompanyIntelligence intelligence = new CompanyIntelligence();
        intelligence.sources = new List<Source>();
        for (Object sourceValue : objectList(serviceIntelligence.get('sources'))) {
            Map<String, Object> serviceSource = objectMap(sourceValue);
            Source source = new Source();
            source.index = integerValue(serviceSource.get('index'));
            source.displayLabel = stringValue(
                serviceSource.get('display_label')
            );
            source.title = stringValue(serviceSource.get('title'));
            source.url = stringValue(serviceSource.get('url'));
            source.domain = stringValue(serviceSource.get('domain'));
            intelligence.sources.add(source);
        }

        intelligence.derivedInformation = new List<DerivedInformation>();
        for (
            Object derivedValue : objectList(
                serviceIntelligence.get('derived_information')
            )
        ) {
            Map<String, Object> serviceDerived = objectMap(derivedValue);
            DerivedInformation derived = new DerivedInformation();
            derived.text = stringValue(serviceDerived.get('text'));
            derived.sourceIndices = integerList(
                serviceDerived.get('source_indices')
            );
            intelligence.derivedInformation.add(derived);
        }

        intelligence.webSearchQueries = stringList(
            serviceIntelligence.get('web_search_queries')
        );
        intelligence.summary = toFrontendSummary(
            objectMap(serviceIntelligence.get('summary'))
        );
        intelligence.searchEntryPoint = new SearchEntryPoint();
        Map<String, Object> searchEntryPoint = objectMap(
            serviceIntelligence.get('search_entry_point')
        );
        intelligence.searchEntryPoint.renderedContent = stringValue(
            searchEntryPoint.get('rendered_content')
        );
        return intelligence;
    }

    private static CompanySummary toFrontendSummary(
        Map<String, Object> serviceSummary
    ) {
        CompanySummary summary = new CompanySummary();
        if (serviceSummary.isEmpty()) {
            return summary;
        }
        summary.companySnapshot = stringList(
            serviceSummary.get('company_snapshot')
        );
        summary.latestCompanyAnnouncements = stringList(
            serviceSummary.get('latest_company_announcements')
        );
        summary.executiveLeadershipAnnouncements = stringList(
            serviceSummary.get('executive_leadership_announcements')
        );
        summary.businessAndFinancialSignals = stringList(
            serviceSummary.get('business_and_financial_signals')
        );
        summary.competitiveAndMarketContext = stringList(
            serviceSummary.get('competitive_and_market_context')
        );
        summary.opportunityRelevance = stringList(
            serviceSummary.get('opportunity_relevance')
        );
        summary.informationGaps = stringList(
            serviceSummary.get('information_gaps')
        );
        return summary;
    }

    private static List<Object> objectList(Object value) {
        return value instanceof List<Object>
            ? (List<Object>) value
            : new List<Object>();
    }

    private static Map<String, Object> objectMap(Object value) {
        return value instanceof Map<String, Object>
            ? (Map<String, Object>) value
            : new Map<String, Object>();
    }

    private static List<String> stringList(Object value) {
        List<String> strings = new List<String>();
        for (Object item : objectList(value)) {
            String text = stringValue(item);
            if (String.isNotBlank(text)) {
                strings.add(text);
            }
        }
        return strings;
    }

    private static List<Integer> integerList(Object value) {
        List<Integer> integers = new List<Integer>();
        for (Object item : objectList(value)) {
            Integer integerItem = integerValue(item);
            if (integerItem != null) {
                integers.add(integerItem);
            }
        }
        return integers;
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Integer integerValue(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception ignored) {
            return null;
        }
    }

    private static Integer normalizeStatus(Integer statusCode) {
        Set<Integer> supportedStatuses = new Set<Integer> {
            INVALID_REQUEST_STATUS,
            REQUEST_TOO_LARGE_STATUS,
            NO_RELIABLE_INFORMATION_STATUS,
            RATE_LIMIT_STATUS,
            INTERNAL_FAILURE_STATUS
        };
        return supportedStatuses.contains(statusCode)
            ? statusCode
            : INTERNAL_FAILURE_STATUS;
    }

    private static CompanyIntelligenceResult failure(Integer statusCode) {
        CompanyIntelligenceResult result = new CompanyIntelligenceResult();
        result.success = false;
        result.statusCode = statusCode;
        result.message = messageForStatus(statusCode);
        return result;
    }

    private static String messageForStatus(Integer statusCode) {
        if (statusCode == INVALID_REQUEST_STATUS) {
            return Label.CompanyIntelligenceInvalidAccount;
        }
        if (statusCode == REQUEST_TOO_LARGE_STATUS) {
            return Label.CompanyIntelligenceRequestTooLarge;
        }
        if (statusCode == NO_RELIABLE_INFORMATION_STATUS) {
            return Label.CompanyIntelligenceNoReliableInformation;
        }
        if (statusCode == RATE_LIMIT_STATUS) {
            return Label.CompanyIntelligenceRateLimited;
        }
        return Label.CompanyIntelligenceTemporaryFailure;
    }

    private static List<SObject> stripReadable(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new List<SObject>();
        }
        return System.Security.stripInaccessible(
                System.AccessType.READABLE,
                records,
                false
            )
            .getRecords();
    }

    private static String stringField(
        SObject record,
        Schema.SObjectField field
    ) {
        if (record == null || field == null) {
            return null;
        }
        Object value = record.getPopulatedFieldsAsMap()
            .get(field.getDescribe().getName());
        return value == null ? null : String.valueOf(value).trim();
    }

    public virtual class AuthProvider {
        public virtual AuthContext authenticate() {
            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(
                AUTH_CONFIG_NAME
            );
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(
                jwt,
                config.identityTokenUrl
            );
            return new AuthContext(config.cloudRunEndpoint, idToken);
        }
    }

    public class AuthContext {
        public String endpoint;
        public String idToken;

        public AuthContext(String endpoint, String idToken) {
            this.endpoint = endpoint;
            this.idToken = idToken;
        }
    }

    public class CompanyIntelligenceRequest {
        public String username;
        public String companyName;
        public String companyUrl;
        public String address;
        public AdditionalContext additionalContext;
    }

    public class AdditionalContext {
        public String industry;
        public String opportunityType;
    }

    public class CompanyIntelligenceResult {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public Integer statusCode { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public CompanyIntelligence intelligence { get; set; }
    }

    public class CompanyIntelligence {
        @AuraEnabled
        public List<Source> sources { get; set; }
        @AuraEnabled
        public List<DerivedInformation> derivedInformation { get; set; }
        @AuraEnabled
        public List<String> webSearchQueries { get; set; }
        @AuraEnabled
        public CompanySummary summary { get; set; }
        @AuraEnabled
        public SearchEntryPoint searchEntryPoint { get; set; }
    }

    public class Source {
        @AuraEnabled
        public Integer index { get; set; }
        @AuraEnabled
        public String displayLabel { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String url { get; set; }
        @AuraEnabled
        public String domain { get; set; }
    }

    public class DerivedInformation {
        @AuraEnabled
        public String text { get; set; }
        @AuraEnabled
        public List<Integer> sourceIndices { get; set; }
    }

    public class CompanySummary {
        @AuraEnabled
        public List<String> companySnapshot { get; set; }
        @AuraEnabled
        public List<String> latestCompanyAnnouncements { get; set; }
        @AuraEnabled
        public List<String> executiveLeadershipAnnouncements { get; set; }
        @AuraEnabled
        public List<String> businessAndFinancialSignals { get; set; }
        @AuraEnabled
        public List<String> competitiveAndMarketContext { get; set; }
        @AuraEnabled
        public List<String> opportunityRelevance { get; set; }
        @AuraEnabled
        public List<String> informationGaps { get; set; }
    }

    public class SearchEntryPoint {
        @AuraEnabled
        public String renderedContent { get; set; }
    }
}
