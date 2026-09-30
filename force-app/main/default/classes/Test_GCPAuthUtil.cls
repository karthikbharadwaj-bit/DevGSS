/*
 * Covers GCPAuthUtil.loadConfig endpoint selection: each mode must read its own
 * GCP_Endpoint_Settings__c field, and a blank endpoint must fail instead of falling back.
 */
@IsTest
private class Test_GCPAuthUtil {
  private static final String SERVICE_HOST = 'https://service.example.invalid';
  private static final String SIMILAR_CASES_ENDPOINT =
    SERVICE_HOST + '/api/v1/similar_cases';
  private static final String OPPORTUNITY_SUMMARY_ENDPOINT =
    SERVICE_HOST + '/api/v1/opportunity_summary';
  private static final String ACCOUNT_SUMMARY_ENDPOINT =
    SERVICE_HOST + '/api/v1/account_summary';

  @TestSetup
  static void testData() {
    new SObjectBuilder(GCP_Endpoint_Settings__c.SObjectType)
      .setField(
        GCP_Endpoint_Settings__c.SetupOwnerId,
        UserInfo.getOrganizationId()
      )
      .setField(
        GCP_Endpoint_Settings__c.Service_Account_Email__c,
        'service@example.invalid'
      )
      .setField(
        GCP_Endpoint_Settings__c.Identity_Token_URL__c,
        SERVICE_HOST + '/token'
      )
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
      )
      .create();
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
}
