/*
* Name         : PostCopyManager.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Manages the post copy tasks from the custom settings. Part of the Sandbox Post Copy framework.
* Documentation: https://wiki.ringcentral.com/display/CRM/Post+Copy+Framework
*/

global class PostCopyManager implements SandboxPostCopy {

    public void runApexClass(SandboxContext context) {

        List<PostCopyWorker> workerList = PostCopyUtil.getSynchronousWorkers(context);
        for (PostCopyWorker worker : workerList) {
            worker.process();
        }

        PostCopyBatch asyncWorker = new PostCopyBatch(context);
        Database.executeBatch(asyncWorker, 1);
    }
}