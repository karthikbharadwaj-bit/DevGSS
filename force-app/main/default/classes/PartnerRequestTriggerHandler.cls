public with sharing class PartnerRequestTriggerHandler {

    public static PRMHelper PRMHelperInstance = new PRMHelper();
     // PRM 80 Start
     public static final Id RCGuest_USER_ID = HardcodedIdsMapper.getMatchedObjectId('0052H00000DsRqJQAV');
     // PRM 80 End

    private static PartnerRequestDuplicateAccountSearcher.SearchResult FoundDuplicates { get; private set; }

    private static Partner_Request__c[] getTriggerNewObjects() {
        return (Partner_Request__c[])Trigger.new;
    }

    public class ProcessPhoneAndTypeBeforeInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for(Partner_Request__c request : getTriggerNewObjects()) { 
                if(request.Ready_For_Processing__c==true && request.PR_Processed__c ==false){
                request.CreatedbyId = RCGuest_USER_ID;
                request.LastModifiedById=RCGuest_USER_ID;
                 }
            // PRM 80 End  
                if(request.Partner_Phone__c != null && request.Partner_Country__c != null) {
                    request.Original_Partner_Phone__c = request.Partner_Phone__c;
                    request.Partner_Phone__c = ValidationUtility.validatePhoneNumber(request.Partner_Phone__c,
                        request.Partner_Country__c);
                }
                if(request.Partner_Type__c!= null && request.Partner_Type__c != PRMHelper.PARTNER_TYPE_BILL_ON_BHEALF && request.Partner_Type__c != PRMHelper.PARTNER_TYPE_WOLESALE_RESELLER && request.Partner_Type__c != PRMHelper.PARTNER_TYPE_AVAYA_WOLESALE_RESELLER && request.Partner_Type__c != PRMHelper.PARTNER_TYPE_ATOS_WOLESALE_RESELLER &&  request.Partner_Type__c != PRMHelper.PARTNER_TYPE_ALE_WOLESALE_RESELLER){
                    if(request.Reseller_Partner_Type__c == PRMHelper.RESELLER_TYPE_REGULAR_PARTNER) {
                    request.Partner_Type__c = PRMHelper.PARTNER_TYPE_MASTER_AGENT;  
                  } else if (request.Reseller_Partner_Type__c == PRMHelper.RESELLER_TYPE_ISV_PARTNER) {
                    request.Partner_Type__c = PRMHelper.PARTNER_TYPE_ISV_PARTNER;
                }
                }
                
            }
        }
    }

    public class PartnerRequestBeforeInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Partner_Request__c[] newRequests = getTriggerNewObjects();
            PartnerRequestDuplicateAccountSearcher.SearchResult result;
            result = PRMHelperInstance.findDuplicateAccounts(getTriggerNewObjects());
            PRMHelperInstance.storeInfoAboutDuplicatesInRequests(newRequests, result.AllFoundAccounts);
            PartnerRequestTriggerHandler.FoundDuplicates = result;
        }
    }

    public class ProcessPhoneBeforeUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for(Partner_Request__c request : getTriggerNewObjects()){
                if (request.Partner_Phone__c != null && request.Partner_Country__c != null) {
                    if (CoreObjectBase.IsFieldChanged(request, Partner_Request__c.Partner_Phone__c)
                        || CoreObjectBase.IsFieldChanged(request, Partner_Request__c.Partner_Country__c))
                    {
                        request.Partner_Phone__c = ValidationUtility.validatePhoneNumber(request.Partner_Phone__c,
                            request.Partner_Country__c);
                    }
                }  
            }
        }
    }

    public class PartnerRequestAfterInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Partner_Request__c[] newRequests = getTriggerNewObjects();
            PRMHelperInstance.processFranchisorRequests(newRequests);
             // PRM 80 Start
              List<Partner_Request__c> prListOfrRecords = new  List<Partner_Request__c> ();
              for(Partner_Request__c request : getTriggerNewObjects()){
                 if(request.Ready_For_Processing__c==false){
                         prListOfrRecords.add(request);
                 }
              } 
             Map<Id, Account> newAccountByRequestId = PRMHelperInstance.onInsertPRM(prListOfrRecords);

            Map<Partner_Request__c, Set<Id>> allFoundAccounts;
            allFoundAccounts = PartnerRequestTriggerHandler.FoundDuplicates.AllFoundAccounts;

            //Added by Saradha for fixing null pointer exception
            for(Partner_Request__c entry : allFoundAccounts.keyset()) {
                if(null!=newAccountByRequestId && null!=entry.Id ){
                    if (newAccountByRequestId.containsKey(entry.Id) == false) {
                        continue;
                    }
                    if(null!=allFoundAccounts && null!=newAccountByRequestId.get(entry.Id) && allFoundAccounts.get(entry) != null) {
                        allFoundAccounts.get(entry).add(newAccountByRequestId.get(entry.Id).Id);
                    }
                }
            }

            PRMHelperInstance.storeInfoAboutDuplicatesInAccounts(allFoundAccounts);
            
            PRMHelperInstance.sendEmailNotificationAboutDuplicates(newRequests,
                PartnerRequestTriggerHandler.FoundDuplicates.FoundByNameAccounts);
        }
    }

     public class PartnerRequestAfterUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
          //PRM 80 start
        for(Partner_Request__c request : getTriggerNewObjects()){
            if(request.PR_Processed__c==false){
         PRMHelperInstance.onUpdatePRM(getTriggerNewObjects());
    }
    //PRM 80 End
            PRMHelperInstance.onUpdatePRM(getTriggerNewObjects());
        }
    }
  }
}