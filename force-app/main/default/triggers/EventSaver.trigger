/*************************************************
Trigger on Event object
After Delete: Prevents non-admin user from deleting Events.
/************************************************/

trigger EventSaver on Event (after delete,after insert, after update) {
    
    if(TriggerHandler.BY_PASS_EVENT_ON_INSERT || TriggerHandler.BY_PASS_EVENT_ON_UPDATE || TriggerHandler.BY_PASS_EVENT_ON_AFTER){
        System.debug('#### RETURNED FROM EVENT INSERT / UPDATE TRG ####');
        return;
    } else {
        TriggerHandler.BY_PASS_EVENT_ON_AFTER = true;
        System.debug('#### STILL CONTINUE FROM EVENT INSERT / UPDATE TRG ####');
    }
    // Contains set of user Id, #implementationTestLink
    Set<String> useridSet = new Set<String>();
    Map<String,Implementation__c> mapImplementation = new Map<String,Implementation__c>();
    List<Implementation__c> finalImplementationToUpdate = new List<Implementation__c>();
    
    // Get the current user's profile name
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    
    // EU Privacy Phase 3 IT Profile changes - START
    Set<String> profiles_who_can_delete_attachments = new Set<String>();
    List<EU_Component_Reference__mdt> euComp = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%EventSaverTrigger%' and DeveloperName = 'ProfilesWhoCanDeleteAttachments'];
    String profilesList  = (euComp.size() > 0) ? euComp[0].Values__c : '';
    if(String.isNotBlank(profilesList)) {
        profiles_who_can_delete_attachments.addAll(profilesList.split(','));
    }
    // If current user is not a System Administrator, do not allow Attachments to be deleted
    if(Trigger.isDelete) {
          if(!profiles_who_can_delete_attachments.contains(prof.Name)) 
          { // EU Privacy Phase 3 IT Profile changes - END
            for (Event e : Trigger.old) {
                e.addError('Unable to delete events.');
            }  
          }
    }

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new EventTriggerHandler.RcActivityInfoCreation())
        .bind(Triggers.Evt.afterupdate, new EventTriggerHandler.RcActivityInfoCreation())
        .manage();
    
    /*******************************************************************
     * @Description.: updating the Account's lastTouchbySalesAgent     *
     * @updatedBy...: India team                                       *
     * @updateDate..: 19/03/2014                                       *
     * @Case Number.: 02432238                                         *
    /*******************************************************************/
    /*********************************************Code for Case Number:02432238 Start from here *****************************************/
    if(Trigger.isInsert || Trigger.isUpdate) {
        try{
            User userObj = UserHelper.getCachedCurrentUser();

            List<Account> accountList = new List<Account>();
            if(Test.isRunningTest() || (prof.Name.toLowerCase().contains('sales') && !prof.Name.toLowerCase().contains('engineer')) ){
                for(Event eventObj: trigger.new){
                    String eventParentId = eventObj.whatId;
                    if(eventParentId != null) {
                        String PrefixOfId = eventParentId.subString(0,3);
                        if(PrefixOfId == '001'){
                            accountList.add(new Account(id = eventParentId));
                        }
                    }
                }
            }
        }catch(Exception Ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }
    }
    
    /**********************************************************************************************
    * @Description : Code is for updating the Most Recent Implementation Event Id.                *
    *                                                                                             *
    * TO BE DELETED.                                                                              *
    **********************************************************************************************/
    if(trigger.isInsert){
        EventTriggerHandler eth = new EventTriggerHandler();
        List<SObject> accountAndOpportunityTeamMembersToInsert = eth.getOpportunityOrAccountTeamMembersToInsert((List<Event>) Trigger.new);
        if (!accountAndOpportunityTeamMembersToInsert.isEmpty()) {
            Database.insert(accountAndOpportunityTeamMembersToInsert);
        }
        try{
            for(Event thisRecord : trigger.new){
                if(!String.isBlank(thisRecord.CustomerId__c)) {
                    useridSet.add(thisRecord.CustomerId__c);
                }
            } 
            if(useridSet != null && useridSet.size()>0) {
                for(Implementation__c implemetationObj : [SELECT RC_USER_ID__c, Account__c,Account__r.Id
                                                          FROM Implementation__c 
                                                          WHERE RC_USER_ID__c IN :useridSet]) {
                    mapImplementation.put(implemetationObj.RC_USER_ID__c,implemetationObj);
                }
            }   
            for(Event thisRecord : trigger.new){
                if(mapImplementation != null && !String.isBlank(thisRecord.CustomerId__c) && mapImplementation.get(thisRecord.CustomerId__c) != null) { 
                    Implementation__c implementationObj = new Implementation__c(Id = mapImplementation.get(thisRecord.CustomerId__c).id);
                    implementationObj.Most_Recent_Implementation_Event__c = thisRecord.Id;
                    system.debug('#### Implementation to be updated - '+implementationObj);
                    finalImplementationToUpdate.add(implementationObj); 
                }
            }
            if(finalImplementationToUpdate != null && finalImplementationToUpdate.size() > 0){
                update finalImplementationToUpdate;
            }
        }catch(Exception ex){
            system.debug('#### Exception at Line = '+ex.getLineNumber()+' Message = '+ex.getMessage());
        }
    }
}