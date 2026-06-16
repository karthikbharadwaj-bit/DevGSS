public class PlatformEvents {
    /*
     * Stored count of successfully published events to use it incrementing in unit tests
    */
    private static Integer publishedEventsCount = 0;
    /*
     * An interface that defines what action need to be performed on the platform event exception occurred
    */
    public interface PlatformEventException {}
    
    /*
     * An interface that defines what action need to be performed on the POC approval email platform event
    */
    public interface POCApprovalEmailInterface {}

    /*
     * Publish the exception event and fire all associated processors
    */
    public static void publishPlatformEventException(String source, System.Exception e, String inboundMessage, String outboundMessage) {
        Exception__e platformException = new Exception__e(
                                             Source__c = PlatformEventsUtil.trim(source, 255),
                                             Error__c = PlatformEventsUtil.trim(e.getMessage(), 255),
                                             StackTrace__c = PlatformEventsUtil.trim(e.getStackTraceString(), 32768),
                                             InboundMessage__c = PlatformEventsUtil.trim(inboundMessage, 32768),
                                             OutboundMessage__c = PlatformEventsUtil.trim(outboundMessage, 32768));
        publishPlatformEvent(platformException, source);
    }

    /*
     * Publish the the paltform event and fire all associated processors
    */
    public static void publishPlatformEvent(SObject event, String source) {

        if((Limits.getDMLRows() < Limits.getLimitDMLRows()) &&
            (Limits.getPublishImmediateDML() < Limits.getLimitPublishImmediateDML())) {
            Database.SaveResult sr = EventBus.publish(event);
            if (sr.isSuccess()) {
                publishedEventsCount++;
                System.debug(event.getSObjectType().getDescribe().getName() + ' event published from: ' + source);
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        } else {
            System.debug('The Governor Limits have already been exhausted and hence failed to publish the platform.');
        }
    }
    /*
     * Publish a list of platform events and fire all associated processors
    */
    public static void publishPlatformEvent(List<SObject> events, String source) {
        if((Limits.getDMLRows() + events.size() < Limits.getLimitDMLRows()) &&
            (Limits.getPublishImmediateDML() < Limits.getLimitPublishImmediateDML())) {
            List<Database.SaveResult> listSr = EventBus.publish(events);
            Integer publishedEventsCountBefore = publishedEventsCount;
            for (Database.SaveResult sr : listSr) {
                if (sr.isSuccess()) {
                    publishedEventsCount++;
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(events.getSObjectType().getDescribe().getName() +' Event published from: ' + source + 'Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
            System.debug(events.getSObjectType().getDescribe().getName() +' Event published from: ' + source + 'Successful Published: ' + (publishedEventsCount - publishedEventsCountBefore));
        } else {
            System.debug('The Governor Limits have already been exhausted and hence failed to publish the platform.');
        }
    }

    public static Integer getCountPublishedEvents() {
        return publishedEventsCount;
    }
}