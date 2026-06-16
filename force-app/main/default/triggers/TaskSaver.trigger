/**********************************************************
Trigger on Task object
After Delete: Prevents non-admin user from deleting Tasks.
/**********************************************************/

trigger TaskSaver on Task (after insert, after update, after delete) {

    if (TriggerHandler.BY_PASS_AFTER) {
        System.debug('### RETURNED FROM TASK TRIGGER AFTER TRG FOR STANDARD LAYOUT ###');
        return;
    }
    
    // Get the current user's profile name
    Profile currentUserProfileRecord = null;
    if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
        currentUserProfileRecord = ProfileHelper.getCurrentUserProfileWithCache();
    }
    else {
        currentUserProfileRecord = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    }
    
    // EU Privacy Phase 3 IT Profile changes - START
    Set<String> profiles_who_can_delete_tasks = new Set<String>();
    List<EU_Component_Reference__mdt> euComp = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%TaskSaverTrigger%' and DeveloperName = 'ProfilesWhoCanDeleteTasks'];
    String profilesList  = (euComp.size() > 0) ? euComp[0].Values__c : '';
    if(String.isNotBlank(profilesList)) {
		profiles_who_can_delete_tasks.addAll(profilesList.split(','));
    }
    if(trigger.isDelete){
        // If current user is not a System Administrator, do not allow Attachments to be deleted
        system.debug('DELETING PROFILE IS::: ' + currentUserProfileRecord.Name); 
        system.debug('DELETING USER IS::: ' + UserInfo.getUserId()); 
        if(!profiles_who_can_delete_tasks.contains(currentUserProfileRecord.Name))
        { // EU Privacy Phase 3 IT Profile changes - END
            for (Task t : Trigger.old) {
                t.addError('Unable to delete tasks.');
            }  
        }
    }

    /*********************************************************************************
     * @Discription.......: updating Account LastTouchSalesPerson Value  when Task   *
     *                      is insert or updated                                     *
     * @lastModifiedDate..: 2/04/2014                                                *
     * @LastModifiedBy....: India Team                                               * 
     * @Case number.......: 02432238                                                 *
     ******************************case:02432238 Start here***************************/
    if(trigger.isInsert || trigger.isUpdate){
        try{
            User userObj = UserHelper.getCachedCurrentUser();

            List<Account> lstParentAccount = new List<Account>();
            if(currentUserProfileRecord.Name.toLowerCase().contains('sales') && !currentUserProfileRecord.Name.toLowerCase().contains('engineer') ){
                for(Task Taskobj: trigger.New){
                    String id = Taskobj.whatId;
                    String PrefixOfId = id.subString(0,3);
                    if(PrefixOfId == '001'){
                        Account newOrUpdatedTaskofAccount = new Account(Id = Taskobj.whatId); 
                        lstParentAccount.add(newOrUpdatedTaskofAccount);
                    }  
                }
            }
        }catch(Exception Ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }           
    /*******************************case:02432238 Ends here****************************/

    }
}