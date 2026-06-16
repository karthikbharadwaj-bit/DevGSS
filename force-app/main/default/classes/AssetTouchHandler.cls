public with sharing class AssetTouchHandler extends Triggers.TriggerHandlerBase  {
    public static Boolean SKIP_TRIGGER = false;
    override public void handle() {
        if (AssetTouchHandler.SKIP_TRIGGER) {
            return;
        }
        List<SObject> toUpdate = new List<SObject>();
        if (Trigger.isInsert) {
            Map<Id, Asset_Touch__c> leadToMostRecentTouchAsset = new Map<Id, Asset_Touch__c>();
            Map<Id, Asset_Touch__c> contactToMostRecentTouchAsset = new Map<Id, Asset_Touch__c>();

            for (Asset_Touch__c at : (List<Asset_Touch__c>) Trigger.new) {
                if (at.Trigger_Recalculation__c) {
                    if (at.Lead__c != null && (!leadToMostRecentTouchAsset.containsKey(at.Lead__c) 
					|| leadToMostRecentTouchAsset.get(at.Lead__c).Asset_Touch_DateTime__c < at.Asset_Touch_DateTime__c)) {
                        leadToMostRecentTouchAsset.put(at.Lead__c, at);
                    }

                    if (at.Contact__c != null && (!contactToMostRecentTouchAsset.containsKey(at.Contact__c) 
					|| contactToMostRecentTouchAsset.get(at.Contact__c).Asset_Touch_DateTime__c < at.Asset_Touch_DateTime__c)) {
                        contactToMostRecentTouchAsset.put(at.Contact__c, at);
                    }
                }
            }

            if (!leadToMostRecentTouchAsset.isEmpty()) {
                for (Lead l : (List<Lead>) new LeadSelector()
				               .selectLeadsWithAssetTouches(new List<Object>{leadToMostRecentTouchAsset.keySet()})
							   .executeQuery()) {
                    Asset_Touch__c mostRecentTouch = leadToMostRecentTouchAsset.get(l.Id);
                    if (mostRecentTouch.Marketing_Asset__c != l.Most_Recent_Asset__c && (l.Most_Recent_Asset__c == null || l.Asset_Touch__r.isEmpty() || (l.Asset_Touch__r[0].Asset_Touch_DateTime__c < mostRecentTouch.Asset_Touch_DateTime__c))) {
                        l.Most_Recent_Asset__c = mostRecentTouch.Marketing_Asset__c;
                        l.Asset_Id__c = mostRecentTouch.Marketing_Asset__r.Asset_Id__c;
                        toUpdate.add(l);
                    }
                }
            }

            if (!contactToMostRecentTouchAsset.isEmpty()) {
                for (Contact c : (List<Contact>) new ContactSelector() 
				                 .selectContactsWithAssetTouches(new List<Object>{contactToMostRecentTouchAsset.keySet()})
								 .executeQuery()) {
                    Asset_Touch__c mostRecentTouch = contactToMostRecentTouchAsset.get(c.Id);
                    if (mostRecentTouch.Marketing_Asset__c != c.Most_Recent_Asset__c && (c.Most_Recent_Asset__c == null || c.Asset_Touch__r.isEmpty() || (c.Asset_Touch__r[0].Asset_Touch_DateTime__c < mostRecentTouch.Asset_Touch_DateTime__c))) {
                        c.Most_Recent_Asset__c = mostRecentTouch.Marketing_Asset__c;
                        c.Asset_Id__c = mostRecentTouch.Marketing_Asset__r.Asset_Id__c;
                        toUpdate.add(c);
                    }
                }
            }

        }

        if (!toUpdate.isEmpty()) {
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
            TriggerHandler.BY_PASS_LEAD_UPDATE = true;
            Database.update(toUpdate, false);
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        }
    }
}