/**********************************************************************************************************
Created By:     eugenebasianomutya
Created Date:   10182016
Description:    Trigger Handler of Resource Object
**********************************************************************************************************/

public with sharing class ResourceTriggerHandler{

    public class ResourceBefore extends Triggers.TriggerHandlerBase {
        override public void handle(){
        }
    }

    public class ResourceAfter extends Triggers.TriggerHandlerBase {
        override public void handle(){

            if (trigger.isInsert || trigger.isUpdate || trigger.isUndelete || trigger.isDelete){
                
                list<Resources__c> lResource = new list<Resources__c>();

                if(trigger.isDelete){
                    lResource = (List<Resources__c>)trigger.old;
                }else{
                    lResource = (List<Resources__c>)trigger.new;
                }
                
                set<Id> sProjectIds= new set<Id>();
                for(Resources__c r: lResource){
                    if(r.Project__c != NULL){                     
                        sProjectIds.add(r.Project__c);
                    }
                }

                if(sProjectIds.size()>0){
                    ResourceTriggerHandlerExt rth = new ResourceTriggerHandlerExt();
                    rth.UpdateProjectLoE(sProjectIds);
                }
            
            }
        }
    }



    public class CalculateTotalEstimateOnProject extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //skip calculating if we've already calculated all the resources. Needed to avoid executing queries multiple times.
            if (TriggerHandler.BY_PASS_TOTAL_ESTIMATE_CALCULATION) {
                return;
            }

            Boolean isInsertOrUndeleteContext = (Trigger.isInsert || Trigger.isUndelete);
            Map<Id, Resources__c> resMap = (isInsertOrUndeleteContext) ? (Map<Id, Resources__c>)Trigger.newMap : (Map<Id, Resources__c>)Trigger.oldMap;
            List<Project__c> projectsToUpdate = getProjectsToUpdate(resMap);
            update projectsToUpdate;

            //don't calculate project total costs several times in one project
            TriggerHandler.BY_PASS_TOTAL_ESTIMATE_CALCULATION = true;
        }

        private List<Project__c> getProjectsToUpdate(Map<Id, Resources__c> resources) {
            Set<Id> projectIds = getProjectIds(resources);
            List<Project__c> projects = new List<Project__c>();
            for (AggregateResult aggRes : [SELECT Project__c projId, SUM(Total_Cost_Estimate__c) totalCosts FROM Resources__c WHERE Project__c IN: projectIds GROUP BY Project__c]) {
                Id projId = (Id)aggRes.get('projId');
                Decimal totalCosts = (Decimal)aggRes.get('totalCosts');
                projects.add(new Project__c(Id = projId, Total_Project_Cost__c = totalCosts));
            }
            return projects;
        }

        private Set<Id> getProjectIds(Map<Id, Resources__c> resourcesMap) {
            Set<Id> projectIds = new Set<Id>();
            for (Resources__c res : resourcesMap.values()) {
                if (res.Project__c == null) {
                    continue;
                }
                projectIds.add(res.Project__c);
            }
            return projectIds;
        }
    }
}