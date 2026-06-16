public with sharing class CaseRouting {

    public class CaseRoutingException extends Exception {}

    public class Context {
        Map<String, Set<Id>> accIdsBySupportType;
        Map<String, Group> groupsByName;
    }

    public class Rule implements Comparable {
        public Integer executionOrder;
        public String supportType;
        public String queueNameToAssign;
        public String recordTypeNameToAssign;
        public Boolean overrideCaseCategory;

        public Rule(CaseRoutingBySupportType__mdt routingSetting) {
            this.executionOrder = Integer.valueOf(routingSetting.ExecutionOrder__c);
            this.supportType = routingSetting.SupportType__c;
            this.queueNameToAssign = routingSetting.Owner__c.toLowerCase();
            this.recordTypeNameToAssign = routingSetting.CaseRecordType__c;
            this.overrideCaseCategory = routingSetting.IsCaseCategoryOverride__c;
        }

        public Integer compareTo(Object compareTo) {
            Rule otherRule = (Rule) compareTo;
            return this.executionOrder - otherRule.executionOrder;
        }

        public Boolean isApplicableTo(Case caseObj, Context context) {
            return context.accIdsBySupportType.containsKey(this.supportType)
                && context.accIdsBySupportType.get(this.supportType).contains(caseObj.AccountId);
        }

        public void applyTo(Case caseObj, Context context) {
            if (!context.groupsByName.containsKey(this.queueNameToAssign)) {
                throw new CaseRoutingException('Queue not found: ' + this.queueNameToAssign);
            }
            caseObj.OwnerId = context.groupsByName.get(this.queueNameToAssign).Id;
            if (this.recordTypeNameToAssign != null && CaseHelper.RT_INFO_BY_NAME.containsKey(this.recordTypeNameToAssign)) {
                caseObj.RecordTypeId = CaseHelper.RT_INFO_BY_NAME.get(this.recordTypeNameToAssign).getRecordTypeId();
            }
            if (this.overrideCaseCategory == true) {
                caseObj.Case_Category__c = this.supportType;
            }
        }
    }

    @testVisible
    private static List<CaseRoutingBySupportType__mdt> routingBySupportTypeSettings {
        get {
            if (routingBySupportTypeSettings == null) {
                routingBySupportTypeSettings = CaseRoutingBySupportType__mdt.getAll().values();
            }
            return routingBySupportTypeSettings;
        }
        set;
    }

    private static List<Rule> routingRules {
        get {
            if (routingRules == null) {
                routingRules = new List<Rule>();
                for (CaseRoutingBySupportType__mdt routingSetting : routingBySupportTypeSettings) {
                    routingRules.add(new Rule(routingSetting));
                }
                routingRules.sort();
            }
            return routingRules;
        }
        private set;
    }

    public static void execute(List<Case> cases, Map<String, Group> groupsByName) {
        execute(cases, groupsByName, null);
    }

    public static void execute(List<Case> cases, Map<String, Group> groupsByName, Map<String, Set<Id>> accIdsBySupportType) {
        Context context = new Context();
        context.groupsByName = groupsByName;
        // Use provided data if available, otherwise fetch it
        context.accIdsBySupportType = accIdsBySupportType != null 
            ? accIdsBySupportType 
            : AccountHelper.getSupportedAccountIdsGroupedBySupportType(
                AquivaHelper.getFieldList(cases, 'AccountId')
            );
        for (Case caseObj : cases) {
            for (Rule rule : routingRules) {
                if (rule?.isApplicableTo(caseObj, context)) {
                    rule.applyTo(caseObj, context);
                    break;
                }
            }
        }
    }
}