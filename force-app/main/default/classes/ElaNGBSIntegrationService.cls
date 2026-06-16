public inherited sharing class ElaNGBSIntegrationService {

    public static final String RELATION_TYPE_FILTER_ELA = 'Relation_Type__c = \'' + AccountHelper.RELATION_TYPE_ELA + '\'';

    public void handleBillingAccSignUp(List<Account> billingAccounts) {
        List<Account> serviceAccounts = getServiceAccountsWithPackages(new Map<Id, Account>(billingAccounts).keySet());
        if (serviceAccounts.isEmpty()) {
            return;
        }
        Map<Id, List<Account>> parentIdChildAccountsMap = createParentIdChildAccMap(serviceAccounts);
        sendDataToNGBS(billingAccounts, parentIdChildAccountsMap);
    }

    public void handleMissedServiceAccSignUp(List<Account> billingAccounts, Set<Id> paidServiceAccountIds) {
        List<Account> serviceAccounts = getAccountsWithPackagesById(paidServiceAccountIds);
        if (serviceAccounts.isEmpty()) {
            return;
        }
        Map<Id, List<Account>> createParentIdChildAccMap = createParentIdChildAccMap(
            billingAccounts,
            new Map<Id, Account>(serviceAccounts)
        );
        sendDataToNGBS(billingAccounts, createParentIdChildAccMap);
    }

    public List<Account> getBillingPaidAccountsWithPackages(Set<Id> billingAccountIds) {
        return (List<Account>) new AccountSelector().selectPaidAccountWithPackage()
            .setCondition(
                'Id IN (SELECT Account__c FROM Package__c WHERE Account__c IN :bind0) AND ELA_Account_Type__c = \''
                    + AccountHelper.ACCOUNT_TYPE_ELA_BILLING + '\'  AND RC_Account_Status__c = \'' + AccountHelper.PAID_STATUS + '\''
            )
            .setQueryBindings(new List<Object>{billingAccountIds})
            .executeQuery();
    }

    public List<Account> getParentAccountsWithPackages(Set<Id> serviceAccountIds) {
        return (List<Account>) new AccountSelector().selectPaidAccountWithPackage()
            .subselect(new QueryFactory(new AccountRelationSelector(), AccountHelper.PARENT_ACCOUNT_JUNCTION_RELATIONSHIP)
                .setFactoryName('selectJunctionForParentAccount')
                .withoutSelectorOrderByIncluded()
                .setCondition('Child_Account__c IN :bind0 AND ' + RELATION_TYPE_FILTER_ELA)
                .setQueryBindings(new List<Object>{serviceAccountIds})
            )
            .setCondition(
                'Id IN (SELECT Parent_Account__c FROM AccountRelation__c WHERE Child_Account__c IN :bind0 AND '
                    +  RELATION_TYPE_FILTER_ELA + ') AND RC_Account_Status__c = \'' + AccountHelper.PAID_STATUS + '\''
            )
            .setQueryBindings(new List<Object>{serviceAccountIds})
            .executeQuery();
    }

    public List<Account> getServiceAccountsWithPackages(Set<Id> billingAccountIds) {
        return (List<Account>) new AccountSelector().selectPaidAccountWithPackage()
            .subselect(new QueryFactory(new AccountRelationSelector(), AccountHelper.CHILD_ACCOUNT_JUNCTION_RELATIONSHIP)
                .setFactoryName('selectJunctionForChildAccount')
                .withoutSelectorOrderByIncluded()
                .setCondition(RELATION_TYPE_FILTER_ELA)
            )
            .setCondition(
                'Id IN (SELECT Child_Account__c FROM AccountRelation__c WHERE Parent_Account__c IN :bind0 AND '
                    +  RELATION_TYPE_FILTER_ELA + ') AND RC_Account_Status__c = \'' + AccountHelper.PAID_STATUS + '\''
            )
            .setQueryBindings(new List<Object>{billingAccountIds})
            .executeQuery();
    }

    private List<Account> getAccountsWithPackagesById(Set<Id> ids) {
        return new AccountSelector().selectAccountsWithPackagesById(new List<Object>{ids})
            .executeQuery();
    }

    private Map<Id, List<Account>> createParentIdChildAccMap(List<Account> parentAccounts, Map<Id, Account> childrenAccountsMap) {
        Map<Id, List<Account>> parentIdChildAccMap = new Map<Id, List<Account>>();
        for(Account parentAccount : parentAccounts) {
            putElementToMap(
                parentIdChildAccMap,
                parentAccount.Id,
                childrenAccountsMap.get(parentAccount.Parent_Account_Relation__r[0].Child_Account__c)
            );
        }
        return parentIdChildAccMap;
    }

    private Map<Id, List<Account>> createParentIdChildAccMap(List<Account> childAccounts) {
        Map<Id, List<Account>> parentIdChildAccMap = new Map<Id, List<Account>>();
        for (Account childAccount : childAccounts) {
            putElementToMap(
                parentIdChildAccMap,
                childAccount.Child_Account_Relation__r[0].Parent_Account__c,
                childAccount
            );
        }
        return parentIdChildAccMap;
    }

    private void putElementToMap(Map<Id, List<Account>> accountMap, Id key, Account element) {
        if( ! accountMap.containsKey(key)) {
            accountMap.put(key, new List<Account>());
        }
        accountMap.get(key).add(element);
    }

    private void sendDataToNGBS(List<Account> parentAccounts, Map<Id, List<Account>> parentIdChildAccountsMap) {
        for (Account parentAccount : parentAccounts) {
            List<Account> childAccounts = parentIdChildAccountsMap.get(parentAccount.Id);
            if(null == childAccounts ||
               childAccounts.isEmpty() ||
               null == parentAccount.Service_Accounts__r ||
               parentAccount.Service_Accounts__r.isEmpty() ||
               null == parentAccount.Service_Accounts__r[0].Account_Package_Id__c ) {
                continue;
            }
            String requestBody = prepareRequestBody(
                parentAccount.Service_Accounts__r[0].Account_Package_Id__c
            );
            for (Account childAccount : childAccounts) {
                if (null == childAccount ||
                    null == childAccount.Service_Accounts__r ||
                    null == childAccount.Billing_ID__c ||
                    childAccount.Service_Accounts__r.isEmpty() ||
                    null == childAccount.Service_Accounts__r[0].Account_Package_Id__c) {
                    continue;
                }
                String requestURL = prepareRequestURL(
                    childAccount.Billing_ID__c,
                    childAccount.Service_Accounts__r[0].Account_Package_Id__c
                );
                requestNGBS(
                    requestURL,
                    requestBody
                );
            }
        }
    }

    @Future(Callout=true)
    private static void requestNGBS(String requestURl, String requestBody) {
        try {
            NGBSAPI.requestNGBS(
                requestURl,
                HttpHelper.METHOD_POST,
                requestBody,
                HttpHelper.CONTENT_TYPE_APPLICATION_JSON,
                null
            );
        } catch (Exception e) {
            PlatformLog.logException(ElaNGBSIntegrationService.class.getName(), e);
        }
    }

    private String prepareRequestBody(String billingAccountId) {
        return '{"type":"Service","parentId":"' + billingAccountId + '"}';
    }

    private String prepareRequestURL(String billingId, String packageId) {
        return String.format(
            NGBSAPI.NGBS_PACKAGE_ELA_SETTINGS_UPDATE,
            new List<String>{billingId, packageId}
        );
    }
}