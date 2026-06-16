trigger NotificationToast on Notification_Toast__e (after insert) {
    ContactTriggerHelper.createCustomNotification(Trigger.new[0].Title__c,Trigger.new[0].Message__c,Trigger.new[0].UserId__c,Trigger.new[0].Recordid__c);
}