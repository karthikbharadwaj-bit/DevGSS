public class NGBSOrderRequest {

    public static final String BILLING_STATE_PURCHASED = 'Purchased';
    public static final String TECHNICAL_LICENSE_DL_75 = 'LC_DL_75';
    public static final String TECHNICAL_LICENSE_DLI_282 = 'LC_DLI_282';
    public static final String TECHNICAL_LICENSE_BYOC_942 = 'LC_DL-BYOC_942';
    public static final String TECHNICAL_LICENSE_FDL_401 = 'LC_FDL_401';
    public static final String TECHNICAL_LICENSE_DL_CC_735 = 'LC_DL-CC_735';
    public static final String TECHNICAL_LICENSE_CRF = 'LC_CRF_51';
    public static final String TECHNICAL_LICENSE_E911 = 'LC_E911_52';
    public static final String TECHNICAL_LICENSE_E911_CC = 'LC_E911-CC_740';
    public static final String TECHNICAL_LICENSE_CRF_CC = 'LC_CRF-CC_739';
    public static final String TWO_DAYS_SHIPPING_METHOD = '2 Day';
    public static final String BILLING_TWO_DAYS_SHIPPING_METHOD = 'TWO_DAYS';
    public static final String RENEWAL_DAY = 'RenewalDay';
    public static final String IMMEDIATE = 'Immediate';
    public static final String TRUE_AND_FALSE = 'TrueAndFalse';
    public static final String PRODUCT_LINE_RC = 'RC';
    public static final List<String> TECHNICAL_SUBLICENSES = new List<String> {TECHNICAL_LICENSE_CRF, TECHNICAL_LICENSE_CRF_CC, TECHNICAL_LICENSE_E911, TECHNICAL_LICENSE_E911_CC};
    public static final List<String> TECHNICAL_LICENSES = new List<String> {TECHNICAL_LICENSE_DL_75, TECHNICAL_LICENSE_FDL_401, TECHNICAL_LICENSE_DL_CC_735, TECHNICAL_LICENSE_BYOC_942};
    public static final List<String> RC_US_BRANDS = new List<String> {OpportunityHelper.BRAND_RINGCENTRAL, OpportunityHelper.BRAND_RINGCENTRAL_CA};
    public static Map<String, BillingWrappers.BillingInfoSummaryLicense> NGBSLicensesMap = new Map<String, BillingWrappers.BillingInfoSummaryLicense>();
    public static List<String> bypassLicenses = new List<String>();
    public static Map<String, BillingWrappers.QLIPackageInfo> allQLIPackageInfo = new Map<String, BillingWrappers.QLIPackageInfo>();
    public static Map<String, String> NGBSLicensesExceptionsMap = new Map<String, String>();
    public static Map<String, LicensesToAdd> ITEMS_TO_ADD = new Map<String, LicensesToAdd>();
    public static Response ALL_MAPS = new Response();
    public static final List<String> ORDER_API_BATCH_FALSE_LICENSES = NGBS_Order_API_Settings__c.getInstance().Batch_False_Licenses_Codes__c.split(';');

    public NGBSOrderRequest() { }

    public class OrderRequestInfo {
        public String salesOrderId;
        public LicensesToAdd[] itemsToAdd;
        public LicensesToBulkRemove[] bulkItemsToRemove;
        public LicensesToReplace[] itemsToReplace;
        public LicensesToUpdate[] itemsToUpdate;
        public LicensesToActivate[] itemsToActivate;
        public LicensesToAppend[] itemsToAppend;
        public OrderInfo orderInfo;
        public String catalogId;
        public String version;
        public String newDuration;
        public String duration;

        public OrderRequestInfo() {}

        public OrderRequestInfo (
            Quote qt,
            Set<Id> qliIds,
            Map<String, String> exceptionMap,
            Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap,
            String billingId,
            String packageId,
            List<String> bypassLicenseRestrictions
        ) {

            List<CustomAddressAssignments__c> addresses = new List<CustomAddressAssignments__c>();
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            if (licenseMap != null && !licenseMap.isEmpty()) {
                NGBSLicensesMap = licenseMap;
            }
            if (!exceptionMap.isEmpty()) {
                NGBSLicensesExceptionsMap = exceptionMap;
            }
            if (!bypassLicenseRestrictions.isEmpty()) {
                bypassLicenses = bypassLicenseRestrictions;
            }

            if (!qliIds.isEmpty()) {
                addresses = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
                    .selectCAAForShipping(new List<Object> {qliIds})
                    .executeQuery();

                qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsWithCostCenterLineItems(new List<Object>{qliIds})
                    .executeQuery();
                if (!qlis.isEmpty()) {
                    ALL_MAPS = getAllMaps(qlis);
                }
            }
            if (qt.Id != null && !qlis.isEmpty()) {
                this.itemsToAdd = getParentLicensesToAdd();
                if (ALL_MAPS.data.get('hasItemsToAppend') != null &&
                    ALL_MAPS.data.get('itemsToAppend') != null &&
                    (Boolean) ALL_MAPS.data.get('hasItemsToAppend')) {
                    Map<String, BillingWrappers.LicenseRequested> licenseIdMap = getLicenseIdsMap(billingId, packageId, (Set<String>)ALL_MAPS.data.get('itemsToAppend'));
                    this.itemsToAppend = getLicensesToAppend(licenseIdMap);
                } else {
                    this.itemsToAppend = new LicensesToAppend[]{};
                }
                if (this.itemsToAdd.size() > 0) {
                    this.orderInfo = new OrderInfo(this.itemsToAdd, addresses);
                    if (addresses.size() > 0) {
                        String externalIdShipping = 'sf:' + qt.OpportunityId + ':' + qt.Id;
                        this.itemsToAdd = getShippingLicenses(this.itemsToAdd, addresses, externalIdShipping);
                    }
                }

                if (this.itemsToAdd.size() > 0 || this.itemsToAppend.size() > 0) {
                    this.salesOrderId = qt.OpportunityId;
                    updateExternalIds(this.itemsToAdd, this.orderInfo.orderItems);
                }
            }

            this.bulkItemsToRemove = new LicensesToBulkRemove[]{};
            this.itemsToReplace = new LicensesToReplace[]{};
            this.itemsToUpdate = new LicensesToUpdate[]{};
            this.itemsToActivate = new LicensesToActivate[]{};
        }
    }

    public class LicensesToAdd {
        public String catalogId;
        public String path;
        public String externalId;
        public String billingCycleDuration;
        public Integer qty;
        public Boolean batch;
        public String billingState;
        public Long billingCodeId;
        public LicensesToAdd[] subItems;
        public String categoryCode;

        public LicensesToAdd(){
            this.subItems = new LicensesToAdd[]{};
        }

        public LicensesToAdd(QuoteLineItem qli, Cost_Center_Line_Item__c ccli, BillingWrappers.BillingInfoSummaryLicense license, Integer i, Boolean isChild, Boolean isDevice) {
            this.billingCodeId = 0;
            this.catalogId = qli.Product_Lic_Id__c;
            this.externalId = 'sf:' + qli.Quote.OpportunityId + ':' + qli.Id + ':' + i;
            BillingWrappers.QLIPackageInfo qliPackage = allQLIPackageInfo.get(qli.Product_Lic_Id__c);
            this.categoryCode = qliPackage?.categoryCode;
            if (qli.ChargeTerm__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                this.billingCycleDuration = BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME;
            } else {
                this.billingCycleDuration = qli.ChargeTerm__c;
            }

            if (isChild || isDevice) {
                this.batch = false;
                this.qty = 1;
                if (!isChild) {
                    if (ccli.Cost_Center__c != null && ccli.Cost_Center__r.BillingId__c != null) {
                        this.billingCodeId = Long.valueOf(ccli.Cost_Center__r.BillingId__c);
                    }
                }
            } else {
                if (ccli.Quantity__c > 0) {
                    this.qty = Integer.valueOf(ccli.Quantity__c);
                    this.batch = true;
                    this.billingCodeId = Long.valueOf(ccli.Cost_Center__r.BillingId__c);
                } else {
                    this.qty = license != null && qli.NewQuantity__c > license.qty
                        ? Integer.valueOf(qli.NewQuantity__c) - license.qty
                        : license == null
                            ? Integer.valueOf(qli.Quantity)
                            : 0;
                    this.batch = true;
                }
            }

            if (ORDER_API_BATCH_FALSE_LICENSES.contains(qliPackage.CategoryCode)) {
                this.batch = false;
            }
            this.billingState = BILLING_STATE_PURCHASED;
            this.subItems = new LicensesToAdd[]{};
        }
    }

    public class LicensesToBulkRemove {
        public LicensesSelector selector;
        public Integer qty;
        public String removalDelay;
    }

    public class LicensesSelector {
        public LicenseKey[] keys = new LicenseKey[]{};
        public Long billingCodeId;
        public String batch;
    }

    public class LicenseKey {
        public String catalogId;
    }

    public class LicensesToReplace {
        public String externalId;
        public LicensesToAdd replacement;
        public Long billingCodeId;

        public LicensesToReplace() {
            this.externalId = '';
            this.replacement = null;
            this.billingCodeId = 0;
        }
    }

    public class LicensesToUpdate {
        public Integer licenseId;
        public String externalId;
        public String newExternalId;
        public PropsDevices props;

        public LicensesToUpdate() {
            this.licenseId = 0;
            this.externalId = '';
            this.newExternalId = '';
            this.props = null;
        }
    }

    public class LicensesToActivate {
        public String externalId;

        public LicensesToActivate() {
            this.externalId = '';
        }
    }

    public class LicensesToAppend {
        public String licenseId;
        public LicensesToAppendChild[] subItems;

        public LicensesToAppend(BillingWrappers.LicenseRequested lr, QuoteLineItem qli) {
            BillingWrappers.QLIPackageInfo qliPackage = allQLIPackageInfo.get(qli.Product_Lic_Id__c);
            this.licenseId = lr.topLicenseId != null ? lr.topLicenseId : lr.licenseId;
            LicensesToAppendChild ltac = new LicensesToAppendChild();
            ltac.billingCycleDuration = qli.ChargeTerm__c;
            ltac.qty = Integer.valueOf(qli.Quantity);
            ltac.path = qliPackage.categoryPath.split(':')[0]+ '{LicenseTypeId='+lr.licenseTypeId+'}=0:'+qliPackage.CategoryCode+'=1';
            this.subItems = new LicensesToAppendChild[] {ltac};
        }
    }

    public class LicensesToAppendChild {
        public String path;
        public String billingCycleDuration;
        public Integer qty;
    }

    public class OrderInfo {
        public OrderItemsRequest[] orderItems;

        public OrderInfo(LicensesToAdd[] itemsToAdd, List<CustomAddressAssignments__c> addresses) {
            List<OrderItemsRequest> orderItems = new List<OrderItemsRequest>();
            Map<String, String> exceptionMap = new Map<String,String>();
            for (CustomAddressAssignments__c caa : addresses) {
                Integer i = Integer.valueOf(caa.Quantity__c);
                for (LicensesToAdd lta : itemsToAdd) {
                    Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(caa.QuoteLineItem__r.Product2);
                    if (isShippingAvailableForLicense && caa.QuoteLineItem__c == lta.externalId.split(':')[2]) {
                        if (exceptionMap.size() == 0 || exceptionMap.get(lta.externalId) != lta.externalId && i > 0) {
                            OrderItemsRequest oir = new OrderItemsRequest(caa, lta.externalId);
                            orderItems.add(oir);
                            i--;
                            exceptionMap.put(lta.externalId, lta.externalId);
                        }
                    }
                }
            }

            for (LicensesToAdd lta : itemsToAdd) {
                if (ORDER_API_BATCH_FALSE_LICENSES.contains(lta.catalogId.split('_')[1])) {
                    OrderItemsRequest oir = new OrderItemsRequest(new CustomAddressAssignments__c(), lta.externalId);
                    orderItems.add(oir);
                }
            }
            this.orderItems = orderItems;
        }
    }

    public class OrderItemsRequest {
        public String id;
        public PropsDevices props;

        public OrderItemsRequest(CustomAddressAssignments__c caa, String externalId) {
            this.id = externalId;
            if (caa.Id != null) {
                this.props = new PropsDevices(caa);
            } else {
                this.props = new PropsDevices();
            }
        }
    }

    public class PropsDevices {
        public String deviceName;
        public String shippingInfo;

        public PropsDevices (){}
        public PropsDevices (CustomAddressAssignments__c caa) {
            if (caa != null) {
                this.deviceName = caa.QuoteLineItem__r.ParentPackageName__c;
                this.shippingInfo = JSON.serialize(new ShippingInfo(caa));
            }
        }
    }

    public class ShippingInfo {
        public ShippingAddress address;
        public String method;
        public String shippingGroupKey;

        public ShippingInfo (CustomAddressAssignments__c caa) {
            if (caa != null) {
                this.address = new ShippingAddress(caa);
                if (caa.Type__c == TWO_DAYS_SHIPPING_METHOD) {
                    this.method = BILLING_TWO_DAYS_SHIPPING_METHOD;
                } else {
                    this.method = caa.Type__c.toUpperCase();
                }
                this.shippingGroupKey = caa.CustomAddress__r.Country__c + '-' + caa.Type__c + '-' + caa.QuoteLineItem__r.ChargeTerm__c + '-' + this.address.city + '-' + this.address.addressLine1;
            }
        }
    }

    public class ShippingAddress {
        public String presetName;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String county;
        public String zipCode;
        public String country;

        public ShippingAddress (CustomAddressAssignments__c caa) {
            if (caa != null) {
                this.presetName = caa.AttentionTo__c;
                this.addressLine1 = caa.CustomAddress__r.AddressLine__c;
                this.addressLine2 = caa.CustomAddress__r.AdditionalAddressLine__c;
                this.city = caa.CustomAddress__r.City__c;
                this.state = caa.CustomAddress__r.State__c;
                this.county = '';
                this.zipCode = caa.CustomAddress__r.PostalCode__c;
                this.country = caa.CustomAddress__r.Country__c;
            }
        }
    }

    public static LicensesToAdd[] getParentLicensesToAdd() {
        List<LicensesToAdd> result = new List<LicensesToAdd>();
        Map<String, QuoteLineItem> allQLIMap = (Map<String, QuoteLineItem>) ALL_MAPS.data.get('allQLIMap');
        Map<String, String> allQLIMapbyPath = (Map<String, String>) ALL_MAPS.data.get('allQLIMapbyPath');
        Integer rowNum = 1;
        for (QuoteLineItem qliMap : allQLIMap.values()) {
            if (allQLIMapbyPath.get(qliMap.Product_Lic_Id__c).contains(':')) {
                continue;
            }

            if (qliMap.Product_Lic_Id__c == 'LC_SCN_582' && !bypassLicenses.contains(qliMap.Product_Lic_Id__c)) {
                continue;
            }

            BillingWrappers.BillingInfoSummaryLicense license = NGBSLicensesMap.get(qliMap.Product_Lic_Id__c);

            if (isTechnicalLicense(qliMap)) {
                LicensesToAdd lta = new LicensesToAdd(qliMap, new Cost_Center_Line_Item__c(), license, rowNum, false, false);
                result.add(lta);
                rowNum++;
            }

            if (!qliMap.Billing_Codes__r.isEmpty()) {
                if (isDeviceOrNonBatchLicense(qliMap) && !qliMap.Zero_Quantity__c && qliMap.Quantity > 0) {
                    for (Cost_Center_Line_Item__c ccli : qliMap.Billing_Codes__r) {
                        Integer quantityCcli = ccli.Quantity__c != null && ccli.Parent__c == null ? Integer.valueOf(ccli.Quantity__c) : Integer.valueOf(ccli.Parent__r.Quantity__c);
                        for (Integer j = rowNum; j < rowNum + quantityCcli; j++) {
                            LicensesToAdd lta = new LicensesToAdd(qliMap, ccli, license, j, false, true);
                            result.add(lta);
                        }
                        rowNum = rowNum + quantityCcli;
                    }
                } else {
                    if (!isTechnicalLicense(qliMap) && !qliMap.Zero_Quantity__c && qliMap.Quantity > 0) {
                        for (Cost_Center_Line_Item__c ccli : qliMap.Billing_Codes__r) {
                            LicensesToAdd lta = new LicensesToAdd(qliMap, ccli, license, rowNum, false, false);
                            result.add(lta);
                            rowNum++;
                        }
                    }
                }
            } else {
                if (isDeviceOrNonBatchLicense(qliMap) && qliMap.Quantity > 0 && !qliMap.Zero_Quantity__c) {
                    Integer quantity = license != null && qliMap.NewQuantity__c > license.qty ? Integer.valueOf(qliMap.NewQuantity__c) - license.qty : license == null ? Integer.valueOf(qliMap.Quantity) : 0;
                    for (Integer j = rowNum; j < rowNum + quantity; j++) {
                        LicensesToAdd lta = new LicensesToAdd(qliMap, new Cost_Center_Line_Item__c(), license, j, false, true);
                        result.add(lta);
                    }
                    rowNum = rowNum + quantity;
                } else {
                    if (!isTechnicalLicense(qliMap) && qliMap.Quantity > 0 && !qliMap.Zero_Quantity__c) {
                        LicensesToAdd lta = new LicensesToAdd(qliMap, new Cost_Center_Line_Item__c(), license, rowNum, false, false);
                        if (lta.qty > 0) {
                            result.add(lta);
                            rowNum++;
                        }
                    }
                }
            }
        }
        return getChildLicensesToAdd(result, rowNum);
    }

    public static LicensesToAdd[] getChildLicensesToAdd(LicensesToAdd[] parentLicenses, Integer rowNum) {
        LicensesToAdd[] splitParent = new LicensesToAdd[]{};
        Map<String, QuoteLineItem> allQLIMap = (Map<String, QuoteLineItem>) ALL_MAPS.data.get('allQLIMap');
        Map<String, String> allQLIMapbyPath = (Map<String, String>) ALL_MAPS.data.get('allQLIMapbyPath');
        Map<String, List<QuoteLineItem>> childQLIsMap = (Map<String, List<QuoteLineItem>>) ALL_MAPS.data.get('childQLIsMap');
        for (LicensesToAdd parentLTA : parentLicenses) {

            for (QuoteLineItem qli : childQLIsMap.get(parentLTA.catalogId)) {
                if (allQLIMapbyPath.get(qli.Product_Lic_Id__c).split(':').size() != 2 || qli.Zero_Quantity__c) {
                    continue;
                }

                BillingWrappers.BillingInfoSummaryLicense license = NGBSLicensesMap.get(qli.Product_Lic_Id__c);

                if (!qli.Billing_Codes__r.isEmpty()) {
                    for (Cost_Center_Line_Item__c ccli : qli.Billing_Codes__r) {
                        Integer ccliQuantity = ccli.Parent__c == null && ccli.Quantity__c != null ? Integer.valueOf(String.valueOf(ccli.Quantity__c)) :
                                ccli.Quantity__c == null && ccli.Parent__r.Quantity__c != null ? Integer.valueOf(String.valueOf(ccli.Parent__r.Quantity__c)) : 0;

                        if (!qli.Zero_Quantity__c && ccliQuantity > 0 && !TECHNICAL_SUBLICENSES.contains(qli.Product_Lic_Id__c) && TECHNICAL_LICENSES.contains(parentLTA.catalogId) && (ccliQuantity != parentLTA.qty || parentLTA.qty == 1)) {
                            LicensesToAdd newParentLTA = getLTA(parentLTA, ccli, ccliQuantity, rowNum);
                            rowNum++;
                            newParentLTA.subItems.add(new LicensesToAdd(qli, new Cost_Center_Line_Item__c(), license, rowNum, true, false));
                            if (qli.CurrencyIsoCode == RingCentralHelper.USD || qli.CurrencyIsoCode == RingCentralHelper.CAD) {
                                for(String techSubLicense : getSubLicenses(parentLTA.catalogId.split('_')[1])) {
                                    rowNum++;
                                    newParentLTA.subItems.add(new LicensesToAdd(allQLIMap.get(techSubLicense), new Cost_Center_Line_Item__c(), license, rowNum, true, false));
                                }
                            }
                            rowNum++;
                            splitParent.add(newParentLTA);
                        } else {
                            if (parentLTA.billingCodeId == 0) {
                                parentLTA.billingCodeId = Long.valueOf(ccli.Cost_Center__r.BillingId__c);
                            }
                            parentLTA.subItems.add(new LicensesToAdd(qli, ccli, license, rowNum, true, false));
                            rowNum++;
                        }
                    }
                } else {
                    Integer quantity = license != null && qli.NewQuantity__c > license.qty
                        ? Integer.valueOf(qli.NewQuantity__c) - license.qty
                        : license == null
                            ? Integer.valueOf(qli.Quantity)
                            : 0;
                    if (quantity > 0 && !qli.Zero_Quantity__c) {
                        if ((Integer.valueOf(qli.Quantity) != parentLTA.qty || parentLTA.qty == 1)
                            && !TECHNICAL_SUBLICENSES.contains(qli.Product_Lic_Id__c)
                            && (TECHNICAL_LICENSES.contains(parentLTA.catalogId)
                                || parentLTA.catalogId == TECHNICAL_LICENSE_DLI_282 && bypassLicenses.contains(parentLTA.catalogId))
                        ) {
                            LicensesToAdd newParentLTA = getLTA(parentLTA, new Cost_Center_Line_Item__c(), quantity, rowNum);
                            rowNum++;
                            newParentLTA.subItems.add(new LicensesToAdd(qli, new Cost_Center_Line_Item__c(), license, rowNum, true, false));
                            if (qli.CurrencyIsoCode == RingCentralHelper.USD || qli.CurrencyIsoCode == RingCentralHelper.CAD) {
                                for (String techSubLicense : getSubLicenses(parentLTA.catalogId.split('_')[1])) {
                                    rowNum++;
                                    newParentLTA.subItems.add(new LicensesToAdd(allQLIMap.get(techSubLicense), new Cost_Center_Line_Item__c(), license, rowNum, true, false));
                                }
                            }
                            rowNum++;
                            splitParent.add(newParentLTA);
                        } else {
                            parentLTA.qty = quantity;
                            parentLTA.subItems.add(new LicensesToAdd(qli, new Cost_Center_Line_Item__c(), license, rowNum, true, false));
                            rowNum++;
                        }
                    }
                }
            }
        }

        for (Integer i = parentLicenses.size() - 1; i >= 0 ; --i) {
            String catalogId = parentLicenses.get(i).catalogId;
            if (catalogId == TECHNICAL_LICENSE_FDL_401 && parentLicenses.get(i).subItems.isEmpty()) {
                parentLicenses.remove(i);
                continue;
            }
            if (catalogId == TECHNICAL_LICENSE_DL_75
                || catalogId == TECHNICAL_LICENSE_DL_CC_735
                || catalogId == TECHNICAL_LICENSE_BYOC_942
                || catalogId == TECHNICAL_LICENSE_DLI_282 && bypassLicenses.contains(catalogId)
                ) {
                if (!parentLicenses.get(i).subItems.isEmpty()) {
                    Integer j = 0;
                    for (LicensesToAdd lta : parentLicenses.get(i).subItems) {
                        if (TECHNICAL_SUBLICENSES.contains(lta.catalogId)) {
                            j++;
                        }
                    }
                    if (parentLicenses.get(i).subItems.size() == j) {
                        parentLicenses.remove(i);
                    }
                } else {
                    parentLicenses.remove(i);
                }
            }
        }

        if (splitParent.size() > 0) {
            parentLicenses.addAll(splitParent);
        }
        for (LicensesToAdd parentLTA : parentLicenses) {
            ITEMS_TO_ADD.put(parentLTA.catalogId, parentLTA);
            if (parentLTA.subItems.isEmpty()) {
                continue;
            }

            for (LicensesToAdd childLicense : parentLTA.subItems) {
                ITEMS_TO_ADD.put(childLicense.catalogId, childLicense);

                for (QuoteLineItem qliMap : allQLIMap.values()) {
                    BillingWrappers.BillingInfoSummaryLicense license = NGBSLicensesMap.get(qliMap.Product_Lic_Id__c);
                    BillingWrappers.QLIPackageInfo qliPackage = allQLIPackageInfo.get(qliMap.Product_Lic_Id__c);
                    // we always write parent catalogId to QLI Package Info in UQT, if the item is not on a root level
                    if (String.isBlank(qliPackage?.parent) || !qliPackage.parent.equalsIgnoreCase(childLicense.catalogId)) {
                        continue;
                    }

                    String childCategory = allQLIMapbyPath.get(childLicense.catalogId) + ':';
                    if (allQLIMapbyPath.get(qliMap.Product_Lic_Id__c).contains(':')
                        && allQLIMapbyPath.get(qliMap.Product_Lic_Id__c).startsWith(childCategory)
                        && allQLIMapbyPath.get(qliMap.Product_Lic_Id__c).split(':').size() == 3
                    ) {
                        LicensesToAdd lta = new LicensesToAdd(qliMap, new Cost_Center_Line_Item__c(), license, rowNum, true, false);
                        ITEMS_TO_ADD.put(lta.catalogId, lta);
                        childLicense.subItems.add(lta);
                        rowNum++;
                    }
                }
            }
        }

        return parentLicenses;
    }

    public static LicensesToAdd[] getShippingLicenses(LicensesToAdd[] itemsToAdd, List<CustomAddressAssignments__c> addresses, String externalIdShipping) {
        Map<String, List<CustomAddressAssignments__c>> caaShippingMap = new Map<String, List<CustomAddressAssignments__c>>();
        Map<String, String> caaShippingBillingCodeMap = new Map<String, String>();
        for (CustomAddressAssignments__c caa : addresses) {
            Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(caa.QuoteLineItem__r.Product2)
                || Product2Helper.isShippingTypeManual(caa.QuoteLineItem__r.Product2);
            if (isShippingAvailableForLicense && caa.ShippingLicenseTree__c != null) {
                if (caa.ShippingBillingCodeId__c != null && caa.ShippingBillingCodeId__c != 'null') {
                    caaShippingBillingCodeMap.put(caa.ShippingLicenseTree__c + '-' + caa.ShippingBillingCodeId__c, caa.ShippingBillingCodeId__c);
                    if (caaShippingMap.get(caa.ShippingLicenseTree__c + '-' + caa.ShippingBillingCodeId__c) == null) {
                        caaShippingMap.put(caa.ShippingLicenseTree__c + '-' + caa.ShippingBillingCodeId__c, new List<CustomAddressAssignments__c>{caa});
                    } else {
                        caaShippingMap.get(caa.ShippingLicenseTree__c + '-' + caa.ShippingBillingCodeId__c).add(caa);
                    }
                } else {
                    if (caaShippingMap.get(caa.ShippingLicenseTree__c) == null) {
                        caaShippingMap.put(caa.ShippingLicenseTree__c, new List<CustomAddressAssignments__c>{caa});
                    } else {
                        caaShippingMap.get(caa.ShippingLicenseTree__c).add(caa);
                    }
                }
            }
        }

        List<Integer> rowNums = new List<Integer>();
        Integer rowNum = 0;
        for (LicensesToAdd lta : itemsToAdd) {
            rowNums.add(Integer.valueOf(lta.externalId.split(':')[3]));
            for (LicensesToAdd ltaSubitem : lta.subItems) {
                rowNums.add(Integer.valueOf(ltaSubitem.externalId.split(':')[3]));
                for (LicensesToAdd ltaSubSubItem : ltaSubitem.subItems) {
                    rowNums.add(Integer.valueOf(ltaSubSubItem.externalId.split(':')[3]));
                }
            }
        }

        rowNums.sort();
        if (!rowNums.isEmpty()) {
            rowNum = rowNums[rowNums.size()-1];
        }
        for (String license : caaShippingMap.keySet()) {
            rowNum++;
            LicensesToAdd shippingLicenseParent = new LicensesToAdd();
            shippingLicenseParent.catalogId = license.split(':')[0];
            shippingLicenseParent.qty = 1;
            shippingLicenseParent.billingCodeId = (!caaShippingBillingCodeMap.isEmpty() && caaShippingBillingCodeMap.get(license) != null) ? Long.valueOf(caaShippingBillingCodeMap.get(license)) : 0;
            shippingLicenseParent.batch = false;
            shippingLicenseParent.externalId = externalIdShipping + ':' + rowNum;
            shippingLicenseParent.billingState = BILLING_STATE_PURCHASED;
            shippingLicenseParent.billingCycleDuration = BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME;

            ITEMS_TO_ADD.put(shippingLicenseParent.catalogId, shippingLicenseParent);
            rowNum++;

            LicensesToAdd shippingLicenseChild = new LicensesToAdd();
            shippingLicenseChild.catalogId = license.split(':')[1];
            shippingLicenseChild.qty = 1;
            shippingLicenseChild.billingCodeId = 0;
            shippingLicenseChild.batch = false;
            shippingLicenseChild.externalId = externalIdShipping + ':' + rowNum;
            shippingLicenseChild.billingState = BILLING_STATE_PURCHASED;
            shippingLicenseChild.billingCycleDuration = BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME;

            ITEMS_TO_ADD.put(shippingLicenseChild.catalogId, shippingLicenseChild);
            rowNum++;

            LicensesToAdd shippingLicenseSubChild = new LicensesToAdd();
            shippingLicenseSubChild.catalogId = license.split(':')[2].split('-')[0];
            shippingLicenseSubChild.billingState = BILLING_STATE_PURCHASED;
            shippingLicenseSubChild.batch = false;
            shippingLicenseSubChild.billingCodeId = 0;
            shippingLicenseSubChild.billingCycleDuration = BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME;
            shippingLicenseSubChild.externalId = externalIdShipping + ':' + rowNum;

            ITEMS_TO_ADD.put(shippingLicenseSubChild.catalogId, shippingLicenseSubChild);
            Integer sumOfQty = 0;
            for (CustomAddressAssignments__c caa : caaShippingMap.get(license)) {
                sumOfQty += Integer.valueOf(caa.Quantity__c);
                shippingLicenseSubChild.qty = sumOfQty;
            }
            shippingLicenseChild.subItems.add(shippingLicenseSubChild);
            shippingLicenseParent.subItems.add(shippingLicenseChild);
            itemsToAdd.add(shippingLicenseParent);
        }
        return itemsToAdd;
    }

    @TestVisible
    private static Boolean isDeviceOrNonBatchLicense(QuoteLineItem qli) {
        if (qli == null) {
            return false;
        }

        Boolean isShippingLabelAutoOrManual = Product2Helper.isShippingTypeAuto(qli.Product2)
            || Product2Helper.isShippingTypeManual(qli.Product2);

        Map<String, String> allQLIMapbyPath = (Map<String, String>) ALL_MAPS.data.get('allQLIMapbyPath');
        Boolean isNonBatchLicense = allQLIMapbyPath != null
            && ORDER_API_BATCH_FALSE_LICENSES.contains(allQLIMapbyPath.get(qli.Product_Lic_Id__c));

        return isNonBatchLicense || isShippingLabelAutoOrManual;
    }

    public static List<String> getSubLicenses(String parentCatalogId) {
        List<String> subLicenses = new List<String>();
        if (parentCatalogId == TECHNICAL_LICENSE_DL_75.split('_')[1]) {
            subLicenses.add(TECHNICAL_LICENSE_CRF);
            subLicenses.add(TECHNICAL_LICENSE_E911);
        }
        if (parentCatalogId == TECHNICAL_LICENSE_DL_CC_735.split('_')[1]) {
            subLicenses.add(TECHNICAL_LICENSE_CRF_CC);
            subLicenses.add(TECHNICAL_LICENSE_E911_CC);
        }
        return subLicenses;
    }

    public static Boolean isTechnicalLicense(QuoteLineItem qli) {
        return TECHNICAL_LICENSES.contains(qli.Product_Lic_Id__c);
    }

    public static LicensesToAdd getLTA(LicensesToAdd parentLicense, Cost_Center_Line_Item__c ccli, Integer ccliQuantity, Integer rowNum) {
        LicensesToAdd lta = new LicensesToAdd();
        lta.catalogId = parentLicense.catalogId;
        lta.batch = true;
        lta.externalId = parentLicense.externalId.split(':')[0] + ':' + parentLicense.externalId.split(':')[1] + ':' + parentLicense.externalId.split(':')[2] + ':' + rowNum;
        lta.billingState = BILLING_STATE_PURCHASED;
        lta.billingCycleDuration = parentLicense.billingCycleDuration;
        if (ccliQuantity > 0) {
            lta.qty = ccliQuantity;
        }
        if (ccli.Id != null) {
            lta.billingCodeId = Long.valueOf(ccli.Cost_Center__r.BillingId__c);
        } else {
            lta.billingCodeId = 0;
        }
        return lta;
    }

    public static Response getAllMaps(List<QuoteLineItem> qlis) {
        Response res = new Response();
        Map<String, QuoteLineItem> allQLIMap = new Map<String, QuoteLineItem>();
        Map<String, String> allQLIMapbyPath = new Map<String, String>();
        Map<String, List<QuoteLineItem>> childQLIsMap = new Map<String, List<QuoteLineItem>>();
        Set<String> tamLisensesParent = new Set<String>();
        Set<String> tamLisensesParentCatalogIds = new Set<String>();
        Boolean hasItemsToAppend = false;
        for (QuoteLineItem qli : qlis) {
            if ((qli.Product_Family__c == Product2Helper.FAMILY_TAXES || !qli.Product_Lic_Id__c.startsWith('LC')) && !qli.Product_Lic_Id__c.startsWith('EVNT')){
                continue;
            }

            BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            allQLIPackageInfo.put(qli.Product_Lic_Id__c, qliPackage);

            if (qliPackage.CategoryCode == NGBSLicensesExceptionsMap.get(qli.Product_Lic_Id__c) && !bypassLicenses.contains(qli.Product_Lic_Id__c)) {
                continue;
            }
            if (Product2Helper.ORDER_API_EXCEPTION_LICENSES.contains(qli.Product_Lic_Id__c)) {
                continue;
            }

            if (qli.Zero_Quantity__c && qli.Entitlement__c != null && (qliPackage.CategoryCode == 'EES' || qliPackage.CategoryCode == 'CCES')) {
                tamLisensesParent.add(qli.Product_Lic_Id__c);
            }

            allQLIMap.put(qli.Product_Lic_Id__c, qli);

            if (qliPackage.categoryPath != null) {
                allQLIMapbyPath.put(qli.Product_Lic_Id__c, qliPackage.categoryPath);
                if (!qliPackage.categoryPath.contains(':')) {
                    childQLIsMap.put(qli.Product_Lic_Id__c, new List<QuoteLineItem>());
                }
            } else {
                allQLIMapbyPath.put(qli.Product_Lic_Id__c, qliPackage.CategoryCode);
                childQLIsMap.put(qli.Product_Lic_Id__c, new List<QuoteLineItem>());
                if (qliPackage.parent != null) {
                    qliPackage.categoryPath = qliPackage.parent.split('_')[1] + ':' + qliPackage.CategoryCode;
                    allQLIMapbyPath.put(qli.Product_Lic_Id__c, qliPackage.categoryPath);
                }
            }
        }

        for (String parentCatalogId : childQLIsMap.keySet()) {
            for (QuoteLineItem qli : allQLIMap.values()) {
                if (allQLIMapbyPath.get(qli.Product_Lic_Id__c).startsWith(allQLIMapbyPath.get(parentCatalogId) + ':')) {
                    childQLIsMap.get(parentCatalogId).add(qli);
                }
            }
        }

        res.setData('allQLIMap', allQLIMap);
        res.setData('allQLIMapbyPath', allQLIMapbyPath);
        res.setData('childQLIsMap', childQLIsMap);
        if (tamLisensesParent != null && !tamLisensesParent.isEmpty()) {
            for (String tamParent : tamLisensesParent) {
                if (!childQLIsMap.get(tamParent).isEmpty()) {
                    for (QuoteLineItem qliChild : childQLIsMap.get(tamParent)) {
                        if (!qliChild.Zero_Quantity__c && qliChild.Entitlement__c == null) {
                            tamLisensesParentCatalogIds.add(tamParent);
                            hasItemsToAppend = true;
                        }
                    }
                }
            }
        }
        if (hasItemsToAppend && !tamLisensesParentCatalogIds.isEmpty()) {
            res.setData('hasItemsToAppend', hasItemsToAppend);
            res.setData('itemsToAppend', tamLisensesParentCatalogIds);
        }

        return res;
    }

    public static LicensesToAppend[] getLicensesToAppend(Map<String, BillingWrappers.LicenseRequested> licenseIdMap) {
        Map<String, QuoteLineItem> allQLIMap = (Map<String, QuoteLineItem>) ALL_MAPS.data.get('allQLIMap');
        LicensesToAppend[] licensesToApp = new LicensesToAppend[]{};
        for (QuoteLineItem qli : allQLIMap.values()) {
            if (!TECHNICAL_SUBLICENSES.contains(qli.Product_Lic_Id__c) && !ITEMS_TO_ADD.containsKey(qli.Product_Lic_Id__c) && !qli.Zero_Quantity__c && qli.Quantity > 0) {
                for (BillingWrappers.LicenseRequested lr : licenseIdMap.values()) {
                    BillingWrappers.QLIPackageInfo qliPackage = allQLIPackageInfo.get(qli.Product_Lic_Id__c);
                    if (qliPackage.categoryPath != null && qliPackage.categoryPath.startsWith(lr.categoryId) && lr.licenseTypeId != null) {
                        LicensesToAppend lta = new LicensesToAppend(lr, qli);
                        licensesToApp.add(lta);
                    }
                }
            }
        }
        return licensesToApp;
    }

    @TestVisible
    public static Map<String, BillingWrappers.LicenseRequested> getLicenseIdsMap(String billingId, String packageId, Set<String> catalogIds) {
        Map <String, BillingWrappers.LicenseRequested> licenseIdsMap = new Map<String, BillingWrappers.LicenseRequested>();
        if (!catalogIds.isEmpty() && billingId != null && packageId != null) {
            for (String catalogId : catalogIds) {
                BillingWrappers.BillingInfoLicenses bInfo = NGBSAPI.getAllLicenses(billingId, packageId, catalogId);
                for (BillingWrappers.LicenseRequested license : bInfo.licenses) {
                    licenseIdsMap.put(license.catalogId, license);
                }
            }
        }
        return licenseIdsMap;
    }

    public static Response callNGBSWithPreparedOrder(SWNDataCollector sdc, List<QuoteLineItem> qlis, String quoteType) {
        return callNGBSWithPreparedOrder(sdc.qt, sdc.qt.OpportunityId, qlis, sdc.billingId, quoteType, sdc.ngbsPackage);
    }
    public static Response callNGBSWithPreparedOrder(
        Quote qt,
        Id oppId,
        List<QuoteLineItem> qlis,
        String billingId,
        String quoteType,
        BillingWrappers.NGBSAccountPackage ngbsAccountPackage
    ) {
        OrderRequestInfo ori = new OrderRequestInfo();
        Response res = new Response();
        HttpResponse response = new HttpResponse();
        String packageId = ngbsAccountPackage?.id;
        String method = HttpHelper.METHOD_POST;
        String url = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + billingId +'/purchase/'+ packageId +'/order/v2';
        ori.salesOrderId = oppId;
        List<QuoteLineItem> upsellQliList = SWNHelper.getUpsellQliList(qlis);
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);

        LicensesToBulkRemove[] bulkLicensesToRemove = new LicensesToBulkRemove[]{};
        if (SWNStep.DOWN_SELL == quoteType || SWNStep.UPGRADE == quoteType) {
            List<QuoteLineItem> downSellQliList = SWNHelper.getDownsellQliList(qlis);

            BillingWrappers.BillingInfo2 billingInfo = NGBSAPI.getBillingInfo(billingId, packageId);
            Set<String> catalogIds = new Set<String>();
            for (BillingWrappers.LicenseRequested2 license : billingInfo.licenses) {
                catalogIds.add(license.catalogId);
            }

            for (QuoteLineItem qli : downSellQliList) {
                if (!catalogIds.contains(qli.Product_Lic_Id__c)) {
                    continue;
                }

                Integer qliQty = Math.abs((Integer)QuoteLineItemHelper.getQuantity(qli));
                LicensesToBulkRemove ltbr = new LicensesToBulkRemove();
                LicensesSelector selector = new LicensesSelector();
                ltbr.qty = qliQty;

                // For Upgrade scenarios, override removalDelay flag to 'Immediate' for all items to remove
                if (SWNStep.UPGRADE == quoteType) {
                    ltbr.removalDelay = IMMEDIATE;
                }

                // For Downsell scenarios with RC product line, add batch parameter = 'TrueAndFalse'
                if (SWNStep.DOWN_SELL == quoteType && billingInfo?.productLine?.equalsIgnoreCase(PRODUCT_LINE_RC)) {
                    selector.batch = TRUE_AND_FALSE;
                }

                LicenseKey key = new LicenseKey();
                key.catalogId = qli.Product_Lic_Id__c;
                selector.keys = new LicenseKey[]{key};
                ltbr.selector = selector;
                bulkLicensesToRemove.add(ltbr);
            }
        }

        LicensesToAdd[] licensesToAdd = new LicensesToAdd[]{};
        if (SWNStep.UP_SELL == quoteType || SWNStep.UPGRADE == quoteType) {
            for (QuoteLineItem qli : upsellQliList) {
                if (Product2Helper.isTaxes(qli.Product2)) {
                    continue;
                }
                LicensesToAdd lta = new LicensesToAdd();
                lta.catalogId = qli.Product_Lic_Id__c;
                if (qli.ChargeTerm__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                    lta.billingCycleDuration = BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME;
                } else {
                    lta.billingCycleDuration = qli.ChargeTerm__c;
                }
                lta.qty = Math.abs((Integer)QuoteLineItemHelper.getQuantity(qli));
                licensesToAdd.add(lta);
            }
        }

        switch on SWNStep.SYNC_STEP.valueOf(quoteType) {
            when DOWN_SELL {
                ori.bulkItemsToRemove = bulkLicensesToRemove;
            }
            when UP_SELL {
                ori.itemsToAdd = licensesToAdd;
            }
            when UPGRADE {
                // override url
                method = HttpHelper.METHOD_PUT;
                url = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + billingId +'/package/'+ packageId +'/catalogId/v2';
                ori.catalogId = pInfo.packageInfo.catalogId;
                ori.version = pInfo.packageInfo.version;
                ori.newDuration = pInfo.duration;
                ori.bulkItemsToRemove = bulkLicensesToRemove;
                ori.itemsToAdd = licensesToAdd;
            }
            when CHARGE_TERM_SYNC {
                ori.duration = pInfo.duration;
                // override url
                method = HttpHelper.METHOD_PUT;
                url = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + billingId +'/package/'+ packageId +'/duration/v2';
            }
        }

        if (ori.salesOrderId != null) {
            String body = JSON.serialize(ori, true);
            response = NGBSAPI.requestNGBS(url, method, body,
                HTTPHelper.CONTENT_TYPE_APPLICATION_JSON);
            if (HttpHelper.isSuccess(response)) {
                res.setData('status', 'success');
            }
        }
        return res;
    }

    private static void updateExternalIds(LicensesToAdd[] itemsToAdd, OrderItemsRequest[] orderItems) {
        SettingsService.NGBSLicenseSetting ngbsLicenseSetting = SettingsService.getNGBSLicenseSetting(true, bypassLicenses);
        for (LicensesToAdd lta : itemsToAdd) {
            if (ngbsLicenseSetting.categoryCodesAsExtIdInOrderAPI.contains(lta.categoryCode)) {
                for (OrderItemsRequest oi : orderItems) {
                    if (oi.id == lta.externalId) {
                        oi.id = lta.categoryCode;
                    }
                }
                lta.externalId = lta.categoryCode;
            }
        }
    }

}