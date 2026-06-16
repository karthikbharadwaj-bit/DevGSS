/**
 * Created by Artem Ignatov on 26.07.2016.
 */

public with sharing class BacklogItemTriggerHelper {
    public class updateTotalSprintPoints extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<ID> sprintsIDToUpdate = new Set<ID>();
            for (Backlog_item__c bli: Trigger.isDelete ? (List<Backlog_item__c>) Trigger.old : (List<Backlog_item__c>) Trigger.new) {
                    sprintsIDToUpdate.add(bli.Sprint__c);
            }
            if (Trigger.isUpdate) {
                for (Backlog_item__c bli: (List<Backlog_item__c>) Trigger.old) {
                    sprintsIDToUpdate.add(bli.Sprint__c);
                }
            }
            List<Backlog_item__c> allLinkedBacklogItems = [SELECT ID, Name, Sprint__r.Total_Story_Points__c, Story_Points__c
                FROM Backlog_item__c
                WHERE Backlog_item__c.Sprint__c IN :sprintsIDToUpdate AND Backlog_item__c.Story_Points__c!=null];
            Map<ID, Integer> totalPointsCounters = new Map<ID, Integer>();
            for (ID spintID : sprintsIDToUpdate) {
                totalPointsCounters.put(spintID, 0);
            }
            for (Backlog_item__c lBli : allLinkedBacklogItems) {
                totalPointsCounters.put(lbli.Sprint__c, totalPointsCounters.get(lbli.Sprint__c) + Integer.valueOf(lBli.Story_Points__c));
            }
            List<Sprints__c> sprintToUpdate = [SELECT ID, Total_Story_Points__c FROM Sprints__c WHERE id IN :sprintsIDToUpdate ];
            for (Sprints__c sprint : sprintToUpdate) {
                sprint.Total_Story_Points__c = totalPointsCounters.get(sprint.ID);
            }
            update sprintToUpdate;
        }
    }

    public class handlePostDeploymentTasks extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String prodSteps = 'Post deployment steps executed in Production';
            String uatSteps = 'Post deployment steps executed on UAT sandbox';
            String e2eSteps = 'Post deployment steps executed on E2E sandbox';

            Id taskRecordTypeId = Task.SObjectType.getDescribe().getRecordTypeInfosByName()
                .get('Backlog Item Task').getRecordTypeId();
            Map<Id, List<String>> bliToTaskSubject = new Map<Id, List<String>>();
            List<Task> tasksToInsert = new List<Task>();
            List<Task> tasksToDelete = new List<Task>();
            Map<Id, Backlog_item__c> blis = new Map<Id, Backlog_item__c>(
                [SELECT Id, Administrative_tasks__c, 
                    (SELECT Id, Subject 
                        FROM Tasks 
                        WHERE Subject =: prodSteps
                            OR Subject =: uatSteps
                            OR Subject =: e2eSteps)
                FROM Backlog_item__c 
                WHERE Id IN: Trigger.new]);

            if(RingCentralVariousSettings__c.getInstance().Release_Engineer_User_Id__c != null) {
                for(Backlog_item__c bli : blis.values()) {
                    for(Task t : bli.Tasks) {
                        if(bliToTaskSubject.get(bli.Id) == null) {
                            bliToTaskSubject.put(bli.Id, new List<String>{t.Subject});
                        } else {
                            List<String> subjects = bliToTaskSubject.get(bli.Id);
                            subjects.add(t.Subject);
                            bliToTaskSubject.put(bli.Id, subjects);
                        }
                    }
                }

                for(Backlog_item__c bli : (List<Backlog_item__c>) Trigger.new) {
                    if(bli.Administrative_tasks__c != null 
                        && ((Map<Id, Backlog_item__c>) Trigger.oldMap).get(bli.Id).Administrative_tasks__c == null) {
                        if(bliToTaskSubject.get(bli.Id) == null) {
                            tasksToInsert.add(createTask(bli.Id, prodSteps));
                            tasksToInsert.add(createTask(bli.Id, uatSteps));
                            tasksToInsert.add(createTask(bli.Id, e2eSteps));
                        } else {
                            if(!bliToTaskSubject.get(bli.Id).contains(prodSteps)) {
                                tasksToInsert.add(createTask(bli.Id, prodSteps));
                            }

                            if(!bliToTaskSubject.get(bli.Id).contains(uatSteps)) {
                                tasksToInsert.add(createTask(bli.Id, uatSteps));
                            }

                            if(!bliToTaskSubject.get(bli.Id).contains(e2eSteps)) {
                                tasksToInsert.add(createTask(bli.Id, e2eSteps));
                            }
                        }
                    }

                    if(bli.Administrative_tasks__c == null 
                        && ((Map<Id, Backlog_item__c>) Trigger.oldMap).get(bli.Id).Administrative_tasks__c != null) {
                        tasksToDelete.addAll(blis.get(bli.Id).Tasks);
                    }
                }

                insert tasksToInsert;
                delete tasksToDelete;
            }
        }

        private Task createTask(Id bliId, String subject) {
            Id releaseEngineerId = RingCentralVariousSettings__c.getInstance().Release_Engineer_User_Id__c;

            return new Task(
                Subject = subject,
                Status = 'Not Started',
                OwnerId = releaseEngineerId,
                WhatId = bliId);
        }
    }
}