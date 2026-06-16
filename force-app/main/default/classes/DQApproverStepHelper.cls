public without sharing class DQApproverStepHelper {

    public static final String APPROVAL_PROSERV_SERVICE = 'Professional Services';
    public static final String APPROVAL_COMMON_SERVICE = 'Common';

    public class ApprovalTypeStepData {
        public String approvalReason = '';
        public DQ_Approval_Type_Step__c dqApprovalTypeStep;

        public ApprovalTypeStepData(String approvalReason, DQ_Approval_Type_Step__c dqApprovalTypeStep) {
            this.approvalReason = approvalReason != null ? approvalReason : '';
            this.dqApprovalTypeStep = dqApprovalTypeStep;
        }
    }

    public class ApproverStepData {
        public DQ_Approval_Step__c approvalStep;
        public List<DQ_Approval_Type_Step__c> approvalTypeStepList = new List<DQ_Approval_Type_Step__c>();
        public List<DQ_Approval_Step_Approver__c> stepApproversList = new List<DQ_Approval_Step_Approver__c>();
        public String approvalReason = '';
        public List<ApprovalTypeStepData> approvalTypeStepDataList = new List<ApprovalTypeStepData>();
        public User managerDetail;
        public Map<Id, String> stepIdToServiceName = new Map<Id, String>();
        public Group dealDeskDetail;
    }

    public static List<ApproverStepData> getApproverStepData(Map<Id, String> approvalTypeIdToReasonMap, DQDataHelper.DealQualificationData dqData, Boolean isFirstLevelApprovalRequired) {
        if (approvalTypeIdToReasonMap == null || approvalTypeIdToReasonMap.isEmpty() || dqData == null) {
            return new List<ApproverStepData>();
        }

        List<DQ_Approval_Type_Step__c> approvalTypeStepList = DQDataHelper.getApprovalTypeSteps(approvalTypeIdToReasonMap.keySet(), dqData);

        Map<String, List<DQ_Approval_Type_Step__c>> stepNameToApprovalTypeStepListMap = new Map<String, List<DQ_Approval_Type_Step__c>>();
        Map<String, String> stepNameToReasonMap = new Map<String, String>();
        for (DQ_Approval_Type_Step__c approvalTypeStep : approvalTypeStepList) {
            String stepName = approvalTypeStep.DQ_Approval_Step__r.Name;
            if (!stepNameToApprovalTypeStepListMap.containsKey(stepName)) {
                stepNameToApprovalTypeStepListMap.put(stepName, new List<DQ_Approval_Type_Step__c>());
            }
            stepNameToApprovalTypeStepListMap.get(stepName).add(approvalTypeStep);

            String stepReason = approvalTypeIdToReasonMap.get(approvalTypeStep.DQ_Approval_Type__c);

            String newStepReason = getStepReason(stepNameToReasonMap.get(stepName), stepReason);
            stepNameToReasonMap.put(stepName, newStepReason);
        }

        Set<Id> approvalStepIdSet = getApprovalStepIdSet(approvalTypeStepList);
        Map<Id, DQ_Approval_Step__c> approvalStepsMap = getApprovalStepsMap(approvalStepIdSet);

        Map<Id, ApproverStepData> approvalTypeStepIdToApproverStepDataMap = buildApproverStepDataMap(
            stepNameToApprovalTypeStepListMap,
            stepNameToReasonMap,
            approvalStepsMap,
            approvalTypeIdToReasonMap
        );

        List<DQ_Approval_Step_Approver__c> approvalStepApproverList = DQDataHelper.getApprovalStepApprovers(approvalStepIdSet, dqData);

        Map<Id, List<DQ_Approval_Step_Approver__c>> stepIdToStepApproversMap = new Map<Id, List<DQ_Approval_Step_Approver__c>>();
        for (DQ_Approval_Step_Approver__c stepApprover : approvalStepApproverList) {
            if (!stepIdToStepApproversMap.containsKey(stepApprover.DQ_Approval_Step__c)) {
                stepIdToStepApproversMap.put(stepApprover.DQ_Approval_Step__c, new List<DQ_Approval_Step_Approver__c>());
            }
            stepIdToStepApproversMap.get(stepApprover.DQ_Approval_Step__c).add(stepApprover);
        }


        for (Id approvalTypeStepId : approvalTypeStepIdToApproverStepDataMap.keySet()) {
            ApproverStepData data = approvalTypeStepIdToApproverStepDataMap.get(approvalTypeStepId);
            if (data == null) {
                data = getApproverStepDataByMatchingStepId(approvalTypeStepId, approvalTypeStepIdToApproverStepDataMap);
            }
            if (!data.approvalTypeStepList.isEmpty()) {
                Set<Id> TMP_approvalStepIdSet = new Set<Id>();
                for (DQ_Approval_Type_Step__c approvalTypeStep : data.approvalTypeStepList) {
                    if (!TMP_approvalStepIdSet.contains(approvalTypeStep.DQ_Approval_Step__c) && stepIdToStepApproversMap.containsKey(approvalTypeStep.DQ_Approval_Step__c)) {
                        TMP_approvalStepIdSet.add(approvalTypeStep.DQ_Approval_Step__c);
                        data.stepApproversList.addAll(stepIdToStepApproversMap.get(approvalTypeStep.DQ_Approval_Step__c));
                    }
                }
            }
            approvalTypeStepIdToApproverStepDataMap.put(approvalTypeStepId, data);
        }

        approvalTypeStepIdToApproverStepDataMap = checkForDefaultApprovers(approvalTypeStepIdToApproverStepDataMap, dqData.mainQuoteData.isPrmQuote);

        List<ApproverStepData> approverStepDataList = isFirstLevelApprovalRequired && !dqData.mainQuoteData.isPrmQuote
            ? addOpportunityOwnerApproval(dqData, approvalTypeStepIdToApproverStepDataMap.values())
            : approvalTypeStepIdToApproverStepDataMap.values();

        return approverStepDataList;
    }

    private static Set<Id> getApprovalStepIdSet(List<DQ_Approval_Type_Step__c> approvalTypeStepList) {
        Set<Id> approvalStepIdSet = new Set<Id>();
        if (approvalTypeStepList == null || approvalTypeStepList.isEmpty()) {
            return approvalStepIdSet;
        }
        for (DQ_Approval_Type_Step__c approvalTypeStep : approvalTypeStepList) {
            approvalStepIdSet.add(approvalTypeStep.DQ_Approval_Step__c);
        }
        return approvalStepIdSet;
    }

    private static Map<Id, ApproverStepData> buildApproverStepDataMap(
        Map<String, List<DQ_Approval_Type_Step__c>> stepNameToApprovalTypeStepListMap,
        Map<String, String> stepNameToReasonMap,
        Map<Id, DQ_Approval_Step__c> approvalStepsMap,
        Map<Id, String> approvalTypeIdToReasonMap
    ) {
        Map<Id, ApproverStepData> result = new Map<Id, ApproverStepData>();
        if (stepNameToApprovalTypeStepListMap == null || stepNameToApprovalTypeStepListMap.isEmpty()) {
            return result;
        }

        for (String stepName : stepNameToApprovalTypeStepListMap.keySet()) {
            List<DQ_Approval_Type_Step__c> approvalTypeSteps = stepNameToApprovalTypeStepListMap.get(stepName);
            if (approvalTypeSteps.isEmpty()) {
                continue;
            }

            Map<Id, Set<String>> stepIdToServiceNames = new Map<Id, Set<String>>();
            Map<String, List<DQ_Approval_Type_Step__c>> stepIdServiceMap = new Map<String, List<DQ_Approval_Type_Step__c>>();
            
            for (DQ_Approval_Type_Step__c approvalTypeStep : approvalTypeSteps) {
                String serviceName = approvalTypeStep.DQ_Approval_Type__r != null 
                    && approvalTypeStep.DQ_Approval_Type__r.ServiceName__c != null
                    ? approvalTypeStep.DQ_Approval_Type__r.ServiceName__c 
                    : '';
                
                if (String.isNotBlank(serviceName)) {
                    Id stepId = approvalTypeStep.DQ_Approval_Step__c;
                    if (!stepIdToServiceNames.containsKey(stepId)) {
                        stepIdToServiceNames.put(stepId, new Set<String>());
                    }
                    stepIdToServiceNames.get(stepId).add(serviceName);
                }
                
                if (String.isBlank(serviceName)) {
                    Id stepId = approvalTypeStep.DQ_Approval_Step__c;
                    Set<String> serviceNames = stepIdToServiceNames.get(stepId);
                    if (serviceNames != null && serviceNames.size() == 1) {
                        serviceName = new List<String>(serviceNames)[0];
                    }
                }
                
                String key;
                if (serviceName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                    key = approvalTypeStep.DQ_Approval_Step__c + '|' + serviceName;
                } else {
                    key = String.valueOf(approvalTypeStep.DQ_Approval_Step__c);
                }
                
                List<DQ_Approval_Type_Step__c> groupList = stepIdServiceMap.get(key);
                if (groupList == null) {
                    groupList = new List<DQ_Approval_Type_Step__c>();
                    stepIdServiceMap.put(key, groupList);
                }
                groupList.add(approvalTypeStep);
            }

            for (String key : stepIdServiceMap.keySet()) {
                List<DQ_Approval_Type_Step__c> groupedSteps = stepIdServiceMap.get(key);
                if (groupedSteps.isEmpty()) {
                    continue;
                }

                DQ_Approval_Type_Step__c approvalTypeStep = groupedSteps.get(0);
                DQ_Approval_Step__c approvalStep = approvalStepsMap.get(approvalTypeStep.DQ_Approval_Step__c);
                if (approvalStep == null) {
                    continue;
                }

                ApproverStepData data = new ApproverStepData();
                data.approvalStep = approvalStep;
                
                String stepNameForReason = approvalTypeStep.DQ_Approval_Step__r != null 
                    ? approvalTypeStep.DQ_Approval_Step__r.Name 
                    : null;
                if (stepNameForReason != null && stepNameToReasonMap.containsKey(stepNameForReason)) {
                    data.approvalReason = stepNameToReasonMap.get(stepNameForReason);
                }
                
                data.approvalTypeStepList = groupedSteps;

                Map<Id, String> stepIdToServiceName = new Map<Id, String>();
                List<ApprovalTypeStepData> approvalTypeStepDataList = new List<ApprovalTypeStepData>();
                
                for (DQ_Approval_Type_Step__c item : groupedSteps) {
                    String approvalReason = approvalTypeIdToReasonMap.get(item.DQ_Approval_Type__c);
                    approvalTypeStepDataList.add(new ApprovalTypeStepData(approvalReason, item));
                    
                    if (item.DQ_Approval_Type__r != null && item.DQ_Approval_Type__r.ServiceName__c != null) {
                        stepIdToServiceName.put(item.DQ_Approval_Step__c, item.DQ_Approval_Type__r.ServiceName__c);
                    }
                }
                
                data.approvalTypeStepDataList = approvalTypeStepDataList;
                data.stepIdToServiceName = stepIdToServiceName;

                result.put(approvalTypeStep.Id, data);
            }
        }
        
        return result;
    }

    private static Map<Id, DQ_Approval_Step__c> getApprovalStepsMap(Set<Id> approvalStepIdSet) {
        if (approvalStepIdSet == null || approvalStepIdSet.isEmpty()) {
            return new Map<Id, DQ_Approval_Step__c>();
        }
        return new Map<Id, DQ_Approval_Step__c>(
            [SELECT Id, Name, Step_Order__c, Overall_Discount__c, Deal_Size__c
                FROM DQ_Approval_Step__c
                WHERE Id IN :approvalStepIdSet
                ORDER BY Step_Order__c DESC]
        );
    }

    private static String getStepReason(String previousStepReason, String newStepReason) {
        if (String.isBlank(previousStepReason)) {
            return newStepReason;
        }
        String result = previousStepReason;
        if (!result.contains(newStepReason)) {
            result += ', ' + newStepReason;
        }
        return result;
    }

    private static ApproverStepData getApproverStepDataByMatchingStepId (Id approvalTypeStepId, Map<Id, ApproverStepData> approverStepDataMap) {
        for (ApproverStepData data : approverStepDataMap.values()) {
            Set<Id> setOfApprovalStepsTypeIds = (new Map<Id, DQ_Approval_Type_Step__c> (data.approvalTypeStepList)).keySet();
            if (setOfApprovalStepsTypeIds.contains(approvalTypeStepId)) {
                return data;
            }
        }
        return null;
    }

    private static Map<Id, ApproverStepData> checkForDefaultApprovers(Map<Id, ApproverStepData> approverStepDataMap, Boolean isPrmQuote) {

        Set<Id> approvalStepIdSet = getApprovalStepIdsForDefaultApprovers(approverStepDataMap);

        List<DQ_Approval_Step_Approver__c> listOfDefaultStepApprovers = getDefaultApprovers(approvalStepIdSet, isPrmQuote);

        Map<Id, DQ_Approval_Step_Approver__c> approvalStepIdToApproverMap = new Map<Id, DQ_Approval_Step_Approver__c>();

        for (DQ_Approval_Step_Approver__c approvalStepApprover : listOfDefaultStepApprovers) {
            approvalStepIdToApproverMap.put(approvalStepApprover.DQ_Approval_Step__c, approvalStepApprover);
        }

        for (ApproverStepData data : approverStepDataMap.values()) {
            if (data.stepApproversList.isEmpty() && approvalStepIdToApproverMap.containsKey(data.approvalStep.Id)) {
                data.stepApproversList.add(approvalStepIdToApproverMap.get(data.approvalStep.Id));
            }
            Boolean isDefaultApproverRequire = true;
            for (DQ_Approval_Step_Approver__c approvalStepApprover : data.stepApproversList) {
                if (approvalStepApprover.Approval_Type__c != 'Notification') {
                    isDefaultApproverRequire = false;
                    break;
                }
            }
            if (isDefaultApproverRequire) {
                if (approvalStepIdToApproverMap.containsKey(data.approvalStep.Id)) {
                    data.stepApproversList.add(approvalStepIdToApproverMap.get(data.approvalStep.Id));
                }
            }
        }

        return approverStepDataMap;
    }

    private static Set<Id> getApprovalStepIdsForDefaultApprovers(Map<Id, ApproverStepData> approverStepDataMap) {
        Set<Id> approvalStepIdSet = new Set<Id>();
        for (ApproverStepData data : approverStepDataMap.values()) {
            if (data.stepApproversList.isEmpty()) {
                approvalStepIdSet.add(data.approvalStep.Id);
            }
            Boolean isDefaultApproverRequire = true;
            for (DQ_Approval_Step_Approver__c approvalStepApprover : data.stepApproversList) {
                if (approvalStepApprover.Approval_Type__c != 'Notification') {
                    isDefaultApproverRequire = false;
                    break;
                }
            }
            if (isDefaultApproverRequire) {
                approvalStepIdSet.add(data.approvalStep.Id);
            }
        }
        return approvalStepIdSet;
    }

    private static List<DQ_Approval_Step_Approver__c> getDefaultApprovers(Set<Id> approvalStepIdSet, Boolean isPrmQuote) {
        List<DQ_Approval_Step_Approver__c> result = new List<DQ_Approval_Step_Approver__c>();
        if (approvalStepIdSet == null || approvalStepIdSet.isEmpty()) {
            return result;
        }
        result = new List<DQ_Approval_Step_Approver__c>([
            SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c
            FROM DQ_Approval_Step_Approver__c
            WHERE DQ_Approval_Step__c =:approvalStepIdSet AND Default__c = true AND IsStepApproverForPRM__c =:isPrmQuote
        ]);
        return result;
    }

    @TestVisible
    private static List<ApproverStepData> addOpportunityOwnerApproval(DQDataHelper.DealQualificationData dqData, List<ApproverStepData> approverStepDataList) {
        if (dqData == null || dqData.opportunityData.oppId == null || approverStepDataList == null || approverStepDataList.isEmpty()) {
            return approverStepDataList;
        }
        Opportunity opp = [
            SELECT Id, OwnerId, Owner.ManagerId, Owner.Manager.Name, Brand_Name__c, Segment_Name__c, CurrencyIsoCode
            FROM Opportunity
            WHERE Id =: dqData.opportunityData.oppId
        ];

        ApproverStepData commonServiceLevel1Data = null;
        for (ApproverStepData data : approverStepDataList) {
            if (data.approvalStep != null && data.approvalStep.Name == 'Level 1') {
                Boolean isProServStep = false;
                for (String service : data.stepIdToServiceName.values()) {
                    if (service == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                        isProServStep = true;
                        break;
                    }
                }
                if (!isProServStep) {
                    commonServiceLevel1Data = data;
                    break;
                }
            }
        }

        if (commonServiceLevel1Data != null) {
            Map<String, Integer> stepOrderMap = getMaxStepOrder(approverStepDataList);
            Integer maxStepOrderForCommonService = stepOrderMap.get(APPROVAL_COMMON_SERVICE);
            
            Boolean isLevel1LatestStep = commonServiceLevel1Data.approvalStep != null 
                && commonServiceLevel1Data.approvalStep.Step_Order__c != null 
                && commonServiceLevel1Data.approvalStep.Step_Order__c == maxStepOrderForCommonService;
            String approvalType = isLevel1LatestStep ? 'Approval' : 'Notification';
            
            String segment = opp.Segment_Name__c == null ? 'SOHO' : opp.Segment_Name__c;
            if (opp.Owner.ManagerId != null) {
                DQ_Approval_Step_Approver__c approvalStepApprover = new DQ_Approval_Step_Approver__c(
                    Brand__c = opp.Brand_Name__c,
                    Segment__c = segment,
                    DQ_Approval_Step__c = commonServiceLevel1Data.approvalStep.Id,
                    Approval_Type__c  = approvalType,
                    Region__c = getRegionValueByOppCurrencyISO(opp.CurrencyIsoCode),
                    OwnerId = opp.Owner.ManagerId
                );
                commonServiceLevel1Data.managerDetail = new User(
                    Id = opp.Owner.ManagerId,
                    FirstName = opp.Owner.Manager.Name
                );
                commonServiceLevel1Data.stepApproversList.add(approvalStepApprover);
            } else {
                QueueSObject ownerQueue = (QueueSObject) new QueueSelector()
                    .selectQueueByName(new List<Object> {'Deal Desk'})
                    .executeQuery()
                    .get(0);
                if (ownerQueue != null && ownerQueue.QueueId != null) {
                    DQ_Approval_Step_Approver__c approvalStepApprover = new DQ_Approval_Step_Approver__c(
                        Brand__c = opp.Brand_Name__c,
                        Segment__c = segment,
                        DQ_Approval_Step__c = commonServiceLevel1Data.approvalStep.Id,
                        Approval_Type__c  = approvalType,
                        Region__c = getRegionValueByOppCurrencyISO(opp.CurrencyIsoCode),
                        OwnerId = ownerQueue.QueueId
                    );
                    commonServiceLevel1Data.dealDeskDetail = new Group(
                        Id = ownerQueue.QueueId,
                        Name = 'Deal Desk'
                    );
                    commonServiceLevel1Data.stepApproversList.add(approvalStepApprover);
                }
            }
        }
        return approverStepDataList;
    }

    private static String getRegionValueByOppCurrencyISO(String currencyIso) {
        Map<String, String> isoCodeToCountryMap = new Map<String, String>{
            'USD' => 'US',
            'EUR' => 'EU',
            'AUS'=> 'Australia'
        };

        if (isoCodeToCountryMap.containsKey(currencyIso)) {
            return isoCodeToCountryMap.get(currencyIso);
        }
        return isoCodeToCountryMap.get('USD');
    }

    public static Map<String, Integer> getMaxStepOrder(List<ApproverStepData> approverStepDataList) {
        Map<String, Integer> stepOrderMap = new Map<String, Integer>{
            APPROVAL_PROSERV_SERVICE => 0,
            APPROVAL_COMMON_SERVICE => 0
        };

        if (approverStepDataList == null || approverStepDataList.isEmpty()) {
            return stepOrderMap;
        }
        
        Integer maxProServOrder = 0;
        Integer maxCommonOrder = 0;
        
        for (ApproverStepData data : approverStepDataList) {
            if (data.approvalStep == null || data.approvalStep.Step_Order__c == null) {
                continue;
            }
            
            if (data.stepApproversList.size() == 1 && data.stepApproversList.get(0) == null) {
                continue;
            }
            
            Integer stepOrder = Integer.valueOf(data.approvalStep.Step_Order__c);
            Boolean isProServ = false;
            
            if (!data.stepIdToServiceName.isEmpty()) {
                String firstService = data.stepIdToServiceName.values().iterator().next();
                isProServ = firstService == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
            } else if (data.approvalTypeStepDataList != null && !data.approvalTypeStepDataList.isEmpty()) {
                ApprovalTypeStepData firstItem = data.approvalTypeStepDataList[0];
                if (firstItem.dqApprovalTypeStep != null 
                    && firstItem.dqApprovalTypeStep.DQ_Approval_Type__r != null) {
                    String serviceName = firstItem.dqApprovalTypeStep.DQ_Approval_Type__r.ServiceName__c;
                    isProServ = serviceName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;
                }
            }
            
            if (isProServ) {
                if (maxProServOrder < stepOrder) {
                    maxProServOrder = stepOrder;
                }
            } else {
                if (maxCommonOrder < stepOrder) {
                    maxCommonOrder = stepOrder;
                }
            }
        }
        
        stepOrderMap.put(APPROVAL_PROSERV_SERVICE, maxProServOrder);
        stepOrderMap.put(APPROVAL_COMMON_SERVICE, maxCommonOrder);
        return stepOrderMap;
    }

    public static Map<Id, String> buildApprovalStepIdToApprovalReasonMap(List<ApproverStepData> approverStepDataList) {
        Map<Id, String> result = new Map<Id, String>();
        if (approverStepDataList == null || approverStepDataList.isEmpty()) {
            return result;
        }
        for (ApproverStepData approverStepDataItem : approverStepDataList) {
            for (ApprovalTypeStepData approvalReasonData : approverStepDataItem.approvalTypeStepDataList) {
                Id dqApprovalStepId = approvalReasonData.dqApprovalTypeStep.DQ_Approval_Step__c;
                if (!String.isBlank(approvalReasonData.approvalReason)) {
                    if (!result.containsKey(dqApprovalStepId)) {
                        result.put(dqApprovalStepId, approvalReasonData.approvalReason);
                    } else {
                        String approvalReason = result.get(dqApprovalStepId);
                        result.put(dqApprovalStepId, approvalReason + ',' + approvalReasonData.approvalReason);
                    }
                }
            }
        }
        return result;
    }

    public static String getApprovalReason(Map<Id, String> approvalStepIdToApprovalReasonMap, DQ_Approval_Step_Approver__c approvalStepApprover, DQApproverStepHelper.ApproverStepData approverStepDataItem) {
        List<String> approvalReasonList = new List<String>();
        String modifiedApprovalReason;
        if (approvalStepIdToApprovalReasonMap.containsKey(approvalStepApprover.DQ_Approval_Step__c)) {
            String approvalReason = approvalStepIdToApprovalReasonMap.get(approvalStepApprover.DQ_Approval_Step__c);
            
            if (approvalReason.contains(',')) {
                approvalReasonList.addAll(approvalReason.split(','));
            } else {
                approvalReasonList.add(approvalReason);
            }
        }
        if (approvalReasonList.isEmpty() && !String.isBlank(approverStepDataItem.approvalReason)) {
            approvalReasonList.add(approverStepDataItem.approvalReason);
        }
        if (!approvalReasonList.isEmpty()) {
            modifiedApprovalReason = String.join(approvalReasonList, '\r\n');
        }
        return modifiedApprovalReason;
    }

    public static String getServiceKey(DQApproverStepHelper.ApproverStepData approverStepDataItem, DQ_Approval_Step_Approver__c approvalStepApprover) {
        String service = approverStepDataItem.stepIdToServiceName.get(approvalStepApprover.DQ_Approval_Step__c);
		String serviceKey = service == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT ? APPROVAL_PROSERV_SERVICE : APPROVAL_COMMON_SERVICE;
        return serviceKey;
    }
}