/**
 * Created by Artem Ignatov on 26.07.2016.
 */

trigger BacklogItem on Backlog_item__c (after insert, after update, after delete, after undelete) {
    new Triggers()
            .bind(Triggers.Evt.afterinsert, new BacklogItemTriggerHelper.updateTotalSprintPoints())
            .bind(Triggers.Evt.afterupdate, new BacklogItemTriggerHelper.updateTotalSprintPoints())
            .bind(Triggers.Evt.afterdelete, new BacklogItemTriggerHelper.updateTotalSprintPoints())
            .bind(Triggers.Evt.afterundelete, new BacklogItemTriggerHelper.updateTotalSprintPoints())
            
            .bind(Triggers.Evt.afterupdate, new BacklogItemTriggerHelper.handlePostDeploymentTasks())
            .manage();

}