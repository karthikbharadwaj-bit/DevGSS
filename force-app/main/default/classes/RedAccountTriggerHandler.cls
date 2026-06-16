public with sharing class RedAccountTriggerHandler {

    public static final String STATUS_RESOLVED_DOWN = 'Resolved – Downgraded';
    public static final String STATUS_RESOLVED_SAVE = 'Resolved - Saved';
    public static final String STATUS_RESOLVED_LOST = 'Resolved - Lost';


    public class RedAccountBefore extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isInsert) {
                OnInsert((Red_Account__c[])Trigger.new);
            }
            if (Trigger.isUpdate) {
                OnUpdate((Red_Account__c[])Trigger.old, (Red_Account__c[])Trigger.new);
            }
        }

        private void OnInsert(Red_Account__c[] newRAccounts) {
            setRedStartDateTimestamp(newRAccounts);
            setRedEndDateTimestamp(newRAccounts);
            //setIssueOwnerOnCreate(newRAccounts);
        }

        private void OnUpdate(Red_Account__c[] oldRAccount, Red_Account__c[] newRAccounts) {
            setRedEndDateTimestamp(newRAccounts);
        }

        private void setRedStartDateTimestamp(Red_Account__c[] newRAccounts) {
            Date thisMoment = Date.today();
            for (Red_Account__c entry : newRAccounts) {
                entry.Red_Start_Date__c = thisMoment;
            }
        }

     /*   private void setIssueOwnerOnCreate(Red_Account__c[] newRAccounts) {
            Set<Id> accIds = new Set<Id>();
            for (Red_Account__c entry : newRAccounts) {
                accIds.add(entry.EscalatedAccount__c);
            }

            Map<Id,Account> accCsmMap = new Map<Id,Account>([
                SELECT CSM__c
                FROM Account
                WHERE Id IN :accIds
            ]);

            for(Red_Account__c entry : newRAccounts) {
                entry.Issue_Owner__c = accCsmMap.get(entry.EscalatedAccount__c).CSM__c;
            }
     } */

        private void setRedEndDateTimestamp(Red_Account__c[] newRAccounts) {
            Set<String> statusesToUpdateEndDate = new Set<String> { STATUS_RESOLVED_DOWN,  STATUS_RESOLVED_SAVE, STATUS_RESOLVED_LOST };
            Date thisMoment = Date.today();
            for(Red_Account__c entry : newRAccounts) {
                if (CoreObjectBase.isFieldChangedToSet(entry, Red_Account__c.Status__c, statusesToUpdateEndDate)) {
                    entry.Red_End_Date__c = thisMoment;
                }
            }
        }
    }
}