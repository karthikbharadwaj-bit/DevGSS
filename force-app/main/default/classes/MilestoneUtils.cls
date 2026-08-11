/**************************************************************************************************
* Project Name..........: Entitlement                                                             *
* File..................: MilestoneUtils.class                                                    *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 26-06-2013                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 26-06-2013                                                              *
* Description...........: Milstone Utility Class, contains logic for milestons creation,          *
*                         closing as per the case record type and associated business hours.      *
*                         case assignment.                                                        *
**************************************************************************************************/

public class MilestoneUtils {

    //Declaring variables & constants.
    //private static final String WAITING_ON_CUSTOMER = 'Waiting on Customer';
    private static final String WORK_IN_PROGRESS = 'Work in Progress';
    private static final String UPDATED_BY_CUSTOMER = 'Updated by Customer';
    private static final String CLOSED = 'Closed';
    private static final String CLOSED_NO_RESPONSE = 'Closed - No Response';
    private static final String OFFLINE_ESCALATION = 'Offline Escalation';

    // Record Types
    private static final String SUPPORT_CASE = 'Support-Case';
    private static final String SUPPORT_T1 = 'Support - T1';
    private static final String SUPPORT_T2 = 'Support - T2';
    private static final String SUPPORT_T3 = 'Support - T3';
    private static final String SUPPORT_QOS = 'Support - QoS';
    private static final String SUPPORT_ERT = 'Support - Executive Response Team';
    private static final String SUPPORT_TELUS = 'Support - Telus';
    private static final String SUPPORT_CUSTOMER_EBONDING = 'Support - Customer ebonding';

    // Map to contain, record type <=> Milestone names (First Response, Follow Up, Resolution) in the specified order.
    private static final Map<String,List<String>> caseRecordTypeMilestoneMap =  new Map<String,List<String>>();
    private static final List<String> risePartnerRecordTypes = new List<String>(); 
    private static final List<String> refinedCMRecordTypes = new List<String>(); 

    // Set of status names, to be included as an exception for fist response, follow up, resolution milestone.
    private static final Set<String> FIRST_RESPONSE_MILESTONE_STATUS_EXCEPTION = new Set<String>{'Cancelled', 'Invalid', 'Duplicate'};
    private static final Set<String> FOLLOW_UP_MILESTONE_STATUS_EXCEPTION =  new Set<String>{'PKI Hold', 'New', 'Cancelled', 'Invalid', 'Duplicate'};
    private static final Set<String> RESOLUTION_MILESTONE_STATUS_EXCEPTION = new Set<String>();

    /******************************************************************************
    * @Description : Static Block                                                 *
    * @Params      : none                                                         *
    * @Return      : none                                                         *
    ******************************************************************************/
    static{
        List<String> milestoneList;
        if(Entitlement_Case_Milestone_Configuration__c.getAll() != null && Entitlement_Case_Milestone_Configuration__c.getAll().size() > 0){
            for(String thisRecord : Entitlement_Case_Milestone_Configuration__c.getAll().keyset()){
                milestoneList = new List<String>();
                milestoneList.add(String.valueOf(Entitlement_Case_Milestone_Configuration__c.getValues(thisRecord).get('First_Response_Milestone__c')));
                milestoneList.add(String.valueOf(Entitlement_Case_Milestone_Configuration__c.getValues(thisRecord).get('FollowUp_Milestone__c')));
                milestoneList.add(String.valueOf(Entitlement_Case_Milestone_Configuration__c.getValues(thisRecord).get('Case_Resolution_Milestone__c')));
                if(milestoneList != null && milestoneList.size() > 0){
                    System.debug('#### Case Record Type = '+thisRecord+' = Milestone = '+milestoneList);
                    caseRecordTypeMilestoneMap.put(thisRecord, milestoneList);
                }
            }
        }

        List<RISE_Partner_Support_RecordTypes__mdt> riseRTMetadataList = RISE_Partner_Support_RecordTypes__mdt.getAll().values();
        for (RISE_Partner_Support_RecordTypes__mdt recTypeRow : riseRTMetadataList) {
            risePartnerRecordTypes.add(recTypeRow.Label);
        }
        
        List<Refined_Case_Milestone_Record_Types__mdt> refinedRTMetadataList = Refined_Case_Milestone_Record_Types__mdt.getAll().values();
        for (Refined_Case_Milestone_Record_Types__mdt recTypeRow : refinedRTMetadataList) {
            refinedCMRecordTypes.add(recTypeRow.Label);
        }
    }

