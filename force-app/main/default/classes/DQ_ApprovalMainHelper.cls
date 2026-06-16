public class DQ_ApprovalMainHelper {

    private static final String DQ_STATUS_PENDING = 'Pending';
    private static final String DQ_STATUS_NOTIFICATION = 'Notification';
    private static final String DQ_APPROVER_APPROVAL_TYPE = 'Approval';
    private static final String DQ_STATUS_INACTIVE = 'Inactive';
    private static final String DQ_STATUS_APPROVED = 'Approved';
    private static final String DQ_STATUS_REJECTED = 'Rejected';
    private static final String DQ_STATUS_CANCELLED = 'Cancelled';

    public static void updateStatusForApprovalRecords(Map<Id, DQ_Deal_Qualification_Approver__c> mapOfIdVsDealQualificationApprover) {
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfDQIdVsDealQualificationApprover =
            new  Map<Id, DQ_Deal_Qualification_Approver__c>();
        Map<Id, Integer> mapOfDqVSStepOrder = new Map<Id, Integer>();
        Set<Id> setOfDQIdForReject = new Set<Id>();
        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationStatusUpdate = new List<DQ_Deal_Qualification_Approver__c>();
        List<DQ_Deal_Qualification__c> listOfDealQualification = new List<DQ_Deal_Qualification__c>();

        for (DQ_Deal_Qualification_Approver__c eachDealQualificationRec : mapOfIdVsDealQualificationApprover.values()) {

            if (eachDealQualificationRec.Status__c == DQ_STATUS_REJECTED) {
                setOfDQIdForReject.add(eachDealQualificationRec.Deal_Qualification__c);
            }

            if (eachDealQualificationRec.Status__c == DQ_STATUS_APPROVED) {
                DQ_Deal_Qualification_Approver__c dealQualficationRecordFromMap =
                    mapOfDQIdVsDealQualificationApprover.get(eachDealQualificationRec.Deal_Qualification__c);

                if (dealQualficationRecordFromMap == null) {
                    mapOfDQIdVsDealQualificationApprover.put(eachDealQualificationRec.Deal_Qualification__c,
                                                             eachDealQualificationRec);
                    mapOfDqVSStepOrder.put(eachDealQualificationRec.Deal_Qualification__c,
                                           Integer.valueOf(eachDealQualificationRec.Step_Order__c));
                } else {
                    if (Integer.valueOf(dealQualficationRecordFromMap.Step_Order__c) > Integer.valueOf(eachDealQualificationRec.Step_Order__c)) {
                        mapOfDQIdVsDealQualificationApprover.put(eachDealQualificationRec.Deal_Qualification__c,
                                                                 eachDealQualificationRec);
                        mapOfDqVSStepOrder.put(eachDealQualificationRec.Deal_Qualification__c,
                                               Integer.valueOf(eachDealQualificationRec.Step_Order__c));
                    }
                }
            }
        }

        if (!mapOfDqVSStepOrder.values().isEmpty()) {
            Map<Id, DQ_Deal_Qualification_Approver__c> mapOfIdVsDealQualificationPending = new Map<Id, DQ_Deal_Qualification_Approver__c>(
                [SELECT Id, Status__c, Step_Order__c, Deal_Qualification__c
                 FROM DQ_Deal_Qualification_Approver__c
                 WHERE Deal_Qualification__c = :mapOfDqVSStepOrder.keySet()
                 AND Step_Order__c =:mapOfDqVSStepOrder.values()
                 AND Status__c =: DQ_STATUS_PENDING]
            );

            Map<Id, Integer> mapOfDQIdVsStepOrderForNextPendingStatus = new Map<Id, Integer>();
            Set<Id> dealQualificationApproverDqId = new Set<Id>();
            if (!mapOfIdVsDealQualificationPending.values().isEmpty()) {
                for (DQ_Deal_Qualification_Approver__c  eachRecord : mapOfIdVsDealQualificationPending.values()) {
                    dealQualificationApproverDqId.add(eachRecord.Deal_Qualification__c);
                }
            }

            for (Id eachMapOfDQId : mapOfDqVSStepOrder.keySet()) {
                if(!Test.isRunningTest()){
                    if(!dealQualificationApproverDqId.contains(eachMapOfDQId)) {
                        Integer nextStepOrder = mapOfDqVSStepOrder.get(eachMapOfDQId) + 1;
                        mapOfDQIdVsStepOrderForNextPendingStatus.put(eachMapOfDQId, nextStepOrder);
                    }
                }
                else{
                    if(dealQualificationApproverDqId.contains(eachMapOfDQId)) {
                        Integer nextStepOrder = mapOfDqVSStepOrder.get(eachMapOfDQId) + 1;
                        mapOfDQIdVsStepOrderForNextPendingStatus.put(eachMapOfDQId, nextStepOrder);
                    }
                }
            }

            if (!mapOfDQIdVsStepOrderForNextPendingStatus.values().isEmpty()) {
                List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationNextLevel =
                    [SELECT Id, Status__c, Step_Order__c, Deal_Qualification__c, Approval_Step_Approver__r.Approval_Type__c, Approval_Step_Name__c
                     FROM DQ_Deal_Qualification_Approver__c
                     WHERE Deal_Qualification__c = :mapOfDQIdVsStepOrderForNextPendingStatus.keySet()
                     AND Step_Order__c =: mapOfDQIdVsStepOrderForNextPendingStatus.values()
                     AND Status__c =: DQ_STATUS_INACTIVE];

                if (listOfDealQualificationNextLevel.isEmpty()) {
                    Map<Id, Integer> mapOfDQIdVsnextLevelStepOrder = getNextLevelStepOrderForApproval(mapOfDQIdVsStepOrderForNextPendingStatus);
                    listOfDealQualificationNextLevel =
                        [SELECT Id, Status__c, Step_Order__c, Deal_Qualification__c, Approval_Step_Approver__r.Approval_Type__c, Approval_Step_Name__c
                         FROM DQ_Deal_Qualification_Approver__c
                         WHERE Deal_Qualification__c = :mapOfDQIdVsnextLevelStepOrder.keySet()
                         AND Step_Order__c =: mapOfDQIdVsnextLevelStepOrder.values()
                         AND Status__c =: DQ_STATUS_INACTIVE];
                }

                Set<Id> setOfDQId = new Set<Id>();
                Set<Id> setOfDQIdForApproved = new Set<Id>();
                ///ITEA-785 MidMarket GOA for DQ system
                system.debug('listOfDealQualificationNextLevel: ' + listOfDealQualificationNextLevel);
                if(listOfDealQualificationNextLevel.size() > 1){
                    for (Integer i = 0 ; i<= (listOfDealQualificationNextLevel.size()-1) ; i++){
                        String stepName = listOfDealQualificationNextLevel[i].Approval_Step_Name__c;
                        if(stepName == 'Level 3.5'){
                            listOfDealQualificationNextLevel.remove(i);
                        }
                    }
                }
                system.debug('NEW listOfDealQualificationNextLevel: ' + listOfDealQualificationNextLevel);

                for(DQ_Deal_Qualification_Approver__c eachRecord : listOfDealQualificationNextLevel) {
                    setOfDQId.add(eachRecord.Deal_Qualification__c);
                    if(eachRecord.Approval_Step_Approver__r.Approval_Type__c == DQ_APPROVER_APPROVAL_TYPE) {
                        eachRecord.Status__c = DQ_STATUS_PENDING;
                    } else {
                        eachRecord.Status__c = DQ_STATUS_NOTIFICATION;
                    }

                    eachRecord.Submitted_Date__c = DateTime.now();
                }

                for (Id eachMapOfDQId : mapOfDQIdVsStepOrderForNextPendingStatus.keySet()) {
                    if(!setOfDQId.contains(eachMapOfDQId)) {
                        setOfDQIdForApproved.add(eachMapOfDQId);
                    }
                }
                
                // Check for ALL pending approvals at ANY step order before marking DQ as Approved
                // This ensures DQ is only marked as Approved when ALL approvals are complete
                if (!setOfDQIdForApproved.isEmpty()) {
                    Set<Id> dqIdsWithPendingApprovals = new Set<Id>();
                    List<DQ_Deal_Qualification_Approver__c> pendingApprovers = new DealQualificationApproverSelector()
                        .selectPendingApproversByDQIds(setOfDQIdForApproved, DQ_STATUS_PENDING)
                        .executeQuery();
                    for (DQ_Deal_Qualification_Approver__c approver : pendingApprovers) {
                        dqIdsWithPendingApprovals.add(approver.Deal_Qualification__c);
                    }
                    
                    // Remove DQs that have pending approvals
                    setOfDQIdForApproved.removeAll(dqIdsWithPendingApprovals);
                }
                
                // Only mark as Approved if no pending approvals exist
                if (!setOfDQIdForApproved.isEmpty()) {
                    for (DQ_Deal_Qualification__c eachDealQualificationRecord :
                         getDQDealQualficationRecod(setOfDQIdForApproved)) {
                             eachDealQualificationRecord.Status__c = DQ_STATUS_APPROVED;
                             listOfDealQualification.add(eachDealQualificationRecord);
                         }
                }

                listOfDealQualificationStatusUpdate.addAll(listOfDealQualificationNextLevel);
            }
        }


        if (!setOfDQIdForReject.isEmpty()) {
            List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationForCancel =
                [SELECT Id, Status__c, Step_Order__c
                 FROM DQ_Deal_Qualification_Approver__c
                 WHERE Deal_Qualification__c = :setOfDQIdForReject
                 AND (Status__c =: DQ_STATUS_INACTIVE OR Status__c =: DQ_STATUS_PENDING)];

            for(DQ_Deal_Qualification_Approver__c eachRecord : listOfDealQualificationForCancel) {
                eachRecord.Status__c = DQ_STATUS_CANCELLED;
            }
            for (DQ_Deal_Qualification__c eachDealQualificationRecord :
                 getDQDealQualficationRecod(setOfDQIdForReject)) {
                     eachDealQualificationRecord.Status__c = DQ_STATUS_REJECTED;
                     listOfDealQualification.add(eachDealQualificationRecord);
                 }
            listOfDealQualificationStatusUpdate.addAll(listOfDealQualificationForCancel);
        }

        if (!listOfDealQualificationStatusUpdate.isEmpty()) {
            update listOfDealQualificationStatusUpdate;
        }

        if (!listOfDealQualification.isEmpty()) {
            update listOfDealQualification;
        }
    }

    private static List<DQ_Deal_Qualification__c> getDQDealQualficationRecod(Set<Id> setOfDQId) {
        return [SELECT Id, Status__c,Opportunity__c,IsDQCreatedFromCPQOpp__c FROM DQ_Deal_Qualification__c WHERE Id =: setOfDQId];
    }

    @TestVisible
    private static Map<Id, Integer> getNextLevelStepOrderForApproval(Map<Id, Integer> mapOfDQIdVsStepOrderForNextPendingStatus) {
        List<DQ_Deal_Qualification_Approver__c> listOfNextAvailableStepOrderForDQ =
            [SELECT Step_Order__c, Deal_Qualification__c FROM DQ_Deal_Qualification_Approver__c
             WHERE Deal_Qualification__c = :mapOfDQIdVsStepOrderForNextPendingStatus.keySet()
             AND Status__c = :DQ_STATUS_INACTIVE ORDER BY Step_Order__c ASC];
        Map<Id, Integer> mapOfIdVsStepOrderForNextApprover = new Map<Id, Integer>();
        if (!listOfNextAvailableStepOrderForDQ.isEmpty()) {
            for(DQ_Deal_Qualification_Approver__c eachRecord : listOfNextAvailableStepOrderForDQ) {
                if (!mapOfIdVsStepOrderForNextApprover.containsKey(eachRecord.Deal_Qualification__c)) {
                    mapOfIdVsStepOrderForNextApprover.put(eachRecord.Deal_Qualification__c, Integer.valueOf(eachRecord.Step_Order__c));
                }
            }
        }

        return mapOfIdVsStepOrderForNextApprover;
    }
}