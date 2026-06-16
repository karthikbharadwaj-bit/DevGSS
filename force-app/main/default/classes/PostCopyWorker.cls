/*
* Name         : PostCopyWorker.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Manages the post copy tasks from the custom settings. Part of the Sandbox Post Copy framework.
*/

public with sharing abstract class PostCopyWorker {

    /*
     * Class extensions will implement this method and include any post copy logic they want to run.
    */
    protected abstract void run();

    /*
     * In order to identify the offending class that has caused an exception this method should be implemented
    */
    public abstract String getClassName();

    public SandboxContext context;
    public void process() {
        // catch any exception from child classes, so next workers will be executed if current one will fail
        try {
            this.run();
            PostCopyUtil.createLogObj(getClassName(), null);
        } catch (Exception e) {
            PostCopyUtil.createLogObj(getClassName(), e);
        }
    }

}