/**
 * This class contains unit tests for validating the behavior of Apex class CaseHighligher
 */
@isTest
private class CaseHighligherTest {
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
  static void myUnitTest() {
    Triggers.switchOff();
    Test_Utils tutilss = new Test_Utils();
    tutilss.initialiseTriggerBypass();
    Account objAccount1 = (Account) SmartFactory.createSObject('Account', true);
    objAccount1.RC_User_ID__c = 'RC' + Math.random();
    upsert objAccount1;
    Red_Account__c objRedAcc = (Red_Account__c) SmartFactory.createSObject(
      'Red_Account__c',
      true
    );
    objRedAcc.EscalatedAccount__c = objAccount1.id;
    objRedAcc.Status__c = 'Inprogress';
    objRedAcc.Issue_Category__c = 'Product';
    objRedAcc.Issue_Status__c = 'New';
    objRedAcc.Primary_Competitor__c = 'Comcast';
    objRedAcc.Primary_Reason_for_Red__c = 'Support Issues';
    objRedAcc.Sub_Reason_for_Red__c = 'Adoption Issues';
    upsert objRedAcc;
    Case cas1 = new Case(
      Type = 'VoIP Device Back Order',
      AccountId = objAccount1.id,
      inContact_BU_ID__c = 123
    );
    upsert cas1;
    ApexPages.StandardController controller = new ApexPages.Standardcontroller(
      cas1
    );
    CaseHighlighter objCaseHighlighter = new CaseHighlighter(controller);
    tutilss.deInitialiseTriggerBypass();
  }

  private static final String SUPPORT_T2_RECORD_TYPE = 'Support_T2';
  private static final String SUPPORT_CHAT_RECORD_TYPE = 'Support_Chat';

  // ── shouldShowHypercare_WhenAccountFlagTrue ───────────────────────────────
  @IsTest
  static void shouldShowHypercare_WhenAccountFlagTrue() {
    Case hypercareCase = createCase(true, true, SUPPORT_T2_RECORD_TYPE);

    Test.startTest();
    CaseHighlighter highlighter = new CaseHighlighter(
      new ApexPages.StandardController(hypercareCase)
    );
    Test.stopTest();

    Assert.isTrue(
      highlighter.isHypercareAccount,
      'Hypercare flag should be true for a Hypercare account'
    );
  }

  // ── shouldHideHypercare_WhenAccountFlagFalse ──────────────────────────────
  @IsTest
  static void shouldHideHypercare_WhenAccountFlagFalse() {
    Case regularCase = createCase(false, true, SUPPORT_T2_RECORD_TYPE);

    Test.startTest();
    CaseHighlighter highlighter = new CaseHighlighter(
      new ApexPages.StandardController(regularCase)
    );
    Test.stopTest();

    Assert.isFalse(
      highlighter.isHypercareAccount,
      'Hypercare flag should be false when the account is not Hypercare'
    );
  }

  // ── shouldHideHypercare_WhenCaseHasNoAccount ──────────────────────────────
  @IsTest
  static void shouldHideHypercare_WhenCaseHasNoAccount() {
    Case noAccountCase = createCase(false, false, SUPPORT_T2_RECORD_TYPE);

    Test.startTest();
    CaseHighlighter highlighter = new CaseHighlighter(
      new ApexPages.StandardController(noAccountCase)
    );
    Test.stopTest();

    Assert.isFalse(
      highlighter.isHypercareAccount,
      'Hypercare flag should be false when the case has no account'
    );
  }

  // ── shouldShowHypercare_WhenRecordTypeIsDifferent ─────────────────────────
  @IsTest
  static void shouldShowHypercare_WhenRecordTypeIsDifferent() {
    Case chatCase = createCase(true, true, SUPPORT_CHAT_RECORD_TYPE);

    Test.startTest();
    CaseHighlighter highlighter = new CaseHighlighter(
      new ApexPages.StandardController(chatCase)
    );
    Test.stopTest();

    Assert.isTrue(
      highlighter.isHypercareAccount,
      'Hypercare flag should not depend on the case record type'
    );
  }

  /**
   * Creates a case, optionally linked to an account, with the Hypercare flag set as requested.
   * Trigger bypass is applied only while the test data is created.
   */
  private static Case createCase(
    Boolean isHypercare,
    Boolean hasAccount,
    String recordTypeDeveloperName
  ) {
    Triggers.switchOff();
    Test_Utils testUtils = new Test_Utils();
    testUtils.initialiseTriggerBypass();
    RecordType caseRecordType = [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = 'Case' AND DeveloperName = :recordTypeDeveloperName
      LIMIT 1
    ];
    Case testCase = new Case(
      Type = 'VoIP Device Back Order',
      RecordTypeId = caseRecordType.Id
    );
    if (hasAccount) {
      Account testAccount = (Account) SmartFactory.createSObject(
        'Account',
        true
      );
      testAccount.RC_User_ID__c = 'RC' + Math.random();
      testAccount.Hyper_Care__c = isHypercare;
      upsert testAccount;
      testCase.AccountId = testAccount.Id;
    }
    insert testCase;
    testUtils.deInitialiseTriggerBypass();
    return testCase;
  }
}
