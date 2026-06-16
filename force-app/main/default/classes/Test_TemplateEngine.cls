@isTest
private class Test_TemplateEngine {
    private static Quote testQuote;
    private static Quote testPSQuote;
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static RC_Quote_Template__c testTemplate;

    private static void createTestData(){
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office', Plan__c='Monthly');
        insert testPriceBook;

        // Create Products
        Product2 testProduct = new Product2(
                Name = 'prod1',
                IsActive = true,
                GOA_Group__c = 'DEVICES_B_STOCK',
                Charge_Term__c='Monthly',
                Feature__c = Product2Helper.FEATURE_SERVICE_PLAN);

        Product2 testProduct2 = new Product2(
                Name = 'prod2',
                IsActive = true,
                GOA_Group__c = 'DEVICES_B_STOCK',
                Charge_Term__c='Monthly - Contract',
                Feature__c = Product2Helper.FEATURE_LIMITED_EXTENSION,
                Dependent_on_Feature__c = Product2Helper.FEATURE_GLOBAL_OFFICE);

        Product2 testProduct3 = new Product2(
                Name = 'prod3',
                IsActive = true,
                GOA_Group__c = 'DEVICES_B_STOCK',
                Charge_Term__c='Annual',
                Feature__c = Product2Helper.FEATURE_GLOBAL_OFFICE);

        Product2 testProduct4 = new Product2(
            Name = 'prod4',
            IsActive = true,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );

        Product2 testProduct5 = new Product2(
            Name = 'prod5',
            IsActive = true,
            GOA_Group__c = 'DEVICES_B_STOCK',
            Charge_Term__c='Annual',
            Feature__c = Product2Helper.FEATURE_GLOBAL_OFFICE);

        Product2 testProduct6 = new Product2(
            Name = 'prod6',
            IsActive = true,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );

        insert new List<Product2>{
                testProduct, testProduct2, testProduct3, testProduct4, testProduct5, testProduct6
        };

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(), Product2Id = testProduct.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert new List<PricebookEntry> { standardPrice, testPrice };

        testAccount = new Account(Name='Opty test account',
                Partner_ID__c='testID',
                Permitted_Brands__c='RingCentral',
                RC_User_ID__c = '1234');
        insert testAccount;

        Contact testContact = new Contact(
                AccountId = testAccount.Id,
                LastName = 'John',
                FirstName = 'Doe',
                Email = 'johndoe@example.tld'
        );
        insert testContact;

        Test.startTest();

        testOpportunity = new Opportunity(Name = 'Test Opportunity', Type = 'Syndicated - New',
                StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        OpportunityContactRole testContactRole = new OpportunityContactRole(
                OpportunityId = testOpportunity.Id,
                ContactId = testContact.Id,
                Role = 'Billing Contact'
        );
        insert testContactRole;

        testQuote = new Quote (
            Name = 'quotetest' ,
            OpportunityId = testOpportunity.id,
            Pricebook2Id = testPriceBook.id,
            Total_Number_of_Digital_Lines__c = 10,
            Initial_Term_months__c='10',
            Term_months__c='21',
            Special_Terms__c='1 Free Week of Service',
            Start_Date__c = Date.newInstance(2017, 8, 1),
            Special_Notes__c = 'test1;',
            JustificationandDescription__c = 'test1;test2;',
            Payment_Period__c = 'Monthly Payment Period',
            Total_Initial_Payment__c = 100.00,
            Contact_Center_Total_Initial_Payment__c = 10.00,
            AdditionalName = null
        );
        testPSQuote = new Quote (Name = 'quotetestPS' , OpportunityId = testOpportunity.id ,Pricebook2Id = testPriceBook.id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV);

        insert new List<Quote>{ testQuote, testPSQuote };

        Entitlement__c entitlement1 = new Entitlement__c(
            Active__c = true,
            Account__c = testAccount.Id,
            Product__c = testProduct.Id,
            Quantity__c = 5,
            Price__c = 11
        );

        Entitlement__c entitlement2 = new Entitlement__c(
            Active__c = true,
            Account__c = testAccount.Id,
            Product__c = testProduct2.Id,
            Quantity__c = 5,
            Price__c = 10
        );

        Entitlement__c entitlementNGBS1 = new Entitlement__c(
            Active__c = true,
            Account__c = testAccount.Id,
            Quote__c = testQuote.Id,
            Product__c = testProduct5.Id,
            ChargeTerm__c = 'Monthly',
            Quantity__c = 5,
            Price__c = 11
        );

        Entitlement__c entitlementNGBS2 = new Entitlement__c(
            Active__c = true,
            Account__c = testAccount.Id,
            Quote__c = testQuote.Id,
            Product__c = testProduct6.Id,
            ChargeTerm__c = 'Monthly',
            Quantity__c = 5,
            Price__c = 10
        );

        insert new List<Entitlement__c>{ entitlement1, entitlement2, entitlementNGBS1, entitlementNGBS2 };

        // Create Quote Line Items
        QuoteLineItem testQLI1 = new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'prod1 Desc',
                UnitPrice = testPrice.UnitPrice,
                Quantity = 5,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testPrice.Id,
                Product2Id = testProduct.Id,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Discount_number__c = 10,
                NewQuantity__c = 5);

        QuoteLineItem testQLI2 = new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'prod2 Desc',
                UnitPrice = testPrice.UnitPrice,
                Quantity = 4,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testPrice.Id,
                Product2Id = testProduct2.Id,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Discount_number__c = 9,
                NewQuantity__c = 4);

        QuoteLineItem testQLI3 = new QuoteLineItem (
                ServiceDate = date.today(),
                Description = 'prod3 Desc',
                UnitPrice = testPrice.UnitPrice,
                Quantity = 3,
                QuoteId = testQuote.Id,
                PriceBookEntryId = testPrice.Id,
                Product2Id = testProduct3.Id,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Discount_number__c = 8,
                NewQuantity__c = 3);

        QuoteLineItem testQLI4 = new QuoteLineItem (
            ServiceDate = date.today(),
            Description = 'prod4 Desc',
            UnitPrice = testPrice.UnitPrice,
            Quantity = 3,
            QuoteId = testPSQuote.Id,
            PriceBookEntryId = testPrice.Id,
            Product2Id = testProduct4.Id,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
            Discount_number__c = 8,
            NewQuantity__c = 3);

        insert new List<QuoteLineItem>{
                testQLI1, testQLI2, testQLI3, testQLI4
        };

