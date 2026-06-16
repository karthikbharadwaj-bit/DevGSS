public with sharing class OrderCustomTriggerHandler {

    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Order__c.sObjectType);
        }
    }
}