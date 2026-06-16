public with sharing class SuccessPlanController {   
   
    @AuraEnabled()
    public static void insertSucessPlanAndActivities(String accId) {
        list<SuccessPlanActivity__c> sucPlaActLst = new list<SuccessPlanActivity__c>();      
        Success_Plan__c supln = new Success_Plan__c();
        supln.Account__c=accId;
        //supln.Partner_Persona_Job_Aid__c=System.Label.SuccessPlanPartnerJobAid; // Updated by Thejasvi
        supln.RBE_Notes__c=System.Label.RBE_NOTES; //Updated by Thejasvi
        insert supln;
       
        for(SuccessPlanActivityData__mdt spd : [select Id, Activity_Name__c, ActivityType__c, PartnerReadinessScore__c, WhatDoYouNeedToDo__c from SuccessPlanActivityData__mdt]) {
            SuccessPlanActivity__c suPlAct = new SuccessPlanActivity__c();
            suPlAct.SuccessPlan__c=supln.Id;
            suPlAct.ActivityName__c=spd.Activity_Name__c;
            suPlAct.Stage__c=spd.ActivityType__c;
            suPlAct.PartnerReadinessScore__c=spd.PartnerReadinessScore__c;
            suPlAct.What_do_you_need_to_do__c=spd.WhatDoYouNeedToDo__c;
            sucPlaActLst.add(suPlAct);           
        }
        if(!sucPlaActLst.isEmpty()) {
            insert sucPlaActLst;
        }
    }

    @AuraEnabled()
    public static success_plan__c getSuccessPlan(String accId) {  
        Success_Plan__c  SPRecord =  [SELECT Id, RBE_Notes__c, Partner_Readiness_Score__c
        FROM success_plan__c
        where account__c= :accId];  
        return SPRecord;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static success_plan__c getSuccessPlanWire(String accId) {  
        Success_Plan__c  SPRecord =  [SELECT Id, RBE_Notes__c, Partner_Readiness_Score__c
        FROM success_plan__c
        where account__c= :accId];  
        return SPRecord;
        
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canGenerateSuccessPlan(String accId) {       
        List<Account> accList = new List<Account>();
        Boolean canGenerate = FALSE;
        String partnerType = System.Label.SuccessPlanPartnerTypes;
        List<String> partnerTypeList = partnerType.split(';');
        accList = [Select Id,Partner_ID__c,RecordType.Name,Partner_Type__c, (select Id from Success_Plans__r limit 1) from Account where Id =: accId ];      
        for(Account accRecord:accList) {
            if((accRecord.Partner_ID__c != '' && accRecord.Partner_ID__c != null && 
            accRecord.RecordType.name =='Partner Account' && 
            (partnerTypeList.contains(accRecord.Partner_Type__c)))) {
                if((accRecord.Success_Plans__r.size()==0)) {
                canGenerate = TRUE;                
            } 
        }
    }       
        return canGenerate;
    }


    @AuraEnabled(cacheable=true)
    public static Boolean hasSuccessPlanProfiles() { 
        boolean isSPProfile = false;
        String viewProfiles = System.Label.SuccessPlanViewProfiles;
        List<String> viewProfileList = viewProfiles.split(';');
        String editProfiles = System.Label.SuccessPlanEditProfiles;
        List<String> editProfileList = editProfiles.split(';');      
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;       
        if(editProfileList.contains(profileName) || viewProfileList.contains(profileName)) {
            isSPProfile= true;
        }
        return isSPProfile;
    }

    @AuraEnabled
    public static boolean isEditable() {
        boolean canEdit = false;
        String viewProfiles = System.Label.SuccessPlanViewProfiles;
        List<String> viewProfileList = viewProfiles.split(';');
        String editProfiles = System.Label.SuccessPlanEditProfiles;
        List<String> editProfileList = editProfiles.split(';');      
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;       
        if(editProfileList.contains(profileName)) {
            canEdit= true;
        }else if(viewProfileList.contains(profileName)) {
            canEdit = false;
        }
        return canEdit;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canDisplayGenerateButton(String accId) {
        List<Account> accList = new List<Account>();
        Boolean displayButton = TRUE;        
        accList = [Select Id, (select Id from Success_Plans__r limit 1) from Account where Id =: accId ];       
        for(Account accRecord:accList) {         
            if((accRecord.Success_Plans__r.size()>0)){
                displayButton = FALSE;            
             }           
        }                   
        return displayButton;
    }

    @AuraEnabled(cacheable=true)
    public static List<SuccessPlanActivity__c>  getSuccessPlanActivityRecords(String accId, String activityDays) {
        List<SuccessPlanActivity__c> SPAList = new List<SuccessPlanActivity__c>();
        List<Success_Plan__c> successPlanRecords = [select Id,Account__c, (select Id, SuccessPlan__c, Comments__c,ActivityName__c, What_do_you_need_to_do__c, Stage__c, Status__c, Time_Stamp__c, lastmodifieddate,PartnerReadinessScore__c from Success_Plan_Activities__r where Stage__c =:activityDays) from Success_Plan__c where Account__c =: accId];
        for(Success_Plan__c spRecord : successPlanRecords) {           
            if(spRecord.Success_Plan_Activities__r.size()>0) {
                    SPAList.addAll(spRecord.Success_Plan_Activities__r);
            }
        }        
        return SPAList;
    }

    @AuraEnabled
    public static String saveDraftValues(Object data) {
        List<SuccessPlanActivity__c> SPAWithTime = new List<SuccessPlanActivity__c>();
        List<SuccessPlanActivity__c> listOfSPA = (List<SuccessPlanActivity__c>) JSON.deserialize(
            JSON.serialize(data),
            List<SuccessPlanActivity__c>.class
        );
        for(SuccessPlanActivity__c SPARecord: listOfSPA) {          
            SPARecord.Time_Stamp__c = DateTime.parse(DateTime.now().format());           
            SPAWithTime.add(SPARecord);
        }
        try {
            update SPAWithTime;
            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR'+e;
        }    
    }

    @AuraEnabled
    public static Boolean checkNegativeScenario(String accId) {       
        List<Account> accList = new List<Account>();
        Boolean isNegativeSce = FALSE;
        String partnerType = System.Label.SuccessPlanPartnerTypes;
        List<String> partnerTypeList = partnerType.split(';');
        accList = [Select Id,Partner_ID__c,RecordType.Name,Partner_Type__c, (select Id from Success_Plans__r limit 1) from Account where Id =: accId ];      
        for(Account accRecord:accList) {
            if((accRecord.Partner_ID__c == '' || accRecord.Partner_ID__c == null || 
            accRecord.RecordType.name !='Partner Account' || 
            (!partnerTypeList.contains(accRecord.Partner_Type__c))) && (accRecord.Success_Plans__r.size()>0)) {               
                isNegativeSce = TRUE;                            
            }
        }       
        return isNegativeSce;
    }
}