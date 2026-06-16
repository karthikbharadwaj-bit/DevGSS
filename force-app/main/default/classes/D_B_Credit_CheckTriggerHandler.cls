public with sharing class D_B_Credit_CheckTriggerHandler {

    public static final String DNBI_APPROVED = 'Approved';
    public static final String DNBI_DECLINED = 'Declined';
    public static final String DNBI_PENDING = 'Pending';
    public static final String DNBI_FURTHER_REVIEW = 'Further Review Required';


    public class ApproveIfDNBIUserIsApprover extends Triggers.TriggerHandlerBase {
        override public void handle() {

            User dnbiUser = D_B_Credit_CheckObj.getDnbiUser();
            
            Map<Id,Id> mapAppId = new Map<Id,Id>();

            for (D_B_Credit_Check__c creditCheck : (List<D_B_Credit_Check__c>) Trigger.new) {
                 mapAppId.put(creditCheck.Id, creditCheck.Approval__c);
            }

            if (mapAppId.size() > 0) {
                List<ProcessInstanceWorkitem> currentApprovers = [SELECT Id, ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId
                                                                  FROM ProcessInstanceWorkitem
                                                                  WHERE ProcessInstance.TargetObjectId IN :mapAppId.values()
                                                                  AND ProcessInstance.Status = :DNBI_PENDING
                                                                  AND ActorId = :dnbiUser.Id
                                                                  ORDER BY CreatedDate DESC];

                for (D_B_Credit_Check__c creditCheck : (List<D_B_Credit_Check__c>) Trigger.new) {
                    if (currentApprovers.size() > 0 &&
                        currentApprovers[0].ActorId == dnbiUser.Id &&
                        creditCheck.D_B_Status__c != null) {
                        if (creditCheck.D_B_Status__c == DNBI_APPROVED) {
                            D_B_Credit_CheckObj processApproval = new D_B_Credit_CheckObj();
                            processApproval.approveDNBStep(creditCheck, currentApprovers);
                        } else if (creditCheck.D_B_Status__c == DNBI_DECLINED) {
                            D_B_Credit_CheckObj processApproval2 = new D_B_Credit_CheckObj();
                            processApproval2.rejectDNBStep(creditCheck, currentApprovers);
                        }
                    }
                }
            }
        }
    }
    public class SendEmailIfDNBStatusIsPending extends Triggers.TriggerHandlerBase {
        override public void handle() {
            D_B_Credit_CheckObj sendEmail = new D_B_Credit_CheckObj();
            sendEmail.dnbStatusPendingEmail((List<D_B_Credit_Check__c>) Trigger.new);
        }
    }
}