public class AccountsPaidAndCanceledSchedulable implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchJob_AccountsPaidAndCanceled(1, 'Customer Contacts'));
    }
}