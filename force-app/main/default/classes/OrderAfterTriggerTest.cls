@isTest
private class OrderAfterTriggerTest {
    private static final String COMMON_FIELDS_ASSERT_MSG_TEMPLATE = '{0}: {1} on Package should be equal to sum of {2} on related Orders';

    private static final Integer OFFICE_ORDER_TO_CREATE = 3;
    private static final Integer RCCC_ORDER_TO_CREATE = 2;
    private static final Integer ED_ORDER_TO_CREATE = 1;
    private static final Integer EV_ORDER_TO_CREATE = 1;
    private static final Integer ORDER_AMOUNT_TO_CREATE = OFFICE_ORDER_TO_CREATE + RCCC_ORDER_TO_CREATE + ED_ORDER_TO_CREATE + EV_ORDER_TO_CREATE;

    private static final Decimal ORDER_SEAT_MRR = 100;
    private static final Decimal ORDER_RECURRING_TOTAL = 500;
    private static final Decimal ORDER_TRANSPORT_MRR = 200;
    private static final Decimal ORDER_MINUTE_BUNDLE = 15;
    private static final Integer ORDER_NUMBER_OF_LICENCES = 20;

    private static final Decimal EXPECTED_PACKAGE_PRICE_PER_SEAT = ORDER_SEAT_MRR / ORDER_NUMBER_OF_LICENCES;
    private static final Integer EXPECTED_PACKAGE_MAIN_LICENCES = ORDER_NUMBER_OF_LICENCES * RCCC_ORDER_TO_CREATE;

    private static final Integer EXPECTED_PACKAGE_NUMBER_OF_ENGAGE_DIGITAL_USERS = ORDER_NUMBER_OF_LICENCES * ED_ORDER_TO_CREATE;
    private static final Decimal EXPECTED_PACKAGE_ED_ADDITIONAL_PRODUCTS_MRR = (ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR) * ED_ORDER_TO_CREATE;
    private static final Decimal EXPECTED_PACKAGE_ENGAGE_DIGITAL_USER_MRR = ORDER_SEAT_MRR * ED_ORDER_TO_CREATE;

    private static final Integer EXPECTED_PACKAGE_NUMBER_OF_ENGAGE_VOICE_USERS = ORDER_NUMBER_OF_LICENCES * EV_ORDER_TO_CREATE;
    private static final Decimal EXPECTED_PACKAGE_ENGAGE_VOICE_USER_MRR = ORDER_SEAT_MRR * EV_ORDER_TO_CREATE;
    private static final Decimal EXPECTED_PACKAGE_EV_ADDITIONAL_PRODUCTS_MRR = (ORDER_RECURRING_TOTAL - ORDER_SEAT_MRR) * EV_ORDER_TO_CREATE;

    private abstract class PackageAsserter {
        private final Package__c packageRecord;
        private final Integer ordersCount;

        protected abstract Map<SObjectField, Object> getServiceFieldsToExpectedValue();
        protected abstract Map<SObjectField, String> getServiceFieldsToAssertMsg();

        public PackageAsserter(Package__c packageRecord, Integer ordersCount) {
            this.ordersCount = ordersCount;
            this.packageRecord = packageRecord;
        }

        public void assert() {
            Map<SObjectField, Object> fieldsToExpectedValue = getServiceFieldsToExpectedValue();
            Map<SObjectField, String> fieldsToAssertMsg = getServiceFieldsToAssertMsg();
            for (SObjectField field : fieldsToExpectedValue.keySet()) {
                Assert.areEqual(
                    fieldsToExpectedValue.get(field),
                    packageRecord.get(field),
                    fieldsToAssertMsg.get(field)
                );
            }
        }

        protected Decimal calculateExpectedValue(Decimal valueOnOrder) {
            return ordersCount * valueOnOrder;
        }
    }

