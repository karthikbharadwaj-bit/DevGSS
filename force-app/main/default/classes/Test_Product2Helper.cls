@isTest
private class Test_Product2Helper {

    @testSetup
    static void setup() {
        // Create basic test products
        List<Product2> testProducts = new List<Product2>();
        
        // Service Plan Product
        Product2 servicePlanProduct = new Product2(
            Name = 'Office Standard',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_SERVICE_PLAN,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING,
            Seat_Range_Min__c = 1,
            Seat_Range_Max__c = 100,
            ExtID__c = 'LC_DL_75_' + System.currentTimeMillis()
        );
        testProducts.add(servicePlanProduct);
        
        // Extended Enterprise Support Product
        Product2 eesProduct = new Product2(
            Name = 'Extended Enterprise Support - Gold',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Seat_Range_Min__c = 1,
            Seat_Range_Max__c = 50
        );
        testProducts.add(eesProduct);
        
        // Contact Center Product
        Product2 ccProduct = new Product2(
            Name = 'Contact Center Seat',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Feature__c = 1,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING,
            ExtID__c = 'CC_RCCCSEAT_1'
        );
        testProducts.add(ccProduct);
        
        // Tax Product
        Product2 taxProduct = new Product2(
            Name = 'Tax Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_TAXES,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(taxProduct);
        
        // Overage Product
        Product2 overageProduct = new Product2(
            Name = 'Overage Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_OVERAGE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(overageProduct);
        
        // Phone Product
        Product2 phoneProduct = new Product2(
            Name = 'Phone Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_DISCOUNTED_PHONES,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_DISCOUNTED_PHONES,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        testProducts.add(phoneProduct);
        
        // Rental Phone Product
        Product2 rentalPhoneProduct = new Product2(
            Name = 'Rental Phone',
            IsActive = true,
            Family = Product2Helper.FAMILY_RENTAL_PHONES,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_DISCOUNTED_PHONES,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(rentalPhoneProduct);
        
        // Mobile User Product
        Product2 mobileUserProduct = new Product2(
            Name = 'Mobile User',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            ExtID__c = Product2Helper.MOBILE_USER_ELEMENT_ID,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(mobileUserProduct);
        
        // Professional Service Product
        Product2 proServProduct = new Product2(
            Name = 'Professional Service',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Group__c = Product2Helper.GROUP_PROSERV,
            Subgroup__c = Product2Helper.SUBGROUP_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        testProducts.add(proServProduct);
        
        // Storage Product
        Product2 storageProduct = new Product2(
            Name = 'Additional Storage',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            CatID__c = Product2Helper.CATID_ADDITIONAL_STORAGE,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(storageProduct);
        
        // Global Seat Product
        Product2 globalSeatProduct = new Product2(
            Name = 'Global Seat',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            CatID__c = '12653-1704-000',
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(globalSeatProduct);
        
        // CC Bundle Product
        Product2 ccBundleProduct = new Product2(
            Name = 'Minutes Bundle 25K',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_CALLS,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(ccBundleProduct);
        
        // Usage License Product
        Product2 usageLicenseProduct = new Product2(
            Name = 'Usage License',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Billing_Type__c = Product2Helper.BILLING_TYPE_USAGE,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(usageLicenseProduct);
        
        // Recurring License Product
        Product2 recurringLicenseProduct = new Product2(
            Name = 'Recurring License',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        testProducts.add(recurringLicenseProduct);
        
        // Shipping Auto Product
        Product2 shippingAutoProduct = new Product2(
            Name = 'Shipping Auto Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            ShippingType__c = Product2Helper.SHIPPING_TYPE_AUTO,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        testProducts.add(shippingAutoProduct);
        
        // Shipping Manual Product
        Product2 shippingManualProduct = new Product2(
            Name = 'Shipping Manual Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            ShippingType__c = Product2Helper.SHIPPING_TYPE_MANUAL,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        testProducts.add(shippingManualProduct);
        
        insert testProducts;
    }

    @isTest
    static void testIsMonthly() {
        Test.startTest();
        
        // Test valid monthly charge terms
        Assert.areEqual(true, Product2Helper.isMonthly(Product2Helper.CHARGE_TERM_MONTHLY), 'Monthly charge term should return true');
        Assert.areEqual(true, Product2Helper.isMonthly(Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT), 'Monthly Contract charge term should return true');
        
        // Test invalid charge terms
        Assert.areEqual(false, Product2Helper.isMonthly(Product2Helper.CHARGE_TERM_ANNUAL), 'Annual charge term should return false');
        Assert.areEqual(false, Product2Helper.isMonthly(Product2Helper.CHARGE_TERM_ONE_TIME), 'One Time charge term should return false');
        Assert.areEqual(false, Product2Helper.isMonthly(null), 'Null charge term should return false');
        Assert.areEqual(false, Product2Helper.isMonthly(''), 'Empty charge term should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsExtendedEnterprise() {
        Test.startTest();
        
        Product2 eesProduct = [SELECT Id, Name, Feature__c FROM Product2 WHERE Name = 'Extended Enterprise Support - Gold' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isExtendedEnterprise(eesProduct), 'Extended Enterprise product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isExtendedEnterprise(null), 'Null product should return false');
        
        // Test with non-EES product
        Product2 serviceProduct = [SELECT Id, Name, Feature__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isExtendedEnterprise(serviceProduct), 'Non-EES product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsCCSeat() {
        Test.startTest();
        
        Product2 ccSeatProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Contact Center Seat' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isCCSeat(ccSeatProduct), 'CC Seat product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isCCSeat(null), 'Null product should return false');
        
        // Test with non-CC Seat product
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isCCSeat(serviceProduct), 'Non-CC Seat product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsCCProduct() {
        Test.startTest();
        
        Product2 ccProduct = [SELECT Id, Name, Sub_Category__c FROM Product2 WHERE Name = 'Contact Center Seat' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isCCProduct(ccProduct), 'CC product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isCCProduct(null), 'Null product should return false');
        
        // Test with non-CC product
        Product2 serviceProduct = [SELECT Id, Name, Sub_Category__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isCCProduct(serviceProduct), 'Non-CC product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsServicePlan() {
        Test.startTest();
        
        Product2 servicePlanProduct = [SELECT Id, Name, Family, Feature__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isServicePlan(servicePlanProduct), 'Service plan product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isServicePlan(null), 'Null product should return false');
        
        // Test with non-service plan product
        Product2 ccProduct = [SELECT Id, Name, Family, Feature__c FROM Product2 WHERE Name = 'Contact Center Seat' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isServicePlan(ccProduct), 'Non-service plan product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsTaxes() {
        Test.startTest();
        
        Product2 taxProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Tax Product' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isTaxes(taxProduct), 'Tax product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isTaxes((Product2) null), 'Null product should return false');
        
        // Test with non-tax product
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isTaxes(serviceProduct), 'Non-tax product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsOverage() {
        Test.startTest();
        
        Product2 overageProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Overage Product' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isOverage(overageProduct), 'Overage product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isOverage(null), 'Null product should return false');
        
        // Test with non-overage product
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isOverage(serviceProduct), 'Non-overage product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testGetGoaGroup() {
        Test.startTest();
        
        // Test with valid JSON
        String validJson = '{"regular": "Test Group"}';
        String result = Product2Helper.getGoaGroup(validJson);
        Assert.areEqual('Test Group', result, 'Valid JSON should return correct group');
        
        // Test with null JSON
        result = Product2Helper.getGoaGroup(null);
        Assert.areEqual('Default', result, 'Null JSON should return Default');
        
        // Test with empty JSON
        result = Product2Helper.getGoaGroup('');
        Assert.areEqual('Default', result, 'Empty JSON should return Default');
        
        // Test with invalid JSON
        result = Product2Helper.getGoaGroup('invalid json');
        Assert.areEqual('Default', result, 'Invalid JSON should return Default');
        
        // Test with JSON without regular key
        String jsonWithoutRegular = '{"other": "value"}';
        result = Product2Helper.getGoaGroup(jsonWithoutRegular);
        Assert.areEqual('Default', result, 'JSON without regular key should return Default');
        
        Test.stopTest();
    }

    @isTest
    static void testConstants() {
        Test.startTest();
        
        // Test product type constants
        Assert.areEqual('Seat', Product2Helper.PRODUCT_TYPE_SEAT, 'PRODUCT_TYPE_SEAT should be correct');
        Assert.areEqual('Port', Product2Helper.PRODUCT_TYPE_PORT, 'PRODUCT_TYPE_PORT should be correct');
        Assert.areEqual('Transport', Product2Helper.PRODUCT_TYPE_TRANSPORT, 'PRODUCT_TYPE_TRANSPORT should be correct');
        
        // Test family constants
        Assert.areEqual('Overage', Product2Helper.FAMILY_OVERAGE, 'FAMILY_OVERAGE should be correct');
        Assert.areEqual('Taxes', Product2Helper.FAMILY_TAXES, 'FAMILY_TAXES should be correct');
        Assert.areEqual('Service', Product2Helper.FAMILY_SERVICE, 'FAMILY_SERVICE should be correct');
        
        // Test charge term constants
        Assert.areEqual('One - Time', Product2Helper.CHARGE_TERM_ONE_TIME, 'CHARGE_TERM_ONE_TIME should be correct');
        Assert.areEqual('Annual', Product2Helper.CHARGE_TERM_ANNUAL, 'CHARGE_TERM_ANNUAL should be correct');
        Assert.areEqual('Monthly', Product2Helper.CHARGE_TERM_MONTHLY, 'CHARGE_TERM_MONTHLY should be correct');
        
        // Test feature constants
        Assert.areEqual(17, Product2Helper.FEATURE_SERVICE_PLAN, 'FEATURE_SERVICE_PLAN should be correct');
        Assert.areEqual(28, Product2Helper.FEATURE_SERVICE_PLAN_FAX, 'FEATURE_SERVICE_PLAN_FAX should be correct');
        Assert.areEqual(12, Product2Helper.FEATURE_LIMITED_EXTENSION, 'FEATURE_LIMITED_EXTENSION should be correct');
        
        // Test subcategory constants
        Assert.areEqual('Main', Product2Helper.SUBCATEGORY_RINGCENTRAL, 'SUBCATEGORY_RINGCENTRAL should be correct');
        Assert.areEqual('Professional Services', Product2Helper.SUBCATEGORY_PROSERV, 'SUBCATEGORY_PROSERV should be correct');
        Assert.areEqual('Contact Center', Product2Helper.SUBCATEGORY_CONTACT_CENTER, 'SUBCATEGORY_CONTACT_CENTER should be correct');
        
        Test.stopTest();
    }

    @isTest
    static void testIsExtendedEnterpriseBronze() {
        Test.startTest();
        
        // Create a Bronze EES product
        Product2 bronzeEesProduct = new Product2(
            Name = 'Extended Enterprise Support - Bronze',
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL
        );
        insert bronzeEesProduct;
        
        Assert.areEqual(true, Product2Helper.isExtendedEnterpriseBronze(bronzeEesProduct), 'Bronze EES product should return true');
        
        // Test with feature and name parameters
        Assert.areEqual(true, Product2Helper.isExtendedEnterpriseBronze(Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT, 'Extended Enterprise Support - Bronze'), 
                     'Bronze EES with feature and name should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isExtendedEnterpriseBronze(null), 'Null product should return false');
        
        // Test with non-Bronze EES product
        Product2 goldEesProduct = [SELECT Id, Name, Feature__c FROM Product2 WHERE Name = 'Extended Enterprise Support - Gold' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isExtendedEnterpriseBronze(goldEesProduct), 'Gold EES product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsCcService() {
        Test.startTest();
        
        Product2 ccServiceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Contact Center Seat' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isCcService(ccServiceProduct), 'CC Service product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isCcService(null), 'Null product should return false');
        
        // Test with non-CC Service product
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isCcService(serviceProduct), 'Non-CC Service product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsPortProduct() {
        Test.startTest();
        
        // Create test products
        Product2 portProduct = new Product2(
            Name = 'Port Product Test ' + System.currentTimeMillis(),
            IsActive = true,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_PORT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        insert portProduct;
        
        Product2 serviceProduct = new Product2(
            Name = 'Office Standard Test ' + System.currentTimeMillis(),
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_SERVICE_PLAN,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING,
            Seat_Range_Min__c = 1,
            Seat_Range_Max__c = 100,
            ExtID__c = 'LC_DL_75_' + System.currentTimeMillis()
        );
        insert serviceProduct;
        
        Assert.areEqual(true, Product2Helper.isPortProduct(portProduct), 'Port product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isPortProduct(null), 'Null product should return false');
        
        // Test with non-port product
        Assert.areEqual(false, Product2Helper.isPortProduct(serviceProduct), 'Non-port product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsSeatProduct() {
        Test.startTest();
        
        // Create test products
        Product2 seatProduct = new Product2(
            Name = 'Office Standard Seat Test ' + System.currentTimeMillis(),
            IsActive = true,
            Family = Product2Helper.FAMILY_SERVICE,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Feature__c = Product2Helper.FEATURE_SERVICE_PLAN,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING,
            Seat_Range_Min__c = 1,
            Seat_Range_Max__c = 100,
            ExtID__c = 'LC_DL_75_' + System.currentTimeMillis()
        );
        insert seatProduct;
        
        Product2 portProduct = new Product2(
            Name = 'Port Product Seat Test ' + System.currentTimeMillis(),
            IsActive = true,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_PORT,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        insert portProduct;
        
        Assert.areEqual(true, Product2Helper.isSeatProduct(seatProduct), 'Seat product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isSeatProduct(null), 'Null product should return false');
        
        // Test with non-seat product
        Assert.areEqual(false, Product2Helper.isSeatProduct(portProduct), 'Non-seat product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsSameProductType() {
        Test.startTest();
        
        Assert.areEqual(true, Product2Helper.isSameProductType(Product2Helper.PRODUCT_TYPE_SEAT, Product2Helper.PRODUCT_TYPE_SEAT), 
                     'Same product types should return true');
        Assert.areEqual(true, Product2Helper.isSameProductType('Seat', 'SEAT'), 
                     'Case insensitive product types should return true');
        
        Assert.areEqual(false, Product2Helper.isSameProductType(Product2Helper.PRODUCT_TYPE_SEAT, Product2Helper.PRODUCT_TYPE_PORT), 
                     'Different product types should return false');
        Assert.areEqual(false, Product2Helper.isSameProductType(null, Product2Helper.PRODUCT_TYPE_SEAT), 
                     'Null product type should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsExtendedEnterpriseSupportInRange() {
        Test.startTest();
        
        Product2 eesProduct = [SELECT Id, Name, Seat_Range_Min__c, Seat_Range_Max__c FROM Product2 WHERE Name = 'Extended Enterprise Support - Gold' LIMIT 1];
        
        
        // Create a mock QuoteLineItem for testing
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.Quantity = 25;
        mockQLI.NewQuantity__c = 25;
        mockQLI.Zero_Quantity__c = false;
        
        Assert.areEqual(true, Product2Helper.isExtendedEnterpriseSupportInRange(eesProduct, mockQLI), 
                     'EES product should be in range for 25 seats');
        
        // Test with null products
        Assert.areEqual(false, Product2Helper.isExtendedEnterpriseSupportInRange(null, mockQLI), 
                     'Null EES product should return false');
        Assert.areEqual(false, Product2Helper.isExtendedEnterpriseSupportInRange(eesProduct, null), 
                     'Null QLI should return false');
        
        // Test with out of range quantity
        mockQLI.Quantity = 100;
        mockQLI.Zero_Quantity__c = false;
        Assert.areEqual(false, Product2Helper.isExtendedEnterpriseSupportInRange(eesProduct, mockQLI), 
                     'EES product should not be in range for 100 seats');
        
        Test.stopTest();
    }

    @isTest
    static void testIsTechnical() {
        Test.startTest();
        
        Product2 technicalProduct = new Product2(
            Name = 'Technical Product',
            IsActive = true,
            Family = Product2Helper.FAMILY_TECHNICAL,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );
        insert technicalProduct;
        
        Assert.areEqual(true, Product2Helper.isTechnical(technicalProduct), 'Technical product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isTechnical(null), 'Null product should return false');
        
        // Test with non-technical product
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isTechnical(serviceProduct), 'Non-technical product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testGetFeaturesUnavailableForOpportunity() {
        Test.startTest();
        
        // Test with null record type
        Set<Decimal> features = Product2Helper.getFeaturesUnavailableForOpportunity(null);
        Assert.areEqual(true, features != null, 'Features set should not be null');
        
        // Test with empty record type
        features = Product2Helper.getFeaturesUnavailableForOpportunity('');
        Assert.areEqual(true, features != null, 'Features set should not be null');
        
        // Test with valid record type (assuming no custom settings exist)
        features = Product2Helper.getFeaturesUnavailableForOpportunity('Test Record Type');
        Assert.areEqual(true, features != null, 'Features set should not be null');
        
        Test.stopTest();
    }

    @isTest
    static void testIsPhone() {
        Test.startTest();
        
        Product2 phoneProduct = [SELECT Id, Name, Feature__c FROM Product2 WHERE Name = 'Phone Product' LIMIT 1];
        
        // Test with null QLI
        Assert.areEqual(false, Product2Helper.isPhone(null), 'Null QLI should return false');
        
        // Test with phone QLI
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.Product2 = phoneProduct;
        Assert.areEqual(true, Product2Helper.isPhone(mockQLI), 'Phone QLI should return true');
        
        // Test with non-phone QLI
        Product2 serviceProduct = [SELECT Id, Name, Feature__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        mockQLI.Product2 = serviceProduct;
        Assert.areEqual(false, Product2Helper.isPhone(mockQLI), 'Non-phone QLI should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsRentalPhone() {
        Test.startTest();
        
        Product2 rentalPhoneProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Rental Phone' LIMIT 1];
        
        // Test with null QLI
        Assert.areEqual(false, Product2Helper.isRentalPhone(null), 'Null QLI should return false');
        
        // Test with rental phone QLI
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.Product2 = rentalPhoneProduct;
        Assert.areEqual(true, Product2Helper.isRentalPhone(mockQLI), 'Rental phone QLI should return true');
        
        // Test with non-rental phone QLI
        Product2 serviceProduct = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        mockQLI.Product2 = serviceProduct;
        Assert.areEqual(false, Product2Helper.isRentalPhone(mockQLI), 'Non-rental phone QLI should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsMobileUser() {
        Test.startTest();
        
        Product2 mobileUserProduct = [SELECT Id, Name, ExtID__c FROM Product2 WHERE Name = 'Mobile User' LIMIT 1];
        QuoteLineItem mockQLI = new QuoteLineItem();
        mockQLI.Product2 = mobileUserProduct;
        
        Assert.areEqual(true, Product2Helper.isMobileUser(mockQLI), 'Mobile user QLI should return true');
        
        // Test with null QLI
        Assert.areEqual(false, Product2Helper.isMobileUser(null), 'Null QLI should return false');
        
        // Test with non-mobile user QLI
        Product2 serviceProduct = [SELECT Id, Name, ExtID__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        mockQLI.Product2 = serviceProduct;
        Assert.areEqual(false, Product2Helper.isMobileUser(mockQLI), 'Non-mobile user QLI should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsProductApplicableForSyncWithNGBS() {
        Test.startTest();
        
        Product2 serviceProduct = [SELECT Id, Name, Sub_Category__c, Family, Charge_Term__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isProductApplicableForSyncWithNGBS(serviceProduct), 
                     'Service product should be applicable for NGBS sync');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isProductApplicableForSyncWithNGBS(null), 
                     'Null product should not be applicable for NGBS sync');
        
        // Test with CC ProServ product
        Product2 ccProServProduct = new Product2(
            Name = 'CC ProServ',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV,
            Family = Product2Helper.FAMILY_SERVICE,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME
        );
        insert ccProServProduct;
        Assert.areEqual(false, Product2Helper.isProductApplicableForSyncWithNGBS(ccProServProduct), 
                     'CC ProServ product should not be applicable for NGBS sync');
        
        // Test with tax product
        Product2 taxProduct = [SELECT Id, Name, Sub_Category__c, Family FROM Product2 WHERE Name = 'Tax Product' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isProductApplicableForSyncWithNGBS(taxProduct), 
                     'Tax product should not be applicable for NGBS sync');
        
        Test.stopTest();
    }

    @isTest
    static void testIsUsageLicense() {
        Test.startTest();
        
        Product2 usageLicenseProduct = [SELECT Id, Name, Billing_Type__c FROM Product2 WHERE Name = 'Usage License' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isUsageLicense(usageLicenseProduct), 'Usage license product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isUsageLicense(null), 'Null product should return false');
        
        // Test with non-usage license product
        Product2 recurringProduct = [SELECT Id, Name, Billing_Type__c FROM Product2 WHERE Name = 'Recurring License' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isUsageLicense(recurringProduct), 'Non-usage license product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsRecurringLicense() {
        Test.startTest();
        
        Product2 recurringLicenseProduct = [SELECT Id, Name, Billing_Type__c FROM Product2 WHERE Name = 'Recurring License' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isRecurringLicense(recurringLicenseProduct), 'Recurring license product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isRecurringLicense(null), 'Null product should return false');
        
        // Test with non-recurring license product
        Product2 usageProduct = [SELECT Id, Name, Billing_Type__c FROM Product2 WHERE Name = 'Usage License' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isRecurringLicense(usageProduct), 'Non-recurring license product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsActiveStorage() {
        Test.startTest();
        
        Product2 storageProduct = [SELECT Id, Name, CatID__c FROM Product2 WHERE Name = 'Additional Storage' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isActiveStorage(storageProduct), 'Storage product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isActiveStorage(null), 'Null product should return false');
        
        // Test with non-storage product
        Product2 serviceProduct = [SELECT Id, Name, CatID__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isActiveStorage(serviceProduct), 'Non-storage product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsGlobalSeat() {
        Test.startTest();
        
        Product2 globalSeatProduct = [SELECT Id, Name, CatID__c FROM Product2 WHERE Name = 'Global Seat' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isGlobalSeat(globalSeatProduct), 'Global seat product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isGlobalSeat(null), 'Null product should return false');
        
        // Test with non-global seat product
        Product2 serviceProduct = [SELECT Id, Name, CatID__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isGlobalSeat(serviceProduct), 'Non-global seat product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testGetCCBundleTypeName() {
        Test.startTest();
        
        Product2 ccBundleProduct = [SELECT Id, Name, Sub_Category__c, Product_Type__c FROM Product2 WHERE Name = 'Minutes Bundle 25K' LIMIT 1];
        
        String bundleType = Product2Helper.getCCBundleTypeName(ccBundleProduct);
        Assert.areEqual('Calls Bundle', bundleType, 'CC bundle product should return Calls Bundle type');
        
        // Test with null product
        bundleType = Product2Helper.getCCBundleTypeName(null);
        Assert.areEqual(null, bundleType, 'Null product should return null');
        
        // Test with non-CC product
        Product2 serviceProduct = [SELECT Id, Name, Sub_Category__c, Product_Type__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        bundleType = Product2Helper.getCCBundleTypeName(serviceProduct);
        Assert.areEqual(null, bundleType, 'Non-CC product should return null');
        
        Test.stopTest();
    }

    @isTest
    static void testGetCCBundleVolume() {
        Test.startTest();
        
        Product2 ccBundleProduct = [SELECT Id, Name, Sub_Category__c FROM Product2 WHERE Name = 'Minutes Bundle 25K' LIMIT 1];
        
        Decimal volume = Product2Helper.getCCBundleVolume(ccBundleProduct);
        Assert.areEqual(25, volume, 'CC bundle product should return correct volume');
        
        // Test with null product
        volume = Product2Helper.getCCBundleVolume(null);
        Assert.areEqual(null, volume, 'Null product should return null');
        
        // Test with non-CC product
        Product2 serviceProduct = [SELECT Id, Name, Sub_Category__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        volume = Product2Helper.getCCBundleVolume(serviceProduct);
        Assert.areEqual(null, volume, 'Non-CC product should return null');
        
        // Test with product without volume in name
        Product2 ccProduct = [SELECT Id, Name, Sub_Category__c FROM Product2 WHERE Name = 'Contact Center Seat' LIMIT 1];
        volume = Product2Helper.getCCBundleVolume(ccProduct);
        Assert.areEqual(null, volume, 'Product without volume in name should return null');
        
        Test.stopTest();
    }

    @isTest
    static void testIsShippingTypeAuto() {
        Test.startTest();
        
        Product2 shippingAutoProduct = [SELECT Id, Name, ShippingType__c FROM Product2 WHERE Name = 'Shipping Auto Product' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isShippingTypeAuto(shippingAutoProduct), 'Auto shipping product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isShippingTypeAuto(null), 'Null product should return false');
        
        // Test with manual shipping product
        Product2 shippingManualProduct = [SELECT Id, Name, ShippingType__c FROM Product2 WHERE Name = 'Shipping Manual Product' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isShippingTypeAuto(shippingManualProduct), 'Manual shipping product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsShippingTypeManual() {
        Test.startTest();
        
        Product2 shippingManualProduct = [SELECT Id, Name, ShippingType__c FROM Product2 WHERE Name = 'Shipping Manual Product' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isShippingTypeManual(shippingManualProduct), 'Manual shipping product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isShippingTypeManual(null), 'Null product should return false');
        
        // Test with auto shipping product
        Product2 shippingAutoProduct = [SELECT Id, Name, ShippingType__c FROM Product2 WHERE Name = 'Shipping Auto Product' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isShippingTypeManual(shippingAutoProduct), 'Auto shipping product should return false');
        
        Test.stopTest();
    }

    @isTest
    static void testIsProfessionalServiceProduct() {
        Test.startTest();
        
        Product2 proServProduct = [SELECT Id, Name, Group__c, Subgroup__c FROM Product2 WHERE Name = 'Professional Service' LIMIT 1];
        
        Assert.areEqual(true, Product2Helper.isProfessionalServiceProduct(proServProduct), 'Professional service product should return true');
        
        // Test with null product
        Assert.areEqual(false, Product2Helper.isProfessionalServiceProduct(null), 'Null product should return false');
        
        // Test with non-professional service product
        Product2 serviceProduct = [SELECT Id, Name, Group__c, Subgroup__c FROM Product2 WHERE Name = 'Office Standard' LIMIT 1];
        Assert.areEqual(false, Product2Helper.isProfessionalServiceProduct(serviceProduct), 'Non-professional service product should return false');
        
        Test.stopTest();
    }
}