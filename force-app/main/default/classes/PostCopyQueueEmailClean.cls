public class PostCopyQueueEmailClean extends PostCopyWorker {

    public override String getClassName() {
        return PostCopyQueueEmailClean.class.getName();
    }

    public override void run() {
        List<Group> queues = [SELECT Id
                                FROM Group
                                WHERE Type = 'Queue'
                                AND Email != ''];

        for(Group q : queues) {
            q.Email = '';
        }

        Database.SaveResult[] results = Database.update(queues, false);
        PostCopyUtil.handleSaveResults(results);
    }
}