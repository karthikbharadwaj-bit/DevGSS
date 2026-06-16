public with sharing class NoteTriggerHelper {

    /*************************************************
    After Insert & Update: Set Responded and Last Touched fields as needed.
    /************************************************/
    public class NoteAfterInsertUpdate extends Triggers.TriggerHandlerBase {
        private DateTime currentDateTime = DateTime.now();

        override public void handle() {
            Set<Id> opportunityIdSet = new Set<Id>();
            Set<Id> leadIdSet = new Set<Id>();
            List<Note> accountNotesToUpdate = new List<Note>();
            
            for(Note noteObj : (List<Note>)Trigger.new) {
                Id parentId = noteObj.ParentId;
                if (String.isNotBlank(parentId)) {
                    SObject parent = parentId.getSObjectType().newSObject();
                    switch on parent {
                        when Opportunity o {
                            opportunityIdSet.add(parentId);
                        }
                        when Lead l {
                            leadIdSet.add(parentId);
                        }
                        when Account a {
                            accountNotesToUpdate.add(noteObj);
                        }
                        when else {
                            continue;
                        }
                    }
                }
            }

            if (!ProfileHelper.isCurrentUserSysAdmin()) {
                if (!opportunityIdSet.isEmpty()) {
                    updateParentOpps(opportunityIdSet);
                }
                if (!leadIdSet.isEmpty()) {
                    updateParentLeads(leadIdSet);
                }
            }
        }

        private void updateParentOpps(Set<Id> opportunityIdSet) {
            Triggers.switchOff();
                updateSObjectRespondedAndLastTouchedFields('Opportunity', opportunityIdSet);
            Triggers.switchOn();
        }

        private void updateParentLeads(Set<Id> leadIdSet) {
            updateSObjectRespondedAndLastTouchedFields('Lead', leadIdSet);
        }


        private void updateSObjectRespondedAndLastTouchedFields(String sObjectType, Set<Id> sObjectIds) {
            String queryStr = ' SELECT Responded_Date__c, Responded_By__c, Last_Touched_Date__c, Last_Touched_By__c ' +
                                'FROM ' + String.escapeSingleQuotes(sObjectType) + ' ' +
                                'WHERE Id IN :sObjectIds';
            SObject[] objectsToUpdate = Database.query(queryStr);

            for (SObject obj : objectsToUpdate) {
                if (obj.get('Responded_Date__c') == null && obj.get('Responded_By__c') == null) {
                    obj.put('Responded_Date__c', currentDateTime);
                    obj.put('Responded_By__c', UserInfo.getUserId());
                }
                obj.put('Last_Touched_Date__c', currentDateTime);
                obj.put('Last_Touched_By__c', UserInfo.getUserId());
            }

            try {
                update objectsToUpdate;
            } catch (Exception ex) {
                System.debug('Failed with update ' + sObjectType + ' on Note Insert or Update ' + ex);
                PlatformLog.logException('Trigger Note ' + sObjectType + ' Update', ex);
            }
        }
    }

    /*************************************************
    After Delete: Prevents non-admin user from deleting Notes.
    /************************************************/
    public class NoteBeforeDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            // If current user is not a System Administrator, do not allow Notes to be deleted
            if (!ProfileHelper.isCurrentUserSysAdmin()) {
                for (Note n : (List<Note>)Trigger.old) {
                    n.addError('Unable to delete notes.');
                }
            }
        }
    }
}