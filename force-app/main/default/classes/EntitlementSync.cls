global without sharing class EntitlementSync implements HttpCalloutMock {

    public static final String ENTITLEMENT_RESPONSE_DATA_KEY = 'entitlementsFromDWHSync';

    private static final integer NAME_FIELD_LENGTH = 80;
    private static final Integer HTTP_REQUEST_TIMEOUT = 120000;

    private static Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>();
    private static Map<Id, Entitlement__c> entlToOrderItemMap = new Map<Id, Entitlement__c>();
    private static Map<Id, ProductDetail__c> productDetailsToInsert = new Map<Id, ProductDetail__c>();
    private static Map<Id, ProductDetail__c> productDetailsToUpdate = new Map<Id, ProductDetail__c>();
    private static List<ProductDetail__c> entitlementProductDetails = new List<ProductDetail__c>();
    private static List<ProductDetail__c> changeDiscountProductDetails = new List<ProductDetail__c>();
    private static Map<Id, ProductDetail__c> entitlementIdToPrDet = new Map<Id, ProductDetail__c>(); // Id Entitlement And Product Detail
    private static List<Entitlement__c> entlsToDeactivate = new List<Entitlement__c>();
    private static List<ProductDetail__c> deactivateEntlProductDetails = new List<ProductDetail__c>();

    public static String mockDWHJsonResponce = '{"rcUserID":129389020,"brandId":1210,"serviceId":1,"editionId":6,"tierId":4422,' +
    '"currency":"USD","currencyId":1,"accountStatus":"Test","accountStatusId":13,"rcProducts"' +
    ':[{"countryName":"FRANCE","countryId":75,"featureId":28,"subFeatureId":1,"fullPhoneName"' +
    ':"Test Phone","numberOfMinutes":1000,"feeType":null,"productName":"Test bundle","productId"' +
    ':2071916,"chargeTerm":"Monthly","quantity":1,"itemListPrice":14.99,"itemDiscountPrice":' +
    '119.96},{"countryName":"FRANCE","countryId":75,"featureId":28,"subFeatureId":1,' +
    '"fullPhoneName":"Test Phone","numberOfMinutes":1000,"feeType":"Fee","productName":' +
    '"Test bundle","productId":2071916,"chargeTerm":"Monthly","quantity":1,"itemListPrice":' +
    '14.99,"itemDiscountPrice":119.96},{"countryName":"FRANCE","countryId":75,"featureId":52,' +
    '"subFeatureId":1,"fullPhoneName":"Test Phone","numberOfMinutes":1000,"feeType":null,' +
    '"productName":"Test bundle","productId":2071916,"chargeTerm":"Monthly","quantity":1,' +
    '"itemListPrice":14.99,"itemDiscountPrice":119.96}],"nonRcProducts":[{"productName":' +
    '"Monthly - 119.96 - RC Office 4","productId":2071916,"chargeTerm":"Monthly","quantity":1,' +
    '"itemListPrice":14.99,"itemDiscountPrice":119.96}]}';

    private static final Set<Decimal> BUNDLE_FEATURES = new Set<Decimal>{52,56};
    private static final Set<Decimal> FAKE_BUNDLE_FEATURES = new Set<Decimal>{59,52,56};
    private static final Set<Decimal> SUPPORT_FEATURES = new Set<Decimal>{
        33,
        Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
        Product2Helper.FEATURE_CC_EXTENDED_ENTERPRISE_SUPPORT
    };

    private static final Set<Decimal> PHONE_FEATURES = new Set<Decimal>{
        34,
        35
    };

    private static final Set<Decimal> GLOBAL_OFFICE_FEATURES = new Set<Decimal>{41,42,47};

    private static final Set<Decimal> OTHER_FEATURES = new Set<Decimal>{
        1,2,3,7,10,12,20,35,
        48,49,51,57,60,65,
        Product2Helper.FEATURE_DIGITAL_LINE_HOT_DESKING
    };

    private static final Set<Decimal> COUNTRY_INDEPENDENT_FEATURES = new Set<Decimal>{48};

    /* features which match by pbe
      33 - Specific for premium support (search `psPriceToName` or `psIntPriceToName`) */
    private static final Set<Decimal> PBE_MATCH_FEATURES = new Set<Decimal>{
      24, 33, 36, 41, 42, 47, 49, 51, 59, 64
    };
    /* features which match by productName && featureId */
    private static final Set<Decimal> PBE_MATCH_FEATURES_OTHER = new Set<Decimal>{
      24, 36, 49, 51, 59, 64
    };

    private static final Map<Decimal, String> CURRENCY_MAPPING = new Map<Decimal, String>{
        1=>'USD',
        2=>'GBP',
        3=>'EUR',
        5=>'CAD',
        6=>'AUD'
    };

    private static final Map<String, String> COUNTRY_MAPPING = new Map<String, String>{
        'VIRGIN ISLANDS (U.S.)' => 'VIRGIN ISLANDS, U.S.',
        'VIRGIN ISLANDS (BRITISH)' => 'VIRGIN ISLANDS, BRITISH',
        'US' => 'UNITED STATES',
        'UK' => 'UNITED KINGDOM',
        'TIMOR-LESTEﾠ(EAST TIMOR)' => 'TIMOR-LESTE',
        'RUSSIAN FEDERATION' => 'RUSSIA',
        'REUNION ISLAND' => 'REUNION',
        'PALESTINIAN TERRITORIES' => 'PALESTINIAN TERRITORY',
        'MICRONESIA, FEDERAL STATES' => 'MICRONESIA, FEDERATED STATES',
        'HONGKONG' => 'HONG KONG',
        'FALKLAND ISLANDS' => 'FALKLAND ISLANDS (MALVINAS)',
        'DEMOCRATIC REPUBLIC OF THE CONGO' => 'CONGO, DEMOCRATIC REPUBLIC'
    };

    public virtual class DWHResponse {
        public String rcUserID;
        public Decimal brandId;
        public Decimal serviceId;
        public Decimal editionId;
        public Decimal tierId;
        public String pcurrency;
        public Decimal currencyId;
        public String accountStatus;
        public Decimal accountStatusId;
        public List<DWHProduct> rcProducts;

        public DWHResponse() {}

        public DWHResponse(DWHResponseSingleProduct source) {
            rcUserID=source.rcUserID;
            brandId=source.brandId;
            serviceId=source.serviceId;
            editionId=source.editionId;
            tierId=source.tierId;
            pcurrency=source.pcurrency;
            currencyId=source.currencyId;
            accountStatus=source.accountStatus;
            accountStatusId=source.accountStatusId;
            rcProducts=new List<DWHProduct>();
            if (source.rcProducts != null) {
                rcProducts = new List<DWHProduct>{source.rcProducts};
            }
        }

        protected void setChargeTermForTrialAccount() {
            if(this.rcProducts == null || this.rcProducts.isEmpty()) {
                return;
            }
            if(!String.isBlank(this.accountStatus) && this.accountStatus.containsIgnoreCase('Trial')) {
                for(DWHProduct dwhProduct : this.rcProducts) {
                    if(dwhProduct.featureId == Product2Helper.FEATURE_SERVICE_PLAN_FAX && String.isBlank(dwhProduct.chargeTerm)) {
                        dwhProduct.switchChargeTerm(Product2Helper.CHARGE_TERM_MONTHLY);
                    }
                }
            }
        }
    }

    public class DWHResponseSingleProduct extends DWHResponse {
        public DWHProduct rcProducts;
    }

    public class DWHProduct {
        public String countryName;
        public Decimal countryId;
        public Decimal featureId;
        public Decimal subFeatureId;
        public String fullPhoneName;
        public Decimal numberOfMinutes;
        public String feeType;
        public String productName;
        public Decimal productId;
        public String chargeTerm;
        public Decimal quantity;
        public Decimal itemListPrice;
        public Decimal itemDiscountPrice;
        public Decimal digitalLineFeatureId;

        //TO DO: convert to map
        public Decimal annualQty;
        public Decimal annualTotalPrice;
        public Decimal annualTotalDiscountPrice;
        public Decimal monthlyQty;
        public Decimal monthlyTotalPrice;
        public Decimal monthlyTotalDiscountPrice;

        public void switchChargeTerm(String newChargeTerm) {
            this.chargeTerm = newChargeTerm;
        }
    }

    public class EntitlementsParams {
        public String pricebook2Id;
        public String quoteId;
        public Decimal additionalLines;
        public List<Entitlement__c> entitlements;
        public List<PricebookEntry> pricebookEntries;
        public String quoteUpsellStatus;
    }

    public class DWHProducts {
        /* DWH always has subscrube (featureId = 28) */
        Decimal serviceFeatureId = 28;
        String serviceChargeTerm;
        Map<Decimal, String> featureIdToChargeTerm = new Map<Decimal, String>();
        Set<Decimal> features = new Set<Decimal>();
        Map<String, DWHProduct> productMap = new Map<String, DWHProduct>();
        String chargeTerm;

        public DWHProducts(DWHProduct[] products) {
          if(products != null) {
            parseFeatures(products);
            aggregate(products);
          }
        }

        /* Find Service Feature Id (by itemListPrice = 0) & create set of feature id */
        public void parseFeatures(DWHProduct[] products) {
            for (DWHProduct prod : products) {
                this.features.add(prod.featureId);
                if(prod.feeType == null) {
                    this.featureIdToChargeTerm.put(prod.featureId, prod.chargeTerm);
                }
                if (Product2Helper.FEATURE_SERVICES.contains(prod.featureId) && prod.itemListPrice == 0) {
                    this.serviceFeatureId = prod.featureId;
                    this.serviceChargeTerm = prod.chargeTerm;
                }
            }
        }

        /* Agregate DWH Prods */
        public void aggregate(DWHProduct[] products) {
            for (DWHProduct prod : products) {
                String prodType;
                String feeType = (prod.feeType != null) ? prod.feeType.toLowerCase() : prod.feeType;

                /* Service and fee */
                if (prod.featureId == serviceFeatureId) {
                    if(feeType == null) { prodType = 'Service'; }
                    else if (feeType == '911') { prodType = 'E911'; }
                    else if (feeType == 'crf') { prodType = 'CRF'; }
                }
                /* others */
                else {
                    String countryId = '';
                    if ( !COUNTRY_INDEPENDENT_FEATURES.contains(prod.featureId) ) {
                        countryId = prod.countryId == null ? countryId : String.valueof(prod.countryId);
                    }

                    String productId = String.valueOf(prod.productId);
                    prodType = productId + countryId;

                    if(prod.digitalLineFeatureId != null) {
                        prodType += prod.digitalLineFeatureId;
                    }

                    if (prod.featureId == 28) {
                        prod.quantity = 0;
                        prodType = 'Service';
                    }
                }

                /* dwh can send fee items with charge term different from service */
                if(feeType == '911' || feeType == 'crf') {
                    prod.chargeTerm = featureIdToChargeTerm.get(prod.featureId);
                }

                if(String.isNotEmpty(prodType)) {
                    this.productMap.put(prodType, this.aggregateProduct(this.productMap.get(prodType), prod));
                }

                //Special processing for service products with zero as price
                //Also we will take product with feature 28
                if (prodType == 'Service') {
                    if (prod.itemListPrice == 0 || prod.featureId == 28) {
                        DwhProduct simpleCopy = new DwhProduct();
                        simpleCopy.featureId = prod.featureId;
                        simpleCopy.itemListPrice = prod.itemListPrice;
                        simpleCopy.itemDiscountPrice = prod.itemDiscountPrice;
                        simpleCopy.quantity = prod.quantity;

                        this.productMap.put(Product2Helper.FAMILY_SERVICE_FREE_OF_CHARGE,
                            this.aggregateProduct(this.productMap.get(Product2Helper.FAMILY_SERVICE_FREE_OF_CHARGE), simpleCopy));
                    }
                }
            }
        }

        private DWHProduct aggregateProduct(DWHProduct productWithTotals, DWHProduct productToAdd) {
            if(productToAdd != null) {
                productToAdd.annualQty = 0;
                productToAdd.annualTotalPrice = 0;
                productToAdd.annualTotalDiscountPrice = 0;
                productToAdd.monthlyQty = 0;
                productToAdd.monthlyTotalPrice = 0;
                productToAdd.monthlyTotalDiscountPrice = 0;
                Decimal quantity = productToAdd.quantity == 0 ? 1 : productToAdd.quantity;
                if(productToAdd.chargeTerm == 'Annual') {
                    productToAdd.annualQty = productToAdd.quantity;
                    productToAdd.annualTotalPrice = productToAdd.itemListPrice * quantity;
                    productToAdd.annualTotalDiscountPrice = productToAdd.itemDiscountPrice * quantity;
                } else {
                    productToAdd.monthlyQty = productToAdd.quantity;
                    productToAdd.monthlyTotalPrice = productToAdd.itemListPrice * quantity;
                    productToAdd.monthlyTotalDiscountPrice = productToAdd.itemDiscountPrice * quantity;
                }
            }

            if(productWithTotals == null) {
                return productToAdd;
            } else {
                productWithTotals.annualQty += productToAdd.annualQty;
                productWithTotals.annualTotalPrice += productToAdd.annualTotalPrice;
                productWithTotals.annualTotalDiscountPrice += productToAdd.annualTotalDiscountPrice;
                productWithTotals.monthlyQty += productToAdd.monthlyQty;
                productWithTotals.monthlyTotalPrice += productToAdd.monthlyTotalPrice;
                productWithTotals.monthlyTotalDiscountPrice += productToAdd.monthlyTotalDiscountPrice;

                return productWithTotals;
            }
        }

        public void normalize(String chargeTerm) {
            this.chargeTerm = chargeTerm;
            for (DWHProduct prod : this.productMap.values()) {
                prod = this.normalizeProduct(prod, chargeTerm);
            }
        }

        /* Define ListPrice, DiscountPrice and ChargeTerm, Quantity */
        private DWHProduct normalizeProduct(DWHProduct prod, String masterChargeTerm) {

            prod.quantity = prod.annualQty + prod.monthlyQty;

            /* to Annual */
            prod.itemListPrice = (prod.annualTotalPrice + prod.monthlyTotalPrice * 12) / prod.quantity;
            prod.itemDiscountPrice = (prod.annualTotalDiscountPrice + prod.monthlyTotalDiscountPrice * 12) / prod.quantity;

            /* Define charge term */
            Boolean condition1 = (prod.monthlyQty == 0);

            Boolean condition2sub0  = (prod.monthlyQty != 0 && prod.annualQty != 0);
            Boolean condition2sub1  = (prod.feeType != null);
            Boolean condition2sub2  = (masterChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL);
            Boolean condition2      = condition2sub2 && (condition2sub0 || condition2sub1);

            Boolean condition3      = (condition1 || condition2);

            prod.chargeTerm = condition3 ? Product2Helper.CHARGE_TERM_ANNUAL : Product2Helper.CHARGE_TERM_MONTHLY;

            /* to Monthly */
            if(prod.chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY) {
                prod.itemListPrice = prod.itemListPrice / 12;
                prod.itemDiscountPrice = prod.itemDiscountPrice / 12;
            }

            return prod;
        }
    }

    @TestVisible
    class ProductsMatcher {

        String tierId;
        Decimal currencyId;
        Decimal serviceFeatureId;
        Decimal pbLineRangeMin;
        Set<Decimal> features;
        String chargeTerm;
        Set<Id> productIds = new Set<Id>();
        Product2[] productList;
        Map<String, PriceBookEntry[]> pbeMap;
        PriceBookEntry[] pbeList;
        Map<Id, Decimal> monthlyContractDiscounts = new Map<id,decimal>();
        Map<Decimal, String> psPriceToName = new Map<Decimal, String>();
        Map<Integer, String> psIntPriceToName = new Map<Integer, String>();

        DWHProduct[] dwhProductList;
        Map<String, DWHProduct> productMap;

        Map<DWHProduct, Product2> allMatched = new Map<DWHProduct, Product2>();
        /* charge-term independent products */
        Map<DWHProduct, Product2> otherMatchedProdMap = new Map<DWHProduct, Product2>();
        /* charge-term dependent */
        Map<String, Map<DWHProduct, Product2>> durationToMatchedProdMap = new Map<String, Map<DWHProduct, Product2>>();
        Map<Id, Entitlement__c> matchedEntlMap = new Map<Id, Entitlement__c>();


        public ProductsMatcher(DWHResponse dwhResponse, DWHProducts dwhProducts) {
            tierId              = String.valueOf(dwhResponse.tierId);
            currencyId          = dwhResponse.currencyId;

            serviceFeatureId    = dwhProducts.serviceFeatureId;
            features            = dwhProducts.features;
            productMap          = dwhProducts.productMap;
            chargeTerm          = dwhProducts.chargeTerm;
            dwhProductList      = productMap.values();

            /* getting products & pbes */
            pbeMap              = getPbe();
            productList         = getProducts();
            pbeList             = pbeMap.get(this.chargeTerm);

            if(pbeList == null) {
                pbeList = new List<PriceBookEntry>();
            }

            /*  Create
                    Product2Id to Monthly Contract Discount Map
                    UnitPrice to Product2Name
            */
            System.debug('\r\n');
            System.debug(' >>> tierId: ' + this.tierId);
            System.debug(' >>> chargeTerm: ' + this.chargeTerm);
            System.debug(' >>> pbeMap: ' + this.pbeMap);
            System.debug(' >>> pbeList: ' + this.pbeList);

            for(Pricebookentry pbe : this.pbeList) {
                monthlyContractDiscounts.put(pbe.Product2Id, pbe.Monthly_Contract_Discount__c);

                /* Specific for premium support */
                if(isPremiumSupport(pbe.Product2)) {
                    psPriceToName.put(pbe.UnitPrice, pbe.Product2.Name);
                    psIntPriceToName.put(pbe.UnitPrice.intValue(), pbe.Product2.Name);
                }
            }
        }

        private Product2[] getProducts() {
            return [ SELECT Id, Name, Family, Feature__c, Charge_Term__c, Number_of_Minutes__c,
                       Sub_Feature__c, Dependent_on_Feature__c, ExtID__c, Matcher_Formula__c
                    FROM Product2
                    WHERE (Feature__c IN :this.features OR Dependent_on_Feature__c IN :this.features)
                    AND Family != :Product2Helper.FAMILY_SERVICE
                    AND Charge_Term__c != :Product2Helper.CHARGE_TERM_ONE_TIME
                    AND Id IN : this.productIds
            ];
        }

        private Map<String, PriceBookEntry[]> getPbe() {

            Set<String> plans = Product2Helper.isMonthly(this.chargeTerm)
                ? Product2Helper.CHARGE_TERMS_SET_MONTHLY
                : new Set<String>{this.chargeTerm};

            List<Pricebook2> pbs = [
                    SELECT Id, Plan__c, Line_Range_Min__c,
                        (SELECT Id, Product2Id, Product2.Charge_Term__c, Product2.Name, Product2.Family,
                            Monthly_Contract_Discount__c, Product2.Id,Product2.Number_of_Minutes__c,
                            product2.Feature__c, UnitPrice, product2.Sub_Feature__c,
                            product2.Dependent_on_Feature__c, product2.ExtID__c, product2.Matcher_Formula__c
                        FROM Pricebookentries)
                    FROM Pricebook2
                    WHERE Tier_ID__c = :this.tierId
                        AND Plan__c IN :plans
            ];

            Map<String, PriceBookEntry[]> pbeMap = new Map<String, PriceBookEntry[]>();
            for(Pricebook2 pb : pbs) {
                List<PricebookEntry> pbes = new List<PricebookEntry>();

                for (PricebookEntry pbe : pb.PricebookEntries) {
                    productIds.add(pbe.Product2Id);
                    if (pbe.Product2.Family == Product2Helper.FAMILY_SERVICE
                        || (pbe.Product2.Family == Product2Helper.FAMILY_FEE && pbe.Product2.Dependent_on_Feature__c == this.serviceFeatureId)
                        || PBE_MATCH_FEATURES.contains(pbe.Product2.Feature__c)) {
                        pbes.add(pbe);
                    }
                }

                this.pbLineRangeMin = pb.Line_Range_Min__c;

                pbeMap.put(pb.Plan__c, pbes);
            }

            return pbeMap;
        }

        /*
        This method will switch charge term from Monthly-contract to Monthly
        in case if pricebook with Monthly-Contract will be not found
        */
        public ProductsMatcher fallbackToMonthly() {
            if (this.chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                if (this.pbeMap.containsKey(Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) == false) {
                    this.chargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
                }
            }
            return this;
        }

        //Sometimes DWH returns to us service product with quantity less than Pricebook2.Line_Range_Min__c
        //This causes incorrect list and net price calculation, so this method will handle this
        public ProductsMatcher alignServiceProductPrice() {
            DwhProduct serviceProduct = this.productMap.get(Product2Helper.FAMILY_SERVICE);
            DwhProduct serviceProductFreeOfCharge = this.productMap.get(Product2Helper.FAMILY_SERVICE_FREE_OF_CHARGE);

            if(serviceProductFreeOfCharge == null || serviceProduct == null) { return this; }

            Decimal serviceProductQuantityWithout28 = serviceProductFreeOfCharge.quantity - 1;
            if (serviceProductQuantityWithout28 < this.pbLineRangeMin) {
                Decimal restoredItemListPrice = serviceProductFreeOfCharge.quantity * serviceProductFreeOfCharge.itemListPrice;
                serviceProduct.itemListPrice = restoredItemListPrice / this.pbLineRangeMin;

                Decimal restoredItemDiscountPrice = serviceProductFreeOfCharge.quantity * serviceProductFreeOfCharge.itemDiscountPrice;
                serviceProduct.itemDiscountPrice = restoredItemDiscountPrice / this.pbLineRangeMin;

                this.productMap.remove(Product2Helper.FAMILY_SERVICE_FREE_OF_CHARGE);
            }

            return this;
        }

        // match by SF Product
        public ProductsMatcher matchBySFProduct(Entitlement__c[] entls) {

            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            Boolean isUseNameMapping = featureToggle != null && featureToggle.UseFeature70ForEES__c == false;

            Map<String, String> eeSupportNameMap = getEESupportNameMap(entls);
            Map<String, String> polycomNameMap = getPolycomNameMap();

            for (Product2 sfProduct : productList) {

                // DWHProduct matchedProd;
                for (DWHProduct dwhProduct : this.dwhProductList) {

                    Boolean c1 = (sfProduct.Feature__c != null              && dwhProduct.featureId == sfProduct.Feature__c              && dwhProduct.feeType == null);
                    Boolean c2 = (sfProduct.Dependent_on_Feature__c != null && dwhProduct.featureId == sfProduct.Dependent_on_Feature__c && dwhProduct.feeType != null);
                    Boolean isSameChargeTerm = (dwhProduct.chargeTerm == sfProduct.Charge_Term__c);

                    if (isSameChargeTerm && (c1 || c2)) {
                        if (BUNDLE_FEATURES.contains(dwhProduct.featureId)) {
                            Boolean c1i = (FAKE_BUNDLE_FEATURES.contains(dwhProduct.featureId) && dwhProduct.productName == sfProduct.Name);
                            if (c1i) {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                                break;
                            }
                        // Sometimes there are products that have same feature as service products.
                        // Because of that, they aren't matched properly.
                        // Here, it's OK to use Product2Helper.FEATURE_SERVICES set to identify them because productList doesn't
                        // contain products with family 'Service' (see query in getProducts() method)
                        } else if (
                            OTHER_FEATURES.contains(dwhProduct.featureId)
                            || Product2Helper.FEATURE_SERVICES.contains(dwhProduct.featureId)
                        ) {
                            if (dwhProduct.feeType == '911' && isE911(sfProduct)) {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                                break;
                            }
                            else if (dwhProduct.feeType == 'CRF' && isCRF(sfProduct)) {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                                break;
                            }
                            else if(dwhProduct.feeType != '911' && dwhProduct.feeType != 'CRF') {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                                break;
                            }
                        } else if (SUPPORT_FEATURES.contains(dwhProduct.featureId)) {
                            if( isExtendedEnterpriseSupport(dwhProduct)) {
                                if(isUseNameMapping && eeSupportNameMap.get(sfProduct.Name) == dwhProduct.productName) {
                                    otherMatchedProdMap.put(dwhProduct, sfProduct);
                                    break;
                                }else if(!isUseNameMapping) {
                                    otherMatchedProdMap.put(dwhProduct, sfProduct);
                                    break;
                                }
                            }else if(isCCExtendedEnterpriseSupport(dwhProduct)) {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                            }

                            if ( isPremiumSupport(dwhProduct) ) {
                                String name     = psPriceToName.get(dwhProduct.itemListPrice);
                                String nameInt  = psIntPriceToName.get(dwhProduct.itemListPrice.intValue());

                                if ( sfProduct.Name == name || sfProduct.Name == nameInt) {
                                    otherMatchedProdMap.put(dwhProduct, sfProduct);
                                    break;
                                }
                            }
                        } else if (PHONE_FEATURES.contains(dwhProduct.featureId) || dwhProduct.featureId == Product2Helper.FEATURE_DIGITAL_LINE_HOT_DESKING) {
                            if ( isRentalPhone(dwhProduct) ) {
                                String pFamily = 'nonexistent';
                                if (dwhProduct.digitalLineFeatureId == 17) {
                                    pFamily = 'Rental Phones';
                                } else if (dwhProduct.digitalLineFeatureId == 12) {
                                    pFamily = 'Limited Extension Rental Phones';
                                } else if (dwhProduct.digitalLineFeatureId == 47) {
                                    pFamily = 'Global Office Rental Phones';
                                } else if (dwhProduct.digitalLineFeatureId == 63) {
                                    pFamily = 'Global Office - Limited Extension Rental Phones';
                                }

                                for(String key : polycomNameMap.keySet()) {
                                    String name = dwhProduct.productName;
                                    if(name.contains(key)) {
                                        dwhProduct.productName = name.replace(key, polycomNameMap.get(key));
                                    }
                                }

                                if(pFamily == sfProduct.Family && dwhProduct.productName == sfProduct.Name) {
                                    otherMatchedProdMap.put(dwhProduct, sfProduct);
                                    break;
                                }
                            } else {
                                otherMatchedProdMap.put(dwhProduct, sfProduct);
                                break;
                            }
                        }
                    }
                }
            }

            return this;
        }

        // match by Pbe
        public ProductsMatcher matchBySFPbe() {

            for(String duration : pbeMap.keySet()) {

                if(durationToMatchedProdMap.get(duration) == null) {
                    durationToMatchedProdMap.put(duration, new Map<DWHProduct, Product2>());
                }
                Map<DWHProduct, Product2> matchedProdMap = durationToMatchedProdMap.get(duration);

                for(Pricebookentry pbe : pbeMap.get(duration)) {

                    // Match Service prods
                    if(pbe.Product2.Charge_Term__c.equalsIgnoreCase(duration)) {
                        if (pbe.Product2.Family == 'Service' && this.productMap.get('Service') != null) {
                            matchedProdMap.put(this.productMap.get('Service'), pbe.Product2);
                        }
                        else if ( isE911(pbe.Product2) && this.productMap.get('E911') != null) {
                            matchedProdMap.put(this.productMap.get('E911'), pbe.Product2);
                        }
                        else if( isCRF(pbe.Product2) && this.productMap.get('CRF') != null) {
                            matchedProdMap.put(this.productMap.get('CRF'), pbe.Product2);
                        }
                    }

                    // Match other
                    for (DWHProduct dwhProduct : this.dwhProductList) {

                        if (  PBE_MATCH_FEATURES_OTHER.contains(dwhProduct.featureId)
                              && dwhProduct.productName == pbe.Product2.Name
                              && dwhProduct.featureId == pbe.Product2.Feature__c )
                        {
                            matchedProdMap.put(dwhProduct, pbe.Product2);
                            break;
                        }

                        if(GLOBAL_OFFICE_FEATURES.contains(dwhProduct.featureId)) {
                            String prodName = dwhProduct.featureId == 41
                                    ? 'IVN Local'
                                    : dwhProduct.featureId == 42
                                            ? 'IVN Toll Free'
                                            : 'Global Office';

                            String countryName = '';
                            if (pbe.Product2.Name.contains(' - ')) {
                                countryName = pbe.Product2.Name.split(' - ')[1];
                            }
                            if (dwhProduct.countryName == countryName
                                || dwhProduct.countryName == COUNTRY_MAPPING.get(countryName)) {
                                    prodName += ' - ' + countryName;
                            }
                            if (pbe.Product2.Name == prodName) {
                                matchedProdMap.put(dwhProduct, pbe.Product2);
                                break;
                            }
                        }
                    }
                }
            }

            return this;
        }

        /* match Entitlement To matched Product */
        public Entitlement__c[] matchEntToProd(Entitlement__c[] entls, Map<String, Entitlement__c> entMap, Account acc) {
            Entitlement__c[] updatedEnts = new List<Entitlement__c>();

            if(chargeTerm == null) {
                return updatedEnts;
            }

            /* if monthly-contract - check on negative discounts
                in case existing negative discount - switch plan to monthly */
            if(chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                Map<DWHProduct, Product2> tempAllMatched = new Map<DWHProduct, Product2>();
                                          tempAllMatched.putAll(this.otherMatchedProdMap);
                                          tempAllMatched.putAll(this.durationToMatchedProdMap.get(chargeTerm));
                for (DWHProduct dwhProd : tempAllMatched.keySet() ) {
                    if(getDiscount(dwhProd, tempAllMatched.get(dwhProd) ) < 0) {
                        chargeTerm = Product2Helper.CHARGE_TERM_MONTHLY;
                        break;
                    }
                }
            }

            this.allMatched.putAll(this.otherMatchedProdMap);
            this.allMatched.putAll(this.durationToMatchedProdMap.get(chargeTerm));

            /* matching */
            for (DWHProduct dwhProd : this.allMatched.keySet() ) {
                Product2 sfProd = this.allMatched.get(dwhProd);
                Entitlement__c ent;

                /* first we try to match active entls */
                ent = matchEnt(sfProd, entls, entMap, true);
                System.debug('match by active -> ' + ent);

                /* if there is no one match - match inactive entls */
                if(ent == null) {
                  ent = matchEnt(sfProd, entls, entMap, false);
                }
                System.debug('match by inactive -> ' + ent);

                /* create matched ent map */
                if(ent != null) {
                    matchedEntlMap.put(ent.Id, ent);
                }

                /* create new if there is no one match */
                ent = (ent != null) ? ent : createEnt(acc);
                ent = updateEnt(ent, sfProd, dwhProd, this.currencyId);

                updatedEnts.add(ent);
            }

            return updatedEnts;
        }

        /* helpers */
        private Entitlement__c matchEnt(Product2 sfProd, Entitlement__c[] entls, Map<String, Entitlement__c> entMap, Boolean byActive) {
          Entitlement__c entl;
          Entitlement__c entlService = entMap.get('Service');

          if( isService(sfProd) ) {
            entl = entlService;
          }
          else if ( isServiceFee(sfProd, entlService) ) {
            if( isE911(sfProd) ) {
              entl = entMap.get('E911');
            }
            else if( isCRF(sfProd) ) {
              entl = entMap.get('CRF');
            }
          }
          else {
            Entitlement__c[] filteredEntls = filterEntlsByActiveValue(entls, byActive);

            Map<String, String> formula = getFormula(sfProd);
            List<Entitlement__c> matchResult = (filteredEntls.size() == null)
              ? new List<Entitlement__c>()
              : RecordsMatcher.match( filteredEntls, sfProd, formula.get('description'), formula.get('source') );

            if (matchResult.size() > 0) {
              entl = byActive ? matchResult.get(0) : getLastCreatedEntl(matchResult);
            }

            /* For active shouldn't be more then 1 */
            if(byActive && matchResult.size() > 1) {
              PlatformLog.logResult('EntitlementSync', 'Product has been matched with more then one entitlement', null, null, null, false);
            }
          }

          return entl;
        }

        private Entitlement__c getLastCreatedEntl(Entitlement__c[] entls) {
          Entitlement__c lastCreatedEntl;

          for (Entitlement__c entl : entls) {
            if(lastCreatedEntl == null) {
              lastCreatedEntl = entl;
            }
            else if(lastCreatedEntl.CreatedDate < entl.CreatedDate) {
              lastCreatedEntl = entl;
            }
          }

          return lastCreatedEntl;
        }
        private Map<String, String> getEESupportNameMap(Entitlement__c[] entls) {
            String technicalAccountManagement = getTechnicalAccountManagementName(entls);
            Map<String, String> result = new Map<String, String>{
                'Extended Enterprise Support - Platinum - price per DL' => 'Extended Enterprise Support - Platinum',
                'Extended Enterprise Support - Gold - price per DL'     => 'Extended Enterprise Support - Gold',
                'Extended Enterprise Support - Silver - price per DL'   => 'Extended Enterprise Support - Silver',
                technicalAccountManagement                              => 'Extended Enterprise Support'
            };

            return result;
        }
        private String getTechnicalAccountManagementName(Entitlement__c[] entls) {
            String result = 'Technical Account Management - first price per DL';
            for(Entitlement__c e : entls) {
                if( e.Product__r.Name == 'Technical Account Management - second price per DL'
                    || e.Product__r.Name == 'Technical Account Management - third price per DL') {
                    result = e.Product__r.Name;
                }
            }
            return result;
        }
        /* dwh prod name to sf prod name */
        private Map<String, String> getPolycomNameMap() {
            return new Map<String, String>{
                'Polycom VVX-410 with 1 Expansion Module - Leasing' => 'Polycom VVX-410 Color Gigabit Ethernet Phone with 1 ' + 'Expansion Module - Rental',
                'Polycom VVX-411 with 1 Expansion Module - Leasing' => 'Polycom VVX-411 Color Gigabit Ethernet Phone with 1 ' + 'Expansion Module - Rental',
                'Polycom VVX-500 with 1 Expansion Module - Leasing' => 'Polycom VVX-500 Color Touchscreen Phone with 1 '      + 'Expansion Module - Rental',
                'Polycom VVX-601 with 1 Expansion Module - Leasing' => 'Polycom VVX-601 Large Color Touchscreen with 1 '      + 'Expansion Module - Rental',
                'Leasing'                                           => 'Rental'
            };
        }

        private Entitlement__c updateEnt(Entitlement__c uEntl, Product2 sfProd, DWHProduct dwhProd, Decimal currencyId) {
            uEntl.Active__c = true;
            uEntl.Name = sfProd.Name.length() > 80 ? sfProd.Name.substring(0, 80) : sfProd.Name;
            uEntl.Product__c = sfProd.Id;
            uEntl.Quantity__c = dwhProd.quantity;
            uEntl.Price__c = getPrice(dwhProd, sfProd);
            uEntl.Discount__c = getDiscount(dwhProd, sfProd);
            uEntl.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
            uEntl.CurrencyIsoCode = CURRENCY_MAPPING.get(currencyId);
            System.debug(uEntl);
            return uEntl;
        }

        private Decimal getDiscount(DWHProduct dwhProd, Product2 sfProd) {
            return dwhProd.itemListPrice - dwhProd.itemDiscountPrice - getMCDiscount(sfProd);
        }

        private Decimal getPrice(DWHProduct dwhProd, Product2 sfProd) {
            return dwhProd.itemListPrice - getMCDiscount(sfProd);
        }

        private Decimal getMCDiscount(Product2 sfProd) {
            Decimal d = 0;

            if(chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                d = this.monthlyContractDiscounts.get(sfProd.Id);
                d = (d != null) ? d : 0;
            }

            return d;
        }

        private Entitlement__c[] findUnmatchedEntls(Entitlement__c[] currentEntls) {
          Entitlement__c[] unmatchedEntls = new List<Entitlement__c>();

          for (Entitlement__c entl : currentEntls) {
            if( !matchedEntlMap.containsKey(entl.Id) ) {
                unmatchedEntls.add(entl);
            }
          }

          return unmatchedEntls;
        }
    }

    global HTTPResponse respond(HTTPRequest req) {

        System.assertEquals('GET', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(mockDWHJsonResponce);
        res.setStatus('OK');
        res.setStatusCode(200);
        return res;
    }

    public EntitlementSync() {}

    public static void syncEntitlements(Order ord, List<OrderItem> orderItems){

        Map<Id, Entitlement__c> entitlementMap = new Map<Id, Entitlement__c>([
                SELECT Id, Name, Product__c, Discount__c, Discount_Type__c, Quantity__c, Active__c,
                        Product__r.Family, Product__r.Name, Product__r.Product_Type__c, Product__r.ExtID__c,
                        Product__r.Edition__c, Product__r.Number_of_minutes__c, Product__r.Parent__c,
                        (SELECT Id, QuantityOrThreshold__c, RampUpStartDate__c, RampUp__c
                            FROM Product_Details__r
                            WHERE IsActive__c = true
                            ORDER BY RampUpStartDate__c DESC, Name DESC
                        )
                FROM Entitlement__c
                WHERE Account__c = :ord.AccountId
        ]);

        Entitlement__c[] matcherResult;
        Entitlement__c matchingEntitlement;

        Schema.DescribeSObjectResult objectDesc = Order.SObjectType.getDescribe();
        Map<Id, Schema.RecordTypeInfo> rtById = objectDesc.getRecordTypeInfosById();
        String rtName = rtById.get(ord.RecordTypeId).getName();

        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for (OrderItem item : orderItems) {
            Entitlement__c entitlementFromMap = entitlementMap.get(item.RC_Entitlement__c);
            Boolean isRCEntitlementExists = (item.RC_Entitlement__c != null);
            Boolean isEntitlmentMapHasRCEntitlment = (entitlementFromMap != null);
            matchingEntitlement =
                    (isRCEntitlementExists && isEntitlmentMapHasRCEntitlment)
                            ? entitlementFromMap : null;
            if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(rtName) || rtName == 'RingCentral' || rtName == 'Professional Services') {
                if (matchingEntitlement != null) {
                    if (item.Active__c) {
                        // if cancel order item is created for entitlement - it should be deactivated
                        // Don't forget to remove check here while removing Cancel Order creation!
                        if (ord.Is_Cancel_Order__c) {
                            deactivateEntitlement(item, matchingEntitlement);
                        } else {
                            updateEntitlement(item, matchingEntitlement);
                        }
                    } else {
                        item.RC_Entitlement__c = matchingEntitlement.Id;
                        deactivateEntitlement(item, matchingEntitlement);
                        item.Deactivate_Date__c = DateTime.now();
                        orderItemsToUpdate.add(item);
                    }
                } else {
                    Entitlement__c newEntitlement;
                    if (item.Active__c) {
                        newEntitlement = insertNewEntitlement(item, ord.AccountId, ord);
                    }
                }
            }
        }

        if(!deactivateEntlProductDetails.isEmpty()){
            upsert deactivateEntlProductDetails;
        }

        if(!entlToOrderItemMap.isEmpty()){
            Set<Entitlement__c> uniqueEntitlements = new Set<Entitlement__c>(entlToOrderItemMap.values());
            upsert new List<Entitlement__c>(uniqueEntitlements);
        }
        updateOrderItems(orderItemsMap, entlToOrderItemMap);
        //B-1463 Change deactivation logic for entitlements
        update orderItemsToUpdate;

        for (Id idpd : productDetailsToInsert.keySet()) {
            productDetailsToInsert.get(idpd).Entitlement__c = entlToOrderItemMap.get(idpd).Id;
        }

        if(!productDetailsToInsert.isEmpty()){
            insert productDetailsToInsert.values();
        }

        for (Id idpd : productDetailsToInsert.keySet()) {
            productDetailsToUpdate.get(idpd).ProductDetail__r = productDetailsToInsert.get(idpd);
            productDetailsToUpdate.get(idpd).ProductDetail__c = productDetailsToInsert.get(idpd).Id;
        }

        productDetailsToUpdate.putAll(entitlementProductDetails);
        productDetailsToUpdate.putAll(adjustedDownSellProductDetails(entitlementIdToPrDet));
        productDetailsToUpdate.putAll(changeDiscountProductDetails);
        for (ProductDetail__c pd : productDetailsToUpdate.values()) {
            if (pd.OrderItem__c != null) {
                pd.RampUpStartDate__c = pd.ProductDetail__r.RampUpStartDate__c;
            }
        }

        if(!productDetailsToUpdate.isEmpty()){
            update productDetailsToUpdate.values();
        }

        ensureTotalQtyAlignsWithPDs(productDetailsToUpdate.values());
    }

    public static Entitlement__c findEntitlement(List<Entitlement__c> accountEntitlements, Order ord, OrderItem ordItem) {
        Entitlement__c result;
        for (Entitlement__c entl: accountEntitlements) {
            if (entl.Product__c == ordItem.Pricebookentry.Product2Id && entl.Active__c) {
                result = entl;
                break;
            }
        }
        if (result == null && ordItem.Pricebookentry.Product2.Family == 'CC Service') {
            for (Entitlement__c entl: accountEntitlements) {
                if (entl.Active__c
                        && entl.Product__r.Family == 'CC Service'
                        && entl.Product__r.Edition__c == ordItem.Pricebookentry.Product2.Edition__c) {
                    result = entl;
                    break;
                }
            }
        }
        return result;
    }

    public static Entitlement__c insertNewEntitlement(OrderItem ordItem, Id accountId, Order ord) {

        Boolean isOneTimeProduct = ordItem.Pricebookentry.Product2.Feature__c != null &&
            Product2Helper.ONE_TIME_FEATURE_SET.contains(Integer.valueOf(ordItem.Pricebookentry.Product2.Feature__c));

        Decimal qty = isOneTimeProduct ? 0 : ordItem.QuantityOrThreshold__c;

        Entitlement__c entitlementToIns = new Entitlement__c(
                Discount__c = ordItem.Discount_Number__c,
                Quantity__c = qty,
                CurrencyIsoCode = ordItem.Pricebookentry.CurrencyIsoCode,
                Price__c = ordItem.UnitPriceWithoutDiscount__c,
                Start_Date__c = Date.today(),
                Account__c = accountId,
                Product__c = ordItem.Pricebookentry.Product2Id,
                Active__c = true,
                Discount_Type__c = ordItem.Discount_Type__c,
                Name = truncateString(ordItem.Pricebookentry.Product2.Name, NAME_FIELD_LENGTH)
        );
        //B-1465 Populate dates on order items when status changes occur
        ordItem.Insert_Date__c = DateTime.now();
        DateTime currentDateTime = System.now();

        for (ProductDetail__c pd : ordItem.Product_Details__r) {
            ProductDetail__c newProductDetail = new ProductDetail__c(
                QuantityOrThreshold__c = pd.QuantityOrThreshold__c,
                RampUpStartDate__c     = pd.OrderItem__r.Order.Submitted_Date__c == null
                                           ? currentDateTime
                                           : pd.OrderItem__r.Order.Submitted_Date__c,
                RampUp__c              = pd.RampUp__c
            );
            pd.RampUpStartDate__c = pd.OrderItem__r.Order.Submitted_Date__c;

            productDetailsToInsert.put(ordItem.Id, newProductDetail);
            productDetailsToUpdate.put(ordItem.Id, pd);
        }

        entlToOrderItemMap.put(ordItem.Id, entitlementToIns);
        orderItemsMap.put(ordItem.Id, ordItem);
        return entitlementToIns;
    }

    public static OrderItem updateEntitlement(OrderItem ordItem, Entitlement__c entl) {

        Boolean isOneTimeProduct = ordItem.Pricebookentry.Product2.Feature__c != null &&
            Product2Helper.ONE_TIME_FEATURE_SET.contains(Integer.valueOf(ordItem.Pricebookentry.Product2.Feature__c));

        entl.Quantity__c += ordItem.QuantityOrThreshold__c;
        if (entl.Quantity__c < 0 || isOneTimeProduct) {
            entl.Quantity__c = 0;
        }

        if (ordItem.Pricebookentry.Product2.Family == Product2Helper.FAMILY_MINUTES_BUNDLE && entl.Quantity__c == 0) {
            entl.Active__c = false;
        }

        entl.Discount__c = ordItem.Discount_Number__c;
        entl.Discount_Type__c = ordItem.Discount_Type__c;
        entl.Price__c = ordItem.UnitPriceWithoutDiscount__c;
        entl.Product__c = ordItem.Pricebookentry.Product2Id;
        entl.Name =  truncateString(ordItem.Pricebookentry.Product2.Name, NAME_FIELD_LENGTH);
        entl.CurrencyIsoCode = ordItem.Pricebookentry.CurrencyIsoCode;

        //B-1465 Populate dates on order items when status changes occur
        ordItem.Update_Date__c = DateTime.now();
        DateTime currentDateTime = System.now();
        for (ProductDetail__c pd : ordItem.Product_Details__r) {
            if (pd.QuantityOrThreshold__c < 0) {
                entitlementIdToPrDet.put(pd.OrderItem__r.RC_Entitlement__c, pd);
            } else if (pd.QuantityOrThreshold__c == 0) {
                if (pd.ProductDetail__c != null) {
                    entitlementProductDetails.add(new ProductDetail__c(
                        Id = pd.ProductDetail__c,
                        RampUp__c = pd.RampUp__c)
                    );
                } else if (ordItem.Zero_Quantity__c) {
                    pd.ProductDetail__c = entl.Product_Details__r[0].Id;

                    changeDiscountProductDetails.add(pd);
                }
            } else {
                ProductDetail__c newProductDetail = new ProductDetail__c(
                    QuantityOrThreshold__c = pd.QuantityOrThreshold__c,
                    RampUpStartDate__c     = pd.OrderItem__r.Order.Submitted_Date__c == null
                        ? currentDateTime
                        : pd.OrderItem__r.Order.Submitted_Date__c,
                    RampUp__c              = pd.RampUp__c
                );
                pd.RampUpStartDate__c = pd.OrderItem__r.Order.Submitted_Date__c;

                productDetailsToInsert.put(ordItem.Id, newProductDetail);
                productDetailsToUpdate.put(ordItem.Id, pd);
            }
        }

        entlToOrderItemMap.put(ordItem.Id, entl);
        orderItemsMap.put(ordItem.Id, ordItem);
        return ordItem;
    }

    public static void deactivateEntitlement(OrderItem orderItem, Entitlement__c entl) {
        if (entl.Active__c) {
            entl.Active__c = false;
            entl.End_Date__c = Date.today();

            //B-1463 Change deactivation logic for entitlements
            entl.Quantity__c = 0;

            entlToOrderItemMap.put(entl.Id, entl);

            List<ProductDetail__c> listProductDetails = new List<ProductDetail__c>();

            for (ProductDetail__c pd : entl.Product_Details__r) {
                listProductDetails.add(new ProductDetail__c(
                    OrderItem__c = orderItem.Id,
                    ProductDetail__c = pd.Id,
                    QuantityOrThreshold__c = -pd.QuantityOrThreshold__c
                ));

                pd.IsActive__c = false;

                listProductDetails.add(pd);
            }
            if (!listProductDetails.isEmpty() && orderItem.Product_Details__r.size() > 0) {
                listProductDetails[0].Id = orderItem.Product_Details__r[0].Id;
                deactivateEntlProductDetails.addAll(listProductDetails);
            }
        }
    }

    public static string truncateString(string inputString,integer length) {
        string result=inputString;
        if(inputString!=null && inputString!='' && length>0) {
            result=(inputString.Length()<length?inputString:inputString.substring(0,length));
        }
        return result;
    }

    public static void updateOrderItems(Map<Id, OrderItem> oiMap, Map<Id, Entitlement__c> eMap) {
        for (Id key : eMap.keySet()) {
            if (oiMap.containsKey(key)) {
                oiMap.get(key).RC_Entitlement__c = eMap.get(key).Id;
            }
        }
        update oiMap.values();
    }

    public static DWHResponse parseDWHResponse(String jsonRes) {
        DWHResponse dwhRes;

        /* Here we can get - List of Products || Single Product */
        try {
            dwhRes = (DWHResponse) JSON.deserialize(jsonRes, DWHResponse.class);
        } catch(Exception e) {
            DWHResponseSingleProduct dwhRespSingle =
                    (DWHResponseSingleProduct) JSON.deserialize(jsonRes, DWHResponseSingleProduct.class);
            dwhRes = new DWHResponse(dwhRespSingle);
        }

        dwhRes.setChargeTermForTrialAccount();

        return dwhRes;
    }


    static Product2[] productList;
    static PriceBookEntry[] pbeList;
    static Map<Id, Decimal> monthlyContractDiscounts = new Map<id,decimal>();
    static Map<Decimal, String> psPriceToName = new Map<Decimal, String>();
    static Map<Integer, String> psIntPriceToName = new Map<Integer, String>();

    //B-2029 Sync with DWH
    webservice static Response syncWithDWH(String accountId) {
        Response syncWithDWHresp = new Response();
        syncWithDWHresp.setData(ENTITLEMENT_RESPONSE_DATA_KEY, new List<Entitlement__c>());

        Account acc = getAccountById(accountId);
        if(acc == null) {
            syncWithDWHresp.error('Cannot find account with id ' + accountId);
            return syncWithDWHresp;
        }

        List<Entitlement__c> currentEntls = getEntitlements(accountId);
        List<Entitlement__c> entls = currentEntls.deepClone(true);
        syncWithDWHresp.setData(ENTITLEMENT_RESPONSE_DATA_KEY, entls);

        String dwhUrl = DWHEntitlementEndpoint__c.getInstance().URL__c;

        if(dwhUrl == null || acc.RC_User_ID__c == null) {
            return syncWithDWHresp;
        }

        /* http req */
        HttpRequest request = new HttpRequest();
        request.setEndpoint(dwhUrl + acc.RC_User_ID__c);
        request.setTimeout(HTTP_REQUEST_TIMEOUT);
        request.setMethod('GET');

        DWHResponse dwhResp;
        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatus() != 'OK') {
                syncWithDWHresp.error(response.getBody());
                return syncWithDWHresp;
            }
            dwhResp = parseDWHResponse(response.getBody());

            /* create ent map */
            Map<String, Entitlement__c> entMap = createEntMap(currentEntls);

            /* Agregate DWH Products */
            /* #1 Agragate */
            DWHProducts dwhProducts = new DWHProducts(dwhResp.rcProducts);

            /* #1.1 Normalize */
            if(!dwhProducts.productMap.isEmpty()) {
              String chargeTerm = getChargeTermOfService(acc, dwhResp.tierId, entMap.get('Service'), dwhProducts.productMap.get('Service'));
              if(chargeTerm == null) {
                  syncWithDWHresp.error('Charge term is empty');
                  return syncWithDWHresp;
              }
              dwhProducts.normalize(chargeTerm);
            }

            /* Matching */
            ProductsMatcher pMatcher = new ProductsMatcher(dwhResp, dwhProducts);

            if(
                pMatcher.pbeList.isEmpty()
                && String.isBlank(acc.Billing_ID__c)
                && isDwhRespContainsNbsProd(dwhResp)
            ) {
                String exHeader = 'Entitlement Sync Failed. Account is pending Sync with NGBS. ';
                String exBody = 'Please wait at least 1 hour and try again.';
                syncWithDWHresp.error(exHeader + exBody);
                return syncWithDWHresp;
            }

            entls = pMatcher.fallbackToMonthly()
                            .alignServiceProductPrice()
                            .matchBySFProduct(currentEntls)
                            .matchBySFPbe()
                            .matchEntToProd(currentEntls, entMap, acc);

            /* Deactivate unmatched ents */
            entls.addAll( deactivateEntlsBySubCategory( pMatcher.findUnmatchedEntls(currentEntls), Product2Helper.SUBCATEGORY_RINGCENTRAL ) );

            upsert entls;
        } catch (Exception e) {
            PlatformLog.logException('Sync entitlement with DWH', e);
            AquivaHelper.throwAquivaException(e);
        }
        syncWithDWHresp.setData(ENTITLEMENT_RESPONSE_DATA_KEY, entls);
        return syncWithDWHresp;
    }

    @TestVisible
    private static Boolean isDwhRespContainsNbsProd(DWHResponse dwhResp) {
        Boolean res = false;
        for(DWHProduct dwhProd : dwhResp.rcProducts) {
            if(!String.isBlank(dwhProd.productName) && dwhProd.productName.toUpperCase().contains('NBS')) {
                res = true;
                break;
            }
        }
        return res;
    }

    public static List<QuoteLineItem> createLineItemsFromEntitlements(EntitlementSync.EntitlementsParams ep) {
        Map<Id, Entitlement__c> productIdToEntitlement = getMapProductIdToEntitlement(ep.entitlements);
        Map<Id, PriceBookEntry> pbeToEntitlement = new Map<Id, PriceBookEntry>();
        List<Entitlement__c> entsNotMatchedByProductId = new List<Entitlement__c>();
        List<QuoteLineItem> qlisToAdd = new List<QuoteLineItem>();

        for (PriceBookEntry pbe : ep.pricebookEntries) {
            if (productIdToEntitlement.get(pbe.Product2Id) != null) {
                pbeToEntitlement.put(productIdToEntitlement.get(pbe.Product2Id).Id, pbe);
            }
        }

        for (Entitlement__c ent : ep.entitlements) {
            if (!pbeToEntitlement.keySet().contains(ent.Id)) {
                entsNotMatchedByProductId.add(ent);
            }
        }
        if (entsNotMatchedByProductId.size() > 0) {
            Map<String, List<Entitlement__c>> familyToListOfEnts = getMapFamilyToListOfEnts(entsNotMatchedByProductId);
            Map<String, List<Entitlement__c>> nameAndFamilyToListOfEnts = getMapNameAndFamilyToListOfEnts(entsNotMatchedByProductId);
            for (PriceBookEntry pbe : ep.pricebookEntries) {
                if (productIdToEntitlement.get(pbe.Product2Id) != null) {
                    continue;
                }
                List<Entitlement__c> matcherResult = new List<Entitlement__c>();
                if (Product2Helper.SUBCATEGORY_CONTACT_CENTER.equalsIgnoreCase(pbe.Product2.Sub_Category__c)) {
                    matcherResult = nameAndFamilyToListOfEnts.get(pbe.Product2.Name + pbe.Product2.Family);
                } else {
                    List<Entitlement__c> entsToMatch = familyToListOfEnts.get(pbe.Product2.Family);
                    if(entsToMatch != null && !entsToMatch.isEmpty()) {
                        matcherResult = (Entitlement__c[]) RecordsMatcher.match(
                            entsToMatch,
                            pbe.Product2,
                            'Upsell_Matcher_Formula__c'
                        );
                    }
                }
                if (matcherResult != null && matcherResult.size() > 0) {
                    Entitlement__c mEnt = matcherResult[0];
                    if (!pbeToEntitlement.containsKey(mEnt.Id)) {
                        pbeToEntitlement.put(mEnt.Id, pbe);
                    }
                }
            }
        }

        for (Entitlement__c entl : ep.entitlements) {
            if(entl.Discount__c < 0) {
                AquivaHelper.throwAuraException(Label.Entitlement_Sync_error);
            }
            if (pbeToEntitlement.containsKey(entl.Id)) {
                PricebookEntry pbe = pbeToEntitlement.get(entl.Id);
                QuoteLineItem qli = createQLIfromPbeAndEnt(pbe, entl, ep);
                qlisToAdd.add(qli);
            }
        }
        return qlisToAdd;
    }

    /* Refactored code */
    public static Account getAccountById(String accountId) {
        List<Account> accs = [
            SELECT Id, RC_User_ID__c,Sales_Agreement_Start_Date__c,
                    Sales_Agreement_End_Date__c, Billing_ID__c
            FROM Account
            WHERE Id = :accountId];

        return accs.isEmpty() ? null : accs.get(0);
    }

    public static Entitlement__c[] getEntitlements(String accountId) {
        return [SELECT Id, Price__c, Discount__c, Discount_Type__c, Active__c, Quantity__c, EffectivePrice__c,
                       CreatedDate,
                       Product__r.Feature__c,
                       Product__r.Sub_Feature__c,
                       Product__r.Dependent_on_Feature__c,
                       Product__r.ExtID__c,
                       Product__r.Name,
                       Product__r.Charge_Term__c,
                       Product__r.Family,
                       Product__r.Sub_Category__c
                FROM Entitlement__c
                WHERE Account__c = :accountId
                ORDER BY Active__c, CreatedDate];
    }

    public static String getChargeTermOfService(Account acc, Decimal dwhTierId, Entitlement__c eService, DWHProduct pService) {
        String result;

        result = getChargeTerm(acc, pService.chargeTerm);

        if (result == null) {
            result = eService.Product__r.Charge_Term__c;
        }

        return result;
    }

    /* check on monthly-contract */
    public static string getChargeTerm(Account currentAccount, String dwhChargeTerm) {
        String result = dwhChargeTerm;
        integer contractedDays = 0;
        Date agreementStart = currentAccount.Sales_Agreement_Start_Date__c;
        Date agreementEnd   = currentAccount.Sales_Agreement_End_Date__c;

        if(agreementStart != null && agreementEnd != null) {
            contractedDays = agreementStart.daysBetween(agreementEnd);
        }

        if(result == Product2Helper.CHARGE_TERM_MONTHLY && contractedDays > 363) {
            result = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        }

        return result;
    }

    /* Need use sorted list of entl (first by active then by created date)
      It provides right selecting service and fees */
    public static Map<String, Entitlement__c> createEntMap(Entitlement__c[] ents) {
        Map<String, Entitlement__c> entMap = new Map<String, Entitlement__c>();

        for (Entitlement__c ent : ents) {
            if ( isService(ent.Product__r) ) {
                entMap.put('Service', ent);
            }
        }
        for (Entitlement__c entl : ents) {
            if ( isServiceFee(entl.Product__r, entMap.get('Service')) ) {
                    if ( isE911(entl.Product__r) ) {
                        entMap.put('E911', entl);
                    } else {
                        entMap.put('CRF', entl);
                    }
            }
        }

        return entMap;
    }

    public static Entitlement__c createEnt(Account acc) {
        return new Entitlement__c(
            Account__c = acc.id
        );
    }

    public static Map<String, String> getFormula(Product2 prod) {
        String description;
        String source = 'string';
        Map<String, String> formula = new Map<String, String>();

        if (prod.Feature__c == 24) {
            description = '{Product__r.Feature__c} equal 24';
        }
        else if (prod.Feature__c == 59) {
            description = '{Product__r.Feature__c} equal 59';
        }
        else if (prod.Feature__c == 36 && prod.Name.contains('International Calling Credit Bundle')) {
            description = '{Product__r.Feature__c} equal 36%%{Product__r.Name} contains International Calling Credit Bundle';
        }
        else if (prod.Feature__c == 36 && prod.Name.contains('International minute bundle')) {
            description = '{Product__r.Feature__c} equal 36%%{Product__r.Name} contains International minute bundle';
        }
        else {
            description = prod.Matcher_Formula__c.replace('%%{Active__c}', '');
        }

        formula.put('description', description);
        formula.put('source', source);

        return formula;
    }
    public static Entitlement__c[] filterEntlsByActiveValue(Entitlement__c[] entls, Boolean active) {
      List<Entitlement__c> filtered = new List<Entitlement__c>();

      for (Entitlement__c entl : entls) {
        if(entl.Active__c == active) {
            filtered.add(entl);
        }
      }

      return filtered;
    }
    public static Entitlement__c[] deactivateEntlsBySubCategory(Entitlement__c[] entls, String subcategory) {
        for (Entitlement__c entl : entls) {
            if(Product2Helper.ONE_TIME_FEATURE_SET.contains(Integer.valueOf(entl.Product__r.Feature__c))) {
                // bypass deactivating entitlements for "One - Time" products.
                continue;
            }
            if(entl.Product__r.Sub_Category__c == subcategory) {
                entl.Active__c = false;
            }
        }

        return entls;
    }

    /* helpers */
    public static Boolean isServiceFee(Product2 prod, Entitlement__c entlService) {
      Boolean isFee = (prod.Family == 'Fee');
      Boolean isSameDepFeature = (entlService != null && prod.Dependent_on_Feature__c == entlService.Product__r.Feature__c);

      return isFee && isSameDepFeature;
    }
    public static Boolean isService(Product2 prod) {
      return prod.Family == 'Service';
    }
    public static Boolean isE911(Product2 prod) {
      return prod.Name.containsIgnoreCase('e911');
    }
    public static Boolean isCRF(Product2 prod) {
      return prod.Name.containsIgnoreCase('Cost Recovery Fee');
    }

    /* Product Helpers */
    public static Boolean isPremiumSupport(Product2 p) { return p.Feature__c == 33; }
    public static Boolean isPremiumSupport(DWHProduct p) { return p.featureId == 33; }
    public static Boolean isRentalPhone(DWHProduct p) { return p.featureId == 34; }

    public static Boolean isExtendedEnterpriseSupport(DWHProduct p) {
        return p.featureId == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT;
    }

    public static Boolean isCCExtendedEnterpriseSupport(DWHProduct p) {
        return p.featureId == Product2Helper.FEATURE_CC_EXTENDED_ENTERPRISE_SUPPORT;
    }

    private static Map<String, List<Entitlement__c>> getMapFamilyToListOfEnts(List<Entitlement__c> entitlements) {
        Map<String, List<Entitlement__c>> familyToListOfEnts = new Map<String, List<Entitlement__c>>();
        for (Entitlement__c e : entitlements) {
            String family = e.Product__r.Family;
            if (String.isBlank(family)) {
                continue;
            }
            if (familyToListOfEnts.get(family) == null) {
                familyToListOfEnts.put(family, new List<Entitlement__c>());
            }
            familyToListOfEnts.get(family).add(e);
        }
        return familyToListOfEnts;
    }
    private static Map<String, List<Entitlement__c>> getMapNameAndFamilyToListOfEnts (List<Entitlement__c> entitlements) {
        Map<String, List<Entitlement__c>> nameAndFamilyToListOfEnts = new Map<String, List<Entitlement__c>>();
        for (Entitlement__c e : entitlements) {
            String family = e.Product__r.Family;
            String name = e.Product__r.Name;
            if (String.isBlank(family) || String.isBlank(name)) {
                continue;
            }
            if (nameAndFamilyToListOfEnts.get(name + family) == null) {
                nameAndFamilyToListOfEnts.put(name + family, new List<Entitlement__c>());
            }
            nameAndFamilyToListOfEnts.get(name + family).add(e);
        }
        return nameAndFamilyToListOfEnts;
    }
    private static Map<Id, Entitlement__c> getMapProductIdToEntitlement(List<Entitlement__c> entitlements) {
        Map<Id, Entitlement__c> productIdToEntitlement = new Map<Id, Entitlement__c>();
        for (Entitlement__c ent : entitlements) {
            if (String.isBlank(ent.Product__c)) {
                throw new AquivaHelper.AquivaException(
                        'Entitlement has no product. Info:' +
                        ' Entitlement Id: ' + ent.Id +
                        ' Entitlement name: ' + ent.Name
                );
            }

            if (productIdToEntitlement.get(ent.Product__c) != null) {
                throw new AquivaHelper.AquivaException(
                        'Two entitlements with for one product are found. Info:' +
                        ' Entitlement 1 Id: ' + ent.Id +
                        ', Entitlement 2 Id: ' + productIdToEntitlement.get(ent.Product__c).Id +
                        ' Product Id: ' + ent.Product__c
                );
            }
            productIdToEntitlement.put(ent.Product__c, ent);
        }
        return productIdToEntitlement;
    }

    private static QuoteLineItem createQLIfromPbeAndEnt(
        PricebookEntry pbe, Entitlement__c entl, EntitlementSync.EntitlementsParams ep
    ) {
        Boolean isAdditionalLinesMoreThanZeroAndFamilyIsService = (
            ep.additionalLines != null &&
            ep.additionalLines != 0 &&
            entl.Product__r.Family == Product2Helper.FAMILY_SERVICE
        );
        Boolean isChargeTermMatchOnEntAndPBEMatch = (entl.Product__r.Charge_Term__c == pbe.Product2.Charge_Term__c);

        Decimal quantityVal = (isAdditionalLinesMoreThanZeroAndFamilyIsService) ? ep.additionalLines : 1;
        Boolean zeroQuantityVal = (isAdditionalLinesMoreThanZeroAndFamilyIsService) ? false : true;
        Decimal unitPriceVal = (isChargeTermMatchOnEntAndPBEMatch) ? entl.Price__c : pbe.UnitPrice;
        String discountTypeVal = (isChargeTermMatchOnEntAndPBEMatch) ? entl.Discount_Type__c : QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        Decimal discountNumberVal = (isChargeTermMatchOnEntAndPBEMatch) ? entl.Discount__c : 0;

        if(ep.quoteUpsellStatus != null && ep.quoteUpsellStatus == QuoteHelper.STATUS_UPGRADE) {
            unitPriceVal = pbe.UnitPrice;
        }

        return new QuoteLineItem (
            Product2Id = pbe.Product2Id,
            PriceBookEntryId = pbe.Id,
            QuoteId = ep.quoteId,
            Entitlement__c = entl.Id,
            Quantity = quantityVal,
            Zero_Quantity__c = zeroQuantityVal,
            UnitPrice = unitPriceVal,
            Discount_Type__c = discountTypeVal,
            Discount_Number__c = discountNumberVal,
            NewQuantity__c = entl.DisplayQuantity__c
        );
    }

    private static List<ProductDetail__c> adjustedDownSellProductDetails (Map<Id, ProductDetail__c> entitlementIdToPrDet) {
        List<ProductDetail__c> productDetailsForUpdate  = new List<ProductDetail__c>();
        EntitlementSelector    entitlementQuerySelector = new EntitlementSelector();
        List<Id>               listEntitlementIds       = new List<Id>(entitlementIdToPrDet.keySet());
        List<ProductDetail__c> allSplittedOrderItemPDs  = new List<ProductDetail__c>();
        Map<Id, SObject> mapEntitlements = new Map<Id, SObject>(
            entitlementQuerySelector.selectEntitlementsByIdsWithProductDetails(listEntitlementIds).executeQuery()
        );

        for (Entitlement__c entitlement : (List<Entitlement__c>) mapEntitlements.values()) {
            ProductDetail__c orderItemPD = entitlementIdToPrDet.get(entitlement.Id);
            Integer quantity = (Integer) orderItemPD.QuantityOrThreshold__c;
            List<ProductDetail__c> newOrderItemPDs = new List<ProductDetail__c>();
            for (ProductDetail__c entitlementPD : entitlement.Product_Details__r) {
                if (-quantity >= entitlementPD.QuantityOrThreshold__c) {
                    entitlementPD.isActive__c = false;
                    productDetailsForUpdate.add(entitlementPD);
                    newOrderItemPDs.add(new ProductDetail__c(
                        OrderItem__c = orderItemPD.OrderItem__c,
                        RampUp__c = '0',
                        RampUpStartDate__c = entitlementPD.RampUpStartDate__c,
                        ProductDetail__c = entitlementPD.Id,
                        QuantityOrThreshold__c = -entitlementPD.QuantityOrThreshold__c
                    ));
                    quantity = quantity + (Integer) entitlementPD.QuantityOrThreshold__c;
                    if (quantity == 0) {
                        newOrderItemPDs[newOrderItemPDs.size()-1].Id = orderItemPD.Id;
                        break;
                    }
                } else {
                    entitlementPD.QuantityOrThreshold__c = entitlementPD.QuantityOrThreshold__c + quantity;
                    orderItemPD.ProductDetail__c = entitlementPD.Id;
                    orderItemPD.QuantityOrThreshold__c = quantity;
                    productDetailsForUpdate.add(entitlementPD);
                    productDetailsForUpdate.add(orderItemPD);
                    break;
                }
            }
            allSplittedOrderItemPDs.addAll(newOrderItemPDs);
        }

        upsert allSplittedOrderItemPDs;
        return productDetailsForUpdate;
    }

    private static void ensureTotalQtyAlignsWithPDs(List<ProductDetail__c> pds) {
        Map<Id, Decimal> totalThresholdByOrderItemId = new Map<Id, Decimal>();
        for (ProductDetail__c pd : pds) {
            if (pd.OrderItem__c == null || pd.QuantityOrThreshold__c <= 0) {
                continue;
            }
            if (!totalThresholdByOrderItemId.containsKey(pd.OrderItem__c)) {
                totalThresholdByOrderItemId.put(pd.OrderItem__c, pd.QuantityOrThreshold__c);
            } else {
                totalThresholdByOrderItemId.put(pd.OrderItem__c, totalThresholdByOrderItemId.get(pd.OrderItem__c) + pd.QuantityOrThreshold__c);
            }
        }
        List<OrderItem> oiToUpdate = new List<OrderItem>();
        for (Id orderItemId : totalThresholdByOrderItemId.keySet()) {
            if (orderItemsMap.containsKey(orderItemId)
                    && orderItemsMap.get(orderItemId).Pricebookentry.Product2.Family == 'Overage') {
                OrderItem oi = orderItemsMap.get(orderItemId);
                oi.Threshold__c = totalThresholdByOrderItemId.get(orderItemId);
                oiToUpdate.add(oi);
            }
        }
        if (!oiToUpdate.isEmpty()) {
            update oiToUpdate;
        }
    }
}