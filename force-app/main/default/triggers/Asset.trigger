trigger Asset on Asset (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete) {

	new Triggers()
			.bind(Triggers.Evt.beforeupdate, new AssetTriggerHelper.UpdateAssetStatus())
			.manage();
}