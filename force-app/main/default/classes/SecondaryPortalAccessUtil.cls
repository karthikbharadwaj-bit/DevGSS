//Created by Pavithra on 11/06/2020 - to calculate sharing for multiple PCM
public class SecondaryPortalAccessUtil {
    public static Map<Id,Set<Id>> getUserIdListForPartnerAccts(Set<Id> setOfAccountIds){
        Map<Id,Set<Id>> mapOfPartnerAcctVsUserIdLst = new Map<Id,Set<Id>>();
        Set<Id> setOfPartnerContactIds = new Set<Id>();
        Map<Id,Id> mapOfPartnerContactIdVsUserId = new Map<Id,Id>();

        List<Portal_Access__c> listOfPortalAccesses = [SELECT Id,Account__c,Contact__c FROM Portal_Access__c WHERE Account__c IN : setOfAccountIds];
        if(!listOfPortalAccesses.isEmpty()){
            for(Portal_Access__c eachRecord : listOfPortalAccesses){
                if(eachRecord.Contact__c != null) {
                    setOfPartnerContactIds.add(eachRecord.Contact__c);
                }
            }
        }

        if(!setOfPartnerContactIds.isEmpty()){
            List<User> listOfPartnerContactUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN: setOfPartnerContactIds and isActive = true];

            for(User eachUser : listOfPartnerContactUsers){
                mapOfPartnerContactIdVsUserId.put(eachUser.ContactId, eachUser.Id);
            }
        }
        if(!listOfPortalAccesses.isEmpty()){
            for(Portal_Access__c eachRecord : listOfPortalAccesses){
                Set<Id> setOfUserId;
                if(!mapOfPartnerAcctVsUserIdLst.isEmpty() && mapOfPartnerAcctVsUserIdLst.containsKey(eachRecord.Account__c)){
                    setOfUserId = mapOfPartnerAcctVsUserIdLst.get(eachRecord.Account__c);
                }else{
                    setOfUserId = new Set<Id>();
                }
                setOfUserId.add(mapOfPartnerContactIdVsUserId.get(eachRecord.Contact__c));
                mapOfPartnerAcctVsUserIdLst.put(eachRecord.Account__c,setOfUserId);
            }
        }
        return mapOfPartnerAcctVsUserIdLst;
    }

    public static Map<String,Map<String,Id>> getGroupIdforCountry(Set<String> setOfBrandName,Set<String> setOfCountry){
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = new Map<String,Map<String,Id>>();
        Set<String> setOfGroupNames = new Set<String>();
        List<Portal_Access__c> listOfPortalAccesses = new List<Portal_Access__c>();
        Map<String,Id> mapOfGroupNameVsGroupId = new Map<String,Id>();

        if(setOfBrandName !=null && setOfCountry != null && !setOfBrandName.isEmpty() && !setOfCountry.isEmpty()){
            listOfPortalAccesses = [SELECT Id,Country__c,Brand_Name__c,Group_Developer_Name__c FROM Portal_Access__c
                                                        WHERE Brand_Name__c IN :setOfBrandName AND Country__c IN :setOfCountry];
        }

        if(listOfPortalAccesses != null && !listOfPortalAccesses.isEmpty()){
            for(Portal_Access__c eachRecord : listOfPortalAccesses){
                setOfGroupNames.add(eachRecord.Group_Developer_Name__c);
            }
            if(setOfGroupNames != null && !setOfGroupNames.isEmpty()){
                List<Group> listOfGroups = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName IN :setOfGroupNames];
                for(Group eachGroup : listOfGroups){
                    mapOfGroupNameVsGroupId.put(eachGroup.DeveloperName,eachGroup.Id);
                }
            }

            for(Portal_Access__c eachRecord : listOfPortalAccesses){
                Map<String,Id> mapOfCountryVsGroupId;
                if(!mapOfBrandVsCountryGroupIdMap.isEmpty() && mapOfBrandVsCountryGroupIdMap.containsKey(eachRecord.Brand_Name__c)){
                    mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(eachRecord.Brand_Name__c);
                    if(!mapOfCountryVsGroupId.containsKey(eachRecord.Country__c)){
                        if(mapOfGroupNameVsGroupId != null && !mapOfGroupNameVsGroupId.isEmpty() &&
                                            mapOfGroupNameVsGroupId.containsKey(eachRecord.Group_Developer_Name__c)){
                            mapOfCountryVsGroupId.put(eachRecord.Country__c,mapOfGroupNameVsGroupId.get(eachRecord.Group_Developer_Name__c));
                        }
                    }
                }else{
                    if(mapOfGroupNameVsGroupId != null && !mapOfGroupNameVsGroupId.isEmpty() &&
                                                    mapOfGroupNameVsGroupId.containsKey(eachRecord.Group_Developer_Name__c)){
                        mapOfCountryVsGroupId = new Map<String,Id>();
                        mapOfCountryVsGroupId.put(eachRecord.Country__c,mapOfGroupNameVsGroupId.get(eachRecord.Group_Developer_Name__c));
                        mapOfBrandVsCountryGroupIdMap.put(eachRecord.Brand_Name__c,mapOfCountryVsGroupId);
                    }
                }
            }
        }
        System.debug('mapOfBrandVsCountryGroupIdMap '+mapOfBrandVsCountryGroupIdMap.size());
        return mapOfBrandVsCountryGroupIdMap;
    }

    //Future methods to recalculate sharing
    @future
    public static void calculateSecondaryPartnerAcctShareFuture(Set<String> setOfBrandName,Set<String> setOfCountry){
        Map<Id,Account> MapOfPartnerAccountIds = new Map<Id,Account>([SELECT Id FROM Account WHERE RC_Brand__c IN :setOfBrandName
                                                                      AND billingCountry IN :setOfCountry AND Avaya_Partnership_Account__c = true
                                                                      AND type = 'Partner']);
        if(MapOfPartnerAccountIds != null && !MapOfPartnerAccountIds.isEmpty() && MapOfPartnerAccountIds.keySet() != null){
            Set<Id> setOfAccountIds = MapOfPartnerAccountIds.keySet();
            Sharing_AccountLeadHandler.handleAccountShare(setOfAccountIds);
            Quote_SharingHandler.handlePartnerQuoteSharingForAccount(setOfAccountIds);
        }
    }

    @future
    public static void calculateSecondaryCustomerAcctShareFuture(Set<String> setOfBrandName,Set<String> setOfCountry,String ObjName){
        Map<Id,Account> MapOfCustAccountIds = new Map<Id,Account>([SELECT Id FROM Account WHERE RC_Brand__c IN :setOfBrandName
                                                                   AND billingCountry IN :setOfCountry AND Avaya_Partnership_Account__c = true
                                                                   AND type = 'Customer']);
        if(MapOfCustAccountIds != null && !MapOfCustAccountIds.isEmpty() && MapOfCustAccountIds.keySet() != null){
            Set<Id> setOfAccountIds = MapOfCustAccountIds.keySet();
            if(ObjName=='Both'){
                Sharing_AccountLeadHandler.handleAccountShare(setOfAccountIds);
                Quote_SharingHandler.handlePartnerQuoteSharingForAccount(setOfAccountIds);
            }else if(ObjName=='Account'){
                Sharing_AccountLeadHandler.handleAccountShare(setOfAccountIds);
            }else if(ObjName=='Quote'){
                Quote_SharingHandler.handlePartnerQuoteSharingForAccount(setOfAccountIds);
            }
        }
    }

    @future
    public static void calculateSecondaryLeadShareFuture(Set<String> setOfBrandName,Set<String> setOfCountry){
        Map<Id,Lead> mapOfLeads = new Map<Id,Lead>([SELECT Id FROM Lead WHERE Avaya_Partnership_Lead__c = true AND
                                                    Lead_Brand_Name__c IN :setOfBrandName AND Country__c IN :setOfCountry]);
        if(mapOfLeads != null && !mapOfLeads.isEmpty() && mapOfLeads.keySet() != null){
            Sharing_AccountLeadHandler.handleLeadShare(mapOfLeads.keySet());
        }
    }

    @future
    public static void calculateSecondaryDealRegShareFuture(Set<String> setOfBrandName,Set<String> setOfCountry){
        Map<Id,Deal_Registration__c> mapOfDealReg = new Map<Id,Deal_Registration__c>([SELECT Id FROM Deal_Registration__c WHERE
                                                                                      Country__c IN :setOfCountry AND Brand_Name__c IN :setOfBrandName
                                                                                      AND Avaya_Partnership_Deal__c = true]);
        if(mapOfDealReg != null && !mapOfDealReg.isEmpty() && mapOfDealReg.keySet() != null){
            Quote_SharingHandler.handleDealRegistrationShare(mapOfDealReg.keySet());
        }
    }

    @future
    public static void calculateSecondaryDealSupportShareFuture(Set<String> setOfBrandName,Set<String> setOfCountry){
        Map<Id,Deal_support__c> mapOfDealSupport = new Map<Id,Deal_support__c>([SELECT Id FROM Deal_support__c WHERE
                                                (Lead__r.Lead_Brand_Name__c IN :setOfBrandName OR Customer_Account__r.RC_Brand__c IN :setOfBrandName
                                                OR Partner_Account__r.RC_Brand__c IN :setOfBrandName) AND
                                                (Lead__r.Country__c IN :setOfCountry OR Customer_Account__r.billingCountry IN :setOfCountry
                                                OR Partner_Account__r.billingCountry IN :setOfCountry)]);
        if(mapOfDealSupport != null && !mapOfDealSupport.isEmpty() && mapOfDealSupport.keySet() != null){
            Quote_SharingHandler.handleDealSupportShare(mapOfDealSupport.keySet());
        }
    }

}