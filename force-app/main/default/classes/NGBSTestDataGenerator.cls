@isTest
public class NGBSTestDataGenerator {

    public NGBSTestDataGenerator() {}

    public static String generateQuotePackageInfo() {
        // BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        // return JSON.serialize(pInfo);
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Office"},"productName":"Office","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }
    public static String generateQuotePackageInfoEvent() {
        // BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        // return JSON.serialize(pInfo);
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Office"},"productName":"Events","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }
    public static String generateQuotePackageInfoEB() {
        return '[{"id":"5","version":"3",'
            + '"packageInfo":{"catalogId":"5","version":"3","name":"Office","id":"12345"},'
            + '"productName":"Office","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular",'
            + '"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],'
            + '"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }

    public static String generateQuotePackageInfoNoBI() {
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Office"},"productName":"Office","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null}]';
    }

    public static String generateQuotePackageInfoEngage() {
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Engage Digital Standalone"},"productName":"Engage Digital Standalone","productId":"7","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }

    public static String generateQuotePackageInfoRCCC() {
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"RingCentral Contact Center"},"productName":"RingCentral Contact Center","productId":"22","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }

    public static String generateQuotePackageInfoProServ() {
        return '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Professional Services","id":"12345"},"productName":"Professional Services","productId":"22","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    }

    public static String generateMultiProductQuotePackageInfo() {
        return '[' +
                '{"id":"1950","version":"1","packageInfo":{"catalogId":"1950","version":"1","name":"RingCentral MVP","displayName":"RingCentral MVP"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":3,"name":"Essentials"},"contract":{"id":"a8f8K0000008OfsQAE","extId":"Office","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false,"value":"1000"}],"permissions":null,"existingPackageInfo":{},"partnerPackage":null,"packageBusinessIdentities":{"defaultBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true},"selectedBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true},"approvedBi":{"id":4,"name":"RingCentral Inc.","address":{"label":null,"firstName":"RingCentral, Inc.","lastName":"","phone":"","email":null,"street1":"20 Davis Dr","street2":"","city":"Belmont","county":"","state":"CA","zip":"94002","country":"USA"},"isDefault":true}}},' +
                '{"id":"692","version":"1","packageInfo":{"catalogId":"692","version":"1","name":"Engage Voice Standalone","displayName":"Engage Voice Standalone"},"productName":"Engage Voice Standalone","productId":"9","duration":"Monthly","edition":{"id":11,"name":"IVR"},"contract":{"id":"a8f8K0000008OgUQAU","extId":"EV_Standalone","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","override":false,"value":"6000"}],"permissions":null,"existingPackageInfo":{},"partnerPackage":null},' +
                '{"id":"801","version":"1","packageInfo":{"catalogId":"801","version":"1","name":"RingCentral Contact Center","displayName":"RingCentral Contact Center"},"productName":"RingCentral Contact Center","productId":"22","duration":"Monthly","edition":{"id":19,"name":"Essentials Edition (3 ports)"},"contract":{"id":"a8f8K0000008OglQAE","extId":"RCCC","billingId":null},"offerType":"Regular","poc":null,"permissions":null,"existingPackageInfo":{},"partnerPackage":null},' +
                '{"id":"581","version":"1","packageInfo":{"catalogId":"581","version":"1","name":"Engage Digital Standalone","displayName":"Engage Digital Standalone"},"productName":"Engage Digital Standalone","productId":"7","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8f8K0000008OgZQAU","extId":"ED_Standalone","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","override":false,"value":"6000"}],"permissions":null,"existingPackageInfo":{},"partnerPackage":null}]';
    }

    public static String generateQuotePackageInfo(Map<String, Object> data) {
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();

        String id = data.containsKey('Id') ? (String) data.get('Id') : '1';
        String version = data.containsKey('Version') ? (String) data.get('Version') : '1';

        pInfo.id = id;
        pInfo.version = version;

        pInfo.PackageInfo = new BillingWrappers.PackageInfo();
        pInfo.PackageInfo.id = data.containsKey('PackageInfoId') ? (String) data.get('PackageInfoId') : null;
        pInfo.PackageInfo.catalogId = id;
        pInfo.PackageInfo.version = version;
        pInfo.PackageInfo.name = data.containsKey('PackageName') ? (String) data.get('PackageName') : 'Test Package';
        pInfo.PackageInfo.displayName = data.containsKey('PackageDisplayName') ? (String) data.get('PackageDisplayName') : 'Test Package';

        pInfo.productName = data.containsKey('ProductName') ? (String) data.get('ProductName') : 'Office';
        pInfo.duration = data.containsKey('Duration') ? (String) data.get('Duration') : 'Monthly';
        pInfo.offerType = data.containsKey('OfferType') ? (String) data.get('OfferType') : 'Regular';
        pInfo.productId = data.containsKey('productId') ? (String) data.get('productId') : '15';
        pInfo.partnerPackage = data.containsKey('partnerPackage') ? (BillingWrappers.PartnerPackageInfo) data.get('partnerPackage') : null;
        pInfo.edition = new BillingWrappers.Edition();
        pInfo.edition.id = id;
        pInfo.edition.name = data.containsKey('EditionName') ? (String) data.get('EditionName') : null;
        pInfo.contract = new BillingWrappers.Contract();
        pInfo.contract.id = data.containsKey('ContractId') ? (String) data.get('ContractId') : null;
        pInfo.contract.extId = data.containsKey('ContractExtId') ? (String) data.get('ContractExtId') : null;
        pInfo.contract.billingId = data.containsKey('ContractBillingId') ? (String) data.get('ContractBillingId') : null;
        pInfo.contract.status = data.containsKey('ContractStatus') ? (String) data.get('ContractStatus') : null;

        return JSON.serialize(new BillingWrappers.QuotePackageInfo[]{pInfo});
    }

    public static String generateQLIPackageInfo() {
        return '{"id":"7","version":"1","duration":"Monthly","categoryCode":"SP", "lboxes": [{"min": 0,"max": 0,"elementID": "1"},{"min": 0,"max": 0,"elementID": "2"}], "categoryPath":"HD"}';
    }

    public static String generateQLIPackageInfo(Map<String, Object> data) {
        BillingWrappers.QLIPackageInfo result = new BillingWrappers.QLIPackageInfo();
        result.Id = (String) data.get('Id');
        result.Version = '1';
        result.Duration = (String) data.get('Duration');
        result.CategoryCode = (String) data.get('CategoryCode');
        result.CategoryPath = (String) data.get('CategoryPath');
        result.Discount = new BillingWrappers.QLIPackageInfoDiscount();

        if (data.containsKey('q')) {
            result.q = (Integer) data.get('q');
        }

        return JSON.serialize(result);
    }

    public static Quote createQuote(Id oppId) {
        return createQuote(oppId, null);
    }
    public static Quote createQuote(Id oppId, String upsellStatus) {
        String upsellStatusToSet = String.isBlank(upsellStatus) ? QuoteHelper.STATUS_NEW_CUSTOMER : upsellStatus;
        return (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test quote',
                Quote.OpportunityId => oppId,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Upsell_Status__c => upsellStatusToSet,
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                Quote.Payment_Plan__c => 'Monthly'
            })
            .create()
            .getRecord();
    }

    public static QuoteLineItem createQLI(String name, String extId, String currencyValue, Account acc, Quote qt) {
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => name,
                Product2.ExtID__c => extId,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => currencyValue
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.PackageCatalogId__c => '7',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount_number__c => 1,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                // TODO get rid of
                QuoteLineItem.Package_Info__c => generateQLIPackageInfo(),
                QuoteLineItem.Package_Info_QLI__c => generateQLIPackageInfo(),
                QuoteLineItem.PackageInfo__c => generateQLIPackageInfo(),
                QuoteLineItem.PackageCatalogId__c => '7',
                QuoteLineItem.PackageVersion__c => '1'
            })
            .create()
            .getRecord();

        return qli;
    }

    public static BillingWrappers.NGBSAccount generateNGBSAccount() {
        BillingWrappers.NGBSAccount ngbsAcc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage>{
            ngbsPkg
        };
        return ngbsAcc;
    }

    public static BillingWrappers.Bundle createBundle(String elementId, Integer quantity, BillingWrappers.AreaCodeData areaCode) {
        BillingWrappers.Bundle bundle = new BillingWrappers.Bundle();
        bundle.elementID = elementId;
        bundle.qty = quantity;
        bundle.areaCode = areaCode;
        bundle.licenses = new List<BillingWrappers.BundleItem>();

        return bundle;
    }

    public static BillingWrappers.BundleItem createBundleItem(String elementId, BillingWrappers.AreaCodeData areaCode) {
        BillingWrappers.BundleItem bundleItem = new BillingWrappers.BundleItem();
        bundleItem.elementID = elementId;
        bundleItem.areaCode = areaCode;

        return bundleItem;
    }

    public static BillingWrappers.TaxLocationsResponse generateTestTaxLocationResponse(String addressId) {
        BillingWrappers.Address testAddress = new BillingWrappers.Address();
        testAddress.id = addressId;

        BillingWrappers.TaxLocation testTaxLocation = new BillingWrappers.TaxLocation();
        testTaxLocation.label = 'taxLocationName';
        testTaxLocation.country = 'United States';
        testAddress.address = testTaxLocation;

        BillingWrappers.TaxLocationsResponse taxLocationResp = new BillingWrappers.TaxLocationsResponse();
        taxLocationResp.addresses = new List<BillingWrappers.Address>{ testAddress };

        return taxLocationResp;
    }

    private static Cost_Center_Line_Item__c buildBundleRoot(Id costCenterId, Id rootQliId, Integer bundleQty) {
        Cost_Center_Line_Item__c bundleRoot =
            (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Cost_Center__c => costCenterId,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => rootQliId,
                Cost_Center_Line_Item__c.Quantity__c => bundleQty
            })
            .create()
            .getRecord();

        return bundleRoot;
    }

    private static List<Cost_Center_Line_Item__c> buildChildCclis(Id costCenterId, Id rootQliId, Set<Id> childQliIds) {
        List<Cost_Center_Line_Item__c> bundleChilds =
            (List<Cost_Center_Line_Item__c>) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Cost_Center__c => costCenterId,
                Cost_Center_Line_Item__c.Parent__c => rootQliId,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideParents(childQliIds)
            })
            .quantity(childQliIds.size())
            .create()
            .getRecords();

        return bundleChilds;
    }

    public static Map<Id, Cost_Center_Line_Item__c> buildBundle(
        Id costCenterId,
        Id rootQliId,
        Set<Id> childQliIds,
        Integer bundleQty
    ) {
        Cost_Center_Line_Item__c rootCcli = buildBundleRoot(costCenterId, rootQliId, bundleQty);
        List<Cost_Center_Line_Item__c> childsCclis = buildChildCclis(costCenterId, rootCcli.Id, childQliIds);

        Map<Id, Cost_Center_Line_Item__c> qliIdToCcliMap = new Map<Id, Cost_Center_Line_Item__c>{
            rootCcli.Quote_Line_Item__c => rootCcli
        };
        for (Cost_Center_Line_Item__c child : childsCclis) {
            qliIdToCcliMap.put(child.Quote_Line_Item__c, child);
        }

        return qliIdToCcliMap;
    }
}