@isTest
public class DQ_SubmitQuoteForApproval_Test {
    @TestSetup
    static void makeData(){
        new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'Test Account',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'Germany'
                }
            )
            .create();

        new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Alias => StringHelper.getRandomString(8),
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.LocaleSidKey => 'en_US',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.Username => 'testapprover@ringcentral.com'
                }
            )
            .create();
    }

    @isTest
    static void testGetQuoteApprovalStatus() {

        System.runAs(getTestUserWithDQGoaPermission()) {

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            User testApprover = (User) new UserSelector()
                .selectUserByUsername(new List<Object>{ new List<String>{ 'testapprover@ringcentral.com' }})
                .executeQuery()
                .get(0);

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.OwnerId => testApprover.Id,
                        Opportunity.CloseDate => System.today().addMonths(1)
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.contract = new BillingWrappers.Contract();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Initial_Term_months__c => '24',
                        Quote.JustificationandDescription__c => 'Test Quote description',
                        Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                        DQ_Deal_Qualification__c.Quote__c => testQuote.Id,
                        DQ_Deal_Qualification__c.Status__c => 'Pending Approval',
                        DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                        DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                        DQ_Deal_Qualification__c.Initial_Term__c => '12',
                        DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => 'Overnight',
                        DQ_Deal_Qualification__c.Justification_Description__c => 'Test DQ description'
                    }
                )
                .create()
                .getRecord();

            createDQDataForInitialTermApproval(testApprover);

            String statusResult = DQ_SubmitQuoteForApproval1.getQuoteApprovalStatus(testQuote.Id);

            Test.stopTest();

            System.assertEquals(
                DQ_SubmitQuoteForApproval1.REQUIRED_STATUS_QUOTE,
                statusResult,
                'Returned Quote status should be ' + DQ_SubmitQuoteForApproval1.REQUIRED_STATUS_QUOTE
            );
        }
    }

    @isTest
    static void testGetApproverByOppIdForInitialTerm() {
        final String testPackageId = '18';
        final String testPackageVersion = '2';
        final String deviceContractGoaGroup = 'Device_Contract';

        System.runAs(getTestUserWithDQGoaPermission()) {

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            User testApprover = (User) new UserSelector()
                .selectUserByUsername(new List<Object>{ new List<String>{ 'testapprover@ringcentral.com' }})
                .executeQuery()
                .get(0);

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.OwnerId => testApprover.Id,
                        Opportunity.CloseDate => System.today().addMonths(1)
                    }
                )
                .create()
                .getRecord();

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.contract = new BillingWrappers.Contract();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Initial_Term_months__c => '24',
                        Quote.JustificationandDescription__c => 'Test Quote description',
                        Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                        DQ_Deal_Qualification__c.Quote__c => testQuote.Id,
                        DQ_Deal_Qualification__c.Status__c => 'New',
                        DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                        DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                        DQ_Deal_Qualification__c.Initial_Term__c => '12',
                        DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => 'Overnight',
                        DQ_Deal_Qualification__c.Justification_Description__c => 'Test DQ description'
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification_History__c testDqHistoryRecord = (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                        DQ_Deal_Qualification_History__c.Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification_Discount_History__c testDqDiscountHistory = (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c => testDqHistoryRecord.Id,
                        DQ_Deal_Qualification_Discount_History__c.Quantity__c => 10,
                        DQ_Deal_Qualification_Discount_History__c.Discount__c => 10,
                        DQ_Deal_Qualification_Discount_History__c.Product_Category__c => deviceContractGoaGroup,
                        DQ_Deal_Qualification_Discount_History__c.Product__c => testProduct.Id,
                        DQ_Deal_Qualification_Discount_History__c.PackageId__c => testPackageId,
                        DQ_Deal_Qualification_Discount_History__c.PackageVersion__c => testPackageVersion
                    }
                )
                .create()
                .getRecord();

            createDQDataForInitialTermApproval(testApprover);

            List<DQ_ApprovalEngine1.ApproverWrapper> result = DQ_SubmitQuoteForApproval1.getApproverByOppId(opp.Id, testQuote.Id);

            Test.stopTest();

            System.assertEquals(
                'Initial term is equal to 24.00',
                result[0].approvalReason,
                'Approval reason should be "Initial term is equal to 24.00"'
            );
        }
    }

    @isTest
    static void testGetApproverByOppIdForInitialTermAndIsInitialTermConsider() {
        final String testPackageId = '18';
        final String testPackageVersion = '2';
        final String deviceContractGoaGroup = 'Device_Contract';

        System.runAs(getTestUserWithDQGoaPermission()) {

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            User testApprover = (User) new UserSelector()
                .selectUserByUsername(new List<Object>{ new List<String>{ 'testapprover@ringcentral.com' }})
                .executeQuery()
                .get(0);

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.OwnerId => testApprover.Id,
                        Opportunity.CloseDate => System.today().addMonths(1)
                    }
                )
                .create()
                .getRecord();

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.contract = new BillingWrappers.Contract();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Initial_Term_months__c => '24',
                        Quote.JustificationandDescription__c => 'Test Quote description',
                        Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                        DQ_Deal_Qualification__c.Quote__c => testQuote.Id,
                        DQ_Deal_Qualification__c.Status__c => 'New',
                        DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                        DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                        DQ_Deal_Qualification__c.Initial_Term__c => '12',
                        DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => 'Overnight',
                        DQ_Deal_Qualification__c.Justification_Description__c => 'Test DQ description'
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification_History__c testDqHistoryRecord = (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                        DQ_Deal_Qualification_History__c.Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification_Discount_History__c testDqDiscountHistory = (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c => testDqHistoryRecord.Id,
                        DQ_Deal_Qualification_Discount_History__c.Quantity__c => 10,
                        DQ_Deal_Qualification_Discount_History__c.Discount__c => 10,
                        DQ_Deal_Qualification_Discount_History__c.Product_Category__c => deviceContractGoaGroup,
                        DQ_Deal_Qualification_Discount_History__c.Product__c => testProduct.Id,
                        DQ_Deal_Qualification_Discount_History__c.PackageId__c => testPackageId,
                        DQ_Deal_Qualification_Discount_History__c.PackageVersion__c => testPackageVersion
                    }
                )
                .create()
                .getRecord();

            createDQDataForInitialTermApproval(testApprover);

            List<DQ_ApprovalEngine1.ApproverWrapper> result = DQ_SubmitQuoteForApproval1.getApproverByOppId(opp.Id, testQuote.Id, true);

            Test.stopTest();

            System.assertEquals(
                'Initial term is equal to 24.00',
                result[0].approvalReason,
                'Approval reason should be "Initial term is equal to 24.00"'
            );
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSubmitQuteForApprovalBatchMethod() {

        System.runAs(getTestUserWithDQGoaPermission()) {

            Test.startTest();

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            User testApprover = (User) new UserSelector()
                .selectUserByUsername(new List<Object>{ new List<String>{ 'testapprover@ringcentral.com' }})
                .executeQuery()
                .get(0);

            Triggers.switchOff();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.OwnerId => testApprover.Id,
                        Opportunity.CloseDate => System.today().addMonths(1)
                    }
                )
                .create()
                .getRecord();

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.contract = new BillingWrappers.Contract();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Initial_Term_months__c => '24',
                        Quote.JustificationandDescription__c => 'Test Quote description',
                        Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    })
                .create()
                .getRecord();

            List<Quote> testProServQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => ValueProviderBuilder.provideUniqueString('ProServ Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                        Quote.Total_Number_of_Digital_Lines__c => 10,
                        Quote.Initial_Term_months__c => '10',
                        Quote.Term_months__c => '21',
                        Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_1,
                        Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                        Quote.Special_Notes__c => 'test1;',
                        Quote.JustificationandDescription__c => 'test1;test2;',
                        Quote.Payment_Period__c => QuoteHelper.MONTHLY_PAYMENT_METHOD,
                        Quote.Total_Initial_Payment__c => 100.00,
                        Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                        Quote.RecordTypeId => ValueProviderBuilder.provideList(
                            new List<Id>{
                                QuoteHelper.RT_ID_PROSERV,
                                QuoteHelper.RT_ID_CC
                            }
                        ),
                        Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                    }
                )
                .create()
                .getRecords();

            Triggers.switchOn();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id
                    }
                )
                .create()
                .getRecord();

            createDQDataForInitialTermApproval(testApprover);

            Test.stopTest();
        }
    }

    @isTest
    static void testSubmitQuteForApprovalForInitialTerm() {

        System.runAs(getTestUserWithDQGoaPermission()) {

            Test.startTest();

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            User testApprover = (User) new UserSelector()
                .selectUserByUsername(new List<Object>{ new List<String>{ 'testapprover@ringcentral.com' }})
                .executeQuery()
                .get(0);

            Triggers.switchOff();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.OwnerId => testApprover.Id,
                        Opportunity.CloseDate => System.today().addMonths(1)
                    }
                )
                .create()
                .getRecord();

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.contract = new BillingWrappers.Contract();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Initial_Term_months__c => '24',
                        Quote.JustificationandDescription__c => 'Test Quote description',
                        Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo}),
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    })
                .create()
                .getRecord();

            List<Quote> testProServQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => ValueProviderBuilder.provideUniqueString('ProServ Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                        Quote.Total_Number_of_Digital_Lines__c => 10,
                        Quote.Initial_Term_months__c => '10',
                        Quote.Term_months__c => '21',
                        Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_1,
                        Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                        Quote.Special_Notes__c => 'test1;',
                        Quote.JustificationandDescription__c => 'test1;test2;',
                        Quote.Payment_Period__c => QuoteHelper.MONTHLY_PAYMENT_METHOD,
                        Quote.Total_Initial_Payment__c => 100.00,
                        Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                        Quote.RecordTypeId => ValueProviderBuilder.provideList(
                            new List<Id>{
                                QuoteHelper.RT_ID_PROSERV,
                                QuoteHelper.RT_ID_CC
                            }
                        ),
                        Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                    }
                )
                .create()
                .getRecords();

            Triggers.switchOn();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id
                    }
                )
                .create()
                .getRecord();

            createDQDataForInitialTermApproval(testApprover);

            Id dqId = DQ_SubmitQuoteForApproval1.submitQuteForApprovalBatchMethod(new Set<Id>{ opp.Id }, new Set<Id>{ testQuote.Id }, true);

            Test.stopTest();

            DQ_Deal_Qualification__c createdDealQualification = (DQ_Deal_Qualification__c) new DealQualificationSelector()
                .selectDQs()
                .selectFields(
                    new Set<SObjectField>{
                        DQ_Deal_Qualification__c.Opportunity__c
                    }
                )
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ dqId })
                .executeQuery()
                .get(0);

            System.assertEquals(
                opp.Id,
                createdDealQualification.Opportunity__c,
                'Created Deal Qualification should have Id of Opportunity in Opportunity__c field'
            );
        }
    }

    @isTest
    static void testGetRegionValueByOppCurrencyISO() {

        Test.startTest();

        System.assertEquals(
            'US',
            DQ_SubmitQuoteForApproval1.getRegionValueByOppCurrencyISO('USD'),
            'Region for USD currency should be US'
        );
        System.assertEquals(
            'EU',
            DQ_SubmitQuoteForApproval1.getRegionValueByOppCurrencyISO('EUR'),
            'Region for EUR currency should be EU'
        );
        System.assertEquals(
            'Australia',
            DQ_SubmitQuoteForApproval1.getRegionValueByOppCurrencyISO('AUS'),
            'Region for AUS currency should be Australia'
        );

        Test.stopTest();
    }

    @isTest
    static void testGetMapOfProductCategoryIdVsMapOfData() {

        System.runAs(getTestUserWithDQGoaPermission()) {

            Account testAcc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{ 'Test Account' })
                .executeQuery()
                .get(0);

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.CloseDate => System.today().addMonths(1),
                        Opportunity.Brand_Name__c => 'Test'
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                        Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                        Quote.isPrimary__c => false
                    }
                )
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry pbEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProduct.Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 55,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => pbEntry.Id,
                        QuoteLineItem.UnitPrice => 500,
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_PACKAGE_INFO
                    }
                )
                .create()
                .getRecord();

            Product_package__c prodPackage = (Product_package__c) new SObjectBuilder(Product_package__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product_Package__c.Ext_Element_Id__c => 'LC_TEST',
                        Product_Package__c.Brand_Name__c => 'Test',
                        Product_Package__c.Element_Ids__c => '5'
                    }
                )
                .create()
                .getRecord();

            Map<String, List<QuoteLineItem>> data = new Map<String, List<QuoteLineItem>>{
                DQ_SubmitQuoteForApproval1.CC_PROSERV_QUOTE_LINE => new List<QuoteLineItem> { testQli }};

            Map<String, Map<String, Map<String, Object>>> result = DQ_SubmitQuoteForApproval1.getMapOfProductCategoryIdVsMapOfData(data);

            Test.stopTest();

            Map<String, Object> resultInnerMap = result.get('Default').get('Default-' + testProduct.Id);

            System.assertEquals(
                10,
                resultInnerMap.get('QUANTITY'),
                'Returned map should have QUANTITY value 10'
            );
            System.assertEquals(
                55.00,
                resultInnerMap.get('DISCOUNT'),
                'Returned map should have DISCOUNT value 55.00'
            );
            System.assertEquals(
                prodPackage.Id,
                resultInnerMap.get('PRODUCT PACKAGE'),
                'Returned map should have QUANTITY value ' + prodPackage.Id
            );
        }
    }

    @isTest
    static void testGetMapOfProductFamilyVsDealQualDiscount() {
        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
                Product2.Group__c => 'testGroup1',
                Product2.Subgroup__c => 'testSubGroup1'
            })
            .create()
            .getRecord();

        Product_package__c productPackage = (Product_package__c) new SObjectBuilder(Product_package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product_Package__c.Ext_Element_Id__c => 'LC_TEST',
                    Product_Package__c.Brand_Name__c => 'Test',
                    Product_Package__c.Element_Ids__c => '5'
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .build()
            .quantity(1)
            .getRecords();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Discounts__c testDqDiscount = (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                DQ_Deal_Qualification_Discounts__c.Product__c => testProduct.Id,
                DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => '1952',
                DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c => '2',
                DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c => 'test Package',
                DQ_Deal_Qualification_Discounts__c.PackageName__c => 'test Package',
                DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_Devices',
                DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                DQ_Deal_Qualification_Discounts__c.Discount__c => 5,
                DQ_Deal_Qualification_Discounts__c.Quantity__c => 10,
                DQ_Deal_Qualification_Discounts__c.Product_Package__c => productPackage.Id,
                DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'Device_Contract'
            })
            .create()
            .getRecord();

        Test.startTest();
            Map<String, DQ_Deal_Qualification_Discounts__c> resultMap =  DQ_SubmitQuoteForApproval1.getMapOfProductFamilyVsDealQualDiscount(new List<DQ_Deal_Qualification_Discounts__c>{testDqDiscount});
        Test.stopTest();

        System.assertEquals(1, resultMap.size(), 'Returned map should have 1 item');
        String resultKey = productPackage.Id + DQ_SubmitQuoteForApproval1.PRODUCT_KEY_SEPERATOR + testDqDiscount.Product_Category__c + DQ_SubmitQuoteForApproval1.PRODUCT_KEY_SEPERATOR + testProduct.Id;
        System.assertEquals(testDqDiscount.Id, resultMap.get(resultKey).Id, 'The created DQ discount should return by the key');
    }

    private static void createDQDataForInitialTermApproval(User testApprover) {
        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.IsUnifiedQuotingApprovalType__c => false,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_INITIAL_TERM,
                    DQ_Approval_Type__c.Threshold__c => 24,
                    DQ_Approval_Type__c.Product_Category__c => 'Default'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Type_Step__c.Region__c => 'US',
                    DQ_Approval_Type_Step__c.Segment__c => 'Default',
                    DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                    DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Step_Approver__c.Region__c => 'US',
                    DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                    DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                    DQ_Approval_Step_Approver__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
    }

    private static User getTestUserWithDQGoaPermission() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Email => new ValueProvider.UniqueStringProvider('testuser@gmail.com'),
                    User.FirstName => new ValueProvider.UniqueStringProvider('firstName'),
                    User.LanguageLocaleKey => 'en_US',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Username => new ValueProvider.UniqueStringProvider('testuser@gmail.com'),
                    User.CommunityNickname => new ValueProvider.UniqueStringProvider('testPortalUser_')
                }
            )
            .create()
            .getRecord();

        PermissionSet dqGoaPermission = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{ new List<String>{ CustomPermissionHelper.PERMISSION_TARGET_PRICE_AND_DQ_GOA }})
            .executeQuery()
            .get(0);

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => dqGoaPermission.Id
                }
            )
            .create();

        return testUser;
    }
}