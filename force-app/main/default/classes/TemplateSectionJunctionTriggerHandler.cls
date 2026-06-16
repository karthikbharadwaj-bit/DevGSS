public with sharing class TemplateSectionJunctionTriggerHandler {
    public class PopulateExternalId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> templateIdSet = new Set<Id>();
            Set<Id> sectionsIdSet = new Set<Id>();
            for (TemplateSectionJunction__c item : (List<TemplateSectionJunction__c>) triggerRecords) {
                templateIdSet.add(item.RC_Quote_Template__c);
                sectionsIdSet.add(item.Template_Section__c);
            }

            Map<Id,RC_Quote_Template__c> templateMap = new Map<Id,RC_Quote_Template__c>([SELECT Id, External_ID__c FROM RC_Quote_Template__c WHERE ID IN :templateIdSet]);
            Map<Id,TemplateSections__c> sectionsMap = new Map<Id,TemplateSections__c>([SELECT Id, External_ID__c FROM TemplateSections__c WHERE ID IN :sectionsIdSet]);

            for (TemplateSectionJunction__c item : (List<TemplateSectionJunction__c>) triggerRecords) {
                if (!String.isBlank(item.External_ID__c)) {
                    continue;
                }
                String templateExtId = templateMap.get(item.RC_Quote_Template__c).External_ID__c;
                String sectionExtId = sectionsMap.get(item.Template_Section__c).External_ID__c;
                if(templateExtId != null && sectionExtId != null) {
                    item.External_ID__c = templateExtId + ' ' + sectionExtId;
                }
            }
        }
    }
}