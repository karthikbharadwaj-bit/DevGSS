public with sharing class SWNValidator {
    public static String validateSyncWithNGBS(SWNDataCollector sdc, Boolean isAutoSync) {
        SWNValidatorManager manager = new SWNValidatorManager(sdc, isAutoSync);

        Response resp = manager.validate();
        handleSuspendedStatus(resp, sdc);

        return JSON.serialize(resp.messages);
    }

    private static void handleSuspendedStatus(Response resp, SWNDataCollector sdc) {
        if (isSuspendedNGBSAccount(sdc)) {
            SWNMessageHelper.InfoMessagesBuilder builder = new SWNMessageHelper.InfoMessagesBuilder();
            resp.addMessage(builder.getSWNMessage(SWNMessageHelper.LabelMessage.SUSPENDED_NGBS_STATUS));
        }
    }

    private static Boolean isSuspendedNGBSAccount(SWNDataCollector sdc) {
        return AccountHelper.SUSPENDED_STATUS.equalsIgnoreCase(sdc.ngbsAcc?.packages[0].status);
    }
}