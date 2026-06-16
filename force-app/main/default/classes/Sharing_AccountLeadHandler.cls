//Naresh Kumar  02/16/2020  Handles sharing for all the objects
global without sharing class Sharing_AccountLeadHandler {

    //Recalculate sharing if owner is changed - Trigger instance
    public static void handleAccountSharingOnOwnerChange(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        if(System.isFuture()) {
            return;
        }
        Set<Id> setOfAccountIds = new Set<Id>();
 Set<Id> setOfAccIds = new Set<Id>();
        Set<Id> setOfPartnerAccountIds = new Set<Id>();
        for(Id eachAccountId : newMap.keySet()) {
            Account objNewAccount = newMap.get(eachAccountId);
            if(objNewAccount.Avaya_Partnership_Account__c && (objNewAccount.ownerId != oldMap.get(eachAccountId).ownerId
                                                              || objNewAccount.Parent_Partner_Account__c != oldMap.get(eachAccountId).Parent_Partner_Account__c
                                                              || objNewAccount.Partner_Account__c != oldMap.get(eachAccountId).Partner_Account__c
                                                              || objNewAccount.Partner_Contact__c != oldMap.get(eachAccountId).Partner_Contact__c
                                                              || objNewAccount.Partner_Channel_Manager__c != oldMap.get(eachAccountId).Partner_Channel_Manager__c
                                                              || objNewAccount.Avaya_Partnership_Account__c != oldMap.get(eachAccountId).Avaya_Partnership_Account__c)){
                                                                  setOfAccountIds.add(eachAccountId);
                                                              }
if(!objNewAccount.Avaya_Partnership_Account__c &&
               (objNewAccount.Avaya_Partnership_Account__c != oldMap.get(eachAccountId).Avaya_Partnership_Account__c)){
                   setOfAccIds.add(eachAccountId);
               }
}
        // Check if running in batch context to avoid future method limitations
        Boolean isBatchContext = System.isBatch();
        
        if(!setOfAccountIds.isEmpty()) {
            if(isBatchContext) {
                // Call synchronous method in batch context
                Sharing_AccountLeadHandler.handleAccountShare(setOfAccountIds);
                Quote_SharingHandler.handlePartnerQuoteSharingForAccount(setOfAccountIds);
            } else {
                Sharing_AccountLeadHandler.handleAccountShareFuture(setOfAccountIds);
            }
        }
        if(!setOfAccIds.isEmpty()){
            if(isBatchContext) {
                // Call synchronous method in batch context
                Sharing_AccountLeadHandler.handleDeltaShare(setOfAccIds, 'Account');
            } else {
                Sharing_AccountLeadHandler.handleDeltaShareFuture(setOfAccIds, 'Account');
            }
        }


        //When CAM is changed for Partner Accts
        for(Id eachAccountId : setOfAccountIds){
            Account objNewAccount = newMap.get(eachAccountId);
            if(objNewAccount.Avaya_Partnership_Account__c && objNewAccount.Type.equalsIgnoreCase('Partner')
               && (objNewAccount.Partner_Channel_Manager__c != oldMap.get(eachAccountId).Partner_Channel_Manager__c)){
                   setOfPartnerAccountIds.add(eachAccountId);
               }
        }
        if(!setOfPartnerAccountIds.isEmpty()){
            if(isBatchContext) {
                // Call synchronous methods in batch context
                handleSharingOnCAMChange(setOfPartnerAccountIds,'Customer Accounts');
                handleSharingOnCAMChange(setOfPartnerAccountIds,'Leads');
                handleSharingOnCAMChange(setOfPartnerAccountIds,'Deal Registration');
                handleSharingOnCAMChange(setOfPartnerAccountIds,'Deal Support');
            } else {
                handleSharingOnCAMChangeFuture(setOfPartnerAccountIds,'Customer Accounts');
                handleSharingOnCAMChangeFuture(setOfPartnerAccountIds,'Leads');
                handleSharingOnCAMChangeFuture(setOfPartnerAccountIds,'Deal Registration');
                handleSharingOnCAMChangeFuture(setOfPartnerAccountIds,'Deal Support');
            }
        }
    }


    @future
    public static void handleAccountShareFuture(Set<Id> setOfAccountIds){
        handleAccountShare(setOfAccountIds);
        Quote_SharingHandler.handlePartnerQuoteSharingForAccount(setOfAccountIds);
    }

    public static void handleAccountShare(List<Account> listOfAccountsToShare){
        Set<Id> setOfAccountIds = new Set<Id>();
        for(Account eachAccount : listOfAccountsToShare){
            if(eachAccount.Avaya_Partnership_Account__c) {
                setOfAccountIds.add(eachAccount.id);
            }
        }
        handleAccountShare(setOfAccountIds);
    }

    public static void handleAccountShare(Set<Id> setOfAccountIds){
        List<AccountShare> listOfAccountShareToCreate = new List<AccountShare>();
        Set<String> SetOfUniqueAcctShareIds = new Set<String>();
        Map<Id, Deal_Registration__c> mapOfAccountIdVsDealReg = new Map<Id, Deal_Registration__c>();
        Map<Id, User> mapOfAccountIdVsPartnerContractUser = new Map<Id,User>();
        Set<Id> setOfPartnerContactIds = new Set<Id>();
        Map<Id,Id> mapOfPartnerContactIdVsUserId = new Map<Id,Id>();
        //secondary Portal Access - starts
        Set<Id> setOfAcctIdsForPortalAccess = new Set<Id>();
        Set<String> setOfCountryForGroupSharing = new Set<String>();
        Set<String> setOfBrandNameForGroupSharing = new Set<String>();
        //secondary Portal Access - ends

        //Avaya Cloud Specialist
        Set<Id> setOfCloudSpecialistContactIds=new Set<Id>();
        Map<Id,Id> mapOfCloudSpecialistContactUserId = new Map<Id,Id>();
        Set<Id> setOfOppIds=new Set<Id>();
        Map<Id, List<Opportunity>> mapOfAccountIdVsOpp = new Map<Id, List<Opportunity>>();

        System.debug('setOfAccountIds++ '+setOfAccountIds);
        List<Account> listOfAccounts = [SELECT Id, Avaya_Partnership_Account__c,Partner_Contact__c, RC_Brand__c,
                                        Parent_Partner_Account__r.Partner_Account__c,
                                        Parent_Partner_Account__c, 
                                        Parent_Partner_Account__r.Parent_Partner_Account__c,
                                        Parent_Partner_Account__r.Parent_Partner_Account__r.Parent_Partner_Account__c,
                                        Partner_Account__c,Type,
                                        Partner_Channel_Manager__c,Partner_Account__r.Partner_Channel_Manager__c,billingCountry
                                        FROM Account WHERE Id IN : setOfAccountIds];

        System.debug('listOfAccounts++'+listOfAccounts);

        List<Lead> listOfLeads = [SELECT Id,Deal_Registration__c,
                                  ConvertedAccountId,
                                  Deal_Registration__r.OwnerId,
                                  Deal_Registration__r.CreatedById
                                  FROM Lead
                                  WHERE ConvertedAccountId IN :setOfAccountIds];

        for(Lead eachLead : listOfLeads){
            Deal_Registration__c objDealReg = new Deal_Registration__c();
            objDealReg.OwnerId = eachLead.Deal_Registration__r.OwnerId;
            objDealReg.CreatedById = eachLead.Deal_Registration__r.CreatedById;
            mapOfAccountIdVsDealReg.put(eachLead.ConvertedAccountId, objDealReg);
        }


        //Get Cloud Specialists Contact Ids of Opp
        for(Opportunity opp:[Select Id,Name,Portal_Cloud_Specialist__c,AccountId from Opportunity where AccountId IN:setOfAccountIds]){
            if(opp!=null && opp.Portal_Cloud_Specialist__c !=null && opp.AccountId !=null &&
               string.valueOf(opp.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')){
                   setOfCloudSpecialistContactIds.add(opp.Portal_Cloud_Specialist__c);
                   if(mapOfAccountIdVsOpp.containsKey(opp.AccountId)) {
                       List<Opportunity> ListOfOpp = mapOfAccountIdVsOpp.get(opp.AccountId);
                       ListOfOpp.add(opp);
                       mapOfAccountIdVsOpp.put((opp.AccountId), ListOfOpp);
                   } else {
                       mapOfAccountIdVsOpp.put((opp.AccountId), new List<Opportunity> { opp });
                   }
               }
        }
        system.debug('mapOfAccountIdVsOpp--'+mapOfAccountIdVsOpp);

        Boolean skipAccountShare = true;
        Set<Id> setOfPartnerAccountIds = new Set<Id>();
        Set<Id> setOfPartnerAccountTmpIds = new Set<Id>();

        //Porting Changes - Including access for Partner Users
        Set<Id> setOfPartnerAccountIdsForUserRoleAccess = new Set<Id>();

        //framing account and it partner ids
        Map<Id,Set<Id>> mapOfAcctWithPartnerIds = new Map<Id,Set<id>>();
        Map<Id,String> mapOfAcctWithBrandName = new Map<Id,String>();
        Map<String,Community_Details__mdt> mapOfBrandAndMetaData = new Map<String,Community_Details__mdt>();
        //Single Login - starts
        Map<Id,Set<Id>> mapAccountToUAMUser = new Map<Id,Set<Id>>();
        Set<Id> setOfPartnerAccounts = new Set<Id>();
        //Single Login - ends

         //Porting Changes - Updated 23/09/20 - starts
         Map<String,Community_Details__mdt> communityDetailsMap = new Map<String,Community_Details__mdt>();
         communityDetailsMap = CommunityInfo.getAllCommunityDetails();
         //Porting Changes - Ends

        for(Account eachAccount : listOfAccounts){
            setOfPartnerAccountTmpIds = new Set<Id>();

            if(!eachAccount.Avaya_Partnership_Account__c) {
                continue;
            }
            if(eachAccount.Partner_Account__c != null){
                setOfPartnerAccountTmpIds.add(eachAccount.Partner_Account__c);
                setOfPartnerAccountIds.add(eachAccount.Partner_Account__c);
                //Single Login - starts
                if(eachAccount.Type == 'Customer') {
                    setOfPartnerAccounts.add(eachAccount.Partner_Account__c);
                }
                //Single Login - ends
                //Porting Changes - Self account access - Updated 23/09/20
                if(String.isNotBlank(eachAccount.RC_Brand__c) && communityDetailsMap!=null && communityDetailsMap.containsKey(eachAccount.RC_Brand__c)
                   && communityDetailsMap.get(eachAccount.RC_Brand__c).Is_Porting_Enabled__c){
                    setOfPartnerAccountTmpIds.add(eachAccount.Id);
                    setOfPartnerAccountIds.add(eachAccount.Id);
                }
            }
            if(eachAccount.Parent_Partner_Account__c != null){
                setOfPartnerAccountTmpIds.add(eachAccount.Parent_Partner_Account__c);
                setOfPartnerAccountIds.add(eachAccount.Parent_Partner_Account__c);
                 //Porting Changes - Self account access - Updated 23/09/20
                 if(String.isNotBlank(eachAccount.RC_Brand__c) && communityDetailsMap!=null && communityDetailsMap.containsKey(eachAccount.RC_Brand__c)
                 && communityDetailsMap.get(eachAccount.RC_Brand__c).Is_Porting_Enabled__c){
                    setOfPartnerAccountTmpIds.add(eachAccount.Id);
                    setOfPartnerAccountIds.add(eachAccount.Id);
                }
            }
            if(eachAccount.RC_Brand__c == 'Unify Office' && 
            eachAccount.Parent_Partner_Account__c != null && 
            eachAccount.Parent_Partner_Account__r.Partner_Account__c != null) {
                setOfPartnerAccountTmpIds.add(eachAccount.Parent_Partner_Account__r.Partner_Account__c);
                setOfPartnerAccountIds.add(eachAccount.Parent_Partner_Account__r.Partner_Account__c);
            }
            if(eachAccount.Partner_Contact__c != null){
                setOfPartnerContactIds.add(eachAccount.Partner_Contact__c);
            }
            if(eachAccount.Type == 'Customer' && eachAccount.Parent_Partner_Account__c != null && eachAccount.Parent_Partner_Account__r.Partner_Account__c!= null){
                    //This is the Top Master Id for Customer
                    setOfPartnerAccountTmpIds.add(eachAccount.Parent_Partner_Account__r.Partner_Account__c);
                    if(eachAccount.Type == 'Customer' && eachAccount.Parent_Partner_Account__c != null && eachAccount.Parent_Partner_Account__r.Parent_Partner_Account__c != null) {
                        setOfPartnerAccountTmpIds.add(eachAccount.Parent_Partner_Account__r.Parent_Partner_Account__c);
                        if(eachAccount.Parent_Partner_Account__r.Parent_Partner_Account__c != null && eachAccount.Parent_Partner_Account__r.Parent_Partner_Account__r.Parent_Partner_Account__c != null) {
                            setOfPartnerAccountTmpIds.add(eachAccount.Parent_Partner_Account__r.Parent_Partner_Account__r.Parent_Partner_Account__c);
                        }
                    }
               }
            //Including Partner Channel manager for sharing - starts
            if(eachAccount.Type == 'Customer'){
                if(eachAccount.Partner_Account__c!= null && eachAccount.Partner_Account__r.Partner_Channel_Manager__c != null){
                    setOfPartnerContactIds.add(eachAccount.Partner_Account__r.Partner_Channel_Manager__c);
                }
            }else if(eachAccount.Type == 'Partner'){
                if(eachAccount.Partner_Channel_Manager__c != null){
                    setOfPartnerContactIds.add(eachAccount.Partner_Channel_Manager__c);
                }
            //Porting Changes - Self account access - Updated 23/09/20
            if(String.isNotBlank(eachAccount.RC_Brand__c) && communityDetailsMap!=null && communityDetailsMap.containsKey(eachAccount.RC_Brand__c)
            && communityDetailsMap.get(eachAccount.RC_Brand__c).Is_Porting_Enabled__c){
                    setOfPartnerAccountIdsForUserRoleAccess.add(eachAccount.Id);
                }
            }
            //Including Partner Channel manager for sharing - ends

            //Including for secondary Portal Access - starts
            if(eachAccount.Type == 'Partner') {
                setOfAcctIdsForPortalAccess.add(eachAccount.Id);
            } else if(eachAccount.Type == 'Customer' && eachAccount.Partner_Account__c!= null) {
                setOfAcctIdsForPortalAccess.add(eachAccount.Partner_Account__c);
            }
            if(eachAccount.billingCountry != null) {
                setOfCountryForGroupSharing.add(eachAccount.billingCountry);
            }
            if(eachAccount.RC_Brand__c != null) {
                setOfBrandNameForGroupSharing.add(eachAccount.RC_Brand__c);
            }
            //Including for secondary Portal Access - ends

            mapOfAcctWithPartnerIds.put(eachAccount.id,setOfPartnerAccountTmpIds);
            mapOfAcctWithBrandName.put(eachAccount.id,eachAccount.RC_Brand__c);
            skipAccountShare = false;

        }
        System.debug('mapOfAcctWithPartnerIds++'+mapOfAcctWithPartnerIds);
        if(!setOfPartnerContactIds.isEmpty()){
            List<User> listOfPartnerContactUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN: setOfPartnerContactIds AND ContactId!=null];
            if(listOfPartnerContactUsers != null){
                for(User eachUser : listOfPartnerContactUsers){
                    if(setOfPartnerContactIds.contains(eachUser.ContactId)) {
                        mapOfPartnerContactIdVsUserId.put(eachUser.ContactId, eachUser.Id);
                    }

                }
            }
        }
        //Single Login code starts
        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>();
        listOfUAM = new List<User_Account_Mapping__c>([Select Id, Partner_Contact__c, Partner_User__c, Partner_Account__c
                                                       From User_Account_Mapping__c
                                                       Where (Partner_Account__c IN: setOfPartnerAccounts OR Partner_Account__c IN: setOfAccountIds)]);


        Set<Id> setUAMUsers = new Set<Id>();
        if(listOfUAM != null && !listOfUAM.isEmpty()){
            for(User_Account_Mapping__c uam : listOfUAM){
                if(mapAccountToUAMUser.containsKey(uam.Partner_Account__c)){
                    setUAMUsers=mapAccountToUAMUser.get(uam.Partner_Account__c);
                    setUAMUsers.add(uam.Partner_User__c);
                    mapAccountToUAMUser.put(uam.Partner_Account__c, setUAMUsers);
                }
                else{
                    setUAMUsers = new Set<Id>();
                    setUAMUsers.add(uam.Partner_User__c);
                    mapAccountToUAMUser.put(uam.Partner_Account__c, setUAMUsers);
                }
            }
        }
        System.debug('mapAccountToUAMUser++'+mapAccountToUAMUser);
        //Single Login code ends


        //Cloud Specialist Users and Mapping of Contact,User
        if(setOfCloudSpecialistContactIds!=null && !setOfCloudSpecialistContactIds.IsEmpty() && setOfCloudSpecialistContactIds.size()>0){
            List<User> listOfCloudSpecialistUsers=[Select Id,ContactId from user where ContactId IN: setOfCloudSpecialistContactIds and ContactId!=null];
            if(listOfCloudSpecialistUsers !=null && !listOfCloudSpecialistUsers.isEmpty() && listOfCloudSpecialistUsers.size()>0){
                for(User user:listOfCloudSpecialistUsers){
                    mapOfCloudSpecialistContactUserId.put(user.ContactId,user.Id);
                }
            }
            system.debug('mapOfCloudSpecialistContactUserId--'+mapOfCloudSpecialistContactUserId);
        }

        if(skipAccountShare) {
            return;
        }

        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroupsNew(setOfPartnerAccountIds,true);
        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;
        Map<Id,List<Id>> mapOfPartnerWithGroups = objWrapper.mapOfPartnerWithGroups;

        System.debug('mapOfPartnerWithGroups++'+mapOfPartnerWithGroups);
        Map<Id,List<Id>> mapOfAccountGroup = new Map<Id,List<Id>>();
        Set<Id> partnerIds = new Set<Id>();
        List<Id> groupIds = new List<Id>();
        for(Id accid : mapOfAcctWithPartnerIds.keySet()){
            partnerIds =  mapOfAcctWithPartnerIds.get(accid);
            groupIds = new List<Id>();
            for(Id partnerId : partnerIds){
                if(mapOfPartnerWithGroups!=null && !mapOfPartnerWithGroups.isEmpty() && mapOfPartnerWithGroups.get(partnerId)!=null){
                    groupIds.addall(mapOfPartnerWithGroups.get(partnerId));
                }
            }
            mapOfAccountGroup.put(accid,groupIds);
        }
        System.debug('mapOfAccountGroup++'+mapOfAccountGroup);

        //Porting Changes - Including access for Partner Users
        Map<Id,List<Id>> mapOfAccountGroupForPartnerUsers = getPartnerUsersAndGroupsForUserRoles(setOfPartnerAccountIdsForUserRoleAccess);
        System.debug('mapOfAccountGroupForPartnerUsers====>' + mapOfAccountGroupForPartnerUsers);

        //Including for secondary portal access - starts
        Map<Id,Set<Id>> mapOfAcctIdVsUserIdLst = SecondaryPortalAccessUtil.getUserIdListForPartnerAccts(setOfAcctIdsForPortalAccess);
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = SecondaryPortalAccessUtil.getGroupIdforCountry(setOfBrandNameForGroupSharing,setOfCountryForGroupSharing);
        //Including for secondary portal access - ends

        for(Account eachAccount : listOfAccounts){
            Id partnerContactUserId = mapOfPartnerContactIdVsUserId.get(eachAccount.Partner_Contact__c);

            if(partnerContactUserId != null){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = partnerContactUserId,
                                                                AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(partnerContactUserId));
            }

            //Including Partner Channel Manager for sharing - starts
            Id partnerChannelMgrUserId = null;
            if(eachAccount.Type == 'Customer'){
                if(eachAccount.Partner_Account__c!= null && eachAccount.Partner_Account__r.Partner_Channel_Manager__c != null){
                    partnerChannelMgrUserId = mapOfPartnerContactIdVsUserId.get(eachAccount.Partner_Account__r.Partner_Channel_Manager__c);
                }
            }else if(eachAccount.Type == 'Partner'){
                if(eachAccount.Partner_Channel_Manager__c != null){
                    partnerChannelMgrUserId = mapOfPartnerContactIdVsUserId.get(eachAccount.Partner_Channel_Manager__c);
                }
            }
            if(partnerChannelMgrUserId != null){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = partnerChannelMgrUserId,
                                                                AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(partnerChannelMgrUserId));
            }
            //Including Partner Channel manager for sharing - ends

            //Porting Changes - Including access for Partner Users - Starts
            if(null!=mapOfAccountGroupForPartnerUsers && null!=mapOfAccountGroupForPartnerUsers.get(eachAccount.id)){
                for(Id groupId : mapOfAccountGroupForPartnerUsers.get(eachAccount.id)){
                    listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = groupId,
                                                                    AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                    ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                    SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(groupId));
                }
            }
            //Porting Changes - Including access for Partner Users - Ends

            if(null!=mapOfAccountGroup && null!=mapOfAccountGroup.get(eachAccount.id)){
                for(Id groupId : mapOfAccountGroup.get(eachAccount.id)){
                    listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = groupId,
                                                                    AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                    ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                    SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(groupId));
                }
            }

            if(UserInfo.getUserType() != 'Standard'){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = UserInfo.getUserId(),
                                                                AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(UserInfo.getUserId()));
            }

            //Including for secondary portal access - starts
            if(mapOfAcctIdVsUserIdLst != null && !mapOfAcctIdVsUserIdLst.isEmpty()){
                Set<Id> setOfUserId = new Set<Id>();
                if(eachAccount.Type == 'Partner' && mapOfAcctIdVsUserIdLst.containsKey(eachAccount.Id)){
                    setOfUserId = mapOfAcctIdVsUserIdLst.get(eachAccount.Id);
                }else if(eachAccount.Type == 'Customer' && mapOfAcctIdVsUserIdLst.containsKey(eachAccount.Partner_Account__c)){
                    setOfUserId = mapOfAcctIdVsUserIdLst.get(eachAccount.Partner_Account__c);
                }
                if(!setOfUserId.isEmpty()){
                    for(Id userId : setOfUserId){
                        listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = userId,
                                                                        AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                        ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                        SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(userId));
                    }
                }
            }
            if(mapOfBrandVsCountryGroupIdMap != null && !mapOfBrandVsCountryGroupIdMap.isEmpty() &&
               mapOfBrandVsCountryGroupIdMap.containsKey(eachAccount.RC_Brand__c)){
                   Map<String,Id> mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(eachAccount.RC_Brand__c);
                   if(mapOfCountryVsGroupId != null && !mapOfCountryVsGroupId.isEmpty() &&
                      mapOfCountryVsGroupId.containsKey(eachAccount.billingCountry)){
                          listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id,
                                                                          UserOrGroupId = mapOfCountryVsGroupId.get(eachAccount.billingCountry),
                                                                          AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                          ContactAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                          SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(mapOfCountryVsGroupId.get(eachAccount.billingCountry)));
                      }
               }
            //Including for secondary portal access - ends
            //Access to Cloud Specialist
            if(mapOfCloudSpecialistContactUserId !=null && mapOfCloudSpecialistContactUserId.keySet() !=null && mapOfCloudSpecialistContactUserId.keySet().size()>0){
                Id cloudSpecialistUserId=null;
                if(mapOfAccountIdVsOpp !=null && mapOfAccountIdVsOpp.containsKey(eachAccount.Id)){
                    for(Opportunity opp: mapOfAccountIdVsOpp.get(eachAccount.Id)){
                        if(opp!=null && opp.Portal_Cloud_Specialist__c !=null){
                            cloudSpecialistUserId=mapOfCloudSpecialistContactUserId.get(opp.Portal_Cloud_Specialist__c);
                            if(cloudSpecialistUserId != null){
                                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id,
                                                                                UserOrGroupId = cloudSpecialistUserId,AccountAccessLevel = 'Edit',
                                                                                OpportunityAccessLevel = 'Edit',ContactAccessLevel = 'Edit',
                                                                                CaseAccessLevel='Edit'));
                                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(cloudSpecialistUserId));
                            }
                        }
                    }

                }
                system.debug('listOfAccountShareToCreate--'+listOfAccountShareToCreate);
            }

            //SingleLogin User Share starts
            if(eachAccount.Type=='Partner' && null!=mapAccountToUAMUser && null!=mapAccountToUAMUser.get(eachAccount.Id)){
                for(Id userId : mapAccountToUAMUser.get(eachAccount.Id)){
                    System.debug('userId++'+userId);
                    listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = userId,
                                                                    AccountAccessLevel = 'Edit',
                                                                    OpportunityAccessLevel = 'Edit',
                                                                    ContactAccessLevel = 'Edit',
                                                                    CaseAccessLevel='Edit'));
                    SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(userId));
                }
            }
            if(eachAccount.Type=='Customer' && null!=mapAccountToUAMUser && null!=mapAccountToUAMUser.get(eachAccount.Partner_Account__c)){
                for(Id userId : mapAccountToUAMUser.get(eachAccount.Partner_Account__c)){
                    System.debug('userId++'+userId);
                    listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccount.Id, UserOrGroupId = userId,
                                                                    AccountAccessLevel = 'Edit',
                                                                    OpportunityAccessLevel = 'Edit',
                                                                    ContactAccessLevel = 'Edit',
                                                                    CaseAccessLevel='Edit'));
                    SetOfUniqueAcctShareIds.add(String.valueOf(eachAccount.Id)+String.valueOf(userId));
                }
            }
            //SingleLogin User Share ends

        }
        //Share with Associated Deal Owner and Created on Owner Change
        if(!mapOfAccountIdVsDealReg.isEmpty()){
            for(Id eachAccountId : mapOfAccountIdVsDealReg.keySet()){
                Deal_Registration__c objDealReg = mapOfAccountIdVsDealReg.get(eachAccountId);
                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccountId, UserOrGroupId = objDealReg.OwnerId,
                                                                AccountAccessLevel = 'Edit',
                                                                OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit',
                                                                CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccountId)+String.valueOf(objDealReg.OwnerId));
                listOfAccountShareToCreate.add(new AccountShare(AccountId = eachAccountId, UserOrGroupId = objDealReg.CreatedById,
                                                                AccountAccessLevel = 'Edit',
                                                                OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit',
                                                                CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(eachAccountId)+String.valueOf(objDealReg.CreatedById));
            }
        }

        if(!listOfAccountShareToCreate.isEmpty()){
            List<AccountShare> listOfAccountSharesToDel = new List<AccountShare>();
            Set<String> setOfExistingAccountShares = new Set<String>();
            List<AccountShare> listOfAccountShareToInsert = new List<AccountShare>();
            //added for gsp ac
             Map<String,ID> mapOfAccessGroups = new map<String,ID>();
            SettingsService.AccessControlSettingsWrapper accessSettings = new SettingsService.AccessControlSettingsWrapper();
            if (accessSettings != null && accessSettings.allGroups != null) {
                mapOfAccessGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
            }
            
        	//added for gsp ac
        	List<AccountShare> listOfAccountShares = new List<AccountShare>();
            if (!mapOfAccessGroups.isEmpty()) {
                listOfAccountShares = [SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE AccountId =: setOfAccountIds
                                                          AND RowCause = 'Manual' AND UserOrGroupId NOT IN :mapOfAccessGroups.values()];
            } else {
                listOfAccountShares = [SELECT id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId =: setOfAccountIds
                                                          AND RowCause = 'Manual'];
            }
            //Form list of delta shares to delete
            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfAccountShares.isEmpty()){
                    for(AccountShare accShare : listOfAccountShares){
                        String tmp = String.valueOf(accShare.AccountId)+String.valueOf(accShare.UserOrGroupId);
                        if(!SetOfUniqueAcctShareIds.contains(tmp)){
                            listOfAccountSharesToDel.add(accShare);
                        }else{
                            setOfExistingAccountShares.add(String.valueOf(accShare.AccountId)+'-'+String.valueOf(accShare.UserOrGroupId));
                        }
                    }
                    Database.delete(listOfAccountSharesToDel, false);
                }

                //Form list of delta shares to insert
                if(!setOfExistingAccountShares.isEmpty()){
                    for(AccountShare eashAS : listOfAccountShareToCreate){
                        String tmp = String.valueOf(eashAS.AccountId)+'-'+String.valueOf(eashAS.UserOrGroupId);
                        if(!setOfExistingAccountShares.contains(tmp)) {
                            listOfAccountShareToInsert.add(eashAS);
                        }
                    }
                }
                if(!listOfAccountShareToInsert.isEmpty()) {
                    Database.insert(listOfAccountShareToInsert, false);
                } else {
                    Database.insert(listOfAccountShareToCreate, false);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
    }

    //Recalculate sharing for Lead, Deal Reg and Deal Supprot when CAM is change for Partner Acct.
    @future
    public static void handleSharingOnCAMChangeFuture(Set<Id> setOfPartnerAccountIds, String objName){
        handleSharingOnCAMChange(setOfPartnerAccountIds, objName);
    }
    
    //Synchronous version of handleSharingOnCAMChangeFuture for batch context
    public static void handleSharingOnCAMChange(Set<Id> setOfPartnerAccountIds, String objName){
        if(objName.equalsIgnoreCase('Leads')){
            Map<Id,Lead> MapOfLeadIds = new Map<Id,Lead>([Select Id from Lead where
                                                          Partner_Account__c IN :setOfPartnerAccountIds]);
            if(null!=MapOfLeadIds && null!=MapOfLeadIds.keySet() && MapOfLeadIds.keySet().size()>0) {
                Sharing_AccountLeadHandler.handleLeadShare(MapOfLeadIds.keySet());
            }
        }else if(objName.equalsIgnoreCase('Deal Registration')){
            Map<Id,Deal_Registration__c> MapOfDealRegIds = new Map<Id,Deal_Registration__c>([Select Id from Deal_Registration__c
                                                                                             where Partner_Account__c IN :setOfPartnerAccountIds]);
            if(null!=MapOfDealRegIds && null!=MapOfDealRegIds.keySet() && MapOfDealRegIds.keySet().size()>0) {
                Quote_SharingHandler.handleDealRegistrationShare(MapOfDealRegIds.keySet());
            }
        }else if(objName.equalsIgnoreCase('Deal Support')){
            Map<Id,Deal_support__c> MapOfDealSupportIds = new Map<Id,Deal_support__c>([Select Id,Lead__c,Customer_Account__c from Deal_support__c
                                                                                       where Partner_Account__c IN :setOfPartnerAccountIds OR
                                                                                       Lead__r.Partner_Account__c IN :setOfPartnerAccountIds OR
                                                                                       Customer_Account__r.Partner_Account__c IN :setOfPartnerAccountIds]);
            if(null!=MapOfDealSupportIds && null!=MapOfDealSupportIds.keySet() && MapOfDealSupportIds.keySet().size()>0) {
                System.debug('MapOfDealSupportIds '+MapOfDealSupportIds.keySet());
                Quote_SharingHandler.handleDealSupportShare(MapOfDealSupportIds.keySet());
            }
        }else if(objName.equalsIgnoreCase('Customer Accounts')){
            Map<Id,Account> MapOfAccountIds = new Map<Id,Account>([Select Id from Account
                                                                   where Type='Customer' AND Partner_Account__c IN :setOfPartnerAccountIds
                                                                   AND Avaya_Partnership_Account__c = true]);
            if(null!=MapOfAccountIds && null!=MapOfAccountIds.keySet() && MapOfAccountIds.keySet().size()>0) {
                Sharing_AccountLeadHandler.handleAccountShare(MapOfAccountIds.keySet());
                Quote_SharingHandler.handlePartnerQuoteSharingForAccount(MapOfAccountIds.keySet());
            }
        }
    }

    //Existing Lead sharing
    @future
    public static void handleExistingLeadShareFuture(Set<Id> setOfLeadIds){
        handleExistingLeadShare(setOfLeadIds);
    }

    public static void handleExistingLeadShare(Set<Id> setOfLeadIds){

        List<Lead> listOfLeads = [SELECT Avaya_Partnership_Lead__c, Partner_Account__c, Partner_Account__r.Partner_Account__c,
                                  Partner_Account__r.Parent_Partner_Account__c,Lead_Brand_Name__c
                                  FROM Lead WHERE id IN : setOfLeadIds];
        Set<Id> setOfPartnerAccountIds = new Set<Id>();
        for(Lead eachLead : listOfLeads){
            if(!eachLead.Avaya_Partnership_Lead__c || eachLead.Partner_Account__c == null) {
                continue;
            }
            setOfPartnerAccountIds.add(eachLead.Partner_Account__c);
            if(eachLead.Partner_Account__r.Partner_Account__c != null) {
                setOfPartnerAccountIds.add(eachLead.Partner_Account__r.Partner_Account__c);
            }
            if(eachLead.Partner_Account__r.Parent_Partner_Account__c != null) {
                setOfPartnerAccountIds.add(eachLead.Partner_Account__r.Parent_Partner_Account__c);
            }
        }

        if(setOfPartnerAccountIds.isEmpty()) {
            return;
        }

        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroups(setOfPartnerAccountIds, false);
        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;
        Map<String,Community_Details__mdt> communityDetailsMap = new Map<String,Community_Details__mdt>();
        communityDetailsMap = CommunityInfo.getAllCommunityDetails();

        List<LeadShare> listOfLeadSharesToCreate = new List<LeadShare>();
        for(Lead eachLead : listOfLeads){
            //Share with the Deal desk User
            listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                       UserOrGroupId = communityDetailsMap.get(eachLead.Lead_Brand_Name__c).Portal_Deal_Desk_User__c,
                                                       LeadAccessLevel = 'Edit'));

            //sharing to group
            for(Group eachGroup: listOfGroups){
                listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                           UserOrGroupId = eachGroup.id, LeadAccessLevel = 'Edit'));
            }
        }

        if(!listOfLeadSharesToCreate.isEmpty()){
            Database.insert(listOfLeadSharesToCreate, false);
        }
    }

    @future
    public static void handleLeadShareFuture(Set<Id> setOfLeadIds){
        handleLeadShare(setOfLeadIds);
    }

    public static void handleLeadShare(Set<Id> setOfLeadIds){
        List<Lead> listOfLeads = [SELECT id, Deal_Registration__c,Partner_Contact__c,Partner_Account__c, Partner_Account__r.Parent_Partner_Account__c, 
                                  Partner_Account__r.Partner_Channel_Manager__c, Lead_Brand_Name__c,
                                  Partner_Account__r.Partner_Account__c,Country__c,Portal_Cloud_Specialist__c,Strategic_Partner_RC_Owner__c
                                  FROM Lead WHERE id IN : setOfLeadIds];
        Set<Id> setOfDealRegIds = new Set<Id>();
        Set<Id> setOfPartnerContactIds = new Set<Id>();
        Set<String> SetOfUniqueLeadShareIds = new Set<String>();
        Map<Id,Id> mapOfDealRegIdVsDealRegOwnerId = new Map<Id, Id>();
        Map<Id,Id> mapOfDealRegIdVsDealRegCreatorId = new Map<Id, Id>();
        Map<Id,Id> mapOfPartnerContactIdVsUserId = new Map<Id,Id>();
        Map<String,Community_Details__mdt> communityDetailsMap = new Map<String,Community_Details__mdt>();
        //secondary Portal Access - starts
        Set<Id> setOfAcctIdsForPortalAccess = new Set<Id>();
        Set<String> setOfCountryForGroupSharing = new Set<String>();
        Set<String> setOfBrandNameForGroupSharing = new Set<String>();
        //secondary Portal Access - ends

        //Avaya Cloud Specialist
        Set<Id> setOfCloudSpecialistContactIds=new Set<Id>();
        Map<Id,Id> mapOfCloudSpecialistContactUserId = new Map<Id,Id>();

        Set<Id> setOfPartnerAccountIds = new Set<Id>();
        Set<Id> setOfPartnerAccountTmpIds = new Set<Id>(); //temp set for map population
        Map<Id,Set<Id>> mapOfLeadWithPartnerIds = new Map<Id,Set<Id>>();
        //Single Login - starts
        Map<Id,Set<Id>> mapLeadToUAMUser = new Map<Id,Set<Id>>();
        Map<Id,Id> mapPartnerToContact = new Map<Id,Id>();
        Map<Id,Id> mapOfContactToUser = new Map<Id,Id>();
        Set<Id> setOfPartnerContact = new Set<Id>();
        Map<Id,Id> mapLeadtoSRCO = new Map<Id,Id>();
        communityDetailsMap = CommunityInfo.getAllCommunityDetails();

        for(Lead eachLead : listOfLeads){
            setOfDealRegIds.add(eachLead.Deal_Registration__c);
            setOfPartnerAccountTmpIds = new Set<Id>();
            // If Deal isnt present for the lead, then to share it to partner accounts
            if(eachLead.Partner_Account__c != null){
                setOfPartnerAccountIds.add(eachLead.Partner_Account__c);
                setOfPartnerAccountTmpIds.add(eachLead.Partner_Account__c);
            }
            if(eachLead.Partner_Account__c != null && eachLead.Partner_Account__r.Partner_Account__c != null){
                setOfPartnerAccountIds.add(eachLead.Partner_Account__r.Partner_Account__c);
                setOfPartnerAccountTmpIds.add(eachLead.Partner_Account__r.Partner_Account__c);
            }
            if(eachLead.Lead_Brand_Name__c == 'Unify Office' && 
            eachLead.Partner_Account__c != null && 
            eachLead.Partner_Account__r.Parent_Partner_Account__c != null) {
                setOfPartnerAccountIds.add(eachLead.Partner_Account__r.Parent_Partner_Account__c);
                setOfPartnerAccountTmpIds.add(eachLead.Partner_Account__r.Parent_Partner_Account__c);                
            }
            if(null != communityDetailsMap && communityDetailsMap.containsKey(eachLead.Lead_Brand_Name__c)){
                setOfPartnerAccountIds.add(communityDetailsMap.get(eachLead.Lead_Brand_Name__c).Portal_Top_Master_Account_Id__c);
                setOfPartnerAccountTmpIds.add(communityDetailsMap.get(eachLead.Lead_Brand_Name__c).Portal_Top_Master_Account_Id__c);
            }

            if(null != eachLead.Partner_Contact__c){
                setOfPartnerContactIds.add(eachLead.Partner_Contact__c);
            }
            if (null != eachLead.Partner_Account__c && null != eachLead.Partner_Account__r.Partner_Channel_Manager__c) {
                setOfPartnerContactIds.add(eachLead.Partner_Account__r.Partner_Channel_Manager__c);
            }

            //Including for secondary Portal Access - starts
            if (null != eachLead.Partner_Account__c) {
                setOfAcctIdsForPortalAccess.add(eachLead.Partner_Account__c);
            }
            if(eachLead.Country__c != null) {
                setOfCountryForGroupSharing.add(eachLead.Country__c);
            }
            if(eachLead.Lead_Brand_Name__c != null) {
                setOfBrandNameForGroupSharing.add(eachLead.Lead_Brand_Name__c);
            }
            //Including for secondary Portal Access - ends

            //Set Of Cloud Specialist Contact Ids
            if(eachLead.Portal_Cloud_Specialist__c!=null &&  string.valueOf(eachLead.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')) {
                setOfCloudSpecialistContactIds.add(eachLead.Portal_Cloud_Specialist__c);
            }

            mapOfLeadWithPartnerIds.put(eachLead.Id,setOfPartnerAccountTmpIds); //map of Lead ids to set of partner account ids.
            //Single Login code starts
            if(eachLead.Partner_Contact__c != null){
                mapPartnerToContact.put(eachLead.Id,eachLead.Partner_Contact__c);
                setOfPartnerContact.add(eachLead.Partner_Contact__c);
            }
            //Single Login code ends
            //Strategic RC Owner Share starts
            if(eachLead.Strategic_Partner_RC_Owner__c != null){
                mapLeadtoSRCO.put(eachLead.Id,eachLead.Strategic_Partner_RC_Owner__c);
            }
            //Strategic RC Owner Share ends
        }
        system.debug('mapOfLeadWithPartnerIds>'+mapOfLeadWithPartnerIds);

        List<User> partnerContactUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN: setOfPartnerContactIds
                                          AND ContactId!=null];
        if(partnerContactUsers != null && !partnerContactUsers.isEmpty()){
            for(User eachUser : partnerContactUsers){
                if(setOfPartnerContactIds.contains(eachUser.ContactId)){
                    mapOfPartnerContactIdVsUserId.put(eachUser.ContactId, eachUser.Id);
                }
            }
        }
        //Single Login Experience code starts
        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>();
        if(setOfPartnerContact!= null && !setOfPartnerContact.isEmpty()){
            listOfUAM = new List<User_Account_Mapping__c>([Select Id, Partner_Contact__c, Partner_User__c
                                                           From User_Account_Mapping__c
                                                           Where Partner_Contact__c IN: setOfPartnerContact]);
        }
        Map<Id,Set<Id>> mapOfUAMContactUser = new Map<Id,Set<Id>>();
        Set<Id> setUAMUsers = new Set<Id>();
        for(User_Account_Mapping__c uam : listOfUAM){
            if(mapOfUAMContactUser.containsKey(uam.Partner_Contact__c)){
                setUAMUsers=mapOfUAMContactUser.get(uam.Partner_Contact__c);
                setUAMUsers.add(uam.Partner_User__c);
                mapOfUAMContactUser.put(uam.Partner_Contact__c, setUAMUsers);
            }
            else{
                setUAMUsers = new Set<Id>();
                setUAMUsers.add(uam.Partner_User__c);
                mapOfUAMContactUser.put(uam.Partner_Contact__c, setUAMUsers);
            }
        }

        if(mapPartnerToContact != null && !mapPartnerToContact.isEmpty()){
            for(Id leadId : mapPartnerToContact.keyset()){
                if(mapOfUAMContactUser != null && mapOfUAMContactUser.containsKey(mapPartnerToContact.get(leadId))){
                    mapLeadToUAMUser.put(leadId, mapOfUAMContactUser.get(mapPartnerToContact.get(leadId)));
                }
            }
        }
        //Single Login Experience code ends

       //Cloud Specialist Users and Mapping of Contact,User
        if(setOfCloudSpecialistContactIds!=null && !setOfCloudSpecialistContactIds.IsEmpty() && setOfCloudSpecialistContactIds.size()>0){
            List<User> listOfCloudSpecialistUsers=[Select Id,ContactId from user where ContactId IN: setOfCloudSpecialistContactIds AND ContactId!=null];
            if(listOfCloudSpecialistUsers !=null && !listOfCloudSpecialistUsers.isEmpty() && listOfCloudSpecialistUsers.size()>0){
                for(User user:listOfCloudSpecialistUsers){
                    mapOfCloudSpecialistContactUserId.put(user.ContactId,user.Id);
                }
            }
        }

        for(Deal_Registration__c eachDealReg : [SELECT Id, OwnerId,CreatedById FROM Deal_Registration__c
                                                WHERE Id IN : setOfDealRegIds]){
                                                    mapOfDealRegIdVsDealRegOwnerId.put(eachDealReg.Id, eachDealReg.OwnerId);
                                                    mapOfDealRegIdVsDealRegCreatorId.put(eachDealReg.Id, eachDealReg.CreatedById);
                                                }

        Map<Id, User> mapOfDealRegOwnerIdVsUser =  new Map<Id, User>([SELECT Id, ContactId,
                                                                      Contact.AccountId, Contact.Account.Partner_Account__c,
                                                                      Contact.Account.Parent_Partner_Account__c,
                                                                      Contact.Account.Parent_Partner_Account__r.Parent_Partner_Account__c
                                                                      FROM User WHERE Id IN : mapOfDealRegIdVsDealRegOwnerId.values() OR
                                                                      Id IN : mapOfDealRegIdVsDealRegCreatorId.values()]);


        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroupsNew(setOfPartnerAccountIds, false);
        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;
        Map<Id,List<Id>> mapOfPartnerWithGroups = objWrapper.mapOfPartnerWithGroups;

        System.debug('mapOfPartnerWithGroups++'+mapOfPartnerWithGroups);
        Map<Id,List<Id>> mapOfLeadGroup = new Map<Id,List<Id>>();

        Map<Id, List<User>> mapOfAccountIdVsUsers = new Map<Id, List<User>>();


        Set<Id> partnerIds = new Set<Id>();
        List<Id> groupIds = new List<Id>();
        for(Id leadid : mapOfLeadWithPartnerIds.keySet()){
            partnerIds =  mapOfLeadWithPartnerIds.get(leadid);
            groupIds = new List<Id>();
            for(Id partnerId : partnerIds){
                if(null!=mapOfPartnerWithGroups && null!=mapOfPartnerWithGroups.keySet() && mapOfPartnerWithGroups.keySet().size()>0
                   && mapOfPartnerWithGroups.containsKey(partnerId)){
                       groupIds.addall(mapOfPartnerWithGroups.get(partnerId));
                   }
            }
            mapOfLeadGroup.put(leadid,groupIds);
        }
        System.debug('mapOfLeadGroup++'+mapOfLeadGroup);

        for(User eachUser : listOfPartnerAccountUsers){
            if(mapOfAccountIdVsUsers.KeySet().contains(eachUser.Contact.AccountId)){
                mapOfAccountIdVsUsers.get(eachUser.Contact.AccountId).add(eachUser);
            } else {
                mapOfAccountIdVsUsers.put(eachUser.Contact.AccountId, new List<User>{eachUser});
            }
        }

        List<LeadShare> listOfLeadSharesToCreate = new List<LeadShare>();

        //Including for secondary portal access - starts
        Map<Id,Set<Id>> mapOfAcctIdVsUserIdLst = SecondaryPortalAccessUtil.getUserIdListForPartnerAccts(setOfAcctIdsForPortalAccess);
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = SecondaryPortalAccessUtil.getGroupIdforCountry(setOfBrandNameForGroupSharing,setOfCountryForGroupSharing);
        //Including for secondary portal access - ends

        for(Lead eachLead : listOfLeads){
            //Added by Girish
            Id partnerContactUserId = null;
            partnerContactUserId = mapOfPartnerContactIdVsUserId.get(eachLead.Partner_Contact__c);
            if(eachLead.Deal_Registration__c != null){
                Id dealRegOwnerId = mapOfDealRegIdVsDealRegOwnerId.get(eachLead.Deal_Registration__c);
                Id dealRegCreatorId = mapOfDealRegIdVsDealRegCreatorId.get(eachLead.Deal_Registration__c);
                User dealRegOwnerUser = mapOfDealRegOwnerIdVsUser.get(dealRegOwnerId);
                User dealCreatorUser = mapOfDealRegOwnerIdVsUser.get(dealRegCreatorId);


                if(dealRegOwnerUser != null && dealRegOwnerUser.ContactId != null){
                    // Share with current Deal Owner
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                               UserOrGroupId = dealRegOwnerUser.Id, LeadAccessLevel = 'Edit'));

                    // Share with current Deal Owner's Account --> Manager & Executive users
                    List<User> listOfDealOwnerAccountUsers = mapOfAccountIdVsUsers.get(dealRegOwnerUser.Contact.AccountId);
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(dealRegOwnerUser.Id));
                }

                if(dealCreatorUser != null && dealCreatorUser.ContactId != null){
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                               UserOrGroupId = dealCreatorUser.Id, LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(dealCreatorUser.Id));
                }
            }


            if(partnerContactUserId != null){
                listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                           UserOrGroupId = partnerContactUserId, LeadAccessLevel = 'Edit'));
                SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(partnerContactUserId));
            }
            //Added for Partner channel Manager
            if (null != eachLead.Partner_Account__c && null != eachLead.Partner_Account__r.Partner_Channel_Manager__c){
                Id partnerChannelMgrUserId = null;
                partnerChannelMgrUserId = mapOfPartnerContactIdVsUserId.get(eachLead.Partner_Account__r.Partner_Channel_Manager__c);

                if(partnerChannelMgrUserId != null){
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                               UserOrGroupId = partnerChannelMgrUserId, LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(partnerChannelMgrUserId));
                }
            }

            //Share with the Deal desk User
            if(null!=eachLead.Lead_Brand_Name__c && eachLead.Lead_Brand_Name__c!='BT Business' ){
                listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                           UserOrGroupId = communityDetailsMap.get(eachLead.Lead_Brand_Name__c).Portal_Deal_Desk_User__c,
                                                           LeadAccessLevel = 'Edit'));
                SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(communityDetailsMap.get(eachLead.Lead_Brand_Name__c).Portal_Deal_Desk_User__c));
            }else{
                listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                           UserOrGroupId = System.Label.Deal_Desk_User,
                                                           LeadAccessLevel = 'Edit'));
                SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(System.Label.Deal_Desk_User));
            }


            ////sharing to group - added 20th Aug, 2020
            if(null!=mapOfLeadGroup && null!=mapOfLeadGroup.get(eachLead.id)){
                for(Id groupId : mapOfLeadGroup.get(eachLead.id)){
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id, UserOrGroupId = groupId,
                                                               LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(groupId));
                }
            }

            //SingleLogin User Share starts
            if(null!=mapLeadToUAMUser && null!=mapLeadToUAMUser.get(eachLead.Id)){
                for(Id userId : mapLeadToUAMUser.get(eachLead.Id)){
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id, UserOrGroupId = userId,
                                                                LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(userId));
                }
            }
            //SingleLogin User Share ends
            //Strategic RC Owner Share starts
            if(null!=mapLeadtoSRCO && null!=mapLeadtoSRCO.get(eachLead.Id)){
                Id userId = mapLeadtoSRCO.get(eachLead.Id);
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id, UserOrGroupId = userId,
                                                                LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(userId));
            }
            //Strategic RC Owner Share ends
            //Access to Cloud Specialist
            if(mapOfCloudSpecialistContactUserId !=null && mapOfCloudSpecialistContactUserId.keySet() !=null && mapOfCloudSpecialistContactUserId.keySet().size()>0){
                Id cloudSpecialistUserId=null;
                cloudSpecialistUserId=mapOfCloudSpecialistContactUserId.get(eachLead.Portal_Cloud_Specialist__c);
                if(cloudSpecialistUserId != null){
                    listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                               UserOrGroupId = cloudSpecialistUserId, LeadAccessLevel = 'Edit'));
                    SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(cloudSpecialistUserId));
                }
            }

            //Including for secondary portal access - starts
            if(mapOfAcctIdVsUserIdLst != null && !mapOfAcctIdVsUserIdLst.isEmpty()){
                Set<Id> setOfUserId = new Set<Id>();
                if(eachLead.Partner_Account__c != null && mapOfAcctIdVsUserIdLst.containsKey(eachLead.Partner_Account__c)){
                    setOfUserId = mapOfAcctIdVsUserIdLst.get(eachLead.Partner_Account__c);
                }
                if(!setOfUserId.isEmpty()){
                    for(Id userId : setOfUserId){
                        listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                                   UserOrGroupId = userId, LeadAccessLevel = 'Edit'));
                        SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(userId));
                    }
                }
            }
            if(mapOfBrandVsCountryGroupIdMap != null && !mapOfBrandVsCountryGroupIdMap.isEmpty() &&
               mapOfBrandVsCountryGroupIdMap.containsKey(eachLead.Lead_Brand_Name__c)){
                   Map<String,Id> mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(eachLead.Lead_Brand_Name__c);
                   if(mapOfCountryVsGroupId != null && !mapOfCountryVsGroupId.isEmpty() &&
                      mapOfCountryVsGroupId.containsKey(eachLead.Country__c)){
                          listOfLeadSharesToCreate.add(new LeadShare(LeadId = eachLead.Id,
                                                                     UserOrGroupId = mapOfCountryVsGroupId.get(eachLead.Country__c),
                                                                     LeadAccessLevel = 'Edit'));
                          SetOfUniqueLeadShareIds.add(String.valueOf(eachLead.Id)+String.valueOf(mapOfCountryVsGroupId.get(eachLead.Country__c)));
                      }
               }
            //Including for secondary portal access - ends
        }
       

        //Added for PCM starts
        if(!listOfLeadSharesToCreate.isEmpty()){
             //added for gsp ac
             Map<String,ID> mapOfAccessGroups = new map<String,ID>();
            SettingsService.AccessControlSettingsWrapper accessSettings = new SettingsService.AccessControlSettingsWrapper();
			if (accessSettings != null && accessSettings.allGroups != null) {
                mapOfAccessGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
            }
        
        	//added for gsp ac
        	List<LeadShare> listOfLeadShares = new List<LeadShare>();
            if (!mapOfAccessGroups.isEmpty()) {
                listOfLeadShares = [SELECT Id, LeadId, UserOrGroupId FROM LeadShare WHERE LeadId =: setOfLeadIds
                                                AND RowCause = 'Manual' AND UserOrGroupId NOT IN :mapOfAccessGroups.values()];
            } else {
                listOfLeadShares = [SELECT id,LeadId,UserOrGroupId FROM LeadShare WHERE LeadId =: setOfLeadIds
                                                AND RowCause = 'Manual'];
            }
            
            List<LeadShare> listOfLeadSharesToDel = new List<LeadShare>();
            List<LeadShare> listOfLeadShareToInsert = new List<LeadShare>();
            Set<String> tmpSetOfLeadShare = new Set<String>();
            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfLeadShares.isEmpty()){
                    for(LeadShare ls : listOfLeadShares){
                        String tmp = String.valueOf(ls.LeadId)+String.valueOf(ls.UserOrGroupId);
                        if(!SetOfUniqueLeadShareIds.contains(tmp)){
                            listOfLeadSharesToDel.add(ls);
                        }else{
                            tmpSetOfLeadShare.add(String.valueOf(ls.LeadId)+'-'+String.valueOf(ls.UserOrGroupId));
                        }
                    }
                    Database.delete(listOfLeadSharesToDel, false);
                }
                if(!tmpSetOfLeadShare.isEmpty()){
                    for(LeadShare eashLS : listOfLeadSharesToCreate){
                        String tmp = String.valueOf(eashLS.LeadId)+'-'+String.valueOf(eashLS.UserOrGroupId);
                        if(!tmpSetOfLeadShare.contains(tmp)) {
                            listOfLeadShareToInsert.add(eashLS);
                        }
                    }
                }
                if(!listOfLeadShareToInsert.isEmpty()) {
                    Database.insert(listOfLeadShareToInsert, false);
                } else {
                    Database.insert(listOfLeadSharesToCreate, false);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
        //Added for PCM Ends

    }

    //Recalculate sharing if owner is changed
    public static void handleLeadSharingOnOwnerChange(Map<Id, Lead> newMap, Map<Id, Lead> oldMap) {
        Set<Id> setOfLeadIds = new Set<Id>();
        Set<Id> setOfLeads = new Set<Id>();
        for(Id eachLeadId : newMap.keySet()) {
            Lead objLead = newMap.get(eachLeadId);
            if(objLead.Avaya_Partnership_Lead__c && (objLead.ownerId != oldMap.get(eachLeadId).ownerId
                                                     || objLead.Avaya_Partnership_Lead__c != oldMap.get(eachLeadId).Avaya_Partnership_Lead__c
                                                     || objLead.Portal_Cloud_Specialist__c != oldMap.get(eachLeadId).Portal_Cloud_Specialist__c
                                                     || objLead.Strategic_Partner_RC_Owner__c != oldMap.get(eachLeadId).Strategic_Partner_RC_Owner__c)){
                                                             setOfLeadIds.add(eachLeadId);
                                                         }
            if(!objLead.Avaya_Partnership_Lead__c &&
                (objLead.Avaya_Partnership_Lead__c != oldMap.get(eachLeadId).Avaya_Partnership_Lead__c)){
                    setOfLeads.add(eachLeadId);
                }
            }

            if(!setOfLeadIds.isEmpty()) {
                if(System.isBatch()) {
                    Sharing_AccountLeadHandler.handleLeadShare(setOfLeadIds);
                } else {
                    Sharing_AccountLeadHandler.handleLeadShareFuture(setOfLeadIds);
                }
            }
            if(!setOfLeads.isEmpty()){
                Sharing_AccountLeadHandler.handleDeltaShareFuture(setOfLeads, 'Lead');
            }
    }

    webservice static void sharingAOCOnLeadConvertService(Id leadId){
        try{
            sharingAOCOnLeadConvertFuture(leadId);
        }
        catch (Exception excp){
        if (System.isBatch() || System.isFuture()) {
            sharingAOCOnLeadConvert(leadId);
        } else {
            sharingAOCOnLeadConvertFuture1(leadId);
        }
        }
    }

    public static void sharingAOCOnLeadConvertFuture(Id leadId){
        //Added if else condition for Automate Lead Convert for ACO 3.0
        Lead objLead = [SELECT Id, Avaya_Partnership_Lead__c,ConvertedAccountId,ConvertedContactId FROM Lead WHERE id =: leadId];
        if(!objLead.Avaya_Partnership_Lead__c) {
            return;
        }

        String accountId = objLead.ConvertedAccountId;
        String contactId = objLead.ConvertedContactId;
        AccountContactRole objAcctContactRole = new AccountContactRole();
        objAcctContactRole.AccountId = accountId;
        objAcctContactRole.ContactId = contactId;
        objAcctContactRole.Role = 'Business User';

        insert objAcctContactRole;
        if(System.isBatch() || System.isFuture()) {
            sharingAOCOnLeadConvert(leadId);
        } else {
            sharingAOCOnLeadConvertFuture1(leadId);
        }
    }
    //Account/Opportunity/Contact sharing on lead convert
    @future(callout=true)
    public static void sharingAOCOnLeadConvertFuture1(Id leadId){
        sharingAOCOnLeadConvert(leadId);
    }

    public static void sharingAOCOnLeadConvert(Id leadId){

        //Added Is_RFP_Needed__c for ALE
        //Removed Is_RFP_Needed__c for BZS-4808
        Lead objLead = [SELECT Id, Deal_Registration__c, Avaya_Partnership_Lead__c, Partner_Contact__c,
                        ConvertedAccountId, Partner_Account__c,Partner_Account__r.Partner_Account__c,VAR_Territory__c,
                        Partner_Account__r.Parent_Partner_Account__c,Sales_Notes__c,SID__c,Inside_Sales_Rep__c,
                        ConvertedContactId, ConvertedOpportunityId,Avaya_Cloud_Specialist__c,RC_Overlay__c,
                        IsNamedAccount__c,OwnerId,Partner_Account__r.Partner_Channel_Manager__c,Lead_Brand_Name__c,
                        Is_Billing__c,Number_of_Users__c,Description,convertedAccount.partner_id__c,Portal_Lead__c,
                        convertedAccount.partner_account__r.partner_id__c,Country__c,Portal_Cloud_Specialist__c,
                        Ignite_Lead__c,Ignite_AE__c,Forecasted_RingCentral_Video_Users__c, Lead_Tier_Name__c,Strategic_Partner_RC_Owner__c,BusinessIdentity__c,Partner_Type__c,Estimated_Close_Date__c,Partners_CRM_Opporunity_ID__c,NumberOfEmployees__c 
                        FROM Lead WHERE id =: leadId];

        system.debug('objLead - '+ objLead);

        if(!objLead.Avaya_Partnership_Lead__c) {
            return;
        }

        String dealRegistrationId = objLead.Deal_Registration__c;
        String accountId = objLead.ConvertedAccountId;
        String opportunityId = objLead.ConvertedOpportunityId;
        String contactId = objLead.ConvertedContactId;
        String partnerId = '';
        if(objLead != null && objLead.convertedAccount != null && objLead.convertedAccount.partner_id__c != null){
            partnerId = objLead.convertedAccount.partner_id__c;
        }else if(objLead != null && objLead.convertedAccount != null && objLead.convertedAccount.partner_account__c != null &&
                 objLead.convertedAccount.partner_account__r.partner_Id__c != null){
                     partnerId = objLead.convertedAccount.partner_account__r.partner_Id__c;
                 }
        Decimal est12MonthBooking=0.0;
        Decimal est12MonthVideoBooking=0.0;

        //Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        Map<String,Community_Details__mdt> communityDetailsMap = new Map<String,Community_Details__mdt>();
        communityDetailsMap = CommunityInfo.getAllCommunityDetails();
        //Added by Girish - For Master Agent inclusion
if(objLead!=null && objLead.Lead_Brand_Name__c!=null){
            if(null != communityDetailsMap && communityDetailsMap.containsKey(objLead.Lead_Brand_Name__c) &&
              communityDetailsMap.get(objLead.Lead_Brand_Name__c).Estimated_12M_Booking_Standard__c !=null){
                    est12MonthBooking=objLead.Number_of_Users__c> 0 ? objLead.Number_of_Users__c * communityDetailsMap.get(objLead.Lead_Brand_Name__c).Estimated_12M_Booking_Standard__c : 0.0;
            }
        }

        //Strategic RC Owner Share starts
        Map<Id,Id> mapOpptoSRCO = new Map<Id,Id>();
        if(objLead.Strategic_Partner_RC_Owner__c != null){
            mapOpptoSRCO.put(objLead.Id,objLead.Strategic_Partner_RC_Owner__c);
        }
        //Strategic RC Owner Share ends

        List<Account> accLstForUpt;
        try {
            accLstForUpt = [select id,Avaya_Partnership_Account__c,Deal_Registration__c,RC_Brand__c,Partner_Account__c,
                                      VAR_Territory__c,Sales_Notes__c,Sid__c,Inside_Sales_Rep__c,Parent_Partner_Account__c,IsNamedAccount__c,Partner_Contact__c,OwnerId, Portal_Account__c from Account where id =: objLead.ConvertedAccountId for update];
        } catch(Exception e) {
            sharingAOCOnLeadConvert(leadId);
        }

        Account objConvertedAccount = null;
        if(accLstForUpt != null && accLstForUpt.size() >0){
            accLstForUpt[0].Id = objLead.ConvertedAccountId;
            accLstForUpt[0].Avaya_Partnership_Account__c = true;
            accLstForUpt[0].Deal_Registration__c = objLead.Deal_Registration__c;
            accLstForUpt[0].RC_Brand__c = objLead.Lead_Brand_Name__c;
            accLstForUpt[0].Partner_Account__c = objLead.Partner_Account__c;
            accLstForUpt[0].VAR_Territory__c = objLead.VAR_Territory__c;
            accLstForUpt[0].Sales_Notes__c = objLead.Sales_Notes__c;
            accLstForUpt[0].Sid__c = objLead.SID__c;
            accLstForUpt[0].Inside_Sales_Rep__c =  objLead.Inside_Sales_Rep__c;
            accLstForUpt[0].Parent_Partner_Account__c = objLead.Partner_Account__r.Partner_Account__c;
            accLstForUpt[0].IsNamedAccount__c = objLead.IsNamedAccount__c;
            accLstForUpt[0].Partner_Contact__c = objLead.Partner_Contact__c;
            accLstForUpt[0].OwnerId = objLead.OwnerId;
            accLstForUpt[0].Portal_Account__c=objLead.Portal_Lead__c;
            accLstForUpt[0].Partner_Type__c=objLead.Partner_Type__c;// Added for JIRA BZS - 6286
            accLstForUpt[0].BusinessIdentity__c=objLead.BusinessIdentity__c;// Added for JIRA BZS - 6286
            Database.update(accLstForUpt[0]);
            objConvertedAccount  = accLstForUpt[0];
        }
        List<Contact> contactLstForUpt;
        try {
            contactLstForUpt = [select id,Avaya_Partnership_Contact__c,Marketo_Sync_Disabled__c,OwnerId,Portal_Contact__c from contact where id =: objLead.OwnerId for update];
        } catch (Exception e) {
            sharingAOCOnLeadConvert(leadId);
        }
        
        if(contactLstForUpt != null && contactLstForUpt.size() > 0){
            contactLstForUpt[0].Avaya_Partnership_Contact__c = true;
            contactLstForUpt[0].Marketo_Sync_Disabled__c = true;
            contactLstForUpt[0].Id = contactId;
            contactLstForUpt[0].OwnerId = objLead.OwnerId;
            contactLstForUpt[0].Portal_Contact__c=objLead.Portal_Lead__c;
            Database.update(contactLstForUpt[0]);
        }

        //Added RFP__c for ALE
        //REmoved RFP__c for BZS-4808
        List<Opportunity> oppLstForUpt;
        try {
            oppLstForUpt = [select id,Partner_Account__c,Avaya_Partnership_Opportunity__c,
                                          Deal_Registration__c,Sid__c,Portal_Opportunity__c,
                                          Inside_Sales_Rep__c,Primary_Opportunity_Contact__c,Sales_Notes__c,IsNamedAccount__c,
                                          Avaya_Cloud_Specialist__c,RC_Overlay__c,Description,Brand_Name__c,
                                          Partner_Contact__c,RecordTypeId,Ignite_Opportunity__c,OwnerId,Portal_Cloud_Specialist__c,Strategic_Partner_RC_Owner__c,
                                          Is_Billing_Opportunity__c,X12_Month_Booking__c,Ignite_AE__c,Forecasted_RingCentral_Video_Users__c,Estimated_12M_RingCentral_Video_Pipeline__c,Tier_Name__c, CloseDate,Partners_CRM_Opporunity_ID__c  
                                          from Opportunity where id =: objLead.ConvertedOpportunityId for update];
        } catch(Exception e) {
            sharingAOCOnLeadConvert(leadId);
        }
        
        Opportunity objConvertedOpportunity = null;
        if(oppLstForUpt != null && oppLstForUpt.size() > 0){
            oppLstForUpt[0].Id = objLead.ConvertedOpportunityId;
            oppLstForUpt[0].Partner_Account__c = objLead.Partner_Account__c;
            oppLstForUpt[0].Avaya_Partnership_Opportunity__c =  true;
            oppLstForUpt[0].Deal_Registration__c =objLead.Deal_Registration__c ;
            oppLstForUpt[0].Sid__c = objLead.SID__c;
            oppLstForUpt[0].Inside_Sales_Rep__c= objLead.Inside_Sales_Rep__c;
            oppLstForUpt[0].Primary_Opportunity_Contact__c = objLead.ConvertedContactId;
            oppLstForUpt[0].Sales_Notes__c = objLead.Sales_Notes__c;
            oppLstForUpt[0].IsNamedAccount__c = objLead.IsNamedAccount__c;
            oppLstForUpt[0].Avaya_Cloud_Specialist__c = objLead.Avaya_Cloud_Specialist__c;
            oppLstForUpt[0].RC_Overlay__c = objLead.RC_Overlay__c;
            oppLstForUpt[0].Description = objLead.Description;
            oppLstForUpt[0].Brand_Name__c = objLead.Lead_Brand_Name__c;
            oppLstForUpt[0].Partner_Contact__c = objLead.Partner_Contact__c ;
            oppLstForUpt[0].RecordTypeId = OpportunityHelper.RT_ID_VAR_OPPORTUNITY;
            oppLstForUpt[0].OwnerId = objLead.OwnerId;
            oppLstForUpt[0].Is_Billing_Opportunity__c  = true;
            oppLstForUpt[0].X12_Month_Booking__c  = est12MonthBooking;
            oppLstForUpt[0].Portal_Cloud_Specialist__c = objLead.Portal_Cloud_Specialist__c;
            oppLstForUpt[0].type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
            oppLstForUpt[0].Portal_Opportunity__c=objLead.Portal_Lead__c;
            oppLstForUpt[0].Ignite_AE__c=objLead.Ignite_AE__c;
            oppLstForUpt[0].Partners_CRM_Opporunity_ID__c=objLead.Partners_CRM_Opporunity_ID__c; //added for PRM-83
            if(objLead.Forecasted_RingCentral_Video_Users__c !=null){
                oppLstForUpt[0].Estimated_12M_RingCentral_Video_Pipeline__c = est12MonthVideoBooking;
                oppLstForUpt[0].Forecasted_RingCentral_Video_Users__c=objLead.Forecasted_RingCentral_Video_Users__c;
            }


            oppLstForUpt[0].Tier_Name__c=objLead.Lead_Tier_Name__c;
            oppLstForUpt[0].Strategic_Partner_RC_Owner__c=objLead.Strategic_Partner_RC_Owner__c; //Avaya
            oppLstForUpt[0].CloseDate = objLead.Estimated_Close_Date__c;
            oppLstForUpt[0].Number_of_Employees__c = objLead.NumberOfEmployees__c;
            Database.update(oppLstForUpt[0]);
            objConvertedOpportunity = oppLstForUpt[0];
        }



        if(dealRegistrationId == null) {
            return;
        }
        // Collect all Deal Registration Owner Ids
        Deal_Registration__c objDealReg = [SELECT id, OwnerId,CreatedById FROM Deal_Registration__c
                                           WHERE Id = :dealRegistrationId];

        List<User> partnerContactUser=new List<User>();
        List<User> partnerChannelMgrUser=new List<User>();
        List<User> listOfCloudSpecialistUsers=new List<User>();//Cloud Specialist Users

        //Get the Partner Contact's User Id
        Id partnerContactUserId = null;
        if(null!=objLead && null!=objLead.Partner_Contact__c){
            partnerContactUser = [Select id from User Where ContactId=:objLead.Partner_Contact__c AND ContactId!=null];
            if(partnerContactUser!=null && !partnerContactUser.isEmpty() &&partnerContactUser.size()>0){
                partnerContactUserId = partnerContactUser[0].id;
            }
        }

        //Get the Partner Channel Manager's User Id
        Id partnerChannelMgrUserId = null;
        if(null!=objLead && null!=objLead.Partner_Account__c && null!=objLead.Partner_Account__r.Partner_Channel_Manager__c){
            partnerChannelMgrUser = [Select id from User Where ContactId=:objLead.Partner_Account__r.Partner_Channel_Manager__c AND ContactId!=null];
            if(partnerChannelMgrUser !=null && !partnerChannelMgrUser.isEmpty() &&partnerChannelMgrUser.size()>0){
                partnerChannelMgrUserId = partnerChannelMgrUser[0].id;
            }
        }

        //Including for secondary Portal Access - starts
        Set<Id> setOfAcctIdsForPortalAccess = new Set<Id>();
        if(objLead.Partner_Account__c != null) {
            setOfAcctIdsForPortalAccess.add(objLead.Partner_Account__c);
        }
        Map<Id,Set<Id>> mapOfAcctIdVsUserIdLst = SecondaryPortalAccessUtil.getUserIdListForPartnerAccts(setOfAcctIdsForPortalAccess);

        Set<String> setOfCountryForGroupSharing = new Set<String>();
        Set<String> setOfBrandNameForGroupSharing = new Set<String>();
        if(objLead.Country__c != null) {
            setOfCountryForGroupSharing.add(objLead.Country__c);
        }
        if(objLead.Lead_Brand_Name__c != null) {
            setOfBrandNameForGroupSharing.add(objLead.Lead_Brand_Name__c);
        }
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = SecondaryPortalAccessUtil.getGroupIdforCountry(setOfBrandNameForGroupSharing,setOfCountryForGroupSharing);
        //Including for secondary Portal Access - ends

        //Get Cloud Specialist User
        Id cloudSpecialistUserId=null;
        if(objConvertedOpportunity !=null && objConvertedOpportunity.Portal_Cloud_Specialist__c != null &&
           string.valueOf(objConvertedOpportunity.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')){
               listOfCloudSpecialistUsers=[Select Id,ContactId from user where ContactId =:objConvertedOpportunity.Portal_Cloud_Specialist__c AND ContactId!=null];
               if(listOfCloudSpecialistUsers !=null && !listOfCloudSpecialistUsers.isEmpty() && listOfCloudSpecialistUsers.size()>0){
                   cloudSpecialistUserId=listOfCloudSpecialistUsers[0].Id;
               }
           }
        system.debug('cloudSpecialistUserId--'+cloudSpecialistUserId);

        // Fetch Deal Registration Owner Ids User Information with Contact & Account detals into Map
        Map<Id, User> mapOfDealRegOwnerIdVsUser =  new Map<Id, User>([SELECT Id, ContactId,
                                                                      Contact.AccountId,
                                                                      Contact.Account.Partner_Account__c,
                                                                      Contact.Account.Parent_Partner_Account__c,
                                                                      Contact.Account.Parent_Partner_Account__r.Parent_Partner_Account__c
                                                                      FROM User
                                                                      WHERE Id = :objDealReg.OwnerId OR
                                                                      Id = :objDealReg.CreatedById]);
        system.debug('mapOfDealRegOwnerIdVsUser-->'+mapOfDealRegOwnerIdVsUser.values());
        // Collect all Deal Owner User and Parent Partner Account Ids
        Set<Id> setOfPartnerAccountIds = new Set<Id>();

        if(objLead.Partner_Account__c != null){
            setOfPartnerAccountIds.add(objLead.Partner_Account__c);
            if(objLead.Partner_Account__r.Partner_Account__c != null){
                setOfPartnerAccountIds.add(objLead.Partner_Account__r.Partner_Account__c);
            }
            if(objLead.Partner_Account__r.Parent_Partner_Account__c != null){
                setOfPartnerAccountIds.add(objLead.Partner_Account__r.Parent_Partner_Account__c);
            }
        }
        if(null != communityDetailsMap && communityDetailsMap.containsKey(objLead.Lead_Brand_Name__c)){
            setOfPartnerAccountIds.add(communityDetailsMap.get(objLead.Lead_Brand_Name__c).Portal_Top_Master_Account_Id__c);
        }

        //Single Login Experience code starts
        Map<Id,Set<Id>> mapAccountToUAMUser = new Map<Id,Set<Id>>();
        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>();
        listOfUAM = new List<User_Account_Mapping__c>([Select Id, Partner_Contact__c, Partner_User__c, Partner_Account__c
                                                       From User_Account_Mapping__c
                                                       Where Partner_Account__c =: objLead.Partner_Account__c]);

        system.debug('listOfUAM>'+listOfUAM);
        Set<Id> setUAMUsers = new Set<Id>();
        if(listOfUAM != null && !listOfUAM.isEmpty()){
            for(User_Account_Mapping__c uam : listOfUAM){
                if(mapAccountToUAMUser.containsKey(uam.Partner_Account__c)){
                    system.debug('inside if>'+mapAccountToUAMUser);
                    setUAMUsers=mapAccountToUAMUser.get(uam.Partner_Account__c);
                    setUAMUsers.add(uam.Partner_User__c);
                    mapAccountToUAMUser.put(uam.Partner_Account__c, setUAMUsers);
                }
                else{
                    system.debug('inside else>');
                    setUAMUsers = new Set<Id>();
                    setUAMUsers.add(uam.Partner_User__c);
                    mapAccountToUAMUser.put(uam.Partner_Account__c, setUAMUsers);
                }
            }
        }
        System.debug('mapAccountToUAMUser++'+mapAccountToUAMUser);
        //Single Login Experience code ends

        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroups(setOfPartnerAccountIds, false);
        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;

        Map<Id, List<User>> mapOfAccountIdVsUsers = new Map<Id, List<User>>();
        for(User eachUser : listOfPartnerAccountUsers){
            if(mapOfAccountIdVsUsers.KeySet().contains(eachUser.Contact.AccountId)){
                mapOfAccountIdVsUsers.get(eachUser.Contact.AccountId).add(eachUser);
            } else {
                mapOfAccountIdVsUsers.put(eachUser.Contact.AccountId, new List<User>{eachUser});
            }
        }

        List<AccountShare> listOfAccountShareToCreate = new List<AccountShare>();
        User dealRegOwnerUser = mapOfDealRegOwnerIdVsUser.get(objDealReg.OwnerId);
        User dealCreatorUser = mapOfDealRegOwnerIdVsUser.get(objDealReg.CreatedById);
        Set<String> SetOfUniqueAcctShareIds = new Set<String>();

        if(dealRegOwnerUser.ContactId != null){
            //Share with current Deal Owner
            listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = dealRegOwnerUser.Id,
                                                     AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit',
                                                     OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
            SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(dealRegOwnerUser.Id));

            //Share with current Deal creator
            listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = dealCreatorUser.Id,
                                                     AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit',
                                                     OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
            SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(dealCreatorUser.Id));

            //Share with Partner Contact User
            if(null!=partnerContactUserId){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = partnerContactUserId,
                                                         AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit',
                                                         OpportunityAccessLevel = 'Edit',CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(partnerContactUserId));
            }
            //Share with Partner Channel Mgr User
            if(null!=partnerChannelMgrUserId){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = partnerChannelMgrUserId,
                                                         AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit',
                                                         OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(partnerChannelMgrUserId));
            }

            //Access to Cloud Specialist
            if(cloudSpecialistUserId != null){
                listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = cloudSpecialistUserId,
                                                         AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit',
                                                         OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(cloudSpecialistUserId));
                system.debug('listOfAccountShareToCreate'+listOfAccountShareToCreate);
            }
            // Share with current Deal Owner's Account --> Manager & Executive users
            List<User> currentDealOwnerAccountUsers = mapOfAccountIdVsUsers.get(dealRegOwnerUser.Contact.AccountId);

        }
        //Sharing to group
        for(Group eachGroup : listOfGroups){
            listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = eachGroup.Id,  AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
            SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(eachGroup.Id));
        }

        //SingleLogin User Share starts
        if(null!=mapAccountToUAMUser && null!=mapAccountToUAMUser.get(objLead.Partner_Account__c)){
            for(Id userId : mapAccountToUAMUser.get(objLead.Partner_Account__c)){
                System.debug('userId++'+userId);
                listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = userId,
                                                                AccountAccessLevel = 'Edit',
                                                                OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit',
                                                                CaseAccessLevel='Edit'));
                SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(userId));
            }
        }
        //SingleLogin User Share ends

        //Strategic RC Owner Share starts
        if(null!=mapOpptoSRCO && null!=mapOpptoSRCO.get(objLead.Id)){
            Id userId = mapOpptoSRCO.get(objLead.Id);
            System.debug('userId++'+userId);
            AccountTeamMember atm = new AccountTeamMember(AccountId = accountId,UserId = userId,TeamMemberRole = 'Strategic Partner RC Owner',
                                                          AccountAccessLevel = 'Edit',ContactAccessLevel = 'Edit',CaseAccessLevel = 'Edit',
                                                          OpportunityAccessLevel = 'Edit');
            insert atm;
            System.debug('ATM +++'+atm);
        }
        //Strategic RC Owner Share ends

        //Including for secondary portal access - starts
        if(mapOfAcctIdVsUserIdLst != null &&  !mapOfAcctIdVsUserIdLst.isEmpty()){
            Set<Id> setOfUserId = new Set<Id>();
            if(mapOfAcctIdVsUserIdLst.containsKey(objLead.Partner_Account__c)){
                setOfUserId = mapOfAcctIdVsUserIdLst.get(objLead.Partner_Account__c);
            }
            if(!setOfUserId.isEmpty()){
                for(Id userId : setOfUserId){
                    listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = userId,  AccountAccessLevel = 'Edit',
                                                             ContactAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel='Edit'));
                    SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(userId));
                }
            }
        }
        if(mapOfBrandVsCountryGroupIdMap != null && !mapOfBrandVsCountryGroupIdMap.isEmpty() &&
           mapOfBrandVsCountryGroupIdMap.containsKey(objLead.Lead_Brand_Name__c)){
               Map<String,Id> mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(objLead.Lead_Brand_Name__c);
               if(mapOfCountryVsGroupId != null && !mapOfCountryVsGroupId.isEmpty() &&
                  mapOfCountryVsGroupId.containsKey(objLead.Country__c)){
                      listOfAccountShareToCreate.add(new AccountShare(AccountId = accountId, UserOrGroupId = mapOfCountryVsGroupId.get(objLead.Country__c),
                                                               AccountAccessLevel = 'Edit', ContactAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                               CaseAccessLevel='Edit'));
                      SetOfUniqueAcctShareIds.add(String.valueOf(accountId)+String.valueOf(mapOfCountryVsGroupId.get(objLead.Country__c)));
                  }
           }

           if(!listOfAccountShareToCreate.isEmpty()){
               //added for gsp ac
             Map<String,ID> mapOfAccessGroups = new map<String,ID>();
            SettingsService.AccessControlSettingsWrapper accessSettings = new SettingsService.AccessControlSettingsWrapper();
            if (accessSettings != null && accessSettings.allGroups != null) {
			mapOfAccessGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
               }
        
        	//added for gsp ac
            List<AccountShare> listOfAccountSharesToDel = new List<AccountShare>();
            Set<String> setOfExistingAccountShares = new Set<String>();
            List<AccountShare> listOfAccountShareToInsert = new List<AccountShare>();
            List<AccountShare> listOfAccountShares = new List<AccountShare>();   
            if (!mapOfAccessGroups.isEmpty()) {
            	listOfAccountShares = [SELECT id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId =: accountId
                                                      AND RowCause = 'Manual' AND UserOrGroupId not in :mapOfAccessGroups.values() ];
            }else{
                listOfAccountShares = [SELECT id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId =: accountId
                                                      AND RowCause = 'Manual'];
            }
            //Form list of delta shares to delete
            if(!listOfAccountShares.isEmpty()){
                for(AccountShare accShare : listOfAccountShares){
                    String tmp = String.valueOf(accShare.AccountId)+String.valueOf(accShare.UserOrGroupId);
                    if(!SetOfUniqueAcctShareIds.contains(tmp)){
                        listOfAccountSharesToDel.add(accShare);
                    }else{
                        setOfExistingAccountShares.add(String.valueOf(accShare.AccountId)+'-'+String.valueOf(accShare.UserOrGroupId));
                    }
                }
                Database.delete(listOfAccountSharesToDel, false);
            }

            //Form list of delta shares to insert
            if(!setOfExistingAccountShares.isEmpty()){
                for(AccountShare eashAS : listOfAccountShareToCreate){
                    String tmp = String.valueOf(eashAS.AccountId)+'-'+String.valueOf(eashAS.UserOrGroupId);
                    if(!setOfExistingAccountShares.contains(tmp)) {
                        listOfAccountShareToInsert.add(eashAS);
                    }
                }
            }
            System.debug('listOfAccountShareToInsert++'+listOfAccountShareToInsert);
            if(!listOfAccountShareToInsert.isEmpty()) {
            	Database.insert(listOfAccountShareToInsert, false);
            } else {
                Database.insert(listOfAccountShareToCreate, false);
            }
        }
    }

    private static PartnerUsersGroupsWrapper getPartnerUsersAndGroups(Set<Id> setOfPartnerAccountIds){
        return getPartnerUsersAndGroups(setOfPartnerAccountIds, true);
    }

    private static PartnerUsersGroupsWrapper getPartnerUsersAndGroups(Set<Id> setOfPartnerAccountIds,
                                                                      Boolean addPartnerAccountIds){

                                                                          if(addPartnerAccountIds){
                                                                              Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
                                                                              Id parentPartnerAccount = comDetail.Portal_Top_Master_Account_Id__c;
                                                                              Id partnerAccount = getSelectedPartnerId();
                                                                              Id masterPartnerAccount = getCurrentUserPartnerAccount();

                                                                              setOfPartnerAccountIds.add(parentPartnerAccount);
                                                                              if(partnerAccount != null) {
                                                                                  setOfPartnerAccountIds.add(partnerAccount);
                                                                              }
                                                                              if(masterPartnerAccount != null ) {
                                                                                  setOfPartnerAccountIds.add(masterPartnerAccount);
                                                                              }
                                                                          }

                                                                          List<User> listOfPartnerAccountUsers = [SELECT Id, ContactId, Contact.AccountId,UserRole.DeveloperName
                                                                                                                  FROM User WHERE (Contact.AccountId IN : setOfPartnerAccountIds) AND Contact.AccountId != null
                                                                                                                  AND (UserRole.Name LIKE '%Executive%' OR UserRole.Name LIKE '%Manager%')];

                                                                          Set<String> setOfUserRoleNames = new Set<String>();
                                                                          for(User eachUser: listOfPartnerAccountUsers){
                                                                              setOfUserRoleNames.add(eachUser.UserRole.DeveloperName);
                                                                          }
                                                                          List<Group> listOfGroups = [SELECT Id, Name, RelatedId, Type From Group WHERE RelatedId IN
                                                                                                      (SELECT Id FROM UserRole WHERE DeveloperName IN : setOfUserRoleNames ) AND Type = 'Role' ];

                                                                          return new PartnerUsersGroupsWrapper(listOfPartnerAccountUsers, listOfGroups);
                                                                      }

    private class PartnerUsersGroupsWrapper{
        List<User> listOfUsers;
        List<Group> listOfGroups;
        Map<Id,List<Id>> mapOfPartnerWithGroups;
        public PartnerUsersGroupsWrapper(List<User> listOfUsers, List<Group> listOfGroups,Map<Id,List<Id>> mapOfPartnerWithGroups){
            this.listOfUsers = listOfUsers;
            this.listOfGroups = listOfGroups;
            this.mapOfPartnerWithGroups = mapOfPartnerWithGroups;
        }
        public PartnerUsersGroupsWrapper(List<User> listOfUsers, List<Group> listOfGroups){
            this.listOfUsers = listOfUsers;
            this.listOfGroups = listOfGroups;
        }
    }

    private static String getSelectedPartnerId(){
        String selectedPartnerAccount;
        try{
            Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
            Id sysAdminProfileId = [SELECT id, Name FROM Profile Where Name = 'System Administrator'].Id;
            //commented if and else because the else query returns null while running test class.
            if(null!=comDetail) {
                if(UserInfo.getProfileId() == sysAdminProfileId)    {
                    selectedPartnerAccount = comDetail.Portal_Top_Master_Account_Id__c;
                } else {
                    User u = [SELECT Id, Name, ContactId, Contact.AccountId, Partner_Account_Id__c
                              FROM User WHERE Id = :UserInfo.getUserId()];
                    selectedPartnerAccount = u.Contact.AccountId;
                }
            }
        } catch (Exception e){
            System.debug(e.getMessage());
        }
        return selectedPartnerAccount;
    }

    private static Id getCurrentUserPartnerAccount(){
        List<User> listOfUser = [SELECT Id, Name, ContactId, Contact.AccountId,
                                 Contact.Account.Partner_Account__c
                                 FROM User WHERE Id =: UserInfo.getUserId()];
        if(!listOfUser.isEmpty()){
            return listOfUser[0].Contact.Account.Partner_Account__c;
        }
        return null;
    }

    //NK: Where is this method used?
    public static Contact getContactAccount(Id contactId){
        List<Contact> listOfContacts = [SELECT Id, AccountId, Account.Partner_Account__c FROM Contact WHERE Id =: contactId];
        if(!listOfContacts.isEmpty()){
            return listOfContacts[0];
        }
        return null;
    }

    //Porting Changes - Including access for Partner User Roles - Starts
    private static Map<Id,List<Id>> getPartnerUsersAndGroupsForUserRoles(Set<Id> setOfPartnerAccountIdsForUserRoleAccess){

        //partner id with developer name map
        Map<Id,List<String>> partnerIdWithDeveloper = new Map<Id,List<String>>();
        //developer name with related id map
        Map<String,Id> developerNameWithRelatedIds = new Map<String,Id>();
        //related id with groupid MAP
        Map<Id,List<Id>> relatedIdwithGroupIds = new Map<Id,List<Id>>();
        //Final map PartnerId with groupids
        Map<Id,List<Id>> mapOfPartnerWithUserRoleGroups = new Map<Id,List<Id>>();
        System.debug('setOfPartnerAccountIdsForUserRoleAccess++'+setOfPartnerAccountIdsForUserRoleAccess);

        List<User> listOfPartnerAccountUsers = [SELECT Id, ContactId, Contact.AccountId,UserRole.DeveloperName
                                                FROM User WHERE (Contact.AccountId IN : setOfPartnerAccountIdsForUserRoleAccess) AND Contact.AccountId != null
                                                /*AND UserRole.Name LIKE '%USER%'*/];
        System.debug('listOfPartnerAccountUsers+++'+listOfPartnerAccountUsers);
        Set<String> setOfUserRoleNames = new Set<String>();
        List<String> tmpList = new List<String>();

        for(User eachUser: listOfPartnerAccountUsers){
            setOfUserRoleNames.add(eachUser.UserRole.DeveloperName);
            if(partnerIdWithDeveloper.get(eachUser.Contact.AccountId) == null){
                tmpList = new List<String>();
                tmpList.add(eachUser.UserRole.DeveloperName);
                partnerIdWithDeveloper.put(eachUser.Contact.AccountId,tmpList);
            }else{
                partnerIdWithDeveloper.get(eachUser.Contact.AccountId).add(eachUser.UserRole.DeveloperName);
            }
        }

        List<UserRole> userRoles =  [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName IN : setOfUserRoleNames ];
        Set<Id> relatedIds = new Set<Id>();
        for(UserRole userRoleObj : userRoles){
            relatedIds.add(userRoleObj.id);
            developerNameWithRelatedIds.put(userRoleObj.DeveloperName,userRoleObj.Id);
        }

        List<Group> listOfGroups = [SELECT Id, Name, RelatedId, Type From Group WHERE RelatedId IN : relatedIds AND Type = 'Role' ];
        for(Group groupObj : listofGroups){
            if(relatedIdwithGroupIds.get(groupObj.RelatedId) == null){
                tmpList = new List<String>();
                tmpList.add(groupObj.Id);
                relatedIdwithGroupIds.put(groupObj.RelatedId,tmpList);
            }else{
                relatedIdwithGroupIds.get(groupObj.RelatedId).add(groupObj.Id);
            }
        }
        List<Id> groupIds = new List<Id>();
        Map<String,List<Id>> mapOfDeveloperNameWithGrpIds = new Map<String,List<Id>>();
        for(String developerName : developerNameWithRelatedIds.keySet()){
            groupIds = relatedIdwithGroupIds.get(developerNameWithRelatedIds.get(developerName));
            mapOfDeveloperNameWithGrpIds.put(developerName,groupIds);
        }

        List<String> tmpList1 = null;
        List<Id> groupIdsFinal = new List<Id>();
        for(Id partnerId : partnerIdWithDeveloper.keyset()){
            tmpList1 = new List<String>();
            tmpList1 = partnerIdWithDeveloper.get(partnerId);
            groupIdsFinal = new List<Id>();
            for(String developerName :tmpList1){
                groupIdsFinal.addall(mapOfDeveloperNameWithGrpIds.get(developerName));
            }
            mapOfPartnerWithUserRoleGroups.put(partnerId,groupIdsFinal);
        }

        return mapOfPartnerWithUserRoleGroups;
    }
    //Porting Changes - Including access for Partner Users - Ends

    private static PartnerUsersGroupsWrapper getPartnerUsersAndGroupsNew(Set<Id> setOfPartnerAccountIds,
                                                                         Boolean addPartnerAccountIds)
    {
        //partner id with developer name map
        Map<Id,List<String>> partnerIdWithDeveloper = new Map<Id,List<String>>();
        //developer name with related id map
        Map<String,Id> developerNameWithRelatedIds = new Map<String,Id>();
        //related id with groupid MAP
        Map<Id,List<Id>> relatedIdwithGroupIds = new Map<Id,List<Id>>();
        //Final map PartnerId with groupids
        Map<Id,List<Id>> mapOfPartnerWithGroups = new Map<Id,List<Id>>();
        Map<Id,Id> mapofdeveloperNamewithId = new Map<Id,Id>();

        if(addPartnerAccountIds){
            List<Id> allTopMasterAcctIds = CommunityInfo.getAllCommunityTopMastersIds();
            Id partnerAccount = getSelectedPartnerId();
            Id masterPartnerAccount = getCurrentUserPartnerAccount();

            setOfPartnerAccountIds.addAll(allTopMasterAcctIds);
            if(partnerAccount != null) {
                setOfPartnerAccountIds.add(partnerAccount);
            }
            if(masterPartnerAccount != null ) {
                setOfPartnerAccountIds.add(masterPartnerAccount);
            }
        }
        System.debug('setOfPartnerAccountIds++'+setOfPartnerAccountIds);
        List<User> listOfPartnerAccountUsers = [SELECT Id, ContactId, Contact.AccountId,UserRole.DeveloperName
                                                FROM User WHERE (Contact.AccountId IN : setOfPartnerAccountIds) AND Contact.AccountId != null
                                                AND (UserRole.Name LIKE '%Executive%' OR UserRole.Name LIKE '%Manager%')];
        System.debug('listOfPartnerAccountUsers+++'+listOfPartnerAccountUsers);
        Set<String> setOfUserRoleNames = new Set<String>();
        List<String> tmpList = new List<String>();

        for(User eachUser: listOfPartnerAccountUsers){
            setOfUserRoleNames.add(eachUser.UserRole.DeveloperName);
            if(partnerIdWithDeveloper.get(eachUser.Contact.AccountId) == null){
                tmpList = new List<String>();
                tmpList.add(eachUser.UserRole.DeveloperName);
                partnerIdWithDeveloper.put(eachUser.Contact.AccountId,tmpList);
            }else{
                partnerIdWithDeveloper.get(eachUser.Contact.AccountId).add(eachUser.UserRole.DeveloperName);
            }

        }

        List<UserRole> userRoles =  [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName IN : setOfUserRoleNames ];
        Set<Id> relatedIds = new Set<Id>();
        for(UserRole userRoleObj : userRoles){
            relatedIds.add(userRoleObj.id);
            developerNameWithRelatedIds.put(userRoleObj.DeveloperName,userRoleObj.Id);
        }

        List<Group> listOfGroups = [SELECT Id, Name, RelatedId, Type From Group WHERE RelatedId IN : relatedIds AND Type = 'Role' ];
        for(Group groupObj : listofGroups){
            if(relatedIdwithGroupIds.get(groupObj.RelatedId) == null){
                tmpList = new List<String>();
                tmpList.add(groupObj.Id);
                relatedIdwithGroupIds.put(groupObj.RelatedId,tmpList);
            }else{
                relatedIdwithGroupIds.get(groupObj.RelatedId).add(groupObj.Id);
            }
        }
        List<Id> groupIds = new List<Id>();
        Map<String,List<Id>> mapOfDeveloperNameWithGrpIds = new Map<String,List<Id>>();
        for(String developerName : developerNameWithRelatedIds.keySet()){
            groupIds = relatedIdwithGroupIds.get(developerNameWithRelatedIds.get(developerName));
            mapOfDeveloperNameWithGrpIds.put(developerName,groupIds);
        }
        List<String> tmpList1 = null;
        List<Id> groupIdsFinal = new List<Id>();
        for(Id partnerId : partnerIdWithDeveloper.keyset()){
            tmpList1 = new List<String>();
            tmpList1 = partnerIdWithDeveloper.get(partnerId);
            groupIdsFinal = new List<Id>();
            for(String developerName :tmpList1){
                groupIdsFinal.addall(mapOfDeveloperNameWithGrpIds.get(developerName));
            }
            mapOfPartnerWithGroups.put(partnerId,groupIdsFinal);
        }
        return new PartnerUsersGroupsWrapper(listOfPartnerAccountUsers, listOfGroups,mapOfPartnerWithGroups);
    }

 @future
    public static void handleDeltaShareFuture(Set<Id> setOfIds, String objName){
        handleDeltaShare(setOfIds, objName);
    }
    
    //Synchronous version of handleDeltaShareFuture for batch context
    public static void handleDeltaShare(Set<Id> setOfIds, String objName){
        system.debug('Delete Customer Manual Sharing +++');
        if(objName.equalsIgnoreCase('Account')){
            List<AccountShare> listOfAccountSharesToDel = new List<AccountShare>();
            List<AccountShare> listOfAccountShares = [SELECT id,AccountId,UserOrGroupId FROM AccountShare WHERE AccountId =: setOfIds
                                                      AND RowCause = 'Manual'];
            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfAccountShares.isEmpty()){
                    system.debug('listOfAccountShares +++'+listOfAccountShares);
                    for(AccountShare accShare : listOfAccountShares){
                        listOfAccountSharesToDel.add(accShare);
                    }
                    system.debug('listOfAccountSharesToDel +++'+listOfAccountSharesToDel);
                    Database.delete(listOfAccountSharesToDel, false);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
        if(objName.equalsIgnoreCase('Lead')){
            List<LeadShare> listOfLeadSharesToDel = new List<LeadShare>();
            List<LeadShare> listOfLeadShares = [SELECT id,LeadId,UserOrGroupId FROM LeadShare WHERE LeadId =: setOfIds
                                                AND RowCause = 'Manual'];
            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfLeadShares.isEmpty()){
                    system.debug('listOfLeadShares +++'+listOfLeadShares);
                    for(LeadShare ldShare : listOfLeadShares){
                        listOfLeadSharesToDel.add(ldShare);
                    }
                    system.debug('listOfLeadSharesToDel +++'+listOfLeadSharesToDel);
                    Database.delete(listOfLeadSharesToDel, false);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
    }
}