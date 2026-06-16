@isTest
private class Test_EntitlementTriggerHelper
{
    static Account acc;
    static Map<String, Product2> products;

    static void createDate() {
        Account accToInsert = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        acc = accToInsert;
        products = new Map<String, Product2>();

        Product2 ccServiceMonthlyContract = new Product2(
            Name = 'ccServiceMonthlyContract',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
        );
        products.put('ccServiceMonthlyContract', ccServiceMonthlyContract);

        Product2 ccServiceAnnual = new Product2(
            Name = 'ccServiceAnnual',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        products.put('ccServiceAnnual', ccServiceAnnual);

        Product2 ccServiceOneTime = new Product2(
            Name = 'ccServiceOneTime',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        products.put('ccServiceOneTime', ccServiceOneTime);

        Product2 serviceCCSubTypeFirst = new Product2(
            Name = 'serviceCCSubTypeFirst',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        products.put('serviceCCSubTypeFirst', serviceCCSubTypeFirst);

        Product2 serviceCCSubTypeSecond = new Product2(
            Name = 'serviceCCSubTypeSecond',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        products.put('serviceCCSubTypeSecond', serviceCCSubTypeSecond);

        Product2 feeSameNameFirst = new Product2(
            Name = 'feeSameName',
            IsActive = true,
            Family = Product2Helper.FAMILY_FEE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        products.put('feeSameNameFirst', feeSameNameFirst);

        Product2 feeSameNameSecond = new Product2(
            Name = 'feeSameName',
            IsActive = true,
            Family = Product2Helper.FAMILY_FEE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        products.put('feeSameNameSecond', feeSameNameSecond);


        Product2 serviceCloudConnect = new Product2(
            Name = 'serviceCloudConnect',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Product_Type__c = 'CloudConnect',
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        products.put('serviceCloudConnect', serviceCloudConnect);

        Product2 serviceExtendedSupport = new Product2(
            Name = 'serviceExtendedSupport',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        products.put('serviceExtendedSupport', serviceExtendedSupport);

        insert products.values();

    }
    @isTest
    static void testAccountCCPaymentTypeSetToAnnualPrePay_updatedToonthToMonth()
    {
        createDate();
        Entitlement__c entAnnual = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('ccServiceAnnual').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        insert entAnnual;

        Account accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY, accToCheck.CcPaymentType__c);
        System.assertEquals(false, accToCheck.CcConverted__c);

        Test.startTest();
            List<Entitlement__c> entList = new List<Entitlement__c>();

            entList.add(entAnnual);
            Entitlement__c entMonthlyContract = new Entitlement__c(
                Name = 'test1', Account__c = acc.Id, Active__c = true,
                Product__c = products.get('ccServiceMonthlyContract').Id,
                Price__c = 25,
                Discount__c = 10,
                Discount_Type__c = 'Currency'
            );
            entList.add(entMonthlyContract);
            upsert entList;

            accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_MONTH_TO_MONTH, accToCheck.CcPaymentType__c);
            System.assertEquals(true, accToCheck.CcConverted__c);
        Test.stopTest();
    }

    @isTest
    static void testAccountCCPaymentTypeSetToMonthToMonth_updatedToAnnual()
    {
        createDate();
        Entitlement__c entAnnual = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('ccServiceMonthlyContract').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        insert entAnnual;

        Account accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_MONTH_TO_MONTH, accToCheck.CcPaymentType__c);
        System.assertEquals(false, accToCheck.CcConverted__c);

        Test.startTest();
            List<Entitlement__c> entList = new List<Entitlement__c>();
            entList.add(entAnnual);
            Entitlement__c entMonthlyContract = new Entitlement__c(
                Name = 'test1', Account__c = acc.Id, Active__c = true,
                Product__c = products.get('ccServiceAnnual').Id,
                Price__c = 25,
                Discount__c = 10,
                Discount_Type__c = 'Currency'
            );
            entList.add(entMonthlyContract);
            upsert entList;

            accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY, accToCheck.CcPaymentType__c);
            System.assertEquals(false, accToCheck.CcConverted__c);
        Test.stopTest();
    }

    @isTest
    static void testDeactivateMonthToMonthEntitlment()
    {
        createDate();
        Entitlement__c ccServiceMonthlyContract = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('ccServiceMonthlyContract').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        insert ccServiceMonthlyContract;

        Account accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_MONTH_TO_MONTH, accToCheck.CcPaymentType__c);
        System.assertEquals(false, accToCheck.CcConverted__c);

        Test.startTest();
            ccServiceMonthlyContract.Active__c = false;
            update ccServiceMonthlyContract;

            accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(null, accToCheck.CcPaymentType__c);
            System.assertEquals(false, accToCheck.CcConverted__c);
        Test.stopTest();
    }

    @isTest
    static void testDeactivateOldEntitlmentOnInsert_UpdateAccountFlags()
    {
        createDate();
        List<Entitlement__c> entitlements = new List<Entitlement__c>();
        Entitlement__c serviceCloudConnect = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('serviceCloudConnect').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(serviceCloudConnect);
        Entitlement__c serviceCCSubTypeFirst = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('serviceCCSubTypeFirst').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(serviceCCSubTypeFirst);
        Entitlement__c feeSameNameFirst = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('feeSameNameFirst').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(feeSameNameFirst);
        Entitlement__c ccServiceOneTime = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = true,
            Product__c = products.get('ccServiceOneTime').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(ccServiceOneTime);
        insert entitlements;

        Account accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c, Extended_Enterprise_Support_Customer__c
                                FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, accToCheck.CcPaymentType__c);
        System.assertEquals(false, accToCheck.CcConverted__c);
        System.assertEquals(false, accToCheck.Extended_Enterprise_Support_Customer__c);

        Test.startTest();
            List<Entitlement__c> anotherEntitlements = new List<Entitlement__c>();
            Entitlement__c serviceCCSubTypeSecond = new Entitlement__c(
                Name = 'test1', Account__c = acc.Id, Active__c = true,
                Product__c = products.get('serviceCCSubTypeSecond').Id,
                Price__c = 25,
                Discount__c = 10,
                Discount_Type__c = 'Currency'
            );
            anotherEntitlements.add(serviceCCSubTypeSecond);
            Entitlement__c feeSameNameSecond = new Entitlement__c(
                Name = 'test1', Account__c = acc.Id, Active__c = true,
                Product__c = products.get('feeSameNameSecond').Id,
                Price__c = 25,
                Discount__c = 10,
                Discount_Type__c = 'Currency'
            );
            anotherEntitlements.add(feeSameNameSecond);
            Entitlement__c serviceExtendedSupport = new Entitlement__c(
                Name = 'test1', Account__c = acc.Id, Active__c = true,
                Product__c = products.get('serviceExtendedSupport').Id,
                Price__c = 25,
                Discount__c = 10,
                Discount_Type__c = 'Currency'
            );
            anotherEntitlements.add(serviceExtendedSupport);
            insert anotherEntitlements;

            accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c, Extended_Enterprise_Support_Customer__c
                            FROM Account WHERE Id = :acc.Id];
            System.assertEquals(null, accToCheck.CcPaymentType__c);
            System.assertEquals(false, accToCheck.CcConverted__c);
            System.assertEquals(true, accToCheck.Extended_Enterprise_Support_Customer__c);

            List<Id> oldEntIds = new List<Id>{serviceCCSubTypeFirst.Id, serviceCloudConnect.Id, feeSameNameFirst.Id};
            for(Entitlement__c entOld : [SELECT Id, Active__c, Product__r.Name FROM Entitlement__c
                                        WHERE Id IN :oldEntIds]) {
                System.assertEquals(false, entOld.Active__c, 'Entitlement for product (' + entOld.Product__r.Name + ') still active');
            }
        Test.stopTest();
    }

    @isTest
    static void testSetCloudConnectCustomerOnAccount_onUpdate()
    {
        createDate();
        List<Entitlement__c> entitlements = new List<Entitlement__c>();
        Entitlement__c serviceCloudConnect = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = false,
            Product__c = products.get('serviceCloudConnect').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(serviceCloudConnect);
        Entitlement__c serviceExtendedSupport = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = false,
            Product__c = products.get('serviceExtendedSupport').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(serviceExtendedSupport);
        Entitlement__c entAnnual = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = false,
            Product__c = products.get('ccServiceAnnual').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(entAnnual);
        insert entitlements;

        Account accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c, Extended_Enterprise_Support_Customer__c
                                FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, accToCheck.CcPaymentType__c);
        System.assertEquals(false, accToCheck.CcConverted__c);
        System.assertEquals(false, accToCheck.Extended_Enterprise_Support_Customer__c);

        // DoNotChangeAnnualPaymentType
        accToCheck.CcPaymentType__c = AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL;
        update accToCheck;

        Test.startTest();
            for(Entitlement__c ent : entitlements){
                ent.Active__c = true;
            }
            update entitlements;

            accToCheck = [SELECT Id, CcPaymentType__c, CcConverted__c, Extended_Enterprise_Support_Customer__c
                                FROM Account WHERE Id = :acc.Id];
            System.assertEquals(AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL, accToCheck.CcPaymentType__c);
            System.assertEquals(false, accToCheck.CcConverted__c);
            System.assertEquals(true, accToCheck.Extended_Enterprise_Support_Customer__c);
        Test.stopTest();
    }

    @isTest
    static void testPrepopulateChargeTerm_onUpdate()
    {
        createDate();

        Test.startTest();
        List<Entitlement__c> entitlements = new List<Entitlement__c>();
        Entitlement__c serviceCloudConnect = new Entitlement__c(
            Name = 'test1', Account__c = acc.Id, Active__c = false,
            Product__c = products.get('serviceCloudConnect').Id,
            Price__c = 25,
            Discount__c = 10,
            Discount_Type__c = 'Currency'
        );
        entitlements.add(serviceCloudConnect);
        insert entitlements;
        Test.stopTest();

        Map <Id, Entitlement__c> entsMap = new Map <Id, Entitlement__c> ([SELECT Id, ChargeTerm__c FROM Entitlement__c]);
        Entitlement__c serviceCloudConnectResult = entsMap.get(serviceCloudConnect.Id);
        System.assertEquals(serviceCloudConnectResult.ChargeTerm__c, products.get('serviceCloudConnect').Charge_Term__c);
    }
}