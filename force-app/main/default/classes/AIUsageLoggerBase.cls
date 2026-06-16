public abstract class AIUsageLoggerBase {

    public abstract void logAccess();
    public abstract void logPrompt(String promptText);
    public abstract void logReport(String objectName);
    public abstract void logLike(String objectName);
    public abstract void logDislike(String objectName);
    public abstract void logSummary();
    public abstract void logSummaryLike(String objectName);
    public abstract void logSummaryDislike(String objectName);
    public abstract void logAccessAndPrompt(String promptText);
    // New: AI Insights Hub subfeature events (all routed to the queueable)
    public abstract void logAIHView(String subfeature);
    public abstract void logAIHLike(String subfeature);
    public abstract void logAIHDislike(String subfeature);
    public abstract void logAIHFeedback(String subfeature, String feedback);
}