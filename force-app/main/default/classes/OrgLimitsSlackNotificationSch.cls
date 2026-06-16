public class OrgLimitsSlackNotificationSch implements Schedulable {
    public void execute(SchedulableContext ctx) {
        OrgLimitsSlackNotification.checkLimitsAndSendWebhook(90, new OrgLimitsSlackNotification.OrgLims());
    }
}