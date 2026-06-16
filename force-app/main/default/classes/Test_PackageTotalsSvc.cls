@IsTest
private class Test_PackageTotalsSvc {
    private static final String MINUTE_BUNDLE_ASSERT_MSG = 'Minute bundle was not calculated correctly';
    private static final String NUMBER_OF_LICENCES_ASSERT_MSG = 'Number of licences was not calculated correctly';
    private static final String SALES_ORDER_MRS_ASSERT_MSG = 'Sales order MRS was not calculated correctly';
    private static final String TRANSPORT_MRR_ASSERT_MSG = 'Transport MRR was not calculated correctly';
    private static final String SERVICE_MRR_ASSERT_MSG = ' was not calculated correctly';

    private static final String ACCOUNT_NAME = 'Test Account';

    private static final Decimal ORDER_SEAT_MRR = 100;
    private static final Decimal ORDER_RECURRING_TOTAL = 500;
    private static final Decimal ORDER_TRANSPORT_MRR = 200;
    private static final Decimal ORDER_MINUTE_BUNDLE = 15;
    private static final Integer ORDER_NUMBER_OF_LICENCES = 20;

    private static final Set<SObjectField> RCCC_FIELDS = new Set<SObjectField> {
        Package__c.SeatMRR__c,
        Package__c.AdditionalProductsMRR__c,
        Package__c.No_of_InContact_Seats__c,
        Package__c.Price_per_Seat__c
    };
    private static final Set<SObjectField> ENGAGE_DIGITAL_FIELDS = new Set<SObjectField> {
        Package__c.EngageDigitalUserMRR__c,
        Package__c.NumberOfEngageDigitalUsers__c,
        Package__c.EDAdditionalProductsMRR__c
    };
    private static final Set<SObjectField> ENGAGE_VOICE_FIELDS = new Set<SObjectField> {
        Package__c.EngageVoiceUserMRR__c,
        Package__c.NumberOfEngageVoiceSeats__c,
        Package__c.EVAdditionalProductsMRR__c
    };
    private static final Set<SObjectField> EVENTS_FIELDS = new Set<SObjectField> {
        Package__c.Events_User_MRR__c,
        Package__c.Number_of_Events_Users__c,
        Package__c.Events_Additional_Products_MRR__c
    };

    private class TestTotalsCalculator extends PackageTotalsSvc.TotalsCalculator {
        Boolean didCalculateServiceFields = false;

        public TestTotalsCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            this(record, relatedOrders, accountsMap, null);
        }

