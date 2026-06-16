public with sharing class EntitlementTriggerHelper {
	public EntitlementTriggerHelper() {

	}

    private static Map<Id, Product2> products = new Map<Id, Product2>();
    private static Map<Id, Account> accounts;
    private static Map<Id, List<Entitlement__c>> accountEntitlements;
    public static Map<Id, Product2> productsMapStatic = new Map<Id, Product2>();

    public class GetData extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Entitlement__c> entitlements = (List<Entitlement__c>) triggerRecords;
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                populateProductsMap(entitlements);
            }

            if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
                collectData(entitlements);
            }
        }

        public void populateProductsMap(List<Entitlement__c> entitlements) {
            Set<Id> prodsToSelect = new Set<Id>();

            for (Entitlement__c ent : entitlements) {
                if (ent.Product__c != null && !products.containsKey(ent.Product__c)) {
                    prodsToSelect.add(ent.Product__c);
                }
            }

            if (prodsToSelect.size() > 0) {
                Map<Id, Product2> prodsMap = new Map<Id, Product2> ([
                    SELECT Id, Charge_Term__c, Family, Product_Type__c, Sub_Category__c, Feature__c, Name
                    FROM Product2
                    WHERE Id IN :prodsToSelect
                ]);
                products.putAll(prodsMap);
            }
        }

        private void collectData(List<Entitlement__c> entitlements) {
            accounts = new Map<Id, Account>();
            accountEntitlements = new Map<Id, List<Entitlement__c>>();

            Set<Id> accountIds = new Set<Id>();
            for (Entitlement__c ent : entitlements) {
                accountIds.add(ent.Account__c);
            }

            for(Entitlement__c ent : [SELECT Id, Account__c, Product__c, Active__c,
                Product__r.Name, Product__r.Family, Product__r.Product_Type__c,
                Product__r.Sub_Category__c, Product__r.Charge_Term__c, Product__r.Feature__c,
                Account__r.CcPaymentType__c, Account__r.Extended_Enterprise_Support_Customer__c
            FROM Entitlement__c
            WHERE Account__c  IN :accountIds]) {
                if (!accounts.containsKey(ent.Account__c)) {
                    accounts.put(ent.Account__c, ent.Account__r);
                    accountEntitlements.put(ent.Account__c, new List<Entitlement__c>());
                }

                accountEntitlements.get(ent.Account__c).add(ent);

                if (ent.Product__c != null && !products.containsKey(ent.Product__c)) {
                    products.put(ent.Product__c, ent.Product__r);
                }
            }
        }
    }

    public class PrepopulateFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Entitlement__c> entitlements = prepopulateChargeTerm((List<Entitlement__c>) triggerRecords);
            prepopulateEffectivePricePrecise(entitlements);
        }

        public List<Entitlement__c> prepopulateChargeTerm(List<Entitlement__c> entitlements) {
            for (Entitlement__c ent : entitlements) {
                if (!EntitlementHelper.isNGBSEntitlement(ent)) {
                    Product2 prod = products.get(ent.Product__c);
                    if (prod != null) {
                        ent.ChargeTerm__c = prod.Charge_Term__c;
                    }
                }
            }
            return entitlements;
        }

        public void prepopulateEffectivePricePrecise (List<Entitlement__c> entitlements) {
            Set<Id> productIds = new Set<Id>();
            String currencyCode;
            String chargeTerm;
            Set<Id> productIdsForCC = new Set<Id>();

            for(Entitlement__c ent: entitlements) {
                chargeTerm = String.isBlank(chargeTerm) ? ent.ChargeTerm__c : chargeTerm;
                currencyCode = String.isBlank(currencyCode) ? ent.CurrencyIsoCode : currencyCode;
                productIds.add(ent.Product__c);
            }

            List<PricebookEntry> entries = [SELECT id, Product2.Id, Pricebook2Id, Pricebook2.Service__c
                                            FROM PricebookEntry
                                            WHERE Product2.Id IN: productIds
                                            AND Pricebook2.IsStandard = FALSE
                                            AND Pricebook2.CurrencyIsoCode = :currencyCode
                                            AND Pricebook2.Plan__c = :chargeTerm
                                            AND IsActive = TRUE
                                            AND Pricebook2.Service__c = 'Contact Center'];

            for(PricebookEntry pbe: entries) {
                productIdsForCC.add(pbe.Product2.Id);
            }

            for (Entitlement__c ent : entitlements) {
                ent.EffectivePricePrecise__c = EntitlementHelper.getEffectivePricePrecise
                    (
                        ent.Price__c,
                        ent.Discount__c,
                        ent.Discount_Type__c,
                        productIdsForCC.contains(ent.Product__c)
                    );
            }
        }
    }

    public static boolean isSeatEntitlement (Entitlement__c ent) {
        return ent.Product__r.Family == Product2Helper.FAMILY_CCSERVICE
                && ent.Product__r.Product_Type__c != null
                && ent.Product__r.Product_Type__c.equalsIgnoreCase(Product2Helper.PRODUCT_TYPE_SEAT);
    }

    public static String getAccountCCPaymentType (List<Entitlement__c> accountEntitlements) {

        String ccPaymentType;
        for(Entitlement__c ent : accountEntitlements){
            if (!ent.Active__c || !isSeatEntitlement(ent)) {
                continue;
            }
            if (ent.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                ccPaymentType = AccountTriggerHelper.CC_PAYMENT_TYPE_MONTH_TO_MONTH;
            } else if (ent.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                ccPaymentType = AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY;
            }
        }

        return ccPaymentType;
    }

    public class OnAfterInsert extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<String> prodFamiliesToDeactivate = new Set<String>{
                Product2Helper.FAMILY_CCSERVICE,
                Product2Helper.FAMILY_FEE,
                Product2Helper.FAMILY_SERVICE
            };

            List<Entitlement__c> entitlements = (List<Entitlement__c>) Trigger.new;

            Map<Id, Entitlement__c> entitlementsToUpdate = new Map<Id, Entitlement__c>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

            for (Entitlement__c ent : entitlements) {

                /* exclude ngbs entitlements */
                if (ent.Quote__c != null) {
                    continue;
                }

                // Product is not required field, but not fire logic for entitlments without it
                if(ent.Product__c == null) {
                    continue;
                }
                Product2 product = products.get(ent.Product__c);
                Account acc = accounts.get(ent.Account__c);
                List<Entitlement__c> currentAccEntitlements = accountEntitlements.get(ent.Account__c);
                for (Entitlement__c accEnt : currentAccEntitlements) {
                    // Product is not required field, but not fire logic for entitlments without it
                    if(accEnt.Product__c == null) {
                        continue;
                    }
                    // logic from old DeactivateOldSeat method
                    // should deactivate entitlements related to different products with the same family
                    if (ent.Id != accEnt.Id && ent.Product__c != accEnt.Product__c
                    && prodFamiliesToDeactivate.contains(accEnt.Product__r.Family)) {

                        if(product.Family == accEnt.Product__r.Family
                            && (product.Family == 'Service'
                                || (product.Sub_Category__c == 'Contact Center'
                                    && product.Product_Type__c == accEnt.Product__r.Product_Type__c)
                                || (product.Family == 'Fee'
                                    && product.Name == accEnt.Product__r.Name))) {
                            accEnt.Active__c = false;
                            accEnt.Quantity__c = 0;
                            accEnt.End_Date__c = System.today();
                            entitlementsToUpdate.put(accEnt.Id, accEnt);
                        }
                    }
                }

                if (product.Feature__c == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT && ent.Active__c
                && !acc.Extended_Enterprise_Support_Customer__c) {

                    acc.Extended_Enterprise_Support_Customer__c = true;
                    accountsToUpdate.put(acc.Id, acc);
                }

                String ccPaymentType = getAccountCCPaymentType(currentAccEntitlements);
                if (ccPaymentType == AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY
                && acc.CcPaymentType__c == AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL) {
                    continue;
                }
                if (acc.CcPaymentType__c != ccPaymentType) {
                    acc.CcPaymentType__c = ccPaymentType;
                    accountsToUpdate.put(acc.Id, acc);
                }
            }

            if (entitlementsToUpdate.size() > 0) {
                update entitlementsToUpdate.values();
            }

            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate.values();
            }
        }
    }

    public class OnAfterUpdate extends Triggers.TriggerHandlerBase {

        override public void handle () {
            List<Entitlement__c> entitlements = (List<Entitlement__c>) Trigger.new;

            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

            for (Entitlement__c ent : entitlements) {
                // Product is not required field, but not fire logic for entitlments without it
                if(ent.Product__c == null) {
                    continue;
                }
                Product2 product = products.get(ent.Product__c);
                Account acc = accounts.get(ent.Account__c);
                List<Entitlement__c> currentAccEntitlements = accountEntitlements.get(ent.Account__c);

                if (product.Feature__c == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT && ent.Active__c
                && !acc.Extended_Enterprise_Support_Customer__c) {

                    acc.Extended_Enterprise_Support_Customer__c = true;
                    accountsToUpdate.put(acc.Id, acc);
                }

                String ccPaymentType = getAccountCCPaymentType(currentAccEntitlements);
                if (ccPaymentType == AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY
                && acc.CcPaymentType__c == AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL) {
                    continue;
                }
                if (acc.CcPaymentType__c != ccPaymentType) {
                    acc.CcPaymentType__c = ccPaymentType;
                    accountsToUpdate.put(acc.Id, acc);
                }
            }

            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate.values();
            }
        }
    }

    public class SetIsHiddenLicense extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<String> hiddenLicensesSet = new Set<String>();
            String oppBi = getOpptyBusinessIdentity(((List<Entitlement__c>)Trigger.new).get(0));
            List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(oppBi);

            SettingsService.NGBSLicenseSetting ngbsLicenseSetting = SettingsService.getNGBSLicenseSetting(true, bypassLicenses);

            for(Entitlement__c ent : (List<Entitlement__c>)Trigger.new) {
                for(String packageId : ngbsLicenseSetting.hiddenSettings.keySet()) {
                    if (packageId == SettingsService.ALL || ent.PackageCatalogId__c != null && ent.PackageCatalogId__c == packageId) {
                        hiddenLicensesSet.addAll(ngbsLicenseSetting.hiddenSettings.get(packageId));
                    }
                }
            }

            if(hiddenLicensesSet.isEmpty()) {
                System.debug('cannot found any hidden licences in NGBSHiddenLicenses__c custom setting. skip processing IsHiddenLicense__c');
                return;
            }

            List<Entitlement__c> entList = new List<Entitlement__c>();
            Set<Id> product2IdSet = new Set<Id>();

            for(Entitlement__c ent : (List<Entitlement__c>)Trigger.new) {
                if(EntitlementHelper.isNGBSEntitlement(ent)) {
                    entList.add(ent);
                    product2IdSet.add(ent.Product__c);
                }
            }

            if(entList.isEmpty()) {
                System.debug('not found entitlements in trigger.new. skip processing IsHiddenLicense__c');
                return;
            }

            Boolean isNeedToSelectProducts = !productsMapStatic.keySet().containsAll(product2IdSet);
            if(isNeedToSelectProducts) {
                List<Product2> productList = [
                    SELECT Id, Name, Family,
                            Feature__c, Sub_Feature__c,
                            Charge_Term__c, ExtID__c
                    FROM Product2
                    WHERE Id IN :product2IdSet
                ];

                for(Product2 p2 : productList) {
                    productsMapStatic.put(p2.Id, p2);
                }
            }

            for(Entitlement__c ent: entList) {
                if(productsMapStatic.containsKey(ent.Product__c)) {
                    Product2 prod = productsMapStatic.get(ent.Product__c);
                    ent.IsHiddenLicense__c = hiddenLicensesSet.contains(prod.ExtID__c);
                }
            }
        }

        private String getOpptyBusinessIdentity(Entitlement__c ent) {
            if (String.isBlank(ent.Quote__c)) {
                return null;
            }
            Quote quote = (Quote) new QuoteSelector()
                .selectOpportunityFieldsByQuoteIds(new Set<Id>{ ent.Quote__c })
                .executeQuery()
                .get(0);

            return quote?.Opportunity?.BusinessIdentity__c;
        }
    }
}