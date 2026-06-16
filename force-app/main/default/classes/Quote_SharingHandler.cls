/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 03-11-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   03-11-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
//Naresh Kumar  02/16/2020  Handles sharing for all the objects
public without sharing class Quote_SharingHandler {

    public static final String ACCESS_LEVEL_NONE = 'None';
    public static final String ACCESS_LEVEL_EDIT = 'Edit';

    public static final String USER_TYPE_STANDARD = 'Standard';


    //Deal Support sharing
    @future
    public static void handleDealSupportShareFuture(Set<Id> setOfDealSupportIds){
        handleDealSupportShare(setOfDealSupportIds);
    }

    public static void handleDealSupportShare(Set<Id> setOfDealSupportIds){

        String brandName = '';
        PartnerDealSupprtAndRegsWrapper dealRegOwnerWrapper = dealSupportSharingWithDealRegOwners(setOfDealSupportIds);
        Set<Id> setOfPartnerAccountIds = dealRegOwnerWrapper.accountIds;
        Map<Id,Id> mapOfDealSupportIdVsDealRegOwnerId = dealRegOwnerWrapper.mapOfDealSupportIdVsDealRegOwnerId;
        Map<Id,Id> mapOfDealSupportIdVsDealRegCreatorId = dealRegOwnerWrapper.mapOfDealSupportIdVsDealRegCreatorId;
        //Partner channel Manager changes
        Map<Id,Id> mapOfDealSupportIdVsDealRegCAMId = dealRegOwnerWrapper.mapOfDealSupportIdVsDealRegCAMId;
        Set<String> SetOfUniqueDealSupportIds = new Set<String>();
        //secondary Portal Access - starts
        Map<Id,Set<Id>> mapOfDealSupportIdVsUsrLst = dealRegOwnerWrapper.mapOfDealSupportIdVsUsrLst;
        Map<Id,Id> mapOfDealSupportIdVsGroupId = dealRegOwnerWrapper.mapOfDealSupportIdVsGroupId;
        //secondary Portal Access - ends
        //Cloud Specialist
        Map<Id,Id> mapOfDealSupportIdVsCloudSpecialist =dealRegOwnerWrapper.mapOfDealSupportIdVsCloudSpecialist;
        system.debug('mapOfDealSupportIdVsCloudSpecialist--'+mapOfDealSupportIdVsCloudSpecialist);

        List<Deal_Support__c> listDealSupports = [SELECT Id, Lead__c, Opportunity__c, Partner_Quote__c,Customer_Account__c,
                                                  Partner_Contact__c,Partner_Account__c,
                                                  Partner_Account__r.Partner_Account__r.Partner_Account__c,
                                                  Partner_Account__r.Partner_Channel_Manager__c, Brand_Name__c,
                                                  Partner_Account__r.Partner_Account__c,Portal_Cloud_Specialist__c
                                                  FROM Deal_Support__c WHERE Id IN : setOfDealSupportIds];

        Map<Id,Set<Id>> mapDealToUAMUser = new Map<Id,Set<Id>>();
        Map<Id,Id> mapPartnerToContact = new Map<Id,Id>();
        Set<Id> setOfPartnerContact = new Set<Id>();
        Set<Id> setOfPartnerAcc = new Set<Id>();
        Map<Id,Id> mapPartnerToAccount = new Map<Id,Id>();
        Map<Id,Id> mapOfAccountToUser = new Map<Id,Id>();

        for(Deal_Support__c eachDS : listDealSupports){

            if(eachDS.Partner_Contact__c != null){
              mapPartnerToContact.put(eachDS.Id,eachDS.Partner_Contact__c);
                setOfPartnerContact.add(eachDS.Partner_Contact__c);
            }
            if(eachDS.Partner_Account__c != null){
                mapPartnerToAccount.put(eachDS.Id,eachDS.Partner_Account__c);
                setOfPartnerAcc.add(eachDS.Partner_Account__c);
            }
        }

        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>();
        if(setOfPartnerContact!= null && !setOfPartnerContact.isEmpty()){
            listOfUAM = new List<User_Account_Mapping__c>([Select Id, Partner_Contact__c, Partner_User__c, Partner_Account__c
                                                           From User_Account_Mapping__c
                                                           Where Partner_Account__c IN: setOfPartnerAcc]);
        }

        Map<Id,Set<Id>> mapAccountToUAMUser = new Map<Id,Set<Id>>();
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
        if(mapPartnerToAccount != null && !mapPartnerToAccount.isEmpty()){
            for(Id dealId : mapPartnerToAccount.keyset()){
                if(mapAccountToUAMUser != null && mapAccountToUAMUser.containsKey(mapPartnerToAccount.get(dealId))){
                    mapDealToUAMUser.put(dealId, mapAccountToUAMUser.get(mapPartnerToAccount.get(dealId)));
                }
            }
        }

        Map<Id, User> mapIdVsDealRegOwner =  new Map<Id, User>([SELECT Id, ContactId,
                                                                Contact.AccountId,
                                                                Contact.Account.Partner_Account__c,
                                                                Contact.Account.Parent_Partner_Account__c,
                                                                Contact.Account.Parent_Partner_Account__r.Parent_Partner_Account__c
                                                                FROM User WHERE Id IN :mapOfDealSupportIdVsDealRegOwnerId.values() OR
                                                                Id IN :mapOfDealSupportIdVsDealRegCreatorId.values()]);
        system.debug('deal owner map - '+mapOfDealSupportIdVsDealRegOwnerId.size());
        system.debug('deal creator map - '+mapOfDealSupportIdVsDealRegCreatorId.size());

        //Bulkify logic - starts
        Map<Id,Set<Id>> mapofDealWithPartnerIds = dealRegOwnerWrapper.mapofDealWithPartnerIds;

        // Community Top Master
        Map<String,Community_Details__mdt> mapOfBrandAndMetaData = new Map<String,Community_Details__mdt>();
        mapOfBrandAndMetaData = CommunityInfo.getAllCommunityDetails();

        Community_Details__mdt commDetailObj = new Community_Details__mdt();
        if(mapOfBrandAndMetaData != null && dealRegOwnerWrapper!= null && dealRegOwnerWrapper.brandName != null && mapOfBrandAndMetaData.containsKey(dealRegOwnerWrapper.brandName)
           ){
               commDetailObj = mapOfBrandAndMetaData.get(dealRegOwnerWrapper.brandName);
               if(!setOfPartnerAccountIds.contains(commDetailObj.Portal_Top_Master_Account_Id__c)){
                   setOfPartnerAccountIds.add(commDetailObj.Portal_Top_Master_Account_Id__c);
               }
           }

        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroupsNew(setOfPartnerAccountIds, true);//Bulkify

        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;

        //Bulkify logic starts
        Map<Id,List<Id>> mapOfPartnerWithGroups = objWrapper.mapOfPartnerWithGroups;
        Map<Id,List<Id>> mapOfAccountGroup = new Map<Id,List<Id>>();

        if(mapofDealWithPartnerIds != null && !mapofDealWithPartnerIds.isEmpty()){
            for(Id dealId : mapofDealWithPartnerIds.keySet()){
                List<Id> groupIds = new List<Id>();
                if(mapofDealWithPartnerIds.containsKey(dealId)){
                    Set<Id> partnerIds =  mapofDealWithPartnerIds.get(dealId);
                    if(partnerIds != null){
                        for(Id partnerId : partnerIds){
                            if(null!=mapOfPartnerWithGroups && null!=mapOfPartnerWithGroups.keySet() && mapOfPartnerWithGroups.keySet().size()>0
                                && mapOfPartnerWithGroups.containsKey(partnerId)){
                                groupIds.addall(mapOfPartnerWithGroups.get(partnerId));
                            }
                        }
                    }
                }
                mapOfAccountGroup.put(dealId,groupIds);
            }
        }
        System.debug('mapOfAccountGroup++'+mapOfAccountGroup);
        //Bulkify logic ends

        List<Deal_Support__Share> listOfDealSupportSharesToCreate = new List<Deal_Support__Share>();
        for(Id eachDealSupportId : setOfDealSupportIds){
            if(UserInfo.getUserType() != 'Standard'){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                                            UserOrGroupId = UserInfo.getUserId(), AccessLevel = 'Edit',
                                                                            RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(UserInfo.getUserId()));
            }
            if(mapOfDealSupportIdVsDealRegOwnerId.get(eachDealSupportId) != null){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                                            UserOrGroupId = mapOfDealSupportIdVsDealRegOwnerId.get(eachDealSupportId), AccessLevel = 'Edit',
                                                                            RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(mapOfDealSupportIdVsDealRegOwnerId.get(eachDealSupportId)));
            }

            if(mapOfDealSupportIdVsDealRegCreatorId.get(eachDealSupportId) != null){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                                            UserOrGroupId = mapOfDealSupportIdVsDealRegCreatorId.get(eachDealSupportId),
                                                                            AccessLevel = 'Edit',
                                                                            RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(mapOfDealSupportIdVsDealRegCreatorId.get(eachDealSupportId)));
            }

            //Including sharing changes for Partner Channel Manager
            if(null!=mapOfDealSupportIdVsDealRegCAMId && mapOfDealSupportIdVsDealRegCAMId.get(eachDealSupportId) != null){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                                            UserOrGroupId = mapOfDealSupportIdVsDealRegCAMId.get(eachDealSupportId),
                                                                            AccessLevel = 'Edit',
                                                                            RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(mapOfDealSupportIdVsDealRegCAMId.get(eachDealSupportId)));
            }

            if(null!=mapOfAccountGroup && null!=mapOfAccountGroup.get(eachDealSupportId)){
                for(Id groupId : mapOfAccountGroup.get(eachDealSupportId)){
                    listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId, UserOrGroupId = groupId,
                                                                                AccessLevel = 'Edit',
                                                                                RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                    SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(groupId));
                }
            }
            //Bulkify logic ends
            //SingleLogin User Share starts
            if(null!=mapDealToUAMUser && null!=mapDealToUAMUser.get(eachDealSupportId)){
                for(Id userId : mapDealToUAMUser.get(eachDealSupportId)){
                    listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId, UserOrGroupId = userId,
                                                                            AccessLevel = 'Edit',
                                                                            RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                    SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(userId));
                }
            }
            //SingleLogin User Share ends

            //Including for secondary portal access - starts
            if(null!=mapOfDealSupportIdVsUsrLst && mapOfDealSupportIdVsUsrLst.get(eachDealSupportId) != null){
                Set<Id> setOfUserId = mapOfDealSupportIdVsUsrLst.get(eachDealSupportId);
                if(setOfUserId != null && !setOfUserId.isEmpty()){
                    for(Id userId : setOfUserId){
                        listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                                                    UserOrGroupId = userId, AccessLevel = 'Edit',
                                                                                    RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                        SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(userId));
                    }
                }
            }
            if(mapOfDealSupportIdVsGroupId != null && !mapOfDealSupportIdVsGroupId.isEmpty() &&
                                                    mapOfDealSupportIdVsGroupId.get(eachDealSupportId) != null){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                        UserOrGroupId = mapOfDealSupportIdVsGroupId.get(eachDealSupportId), AccessLevel = 'Edit',
                                                        RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(mapOfDealSupportIdVsGroupId.get(eachDealSupportId)));
            }
        //Including for secondary portal access - ends

            //Access To Cloud Specialist
            if(mapOfDealSupportIdVsCloudSpecialist !=null && !mapOfDealSupportIdVsCloudSpecialist.IsEmpty() && mapOfDealSupportIdVsCloudSpecialist.get(eachDealSupportId) != null){
                listOfDealSupportSharesToCreate.add(new Deal_Support__Share(ParentId = eachDealSupportId,
                                                        UserOrGroupId = mapOfDealSupportIdVsCloudSpecialist.get(eachDealSupportId), AccessLevel = 'Edit',
                                                        RowCause = Schema.Deal_Support__Share.RowCause.Deal_Support_Access__c));
                SetOfUniqueDealSupportIds.add(String.valueOf(eachDealSupportId)+String.valueOf(mapOfDealSupportIdVsCloudSpecialist.get(eachDealSupportId)));
            }

        }
        //Partner channel Manager - starts
        if(!listOfDealSupportSharesToCreate.isEmpty()){
            List<Deal_Support__Share> listOfDealSupportSharesToDel = new List<Deal_Support__Share>();
            Set<String> tmpSetOfDSShare = new Set<String>();
            List<Deal_Support__Share> listOfDealSupportShareToInsert = new List<Deal_Support__Share>();
            List<Deal_Support__Share> listOfDealSupportShares = [SELECT id,ParentId,UserOrGroupId FROM Deal_Support__Share
                                                                 WHERE ParentId IN :setOfDealSupportIds
                                                                 AND RowCause = 'Deal_Support_Access__c'];
            System.debug('listOfDealSupportShares '+listOfDealSupportShares.isEmpty());

            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfDealSupportShares.isEmpty()){
                    for(Deal_Support__Share dsShare : listOfDealSupportShares){
                        String tmp = String.valueOf(dsShare.ParentId)+String.valueOf(dsShare.UserOrGroupId);
                        if(!SetOfUniqueDealSupportIds.contains(tmp)){
                            listOfDealSupportSharesToDel.add(dsShare);
                        }else{
                            tmpSetOfDSShare.add(String.valueOf(dsShare.ParentId)+'-'+String.valueOf(dsShare.UserOrGroupId));
                        }
                    }
                    Database.delete(listOfDealSupportSharesToDel, false);
                }
                if(!tmpSetOfDSShare.isEmpty()){
                    for(Deal_Support__Share eashDS : listOfDealSupportSharesToCreate){
                        String tmp = String.valueOf(eashDS.ParentId)+'-'+String.valueOf(eashDS.UserOrGroupId);
                        if(!tmpSetOfDSShare.contains(tmp)) {
                            listOfDealSupportShareToInsert.add(eashDS);
                        }
                    }
                }
                if(!listOfDealSupportShareToInsert.isEmpty()) {
                    Database.insert(listOfDealSupportShareToInsert, false);
                } else {
                    Database.insert(listOfDealSupportSharesToCreate, false);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
        //Partner channel Manager - ends
    }

    //Partner quote sharing
    @future
    public static void handlePartnerQuoteSharingFuture(Id partnerQuoteId){
        handlePartnerQuoteSharing(partnerQuoteId);
    }

    public static void handlePartnerQuoteSharingForAccount(Set<Id> setOfAccountIds){
        Map<Id, Partner_Quote__c> mapOfIdVsPartnerQuote = new Map<Id, Partner_Quote__c>([SELECT Opportunity__r.AccountId FROM Partner_Quote__c WHERE
                                                                                         Opportunity__r.AccountId IN : setOfAccountIds]);
        handlePartnerQuoteSharing(mapOfIdVsPartnerQuote.keyset());
    }

    public static void handlePartnerQuoteSharing(String partnerQuoteId){
        Set<Id> setOfPartnerQuoteIds = new Set<Id>{partnerQuoteId};
            handlePartnerQuoteSharing(setOfPartnerQuoteIds);
    }

    public static void handlePartnerQuoteSharing(Set<Id> partnerQuoteIdsSet){
        Id currentUserId = UserInfo.getUserId();
        String currentUserType = UserInfo.getUserType();

        List<Partner_Quote__c> partnerQuotes = [
            SELECT Opportunity__c, Opportunity__r.AccountId
            FROM Partner_Quote__c
            WHERE Id =: partnerQuoteIdsSet
        ];

        Map<Id, List<AccountShare>> accSharesByIds = new Map<Id, List<AccountShare>>();
        for (Partner_Quote__c pQuote : partnerQuotes) {
            accSharesByIds.put(pQuote.Opportunity__r.AccountId,  new List<AccountShare>());
        }

        List<AccountShare> accShares = [
            SELECT AccountId, UserOrGroupId, OpportunityAccessLevel
            FROM AccountShare
            WHERE AccountId IN :accSharesByIds.keySet() AND OpportunityAccessLevel !=: ACCESS_LEVEL_NONE
        ];

        Set<Id> userIds = new Set<Id>();
        for (AccountShare accShare : accShares) {
            accSharesByIds.get(accShare.AccountId).add(accShare);

            if (accShare.UserOrGroupId != null
                && SFDescribeHelper.SOBJECT_NAME_USER.equalsIgnoreCase(SFDescribeHelper.getObjectNameById(accShare.UserOrGroupId))) {
                userIds.add(accShare.UserOrGroupId);
            }
        }

        Map<Id, User> usersByIds = new Map<Id, User>(
            (List<User>) new UserSelector()
                .selectUsersByIds(userIds)
                .selectFields(new List<String>{'Id', 'UserType'})
                .executeQuery()
        );

        List<Partner_Quote__Share> partnerQuoteSharesToInsert = new List<Partner_Quote__Share>();
        for (Partner_Quote__c pQuote : partnerQuotes) {

            for (AccountShare accShare : accSharesByIds.get(pQuote.Opportunity__r.AccountId)) {
                if (currentUserId == accShare.UserOrGroupId || USER_TYPE_STANDARD.equalsIgnoreCase(usersByIds.get(accShare.UserOrGroupId)?.UserType)) {
                    continue;
                }
                partnerQuoteSharesToInsert.add(
                    new Partner_Quote__Share(
                        ParentId = pQuote.Id,
                        UserOrGroupId = accShare.UserOrGroupId,
                        AccessLevel = ACCESS_LEVEL_EDIT,
                        RowCause = Schema.Partner_Quote__Share.RowCause.Opportunity_Quote_Access__c
                    )
                );
            }

            if (!USER_TYPE_STANDARD.equalsIgnoreCase(currentUserType)) {
                partnerQuoteSharesToInsert.add(
                    new Partner_Quote__Share(
                        ParentId = pQuote.Id,
                        UserOrGroupId = currentUserId,
                        AccessLevel = ACCESS_LEVEL_EDIT,
                        RowCause = Schema.Partner_Quote__Share.RowCause.Partner_Quote_Access__c
                    )
                );
            }
        }

        if (!partnerQuoteSharesToInsert.isEmpty()) {
            List<Partner_Quote__Share> existingPartnerQuoteShares = [
                SELECT Id
                FROM Partner_Quote__Share
                WHERE ParentId IN :partnerQuoteIdsSet
                AND RowCause = :Schema.Partner_Quote__Share.RowCause.Opportunity_Quote_Access__c
            ];

            if (!existingPartnerQuoteShares.isEmpty()) {
                Database.delete(existingPartnerQuoteShares, false);
            }

            Database.insert(partnerQuoteSharesToInsert, false);
        }
    }

    @future
    public static void handleAccountChangeRequestSharingFuture(Id AccountChangeRequestId){
        handleAccountChangeRequestSharing(AccountChangeRequestId);
    }

    public static void handleAccountChangeRequestSharing(String AccountChangeRequestId){
        Set<Id> setOfAccountChangeRequestIds = new Set<Id>{AccountChangeRequestId};
            handleAccountChangeRequestSharing(setOfAccountChangeRequestIds);
    }
    public static void handleAccountChangeRequestSharing(Set<Id> setOfAccountChangeRequestIds){
        System.debug('Recalc Quote++'+setOfAccountChangeRequestIds.size());
        try{
        List<Account_Change_Request__Share> listOfAccountChangeRequestSharesToCreate = new List<Account_Change_Request__Share>();
        Map<Id, List<AccountShare>> mapOfAccountIdVsAccountshare = new Map<Id, List<AccountShare>>();
        Set<Id> setOfAccountIds=new Set<Id>();
        List<AccountShare> listOfAccountShares=new List<AccountShare>();
        List<Account_Change_Request__c> listOfAccountChangeRequests = [SELECT id,Account__c,Status__c FROM Account_Change_Request__c WHERE Id=: setOfAccountChangeRequestIds];
        for(Account_Change_Request__c eachACR : listOfAccountChangeRequests){
            if(eachACR.Account__c !=null) {
              setOfAccountIds.add(eachACR.Account__c);
            }
        }

       for(AccountShare accountShare:[Select Id,AccountId,AccountAccessLevel,UserOrGroupId from AccountShare where AccountId IN:setOfAccountIds]){
            if(accountShare !=null ){

                   if(mapOfAccountIdVsAccountshare.containsKey(accountShare.AccountId)) {
                       listOfAccountShares = mapOfAccountIdVsAccountshare.get(accountShare.AccountId);
                       listOfAccountShares.add(accountShare);
                       mapOfAccountIdVsAccountshare.put((accountShare.AccountId), listOfAccountShares);
                   } else {
                       mapOfAccountIdVsAccountshare.put((accountShare.AccountId), new List<AccountShare> { accountShare });
                   }
               }
           system.debug('mapOfAccountIdVsAccountshare'+mapOfAccountIdVsAccountshare);
        }

        Set<Id> setOfUserOrGroupIds = new Set<Id>();
        for(Account_Change_Request__c eachACR : listOfAccountChangeRequests){
            for(AccountShare eachAccShare : mapOfAccountIdVsAccountshare.get(eachACR.Account__c)){
                if(setOfUserOrGroupIds.contains(eachAccShare.UserOrGroupId)){
                                    listOfAccountChangeRequestSharesToCreate.add(new Account_Change_Request__Share(ParentId = eachACR.id,
                                                                              UserOrGroupId = eachAccShare.UserOrGroupId, AccessLevel = 'Edit',
                                                                              RowCause = Schema.Account_Change_Request__Share.RowCause.Manual));
                }
      listOfAccountChangeRequestSharesToCreate.add(new Account_Change_Request__Share(ParentId = eachACR.id,
                                                                              UserOrGroupId = eachAccShare.UserOrGroupId, AccessLevel = 'Edit',
                                                                              RowCause = Schema.Account_Change_Request__Share.RowCause.Manual));
            }
            if(UserInfo.getUserType() != 'Standard'){
                listOfAccountChangeRequestSharesToCreate.add(new Account_Change_Request__Share(ParentId = eachACR.id,
                                                                              UserOrGroupId = UserInfo.getUserId(), AccessLevel = 'Edit',
                                                                              RowCause = Schema.Account_Change_Request__Share.RowCause.Manual));
                setOfUserOrGroupIds.add(UserInfo.getUserId());
            }
        }


        system.debug('listOfAccountChangeRequestSharesToCreate--'+listOfAccountChangeRequestSharesToCreate);
        if(!listOfAccountChangeRequestSharesToCreate.isEmpty()){
            //Deleting existing shares
            List<Account_Change_Request__Share> listOfExistingAccountChangeRequestShares = [SELECT id FROM Account_Change_Request__Share
                                                                          WHERE ParentId IN :setOfAccountChangeRequestIds
                                                                          AND RowCause =: Schema.Account_Change_Request__Share.RowCause.Manual];
            if(!listOfExistingAccountChangeRequestShares.isEmpty()) {
                Database.delete(listOfExistingAccountChangeRequestShares, false);
            }
            //Inserting new share
            Database.insert(listOfAccountChangeRequestSharesToCreate, false);
        }
        }catch(Exception e){
              System.debug(e.getMessage());
         }
    }

    //Deal registration sharing
    public static void handleDealRegistrationShareFuture(Set<Id> setOfDealRegIds){
        handleDealRegistrationShare(setOfDealRegIds);
    }

    public static void handleDealRegistrationShare(Set<Id> setOfDealRegIds){
        List<Deal_Registration__c> listOfDealRegs = [SELECT id, Avaya_Partnership_Deal__c, OwnerId, CreatedById,
                                                     Partner_Account__c, Partner_Account__r.Partner_Channel_Manager__c,
                                                     Partner_Account__r.Partner_Account__c, Partner_Account__r.Partner_Account__r.Partner_Account__c,Partner_Account__r.Partner_Account__r.Parent_Partner_Account__c,
                                                     Country__c,Brand_Name__c ,Portal_Cloud_Specialist__c, Partner_Contact__c
                                                     FROM Deal_Registration__c WHERE id IN : setOfDealRegIds];
        Set<Id> setOfDealRegUserIds = new Set<Id>();
        //Partner channel Manager
        Set<Id> setOfPartnerContactIds = new Set<Id>();
        Map<Id,Id> mapOfPartnerContactIdVsUserId = new Map<Id,Id>();
        Set<String> SetOfUniqueDealRegShareIds = new Set<String>();
        //secondary Portal Access - starts
        Set<Id> setOfAcctIdsForPortalAccess = new Set<Id>();
        Set<String> setOfCountryForGroupSharing = new Set<String>();
        Set<String> setOfBrandNameForGroupSharing = new Set<String>();
        //secondary Portal Access - ends

        //Avaya Cloud Specialist
        Set<Id> setOfCloudSpecialistContactIds=new Set<Id>();
        Map<Id,Id> mapOfCloudSpecialistContactUserId = new Map<Id,Id>();

        //Bulkify starts
        Set<Id> userIds = new Set<Id>();
        Set<Id> tmpDealPartnerIds = new Set<Id>();
        User eachUserId = new User();
        Set<Id> tmpDealUserId = new Set<Id>();
        Map<Id,Set<Id>> mapofDealWithUserIds = new  Map<Id,Set<Id>>();
        Set<Id> setOfPartnerAccountIds = new Set<Id>();
        Map<Id,Set<Id>> mapofDealWithPartnerIds = new  Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapDealToUAMUser = new Map<Id,Set<Id>>();
        Map<Id,Id>mapPartnerToContact = new Map<Id,Id>();
        Map<Id,Id> mapOfContactToUser = new Map<Id,Id>();
        Set<Id> setOfPartnerContact = new Set<Id>();
        //Bulkify ends

        for(Deal_Registration__c eachDealReg : listOfDealRegs){
            if(eachDealReg.Avaya_Partnership_Deal__c){
                setOfDealRegUserIds.add(eachDealReg.OwnerId);
                //added by Girish
                setOfDealRegUserIds.add(eachDealReg.CreatedById);

                //Bulkify logic
                tmpDealUserId = new Set<Id>();
                tmpDealUserId.add(eachDealReg.OwnerId);
                tmpDealUserId.add(eachDealReg.CreatedById);
                mapofDealWithUserIds.put(eachDealReg.id,tmpDealUserId);
                //added by Saradha
                if(eachDealReg.Partner_Account__c != null){
                    tmpDealPartnerIds = new Set<Id>();
                    tmpDealPartnerIds.add(eachDealReg.Partner_Account__c);
                    setOfPartnerAccountIds.add(eachDealReg.Partner_Account__c);
                    if(eachDealReg.Partner_Account__r.Partner_Account__c != null){
                        setOfPartnerAccountIds.add(eachDealReg.Partner_Account__r.Partner_Account__c);
                        tmpDealPartnerIds.add(eachDealReg.Partner_Account__r.Partner_Account__c);
                        if(eachDealReg.Partner_Account__r.Partner_Account__r.Partner_Account__c != null){
                          setOfPartnerAccountIds.add(eachDealReg.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                            tmpDealPartnerIds.add(eachDealReg.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                        }
                        if(eachDealReg.Brand_Name__c == 'Unify Office' &&
                        eachDealReg.Partner_Account__r.Partner_Account__r.Parent_Partner_Account__c != null) {
                            setOfPartnerAccountIds.add(eachDealReg.Partner_Account__r.Partner_Account__r.Parent_Partner_Account__c);
                            tmpDealPartnerIds.add(eachDealReg.Partner_Account__r.Partner_Account__r.Parent_Partner_Account__c);
                        }
                    }
                    mapofDealWithPartnerIds.put(eachDealReg.id,tmpDealPartnerIds);
                }
                //Bulkify ends
            }
            //Partner channel Manager - starts
            if(null != eachDealReg.Partner_Account__c && null != eachDealReg.Partner_Account__r.Partner_Channel_Manager__c) {
                setOfPartnerContactIds.add(eachDealReg.Partner_Account__r.Partner_Channel_Manager__c);
            }

            //Including for secondary Portal Access - starts
            if(null != eachDealReg.Partner_Account__c) {
                setOfAcctIdsForPortalAccess.add(eachDealReg.Partner_Account__c);
            }
            if(eachDealReg.Country__c != null) {
                setOfCountryForGroupSharing.add(eachDealReg.Country__c);
            }
            if(eachDealReg.Brand_Name__c != null) {
                setOfBrandNameForGroupSharing.add(eachDealReg.Brand_Name__c);
            }
            //Including for secondary Portal Access - ends

            //Set Of Cloud Specialist Contact Ids
            if(eachDealReg.Portal_Cloud_Specialist__c!=null && string.valueOf(eachDealReg.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')) {
                setOfCloudSpecialistContactIds.add(eachDealReg.Portal_Cloud_Specialist__c);
            }

            if(eachDealReg.Partner_Contact__c != null){
              mapPartnerToContact.put(eachDealReg.Id,eachDealReg.Partner_Contact__c);
                setOfPartnerContact.add(eachDealReg.Partner_Contact__c);
            }
        }

        List<User> partnerContactUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN: setOfPartnerContactIds AND ContactId!=null];
        if(null != partnerContactUsers){
            for(User eachUser : partnerContactUsers){
                if(setOfPartnerContactIds.contains(eachUser.ContactId)) {
                    mapOfPartnerContactIdVsUserId.put(eachUser.ContactId, eachUser.Id);
                }
            }
        }
        //Partner channel Manager - ends
        List<User_Account_Mapping__c> listOfUAM = new List<User_Account_Mapping__c>();
        if(setOfPartnerContact!= null && !setOfPartnerContact.isEmpty()){
            listOfUAM = new List<User_Account_Mapping__c>([Select Id, Partner_Contact__c, Partner_User__c
                                                           From User_Account_Mapping__c
                                                           Where Partner_Contact__c IN: setOfPartnerContact]);
        }
        system.debug('listOfUAM>>'+listOfUAM);
        Map<Id,Set<Id>> mapOfUAMContactUser = new Map<Id,Set<Id>>();
        Set<Id> setUAMUsers = new Set<Id>();
        if(listOfUAM != null && !listOfUAM.isEmpty()){
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
        }
        system.debug('mapOfUAMContactUser>>'+mapOfUAMContactUser);

        if(mapPartnerToContact != null && !mapPartnerToContact.isEmpty()){
            for(Id dealId : mapPartnerToContact.keyset()){
                if(mapOfUAMContactUser != null && mapOfUAMContactUser.containsKey(mapPartnerToContact.get(dealId))){
                    mapDealToUAMUser.put(dealId, mapOfUAMContactUser.get(mapPartnerToContact.get(dealId)));
                }
            }
        }
        system.debug('mapDealToUAMUser>>'+mapDealToUAMUser);

        //Cloud Specialist Users and Mapping of Contact,User
        if(setOfCloudSpecialistContactIds!=null && !setOfCloudSpecialistContactIds.IsEmpty() && setOfCloudSpecialistContactIds.size()>0){
            List<User> listOfCloudSpecialistUsers=[Select Id,ContactId from user where ContactId IN: setOfCloudSpecialistContactIds AND ContactId != null];
            if(listOfCloudSpecialistUsers !=null && !listOfCloudSpecialistUsers.isEmpty() && listOfCloudSpecialistUsers.size()>0){
                for(User user:listOfCloudSpecialistUsers){
                    mapOfCloudSpecialistContactUserId.put(user.ContactId,user.Id);
                }
            }
        }

        Map<Id, User> mapIdVsDealRegOwner =  new Map<Id, User>([SELECT Id, ContactId,
                                                                Contact.AccountId,
                                                                Contact.Account.Partner_Account__c,
                                                                Contact.Account.Parent_Partner_Account__c,
                                                                Contact.Account.Parent_Partner_Account__r.Parent_Partner_Account__c
                                                                FROM User WHERE Id IN :setOfDealRegUserIds]);

        System.debug('mapofDealWithPartnerIds+++'+mapofDealWithPartnerIds);

        //PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroups(setOfPartnerAccountIds, false);
        PartnerUsersGroupsWrapper objWrapper = getPartnerUsersAndGroupsNew(setOfPartnerAccountIds, false);
        Map<Id,List<Id>> mapOfPartnerWithGroups = objWrapper.mapOfPartnerWithGroups;
        Map<Id,List<Id>> mapOfAccountGroup = new Map<Id,List<Id>>();
        Set<Id> partnerIds = new Set<Id>();
        List<Id> groupIds = new List<Id>();

        for(Id dealId : mapofDealWithPartnerIds.keySet()){
            partnerIds =  mapofDealWithPartnerIds.get(dealId);
            groupIds = new List<Id>();
            for(Id partnerId : partnerIds){
                if(null!=mapOfPartnerWithGroups && null!=mapOfPartnerWithGroups.keySet() && mapOfPartnerWithGroups.keySet().size()>0
                   && mapOfPartnerWithGroups.containsKey(partnerId)){
                       groupIds.addall(mapOfPartnerWithGroups.get(partnerId));
                   }
            }
            mapOfAccountGroup.put(dealId,groupIds);
        }
        System.debug('mapOfAccountGroup++'+mapOfAccountGroup);
        //Bulkify logic - ends

        List<User> listOfPartnerAccountUsers = objWrapper.listOfUsers;
        List<Group> listOfGroups = objWrapper.listOfGroups;

        Map<Id, List<User>> mapOfAccountIdVsUsers = new Map<Id, List<User>>();
        for(User eachUser : listOfPartnerAccountUsers){
            if(mapOfAccountIdVsUsers.KeySet().contains(eachUser.Contact.AccountId)){
                mapOfAccountIdVsUsers.get(eachUser.Contact.AccountId).add(eachUser);
            } else {
                mapOfAccountIdVsUsers.put(eachUser.Contact.AccountId, new List<User>{eachUser} );
            }
        }

        List<Deal_Registration__Share> listOfDealRegSharesToCreate = new List<Deal_Registration__Share>();
        //Including for secondary portal access - starts
        Map<Id,Set<Id>> mapOfAcctIdVsUserIdLst = SecondaryPortalAccessUtil.getUserIdListForPartnerAccts(setOfAcctIdsForPortalAccess);
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = SecondaryPortalAccessUtil.getGroupIdforCountry(setOfBrandNameForGroupSharing,setOfCountryForGroupSharing);
        //Including for secondary portal access - ends

        User currentUser = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('currentUser--> '+currentUser);
        Boolean isGuest = false;
        if(currentUser.Profile.UserLicense.Name == 'Guest User License')
        {
            isGuest = true;
        }

        for(Deal_Registration__c eachDealReg : listOfDealRegs){
            //added by Girish
            if(!isGuest)
            {
            User dealCreator = mapIdVsDealRegOwner.get(eachDealReg.CreatedById);
            listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                                         UserOrGroupId = eachDealReg.CreatedById,
                                                                         AccessLevel = 'Edit',
                                                                         RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
            SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(eachDealReg.CreatedById));
            }

            User dealOwner = mapIdVsDealRegOwner.get(eachDealReg.OwnerId);
            listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                                         UserOrGroupId = eachDealReg.OwnerId,
                                                                         AccessLevel = 'Edit',
                                                                         RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
            SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(eachDealReg.OwnerId));

            if(null!=mapOfAccountGroup && null!=mapOfAccountGroup.get(eachDealReg.id)){
                for(Id groupId : mapOfAccountGroup.get(eachDealReg.id)){
                    listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id, UserOrGroupId = groupId,
                                                                                 AccessLevel = 'Edit',
                                                                                 RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                    SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(groupId));
                }
            }
            //SingleLogin User Share starts
            if(null!=mapDealToUAMUser && null!=mapDealToUAMUser.get(eachDealReg.Id)){
                for(Id userId : mapDealToUAMUser.get(eachDealReg.Id)){
                    listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id, UserOrGroupId = userId,
                                                                                AccessLevel = 'Edit',
                                                                                RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                    SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(userId));
                }
            }
            //SingleLogin User Share ends

            //Bulkify ends

            //Added for Partner channel Manager
            if(null!=mapOfPartnerContactIdVsUserId && null != eachDealReg.Partner_Account__c && null != eachDealReg.Partner_Account__r.Partner_Channel_Manager__c){
                Id partnerChannelMgrUserId = null;
                partnerChannelMgrUserId = mapOfPartnerContactIdVsUserId.get(eachDealReg.Partner_Account__r.Partner_Channel_Manager__c);
                if(partnerChannelMgrUserId != null){
                    listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                                                 UserOrGroupId = partnerChannelMgrUserId, AccessLevel = 'Edit',
                                                                                 RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                    SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(partnerChannelMgrUserId));
                }
            }

            //Access to Cloud Specialist
            if(mapOfCloudSpecialistContactUserId !=null && mapOfCloudSpecialistContactUserId.keySet() !=null && mapOfCloudSpecialistContactUserId.keySet().size()>0){
                Id cloudSpecialistUserId=null;
                cloudSpecialistUserId=mapOfCloudSpecialistContactUserId.get(eachDealReg.Portal_Cloud_Specialist__c);
                if(cloudSpecialistUserId != null){
                    listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                UserOrGroupId = cloudSpecialistUserId, AccessLevel = 'Edit',
                                                RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                    SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(cloudSpecialistUserId));
                }
            }

            //Including for secondary portal access - starts
            if(mapOfAcctIdVsUserIdLst != null && !mapOfAcctIdVsUserIdLst.isEmpty()){
                Set<Id> setOfUserId = new Set<Id>();
                if(eachDealReg.Partner_Account__c != null && mapOfAcctIdVsUserIdLst.containsKey(eachDealReg.Partner_Account__c)){
                    setOfUserId = mapOfAcctIdVsUserIdLst.get(eachDealReg.Partner_Account__c);
                }
                if(!setOfUserId.isEmpty()){
                    for(Id userId : setOfUserId){
                        if(userId != null) {
                            listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                                                     UserOrGroupId = userId, AccessLevel = 'Edit',
                                                                                     RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                            SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(userId));
                        }
                    }
                }
            }
            if(mapOfBrandVsCountryGroupIdMap != null && !mapOfBrandVsCountryGroupIdMap.isEmpty() &&
                                                mapOfBrandVsCountryGroupIdMap.containsKey(eachDealReg.Brand_Name__c)){
                Map<String,Id> mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(eachDealReg.Brand_Name__c);
                if(mapOfCountryVsGroupId != null && !mapOfCountryVsGroupId.isEmpty() &&
                                                mapOfCountryVsGroupId.containsKey(eachDealReg.Country__c)){
                    listOfDealRegSharesToCreate.add(new Deal_Registration__Share(ParentId = eachDealReg.Id,
                                                    UserOrGroupId = mapOfCountryVsGroupId.get(eachDealReg.Country__c), AccessLevel = 'Edit',
                                                    RowCause = Schema.Deal_Registration__Share.RowCause.Deal_Registration_Share__c));
                    SetOfUniqueDealRegShareIds.add(String.valueOf(eachDealReg.Id)+String.valueOf(mapOfCountryVsGroupId.get(eachDealReg.Country__c)));
                }
            }
            //Including for secondary portal access - ends
        }
        //Added for PCM starts
        if(!listOfDealRegSharesToCreate.isEmpty()){
            List<Deal_registration__Share> listOfDealRegSharesToDel = new List<Deal_registration__Share>();
            Set<String> tmpSetOfDealRegShare = new Set<String>();
            List<Deal_registration__Share> listOfDealRegShareToInsert = new List<Deal_registration__Share>();
            List<Deal_registration__Share> listOfDealRegShares = [SELECT id,ParentId,userorgroupId, rowcause
                                                                  FROM Deal_registration__Share
                                                                  where ParentId in :setOfDealRegIds
                                                                  AND RowCause =: Schema.Deal_registration__Share.RowCause.Deal_Registration_Share__c];
            Savepoint sp = Database.setSavepoint();
            try{
                if(!listOfDealRegShares.isEmpty()){
                    for(Deal_registration__Share dealRegShare : listOfDealRegShares){
                        String tmp = String.valueOf(dealRegShare.ParentId)+String.valueOf(dealRegShare.userorgroupId);
                        if(!SetOfUniqueDealRegShareIds.contains(tmp)){
                            listOfDealRegSharesToDel.add(dealRegShare);
                        }else{
                            tmpSetOfDealRegShare.add(String.valueOf(dealRegShare.ParentId)+'-'+String.valueOf(dealRegShare.UserOrGroupId));
                        }
                    }
                    Database.delete(listOfDealRegSharesToDel, false);
                }
                if(!tmpSetOfDealRegShare.isEmpty()){
                    for(Deal_registration__Share eashDRS : listOfDealRegSharesToCreate){
                        String tmp = String.valueOf(eashDRS.ParentId)+'-'+String.valueOf(eashDRS.UserOrGroupId);
                        if(!tmpSetOfDealRegShare.contains(tmp)) {
                            listOfDealRegShareToInsert.add(eashDRS);
                        }
                    }
                }
                if(!listOfDealRegShareToInsert.isEmpty()) {
                    Database.insert(listOfDealRegShareToInsert, true);
                }
                else {
                    Database.insert(listOfDealRegSharesToCreate, true);
                }
            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
        //Added for PCM Ends
    }

    @TestVisible
    private static PartnerDealSupprtAndRegsWrapper dealSupportSharingWithDealRegOwners(Set<Id> setOfDealSupportIds){
        Map<Id,Id> mapOfDealSupportIdVsDealRegOwnerId = new Map<Id,Id>();
        Map<Id,Id> mapOfDealSupportIdVsDealRegCreatorId = new Map<Id,Id>();
        Map<Id,Id> mapOfDealSupportIdVsDealRegCAMId = new Map<Id,Id>();//Partner Channel Manager
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfPartnerContactIds = new Set<Id>();//Partner Channel Manager
        //secondary Portal Access - starts
        Set<Id> setOfAcctIdsForPortalAccess = new Set<Id>();
        Map<Id,Id> mapOfDealSupportIdVSPartnerAcctId = new Map<Id,Id>();
        Map<Id,Set<Id>> mapOfDealSupportIdVsUsrLst = new Map<Id,Set<Id>>();
        Set<String> setOfCountryForGroupSharing = new Set<String>();
        Set<String> setOfBrandNameForGroupSharing = new Set<String>();
        //secondary Portal Access - ends
        String brandName = null;
        //Avaya Cloud Specialist
        Map<Id,Id> mapOfDealSupportIdVsCloudSpecialist =new Map<Id,Id>();
        Set<Id> setOfCloudSpecialistContactIds=new Set<Id>();
        Map<Id,Id> mapOfCloudSpecialistContactUserId = new Map<Id,Id>();
        Map<Id,Set<Id>> mapofDealWithPartnerIds = new  Map<Id,Set<Id>>();//Bulkify

        List<Deal_Support__c> listOfDealSupports = [SELECT id, Lead__c,Lead__r.partner_account__c,
                                                    Lead__r.partner_account__r.id,
                                                    Lead__r.Deal_Registration__c,
                                                    Lead__r.Deal_Registration__r.ownerid,
                                                    Lead__r.Deal_Registration__r.CreatedById,
                                                    Lead__r.Partner_Account__r.Partner_Channel_Manager__c,
                                                    Lead__r.Lead_Brand_Name__c,
                                                    Lead__r.Partner_Account__r.RC_Brand__c,
                                                    Lead__r.Country__c,
                                                    Opportunity__r.Deal_Registration__c,
                                                    Opportunity__r.partner_account__c,
                                                    Opportunity__r.Deal_Registration__r.ownerid,
                                                    Opportunity__r.Deal_Registration__r.CreatedById,
                                                    Opportunity__r.Partner_Account__r.Partner_Channel_Manager__c,
                                                    Opportunity__r.Partner_Account__r.RC_Brand__c,
                                                    Opportunity__r.Deal_Registration__r.Brand_Name__c,
                                                    Customer_Account__r.Deal_Registration__r.ownerid,
                                                    Customer_Account__r.partner_account__c,
                                                    Customer_Account__r.Deal_Registration__r.CreatedById,
                                                    Customer_Account__r.Deal_Registration__r.Brand_Name__c,
                                                    Customer_Account__r.Partner_Account__r.Partner_Channel_Manager__c,
                                                    Customer_Account__r.Partner_Account__r.RC_Brand__c,
                                                    Customer_Account__r.billingCountry,
                                                    Customer_Account__r.RC_Brand__c,
                                                    Partner_Account__c,Partner_Account__r.RC_Brand__c,
                                                    Partner_Contact__c,Partner_Contact__r.Account.RC_Brand__c,
                                                    Partner_Account__r.billingCountry,
                                                    Partner_Account__r.Partner_Account__c,
                                                    Partner_Account__r.Partner_Account__r.Partner_Account__c,
                                                    Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c,
                                                    Portal_Cloud_Specialist__c
                                                    FROM Deal_support__c
                                                    WHERE id IN :setOfDealSupportIds
                                                    AND (Lead__c != null OR Opportunity__c != null OR Customer_Account__c != null OR Partner_Account__c != null)];

        for(Deal_Support__c eachDS : listOfDealSupports){
            if(eachDS.Partner_Account__c != null){
                Set<Id> tmpDealPartnerIds = new Set<Id>();
                tmpDealPartnerIds.add(eachDS.Partner_Account__c);
                setOfAccountIds.add(eachDS.Partner_Account__c);
                System.debug('Level 1:' + eachDS.Partner_Account__c);
                if(eachDS.Partner_Account__r.Partner_Account__c != null){
                    setOfAccountIds.add(eachDS.Partner_Account__r.Partner_Account__c);
                    tmpDealPartnerIds.add(eachDS.Partner_Account__r.Partner_Account__c);
                    System.debug('Level 2:' + eachDS.Partner_Account__r.Partner_Account__c);
                    if(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__c != null){
                        setOfAccountIds.add(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                        tmpDealPartnerIds.add(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                        if(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c != null){
                            setOfAccountIds.add(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                            tmpDealPartnerIds.add(eachDS.Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c);
                        }
                    }
                }
                mapofDealWithPartnerIds.put(eachDS.id,tmpDealPartnerIds);
            }
            //Bulkify logic ends

            if(eachDS.Lead__c != null && eachDS.Lead__r.Deal_Registration__c != null && eachDS.Lead__r.Deal_Registration__r.ownerid != null){
                mapOfDealSupportIdVsDealRegOwnerId.put(eachDS.id,eachDS.Lead__r.Deal_Registration__r.ownerid);
            }else if(eachDS.Opportunity__r.Deal_Registration__c != null
                     && eachDS.Opportunity__r.Deal_Registration__r.ownerid != null){
                mapOfDealSupportIdVsDealRegOwnerId.put(eachDS.id,eachDS.Opportunity__r.Deal_Registration__r.ownerid);
            }else if(eachDS.Customer_Account__r.Deal_Registration__c != null
                    && eachDS.Customer_Account__r.Deal_Registration__r.ownerid != null){
                mapOfDealSupportIdVsDealRegOwnerId.put(eachDS.id,eachDS.Customer_Account__r.Deal_Registration__r.ownerid);
            }

            if(eachDS.Lead__c != null && eachDS.Lead__r.Deal_Registration__c != null && eachDS.Lead__r.Deal_Registration__r.CreatedById != null){
                mapOfDealSupportIdVsDealRegCreatorId.put(eachDS.id,eachDS.Lead__r.Deal_Registration__r.CreatedById);
            }else if(eachDS.Opportunity__r.Deal_Registration__c != null
                    && eachDS.Opportunity__r.Deal_Registration__r.CreatedById != null){
                mapOfDealSupportIdVsDealRegCreatorId.put(eachDS.id,eachDS.Opportunity__r.Deal_Registration__r.CreatedById);
            }else if(eachDS.Customer_Account__r.Deal_Registration__c != null
                    && eachDS.Customer_Account__r.Deal_Registration__r.CreatedById != null){
                mapOfDealSupportIdVsDealRegCreatorId.put(eachDS.id,eachDS.Customer_Account__r.Deal_Registration__r.CreatedById);
            }

            //Including for secondary Portal Access - starts
            if(eachDS.Lead__c != null && eachDS.Lead__r.Partner_Account__c != null){
                setOfAcctIdsForPortalAccess.add(eachDS.Lead__r.Partner_Account__c);
                mapOfDealSupportIdVSPartnerAcctId.put(eachDS.id,eachDS.Lead__r.Partner_Account__c);
            }else if(eachDS.Opportunity__r.Partner_Account__c != null){
                setOfAcctIdsForPortalAccess.add(eachDS.Opportunity__r.Partner_Account__c);
                mapOfDealSupportIdVSPartnerAcctId.put(eachDS.id,eachDS.Opportunity__r.Partner_Account__c);
            }else if(eachDS.Customer_Account__r.Partner_Account__c != null){
                setOfAcctIdsForPortalAccess.add(eachDS.Customer_Account__r.Partner_Account__c);
                mapOfDealSupportIdVSPartnerAcctId.put(eachDS.id,eachDS.Customer_Account__r.Partner_Account__c);
            }
            if(eachDS.Lead__c != null && eachDS.Lead__r.Country__c != null){
                setOfCountryForGroupSharing.add(eachDS.Lead__r.Country__c);
            }else if(eachDS.Customer_Account__r.billingCountry != null){
                setOfCountryForGroupSharing.add(eachDS.Customer_Account__r.billingCountry);
            }else if(eachDS.Partner_Account__r.billingCountry != null){
                setOfCountryForGroupSharing.add(eachDS.Partner_Account__r.billingCountry);
            }
            if(eachDS.Lead__c != null && eachDS.Lead__r.Lead_Brand_Name__c != null){
                setOfBrandNameForGroupSharing.add(eachDS.Lead__r.Lead_Brand_Name__c);
            }else if(eachDS.Customer_Account__r.RC_Brand__c != null){
                setOfBrandNameForGroupSharing.add(eachDS.Customer_Account__r.RC_Brand__c);
            }else if(eachDS.Partner_Account__r.RC_Brand__c != null){
                setOfBrandNameForGroupSharing.add(eachDS.Partner_Account__r.RC_Brand__c);
            }
            //Including for secondary Portal Access - ends

            //including sharing changes for Partner Channel Manager - starts
            if(eachDS.Lead__c != null && eachDS.Lead__r.Partner_Account__c != null
                    && eachDS.Lead__r.Partner_Account__r.Partner_Channel_Manager__c != null){
                setOfPartnerContactIds.add(eachDS.Lead__r.Partner_Account__r.Partner_Channel_Manager__c);
                mapOfDealSupportIdVsDealRegCAMId.put(eachDS.id,eachDS.Lead__r.Partner_Account__r.Partner_Channel_Manager__c);
            }else if(eachDS.Opportunity__r.Partner_Account__c != null
                    && eachDS.Opportunity__r.Partner_Account__r.Partner_Channel_Manager__c != null){
                setOfPartnerContactIds.add(eachDS.Opportunity__r.Partner_Account__r.Partner_Channel_Manager__c);
                mapOfDealSupportIdVsDealRegCAMId.put(eachDS.id,eachDS.Opportunity__r.Partner_Account__r.Partner_Channel_Manager__c);
            }else if(eachDS.Customer_Account__r.Partner_Account__c != null
                    && eachDS.Customer_Account__r.Partner_Account__r.Partner_Channel_Manager__c != null){
                setOfPartnerContactIds.add(eachDS.Customer_Account__r.Partner_Account__r.Partner_Channel_Manager__c);
                mapOfDealSupportIdVsDealRegCAMId.put(eachDS.id,eachDS.Customer_Account__r.Partner_Account__r.Partner_Channel_Manager__c);
            }
            if(eachDS.Lead__c != null && eachDS.Lead__r.Lead_Brand_Name__c != null){
                brandName = eachDS.Lead__r.Lead_Brand_Name__c;
            }else if(eachDS.Lead__c != null && eachDS.Lead__r.partner_account__c != null && eachDS.Lead__r.Partner_Account__r.RC_Brand__c != null){
                brandName = eachDS.Lead__r.Partner_Account__r.RC_Brand__c;
            }else if(eachDS.Opportunity__c != null && eachDS.Opportunity__r.Deal_Registration__c != null && eachDS.Opportunity__r.Deal_Registration__r.Brand_Name__c != null){
                brandName = eachDS.Opportunity__r.Deal_Registration__r.Brand_Name__c ;
            }else if(eachDS.Opportunity__c != null && eachDS.Opportunity__r.Partner_Account__c != null && eachDS.Opportunity__r.Partner_Account__r.RC_Brand__c != null){
                brandName = eachDS.Opportunity__r.Partner_Account__r.RC_Brand__c ;
            }else if(eachDS.Customer_Account__c != null && eachDS.Customer_Account__r.Deal_Registration__c != null && eachDS.Customer_Account__r.Deal_Registration__r.Brand_Name__c != null){
                brandName = eachDS.Customer_Account__r.Deal_Registration__r.Brand_Name__c;
            }else if(eachDS.Customer_Account__c != null && eachDS.Customer_Account__r.Partner_Account__c != null && eachDS.Customer_Account__r.Partner_Account__r.RC_Brand__c != null){
                brandName = eachDS.Customer_Account__r.Partner_Account__r.RC_Brand__c ;
            }else if(eachDS.Partner_Account__c != null && eachDS.Partner_Account__r.RC_Brand__c != null){
                brandName = eachDS.Partner_Account__r.RC_Brand__c;
            }

            //Set Of Cloud Specialist Contact Ids and Mapping of respective Cloud Specialist to each DS
            if(eachDS.Portal_Cloud_Specialist__c!=null && string.valueOf(eachDS.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')){
                setOfCloudSpecialistContactIds.add(eachDS.Portal_Cloud_Specialist__c);
                mapOfDealSupportIdVsCloudSpecialist.put(eachDS.id,eachDS.Portal_Cloud_Specialist__c);
            }
        }
        if(!setOfPartnerContactIds.isEmpty()){
            List<User> partnerContactUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN: setOfPartnerContactIds AND ContactId!=null];
            Map<Id,Id> mapOfPartnerContactIdVsUserId = new Map<Id,Id>();

            for(User eachUser : partnerContactUsers){
                mapOfPartnerContactIdVsUserId.put(eachUser.ContactId, eachUser.Id);
            }
            for(Id dealSupportId : mapOfDealSupportIdVsDealRegCAMId.keySet()){
                Id contactId = mapOfDealSupportIdVsDealRegCAMId.get(dealSupportId);
                mapOfDealSupportIdVsDealRegCAMId.put(dealSupportId,mapOfPartnerContactIdVsUserId.get(contactId));
            }
        }else{
            mapOfDealSupportIdVsDealRegCAMId = new Map<Id,Id>();
        }
        //including sharing changes for Partner Channel Manager - ends

        //Including for secondary portal access - starts
        Map<Id,Set<Id>> mapOfAcctIdVsUserIdLst = SecondaryPortalAccessUtil.getUserIdListForPartnerAccts(setOfAcctIdsForPortalAccess);
        if(mapOfAcctIdVsUserIdLst != null && mapOfDealSupportIdVSPartnerAcctId != null && !mapOfDealSupportIdVSPartnerAcctId.isEmpty() && !mapOfAcctIdVsUserIdLst.isEmpty()){
            for(Id dealSupportId : mapOfDealSupportIdVSPartnerAcctId.keySet()){
                if(mapOfAcctIdVsUserIdLst.containsKey(mapOfDealSupportIdVSPartnerAcctId.get(dealSupportId))){
                    Set<Id> setOfUserId = mapOfAcctIdVsUserIdLst.get(mapOfDealSupportIdVSPartnerAcctId.get(dealSupportId));
                    if(setOfUserId != null && !setOfUserId.isEmpty()){
                        mapOfDealSupportIdVsUsrLst.put(dealSupportId,setOfUserId);
                    }
                }
            }
        }
        Map<String,Map<String,Id>> mapOfBrandVsCountryGroupIdMap = SecondaryPortalAccessUtil.getGroupIdforCountry(setOfBrandNameForGroupSharing,setOfCountryForGroupSharing);
        Map<Id,Id> mapOfDealSupportIdVsGroupId = new Map<Id,Id>();
        if(mapOfBrandVsCountryGroupIdMap != null && !mapOfBrandVsCountryGroupIdMap.isEmpty()){
            for(Deal_Support__c eachDS : listOfDealSupports){
                String brandNameSharing = '';
                if(eachDS.Lead__r.Lead_Brand_Name__c != null){
                    brandNameSharing = eachDS.Lead__r.Lead_Brand_Name__c;
                }else if(eachDS.Customer_Account__r.RC_Brand__c != null){
                    brandNameSharing = eachDS.Customer_Account__r.RC_Brand__c;
                }else if(eachDS.Partner_Account__r.RC_Brand__c != null){
                    brandNameSharing = eachDS.Partner_Account__r.RC_Brand__c;
                }
                if(!brandName.equals('') && mapOfBrandVsCountryGroupIdMap.containsKey(brandNameSharing)){
                    Map<String,Id> mapOfCountryVsGroupId = mapOfBrandVsCountryGroupIdMap.get(brandNameSharing);
                    if(mapOfCountryVsGroupId != null && !mapOfCountryVsGroupId.isEmpty()){
                        String country = '';
                        if(eachDS.Lead__r.Country__c != null){
                            country = eachDS.Lead__r.Country__c;
                        }else if(eachDS.Customer_Account__r.billingCountry != null){
                            country = eachDS.Customer_Account__r.billingCountry;
                        }else if(eachDS.Partner_Account__r.billingCountry != null){
                            country = eachDS.Partner_Account__r.billingCountry;
                        }
                        if(!country.equals('') && mapOfCountryVsGroupId.containsKey(country)){
                            mapOfDealSupportIdVsGroupId.put(eachDS.Id,mapOfCountryVsGroupId.get(country));
                        }
                    }
                }
            }
        }
        //Including for secondary portal access - ends
        //Cloud Specialist Users and Mapping of respective Cloud Specialist to each DealSupport
        if(setOfCloudSpecialistContactIds!=null && !setOfCloudSpecialistContactIds.IsEmpty() && setOfCloudSpecialistContactIds.size()>0){
            List<User> listOfCloudSpecialistUsers=[Select Id,ContactId from user where ContactId IN: setOfCloudSpecialistContactIds AND ContactId!=null];
            if(listOfCloudSpecialistUsers !=null && !listOfCloudSpecialistUsers.isEmpty() && listOfCloudSpecialistUsers.size()>0){
                for(User user:listOfCloudSpecialistUsers){
                    mapOfCloudSpecialistContactUserId.put(user.ContactId,user.Id);
                }
                for(Id dealSupportId : mapOfDealSupportIdVsCloudSpecialist.keySet()){
                    Id contactId = mapOfDealSupportIdVsCloudSpecialist.get(dealSupportId);
                    mapOfDealSupportIdVsCloudSpecialist.put(dealSupportId,mapOfCloudSpecialistContactUserId.get(contactId));
                }
            }
        }

        return new PartnerDealSupprtAndRegsWrapper(mapOfDealSupportIdVsDealRegOwnerId, setOfAccountIds, mapOfDealSupportIdVsDealRegCreatorId,
                                                   mapOfDealSupportIdVsDealRegCAMId,mapOfDealSupportIdVsUsrLst,brandName,mapOfDealSupportIdVsGroupId,
                                                   mapOfDealSupportIdVsCloudSpecialist,mapofDealWithPartnerIds);
    }

    private class PartnerUsersGroupsWrapper{
        List<User> listOfUsers;
        List<Group> listOfGroups;
        //Bulkify starts
        Map<Id,List<Id>> mapOfPartnerWithGroups;

        public PartnerUsersGroupsWrapper(List<User> listOfUsers, List<Group> listOfGroups,Map<Id,List<Id>> mapOfPartnerWithGroups){
            this.listOfUsers = listOfUsers;
            this.listOfGroups = listOfGroups;
            this.mapOfPartnerWithGroups = mapOfPartnerWithGroups;
        }
        //Bulkify ends
        public PartnerUsersGroupsWrapper(List<User> listOfUsers, List<Group> listOfGroups){
            this.listOfUsers = listOfUsers;
            this.listOfGroups = listOfGroups;
        }
    }

    @TestVisible
    private class PartnerDealSupprtAndRegsWrapper{
        Set<Id> accountIds;
        Map<Id,Id> mapOfDealSupportIdVsDealRegOwnerId;
        Map<Id,Id> mapOfDealSupportIdVsDealRegCreatorId;
        Map<Id,Id> mapOfDealSupportIdVsDealRegCAMId;//Partner Channel Manager
        Map<Id,Set<Id>> mapOfDealSupportIdVsUsrLst;//secondary Portal Access
        Map<Id,Id> mapOfDealSupportIdVsGroupId = new Map<Id,Id>();//secondary Portal Access
        String brandName;
        Map<Id,Id> mapOfDealSupportIdVsCloudSpecialist = new Map<Id,Id>(); //Cloud Specialist
        Map<Id,Set<Id>> mapofDealWithPartnerIds = new  Map<Id,Set<Id>>();//Bulkify

        public PartnerDealSupprtAndRegsWrapper(Map<Id,Id> mapOfDealSupportIdVsDealRegOwnerId, Set<Id> accountIds,
                                               Map<Id,Id> mapOfDealSupportIdVsDealRegCreatorId,
                                               Map<Id,Id> mapOfDealSupportIdVsDealRegCAMId,Map<Id,Set<Id>> mapOfDealSupportIdVsUsrLst,
                                               String brandName,Map<Id,Id> mapOfDealSupportIdVsGroupId,
                                               Map<Id,Id> mapOfDealSupportIdVsCloudSpecialist,Map<Id,Set<Id>> mapofDealWithPartnerIds){
            this.mapOfDealSupportIdVsDealRegOwnerId = mapOfDealSupportIdVsDealRegOwnerId;
            this.accountIds = accountIds;
            this.mapOfDealSupportIdVsDealRegCreatorId = mapOfDealSupportIdVsDealRegCreatorId;
            this.mapOfDealSupportIdVsDealRegCAMId = mapOfDealSupportIdVsDealRegCAMId;//Partner Channel Manager
            this.mapOfDealSupportIdVsUsrLst = mapOfDealSupportIdVsUsrLst;//secondary Portal Access
            this.brandName = brandName;
            this.mapOfDealSupportIdVsGroupId = mapOfDealSupportIdVsGroupId;//secondary Portal Access
            this.mapOfDealSupportIdVsCloudSpecialist=mapOfDealSupportIdVsCloudSpecialist; //Cloud Specialist
            this.mapofDealWithPartnerIds = mapofDealWithPartnerIds;//bulkify
        }
    }
    //Added for Bulkify
    private static PartnerUsersGroupsWrapper getPartnerUsersAndGroupsNew(Set<Id> setOfPartnerAccountIds,
                                                                         Boolean addPartnerAccountIds)
    {
        //partner id with developer name map
        Map<Id,Set<String>> partnerIdWithDeveloper = new Map<Id,Set<String>>();
        //developer name with related id map
        Map<String,Id> developerNameWithRelatedIds = new Map<String,Id>();
        //related id with groupid MAP
        Map<Id,List<Id>> relatedIdwithGroupIds = new Map<Id,List<Id>>();
        //Final map PartnerId with groupids
        Map<Id,List<Id>> mapOfPartnerWithGroups = new Map<Id,List<Id>>();
        Map<Id,Id> mapofdeveloperNamewithId = new Map<Id,Id>();

        if(addPartnerAccountIds){
            Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
            if(null!=comDetail){
                Id parentPartnerAccount = comDetail.Portal_Top_Master_Account_Id__c;
                if(!setOfPartnerAccountIds.contains(parentPartnerAccount)){
                setOfPartnerAccountIds.add(parentPartnerAccount);
               }
            }
            Id partnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
            Id masterPartnerAccount = PartnerDealRegistrationUtil.getCurrentUserPartnerAccount();

            setOfPartnerAccountIds.add(partnerAccount);
            setOfPartnerAccountIds.add(masterPartnerAccount);
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
                partnerIdWithDeveloper.put(eachUser.Contact.AccountId,new Set<String>(tmpList));
            }else{
                partnerIdWithDeveloper.get(eachUser.Contact.AccountId).add(eachUser.UserRole.DeveloperName);
            }
        }
        System.debug('partnerIdWithDeveloper++'+partnerIdWithDeveloper);
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
            tmpList1 = new List<String>(partnerIdWithDeveloper.get(partnerId));
            groupIdsFinal = new List<Id>();
            for(String developerName :tmpList1){
               groupIdsFinal.addall(mapOfDeveloperNameWithGrpIds.get(developerName));
            }
            mapOfPartnerWithGroups.put(partnerId,groupIdsFinal);
        }
        return new PartnerUsersGroupsWrapper(listOfPartnerAccountUsers, listOfGroups,mapOfPartnerWithGroups);
    }
}