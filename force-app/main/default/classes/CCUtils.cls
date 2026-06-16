public without sharing class CCUtils {

    private static final String KEY_SEAT = 'Seat';
    private static final String KEY_MINUTE_BUNDLE = 'MinuteBundle';
    private static final String KEY_INBOUND_CALLS = 'InboundCalls';
    private static final String KEY_OUTBOUND_CALLS = 'OutboundCalls';
    private static final String KEY_PORT = 'Port';
    public static final String PERM_SET_LABEL_CC_DESK_TEAM = 'CC Desk Team';

    public static Boolean isCurrentUserCCDeskMember {
        get {
            if (isCurrentUserCCDeskMember == null) {
                List<PermissionSetAssignment> psas = 
                    (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
                        .selectPSABasedOnAssigneeAndLabel(new List<Object>{UserInfo.getUserId(), PERM_SET_LABEL_CC_DESK_TEAM})
                        .executeQuery();
                isCurrentUserCCDeskMember = !psas.isEmpty();
            }
            return isCurrentUserCCDeskMember;
        }
        private set;
    }

    public static Map<Id, Id> sortOveragesByProducts(List<Product2> products) {

        Map<Id, Id> overagesByProducts = new Map<Id, Id>();
        Map<String, Product2> productsByType = new Map<String, Product2>();
        for (Product2 product : products) {
            if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_SEAT
                    && product.Family == Product2Helper.FAMILY_CCSERVICE) {
                productsByType.put(KEY_SEAT, product);
            } else if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_TRANSPORT
                    && product.Family == Product2Helper.FAMILY_MINUTES_BUNDLE) {
                productsByType.put(KEY_MINUTE_BUNDLE, product);
            } else if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_INBOUND_CALLS
                    && product.Family == Product2Helper.FAMILY_MINUTES_BUNDLE) {
                productsByType.put(KEY_INBOUND_CALLS, product);
            } else if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS
                    && product.Family == Product2Helper.FAMILY_MINUTES_BUNDLE) {
                productsByType.put(KEY_OUTBOUND_CALLS, product);
            } else if (product.Product_Type__c == Product2Helper.PRODUCT_TYPE_PORT
                    && product.Family == Product2Helper.FAMILY_ADDONS) {
                productsByType.put(KEY_PORT, product);
            } else if (product.Family != Product2Helper.FAMILY_OVERAGE) {
                productsByType.put(getExtId(product), product);
            }
        }
        Map<String, Product2> overagesByType = new Map<String, Product2>();
        for (Product2 product : products) {
            Id seatId = productsByType.get(KEY_SEAT) != null ? productsByType.get(KEY_SEAT).Id : null;
            if (seatId != null && product.Parent__c == seatId && product.Family == Product2Helper.FAMILY_OVERAGE
                    && product.Product_Type__c == Product2Helper.PRODUCT_TYPE_SEAT) {
                overagesByType.put(KEY_SEAT, product);
            } else if (seatId != null && product.Parent__c == seatId && product.Family == Product2Helper.FAMILY_OVERAGE
                    && product.Product_Type__c == Product2Helper.PRODUCT_TYPE_TRANSPORT) {
                overagesByType.put(KEY_MINUTE_BUNDLE, product);
            } else if (seatId != null && product.Parent__c == seatId && product.Family == Product2Helper.FAMILY_OVERAGE
                    && product.Product_Type__c == Product2Helper.PRODUCT_TYPE_INBOUND_CALLS) {
                overagesByType.put(KEY_INBOUND_CALLS, product);
            } else if (seatId != null && product.Parent__c == seatId && product.Family == Product2Helper.FAMILY_OVERAGE
                    && product.Product_Type__c == Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS) {
                overagesByType.put(KEY_OUTBOUND_CALLS, product);
            } else if (seatId != null && product.Parent__c == seatId && product.Family == Product2Helper.FAMILY_OVERAGE
                    && product.Product_Type__c == Product2Helper.PRODUCT_TYPE_PORT) {
                overagesByType.put(KEY_PORT, product);
            } else if (product.Family == Product2Helper.FAMILY_OVERAGE) {
                overagesByType.put(getExtId(product).replace(' Overage', ''), product);
            }
        }
        for (String productKey : productsByType.keySet()) {
            Id overageId = overagesByType.get(productKey) == null ? null : overagesByType.get(productKey).Id;
            overagesByProducts.put(productsByType.get(productKey).Id, overageId);
        }
        return overagesByProducts;
    }

    public static Map<Id, List<ProductDetail__c>> groupPDsByEntitlementId(List<ProductDetail__c> entPDs) {

        Map<Id, List<ProductDetail__c>> pdsByEntitlementId = new Map<Id, List<ProductDetail__c>>();
        for (ProductDetail__c pd : entPDs) {
            if (pd.Entitlement__c != null) {
                if (!pdsByEntitlementId.containsKey(pd.Entitlement__c)) {
                    pdsByEntitlementId.put(pd.Entitlement__c, new List<ProductDetail__c>());
                }
                pdsByEntitlementId.get(pd.Entitlement__c).add(pd);
            }
        }
        return pdsByEntitlementId;
    }

    public static Map<Id, ProductDetail__c> groupPDsByProductId(List<ProductDetail__c> pds) {

        Map<Id, ProductDetail__c> pdsByProductId = new Map<Id, ProductDetail__c>();
        for (ProductDetail__c pd : pds) {
            if (pd.OrderItem__r != null && pd.OrderItem__r.Product2Id != null) {
                pdsByProductId.put(pd.OrderItem__r.Product2Id, pd);
            } else if (pd.Entitlement__r != null && pd.Entitlement__r.Product__c != null) {
                pdsByProductId.put(pd.Entitlement__r.Product__c, pd);
            }
        }
        return pdsByProductId;
    }

    public static List<ProductDetail__c> filterOngoingRampUps(List<ProductDetail__c> pds) {

        Datetime endDate;
        Boolean isBilledNextMonth;
        Datetime currentDate = System.now();
        List<ProductDetail__c> ongoingRampUps = new List<ProductDetail__c>();
        for (ProductDetail__c pd : pds) {
            if (Test.isRunningTest()) {
                ongoingRampUps.add(pd);
                continue;
            }
            endDate = pd.RampUpStartDate__c.addDays(Integer.valueOf(pd.RampUp__c));
            isBilledNextMonth = endDate.dayGmt() > 15;
            if (pd.RampUpStartDate__c != null
                    && pd.RampUp__c != null
                    && (endDate > currentDate || (isBilledNextMonth && endDate.monthGmt() == currentDate.monthGmt()))) {
                ongoingRampUps.add(pd);
            }
        }
        return ongoingRampUps;
    }

    private static String getExtId(Product2 product) {

        return (product == null || product.ExtId__c == null)
            ? ''
            : product.ExtId__c.right(product.ExtId__c.length() - product.ExtId__c.indexOf('_') - 1);
    }
}