    // Package__c fields that are common for all services
    private class CommonFieldsAsserter extends PackageAsserter {
        protected override Map<SObjectField, Object> getServiceFieldsToExpectedValue() {
            return new Map<SObjectField, Object> {
                Package__c.Sales_Order_MRS__c => calculateExpectedValue(ORDER_RECURRING_TOTAL),
                Package__c.TransportMRR__c => calculateExpectedValue(ORDER_TRANSPORT_MRR),
                Package__c.MinuteBundle__c => calculateExpectedValue(ORDER_MINUTE_BUNDLE),
                Package__c.NumberOfMainLicenses__c => calculateExpectedValue(ORDER_NUMBER_OF_LICENCES)
            };
        }

        protected override Map<SObjectField, String> getServiceFieldsToAssertMsg() {
            return new Map<SObjectField, String> {
                Package__c.Sales_Order_MRS__c => getAssertMsg(Package__c.Sales_Order_MRS__c, Order.Recurring_total__c),
                Package__c.TransportMRR__c => getAssertMsg(Package__c.TransportMRR__c, Order.TransportMRR__c),
                Package__c.MinuteBundle__c => getAssertMsg(Package__c.MinuteBundle__c, Order.MinuteBundle__c),
                Package__c.NumberOfMainLicenses__c => getAssertMsg(Package__c.NumberOfMainLicenses__c, Order.NumberOfMainLicenses__c)
            };
        }

        public CommonFieldsAsserter(Package__c packageRecord, Integer ordersCount) {
            super(packageRecord, ordersCount);
        }

        private String getAssertMsg(SObjectField packageField, SObjectField orderField) {
            return String.format(
                COMMON_FIELDS_ASSERT_MSG_TEMPLATE,
                new List<Object> {
                    packageRecord.Service_Type__c,
                    packageField,
                    orderField
                }
            );
        }
    }

    private class OfficeAsserter extends PackageAsserter {
        protected override Map<SObjectField, Object> getServiceFieldsToExpectedValue() {
            return new Map<SObjectField, Object> {
                Package__c.AcquisitionMRR__c => OFFICE_ORDER_TO_CREATE * ORDER_RECURRING_TOTAL
            };
        }

        protected override Map<SObjectField, String> getServiceFieldsToAssertMsg() {
            return new Map<SObjectField, String> {
                Package__c.AcquisitionMRR__c => 'AcquisitionMRR__c on Package should be equal to sum of AcquisitionMRR__c on office orders'
            };
        }

        public OfficeAsserter(Package__c packageRecord) {
            super(packageRecord, OFFICE_ORDER_TO_CREATE);
        }
    }

    private class RCCCAsserter extends PackageAsserter {
        protected override Map<SObjectField, Object> getServiceFieldsToExpectedValue() {
            return new Map<SObjectField, Object> {
                Package__c.SeatMRR__c => calculateExpectedValue(ORDER_SEAT_MRR),
                Package__c.No_of_InContact_Seats__c => EXPECTED_PACKAGE_MAIN_LICENCES,
                Package__c.Price_per_Seat__c => EXPECTED_PACKAGE_PRICE_PER_SEAT
            };
        }

        protected override Map<SObjectField, String> getServiceFieldsToAssertMsg() {
            return new Map<SObjectField, String> {
                Package__c.SeatMRR__c => 'SeatMRR__c on Package should be equal to sum of SeatMRR__c on related Orders',
                Package__c.No_of_InContact_Seats__c => 'No_of_InContact_Seats__c on Package should be equal to NumberOfMainLicenses__c on package',
                Package__c.Price_per_Seat__c => 'Price_per_Seat__c on Package should be equal to SeatMRR__c / No_of_InContact_Seats__c on package'
            };
        }

        public RCCCAsserter(Package__c packageRecord) {
            super(packageRecord, RCCC_ORDER_TO_CREATE);
        }
    }

