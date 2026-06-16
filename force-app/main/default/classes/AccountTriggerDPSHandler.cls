public without sharing class AccountTriggerDPSHandler {
    public static void LockRecordsonDPSFlag(List<Id> recordstoLock){
        //Lock the relevant records in case DPS is flagged
        if(recordstoLock.size() > 0){
            List<Approval.LockResult> lrList = Approval.lock(recordstoLock, false);
            for(Approval.LockResult lr : lrList) {
                if (lr.isSuccess()) {
                    System.debug('Successfully locked with ID: ' + lr.getId());
                }
                else {
                    for(Database.Error err : lr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    public static void UnlockRecordsonDPSClear(List<Id> recordstoUnLock){
        //Unlock records if DPS has cleared the account
        if(recordstoUnLock.size() > 0){
            List<Approval.UnlockResult> lrList = Approval.unlock(recordstoUnLock, false);
            for(Approval.UnlockResult lr : lrList) {
                if (lr.isSuccess()) {
                    System.debug('Successfully locked with ID: ' + lr.getId());
                }
                else {
                    for(Database.Error err : lr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
}