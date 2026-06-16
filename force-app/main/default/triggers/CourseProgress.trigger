trigger CourseProgress on skilljar__Course_Progress__c (after insert, after update, before delete) {
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate) 
        || (trigger.isBefore && trigger.isDelete)
    ) {
        CourseProgressHelper.updateAccountCertifiedDeliveryPartnerStatusField(trigger.newMap, trigger.oldMap);
    }
}