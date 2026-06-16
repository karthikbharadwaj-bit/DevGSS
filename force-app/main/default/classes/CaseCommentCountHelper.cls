public class CaseCommentCountHelper {
    Set<Id> caseIdSet = new Set<Id>();
    Set<Id> createdUserIdSet = new Set<Id>();
    
    // Record Type for Closed Support Telus Cases to Bypass the Validation Rule Error
    private static final Set<String> TELUS_RECORD_TYPES = new Set<String>{
        'Support_Telus',
        'Support_T1_Shipping'
    };
    
    // Closed statuses that should be skipped for Support_Telus cases to avoid validation rule conflicts
    private static final Set<String> CLOSED_STATUSES_FOR_TELUS = new Set<String>{
        'Closed', 
        'Closed - No Response', 
        'Closed - No Contact', 
        'Closed - No Issue', 
        'Closed - Duplicate'
    };

    public Map<Id, Case> getCaseCommentCountInfo(List<CaseComment> caseCommentList) {
        Map<Id, Case> caseCommentMap = new map<Id,Case>();

        if(caseCommentList == null || caseCommentList.isEmpty()) {
            return caseCommentMap;
        }

        for(CaseComment caseCommentObj : caseCommentList) {
            if(!String.IsBlank(caseCommentObj.parentId)) {
                caseIdSet.add(caseCommentObj.parentId);
            }
        }

        if(!caseIdSet.isEmpty()) {
            caseCommentMap = new Map<Id,Case>([
                SELECT No_of_Private_Comments__c,
                       No_of_Public_Comments__c, 
                       Created_by_customer__c,
                       Created_by_Agent__c,
                       RecordType.DeveloperName,
                       Status
                FROM Case 
                WHERE Id IN :caseIdSet
            ]);
        }

        return caseCommentMap;
    }

    public map<Id,User> getcreatedUserMap(List<CaseComment> caseCommentList) {
        Map<Id, User> createdUserMap = new Map<Id, User>();

        if(caseCommentList == null || caseCommentList.isEmpty()) {
            return createdUserMap;
        }

        for(CaseComment caseCommentObj : caseCommentList) {
            createdUserIdSet.add(caseCommentObj.createdById);
        }
        createdUserMap = new Map<Id, User>([SELECT Email FROM User WHERE Id IN :createdUserIdSet]);

        return createdUserMap;
    }


    private class CaseCommentCountData {
        public Id caseId;
        public Decimal numberOfPublishedComments = 0;
        public Decimal numberOfNotPublishedComments = 0;
        public Decimal numberOfCommentsCreatedByRCAgent = 0;
        public Decimal numberOfCommentsCreatedByCustomer = 0;
    }

    private Map<Id, CaseCommentCountData> buildCaseCommentCountDataMap(List<CaseComment> caseCommentList, Map<Id, CaseComment> caseCommentOldMap, Map<Id, User> createdUserMap) {

        Map<Id, CaseCommentCountData> resultMap = new Map<Id, CaseCommentCountData>();

        if(caseCommentList == null || caseCommentList.isEmpty()) {
            return resultMap;
        }

        Map<Id, List<CaseComment>> caseIdToCaseCommentListMap = new Map<Id, List<CaseComment>>();

        for(CaseComment cc : caseCommentList) {
            if(!caseIdToCaseCommentListMap.containsKey(cc.ParentId)) {
                caseIdToCaseCommentListMap.put(cc.ParentId, new List<CaseComment>());
            }
            caseIdToCaseCommentListMap.get(cc.ParentId).add(cc);
        }

        for(Id caseId : caseIdToCaseCommentListMap.keySet()) {
            List<CaseComment> ccList = caseIdToCaseCommentListMap.get(caseId);
            Decimal numOfPublished = 0;
            Decimal numOfNotPublished = 0;

            Decimal createdByRCAgent = 0;
            Decimal createdByCustomer = 0;
            for(CaseComment cc : ccList) {
                if(Trigger.isInsert) {
                    if(cc.IsPublished) {
                        numOfPublished++;
                    }else{
                        numOfNotPublished++;
                    }
                }else if(Trigger.isUpdate) {
                    CaseComment ccOld = caseCommentOldMap.get(cc.id);
                    if(!ccOld.IsPublished && cc.IsPublished) {
                        numOfPublished++;
                        numOfNotPublished--;
                    }else if(ccOld.IsPublished && !cc.IsPublished) {
                        numOfPublished--;
                        numOfNotPublished++;
                    }
                }else if(Trigger.isDelete) {
                    if(cc.IsPublished) {
                        numOfPublished--;
                    }else{
                        numOfNotPublished--;
                    }
                }

                if(createdUserMap != null && createdUserMap.containsKey(cc.createdByID)) {
                    User usr = createdUserMap.get(cc.createdByID);
                    String usrEmail = StringHelper.safeString(usr.Email);
                    Boolean isRingcentralAgent = usrEmail.split('@')[1].containsIgnoreCase('ringcentral.com');
                    if(Trigger.isInsert) {
                        if(isRingcentralAgent) {
                            createdByRCAgent++;
                        }else{
                            createdByCustomer++;
                        }
                    }else if(Trigger.isDelete) {
                        if(isRingcentralAgent) {
                            createdByRCAgent--;
                        }else{
                            createdByCustomer--;
                        }
                    }
                }
            }

            CaseCommentCountData data = new CaseCommentCountData();
            data.caseId = caseId;
            data.numberOfPublishedComments = numOfPublished;
            data.numberOfNotPublishedComments = numOfNotPublished;
            data.numberOfCommentsCreatedByRCAgent = createdByRCAgent;
            data.numberOfCommentsCreatedByCustomer = createdByCustomer;

            resultMap.put(caseId, data);
        }

        return resultMap;
    }

    public List<Case> getUpdatedCaseListOnDelete(List<CaseComment> caseCommentList, Map<Id, Case> caseCommentMap, Map<Id, User> createdUserMap) {
        List<Case> caseListToUpd = new List<Case>();

        Map<Id, CaseCommentCountData> caseIdToCaseCommentCountDataMap = buildCaseCommentCountDataMap(caseCommentList, null, createdUserMap);

        for(Id caseId : caseIdToCaseCommentCountDataMap.keySet()) {

            Case caseObj = caseCommentMap.get(caseId);
            
            // Skip closed Support_Telus cases to avoid validation rule conflict (Lock_Status_When_Closed_Telus)
            if(isClosedTelusCase(caseObj)) {
                continue;
            }
            
            CaseCommentCountData caseCommentCountData = caseIdToCaseCommentCountDataMap.get(caseId);

            Case caseToUpdate = new Case(Id = caseId);

            Decimal numberOfPublicComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.No_of_Public_Comments__c);
            caseToUpdate.No_of_Public_Comments__c = numberOfPublicComments + caseCommentCountData.numberOfPublishedComments;

            Decimal numberOfPrivateComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.No_of_Private_Comments__c);
            caseToUpdate.No_of_Private_Comments__c = numberOfPrivateComments + caseCommentCountData.numberOfNotPublishedComments;

            Decimal numOfAgentComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.Created_by_Agent__c);
            caseToUpdate.Created_by_Agent__c = numOfAgentComments + caseCommentCountData.numberOfCommentsCreatedByRCAgent;

            Decimal numOfCustomerComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.Created_by_customer__c);
            caseToUpdate.Created_by_customer__c = numOfCustomerComments + caseCommentCountData.numberOfCommentsCreatedByCustomer;

            caseListToUpd.add(caseToUpdate);
        }

        return caseListToUpd;
    }

    public List<Case> getUpdatedCaseListOnInsOrUpd(Map<Id, CaseComment> caseCommentOldMap, List<CaseComment> caseCommentListNew, Map<Id, Case> caseCommentMap, Map<Id, User> createdUserMap) {

        List<Case> caseListToUpd = new List<Case>();

        Map<Id, CaseCommentCountData> caseIdToCaseCommentCountDataMap = buildCaseCommentCountDataMap(caseCommentListNew, caseCommentOldMap, createdUserMap);

        for(Id caseId : caseIdToCaseCommentCountDataMap.keySet()) {

            Case caseObj = caseCommentMap.get(caseId);
            
            // Skip closed Support_Telus cases to avoid validation rule conflict (Lock_Status_When_Closed_Telus)
            if(isClosedTelusCase(caseObj)) {
                continue;
            }
            
            CaseCommentCountData caseCommentCountData = caseIdToCaseCommentCountDataMap.get(caseId);

            Case caseToUpdate = new Case(Id = caseId);

            Decimal numberOfPublicComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.No_of_Public_Comments__c);
            caseToUpdate.No_of_Public_Comments__c = numberOfPublicComments + caseCommentCountData.numberOfPublishedComments;

            Decimal numberOfPrivateComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.No_of_Private_Comments__c);
            caseToUpdate.No_of_Private_Comments__c = numberOfPrivateComments + caseCommentCountData.numberOfNotPublishedComments;

            Decimal numOfAgentComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.Created_by_Agent__c);
            caseToUpdate.Created_by_Agent__c = numOfAgentComments + caseCommentCountData.numberOfCommentsCreatedByRCAgent;

            Decimal numOfCustomerComments = (Decimal) NumberHelper.getNumberNullSafe(caseObj.Created_by_customer__c);
            caseToUpdate.Created_by_customer__c = numOfCustomerComments + caseCommentCountData.numberOfCommentsCreatedByCustomer;

            caseListToUpd.add(caseToUpdate);
        }

        return caseListToUpd;
    }

    /**
     * @description Checks if the given Case is a closed Support_Telus case.
     *              Used to skip comment count updates for these cases to avoid
     *              the Lock_Status_When_Closed_Telus validation rule conflict.
     * @param caseObj The Case record to check
     * @return Boolean true if the case is a closed Support_Telus case, false otherwise
     */
    private Boolean isClosedTelusCase(Case caseObj) {
        if(caseObj == null) {
            return false;
        }
        
        String recordTypeDeveloperName = caseObj.RecordType != null ? caseObj.RecordType.DeveloperName : null;
        String status = caseObj.Status;
        
        return TELUS_RECORD_TYPES.contains(recordTypeDeveloperName) && 
            CLOSED_STATUSES_FOR_TELUS.contains(status);
    }
}