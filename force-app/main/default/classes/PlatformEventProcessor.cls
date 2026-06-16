public abstract class PlatformEventProcessor {
    /*
     * Class extensions will implement this method and include any logic needed to run during particular event execution.
    */
    protected abstract void handle(List<SObject> events);

    /* 
     *  Class extensions are required to implement the run method above which is then wrapped by this handle() method. 
    */ 
    public void process(List<SObject> events) {
        handle(events);
    }
}