    private class EDAsserter extends PackageAsserter {
        protected override Map<SObjectField, Object> getServiceFieldsToExpectedValue() {
            return new Map<SObjectField, Object> {
                Package__c.NumberOfEngageDigitalUsers__c => EXPECTED_PACKAGE_NUMBER_OF_ENGAGE_DIGITAL_USERS,
                Package__c.EngageDigitalUserMRR__c => EXPECTED_PACKAGE_ENGAGE_DIGITAL_USER_MRR,
                Package__c.EDAdditionalProductsMRR__c => EXPECTED_PACKAGE_ED_ADDITIONAL_PRODUCTS_MRR
            };
        }

        protected override Map<SObjectField, String> getServiceFieldsToAssertMsg() {
            return new Map<SObjectField, String> {
                Package__c.NumberOfEngageDigitalUsers__c => 'NumberOfEngageDigitalUsers__c on Package should be equal to sum of NumberOfMainLicenses__c on package',
                Package__c.EngageDigitalUserMRR__c => 'EngageDigitalUserMRR__c on Package should be equal to SeatMRR__c on package',
                Package__c.EDAdditionalProductsMRR__c => 'EDAdditionalProductsMRR__c on Package should be equal to Sales_Order_MRS__c - SeatMRR__c on package'
            };
        }

        public EDAsserter(Package__c packageRecord) {
            super(packageRecord, ED_ORDER_TO_CREATE);
        }
    }

    private class EVAsserter extends PackageAsserter {
        protected override Map<SObjectField, Object> getServiceFieldsToExpectedValue() {
            return new Map<SObjectField, Object> {
                Package__c.NumberOfEngageVoiceSeats__c => EXPECTED_PACKAGE_NUMBER_OF_ENGAGE_VOICE_USERS,
                Package__c.EngageVoiceUserMRR__c => EXPECTED_PACKAGE_ENGAGE_VOICE_USER_MRR,
                Package__c.EVAdditionalProductsMRR__c => EXPECTED_PACKAGE_EV_ADDITIONAL_PRODUCTS_MRR
            };
        }

        protected override Map<SObjectField, String> getServiceFieldsToAssertMsg() {
            return new Map<SObjectField, String> {
                Package__c.NumberOfEngageVoiceSeats__c => 'NumberOfEngageVoiceSeats__c on Package should be equal to sum of NumberOfMainLicenses__c on package',
                Package__c.EngageVoiceUserMRR__c => 'EngageVoiceUserMRR__c on Package should be equal to sum of SeatMRR__c on package',
                Package__c.EVAdditionalProductsMRR__c => 'EVAdditionalProductsMRR__c on Package should be equal to Sales_Order_MRS__c - SeatMRR__c on package'
            };
        }

        public EVAsserter(Package__c packageRecord) {
            super(packageRecord, EV_ORDER_TO_CREATE);
        }
    }

