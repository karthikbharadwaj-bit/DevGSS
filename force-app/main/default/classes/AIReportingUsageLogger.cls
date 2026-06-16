public with sharing class AIReportingUsageLogger extends AIUsageLoggerBase {

    public override void logAccess() {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'access'}, null));
    }

    public override void logPrompt(String promptText) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'prompt'}, promptText));
    }

    public override void logReport(String objectName) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'report'}, objectName));
    }

    public override void logLike(String objectName) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'report_like'}, objectName));
    }

    public override void logDislike(String objectName) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'report_dislike'}, objectName));
    }

    public override void logSummary() {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'summary'}, null));
    }

    public override void logSummaryLike(String objectName) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'summary_like'}, objectName));
    }

    public override void logSummaryDislike(String objectName) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'summary_dislike'}, objectName));
    }

    public override void logAccessAndPrompt(String promptText) {
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{'access', 'prompt'}, promptText));
    }
    
    // 🔹 New: AI Insights Hub subfeature events (payload is JSON: {"subfeature":"...", "feedback":"..."?})
    public override void logAIHView(String subfeature) {
        System.enqueueJob(new AIUsageLogQueueable(
            new List<String>{ 'aih_view' },
            JSON.serialize(new Map<String, Object>{ 'subfeature' => subfeature })
        ));
    }
    
    public override void logAIHLike(String subfeature) {
        System.enqueueJob(new AIUsageLogQueueable(
            new List<String>{ 'aih_like' },
            JSON.serialize(new Map<String, Object>{ 'subfeature' => subfeature })
        ));
    }
    
    public override void logAIHDislike(String subfeature) {
        System.enqueueJob(new AIUsageLogQueueable(
            new List<String>{ 'aih_dislike' },
            JSON.serialize(new Map<String, Object>{ 'subfeature' => subfeature })
        ));
    }
    
    public override void logAIHFeedback(String subfeature, String feedback) {
        System.enqueueJob(new AIUsageLogQueueable(
            new List<String>{ 'aih_feedback' },
            JSON.serialize(new Map<String, Object>{ 'subfeature' => subfeature, 'feedback' => feedback })
        ));
    }
}