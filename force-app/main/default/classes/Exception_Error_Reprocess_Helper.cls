public with sharing class Exception_Error_Reprocess_Helper {
    public static final String RECORDTYPENAME_CAMPAIGNMEMBERRETRY = CampaignMemberRetry__e.SObjectType.getDescribe()
        .getName();
    public static final String RECORDTYPENAME_CAMPAIGNMEMBERLOG = Campaign_Member_Log__e.SObjectType.getDescribe()
        .getName();

    public static final String DEVELOPERNAME_EANH_MDT = 'Camp_Memb_Exception_Log';
    public static final String INVALID_CROSS_REFERENCE = 'invalid cross reference id';
    public static final String DELETED = 'deleted';
    public static final String ALREADY_A_MEMBER = 'already a campaign member';
    public static final String CAMPAIGN_ID_OR_MEMBER_NULL = 'either the member id or the campaignid is null';

    public static void campaignMembers(List<Exception_And_Notification_History__c> EANHs, EmailInfoWrapper emailInfo) {
        emailinfo.addTotalProcess(EANHs.size());

        Map<String, CampaignMember> campaignMemberListTriggerOnByKeyStringInsert = new Map<String, CampaignMember>();
        Map<String, CampaignMember> campaignMemberListTriggerOffByKeyStringInsert = new Map<String, CampaignMember>();
        Map<String, CampaignMember> campaignMemberListTriggerOnByKeyStringUpdate = new Map<String, CampaignMember>();

        Map<String, Exception_And_Notification_History__c> EANHMapToDelete = new Map<String, Exception_And_Notification_History__c>();
        Map<String, Exception_And_Notification_History__c> EANHMapToUpdate = new Map<String, Exception_And_Notification_History__c>();

        Map<String, Exception_And_Notification_History__c> EANHByKey = new Map<String, Exception_And_Notification_History__c>();

        Set<Id> leadsId = new Set<Id>();
        Set<Id> contactsId = new Set<Id>();
        Set<Id> campaignsId = new Set<Id>();

        Integer maxAttempts = null;
        Exception_reprocess_Setting__mdt EANHmdt = Exception_reprocess_Setting__mdt.getInstance(DEVELOPERNAME_EANH_MDT);

        maxAttempts = (EANHmdt != null && EANHmdt.Max_attempts__c != null) ? EANHmdt.Max_attempts__c.intValue() : 5;

        for (Exception_And_Notification_History__c EANH : EANHs) {
            if (EANH.Attempts__c >= maxAttempts) {
                emailInfo.addExceptionsWithMoreThanMaxAttempts(EANH);
                continue;
            }

            EANH.Attempts__c = (EANH.Attempts__c != null) ? EANH.Attempts__c + 1 : 1;
            CampaignMember cm;

            if (EANH.Object_Type__c == RECORDTYPENAME_CAMPAIGNMEMBERRETRY) {
                //If the EANH is attempting to insert a Campaign Member duplicated then it will be removed.
                CampaignMemberRetry__e cmRetry = (CampaignMemberRetry__e) JSON.deserialize(
                    EANH.Affected_record_ID__c,
                    CampaignMemberRetry__e.class
                );
                String key = cmRetry.CampaignId__c + '-' + cmRetry.ContactId__c + '-' + cmRetry.LeadId__c;

                if (EANH.Exception_desc__c.containsIgnoreCase('DUPLICATE_VALUE')) {
                    EANHMapToDelete.put(key + '-' + EANH.id, EANH);
                    continue;
                }

                if (EANHByKey.containsKey(key) && !EANHMapToDelete.containsKey(key + '-' + EANH.id)) {
                    emailinfo.addTotalProcess(-1);
                    EANHMapToDelete.put(key + '-' + EANH.id, EANHByKey.remove(key));
                }

                EANHByKey.put(key, EANH);

                cm  = new CampaignMember(
                    campaignId = addIdToSet(cmRetry.CampaignId__c, campaignsId) ? Id.valueOf(cmRetry.CampaignId__c) : null,
                    contactId  = addIdToSet(cmRetry.ContactId__c, contactsId) ? Id.valueOf(cmRetry.ContactId__c) : null,
                    leadId = addIdToSet(cmRetry.LeadId__c, leadsId) ? Id.valueOf(cmRetry.LeadId__c) : null
                );

                cm.Primary_Marketing_Asset__c = (cmRetry.Primary_Marketing_Asset__c != null && cmRetry.Primary_Marketing_Asset__c != 'null') ? 
                    cmRetry.Primary_Marketing_Asset__c : 
                    null;

                if (cmRetry.Trigger_On__c) {
                    campaignMemberListTriggerOnByKeyStringInsert.put(key, cm);
                } else {
                    campaignMemberListTriggerOffByKeyStringInsert.put(key, cm);
                }
            } else if (EANH.Object_Type__c == RECORDTYPENAME_CAMPAIGNMEMBERLOG) {
                if (EANH.Affected_Record_Id__c != null) {
                    cm = (CampaignMember) JSON.deserialize(EANH.Affected_Record_Id__c, CampaignMember.class);
                } else {
                    cm = (CampaignMember) JSON.deserialize(
                        EANH.Field_Changes__c.replace('&quot;', '"'),
                        CampaignMember.class
                    );
                }

                String key = '';

                if (EANH.Record_Id__c.contains('-')) {
                    key = EANH.Record_Id__c;
                    campaignMemberListTriggerOnByKeyStringInsert.put(key, cm);

                    String[] ids = key.split('-');
                    cm = cm.clone(false, true);
                    cm.campaignId = addIdToSet(ids[0], campaignsId) ? Id.valueOf(ids[0]) : null;
                    cm.contactId  = addIdToSet(ids[1], contactsId) ? Id.valueOf(ids[1]) : null;
                    cm.leadId = addIdToSet(ids[2], leadsId) ? Id.valueOf(ids[2]) : null;
                } else {
                    cm.Id = EANH.Record_Id__c;

                    key = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId;
                    
                    campaignsId.add(cm.campaignId);

                    addIdToSet(cm.ContactId, contactsId);
                    addIdToSet(cm.LeadId, leadsId);

                    campaignMemberListTriggerOnByKeyStringUpdate.put(key, cm);
                }
                if (EANHByKey.containsKey(key) && !EANHMapToDelete.containsKey(key + '-' + EANH.id)) {
                    emailinfo.addTotalProcess(-1);
                    EANHMapToDelete.put(key + '-' + EANH.id, EANHByKey.remove(key));
                }
                EANHByKey.put(key, EANH);
            }
        }
        
        for (
            CampaignMember cm : (List<CampaignMember>) new CampaignMemberSelector()
                .selectCampaignMembersByLeadAndCampaignORByContactAndCampaign(new object[]{
                    leadsId,
                    campaignsId,
                    contactsId
                })
                .executeQuery()
        ) {
            String key = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId;
            if (EANHByKey.containsKey(key)) {
                Exception_And_Notification_History__c EANH = EANHByKey.get(key);

                boolean deleteEANH = false;
                
                if (campaignMemberListTriggerOnByKeyStringInsert.containsKey(key)) {
                    campaignMemberListTriggerOnByKeyStringInsert.remove(key);
                    deleteEANH = true;
                } else if (campaignMemberListTriggerOffByKeyStringInsert.containsKey(key)) {
                    campaignMemberListTriggerOffByKeyStringInsert.remove(key);
                    deleteEANH = true;
                } else if (
                    campaignMemberListTriggerOnByKeyStringUpdate.containskey(Key) &&
                    cm.lastModifiedDate > EANH.createdDate &&
                    cm.LastModifiedById != UserInfo.getUserId()
                ) {
                    campaignMemberListTriggerOnByKeyStringUpdate.remove(key);
                    deleteEANH = true;
                }
                if (deleteEANH && EANH != null) {
                    emailinfo.addTotalProcess(-1);
                    EANHByKey.remove(key);
                    EANHMapToDelete.put(key + '-' + EANH.id, EANH);
                }
            }
        }
        if (campaignMemberListTriggerOnByKeyStringInsert.size() > 0) {
            List<CampaignMember> cmToInsert = new List<CampaignMember>(
                campaignMemberListTriggerOnByKeyStringInsert.values()
            );
            tryInsertOrUpdateCampaignMember(
                cmToInsert,
                true,
                true,
                EANHMapToDelete,
                EANHMapToUpdate,
                EANHByKey,
                emailInfo
            );
        }

        if (campaignMemberListTriggerOffByKeyStringInsert.size() > 0) {
            List<CampaignMember> cmToInsert = new List<CampaignMember>(
                campaignMemberListTriggerOffByKeyStringInsert.values()
            );
            tryInsertOrUpdateCampaignMember(
                cmToInsert,
                false,
                true,
                EANHMapToDelete,
                EANHMapToUpdate,
                EANHByKey,
                emailInfo
            );
        }

        if (campaignMemberListTriggerOnByKeyStringUpdate.size() > 0) {
            List<CampaignMember> cmToUpdate = new List<CampaignMember>(
                campaignMemberListTriggerOnByKeyStringUpdate.values()
            );
            tryInsertOrUpdateCampaignMember(
                cmToUpdate,
                true,
                false,
                EANHMapToDelete,
                EANHMapToUpdate,
                EANHByKey,
                emailInfo
            );
        }

        if (EANHMapToUpdate.size() > 0) {
            Database.update(new List<Exception_And_Notification_History__c>(EANHMapToUpdate.values()), false);
        }

        if (EANHMapToDelete.size() > 0) {
            Database.delete(new List<Exception_And_Notification_History__c>(EANHMapToDelete.values()), false);
        }
    }

    //returns if the specified Id was added to the set
    private static Boolean addIdToSet(string idToAdd, Set<Id> idSet) {
        Boolean added = false;
        if (idToAdd != null && idToAdd != 'null') {
            try {
                idSet.add(Id.valueOf(idToAdd));
                added = true;
            } catch(Exception e){
                //invalid id...
            }
        }
        return added;
    }

    public static void tryInsertOrUpdateCampaignMember(
        List<CampaignMember> cmToInsertOrUpdate,
        Boolean triggerOn,
        Boolean isInsert,
        Map<String, Exception_And_Notification_History__c> EANHMapToDelete,
        Map<String, Exception_And_Notification_History__c> EANHMapToUpdate,
        Map<String, Exception_And_Notification_History__c> EANHByKey,
        EmailInfoWrapper emailInfo
    ) {
        CampaignMemberTriggerHandler.dmlFromExceptionAndNotificationReprocessingBatch = true;
        Database.SaveResult[] results;
        if (triggerOn) {
            if (isInsert) {
                results = Database.Insert(cmToInsertOrUpdate, false);
            } else {
                results = Database.update(cmToInsertOrUpdate, false);
            }
        } else {
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = true;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = true;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = true;
            results = Database.Insert(cmToInsertOrUpdate, false);
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = false;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = false;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = false;
        }
        Integer i = 0;
        for (Database.SaveResult result : results) {
            CampaignMember cm = cmToInsertOrUpdate[i++];
            String key = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId;
            Exception_And_Notification_History__c EANH = EANHByKey.get(key);
            String keyandEANH = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId + '-' + EANH.id;
            Boolean deleteEANH = false;
            if (result.isSuccess()) {
                deleteEANH = true;
                emailInfo.addInsertedCampaignMember();
            } else {
                String exMessage = result.getErrors()[0].getMessage();

                if (exMessage.containsIgnoreCase('DUPLICATE_VALUE') || exMessage.containsIgnoreCase(DELETED) || 
                    exMessage.containsIgnoreCase(ALREADY_A_MEMBER) || exMessage.containsIgnoreCase(INVALID_CROSS_REFERENCE) ||
                    exMessage.containsIgnoreCase(CAMPAIGN_ID_OR_MEMBER_NULL)) {
                    deleteEANH = true;
                    emailInfo.addTotalDeletedEANHRecords();
                } else {
                    if (String.valueOf(cm.Id) == null) {
                        emailInfo.addFailedCampaignMemberWithoutId();
                    } else {
                        emailInfo.addFailedCampaignMemberWithId();
                    }
                    if (EANH != null) {
                        if (
                            EANH.Object_Type__c == RECORDTYPENAME_CAMPAIGNMEMBERLOG &&
                            EANH.Affected_Record_Id__c == null
                        ) {
                            EANH.Affected_Record_Id__c = EANH.Field_Changes__c.replace('&quot;', '"');
                            EANH.Field_Changes__c = null;
                        }
                        EANH.Exception_desc__c = exMessage;
                        if (!EANHMapToUpdate.containsKey(keyandEANH)) {
                            EANHMapToUpdate.put(keyandEANH, EANH);
                        }
                    }
                }
            }
            if (deleteEANH && EANH != null && !EANHMapToDelete.containsKey(keyandEANH)) {
                //Maybe this EANH can be deleted before this transaction.
                EANHMapToDelete.put(keyandEANH, EANH);
            }
        }
    }

    public enum REPORT_TYPES {
        INSERT_WITH_LESS_5_ATTEMPS,
        UPDATE_WITH_LESS_5_ATTEMPS,
        INSERT_WITH_MORE_5_ATTEMPS,
        UPDATE_WITH_MORE_5_ATTEMPS
    }

    public class EmailInfoWrapper {
        private Integer totalProcess;
        private Integer totalInsertCampaignMembers;
        private Integer totalFailedCampaignMembersWithId;
        private Integer totalFailedCampaignMembersWithoutId;
        private Integer totalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts;
        private Integer totalDeletedEANHRecords;
        private Integer totalFailedCampaignMembersWithIdAndPassTheMaxAttempts;

        public EmailInfoWrapper() {
            this.totalInsertCampaignMembers = 0;
            this.totalFailedCampaignMembersWithId = 0;
            this.totalFailedCampaignMembersWithoutId = 0;
            this.totalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts = 0;
            this.totalFailedCampaignMembersWithIdAndPassTheMaxAttempts = 0;
            this.totalDeletedEANHRecords = 0;
            this.totalProcess = 0;
        }

        public Map<REPORT_TYPES, String> getReportsUrl() {
            RingCentralVariousSettings__c rcSettings = RingCentralVariousSettings__c.getOrgDefaults();
            Map<REPORT_TYPES, String> URLByReportType = new Map<REPORT_TYPES, String>();
            if (rcSettings.Report_Id_Campaign_Member_Insert__c != null) {
                URLByReportType.put(
                    REPORT_TYPES.INSERT_WITH_MORE_5_ATTEMPS,
                    generateUrl(rcSettings.Report_Id_Campaign_Member_Insert__c, 'Go to report')
                );
            }
            if (rcSettings.Report_Id_Campaign_Member_Update__c != null) {
                URLByReportType.put(
                    REPORT_TYPES.UPDATE_WITH_MORE_5_ATTEMPS,
                    generateUrl(rcSettings.Report_Id_Campaign_Member_Update__c, 'Go to report')
                );
            }
            if(rcSettings.Report_Id_Reprocess_CM_Update__c != null){
                URLByReportType.put(
                    REPORT_TYPES.UPDATE_WITH_LESS_5_ATTEMPS,
                    generateUrl(rcSettings.Report_Id_Reprocess_CM_Update__c, 'Go to report')
                );
            }
            if(rcSettings.Report_Id_Reprocess_CM_Insert__c != null){
                URLByReportType.put(
                    REPORT_TYPES.INSERT_WITH_LESS_5_ATTEMPS,
                    generateUrl(rcSettings.Report_Id_Reprocess_CM_Insert__c, 'Go to report')
                );
            }
            return URLByReportType;
        }

        public void addExceptionsWithMoreThanMaxAttempts(Exception_And_Notification_History__c EANH) {
            if (EANH.Object_Type__c == RECORDTYPENAME_CAMPAIGNMEMBERRETRY) {
                this.totalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts++;
            } else if (EANH.Object_Type__c == RECORDTYPENAME_CAMPAIGNMEMBERLOG) {
                CampaignMember cm;
                if (EANH.Affected_Record_Id__c != null) {
                    cm = (CampaignMember) JSON.deserialize(EANH.Affected_Record_Id__c, CampaignMember.class);
                } else {
                    cm = (CampaignMember) JSON.deserialize(
                        EANH.Field_Changes__c.replace('&quot;', '"'),
                        CampaignMember.class
                    );
                }
                if (String.valueOf(cm.Id) != null) {
                    this.totalFailedCampaignMembersWithIdAndPassTheMaxAttempts++;
                } else {
                    this.totalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts++;
                }
            }
        }

        public void addTotalProcess(Integer amount) {
            this.totalProcess += amount;
        }

        public void addInsertedCampaignMember() {
            this.totalInsertCampaignMembers++;
        }

        public void addFailedCampaignMemberWithId() {
            this.totalFailedCampaignMembersWithId++;
        }

        public void addFailedCampaignMemberWithoutId() {
            this.totalFailedCampaignMembersWithoutId++;
        }

        public void addTotalDeletedEANHRecords() {
            this.totalDeletedEANHRecords++;
        }

        public Integer getTotalProcess() {
            return this.totalProcess;
        }

        public Integer getTotalSuccessCampaignMember() {
            return this.totalInsertCampaignMembers;
        }

        public Integer getTotalFailedCampaignMembersWithId() {
            return this.totalFailedCampaignMembersWithId;
        }

        public Integer getTotalFailedCampaignMembersWithoutId() {
            return this.totalFailedCampaignMembersWithoutId;
        }

        public Integer getTotalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts() {
            return this.totalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts;
        }

        public Integer getTotalFailedCampaignMembersWithIdAndPassTheMaxAttempts() {
            return this.totalFailedCampaignMembersWithIdAndPassTheMaxAttempts;
        }
        
        public Integer getTotalDeletedEANHRecords() {
            return this.totalDeletedEANHRecords;
        }
        
        private String generateURL(String id, String label) {
            return '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + id + '"> ' + label + '</a>';
        }
    }
}