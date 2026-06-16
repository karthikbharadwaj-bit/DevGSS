/*************************************************
Trigger on Task object
After Insert & Update: Throw error if due date is past.
Set Responded and Last Touched fields as needed.
/************************************************/

trigger Task on Task (before insert, before update) {

     if (TriggerHandler.BY_PASS_BEFORE) {
        System.debug('### RETURNED FROM TASK TRIGGER BEFORE TRG FOR STANDARD LAYOUT ###');
        return;
    }
    
    static final String PROFILE_SYS_ADMIN = 'System Administrator';
    static final Id RT_TASK_STANDARD_TASK = Schema.SObjectType.Task.getRecordTypeInfosByName()
        .get('Standard Task').getRecordTypeId();

    Profile currentUserProfileRecord = null;
    if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
        currentUserProfileRecord = ProfileHelper.getCurrentUserProfileWithCache();
    }
    else {
        currentUserProfileRecord = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    }

    Set<String> statusesFirstTouchUpdate = new Set<String>{
        'In Progress',
        'Completed',
        'Waiting on someone else',
        'Declined',
        'In Progress - Call Out',
        'In Progress - Waiting on someone else',
        'In Progress - Contacted',
        'Completed with opp',
        'Completed with no opp',
        'Deferred'
    };
    Set<String> statusesLastTouchUpdate = new Set<String>{
        'Completed',
        'Completed with opp',
        'Completed with no opp',
        'Deferred'
    };
    for (Task taskObj : Trigger.new) {
        Boolean isOldStatusInStatusesFirstTouchUpdate = false;
        if (Trigger.isUpdate && statusesFirstTouchUpdate.contains(Trigger.oldMap.get(taskObj.Id).Status)) {
            isOldStatusInStatusesFirstTouchUpdate = true;
        }
        if (statusesFirstTouchUpdate.contains(taskObj.Status)
            && (CoreObjectBase.isFieldChanged(taskObj, Task.Status) && !isOldStatusInStatusesFirstTouchUpdate)) {
                Datetime taskCreatedDate = (taskObj.CreatedDate != null ? taskObj.CreatedDate : DateTime.now());
                Datetime taskLastModifiedDate = (taskObj.LastModifiedDate != null ? taskObj.LastModifiedDate : DateTime.now());
                taskObj.SLA_First_Touch__c = Date.valueOf(taskCreatedDate).daysBetween(Date.valueOf(taskLastModifiedDate));
        }
        if (statusesLastTouchUpdate.contains(taskObj.Status)) {
            taskObj.SLA_Last_Touch_Stamp__c = DateTime.now();
        }
    }

    // by passing the system admin
    if (PROFILE_SYS_ADMIN.equalsIgnoreCase(currentUserProfileRecord.Name)) {
        return;
    }

    Boolean errorFound = false;

    /*Set for What & Who Id*/
    Set<Id> whatIds = new Set<Id>();
    Set<Id> whoIds = new Set<Id>();

    //Regex patter to find values like: "From: user@rc.com"
    Pattern taskDescrPattern = Pattern.compile('(?ms)^(From:)+.+@.+');

    for (Task taskObj : Trigger.new) {
        whatIds.add(taskObj.WhatId);
        whoIds.add(taskObj.WhoId);

        //Will bypass Task w. record type "Standard Task" and if Description field contains
        //something like "From: guest@site.com"
        //These tasks are looks like to be came from Salesforce to Outlook tool and
        //we should not check their Due date
        if (Trigger.isInsert) {
            if (taskObj.RecordTypeId == RT_TASK_STANDARD_TASK && String.isNotBlank(taskObj.Description)) {
                if (taskDescrPattern.matcher(taskObj.Description).matches()) {
                    continue;
                }
            }

            if( taskObj.ActivityDate < Date.today()) {
                taskObj.ActivityDate.addError('Your task due date cannot be past due.');
                errorFound |= true;
            }
        }
    }

    if (errorFound) {
        return;
    }

    /*List For Opportunity & Lead*/
    List<Opportunity> oppList = new List<Opportunity>();
    List<Lead> leadList = new List<Lead>();
    Map<Id,Opportunity> oppMap;
    Map<Id,Lead> leadMap;
    if(!whatIds.isEmpty() ){
        oppMap = new Map<Id,Opportunity>([SELECT Id, Responded_Date__c, Responded_By__c,
            Last_Touched_Date__c, Last_Touched_By__c
            FROM Opportunity
            WHERE Id IN :whatIds]);
    }
    if(!whoIds.isEmpty() ){
        leadMap = new Map<Id, Lead>([SELECT Id, Responded_Date__c ,Responded_By__c,
            Last_Touched_Date__c, Last_Touched_By__c
            FROM Lead
            WHERE Id IN :whoIds]);
    }
    for(Task taskObj: Trigger.new) {
        try {
            Opportunity opp = oppMap.get(taskObj.WhatId);
            if(opp != null) {
                if(opp.Responded_Date__c == null && opp.Responded_By__c == null) {
                    opp.Responded_Date__c = Datetime.now();
                    opp.Responded_By__c = UserInfo.getUserId();
                }
                opp.Last_Touched_Date__c  = Datetime.now();
                opp.Last_Touched_By__c = UserInfo.getUserId();
                oppList.add(opp);
            }

            Lead leadObj =  leadMap.get(taskObj.WhoId);
            if(leadObj != null) {
                if(leadObj.Responded_Date__c == null && leadObj.Responded_By__c == null){
                    leadObj.Responded_Date__c = Datetime.now();
                    leadObj.Responded_By__c = UserInfo.getUserId();
                }
                leadObj.Last_Touched_Date__c  = Datetime.now();
                leadObj.Last_Touched_By__c = UserInfo.getUserId();
                leadList.add(leadObj);
            }
        } catch(Exception e) {
            taskObj.addError(e);
        }
    }

    try {
        if(leadList.size() > 0){
            TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT();
            Triggers.switchOff();
            update leadList;
            Triggers.switchOn();
            TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        }

        if(oppList.size() > 0){
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            Triggers.switchOff();
            update oppList;
            Triggers.switchOn();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        }
    } catch(Exception e) {
        PlatformLog.logException('Task trigger', e);
    }
}