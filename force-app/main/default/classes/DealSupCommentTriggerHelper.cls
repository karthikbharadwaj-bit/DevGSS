//Ankit Sharma 	12/14/2020	update Deal Support when any dealsupport comment record is inserted or update....
public class DealSupCommentTriggerHelper {
    public static void updateDealSupport(List<Deal_Support_Comments__c> listOfDealSuppComment, Boolean isInsert) {
        List<Deal_Support__c> listDealSupport = new List<Deal_Support__c>();
        for(Deal_Support_Comments__c objDealSuppComment : listOfDealSuppComment) {
            if(objDealSuppComment.Deal_Support__c != null) {
                //listDealSupport.add(new Deal_Support__c(Id = objDealSuppComment.Deal_Support__c));
                Deal_Support__c dealSupport =  new Deal_Support__c(Id = objDealSuppComment.Deal_Support__c);
                if(isInsert)
                {
                    dealSupport.Last_Comment_By__c = objDealSuppComment.CreatedById;
                }
                listDealSupport.add(dealSupport);
            }
        }
        if(!listDealSupport.isEmpty()) {
            update listDealSupport;
        }
    }
    public static void updateComment(List<Deal_Support_Comments__c> listOfDealSuppComment){
        Set<Id> dealSuppIds = new Set<Id>();
        for(Deal_Support_Comments__c objDSC : listOfDealSuppComment) {
            if(objDSC.Deal_Support__c != null) {
                dealSuppIds.add(objDSC.Deal_Support__c);                
            }
        }
        Map<Id, Deal_Support__c> mapOfDS = new Map<Id, Deal_Support__c>([Select Id, Name, Assigned_To_Owner__c, Strategic_Partner_RC_Owner_User__c 
                                                                         from Deal_Support__c where Id IN:dealSuppIds]);
        if(!mapOfDS.isEmpty()){
            for(Deal_Support_Comments__c objDSC : listOfDealSuppComment) {
                if(objDSC.Deal_Support__c != null){
                    if(mapOfDS.get(objDSC.Deal_Support__c) != null){
                        if(mapOfDS.get(objDSC.Deal_Support__c).Assigned_To_Owner__c != null){
                            objDSC.Assigned_To_Owner__c = mapOfDS.get(objDSC.Deal_Support__c).Assigned_To_Owner__c;
                        }
                        if(mapOfDS.get(objDSC.Deal_Support__c).Strategic_Partner_RC_Owner_User__c != null){
                            objDSC.Strategic_Partner_RC_Owner_User__c = mapOfDS.get(objDSC.Deal_Support__c).Strategic_Partner_RC_Owner_User__c;
                        }
                    }
                }                
            }
        }
    }
}