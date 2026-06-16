public with sharing class RCQuoteTemplateTriggerHandler {
    public class PopulateExternalId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (RC_Quote_Template__c item : (List<RC_Quote_Template__c>) triggerRecords) {
                if (!String.isBlank(item.External_ID__c)) {
                    continue;
                }
                Uuid uuid = new Uuid();
                item.External_ID__c = uuid.getValue();
            }
        }
    }
}