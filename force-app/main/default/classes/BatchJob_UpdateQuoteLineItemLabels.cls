public with sharing class BatchJob_UpdateQuoteLineItemLabels implements Database.Batchable<sObject>, Database.Stateful {

    private Map<Id, PlatformLog__c> logs = new Map<Id, PlatformLog__c>();

    private String query = '';

    private List<LabelMapping> mappingsList = new List<LabelMapping>{
        new LabelMapping(
            'shippingReq',
            'auto',
            new Set<String>{'HDR', 'HDRF', 'HD', 'HDRD'}
        ),
        new LabelMapping(
            'shippingReq',
            'manual',
            new Set<String>{'HDHS', 'HDO', 'HDRO'}
        )
    };

    public class LabelMapping {
        public String labelName = '';
        public String labelValue = '';
        public Set<String> categoryCodes = new Set<String>();

        public LabelMapping(String labelName, String labelValue, Set<String> categoryCodes) {
            this.labelName = labelName;
            this.labelValue = labelValue;
            this.categoryCodes = categoryCodes;
        }
    }

    public BatchJob_UpdateQuoteLineItemLabels() {}

    public BatchJob_UpdateQuoteLineItemLabels(String query) {
        this.query = query;
    }

    public BatchJob_UpdateQuoteLineItemLabels(String query, List<LabelMapping> mappingsList) {
        this(query);
        this.mappingsList = mappingsList;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (String.isNotBlank(this.query)) {
            return Database.getQueryLocator(this.query);
        } else {
            return new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .setCondition('(Product2.ExtID__c LIKE \'%_HDR_%\' OR Product2.ExtID__c LIKE \'%_HDRF_%\' ' +
                'OR Product2.ExtID__c LIKE \'%_HD_%\' OR Product2.ExtID__c LIKE \'%_HDRD_%\' OR Product2.ExtID__c LIKE \'%_HDHS_%\' ' +
                'OR Product2.ExtID__c LIKE \'%_HDO_%\' OR Product2.ExtID__c LIKE \'%_HDRO_%\') ' +
                'AND ((Quote.Opportunity.StageName != \'' + OpportunityHelper.STAGE_NAME_CLOSED_WON + '\') ' +
                'OR (Quote.Opportunity.StageName = \'' + OpportunityHelper.STAGE_NAME_DOWNGRADED + '\' AND Quote.Opportunity.isOrderStepCompleted__c = false) ' +
                'OR (Quote.Opportunity.StageName = \'' + OpportunityHelper.STAGE_NAME_CLOSED_WON + '\' AND Quote.Opportunity.isOrderStepCompleted__c = false)) ' +
                'AND CreatedDate = LAST_N_DAYS:600')
                .executeQueryLocator();
        }
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Map<Id, QuoteLineItem> updatedQlis = new Map<Id, QuoteLineItem>();
        for (LabelMapping mapping : mappingsList) {
            updatedQlis.putAll(
                addLabels(mapping, (List<QuoteLineItem>) scope)
            );
        }

        Triggers.switchOff();
        Database.SaveResult[] saveResults = Database.update(updatedQlis.values(), false);
        logFailedUpdates(updatedQlis.values(), saveResults);
        Triggers.switchOn();
    }

    public void finish(Database.BatchableContext bc) {
        PlatformLog.logResults(logs.values());
    }

    private Map<Id, QuoteLineItem> addLabels(LabelMapping mapping, List<QuoteLineItem> qliList) {

        Map<Id, QuoteLineItem> result = new Map<Id, QuoteLineItem>();

        if (mapping == null || qliList == null || qliList.isEmpty()) {
            return result;
        }

        for (QuoteLineItem qli : qliList) {
            try {
                qli.PackageInfo__c = addLabels(mapping, qli.PackageInfo__c);
                qli.Package_Info_QLI__c = addLabels(mapping, qli.Package_Info_QLI__c);
                result.put(qli.Id, qli);
            } catch (Exception ex) {
                String error = 'QuoteLineItem.Id = ' + qli.Id + ';\n' + ex.getMessage();
                PlatformLog__c log = PlatformLog.buildLog(
                    'BatchJob_UpdateQuoteLineItemLabels',
                    error,
                    ex.getStackTraceString(),
                    '',
                    ''
                );
                logs.put(qli.Id, log);
            }
        }

        return result;
    }

    @TestVisible
    private String addLabels(LabelMapping mapping, String pInfoJson) {
        if (mapping == null || String.isBlank(pInfoJson)) {
            return pInfoJson;
        }

        Map<String, Object> qliPackageInfo = (Map<String, Object>) JSON.deserializeUntyped(pInfoJson);
        String categoryCode = (String) qliPackageInfo.get('categoryCode');
        if (mapping.categoryCodes.contains(categoryCode)) {

            Map<String, Object> updatedLabels = new Map<String, Object>();
            if (qliPackageInfo.containsKey('labels') && qliPackageInfo.get('labels') != null) {
                updatedLabels = (Map<String, Object>) qliPackageInfo.get('labels');
                updatedLabels.put(mapping.labelName, mapping.labelValue);
            } else {
                updatedLabels.put(mapping.labelName, mapping.labelValue);
            }

            qliPackageInfo.put('labels', updatedLabels);
        }

        return JSON.serialize(qliPackageInfo);
    }

    private void logFailedUpdates(List<QuoteLineItem> records, DataBase.SaveResult[] saveResultList) {
        for (Integer i = 0; i < saveResultList.size(); i++) {
            if (!saveResultList[i].isSuccess()) {
                for (Database.Error error : saveResultList[i].getErrors()) {
                    String errorString = 'QuoiteLineItem.Id = ' + records[i].Id + ';\n' + error.getMessage();
                    PlatformLog__c log = PlatformLog.buildLog(
                        'BatchJob_UpdateQuoteLineItemLabels',
                        error.getMessage(),
                        errorString,
                        '',
                        ''
                    );
                    logs.put(records[i].Id, log);
                }
            }
        }
    }
}