        public TestTotalsCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap, SObjectField serviceMRRField) {
            super(record, relatedOrders, accountsMap, serviceMRRField);
        }

        protected override void calculateServiceFields() {
            didCalculateServiceFields = true;
        }
    }

    private static Map<Id, Account> buildTestAccounts() {
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType)
            })
            .quantity(1)
            .build()
            .getRecords();
        return new Map<Id, Account>(testAccs);
    }

    private static List<Order> buildTestOrders(Map<Id, Account> accountMap) {
        return (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.SeatMRR__c => ORDER_SEAT_MRR,
                Order.Recurring_Total__c => ORDER_RECURRING_TOTAL,
                Order.TransportMRR__c => ORDER_TRANSPORT_MRR,
                Order.MinuteBundle__c => ORDER_MINUTE_BUNDLE,
                Order.NumberOfMainLicenses__c => ORDER_NUMBER_OF_LICENCES,
                Order.AccountId => ValueProviderBuilder.provideParents(accountMap.keySet())
            })
            .quantity(1)
            .build()
            .getRecords();
    }

    private static Package__c buildTestPackage(String serviceType) {
        return new Package__c(Service_Type__c = serviceType, AcquisitionMRR__c = 0);
    }

    private static void assertCommonFields(Package__c testPackage, SObjectField serviceMRRField) {
        Assert.areEqual(ORDER_MINUTE_BUNDLE, testPackage.MinuteBundle__c, MINUTE_BUNDLE_ASSERT_MSG);
        Assert.areEqual(ORDER_NUMBER_OF_LICENCES, testPackage.NumberOfMainLicenses__c, NUMBER_OF_LICENCES_ASSERT_MSG);
        Assert.areEqual(ORDER_RECURRING_TOTAL, testPackage.Sales_Order_MRS__c, SALES_ORDER_MRS_ASSERT_MSG);
        Assert.areEqual(ORDER_TRANSPORT_MRR, testPackage.TransportMRR__c, TRANSPORT_MRR_ASSERT_MSG);
        if (serviceMRRField != null) {
            Assert.areEqual(ORDER_SEAT_MRR, testPackage.get(serviceMRRField), serviceMRRField.toString() + SERVICE_MRR_ASSERT_MSG);
        }
    }

    private static void assertOtherServiceFields(Package__c testPackage, Set<SObjectField> otherServiceFields) {
        for (SObjectField field : otherServiceFields) {
            Assert.areEqual(
                0,
                NumberHelper.getNumberNullSafe(testPackage.get(field)),
                field.toString() + ' is expected to be empty for ' + testPackage.Service_Type__c
            );
        }
    }

    @isTest
    static void testGetCalculationStrategy() {
        Package__c testPackage = new Package__c();
        List<Order> relatedOrders = new List<Order>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();

        // the only way to dynamically determine TotalsCalculator subclass is to check the service-specific MRR field
        Map<String, SObjectField> serviceTypeToExpectedField = new Map<String, SObjectField> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => null,
            QuoteHelper.NGBS_RCCC_PRODUCT => Package__c.SeatMRR__c,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => Package__c.EngageDigitalUserMRR__c,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => Package__c.EngageVoiceUserMRR__c,
            QuoteHelper.NGBS_RCEVENTS_PRODUCT => Package__c.Events_User_MRR__c
        };
        Set<String> serviceTypes = serviceTypeToExpectedField.keySet();
        Test.startTest();
            for (String serviceType : serviceTypes) {
                testPackage.Service_Type__c = serviceType;
                PackageTotalsSvc.TotalsCalculator result = PackageTotalsSvc.getCalculationStrategy(testPackage, relatedOrders, accountsMap);

                Assert.areEqual(
                    serviceTypeToExpectedField.get(serviceType),
                    result.serviceMRRField,
                    'Wrong calculation strategy was returned for ' + serviceType
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testTotalsCalculatorConstructor() {
        Package__c testPackage = new Package__c();
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);
        SObjectField expectedServiceMRRField = Package__c.SeatMRR__c;

        Test.startTest();
            TestTotalsCalculator calculator = new TestTotalsCalculator(testPackage, relatedOrders, accountsMap, expectedServiceMRRField);
        Test.stopTest();

        Assert.areEqual(testPackage, calculator.record, 'Record was not set correctly');
        Assert.areEqual(relatedOrders, calculator.relatedOrders, 'Related orders were not set correctly');
        Assert.areEqual(accountsMap, calculator.accountsMap, 'Accounts map was not set correctly');
        Assert.areEqual(expectedServiceMRRField, calculator.serviceMRRField, 'Unexpected service MRR field was set');
    }

    // TODO: test for annual orders
    @isTest
    static void testTotalsCalculatorCalculations() {
        Package__c testPackage = new Package__c(AcquisitionMRR__c = 0);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        TestTotalsCalculator calculator = new TestTotalsCalculator(testPackage, relatedOrders, accountsMap);
        Test.startTest();
            calculator.calculateTotals();
        Test.stopTest();

        Assert.isTrue(calculator.didCalculateServiceFields, 'Service specific fields were not calculated');
        assertCommonFields(testPackage, null);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testTotalsCalculatorCalculationsWhenOrderFieldsAreNull() {
        Package__c testPackage = new Package__c(AcquisitionMRR__c = 0);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> orderWithNullFields = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, ValueProviderBuilder.provideParents(accountsMap.keySet()))
            .build()
            .getRecords();

        TestTotalsCalculator calculator = new TestTotalsCalculator(testPackage, orderWithNullFields, accountsMap);
        Test.startTest();
            calculator.calculateTotals();
        Test.stopTest();

        Set<SObjectField> allTotalFields = new Set<SObjectField> {
            Package__c.MinuteBundle__c,
            Package__c.NumberOfMainLicenses__c,
            Package__c.Sales_Order_MRS__c,
            Package__c.TransportMRR__c,
            Package__c.AcquisitionMRR__c
        };
        allTotalFields.addAll(RCCC_FIELDS);
        allTotalFields.addAll(ENGAGE_DIGITAL_FIELDS);
        allTotalFields.addAll(ENGAGE_VOICE_FIELDS);
        allTotalFields.addAll(EVENTS_FIELDS);
        assertOtherServiceFields(testPackage, allTotalFields);
    }

    @isTest
    static void testOfficeCalculator() {
        Package__c testPackage = buildTestPackage(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        Test.startTest();
            PackageTotalsSvc.OfficeCalculator calculator = new PackageTotalsSvc.OfficeCalculator(testPackage, relatedOrders, accountsMap);
            calculator.calculateTotals();
        Test.stopTest();

        Assert.isNull(calculator.serviceMRRField, 'There should not be any service specific field for Office');
        assertCommonFields(testPackage, null);

        Set<SObjectField> nonOfficeFields = new Set<SObjectField>(RCCC_FIELDS);
        nonOfficeFields.addAll(ENGAGE_DIGITAL_FIELDS);
        nonOfficeFields.addAll(ENGAGE_VOICE_FIELDS);
        nonOfficeFields.addAll(EVENTS_FIELDS);
        assertOtherServiceFields(testPackage, nonOfficeFields);
    }

    @isTest
    static void testRCCCCalculator() {
        Package__c testPackage = buildTestPackage(QuoteHelper.NGBS_RCCC_PRODUCT);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        Test.startTest();
            PackageTotalsSvc.RCCCCalculator calculator = new PackageTotalsSvc.RCCCCalculator(testPackage, relatedOrders, accountsMap);
            calculator.calculateTotals();
        Test.stopTest();

        Assert.areEqual(Package__c.SeatMRR__c, calculator.serviceMRRField, 'Wrong MRR field was chosen for RCCC package');
        assertCommonFields(testPackage, Package__c.SeatMRR__c);
        Assert.areEqual(ORDER_NUMBER_OF_LICENCES, testPackage.No_of_InContact_Seats__c, 'Number of InContact seats was not calculated correctly');
        Assert.areEqual(ORDER_SEAT_MRR / ORDER_NUMBER_OF_LICENCES, testPackage.Price_per_Seat__c, 'Price per seat was not calculated correctly');
        Assert.areEqual(ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR, testPackage.AdditionalProductsMRR__c, 'Additional products MRR was not calculated correctly');

        Set<SObjectField> nonRCCCFields = new Set<SObjectField>(ENGAGE_DIGITAL_FIELDS);
        nonRCCCFields.addAll(ENGAGE_VOICE_FIELDS);
        nonRCCCFields.addAll(EVENTS_FIELDS);
        assertOtherServiceFields(testPackage, nonRCCCFields);
    }

    @isTest
    static void testEngageDigitalCalculator() {
        Package__c testPackage = buildTestPackage(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        Test.startTest();
            PackageTotalsSvc.EngageDigitalCalculator calculator = new PackageTotalsSvc.EngageDigitalCalculator(testPackage, relatedOrders, accountsMap);
            calculator.calculateTotals();
        Test.stopTest();

        Assert.areEqual(Package__c.EngageDigitalUserMRR__c, calculator.serviceMRRField, 'Wrong MRR field was chosen for Engage Digital package');
        assertCommonFields(testPackage, Package__c.EngageDigitalUserMRR__c);
        Assert.areEqual(ORDER_NUMBER_OF_LICENCES, testPackage.NumberOfEngageDigitalUsers__c, 'Number of Engage Digital users was not calculated correctly');
        Assert.areEqual(ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR, testPackage.EDAdditionalProductsMRR__c, 'Engage Digital additional products MRR was not calculated correctly');

        Set<SObjectField> nonEngageDigitalFields = new Set<SObjectField>(RCCC_FIELDS);
        nonEngageDigitalFields.addAll(ENGAGE_VOICE_FIELDS);
        assertOtherServiceFields(testPackage, nonEngageDigitalFields);
    }

    @isTest
    static void testEngageVoiceCalculator() {
        Package__c testPackage = buildTestPackage(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        Test.startTest();
            PackageTotalsSvc.EngageVoiceCalculator calculator = new PackageTotalsSvc.EngageVoiceCalculator(testPackage, relatedOrders, accountsMap);
            calculator.calculateTotals();
        Test.stopTest();

        Assert.areEqual(Package__c.EngageVoiceUserMRR__c, calculator.serviceMRRField, 'Wrong MRR field was chosen for Engage Voice package');
        assertCommonFields(testPackage, Package__c.EngageVoiceUserMRR__c);
        Assert.areEqual(ORDER_NUMBER_OF_LICENCES, testPackage.NumberOfEngageVoiceSeats__c, 'Number of Engage Voice seats was not calculated correctly');
        Assert.areEqual(ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR, testPackage.EVAdditionalProductsMRR__c, 'Engage Voice additional products MRR was not calculated correctly');

        Set<SObjectField> nonEngageVoiceFields = new Set<SObjectField>(RCCC_FIELDS);
        nonEngageVoiceFields.addAll(ENGAGE_DIGITAL_FIELDS);
        assertOtherServiceFields(testPackage, nonEngageVoiceFields);
    }

    @isTest
    static void testEventsCalculator() {
        Package__c testPackage = buildTestPackage(QuoteHelper.NGBS_RCEVENTS_PRODUCT);
        Map<Id, Account> accountsMap = buildTestAccounts();
        List<Order> relatedOrders = buildTestOrders(accountsMap);

        Test.startTest();
            PackageTotalsSvc.EventsCalculator calculator = new PackageTotalsSvc.EventsCalculator(testPackage, relatedOrders, accountsMap);
            calculator.calculateTotals();
        Test.stopTest();
        
        Assert.areEqual(Package__c.Events_User_MRR__c, calculator.serviceMRRField, 'Wrong MRR field was chosen for Events package');
        assertCommonFields(testPackage, Package__c.Events_User_MRR__c);
        Assert.areEqual(ORDER_NUMBER_OF_LICENCES, testPackage.Number_of_Events_Users__c, 'Number of Event users was not calculated correctly');
        Assert.areEqual(ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR, testPackage.Events_Additional_Products_MRR__c, 'Event additional products MRR was not calculated correctly');

        Set<SObjectField> nonEventFields = new Set<SObjectField>(RCCC_FIELDS);
        nonEventFields.addAll(ENGAGE_DIGITAL_FIELDS);
        nonEventFields.addAll(ENGAGE_VOICE_FIELDS);
        assertOtherServiceFields(testPackage, nonEventFields);
    }
}