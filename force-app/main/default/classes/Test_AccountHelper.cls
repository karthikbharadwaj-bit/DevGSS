@IsTest
private class Test_AccountHelper {
    @IsTest
    static void testIsAccFlagMigrated() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'test Acc',
                    Account.AccMigrationFlag__c => AccountHelper.MIGRATED_STATUS
            })
            .build()
            .getRecord();

        System.assertEquals(
            true,
            AccountHelper.isAccFlagMigrated(testAccount),
            'Method should retrun true if Account AccMigrationFlag__c field is Migrated'
        );
    }

    @IsTest
    static void testIsAccountTrial() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                    Account.Billing_ID__c => 'Test',
                    Account.RC_Account_Status__c => AccountHelper.ACCOUNT_STATUS_TRIAL
            })
            .create()
            .getRecord();

        System.assert(AccountHelper.isTrial(testAccount));
    }

    @IsTest
    static void testIsElaService() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_SERVICE
            })
            .create()
            .getRecord();
        System.assert(AccountHelper.isElaService(testAccount));
    }

    @IsTest
    static void testIsAccountInvoiceOnBehalf() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test',
                Account.Partner_Id__c => '12345'
            })
            .create()
            .getRecord();

        Boolean isIoB = AccountHelper.isInvoiceOnBehalfAccount(testAccount);
        System.assertEquals(false, isIoB, 'Account was identified as Invoice on Behalf');

        testAccount.Partner_Type__c = AccountHelper.ACCOUNT_PARTNER_AVAYA_BILL_ON_BEHALF;
        update testAccount;

       isIoB = AccountHelper.isInvoiceOnBehalfAccount(testAccount);
        System.assertEquals(true, isIoB, 'Account was not identified as Invoice on Behalf');
    }

    @IsTest
    static void testAccountInvoiceOnBehalfSwitch() {
        Test.startTest();

        Account nonBobAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test'
            })
            .create()
            .getRecord();

        Account bobAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test',
                Account.Partner_Id__c => '12345',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_AVAYA_BILL_ON_BEHALF
            })
            .create()
            .getRecord();

        Test.stopTest();

        System.assertEquals(true, AccountHelper.accountInvoiceOnBehalfSwitch(bobAccount, nonBobAccount), 'Account Invoice on Behalf Switch wasn\'t detected');
        System.assertEquals(true, AccountHelper.accountInvoiceOnBehalfSwitch(nonBobAccount, bobAccount), 'Account Invoice on Behalf Switch wasn\'t detected');
        System.assertEquals(false, AccountHelper.accountInvoiceOnBehalfSwitch(bobAccount, bobAccount), 'Account Invoice on Behalf Switch was detected incorrectly');
    }

    @IsTest
    static void testAccountWholesaleSwitch() {
        Test.startTest();

        Account nonWholesaleAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test'
            })
            .create()
            .getRecord();

        Account wholesaleAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test',
                Account.Partner_Id__c => '12345',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_ATOS_WHOLESALE
            })
            .create()
            .getRecord();

        Test.stopTest();

        Assert.isTrue(AccountHelper.accountWholesaleSwitch(wholesaleAccount, nonWholesaleAccount), 'Account Wholesale Switch wasn\'t detected');
        Assert.isTrue(AccountHelper.accountWholesaleSwitch(nonWholesaleAccount, wholesaleAccount), 'Account Wholesale Switch wasn\'t detected');
        Assert.isFalse(AccountHelper.accountWholesaleSwitch(nonWholesaleAccount, nonWholesaleAccount), 'Account Wholesale Switch was detected incorrectly');
    }

    @IsTest
    private static void testIsCreditCardAccount() {
        Account creditCardAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Account_Payment_Method__c => AccountHelper.PAYMENT_METHOD_CREDIT_CARD
            })
            .build()
            .getRecord();

        Account ngbsCreditCardAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Account_Payment_Method__c => AccountHelper.PAYMENT_METHOD_NGBS_CREDIT_CARD
            })
            .build()
            .getRecord();

        Account invoiceAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Account_Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE
            })
            .build()
            .getRecord();

        Assert.isTrue(AccountHelper.isCreditCardAccount(creditCardAccount), '"Credit Card" method should pass');
        Assert.isTrue(AccountHelper.isCreditCardAccount(ngbsCreditCardAccount), '"CreditCard" method should pass');
        Assert.isFalse(AccountHelper.isCreditCardAccount(invoiceAccount), '"Invoice" method should not pass');
    }

    @IsTest
    private static void testIsBillingAddressEmpty() {

        System.assertEquals(
            true,
            AccountHelper.isBillingAddressEmpty(null),
            'method should return true if passed argument is null'
        );

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test account',
                Account.BillingCountry => 'test country',
                Account.BillingState => 'test state',
                Account.BillingPostalCode => '123456',
                Account.BillingCity => 'test city'
            })
            .build()
            .getRecord();

        System.assertEquals(
            true,
            AccountHelper.isBillingAddressEmpty(testAccount),
            'method should return true if any address field(BillingStreet in current case) is empty'
        );


        testAccount.BillingStreet = 'test street';
        System.assertEquals(
            false,
            AccountHelper.isBillingAddressEmpty(testAccount),
            'method should return false if account address fields is not empty'
        );
    }

    @IsTest
    static void testCopyPartnerInfo() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .build()
            .getRecord();

        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Partner_Account__c => 'Test',
                Account.Partner_ID__c => 'Test',
                Account.Partner_Type__c => 'Test',
                Account.Partner_Account_Name__c => 'Test',
                Account.Partner_Contact__c => 'Test',
                Account.Parent_Partner_Account__c => 'Test',
                Account.Ultimate_Partner_Name__c => 'Test',
                Account.Ultimate_Partner_ID__c => 'Test',
                Account.Settlement_Type__c => 'Test'
            })
            .build()
            .getRecord();

        Account result = AccountHelper.copyPartnerInformation(testAccount, partnerAccount);

        System.assertEquals(testAccount.Partner_Account__c, result.Partner_Account__c, 'Partner_Account__c should be copied from the partner account');
        System.assertEquals(testAccount.Partner_ID__c, result.Partner_ID__c, 'Partner_ID__c should be copied from the partner account');
        System.assertEquals(testAccount.Partner_Type__c, result.Partner_Type__c, 'Partner_Type__c should be copied from the partner account');
        System.assertEquals(testAccount.Partner_Account_Name__c, result.Partner_Account_Name__c, 'Partner_Account_Name__c should be copied from the partner account');
        System.assertEquals(testAccount.Ultimate_Partner_Name__c, result.Ultimate_Partner_Name__c, 'Ultimate_Partner_Name__c should be copied from the partner account');
        System.assertEquals(testAccount.Ultimate_Partner_Name__c, result.Ultimate_Partner_Name__c, 'Ultimate_Partner_Name__c should be copied from the partner account');
        System.assertEquals(testAccount.Ultimate_Partner_ID__c, result.Ultimate_Partner_ID__c, 'Ultimate_Partner_ID__c should be copied from the partner account');
        System.assertEquals(testAccount.Settlement_Type__c, result.Settlement_Type__c, 'Settlement_Type__c should be copied from the partner account');
    }

    @IsTest
    static void testIsSingaporeBillingCountry() {
        System.assertEquals(
            false,
            AccountHelper.isSingaporeBillingCountry(null),
            'method should return false if passed argument is null'
        );

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingCountry => 'United States'
            })
            .build()
            .getRecord();

        System.assertEquals(
            false,
            AccountHelper.isSingaporeBillingCountry(testAccount),
            'method should return false if BillingCountry on passed account is not "Singapore"'
        );

        testAccount.BillingCountry = 'Singapore';
        System.assertEquals(
            true,
            AccountHelper.isSingaporeBillingCountry(testAccount),
            'method should return true if BillingCountry on passed account is "Singapore"'
        );
    }

    @IsTest
    static void testGetNgbsPartnerId() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS,
                Account.Billing_ID__c => 'Test',
                Account.NGBS_Partner_ID__c => 12345
            })
            .create()
            .getRecord();

        System.assertEquals(12345, AccountHelper.getNgbsPartnerId(testAccount.Id), 'Wrong NGBS Partner ID was received');
    }

    @IsTest
    static void testIsAustraliaBillingCountry() {
        System.assertEquals(
            false,
            AccountHelper.isAustraliaBillingCountry(null),
            'method should return false if passed argument is null'
        );

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingCountry => 'United States'
            })
            .build()
            .getRecord();

        System.assertEquals(
            false,
            AccountHelper.isAustraliaBillingCountry(testAccount),
            'method should return false if BillingCountry on passed account is not "Australia"'
        );

        testAccount.BillingCountry = 'Australia';
        System.assertEquals(
            true,
            AccountHelper.isAustraliaBillingCountry(testAccount),
            'method should return true if BillingCountry on passed account is "Australia"'
        );
    }

    @isTest
    static void testIsInContactLegacyExistingBusiness() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.inContact_account_ID__c => null
            })
            .build()
            .getRecord();

        Assert.isFalse(
            AccountHelper.isInContactLegacyExistingBusiness(testAccount),
            'The method should return false if inContact_account_ID__c = null'
        );

        testAccount.inContact_account_ID__c = '1';
        Assert.isTrue(
            AccountHelper.isInContactLegacyExistingBusiness(testAccount),
            'The method should return true if inContact_account_ID__c on passed account is not null'
        );
    }

    @IsTest
    static void testIsPartner() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();
        System.assert(AccountHelper.isPartner(testAccount));
    }

    @IsTest
    static void testGenerateElaServiceAccounts() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test account',
                Account.BillingCountry => 'test country',
                Account.BillingState => 'test state',
                Account.BillingPostalCode => '123456',
                Account.BillingCity => 'test city'
        })
        .build()
        .getRecord();

        List<Account> serviceAccList = AccountHelper.generateElaServiceAccounts(testAccount, 2, 'test');
        System.assertEquals(2, serviceAccList.size(), 'should be 2 accs created');

        Account serviceAcc = serviceAccList.get(0);
        System.assert(AccountHelper.ACCOUNT_TYPE_ELA_SERVICE.equals(serviceAcc.ELA_Account_Type__c), 'should be service type');
        System.assert('test'.equals(serviceAcc.Name), 'should have name test');
    }

    @isTest
    static void testIsAccountHasCCEntitlements() {
        Account testAccounts = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'test account',
                    Account.Billing_ID__c => '123233'
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Product2.Name => 'Connect Pro - Annual Fee',
                            Product2.IsActive => true,
                            Product2.Family => 'RingCentral',
                            Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
                    }
            )
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Entitlement__c.Name => 'Entitlement Name',
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Account__c => testAccounts.Id,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 2,
                    Entitlement__c.Quantity__c => 5,
                    Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Product__c => testProduct.Id,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        Test.startTest();
        Boolean result = AccountHelper.isAccountHasCCEntitlements(testAccounts.Id);
        Test.stopTest();

        Assert.isTrue(result, 'Result should be true');
    }

    private static Set<String> ACCOUNT_NULL_FIELDS = new Set<String>{
        'Package_Status__c',
        'RC_Account_Number__c',
        'RC_Account_Status__c',
        'RC_Activation_Date__c',
        'RC_Edition__c',
        'RC_Plan_Renewal_Date__c',
        'RC_Service_ID__c',
        'RC_Signup_Date__c',
        'RC_Signup_Funnel__c',
        'RC_Sync_Status__c',
        'RC_Tier__c',
        'RC_Tier_ID__c',
        'RC_Upgrade_Date__c',
        'RC_User_ID__c',
        'Sales_Agreement_End_Date__c',
        'Sales_Agreement_Start_Date__c',
        'Sales_Booking_MRS__c',
        'Service_Version_Label__c',
        'Sign_up_Purchase_Limit__c',
        'SignupType__c',
        'Total_Contract_Value_Calculated__c',
        'Total_Contract_Value_Override__c',
        'Total_DLs__c',
        'Total_MRR__c',
        'Total_Opportunities__c',
        'Total_Potential_Users__c',
        'Total_Won_Opportunities__c',
        'Transport_MRR__c',
        'ParentId',
        'Ultimate_Account__c',
        'Ultimate_Parent_Partner_ID__c',
        'Ultimate_Parent_Snapshot__c',
        'Ultimate_Partner_ID__c',
        'Ultimate_Partner_Name__c',
        'VideoProvider__c',
        'Actual_transport_MRR__c',
        'Additional_Products_MRR__c',
        'aMRR__c',
        'Seat_MRR__c',
        'PartnerMrr__c',
        'Parent_Account_Total_MRR__c',
        'MRR_Transfer_Effective_Date__c',
        'MRR_of_current_customers__c',
        'Farming_Assignment_MRR__c'
    };
    @IsTest
    static void testGenerateTechnicalAccounts() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity opp = TestDataGenerator.createOpportunity(masterAccount);
        Quote activeQuote = TestDataGenerator.createActiveAgreement(opp);
        masterAccount.Active_Sales_Agreement__c = activeQuote.Id;
        masterAccount.Tax_Exempt__c = true;
        masterAccount.RC_Account_Number__c = String.valueOf(ValueProviderBuilder.provideUniqueDecimal(0, 8).getValue());
        masterAccount.RC_Account_Status__c = 'Paid';
        masterAccount.RC_Activation_Date__c = System.now();
        masterAccount.RC_Edition__c = 'Standard';
        masterAccount.RC_Plan_Renewal_Date__c = System.today().addMonths(5);
        masterAccount.RC_Service_ID__c = String.valueOf(ValueProviderBuilder.provideUniqueDecimal(0, 8).getValue());
        masterAccount.RC_Signup_Date__c = System.now();
        masterAccount.RC_Signup_Funnel__c = String.valueOf(ValueProviderBuilder.provideUniqueFixedLengthString('FUNNEL', 8).getValue());
        masterAccount.RC_Sync_Status__c = 'In Sync';
        masterAccount.RC_Tier__c = 'Office';
        masterAccount.RC_Tier_ID__c = String.valueOf(ValueProviderBuilder.provideUniqueFixedLengthString('TIER', 8).getValue());
        masterAccount.RC_Upgrade_Date__c = System.today().addMonths(1);
        masterAccount.RC_User_ID__c = String.valueOf(ValueProviderBuilder.provideUniqueDecimal(0, 8).getValue());
        masterAccount.Sales_Booking_MRS__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 4).getValue();
        masterAccount.Service_Type__c = 'Office';
        masterAccount.Sign_up_Purchase_Limit__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 6).getValue();
        masterAccount.SignupType__c = 'Free';
        masterAccount.Total_Contract_Value_Calculated__c = Integer.valueOf(ValueProviderBuilder.provideUniqueDecimal(0, 8).getValue());
        masterAccount.Total_Contract_Value_Override__c = Integer.valueOf(ValueProviderBuilder.provideUniqueDecimal(0, 8).getValue());
        masterAccount.Total_DLs__c = Integer.valueOf(ValueProviderBuilder.provideUniqueDecimal(1, 3).getValue());
        masterAccount.Total_Potential_Users__c = Integer.valueOf(ValueProviderBuilder.provideUniqueDecimal(2, 2).getValue());
        masterAccount.VideoProvider__c = 'RCV';
        masterAccount.Actual_transport_MRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.Additional_Products_MRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.aMRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.Parent_Account_Total_MRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.MRR_Transfer_Effective_Date__c = System.today().addDays(15);
        masterAccount.MRR_of_current_customers__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.Farming_Assignment_MRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        masterAccount.Parent_Account_Total_MRR__c = (Decimal) ValueProviderBuilder.provideUniqueDecimal(0, 2).getValue();
        update masterAccount;

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };
        Test.startTest();
        Map<String, Account> result = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Test.stopTest();

        masterAccount = (Account) new AccountSelector()
            .selectAccountByIdWithAllFields(masterAccount.Id)
            .executeQuery()
            .get(0);

        System.assertNotEquals(true, result.isEmpty(), 'result should not be empty');
        System.assertNotEquals(true, result.containsKey(QuoteHelper.NGBS_OFFICE_PRODUCT), 'result should not contain MVP accounts');
        System.assertEquals(3, result.size(), 'result should contain 3 entries');


        for (String service : result.keySet()) {
            Account techAccount = result.get(service);

            System.assertNotEquals(
                null, techAccount,
                'technical account should be created'
            );
            System.assertEquals(
                String.format('{0} [system: {1}]', new List<Object> { masterAccount.Name, service }),
                techAccount.Name,
                'technical account should have correct name set'
            );
            System.assertEquals(
                service, techAccount.Service_Type__c,
                'technical account should have correct service name set'
            );
            System.assertEquals(
                masterAccount.Id, techAccount.Master_Account__c,
                'technical account should be linked to master'
            );
            System.assertEquals(
                true, techAccount.IsMultiProductTechnicalAccount__c,
                'technical account should have multi-product flag set'
            );
            System.assertEquals(
                techAccount.Id, techAccount.Ultimate_Parent_Account_ID__c,
                'technical account ultimate parent account id should be equal to id'
            );

            for (String fieldName : ACCOUNT_NULL_FIELDS) {
                System.assertEquals(
                    true, techAccount.get(fieldName) == null || techAccount.get(fieldName) == 0,
                    String.format(
                        'technical account field {0} should be null',
                        new List<Object>{ fieldName }
                    )
                );
            }
        }
    }

    @IsTest
    static void testGenerateEnterpriseAccountId() {
        new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134,
                RCSequence__c.SandboxNumber__c => 4
            })
            .create();

        Test.startTest();
            String enterpriseAccountId = AccountHelper.generateEnterpriseAccountId();
        Test.stopTest();
        Decimal subSequence = RCSequence__c.getInstance().SubSequence__c;
        System.assertEquals('131354990', enterpriseAccountId, 'EnterpriseAccountId is not equal as expected');
        System.assertEquals(135, subSequence, 'The subsequence should have a value greater than the previously created one.');
    }

    @isTest
    private static void testGetAccountNameById() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Response testResp = new Response();
        testResp.setData('Name', String.valueOf(testAccount.Name));

        Test.startTest();
        Response result = AccountHelper.getAccountNameById(testAccount.Id);
        Test.stopTest();

        System.assertEquals(Response.STATUS_SUCCESS, result.status, 'Status should be successful');
        System.assertEquals(testResp.data, result.data, 'Data should be equal');
    }

    @IsTest
    static void testIsPOCToPaid() {
        Triggers.switchOff();

        Account emptyAcc = new Account();

        Account paidAcc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Account paidAcc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Offer_Type__c => AccountHelper.PAID_STATUS,
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Account pocToPaidAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_Account_Status__c => AccountHelper.OFFER_TYPE_POC,
                Account.Offer_Type__c => AccountHelper.OFFER_TYPE_POC,
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Account pocToPaidTrialAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_Account_Status__c => AccountHelper.OFFER_TYPE_TRIAL,
                Account.Offer_Type__c => AccountHelper.OFFER_TYPE_TRIAL,
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Triggers.switchOn();

        System.assert(!AccountHelper.isPOCToPaid(null),
            'isPOCToPaid method should return false if null was passed as argument');
        System.assert(!AccountHelper.isPOCToPaid(emptyAcc),
            'isPOCToPaid method should return false for Account with empty Offer_Type__c field');
        System.assert(!AccountHelper.isPOCToPaid(paidAcc1),
            'isPOCToPaid method should return false for Account with RC_Account_Status__c \'' + AccountHelper.PAID_STATUS + '\'');
        System.assert(!AccountHelper.isPOCToPaid(paidAcc2),
            'isPOCToPaid method should return false for Account with Offer_Type__c \'' + AccountHelper.PAID_STATUS + '\'');
        System.assert(AccountHelper.isPOCToPaid(pocToPaidAcc),
            'isPOCToPaid method should return true for Account with Offer_Type__c \'POC\' and not empty User Id');
        System.assert(AccountHelper.isPOCToPaid(pocToPaidTrialAcc),
            'isPOCToPaid method should return true for Account with Offer_Type__c \'Trial\' and not empty User Id');
    }

    @isTest
    static void testIsAccFlagInAnyMigrationStatus() {
        Test.startTest();
            Boolean whenStatusIsValid = AccountHelper.isAccFlagInAnyMigrationStatus(new Account(AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_ROLLBACKED));
            Boolean whenNull = AccountHelper.isAccFlagInAnyMigrationStatus(new Account(AccMigrationFlag__c = null));
        Test.stopTest();

        Assert.isTrue(
            whenStatusIsValid,
            'When valid status is passed, should return true'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if AccMigrationFlag__c is not specified'
        );
    }

    @isTest
    static void testIsMigrationInProgress() {
        Test.startTest();
            Boolean whenStatusIsValid = AccountHelper.isMigrationInProgress(AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS);
            Boolean whenStatusIsNotInProgress = AccountHelper.isMigrationInProgress(AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED);
            Boolean whenNull = AccountHelper.isMigrationInProgress(null);
        Test.stopTest();

        Assert.isTrue(
            whenStatusIsValid,
            'When valid status is passed, should return true'
        );
        Assert.isFalse(
            whenStatusIsNotInProgress,
            'Should return false, if AccMigrationFlag__c is scheduled'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if AccMigrationFlag__c is not specified'
        );
    }

    @isTest
    static void testIsInactive() {
        Test.startTest();
            Boolean whenStatusIsValid = AccountHelper.isInactive(new Account(RC_Account_Status__c = AccountHelper.ACCOUNT_STATUS_TERMINATED));
            Boolean whenNull = AccountHelper.isInactive(new Account(RC_Account_Status__c = null));
        Test.stopTest();

        Assert.isTrue(
            whenStatusIsValid,
            'When RC_Account_Status__c is terminated, should return true'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if RC_Account_Status__c is not specified'
        );
    }

    @isTest
    static void testIsAnyInvoiceAccount() {
        Test.startTest();
            Boolean whenStatusIsValid = AccountHelper.isAnyInvoiceAccount(new Account(Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE));
            Boolean whenNull = AccountHelper.isAnyInvoiceAccount(new Account(Payment_Method__c = null));
        Test.stopTest();

        Assert.isTrue(
            whenStatusIsValid,
            'When Payment_Method__c is Invoice, should return true'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if Payment_Method__c is not specified'
        );
    }

    @isTest
    static void testCreateAccountContactRole() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Id dummyContactId = (Id) new ValueProvider.DummyIdProvider(Contact.sObjectType).getValue();

        Test.startTest();
            AccountContactRole createdAcr = AccountHelper.createAccountContactRole(dummyAccId, dummyContactId);
        Test.stopTest();

        Assert.isNotNull(createdAcr, 'The method must return an AccountContactRole');
        Assert.isTrue(createdAcr.IsPrimary, 'The returned AccountContactRole must be primary');
        Assert.areEqual(dummyAccId, createdAcr.AccountId, 'The returned AccountContactRole must have correct Account parent');
        Assert.areEqual(dummyContactId, createdAcr.ContactId, 'The returned AccountContactRole must have correct Contact parent');
    }

    @isTest
    static void testCreateAccountRelationEla() {
        Id dummyParentAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Id dummyChildAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            AccountRelation__c createdAr = AccountHelper.createAccountRelationEla(dummyParentAccId, dummyChildAccId);
        Test.stopTest();

        Assert.isNotNull(createdAr, 'The method must return an AccountContactRole');
        Assert.areEqual(AccountHelper.RELATION_TYPE_ELA, createdAr.Relation_Type__c, 'The returned Account Relation must be of a correct type');
        Assert.areEqual(dummyParentAccId, createdAr.Parent_Account__c, 'The returned Account Relation must have correct Account parent');
        Assert.areEqual(dummyChildAccId, createdAr.Child_Account__c, 'The returned Account Relation must have correct Account child');
    }

    @isTest
    static void testConvertAccountToElaBilling() {
        Account elaBillingAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, new ValueProvider.UniqueStringProvider())
            .build()
            .getRecord();

        Test.startTest();
            AccountHelper.convertAccountToElaBilling(elaBillingAccount);
        Test.stopTest();

        Assert.isTrue(
            elaBillingAccount.Name.contains(AccountHelper.ACCOUNT_BILLABLE_POSTFIX),
            'The method must add the needed postfix'
        );
    }

    @isTest
    static void testIsEBIndianAccount() {
        Test.startTest();
            Boolean whenAccIsIndian = AccountHelper.isEBIndianAccount(new Account(RC_Brand__c = OpportunityHelper.BRAND_RINGCENTRAL_EU, CurrencyIsoCode = OpportunityHelper.CURRENCY_NAME_INR));
            Boolean whenAccIsNotIndian = AccountHelper.isEBIndianAccount(new Account(RC_Brand__c = OpportunityHelper.BRAND_RINGCENTRAL_EU, CurrencyIsoCode = OpportunityHelper.CURRENCY_ISO_CODE_USD));
            Boolean whenNull = AccountHelper.isEBIndianAccount(null);
        Test.stopTest();

        Assert.isTrue(
            whenAccIsIndian,
            'When valid status is passed, should return true'
        );
        Assert.isFalse(
            whenAccIsNotIndian,
            'Should return false, if the input Account is not Indian'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if the input Account is not specified'
        );
    }

    @isTest
    static void testIsPackageActive() {
        Test.startTest();
            Boolean whenPackageIsActive = AccountHelper.isPackageActive(AccountHelper.PACKAGE_STATUS_ACTIVE);
            Boolean whenPackageIsInitial = AccountHelper.isPackageActive(AccountHelper.PACKAGE_STATUS_INITIAL);
            Boolean whenNull = AccountHelper.isPackageActive(null);
        Test.stopTest();

        Assert.isTrue(
            whenPackageIsActive,
            'Should return true, if package is ' + AccountHelper.PACKAGE_STATUS_ACTIVE
        );
        Assert.isFalse(
            whenPackageIsInitial,
            'Should return false, if the status is ' + AccountHelper.PACKAGE_STATUS_INITIAL
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if null is provided'
        );
    }

    @isTest
    static void testIsContracted() {
        Id dummySalesAgreementId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        Test.startTest();
            Boolean whenContracted = AccountHelper.isContracted(new Account(Active_Sales_Agreement__c = dummySalesAgreementId));
            Boolean whenNotContracted = AccountHelper.isContracted(new Account(Active_Sales_Agreement__c = null));
            Boolean whenNull = AccountHelper.isContracted(null);
        Test.stopTest();

        Assert.isTrue(
            whenContracted,
            'Should return true, if an Account has active sales agreement'
        );
        Assert.isFalse(
            whenNotContracted,
            'Should return false, if an Account does not have any active sales agreement'
        );
        Assert.isFalse(
            whenNull,
            'Should return false, if null is provided'
        );
    }

    @isTest
    static void testGetSupportedAccountIdsGroupedBySupportType() {
        final String SUPPORT_TYPE_1 = 'testSupportType1';
        final String SUPPORT_TYPE_2 = 'testSupportType2';

        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('test acc')
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Entitlement> testEnt = (List<Entitlement>) new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement.AccountId => ValueProviderBuilder.provideList(new List<String>{ testAccs[0].Id, testAccs[1].Id, testAccs[1].Id }),
                Entitlement.Name => 'Advanced Support',
                Entitlement.Type => 'testSupportType1',
                Entitlement.Type => ValueProviderBuilder.provideList(new List<String>{SUPPORT_TYPE_1, SUPPORT_TYPE_1, SUPPORT_TYPE_2 }),
                Entitlement.StartDate => Date.today().addDays(-1)
            })
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
        Map<String, Set<Id>> result = AccountHelper.getSupportedAccountIdsGroupedBySupportType(new Set<Id>{ testAccs[0].Id, testAccs[1].Id });
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 groups');
        System.assertEquals(2, result.get(SUPPORT_TYPE_1).size(), 'Should return 2 accounts for the testSupportType1');
        System.assertEquals(1, result.get(SUPPORT_TYPE_2).size(), 'Should return 1 account for the testSupportType2');
    }

    @isTest
    static void testGetMasterAccount() {
        ValueProvider.DummyIdProvider idProvider =  new ValueProvider.DummyIdProvider(Account.sObjectType);

        Account testMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => idProvider,
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .build()
            .getRecord();
        Account testTechAccount = buildTechAccWithMasterAcc(testMasterAccount, idProvider);

        Test.startTest();
            Account whenTechAccount = AccountHelper.getMasterAccount(testTechAccount);
            Account whenMasterAccount = AccountHelper.getMasterAccount(testMasterAccount);
        Test.stopTest();

        Assert.areEqual(testMasterAccount, whenTechAccount, 'Should return master Account for technical Account');
        Assert.areEqual(testMasterAccount, whenMasterAccount, 'Should return the same Account if it is not technical');
    }

    @isTest
    static void testPrepareAccountForUpdating() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.AID__c => 'AID1_account',
                Account.BMID__c => 'BMID1_account',
                Account.Id => ValueProviderBuilder.provideDummyId(Account.SObjectType)
            })
            .build()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.AID__c => 'AID1',
                Package__c.BMID__c => 'BMID1'
            })
            .build()
            .getRecord();
        Map<Id, Account> accountsToUpdate = new Map<id, Account>();

        Test.startTest();
            AccountHelper.prepareAccountForUpdating(testPackage, testAcc, accountsToUpdate);
        Test.stopTest();

        Assert.areEqual(1, accountsToUpdate.size(), 'Test account should be added in the map');

        for (SObjectField packageField : PackageHelper.PACKAGE_FIELDS) {
            SObjectField accountField = PackageHelper.PACKAGE_TO_ACCOUNT_FIELDS_MAP.get(packageField);
            Object accountFieldValue = testAcc.get(accountField);
            Object packageFieldValue = testPackage.get(packageField);

            Assert.areEqual(packageFieldValue, accountFieldValue, 'Account field <' + accountField + '> should be copied from package field <' + packageField + '>');
        }
    }

    private static Account buildTechAccWithMasterAcc(Account masterAccount, ValueProvider.DummyIdProvider idProvider) {
        Account testTechAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => idProvider,
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.Master_Account__c => masterAccount.Id
            })
            .build()
            .getRecord();

        return (Account) Test_Utils.putIntoUnwritableField(
            testTechAccount,
            Account.class,
            'Master_Account__r',
            masterAccount
        );
    }
}