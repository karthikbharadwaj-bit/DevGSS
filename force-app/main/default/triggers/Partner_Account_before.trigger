/*
Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date           Description                                            Tag
--------------------------------------------------------------------------------------------------------------------
CRM-4103            Lister         20-Aug-21      Revert Partner ID to old value if new value 
                                                  is set to null by RCESB user                            T1                                                
********************************************************************************************************************
*/

trigger Partner_Account_before on Account (before update) {
/*
    As a requirement for the partner portal, partners need to be able to see their customer accounts and contacts.
    To enable this,Account Record must be shared with Partner portal user . The triggers below are delete the old sharing rule
    record if customer partner account id is changed

*/
  ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
  if (bypassTrigger != null && bypassTrigger.Bypass_Account_Trigger__c == true) {
      System.debug('$$$ ByPassTrigger__c Active For Account $$$');
      return;
  }
	if((TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT ||
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE ||
        TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE) && !Test.isRunningTest()){
		    System.debug('### RETURNED FROM PARTNER ACCOUNT BEFORE ###');
		    return;
	} else {
		TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = true;
		System.debug('### STILL CONTINUE FROM PARTNER ACCOUNT BEFORE ###');
	}

	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    Map<ID, Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    Map<String, Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
    Id objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT).getRecordTypeId();
    Id partnerAccountRecordType = rtMapByRecName.get(AccountTriggerHelperExt.PARTNER_ACCOUNT).getRecordTypeId();
    Id customerAccountRecordType = rtMapByRecName.get(AccountTriggerHelperExt.CUSTOMER_ACCOUNT).getRecordTypeId();
    
    /*<T1>*/
    String partnerIdNullUpdateUsersCheckLabel = System.Label.PartnerID_Null_Update_Users_Check;
    List<String> partnerIdNullUpdateUsersCheckList = partnerIdNullUpdateUsersCheckLabel.split(',');
    /*</T1>*/

if(trigger.isUpdate){
       //if partner id is  changed in customer account then delete the sharing rule with customer accounts (associated with old partner id)
  try{
	Set<Id> accountsWithSharingToDelete = new Set<Id>();
    Set<Id> groupOruserid = new Set<Id>();
	List<String> accountPartnerIdsForProcess = new List<String>();
	List<Id> accountIdsForProcess = new List<Id>();
     for(Account objAccount:trigger.new){

		Account oldRecord = Trigger.oldMap.get(objAccount.Id);
         
         /*<T1>*/ 
         if(oldRecord.Partner_ID__c !=objAccount.Partner_ID__c && oldRecord.Partner_ID__c!=null && String.isBlank(objAccount.Partner_ID__c)
           && !partnerIdNullUpdateUsersCheckList.isEmpty() && partnerIdNullUpdateUsersCheckList.contains(System.UserInfo.getUserId())){
             objAccount.Partner_ID__c = oldRecord.Partner_ID__c;
         }
         /*</T1>*/
         
         
        if(oldRecord.Partner_ID__c!=null && oldRecord.Partner_ID__c !=objAccount.Partner_ID__c && objAccount.RecordTypeId == objRecordType){
            objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.PARTNER_ACCOUNT).getRecordTypeId();

                 AccountUpdateSharingRule.deleteOldSharingRuleForAccount(objAccount.id,oldRecord.Partner_ID__c,objRecordType);

            } else if((oldRecord.Partner_ID__c!=null && oldRecord.Partner_ID__c !=objAccount.Partner_ID__c &&
                      rtMapByName.get(objRecordType).getName() == AccountTriggerHelperExt.PARTNER_ACCOUNT) || Test.isRunningTest()) {
                objRecordType = rtMapByRecName.get(AccountTriggerHelperExt.PARTNER_ACCOUNT).getRecordTypeId();
				accountPartnerIdsForProcess.add(oldRecord.Partner_ID__c);
				accountIdsForProcess.add(objAccount.id);
				accountsWithSharingToDelete.add(objAccount.id);
            }
        }

		if (accountPartnerIdsForProcess.size() > 0) {
			List<Id> userRoleIdsForProcess = new List<Id>();
			for(User objUserold:[Select id,UserRole.Name,Contact.Account.RecordTypeId  from User where Contact.Account.Partner_ID__c in :accountPartnerIdsForProcess
								and Contact.Account.RecordTypeId = :partnerAccountRecordType and UserRole.PortalType='Partner' and
								UserRole.PortalRole='Executive' and Contact.Account.IsPartner=true and Contact.Account.id in :accountIdsForProcess]){
				userRoleIdsForProcess.add(objUserold.UserRoleId);
			}

			Set<Id> groupOruserIds=new Set<Id>();
			for(Group p:[Select id from group where RelatedId in :userRoleIdsForProcess ]){
				groupOruserIds.add(p.id);
			}

			if (accountsWithSharingToDelete.size() > 0) {
                Id processedRecordType = (Test.isRunningTest() ? partnerAccountRecordType : customerAccountRecordType);
				AccountUpdateSharingRule.deleteOldPrtnerSharingRuleForAccount(accountsWithSharingToDelete,accountPartnerIdsForProcess,customerAccountRecordType,groupOruserIds);
			}
		}

   }catch(Exception e){}
}

}