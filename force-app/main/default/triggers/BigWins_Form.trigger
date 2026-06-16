trigger BigWins_Form on BigWins_Form__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete) {

		new Triggers()
			.bind(Triggers.Evt.afterupdate, new BigWinsFormTriggerHandler.BigWinsFormAfter())

	        .manage();
}