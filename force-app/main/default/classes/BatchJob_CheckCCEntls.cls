public with sharing class BatchJob_CheckCCEntls implements Database.Batchable<sObject>, Database.Stateful {

    @TestVisible
    static Integer emailLimits = 0; // variable for more convinient testing

    String query;

    public BatchJob_CheckCCEntls() {}

    public BatchJob_CheckCCEntls(String q) {
        if (!String.isBlank(q)) {
            this.query = q;
        }
    }

    Set<String> alreadyProcessedRcUserIds = new Set<String>();

    List<String> errorsList = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Database.QueryLocator result;

        if (String.isBlank(this.query)) {
            EntitlementSelector entlSelector = new EntitlementSelector();
            result = entlSelector.selectEntitlementsForCheckCCEntls().executeQueryLocator();
        } else {
            result = Database.getQueryLocator(this.query);
        }

        return result;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        Set<String> rcUserIdSet = new Set<String>();

        List<Entitlement__c> selectedEntitlements = (List<Entitlement__c>) scope;
        for (Entitlement__c entl : selectedEntitlements) {
            rcUserIdSet.add(entl.Account__r.RC_User_Id__c);
        }

        EntitlementSelector entlSelector = new EntitlementSelector();
        List<Object> bindings = new List<Object>();
        bindings.add(rcUserIdSet);
        if (!alreadyProcessedRcUserIds.isEmpty()) {
            bindings.add(alreadyProcessedRcUserIds);
        }
        List<Entitlement__c> selectedEntlList = entlSelector.selectEntitlementsByRcUserIdForCheckCCEntls(bindings)
            .executeQuery();

        Map<String, List<Entitlement__c>> accToEnts = new Map<String, List<Entitlement__c>>();

        for (Entitlement__c ent : selectedEntlList) {
            if (accToEnts.get(ent.Account__r.RC_User_Id__c) == null) {
                accToEnts.put(ent.Account__r.RC_User_Id__c, new List<Entitlement__c>());
            }
            accToEnts.get(ent.Account__r.RC_User_Id__c).add(ent);
        }

        if (!accToEnts.keySet().isEmpty()) {
            alreadyProcessedRcUserIds.addAll(accToEnts.keySet());
        }

        List<String> foundedErrors = findErros(accToEnts);

        if (foundedErrors.isEmpty()) {
            return;
        }

        errorsList.addAll(foundedErrors);
    }

    public void finish(Database.BatchableContext bc) {

        if (errorsList.isEmpty()) {
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        Set<String> emailAddresses = new Set<String>();
        emailAddresses.add(UserInfo.getUserEmail());
        emailAddresses.add('ApexErrors@ringcentral.com');
        emailAddresses.add('ringcentral@aquivalabs.com');

        Map<String, Emails__c> emailsCustomSetting = Emails__c.getall();
        if (emailsCustomSetting.containsKey('apexerrors')) {
            emailAddresses.add(emailsCustomSetting.get('apexerrors').Email_Address__c);
        }
        if (emailsCustomSetting.containsKey('bizservdev')) {
            emailAddresses.add(emailsCustomSetting.get('bizservdev').Email_Address__c);
        }

        emailAddresses.remove(null);

        String[] toAddresses = new String[] {};
        toAddresses.addAll(emailAddresses);
        mail.setToAddresses(toAddresses);

        mail.setSubject('CCEntitlementsChecker errors');

        mail.setPlainTextBody(
            String.join(errorsList, ' | \n\n')
        );

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        emailLimits = Limits.getEmailInvocations();
    }



    private List<String> findErros(Map<String, List<Entitlement__c>> accToEnts) {

        List<String> er = new List<String>();

        for (String accountId : accToEnts.keySet()) {

            Map<String, List<Entitlement__c>> productKeysToEnts = new Map<String, List<Entitlement__c>>();

            for (Entitlement__c ent : accToEnts.get(accountId)) {
                if (ent.Product__r.Product_Type__c == 'Seat' && ent.Product__r.Family == 'CC Service') {
                    if (productKeysToEnts.get('Seat') == null) {
                        productKeysToEnts.put('Seat', new List<Entitlement__c>());
                    }
                    productKeysToEnts.get('Seat').add(ent);
                } else if (ent.Product__r.Product_Type__c == 'Transport' && ent.Product__r.Family == 'Minutes Bundle') {
                    if (productKeysToEnts.get('MinuteBundle') == null) {
                        productKeysToEnts.put('MinuteBundle', new List<Entitlement__c>());
                    }
                    productKeysToEnts.get('MinuteBundle').add(ent);
                } else if (ent.Product__r.Product_Type__c == 'Inbound Calls' && ent.Product__r.Family == 'Minutes Bundle') {
                    if (productKeysToEnts.get('InboundCalls') == null) {
                        productKeysToEnts.put('InboundCalls', new List<Entitlement__c>());
                    }
                    productKeysToEnts.get('InboundCalls').add(ent);
                } else if (ent.Product__r.Product_Type__c == 'Outbound Calls to Local Numbers and Mobile' &&
                    ent.Product__r.Family == 'Minutes Bundle') {

                    if (productKeysToEnts.get('OutboundCalls') == null) {
                        productKeysToEnts.put('OutboundCalls', new List<Entitlement__c>());
                    }
                    productKeysToEnts.get('OutboundCalls').add(ent);
                } else if (ent.Product__r.Product_Type__c == 'Port' && ent.Product__r.Family == 'Add - Ons') {
                    if (productKeysToEnts.get('Port') == null) {
                        productKeysToEnts.put('Port', new List<Entitlement__c>());
                    }
                    productKeysToEnts.get('Port').add(ent);
                } else if (ent.Product__r.Family != 'Overage') {
                    String substrExtId = ent.Product__r.ExtId__c.right(
                        ent.Product__r.ExtId__c.length() - ent.Product__r.ExtId__c.indexOf('_') - 1
                    );
                    if (productKeysToEnts.get(substrExtId) == null) {
                        productKeysToEnts.put(substrExtId, new List<Entitlement__c>());
                    }
                    productKeysToEnts.get(substrExtId).add(ent);
                }
            }

            Map<String, List<Entitlement__c>> overageKeysToEnts = new Map<String, List<Entitlement__c>>();

            for (Entitlement__c ent : accToEnts.get(accountId)) {
                Entitlement__c seat = productKeysToEnts.get('Seat') != null ? productKeysToEnts.get('Seat').get(0) : null;
                if (seat != null && ent.Product__r.Parent__c == seat.Product__c && ent.Product__r.Family == 'Overage' &&
                    ent.Product__r.Product_Type__c == 'Seat') {

                    if (overageKeysToEnts.get('Seat') == null) {
                        overageKeysToEnts.put('Seat', new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get('Seat').add(ent);
                } else if (seat != null && ent.Product__r.Parent__c == seat.Product__c &&
                    ent.Product__r.Family == 'Overage' && ent.Product__r.Product_Type__c == 'Transport') {

                    if (overageKeysToEnts.get('MinuteBundle') == null) {
                        overageKeysToEnts.put('MinuteBundle', new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get('MinuteBundle').add(ent);

                } else if (seat != null && ent.Product__r.Parent__c == seat.Product__c &&
                    ent.Product__r.Family == 'Overage' && ent.Product__r.Product_Type__c == 'Inbound Calls') {

                    if (overageKeysToEnts.get('InboundCalls') == null) {
                        overageKeysToEnts.put('InboundCalls', new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get('InboundCalls').add(ent);

                } else if (seat != null && ent.Product__r.Parent__c == seat.Product__c &&
                    ent.Product__r.Family == 'Overage' &&
                    ent.Product__r.Product_Type__c == 'Outbound Calls to Local Numbers and Mobile') {

                    if (overageKeysToEnts.get('OutboundCalls') == null) {
                        overageKeysToEnts.put('OutboundCalls', new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get('OutboundCalls').add(ent);
                } else if (seat != null && ent.Product__r.Parent__c == seat.Product__c &&
                    ent.Product__r.Family == 'Overage' && ent.Product__r.Product_Type__c == 'Port') {

                    if (overageKeysToEnts.get('Port') == null) {
                        overageKeysToEnts.put('Port', new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get('Port').add(ent);
                } else if (ent.Product__r.Family == 'Overage') {
                    String substrExtId = ent.Product__r.ExtId__c.right(
                        ent.Product__r.ExtId__c.length() - ent.Product__r.ExtId__c.indexOf('_') - 1
                    );
                    if (!overageKeysToEnts.containsKey(substrExtId) && substrExtId.contains(' Overage')) { // remove ' Overage' for mapping by extId
                        substrExtId = substrExtId.replace(' Overage', '');
                    }
                    if (overageKeysToEnts.get(substrExtId) == null) {
                        overageKeysToEnts.put(substrExtId, new List<Entitlement__c>());
                    }
                    overageKeysToEnts.get(substrExtId).add(ent);
                }
            }

            for (String productKey : productKeysToEnts.keySet()) {
                List<Entitlement__c> products = productKeysToEnts.get(productKey);
                Entitlement__c product = products.get(0);
                List<Entitlement__c> overages = overageKeysToEnts.get(productKey);
                if (products.size() > 1) {
                    er.add(';' + product.Account__r.RC_User_Id__c + ';Product;' + product.Name + ';' +
                        product.Id + ';more than 1 product for the same key(' + productKey + ')');
                    continue;
                }
                if (overages == null) {
                    Boolean isFeeProduct = product.Name.containsIgnoreCase(' fee ');
                    Boolean isUpToNumberUsersProduct = product.Name.contains('(up to ') &&
                        product.Name.contains('users)');
                    Boolean isPerGBProduct = product.Name.contains('(per GB)');
                    Boolean isDirectDataAccessProduct = product.Name.contains('Direct Data Access');

                    // fee bypass, upToNumberUsers bypass, perGB bypass, isDirectDataAccess bypass
                    if (!isFeeProduct && !isUpToNumberUsersProduct && !isPerGBProduct && !isDirectDataAccessProduct) {
                        er.add(';' + product.Account__r.RC_User_Id__c + ';Product;' + product.Name + ';' +
                            product.Id + ';has no overages');
                    }
                    continue;
                }
                if (overages.size() > 1) {
                    er.add(';' + product.Account__r.RC_User_Id__c + ';Product;' + product.Name + ';' +
                        product.Id + ';has more than 1 overages for the same key');
                    continue;
                }
                Entitlement__c overage = overages.get(0);
                if (productKey == 'MinuteBundle') {
                    if (product.Product__r.Number_of_Minutes__c != overage.Quantity__c) {
                        er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' + overage.Name + ';' +
                            overage.Id + ';has incorrect quantity productKey(' + productKey + ');' +
                            overage.Quantity__c + ';' + product.Product__r.Number_of_Minutes__c + ';' +
                            (product.Product__r.Number_of_Minutes__c - overage.Quantity__c));
                        continue;
                    }
                } else if (productKey == 'InboundCalls') {
                    if (product.Product__r.Number_of_Minutes__c != overage.Quantity__c) {
                        er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' + overage.Name + ';' +
                            overage.Id + ';has incorrect quantity productKey(' + productKey + ');' +
                            overage.Quantity__c + ';' + product.Product__r.Number_of_Minutes__c + ';' +
                            (product.Product__r.Number_of_Minutes__c - overage.Quantity__c));
                        continue;
                    }
                } else if (productKey == 'OutboundCalls') {
                    if (product.Product__r.Number_of_Minutes__c != overage.Quantity__c) {
                        er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' + overage.Name + ';' +
                            overage.Id + ';has incorrect quantity productKey(' + productKey + ');' +
                            overage.Quantity__c + ';' + product.Product__r.Number_of_Minutes__c + ';' +
                            (product.Product__r.Number_of_Minutes__c - overage.Quantity__c));
                        continue;
                    }
                } else {
                    if (product.Quantity__c != overage.Quantity__c) {
                        er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' + overage.Name + ';' +
                            overage.Id + ';has incorrect quantity productKey(' + productKey + ');' +
                            overage.Quantity__c + ';' + product.Quantity__c + ';' +
                            (product.Quantity__c - overage.Quantity__c));
                        continue;
                    }
                }
            }

            for (String overageKey : overageKeysToEnts.keySet()) {
                Entitlement__c overage = overageKeysToEnts.get(overageKey).get(0);
                if (productKeysToEnts.get(overageKey) == null) {
                    er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' +
                        overageKeysToEnts.get(overageKey).get(0).Name + ';' +
                        overageKeysToEnts.get(overageKey).get(0).Id + ';has no products for it');
                    continue;
                }
                if (productKeysToEnts.get(overageKey).size() > 1) {
                    er.add(';' + overage.Account__r.RC_User_Id__c + ';Overage;' +
                        overageKeysToEnts.get(overageKey).get(0).Name + ';' +
                        overageKeysToEnts.get(overageKey).get(0).Id + ';has more than 1 product for it');
                    continue;
                }
            }
        }

        return er;
    }
}