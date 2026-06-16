public with sharing class Partner_LookupSearchController{
  //Method to get all partners
  @AuraEnabled
  public static PartnerSearchWrapper getPartnerData(String searchKeyWord, boolean isMasterPartner, String searchBy, boolean isCurrentContactPCM, boolean isSingleLogin, boolean isNew){
    String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
    PartnerSearchWrapper objSW = new PartnerSearchWrapper();
    String query = '';
    List<Contact> listOfCurrentContacts = new List<Contact>();
    String currentContactPartnerPortalView = '';
    CommunityInfo comm = new CommunityInfo();
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
    List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
    objSW.partnerCommunityName = brandNamesList;
    String AvayaOffice = '';
    if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
      AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
    }
    String slist = '';
    if (brandNamesList != null && brandNamesList.size() > 0){
      for (String s : brandNamesList){
        slist += '\'' + s + '\',';
      }
      slist = slist.substring(0, slist.length() - 1);
    }

    Id userId = UserInfo.getUserId();
    Set<Id> setUserAccIds = new Set<Id>();
    for (User_Account_Mapping__c uam : [Select Id, Partner_Account__c, Partner_Contact__c from User_Account_Mapping__c where Partner_User__c = :userId]){
      setUserAccIds.add(uam.Partner_Contact__c);
    }
    List<User> userList = [Select ContactId from User where Id = :userId];
    Id contactId = userList[0].ContactId;

    if (!isMasterPartner){
      if (brandNamesList.contains('Avaya Cloud Office')){
        if (!isNew){
          //Added Permitted_Countries__c for multiple countries for ACO 3.0
          query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.Master_Agent_Channel_Manager__c, Account.VAR_Territory__c,Account.Partner_Type__c,Account.BusinessIdentity__c, ' + 
                'Permitted_Countries__c FROM Contact ' + 
                ' Where Account.type= ' + '\'Partner\' AND Account.Partner_Hierarchy_Level__c  = \'Reseller\' And Account.Avaya_partnership_account__c = true And Avaya_partnership_contact__c = true And (AccountId = \'' + selectedPartnerAccount + '\' OR Account.Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Account.Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\') and (Account.Permitted_Brands__c != null AND Account.Permitted_Brands__c INCLUDES (' + slist + '))';
        }
        //Single Login code starts
        else if (isNew && isSingleLogin){
          query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.Territory__c,Account.VAR_Territory__c,Account.Partner_Type__c,Account.Master_Agent_Channel_Manager__c,Account.BusinessIdentity__c, ' + 
                'Permitted_Countries__c FROM Contact ' + 
                ' Where Account.type= ' + '\'Partner\' AND Account.Partner_Hierarchy_Level__c  = \'Reseller\' And Account.Avaya_partnership_account__c = true And (Id =: contactId Or Id IN: setUserAccIds) and (Account.Permitted_Brands__c != null OR Account.Permitted_Brands__c INCLUDES (' + slist + '))';
        }
        //Single Login code ends
        listOfCurrentContacts = PartnerDealRegistrationUtil.getCurrentUserPartnerContact();

        if (isCurrentContactPCM && !isSingleLogin){
          if (listOfCurrentContacts != null && !listOfCurrentContacts.isEmpty() && listOfCurrentContacts.size() > 0){
            String currentPCMId = listOfCurrentContacts[0].Id;
            Set<Id> setOfSecondaryPCMAccountIds = new Set<Id>();
            List<Portal_Access__c> listOfPortalAccess = [select id, account__c, contact__c from Portal_Access__c where contact__c = :currentPCMId];
            if (listOfPortalAccess != null && !listOfPortalAccess.isEmpty() && listOfPortalAccess.size() > 0){
              for (Portal_Access__c portal : listOfPortalAccess){
                if (portal.account__c != null) {
                  setOfSecondaryPCMAccountIds.add(portal.account__c);
                }
              }
            }
            query += ' And (Account.Partner_Channel_Manager__c=\'' + currentPCMId + '\' OR Account.Id IN: setOfSecondaryPCMAccountIds)';
          }
        }
      } else{
        if (!isNew){
          //Added Permitted_Countries__c for multiple countries for ACO 3.0
          if (brandNamesList.contains('Unify Office') && comDetail != null && comDetail.Portal_Top_Master_Account_Id__c == selectedPartnerAccount){
            query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.Master_Agent_Channel_Manager__c, Account.VAR_Territory__c,Account.Partner_Type__c,Account.BusinessIdentity__c, ' + 
         'Permitted_Countries__c,Account.Inside_Sales_Rep__c FROM Contact ' + 
         ' Where Account.type= ' + '\'Partner\' AND Account.Partner_Hierarchy_Level__c  = \'Reseller\' And Account.Avaya_partnership_account__c = true And Avaya_partnership_contact__c = true And (Account.Permitted_Brands__c != null AND Account.Permitted_Brands__c INCLUDES (' + slist + '))';
          } else{
            query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.Master_Agent_Channel_Manager__c, Account.VAR_Territory__c,Account.Partner_Type__c,Account.BusinessIdentity__c, ' + 
         'Permitted_Countries__c,Account.Inside_Sales_Rep__c,Account.Partner_Classification__c FROM Contact ' + 
         ' Where Account.type= ' + '\'Partner\' AND Account.Partner_Hierarchy_Level__c  = \'Reseller\' And Account.Avaya_partnership_account__c = true And Avaya_partnership_contact__c = true And (Account.Permitted_Brands__c != null AND Account.Permitted_Brands__c INCLUDES (' + slist + '))  And (AccountId = \'' + selectedPartnerAccount + '\' OR Account.Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Account.Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\')';
          }
        } else if (isNew && isSingleLogin){
          //Added Permitted_Countries__c for multiple countries for ACO 3.0
          query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.Territory__c,Account.VAR_Territory__c,Account.Partner_Type__c,Account.Master_Agent_Channel_Manager__c,Account.BusinessIdentity__c, ' + 
         'Permitted_Countries__c,Account.Inside_Sales_Rep__c,Account.Partner_Classification__c FROM Contact ' + 
         ' Where Account.type= ' + '\'Partner\' AND Account.Partner_Hierarchy_Level__c  = \'Reseller\' And Account.Avaya_partnership_account__c = true And Account.Permitted_Brands__c INCLUDES(' + slist + ')  And (Id =: contactId Or Id IN: setUserAccIds)';
        }
        if (isMasterPartner){
          query += ' And Account.Partner_Role__c=' + '\'Master Agent\'';
        }
      }
      if (null != searchKeyWord && searchKeyWord != ''){
        if (searchBy == 'contact'){
          String searchKey = '\'%' + searchKeyWord + '%\'';
          query += ' And ' + 'Name' + ' Like ' + searchKey;
        } else{
          String searchKey = '\'%' + searchKeyWord + '%\'';
          query += ' And ' + 'Account.Name' + ' Like ' + searchKey;
        }
      } else{
        query = query + ' LIMIT 10';
      }
      objSW.partnerContactList = Database.query(query);
    } else{
      objSW.partnerContactList = getContactAccountsForMaster(selectedPartnerAccount, searchKeyWord, searchBy);
    }

    return objSW;
  }
  @AuraEnabled
  public static PartnerSearchWrapper getPartnerAccountData(String searchKeyWord){
    List<Account> lstPartnerAccounts = new List<Account>();
    Account currentPartnerAccount = new Account();
    PartnerSearchWrapper objSW = new PartnerSearchWrapper();
    String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
    String query = '';
    String currentContactPartnerPortalView = '';
    List<Contact> listOfCurrentContacts = new List<Contact>();

    CommunityInfo comm = new CommunityInfo();
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
    List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
    objSW.partnerCommunityName = brandNamesList;
    String AvayaOffice = '';
    if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
      AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
    }
    String slist = '';
    if (brandNamesList != null && brandNamesList.size() > 0){
      for (String s : brandNamesList){
        slist += '\'' + s + '\',';
      }
      slist = slist.substring(0, slist.length() - 1);
    }

    if (brandNamesList.contains('Avaya Cloud Office')){
      query = 'select Id, Name,Partner_ID__c,Permitted_Brands__c,Partner_country__c,Partner_Account__r.Name' + 
       ' FROM Account ' + 
       ' Where Type= ' + '\'Partner\' And Avaya_partnership_account__c = true And (Id = \'' + selectedPartnerAccount + '\' OR Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\') and (Permitted_Brands__c != null AND Permitted_Brands__c INCLUDES (' + slist + '))';
      listOfCurrentContacts = PartnerDealRegistrationUtil.getCurrentUserPartnerContact();
      if (listOfCurrentContacts != null && !listOfCurrentContacts.isEmpty() && listOfCurrentContacts.size() > 0) {
        currentContactPartnerPortalView = listOfCurrentContacts[0].Partner_Portal_View__c;
      }
    } else{
      if (brandNamesList.contains('Unify Office') && comDetail != null && comDetail.Portal_Top_Master_Account_Id__c == selectedPartnerAccount){
        query = 'select Id, Name,Partner_ID__c,Permitted_Brands__c,Partner_country__c,Partner_Account__r.Name' + 
                ' FROM Account ' + 
                ' Where Type= ' + '\'Partner\' And Avaya_partnership_account__c = true And (Permitted_Brands__c != null AND Permitted_Brands__c INCLUDES(' + slist + '))';
      } else{
        query = 'select Id, Name,Partner_ID__c,Permitted_Brands__c,Partner_country__c,Partner_Account__r.Name' + 
                ' FROM Account ' + 
                ' Where Type= ' + '\'Partner\' And Avaya_partnership_account__c = true And (Permitted_Brands__c != null AND Permitted_Brands__c INCLUDES(' + slist + '))  And (Id = \'' + selectedPartnerAccount + '\' OR Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\')';
      }
    }

    if (null != searchKeyWord && searchKeyWord != ''){
      String searchKey = '\'%' + searchKeyWord + '%\'';
      query += ' And ' + 'Name' + ' Like ' + searchKey;
    }
    query += ' order by Name';
    for (Account a : Database.query(query)){
      if (a.Id != selectedPartnerAccount){
        lstPartnerAccounts.add(a);
      } else{
        currentPartnerAccount = a;
      }
    }

    objSW.partnerAccountList = new List<Account>();
    Integer size = 0;
    if (null != searchKeyWord && searchKeyWord != ''){
      size = lstPartnerAccounts.size();
    } else{
      size = 5;
      objSW.partnerAccountList.add(currentPartnerAccount);
    }
    if (lstPartnerAccounts.size() > 0){
      for (Integer i = 0; i < lstPartnerAccounts.size(); i++){
        objSW.partnerAccountList.add(lstPartnerAccounts[i]);
        if (i > size - 1) {
          break;
        }
      }
    }

    return objSW;
  }
  public static List<Contact> getContactAccountsForMaster(String selectedPartnerAccount, String searchKeyWord, String searchBy){
    List<Account> partnerAccountList = new List<Account>();
    List<Contact> partnerContactList = new List<Contact>();
    String contactQuery = '';
    String query = '';
    String currentContactPartnerPortalView = '';
    List<Contact> listOfCurrentContacts = new List<Contact>();
    CommunityInfo comm = new CommunityInfo();
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
    List<String> brandNamesList = comDetail.Brand_Name__c.split(';');

    String slist = '';
    if (brandNamesList != null && brandNamesList.size() > 0){
      for (String s : brandNamesList){
        slist += '\'' + s + '\',';
      }
      slist = slist.substring(0, slist.length() - 1);
    }

    String AVAYAOFFICE = '';
    if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
      AVAYAOFFICE = String.valueOf(System.Label.AVAYACLOUDOFFICE);
    }
    if (null != searchKeyWord && searchKeyWord != ''){
      if (searchBy == 'contact'){
        String searchKey = '\'%' + searchKeyWord + '%\'';
        contactQuery += ' where ' + 'Name' + ' Like ' + searchKey;
      } else{
        String searchKey = '\'%' + searchKeyWord + '%\'';
        contactQuery += ' where ' + 'Account.Name' + ' Like ' + searchKey;
      }
    }
    if (brandNamesList.contains('Avaya Cloud Office')){

      //Added Permitted_Countries__c for multiple countries for ACO 3.0
      query = 'select id,name,Permitted_Brands__c,(select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Permitted_Countries__c FROM Contacts ' + contactQuery + 'LIMIT 1) from account where type= ' + '\'Partner\' And Avaya_partnership_account__c = true And (Id = \'' + selectedPartnerAccount + '\' OR Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\') and (Permitted_Brands__c != null  AND  Permitted_Brands__c INCLUDES (' + slist + '))';
      listOfCurrentContacts = PartnerDealRegistrationUtil.getCurrentUserPartnerContact();
    } else{
      //Added Permitted_Countries__c for multiple countries for ACO 3.0
      query = 'select id,name,Permitted_Brands__c,(select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Permitted_Countries__c,Account.Partner_Classification__c FROM Contacts ' + contactQuery + 'LIMIT 1) from account where type= ' + '\'Partner\' And Avaya_partnership_account__c = true And (Id = \'' + selectedPartnerAccount + '\' OR Partner_Account__c = \'' + selectedPartnerAccount + '\' OR Parent_Partner_Account__c = \'' + selectedPartnerAccount + '\') and (Permitted_Brands__c != null AND Permitted_Brands__c INCLUDES (' + slist + '))';
    }

    query += ' And Partner_Role__c=' + '\'Master Agent\'';
    if (searchKeyWord == ''){
      query = query + ' LIMIT 50';
    }
    partnerAccountList = Database.query(query);
    for (Account accObj : partnerAccountList){
      if (accObj.Contacts.size() > 0){
        partnerContactList.add(accObj.Contacts.get(0));
      }
    }
    return partnerContactList;
  }
  //Translation Start
  @AuraEnabled
  public static CommunityInfo.Translationswrap getTranslations(String objNames){
    return CommunityInfo.getTranslations(objNames);
  }
  //Translation End
  @AuraEnabled
  public static PartnerSearchWrapper getPartnerDataforSFDC(String searchKeyWord, String searchBy, boolean isSFDC, String brandName){
    PartnerSearchWrapper objSW = new PartnerSearchWrapper();
    String brands = '';
    brands += '\'' + brandName + '\'';

    String query = '';
    List<Contact> listOfCurrentContacts = new List<Contact>();
    String AvayaOffice = '';
    if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
      AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
    }
    if (brandName == 'Avaya Cloud Office'){
      query = 'select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.BusinessIdentity__c,' + 
         ' Account.Territory__c,Account.VAR_Territory__c,Account.Partner_Type__c,Account.Master_Agent_Channel_Manager__c FROM Contact ' + 
         ' Where Account.type= ' + '\'Partner\' And Account.Avaya_partnership_account__c = true and (Account.Permitted_Brands__c != null  AND  Account.Permitted_Brands__c INCLUDES (' + brands + '))';// and Id IN \''+userId+'\'
    } else{
      //PBC-9705 P2CSharing PartnerClassification
      query = 'Select Id, Name,Account.Name,Account.Id,Phone,Email,Account.Partner_ID__c,Account.Partner_Classification__c,Account.Partner_country__c,Account.Partner_Account__r.Name,Account.Permitted_Brands__c,Account.BusinessIdentity__c,' + 
      ' Account.Territory__c,Account.VAR_Territory__c,Account.Partner_Type__c,Account.Master_Agent_Channel_Manager__c FROM Contact ' + 
      ' Where Account.type= ' + '\'Partner\' And Account.Avaya_partnership_account__c = true And (Account.Permitted_Brands__c != null AND Account.Permitted_Brands__c INCLUDES (' + brands + '))';// and Id IN \''+userId+'\'
    }
    if (null != searchKeyWord && searchKeyWord != ''){
      if (searchBy == 'contact'){
        String searchKey = '\'%' + searchKeyWord + '%\'';
        query += ' And ' + 'Name' + ' Like ' + searchKey;
      } else{
        String searchKey = '\'%' + searchKeyWord + '%\'';
        query += ' And ' + 'Account.Name' + ' Like ' + searchKey;
      }
    } else{
      query = query + ' LIMIT 10';
    }
    objSW.partnerContactList = Database.query(query);

    return objSW;
  }
  public class PartnerSearchWrapper{
    @AuraEnabled
    public List<Contact> partnerContactList{ get; set; }
    @AuraEnabled
    public List<Account> partnerAccountList{ get; set; }
    @AuraEnabled
    public List<String> partnerCommunityName{ get; set; }
  }
}