public class AIUsageLogQueueable implements Queueable {

    private List<String> eventTypes;
    private String contextValue;

    public AIUsageLogQueueable(List<String> eventTypes, String contextValue) {
        this.eventTypes = eventTypes;
        this.contextValue = contextValue;
    }

    public void execute(QueueableContext context) {
        for (String type : eventTypes) {
            AIUsageLogHelper.logEvent(type, contextValue);
        }
    }
}