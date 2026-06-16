public without sharing class PartnerOperationsHelper {
	public class PartnerScenario {
        @AuraEnabled public List<PartnerScenarioStep> steps;
        @AuraEnabled public Boolean isCompleted;

        public PartnerScenario(List<PartnerScenarioStep> steps) {
            this.steps = steps;
            this.isCompleted = true;

            for (PartnerScenarioStep step : steps) {
                if (!step.isSync) {
                    isCompleted = false;
                }
            }
        }
    }

    public virtual class PartnerStep {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String action;
        @AuraEnabled public Decimal order;

        public PartnerStep(String name, String label, String description, String action, Decimal order) {
            this.name = name;
            this.label = label;
            this.description = description;
            this.action = action;
            this.order = order;
        }
    }

    public class PartnerScenarioStep extends PartnerStep {
        @AuraEnabled public Boolean isSync;

        public PartnerScenarioStep(String name, String label, String description, String action, Decimal order, Boolean isSync) {
            super(name, label, description, action, order);
            this.isSync = isSync;
        }
    }

	public class ValidateStepParams {
        @AuraEnabled
        public Id logId {get;set;}
        @AuraEnabled
        public String name {get;set;}
    }

	public class PartnerOperation {
        public Id id;
        public Id account;
        public Id opportunity;
        public Id approval;
        public Boolean status;
        public PartnerInfo partnerInfo;

    public PartnerOperation(PartnerOperationsLog__c partnerLog) {
            this.id = partnerLog.Id;
            this.account = partnerLog.Account__c;
            this.opportunity = partnerLog.Opportunity__c;
            this.approval = partnerLog.Approval__c;
            this.status = partnerLog.isCompleted__c;
            this.partnerInfo = (PartnerInfo) JSON.deserialize(partnerLog.PartnerInfo__c, PartnerInfo.class);
        }
    }

    public class PartnerInfo {
        public String id;
        public String ngbsPartnerId;
    }
}