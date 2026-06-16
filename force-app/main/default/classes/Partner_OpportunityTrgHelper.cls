public class Partner_OpportunityTrgHelper {
    //Mappings for Opportunity Before
    public static Opportunity oppBeforeMappings(Opportunity newOpp,Map<Id,Opportunity> oldOppMap){
        system.debug('inside partner opp trg');
        //PBC-10584: Added in Oppty trigger instead of validation rule, as we have reached the maximum number of 20 unique object references on Opportunity
        List<Community_Details__mdt> commDet_mdt = [Select Top_Master_Partner_Id__c,Brand_Name__c from Community_Details__mdt where Brand_Name__c = 'Rainbow Office' limit 1];
        List<Contact> aleTopCon = [Select Account.Partner_ID__c from Contact where Id =: newOpp.Portal_Cloud_Specialist__c limit 1];
        if(commDet_mdt.size() > 0 && aleTopCon.size() > 0 && newOpp.Brand_Name__c == commDet_mdt[0].Brand_Name__c && newOpp.Portal_Cloud_Specialist__c != null && aleTopCon[0].Account.Partner_ID__c != commDet_mdt[0].Top_Master_Partner_Id__c){
            newOpp.AddError('Portal_Cloud_Specialist__c',System.Label.Not_ALE_Top_Level_Contact_Error);
        }
        //PBC-10584 END
        if(oldOppMap !=null &&  oldOppMap.get(newOpp.Id) !=null){
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            if(newOpp !=null &&
               newOpp.Avaya_Cloud_Specialist__c != null &&
               newOpp.Avaya_Cloud_Specialist__c != oldOpp.Avaya_Cloud_Specialist__c &&
               newOpp.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')){
                   newOpp.Portal_Cloud_Specialist__c=newOpp.Avaya_Cloud_Specialist__c;
               }
            if(newOpp !=null && 
               newOpp.Portal_Cloud_Specialist__c != null){
                   newOpp.Avaya_Cloud_Specialist__c=newOpp.Portal_Cloud_Specialist__c;
                   system.debug('Avaya_Cloud_Specialist__c'+ newOpp.Avaya_Cloud_Specialist__c);
               }
        }
        else if(oldOppMap ==null && newOpp !=null){
            if(newOpp !=null && 
               newOpp.Avaya_Cloud_Specialist__c != null &&
               newOpp.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')){
                   newOpp.Portal_Cloud_Specialist__c=newOpp.Avaya_Cloud_Specialist__c;
                   system.debug('Portal_Cloud_Specialist__c'+ newOpp.Portal_Cloud_Specialist__c);
               }
            if(newOpp !=null && 
               newOpp.Portal_Cloud_Specialist__c != null){
                   newOpp.Avaya_Cloud_Specialist__c=newOpp.Portal_Cloud_Specialist__c;
                   system.debug('Avaya_Cloud_Specialist__c'+ newOpp.Avaya_Cloud_Specialist__c);
               }
        }
        return newOpp;
    }
    //On Change Of Opp Cloud Specialist, recalculate sharing of Opp
    public static void oppAfterMappings(List<Opportunity> newOppList,Map<Id,Opportunity> oldOppMap){
        system.debug('inside partner opp trg');
        Boolean isCloudSpecialistUpdated=false;
        Set<Id> oppIds=new Set<Id>();
        Set<Id> dealSupportIds=new Set<Id>();
        Set<Id> customerAccountIds=new Set<Id>();
        //After Update
        if(oldOppMap!=null && oldOppMap.size()>0){
            if( newOppList !=null && newOppList.size()>0 && !newOppList.isEmpty()){
                for(Opportunity opp:newOppList){
                    if(oldOppMap.get(opp.Id) !=null){
                        Opportunity oldOpp = oldOppMap.get(opp.Id);
                        if(opp.AccountId != null && opp.Portal_Cloud_Specialist__c != null && opp.Portal_Cloud_Specialist__c != oldOpp.Portal_Cloud_Specialist__c &&
                           string.valueOf(opp.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')){
                               isCloudSpecialistUpdated=true;
                               customerAccountIds.add(opp.AccountId);
                           }
                    }
                    oppIds.add(opp.Id);
                }
                if(isCloudSpecialistUpdated){
                    if(!System.isFuture()){
                        if(customerAccountIds!=null && !customerAccountIds.IsEmpty() && customerAccountIds.size()>0){
                            Sharing_AccountLeadHandler.handleAccountShareFuture(customerAccountIds);
                        }
                        //On Change Of Opp Cloud Specialist, recalculate sharing for related Deal Supports
                        if(oppIds != null && !oppIds.isEmpty() && oppIds.size()>0){
                            for(Deal_Support__c ds:[Select id,Name,Status__c,Type__c,Opportunity__c,Portal_Cloud_Specialist__c,CreatedDate from Deal_Support__c where Opportunity__c IN:oppIds]){
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
        }else if(oldOppMap ==null && newOppList !=null && newOppList.size()>0 && !newOppList.isEmpty()){
            //After Insert
            for(Opportunity opp:newOppList){
                if(opp.AccountId != null && opp.Portal_Cloud_Specialist__c !=null) {
                    customerAccountIds.add(opp.AccountId);
                }
            }
            if(!System.isFuture()){
                if(customerAccountIds!=null && !customerAccountIds.IsEmpty() && customerAccountIds.size()>0){
                    Sharing_AccountLeadHandler.handleAccountShareFuture(customerAccountIds);
                }
            }
            
        }
    }
}