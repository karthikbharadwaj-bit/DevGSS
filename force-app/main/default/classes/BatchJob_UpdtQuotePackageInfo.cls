global with sharing class BatchJob_UpdtQuotePackageInfo implements Database.Batchable<sObject>,Database.AllowsCallouts {
    private PlatformLog__c[] logs = new List<PlatformLog__c>();
    private final List<String> germanBiBillingCountries = new List<String>{
        'Germany','Austria'
    };
    private final List<String> nonFrenchBiBillingCountries = new List<String>{
        'Germany','Austria','United Kingdom',
        'United Kingdom of Great Britain and Northern Ireland','UK'
    };
    private final List<String> packageIdsForUpdate = new List<String>{
        '61','62','63','65','68','160','162','164','168','170'
    };

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query =
            'SELECT Id, Package_Info__c, Account.Billing_ID__c, Account.BillingCountry ' +
            'FROM Quote ' +
            'WHERE Opportunity.Brand_Name__c = \'RingCentral EU\' AND ' +
            'QuoteType__c != \'Agreement\' AND ' +
            'RecordType.Name IN (\'POC Quote\', \'Sales Quote V2\') AND ' +
            'Opportunity.StageName NOT IN (\'0. Downgraded\', \'7. Closed Won\')';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Quote> quotesToUpdate = new List<Quote>();
        List<Quote> quotes = (List<Quote>) scope;

        for (Quote q : quotes) {
            if (q.Package_Info__c != null) {
                BillingWrappers.QuotePackageInfo info = validatePackageInfo(q);

                if (info == null) {
                    continue;
                }
                String packageId = info.Id;

                if (OpportunityHelper.isExistingBusinessBilling(q)) {
                    BillingWrappers.BusinessIdentity accountBi = getAccountBi(q);

                    if (accountBi?.id != null && accountBi?.name != null && accountBi?.address != null && accountBi?.isDefault != null) {

                        q.Package_Info__c = setPackageInfo(q, accountBi);

                        if (validatePackageInfo(q) != null) {
                            quotesToUpdate.add(q);
                        }
                    }
                } else {
                    if (packageId != null && packageIdsForUpdate.contains(packageId)) {
                        BillingWrappers.BusinessIdentity packageBi = getPackageBi(packageId, q);

                        if (packageBi?.id != null && packageBi?.name != null && packageBi?.address != null && packageBi?.isDefault != null) {

                            q.Package_Info__c = setPackageInfo(q, packageBi);

                            if (validatePackageInfo(q) != null) {
                                quotesToUpdate.add(q);
                            }
                        }
                    }
                }
            }
        }

        Triggers.switchOff();
        Database.SaveResult[] result = Database.update(quotesToUpdate, false);
        Triggers.switchOn();

        logUpdateFailed(quotesToUpdate, result);
    }

    private String setPackageInfo(Quote q, BillingWrappers.BusinessIdentity newBi){
        List<Object> info = (List<Object>) JSON.deserializeUntyped(q.Package_Info__c);
        Map<String, Object> infoMap = (Map<String, Object>) info[0];
        Map<String, Object> packageBusinessIdentities = (Map<String, Object>) infoMap.get('packageBusinessIdentities');

        if (packageBusinessIdentities != null && !packageBusinessIdentities.isEmpty()) {
            updateBusinessIdentities(packageBusinessIdentities, newBi);
            infoMap.put('packageBusinessIdentities', packageBusinessIdentities);
        } else {
            BillingWrappers.BusinessIdentities bis = new BillingWrappers.BusinessIdentities();
            bis.defaultBi  = newBi;
            bis.selectedBi = newBi;
            bis.approvedBi = newBi;
            infoMap.put('packageBusinessIdentities', bis);
        }

        return JSON.serialize(info);
    }

    private void updateBusinessIdentities(Map<String, Object> packageBusinessIdentities, BillingWrappers.BusinessIdentity newBi) {
        setBusinessIdentity(packageBusinessIdentities, 'defaultBi', newBi);
        setBusinessIdentity(packageBusinessIdentities, 'selectedBi', newBi);
        setBusinessIdentity(packageBusinessIdentities, 'approvedBi', newBi);
    }

    private void setBusinessIdentity(Map<String, Object> packageBusinessIdentities, String biType, BillingWrappers.BusinessIdentity newBi) {
        Map<String, Object> currentBi = (Map<String, Object>) packageBusinessIdentities.get(biType);

        if (currentBi != null) {
            updateBusinessIdentity(currentBi, newBi);
            packageBusinessIdentities.put(biType, currentBi);
        } else {
            packageBusinessIdentities.put(biType, newBi);
        }
    }

    private void updateBusinessIdentity(Map<String, Object> currentBi, BillingWrappers.BusinessIdentity newBi) {
        currentBi.put('id', newBi.id);
        currentBi.put('name', newBi.name);
        currentBi.put('address', newBi.address);
        currentBi.put('isDefault', newBi.isDefault);
    }

    private BillingWrappers.BusinessIdentity getPackageBi(String packageId, Quote q) {
        BillingWrappers.BusinessIdentity bi = new BillingWrappers.BusinessIdentity();
        List<BillingWrappers.BusinessIdentity> packageBis = BusinessIdentitiesService.parseResponseBody(BusinessIdentitiesService.getResponseBody(packageId));

        for (BillingWrappers.BusinessIdentity packageBi : packageBis) {
            packageBi.isDefault = true;

            if (packageBi.id == '33' && germanBiBillingCountries.contains(q.Account.BillingCountry)) {
                bi = packageBi;
                break;
            } else if(packageBi.id == '1' && !nonFrenchBiBillingCountries.contains(q.Account.BillingCountry)){
                bi = packageBi;
                break;
            }
        }

        return bi;
    }

    private BillingWrappers.BusinessIdentity getAccountBi(Quote q) {
        BillingWrappers.BusinessIdentity accountBi;
        String accountInfo;
        String biID;

        try {
            accountInfo = NGBSAPI.getNGBSAccountSummary(q.Account.Billing_ID__c);
        } catch (Exception e) {
            String error = ' Account BillingId - ' + q.Account.Billing_ID__c + ' Not Fount in Billing System. Account Id - ' + q.Account.Id;
            System.debug(error);
            logs.add(PlatformLog.buildLog(q.Id, error, e.getMessage(), null, null));
        }

        if (accountInfo != null) {
            Pattern p = Pattern.compile('businessIdentityId":(\\d+)');
            Matcher pm = p.matcher(accountInfo);

            if(pm.find()){
                biID = pm.group(1);
            }
        }

        if (biID != null) {
            String endpoint = NGBSAPI.NGBS_CATALOG_PATH + '/businessidentities' + '/' + biID;
            String responseBody = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody();
            accountBi = (BillingWrappers.BusinessIdentity) JSON.deserialize(responseBody, BillingWrappers.BusinessIdentity.class);
            accountBi.isDefault = true;
        }

        return accountBi;
    }

    private BillingWrappers.QuotePackageInfo validatePackageInfo(Quote q) {
        BillingWrappers.QuotePackageInfo packageInfo;

        try {
            //JSON validation
            String serialized = JSON.serialize(q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1)).replace('\\', '');
            packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
                serialized.substring(1, serialized.length() - 1), BillingWrappers.QuotePackageInfo.class
            );
        } catch (Exception e) {
            String error = 'Package info for Quote ' + q.Id + ' populated with errors: ' + e.getStackTraceString();
            System.debug(error);
            logs.add(PlatformLog.buildLog(q.Id, e.getMessage(), error, null, null));
        }

        return packageInfo;
    }

    private void logUpdateFailed(List<Quote> quotesToUpdate, DataBase.SaveResult[] saveResultList) {
        for (Integer i = 0; i < saveResultList.size(); i++ ) {

            if (!saveResultList[i].isSuccess()) {
                for (Database.Error e : saveResultList[i].getErrors()) {
                    String error = 'Business Identity population script error: ' + e.getMessage();
                    System.debug(error);
                    logs.add(PlatformLog.buildLog(quotesToUpdate[i].Id, e.getMessage(), error, null, null));
                }
            }
        }
        PlatformLog.logResults(logs);
    }

    global void finish(Database.BatchableContext BC) {}
}