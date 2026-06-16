public class TaskTriggerHandler {
    public class RcActivityInfoCreation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            TaskTriggerHelper.populateDFRActivityFields(Trigger.new);
        }
    }
}