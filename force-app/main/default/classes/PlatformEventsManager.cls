public class PlatformEventsManager {
    /*
     * Manage the platform events in generic way, assigning the processors using the implemented interface.
    */
    public static void processEvents(String interfaceName, List<SObject> events) {
        List<PlatformEventProcessor> processors = PlatformEventsUtil.getProcessors(interfaceName);
        for(PlatformEventProcessor processor : processors) {
            processor.process(events);
        }
    }
}