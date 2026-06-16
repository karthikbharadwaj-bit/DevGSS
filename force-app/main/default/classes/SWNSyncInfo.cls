public class SWNSyncInfo {
    @TestVisible
    private static final String REQUIRED_PARAM_ERROR = 'Required parameter "syncStepName" is blank.';

    @TestVisible
    private static final String NGBS_SYNC_EXECUTOR_KEY = 'NGBSSyncExecutorInfo';
    @TestVisible
    private static final String SYNC_INFO_KEY = 'syncInfo';

    public String scenarioName = '';
    public Map<String, String> userNameMap = new Map<String, String>();
    public Map<String, Datetime> timeStampMap = new Map<String, Datetime>();
    public List<String> stepNames = new List<String>();

    public static Response getStepsSyncInfo(SWNDataCollector sdc, List<String> steps) {
        Response result = new Response();
        NGBSAPI.initNgbsEndpoints(sdc.opp.isFedRamp__c);
        result.setData(NGBS_SYNC_EXECUTOR_KEY, sdc.syncable.getNGBSSyncExecutorInfo());
        result.setData(SYNC_INFO_KEY, sdc.syncable.getSyncInfoField());

        for (String step : steps) {
            SWNStepInfo stepInfo = SWNStepInfo.getStepInfo(step, sdc);
            if (stepInfo != null) {
                result.setData(step, stepInfo);
            } else {
                result.error('Error', 'No information about ' + step + ' step');
            }
        }

        return result;
    }

    public static String updateSyncInfoJson(String scenarioName, String syncInfoJson, String syncStepName, String userName, List<String> stepNames) {
        if (syncStepName == null) {
            AquivaHelper.throwAquivaException(REQUIRED_PARAM_ERROR);
        }

        SWNSyncInfo syncInfo = String.isBlank(syncInfoJson)
            ? new SWNSyncInfo()
            : (SWNSyncInfo) JSON.deserialize(syncInfoJson, SWNSyncInfo.class);

        syncInfo.scenarioName = scenarioName;
        syncInfo.stepNames = stepNames;
        syncInfo.userNameMap.put(syncStepName, userName ?? UserInfo.getName());
        syncInfo.timeStampMap.put(syncStepName, Datetime.now());

        return JSON.serialize(syncInfo, true);
    }
}