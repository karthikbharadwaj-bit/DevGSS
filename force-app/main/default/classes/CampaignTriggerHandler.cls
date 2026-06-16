public with sharing class CampaignTriggerHandler {

    public class DFR_IntendedBrandPopulation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<DFR_Update_Field__e> eventList = new List<DFR_Update_Field__e>();

            for (Campaign cmp : (List<Campaign>) Trigger.new) {
                if (isChangedField(cmp, Campaign.Intended_Country__c)) {
                    eventList.add(new DFR_Update_Field__e(
                        Id__c = cmp.Id,
                        Fields__c = DemandFunnelPlatEvents.INTENDED_BRAND_FIELD
                    ));
                }
            }

            if (eventList.size() > 0) {
                PlatformEvents.publishPlatformEvent(eventList, 'CampaignTriggerHandler');
            }
        }
    }
}