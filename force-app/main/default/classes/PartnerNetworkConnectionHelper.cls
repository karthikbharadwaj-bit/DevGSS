public class PartnerNetworkConnectionHelper {
    private static final String CASE_CREATION_SUCCESS_WITH_ERROR = 'Case was created with error. ';
    public static List<PartnerNetworkRecordConnection> selectPnrcByLocalRecordId(Set<Id> localRecordIdSet) {
        return (List<PartnerNetworkRecordConnection>) new PartnerNetworkRecordConnectionSelector()
            .selectPnrcByLocalRecordId(localRecordIdSet)
            .withoutSelectorOrderByIncluded()
            .executeQuery();
    }

    public static PartnerNetworkRecordConnection selectPnrcByLocalRecordId(Id localRecordId) {
        return (PartnerNetworkRecordConnection) new ListOptional(selectPnrcByLocalRecordId(new Set<Id> { localRecordId })).getFirst();
    }


    public static Map<Id, PartnerNetworkRecordConnection> createLocalRecordIdToPnrcMap(List<PartnerNetworkRecordConnection> pnrcs) {
        Map<Id, PartnerNetworkRecordConnection> localRecordIdToPnrcMap = new Map<Id, PartnerNetworkRecordConnection>();
        for (PartnerNetworkRecordConnection pnrc : pnrcs) {
            localRecordIdToPnrcMap.put(pnrc.LocalRecordId, pnrc);
        }
        return localRecordIdToPnrcMap;
    }

    public static Map<Id, PartnerNetworkRecordConnection> getLocalRecordIdToPnrcMap(Set<Id> idSet) {
        return createLocalRecordIdToPnrcMap(
            selectPnrcByLocalRecordId(idSet)
        );
    }

    public static Map<Id, PartnerNetworkRecordConnection> getLocalRecordIdToPnrcMap(List<SObject> sObjects) {
        return getLocalRecordIdToPnrcMap(
            new Map<Id, SObject>(sObjects).keySet()
        );
    }

    public static PartnerNetworkRecordConnection buildSObject(Id connectionId, Id sObjectId, String relatedRecords) {
        return (PartnerNetworkRecordConnection) new SObjectBuilder(PartnerNetworkRecordConnection.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerNetworkRecordConnection.ConnectionId => connectionId,
                PartnerNetworkRecordConnection.LocalRecordId => sObjectId,
                PartnerNetworkRecordConnection.RelatedRecords => relatedRecords,
                PartnerNetworkRecordConnection.SendClosedTasks => false,
                PartnerNetworkRecordConnection.SendEmails => false,
                PartnerNetworkRecordConnection.SendOpenTasks => false
            })
            .build()
            .getRecord();
    }

    @future
    public static void shareSObject(Id connectionId, Id sObjectId, String relatedRecords, Id oppId) {
        if (Test.isRunningTest()) {
            return;
        }
        try {
            insert buildSObject(connectionId, sObjectId, relatedRecords);
        } catch (Exception ex) {
            handleSharingError(oppId, ex);
        }
    }

    @TestVisible
    private static void handleSharingError(Id oppId, Exception ex) {
        Opportunity opp = IcbHelper.selectOpportunityForInContactCaseSharing(oppId);
        Case icbCase = IcbHelper.selectICBCase(opp);
        System.enqueueJob(new ICBNotificationQueueable(opp, icbCase, CASE_CREATION_SUCCESS_WITH_ERROR, ex));
    }
}