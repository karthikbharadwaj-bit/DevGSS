public with sharing class AgentCreditTriggerHandler {

    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Agent_Credit__c.sObjectType);
        }
    }
}