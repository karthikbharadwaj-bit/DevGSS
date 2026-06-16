/*
* Name         : AssetTriggerHelper.cls
* Created By   : Alexander Savickiy (asavickiy@aquivalabs.com)
* Created Date : 01/January/2018
* Description  : Class contains methods for Asset trigger
*/
public class AssetTriggerHelper {
	//Populate Active__c checkbox 
	public class UpdateAssetStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
        	//Cast trigger variables once
            List<Asset> newAssets = (List<Asset>) Trigger.new;
            for (Asset assetRecord : newAssets) {
            	if (assetRecord.Delivered_Quantity__c == assetRecord.Quantity) {
            		assetRecord.Active__c = false;
            	}
            }
        }
    }
}