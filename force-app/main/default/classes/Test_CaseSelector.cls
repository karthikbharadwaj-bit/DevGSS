@isTest
private class Test_CaseSelector {
  //Account fields defined
  private static final String ACCOUNT_NAME = 'Test';
  private static final String ACCOINT_BILLING_ID = '12345';

  //Contact fields defined
  private static final String CONTACT_FIRST_NAME = 'Test1';
  private static final String CONTACT_LAST_NAME = 'Test1';
  private static final String CONTACT_EMAIL = 'test@test.com';
  private static final String CONTACT_PHONE = '1234567890';
  private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

  //Opportunity fields defined
  private static final String OPPORTUNITY_NAME = 'TestOpportunity';
  private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
  private static final String OPPORTUNITY_TIER_NAME = 'Office';
  private static final String OPPORTUNITY_STAGE_NAME = '1. Qualify';
  private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

  //Case fields defined
  private static final String CASE_BRAND_NAME = 'Test Brand';

  public static final String ARTICLE_TITLE = 'Test Article title';
  public static final String ARTICLE_URLNAME = 'Test-Article-unique-url';
  public static final String ARTICLE_SUMMARY = 'Test Article summary';
  public static final String ARTICLE_DETAILS = 'Test Article details';
  public static final String ARTICLE_LANGUAGE = 'en_US';

  public static final IValueProvider emailProvider = ValueProviderBuilder.provideUniqueEmail(
    'Test_KnowledgeArticleService_UserName'
  );

  public static final String ADMIN_USERNAME = (String) emailProvider.getValue();
  public static final String READER_USERNAME = (String) emailProvider.getValue();
  public static final String CANDIDATE_USERNAME = (String) emailProvider.getValue();
  public static final String CONTRIBUTOR_USERNAME = (String) emailProvider.getValue();
  public static final String PUBLISHER_USERNAME = (String) emailProvider.getValue();
  public static final String COACH_USERNAME = (String) emailProvider.getValue();
  public static final String EXPERT_USERNAME = (String) emailProvider.getValue();
  public static final String NOT_KNOWLEDGE_USER_USERNAME = (String) emailProvider.getValue();

  public static final String ADMIN_USER_PROFILE_NAME = 'System Administrator';
  public static final String USER_LANGUAGE = 'en_US';
  public static final String OVERALL_EMAIL = 'kcs@kcs.com';

  //Assert messages defined
  private static final String ASSERT_MESSAGE = 'Cases should be selected';
  private static final String ASSERT_EQUALS_MESSAGE = 'Wrong case selected';
  private static final String ASSERT_FIELD_MESSAGE = 'Fields should be selected';

