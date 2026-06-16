public class DQ_AutoApproveEngine {


    public static void autoApproveEligibleDQApprovals(
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfDealQualificationOldApprover,
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfDealQualificationNewApprover)
    {

        List<DQ_Deal_Qualification_Approver__c> listOfNeedToApproveDQApprover = new List<DQ_Deal_Qualification_Approver__c>();
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfInActiveToPendingDealQual = new Map<Id, DQ_Deal_Qualification_Approver__c>();
        Set<Id> setOfInActiveDealQualId = new Set<Id>();
        Set<Id> setOfCurrentEligibleQueueIdForMember = new Set<Id> ();

        for (Id dealQualApproverId : mapOfDealQualificationOldApprover.keySet()) {
            DQ_Deal_Qualification_Approver__c oldDealQualApprover = mapOfDealQualificationOldApprover.get(dealQualApproverId);
            DQ_Deal_Qualification_Approver__c newDealQualApprover = mapOfDealQualificationNewApprover.get(dealQualApproverId);

            if (oldDealQualApprover.Status__c == 'Inactive' && newDealQualApprover.Status__c == 'Pending') {
                mapOfInActiveToPendingDealQual.put(dealQualApproverId, newDealQualApprover);
                setOfInActiveDealQualId.add(newDealQualApprover.Deal_Qualification__c);
                if (newDealQualApprover.OwnerId.getSObjectType() == Group.getSObjectType()) {
                    setOfCurrentEligibleQueueIdForMember.add(newDealQualApprover.OwnerId);
                }
            }
        }

        if (!mapOfInActiveToPendingDealQual.values().isEmpty())
        {
            Map<Id, List<Id>> mapOfDQIdVsApprovedByUser = createMapOfApprovedQueueAndUserByDQId(setOfInActiveDealQualId);
            Set<Id> setOfDealQualApproverQueueIds = getAllQueueIdForApprovedDealQualApprover(getLatestSubmitOrderPendingApprovedDQApproverByDQIds(setOfInActiveDealQualId));
            Map<Id, Id> mapOfUserVsDQId = getMapOfLastApprovedUserByDQId(setOfInActiveDealQualId);

            setOfDealQualApproverQueueIds.addAll(setOfCurrentEligibleQueueIdForMember);
            Map<Id, List<Id>> mapOfQueueIdVsUser = createMapOfQueueIdAndUser(setOfDealQualApproverQueueIds);

            for (Id eachDQId : mapOfInActiveToPendingDealQual.keySet()) {
                DQ_Deal_Qualification_Approver__c eachDQApprover = mapOfInActiveToPendingDealQual.get(eachDQId);

                if (eachDQApprover != null)
                {
                    // Approved By User List for DQ
                    List<Id> listOfApprovedUserForDQ = mapOfDQIdVsApprovedByUser.get(eachDQApprover.Deal_Qualification__c);
                    if (listOfApprovedUserForDQ == null) {
                        listOfApprovedUserForDQ = new List<Id>();
                    }
                    Id approvedByUserId = mapOfUserVsDQId.get(eachDQApprover.Deal_Qualification__c);
                    // Check if Approved User Belongs to Pending Owner Id ?
                    // If Owner is User
                    if (eachDQApprover.OwnerId.getSObjectType() == User.getSObjectType())
                    {
                        // Check if owner is already belongs to approved by group
                        // if Belongs then approved record.
                        if (listOfApprovedUserForDQ.contains(eachDQApprover.OwnerId))
                        {
                            eachDQApprover.Status__c = 'Approved';
                            eachDQApprover.Auto_Approval__c = true;
                            eachDQApprover.Approved_By__c = approvedByUserId;
                            eachDQApprover.Approve_Reject_Date__c = System.now();
                            listOfNeedToApproveDQApprover.add(eachDQApprover);
                        }
                    }
                    // if Owner is Queue Id
                    else if (eachDQApprover.OwnerId.getSObjectType() == Group.getSObjectType())
                    {
                        // Get Queue Member by Queue Id
                        List<Id> queueMemberUser = mapOfQueueIdVsUser.get(eachDQApprover.OwnerId);
                        if (queueMemberUser == null) {
                        	queueMemberUser = new List<Id>();
                        }
                        if (ifApprovedUserBelongsToQUeue(queueMemberUser, listOfApprovedUserForDQ))
                        {
                            eachDQApprover.Status__c = 'Approved';
                            eachDQApprover.Auto_Approval__c = true;
                            eachDQApprover.Approved_By__c = approvedByUserId;
                            eachDQApprover.Approve_Reject_Date__c = System.now();
                            listOfNeedToApproveDQApprover.add(eachDQApprover);
                        }
                    }
                }
            }
        }

    }

    private static Map<Id, Id> getMapOfLastApprovedUserByDQId(Set<Id> setOfDQIds) {
        Map<Id, Id> mapOfDQVsUserId = new Map<Id, Id>();
        List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealQualificationApprover = getLatestSubmitOrderApprovedDQApproverByDQIds(setOfDqIds);
        for(DQ_Deal_Qualification_Approver__c eachApprover : listOfApprovedDealQualificationApprover) {
            Id userId = mapOfDQVsUserId.get(eachApprover.Deal_Qualification__c);
            if (userId == null){
                mapOfDQVsUserId.put(eachApprover.Deal_Qualification__c, eachApprover.Approved_By__c);
            }
        }
        return mapOfDQVsUserId;
    }

    @TestVisible
    private static Boolean ifApprovedUserBelongsToQUeue (List<Id> queueMembers, List<Id> approvedUsers) {
        Boolean isFound = false;

        if (queueMembers != null && approvedUsers != null) {
            for (Id eachId : approvedUsers) {
                if (queueMembers.contains(eachId)) {
                    isFound = true;
                    break;
                }
            }
        }

        return isFound;
    }

    private static Set<Id> getAllQueueIdForApprovedDealQualApprover(List<DQ_Deal_Qualification_Approver__c> listOfDealQualApprover) {
        Set<Id> setOfQueueIds = new Set<Id>();
        for (DQ_Deal_Qualification_Approver__c eachApprover : listOfDealQualApprover) {
            if (eachApprover.OwnerId.getSObjectType() == Group.getSObjectType()) {
                setOfQueueIds.add(eachApprover.OwnerId);
            }
        }
        return setOfQueueIds;
    }

    private static Map<Id, List<Id>> createMapOfQueueIdAndUser(Set<Id> setOfQueueIds) {
        Map<Id, List<Id>> mapOfQueueIdVsListOfUser = new Map<Id, List<Id>>();
        for (GroupMember eachGroupMember : getAllGroupMemberWithAutoApprovalByQueueId(setOfQueueIds)) {
            List<Id> listOfUser = mapOfQueueIdVsListOfUser.get(eachGroupMember.GroupId);
            if (listOfUser == null) {
                listOfUser = new List<Id>();
            }

            if (eachGroupMember.UserOrGroupId.getSObjectType() == User.sObjectType) {
                listOfUser.add(eachGroupMember.UserOrGroupId);
            }
            mapOfQueueIdVsListOfUser.put(eachGroupMember.GroupId, listOfUser);
        }
        return mapOfQueueIdVsListOfUser;
    }

    private static List<GroupMember> getAllGroupMemberWithAutoApprovalByQueueId (Set<Id> setOfQueueIds) {
        List<GroupMember> listOfGroupApprovalMember = new List<GroupMember>();
        Set<Id> setOfUserIds = new Set<Id>();
        List<GroupMember> listOfGroupMember = [Select Id, UserOrGroupId, GroupId From GroupMember where GroupId =:setOfQueueIds];
        for (GroupMember eachGroupMember : listOfGroupMember) {
            if (eachGroupMember.UserOrGroupId.getSObjectType() == User.getSObjectType()) {
                setOfUserIds.add(eachGroupMember.UserOrGroupId);
            }
        }

        Map<Id, User> mapOfUserVsUserId = new Map<Id, User>([SELECT Id, Name, Enable_Auto_DQ_Approval__c FROM User WHERE Id IN:setOfUserIds]);
        for (GroupMember eachGroupMember : listOfGroupMember) {
            if (eachGroupMember.UserOrGroupId.getSObjectType() == User.getSObjectType()) {
                User eachUser = mapOfUserVsUserId.get(eachGroupMember.UserOrGroupId);
                if (eachUser.Enable_Auto_DQ_Approval__c != null && eachUser.Enable_Auto_DQ_Approval__c) {
                    listOfGroupApprovalMember.add(eachGroupMember);
                }
            }
        }
        return listOfGroupApprovalMember;
    }


    private static Map<Id, List<Id>> createMapOfApprovedQueueAndUserByDQId(Set<Id> setOfDqIds) {
        Map<Id, List<Id>> mapOfApprovedUserByDQId = new Map<Id, List<Id>>();
        List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealQualificationApprover = getLatestSubmitOrderApprovedDQApproverByDQIds(setOfDqIds);
        for (DQ_Deal_Qualification_Approver__c eachDQApprover : listOfApprovedDealQualificationApprover) {
            List<Id> listOfUser = mapOfApprovedUserByDQId.get(eachDQApprover.Deal_Qualification__c);
            if (listOfUser == null) {
                listOfUser = new List<Id>();
            }

            listOfUser.add(eachDQApprover.Approved_By__c);
            mapOfApprovedUserByDQId.put(eachDQApprover.Deal_Qualification__c, listOfUser);
        }
        return mapOfApprovedUserByDQId;
    }

    private static List<DQ_Deal_Qualification_Approver__c> getLatestSubmitOrderApprovedDQApproverByDQIds(Set<Id> setOfDQIds) {
        List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealQualificationApprover = getDealQualApprovedApproverByDQId(setOfDqIds);
        return getLatestSubmitOrderDQApproverByDQIds(listOfApprovedDealQualificationApprover);
    }


    private static List<DQ_Deal_Qualification_Approver__c> getLatestSubmitOrderPendingApprovedDQApproverByDQIds(Set<Id> setOfDQIds) {
        List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealQualificationApprover = getDealQualPendingApprovedApproverByDQId(setOfDqIds);
        return getLatestSubmitOrderDQApproverByDQIds(listOfApprovedDealQualificationApprover);
    }

    private static List<DQ_Deal_Qualification_Approver__c> getLatestSubmitOrderDQApproverByDQIds(List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealQualificationApprover) {
        Map<Id, List<DQ_Deal_Qualification_Approver__c>> mapOfDQIdVsListOfApprover = new  Map<Id, List<DQ_Deal_Qualification_Approver__c>>();
        for (DQ_Deal_Qualification_Approver__c eachApprover : listOfApprovedDealQualificationApprover) {
            List<DQ_Deal_Qualification_Approver__c> listOfDQApprover = mapOfDQIdVsListOfApprover.get(eachApprover.Deal_Qualification__c);
            if (listOfDQApprover == null) {
                listOfDQApprover = new List<DQ_Deal_Qualification_Approver__c> ();
            }

            DQ_Deal_Qualification_Approver__c existingListApproverRecord = eachApprover;
            if (listOfDQApprover.size() > 0) {
                existingListApproverRecord = listOfDQApprover.get(0);
            }

            if (existingListApproverRecord.Submitted_Order__c == eachApprover.Submitted_Order__c) {
                listOfDQApprover.add(eachApprover);
            }

            mapOfDQIdVsListOfApprover.put(eachApprover.Deal_Qualification__c, listOfDQApprover);
        }

        List<DQ_Deal_Qualification_Approver__c> listOfApprovedDealApproverRecord = new List<DQ_Deal_Qualification_Approver__c>();
        for (List<DQ_Deal_Qualification_Approver__c> eachMapRecord : mapOfDQIdVsListOfApprover.values()) {
            listOfApprovedDealApproverRecord.addAll(eachMapRecord);
        }

        return listOfApprovedDealApproverRecord;
    }

    public static List<DQ_Deal_Qualification_Approver__c> getDealQualApprovedApproverByDQId(Set<Id> setOfDQIds) {
        return [SELECT Approval_Reason__c, Approval_Step__c, Approval_Step_Approver__c, Approved_By__c, Approve_Reject_Date__c,
            Comments__c, Status__c, Step_Order__c, Submitted_Order__c, Deal_Qualification__c, OwnerId
            FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :setOfDQIds AND Status__c = 'Approved'
            ORDER BY Submitted_Order__c DESC];
    }

    public static List<DQ_Deal_Qualification_Approver__c> getDealQualPendingApprovedApproverByDQId(Set<Id> setOfDQIds) {
        return [SELECT Approval_Reason__c, Approval_Step__c, Approval_Step_Approver__c, Approved_By__c,
            Comments__c, Status__c, Step_Order__c, Submitted_Order__c, Deal_Qualification__c, OwnerId
            FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :setOfDQIds AND
            (Status__c = 'Approved' OR Status__c = 'Pending')
            ORDER BY Submitted_Order__c DESC];
    }

    //Update Delegate_Email__c email field on DQ_Deal_Qualification_Approver__c records
    public static void updateDelegateEmail(
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfDealQualificationOldApprover,
        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationNewApprover
    ) {
        Map<String,Id> mapofOwnerIdToDelegateUserId = new Map<String,String>();
        Map<String,String> mapofDelegateUserIdToEmail = new Map<String,String>();
        Set<Id> ownerIdSet = new Set<Id>();

        if(Trigger.isUpdate ) {
            for(DQ_Deal_Qualification_Approver__c objApprover : listOfDealQualificationNewApprover) {
                if(objApprover.ownerId != mapOfDealQualificationOldApprover.get(objApprover.Id).ownerId && String.valueof(objApprover.ownerId).startsWith('005')) {
                    ownerIdSet.add(objApprover.ownerId);
                }
            }
        }

        if(Trigger.isInsert ) {
            for(DQ_Deal_Qualification_Approver__c objApprover : listOfDealQualificationNewApprover) {
                if(String.valueof(objApprover.ownerId).startsWith('005')) {
                    ownerIdSet.add(objApprover.ownerId);
                }
            }
        }

        // Query to get Approvers who have Delegated Approvers
        List<User> approversUsers = new UserSelector()
            .selectUsersWithDelegatedApproversByIds(ownerIdSet)
            .executeQuery();
        for(User objUser : approversUsers) {
            mapofOwnerIdToDelegateUserId.put(objUser.Id,objUser.DelegatedApproverId);
        }

        // Query to get Delegated user email
        for(User objUser : [SELECT Id, Email, UserPreferencesReceiveNotificationsAsDelegatedApprover  FROM User
                                WHERE Id IN :mapofOwnerIdToDelegateUserId.values()
                                AND UserPreferencesReceiveNotificationsAsDelegatedApprover = true]) {
            mapofDelegateUserIdToEmail.put(objUser.Id,objUser.Email);
        }

        //update email
        for(DQ_Deal_Qualification_Approver__c objApprover : listOfDealQualificationNewApprover) {
            if(String.valueof(objApprover.ownerId).startsWith('005') && mapofOwnerIdToDelegateUserId.containsKey(objApprover.ownerId)
                && mapofDelegateUserIdToEmail.containsKey(mapofOwnerIdToDelegateUserId.get(objApprover.ownerId)) && objApprover.Approval_Step_Name__c == 'Level 1') {
                objApprover.Delegate_Email__c = mapofDelegateUserIdToEmail.get(mapofOwnerIdToDelegateUserId.get(objApprover.ownerId));
            }
        }
    }
}