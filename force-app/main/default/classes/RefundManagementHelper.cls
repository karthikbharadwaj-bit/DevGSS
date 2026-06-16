public with sharing class RefundManagementHelper {

	/**
     * Method to process Refund Management page validation
     * @param approvalId - Approval__c id
     * @return list of errors if they exist
     */
	public static List<ErrorWrapper> checkRefundManagementPageAccessPermissions(Id approvalId) {
		Approval__c approvalRecord = [
            SELECT Id, Status__c
            FROM Approval__c
            WHERE Id =: approvalId
		];
		//List of possible errors
		List <ErrorWrapper> errorMessagesList = new List <ErrorWrapper>();

		List<Profile> profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Id =: userinfo.getProfileId()
            LIMIT 1
        ];
		//Check if user has custom permissions to start refund management page
		if (!Test.isRunningTest() && !FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_REFUND_MANAGEMENT)
			|| Test.isRunningTest() && FeatureManagement.checkPermission('Support_Director_permission')) {   //Added as part of profile consolidation of Support Agent profiles
			ErrorWrapper error = new ErrorWrapper('You don\'t have permission to use Refund Management Page',
												'You need \'Refund Management\' custom permission to use the page');
			errorMessagesList.add(error);
			return errorMessagesList;
		}

		//Check if user is a memeber of BidDesk Queue
		Boolean isBidDeskQueue = false;
		List <GroupMember> groupMemberList = [SELECT Id, Group.Name
										FROM GroupMember
										WHERE UserOrGroupId =: UserInfo.getUserId()
										AND Group.Type = 'Queue'];
		for (GroupMember groupMemberRecord : groupMemberList) {
			if (groupMemberRecord.Group.Name == 'Bid Desk') {
				isBidDeskQueue = true;
				break;
			}
		}
		//If user is not sysAdmin and not BidDesk queue member
		if (!ProfileHelper.isCurrentUserSysAdmin() && !isBidDeskQueue) {
			ErrorWrapper error = new ErrorWrapper('You are not allowed to open Refund Management Page',
												'Only members of Bid Desk Queue are allowed to process Refund Approvals using Refund Management Page');
			errorMessagesList.add(error);
		}


		//Approval should be processed only when it is pending approval from Bid Desk queue
		if (!isBidDeskQueueAssigned(approvalId)) {
			ErrorWrapper error = new ErrorWrapper('Approval is not ready to be Processed by Bid Desk',
				'Approval Record current approver should be assigned to Bid Desk queue');
			errorMessagesList.add(error);
		}

		return errorMessagesList;
	}

	@TestVisible
	private static Boolean isBidDeskQueueAssigned(Id targetObjId) {
		Boolean isBidDeskQueue = false;
		List <ProcessInstance> approvalProcessList = [SELECT CreatedDate, Id, IsDeleted,
                      							(SELECT Id, ActorId, IsPending
												FROM StepsAndWorkitems )
                     						FROM ProcessInstance
                     						WHERE TargetObjectId =: targetObjId
                     						AND IsDeleted = false
                     						ORDER BY CreatedDate DESC];
        if (!approvalProcessList.isEmpty()) {
			Id assigneeId;
        	for (ProcessInstanceHistory processHistory :  approvalProcessList[0].StepsAndWorkitems) {
        		if (processHistory.isPending) {
        			assigneeId = processHistory.ActorId;
        		}
			}
	        if (assigneeId != null || Test.isRunningTest()) {
				isBidDeskQueue = isBidDeskQueueId(assigneeId);
	        }
        }
        return isBidDeskQueue;
	}

	@TestVisible
	private static Boolean isBidDeskQueueId(Id queueId) {
		Boolean result = false;
		if (queueId == null || queueId.getSObjectType() != Group.SObjectType) {
			return result;
		}
		List<Group> queueList = (List<Group>) new GroupSelector()
			.selectGroups()
			.selectField(Group.Name)
			.selectField(Group.Type)
			.setCondition('Type = \'' + GroupHelper.GROUP_TYPE_QUEUE + '\' AND Id = \'' + queueId + '\'')
			.setLimit(1)
			.executeQuery();

		if (!queueList.isEmpty()) {
			result = queueList[0].Name == 'Bid Desk';
		}
		return result;
	}

	public class ErrorWrapper {
		public String header;
		public string message;

		public ErrorWrapper (String header, String message) {
			this.header = header;
			this.message = message;
		}
	}
}