  @testSetup
  private static void testData() {
    Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Account.Name => ACCOUNT_NAME,
          Account.Billing_ID__c => ACCOINT_BILLING_ID
        }
      )
      .create()
      .getRecord();

    Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Contact.FirstName => CONTACT_FIRST_NAME,
          Contact.LastName => CONTACT_LAST_NAME,
          Contact.AccountId => testAcc.Id,
          Contact.Email => CONTACT_EMAIL,
          Contact.Phone => CONTACT_PHONE,
          Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE
        }
      )
      .create()
      .getRecord();
    Test.StartTest();
    Opportunity testOpp = (Opportunity) new SobjectBuilder(
        Opportunity.SObjectType
      )
      .setFields(
        new Map<SObjectField, Object>{
          Opportunity.AccountId => testAcc.Id,
          Opportunity.Name => OPPORTUNITY_NAME,
          Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
          Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
          Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
          Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
        }
      )
      .create()
      .getRecord();

    Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
          Case.Status => CaseHelper.CASE_STATUS_NEW,
          Case.AccountId => testAcc.Id,
          Case.ContactId => testContact.Id,
          Case.Opportunity_Reference__c => testOpp.Id,
          Case.Account_Brand__c => CASE_BRAND_NAME
        }
      )
      .create()
      .getRecord();
    Test.StopTest();
  }

  @isTest
  private static void testSelectCases() {
    List<Case> cases = (List<Case>) new CaseSelector(true, true)
      .selectCases()
      .executeQuery();

    System.assert(cases.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesForApproval() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> casesForApproval = (List<Case>) new CaseSelector()
      .selectCasesForApproval(new List<Object>{ new Set<Id>{ cases[0].Id } })
      .executeQuery();

    System.assert(cases.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesDefault() {
    List<Case> casesDefault = (List<Case>) new CaseSelector()
      .selectCasesDefault()
      .executeQuery();

    System.assert(casesDefault.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesDefaultDetailed() {
    List<Case> casesDefaultDetailed = (List<Case>) new CaseSelector()
      .selectCasesDefaultDetailed(new List<Object>{})
      .executeQuery();

    System.assert(casesDefaultDetailed.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesByStatus() {
    List<Case> casesByStatus = (List<Case>) new CaseSelector()
      .selectCasesByStatus(new List<Object>{ CaseHelper.CASE_STATUS_NEW })
      .executeQuery();

    System.assert(casesByStatus.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesForSCPreview() {
    List<Contact> contacts = (List<Contact>) new ContactSelector()
      .selectContacts()
      .executeQuery();

    List<Case> casesForSCPreview = (List<Case>) new CaseSelector()
      .selectCasesForSCPreview(
        new List<Object>{
          new List<String>{ CaseHelper.CASE_STATUS_CLOSED },
          contacts[0].AccountId,
          contacts[0].Id
        }
      )
      .executeQuery();

    System.assert(casesForSCPreview.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesForAPI() {
    List<Contact> contacts = (List<Contact>) new ContactSelector()
      .selectContacts()
      .executeQuery();

    List<Case> casesForAPI = (List<Case>) new CaseSelector()
      .selectCasesForAPI(
        new CaseListAPIController.FieldAndValueToSearch(null, null),
        new List<Object>{
          contacts[0].AccountId,
          new List<String>{ CaseHelper.RT_NAME_PORTING_OUT },
          contacts[0].Id
        },
        null
      )
      .executeQuery();

    List<Case> casesForAPINotNullWithSecondBind = (List<Case>) new CaseSelector()
      .selectCasesForAPI(
        new CaseListAPIController.FieldAndValueToSearch(
          'Account_Brand__c',
          CASE_BRAND_NAME
        ),
        new List<Object>{
          contacts[0].AccountId,
          new List<String>{ CaseHelper.RT_NAME_PORTING_OUT }
        },
        null
      )
      .executeQuery();

    List<Case> casesForAPINotNullWithThirdBind = (List<Case>) new CaseSelector()
      .selectCasesForAPI(
        new CaseListAPIController.FieldAndValueToSearch(
          'Account_Brand__c',
          CASE_BRAND_NAME
        ),
        new List<Object>{
          contacts[0].AccountId,
          new List<String>{ CaseHelper.RT_NAME_PORTING_OUT },
          contacts[0].Id
        },
        null
      )
      .executeQuery();

    System.assert(casesForAPI.size() > 0, ASSERT_MESSAGE);
    System.assert(casesForAPINotNullWithSecondBind.size() > 0, ASSERT_MESSAGE);
    System.assert(casesForAPINotNullWithThirdBind.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesWithArticlesById() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();
    /*
        List<CaseArticle> articles = (List<CaseArticle>) new CaseSelector.CaseArticleSelector(true, true)
		    .selectArticlesDefault()
		    .executeQuery();
        */

    List<Case> casesWithArticlesById = (List<Case>) new CaseSelector()
      .selectCasesWithArticlesById(
        new List<Object>{ new Set<Id>{ cases[0].Id } }
      )
      .executeQuery();

    System.assert(casesWithArticlesById.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCaseByIdWithCommentsAttachmentsAndContactData() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> caseByIdWithCommentsAttachmentsAndContactData = (List<Case>) new CaseSelector()
      .selectCaseByIdWithCommentsAttachmentsAndContactData(
        new List<Object>{ new Set<Id>{ cases[0].Id } }
      )
      .executeQuery();

    System.assert(
      caseByIdWithCommentsAttachmentsAndContactData.size() > 0,
      ASSERT_MESSAGE
    );
  }

  @isTest
  private static void testSelectCasesIcbByNumber() {
    List<Case> casesDefaultDetailed = (List<Case>) new CaseSelector()
      .selectCasesDefaultDetailed(new List<Object>{})
      .executeQuery();

    List<Case> casesIcbByNumber = (List<Case>) new CaseSelector()
      .selectCasesIcbByNumber(
        new List<String>{ casesDefaultDetailed[0].CaseNumber }
      )
      .executeQuery();

    System.assert(casesIcbByNumber.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectInContactCasesForOpportunities() {
    List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
      .selectOpportunities()
      .executeQuery();

    List<Case> inContactCasesForOpportunities = (List<Case>) new CaseSelector()
      .selectInContactCasesForOpportunities(
        new List<String>{ opportunities[0].Id }
      )
      .executeQuery();

    System.assert(inContactCasesForOpportunities.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesByIds() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> casesByIds = (List<Case>) new CaseSelector()
      .selectCasesByIds(new Set<Id>{ cases[0].Id })
      .executeQuery();

    System.assert(casesByIds.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCaseForEscalating() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> caseForEscalating = (List<Case>) new CaseSelector()
      .selectCaseForEscalating(new List<Object>{ new Set<Id>{ cases[0].Id } })
      .executeQuery();

    System.assert(caseForEscalating.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCaseForReopening() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> caseForReopening = (List<Case>) new CaseSelector()
      .selectCaseForReopening(new List<Object>{ new Set<Id>{ cases[0].Id } })
      .executeQuery();

    System.assert(caseForReopening.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testGetFieldList() {
    CaseSelector.CaseArticleSelector caObject = new CaseSelector.CaseArticleSelector(
      true,
      true
    );
    List<Schema.SObjectField> defaultFieldList = caObject.getDefaultFieldList();

    System.assert(defaultFieldList.size() > 0, ASSERT_FIELD_MESSAGE);
  }

  @isTest
  private static void testSelectCasesByOpportunityId() {
    List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
      .selectOpportunities()
      .executeQuery();

    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCasesByOpportunityId(
        new List<Object>{ new Set<Id>{ opportunities[0].Id } }
      )
      .executeQuery();

    System.assert(cases.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelectCasesWithOpportunity() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> reselectedCases = (List<Case>) new CaseSelector()
      .selectCasesWithOpportunity(
        new List<Object>{ new Set<Id>{ cases[0].Id } }
      )
      .executeQuery();

    System.assert(reselectedCases.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testselectCasesByIdsAndRecordTypes() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> testCases = (List<Case>) new CaseSelector()
      .selectCasesByIdsAndRecordTypes(
        new List<Object>{
          new Set<Id>{ cases[0].Id },
          new Set<String>{ CaseHelper.RT_ID_PORTING_OUT }
        }
      )
      .executeQuery();

    System.assert(testCases.size() > 0, ASSERT_MESSAGE);
  }

  @isTest
  private static void testSelecCaseByRecordTypeNameAndStatus() {
    List<Case> cases = (List<Case>) new CaseSelector()
      .selectCases()
      .executeQuery();

    List<Case> casesByRecordTypeNameAndStatus = (List<Case>) new CaseSelector()
      .selecCaseByRecordTypeNameAndStatus(
        new List<Object>{
          new List<String>{ CaseHelper.CASE_STATUS_NEW },
          new List<String>{ CaseHelper.RT_NAME_PORTING_OUT }
        }
      )
      .executeQuery();

    System.assert(!casesByRecordTypeNameAndStatus.isEmpty(), ASSERT_MESSAGE);
  }

  @isTest
  private static void shouldSelectBTResponseFieldsWhenCaseIdsAreProvided() {
    Account btAccount = (Account) new SObjectBuilder(Account.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Account.Name => ValueProviderBuilder.provideUniqueString(
            'BT selector account'
          ),
          Account.RC_Brand__c => CaseHelper.BRAND_BT_BUSINESS
        }
      )
      .create()
      .getRecord();
    String contactEmail = (String) ValueProviderBuilder.provideUniqueEmail(
        'bt-selector-contact',
        '@example.com'
      )
      .getValue();
    Contact btContact = (Contact) new SObjectBuilder(Contact.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Contact.LastName => ValueProviderBuilder.provideUniqueString(
            'BT selector contact'
          ),
          Contact.Email => contactEmail,
          Contact.AccountId => btAccount.Id
        }
      )
      .create()
      .getRecord();
    Case btCase = (Case) new SObjectBuilder(Case.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
          Case.Status => CaseHelper.CASE_STATUS_NEW,
          Case.AccountId => btAccount.Id,
          Case.ContactId => btContact.Id,
          Case.Account_Brand__c => CaseHelper.BRAND_BT_BUSINESS
        }
      )
      .create()
      .getRecord();
    List<Case> expectedCases = (List<Case>) new CaseSelector()
      .selectCasesDefaultDetailed(new List<Object>{})
      .setCondition('Id IN :bind0')
      .setQueryBindings(new List<Object>{ new Set<Id>{ btCase.Id } })
      .executeQuery();
    Case expectedCase = null;
    for (Case queriedCase : expectedCases) {
      if (queriedCase.Id == btCase.Id) {
        expectedCase = queriedCase;
        break;
      }
    }
    String expectedCaseMessage = 'The BT selector fixture should be queried';
    Assert.isNotNull(expectedCase, expectedCaseMessage);
    String brandMessage = 'Brand_Account__c should be selected';
    String caseNumberMessage = 'CaseNumber should be selected';
    String recordTypeMessage = 'RecordTypeName__c should be selected';
    String contactEmailMessage = 'Contact.Email should be selected';

    Test.startTest();
    List<Case> selectedCases = (List<Case>) new CaseSelector()
      .selectCasesForBTCustomerResponseCheck(new Set<Id>{ expectedCase.Id })
      .executeQuery();
    Test.stopTest();

    Assert.areEqual(1, selectedCases.size(), ASSERT_MESSAGE);
    Assert.areEqual(
      expectedCase.Id,
      selectedCases[0].Id,
      ASSERT_EQUALS_MESSAGE
    );
    Assert.areEqual(
      CaseHelper.BRAND_BT_BUSINESS,
      selectedCases[0].Brand_Account__c,
      brandMessage
    );
    Assert.areEqual(
      expectedCase.CaseNumber,
      selectedCases[0].CaseNumber,
      caseNumberMessage
    );
    String expectedRecordTypeName = Schema.SObjectType.Case.getRecordTypeInfosById()
      .get(expectedCase.RecordTypeId)
      .getDeveloperName();
    Assert.areEqual(
      expectedRecordTypeName,
      selectedCases[0].RecordTypeName__c,
      recordTypeMessage
    );
    Assert.areEqual(
      contactEmail,
      selectedCases[0].Contact.Email,
      contactEmailMessage
    );
  }

  @isTest
  private static void shouldSelectHighlighterFieldsWhenCaseIdIsProvided() {
    Account hypercareAccount = (Account) new SObjectBuilder(Account.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Account.Name => ValueProviderBuilder.provideUniqueString(
            'Highlighter selector account'
          ),
          Account.Hyper_Care__c => true
        }
      )
      .create()
      .getRecord();
    Contact highlighterContact = (Contact) new SObjectBuilder(
        Contact.SObjectType
      )
      .setFields(
        new Map<SObjectField, Object>{
          Contact.LastName => ValueProviderBuilder.provideUniqueString(
            'Highlighter selector contact'
          ),
          Contact.AccountId => hypercareAccount.Id
        }
      )
      .create()
      .getRecord();
    Case highlighterCase = (Case) new SObjectBuilder(Case.SObjectType)
      .setFields(
        new Map<SObjectField, Object>{
          Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T2,
          Case.Status => CaseHelper.CASE_STATUS_NEW,
          Case.AccountId => hypercareAccount.Id,
          Case.ContactId => highlighterContact.Id
        }
      )
      .create()
      .getRecord();
    String accountMessage = 'AccountId should be selected';
    String recordTypeMessage = 'RecordTypeId should be selected';
    String hypercareMessage = 'Account.Hyper_Care__c should be selected';

    Test.startTest();
    List<Case> selectedCases = (List<Case>) new CaseSelector()
      .selectCaseForHighlighter(highlighterCase.Id)
      .executeQuery();
    Test.stopTest();

    Assert.areEqual(1, selectedCases.size(), ASSERT_MESSAGE);
    Assert.areEqual(
      highlighterCase.Id,
      selectedCases[0].Id,
      ASSERT_EQUALS_MESSAGE
    );
    Assert.areEqual(
      hypercareAccount.Id,
      selectedCases[0].AccountId,
      accountMessage
    );
    Assert.areEqual(
      CaseHelper.RT_ID_SUPPORT_T2,
      selectedCases[0].RecordTypeId,
      recordTypeMessage
    );
    Assert.isTrue(selectedCases[0].Account.Hyper_Care__c, hypercareMessage);
  }

  @isTest
  private static void shouldReturnNoCasesWhenHighlighterCaseIdIsUnknown() {
    Case unknownCase = new Case(
      Id = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000'
    );
    String emptyMessage = 'No case should be selected for an unknown id';

    Test.startTest();
    List<Case> selectedCases = (List<Case>) new CaseSelector()
      .selectCaseForHighlighter(unknownCase.Id)
      .executeQuery();
    Test.stopTest();

    Assert.areEqual(0, selectedCases.size(), emptyMessage);
  }

  @isTest
  private static void shouldExcludeCasesWhenIdsAreNotBound() {
    String excludedMessage = 'Only the bound case should be selected';

    Test.startTest();
    List<Case> selectedCases = (List<Case>) new CaseSelector()
      .selectCasesForBTCustomerResponseCheck(new Set<Id>{})
      .executeQuery();
    Test.stopTest();

    Assert.areEqual(0, selectedCases.size(), excludedMessage);
  }
}
