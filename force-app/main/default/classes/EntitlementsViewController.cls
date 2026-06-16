/**
 * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/169738252/Entitlements+View
 */
public class EntitlementsViewController {

    public static final String ASSETS_RESPONSE_DATA_KEY = 'assets';
    public static final String ENTITLEMENT_DETAILS_RESPONSE_DATA_KEY = 'entitlementDetails';
    public static final List<Schema.SObjectField> quoteFieldList = new List<Schema.SObjectField> {
        Quote.Payment_Plan__c,
        Quote.Auto_Renewal__c,
        Quote.Term_months__c,
        Quote.CurrencyIsoCode
    };

    public Account acc { get; set; }

    public EntitlementsViewController() {
        String accId = Apexpages.currentpage().getparameters().get('Id');
        acc = new Account(Id = accId);
    }

    public EntitlementsViewController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new String[]{
                    'Billing_ID__c',
                    'Name'
            });
        }

        acc = (Account) stdController.getRecord();
    }

    @AuraEnabled
    public static Response getEntitlements(String accId, String billingId) {
        Response syncWithDWHResult = new Response();
        if (String.isBlank(billingId)) {
            try {
                syncWithDWHResult = EntitlementSync.syncWithDWH(accId);
            } catch (Exception e) {
                syncWithDWHResult.warning('Error during sync from Data Warehouse. Using Existing Entitlements.');
                syncWithDWHResult.warning(e.getMessage());
            }
        }

        try {
            List<Entitlement__c> data = new List<Entitlement__c>();
            Map<Id, List<ProductDetail__c>> entitlementDetails = new Map<Id, List<ProductDetail__c>>();

            if (!String.isBlank(accId)) {
                data = (List<Entitlement__c>) new EntitlementSelector()
                    .selectEntitlementsForViewEntPage(accId)
                    .executeQuery();

                for (ProductDetail__c pd : [SELECT Id, RampUp__c, RampUpStartDate__c,
                                                Entitlement__c, QuantityOrThreshold__c
                                            FROM ProductDetail__c
                                            WHERE Entitlement__c IN :new Map<Id, Entitlement__c>(data).keySet()
                                                AND IsActive__c = true]) {
                    if (!entitlementDetails.containsKey(pd.Entitlement__c)) {
                        entitlementDetails.put(pd.Entitlement__c, new List<ProductDetail__c>());
                    }
                    entitlementDetails.get(pd.Entitlement__c).add(pd);
                }
            } else {
                syncWithDWHResult.error('AccountId is empty.');
            }
            syncWithDWHResult.setData(EntitlementSync.ENTITLEMENT_RESPONSE_DATA_KEY, data);
            syncWithDWHResult.setData(ENTITLEMENT_DETAILS_RESPONSE_DATA_KEY, entitlementDetails);
        } catch (Exception e) {
            AquivaHelper.throwAuraException('An error occurred while receiving the entitlements. (' + e.getMessage() + ')');
        }

        return syncWithDWHResult;
    }

    @AuraEnabled
    public static String getNGBSLicenseSettings() {
      SettingsService.LicensesSettings settings = SettingsService.getLicenseSettings(true, new List<String>());
      return JSON.serialize(settings);
    }

    @AuraEnabled
    public static String getPackagesFromBilling(String accId, String billingId) {
        // Get child accounts for MPL support
        List<Account> childAccounts = (List<Account>) new AccountSelector()
            .selectChildAccounts(new List<Object>{new Set<Id>{accId}})
            .executeQuery();

        List<String> billingIdsToProcess = new List<String>{billingId};
        for (Account acc : childAccounts) {
            if (String.isNotBlank(acc.Billing_ID__c)) {
                billingIdsToProcess.add(acc.Billing_ID__c);
            }
        }

        List<EntitlementsViewHelper.PackageInfo> packages = new List<EntitlementsViewHelper.PackageInfo>();
        for (String currentBillingId : billingIdsToProcess) {
            try {
                String packageInfoResponse = NGBSAPI.getNGBSAccountSummary(currentBillingId);
                if (String.isBlank(packageInfoResponse)) {
                    continue;
                }
                packageInfoResponse = packageInfoResponse.replace('"currency":','"currencyCode":');
                EntitlementsViewHelper.AccountSummaryResponse accountSummary =
                    (EntitlementsViewHelper.AccountSummaryResponse)
                        JSON.deserialize(packageInfoResponse, EntitlementsViewHelper.AccountSummaryResponse.class);

                for (EntitlementsViewHelper.PackageInfo pkg : accountSummary.packages) {
                    pkg.billingId = currentBillingId;
                    packages.add(pkg);
                }

            } catch (Exception e) {
                throw e;
            }
        }
        String responseJSON = JSON.serialize(packages, true);
        responseJSON = responseJSON.replace('"currencyCode":','"currency":');

        //return JSON.serialize(packages, true);
        return responseJSON;
    }

    @AuraEnabled
    public static String getBillingInfo(String billingId, String packageId) {
        List<EntitlementsViewHelper.GroupedLicense> groupedLicenses =
            EntitlementsViewHelper.getBillingInfoForPackage(billingId, packageId);
        return JSON.serialize(groupedLicenses);
    }

    @AuraEnabled
    public static Response getAssets(Id accId) {
        Response result = new Response();

        try {
            List<Asset> data = new List<Asset>();

            if (!String.isBlank(accId)) {
                data = [
                        SELECT Id, Name, Quantity, Completion_Date__c, Delivered_Quantity__c, AccountId, Active__c,
                                Price, Product2Id, Product2.Name, Product2.Charge_Term__c, Product2.Sub_Category__c, Start_Date__c,
                                Total_Price__c, Unit_Price__c, Discount_Number__c, Discount_Type__c, CurrencyIsoCode, (
                                SELECT Id, Qty__c, UnitPrice, UnitPriceWithoutDiscount__c, CurrencyIsoCode,
                                        Discount_Type__c, Discount_Number__c, Order.Id, Order.Name,
                                        Order.Submitted_Date__c, Product2.Charge_Term__c
                                FROM Order_Products__r
                                WHERE Order.Submitted_Date__c != null
                        )
                        FROM Asset
                        WHERE AccountId = :accId
                        AND Product2.Charge_Term__c = :Product2Helper.CHARGE_TERM_ONE_TIME
                ];

            } else {
                result.error('AccountId is empty.');
            }
            result.setData(ASSETS_RESPONSE_DATA_KEY, data);
        } catch (Exception e) {
            AquivaHelper.throwAuraException('An error occurred while receiving the assets. (' + e.getMessage() + ')');
        }

        return result;
    }

    @AuraEnabled
    public static Account getAccount(Id accId) {
        return [
            SELECT
                Id,
                Name,
                Number_of_DL_s__c,
                RC_Tier__c,
                Payment_Plan__c,
                Sales_Agreement_Start_Date__c,
                Sales_Agreement_End_Date__c,
                Term_months__c,
                CurrencyIsoCode
            FROM Account
            WHERE Id = :accId
        ];
    }

    @AuraEnabled (cacheable=true)
    public static Quote getActiveSalesAgreement(Id accountId) {
        List<Quote> activeQuotes = (List<Quote>) new QuoteSelector()
                .selectActiveQuoteFromAccount(quoteFieldList, accountId)
                .executeQuery();
        
        return !activeQuotes.isEmpty() ? activeQuotes.get(0) : new Quote();
    }
}