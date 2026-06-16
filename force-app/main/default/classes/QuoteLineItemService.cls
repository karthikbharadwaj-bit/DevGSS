@RestResource(urlMapping='/QuoteLineItemService/*')
global with sharing class QuoteLineItemService {

    public static List<String> currencyList = RingCentralHelper.getOrgCurrencyCodes();
    public static final String TAX = 'Tax';
    public static final String DUPLICATED_QLI_MESSAGE = 'There are duplicated items on the quote';

    static Map<String,PricebookEntry> catalogIdToPBE = new Map<String,PricebookEntry>();
    static Map<String,Product2> catalogIdToProduct = new Map<String,Product2>();

    @HttpPost
    global static void handleRequest() {
        Response res = new Response();

        String body = RestContext.request.requestBody.toString();
        BillingWrappers.Params paramsData = (BillingWrappers.Params) JSON.deserialize(body, BillingWrappers.Params.class);

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        try {
            /* sync products */
            if (paramsData.action == 'syncProducts') {

                Response result = syncProducts(paramsData.quoteId, paramsData.products);
                res.addMessages(result.messages);

            } else if (paramsData.action == 'syncEntitlements') {

                syncEntitlements(paramsData.quoteId, paramsData.entitlements);

            } else if (paramsData.action == 'insertQuoteLineItems') {
                List<QuoteLineItem> qliList = insertQuoteLineItems(paramsData.quoteId, paramsData.items);
                res.setData('items', qliList);
            } else if (paramsData.action == 'insertTechnicalQuoteLineItems') {
                Map<String, QuoteLineItem[]> qliMap = upsertTechnicalQuoteLineItems(paramsData.quoteId, paramsData.cartItemsByService);
                res.setData('items', qliMap);
            } else if (paramsData.action == 'insertTechnicalQuoteLineItemsUB') {
                Map<String, QuoteLineItem[]> qliMap = upsertTechnicalQuoteLineItemsUB(paramsData.quoteId, paramsData.cartItemsByService);
                res.setData('items', qliMap);
            } else if (paramsData.action == 'updateQuoteLineItems') {
                List<QuoteLineItem> qliList = insertQuoteLineItems(paramsData.quoteId, paramsData.items);
                res.setData('items', qliList);
            } else if (paramsData.action == 'updateTechnicalQuoteLineItems') {
                Map<String, QuoteLineItem[]> qliMap = upsertTechnicalQuoteLineItems(paramsData.quoteId, paramsData.cartItemsByService);
                res.setData('items', qliMap);
            } else if (paramsData.action == 'updateTechnicalQuoteLineItemsUB') {
                Map<String, QuoteLineItem[]> qliMap = upsertTechnicalQuoteLineItemsUB(paramsData.quoteId, paramsData.cartItemsByService);
                res.setData('items', qliMap);
            } else if (paramsData.action == 'populateNGBSEntitlementTotals') {
                update QuoteTotals.populateNGBSEntitlementTotals(new Quote(Id = paramsData.quoteId));
            } else if (paramsData.action == 'delete') {
                deleteQlis(paramsData);
            } else if (paramsData.action == 'crop') {
                QuoteLineItemHelper.cropQuoteLineItems(paramsData.quoteId, paramsData.catalogIds, paramsData.isProServChangeOrderOpp);
            } else if (paramsData.action == 'updateTargetPriceInfo') {
                updateTargetPriceInfo(paramsData.quoteId, paramsData.items);
            } else if (paramsData.action == 'copyQuoteLineItems') {
                QuoteLineItemHelper.copyQuoteLineItemsToMasterQuote((Id) paramsData.quoteId);
            } else if (paramsData.action == 'getQuoteLineItemsByQuoteId') {
                List<QuoteLineItem> qliList = QuoteLineItemHelper.getQuoteLineItemsByQuoteId((Id) paramsData.quoteId);
                res.setData('quoteLineItems', qliList);
            } else if (paramsData.action == 'createQuoteLineItemsForChangeOrder') {
                createOneTimeProservQLIForChangeOrder(paramsData.orderId, paramsData.quoteId, paramsData.proServPackage);
            }

        } catch (Exception e) {
            res.error(e);
        }

        RestContext.response.responseBody = Blob.valueOf( JSON.serialize(res) );
    }

    public static Response syncProducts(Id quoteId, List<BillingWrappers.BillingProduct> products) {
        Response res = new Response();
        try {
            /* create map for all catalogId from items */
            Map<String, BillingWrappers.BillingProduct> catalogIdToBillingProduct = new Map<String, BillingWrappers.BillingProduct>();
            for(BillingWrappers.BillingProduct item : products) {
                catalogIdToBillingProduct.put(item.catalogId, item);
            }

            List<PricebookEntry> pbeList = getPbeBasedOnProducts(quoteId, catalogIdToBillingProduct);

            List<Product2> productListToActivate = new List<Product2>();
            Map<String, Map<String, PricebookEntry>> pbeCurrencyMap = new Map<String, Map<String, PricebookEntry>>();
            for(PricebookEntry pbe : pbeList) {

                String catalogId = pbe.Product2.ExtID__c;
                String isoCode = pbe.CurrencyIsoCode;

                /* Activate product */
                if(pbe.Product2.IsActive == false) {
                    pbe.Product2.IsActive = true;
                    productListToActivate.add(new Product2(
                            Id = pbe.Product2.Id,
                            IsActive = true
                    ));
                }

                if (pbeCurrencyMap.get(catalogId) == null) {
                    pbeCurrencyMap.put(catalogId, new Map<String, PricebookEntry>());
                }
                pbeCurrencyMap.get(catalogId).put(isoCode, pbe);

                BillingWrappers.BillingProduct product = catalogIdToBillingProduct.get(pbe.Product2.ExtID__c);
                if( product.currencyIsoCode == pbe.CurrencyIsoCode ) {
                    catalogIdToPBE.put(pbe.Product2.ExtID__c, pbe);
                    catalogIdToProduct.put(pbe.Product2.ExtID__c, pbe.Product2);
                }
            }
            update productListToActivate;

            /* Feature Toggle */
            Boolean allowPopulateGOA = Feature_Toggle__c.getInstance().GOA_Population_from_NGBS__c;

            List<String> incorrectGOAProducts = new List<String>();

            /* product logic */
            List<Product2> productsToInsert = new List<Product2>();
            List<Product2> productsToUpdate = new List<Product2>();
            for (BillingWrappers.BillingProduct product : products) {

                /* GOA */
                Boolean isValidGOA = isValidGOA(product.goa);
                Boolean isUpdateGOA = allowPopulateGOA && isValidGOA;
                if (allowPopulateGOA && !isValidGOA) {
                    incorrectGOAProducts.add(product.name);
                }

                Product2 prod;
                /* Create new */
                if( catalogIdToPBE.get(product.catalogId) == null ) {
                    prod = createProduct(product, isUpdateGOA);
                    productsToInsert.add(prod);
                /* Update */
                } else {
                    prod = catalogIdToProduct.get(product.catalogId);
                    prod = updateProduct(prod, product, isUpdateGOA);
                    productsToUpdate.add(prod);
                }
            }

            /* goa warning */
            if (!incorrectGOAProducts.isEmpty()) {
                res.warning('Following products has incorrect GOA in NGBS: ' + String.join(incorrectGOAProducts, ', '));
            }

            List<Product2> productsToUpsert = new List<Product2>();
            productsToUpsert.addAll(productsToInsert);
            productsToUpsert.addAll(productsToUpdate);

            //Remove this line after E2EStaging/UAT refresh
            fixArchivedProductForInsert(productsToUpsert);

            upsert productsToUpsert ExtID__c;

            /*  pbe logic */
            PricebookEntry pbeStd;
            List<PricebookEntry> pbeStdToInsert = new List<PricebookEntry>();
            for(Product2 productToInsert : productsToInsert) {
                for(String currencyValue : currencyList) {
                    String catalogId = productToInsert.ExtID__c;

                    if( pbeCurrencyMap.get(catalogId) != null &&
                        pbeCurrencyMap.get(catalogId).get(currencyValue) != null ) {
                        continue;
                    }

                    pbeStd = new PricebookEntry(
                        Pricebook2Id = Pricebook2Helper.getStandardPricebookId(),
                        Product2Id = productToInsert.Id,
                        UnitPrice = 0,
                        IsActive = true,
                        UseStandardPrice = false,
                        CurrencyIsoCode = currencyValue
                    );

                    pbeStdToInsert.add(pbeStd);

                    BillingWrappers.BillingProduct product = catalogIdToBillingProduct.get(catalogId);
                    if(currencyValue == product.currencyIsoCode) {
                        catalogIdToPBE.put(product.catalogId, pbeStd);
                    }
                }
            }

            if( pbeStdToInsert.size() > 0 ) {
                insert pbeStdToInsert;
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of products', e);
        }

        return res;
    }

    public static void syncEntitlements(Id quoteId, BillingWrappers.BillingEntitlement[] billingEnts) {
        try {
            if (billingEnts == null) {
                return;
            }

            Quote qt = (
                (List<Quote>) new QuoteSelector()
                    .selectQuoteForQuotingToolItemsSync(quoteId)
                    .executeQuery()
                ).get(0);

            Id accountId = qt.AccountId;

            /* billing entitlements map */
            Map<String, BillingWrappers.BillingEntitlement> catalogIdToBillingEnt = new Map<String, BillingWrappers.BillingEntitlement>();
            for (BillingWrappers.BillingEntitlement billingEnt : billingEnts) {
                catalogIdToBillingEnt.put(billingEnt.elementId, billingEnt);
            }

            // Remove this line after E2E/UAT refresh
            fixArchivedProductForMapping(catalogIdToBillingEnt);

            /* get products */
            Product2[] prodList = [
                SELECT Id, ExtID__c
                FROM Product2
                WHERE ExtID__c IN : catalogIdToBillingEnt.keySet()
            ];

            /* product map */
            Map<String, Product2> catalogIdToProduct = new Map<String, Product2>();
            for (Product2 prod : prodList) {
                catalogIdToProduct.put(prod.ExtID__c, prod);
            }

            Entitlement__c[] ents = createBillingEntitlements(accountId, qt, catalogIdToProduct, billingEnts);
            insert ents;

            Id primaryLicenseProductId = findPrimaryLicenseProductId(billingEnts, catalogIdToProduct);
            Id primaryLicenseEntitlementId = findPrimaryLicenseEntitlementId(primaryLicenseProductId, ents);

            if (primaryLicenseEntitlementId != null && qt.CurrentService__c != primaryLicenseEntitlementId) {

                qt.CurrentService__c = primaryLicenseEntitlementId;
                update qt;

            } else {

                List<Entitlement__c> reselectedEntitlements = (List<Entitlement__c>) new EntitlementSelector()
                    .selectEntitlementsForSync(qt.Id)
                    .executeQuery();

                if (QuoteHelper.setServiceEntitlementOnQuote(qt, accountId, reselectedEntitlements)) {
                    update qt;
                }
            }

        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of entitlements', e);
        }
    }

    public static List<QuoteLineItem> insertQuoteLineItems(
        Id quoteId,
        BillingWrappers.CartItem[] items
    ) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();

        try {
            result = QuoteLineItemHelper.upsertQuoteLineItems(quoteId, items);
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of quote line items ' + '('+e.getMessage()+')', e);
        }

        return result;
    }

    public static Map<String, List<QuoteLineItem>> upsertTechnicalQuoteLineItems(
        Id masterQuoteId,
        Map<String, BillingWrappers.CartItem[]> itemsByServicesMap
    ) {
        Map<String, List<QuoteLineItem>> result = new Map<String, List<QuoteLineItem>>();

        try {
            result = QuoteLineItemHelper.upsertTechnicalQuoteLineItems(masterQuoteId, itemsByServicesMap);
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of quote line items ' + '('+e.getMessage()+')', e);
        }

        return result;
    }

    public static Map<String, List<QuoteLineItem>> upsertTechnicalQuoteLineItemsUB(
        Id masterQuoteId,
        Map<String, BillingWrappers.CartItem[]> itemsByServicesMap
    ) {
        Map<String, List<QuoteLineItem>> result = new Map<String, List<QuoteLineItem>>();

        try {
            result = QuoteLineItemHelper.upsertTechnicalQuoteLineItemsUB(masterQuoteId, itemsByServicesMap);
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of quote line items ' + '('+e.getMessage()+')', e);
        }

        return result;
    }

    private static List<PricebookEntry> getPbeBasedOnProducts(
        Id quoteId,
        Map<String,BillingWrappers.BillingProduct> catalogIdToProduct
    ) {
        Quote currentQuote = (
            (List<Quote>) new QuoteSelector()
                .selectQuoteForQuotingToolItemsSync(quoteId)
                .executeQuery()
            ).get(0);

        return new PricebookEntrySelector()
            .getQuotingToolSyncPBEs(new List<Object>{
                currentQuote.Pricebook2Id,
                catalogIdToProduct.keySet(),
                currencyList
            })
            .executeQuery();
    }

    private static Product2 updateProduct(Product2 prod, BillingWrappers.BillingProduct product, Boolean allowPopulateGOA) {
        /* GOA */
        if (allowPopulateGOA) {
            prod.GOA_Group_V3__c = product.goa;
        }

        /* Family & Feature */
        if (String.isBlank(prod.Family) || prod.Feature__c == null) {
            Map<String,String> mappedValues = populateTechnicalField(product.categoryCode);

            prod.Family = product.itemType == TAX
                            ? Product2Helper.FAMILY_TAXES
                            : mappedValues.get('Family__c');

            prod.Feature__c = mappedValues.get('Feature__c') != null
                                ? Decimal.valueOf(mappedValues.get('Feature__c'))
                                : null;
        }

        if (String.isBlank(prod.Billing_Type__c)) {
            prod.Billing_Type__c = product.billingType;
        }

        if (String.isBlank(prod.CategoryCode__c)) {
            prod.CategoryCode__c = product.categoryCode;
        }

        if (String.isBlank(prod.CategoryName__c)) {
            prod.CategoryName__c = product.categoryName;
        }

        if (String.isBlank(prod.ServiceCategory__c)) {
            prod.ServiceCategory__c = product.serviceCategory;
        }

        prod.UpsellType__c = product.upsellType;
        prod.InitialOrderType__c = product.initialOrderType;
        prod.ShippingType__c = product.shippingType;
        prod.DownsellType__c = product.downsellType;
        prod.LicenseGroup__c = (!String.isBlank(product.licenseGroup) ? product.licenseGroup : prod.LicenseGroup__c);
        prod.Group__c = product.quotingGroup;
        prod.Subgroup__c = product.quotingSubGroup;
        prod.Description = product.displayName;
        prod.SupportType__c = product.supportType;
        
        return prod;
    }

    private static Product2 createProduct(BillingWrappers.BillingProduct product, Boolean allowPopulateGOA) {
        // Get values for feature and family fields for cartItem
        Map<String,String> mappedValues = populateTechnicalField(product.categoryCode);
        Product2 prod = new Product2(
            ExtID__c        = product.catalogId,
            Name            = product.name,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            IsActive        = true,
            Family          = product.itemType == TAX
                                ? Product2Helper.FAMILY_TAXES
                                : mappedValues.get('Family__c'),
            GOA_Group_V3__c = allowPopulateGOA
                                ? product.goa
                                : null,
            Feature__c      = mappedValues.get('Feature__c') != null
                                ? Decimal.valueOf(mappedValues.get('Feature__c'))
                                : null,
            Billing_Type__c = product.billingType,
            Group__c = product.quotingGroup,
            Subgroup__c = product.quotingSubGroup,
            CategoryName__c = product.categoryName,
            ServiceCategory__c = product.serviceCategory,
            CategoryCode__c = product.categoryCode,
            LicenseGroup__c = product.licenseGroup,
            Description = product.displayName,
            UpsellType__c = product.upsellType,
            InitialOrderType__c = product.initialOrderType,
            ShippingType__c = product.shippingType,
            SupportType__c = product.supportType,
            DownsellType__c = product.downsellType
        );
        return prod;
    }

    public static List<QuoteLineItem> deleteQlis (BillingWrappers.Params paramsData) {
        return QuoteLineItemHelper.deleteQuoteLineItems(paramsData.quoteId, paramsData.items);
    }

    public static Map<String,String> populateTechnicalField(String categoryCode) {
        Map<String,String> resultMap = new Map<String,String>{'Feature__c' => null, 'Family__c' => null};

        List<NGBS_New_Products_Mapping__c> productMapping = NGBS_New_Products_Mapping__c.getAll().values();
        for (NGBS_New_Products_Mapping__c item : productMapping) {
            if (item.Category_Code__c == categoryCode) {
                resultMap.put('Feature__c', String.valueOf(item.Feature__c));
                resultMap.put('Family__c', item.Family__c);
            }
        }
        return resultMap;
    }

    @testVisible
    private static Id findPrimaryLicenseProductId(
        List<BillingWrappers.BillingEntitlement> billingEnts,
        Map<String, Product2> catalogIdToProduct
    ) {

        if (billingEnts == null || billingEnts.isEmpty() || catalogIdToProduct == null || catalogIdToProduct.isEmpty()) {
            return null;
        }

        Map<Id, BillingWrappers.BillingEntitlement> productIdToBillingEntitlementMap = new Map<Id, BillingWrappers.BillingEntitlement>();
        for (BillingWrappers.BillingEntitlement billingEnt : billingEnts) {
            Id productId = catalogIdToProduct.get(billingEnt.elementId).Id;
            productIdToBillingEntitlementMap.put(productId, billingEnt);
        }

        Id primaryLicenseProductId;
        for (Id productId : productIdToBillingEntitlementMap.keySet()) {
            BillingWrappers.BillingEntitlement billingEntl = productIdToBillingEntitlementMap.get(productId);
            Boolean isPrimaryLicense = billingEntl != null && billingEntl.isPrimaryLicenseType != null && billingEntl.isPrimaryLicenseType;
            if (isPrimaryLicense) {
                primaryLicenseProductId = productId;
            }
        }

        return primaryLicenseProductId;
    }

    @testVisible
    private static Id findPrimaryLicenseEntitlementId(
        Id primaryLicenseProductId,
        List<Entitlement__c> entitlementList
    ) {

        if (primaryLicenseProductId == null || entitlementList == null || entitlementList.isEmpty()) {
            return null;
        }

        Id primaryLicenseEntitlementId;
        for (Entitlement__c entl : entitlementList) {
            if (entl.Product__c == primaryLicenseProductId) {
                primaryLicenseEntitlementId = entl.Id;
                break;
            }
        }

        return primaryLicenseEntitlementId;
    }

    public static Entitlement__c[] createBillingEntitlements(
        Id accountId,
        Quote qt,
        Map<String, Product2> catalogIdToProduct,
        BillingWrappers.BillingEntitlement[] billingEnts
    ) {
        Entitlement__c[] entitlements = new List<Entitlement__c>();

        for (BillingWrappers.BillingEntitlement billingEnt : billingEnts) {
            Id productId = catalogIdToProduct.get(billingEnt.elementId).Id;
            entitlements.add(
                createBillingEntitlement(accountId, qt, productId, billingEnt)
            );
        }

        return entitlements;
    }

    public static Entitlement__c createBillingEntitlement(
        Id accountId,
        Quote qt,
        Id productId,
        BillingWrappers.BillingEntitlement ent
    ) {
        return new Entitlement__c(
            Account__c = accountId,
            Quote__c = qt.Id,
            Product__c = productId,

            Name = ent.name.abbreviate(80),
            Quantity__c = ent.quantity,
            Price__c = ent.unitPrice,
            ChargeTerm__c = ent.duration,
            Display_Name__c = ent.displayName,

            Discount__c = ent.discount.value.setScale(2, RoundingMode.HALF_UP),
            Discount_Type__c = ent.discount.type,

            PackageCatalogId__c = String.valueOf(ent.billingPackage.catalogId),
            PackageVersion__c = String.valueOf(ent.billingPackage.version),
            PackageOfferType__c = String.valueOf(ent.billingPackage.offerType),
            PackageDuration__c = String.valueOf(ent.billingPackage.masterDuration),

            Active__c = true,
            Sort_Order__c = ent.sortOrder,
            CurrencyIsoCode = ent.billingPackage.currencyCode,

            PartnerConfig__c = ent.partnerConfig
        );
    }

    public static List<QuoteLineItem> getQuoteLineItems(
        String quoteId,
        Set<Id> quoteLineItemIds
    ) {
        return QuoteLineItemHelper.getQuoteLineItems(quoteId, new List<Id>(quoteLineItemIds));
    }

    private static Boolean isValidGOA(String goaStr) {
        Boolean result = true;

        try {
            if (String.isNotBlank(goaStr)) {
                BillingWrappers.GOA goa = (BillingWrappers.GOA) JSON.deserialize(goaStr, BillingWrappers.GOA.class);
                result = goa.regular != null && goa.contracted != null;
            }
        } catch (Exception e) {
            result = false;
        }

        return result;
    }

    // This code is to be removed after E2EStaging/UAT refresh
    private static void fixArchivedProductForInsert(List<Product2> products) {
        for (Product2 prod : products) {
            if (prod.ExtId__c == 'LC_SH_86') {
                prod.ExtId__c += '_temp';
            }
        }
    }

    private static void fixArchivedProductForMapping(Map<String, Object> qliServiceMap) {
        for (String key : qliServiceMAp.keySet()) {
            if (key == 'LC_SH_86') {
                qliServiceMap.put('LC_SH_86_temp', qliServiceMap.get(key));
                qliServiceMap.remove(key);
            }
        }
    }

    private static void updateTargetPriceInfo(Id quoteId, BillingWrappers.CartItem[] items) {
        try {
            Map<Id, QuoteLineItem> idToQli = new Map<Id, QuoteLineItem>((List<QuoteLineItem>)new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quoteId)
                .executeQuery());

            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            for (BillingWrappers.CartItem cartItem: items) {
                QuoteLineItem qli = idToQli.get(cartItem.id);
                String shortPackageInfo = BillingWrappers.getShortQLIPackageInfo(cartItem.packageInfo);
                qli.PackageInfo__c = cartItem.packageInfo;
                qli.Package_Info_QLI__c = cartItem.packageInfo;
                qli.Package_Info__c = shortPackageInfo;
                qlisToUpdate.add(qli);
            }

            if (!qlisToUpdate.isEmpty()) {
                update qlisToUpdate;
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during synchronization of quote line items ' + '('+ e.getMessage() +')', e);
        }
    }

    private static void createOneTimeProservQLIForChangeOrder(Id orderId, Id quoteId, BillingWrappers.NGBSAccountPackage proServPackage) {
        try {
            Map<String, OrderItem> productLicToOrderItemMap = new Map<String, OrderItem>();
            Map<String, Decimal> productLicToDeliveredQuantityMap = new Map<String, Decimal>();
            List<Id> quoteLineItemIds = new List<Id>();
            List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();

            List<OrderItem> orderItems = (List<OrderItem>) new OrderItemSelector()
                .selectOrderItemsByOrderIds(new List<Object>{ new Set<Id>{orderId} })
                .executeQuery();

            List<SuborderLineItem__c> billedSuborderLineItems = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
                .selectSuborderLineItemsForProServ()
                .setCondition('Suborder__r.Order__c = :bind0 AND Suborder__r.Status__c = :bind1')
                .setQueryBindings(new List<Object>{orderId, SuborderHelper.STATUS_BILLED})
                .executeQuery();
            
            for (OrderItem orderItem : orderItems) {
                if (orderItem.QuoteLineItem.Item_Type__c != TAX) {
                    String productLicId = orderItem.QuoteLineItem.Product_Lic_Id__c;
                    productLicToOrderItemMap.put(productLicId, orderItem);
                    quoteLineItemIds.add(orderItem.QuoteLineItem.Id);
                }
            }

            for (SuborderLineItem__c suborderLineItem: billedSuborderLineItems) {
                String productLicId = suborderLineItem.SalesAgreementLineItem__r.Product_Lic_Id__c;
                if (productLicToDeliveredQuantityMap.containsKey(productLicId)) {
                    Decimal sumDeliveredQuantity = productLicToDeliveredQuantityMap.get(productLicId) + suborderLineItem.Quantity__c;
                    productLicToDeliveredQuantityMap.put(productLicId, sumDeliveredQuantity);
                } else {
                    productLicToDeliveredQuantityMap.put(productLicId, suborderLineItem.Quantity__c);
                }
            }

            List<QuoteLineItem> selectedQuoteLineItems = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByIds(quoteLineItemIds)
                .executeQuery();
            
            Map<String,Entitlement__c> productLicIdToEntitlmentMap = new  Map<String,Entitlement__c>();
            for (QuoteLineItem qli: selectedQuoteLineItems) {
                String productLicId = qli.Product_Lic_Id__c;
                OrderItem psOrderItem = productLicToOrderItemMap.get(productLicId);
                productLicIdToEntitlmentMap.put(productLicId, new Entitlement__c(
                    Account__c = qli.Quote.Opportunity.AccountId,
                    Quote__c = quoteId,
                    Product__c = qli.Product2Id,
                    Quantity__c = psOrderItem.Quantity,
                    Price__c = qli.UnitPrice,
                    ChargeTerm__c = qli.ChargeTerm__c,
                    Discount__c = qli.Discount_number__c,
                    Discount_Type__c = qli.Discount_type__c,
                    Active__c = true,
                    CurrencyIsoCode = qli.CurrencyIsoCode,
                    Name = qli.Product2.Name,
                    PackageCatalogId__c = proServPackage.catalogId,
                    PackageVersion__c = proServPackage.version
                ));
            }

            if (!productLicIdToEntitlmentMap.values().isEmpty()) {
                insert productLicIdToEntitlmentMap.values();
            }

            for (QuoteLineItem quoteLineItem: selectedQuoteLineItems) {
                String productLicId = quoteLineItem.Product_Lic_Id__c;
                OrderItem psOrderItem = productLicToOrderItemMap.get(productLicId);
                QuoteLineItem newQuoteLineItem = quoteLineItem.clone(false);
                newQuoteLineItem.Entitlement__c = productLicIdToEntitlmentMap.get(productLicId).Id;
                newQuoteLineItem.QuoteId = quoteId;
                newQuoteLineItem.NewQuantity__c = psOrderItem.Quantity;
                newQuoteLineItem.Quantity = 1;
                newQuoteLineItem.Zero_Quantity__c = true;
                newQuoteLineItem.DeliveredQuantity__c = psOrderItem.Quantity - psOrderItem.Not_Shipped_Phones__c;
                if (productLicToDeliveredQuantityMap.containsKey(productLicId)) {
                    newQuoteLineItem.DeliveredQuantity__c += productLicToDeliveredQuantityMap.get(productLicId);
                }
                quoteLineItemsToInsert.add(newQuoteLineItem);
            }

            if (!quoteLineItemsToInsert.isEmpty()) {
                insert quoteLineItemsToInsert;
            }
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Error occurred during creation of QLI for change order ' + '('+ e.getMessage() +')', e);
        }
    }
}