//Ankit Sharma 	12/14/2020	update Deal Support when any dealsupport comment record is inserted or update....
trigger DealSupportCommentTrigger on Deal_Support_Comments__c (after insert, after update, before insert) {
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
		DealSupCommentTriggerHelper.updateDealSupport(trigger.new, trigger.isInsert);
    }
    if(trigger.isBefore && trigger.isInsert){
        DealSupCommentTriggerHelper.updateComment(trigger.new);
    }
}