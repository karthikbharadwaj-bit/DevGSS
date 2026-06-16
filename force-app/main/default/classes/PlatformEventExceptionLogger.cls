public class PlatformEventExceptionLogger extends PlatformEventProcessor implements PlatformEvents.PlatformEventException {
    /*
     * Convert platform events to logs.
    */
    public override void handle(List<SObject> events) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for(Exception__e event : (List<Exception__e>)events) {
            logs.add(PlatformLog.buildLog(event.Source__c, event.Error__c, event.StackTrace__c, 
                                          event.InboundMessage__c, event.OutboundMessage__c));
        }

        /*
         * Ensure that we're well within the Governor Limits.
         * The creation of the Log shouldn't disturb the execution of that Apex Class that utilizes this method to
         * create a log.
        */
        try {
            if((Limits.getDMLRows() < Limits.getLimitDMLRows()) && 
               (Limits.getDMLStatements() < Limits.getLimitDMLStatements())) {
                Database.insert(logs);
            } else {
                System.debug('The Governor Limits have already been exhausted and hence failed to create a log');
            }
        } catch(DMLException e) {
            System.debug('Exception occured during the platform log creation: ' + e.getMessage());
        }  
    }
}