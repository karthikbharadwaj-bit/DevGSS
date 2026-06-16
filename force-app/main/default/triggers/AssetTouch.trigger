trigger AssetTouch on Asset_Touch__c (after insert) {
	new Triggers()
		.bind(Triggers.Evt.afterinsert, new AssetTouchHandler())
		.manage();
}