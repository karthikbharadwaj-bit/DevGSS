public with sharing class ICBNotificationQueueable implements Queueable {

    @TestVisible
    private Case icbCase;
    @TestVisible
    private Opportunity targetOpty;
    @TestVisible
    private String errorMessage;
    private Exception e;

    public ICBNotificationQueueable(Opportunity opp, Case cs, Exception e) {
        this(opp, cs, IcbHelper.SYNC_WITH_NGBS_ERROR, e);
    }

    public ICBNotificationQueueable(Opportunity opp, Case cs, String errorMessage, Exception e) {
        this.icbCase = cs;
        this.targetOpty = opp;
        this.errorMessage = errorMessage;
        this.e = e;
    }

    public void execute(QueueableContext context) {
        sendNotifications();
    }

    private void sendNotifications() {
        // Do not pass SObjects in the this.errorMessage
        String message = String.format(this.errorMessage, new List<Object> { this.e.getMessage() });
        String messageDetail = this.e.getStackTraceString();

        Opportunity oppToNotify = OpportunityHelper.getMasterOpportunity(this.targetOpty);

        ChatterHelper.createChatterPost(
            oppToNotify.OwnerId,
            oppToNotify.Id,
            message,
            messageDetail
        );
        EmailNotificationHelper.sendEmail(this.e, this.icbCase);
    }
}