/*
 * Covers GCPAuthUtil: loadConfig endpoint selection (each mode must read its own
 * GCP_Endpoint_Settings__c field, and a blank endpoint must fail instead of falling back),
 * the signed JWT, and the identity-token exchange.
 */
@IsTest
private class Test_GCPAuthUtil {
  private static final String SERVICE_HOST = 'https://service.example.invalid';
  private static final String TOKEN_URL = SERVICE_HOST + '/token';
  private static final String SERVICE_ACCOUNT = 'service@example.invalid';
  private static final String SIMILAR_CASES_ENDPOINT =
    SERVICE_HOST + '/api/v1/similar_cases';
  private static final String OPPORTUNITY_SUMMARY_ENDPOINT =
    SERVICE_HOST + '/api/v1/opportunity_summary';
  private static final String ACCOUNT_SUMMARY_ENDPOINT =
    SERVICE_HOST + '/api/v1/account_summary';
  // Signing certificate configured in GCP_Endpoint_Settings__c and used by the other GCP callout tests.
  private static final String SIGNING_CERTIFICATE = 'privatekey';
  private static final String ID_TOKEN = 'identity-token';
  private static final String SIGNED_JWT = 'header.claims.signature';

  // Each loadConfig mode and the settings field it must read.
  private static final Map<String, Schema.SObjectField> MODE_TO_ENDPOINT_FIELD = new Map<String, Schema.SObjectField>{
    'knowledge' => GCP_Endpoint_Settings__c.Article_Cloud_Run_Endpoint__c,
    'caseComments' => GCP_Endpoint_Settings__c.Case_Comment_Cloud_Run_Endpoint__c,
    'caseEmails' => GCP_Endpoint_Settings__c.Case_Emails_Cloud_Run_Endpoint__c,
    GCPAuthUtil.JIRA_COMMENT_SUMMARY => GCP_Endpoint_Settings__c.Jira_Comment_Summary_Endpoint__c,
    GCPAuthUtil.CHAT_TRANSCRIPT_SUMMARY => GCP_Endpoint_Settings__c.Chat_Transcript_Summary_Endpoint__c,
    GCPAuthUtil.ESCALATION_SENTIMENT => GCP_Endpoint_Settings__c.Escalation_Sentiment_Endpoint__c,
    GCPAuthUtil.AGENT_DASHBOARD => GCP_Endpoint_Settings__c.Agent_Dashboard_Endpoint__c,
    GCPAuthUtil.FEED_SUMMARY => GCP_Endpoint_Settings__c.Feed_Summary_Endpoint__c,
    GCPAuthUtil.RED_ACCOUNT_SUMMARY => GCP_Endpoint_Settings__c.Red_Account_Summary_Endpoint__c,
    GCPAuthUtil.NEXT_STEPS => GCP_Endpoint_Settings__c.Next_Steps_Endpoint__c,
    GCPAuthUtil.RED_ACCOUNT_AI_FIELDS => GCP_Endpoint_Settings__c.Red_Account_AI_Endpoint__c,
    GCPAuthUtil.RED_ACCOUNT_PICKLIST_BQ => GCP_Endpoint_Settings__c.Red_Account_Picklist_BQ_Endpoint__c
  };

