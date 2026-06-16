global class BatchJob_TransferJustification implements Database.Batchable<SObject>, Database.Stateful {
    private String query;

    global BatchJob_TransferJustification() {}

    global BatchJob_TransferJustification(String q) {
        if (!String.isBlank(q)) {
            this.query = q;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator result;
        if (String.isBlank(this.query)) {
            DealQualificationSelector dqSelector = new DealQualificationSelector();
            result = new DealQualificationSelector()
                .selectDQs()
                .selectFields(
                    new Set<SObjectField>{
                        DQ_Deal_Qualification__c.Justification_For_Discount__c,
                        DQ_Deal_Qualification__c.Justification_Description__c
                    }
                )
                .executeQueryLocator();
        } else {
            result = Database.getQueryLocator(this.query);
        }
        return result;
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<DQ_Deal_Qualification__c> dqList = (List<DQ_Deal_Qualification__c>) scope;
        for (DQ_Deal_Qualification__c dq : dqList) {
            if (dq.Justification_Description__c == null && dq.Justification_For_Discount__c != null) {
                dq.Justification_Description__c = dq.Justification_For_Discount__c;
            }
        }
        update dqList;
    }

    global void finish(Database.BatchableContext BC) {
    }
}