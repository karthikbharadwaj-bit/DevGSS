public with sharing class PackageHelper {
    public static final String PACKAGE_OFFER_TYPE_FREE = 'Free';
    public static final String PACKAGE_OFFER_TYPE_PAID = 'Paid';
    public static final String PACKAGE_OFFER_TYPE_POC = 'POC';
    public static final String PACKAGE_OFFER_TYPE_TRIAL = 'Trial (other)';
    public static final List<String> ACTIVE_PACKAGE_OFFER_TYPES = new List<String>{
        PACKAGE_OFFER_TYPE_FREE,
        PACKAGE_OFFER_TYPE_PAID,
        PACKAGE_OFFER_TYPE_POC,
        PACKAGE_OFFER_TYPE_TRIAL
    };

    public static final String PROSERV_SERVICE_TYPE = 'Professional Services';
    public static final String PACKAGE_STATUS_ACTIVE = 'Active';
    public static final String PACKAGE_STATUS_CANCELED = 'Canceled';
    public static final String PACKAGE_STATUS_CANCELLED = 'Cancelled';
    public static final String PACKAGE_STATUS_DELETED = 'Deleted';
    public static final String PACKAGE_STATUS_DISABLED = 'Disabled';

    public static final String RINGCX_PACKAGE_NAME = 'RingCX';

    public static final Map<SObjectField, SObjectField> PACKAGE_TO_ACCOUNT_FIELDS_MAP = new Map<SObjectField, SObjectField> {
        Package__c.RC_Signup_Funnel__c => Account.RC_Signup_Funnel__c,
        Package__c.RC_Attribution_Channel__c => Account.RC_Attribution_Channel__c,
        Package__c.RC_Attribution_L2__c => Account.RC_Attribution_L2__c,
        Package__c.RC_Attribution_L3__c => Account.RC_Attribution_L3__c,
        Package__c.RC_Attribution_Campaign__c => Account.RC_Attribution_Campaign__c,
        Package__c.Attribution_partner_id__c => Account.Attribution_partner_id__c,
        Package__c.BMID__c => Account.BMID__c,
        Package__c.PID__c => Account.PID__c,
        Package__c.AID__c => Account.AID__c,
        Package__c.OID__c => Account.OID__c
    };

    public static final Set<SObjectField> PACKAGE_FIELDS = PACKAGE_TO_ACCOUNT_FIELDS_MAP.keySet();

    public static Decimal getReportedMRS(Package__c bap, Account account) {
        if (account == null || bap == null) {
            return null;
        }
        if(bap.Service_Type__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
            Decimal combinedEngageDigitalMRR = account.CombinedEngageDigitalMRR__c != null
                ? account.CombinedEngageDigitalMRR__c
                : 0;
            Decimal combinedEngageVoiceMRR = account.CombinedEngageVoiceMRR__c != null
                ? account.CombinedEngageVoiceMRR__c
                : 0;

            return combinedEngageDigitalMRR
                - combinedEngageVoiceMRR;
        } else {
            return bap != null && bap.Sales_Order_MRS__c != null ? bap.Sales_Order_MRS__c : null;
        }
    }

    public static List<Package__c> filterPackagesByCreatedDateAndService(List<Package__c> packages) {
        List<Package__c> filteredPackages = new List<Package__c>();
        if (packages.isEmpty()) {
            return filteredPackages;
        }
        Map<Id, List<Package__c>> accountToPackagesMap = PackageHelper.mapAccountIdToPackages(packages);
        for (Id accID : accountToPackagesMap.keySet()) {
            List<Package__c> pkgs = new List<Package__c>();
            for (Package__c pkg : accountToPackagesMap.get(accID)) {
                if (String.isNotBlank(pkg.Service_Type__c)) {
                    pkgs.add(pkg);
                }
            }
            if(pkgs.isEmpty()) {
                continue;
            }
            if (pkgs.size() > 1) {
                pkgs.sort(new PackageComparator());
            }
            filteredPackages.add(pkgs[0]);
        }

        return filteredPackages;
    }

    public static Map<Id, List<Package__c>> mapAccountIdToPackages(List<Package__c> packages) {
        Map<Id, List<Package__c>> accountToPackagesMap = new Map<Id, List<Package__c>>();
        if (packages.isEmpty()) {
            return accountToPackagesMap;
        }
        for (Package__c pkg : packages) {
            if (!accountToPackagesMap.containsKey(pkg.Account__c)) {
                accountToPackagesMap.put(pkg.Account__c, new List<Package__c>());
            }
            accountToPackagesMap.get(pkg.Account__c).add(pkg);
        }
        return accountToPackagesMap;
    }

    public static Map<String, List<Package__c>> mapServiceToPackages(List<Package__c> packages) {
        Map<String, List<Package__c>> serviceToPackagesMap = new Map<String, List<Package__c>>();
        if (packages.isEmpty()) {
            return serviceToPackagesMap;
        }
        for (Package__c pkg : packages) {
            if (!serviceToPackagesMap.containsKey(pkg.Service_Type__c)) {
                serviceToPackagesMap.put(pkg.Service_Type__c, new List<Package__c>());
            }
            serviceToPackagesMap.get(pkg.Service_Type__c).add(pkg);
        }
        return serviceToPackagesMap;
    }

    public class PackageComparator implements Comparator<Package__c> {
        public Integer compare(Package__c pkg1, Package__c pkg2) {
            Map<String, Integer> serviceOrder = new Map<String, Integer>{
                'Office' => 1,
                'Engage Digital Standalone' => 2,
                'RingCentral Contact Center' => 3,
                'Engage Voice Standalone' => 4
            };

            if (pkg1.CreatedDate != null && pkg2.CreatedDate != null) {
                Long pkg1Date = pkg1.CreatedDate.getTime();
                Long pkg2Date = pkg2.CreatedDate.getTime();
                if (pkg1Date < pkg2Date) {
                    return -1;
                } else if (pkg1Date > pkg2Date) {
                    return 1;
                }
            }

            Integer lastOrder = serviceOrder.size() + 1;
            Integer pkg1Order = serviceOrder.containsKey(pkg1?.Service_Type__c) ? serviceOrder.get(pkg1?.Service_Type__c) : lastOrder;
            Integer pkg2Order = serviceOrder.containsKey(pkg2?.Service_Type__c) ? serviceOrder.get(pkg2?.Service_Type__c) : lastOrder;
            return pkg1Order - pkg2Order;
        }
    }

    public static Map<Id, Package__c> filterPackagesByService(List<Package__c> packages) {
        return filterPackagesByService(packages, null);
    }

    public static Map<Id, Package__c> filterPackagesByService(List<Package__c> packages, String service) {
        Map<Id, Package__c> resultAccountToPackageMap = new Map<Id, Package__c>();
        Map<String, List<Package__c>> serviceToPackagesMap = new Map<String, List<Package__c>>();
        if (packages.isEmpty()) {
            return resultAccountToPackageMap;
        }

        // Map account IDs to their packages
        Map<Id, List<Package__c>> accountToPackagesMap = mapAccountIdToPackages(packages);

        for (Id accountId : accountToPackagesMap.keySet()) {
            List<Package__c> accountPackages = accountToPackagesMap.get(accountId);
            String serviceToUse = service;

            // Set default service only if there is more than one package
            if (accountPackages.size() > 1 && service == null) {
                serviceToUse = QuoteHelper.NGBS_OFFICE_PRODUCT;
            }

            // Map service to package
            serviceToPackagesMap = mapServiceToPackages(accountPackages);

            Package__c matchingPackage = null;
            if (serviceToPackagesMap.containsKey(serviceToUse)) {
                for (Package__c pkg : serviceToPackagesMap.get(serviceToUse)) {
                    matchingPackage = pkg;
                    break;
                }
            } else if (service == null && !serviceToPackagesMap.isEmpty()) {
                List<Package__c> pkgs = serviceToPackagesMap.values().get(0);
                matchingPackage = pkgs?.get(0);
            }

            if (matchingPackage != null) {
                resultAccountToPackageMap.put(accountId, matchingPackage);
            }
        }

        return resultAccountToPackageMap;
    }

    public static Package__c buildPackage(String oppId, String accountId, String billingPackageId, String productName) {
        Package__c pkg = new Package__c();
        pkg.Account_Package_Id__c = billingPackageId;
        pkg.Opportunity__c = oppId;
        pkg.Account__c = accountId;
        pkg.Service_Type__c = productName;
        return pkg;
    }
    
    @future
    // this method is used in after insert trigger
    // and updates packages that provide attribution fields for account
    public static void markPackagesAsMarketing(Set<Id> pkgIds) {
        pkgIds.remove(null);
        if (pkgIds.isEmpty()) {
            return;
        }

        List<Package__c> pkgs = new List<Package__c>();
        for (Id pkgId : pkgIds) {
            pkgs.add(new Package__c(Id = pkgId, IsUsedForAccountAttribution__c = true));
        }

        Triggers.switchOff();
        update pkgs;
        Triggers.switchOn();
    }

    public static Map<Id, Package__c> collectAccIdToPackageMap(Map<Id, List<Package__c>> accIdToPackagesMap) {
        Map<Id, Package__c> accIdToFieldsPackageMap = new Map<Id, Package__c>();
        for (Id accId : accIdToPackagesMap.keySet()) {
            Package__c oldestPkg = getOldestPackageWithMarketingFields(accIdToPackagesMap.get(accId));
            if (oldestPkg != null) {
                accIdToFieldsPackageMap.put(accId, oldestPkg);
            }
        }
        return accIdToFieldsPackageMap;
    }

    private static Package__c getOldestPackageWithMarketingFields(List<Package__c> pkgs) {
        List<Package__c> validPkg = getValidPackagesForMarketingUpdate(pkgs);
        if (validPkg.isEmpty()) {
            return null;
        }
        if (validPkg.size() > 1) {
            validPkg.sort(new PackageComparator());
        }

        return (Package__c) ListHelper.first(validPkg);
    }

    private static List<Package__c> getValidPackagesForMarketingUpdate(List<Package__c> pkgs) {
        Map<Id, Package__c> validPkgsMap = new Map<Id, Package__c>();
        for (SObjectField packageField : PACKAGE_FIELDS) {
            for (Package__c pkg : pkgs) {
                if (pkg.IsUsedForAccountAttribution__c) {
                    return new List<Package__c> { pkg };
                }
                if (pkg.get(packageField) != null && !validPkgsMap.containsKey(pkg.Id)) {
                    validPkgsMap.put(pkg.Id, pkg);
                    continue;
                }
            }
        }
        return validPkgsMap.values();
    }
}