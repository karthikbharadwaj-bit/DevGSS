/*
* Name         : PostCopyUtil.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Class containscommon methods for Sandbox Post Copy framework.
*/

public with sharing class PostCopyUtil {

    private static final String PICKLIST_STATUS_SUCCESS = 'Success';
    private static final String PICKLIST_STATUS_FAILURE = 'Error';
    private static final String DELIMITER = '|||';
    public static Boolean OVERALL_SUCCESS = true;

    public static final String PRODUCTION_EXCEPTION_MESSAGE = 'Running Post Copy Framework on production is not allowed.';
    public static final String HAS_NO_PERMISSION_EXCEPTION_MESSAGE = 'You can not run a Post Copy Framework without custom permission "' + CustomPermissionHelper.PERMISSION_RUN_POST_COPY_FRAMEWORK + '".';

    @testVisible public static Boolean isProduction = false;
    static {
        Organization currentOrg = (Organization) new OrganizationSelector()
            .selectOrg()
            .setQueryCaching(true)
            .executeQuery()
            .get(0);

        isProduction = !currentOrg.IsSandbox;
    }

    //Create the error debug log. In the future we can replace it with the custom Log object.
    public static void createLogObj(String className, Exception e){
        if(e != null){
            OVERALL_SUCCESS = false;
            PlatformLog.logException('PostCopyUtil.' + className, e);
            System.debug(PICKLIST_STATUS_FAILURE + DELIMITER + className + DELIMITER + getErrorMessage(e));
        } else {
            System.debug(PICKLIST_STATUS_SUCCESS + DELIMITER + className);
        }
    }

    public static PlatformLog__c buildLogObj(String source, Exception e) {
        return PlatformLog.buildLog(source, e?.getMessage(), e?.getStackTraceString(), null, null);
    }

    public class ForcedException extends Exception{}

    private static String getErrorMessage(Exception e){
        return e.getLineNumber() + DELIMITER
                + e.getMessage() + DELIMITER
                + e.getStackTraceString();
    }

    //Get and create the workers from the custom settings.
    public static List<PostCopyWorker> getSynchronousWorkers(SandboxContext context) {
        return getWorkerListBasedOnSettings(getListOfPostrefreshTasks(false), context);
    }

    private static List<PostCopyWorker> getWorkerListBasedOnSettings(
        List<PostCopyTasks__c> taskList, SandboxContext context
    ) {
        List<PostCopyWorker> workerList = new List<PostCopyWorker>();
        for (PostCopyTasks__c task : taskList) {
            String workerName = task.DeveloperName__c;
            PostCopyWorker worker = createWorkerObjectFromString(workerName, context);
            if (worker == null) {
                // a log obj was created in createWorkerObjectFromString() above; it also retuned a null obj so we're not going to add it
                continue;
            }
            workerList.add(worker);
        }
        return workerList;
    }

    public static PostCopyWorker createWorkerObjectFromString(String workerName, SandboxContext context) {
        PostCopyWorker worker = null;
        try {
            Type t = Type.forName(workerName);
            worker = (PostCopyWorker) t.newInstance();
            worker.context = context;
        } catch (Exception e){
            PostCopyUtil.createLogObj(PostCopyUtil.class.getName(), e);
        }
        return worker;
    }

    public static void handleSaveResults(List<Database.SaveResult> saveResults){
        List<PlatformLog__c> logs = PostCopyUtil.buildDatabaseOperationErrorsLogs(saveResults);
        if (logs != null && !logs.isEmpty()) {
            PlatformLog.logResults(logs);
        }
    }

    public static List<PlatformLog__c> buildDatabaseOperationErrorsLogs(List<Database.SaveResult> saveResults) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();

        for (Database.SaveResult saveResult : saveResults) {

            if (!saveResult.isSuccess()) {

                for (Database.Error err : saveResult.getErrors()) {
                    logs.add(
                        PlatformLog.buildLog(
                            'PostCopyManager',
                            String.valueOf(err.getStatusCode()),
                            err.getMessage(),
                            null,
                            null
                    ));
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Record fields that affected this error: ' + err.getFields());
                }
            }
        }

        return logs;
    }

    public static List<PostCopyTasks__c> getListOfPostrefreshTasks(Boolean async) {
        return [
            SELECT Id, DeveloperName__c, Active__c, OrderNumber__c
            FROM PostCopyTasks__c
            WHERE Active__c = true
            AND IsAsync__c = :async
            ORDER BY OrderNumber__c ASC
        ];
    }

    public class CustomSandboxContextException extends Exception {}

    /* Create a class that implements System.SandboxContext as we can't instantiate System.SandboxContex. */
    public class CustomSandboxContext implements System.SandboxContext {
        private String boxName;
        public CustomSandboxContext() {
            this.boxName = UserInfo.getUserName().substringAfterLast('.');
            checkPermissions();
        }
        public CustomSandboxContext(String boxName) {
            this.boxName = boxName;
            checkPermissions();
        }

        //This is not used in the framework and we need any id.
        public Id organizationId() {
            return UserInfo.getOrganizationId();
        }

        //This is not used in the framework and we need any id.
        public Id sandboxId() {
            return UserInfo.getOrganizationId();
        }

        public String sandboxName() {
            return this.boxName;
        }

        private void checkPermissions() {
            Boolean canRunPostCopy = FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_RUN_POST_COPY_FRAMEWORK);

            if (isProduction) {
                throw new CustomSandboxContextException(PRODUCTION_EXCEPTION_MESSAGE);
            } else if (!canRunPostCopy) {
                throw new CustomSandboxContextException(HAS_NO_PERMISSION_EXCEPTION_MESSAGE);
            }
        }
    }
}