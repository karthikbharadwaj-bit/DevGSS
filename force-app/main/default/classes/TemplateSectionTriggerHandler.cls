public with sharing class TemplateSectionTriggerHandler {
    public class PopulateExternalId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (TemplateSections__c item : (List<TemplateSections__c>) triggerRecords) {
                if (!String.isBlank(item.External_ID__c)) {
                    continue;
                }
                Uuid uuid = new Uuid();
                item.External_ID__c = uuid.getValue();
            }
        }
    }
}