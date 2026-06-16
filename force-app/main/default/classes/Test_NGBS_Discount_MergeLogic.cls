@isTest
public class Test_NGBS_Discount_MergeLogic {

    public static final String CATALOG_APPLICATION_TYPE = 'catalog';
    public static final String CATEGORY_APPLICATION_TYPE = 'category';

    public static final Decimal DEFAULT_DISCOUNT = 10;
    public static final Decimal DEFAULT_PRICE = 100;
    public static final Decimal DEFAULT_QUANTITY = 5;

    public class DiscountDetail {
        public String catalogOrCategoryId;
        public String applicationType;
        public String billingType;
        public Decimal discountNumber;
        public String discountType;
    
        public DiscountDetail(String catalogOrCategoryId, String applicationType, String billingType, Decimal discountNumber, String discountType) {
            this.catalogOrCategoryId = catalogOrCategoryId;
            this.applicationType = applicationType;
            this.billingType = billingType;
            this.discountNumber = discountNumber;
            this.discountType = discountType;
        }
    }

    private static BillingWrappers.QuotePackageInfo getDefaultQuotePackageInfo() {
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.duration = Product2Helper.CHARGE_TERM_MONTHLY;
        return pInfo;
    }

    public static List<NGBS_Discount.DiscountItemWrapper> getDiscountItemWrappersFromDiscountDetails(List<DiscountDetail> discountItems) {
        List<NGBS_Discount.DiscountItemWrapper> diwList = new List<NGBS_Discount.DiscountItemWrapper>();

        for (DiscountDetail dd : discountItems) {
            NGBS_Discount.DiscountItemWrapper diw = new NGBS_Discount.DiscountItemWrapper(
                dd.catalogOrCategoryId,
                dd.catalogOrCategoryId,
                Product2Helper.CHARGE_TERM_MONTHLY,
                new NGBS_Discount.DiscountValue(dd.discountNumber, dd.discountType, true)
            );
            diw.applicableType = dd.catalogOrCategoryId.split('_').size() > 1
                ? NGBS_Discount.BILLING_CATALOG_ID_TYPE
                : NGBS_Discount.BILLING_CATEGORY_ID_TYPE;
            diwList.add(diw);
        }
        return diwList;
    }

