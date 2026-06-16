public class Partner_LeadTrgHelper {
    //Mappings for Lead Before 
    public static Lead leadBeforeMappings(Lead newLead,Map<Id,Lead> oldLeadMap){
        if(oldLeadMap !=null &&  oldLeadMap.get(newLead.Id) !=null){
            Lead oldLead = oldLeadMap.get(newLead.Id);
            if(newLead !=null && newLead.Avaya_Cloud_Specialist__c!=null &&
               newLead.Avaya_Cloud_Specialist__c != oldLead.Avaya_Cloud_Specialist__c
               && newLead.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')){
                   newLead.Portal_Cloud_Specialist__c=newLead.Avaya_Cloud_Specialist__c;
               }
            if(newLead !=null && 
               newLead.Portal_Cloud_Specialist__c != null){
                   newLead.Avaya_Cloud_Specialist__c=newLead.Portal_Cloud_Specialist__c;
                   system.debug('Avaya_Cloud_Specialist__c'+ newLead.Avaya_Cloud_Specialist__c);
               }


        }else if(oldLeadMap ==null && newLead !=null){
            if(newLead !=null && newLead.Avaya_Cloud_Specialist__c!=null &&
               newLead.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')){
                   newLead.Portal_Cloud_Specialist__c=newLead.Avaya_Cloud_Specialist__c;
               }
            if(newLead !=null && 
               newLead.Portal_Cloud_Specialist__c != null){
                   newLead.Avaya_Cloud_Specialist__c=newLead.Portal_Cloud_Specialist__c;
                   system.debug('Avaya_Cloud_Specialist__c'+ newLead.Avaya_Cloud_Specialist__c);
               }
        }
        return newLead;
    }
    
    //On Change Of Lead Cloud Specialist, recalculate sharing for related Deal Supports
    public static void recalculateDealSupportsOfLead(List<Lead> newLeadList,Map<Id,Lead> oldLeadMap){
       	Boolean isCloudSpecialistUpdated=false;
        Set<Id> leadIds=new Set<Id>();
        Set<Id> dealSupportIds=new Set<Id>();
       
        if(oldLeadMap!=null && newLeadList!=null){
            for(Lead lead:newLeadList){
                Lead oldLead = oldLeadMap.get(lead.Id);
                if(lead.Portal_Cloud_Specialist__c!=null && 
                   lead.Portal_Cloud_Specialist__c != oldLead.Portal_Cloud_Specialist__c &&
                   string.valueOf(lead.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')){
                       isCloudSpecialistUpdated=true;
                   }
                leadIds.add(lead.Id);
            }
            if(isCloudSpecialistUpdated){
                if(!System.isFuture()){
                    //To recalculate Cloud Specialist for related deal supports of Opp	
                    if(leadIds != null && !leadIds.isEmpty() && leadIds.size()>0){
                        for(Deal_Support__c ds:[Select id,Name,Status__c,Type__c,Lead__c,Opportunity__c,Portal_Cloud_Specialist__c,CreatedDate from Deal_Support__c where Lead__c IN:leadIds]){
                            if(ds != null) {
                                dealSupportIds.add(ds.Id);
                            }
                        }
                        if(dealSupportIds != null && !dealSupportIds.IsEmpty() && dealSupportIds.size()>0){
                            Quote_SharingHandler.handleDealSupportShareFuture(dealSupportIds);
                        }
                    }
                }
            }
        }
    }
}