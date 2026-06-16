@isTest
public class TestDataGenerator {

    public static string TEST_PACKAGE_INFO = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"SC","discount":{"type":"Percent","value":"3.48"},"price":"40"}';
    public static string TEST_DEVICE_PACKAGE_INFO = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"HD","discount":{"type":"Percent","value":"0"},"price":"40"}';

    public TestDataGenerator() {}

    public static Contact createContact(String contactFirstName, String contactLastName, Account acc) {
        Contact testContact = new Contact(
            FirstName = contactFirstName,
            LastName = contactLastName,
            AccountId = acc.Id
        );

        insert testContact;

        return testContact;
    }

    public static AccountContactRole createAccountContactRole(Account acc, Contact con, String role, Boolean isPrimary) {
        AccountContactRole acr = new AccountContactRole(
            AccountId = acc.Id,
            ContactId = con.Id,
            Role = role != null ? role : 'Accounts Payable',
            IsPrimary = isPrimary != null ? isPrimary : false
        );

        insert acr;

        return acr;
    }

    public static Account createAccount(String accName) {
        return createAccount(accName, QuoteHelper.NGBS_OFFICE_PRODUCT);
    }
    public static Account createAccount(String accName, String serviceName) {
        Account testAcc = new Account(
            Name = (accName != null) ? accName : 'Test Account',
            Service_Type__c = (serviceName != null) ? serviceName : QuoteHelper.NGBS_OFFICE_PRODUCT
        );

        testAcc.CombinedMVPCurrentTotalMRR__c = 0;
        testAcc.CombinedMVPAcquisitionMRR__c = 0;
        testAcc.CombinedCCAcquisitionMRR__c = 0;
        testAcc.CombinedEngageDigitalMRR__c = 0;
        testAcc.CombinedEDAcquisitionMRR__c = 0;
        testAcc.CombinedEngageVoiceMRR__c = 0;
        testAcc.CombinedEVAcquisitionMRR__c = 0;

        insert testAcc;
        return testAcc;
    }

    public static Opportunity createOpportunity(Account testAcc) {
        return createOpportunity(testAcc, null);
    }

    public static Opportunity createOpportunity(Account testAcc, String serviceName) {
        if(testAcc == null) {
            testAcc = createAccount(null);
        }
        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'Test Opportunity',
            Type = 'New Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = String.isBlank(serviceName) ? 'Professional' : serviceName,
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert testOpp;
        return testOpp;
    }

    public static Pricebook2 createPricebook2() {
        return createPricebook2('Office');
    }

    public static Pricebook2 createPricebook2(String service) {
        Pricebook2 testPriceBook = new Pricebook2(
            Name = service + ' Price Book',
            Description = service + 'Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 1,
            Line_Range_Max__c = 50,
            CurrencyIsoCode = 'USD',
            Service__c = service,
            Plan__c = 'Annual'
        );

        insert testPriceBook;
        return testPriceBook;
    }

    public static Product2 createProduct2() {
        return createProduct2(null);
    }
    public static Product2 createProduct2(String elementId) {
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );

        if (elementId != null) {
            testProduct.ExtID__c = elementId;
        }

        insert testProduct;
        return testProduct;
    }

    public static PricebookEntry createPricebookEntry() {
        return createPricebookEntry(null, null);
    }

    public static PricebookEntry createPricebookEntry(Product2 product, PriceBook2 pb2) {
        PricebookEntry testPBE = new PricebookEntry(
                UnitPrice = 10,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        if(pb2 == null) {
            testPBE.Pricebook2Id = Test.getStandardPricebookId();
        } else {
            testPBE.Pricebook2Id = pb2.Id;
        }

        if(product == null) {
            testPBE.Product2Id = createProduct2().Id;
        } else {
            testPBE.Product2Id = product.Id;
        }

        insert testPBE;

        return testPBE;
    }

    public static Quote createMasterQuote(Opportunity testOpp) {
        return createMasterQuote(testOpp, null);
    }

    public static Quote createMasterQuote(Opportunity testOpp, PriceBook2 pb2) {
        return createQuote(testOpp, pb2, null, true);
    }

    public static Quote createQuote(Opportunity testOpp) {
        return createQuote(testOpp, null);
    }

    public static Quote createQuote(Opportunity testOpp, PriceBook2 pb2) {
        return createQuote(testOpp, pb2, null, false);
    }

    public static Quote createQuote(Opportunity testOpp, PriceBook2 pb2, String upsellStatus, Boolean isMultiProduct) {

        Quote testQuote = new Quote (
            Name = 'Quote For Tests',
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Approved_Status__c = 'Approved',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Term_months__c = '36',
            Initial_Term_months__c = '36'
        );

        if (isMultiProduct) {
            testQuote.Package_Info__c = NGBSTestDataGenerator.generateMultiProductQuotePackageInfo();
        } else {
            testQuote.Package_Info__c = NGBSTestDataGenerator.generateQuotePackageInfo();
        }

        if (String.isNotBlank(upsellStatus)) {
            testQuote.Upsell_Status__c = upsellStatus;
        }

        if(pb2 == null) {
            testQuote.Pricebook2Id = Test.getStandardPricebookId();
        } else {
            testQuote.Pricebook2 = pb2;
        }

        insert testQuote;

        return testQuote;
    }

    public static Quote createActiveAgreement(Opportunity testOpp) {
        return createActiveAgreement(testOpp, null);
    }

    public static Quote createActiveAgreement(Opportunity testOpp, PriceBook2 pb2) {

        Quote testQuote = new Quote (
            Name = 'Quote For Tests',
            OpportunityId = testOpp.Id,
            Status = 'Active',
            Approved_Status__c = 'Approved',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT
        );

        if(pb2 == null) {
            testQuote.Pricebook2Id = Test.getStandardPricebookId();
        } else {
            testQuote.Pricebook2 = pb2;
        }

        insert testQuote;

        return testQuote;
    }

    public static Id getQuoteRecordTypeIdByName(String devName) {
        return [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName =: devName].Id;
    }

    /* QuoteLineItem */
    public static QuoteLineItem createQuoteLineItem(Quote qt) {
        return createQuoteLineItem(qt, null);
    }
    public static QuoteLineItem createQuoteLineItem(Quote qt, Product2 product) {

        PricebookEntry pbe = createPricebookEntry();

        QuoteLineItem testQuoteLineItem = new QuoteLineItem (
            QuoteId = qt.Id,
            Quantity = 1,
            UnitPrice = pbe.UnitPrice,
            PricebookEntryId = pbe.Id,
            PackageInfo__c = TEST_PACKAGE_INFO,
            Package_Info_QLI__c = TEST_PACKAGE_INFO
        );

        if(product != null) {
            testQuoteLineItem.Product2Id = product.Id;
        } else {
            testQuoteLineItem.Product2Id = createProduct2().Id;
        }
        insert testQuoteLineItem;

        return testQuoteLineItem;
    }

    public static BillingWrappers.BillingProduct createBillingProduct(String name, String catalogId, String categoryCode) {
        BillingWrappers.BillingProduct product = new BillingWrappers.BillingProduct();
        product.name = name;
        product.catalogId = catalogId;
        product.currencyIsoCode = 'USD';
        product.goa = '';
        product.categoryCode = categoryCode;
        product.itemType = 'Product';

        return product;
    }

    public static BillingWrappers.CartItem createCartItemBilling(String name, String catalogId, Boolean isDeleted,String packageInfo) {
        BillingWrappers.CartItem cartItem = new BillingWrappers.CartItem();

        cartItem.id = null;
        cartItem.catalogId = catalogId; // 'LC_SC_1';
        cartItem.name = name; // 'Subscription';
        cartItem.quantity = 1;
        cartItem.unitPrice = 7.98;
        cartItem.billingCycleDuration = 'Monthly';
        cartItem.discount = 1;
        cartItem.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        cartItem.currencyIsoCode = 'USD';
        cartItem.packageInfo = packageInfo != null ? packageInfo : TEST_PACKAGE_INFO;
        cartItem.isDeleted = isDeleted;

        cartItem.billingPackage = new BillingWrappers.PackageInfo();
        cartItem.billingPackage.catalogId = '5';
        cartItem.billingPackage.version = '1';

        return cartItem;
    }

    public static String getPackageInfoStr(String id, String version, String duration) {
        String result = '[{"version":"' + version + '","trial":null,"productName":"Meetings","productId":null,"poc":null,"permissions":"Submit;","partnerPackage":null,"packageInfo":null,"packageBusinessIdentities":null,"offerType":"Regular","id":"'
                + id + '","globalPackageLimits":null,"existingPackageInfo":null,"edition":null,"duration":"' + duration + '","contract":null}]';
        return result;
    }

    public static String getPackageInfoStrWithPreferredLanguage(String id, String version, String duration) {
        String result = '[{"version":"' + version + '","trial":null,"productName":"Meetings","productId":null,"preferredLanguage":null,"poc":null,"permissions":"Submit;","partnerPackage":null,"packageInfo":null,"packageBusinessIdentities":null,"offerType":"Regular","id":"'
                + id + '","globalPackageLimits":null,"existingPackageInfo":null,"edition":null,"duration":"' + duration + '","contract":null}]';
        return result;
    }

    public static Cost_Center__c createCostCenter(String name, Quote quote) {
        Cost_Center__c costCenter = new Cost_Center__c(Name = name, Quote__c = quote.Id);
        insert costCenter;
        return costCenter;
    }

    public static Cost_Center_Line_Item__c createCostCenterLineItem(Cost_Center__c costCenter, QuoteLineItem qli) {
        Cost_Center_Line_Item__c costCenterLineItem = new Cost_Center_Line_Item__c(
            Cost_Center__c = costCenter.Id,
            Quote_Line_Item__c = qli.Id,
            Quantity__c = qli.Quantity
        );

        insert costCenterLineItem;
        return costCenterLineItem;
    }

    public static BillingWrappers.BillingCode createBillingCode() {
        return createBillingCode(null);
    }

    public static BillingWrappers.BillingCode createBillingCode(BillingWrappers.BillingCode parent) {
        BillingWrappers.BillingCode billingCode = new BillingWrappers.BillingCode();
        billingCode.guid = String.valueOf(System.currentTimeMillis());
        billingCode.parentBillingId = parent == null ? null : billingCode.parentBillingId;
        billingCode.name = 'test Billing Code ' + billingCode.guid;
        billingCode.depth = parent == null ? 0 : parent.depth + 1;
        billingCode.location = createTaxLocation();
        billingCode.bundles = new List<BillingWrappers.Bundle>();
        return billingCode;
    }

    public static BillingWrappers.TaxLocation createTaxLocation () {
        BillingWrappers.TaxLocation tl = new BillingWrappers.TaxLocation();
        tl.label = 'testLabel';
        tl.city = 'testCity';
        tl.country = 'testCountry';
        tl.zip = '12345';
        tl.firstName = 'testTaxLocation';
        tl.state = 'testState';
        tl.street1 = 'testStreet';

        return tl;
    }

    public static User createUser() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => 'testuser1@testtest.com',
                    User.LastName => 'Test Lastname',
                    User.Email => 'test@test.com',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.Alias => 'talias'
                }
            )
            .create()
            .getRecord();
        return testUser;
    }

    public static Package__c createBillingAccountPackage(Account account) {
        return createBillingAccountPackage(account, account);
    }

    public static Package__c createBillingAccountPackage(Account account, Account masterAccount) {
        Package__c billingAccountPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Enterprise_Account_ID__c => account.Id,
                Package__c.Account__c => masterAccount.Id,
                Package__c.Name => ValueProviderBuilder.provideUniqueString(Account.Id),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideUniqueString(Account.Id),
                Package__c.Service_Type__c => account.Service_Type__c,
                Package__c.Reported_MRS__c => 0
            })
            .create()
            .getRecord();

        return billingAccountPackage;
    }

    public class MultiproductStructure {
        public Account masterAccount;
        public Opportunity masterOpp;
        public Quote masterQuote;
        public List<QuoteLineItem> masterQLIs;

        public Map<String, BillingWrappers.CartItem[]> serviceNameToCartItems;

        public Map<String, Account> serviceAccounts;
        public Map<String, Opportunity> serviceOpportunities;
        public Map<String, Quote> serviceQuotes;
        public Map<String, List<QuoteLineItem>> technicalQLIs;

        public MultiproductStructure() {
            this.masterAccount = TestDataGenerator.createAccount('Master');
            this.masterOpp = TestDataGenerator.createOpportunity(masterAccount, QuoteHelper.NGBS_OFFICE_PRODUCT);
            this.masterQuote = TestDataGenerator.createQuote(masterOpp);
            this.masterQLIs = new List<QuoteLineItem>();

            Product2 pOffice1 = TestDataGenerator.createProduct2('OFFICE1');
            Product2 pOffice2 = TestDataGenerator.createProduct2('LC_DL-UNL_50');
            Product2 pCC1 = TestDataGenerator.createProduct2('CC1');


            Pricebook2 pbOffice = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_OFFICE_PRODUCT);
            Pricebook2 pbCC = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_RCCC_PRODUCT);
            Pricebook2 pbEV = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
            Pricebook2 pbED = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
            Pricebook2 pbFax = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_FAX_PRODUCT);

            PricebookEntry spbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, null);
            PricebookEntry spbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, null);
            PricebookEntry spbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, null);

            PricebookEntry pbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, pbOffice);
            PricebookEntry pbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, pbOffice);
            PricebookEntry pbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, pbCC);

            QuoteLineItem qliOffice1 = (QuoteLineItem) new SObjectFactory()
                .create(
                    QuoteLineItem.SObjectType,
                    new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => pOffice1.Id,
                        QuoteLineItem.QuoteId => masterQuote.Id,
                        QuoteLineItem.PricebookEntryId => spbeOffice1.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.UnitPrice => 100
                    }
                );
            QuoteLineItem qliOffice2 = (QuoteLineItem) new SObjectFactory()
                .create(
                    QuoteLineItem.SObjectType,
                    new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => pOffice2.Id,
                        QuoteLineItem.QuoteId => masterQuote.Id,
                        QuoteLineItem.PricebookEntryId => spbeOffice2.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.UnitPrice => 100
                    }
                );
            QuoteLineItem qliCC1 = (QuoteLineItem) new SObjectFactory()
                .create(
                    QuoteLineItem.SObjectType,
                    new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => pCC1.Id,
                        QuoteLineItem.QuoteId => masterQuote.Id,
                        QuoteLineItem.PricebookEntryId => spbeCC1.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.UnitPrice => 100
                    }
                );

            this.masterQLIs.addAll(
                new List<QuoteLineItem>{
                    qliOffice1,
                    qliOffice2,
                    qliCC1
                }
            );

            BillingWrappers.Params params = new BillingWrappers.Params();
            BillingWrappers.CartItem office1 = TestDataGenerator.createCartItemBilling(
                'Office 1',
                'OFFICE1',
                false,
                null
            );

            BillingWrappers.CartItem office2 = TestDataGenerator.createCartItemBilling(
                'Office 2',
                'LC_DL-UNL_50',
                false,
                null
            );
            BillingWrappers.CartItem rcc1 = TestDataGenerator.createCartItemBilling(
                'CC 1',
                'CC1',
                false,
                null
            );

            this.serviceNameToCartItems = new Map<String, BillingWrappers.CartItem[]> {
                QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>{
                    office1, office2
                },
                QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>{
                    rcc1
                },
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>(),
                QuoteHelper.NGBS_FAX_PRODUCT => new List<BillingWrappers.CartItem>()
            };


            BillingWrappers.QuoteWrapper officeQuoteInfo = new BillingWrappers.QuoteWrapper();
            BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
            BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
            BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();

            Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
                QuoteHelper.NGBS_OFFICE_PRODUCT => officeQuoteInfo,
                QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteInfo
            };

            List<String> serviceNames = new List<String>(serviceNameToCartItems.keySet());

            this.serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
            this.serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);
            this.serviceQuotes = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);
            this.technicalQLIs = QuoteLineItemHelper.upsertTechnicalQuoteLineItems(masterQuote, serviceNameToCartItems, serviceQuotes);
        }
    }

    public static SObject putChildRecordsIntoParent(SObject parentObj, String childRelationshipName, List<SObject> childRecords) {
        Map<String, Object> queryResultMap = new Map<String, Object> {
            'totalSize' => childRecords.size(),
            'done' => true,
            'records' => childRecords
        };

        Map<String, Object> parentMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(parentObj));
        parentMap.put(childRelationshipName, queryResultMap);

        String sObjectTypeName = parentObj.getSObjectType().getDescribe().getName();
        Type sObjectType = Type.forName('Schema.' + sObjectTypeName);

        return (SObject) JSON.deserialize(JSON.serialize(parentMap), sObjectType);
    }

    public static SObject linkParentToChild(SObject childRecord, SObject parentRecord, String childRelationshipName) {
        Map<String, Object> parentMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(parentRecord));

        Map<String, Object> relationshipMap = new Map<String, Object> {
            'attributes' => new Map<String, Object> {
                'type' => parentRecord.getSObjectType().getDescribe().getName(),
                'url' => '/' + parentRecord.Id
            }
        };
        relationshipMap.putAll(parentMap);

        Map<String, Object> childMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(childRecord));
        childMap.put(childRelationshipName, relationshipMap);

        String childTypeName = childRecord.getSObjectType().getDescribe().getName();
        Type childType = Type.forName('Schema.' + childTypeName);

        return (SObject) JSON.deserialize(JSON.serialize(childMap), childType);
    }
}