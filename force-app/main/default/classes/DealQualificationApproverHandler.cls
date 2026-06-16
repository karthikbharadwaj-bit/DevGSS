public with sharing class DealQualificationApproverHandler {
    public class SetClosedDateTime extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (DQ_Deal_Qualification_Approver__c dqa : (List<DQ_Deal_Qualification_Approver__c>) Trigger.new) {
                if (dqa.Status__c == DQDataHelper.STATUS_APPROVED 
                    || dqa.Status__c == DQDataHelper.STATUS_REJECTED) {
                    dqa.ClosedDateTime__c = DateTime.now();
                }
            }
        }
    }

    public class CountApprovalsOnDQ extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<DQ_Deal_Qualification_Approver__c> records;
            if (Trigger.isInsert) {
                records = (List<DQ_Deal_Qualification_Approver__c>) Trigger.new;
            } else if (Trigger.isDelete) {
                records = (List<DQ_Deal_Qualification_Approver__c>) Trigger.old;
            }

            List<DQ_Deal_Qualification__c> dqToUpdate = new List<DQ_Deal_Qualification__c>();
            Set<Id> dqIds = new Set<Id>();

            for (DQ_Deal_Qualification_Approver__c dqa : records) {
                dqIds.add(dqa.Deal_Qualification__c);
            }

            List<DQ_Deal_Qualification__c> dqs = (List<DQ_Deal_Qualification__c>) new DealQualificationSelector()
                .selectDQs()
                .selectFields(
                    new Set<SObjectField>{
                        DQ_Deal_Qualification__c.NumberOfApprovers__c
                    }
                )
                .subselect(
                    new DealQualificationApproverSelector()
                    .selectDQApprovers()
                )
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object>{ dqIds })
                .executeQuery();

            for (DQ_Deal_Qualification__c dq : dqs) {
                if (dq.NumberOfApprovers__c != dq.Deal_Qualification_Approvers__r.size()) {
                    dq.NumberOfApprovers__c = dq.Deal_Qualification_Approvers__r.size();
                    dqToUpdate.add(dq);
                }
            }

            Triggers.switchOff();
            update dqToUpdate;
            Triggers.switchOn();
        }
    }
}