    /******************************************************************************
    * @Description : Closes milestone.                                            *
    * @Params      : List<Id>, String, DateTime                                   *
    * @Return      : void                                                         *
    ******************************************************************************/
    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) {

        List<CaseMilestone> cmsToUpdate =  new List<CaseMilestone>();
        System.debug('#### Milestone - '+milestoneName);
        System.debug('#### Case Id - '+caseIds);
        System.debug('#### Completion Date - '+complDate);

        if((caseIds == null || caseIds.isEmpty()) && String.isBlank(milestoneName) && complDate == null) {
            return;
        }

        try{
            cmsToUpdate = [SELECT Id, completionDate
                FROM CaseMilestone cm
                WHERE caseId IN: caseIds
                    AND cm.MilestoneType.Name =: milestoneName
                    AND completionDate = null limit 1];

            if (cmsToUpdate != null && !cmsToUpdate.isEmpty()) {
                for (CaseMilestone cm : cmsToUpdate){
                    cm.completionDate = complDate;
                }
                update cmsToUpdate;
            } // end if
        }catch(Exception ex) {
            System.debug('#### Error @ closeCaseMilestone - '+ex.getMessage()+' Line No---->'+ex.getLineNumber());
        }
    }

    /******************************************************************************
    * @Description : Segregate list of Case<Ids> to be passed in completeMilestone*
    *                method for milestone closing.                                *
    * @Params      : Map<Id, Case>, Map<Id, Case>                                 *
    * @Return      : void                                                         *
    ******************************************************************************/
    public static void closeCaseMilestone(Map<Id,Case> oldCaseMap, Map<Id,Case> newCaseMap) {

        if(newCaseMap == null) {
            return;
        }

        // Variable to contain map of String(Record Type Name) <--> case Id, for milestone closure.
        Map<String,List<Id>> firsResponseMap =  new Map<String,List<Id>>();
        Map<String,List<Id>> followUpMap =  new Map<String,List<Id>>();
        Map<String,List<Id>> resolutionMap =  new Map<String,List<Id>>();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();

        for(Id thisRecord : newCaseMap.keySet()) {

            // Maintaining new and old case object.
            Case newRecord = newCaseMap.get(thisRecord);
            Case oldRecord = oldCaseMap != null ? oldCaseMap.get(thisRecord) : null;
            String caseRecordTypeName = rtMapById.get(newRecord.recordTypeId).Name;

            Boolean isInternalCommentsChanged = oldRecord != null &&
                newRecord.Comments != null && newRecord.Comments != oldRecord.Comments;

            Boolean isFirstRespTmstmpNotEmptyForSpecRecordType = isFirstRespTmstmpNotEmptyForSpecificRecordTypes(newRecord, caseRecordTypeName);

            /* Creating Map for record type <--> List of Id's, for which first response milestone needs to be closed. */
            if(!FIRST_RESPONSE_MILESTONE_STATUS_EXCEPTION.contains(newRecord.Status) &&
                (isFirstRespTmstmpNotEmptyForSpecRecordType ||
                (isInternalCommentsChanged && CaseHelper.RT_ID_SUPPORT_INTEGRATIONS == newRecord.recordTypeId))) {

                if(firsResponseMap.get(caseRecordTypeName) != null) {
                    firsResponseMap.get(caseRecordTypeName).add(thisRecord);
                }else{
                    firsResponseMap.put(caseRecordTypeName, new List<Id>{thisRecord});
                }
            }

            /* Creating Map for record type <--> List of Id's, for which follow up milestone needs to be closed. */
            if(oldRecord != null && newRecord.Last_Agent_Update__c != oldRecord.Last_Agent_Update__c &&
                (isFirstRespTmstmpNotEmptyForSpecRecordType || SUPPORT_T1.equalsIgnoreCase(caseRecordTypeName))) {

                if(!FOLLOW_UP_MILESTONE_STATUS_EXCEPTION.contains(newRecord.Status)) {
                    if(followUpMap.get(caseRecordTypeName) != null) {
                        followUpMap.get(caseRecordTypeName).add(thisRecord);
                    }else{
                        followUpMap.put(caseRecordTypeName, new List<Id>{thisRecord});
                    }
                }
            }

            /* Creating Map for record type <--> List of Id's, for which resolution milestone needs to be closed. */
            if((newRecord.Status.equalsIgnoreCase(CLOSED) || newRecord.Status.equalsIgnoreCase(CLOSED_NO_RESPONSE))) {
                if(resolutionMap.get(caseRecordTypeName) != null) {
                    resolutionMap.get(caseRecordTypeName).add(thisRecord);
                }else{
                    resolutionMap.put(caseRecordTypeName, new List<Id>{thisRecord});
                }
            }
        }

        // Calling methods to close milestone.
        closeRespectiveMilestone(firsResponseMap, followUpMap, resolutionMap);
    }

    /******************************************************************************
    * @Description : Calling method to finally close the milestone.               *
    * @Params      : Map<Id, Case>, Map<Id, Case>                                 *
    * @Return      : void                                                         *
    ******************************************************************************/
    public static void closeRespectiveMilestone(Map<String,List<Id>> firsResponseMap,Map<String,List<Id>> followUpMap,Map<String,List<Id>> resolutionMap){

        if(firsResponseMap == null && followUpMap == null && resolutionMap == null) {
            return;
        }

        // Closing all first response milestones
        for(String thisRecord : firsResponseMap.keySet()) {
            if(caseRecordTypeMilestoneMap != null &&
                caseRecordTypeMilestoneMap.containsKey(thisRecord) &&
                caseRecordTypeMilestoneMap.get(thisRecord) != null) {

                completeMilestone(firsResponseMap.get(thisRecord), caseRecordTypeMilestoneMap.get(thisRecord)[0], system.now());
            }
        }
        // Closing all follow up milestones
        for(String thisRecord : followUpMap.keySet()){
            if(caseRecordTypeMilestoneMap != null &&
                caseRecordTypeMilestoneMap.containsKey(thisRecord) &&
                caseRecordTypeMilestoneMap.get(thisRecord) != null){

                completeMilestone(followUpMap.get(thisRecord), caseRecordTypeMilestoneMap.get(thisRecord)[1], system.now());
            }
        }
        // Closing all resolution milestones
        for(String thisRecord : resolutionMap.keySet()){
            if(caseRecordTypeMilestoneMap != null &&
                caseRecordTypeMilestoneMap.containsKey(thisRecord) &&
                caseRecordTypeMilestoneMap.get(thisRecord) != null){

                completeMilestone(resolutionMap.get(thisRecord), caseRecordTypeMilestoneMap.get(thisRecord)[2], system.now());
            }
        }
    }

    @TestVisible
    private static Boolean isFirstRespTmstmpNotEmptyForSpecificRecordTypes(Case caseRecord, String caseRecordTypeName) {

        Boolean result = false;

        if (caseRecord == null && String.isBlank(caseRecordTypeName)) {
            return result;
        }

        if (String.isBlank(caseRecordTypeName)) {
            caseRecordTypeName = '';
        }

        result = (
            (caseRecord.First_Response_Timestamp__c != null && SUPPORT_CASE.equalsIgnoreCase(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_T2__c  != null && SUPPORT_T2.equalsIgnoreCase(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_T3__c  != null && SUPPORT_T3.equalsIgnoreCase(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_QoS__c != null && SUPPORT_QOS.equalsIgnoreCase(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_ERT__c != null && SUPPORT_ERT.equalsIgnoreCase(caseRecordTypeName)) ||
           // (caseRecord.First_Response_Timestamp_NTD__c != null && caseRecordTypeName.contains('Porting')) ||
            (caseRecord.First_Response_Timestamp_TELUS__c != null && risePartnerRecordTypes.contains(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_TELUS__c != null && refinedCMRecordTypes.contains(caseRecordTypeName)) ||
            (caseRecord.First_Response_Timestamp_TELUS__c != null && SUPPORT_CUSTOMER_EBONDING.equalsIgnoreCase(caseRecordTypeName))
            );

        return result;
    }
}// End of Class.