public class BatchJob_RecalculateMRR implements Database.Batchable<SObject> {
    private Set<Id> accIdsToRecalculate;
    private Boolean withUpdate;

    public BatchJob_RecalculateMRR(Set<Id> accIdsToRecalculate, Boolean withUpdate) {
        this.accIdsToRecalculate = accIdsToRecalculate;
        this.withUpdate = withUpdate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.Id,
                Account.Additional_Products_MRR__c,
                Account.Minute_Bundle__c,
                Account.No_of_InContact_Seats__c,
                Account.Total_MRR__c
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {this.accIdsToRecalculate})
            .executeQueryLocator();
    }


    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<String> families = new List<String> {'Training', 'Minutes Bundle', 'CC Service', 'Overage'};
        Map<Id,SObject> accountMap = new Map<Id,SObject>(accounts);
        Set<Id> accountIds = accountMap.keySet();
        Map<Id, List<Entitlement__c>> entitlementMap = new Map<Id, List<Entitlement__c>>();
        List<Account> accToUpdate = new List<Account>();
        List<Package__c> bapToUpdate = new List<Package__c>();

        for (Entitlement__c ent : (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlements()
            .selectFields(new List<String> {
                'Id',
                'Account__c',
                'Name',
                'Quantity__c',
                'EffectivePrice__c',
                'Total_Monthly_Price__c',
                'Product__r.Family',
                'Product__r.Charge_Term__c',
                'Product__r.Number_of_Minutes__c' })
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__c IN :bind0 AND Active__c = true' +
                ' AND Product__r.Sub_Category__c IN (\'Contact Center\',\'RingCentral Contact Center\')')
            .setQueryBindings(new List<Object> {accountIds})
            .executeQuery()) {
            Id accId = ent.Account__c;
            if (entitlementMap.containsKey(accId)) {
                entitlementMap.get(accId).add(ent);
            } else {
                entitlementMap.put(accId, new List<Entitlement__c> {ent});
            }
        }

        List<Package__c> baps = new PackageSelector()
            .selectPackagesForAccountUpdateByAccountIds(new List<Id>(accountIds))
            .executeQuery();

        for (Id accId : entitlementMap.keySet()) {
            /*
            Script is taken from https://wiki.ringcentral.com/display/CRM/Script+to+recalculate+MRR+for+Legacy+CC
            Calculation of Contact Center MRR is based on the formula:
            Seat_MRR__c + TFN_DID_MRR__c + Transport_MRR__c + Additional_Products_MRR__c
            We skip TFN_DID_MRR calculation because we have no information about it and only 5 accounts have it populated in production
            */

            Double SeatMRR = 0;
            Double NumberOfInContactSeats = 0;
            Double PricePerSeat = 0;
            Double TFN_DID_MMR = 0; // We hardcode it to zero
            Double TransportMRR = 0;
            Double ActualTransportMRR = 0;
            Double MinuteBundle = 0;
            Double AdditionalPorts = 0;
            Double PricePerPort = 0;
            Double AdditionalProductsMRR = 0;

            Double ContactCenterMRR = 0;
            List<Entitlement__c> ents = entitlementMap.get(accId);
            for (Entitlement__c e : ents) {
                if (e.Product__r.Family == Product2Helper.FAMILY_CCSERVICE && e.Name.containsIgnoreCase('Seat')) {
                    PricePerSeat = e.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL
                        ? e.EffectivePrice__c / 12
                        : e.EffectivePrice__c;
                } else if (e.Product__r.Family == Product2Helper.FAMILY_MINUTES_BUNDLE) {
                    ActualTransportMRR += e.Total_Monthly_Price__c;
                    MinuteBundle += e.Product__r.Number_of_Minutes__c;
                } else if (e.Name.containsIgnoreCase('Additional Port') && e.Product__r.Family != Product2Helper.FAMILY_OVERAGE) {
                    AdditionalPorts = e.Quantity__c;
                    PricePerPort = e.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL
                        ? e.EffectivePrice__c / 12
                        : e.EffectivePrice__c;
                }
            }

            for (Package__c bap : baps) {
                if (bap.Account__c == accId && PackageHelper.PACKAGE_STATUS_ACTIVE.equals(bap.Package_Status__c)) {
                    AdditionalProductsMRR += bap?.AdditionalProductsMRR__c;
                    NumberOfInContactSeats += bap?.No_of_InContact_Seats__c;
                }
            }
            SeatMRR = NumberOfInContactSeats * PricePerSeat;
            TransportMRR = ActualTransportMRR != 0 ? ActualTransportMRR : MinuteBundle * 0.014;

            ContactCenterMRR = SeatMRR + TFN_DID_MMR + TransportMRR + (AdditionalPorts * PricePerPort) + AdditionalProductsMRR;
            Account acc = (Account) accountMap.get(accId);
            System.debug('AccountId: ' + accId + ' // Current Total_MRR__c: ' + acc.Total_MRR__c + ' // New Contact_Center_MRR__c : ' + ContactCenterMRR);

            acc.No_of_InContact_Seats__c = NumberOfInContactSeats;
            acc.Minute_Bundle__c = MinuteBundle;

            accToUpdate.add(acc);

            Map<Id, Package__c> ccBapToProcessMap = PackageHelper.filterPackagesByService(baps, AccountHelper.SERVICE_TYPE_RCCC);
            Package__c ccBapToProcess = ccBapToProcessMap.get(accId);
            if (ccBapToProcess != null) {
                ccBapToProcess.Price_per_Seat__c = PricePerSeat;
                ccBapToProcess.Actual_transport_MRR__c = ActualTransportMRR;
                bapToUpdate.add(ccBapToProcess);
            }
        }

        if (withUpdate) {
            update accToUpdate;
            Triggers.switchOff();
            update bapToUpdate;
            Triggers.switchOn();
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}