    private static void assertPackage(Package__c packageRecord) {
        Integer relatedOrdersAmount;
        PackageAsserter asserter;
        if (packageRecord.Service_Type__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
            relatedOrdersAmount = OFFICE_ORDER_TO_CREATE;
            asserter = new OfficeAsserter(packageRecord);
        } else if (packageRecord.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
            relatedOrdersAmount = RCCC_ORDER_TO_CREATE;
            asserter = new RCCCAsserter(packageRecord);
        } else if (packageRecord.Service_Type__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
            relatedOrdersAmount = ED_ORDER_TO_CREATE;
            asserter = new EDAsserter(packageRecord);
        } else if (packageRecord.Service_Type__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
            relatedOrdersAmount = EV_ORDER_TO_CREATE;
            asserter = new EVAsserter(packageRecord);
        } else {
            Assert.fail('Need to implement assertion for ' + packageRecord.Service_Type__c);
        }
        new CommonFieldsAsserter(packageRecord, relatedOrdersAmount).assert();
        asserter.assert();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
    	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    	Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
		Account accObj = new Account();
        accObj.Name = 'TestAccount';
        accObj.Number_of_DL_s__c = 5;
        accObj.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
        accObj.Type ='Partner';
        accObj.Partner_ID__c = '12345';
        accObj.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        insert accObj;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;

        Order__c orderVal = new  Order__c();
        orderVal.Name = '12345678';
        orderVal.X12M_Company_Booking_Amount__c = 100.00;
        orderVal.Order_Date__c = system.today();
        orderVal.account__c = accObj.Id;
        orderVal.Lead_Source__c = 'Referral Program';
        insert  orderVal;

        orderVal.Name='test';
        update orderVal;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testUpdateTotalFieldsOnPackage() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Triggers.switchOff();
        Triggers.except('OrderAfterTriggerHandler.UpdateTotalFieldsOnPackage');

        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Validate Account'),
                    Account.Partner_ID__c => '1234567',
                    Account.Payment_Method__c => 'Invoice',
                    Account.Payment_Plan__c => 'Monthly',
                    Account.RC_User_ID__c => '400389021062',
                    Account.Billing_ID__c => '5037002',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.AccountId => masterAccount.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => System.today() + 90
                })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => masterOpp.Id,
                Quote.Account__c => masterAccount.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();


        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test Name',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly'
            })
            .create()
            .getRecord();

            PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();


        List<Package__c> packages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Package__c.Account__c => masterAccount.Id,
                    Package__c.Enterprise_Account_ID__c => masterAccount.Id,
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19', '20', '21'}),
                    Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{
                        QuoteHelper.NGBS_OFFICE_PRODUCT,
                        QuoteHelper.NGBS_RCCC_PRODUCT,
                        QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                        QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
                    })
                })
            .quantity(4)
            .create()
            .getRecords();
        Package__c officePackage = packages[0];
        Package__c rcccPackage = packages[1];
        Package__c edPackage = packages[2];
        Package__c evPackage = packages[3];

        List<Order> testOrders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => masterAccount.Id,
                Order.QuoteId => qt.Id,
                Order.OpportunityId => masterOpp.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => System.today(),
                Order.Recurring_total__c => ORDER_RECURRING_TOTAL,
                Order.SeatMRR__c => ORDER_SEAT_MRR,
                Order.TransportMRR__c => ORDER_TRANSPORT_MRR,
                Order.MinuteBundle__c => ORDER_MINUTE_BUNDLE,
                Order.NumberOfMainLicenses__c => ORDER_NUMBER_OF_LICENCES,
                Order.PackageId__c => ValueProviderBuilder.provideList(new List<Id> {
                    officePackage.Id,
                    officePackage.Id,
                    officePackage.Id,
                    rcccPackage.Id,
                    rcccPackage.Id,
                    edPackage.Id,
                    evPackage.Id
                }),
                Order.Status => 'Requested'
            })
            .quantity(ORDER_AMOUNT_TO_CREATE)
            .create()
            .getRecords();


        new SObjectBuilder(OrderItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    OrderItem.OrderId => ValueProviderBuilder.provideParents(testOrders),
                    OrderItem.PricebookEntryId => testPBE.Id,
                    OrderItem.UnitPrice => 10,
                    OrderItem.Quantity => 1
                }
            )
            .quantity(7)
            .create();

        Test.startTest();
            for (Order ord: testOrders) {
                ord.Status = OrderHelper.STATUS_ACTIVATED;
            }
            update testOrders;
        Test.stopTest();
        Triggers.switchOn();

        List<Package__c> updatedPackages = (List<Package__c>) new PackageSelector()
            .selectAllPackages()
            .selectFields(new Set<SObjectField> {
                Package__c.Service_Type__c,
                Package__c.MinuteBundle__c,
                Package__c.No_of_InContact_Seats__c,
                Package__c.NumberOfEngageDigitalUsers__c,
                Package__c.EngageDigitalUserMRR__c,
                Package__c.EDAdditionalProductsMRR__c,
                Package__c.NumberOfEngageVoiceSeats__c,
                Package__c.EngageVoiceUserMRR__c,
                Package__c.EVAdditionalProductsMRR__c,
                Package__c.Price_per_Seat__c
            })
            .executeQuery();
        for (Package__c pckg : updatedPackages) {
            assertPackage(pckg);
        }
    }
}