    public static Quote buildQuoteWithQlisFromDiscountDetails(
        Map<String, List<DiscountDetail>> discountDetailsMap,
        List<String> catalogIdsForQLIsCreationFromCategoryDiscounts
    ) {
        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.sObjectType),
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{getDefaultQuotePackageInfo()}),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        List<String> sortedKeys = new List<String>(discountDetailsMap.keySet());
        sortedKeys.sort();
        List<String> reversedKeys = new List<String>();
        for (Integer i = sortedKeys.size() - 1; i >= 0; i--) {
            reversedKeys.add(sortedKeys[i]);
        }

        Integer idIter = 0;
        Map<String, QuoteLineItem> catalogIdToQLIs = new Map<String, QuoteLineItem>();
        for (String key : reversedKeys) {
            List<DiscountDetail> discountDetails = discountDetailsMap.get(key);

            for (DiscountDetail discountDetail : discountDetails) {
                
                String catalogIdForQLI = null;

                if (discountDetail.applicationType == CATALOG_APPLICATION_TYPE) {
                    catalogIdForQLI = discountDetail.catalogOrCategoryId;
                } else if (discountDetail.applicationType == CATEGORY_APPLICATION_TYPE) {
                    for (String catalogId : catalogIdsForQLIsCreationFromCategoryDiscounts) {
                        String categoryOfCatalog = NGBS_Discount.getCategoryFromCatalogId(catalogId);
                        if (categoryOfCatalog == discountDetail.catalogOrCategoryId) {
                            catalogIdForQLI = catalogId;
                            break;
                        }
                    }
                }

                if (catalogIdForQLI == null || catalogIdToQLIs.get(catalogIdForQLI) != null) {
                    continue;
                }

                Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Product2.Id => getDummyId(Product2.sObjectType, idIter),
                            Product2.Name => catalogIdForQLI + '_name',
                            Product2.ExtID__c => catalogIdForQLI,
                            Product2.Billing_Type__c => discountDetail.billingType
                        }
                    )
                    .build()
                    .getRecord();
                
                Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Entitlement__c.Id => getDummyId(Entitlement__c.sObjectType, idIter),
                        Entitlement__c.Name => product.Name,
                        Entitlement__c.Active__c => true,
                        Entitlement__c.Price__c => DEFAULT_PRICE,
                        Entitlement__c.Discount_Type__c => discountDetail.discountType,
                        Entitlement__c.Discount__c => discountDetail.discountNumber,
                        Entitlement__c.Quantity__c => DEFAULT_QUANTITY,
                        Entitlement__c.Product__c => product.Id,
                        Entitlement__c.ChargeTerm__c => discountDetail.billingType == Product2Helper.BILLING_TYPE_ONE_TIME
                            ? Product2Helper.CHARGE_TERM_ONE_TIME
                            : Product2Helper.CHARGE_TERM_MONTHLY,
                        Entitlement__c.Quote__c => qt.Id
                    })
                    .build()
                    .getRecord();
                
                BillingWrappers.QLIPackageInfo packageInfo =  new BillingWrappers.QLIPackageInfo();
                packageInfo.duration = discountDetail.billingType == BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME
                    ? Product2Helper.CHARGE_TERM_ONE_TIME
                    : Product2Helper.CHARGE_TERM_MONTHLY;
                packageInfo.categoryCode = NGBS_Discount.getCategoryFromCatalogId(product.ExtID__c);
                

                QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => qt.Id,
                            QuoteLineItem.Product2Id => product.Id,
                            QuoteLineItem.Discount_type__c => discountDetail.discountType,
                            QuoteLineItem.Discount_number__c => discountDetail.discountNumber,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.NewQuantity__c => DEFAULT_QUANTITY,
                            QuoteLineItem.Zero_Quantity__c => true,
                            QuoteLineItem.UnitPrice => DEFAULT_PRICE,
                            QuoteLineItem.PackageInfo__c => JSON.serialize(packageInfo),
                            QuoteLineItem.Display_Name__c => product.Name,
                            QuoteLineItem.ChargeTerm__c => discountDetail.billingType == Product2Helper.BILLING_TYPE_ONE_TIME
                                ? Product2Helper.CHARGE_TERM_ONE_TIME
                                : Product2Helper.CHARGE_TERM_MONTHLY,
                            QuoteLineItem.Entitlement__c => ent.Id
                        }
                    )
                    .build()
                    .getRecord();
                qli = (QuoteLineItem) linkParentToChild(qli, product, 'Product2');
                catalogIdToQLIs.put(catalogIdForQLI, qli);

                idIter++;
            }
        }

        if (catalogIdToQLIs.values().isEmpty()) {
            return qt;
        }
        
        return (Quote) putChildRecordsIntoParent(qt, 'QuoteLineItems', catalogIdToQLIs.values());
    }

    private static Id getDummyId(SObjectType sObjectType, Integer idIter) {
        String dummyProductId = String.valueOf(ValueProviderBuilder.provideDummyId(sObjectType, 15).getValue());
        String iString = String.valueOf(idIter);
        String lastTwoChars = iString.length() == 1 ? '0' + iString : iString;
        return Id.valueOf(dummyProductId.substring(0, dummyProductId.length() - 2) + lastTwoChars);
    }

    private static SObject putChildRecordsIntoParent(SObject parentObj, String childRelationshipName, List<SObject> childRecords) {
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

    private static SObject linkParentToChild(SObject childRecord, SObject parentRecord, String childRelationshipName) {
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

    private static List<NGBS_Discount.DiscountTemplateGroup> getNGBSDiscountTemplateGroupsWithProvidedDiscounts(Map<String, List<DiscountDetail>> discountItemsMap) {
        BillingWrappers.QuotePackageInfo pInfo = getDefaultQuotePackageInfo();

        List<BillingWrappers.BillingContract> billingContracts = null;

        List<NGBS_Discount.DiscountTemplateGroup> tempGroups = new List<NGBS_Discount.DiscountTemplateGroup>();
        for (String priority : discountItemsMap.keySet()) {
            tempGroups.add(
                new NGBS_Discount.DiscountTemplateGroup(
                    'test_quote_number',
                    pInfo,
                    getDiscountItemWrappersFromDiscountDetails(discountItemsMap.get(priority)),
                    priority,
                    billingContracts,
                    new Map<String, String>()
                )
            );
        }

        return tempGroups;
    }

    private static Map<String, Set<String>> getPriorityToApplicationIdsFromDTG(List<NGBS_Discount.DiscountTemplateGroup> dtgList) {
        Map<String, Set<String>> priorityToApplicationIdsFromDTG = new Map<String, Set<String>>();
        
        for(NGBS_Discount.DiscountTemplateGroup dtg : dtgList) {
            for(NGBS_Discount.DiscountTemplate dt : dtg.discountTemplates) {            
                if (!priorityToApplicationIdsFromDTG.containsKey(dtg.priority)) {
                    priorityToApplicationIdsFromDTG.put(dtg.priority, new Set<String>());
                }
                priorityToApplicationIdsFromDTG.get(dtg.priority).add(dt.applicableTo.id);
            }
        }
        return priorityToApplicationIdsFromDTG;
    }

    private static Set<String> getPrioritiesFromDTGs(List<NGBS_Discount.DiscountTemplateGroup> dtgList) {
        Set<String> priorities = new Set<String>();
        for(NGBS_Discount.DiscountTemplateGroup dtg : dtgList) {
            priorities.add(dtg.priority);
        }
        return priorities;
    }

    @isTest
    static void testGetMergedDtgList() {

        Map<String, List<DiscountDetail>> discountDetailsMap = new Map<String, List<DiscountDetail>>{
            'A' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_1', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'B' => new List<DiscountDetail>{
                new DiscountDetail('HDR', CATEGORY_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'C' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_2', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE),
                new DiscountDetail('LC_HDRD_1', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'D' => new List<DiscountDetail>{
                new DiscountDetail('HDRD', CATEGORY_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'E' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_3', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE),
                new DiscountDetail('LC_HDRD_2', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            }
        };

        List<String> catalogIdsForQLIsCreationFromCategoryDiscounts = new List<String>{
            'LC_HDRD_3' // catalog id from HDRD category for quote line item creation
        };

        List<NGBS_Discount.DiscountTemplateGroup> currentNGBSGroups = getNGBSDiscountTemplateGroupsWithProvidedDiscounts(discountDetailsMap);

        // create QLIs in accordance with discounts as in the Quoting Tool
        Quote qt = buildQuoteWithQlisFromDiscountDetails(discountDetailsMap, catalogIdsForQLIsCreationFromCategoryDiscounts);
        List<QuoteLineItem> qliList = qt.quotelineitems;

        // update LC_HDRD_2 qli with 90% discount
        for(QuoteLineItem qli : qliList) {
            if (qli.Display_Name__c.contains('LC_HDRD_2')) {
                qli.Discount_number__c = 90;
            }
        }
            
        Test.startTest();
            List<NGBS_Discount.DiscountTemplateGroup> mergedDTGs = NGBS_Discount.getMergedDtgList(qt, null, null, currentNGBSGroups, currentNGBSGroups);
        Test.stopTest();

        Set<String> priorities = getPrioritiesFromDTGs(mergedDTGs);
        Map<String, Set<String>> priorityToApplicationIdsFromDTG = getPriorityToApplicationIdsFromDTG(mergedDTGs);
        
        Assert.areEqual(new Set<String>{'F', 'G', 'H'}, priorities, 'mergedDTGs must have 3 DTGs with such new priorities');
        Assert.areEqual(
            new Set<String>{'LC_HDR_1'}, 
            priorityToApplicationIdsFromDTG.get('F'), 
            'F priority should only contain discount for the expected license'
        );
        Assert.areEqual(
            new Set<String>{'HDR'}, 
            priorityToApplicationIdsFromDTG.get('G'), 
            'G priority should only contain discount for the expected category'
        );
        Assert.areEqual(
            new Set<String>{'LC_HDR_2', 'LC_HDR_3', 'LC_HDRD_1', 'LC_HDRD_2', 'LC_HDRD_3'}, 
            priorityToApplicationIdsFromDTG.get('H'), 
            'H priority should only contain discount for the expected licenses'
        );
    }

    @isTest
    static void testGetMergedDtgListWhenThereAreCategoryDiscountAndTwoLicenseDiscounts() {

        Map<String, List<DiscountDetail>> discountDetailsMap = new Map<String, List<DiscountDetail>>{
            'A' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_1', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'B' => new List<DiscountDetail>{
                new DiscountDetail('HDR', CATEGORY_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            },
            'C' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_2', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            }
        };

        List<NGBS_Discount.DiscountTemplateGroup> currentNGBSGroups = getNGBSDiscountTemplateGroupsWithProvidedDiscounts(discountDetailsMap);

        // create QLIs in accordance with discounts as in the Quoting Tool
        Quote qt = buildQuoteWithQlisFromDiscountDetails(discountDetailsMap, new List<String>());
        List<QuoteLineItem> qliList = qt.quotelineitems;

        // update LC_HDR_2 qli with 90% discount
        for(QuoteLineItem qli : qliList) {
            if (qli.Display_Name__c.contains('LC_HDR_2')) {
                qli.Discount_number__c = 90;
            }
        }
            
        Test.startTest();
            List<NGBS_Discount.DiscountTemplateGroup> mergedDTGs = NGBS_Discount.getMergedDtgList(qt, null, null, currentNGBSGroups, currentNGBSGroups);
        Test.stopTest();

        Set<String> priorities = getPrioritiesFromDTGs(mergedDTGs);
        Map<String, Set<String>> priorityToApplicationIdsFromDTG = getPriorityToApplicationIdsFromDTG(mergedDTGs);
        
        Assert.areEqual(new Set<String>{'D'}, priorities, 'there should be only one group as Category discount should be removed and LC_HDR_1 should be replaced');
        Assert.areEqual(
            new Set<String>{'LC_HDR_1', 'LC_HDR_2'}, 
            priorityToApplicationIdsFromDTG.get('D'), 
            'D priority should contain discounts for LC_HDR_2 as it was updated in QLI and LC_HDR_1 that is equal to HDR category'
        );
    }

    @isTest
    static void testHasNonSFDCPromoCode() {
        String oppId = String.valueOf(ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue());
        Datetime dtn = Datetime.now();
        String promoCode = oppId + dtn.format(BillingWrappers.DATE_TIME_FORMAT);

        Test.startTest();
            Boolean result = NGBS_Discount.hasNonSFDCPromoCode(promoCode);
        Test.stopTest();

        Assert.areEqual(false, result, 'hasNonSFDCPromoCode should return false as there is opp id in promo code');
    }

    @isTest
    static void testShouldNewDiscountBeCreatedFromQliWithoutActiveDiscount() {
        Map<String, List<DiscountDetail>> discountDetailsMap = new Map<String, List<DiscountDetail>>{
            'A' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_1', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            }
        };
        Quote qt = buildQuoteWithQlisFromDiscountDetails(discountDetailsMap, new List<String>());

        Test.startTest();
            Boolean result = NGBS_Discount.shouldNewDiscountBeCreatedFromQLI(
                qt.quotelineitems[0],
                DEFAULT_DISCOUNT,
                null,
                Product2Helper.CHARGE_TERM_MONTHLY,
                new List<String>(),
                true
            );
        Test.stopTest();

        Assert.areEqual(true, result, 'if there is no active NGBS discount for the QLI, new discount should be created');
    }

    @isTest
    static void testShouldNewDiscountBeCreatedFromQliMergeLogic() {
        Map<String, List<DiscountDetail>> discountDetailsMap = new Map<String, List<DiscountDetail>>{
            'A' => new List<DiscountDetail>{
                new DiscountDetail('LC_HDR_1', CATALOG_APPLICATION_TYPE, Product2Helper.CHARGE_TERM_MONTHLY, DEFAULT_DISCOUNT, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
            }
        };
        List<NGBS_Discount.DiscountTemplateGroup> currentNGBSGroups = getNGBSDiscountTemplateGroupsWithProvidedDiscounts(discountDetailsMap);

        Quote qt = buildQuoteWithQlisFromDiscountDetails(discountDetailsMap, new List<String>());
        qt.quotelineitems[0].Entitlement__c = null;

        Test.startTest();
            Boolean result = NGBS_Discount.shouldNewDiscountBeCreatedFromQLI(
                qt.quotelineitems[0],
                DEFAULT_DISCOUNT,
                currentNGBSGroups[0].discountTemplates[0],
                Product2Helper.CHARGE_TERM_MONTHLY,
                new List<String>(),
                true
            );
        Test.stopTest();

        Assert.areEqual(true, result, 'if QLI was added as a new item to the Quote, new discount should be created');
    }
}