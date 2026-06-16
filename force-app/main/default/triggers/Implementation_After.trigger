/* ================================================================================================

UPDATE:

By: eugenebasianomutya
Date: 12162016
Case: 04262550 - Update Medallia Outbound Message
Description:
    Update this trigger (https://rc.my.salesforce.com/01q80000000GuDX) - Implementation_After
      >> replace Implementation_Status__c with Implementation_Status_2__c. Copy Implementation_Status_2__c instead of Implementation_Status__c to account
=================================================================================================== */



trigger Implementation_After on Implementation__c (After Insert, After Update) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_Implementation_Trigger__c == true) {
             System.debug('$$$ ByPassTrigger__c Active For Implementation Credit $$$');
            return;
        }
    // Flag to check if trigger is to be executed or not.
    if (TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER){
      System.debug('### RETURNED FROM IMPLEMENTATION AFTER TRG ###');
      return;
    } else {
      System.debug('### STILL CONTINUE FROM IMPLEMENTATION AFTER TRG ###');
      TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
    }
      if (Trigger.isInsert){
          System.debug('#### calling method to create dummy event.');
          //-------------------As/Simplion/3/13/2015----------------------------------
        Map<Id, Id> mappingImpToEvent = ImplementationHelper.createDummyEvent(trigger.new);
          Set<id> acc_ids = new Set<id>();
          set<string> userIdSet = new set<string>();

        /*Collectiong related Accounts*/

        for (Implementation__c imp: Trigger.new){
            acc_ids.add(Imp.Account__c);
            System.debug('IMPLEMENTATON ID  --->'+imp.id);
            if (!string.isBlank(imp.RC_USER_ID__c)) {
            userIdSet.add(imp.RC_USER_ID__c);
            }
         }

        /*Fetching Accounts*/
        Map<id,Account> acct_map = new Map<id,Account>([SELECT id, Implementation_Status__c FROM Account Where id IN:acc_ids]);
        List<Account> acct_list = new List<Account>();
        Set<Account> s = new Set<Account>();
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        map<string,List<Event>> mapImplementationTOEvent = new map<string,List<Event>>();
         if (userIdSet != null && userIdSet.size()>0) {
           List<Event> eventListQuery = new List<Event>();
           if (Test.isRunningTest()) {
             eventListQuery = [select CustomerId__c from Event where CustomerId__c IN : userIdSet limit 1];
           } else {
             eventListQuery = [select CustomerId__c from Event where CustomerId__c IN : userIdSet];
           }
           for (Event eventObj : eventListQuery) {
             if (eventObj.CustomerId__c != null) {
               List<Event> eventList = new List<Event>();
               if (mapImplementationTOEvent != null && mapImplementationTOEvent.containsKey(eventObj.CustomerId__c)) {
                 eventList = mapImplementationTOEvent.get(eventObj.CustomerId__c);
               }
               eventList.add(eventObj);
               mapImplementationTOEvent.put(eventObj.CustomerId__c,eventList);
               }
           }
        }

        List<Event> eventToUpd = new List<Event>();
        for (Implementation__c imp: Trigger.new){
            if (imp.Account__c != null && acct_map !=null && acct_map.get(imp.Account__c) !=null){
                Account tempAcc = acct_map.get(imp.Account__c);

                //Case: 04262550 - START
                tempAcc.Implementation_Status__c = imp.Implementation_Status_2__c;
                //Case: 04262550 - END

                if (mappingImpToEvent != null && mappingImpToEvent.get(imp.Id) != null){
                tempAcc.Initial_Implementation_Event__c = mappingImpToEvent.get(imp.Id);
                }
                s.add(tempAcc);
                mapAccount.put(tempAcc.Id, tempAcc);
            }
            if (!string.isBlank(imp.RC_USER_ID__c) && mapImplementationTOEvent != null && mapImplementationTOEvent.get(imp.RC_USER_ID__c) != null) {
                List<Event> eventListTOUpd = mapImplementationTOEvent.get(imp.RC_USER_ID__c);
                for(Event eventObj : eventListTOUpd) {
                Event evenObj  = new Event(Id = eventObj.id);
                evenObj.WhatId = imp.Id;
                eventToUpd.add(evenObj);
                }
            }
        }
        try {
            if (!mapAccount.isEmpty()) {
            acct_list.addAll(mapAccount.values());
            update acct_list;
            }
            if (eventToUpd != null && eventToUpd.size()>0) {
            update eventToUpd;
            }
        } catch (Exception ex) {}
    }

    /*
     * Graduation Score card Implementation Phase Start
     */
        if (Trigger.isUpdate || Trigger.isInsert){
            Set<String> acc_ids = new Set<String>();

            /*Collectiong related Accounts*/
            for (Implementation__c imp: Trigger.new){
                acc_ids.add(imp.Account__c);
            }
            Map<Id, Account> accountMetricMap = AccountScoreCardHelper.getAccountsWithAccountMetric(acc_ids);
            Map<Id, Account_Metric__c> accMetricIdToAccMetricMap = new Map<Id, Account_Metric__c>();

            String strAction = GraduationScoreCardHelper.STR_INSERT;
            if (Trigger.isUpdate){
                strAction = GraduationScoreCardHelper.STR_UPDATE;
            }
            for (Implementation__c imp: Trigger.new){
                GraduationScoreCardHelper.ScoreCardWrapper objScoreCardWrapper = new GraduationScoreCardHelper.ScoreCardWrapper();
                if (Trigger.isUpdate){
                objScoreCardWrapper = GraduationScoreCardHelper.getImplementationCompletionDetails(imp, Trigger.oldMap.get(imp.Id), strAction);
                } else {
                objScoreCardWrapper = GraduationScoreCardHelper.getImplementationCompletionDetails(imp, null, strAction);
                }
                Account_Metric__c accountMetric = new Account_Metric__c();
                if (accountMetricMap.get(imp.Account__c) != null && accountMetricMap.get(imp.Account__c).Account_Metrics__r.size()>0){
                    accountMetric = accountMetricMap.get(imp.Account__c).Account_Metrics__r[0];
                }
                if (accountMetric.Id != null){
                    accountMetric.Account_Graduation_Status__c = 'New';
                    if (imp.Implementation_Phase_Completion_Rate__c >0 && imp.Implementation_Phase_Completion_Rate__c <100) {
                        accountMetric.Account_Graduation_Status__c = 'Implementation Phase';
                    }
                    if (imp.Implementation_Phase_Completion_Rate__c == 100) {
                        accountMetric.Account_Graduation_Status__c = 'Adoption/Maturity Phase';
                    }
                    if (accountMetric.Adoption_Phase_Completion_Rate__c >= 75) {
                        accountMetric.Account_Graduation_Status__c = 'Graduation Phase';
                    }
                    accMetricIdToAccMetricMap.put(accountMetric.Id, accountMetric);
                }
                System.debug('accMetricIdToAccMetricMap------>' + accMetricIdToAccMetricMap);
            }
            if(accMetricIdToAccMetricMap.size()>0){
                update (new List<Account_Metric__c>(accMetricIdToAccMetricMap.values()));
            }
        }
     /* Graduation Score card Implementation Phase END*/
}