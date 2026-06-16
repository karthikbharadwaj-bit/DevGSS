@isTest
public with sharing class Test_UQTQuoteListController {
    private static final Set<String> RECORD_TYPE_NAMES = new Set<String> {
        QuoteHelper.RT_NAME_SALES,
        QuoteHelper.RT_NAME_POC_QUOTE,
        QuoteHelper.RT_NAME_CONTACT_CENTER,
        QuoteHelper.RT_NAME_PROSERV,
        QuoteHelper.RT_NAME_CC_PROSERV
    };

    @testSetup
  	static void setup() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        upsert new NGBS_Settings_FedRamp__c(
            BaseEndpoint__c = 'https://testfedrampapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"122"}'
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Sales Office Quote',
                    'POC Fax Quote',
                    'Engage Voice Quote',
                    'No Product Quote',
                    'No Package Info Quote'
                }),
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Object>{
                    true,
                    true,
                    false,
                    false,
                    false
                }),
                Quote.QuotePosition__c => ValueProviderBuilder.provideList(new List<Integer>{ 1, 2, 3, 4, 5 }),
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => QuoteHelper.NGBS_OFFICE_PRODUCT
                    }),
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => QuoteHelper.NGBS_FAX_PRODUCT
                    }),
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
                    }),
                    NGBSTestDataGenerator.generateQuotePackageInfo(),
                    null
                }),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_POC,
                    QuoteHelper.RT_ID_CC,
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                })
            })
            .quantity(5)
            .create()
            .getRecords();

        Triggers.switchOn();
    }

    private static User createTestUser(String profileName) {
        String uniqueUserName = 'testUser' + DateTime.now().getTime() + '@ringcentral.com.test';
        Profile p = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{profileName})
            .executeQuery()
            .get(0);

        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        return testUser;
    }

    @isTest
    static void testGetBillingAccountSuccess() {
        Account acc = new Account();
        String emptyAccString = JSON.serialize(acc);

        acc.Billing_ID__c = '123456';
        String regularAccString = JSON.serialize(acc);

        acc.RC_Account_Status__c = AccountHelper.OFFER_TYPE_POC;
        acc.Offer_Type__c = AccountHelper.OFFER_TYPE_POC;
        String accStringPOCtoPaid = JSON.serialize(acc);

        String bodyForMock = 'testBody';

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = bodyForMock;
        tstMock.code = 200;
        tstMock.status = 'Complete';

        Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();

        Response accBillingInfoEmpty = UQTQuoteListController.getBillingAccount(emptyAccString);
        Response res = UQTQuoteListController.getBillingAccount(regularAccString);
        String accBillingInfo = (String) res.data.get('accBillingInfo');
        Boolean isPOCtoPaidRegularAcc = (Boolean) res.data.get('isPOCtoPaid');
        Response resPOCtoPaid = UQTQuoteListController.getBillingAccount(accStringPOCtoPaid);
        String accBillingInfoPOCtoPaid = (String) resPOCtoPaid.data.get('accBillingInfo');
        Boolean isPOCtoPaidPOCtoPaidAcc = (Boolean) resPOCtoPaid.data.get('isPOCtoPaid');

        Test.stopTest();

        Assert.isTrue(accBillingInfoEmpty.data.isEmpty(), 'Response should return empty data map for empty Account Id value');
        Assert.areEqual(bodyForMock, accBillingInfo, 'Response should return correct body');
        Assert.isFalse(isPOCtoPaidRegularAcc, 'Response should return false value of isPOCtoPaid for regular account');
        Assert.areEqual(bodyForMock, accBillingInfoPOCtoPaid, 'Response should return correct body');
        Assert.isTrue(isPOCtoPaidPOCtoPaidAcc, 'Response should return true value of isPOCtoPaid for POC-to-Paid account');
    }

    @isTest
    static void testGetBillingAccountFailure() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Billing_ID__c => '123456'
                }
            )
            .build()
            .getRecord();
        String accString = JSON.serialize(acc);

        Boolean exceptionThrown = false;

        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = '{"responseBody":{"code":404,"message":"Object [account] not found for [id = 3120888001]"}}';
        tstMock.code = 404;
        tstMock.status = 'Not Found';

        Test.setMock(HttpCalloutMock.class, tstMock);

        try {
            Test.startTest();
            UQTQuoteListController.getBillingAccount(accString);
            Test.stopTest();
            Assert.fail();
        } catch (Exception ex) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown = ex.getMessage().contains(UQTQuoteListController.GET_ACCOUNT_FAIL);
            Assert.isTrue(expectedExceptionThrown, 'Exception should contain ' + UQTQuoteListController.GET_ACCOUNT_FAIL);
        }
        Assert.isTrue(exceptionThrown, 'expected exception should be thrown');
    }

    @isTest
    static void testPOCQuotesForRiseBrand() {
        Opportunity opp = queryOpportunity();

        Test.startTest();
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        featureToggle.IsPOCQuoteCreationAllowed__c = true;
        upsert featureToggle;

        update (new Opportunity(Id = opp.Id, Brand_Name__c = 'Rise America'));

        opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Response responseNewBusinessWithoutPOC = UQTQuoteListController.getQuotesData(oppString, false);
        Map<String, List<Quote>> rtNamesToQuotesNewBusinessWithoutPOC =
        (Map<String, List<Quote>>) responseNewBusinessWithoutPOC.getData('recordTypeNameToQuotesMap');

        Test.stopTest();
        Assert.isNull(rtNamesToQuotesNewBusinessWithoutPOC.get(QuoteHelper.RT_NAME_POC_QUOTE),
            'Record type Name to Quotes map shouldn\'t contain POC Quotes for New Business opportunity');
    }

    @isTest
    static void testPOCQuotesForGSPPartner() {
        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Brand_Name__c, 'Apple')
                .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
                .build()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => false,
                GSP_Partner_Setup__c.Disable_POC__c => true,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple',
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        featureToggle.IsPOCQuoteCreationAllowed__c = true;
        upsert featureToggle;

        String oppString = JSON.serialize(opp);

        Response responseNewBusinessWithoutPOC = UQTQuoteListController.getQuotesData(oppString, false);
        Map<String, List<Quote>> rtNamesToQuotesNewBusinessWithoutPOC =
        (Map<String, List<Quote>>) responseNewBusinessWithoutPOC.getData('recordTypeNameToQuotesMap');

        Test.stopTest();
        Assert.isNull(rtNamesToQuotesNewBusinessWithoutPOC.get(QuoteHelper.RT_NAME_POC_QUOTE),
            'Record type Name to Quotes map shouldn\'t contain POC Quotes for New Business opportunity');
    }

    @isTest
    static void testGetQuotesDataRecordTypeNameToQuotesMap() {
        Opportunity opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Test.startTest();

        Response responseNewBusinessWithoutPOC = UQTQuoteListController.getQuotesData(oppString, false);
        Map<String, List<Quote>> rtNamesToQuotesNewBusinessWithoutPOC =
        (Map<String, List<Quote>>) responseNewBusinessWithoutPOC.getData('recordTypeNameToQuotesMap');

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        featureToggle.IsPOCQuoteCreationAllowed__c = true;
        upsert featureToggle;

        Response responseNewBusinessWithPOC = UQTQuoteListController.getQuotesData(oppString, false);
        Map<String, List<Quote>> rtNamesToQuotesNewBusinessWithPOC =
        (Map<String, List<Quote>>) responseNewBusinessWithPOC.getData('recordTypeNameToQuotesMap');


        update (new Account(Id = opp.AccountId, Billing_ID__c = '123'));

        opp = queryOpportunity();
        String oppStringExistingBusiness = JSON.serialize(opp);

        Response responseExistingBusinessWithoutPOC = UQTQuoteListController.getQuotesData(oppStringExistingBusiness, false);
        Map<String, List<Quote>> rtNamesToQuotesExistingBusinessWithoutPOC =
        (Map<String, List<Quote>>) responseExistingBusinessWithoutPOC.getData('recordTypeNameToQuotesMap');

        update (new Account(Id = opp.AccountId, Offer_Type__c = AccountHelper.OFFER_TYPE_POC));

        opp = queryOpportunity();
        String oppStringPOCtoPaid = JSON.serialize(opp);

        Response responseExistingBusinessWithPOC = UQTQuoteListController.getQuotesData(oppStringPOCtoPaid, false);
        Map<String, List<Quote>> rtNamesToQuotesExistingBusinessWithPOC =
        (Map<String, List<Quote>>) responseExistingBusinessWithPOC.getData('recordTypeNameToQuotesMap');

        Test.stopTest();

        for (String recordTypeName : RECORD_TYPE_NAMES) {
            if (recordTypeName == QuoteHelper.RT_NAME_POC_QUOTE) {
                Assert.isNull(rtNamesToQuotesNewBusinessWithoutPOC.get(recordTypeName),
                'Record type Name to Quotes map shouldn\'t contain POC Quotes for New Business opportunity' +
                'except for POC Quotes when IsPOCQuoteCreationAllowed__c feature toggle is false');

                Assert.areEqual(1, rtNamesToQuotesNewBusinessWithPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain POC Quotes for New Business opportunity' +
                'when IsPOCQuoteCreationAllowed__c feature toggle is true');

                Assert.isNull(rtNamesToQuotesExistingBusinessWithoutPOC.get(recordTypeName),
                'Record type Name to Quotes map shouldn\'t contain POC Quotes for regular Existing Business opportunity' +
                'when IsPOCQuoteCreationAllowed__c feature toggle is true');

                Assert.areEqual(1, rtNamesToQuotesExistingBusinessWithPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain POC Quotes for POC-to-Paid Existing Business opportunity');
            } else {
                Assert.areEqual(1, rtNamesToQuotesNewBusinessWithoutPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain one quote of every available record type for New Business opportunity' +
                'except for POC Quotes when IsPOCQuoteCreationAllowed__c feature toggle is false');

                Assert.areEqual(1, rtNamesToQuotesNewBusinessWithPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain one quote of every available record type for New Business opportunity' +
                'when IsPOCQuoteCreationAllowed__c feature toggle is true');

                Assert.areEqual(1, rtNamesToQuotesExistingBusinessWithoutPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain one quote of every available record type for regular Existing Business opportunity' +
                'except for POC Quotes when IsPOCQuoteCreationAllowed__c feature toggle is true');

                Assert.areEqual(1, rtNamesToQuotesExistingBusinessWithPOC.get(recordTypeName).size(),
                'Record type Name to Quotes map should contain one quote of every available record type for POC-to-Paid Existing Business opportunity');
            }
        }
    }

    @isTest
    static void testGetQuotesDataIsProServOnly() {
        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Brand_Name__c, 'Apple')
                .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
                .build()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple',
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true
            })
            .create()
            .getRecord();

        String oppString = JSON.serialize(opp);

        Test.startTest();

        Response res = UQTQuoteListController.getQuotesData(oppString, true);
        Boolean isProServOnly = (Boolean) res.getData('isProServOnly');

        Test.stopTest();

        System.assertEquals(true, isProServOnly, 'isProServOnly value should be true for ProServ only opportunity');
    }

    @isTest
    static void testCloneQuote() {
        Quote qt = queryQuoteByName('Sales Office Quote');

        Test.startTest();

        Quote clonedQuote = (Quote) UQTQuoteListController.cloneQuote(qt.Id, null).data.get('clonedQuote');

        Test.stopTest();

        System.assertEquals('Sales Office 2', clonedQuote.Name, 'Cloned Quote name should consist of original quote name minus 1 last word' +
        ' and an incremented position');
    }

    @isTest
    static void testMakeQuotePrimary() {
        Opportunity opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Quote newPrimaryQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'New Primary Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false
            })
            .create()
            .getRecord();

        Map<String, List<Quote>> recordTypeNameToQuotesMapInput =
        (Map<String, List<Quote>>) UQTQuoteListController.getQuotesData(oppString, false).data.get('recordTypeNameToQuotesMap');

        Test.startTest();

        Response res = UQTQuoteListController.makeQuotePrimary(
            newPrimaryQuote.Id,
            oppString,
            QuoteHelper.RT_NAME_SALES,
            recordTypeNameToQuotesMapInput
        );
        Map<String, List<Quote>> recordTypeNameToQuotesMap = (Map<String, List<Quote>>) res.data.get('recordTypeNameToQuotesMap');

        Test.stopTest();

        for (Quote q : recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_SALES)) {
            if (q.Id == newPrimaryQuote.Id) {
                Assert.isTrue(q.isPrimary__c, 'Quote should become Primary');
            } else {
                Assert.isFalse(q.isPrimary__c, 'All other Quotes of the same record type should not be Primary');
            }
        }
    }

    @isTest
    static void testDeleteCCAndCancelProServsIfRequiredSales() {
        Opportunity opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Quote essentialsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Non Primary Essentials Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                    'EditionName' => QuoteHelper.PACKAGE_EDITION_ESSENTIALS
                })
            })
            .create()
            .getRecord();

        Quote salesQuote = queryQuoteByName('Sales Office Quote');
        delete salesQuote;

        Map<String, List<Quote>> recordTypeNameToQuotesMapSalesInput =
        (Map<String, List<Quote>>) UQTQuoteListController.getQuotesData(oppString, false).data.get('recordTypeNameToQuotesMap');

        Test.startTest();

        Response resSales = UQTQuoteListController.deleteCCAndCancelProServsIfRequired(QuoteHelper.RT_NAME_SALES, recordTypeNameToQuotesMapSalesInput);
        Map<String, List<Quote>> recordTypeNameToQuotesMapSales = (Map<String, List<Quote>>) resSales.data.get('recordTypeNameToQuotesMap');

        Test.stopTest();

        Assert.areEqual(true, resSales.data.get('isContactCenterDeleted'),
        'isContactCenterDeleted value should be true if new Primary Sales Quote has Essentials package');
        Assert.areEqual(true, resSales.data.get('isProServCancelled'),
        'isProServCancelled value should be true if new Primary Sales Quote has Essentials package');
        Assert.areEqual(true, resSales.data.get('isCCProServCancelled'),
        'isCCProServCancelled value should be true if new Primary Sales Quote has Essentials package');

        for (String recordTypeName : RECORD_TYPE_NAMES) {
            if (recordTypeName == QuoteHelper.RT_NAME_CONTACT_CENTER) {
                Assert.isNull(recordTypeNameToQuotesMapSales.get(recordTypeName),
                'Record type Name to Quotes map shouldn\'t contain  Contact Center Quotes list if new Primary Sales Quote has Essentials package');
            } else if (new Set<String>{ QuoteHelper.RT_NAME_PROSERV, QuoteHelper.RT_NAME_CC_PROSERV }.contains(recordTypeName)) {
                Assert.areEqual(QuoteHelper.PROSERVSTATUS_CANCELLED, recordTypeNameToQuotesMapSales.get(recordTypeName)[0].ProServ_Status__c,
                'Record type Name to Quotes map should contain ' + recordTypeName + ' with ProServ_Status__c "Cancelled" if  '
                + 'new Primary Sales Quote has Essentials package');
            }
        }
    }

    @isTest
    static void testDeleteCCAndCancelProServsIfRequiredSalesNonEssentials() {
        Opportunity opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Quote secondSalesQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Non Primary Essentials Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                    'EditionName' => 'Not Essentials'
                })
            })
            .create()
            .getRecord();

        Quote salesQuote = queryQuoteByName('Sales Office Quote');
        delete salesQuote;

        Map<String, List<Quote>> recordTypeNameToQuotesMapSalesInput =
        (Map<String, List<Quote>>) UQTQuoteListController.getQuotesData(oppString, false).data.get('recordTypeNameToQuotesMap');

        Test.startTest();

        Response resSales = UQTQuoteListController.deleteCCAndCancelProServsIfRequired(QuoteHelper.RT_NAME_SALES, recordTypeNameToQuotesMapSalesInput);
        Map<String, List<Quote>> recordTypeNameToQuotesMapSales = (Map<String, List<Quote>>) resSales.data.get('recordTypeNameToQuotesMap');

        Test.stopTest();

        Assert.areEqual(true, resSales.data.get('isContactCenterDeleted'),
        'isContactCenterDeleted value should be true if there is new Primary Sales Quote');
        Assert.areNotEqual(resSales.data.get('isProServCancelled'),
        'isProServCancelled value shouldn\'t be true if there is new Primary Sales Quote without Essentials package');
        Assert.areEqual(true, resSales.data.get('isCCProServCancelled'),
        'isCCProServCancelled value should be true if there is new Primary Sales Quote');

        for (String recordTypeName : RECORD_TYPE_NAMES) {
            if (recordTypeName == QuoteHelper.RT_NAME_CONTACT_CENTER) {
                Assert.isNull(recordTypeNameToQuotesMapSales.get(recordTypeName),
                'Record type Name to Quotes map shouldn\'t contain Contact Center Quotes list if there is new Primary Sales Quote');
            } else if (recordTypeName == QuoteHelper.RT_NAME_PROSERV) {
                Assert.areNotEqual(QuoteHelper.PROSERVSTATUS_CANCELLED, recordTypeNameToQuotesMapSales.get(recordTypeName)[0].ProServ_Status__c,
                'Record type Name to Quotes map shouldn\'t contain ' + recordTypeName + ' with ProServ_Status__c "Cancelled" if  '
                + 'new Primary Sales Quote hasn\'t got Essentials package');
            } else if (recordTypeName == QuoteHelper.RT_NAME_CC_PROSERV) {
                Assert.areEqual(QuoteHelper.PROSERVSTATUS_CANCELLED, recordTypeNameToQuotesMapSales.get(recordTypeName)[0].ProServ_Status__c,
                'Record type Name to Quotes map should contain ' + recordTypeName + ' with ProServ_Status__c "Cancelled" if  '
                + 'if there is new Primary Sales Quote');
            }
        }
    }

    @isTest
    static void testDeleteCCAndCancelProServsIfRequiredNonSales() {
        Opportunity opp = queryOpportunity();
        String oppString = JSON.serialize(opp);

        Map<String, List<Quote>> recordTypeNameToQuotesMapPOCInput =
        (Map<String, List<Quote>>) UQTQuoteListController.getQuotesData(oppString, false).data.get('recordTypeNameToQuotesMap');

        Test.startTest();

        Response resPOC = UQTQuoteListController.deleteCCAndCancelProServsIfRequired(QuoteHelper.RT_NAME_POC_QUOTE, recordTypeNameToQuotesMapPOCInput);
        Map<String, List<Quote>> recordTypeNameToQuotesMapPOC = (Map<String, List<Quote>>) resPOC.data.get('recordTypeNameToQuotesMap');

        Test.stopTest();

        Assert.isNull(resPOC.data.get('isContactCenterDeleted'),
        'isContactCenterDeleted value should be null for non-Sales Primary Quote');
        Assert.isNull(resPOC.data.get('isProServCancelled'),
        'isProServCancelled value should be null for non-Sales Primary Quote');
        Assert.isNull(resPOC.data.get('isCCProServCancelled'),
        'isCCProServCancelled value should be null for non-Sales Primary Quote');
        Assert.areEqual(recordTypeNameToQuotesMapPOC, recordTypeNameToQuotesMapPOCInput,
        'Record type Name to Quotes map should not be changed for non-Sales Primary Quote');
    }

    private static Opportunity queryOpportunity() {
        OpportunitySelector oppSelector = new OpportunitySelector();
        return (Opportunity) oppSelector
            .selectOpportunityByName('Test Opportunity')
            .selectFields(oppSelector.getFieldsForQuoteWizard())
            .setLimit(1)
            .executeQuery()
            .get(0);
    }

    private static Quote queryQuoteByName(String quoteName) {
        return (Quote) new QuoteSelector()
            .selectQuoteByName(quoteName)
            .setLimit(1)
            .executeQuery()
            .get(0);
    }

    @isTest
    static void testCheckAccountBillingCountry() {
        Response resp;
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, true)
            .create();

        System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING)) {

            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'Test acc',
                    Account.BillingCountry => 'Egypt'
                })
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.BusinessIdentity__c => '{"currency":"GBP","biId":"2"}',
                    Opportunity.Sub_Brand__c => '1211.AMZN_UK',
                    Opportunity.Brand_Name__c => 'RingCentral UK',
                    Opportunity.AccountId => acc.Id
                })
                .build()
                .getRecord();

            String oppString = JSON.serialize(testOpp);

            resp = UQTQuoteListController.checkAccountBillingCountry(oppString);
        }

        System.assertEquals(resp.data.get('isWrongAccountBillingCountry'), true, 'Response data isWrongAccountBillingCountry should be true');
    }

    @isTest
    static void testCheckAccountBillingCountryWithoutFT() {
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, false)
            .create();

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunityByName('Test Opportunity')
            .executeQuery()
            .get(0);

        String oppString = JSON.serialize(opp);

        Response resp = UQTQuoteListController.checkAccountBillingCountry(oppString);
        System.assertEquals(resp.data, new Response().data, 'Response data should be empty');
    }

    @isTest
    static void testCheckAccountBillingCountryForExistingBusiness() {
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, true)
            .create();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'Test account'
            })
            .withoutSelectorFieldsIncluded()
            .selectFields(new Set<String>{
                'Billing_ID__c'
            })
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        acc.Billing_ID__c = '123456';
        update acc;
        Triggers.switchOn();

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunityByName('Test Opportunity')
            .withoutSelectorFieldsIncluded()
            .selectFields(new Set<String>{
                'Account.Billing_ID__c'
            })
            .executeQuery()
            .get(0);

        String oppString = JSON.serialize(opp);

        Test.startTest();
        Response resp = UQTQuoteListController.checkAccountBillingCountry(oppString);
        Test.stopTest();

        Assert.areEqual(resp.data, new Response().data, 'Response data should be empty');
    }

    @isTest
    static void testCheckAccountBillingCountryUnderCRMDeveloperProfile() {
        Response resp;
        Test.startTest();
            System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_CRM_DEVELOPER)) {
                Account acc = new Account(Name = 'Test acc', BillingCountry = 'Egypt');
                insert acc;

                Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        Opportunity.BusinessIdentity__c => '{"currency":"GBP","biId":"2"}',
                        Opportunity.Sub_Brand__c => '1211.AMZN_UK',
                        Opportunity.Brand_Name__c => 'RingCentral UK',
                        Opportunity.AccountId => acc.Id
                    })
                    .build()
                    .getRecord();

                String oppString = JSON.serialize(opp);

                resp = UQTQuoteListController.checkAccountBillingCountry(oppString);
            }
        Test.stopTest();

        System.assertEquals(resp.data, new Response().data, 'Response data should be empty');
    }

    @isTest
    static void testDropQuote() {
        Quote qt = queryQuoteByName('Sales Office Quote');

        Test.startTest();

        Response res = UQTQuoteListController.dropQuote((String) qt.Id);
        Id droppedQuoteId = (Id) res.data.get('droppedQuoteId');

        Test.stopTest();

        List<Quote> droppedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuoteById(new List<Object> { droppedQuoteId })
            .executeQuery();

        System.assertEquals(true, droppedQuotes.isEmpty(), 'Dropped Quote should be deleted');
    }

    private static Opportunity attachAccountToOpportunity(Opportunity oppty, Account acc) {
        Map<String, Object> opptyMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppty));
        opptyMap.put('Account', acc);
        return (Opportunity) JSON.deserialize(JSON.serialize(opptyMap), Opportunity.class);
    }
}