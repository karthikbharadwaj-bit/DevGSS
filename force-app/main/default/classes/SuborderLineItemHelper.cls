/**
 * This is helper class for SuborderLineItem__c custom object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public with sharing class SuborderLineItemHelper {

    public static SuborderLineItem__c buildSuborderLineItem(Suborder__c suborder, Hardware_Line_Item__c phaseLineItem) {
        SuborderLineItem__c suborderLineItem = new SuborderLineItem__c();
        suborderLineItem.Suborder__c = suborder.Id;
        suborderLineItem.SalesAgreementLineItem__c = phaseLineItem.Quote_Line_Item__c;
        suborderLineItem.Name = phaseLineItem.Name;
        suborderLineItem.Quantity__c = phaseLineItem.Quantity__c;
        suborderLineItem.CurrencyIsoCode = suborder.CurrencyIsoCode;
        return suborderLineItem;
    }

    public static void createSuborderLineItems(List<Suborder__c> suborders, Map<Id, Phase__c> phasesMap) {
        List<SuborderLineItem__c> suborderLineItems = new List<SuborderLineItem__c>();
        if (suborders.isEmpty()) {
            return;
        }

        for (Suborder__c suborder : suborders) {
            for (Hardware_Line_Item__c phaseLineItem : phasesMap.get(suborder.Phase__c).Hardware_Line_Items__r) {
                suborderLineItems.add(SuborderLineItemHelper.buildSuborderLineItem(suborder, phaseLineItem));
            }
        }

        if (!suborderLineItems.isEmpty()) {
            insert suborderLineItems;
        }
    }
}