  @TestSetup
  static void testData() {
    SObjectBuilder settings = new SObjectBuilder(
        GCP_Endpoint_Settings__c.SObjectType
      )
      .setField(
        GCP_Endpoint_Settings__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(
        GCP_Endpoint_Settings__c.Service_Account_Email__c,
        SERVICE_ACCOUNT
      )
      .setField(GCP_Endpoint_Settings__c.Identity_Token_URL__c, TOKEN_URL)
      .setField(
        GCP_Endpoint_Settings__c.Certificate_Name__c,
        'test_certificate'
      )
      .setField(
        GCP_Endpoint_Settings__c.Cloud_Run_Endpoint__c,
        SIMILAR_CASES_ENDPOINT
      )
      .setField(
        GCP_Endpoint_Settings__c.Opportunity_Summary_Endpoint__c,
        OPPORTUNITY_SUMMARY_ENDPOINT
      )
      .setField(
        GCP_Endpoint_Settings__c.Account_Summary_Endpoint__c,
        ACCOUNT_SUMMARY_ENDPOINT
      );
    for (String mode : MODE_TO_ENDPOINT_FIELD.keySet()) {
      settings.setField(MODE_TO_ENDPOINT_FIELD.get(mode), endpointFor(mode));
    }
    settings.create();
  }

  private static String endpointFor(String mode) {
    return SERVICE_HOST + '/' + mode.deleteWhitespace();
  }

  @IsTest
  static void shouldUseAccountSummaryEndpointWhenModeIsAccountSummary() {
    Test.startTest();
    GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(
      GCPAuthUtil.ACCOUNT_SUMMARY
    );
    Test.stopTest();

    String endpointMessage = 'Account Summary must read Account_Summary_Endpoint__c.';
    String audienceMessage = 'The token audience must be the Account Summary endpoint.';
    Assert.areEqual(
      ACCOUNT_SUMMARY_ENDPOINT,
      config.cloudRunEndpoint,
      endpointMessage
    );
    Assert.areEqual(ACCOUNT_SUMMARY_ENDPOINT, config.audience, audienceMessage);
  }

  @IsTest
  static void shouldMatchAccountSummaryModeWhenCaseAndSpacingDiffer() {
    Test.startTest();
    GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig('  ACCOUNTSUMMARY ');
    Test.stopTest();

    String modeMessage = 'Mode matching must ignore case and surrounding spaces.';
    Assert.areEqual(
      ACCOUNT_SUMMARY_ENDPOINT,
      config.cloudRunEndpoint,
      modeMessage
    );
  }

  @IsTest
  static void shouldKeepOpportunitySummaryEndpointWhenModeIsOpportunitySummary() {
    Test.startTest();
    GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(
      GCPAuthUtil.OPPORTUNITY_SUMMARY
    );
    Test.stopTest();

    String endpointMessage = 'Opportunity Summary must keep reading Opportunity_Summary_Endpoint__c.';
    Assert.areEqual(
      OPPORTUNITY_SUMMARY_ENDPOINT,
      config.cloudRunEndpoint,
      endpointMessage
    );
  }

  @IsTest
  static void shouldUseSimilarCasesEndpointWhenModeIsUnknown() {
    Test.startTest();
    GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig('similar');
    Test.stopTest();

    String defaultMessage = 'Unknown modes must keep the Similar Cases default.';
    Assert.areEqual(
      SIMILAR_CASES_ENDPOINT,
      config.cloudRunEndpoint,
      defaultMessage
    );
  }

  @IsTest
  static void shouldThrowWhenAccountSummaryEndpointIsBlank() {
    GCP_Endpoint_Settings__c settings = GCP_Endpoint_Settings__c.getOrgDefaults();
    settings.Account_Summary_Endpoint__c = null;
    update settings;
    Boolean isThrown = false;

    Test.startTest();
    try {
      GCPAuthUtil.loadConfig(GCPAuthUtil.ACCOUNT_SUMMARY);
    } catch (GCPAuthUtil.GCPCalloutException e) {
      isThrown = true;
    }
    Test.stopTest();

    String blankMessage = 'A blank Account Summary endpoint must fail instead of using another endpoint.';
    Assert.isTrue(isThrown, blankMessage);
  }

  @IsTest
  static void shouldReadEachModeEndpointWhenModeIsRequested() {
    Map<String, GCPAuthUtil.GCPConfig> modeToConfig = new Map<String, GCPAuthUtil.GCPConfig>();

    Test.startTest();
    for (String mode : MODE_TO_ENDPOINT_FIELD.keySet()) {
      modeToConfig.put(mode, GCPAuthUtil.loadConfig(mode));
    }
    Test.stopTest();

    for (String mode : MODE_TO_ENDPOINT_FIELD.keySet()) {
      String endpointMessage =
        'Mode ' +
        mode +
        ' must read its own endpoint field.';
      String audienceMessage =
        'Mode ' +
        mode +
        ' must use its endpoint as the token audience.';
      GCPAuthUtil.GCPConfig config = modeToConfig.get(mode);
      Assert.areEqual(
        endpointFor(mode),
        config.cloudRunEndpoint,
        endpointMessage
      );
      Assert.areEqual(endpointFor(mode), config.audience, audienceMessage);
    }
  }

  @IsTest
  static void shouldCarryServiceAccountSettingsWhenConfigLoads() {
    Test.startTest();
    GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig(null);
    Test.stopTest();

    String accountMessage = 'The service account must come from the settings.';
    String tokenUrlMessage = 'The identity token URL must come from the settings.';
    String defaultMessage = 'A missing mode must use the Similar Cases default.';
    Assert.areEqual(
      SERVICE_ACCOUNT,
      config.serviceAccountEmail,
      accountMessage
    );
    Assert.areEqual(TOKEN_URL, config.identityTokenUrl, tokenUrlMessage);
    Assert.areEqual(
      SIMILAR_CASES_ENDPOINT,
      config.cloudRunEndpoint,
      defaultMessage
    );
  }

  @IsTest
  static void shouldSignJwtForTargetAudienceWhenCertificateIsConfigured() {
    GCPAuthUtil.GCPConfig config = new GCPAuthUtil.GCPConfig();
    config.serviceAccountEmail = SERVICE_ACCOUNT;
    config.identityTokenUrl = TOKEN_URL;
    config.audience = ACCOUNT_SUMMARY_ENDPOINT;
    config.certificate = SIGNING_CERTIFICATE;

    Test.startTest();
    String jwt = GCPAuthUtil.createSignedJWT(config);
    Test.stopTest();

    List<String> parts = jwt.split('\\.');
    Map<String, Object> claims = (Map<String, Object>) JSON.deserializeUntyped(
      base64UrlDecode(parts[1])
    );
    String partsMessage = 'A JWT must have a header, claims and signature.';
    String urlSafeMessage = 'JWT segments must be base64url encoded without padding.';
    String audienceMessage = 'The JWT must target the configured Cloud Run audience.';
    String issuerMessage = 'The service account must issue the JWT.';
    String tokenUrlMessage = 'The JWT audience must be the identity token URL.';
    String expiryMessage = 'The JWT must expire one hour after it is issued.';
    Assert.areEqual(3, parts.size(), partsMessage);
    Assert.isFalse(
      jwt.contains('=') || jwt.contains('+') || jwt.contains('/'),
      urlSafeMessage
    );
    Assert.areEqual(
      ACCOUNT_SUMMARY_ENDPOINT,
      claims.get('target_audience'),
      audienceMessage
    );
    Assert.areEqual(SERVICE_ACCOUNT, claims.get('iss'), issuerMessage);
    Assert.areEqual(TOKEN_URL, claims.get('aud'), tokenUrlMessage);
    Long issuedAt = Long.valueOf(String.valueOf(claims.get('iat')));
    Long expiresAt = Long.valueOf(String.valueOf(claims.get('exp')));
    Assert.areEqual(3600, expiresAt - issuedAt, expiryMessage);
  }

  @IsTest
  static void shouldReturnIdTokenWhenTokenEndpointAccepts() {
    Test.setMock(
      HttpCalloutMock.class,
      new TokenEndpointMock(
        200,
        JSON.serialize(new Map<String, Object>{ 'id_token' => ID_TOKEN })
      )
    );

    Test.startTest();
    String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(
      SIGNED_JWT,
      TOKEN_URL
    );
    Test.stopTest();

    String tokenMessage = 'The id_token from the token endpoint must be returned.';
    Assert.areEqual(ID_TOKEN, idToken, tokenMessage);
  }

  @IsTest
  static void shouldThrowWhenTokenResponseHasNoIdToken() {
    Test.setMock(
      HttpCalloutMock.class,
      new TokenEndpointMock(
        200,
        JSON.serialize(new Map<String, Object>{ 'access_token' => ID_TOKEN })
      )
    );
    Boolean isThrown = false;

    Test.startTest();
    try {
      GCPAuthUtil.exchangeJWTForIdentityToken(SIGNED_JWT, TOKEN_URL);
    } catch (CalloutException e) {
      isThrown = true;
    }
    Test.stopTest();

    String missingTokenMessage = 'A token response without id_token must fail.';
    Assert.isTrue(isThrown, missingTokenMessage);
  }

  @IsTest
  static void shouldThrowWhenTokenEndpointRejects() {
    Test.setMock(
      HttpCalloutMock.class,
      new TokenEndpointMock(401, '{"error":"invalid_grant"}')
    );
    String errorMessage;

    Test.startTest();
    try {
      GCPAuthUtil.exchangeJWTForIdentityToken(SIGNED_JWT, TOKEN_URL);
    } catch (CalloutException e) {
      errorMessage = e.getMessage();
    }
    Test.stopTest();

    String rejectedMessage = 'A rejected token request must fail with its status code.';
    Assert.isNotNull(errorMessage, rejectedMessage);
    Assert.isTrue(errorMessage.contains('401'), rejectedMessage);
  }

  private static String base64UrlDecode(String segment) {
    String base64 = segment.replace('-', '+').replace('_', '/');
    while (Math.mod(base64.length(), 4) != 0) {
      base64 += '=';
    }
    return EncodingUtil.base64Decode(base64).toString();
  }

  private class TokenEndpointMock implements HttpCalloutMock {
    private Integer statusCode;
    private String body;

    private TokenEndpointMock(Integer statusCode, String body) {
      this.statusCode = statusCode;
      this.body = body;
    }

    public HttpResponse respond(HttpRequest request) {
      String endpointMessage = 'The JWT must be posted to the identity token URL.';
      String grantMessage = 'The request must use the JWT bearer grant with the signed JWT.';
      Assert.areEqual(TOKEN_URL, request.getEndpoint(), endpointMessage);
      Assert.areEqual('POST', request.getMethod(), endpointMessage);
      Assert.isTrue(
        request.getBody()
          .contains('assertion=' + EncodingUtil.urlEncode(SIGNED_JWT, 'UTF-8')),
        grantMessage
      );
      HttpResponse response = new HttpResponse();
      response.setStatusCode(statusCode);
      response.setBody(body);
      return response;
    }
  }
}
