public class PlatformEventsUtil {
    /*
     * Constants.
    */ 
    public static final String PE_TEST_ERROR_NOT_EQUALS = 'The error message is not correct.';
    public static final String PE_TEST_SOURCE_NOT_EQUALS = 'The error is called from the another class.';
    public static final String PE_TEST_STACK_NOT_EQUALS = 'The detailed stack is not correct.';
    public static final String PE_TEST_INBOUND_NOT_EQUALS = 'The inbound message is not correct.';
    public static final String PE_TEST_OUTBOUND_NOT_EQUALS = 'The outbound message is not correct.';
    public static final String PE_TEST_DML_LIMITS_NOT_EQUALS = 'Logs amount is more then the DML limits.';

    /*
     * Get and create the workers from all the classes extending specified platform event interface.
    */
    public static List<PlatformEventProcessor> getProcessors(String interfaceName) {
        List<ApexClass> processors = (List<ApexClass>)[FIND :interfaceName 
                                                       IN ALL FIELDS
                                                       RETURNING ApexClass(Id, Name)][0];
        return getProcessorListFromCustomMetaDataTypes(processors);
    }

    /*
     * Cast apex classes list into processors.
    */
    private static List<PlatformEventProcessor> getProcessorListFromCustomMetaDataTypes(List<ApexClass> processors) {
        List<PlatformEventProcessor> processorList = new List<PlatformEventProcessor>();
        for(ApexClass processor : processors) {
            PlatformEventProcessor handler = createProcessor(processor.Name);
            if(handler == null) {
                continue;
            }
            processorList.add(handler);
        }
        return processorList;
    }

    /*
     * Cast apex name into platform event processor.
    */
    private static PlatformEventProcessor createProcessor(String processorName) {
        PlatformEventProcessor processor = null;
        try {
            Type t = Type.forName(processorName);
            processor = (PlatformEventProcessor) t.newInstance();
        } catch (Exception e) {
            PlatformLog.logException(PlatformEventsUtil.class.getName(), e, false);
        }
        return processor;
    }

    /*
     * Care if value might be null in String.left().
    */ 
    public static String trim(String value, Integer length) {
        if (value == null) {
            return null;
        } else {
            return value.left(length);
        }
    }
}