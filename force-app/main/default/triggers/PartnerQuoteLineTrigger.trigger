//Ankit Sharma 	12/14/2020	update total reccurring or one time payment on PartnerQuote when any quoteline insert or update..
trigger PartnerQuoteLineTrigger on Partner_Quote_Line__c (after insert, after update) {
	PartnerQuoteLineTriggerHelper.calculateQuoteTotalPrice(trigger.new);
}