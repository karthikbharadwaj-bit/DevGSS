public with sharing class CaseCommentTriggerHelper {
    
    public static final String MILESTONE_NAME_FOLLOW_UP_SUPPORT_INTEGRATION = 'Follow Up (Support-Integration)';
    public static final String MILESTONE_NAME_FIRST_RESPONSE = 'First Response';
    
    public class CompleteFirstResponseMilestoneHandler extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            
            Boolean isNeedToHandle = EntitlementHelper.IsEntitlementsEnabled() && EntitlementHelper.isPortalUser();
            
            if(!isNeedToHandle) {
                return;
            }
            
            Set<Id> caseIds = new Set<Id>();
            
            for (CaseComment cc : (List<CaseComment>) Trigger.new) {
                // Only public comments qualify
                if(cc.IsPublished == true ) {
                    caseIds.add(cc.ParentId);
                }
            }
            if(caseIds.isEmpty()) {
                return;
            }
            
            Set<Id> casesIdsSet = findCaseIdsToCompleteFirstResponseMilestone(caseIds);
            
            if(casesIdsSet.isEmpty()) {
                return;
            }
            
            MilestoneUtils.completeMilestone(
                new List<Id>(casesIdsSet),
                MILESTONE_NAME_FIRST_RESPONSE,
                System.now()
            );
        }
        
        @TestVisible
        private Set<Id> findCaseIdsToCompleteFirstResponseMilestone(Set<Id> caseIdSet) {
            
            if(caseIdSet == null || caseIdSet.isEmpty()) {
                return new Set<Id>();
            }
            
            Map<Id, Case> casesMap = new Map<Id, Case>(
                [SELECT Id, ContactId, Contact.Email, OwnerId,
                 Status, EntitlementId, SlaStartDate, SlaExitDate
                 FROM Case
                 WHERE Id IN :caseIdSet AND
                 Status != :CaseHelper.CASE_STATUS_CLOSED AND
                 RecordTypeId = :CaseHelper.RT_ID_SUPPORT_CASE AND
                 EntitlementId != null AND
                 SlaExitDate = null AND
                 First_Response_Timestamp__c = null AND
                 SlaStartDate <= :System.now()]
            );
            
            return casesMap.keySet();
        }
    }
    
    public class CompleteFollowUpSupportIntegrationMilestone extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            
            Set<Id> caseIdSet = new Set<Id>();
            
            for(CaseComment cc : (List<CaseComment>) Trigger.new) {
                caseIdSet.add(cc.ParentId);
            }
            
            Set<Id> unclosedCasesIdsSet = findCaseIdsToCompleteFollowUpMilestone(caseIdSet);
            
            if(unclosedCasesIdsSet.isEmpty()) {
                return;
            }
            
            MilestoneUtils.completeMilestone(
                new List<Id>(unclosedCasesIdsSet),
                MILESTONE_NAME_FOLLOW_UP_SUPPORT_INTEGRATION,
                System.now()
            );
        }
        
        @TestVisible
        private Set<Id> findCaseIdsToCompleteFollowUpMilestone(Set<Id> caseIdSet) {
            
            if(caseIdSet == null || caseIdSet.isEmpty()) {
                return new Set<Id>();
            }
            
            Map<Id, Case> unclosedCasesMap = new Map<Id, Case>(
                [SELECT Id FROM Case WHERE Id IN :caseIdSet AND
                 Status != :CaseHelper.CASE_STATUS_CLOSED AND
                 RecordTypeId = :CaseHelper.RT_ID_SUPPORT_INTEGRATIONS]
            );
            
            return unclosedCasesMap.keySet();
        }
    }
    
    
    public class CaseCommentCount extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            
            if(TriggerHandler.BY_PASS_CASECOMMENT_ON_INSERT || TriggerHandler.BY_PASS_CASECOMMENT_ON_UPDATE){
                System.debug('### RETURNED FROM CASECOMMENT AFTER TRG ###');
                return;
            }
            
            // To ByPass Case Trigger Code
            TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
            TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
            
            CaseCommentCountHelper caseCommentHelpeObj = new CaseCommentCountHelper();
            
            if(Trigger.isDelete) {
                
                Map<Id, Case> caseCommentMap = caseCommentHelpeObj.getCaseCommentCountInfo(Trigger.old);
                
                Map<Id, User> createdUserMap = caseCommentHelpeObj.getcreatedUserMap(Trigger.old);
                
                List<Case> caseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnDelete(Trigger.old, caseCommentMap, createdUserMap);
                
                if(caseListToUpd == null || caseListToUpd.isEmpty()) {
                    return;
                }
                
                update caseListToUpd;
                
            } else if (Trigger.isInsert || Trigger.IsUpdate) {
                // TELUS CASE COMMENT CODE STARTS
                try{
                    if(Trigger.isInsert) {
                        TelusExternalSharingHelperCls.onLocalCaseCommentInsert(Trigger.new);
                    }
                    if(Trigger.isUpdate) {
                        TelusExternalSharingHelperCls.onLocalCaseCommentUpdate(Trigger.new);
                    }
                }catch(Exception e) {
                    System.debug('Exception occured IN TELUS Code for Comments.');
                }
                // TELUS CASE COMMENT CODE ENDS
                
                Map<Id, Case> caseCommentMap = caseCommentHelpeObj.getCaseCommentCountInfo(Trigger.new);
                
                Map<Id, User> createdUserMap = caseCommentHelpeObj.getcreatedUserMap(Trigger.new);
                
                List<Case> caseListToUpd = new List<Case>();
                
                if(Trigger.isInsert) {
                    caseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnInsOrUpd(null, (List<CaseComment>) Trigger.New, caseCommentMap, createdUserMap);
                } else if(Trigger.IsUpdate) {
                    caseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnInsOrUpd((Map<Id, CaseComment>) Trigger.oldMap, (List<CaseComment>) Trigger.New, caseCommentMap, createdUserMap);
                }
                
                if(caseListToUpd == null || caseListToUpd.isEmpty()) {
                    return;
                }
                
                TriggerHandler.BY_PASS_CASE_Trigger = true;
                update caseListToUpd;
            }
        }
    }
    
    //added  logic to prevent deletion of CaseComment records by any user other than sys admin
    public  void checkDeleteAccess(List<CaseComment> oldCaseComments){   
        if(!ProfileHelper.isCurrentUserSysAdmin()){
            for(CaseComment csc : oldCaseComments){
                csc.addError('You are not authorized to delete the case comment');                
            }   
        }
    }
}