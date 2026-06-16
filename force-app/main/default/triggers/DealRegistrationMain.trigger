trigger DealRegistrationMain on Deal_Registration__c(before insert, before update, after insert, after update) {
  if (Test.isRunningTest()) {
    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Deal_Registration__c == true) {
      System.debug('$$$ ByPassTrigger__c Active For Deal Registration $$$');
      return;
    }
  }

  if (Trigger.isInsert && Trigger.isBefore) {
    try {
      Set <String> partnerContactIds = new Set <String> ();
      for (Deal_Registration__c dealReg: Trigger.NEW) {
        if (dealReg.Partner_Contact__c != NULL) {
          partnerContactIds.add(dealReg.Partner_Contact__c);
        }
      }
      Map <Id, Contact> partnerContactsMap = null;
      Map <String, String> partnerContactIdUserIdMap = null;
      if (partnerContactIds.size()> 0) {
        partnerContactsMap = new Map <Id, Contact> ([SELECT Id, AccountId, Account.Partner_ID__c
          FROM Contact WHERE Id IN: partnerContactIds
        ]);
        partnerContactIdUserIdMap = new Map <String, String> ();
        for (User u: [SELECT Id, Name, ContactId, Contact.AccountId FROM User WHERE ContactId IN: partnerContactIds AND isActive = true]) {
          partnerContactIdUserIdMap.put(u.ContactId, u.Id);
        }
      }

      User currentUser = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Partner_ID__c, Contact.Account.Master_Agent_Channel_Manager__c,
          Profile.UserLicense.Name
          FROM User WHERE Id =: UserInfo.getUserId()
      ];

      Boolean isGuest = false;
      String CommunityName;
      if (currentUser.Profile.UserLicense.Name == 'Guest User License') {
        isGuest = true;
      }
      List <Network> network = [Select id, Name from Network where Id =: Network.getNetworkId()];
      if (network != null && network.size()> 0) {
        CommunityName = network[0].Name;
      }
      List <Community_Details__mdt> commDetails = [select Brand_Name__c, Portal_Deal_Desk_User__c from Community_Details__mdt where MasterLabel =: CommunityName];
      Map <String, Community_Details__mdt> BrandNametoComDetailMap = new Map <String, Community_Details__mdt> ();
      List <String> brandNamesofCommunity = new List <String> ();
      for (Community_Details__mdt commDetail: commDetails) {
        brandNamesofCommunity = commDetail.Brand_Name__c.split(';');
        for (String brandName: brandNamesofCommunity) {
          BrandNametoComDetailMap.put(brandName, commDetail);
        }
      }

      for (Deal_Registration__c dealReg: Trigger.NEW) {
        dealReg.Street__c = dealReg.Address__c;
        if (dealReg.Partner_Contact__c != NULL) {
          dealReg.Partner_Account__c = partnerContactsMap != NULL ? partnerContactsMap.get(dealReg.Partner_Contact__c).AccountId : currentUser.Contact.AccountId;
          dealReg.Partner_Id__c = partnerContactsMap != NULL ? partnerContactsMap.get(dealReg.Partner_Contact__c).Account.Partner_ID__c : currentUser.Contact.Account.Partner_ID__c;
          if (isGuest) {
            dealReg.OwnerId = BrandNametoComDetailMap.get(dealReg.Brand_Name__c).Portal_Deal_Desk_User__c;
          } else {
            dealReg.OwnerId = (partnerContactIdUserIdMap != NULL && partnerContactIdUserIdMap.get(dealReg.Partner_Contact__c) != NULL) ?
              partnerContactIdUserIdMap.get(dealReg.Partner_Contact__c) : currentUser.Id;
          }
        } else {
          dealReg.Partner_Account__c = currentUser.Contact.AccountId;
          dealReg.Partner_Contact__c = currentUser.ContactId;
          dealReg.Partner_Id__c = currentUser.Contact.Account.Partner_ID__c;
        }
        //Status should be 'Pending Approval when RC_Overlay__c != API.
        if(dealReg.RC_Overlay__c != 'API') {
          dealReg.Status__c = 'Pending Approval';
        } else {
          dealReg.Status__c = 'Approved';
        }
        if (dealReg.Existing_Solution_Provider_Others__c instanceOf Id && ((Id) dealReg.Existing_Solution_Provider_Others__c).getSObjectType().getDescribe().getName() == 'User') {
            dealReg.AgencyRep__c = dealReg.Existing_Solution_Provider_Others__c;
        }

        //Added For Cloud Specialist Mapping
        if (dealReg.Portal_Cloud_Specialist__c == null && dealReg.Avaya_Cloud_Specialist__c != null && dealReg.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')) {
          dealReg.Portal_Cloud_Specialist__c = dealReg.Avaya_Cloud_Specialist__c;
        }
      }
    } catch (Exception exp) {
      system.debug(exp.getMessage());
      system.debug('Line Number-->' + exp.getLineNumber());
    }
  }

  if (Trigger.isUpdate && Trigger.isBefore) {
    for (Deal_Registration__c dealReg: Trigger.NEW) {
      if (dealReg.Brand_Name__c != 'Rainbow Office' && dealReg.Avaya_Cloud_Specialist__c != null && dealReg.Avaya_Cloud_Specialist__c.startsWithIgnoreCase('003')) {
        //pbc-10695
        dealReg.Portal_Cloud_Specialist__c = dealReg.Avaya_Cloud_Specialist__c;
      }
    }
    for(Id dealId : trigger.newMap.keyset()) {
         //pbc-10695
      	 Deal_Registration__c oldDeal = trigger.oldMap.get(dealId);
         Deal_Registration__c newDeal = trigger.newMap.get(dealId);

         if(newDeal != null && oldDeal != null && newDeal.Brand_Name__c == 'Rainbow Office' &&
            (newDeal.Portal_Cloud_Specialist__c != oldDeal.Portal_Cloud_Specialist__c) &&
            (newDeal.Portal_Cloud_Specialist__c != newDeal.Avaya_Cloud_Specialist__c)) {
             newDeal.Avaya_Cloud_Specialist__c = newDeal.Portal_Cloud_Specialist__c;
            }
         if(newDeal != null && oldDeal != null && newDeal.Brand_Name__c == 'Rainbow Office' &&
            (newDeal.Avaya_Cloud_Specialist__c != oldDeal.Avaya_Cloud_Specialist__c) &&
          	(newDeal.Avaya_Cloud_Specialist__c != newDeal.Portal_Cloud_Specialist__c)) {
             newDeal.Portal_Cloud_Specialist__c = newDeal.Avaya_Cloud_Specialist__c;
            }
     }
  }

  if (Trigger.isInsert && Trigger.isAfter) {
    Set<Id> dealRegsToBeUpdated = new Set<Id>();

    //Do this step only when RC_Overlay__c != API.
    for(Id dealRegId : trigger.newMap.keyset()) {
      Deal_Registration__c dealReg = trigger.newMap.get(dealRegId);
      if(dealReg.RC_Overlay__c != 'API') {
        dealRegsToBeUpdated.add(dealRegId);
      }
    }

    //Share Deals
    Quote_SharingHandler.handleDealRegistrationShareFuture(dealRegsToBeUpdated);
    //Perform Duplicate Check
    PartnerDealRegistrationUtil.performDuplicateCheck(dealRegsToBeUpdated);
  }

  if (Trigger.isUpdate && Trigger.isAfter) {
    Set <Id> dealSharingIds = new Set <Id> ();
    List <Deal_Registration__c> dealToCreateAsLeads = new List <Deal_Registration__c> ();
    for (Deal_Registration__c dealReg: Trigger.NEW) {
      if (Trigger.OldMap.get(dealReg.Id).Status__c != dealReg.Status__c && dealReg.Status__c == 'Approved') {
        dealToCreateAsLeads.add(dealReg);
      }
      if (dealReg.Portal_Cloud_Specialist__c != null &&
        Trigger.OldMap.get(dealReg.Id).Portal_Cloud_Specialist__c != dealReg.Portal_Cloud_Specialist__c &&
        string.valueOf(dealReg.Portal_Cloud_Specialist__c).startsWithIgnoreCase('003')) {
        dealSharingIds.add(dealReg.Id);
      }
    }

    if (dealSharingIds != null && !dealSharingIds.IsEmpty() && dealSharingIds.size()> 0) {
      Quote_SharingHandler.handleDealRegistrationShareFuture(dealSharingIds);
    }
    if (dealToCreateAsLeads.size()> 0) {
      //Create Leads
      List <Lead> leadsCreated = PartnerDealRegistrationUtil.AddDealAsLead(dealToCreateAsLeads);
      if (leadsCreated.size()> 0) {
        //Share Leads
        Set <Id> setOfLeadIds = new Set <Id> ();
        for (Lead eachLead: leadsCreated) {
          setOfLeadIds.add(eachLead.Id);
        }
        Sharing_AccountLeadHandler.handleLeadShare(setOfLeadIds);
      }
    }
  }
}