public with sharing class Batchjob_Exception_Error_Reprocess implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    static final String RECORDTYPENAME_CAMP_MEMB = 'Camp Memb Exception Log';
    private List<Id> recordTypeIds = new List<Id>();

    @testVisible
    private static Exception_Error_Reprocess_Helper.EmailInfoWrapper emailInfoForTesting;

    private Exception_Error_Reprocess_Helper.EmailInfoWrapper emailInfo;

    public Iterable<sObject> start(Database.BatchableContext bc) {
        recordTypeIds.add(
            Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(RECORDTYPENAME_CAMP_MEMB)
                .getRecordTypeId()
        );

        this.emailInfo = new Exception_Error_Reprocess_Helper.EmailInfoWrapper();

        return new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeId(recordTypeIds)
            .addOrdering(Exception_And_Notification_History__c.CreatedDate, QueryFactory.SortOrder.ASCENDING)
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext BC, list<sObject> EANHToProcess) {
        Map<String, List<Exception_And_Notification_History__c>> EANHByRecordTypeName = new Map<String, List<Exception_And_Notification_History__c>>();

        Map<Id, Schema.RecordTypeInfo> EANHRecordTypeInfoById = Exception_And_Notification_History__c.SObjectType.getDescribe()
            .getRecordTypeInfosById();

        for (Exception_And_Notification_History__c EANH : (list<Exception_And_Notification_History__c>) EANHToProcess) {
            String rtName = EANHRecordTypeInfoById.get(EANH.RecordTypeId).getName();

            if (!EANHByRecordTypeName.containsKey(rtName)) {
                EANHByRecordTypeName.put(rtName, new List<Exception_And_Notification_History__c>{});
            }

            EANHByRecordTypeName.get(rtName).add(EANH);
        }

        for (String rtName : EANHByRecordTypeName.keySet()) {
            if (rtName.equalsIgnoreCase(RECORDTYPENAME_CAMP_MEMB)) {
                Exception_Error_Reprocess_Helper.campaignMembers(EANHByRecordTypeName.get(rtName), this.emailInfo);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('Batchjob_Exception_Error_Reprocess');

        if (bjc != null && String.isNotBlank(bjc.ErrorEmailDistributionList__c)) {
            List<String> emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');

            Map<Exception_Error_Reprocess_Helper.REPORT_TYPES, String> reportUrlByReportType = this.emailInfo.getReportsUrl();

            String reportUrl_UpdateWithMoreFiveAttemps = reportUrlByReportType.containskey(
                    Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_MORE_5_ATTEMPS
                )
                ? reportUrlByReportType.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_MORE_5_ATTEMPS)
                : '';
            String reportUrl_InsertWithMoreFiveAttemps = reportUrlByReportType.containskey(
                    Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_MORE_5_ATTEMPS
                )
                ? reportUrlByReportType.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_MORE_5_ATTEMPS)
                : '';
            String reportUrl_InsertWithLessFiveAttemps = reportUrlByReportType.containskey(
                    Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_LESS_5_ATTEMPS
                )
                ? reportUrlByReportType.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_LESS_5_ATTEMPS)
                : '';
            String reportUrl_UpdateWithLessFiveAttemps = reportUrlByReportType.containskey(
                    Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_LESS_5_ATTEMPS
                )
                ? reportUrlByReportType.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_LESS_5_ATTEMPS)
                : '';

            Integer totalFailedCMWithoutId = this.emailInfo.getTotalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts();
            Integer totalFailedCMWithId = this.emailInfo.getTotalFailedCampaignMembersWithIdAndPassTheMaxAttempts();

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.saveAsActivity = false;
            mail.setToAddresses(emailsToSend);
            mail.setSubject('Batch job reprocess failed records ' + Datetime.now());
            mail.setHtmlBody(
                '' +
                '<h1>Batch job for reprocessing of failed records has finished.</h1>' +
                '<h2>Successful records: ' +
                this.emailInfo.getTotalSuccessCampaignMember() +
                '</h2>' +
                '<h2>Failed records:</h2>' +
                '<h3>On insert: ' +
                this.emailInfo.getTotalFailedCampaignMembersWithoutId() + ' ' + 
                reportUrl_InsertWithLessFiveAttemps + '</h3>' +
                '<h3>On update: ' +
                this.emailInfo.getTotalFailedCampaignMembersWithId() + ' ' + 
                reportUrl_UpdateWithLessFiveAttemps + '</h3>' +
                '<h2>Failed records that can’t be reprocessed:</h2>' +
                '<h3>For insert: ' +
                ((totalFailedCMWithoutId > 1) ? totalFailedCMWithoutId + ' ' + reportUrl_InsertWithMoreFiveAttemps: '0 ') +
                '</h3>' +
                '<h3>For update: ' +
                ((totalFailedCMWithId > 1) ? totalFailedCMWithId + ' ' + reportUrl_UpdateWithMoreFiveAttemps: '0') +
                '</h3>' +
                ((this.emailinfo.getTotalDeletedEANHRecords() > 1) ? '<h2>Total records deleted: \n' + this.emailinfo.getTotalDeletedEANHRecords() +
                '</h2>' : '') +
                '<h2>Total process: ' +
                this.emailinfo.getTotalProcess() +
                '</h2><br/>'
            );


            if (Test.isRunningTest()) {
                emailInfoForTesting = this.emailInfo;
            } else {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            }
        }
    }

    public void execute(SchedulableContext context) {
        Batchjob_Exception_Error_Reprocess batch = new Batchjob_Exception_Error_Reprocess();
        Database.executeBatch(batch);
    }
    
}