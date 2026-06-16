public class PlatformLog {

    public static void logResults(PlatformLog__c[] logs) {
        try {

            if((Limits.getDMLRows() < Limits.getLimitDMLRows()) &&
               (Limits.getDMLStatements() < Limits.getLimitDMLStatements())) {

                Database.insert(logs);
            } else {
                System.debug('The Governor Limits have already been exhausted and hence failed to create a log.');
            }

        } catch(DMLException e) {
            System.debug('Exception occured during the platform log creation: ' + e.getMessage());
        }
    }

    /*
     * Write the error to the Platform Log.
    */
    public static void logResult(String source, String errorText, String stackTrace,
        String inboundMessage, String outboundMessage, Boolean saveAsync) {

        /*
         * Ensure that we're well within the Governor Limits.
         * The creation of the Log shouldn't disturb the execution of that Apex Class that utilizes this method to
         * create a log.
        */
        try {

            if((Limits.getDMLRows() < Limits.getLimitDMLRows()) &&
                (Limits.getDMLStatements() < Limits.getLimitDMLStatements())) {

                PlatformLog__c log = buildLog(source, errorText, stackTrace, inboundMessage, outboundMessage);

                if (saveAsync) {
                    logExceptionAsync(JSON.serialize(log));
                } else {
                    Database.insert(log);
                }

            } else {
                System.debug('The Governor Limits have already been exhausted and hence failed to create a log.');
            }

        } catch(DMLException e) {
            System.debug('Exception occured during the platform log creation: ' + e.getMessage());
        }
    }

    /*
     * Complience for the limits.
    */
    public static PlatformLog__c buildLog(String source, String errorText, String stackTrace,
        String inboundMessage, String outboundMessage) {
        return new PlatformLog__c(
            Source__c = PlatformEventsUtil.trim(source, 255),
            Error__c = PlatformEventsUtil.trim(errorText, 255),
            StackTrace__c = PlatformEventsUtil.trim(stackTrace, 32768),
            InboundMessage__c = PlatformEventsUtil.trim(inboundMessage, 32768),
            OutboundMessage__c = PlatformEventsUtil.trim(outboundMessage, 32768)
        );
    }

    /*
     * Convenience, convert exception to log.
    */
    public static void logException(String source, System.Exception e) {
        logResult(source, e.getMessage(), e.getStackTraceString(), null, null, false);
    }

    /*
     * Convenience, convert exception to log.
    */
    public static void logException(String source, System.Exception e, Boolean saveAsync) {
        logResult(source, e.getMessage(), e.getStackTraceString(), null, null, saveAsync);
    }

    /*
     * Convenience, convert exception to log.
    */
    public static void logException(String source, System.Exception e, String inboundMessage, String outboundMessage, Boolean saveAsync) {
        logResult(source, e.getMessage(), e.getStackTraceString(), inboundMessage, outboundMessage, saveAsync);
    }

    public static void logErrors(String source, Database.SaveResult[] saveResults, SObject[] records) {
        PlatformLog__c[] errorLogs = new List<PlatformLog__c>();
        for (Integer i = 0; i < saveResults.size(); ++i) {
            for (Database.Error error : saveResults[i].getErrors()) {
                errorLogs.add(PlatformLog.buildLog(source, records[i].Id + ': ' + error.getMessage(), null, null, null));
            }
        }
        if (!errorLogs.isEmpty()) {
            logResults(errorLogs);
        }
    }

    /*
     * Doesn't care about async operation exceptions as they will be fired in the separate context.
    */
    @future
    public static void logExceptionAsync(String serializedMessage) {
        PlatformLog__c log = (PlatformLog__c)JSON.deserialize(serializedMessage, PlatformLog__c.class);
        Database.insert(log);
    }

    @future
    public static void logExceptionsAsync(String serializedMessage) {
        List<PlatformLog__c> logs = (List<PlatformLog__c>) JSON.deserialize(serializedMessage, List<PlatformLog__c>.class);
        Database.insert(logs);
    }

    /*
     * Retrieve a log by ID.
    */
    public static PlatformLog__c retrieve(Id logId) {
        return [SELECT Id,
                       Name,
                       CreatedDate,
                       Source__c,
                       Error__c,
                       StackTrace__c,
                       InboundMessage__c,
                       OutboundMessage__c
                FROM PlatformLog__c
                WHERE Id = :logId];
    }

    /*
     * Return most recent log entry.
    */
    public static PlatformLog__c getMostRecent() {
        List<PlatformLog__c> logs = [SELECT Id,
                                            Name,
                                            CreatedDate,
                                            Source__c,
                                            Error__c,
                                            StackTrace__c,
                                            InboundMessage__c,
                                            OutboundMessage__c
                                       FROM PlatformLog__c
                                       ORDER BY CreatedDate DESC
                                       LIMIT 1];
        if (logs.isEmpty()) {
            return null;
        } else {
            return logs[0];
        }
    }

    /*
     * Class for the custom Log Exception. Use it when you want to through custom error.
    */
    public class PlatformLogException extends Exception {}
}