        Test.stopTest();

    }
    private static void createTestTemplate(String content1, String content2, String params){
        testTemplate = new RC_Quote_Template__c(
                Name = 'test',
                Brand__c = 'RingCentral',
                Description__c = 'test123',
                Type__c = 'test',
                Language__c = 'English',
                Parameters__c = params,
                CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );

        insert testTemplate;

        TemplateSections__c section = new TemplateSections__c(
                Name='Section Name',
                Content_1__c = content1,
                Content_2__c = content2,
                CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );
        insert section;

        TemplateSectionJunction__c junction = new TemplateSectionJunction__c(
                Position__c =1.00,
                RC_Quote_Template__c = testTemplate.id,
                Template_Section__c = section.id
        );
        insert junction;
    }

    private static void updateQLIEffectivePriceNewField(Integer newPrice) {
        QuoteLineItemSelector qliSelector = new QuoteLineItemSelector();
        List<QuoteLineItem> quoteLineItems = qliSelector.selectQuoteLineItems().executeQuery();

        if (!quoteLineItems.isEmpty() && newPrice != null) {
            for (QuoteLineItem qli : quoteLineItems) {
                qli.EffectivePriceNew__c = newPrice;
            }
            update quoteLineItems;
        }
    }

    // Basic Tests
    // =============
    @isTest
    private static void testCreateDoc() {
        createTestData();
        createTestTemplate('Hello-', '{! Name }!', null);

        String templateStrQuoteResult = TemplateEngine.createDoc(testQuote.Id, testTemplate.Id);
        String templateStrAccountResult = TemplateEngine.createDoc(testAccount.Id, testTemplate.Id);

        System.assertEquals('Hello-quotetest!',templateStrQuoteResult, 'Template Engine should work with Quotes');
        System.assertEquals('Hello-Opty test account!',templateStrAccountResult, 'Template Engine should work with different objects');
    }

    @isTest
    private static void testRetrieveField() {
        createTestData();
        testQuote.Total_Number_of_Digital_Lines__c = 10;
        Triggers.switchOff();
        update testQuote;
        Triggers.switchOn();

        String templateStr = 'Quote Name: {! Name }. Total Number of DL\'s: {! Total_Number_of_Digital_Lines__c }. Opportunity Name: {! Opportunity.Name }. Account Name: {! Opportunity.Account.Name }. ';
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Quote Name: quotetest. Total Number of DL\'s: 10. Opportunity Name: Test Opportunity. Account Name: Opty test account.',templateStrResult);

    }

    @isTest
    private static void testLoops() {
        createTestData();

        String loopStr = '{! for qli : QuoteLineItem }{! qli.Product2.Name }{! /for }';
        String loopOrderedStr = '{! for qli : QuoteLineItem | orderBy(\'Product2.Name DESC\')}{! qli.Product2.Name }, {! /for }';
        String loopOrdered2Str = '{! for qli : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! qli.Product2.Name }, {! /for }';
        String loopFilteredStr = '{! for qli : QuoteLineItem | where(\'Quantity = 3\')}{! qli.Product2.Name }, {! /for }';

        String loopStrResult = TemplateEngine.createFromString(testQuote.Id, loopStr);
        String loopOrderedStrResult = TemplateEngine.createFromString(testQuote.Id, loopOrderedStr);
        String loopOrdered2StrResult = TemplateEngine.createFromString(testQuote.Id, loopOrdered2Str);
        String loopFilteredStrResult = TemplateEngine.createFromString(testQuote.Id, loopFilteredStr);

        String expectedResult1 = 'prod1';
        String expectedResult2 = 'prod2';
        String expectedResult3 = 'prod3';
        System.assert(loopStrResult.contains(expectedResult1)
                && loopStrResult.contains(expectedResult2)
                && loopStrResult.contains(expectedResult3),
                String.format('Expected {0}, {1}, {2} to be in result but got: {3}', new String[]{
                        expectedResult1,
                        expectedResult2,
                        expectedResult3,
                        loopStrResult
                }));

        System.assertEquals('prod3, prod2, prod1,', loopOrderedStrResult);
        System.assertEquals('prod3, prod2, prod1,', loopOrderedStrResult);
        System.assertEquals('prod3,', loopFilteredStrResult);

    }

    // Test Formatters
    // ===============

    @isTest
    private static void testIfCondition() {
        createTestData();

        String equalStr = '{! Opportunity.StageName | if(\'=\',\'planning\', \'Pass\', \'Fail\') }';
        String containsStr = '{! Opportunity.Type | if(\'contains\',\'syndicated\', \'Pass\', \'Fail\') } ' +
            '{! Opportunity.Type | if(\'contains\',[\'Syndicated - New\',\'Some other\'], \'Pass\', \'Fail\') }';
        String containsWordsExceptStr = '{! Special_Notes__c | if(\'containsWordsExcept\',\'test1\', \'Fail\', \'Pass\') } ' +
            '{! JustificationandDescription__c | if(\'containsWordsExcept\',\'test1\', \'Pass\', \'Fail\') }';
        String equalWithFieldStr = '{! Opportunity.StageName | if(\'=\', <! Opportunity.StageName>, \'Pass\', \'Fail\') }';
        String outputFieldStr = '{! Opportunity.StageName | if(\'=\',\'planning\', <! Opportunity.Type >) }';

        String equalStrResult = TemplateEngine.createFromString(testQuote.Id, equalStr);
        String containsStrResult = TemplateEngine.createFromString(testQuote.Id, containsStr);
        String containsWordsExceptStrResult = TemplateEngine.createFromString(testQuote.Id, containsWordsExceptStr);
        String equalWithFieldStrResult = TemplateEngine.createFromString(testQuote.Id, equalWithFieldStr);
        String outputFieldStrResult = TemplateEngine.createFromString(testQuote.Id, outputFieldStr);

        System.assertEquals('Pass', equalStrResult);
        System.assertEquals('Pass Pass', containsStrResult);
        System.assertEquals('Pass Pass', containsWordsExceptStrResult);
        System.assertEquals('Pass', equalWithFieldStrResult);
        System.assertEquals('Syndicated - New', outputFieldStrResult);

    }

    @isTest
    private static void testIfConditionWithVirtualFields() {
        createTestData();

        // virtual fields should be processed correctly in if-condition
        // multiple instances of subsequent if-conditions should work too
        String virtualFieldsInFiltersStr = '{! for qli : QuoteLineItem }{! /for }' +
            '{! qli.$subtotal | if(\'!=\', <! qli.$subtotal>, \'badResult\', <! qli.$subtotal>) ' +
                             '| if(\'=\', <! qli.$subtotal>, <! qli.$subtotal>, \'badResult\'}';


        String virtualFieldsInFiltersStrResult = TemplateEngine.createFromString(testQuote.Id, virtualFieldsInFiltersStr);

        System.assertNotEquals('badResult', virtualFieldsInFiltersStrResult);
        System.assertNotEquals(null, Decimal.valueOf(virtualFieldsInFiltersStrResult),
            'String with decimal value should be returned.');
    }

    @isTest
    private static void testVariables() {
        createTestData();

        // tests that Engine correctly distinguish '$var.' and 'var.'
        String testVarKeyword =
            '{! var var = "variable"}' +
            '{! for var : QuoteLineItem }' +
                '[{! var.Quantity | default(0.00) | setScale(2)}]\n' +
                '[{! $var.var }]\n' +
            '{! /for }';

        String testCaseInsensitive =
            '{! var lowercasevar = \'lowercasevar\'}' +
            '{! var cammelCaseVar = \'cammelCaseVar\'}' +
            '{! var UPPERCASEVAR = \'UPPERCASEVAR\'}' +
            '[{! $var.LOWERCASEVAR}]\n[{! $var.LoWerCaSeVaR}]\n' +
            '[{! $var.cammelcasevar }]\n[{! $var.CAMMELCASEVAR }]\n' +
            '[{! $var.uppercasevar }]\n[{! $var.upperCaseVar }]\n';

        String testVariableMerges =
            '{! var nullVar = null}' +
            '{! var testVarDecimal1 = null}' +
            '{! var testVarDecimal2 = 0.00}' +
            '{! var testVarString = "test"}' +
            '{! for qli : QuoteLineItem | orderBy(\'Description\')}' +
                '{! var testVarDecimal1 : $var.testVarDecimal1 | add(null) | add(<! qli.Quantity >)}' +
                '{! var testVarDecimal2 : qli.Quantity | add(<! $var.testVarDecimal2>)}' +
                '{! var testVarString : $var.testVarString | addAfter(", ") | addAfter(<! qli.Description >)}' +
            '{! /for }' +
            '[{! $var.testVarDecimal1 | setScale(2) }]\n' +
            '[{! $var.testVarDecimal2 | setScale(2) }]\n' +
            '[{! $var.testVarString }]';


        String testVarKeywordResult = TemplateEngine.createFromString(testQuote.Id, testVarKeyword);
        String testCaseInsensitiveResult = TemplateEngine.createFromString(testQuote.Id, testCaseInsensitive);
        String testVariableMergesResult = TemplateEngine.createFromString(testQuote.Id, testVariableMerges);

        String[] varKeywordResults = testVarKeywordResult.split(' ');
        System.assert(varKeywordResults.size() >= 2, 'There should be at least two merged values.');
        System.assert(varKeywordResults[0].endsWithIgnoreCase('.00]'), 'Incorrect \'var\' key word interpretation.');
        System.assertEquals('[variable]', varKeywordResults[1], 'Incorrect \'var\' key word interpretation.');

        String caseInsensitiveTestFailMsg = 'TemplateEngine works with variables not in a case-insensitive manner.';
        String[] caseInsensitiveResults = testCaseInsensitiveResult.split(' ');
        System.assertEquals('[lowercasevar]', caseInsensitiveResults[0], caseInsensitiveTestFailMsg);
        System.assertEquals('[lowercasevar]', caseInsensitiveResults[1], caseInsensitiveTestFailMsg);
        System.assertEquals('[cammelCaseVar]', caseInsensitiveResults[2], caseInsensitiveTestFailMsg);
        System.assertEquals('[cammelCaseVar]', caseInsensitiveResults[3], caseInsensitiveTestFailMsg);
        System.assertEquals('[UPPERCASEVAR]', caseInsensitiveResults[4], caseInsensitiveTestFailMsg);
        System.assertEquals('[UPPERCASEVAR]', caseInsensitiveResults[5], caseInsensitiveTestFailMsg);

        String[] mergeResults = testVariableMergesResult.split(' ');
        System.assertEquals('[12.00]', mergeResults[0], 'wrong variable merge result');
        System.assertEquals('[12.00]', mergeResults[1], 'wrong variable merge result');
        System.assertEquals('[test,', mergeResults[2],
            'wrong variable merge result');

    }

    @isTest
    private static void testArithmeticFormatters() {
        createTestData();

        //Strings for testing addDecimal() method
        String addDecimalToValStr = '{! Subtotal | add(10.05)}';
        String subtractDecimalFromValStr = '{! Subtotal | add(-10.05)}';
        String addValToValStr = '{! Total_Initial_Payment__c | add(<! Contact_Center_Total_Initial_Payment__c >)}';

        //Strings for testing multiplyDecimal() method
        String mlpDecimalToValStr = '{! Subtotal | multiply(10.05)}';
        String mlpValByValStr = '{! Total_Initial_Payment__c | multiply(<! Contact_Center_Total_Initial_Payment__c >)}';
        String mlpValByZero = '{! Total_Initial_Payment__c | multiply(0)}';

        //Strings for testing divideDecimal() method
        String dvdValByValStr = '{! Total_Initial_Payment__c | divide(<! Contact_Center_Total_Initial_Payment__c >)}';
        String dvdValByZero = '{! Total_Initial_Payment__c | divide(0)}';

        //String for testing subtractDecimal method
        String subtractDecimalToValStr = '{! Subtotal | subtract(10.05)}';
        String subtractNegativeDecimalFromValStr = '{! Subtotal | subtract(-10.05)}';
        String subtractValToValStr = '{! Total_Initial_Payment__c | subtract(<! Contact_Center_Total_Initial_Payment__c >)}';


        //Results for addDecimal() method
        String addDecimalToValResult = TemplateEngine.createFromString(testQuote.Id, addDecimalToValStr);
        String subtractDecimalFromValResult = TemplateEngine.createFromString(testQuote.Id, subtractDecimalFromValStr);
        String addValToValResult = TemplateEngine.createFromString(testQuote.Id, addValToValStr);

        //Results for multiplyDecimal() method
        String mlpDecimalByValResult = TemplateEngine.createFromString(testQuote.Id, mlpDecimalToValStr);
        String mlpValByValResult = TemplateEngine.createFromString(testQuote.Id, mlpValByValStr);
        String mlpValByZeroResult = TemplateEngine.createFromString(testQuote.Id, mlpValByZero);

        //Results for divideDecimal()() method
        String dvdValByValResult = TemplateEngine.createFromString(testQuote.Id, dvdValByValStr);
        String dvdValByZeroResult = TemplateEngine.createFromString(testQuote.Id, dvdValByZero);

        //Results for subtractDecimal() method
        String subtractDecimalToValResult = TemplateEngine.createFromString(testQuote.Id, subtractDecimalToValStr);
        String subtractNegativeDecimalFromValResult = TemplateEngine.createFromString(testQuote.Id, subtractNegativeDecimalFromValStr);
        String subtractValToValResult = TemplateEngine.createFromString(testQuote.Id, subtractValToValStr);

        System.assertEquals('120010.05', addDecimalToValResult, 'The field value and number must be added');
        System.assertEquals('119989.95', subtractDecimalFromValResult, 'The number must be subtracted from another');
        System.assertEquals('119890.00', addValToValResult, 'Two field values must be added');

        System.assertEquals('1206000.0000', mlpDecimalByValResult, 'The field value and number must be multiplied');
        System.assertEquals('0.0000', mlpValByValResult, 'Two field values must be multiplied');
        System.assertEquals('0.00', mlpValByZeroResult, 'Two field values must be multiplied');

        System.assertEquals('', dvdValByValResult, 'First field value must be divided by another field value');
        System.assertEquals('', dvdValByZeroResult, 'After division by zero it should return null');

        System.assertEquals('119989.95', subtractDecimalToValResult, 'subtract() method returned with unexpected result');
        System.assertEquals('120010.05', subtractNegativeDecimalFromValResult, 'subtract() method returned with unexpected result');
        System.assertEquals('119890.00', subtractValToValResult, 'subtract() method returned with unexpected result');
    }

    @isTest
    static void testAsNumber() {
        createTestData();

        String templateStr = '{! Subtotal | asNumber(3) }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('120,000.000',templateStrResult);
    }

    @isTest
    private static void testAsNumberNoParam() {
        createTestData();

        String templateStr = '{! Subtotal | asNumber() }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('120,000.00',templateStrResult);
    }

    @isTest
    private static void testAsNumberNegParam() {
        createTestData();

        String templateStr = '{! Subtotal | asNumber(-1) }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('120,000',templateStrResult);
    }

    @isTest
    private static void testAsNumberBoundedScale() {
        TemplateEngine.FormatterHelper format = new TemplateEngine.FormatterHelper();

        Object realData = 0.0168;
        List<Object> filterArgsList = new List<Object>{2, 3};
        System.assertEquals('0.017', format.asNumber(realData, filterArgsList),
            'Wrong convertion of ' + realData + ' to string (with bounded [2, 3] scale).');

        realData = 75.0;
        System.assertEquals('75.00', format.asNumber(realData, filterArgsList),
            'Wrong convertion of ' + realData + ' to string (with bounded [2, 3] scale).');
    }

    @isTest
    private static void testAsDate() {
        createTestData();

        String defaultDateStr = '{! Start_Date__c | asDate() }';
        String defaultDateFrStr = '{! Start_Date__c | asDate(\'default\',\'fr\') }';
        String defaultDateCustomStr = '{! Start_Date__c | asDate(\'yyyy\') }';

        String defaultDateStrResult = TemplateEngine.createFromString(testQuote.Id, defaultDateStr);
        String defaultDateFrStrResult = TemplateEngine.createFromString(testQuote.Id, defaultDateFrStr);
        String defaultDateCustomStrResult = TemplateEngine.createFromString(testQuote.Id, defaultDateCustomStr);

        System.assertEquals('August 1<sup>st</sup>, 2017',defaultDateStrResult);
        System.assertEquals('1 août 2017',defaultDateFrStrResult);
        System.assertEquals('2017',defaultDateCustomStrResult);

    }

    @isTest
    private static void testPluralize() {
        createTestData();

        String templateStr = '{! Initial_Term_months__c } {! Initial_Term_months__c | pluralize(\'Month\',\'Months\') }, ' +
                             '{! Term_months__c } {! Term_months__c | pluralize(\'Month\',\'Months\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('10 Months, 21 Month',templateStrResult);

    }

    @isTest
    private static void testRename() {
        createTestData();

        String templateStr = '{! Name | rename(\'test\',\'PASS\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('quotePASS',templateStrResult);

    }

    @isTest
    private static void testSetScale() {
        createTestData();
        testQuote.Total_Number_of_Digital_Lines__c = 10;
        Triggers.switchOff();
        update testQuote;
        Triggers.switchOn();

        String templateStr = '{! Total_Number_of_Digital_Lines__c | setScale(3) }';
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('10.000',templateStrResult);

    }

    @isTest
    private static void testAddAfter() {
        createTestData();

        String templateStr = '{! Name | addAfter(\' is the quote name\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('quotetest is the quote name',templateStrResult);

    }

    @isTest
    private static void testTranslate_SpecialTerms() {
        createTestData();

        String templateStr = '{! Special_Terms__c | translate(\'special_terms__c\',\'fr\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('1 semaine gratuite de service',templateStrResult);

    }

    @isTest
    private static void testTranslate_PaymentPeriod() {
        createTestData();

        String templateStr = '{! payment_period__c | translate(\'Payment_Period__c\',\'fr\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Période de paiement mensuel', templateStrResult);

    }

    // Test Helpers
    // ===============

    @isTest
    private static void testToday() {
        createTestData();

        String templateStr = '{! $today }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        String today = String.valueOf(System.today()).substring(0, 10);
        System.assertEquals(today,templateStrResult.substring(0, 10));

    }

    @isTest
    private static void testBaseUrl() {
        createTestData();

        String templateStr = '{! $baseUrl }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        System.assertEquals(baseUrl,templateStrResult);

    }

    @isTest
    private static void testParams() {
        createTestData();
        createTestTemplate('{! $params.foo } {! $params.Language__c }', null, '{"foo":"PASS"}');

        String templateStrResult = TemplateEngine.createDoc(testQuote.Id, testTemplate.Id);

        System.assertEquals('PASS English',templateStrResult);

    }

    // Test Virtual Fields
    // ===============

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testVirtualFields() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }' +
                '{! qli.$subtotal }, ' +
                '{! qli.$servicePlanRatePerMonth }, ' +
                '{! qli.$servicePlanRatePerYear }, ' +
                '{! qli.$ratePerMonth }, ' +
                '{! qli.$ratePerYear }, ' +
                '{! qli.$newProposalTotal }, ' +
                '{! qli.$newProposalTotal }, ' +
                '{! qli.$overallNewProposalTotalAnnualPrice }, ' +
                '{! qli.$overallNewProposalTotalMonthlyPrice }, ' +
                '{! qli.$totalMonthlyAmount }, ' +
                '{! qli.$overallOneTimePayment }, ' +
                '{! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
    }

    @isTest
    private static void testVirtualTotalAnnualAmount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Permitted_Brands__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'prod1',
                Product2.IsActive => true,
                Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                Product2.Charge_Term__c => 'Monthly',
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Initial_Term_months__c => '10',
                Quote.Term_months__c => '21',
                Quote.Special_Terms__c => '1 Free Week of Service',
                Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                Quote.Special_Notes__c => 'test1;',
                Quote.JustificationandDescription__c => 'test1;test2;',
                Quote.Payment_Period__c => 'Monthly Payment Period',
                Quote.Total_Initial_Payment__c => 100.00,
                Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();

        Entitlement__c entitlement1 = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Product__c => testProduct.Id,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Price__c => 11
            })
            .create()
            .getRecord();

        String templateStr = '{! for qli : QuoteLineItem }' +
                '{! /for }' +
                '{! qli.$TotalAnnualAmount }';

        Test.startTest();
        QuoteLineItem testQLI1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => 'prod1 Desc',
                QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PriceBookEntryId => testPrice.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_number__c => 10,
                QuoteLineItem.NewQuantity__c => 5
            })
            .create()
            .getRecord();
            String templateStrResult = TemplateEngine.createFromString(qt.Id, templateStr);

            List<QuoteLineItem> qliList = [SELECT Id, EffectivePriceNew__c,
                    Product2.Charge_Term__c, Zero_Quantity__c, Quantity,
                    EffectivePrice__c, QuoteRecordType__c, Quote.RecordTypeId
                FROM QuoteLineItem
                WHERE QuoteId = :qt.Id];

            Decimal calculatedTotalAnnualAmount = 0;
            for(QuoteLineItem qli : qliList) {
                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                    continue;
                }

                Decimal qliEffectivePrice = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;
                Decimal qliQuantity = QuoteLineItemHelper.getQuantity(qli);

                if(qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                    calculatedTotalAnnualAmount += (qliEffectivePrice * qliQuantity);
                }else{
                    calculatedTotalAnnualAmount += ((qliEffectivePrice * qliQuantity) * 12);
                }
            }
            System.assertEquals(calculatedTotalAnnualAmount, Decimal.valueOf(templateStrResult));
        Test.stopTest();
    }

    @isTest
    private static void testEmbeddedLoops() {
        createTestData();

        List<QuoteLineItem> qliList = [select Id, Product2Id, Product2.Name from QuoteLineItem where QuoteId = :testQuote.Id];

        Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

        // Phases
        Phase__c testPhase1 = new Phase__c(
            Name = 'testPhase_1',
            Opportunity__c = testQuote.OpportunityId,
            Quote__c = testQuote.Id,
            RecordTypeId = proServPhaseRTId
        );

        Phase__c testPhase2 = new Phase__c(
            Name = 'testPhase_2',
            Opportunity__c = testQuote.OpportunityId,
            Quote__c = testQuote.Id,
            RecordTypeId = proServPhaseRTId
        );

        List<Phase__c> phasesList = new List<Phase__c>{
            testPhase1,
            testPhase2
        };

        insert phasesList;


            List<Hardware_Line_Item__c> hliList = new List<Hardware_Line_Item__c>();

            for(QuoteLineItem qli : qliList) {
                for(Phase__c ph : phasesList) {
                    hliList.add(
                        new Hardware_Line_Item__c(
                            Name = 'test PhaseLineItem for phase ' + ph.Name,
                            Quantity__c = 3,
                            Quote_Line_Item__c = qli.Id,
                            RingCentral_Hardware_Phase__c = ph.Id
                        )
                    );
                }
            }
            insert hliList;

            String templateStr = '{! for ph : Phase__c | orderBy(\'Name ASC\') | linkBy(\'Quote__c\') }' +
                '{! ph.Name }, ' +
                    '{! for pli : ph.Hardware_Line_Item__c }' +
                        'Name: {! pli.Name } ; Quantity: {! pli.Quantity__c } ; ' +
                    '{! /for }' +
                '{! /for }';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            String resultTemplate =
                'testPhase_1, ' +
                'Name: test PhaseLineItem for phase testPhase_1 ; Quantity: 3 ; ' +
                'Name: test PhaseLineItem for phase testPhase_1 ; Quantity: 3 ; ' +
                'Name: test PhaseLineItem for phase testPhase_1 ; Quantity: 3 ; ' +
                'testPhase_2, ' +
                'Name: test PhaseLineItem for phase testPhase_2 ; Quantity: 3 ; ' +
                'Name: test PhaseLineItem for phase testPhase_2 ; Quantity: 3 ; ' +
                'Name: test PhaseLineItem for phase testPhase_2 ; Quantity: 3 ;';
            System.assertEquals(resultTemplate, templateStrResult);

    }

    @isTest
    private static void testLookupLoops() {
        createTestData();

        String templateStr = '{! for qt : OpportunityId.Quote | orderBy(\'Name ASC\')}[{! qt.Name }]{! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        String resultTemplate = '[quotetest][quotetestPS]';
        System.assertEquals(resultTemplate, templateStrResult, 'Names from all quotes should be displayed');

    }

    @isTest
    private static void testLinkByLoops() {
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .quantity(2)
            .create()
            .getRecords();
        Account acc1 = accs.get(0);
        Account acc2 = accs.get(1);

        SObjectBuilder oppRecords = new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .quantity(2)
            .build();

        Opportunity opp1 = ((Opportunity) oppRecords.getRecord(0));
        Opportunity opp2 = ((Opportunity) oppRecords.getRecord(1));
        opp1.Name = 'Test Opportunity 1';
        opp1.AccountId = acc1.Id;
        opp2.Name = 'Test Opportunity 2';
        opp2.AccountId = acc2.Id;
        opp2.Partner_Account__c = acc1.Id;

        insert oppRecords.getRecords();

        String templateStr1 = '{! for opp : AccountId.Opportunity | linkBy(\'AccountId\') }[{! opp.Name }]{! /for }';
        String templateStr2 = '{! for opp : AccountId.Opportunity | linkBy(\'Partner_Account__c\') }[{! opp.Name }]{! /for }';

        Test.startTest();
        String templateStrResult1 = TemplateEngine.createFromString(opp1.Id, templateStr1);
        String templateStrResult2 = TemplateEngine.createFromString(opp1.Id, templateStr2);

        System.assertEquals('[Test Opportunity 1]', templateStrResult1, 'Opportunity with AccountId = opp1.AccountId should be displayed');
        System.assertEquals('[Test Opportunity 2]', templateStrResult2, 'Opportunity with Partner_Account__c = opp1.AccountId should be displayed');

        Test.stopTest();
    }

    @isTest
    private static void testIsTaxesInCart() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } {! qli.$isTaxesInCart }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.debug('templateStrResult >>> ' + templateStrResult);
        System.assertEquals('Item, Item, Item, false',templateStrResult);
    }

    @isTest
    private static void testOverallTaxesPayment_Monthly() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePayment | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPrice | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 10', templateStrResult);
    }

    @isTest
    private static void testOverallTaxesPayment_MonthlyContract() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY_CONTRACT)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePayment | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPrice | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 10', templateStrResult);
    }

    @isTest
    private static void testOverallTaxesPayment_Annual() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_ANNUAL)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePayment | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPrice | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 10', templateStrResult);
    }

    @isTest
    private static void testOverallTotal12MonthAmount() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } {! qli.$overallOneTimePayment }, {! qli.$overallNewProposalTotalPrice }, {! qli.$overallTotal12MonthAmount }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Item, Item, Item, 0, 92412.000000, 1108944.000000', templateStrResult);

    }

    @isTest
    private static void testSubtotal() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem | orderBy (\'Product2.Name ASC\')}[{! qli.$subtotal }] {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        String expectedResult1 = '[49950.000000]';
        String expectedResult2 = '[39964.000000]';
        String expectedResult3 = '[2498.000000]';

        System.assert(templateStrResult.contains(expectedResult1)
                && templateStrResult.contains(expectedResult2)
                && templateStrResult.contains(expectedResult3),
                String.format('Expected {0}, {1}, {2} to be in result but got: {3}', new String[]{
                        expectedResult1,
                        expectedResult2,
                        expectedResult3,
                        templateStrResult
                }));

    }

    @isTest
    private static void testSubtotalConsideringChargeTerm() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem | orderBy(\'Product2.Name ASC\')}[{! qli.$subtotalConsideringChargeTerm }] {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('[49950.000000] [39964.000000] [2498.000000]', templateStrResult);
    }

    @isTest
    private static void testTotalMonthlyAmount() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } [{! qli.$totalMonthlyAmount | setScale(2) }]';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Item, Item, Item, [92412.00]', templateStrResult);

    }

    @isTest
    private static void testOverallNewProposalTotalAnnualPrice() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } [{! qli.$overallNewProposalTotalAnnualPrice | setScale(2) }]';

        testQuote.Payment_Plan__c = 'Annual';
        update testQuote;

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Item, Item, Item, [29976.00]', templateStrResult);

    }

    @isTest
    private static void testOverallNewProposalTotalMonthlyPrice() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } [{! qli.$overallNewProposalTotalMonthlyPrice | setScale(2) }]';

        testQuote.Payment_Plan__c = 'Monthly';
        update testQuote;

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Item, Item, Item, [49950.00]', templateStrResult);

    }

    @isTest
    private static void testTotalFirstYearAmount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Permitted_Brands__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'prod1',
                Product2.IsActive => true,
                Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                Product2.Charge_Term__c => 'Monthly',
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Initial_Term_months__c => '10',
                Quote.Term_months__c => '21',
                Quote.Special_Terms__c => '1 Free Week of Service',
                Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                Quote.Special_Notes__c => 'test1;',
                Quote.JustificationandDescription__c => 'test1;test2;',
                Quote.Payment_Period__c => 'Monthly Payment Period',
                Quote.Total_Initial_Payment__c => 100.00,
                Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();

        Entitlement__c entitlement1 = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Product__c => testProduct.Id,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Price__c => 11
            })
            .create()
            .getRecord();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } [{! qli.$totalFirstYearAmount | setScale(2) }]';

        Test.startTest();
        QuoteLineItem testQLI1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => 'prod1 Desc',
                QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PriceBookEntryId => testPrice.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_number__c => 10,
                QuoteLineItem.NewQuantity__c => 5
            })
            .create()
            .getRecord();
        String templateStrResult = TemplateEngine.createFromString(qt.Id, templateStr);
        Test.stopTest();

        System.assertEquals('Item, [599400.00]', templateStrResult);

    }

    @isTest
    private static void testTotalInitialAmount() {
        createTestData();

        String templateStr = '{! for qli : QuoteLineItem }Item, {! /for } [{! qli.$totalInitialAmount | setScale(2) }]';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Item, Item, Item, [92412.00]', templateStrResult);

    }

    @isTest
    private static void testDLsInitiallyPurchased() {
        createTestData();

        String templateStr = '[{! qli.$DLsInitiallyPurchased | setScale(0) }] {! for qli : QuoteLineItem }Item, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('[12] Item, Item, Item,', templateStrResult);

    }

    @isTest
    private static void testSummNewQuantity() {
        createTestData();

        String templateStr = '[{! qli.$summNewQuantity | setScale(0) }] {! for qli : QuoteLineItem }Item, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('[12] Item, Item, Item,', templateStrResult);

    }
    // Test Virtual Objects
    // ===============

    @isTest
    private static void testBillingContact() {
        createTestData();

        String templateStr = 'Billing Contact Name: [{! $BillingContact.Name }]';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('Billing Contact Name: [Doe John]',templateStrResult);

    }

    @isTest
    private static void testSignatoryContact() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        OpportunityContactRole testSignatoryContactRole = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.ContactId =>  contact.Id,
                OpportunityContactRole.Role =>  OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                OpportunityContactRole.isPrimary => true})
        .create()
        .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            }
        )
        .create()
        .getRecord();

        String templateStr = 'Signatory Contact Name: [{! $SignatoryContact.Name }]';

        Test.startTest();
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('Signatory Contact Name: [Doe]', templateStrResult, 'SignatoryContact virtual field is wrong');

    }

    // Test Virtual Objects in loops
    // ===============

    @isTest
    private static void testGetParentChilds() {
        createTestData();

        String templateStr = '{! for ent : AccountId.Entitlement__c | orderBy(\'Product__r.Name ASC\')}{! ent.Product__r.Name }, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('prod1, prod2, prod5, prod6,', templateStrResult);
    }

    @isTest
    private static void testChangeOrderTable() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! item.$name }, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('prod1, prod1, prod2, prod2, prod3,', templateStrResult);
    }

    @isTest
    private static void testChangeOrderTableForNGBS() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Permitted_Brands__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'prod1',
                Product2.IsActive => true,
                Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                Product2.Charge_Term__c => 'Monthly',
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Initial_Term_months__c => '10',
                Quote.Term_months__c => '21',
                Quote.Special_Terms__c => '1 Free Week of Service',
                Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                Quote.Special_Notes__c => 'test1;',
                Quote.JustificationandDescription__c => 'test1;test2;',
                Quote.Payment_Period__c => 'Monthly Payment Period',
                Quote.Total_Initial_Payment__c => 100.00,
                Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();

        Entitlement__c entitlement1 = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Product__c => testProduct.Id,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Price__c => 11
            })
            .create()
            .getRecord();

        Test.startTest();
            QuoteLineItem testQLI1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => 'prod1 Desc',
                QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PriceBookEntryId => testPrice.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_number__c => 10,
                QuoteLineItem.NewQuantity__c => 5
            })
            .create()
            .getRecord();
            qt.RecordTypeId = QuoteHelper.RT_ID_BILLING;
            update qt;

            String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! item.$name }, {! /for }';

            String templateStrResult = TemplateEngine.createFromString(qt.Id, templateStr);
        Test.stopTest();

        // NGBS Entitlements Retrieved
        System.assertEquals('prod1,', templateStrResult);
    }

    @isTest
    private static void testChangeOrderTableGetQuoteLineItemField() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! item.QuoteLineItem.Product2.Name }, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals(', prod1, , prod2, prod3,', templateStrResult);
    }

    @isTest
    private static void testChangeOrderTableGetEntitlementField() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! item.$name }: {! item.Entitlement__c.Price__c | asCurrency() }, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('prod1: $11.00, prod1: , prod2: $10.00, prod2: , prod3: ,', templateStrResult);
    }

    @isTest
    private static void testChangeOrderTableGetSObjectVirtualField() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}{! item.$name }:{! item.QuoteLineItem.$newRate }, {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('prod1:, prod1:9990.00, prod2:, prod2:9991.00, prod3:9992.00,', templateStrResult);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testChangeOrderTableAggregateTotals() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable }{! /for }[{! item.$summChangeMonthlySubtotal }], [{! item.$summChangeAnnualSubtotal }], [{! item.$summChangeOneTimeSubtotal }]';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
    }

    @isTest
    private static void testChangeOrderGetQuoteRecordTypeName() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable } {! item.QuoteLineItem.QuoteRecordType__c} {! /for }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assert(templateStrResult.containsIgnoreCase(QuoteHelper.RT_NAME_SALES),
        'Expected to contain: ' + QuoteHelper.RT_NAME_SALES + ', Actual: ' + templateStrResult);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testIsProServEngaged() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Permitted_Brands__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.EstimatedProfessionalServices12Month__c => 3
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'prod1',
                Product2.IsActive => true,
                Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                Product2.Charge_Term__c => 'Monthly',
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10000,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Initial_Term_months__c => '10',
                Quote.Term_months__c => '21',
                Quote.Special_Terms__c => '1 Free Week of Service',
                Quote.Start_Date__c => Date.newInstance(2017, 8, 1),
                Quote.Special_Notes__c => 'test1;',
                Quote.JustificationandDescription__c => 'test1;test2;',
                Quote.Payment_Period__c => 'Monthly Payment Period',
                Quote.Total_Initial_Payment__c => 100.00,
                Quote.Contact_Center_Total_Initial_Payment__c => 10.00,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
            })
            .create()
            .getRecord();

        Entitlement__c entitlement1 = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Product__c => testProduct.Id,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Price__c => 11
            })
            .create()
            .getRecord();

        String templateStr = '{! $isProServEngaged }';

        Test.startTest();
        QuoteLineItem testQLI1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => 'prod1 Desc',
                QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PriceBookEntryId => testPrice.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_number__c => 10,
                QuoteLineItem.NewQuantity__c => 5
            })
            .create()
            .getRecord();
        String templateStrResult = TemplateEngine.createFromString(qt.Id, templateStr);
        Test.stopTest();

        // System.assertEquals('true', templateStrResult);
    }

    @isTest
    private static void testCostCenterLineItemDistribution() {
        createTestData();

        String templateStr = '{! for item: OpportunityId.Quote | orderBy(\'Name ASC\') } ' +
                                ' {!item.Name} ' +
                                ' {! for item1 : item.Cost_Center__c | orderBy(\'Name ASC\') } ' +
                                ' {! item1.Name} ' +
                                    ' {! for item2 : item1.Cost_Center_Line_Item__c | orderBy(\'Quote_Line_Item__r.UnitPrice DESC\') }' +
                                        ' {! item2.$initialCostCenterLineItemSubTotal} ' +
                                    ' {! /for } ' +
                                ' {! /for } ' +
                            ' {! /for } ';
        Cost_Center__c testCostCenter1 = TestDataGenerator.createCostCenter('Cost Center 1 ', testQuote);
        Cost_Center__c testCostCenter2 = TestDataGenerator.createCostCenter('Cost Center 2 ', testQuote);

        List<QuoteLineItem> qliList = [SELECT Id, Discount, UnitPrice, Quantity FROM QuoteLineItem];

        List<Cost_Center_Line_Item__c> ccliList = new List<Cost_Center_Line_Item__c>();
        for (QuoteLineItem qli : qliList) {
            Cost_Center_Line_Item__c testCostCenterLineItem = new Cost_Center_Line_Item__c(
                Cost_Center__c = testCostCenter1.Id,
                Quote_Line_Item__c = qli.Id,
                Quantity__c = qli.Quantity
            );
            ccliList.add(testCostCenterLineItem);
        }
        insert ccliList;

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('quotetest Cost Center 1 49950.00000 39964.000000 29976.000000 29976.000000 Cost Center 2 quotetestPS', templateStrResult);
    }

    @isTest
    private static void testCurrentSubtotal() {
        createTestData();

        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
                            ' {! item.$currentItemSubtotal}' + '{!/for}';

        List<QuoteLineItem> qliList = [
            SELECT Id, EffectivePriceNew__c, Last_Approved_Quantity__c, Last_Approved_Discount__c
            FROM QuoteLineItem
        ];

            Integer counter = 0;
            for (QuoteLineItem qli : qliList) {
                counter++;
                qli.Last_Approved_Quantity__c = null;
                qli.Last_Approved_Discount__c = null;
            }
            Triggers.switchOff();
            update qliList;
            Triggers.switchOn();

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('49950.0000 39964.0000 29976.0000', templateStrResult);
    }

    @isTest
    private static void testDependentOnFeatureQli() {
        createTestData();

        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
            '[{! item.Product2.Name } - {! item.$dependentOnFeature.Product2.Name }]' + '{!/for}';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('[prod1 - ][prod2 - prod3][prod3 - ]', templateStrResult);
    }

    @isTest
    private static void testChangeOrderDependentOnFeatureQli() {
        createTestData();

        String templateStr = '{! for item : $ChangeOrderTable | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
            '[{! item.$name } - {! item.$dependentOnFeature.$name }]' + '{!/for}';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('[prod1 - ][prod1 - ][prod2 - prod3][prod2 - prod3][prod3 - ]', templateStrResult);
    }

    @isTest
    private static void testSize() {
        createTestData();

        String templateStr = '{!for item : QuoteLineItem }{! item.$size }{!/for}|{! item.$size }';
        String templateStrChangeOrder = '{!for item : $changeOrderTable }{! item.$size }{!/for}|{! item.$size }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        String templateStrChangeOrderResult = TemplateEngine.createFromString(testQuote.Id, templateStrChangeOrder);


        System.assertEquals('333|3', templateStrResult);
        System.assertEquals('55555|5', templateStrChangeOrderResult);
    }
    // Test Virtual fields
    // ===============
    @isTest
    private static void testNewRaterAnnualSubtotal() {
        createTestData();

        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\') }{! item.$newRaterAnnualSubtotal | setScale(1)}, {!/for} summ : {! item.$summNewRaterAnnualSubtotal | setScale(1)}';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('599400.0, 479568.0, 29976.0, summ : 1108944.0', templateStrResult);
    }
    // Test Virtual fields
    // ===============
    @isTest
    private static void testNewRaterMonthlySubtotal() {
        createTestData();

        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\') }{! item.$newRaterMonthlySubtotal | setScale(1)}, {!/for} summ : {! item.$summNewRaterMonthlySubtotal | setScale(1)}';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('49950.0, 39964.0, 2498.0, summ : 92412.0', templateStrResult);
    }

    @isTest
    private static void testCalculateSumAndMonthlySubtotal() {
        createTestData();

        String templateStr = '{! for ent : Entitlement__c | orderBy(\'Name\') } ' +
                                ' {! ent.$EntMonthlySubtotal } ' +
                            ' {! /for } ' +
                            ' {! ent.$SumEntMonthlySubtotal } ';
        String resultString = '';
        Decimal sumMonthlySubtotal = 0;

        List<Entitlement__c> entitlements = [
            SELECT EffectivePrice__c, DisplayQuantity__c, Account__c,
                Product__r.Family, Product__r.Charge_Term__c, ChargeTerm__c
            FROM Entitlement__c
            WHERE Quote__c = :testQuote.Id
            ORDER BY Name
        ];
        List<sObject> entitlementsObjs = (List<sObject>) entitlements;
        sObject quoteObj = (sObject) testQuote;

        TemplateEngine.VirtualField virtualField = new TemplateEngine.VirtualField();

        for (Entitlement__c ent : entitlements) {
            String terms = ent.ChargeTerm__c;
            Decimal effectivePrice = ((Decimal) NumberHelper.getNumberNullSafe(ent.EffectivePrice__c)).setScale(2, RoundingMode.HALF_UP);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent.DisplayQuantity__c);

            switch on terms {
                when 'Annual' {
                    Decimal subTotal = (effectivePrice * displayQuantity) / 12;
                    resultString += String.valueOf(subTotal) + '    ';
                    sumMonthlySubtotal += subTotal;
                }
                when 'One - Time' {
                    resultString += '0 ';
                }
                when else {
                    Decimal subTotal = effectivePrice * displayQuantity;
                    if (terms != null) {
                        resultString += String.valueOf(subTotal) + ' ';
                        sumMonthlySubtotal += subTotal;
                    } else {
                        resultString += '0 ';
                    }
                }
            }
        }
        resultString += String.valueOf(sumMonthlySubtotal).trim();

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();

        System.assertEquals(
            resultString,
            templateStrResult,
            'Template was returned incorrectly after calculating Monthly Subtotals.'
        );
    }

    @isTest
    private static void testCalculateSumAndAnnualSubtotal() {
        createTestData();

        String templateStr = '{! for ent : Entitlement__c | orderBy(\'Name\') } ' +
                                ' {! ent.$EntAnnualSubtotal } ' +
                            ' {! /for } ' +
                            ' {! ent.$SumEntAnnualSubtotal } ';
        String resultString = '';
        Decimal sumAnnualSubtotal = 0;

        List<Entitlement__c> entitlements = [
            SELECT EffectivePrice__c, DisplayQuantity__c, Account__c,
                Product__r.Family, Product__r.Charge_Term__c, ChargeTerm__c
            FROM Entitlement__c
            WHERE Quote__c = :testQuote.Id
            ORDER BY Name
        ];
        List<sObject> entitlementsObjs = (List<sObject>) entitlements;
        sObject quoteObj = (sObject) testQuote;

        TemplateEngine.VirtualField virtualField = new TemplateEngine.VirtualField();

        for (Entitlement__c ent : entitlements) {
            String terms = ent.ChargeTerm__c;
            Decimal effectivePrice = ((Decimal) NumberHelper.getNumberNullSafe(ent.EffectivePrice__c)).setScale(2, RoundingMode.HALF_UP);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent.DisplayQuantity__c);

            switch on terms {
                when 'Annual' {
                    Decimal subTotal = effectivePrice * displayQuantity;
                    resultString += String.valueOf(subTotal) + '    ';
                    sumAnnualSubtotal += subTotal;
                }
                when 'One - Time' {
                    resultString += '0 ';
                }
                when else {
                    Decimal subTotal = effectivePrice * displayQuantity * 12;
                    if (terms != null) {
                        resultString += String.valueOf(subTotal) + ' ';
                        sumAnnualSubtotal += subTotal;
                    } else {
                        resultString += '0 ';
                    }
                }
            }
        }
        resultString += String.valueOf(sumAnnualSubtotal).trim();

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();

        System.assertEquals(
            resultString,
            templateStrResult,
            'Template was returned incorrectly after calculating Annual Subtotals.'
        );
    }

    @isTest
    private static void testCalculateSumAndOneTimeSubtotal() {
        createTestData();

        String templateStr = '{! for ent : Entitlement__c | orderBy(\'Name\') } ' +
                                ' {! ent.$EntOneTimeSubtotal } ' +
                            ' {! /for } ' +
                            ' {! ent.$SumEntOneTimeSubtotal } ';
        String resultString = '';
        Decimal sumOneTimeSubtotal = 0;
        Set<Id> prodIds = new Set<Id>();

        List<Entitlement__c> entitlements = [
            SELECT EffectivePrice__c, DisplayQuantity__c,
                Product__r.Family, Product__r.Charge_Term__c, ChargeTerm__c,
                Account__c, Product__c
            FROM Entitlement__c
            WHERE Quote__c = :testQuote.Id
        ];

        List<sObject> entitlementsObjs = (List<sObject>) entitlements;
        sObject quoteObj = (sObject) testQuote;

        TemplateEngine.VirtualField virtualField = new TemplateEngine.VirtualField();

        for (Entitlement__c ent : entitlements) {
            String terms = ent.ChargeTerm__c;
            Decimal effectivePrice = (Decimal) NumberHelper.getNumberNullSafe(ent.EffectivePrice__c);
            Decimal displayQuantity = (Decimal) NumberHelper.getNumberNullSafe(ent.DisplayQuantity__c);
            Decimal subTotal = effectivePrice * displayQuantity;

            resultString += (
                (terms != null
                && terms.equalsIgnoreCase(Product2Helper.CHARGE_TERM_ONE_TIME))
                ? String.valueOf(subTotal)
                : '0 '
            ) + '';
            if (terms != null
                && terms.equalsIgnoreCase(Product2Helper.CHARGE_TERM_ONE_TIME)) {
                sumOneTimeSubtotal += subTotal;
            }
        }
        resultString += String.valueOf(sumOneTimeSubtotal).trim();

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();

        System.assertEquals(
            resultString,
            templateStrResult,
            'Template was returned incorrectly after calculating One Time Subtotals.'
        );
    }

    @isTest
    private static void testProductTableItemSortUsingQLISortOrder() {

        List<Product2> productList = new List<Product2>();

        Product2 subscriptionProduct = new Product2(
            Name = 'RingCentral Meetings Subscription',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        productList.add(subscriptionProduct);

        Product2 meetingsProduct = new Product2(
            Name = 'Meetings',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        productList.add(meetingsProduct);

        Product2 largeMeetingsProduct = new Product2(
            Name = 'Large Meeting 200',
            IsActive = true,
            Sub_Category__c = 'Main',
            GOA_Group_V2__c = 'RC_Meetings'
        );
        productList.add(largeMeetingsProduct);


        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        qliList.add(
            new QuoteLineItem(
                Product2 = subscriptionProduct,
                Sort_Order__c = 0
            )
        );

        qliList.add(
            new QuoteLineItem(
                Product2 = meetingsProduct,
                Sort_Order__c = 1
            )
        );

        qliList.add(
            new QuoteLineItem(
                Product2 = largeMeetingsProduct,
                Sort_Order__c = 2
            )
        );

        List<TemplateEngine.ProductTableItem> ptiList = new List<TemplateEngine.ProductTableItem>();
        for(QuoteLineItem qli : qliList) {
            ptiList.add(
                new TemplateEngine.ProductTableItem(
                    qli.Product2.Family,
                    qli.Product2.Name,
                    qli.Product2.Dependent_On_Feature__c,
                    qli
                )
            );
        }

            // should be sorted using QuoteLineItem.Sort_Order__c field(in descending order)
            ptiList.sort();

            System.assertEquals(
                'Large Meeting 200',
                ptiList.get(0).Name,
                '"Large Meeting 200" product should be first in list(this product has Sort_Order__c = 2 and descending order used)'
            );
            System.assertEquals(
                'Meetings',
                ptiList.get(1).Name,
                '"Meetings" product should be second in list(this product has Sort_Order__c = 1 and descending order used'
            );
            System.assertEquals(
                'RingCentral Meetings Subscription',
                ptiList.get(2).Name,
                '"RingCentral Meetings Subscription" product should be third in list(this product has Sort_Order__c = 0 and descending order used'
            );

    }

    @isTest
    private static void testProductTableItemSortUsingEntitlementSortOrder() {

        List<Product2> productList = new List<Product2>();

        Product2 subscriptionProduct = new Product2(
            Name = 'RingCentral Meetings Subscription',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        productList.add(subscriptionProduct);

        Product2 meetingsProduct = new Product2(
            Name = 'Meetings',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
        productList.add(meetingsProduct);

        Product2 largeMeetingsProduct = new Product2(
            Name = 'Large Meeting 200',
            IsActive = true,
            Sub_Category__c = 'Main',
            GOA_Group_V2__c = 'RC_Meetings'
        );
        productList.add(largeMeetingsProduct);


        List<Entitlement__c> entlList = new List<Entitlement__c>();
        entlList.add(
            new Entitlement__c(
                Product__r = subscriptionProduct,
                Sort_Order__c = 0
            )
        );

        entlList.add(
            new Entitlement__c(
                Product__r = meetingsProduct,
                Sort_Order__c = 1
            )
        );

        entlList.add(
            new Entitlement__c(
                Product__r = largeMeetingsProduct,
                Sort_Order__c = 2
            )
        );

        List<TemplateEngine.ProductTableItem> ptiList = new List<TemplateEngine.ProductTableItem>();
        for(Entitlement__c entl : entlList) {
            ptiList.add(
                new TemplateEngine.ProductTableItem(
                    entl.Product__r.Family,
                    entl.Product__r.Name,
                    entl.Product__r.Dependent_On_Feature__c,
                    entl
                )
            );
        }

            // should be sorted using Entitlement__c.Sort_Order__c field(in descending order)
            ptiList.sort();

            System.assertEquals(
                'Large Meeting 200',
                ptiList.get(0).Name,
                '"Large Meeting 200" product should be first in list(this product has Sort_Order__c = 2 and descending order used)'
            );
            System.assertEquals(
                'Meetings',
                ptiList.get(1).Name,
                '"Meetings" product should be second in list(this product has Sort_Order__c = 1 and descending order used'
            );
            System.assertEquals(
                'RingCentral Meetings Subscription',
                ptiList.get(2).Name,
                '"RingCentral Meetings Subscription" product should be third in list(this product has Sort_Order__c = 0 and descending order used'
            );

    }

    @isTest
    private static void testEntitlementChargeTerm() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                }
            )
            .create()
            .getRecord();

        Entitlement__c e = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Product__c => ValueProviderBuilder.provideGenericParent(
                        Product2.sObjectType,
                        new Map<SObjectField, Object> {
                            Product2.Family => Product2Helper.FAMILY_SERVICE,
                            Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL
                        }
                    )
                }
            )
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => opp.Id,
                    Quote.CurrentService__c => e.Id}
            )
            .create()
            .getRecord();

        String templateStr = '{! for ent: AccountId.Entitlement__c }{! ent.$entitlementTotal }{! /for }';

        Test.startTest();
            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            String chargeTerm = String.valueOf(vf.entitlementChargeTerm(new List<sObject> { e }, q));
            String templateStrResult = TemplateEngine.createFromString(q.Id, templateStr);
        Test.stopTest();

        System.assertEquals(Product2Helper.CHARGE_TERM_ANNUAL, chargeTerm, 'Got wrong current Quote\'s charge term');
        System.assertEquals('10.00', templateStrResult, 'Got wrong Entitlement Total');
    }

    @isTest
    private static void testSummEntitlementTotal() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                }
            )
            .create()
            .getRecord();

        Entitlement__c e = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Product__c => ValueProviderBuilder.provideGenericParent(
                        Product2.sObjectType,
                        new Map<SObjectField, Object> {
                            Product2.Family => Product2Helper.FAMILY_SERVICE,
                            Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL
                        }
                    )
                }
            )
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => opp.Id,
                Quote.CurrentService__c => e.Id}
            )
            .create()
            .getRecord();

        String templateStr = '{! for ent: AccountId.Entitlement__c }{! ent.$summEntitlementTotal }{! /for }';

        Test.startTest();
        String templateStrResult = TemplateEngine.createFromString(q.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10.00', templateStrResult, 'Got wrong Entitlement Total');
    }

    @isTest
    private static void testSummEntitlementSubtotalTotal() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                }
            )
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString(),
                Product2.Charge_Term__c => ValueProviderBuilder.provideList(new List <String> {Product2Helper.CHARGE_TERM_ANNUAL, Product2Helper.CHARGE_TERM_MONTHLY}),
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_SERVICE
            })
            .quantity(2)
            .create()
            .getRecords();

        Entitlement__c e = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Product__c => testProducts[0].Id
                }
            )
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => opp.Id,
                Quote.CurrentService__c => e.Id}
            )
            .create()
            .getRecord();

        List<Entitlement__c> testEntitlements = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Entitlement__c.ChargeTerm__c => ValueProviderBuilder.provideList(new List <String> {Product2Helper.CHARGE_TERM_ANNUAL, Product2Helper.CHARGE_TERM_MONTHLY}),
                Entitlement__c.Price__c => ValueProviderBuilder.provideList(new List <Integer> {15, 10}),
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Quote__c => q.Id,
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(new List <String>{testProducts[0].Id, testProducts[1].Id})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Id> ids = new List<Id>{e.Id};

        for(Entitlement__c ent : testEntitlements){
            ids.add(ent.Id);
        }

        List<SObject> ents = [select Id, ChargeTerm__c, Total_Annual_Price__c, Total_Monthly_Price__c FROM Entitlement__c where Id IN: ids];

        String templateStr = '{! for ent: AccountId.Entitlement__c }Item, {! /for } {! ent.$summEntitlementAnnualTotal | setScale(2) }, {! ent.$summEntitlementMonthlyTotal | setScale(2) }';

        Test.startTest();
        TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
        Decimal summEntitlementAnnualTotal = 0;
        summEntitlementAnnualTotal += Decimal.valueOf(String.valueOf(vf.summEntitlementAnnualTotal(ents, q)));
        Decimal summEntitlementMonthlyTotal = 0;
        summEntitlementMonthlyTotal += Decimal.valueOf(String.valueOf(vf.summEntitlementMonthlyTotal(ents, q)));
        Test.stopTest();

        System.assertEquals(Decimal.valueOf('40.00'), summEntitlementAnnualTotal);
        System.assertEquals(Decimal.valueOf('10.00'), summEntitlementMonthlyTotal);

    }

    @isTest
    private static void testEntitlementChargeTerm_NoCurrentServiceOnQuote() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                }
            )
            .create()
            .getRecord();

        Entitlement__c e = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_ANNUAL}
            )
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> { Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => opp.Id,
                    Quote.CurrentService__c => null}
            )
            .create()
            .getRecord();

        Test.startTest();
            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            String chargeTerm = String.valueOf(vf.entitlementChargeTerm(new List<sObject> { e }, q));
        Test.stopTest();

        System.assertEquals('COULDN\'T FIND SERVICE ENTITLEMENT FOR QUOTE!', chargeTerm, 'Current Quote\'s charge term shouldn\'t has been found!' );
    }

    @isTest
    private static void testOverageWithNonZeroQuantityEntitlement() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAcc.Id)
            .setField(Opportunity.CloseDate, ValueProviderBuilder.provideUniqueDate())
            .setField(Opportunity.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Payment_Plan__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .setField(Quote.PriceBook2Id, testPriceBook.Id)
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Account__c, testAcc.Id)
            .setField(Entitlement__c.Product__c, testProduct.Id)
            .setField(Entitlement__c.Quantity__c, 1000)
            .setField(Entitlement__c.Price__c, 200)
            .create()
            .getRecord();

        PricebookEntry testPricebookentryStandard = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPriceBookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 0)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        PricebookEntry testPricebookentry = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, testPriceBook.Id)
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 200)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Product2Id, testProduct.Id)
            .setField(QuoteLineItem.QuoteId, testQuote.Id)
            .setField(QuoteLineItem.Entitlement__c, testEnt.Id)
            .setField(QuoteLineItem.UnitPrice, testEnt.Price__c)
            .setField(QuoteLineItem.Quantity, ValueProviderBuilder.provideUniqueNumber(1))
            .setField(QuoteLineItem.PricebookEntryId, testPricebookentry.Id)
            .setField(QuoteLineItem.Zero_Quantity__c, true)
            .create()
            .getRecord();

        String templateStr =
            '{!for item : QuoteLineItem}'
            + '{! item.$newRaterMonthlySubtotal | setScale(2)},'
            + '{! item.$subTotal | setScale(2)},'
            + '{!/for}'
            + '{! item.$summNewRaterMonthlySubtotal | setScale(2)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();
            // Subtotals and totals for Overages should always be 0
            String expectedString = '0.00,0.00,0.00';
        Test.stopTest();

        System.assertEquals(
            expectedString,
            templateStrResult,
            'Template was returned incorrectly after calculating new Rater Monthly Subtotals and Totals '
            + 'for an Overage with non-zero Entitlement__r.Quantity__c'
        );
    }

    @isTest
    private static void testWrap() {
        createTestData();

        String templateStr = '{! $today | wrap(\'+\', \'+\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('+' + System.today() + '+', templateStrResult, 'String hasn\'t been wrapped');
    }

    @isTest
    private static void testWrapOneParam() {
        createTestData();

        String templateStr = '{! $today | wrap(\'+\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assertEquals('+' + System.today() + '+', templateStrResult, 'String hasn\'t been wrapped');
    }

    @isTest
    private static void testWrapEmptyString() {
        createTestData();

        String templateStr = '{! AdditionalName | wrap(\'+\') }';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

        System.assert(String.isBlank(templateStrResult), 'Empty string wrapped');
    }

    @isTest
    private static void testApexFilter() {

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAcc.Id)
            .setField(Opportunity.CloseDate, ValueProviderBuilder.provideUniqueDate())
            .setField(Opportunity.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Payment_Plan__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .setField(Quote.PriceBook2Id, Test.getStandardPriceBookId())
            .create()
            .getRecord();

        String preservedOverageProduct = 'Domestic Minutes Overage';
        Product2[] testProducts = (Product2[]) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, new ValueProvider.ListProvider(new List<String>{preservedOverageProduct, 'fakeProductName'}))
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .quantity(2)
            .create()
            .getRecords();

        PricebookEntry[] testPbes = (PricebookEntry[]) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPriceBookId())
            .setField(PricebookEntry.Product2Id,
                new ValueProvider.ListProvider(new List<Id>{testProducts[0].Id, testProducts[1].Id}))
            .setField(PricebookEntry.UnitPrice, 345)
            .setField(PricebookEntry.IsActive, true)
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.QuoteId, testQuote.Id)
            .setField(QuoteLineItem.UnitPrice, 345)
            .setField(QuoteLineItem.EffectivePriceNew__c, 345)
            .setField(QuoteLineItem.Last_Approved_Discount__c,
                new ValueProvider.ListProvider(new List<Integer>{0, 100})
            )
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.PricebookEntryId,
                new ValueProvider.ListProvider(new List<Id>{testPbes[0].Id, testPbes[1].Id}))
            .quantity(2)
            .create();

        PdfPreservedItems__c preservedOverage = new PdfPreservedItems__c();
        preservedOverage.Name = preservedOverageProduct;
        preservedOverage.Product_Name__c = preservedOverageProduct;
        preservedOverage.Preserved_Overage__c = true;
        insert preservedOverage;

        String templateStr =
            '{! for qli : QuoteLineItem | apexFilter(\'OVERAGES_BY_DISCOUNT\')}' +
                '[{! qli.Product2.Name }]' +
            '{! /for }';

        String templateNotChanged =
            '{! for qli : QuoteLineItem | apexFilter(\'REMOVE_NOT_CHANGED_QLIS\')}' +
                '[{! qli.Product2.Name }]' +
            '{! /for }';

        Test.startTest();

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
            String templateNotChangedResult = TemplateEngine.createFromString(testQuote.Id, templateNotChanged);

        Test.stopTest();

        // checks that template with 'OVERAGES_BY_DISCOUNT' apexFilter could be correctly processeded without failure
        // and that this apexFilter is able to filter out some overages, but not all of them.
        System.assertEquals('[' + preservedOverageProduct + ']', templateStrResult,
            'Merge result should contains exactly one overage.');

        // checks that template with 'REMOVE_NOT_CHANGED_QLIS' apexFilter could be correctly processeded without failure
        // and that this apexFilter is able to filter out some QuoteLineItems, but not all of them.
        System.assertEquals('[fakeProductName]', templateNotChangedResult,
            'Merge result should contains exactly one product.');

    }

    /**
     * Overage with special name - this should be always preservend
     */
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFilterOveragesByDiscountPreservedName() {

        IValueProvider productIdsProvider = new ValueProvider.DummyIdProvider(Product2.sObjectType);
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType);

        Product2 overageWithPreservedName = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, 'Domestic Minutes Overage')
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .build()
            .getRecord();
        QuoteLineItem overageWithPreservedNameQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .build()
            .getRecord();
        overageWithPreservedNameQli.Product2 = overageWithPreservedName;

        Test.startTest();

            testFiltration(new TemplateEngine.TemplateHandler(),
                new List<QuoteLineItem>{overageWithPreservedNameQli},
                new List<QuoteLineItem>{overageWithPreservedNameQli},
                'Wrong filtration result for a case with special (always preserved) overage name.'
            );

        Test.stopTest();
    }

    /**
     * Overage should be preserved only if it discout differs from parent product/entitlement
     */
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFilterOveragesByDiscountParentChild() {

        IValueProvider productIdsProvider = new ValueProvider.DummyIdProvider(Product2.sObjectType);
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType);

        // seat product (parent)
        Product2 seatProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, 'Contact Center: Ultimate-Plus Edition Seat')
            .setField(Product2.Family, Product2Helper.FAMILY_CCSERVICE)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .build()
            .getRecord();
        QuoteLineItem seatQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .setField(QuoteLineItem.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            .setField(QuoteLineItem.Discount_number__c, 0)
            .build()
            .getRecord();
        seatQli.Product2 = seatProduct;

        // seat overages (childs)
        Product2 seatOverage = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, 'Seat Overage')
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .setField(Product2.Parent__c, seatProduct.Id)
            .build()
            .getRecord();
        QuoteLineItem[] seatOverageQlis = (QuoteLineItem[]) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .quantity(4)
            .build()
            .getRecords();
        for (QuoteLineItem seatOverageQli : seatOverageQlis) {
            seatOverageQli.Product2 = seatOverage;
        }
        seatOverageQlis[0].Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        seatOverageQlis[0].Discount_number__c = 0;
        seatOverageQlis[1].Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        seatOverageQlis[1].Discount_number__c = 0;
        seatOverageQlis[2].Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        seatOverageQlis[2].Discount_number__c = 10;
        seatOverageQlis[3].Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        seatOverageQlis[3].Discount_number__c = 10;

        Entitlement__c overageEntitlement = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Id, new ValueProvider.DummyIdProvider(Entitlement__c.sObjectType))
            .setField(Entitlement__c.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            .setField(Entitlement__c.Discount__c, 0)
            .build().getRecord();

        Test.startTest();

            TemplateEngine.TemplateHandler handler = new TemplateEngine.TemplateHandler();

            testFiltration(handler,
                new List<QuoteLineItem>{seatQli},
                new List<QuoteLineItem>{},
                'Non-overage products should be filtered out.'
            );

            List<QuoteLineItem> seatChildTest = new List<QuoteLineItem>{seatQli};
            seatChildTest.addAll(seatOverageQlis);

            // CRM-1375: Hide $0 overages from Attachment A
            testFiltration(handler,
                seatChildTest,
                new List<QuoteLineItem>{},
                'Wrong filtration result for overages with UnitPrice = 0'
            );

            for (QuoteLineItem seatOverageQli : seatOverageQlis) {
                seatOverageQli.UnitPrice = 10;
            }

            // child-parrent logic tests
            testFiltration(handler,
                seatChildTest,
                new List<QuoteLineItem>{seatOverageQlis[2], seatOverageQlis[3]},
                'Wrong filtration result for overages with 0-discounted parent product.'
            );

            seatQli.Discount_number__c = 10;
            testFiltration(handler,
                seatChildTest,
                new List<QuoteLineItem>{seatOverageQlis[0], seatOverageQlis[1], seatOverageQlis[3]},
                'Wrong filtration result for overages with discounted parent product.'
            );

            // overage with entitlement logic tests
            for (QuoteLineItem seatOverageQli : seatOverageQlis) {
                seatOverageQli.Entitlement__r = overageEntitlement;
                seatOverageQli.Entitlement__c = overageEntitlement.Id;
            }

            seatChildTest.addAll(seatOverageQlis);
            testFiltration(handler,
                seatOverageQlis,
                new List<QuoteLineItem>{seatOverageQlis[2], seatOverageQlis[3]},
                'Wrong filtration result for overages with 0-discounted entitlement.'
            );

            overageEntitlement.Discount__c = 10;
            testFiltration(handler,
                seatOverageQlis,
                new List<QuoteLineItem>{seatOverageQlis[0], seatOverageQlis[1], seatOverageQlis[3]},
                'Wrong filtration result for overages with discounted entitlement.'
            );

        Test.stopTest();
    }

    /**
     * Sms overages should be preserved only if parent "sms fee" product present
     */
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFilterOveragesByDiscountSmsOverages() {
        IValueProvider uniqueStringProvider = new ValueProvider.UniqueStringProvider('test');
        IValueProvider productIdsProvider = new ValueProvider.DummyIdProvider(Product2.sObjectType);
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType);

        // sms fee products
        Product2 inboundSmsFeeProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, Product2Helper.NAME_CC_INBOUND_SMS_APPLICATION_FEE + ' - US')
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .setField(Product2.Product_Type__c, 'SMS')
            .build()
            .getRecord();
        QuoteLineItem inboundSmsFeeQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .build()
            .getRecord();
        inboundSmsFeeQli.Product2 = inboundSmsFeeProduct;

        Product2 outboundSmsFeeProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, Product2Helper.NAME_CC_OUTBOUND_SMS_APPLICATION_FEE + ' - US')
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .setField(Product2.Product_Type__c, 'SMS')
            .build()
            .getRecord();
        QuoteLineItem outboundSmsFeeQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .build()
            .getRecord();
        outboundSmsFeeQli.Product2 = outboundSmsFeeProduct;

        // overages
        Product2[] smsOverages = (Product2[]) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name,
                new ValueProvider.ListProvider(new List<String>{
                    'Incoming SMS Msg (per message)',
                    'Outgoing SMS (per Message)',
                    'Outbound SMS Rate (per Message)',
                    'SMS Toll Free Long Code Rate (per Message)'
                }))
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .setField(Product2.Product_Type__c,
                new ValueProvider.ListProvider(new List<String>{
                    Product2Helper.PRODUCT_TYPE_INCOMING_SMS,
                    Product2Helper.PRODUCT_TYPE_OUTGOING_SMS,
                    Product2Helper.PRODUCT_TYPE_OUTGOING_SMS_RATE,
                    Product2Helper.PRODUCT_TYPE_SMS_TF_LONG_RATE
                }))
            .quantity(4)
            .build()
            .getRecords();
        QuoteLineItem[] smsOverageQlis = (QuoteLineItem[]) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .quantity(4)
            .build()
            .getRecords();
        for (Integer i = 0; i < smsOverageQlis.size(); ++i) {
            smsOverageQlis[i].Product2 = smsOverages[i];
        }

        Test.startTest();

            TemplateEngine.TemplateHandler handler = new TemplateEngine.TemplateHandler();

            List<QuoteLineItem> qlisToFilter = smsOverageQlis.clone();
            qlisToFilter.add(inboundSmsFeeQli);
            testFiltration(handler,
                qlisToFilter,
                new List<QuoteLineItem>{smsOverageQlis[0], smsOverageQlis[1], smsOverageQlis[3]},
                'Wrong filtration result for inbound sms overages.'
            );

            qlisToFilter = smsOverageQlis.clone();
            qlisToFilter.add(outboundSmsFeeQli);
            testFiltration(handler,
                qlisToFilter,
                new List<QuoteLineItem>{smsOverageQlis[0], smsOverageQlis[2], smsOverageQlis[3]},
                'Wrong filtration result for outbound sms overages.'
            );

            qlisToFilter = smsOverageQlis.clone();
            qlisToFilter.addAll(new List<QuoteLineItem>{inboundSmsFeeQli, outboundSmsFeeQli});
            testFiltration(handler,
                qlisToFilter,
                smsOverageQlis,
                'Wrong filtration result for sms overages.'
            );

        Test.stopTest();

    }

    // helper for testFilterOveragesByDiscountXXXXX tests
    private static void testFiltration(TemplateEngine.TemplateHandler handler, List<QuoteLineItem> input,
        List<QuoteLineItem> expected, String errMsg
    ) {
        TemplateEngine.SetSelectedTemplate('NGBS Initial Order Form');
        List<QuoteLineItem> filteredQlis = handler.filterOveragesByDiscount(input);

        Set<Id> filteredIds = new Set<Id>();
        for (QuoteLineItem qli : filteredQlis) {
            filteredIds.add(qli.Id);
        }

        Set<Id> expectedIds = new Set<Id>();
        for (QuoteLineItem qli : expected) {
            expectedIds.add(qli.Id);
        }

        //System.assertEquals(expectedIds, filteredIds, errMsg);
    }

    @isTest
    private static void testGetQlisWithNonApprovedChanges() {
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType.getDescribe().getKeyPrefix(), 15);

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, new ValueProvider.DummyIdProvider(Product2.sObjectType))
            .setField(Product2.Name, 'testProduct')
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .build()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Id, new ValueProvider.DummyIdProvider(Quote.sObjectType))
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Payment_Plan__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .setField(Quote.PriceBook2Id, Test.getStandardPriceBookId())
            .build()
            .getRecord();
        quote.RecordType = new RecordType(Name = QuoteHelper.RT_NAME_BILLING);

        List<QuoteLineItem> qlis = new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.NewQuantity__c, 1)
            .setField(QuoteLineItem.UnitPrice, 1)
            .setField(QuoteLineItem.EffectivePriceNew__c, 1)
            .quantity(7)
            .build()
            .getRecords();

        QuoteLineItem qliNoChanges = qlis[0];

        // Discount change
        QuoteLineItem qliDiscountTypeChanged = qlis[1];
        qliDiscountTypeChanged.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

        QuoteLineItem qliDiscountChanged = qlis[2];
        qliDiscountChanged.Last_Approved_Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        qliDiscountChanged.Last_Approved_Discount__c = 1.34;
        qliDiscountChanged.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        qliDiscountChanged.Discount_number__c = 2.34;

        // Quantity change
        QuoteLineItem qliQuantityChanged = qlis[3];
        qliQuantityChanged.Last_Approved_Quantity__c = 5;
        qliQuantityChanged.NewQuantity__c = 10;

        // EffectivePrice change
        QuoteLineItem qliEffectivePriceChanged = qlis[4];
        qliEffectivePriceChanged.Last_Approved_Discount__c = 1;
        qliEffectivePriceChanged.EffectivePriceNew__c = 5;

        // Subtotal change
        QuoteLineItem qliSubtotalChanged = qlis[5];
        // currentItemSubtotal = 15
        qliSubtotalChanged.Last_Approved_Discount__c = null;
        qliSubtotalChanged.EffectivePriceNew__c = 5;
        qliSubtotalChanged.Quantity = 3;
        // subtotalConsideringChargeTerm = (5-1)*3 = 12
        qliSubtotalChanged.Discount = 1;

        for (QuoteLineItem qli : qlis) {
            qli.recalculateFormulas();
            qli.Id = (Id) qliIdsProvider.getValue();
            qli.Quote = quote;
            qli.Product2 = testProduct;
        }

        Test.startTest();

            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            TemplateEngine.TemplateHandler handler = new TemplateEngine.TemplateHandler();

            System.assert(!handler.isQliHasNonApprovedChanges(qliNoChanges));
            System.assert(handler.isQliHasNonApprovedChanges(qliDiscountTypeChanged));
            System.assert(handler.isQliHasNonApprovedChanges(qliDiscountChanged));
            System.assert(handler.isQliHasNonApprovedChanges(qliQuantityChanged));
            System.assert(handler.isQliHasNonApprovedChanges(qliEffectivePriceChanged));
            System.assert(handler.isQliHasNonApprovedChanges(qliSubtotalChanged));

            List<QuoteLineItem> filtered = handler.getQlisWithNonApprovedChanges(qlis);
            Set<Id> filteredIds = new Set<Id>();
            for (QuoteLineItem filteredQli : filtered) {
                filteredIds.add(filteredQli.Id);
            }

            System.assertEquals(5, filtered.size());
            System.assert(!filteredIds.contains(qliNoChanges.Id));

        Test.stopTest();
    }

    @isTest
    private static void testGoaStatus() {
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType.getDescribe().getKeyPrefix(), 15);

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, new ValueProvider.DummyIdProvider(Product2.sObjectType))
            .setField(Product2.Name, 'testProduct')
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .build()
            .getRecord();

        List<Quote> quotes = new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Id, new ValueProvider.DummyIdProvider(Quote.sObjectType))
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.Payment_Plan__c, Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT)
            .setField(Quote.PriceBook2Id, Test.getStandardPriceBookId())
            .quantity(2)
            .build()
            .getRecords();
        quotes[0].RecordType = new RecordType(Name = QuoteHelper.RT_NAME_BILLING);

        List<QuoteLineItem> qlis = new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.UnitPrice, 463)
            .setField(QuoteLineItem.Quantity, 13)
            .setField(QuoteLineItem.NewQuantity__c, 13)
            .quantity(5)
            .build()
            .getRecords();

        QuoteLineItem qliNoDiscount = qlis[0];

        QuoteLineItem qliDiscountApproved = qlis[1];
        qliDiscountApproved.EffectivePriceNew__c = qliDiscountApproved.UnitPrice;

        QuoteLineItem qliDiscountChanged = qlis[2];
        qliDiscountChanged.Discount_number__c = 5;
        qliDiscountChanged.Last_Approved_Discount__c = 8;

        QuoteLineItem qliQuantityChanged = qlis[3];
        qliQuantityChanged.NewQuantity__c = 5;
        qliQuantityChanged.Last_Approved_Quantity__c = 8;

        QuoteLineItem qliDiscountAndQuantityChanged = qlis[4];
        qliDiscountAndQuantityChanged.NewQuantity__c = 5;
        qliDiscountAndQuantityChanged.Last_Approved_Quantity__c = 8;
        qliDiscountAndQuantityChanged.Discount_number__c = 5;
        qliDiscountAndQuantityChanged.Last_Approved_Discount__c = 8;

        for (QuoteLineItem qli : qlis) {
            qli.recalculateFormulas();
            qli.Id = (Id) qliIdsProvider.getValue();
            qli.Quote = quotes[0];
            qli.Product2 = testProduct;
        }
        qliDiscountApproved.Quote = quotes[1];

        Test.startTest();

            TemplateEngine.VirtualField vf = new TemplateEngine.VirtualField();
            TemplateEngine.TemplateHandler handler = new TemplateEngine.TemplateHandler();

            String errMsg = 'Wrong GOA status.';
            System.assertEquals('No Discount', vf.goaStatus(qliNoDiscount), errMsg);
            System.assertEquals('Discount Change', vf.goaStatus(qliDiscountChanged), errMsg);
            System.assertEquals('Quantity Change', vf.goaStatus(qliQuantityChanged), errMsg);
            System.assertEquals('Discount & Quantity Change', vf.goaStatus(qliDiscountAndQuantityChanged), errMsg);
            System.assertEquals('Discount Approved', vf.goaStatus(qliDiscountApproved), errMsg);

        Test.stopTest();
    }

    @isTest
    private static void testGetObjToGetCurrency() {
        TemplateEngine.TemplateHandler handler = new TemplateEngine.TemplateHandler();

        // data items
        TemplateEngine.DataItem dataItemNoData = new TemplateEngine.DataItem();

        TemplateEngine.DataItem dataItemQuote = new TemplateEngine.DataItem();
        dataItemQuote.type = TemplateEngine.CUSTOM_QUERY_TYPE;
        dataItemQuote.data = new Quote(CurrencyIsoCode = 'RUB');

        TemplateEngine.DataItem dataItemCHangeOrderQli = new TemplateEngine.DataItem();
        dataItemCHangeOrderQli.type = TemplateEngine.CHANGE_ORDER_TYPE;
        TemplateEngine.ChangeOrderItem coiQli = new TemplateEngine.ChangeOrderItem();
        // It is impossible to simply set CurrencyIsoCode for QuoteLineItem, cause it refers to Quote.CurrencyIsoCode
        // and it impossible to set Quote.CurrencyIsoCode without a Quote insert.
        // As workaround we could instantiate qli from json.
        coiQli.quoteLineItem = (QuoteLineItem)
            JSON.deserialize('{"attributes":{"type":"QuoteLineItem"},"CurrencyIsoCode":"BYN"}', QuoteLineItem.class);
        dataItemCHangeOrderQli.dataList = new List<TemplateEngine.ChangeOrderItem>{coiQli};

        TemplateEngine.DataItem dataItemChangeOrderEnt = new TemplateEngine.DataItem();
        dataItemChangeOrderEnt.type = TemplateEngine.CHANGE_ORDER_TYPE;
        TemplateEngine.ChangeOrderItem coiEnt = new TemplateEngine.ChangeOrderItem();
        coiEnt.Entitlement = new Entitlement__c(CurrencyIsoCode = 'UAH');
        dataItemChangeOrderEnt.dataList = new List<TemplateEngine.ChangeOrderItem>{coiEnt};

        Test.startTest();

            SObject objToGetCurrency;

            objToGetCurrency = handler.getObjToGetCurrency(dataItemNoData);
            System.assertEquals(null, objToGetCurrency);

            objToGetCurrency = handler.getObjToGetCurrency(dataItemQuote);
            System.assertNotEquals(null, objToGetCurrency);
            System.assertEquals('RUB', objToGetCurrency.get('CurrencyIsoCode'));

            objToGetCurrency = handler.getObjToGetCurrency(dataItemCHangeOrderQli);
            System.assertNotEquals(null, objToGetCurrency);
            System.assertEquals('BYN', objToGetCurrency.get('CurrencyIsoCode'));

            objToGetCurrency = handler.getObjToGetCurrency(dataItemChangeOrderEnt);
            System.assertNotEquals(null, objToGetCurrency);
            System.assertEquals('UAH', objToGetCurrency.get('CurrencyIsoCode'));

        Test.stopTest();

    }

    @isTest
    private static void testAsCurrencyOrPercentageString() {
        TemplateEngine.FormatterHelper helper = new TemplateEngine.FormatterHelper();

        // test case with formatting to percentage value.
        // checks that 'objToGetCurrency' is not required in this case.
        Object percentageString = helper.asCurrencyOrPercentageString(
            15.7, null, new List<Object>{QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE});
        System.assertEquals('15.70%', percentageString, 'Wrong formatting result.');

        // test case with formatting to currency value.
        // checks that formatting to currency is used by default.
        Object currencyString = helper.asCurrencyOrPercentageString(
            15.7, new Contact(CurrencyIsoCode = 'EUR'), new List<Object>{'incorrectType'});
        System.assertEquals('€15.70', currencyString, 'Formatting to currency is used by default.');

        Boolean isAqExceptionThrown = false;
        try{
            helper.asCurrencyOrPercentageString(
                15.7, new Contact(CurrencyIsoCode = 'EUR'), new List<Object>());
        } catch (AquivaHelper.AquivaException ex) {
            isAqExceptionThrown = true;
        }
        System.assert(isAqExceptionThrown, 'argsList MUST contains a [0] value to determine formatter to use.');

    }

    @isTest
    private static void testGetTemplateBodyByIdOrExtermalId() {
        String cont1sec1 = 'Hello_';
        String cont2sec1 = 'world!';
        String cont1sec2 = 'Hi_';
        String cont2sec2 = 'RC!';
        // for test purposes, sec1 has Position__c = 2 and sec2 has Position__c = 1
        String fullContent = cont1sec2 + cont2sec2 + cont1sec1 + cont2sec1;

        String templateCssStyles = 'body{ font-size: 12pt;}';
        String section1CssStyles =  null;
        String section2CssStyles = 'table {width: 100%;}';
        String fullStyles = templateCssStyles + section2CssStyles;

        String testParamValue = 'testVal';

        RC_Quote_Template__c template = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setField(RC_Quote_Template__c.Name, 'testTemplate')
            .setField(RC_Quote_Template__c.CSS_Styles_1__c, templateCssStyles)
            .setField(RC_Quote_Template__c.Parameters__c, '{"param": "' + testParamValue + '"}')
            .setField(RC_Quote_Template__c.Language__c, 'English')
            .create()
            .getRecord();

        List<TemplateSections__c> sections = new SObjectBuilder(TemplateSections__c.sObjectType)
            .setField(TemplateSections__c.Name, 'testSection')
            .setField(TemplateSections__c.CSS_Styles_1__c, new ValueProvider.ListProvider(
                new List<String>{section1CssStyles, section2CssStyles}))
            .setField(TemplateSections__c.Content_1__c, new ValueProvider.ListProvider(
                new List<String>{cont1sec1, cont1sec2}))
            .setField(TemplateSections__c.Content_2__c, new ValueProvider.ListProvider(
                new List<String>{cont2sec1, cont2sec2}))
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(TemplateSectionJunction__c.sObjectType)
            .setField(TemplateSectionJunction__c.RC_Quote_Template__c, template.Id)
            .setField(TemplateSectionJunction__c.Template_Section__c, new ValueProvider.ListProvider(
                new List<String>{sections[0].Id, sections[1].Id}))
            .setField(TemplateSectionJunction__c.Position__c, new ValueProvider.ListProvider(
                new List<Integer>{2, 1}))
            .quantity(2)
            .create();

        List<RC_Quote_Template__c> templates = (new RCQuoteTemplateSelector())
            .selectRCQuoteTemplates()
            .selectField(RC_Quote_Template__c.External_ID__c)
            .executeQuery();

        System.assertEquals(1, templates.size(), 'Wrong templates number.');
        System.assert(String.isNotBlank(templates[0].External_ID__c), 'External_ID__c must be auto-populated.');

        Test.startTest();

            Map<String, Map<String, String>> templById = TemplateEngine.getTemplateBody(templates[0].Id);
            Map<String, Map<String, String>> templByExtId = TemplateEngine.getTemplateBody(templates[0].External_ID__c);

        Test.stopTest();

        System.assertEquals(fullContent, templById.get('template').get('content'),
            'Wrong content gotten by template Id.');
        System.assertEquals(fullContent, templByExtId.get('template').get('content'),
            'Wrong content gotten by template External_ID__c.');

        System.assertEquals(fullStyles, templById.get('template').get('styles'),
            'Wrong styles gotten by template Id.');
        System.assertEquals(fullStyles, templByExtId.get('template').get('styles'),
            'Wrong styles gotten by template External_ID__c.');

        System.assertEquals(testParamValue, templById.get('parameters').get('param'),
            'Wrong parameters gotten by template Id.');
        System.assertEquals(testParamValue, templByExtId.get('parameters').get('param'),
            'Wrong parameters gotten by template External_ID__c.');

    }

    @isTest
    private static void testOverallNewProposalTotalPriceWithTaxes() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePayment | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPriceWithTaxes | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 20', templateStrResult);
    }

    @isTest
    private static void testOverallOneTimePaymentWithTaxes() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePaymentWithTaxes | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPrice | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 10', templateStrResult);
    }

    @isTest
    private static void testOverallOneTimePaymentWithTaxes_Annual() {
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_ANNUAL)
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        // Create Quote
        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        String templateStr = '{! for qli : QuoteLineItem }{! /for }'
                            + '{! qli.$overallTaxesPayment | asNumber(0)}'
                            + ', {! qli.$overallOneTimePaymentWithTaxes | asNumber(0)}'
                            + ', {! qli.$overallNewProposalTotalPrice | asNumber(0)}';

        Test.startTest();
            String templateStrResult = TemplateEngine.createFromString(quoteRecord.Id, templateStr);
        Test.stopTest();

        System.assertEquals('10, 10, 120', templateStrResult);
    }

    @isTest
    private static void testApprovedBICountry() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        String templateStr = '{! $approvedBICountry }';

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('USA', res);
    }

    @isTest
    private static void testApprovedBICountry_PackageInfoEmpty() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        String templateStr = '{! $approvedBICountry }';

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('', res);
    }

    @isTest
    private static void testApprovedBICountry_PackageInfoHasNoBI() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities = null;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => JSON.serialize(pInfo)
                }
            )
            .create()
            .getRecord();

        String templateStr = '{! $approvedBICountry }';

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('', res);
    }

    @isTest
    static void testEngageLegalApprovalSelectedCorrectlyForMultipleFlow() {
        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LeadConversionConfiguration__c.Name => OpportunityHelper.BRAND_AVAYA,
                    LeadConversionConfiguration__c.Multiple_Engage_Legal_Management_Flow__c => true
                }
            ).create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Approval__c plainApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'plainApproval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Account__c => testAccount.Id,
                    Approval__c.Opportunity__c => opp.Id
                }
            )
            .build()
            .getRecord();

        Approval__c checkedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'checkedApproval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Account__c => testAccount.Id,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.Special_Terms_and_Notes__c => 'test data',
                    Approval__c.Send_Special_Terms_To_PDF__c => true
                }
            )
            .build()
            .getRecord();

        Test.startTest();
            insert new List<Approval__c> {plainApproval, checkedApproval};
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $EngageLegalApproval.Special_Terms_and_Notes__c }');
        Test.stopTest();

        System.assertEquals(checkedApproval.Special_Terms_and_Notes__c, res,
            'Special_Terms_and_Notes__c from approval with Send_Special_Terms_To_PDF__c set to true should be shown');
    }

    @isTest
    static void testEngageLegalApprovalSelectedForSingleFlow() {
        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LeadConversionConfiguration__c.Name => OpportunityHelper.BRAND_AVAYA,
                    LeadConversionConfiguration__c.Multiple_Engage_Legal_Management_Flow__c => false
                }
            ).create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'plainApproval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Account__c => testAccount.Id,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.Special_Terms_and_Notes__c => 'test data'
                }
            )
            .build()
            .getRecord();

        Test.startTest();
            insert new List<Approval__c> {app};
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $EngageLegalApproval.Special_Terms_and_Notes__c }');
        Test.stopTest();

        System.assertEquals(app.Special_Terms_and_Notes__c, res,
            'Special_Terms_and_Notes__c from approval should be shown');
    }

    @isTest
    static void testLocalSubscribedAddressVirtualObject() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Approval__c plainApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Approval__c.Opportunity__c => opp.Id,
                        Approval__c.Account__c => testAccount.Id,
                        Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                        Approval__c.DateOfSignOff__c => System.today(),
                        Approval__c.Other__c => 'test Other',
                        Approval__c.NameOfTheAuthorisedSignatory__c => 'test name of Authorised Signatory',
                        Approval__c.NameOfFatherOrHusband__c => 'test name of father',
                        Approval__c.GenderOfAuthorisedSignatory__c => 'Male',
                        Approval__c.NationalityOfAuthorisedSignatory__c => 'India',
                        Approval__c.DateOfBirthOfAuthorisedSignatory__c => System.today().addYears(-20),
                        Approval__c.KycFiles__c => 'file1;file2;file3;file4;file5;file6;file7;file8;file9',
                        Approval__c.PanGirNo__c => '1324567890',
                        Approval__c.HouseNo__c => '1',
                        Approval__c.StreetAddress__c => 'test Street',
                        Approval__c.Area__c => 'test Area',
                        Approval__c.City__c => 'test City',
                        Approval__c.District__c => 'test District',
                        Approval__c.State__c => 'Assam',
                        Approval__c.PinCode__c => '123456',
                        Approval__c.GstNo__c => 'hs5351z3'
                    }
                )
                .create()
                .getRecord();

            LocalSubscribedAddress__c localSubscribedAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        LocalSubscribedAddress__c.Name => 'Test',
                        LocalSubscribedAddress__c.RecordTypeId =>  LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY,
                        LocalSubscribedAddress__c.Approval__c => plainApproval.Id,
                        LocalSubscribedAddress__c.State__c => 'NY',
                        LocalSubscribedAddress__c.City__c => 'New York'
                    }
                )
                .create()
                .getRecord();

            Approval.ProcessResult result = ApprovalHelper.setApprovalAction(plainApproval.Id, 'Approve', 'Ok');

            String res = TemplateEngine.createFromString(testQuote.Id, '{!$LocalSubscribedAddress.City__c} {! $LocalSubscribedAddress.State__c }');
        Test.stopTest();

        System.assertEquals('New York NY', res, 'LocalSubscribedAddress virtual object is wrong');
    }

    @isTest
    static void testHierarchyLevelForNewBusiness() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();


                String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $HierarchyTable}{! item.Display_Name__c } {! item.EffectivePriceNew__c } {! item.$hierarchyLevel } {! /for }');
            Test.stopTest();

            System.assertEquals('DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1', res.trim(), 'Hierarchy structure is wrong');
    }

    @isTest
    static void testHierarchyLevelForExistingBusinessNewItems() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();


            String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableNew } {! item.QuoteLineItem.Display_Name__c } {! item.QuoteLineItem.EffectivePriceNew__c } {! item.$hierarchyLevel } {! /for }');
        Test.stopTest();

        System.assertEquals('DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1', res.trim(), 'Hierarchy structure is wrong');
    }

    @isTest
    static void testHierarchyLevelForExistingBusinessExistingItems() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Test.startTest();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, prod.Id)
            .setField(Entitlement__c.Quantity__c, 1)
            .setField(Entitlement__c.Price__c, 10)
            .setField(Entitlement__c.Display_Name__c, 'DigitalLine Unlimited Standard')
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.Entitlement__c => testEnt.Id,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableExisting } {! item.Entitlement__c.Display_Name__c } {! item.Entitlement__c.Price__c } {! item.$hierarchyLevel } {! /for }');
        Test.stopTest();

        System.assertEquals('DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1', res.trim(), 'Hierarchy structure is wrong');
    }

    @isTest
    static void testChangeTermChangedForExistingBusinessExistingItemsChangeOrderHierarchySubtotal() {

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Test.startTest();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, prod.Id)
            .setField(Entitlement__c.Quantity__c, 1)
            .setField(Entitlement__c.ChargeTerm__c, Product2Helper.CHARGE_TERM_ANNUAL)
            .setField(Entitlement__c.Price__c, 10)
            .setField(Entitlement__c.Display_Name__c, 'DigitalLine Unlimited Standard')
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 2,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.Entitlement__c => testEnt.Id,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();

        String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableExisting } {! item.Entitlement__c.Display_Name__c } {! item.Entitlement__c.Price__c } {! item.$hierarchyLevel } {! item.$changeOrderHierarchySubtotal} {! /for }');
        Test.stopTest();

        System.assertEquals('DigitalLine Unlimited Standard 10.00 0 20.00 DigitalLine Unlimited Standard 10.00 1 20.00', res.trim(), '$changeOrderHierarchySubtotal is wrong');
    }

    @isTest
    static void testHierarchyLevelForExistingBusinessNewAndExistingItems() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Test.startTest();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, prod.Id)
            .setField(Entitlement__c.Quantity__c, 1)
            .setField(Entitlement__c.Price__c, 10)
            .setField(Entitlement__c.Display_Name__c, 'DigitalLine Unlimited Standard')
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.Entitlement__c => testEnt.Id,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();

            String resNew = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableExistingAndNew } {! item.QuoteLineItem.Display_Name__c } {! item.QuoteLineItem.EffectivePriceNew__c } {! item.$hierarchyLevel } {! /for }');
            String resExisting = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableExistingAndNew } {! item.Entitlement__c.Display_Name__c } {! item.Entitlement__c.Price__c } {! item.$hierarchyLevel } {! /for }');
        Test.stopTest();

        System.assertEquals('DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1', resNew.trim(), 'Hierarchy structure is wrong');
        System.assertEquals('DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1', resExisting.trim(), 'Hierarchy structure is wrong');
    }

    @isTest
    static void testHierarchyTableChangeOrder() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Test.startTest();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, prod.Id)
            .setField(Entitlement__c.Quantity__c, 1)
            .setField(Entitlement__c.ChargeTerm__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Entitlement__c.Price__c, 15)
            .setField(Entitlement__c.Display_Name__c, 'DigitalLine Unlimited Standard')
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.Quantity => 99,
                QuoteLineItem.NewQuantity__c => 100,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .create()
            .getRecord();

            String hierarchyTableExistingAndNewStr = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableExistingAndNew } {! item.QuoteLineItem.Display_Name__c } {! item.QuoteLineItem.EffectivePriceNew__c } {! item.$hierarchyLevel } {! /for }');

            String name = '{! item.QuoteLineItem.Display_Name__c | if(\'!=\', \'\', <! item.QuoteLineItem.Display_Name__c>, <! item.Entitlement__c.Display_Name__c>)}';
            String price = '{! item.QuoteLineItem.EffectivePriceNew__c | if(\'!=\', \'\', <! item.QuoteLineItem.EffectivePriceNew__c>, <! item.Entitlement__c.Price__c>)}';
            String hierarchyTableChangeOrderStr = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableChangeOrder } ' + name + ' ' + price + ' {! item.$hierarchyLevel } {! /for }');

            ent.Price__c = 10;
            Triggers.switchOff();
            update ent;
            Triggers.switchOn();
            String hierarchyTableChangeOrderWithMergedCoiStr = TemplateEngine.createFromString(testQuote.Id, '{! for item : $hierarchyTableChangeOrder } ' + name + ' ' + price + ' {! item.$hierarchyLevel } {! /for }');
        Test.stopTest();

        System.assertEquals(
            'DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1',
            hierarchyTableExistingAndNewStr.trim(),
            'Hierarchy structure of hierarchyTableExistingAndNew is wrong'
        );
        System.assertEquals(
            'DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1 DigitalLine Unlimited Standard 15.00 0 DigitalLine Unlimited Standard 15.00 1',
            hierarchyTableChangeOrderStr.trim(),
            'Hierarchy structure of hierarchyTableChangeOrder is wrong'
        );
        System.assertEquals(
            'DigitalLine Unlimited Standard 10.00 0 DigitalLine Unlimited Standard 10.00 1',
            hierarchyTableChangeOrderWithMergedCoiStr.trim(),
            'Hierarchy structure of hierarchyTableChangeOrder is wrong'
        );
    }

    @isTest
    static void testHierarchyItemsOrdering() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited Standard',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":5,"Price":0,"parent":"LC_DL_75","originalDiscount":null,"lboxes":[{"elementID":"LB_70","min":1,"max":99999}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percentage"},"categoryPath":"DL:DL-UNL","CategoryCode":"DL-UNL","billingType":null}'
            })
            .build()
            .getRecord();

        QuoteLineItem qli2 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'e911 Service Fee',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":null,"Price":null,"parent":null,"originalDiscount":null,"lboxes":[{"elementID":null,"min":null,"max":null}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"DL:E911","CategoryCode":"E911","billingType":null}'
            })
            .build()
            .getRecord();
        Test.startTest();
            insert new List<QuoteLineItem>{qli, qli2};

                String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $HierarchyTable}{! item.Display_Name__c } {! item.EffectivePriceNew__c } {! item.$hierarchyLevel } {! /for }');
        Test.stopTest();

        System.assertEquals('DigitalLine Unlimited Standard 20.00 0 DigitalLine Unlimited Standard 10.00 1 e911 Service Fee 10.00 1', res.trim(), 'Hierarchy structure is wrong');
    }

    @isTest
    public static void testShowQliInPdf() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        String preservedProductExtId = 'LC_RCMT_928';
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => preservedProductExtId,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PdfPreservedItems__c preservedProduct = new PdfPreservedItems__c();
        preservedProduct.Name = preservedProductExtId;
        preservedProduct.Product_External_Id__c = preservedProductExtId;
        preservedProduct.Preserved_In_Hierarchy_Tables__c = true;
        insert preservedProduct;

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Test.startTest();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'RingCentral Video',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":[{"elementID":null,"min":null,"max":null}],"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"RCMT","CategoryCode":"RCMT"}'
            })
            .create()
            .getRecord();

                String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $HierarchyTable}{! item.Display_Name__c } {! item.EffectivePriceNew__c } {! /for }');
            Test.stopTest();

            System.assertEquals('RingCentral Video 10.00', res.trim(),'RingCentral Video is not displayed');
    }

    @isTest
    private static void testPartnerAccountsPayableContact() {
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                Account.Credit_Limit__c => 150,
                Account.BusinessIdentity__c => 'RingCentral Ink.',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_ATOS_WHOLESALE,
                Account.Partner_ID__c => '12345',
                Account.PartnerStatus__c => 'Active'
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.BusinessIdentity__c => 'RingCentral Ink.',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_ATOS_WHOLESALE,
                Account.Partner_Account__c => partnerAccount.Id,
                Account.Partner_ID__c => '12345'
            })
            .create()
            .getRecord();

        Contact partnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, partnerAccount.Id)
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        AccountContactRole accPartnerRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => partnerAccount.Id,
                AccountContactRole.ContactId => partnerContact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        String templateStr = 'Partner Accounts Payable Contact Name: [{! $PartnerAccountsPayableContact.Name }]';

        Test.startTest();
        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.Account__c => testAccount.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Monthly_Credit_Limit__c => 180,
                Approval__c.PartnerAccountPayableContact__c => partnerContact.Id,
                Approval__c.SwitchInvoicePartnerAccount__c => partnerAccount.Id,
                Approval__c.IsChangePaymentMethodRequest__c => true,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED
            })
            .create()
            .getRecord();
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('Partner Accounts Payable Contact Name: [Doe]', templateStrResult, 'PartnerAccountsPayableContact virtual object is wrong');

    }

    @isTest
    static void testOldPackageName() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => '[{"version":"1","trial":null,"productName":"Office","productId":"2","poc":null,"permissions":null,"packageInfo":{"version":"1","oldPackageName":"RingCentral Office Premium","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","id":"62554005","displayName":"RingCentral Office Standard","catalogId":"65"},"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"offerType":"Regular","id":"65","globalPackageLimits":[{"value":"6000","transactionType":"Any","target":"Global","scope":"BillingCycle","name":"Monthly money amount limit","limitType":null,"isOverride":null,"code":"MONTHLY_AMOUNT_LIMIT"}],"existingPackageInfo":{"version":"1","productName":"Office","offerType":"ProofOfConcept","id":"162"},"edition":{"name":"Standard","id":"1"},"duration":"Annual","contract":{"status":"new","id":"a8f2H0000008XMHQA2","extId":"Office_Europe","billingId":"36061005"}}]'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $oldPackageName }');
        Test.stopTest();

        System.assertEquals('RingCentral Office Premium', res, 'Old package name is wrong');
    }

    @isTest
    static void testNewPackageName() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => '[{"version":"1","trial":null,"productName":"Office","productId":"2","poc":null,"permissions":null,"packageInfo":{"version":"1","oldPackageName":"RingCentral Office Premium","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","id":"62554005","displayName":"RingCentral Office Standard","catalogId":"65"},"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"offerType":"Regular","id":"65","globalPackageLimits":[{"value":"6000","transactionType":"Any","target":"Global","scope":"BillingCycle","name":"Monthly money amount limit","limitType":null,"isOverride":null,"code":"MONTHLY_AMOUNT_LIMIT"}],"existingPackageInfo":{"version":"1","productName":"Office","offerType":"ProofOfConcept","id":"162"},"edition":{"name":"Standard","id":"1"},"duration":"Annual","contract":{"status":"new","id":"a8f2H0000008XMHQA2","extId":"Office_Europe","billingId":"36061005"}}]'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $newPackageName }');
        Test.stopTest();

        System.assertEquals('RingCentral Office Standard', res, 'New package name is wrong');
    }

    @isTest
    static void testIsTargetPriceAvailableTurnedOn() {

        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $isTargetPriceAvailable }');
        Test.stopTest();

        System.assertEquals('true', res, 'Enable TP and DQ Based GOA feature toggle is turned off');
    }

    @isTest
    static void testIsTargetPriceAvailableTurnedOff() {
        User testUser = createTestUserWithSegment('');
        System.runAs(testUser) {
            Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c => false
                })
                .create()
                .getRecord();

            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                        Opportunity.AccountId => testAccount.Id})
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id,
                        Quote.Pricebook2Id => Test.getStandardPricebookId()
                    }
                )
                .create()
                .getRecord();

            Test.startTest();
                String res = TemplateEngine.createFromString(testQuote.Id, '{! $isTargetPriceAvailable }');
            Test.stopTest();

            System.assertEquals('false', res, 'Enable TP and DQ Based GOA feature toggle is turned on');
        }
    }

    @isTest
    static void testSelectedPackageId() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => '[{"id":"20","version":"1","packageInfo":{"id":46142001,"catalogId":"20","version":"1","name":"MVP Essentials 1/2+ Lines - 5160/5161","displayName":"RingCentral MVP Essentials","oldPackageName":"RingCentral MVP Essentials"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":3,"name":"Essentials"},"contract":{"id":"a8f0R000000rAsoQAE","extId":"Office","billingId":"27652001"},"offerType":"Regular","poc":null,"permissions":null,"packageBusinessIdentities":{"approvedBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true},"defaultBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true},"selectedBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true}},"existingPackageInfo":{"id":"20","version":"1","offerType":"Regular","productName":"Office"},"partnerPackage":{"id":"162001","version":3,"settlementType":"RebateGreaterOfWholesale"}}]'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $SelectedPackageId }');
        Test.stopTest();

        System.assertEquals('20', res, 'Package id is wrong');
    }

    @isTest
    static void testEngageVoicePackageIds() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .setField(Account.BillingCountry, 'Canada')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testQuote.Id, '{! $EngageVoicePackageIds}');
        Test.stopTest();

        System.assertEquals('(754, 755, 756, 757)', res, 'Engage Voice Package Ids is wrong');
    }

    @isTest
    public static void testSignatureTagsForUnifyOfficeUKBusinessIdentityWithUserSegment(){
        User testUser = createTestUserWithSegment('Majors');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"30"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Chris Donan]', templateStrResult, 'Signature.Signature__c field is wrong');
         }
    }

    @isTest
    public static void testSignatureTagsForUnifyOfficeUKBusinessIdentityWithouthUserSegment(){
        User testUser = createTestUserWithSegment('');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"30"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Alex Shumway-Jones]', templateStrResult, 'Signature.Signature__c field is wrong');
         }
    }

    @isTest
    public static void testSignatureTagsForRingCentralBusinessIdentityWithEnterpriseUserSegment(){
        User testUser = createTestUserWithSegment('Enterprise');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Joe Jacob]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralBusinessIdentityWithMajorsUserSegment(){
        User testUser = createTestUserWithSegment('Majors');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Chris Donan]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralBusinessIdentityWithMidMarketUserSegment(){
        User testUser = createTestUserWithSegment('Mid Market');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Chris Donan]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralBusinessIdentityWithOtherUserSegment(){
        User testUser = createTestUserWithSegment('Other');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Alex Shumway-Jones]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralBusinessIdentityWithoutUserSegment(){
        User testUser = createTestUserWithSegment('');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"4"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Alex Shumway-Jones]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralGermanyBusinessIdentityWithoutUserSegment(){
        User testUser = createTestUserWithSegment('');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"EUR","biId":"33"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Thomas Nicolaus]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    @isTest
    public static void testSignatureTagsForRingCentralGermanyBusinessIdentityWithEnterpriseUserSegment(){
        User testUser = createTestUserWithSegment('Enterprise');
        System.runAs(testUser) {
            Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.BusinessIdentity__c => '{"currency":"EUR","biId":"33"}'
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => opp.Id
                    }
                )
                .create()
                .getRecord();

            String templateStr = 'Signature Name: [{! $Signature.Signature__c}]';

            String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);

            System.assertEquals('Signature Name: [Thomas Nicolaus]', templateStrResult, 'Signature.Signature__c field is wrong');
        }
    }

    private static User createTestUserWithSegment(String segment){
        return (User) new SObjectBuilder(User.SObjectType)
                .setField(User.SegmentPicklist__c, segment)
                .build()
                .getRecord();
    }

    @isTest
    private static void testResellerPriceWholesaleRaterFixedType() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.EffectivePriceNew__c => 0,
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"DL-UNL","duration":"Monthly","parent":"LC_DL_75","q":25,"lbox":{"min":1,"max":99999,"elementID":"LB_70"},"categoryPath":"DL:DL-UNL","originalDiscount":null,"partnerInfo":{"billingPlan":[{"wholesaleRater":{"type":"Fixed","config":"70.00"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Monthly"}]}}'
            })
            .create()
            .getRecord();


        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
        ' {!item.$resellerPrice | asCurrency()}' + '{!/for}';


        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('$30.00', templateStrResult, 'resellerPrice virtual field is wrong');

    }

    @isTest
    private static void testResellerPriceWholesaleRaterVolumeBasedType() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.EffectivePriceNew__c => 0,
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"DL-UNL","duration":"Monthly","parent":"LC_DL_75","q":25,"lbox":{"min":1,"max":99999,"elementID":"LB_70"},"categoryPath":"DL:DL-UNL","originalDiscount":null,"partnerInfo":{"billingPlan":[{"wholesaleRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, \\"value\\": \\"33.33\\"}, {\\"from\\": 2,\\"to\\": 99999, \\"value\\": \\"60.00\\"}]"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Monthly"}]}}'
            })
            .create()
            .getRecord();


        String templateStr = '{!for item : QuoteLineItem | where(\'NewQuantity__c != 0\') | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
        ' {!item.$resellerPrice | asCurrency()}' + '{!/for}';


        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('$40.00', templateStrResult, 'resellerPrice virtual field is wrong');

    }

    @isTest
    private static void testResellerPriceTotalsWholesaleRaterFixedType() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 12,
                QuoteLineItem.NewQuantity__c => 12,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.EffectivePriceNew__c => 0,
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"DL-UNL","duration":"Monthly","parent":"LC_DL_75","q":25,"lbox":{"min":1,"max":99999,"elementID":"LB_70"},"categoryPath":"DL:DL-UNL","originalDiscount":null,"partnerInfo":{"billingPlan":[{"wholesaleRater":{"type":"Fixed","config":"70.00"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Monthly"}]}}'
            })
            .create()
            .getRecord();


        String templateStr = '{!for item : QuoteLineItem | orderBy(\'PRODUCTS_STANDARD_SORT\')}' +
        ' {!item.$resellerPriceTotals | asCurrency()}' + '{!/for}';


        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr);
        Test.stopTest();

        System.assertEquals('$360.00', templateStrResult, 'resellerPriceTotals virtual field is wrong');

    }

    @isTest
    private static void testEntResellerPriceMonthlySubtotalWholesaleRaterFixedType() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 12,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Price__c => 100,
                Entitlement__c.Quote__c => testQuote.Id,
                Entitlement__c.PartnerConfig__c => '{"partnerPackageId":"111", "partnerPackageVersion": 23,"billingPlan":[{"wholesaleRater":{"type":"Fixed","config":"70.00"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Monthly"}]}'

            })
            .create()
            .getRecord();

        String templateStr = '{! for ent : Entitlement__c | orderBy(\'Name\') } ' +
        ' {! ent.$EntResellerPriceMonthlySubtotal | asCurrency() } ' +
        ' {! /for } ';

        Test.startTest();
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();
        Test.stopTest();

        System.assertEquals('$360.00', templateStrResult, 'EntResellerPriceMonthlySubtotal virtual field is wrong');

    }

    @isTest
    private static void testEntResellerPriceAnnualSubtotalWholesaleRaterVolumeBasedType() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 12,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Entitlement__c.Price__c => 100,
                Entitlement__c.Quote__c => testQuote.Id,
                Entitlement__c.PartnerConfig__c => '{"partnerPackageId":"111", "partnerPackageVersion": 23,"billingPlan":[{"wholesaleRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, \\"value\\": \\"33.33\\"}, {\\"from\\": 2,\\"to\\": 99999, \\"value\\": \\"60.00\\"}]"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Annual"}]}'

            })
            .create()
            .getRecord();

        String templateStr = '{! for ent : Entitlement__c | orderBy(\'Name\') } ' +
        ' {! ent.$EntResellerPriceAnnualSubtotal | asCurrency() } ' +
        ' {! /for } ';

        Test.startTest();
        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();
        Test.stopTest();

        System.assertEquals('$480.00', templateStrResult, 'EntResellerPriceAnnualSubtotal virtual field is wrong');

    }

    @isTest
    private static void testIsWholesaleEntitlement() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();
        Test.startTest();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => 'LC_DL-UNL_50',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Entitlement__c testEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 12,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Price__c => 100,
                Entitlement__c.Quote__c => testQuote.Id,
                Entitlement__c.PartnerConfig__c => ''

            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Display_Name__c => 'DigitalLine Unlimited',
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.EffectivePriceNew__c => 0,
                QuoteLineItem.Entitlement__c => testEnt.Id,
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"DL-UNL","duration":"Monthly","parent":"LC_DL_75","q":25,"lbox":{"min":1,"max":99999,"elementID":"LB_70"},"categoryPath":"DL:DL-UNL","originalDiscount":null,"partnerInfo":{"billingPlan":[{"wholesaleRater":{"type":"Fixed","config":"70.00"},"startDate":"2010-01-01T00:00Z[UTC]","revShareRater":{"type":"VolumeBased","config":"[{\\"from\\": 0,\\"to\\": 1, value: \\"33.33\\"}, {\\"from\\": 100,\\"to\\": 99999, value: \\"44.44\\"}]"},"duration":"Monthly"}]}}'
            })
            .create()
            .getRecord();

        String templateStr = '{! $IsWholesaleEntitlement} ';

        String templateStrResult = TemplateEngine.createFromString(testQuote.Id, templateStr).trim();
        Test.stopTest();

        System.assertEquals('false', templateStrResult, 'IsWholesaleEntitlement virtual field is wrong');

    }

    @isTest
    static void testIsServiceTerminatedPositive() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideList(new List<String>{
                '654343858',
                '546434575',
                '658564564'
            }))
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();
        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .create()
            .getRecord();

            List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                'RingCentral Contact Center',
                'Engage Voice Standalone',
                'Engage Digital Standalone'
            }))
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.IsTermination__c, true)
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
            String resCC = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isCCTerminated }');
            String resEngD = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isEngDTerminated }');
            String resEngV = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isEngVTerminated }');
        Test.stopTest();

        System.assertEquals('true', resCC, 'isCCTerminated has to be true');
        System.assertEquals('true', resEngD, 'isEngDTerminated has to be true');
        System.assertEquals('true', resEngV, 'isEngVTerminated has to be true');
    }

    @isTest
    static void testIsServiceTerminatedNegative() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideList(new List<String>{
                '654343858',
                '546434575',
                '658564564'
            }))
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();
        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .create()
            .getRecord();

            List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                QuoteHelper.NGBS_RCCC_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            }))
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.IsTermination__c, false)
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
            String resCC = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isCCTerminated }');
            String resEngD = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isEngDTerminated }');
            String resEngV = TemplateEngine.createFromString(testMasterQuote.Id, '{! $isEngVTerminated }');
        Test.stopTest();

        System.assertEquals('false', resCC, 'isCCTerminated has to be true');
        System.assertEquals('false', resEngD, 'isEngDTerminated has to be true');
        System.assertEquals('false', resEngV, 'isEngVTerminated has to be true');
    }

    @isTest
    static void testTechnicalQuoteEVGetting() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.IsMultiProductTechnicalAccount__c => false
                }
            )
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                    new Map<SObjectField, Object> {
                        Account.IsMultiProductTechnicalAccount__c => false,
                        Account.Master_Account__c => testMasterAccount.Id
                    }
                )
            .create()
            .getRecord();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testMasterAccount.Id,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.IsMultiProductTechnicalOpportunity__c => true
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.IsPrimary__c => true,
                    Quote.OpportunityId => testMasterOpportunity.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.IsPrimary__c => false,
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.MasterQuote__c => testMasterQuote.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.ServiceName__c => QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            String res = TemplateEngine.createFromString(testMasterQuote.Id, '{! $TechnicalQuoteEV.Id }');
        Test.stopTest();

        System.assertEquals(testQuote.Id, res, 'TechnicalQuoteEV.Id virtual field should contain EV technical Quote Id');

    }

    @isTest
    static void testCalculatePhaseTotals() {
        Triggers.switchOff();
        String templateStrPhaseTotal = '{! for phase : $Phases } {! /for } {! phase.$phaseTotal } ';
        String templateStrPhasesGrandTotal = '{! for phase : $Phases } {! /for } {! phase.$phasesGrandTotal }';
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY,
                    PriceBook2.IsActive => true
                }
            )
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        List<Product2> productRecords = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                        Product2Helper.FAMILY_DISCOUNTED_PHONES,
                        Product2Helper.FAMILY_TAXES
                    })
                }
            )
            .create()
            .getRecords();

        productRecords.add(
            (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                            Product2Helper.FAMILY_DISCOUNTED_PHONES
                        })
                    }
                )
                .create()
                .getRecord()
        );

        List<PricebookEntry> standardPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<PricebookEntry> customPbeRecords = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecords();

        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(customPbeRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecords();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Phase_Number__c => 1,
                Phase__c.Quote__c => quoteRecord.Id,
                Phase__c.Opportunity__c => opportunityRecord.Id
            })
            .create()
            .getRecord();

        List<Hardware_Line_Item__c> testHLIs = (List<Hardware_Line_Item__c>) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id>{
                        qliRecords[0].Id,
                        qliRecords[1].Id
                    }
                ),
                Hardware_Line_Item__c.Total_Price__c => ValueProviderBuilder.provideList(new List<Decimal>{22,25})
            })
            .create()
            .quantity(2)
            .getRecords();

        Phase__c testPhase2 = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Phase_Number__c => 2,
                Phase__c.Quote__c => quoteRecord.Id,
                Phase__c.Opportunity__c => opportunityRecord.Id
            })
            .create()
            .getRecord();

        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase2.Id,
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Quote_Line_Item__c => qliRecords[2].Id,
                Hardware_Line_Item__c.Total_Price__c => 30
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            String resultPhaseTotal = TemplateEngine.createFromString(quoteRecord.Id, templateStrPhaseTotal);
            String resultPhasesGrandTotal = TemplateEngine.createFromString(quoteRecord.Id, templateStrPhasesGrandTotal);
        Test.stopTest();
        Decimal phaseTotal = 0;
        for (Hardware_Line_Item__c hli : testHLIs) {
            phaseTotal += hli.Total_Price__c;
        }
        Decimal phasesGrandTotal = phaseTotal + testHLI.Total_Price__c;
        System.assertEquals(phaseTotal, Decimal.valueOf(resultPhaseTotal), 'phaseTotal should include sum of total price from all Phase Line Items');
        System.assertEquals(phasesGrandTotal, Decimal.valueOf(resultPhasesGrandTotal), 'phasesGrandTotal should include sum of total price from all Phase Line Items from all Phases');
    }

    @isTest
    static void testCalculatePhasesUCCCSubTotal() {
        Triggers.switchOff();
        String templateStrPhaseUCSubTotal = '{! for phase : $Phases } {! /for } {! phase.$phasesUCSubTotal } ';
        String templateStrPhaseCCSubTotal = '{! for phase : $Phases } {! /for } {! phase.$phasesCCSubTotal } ';
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY,
                    PriceBook2.IsActive => true
                }
            )
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            )
            .create()
            .getRecord();

        PricebookEntry standardPbeRecord = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        PricebookEntry customPbeRecord = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => customPbeRecord.Id,
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecord();

        List<Phase__c> phases = (List<Phase__c>) new SObjectBuilder(Phase__c.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => ValueProviderBuilder.provideList(new List<String>{'test phase 1','test phase 2'}),
                    Phase__c.Phase_Number__c => ValueProviderBuilder.provideList(new List<Integer>{1,2}),
                    Phase__c.Quote__c => quoteRecord.Id,
                    Phase__c.Opportunity__c => opportunityRecord.Id,
                    Phase__c.Phase_Type__c => ValueProviderBuilder.provideList(new List<String>{'UC','CC'})
                }
            )
            .create()
            .getRecords();

        List<Hardware_Line_Item__c> testHLIs = (List<Hardware_Line_Item__c>) new SObjectBuilder(Hardware_Line_Item__c.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => ValueProviderBuilder.provideList(new List<Id>{phases[0].Id, phases[1].Id}),
                    Hardware_Line_Item__c.Quantity__c => 1,
                    Hardware_Line_Item__c.Quote_Line_Item__c => qli.Id,
                    Hardware_Line_Item__c.Total_Price__c => ValueProviderBuilder.provideList(new List<Decimal>{40,30})
                }
            )
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
            String resultPhaseUCSubTotal = TemplateEngine.createFromString(quoteRecord.Id, templateStrPhaseUCSubTotal);
            String resultPhaseCCSubTotal = TemplateEngine.createFromString(quoteRecord.Id, templateStrPhaseCCSubTotal);
        Test.stopTest();
        Assert.areEqual(40, Decimal.valueOf(resultPhaseUCSubTotal), 'phasesCCSubTotal should include sum of total price from all Phase Line Items from UC Phases');
        Assert.areEqual(30, Decimal.valueOf(resultPhaseCCSubTotal), 'phasesCCSubTotal should include sum of total price from all Phase Line Items from CC Phases');
    }

    @isTest
    static void testCalculatePhasesTypes() {
        Triggers.switchOff();
        String templateStrPhaseTypes = '{! for phase : $Phases } {! /for } {! phase.$phasesTypes } ';
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY,
                    PriceBook2.IsActive => true
                }
            )
            .create()
            .getRecord();

        Opportunity opportunityRecord = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote quoteRecord = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Pricebook2Id => testPriceBook.Id
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            )
            .create()
            .getRecord();

        PricebookEntry standardPbeRecord = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        PricebookEntry customPbeRecord = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => customPbeRecord.Id,
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Quantity => 1
                }
            )
            .create()
            .getRecord();

        List<Phase__c> phases = (List<Phase__c>) new SObjectBuilder(Phase__c.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => ValueProviderBuilder.provideList(new List<String>{'test phase 1','test phase 2'}),
                    Phase__c.Phase_Number__c => ValueProviderBuilder.provideList(new List<Integer>{1,2}),
                    Phase__c.Quote__c => quoteRecord.Id,
                    Phase__c.Opportunity__c => opportunityRecord.Id,
                    Phase__c.Phase_Type__c => ValueProviderBuilder.provideList(new List<String>{'UC','CC'})
                }
            )
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
            String resultPhasesTypes = TemplateEngine.createFromString(quoteRecord.Id, templateStrPhaseTypes);
        Test.stopTest();
        Assert.areEqual(true, resultPhasesTypes.contains('UC'), 'resultPhasesTypes should contain UC Phase Type');
        Assert.areEqual(true, resultPhasesTypes.contains('CC'), 'resultPhasesTypes should contain CC Phase Type');
    }

    @isTest
    static void testTaxesAndFeesTable() {
        Id standardPricebookId = Test.getStandardPricebookId();
         Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => standardPricebookId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, 'Test Product')
            .setField(Product2.Family, Product2Helper.FAMILY_FEE)
            .setField(Product2.ExtID__c, Product2Helper.ELEMENT_ID_E911_FEE)
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, standardPricebookId)
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 100)
            .setField(PricebookEntry.IsActive, true)
            .create()
            .getRecord();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => testPBE.Id,
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{
                    100, 100, 100, 200
                }),
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Display_Name__c => 'Test Product'
            })
            .quantity(4)
            .create()
            .getRecords();

        Test.startTest();
        String res = TemplateEngine.createFromString(testQuote.Id, '{! for item : $TaxesAndFeesTable}{! item.Display_Name__c } {! item.EffectivePriceNew__c } {!  item.NewQuantity__c} {! item.Product2.Family} {! /for }');
        Test.stopTest();

        Assert.areEqual('Test Product 100.00 3.00 Fee Test Product 200.00 1.00 Fee', res.trim(), 'TaxesAndFeesTable virtual field should contain correct Taxes And Fees Table');
    }
}