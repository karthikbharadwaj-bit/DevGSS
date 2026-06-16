/*      
* Created By    : Girish
* Created Date  : 22-11-2019
* Description   : Controller class for Partner details component
* Test Class    :       

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date            Description                                 Tag
Reseller Requests   Ishwarya        12/11/2019      Updated logic to display reseller requests   T1
********************************************************************************************************************
*/
public class PartnerDetailsController {
    
    public static String selectedUserAccountId {get;set;}
    public static String selectedUserPartnerAccountId {get;set;}
    public static String selUserUltimatePartnerAccountId {get;set;}
    public static String selectedUserContactId {get;set;}    
    
    @AuraEnabled
    public static PartnerWrapper loadPartnersAndUsers(String searchKeyWord, String searchBy, Decimal pageNumber, Decimal pageSize){
        List<Partner> retList = new List<Partner>();
        Set<Id> accountIdSet = new Set<Id>(); 
        Map<Id,List<PartnerUser>> usersForAccountMap = new Map<Id,List<PartnerUser>>();   
        List<Account> partnerAccounts = new List<Account>();
        PartnerWrapper pw = new PartnerWrapper();
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;
        Integer totalRecords;
        String query = '';
        String currentContactPartnerPortalView='';
        List<Contact> listOfCurrentContacts=new List<Contact>();
        
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        pw.communityDetailsRecord=comDetail;
        pw.partnerMasterLabel = comDetail.MasterLabel;
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        UserWrapper uw = checkUserRole();
        
        String AVAYAOFFICE = '';
         if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AVAYAOFFICE=String.valueOf(System.Label.AVAYACLOUDOFFICE);
         }
        if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null 
           && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords=1000;
        }
        selectedUserAccountId = PartnerDealRegistrationUtil.getSelectedPartnerId();
        System.debug('selectedUserAccountId+++ '+selectedUserAccountId);
        if(brandNamesList.contains('Avaya Cloud Office')){
            query = 'select count() from account '+
                'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ') AND type='+'\'Partner\' and isPartner=true and PartnerStatus__c!='+'\'Declined\' and Avaya_partnership_account__c = true and (RC_Brand__c = null OR RC_Brand__c = \''+AVAYAOFFICE+'\')';
           
            System.debug('query1+++ '+query);
            system.debug('total size - ' + Database.countquery(query));   
        }else{
            if(brandNamesList.contains('Unify Office') && 
            comDetail != null && 
            selectedUserAccountId == comDetail.Portal_Top_Master_Account_Id__c) {
                query = 'select count() from account '+
                'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ' OR Partner_Account__r.Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ') AND type='+'\'Partner\' and isPartner=true And PartnerStatus__c!='+'\'Declined\'and Avaya_partnership_account__c = true and RC_Brand__c  IN: brandNamesList';
            }
            else {
            query = 'select count() from account '+
                'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                ') AND type='+'\'Partner\' and isPartner=true And PartnerStatus__c!='+'\'Declined\'and Avaya_partnership_account__c = true and RC_Brand__c  IN: brandNamesList';
            }
        }
        
        if(null!= searchKeyWord){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            query += ' And '+ searchBy+ ' Like '+searchKey;
        }   
        Integer totSize = Database.countquery(query);
        System.debug('query2+++ '+query);
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        
        if(null!=totalRecords && totalRecords > 0){    
            if(brandNamesList.contains('Avaya Cloud Office')){
                query = 'select id,Partner_Role__c, SID__c,name,phone, ownerid, owner.name, billingCity,billingState,BillingPostalCode, '+
                    'Parent_Partner_Account__c,Partner_Account__c,Partner_ID__c,External_SID__c,Partner_Account__r.Name, Partner_Channel_Manager__c,Master_Agent_Channel_Manager__c FROM Account '+
                    'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ') AND type='+'\'Partner\'  and isPartner=true and PartnerStatus__c!='+'\'Declined\' and Avaya_partnership_account__c = true and (RC_Brand__c = null OR RC_Brand__c = \''+AVAYAOFFICE+'\')'; 
            }else{
                if(brandNamesList.contains('Unify Office') && 
                comDetail != null && 
                selectedUserAccountId == comDetail.Portal_Top_Master_Account_Id__c) {
                    query = 'select id,Partner_Role__c, SID__c,name,phone, ownerid, owner.name, billingCity,billingState,BillingPostalCode, '+
                    'Parent_Partner_Account__c,Partner_Account__c,Partner_ID__c,External_SID__c,Partner_Account__r.Name, Partner_Channel_Manager__c,Master_Agent_Channel_Manager__c FROM Account '+
                    'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ' OR Partner_Account__r.Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ') AND type='+'\'Partner\'  and isPartner=true And PartnerStatus__c!='+'\'Declined\' and Avaya_partnership_account__c = true and RC_Brand__c IN: brandNamesList';
                }
                else {
                    query = 'select id,Partner_Role__c, SID__c,name,phone, ownerid, owner.name, billingCity,billingState,BillingPostalCode, '+
                    'Parent_Partner_Account__c,Partner_Account__c,Partner_ID__c,External_SID__c,Partner_Account__r.Name, Partner_Channel_Manager__c,Master_Agent_Channel_Manager__c FROM Account '+
                    'WHERE (Parent_Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ' OR Partner_Account__c ='+'\''+selectedUserAccountId+'\''+
                    ') AND type='+'\'Partner\'  and isPartner=true And PartnerStatus__c!='+'\'Declined\' and Avaya_partnership_account__c = true and RC_Brand__c IN: brandNamesList';
                }
            }
            
            if(null!= searchKeyWord){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                query += ' And '+ searchBy+ ' Like '+searchKey;
            } 
            System.debug('psize offset'+pSize+' : '+offset);
            query += '  Order By CreatedDate DESC LIMIT :pSize OFFSET :offset'; 
            System.debug('query2+++ '+query);
            partnerAccounts = Database.query(query);
            pw.isAvaya = false;
            
            for(Account a: partnerAccounts){
                accountIdSet.add(a.id);
            }
            
            List<Contact> partnerUsers = [select id,accountid, name,email, phone, ownerid, owner.name
                                          from Contact
                                          where accountid in:accountIdSet];
            
            if(partnerUsers.size()>0) {
                pw.listContact=partnerUsers;                              
            }
            for(Contact con:partnerUsers){
                PartnerUser partnerUser = new PartnerUser();                
                partnerUser.name = con.id;
                partnerUser.userName = con.name;
                partnerUser.phone = con.phone;
                partnerUser.owner = URL.getOrgDomainUrl().toExternalForm()+'/'+con.ownerid;
                partnerUser.ownerName = con.owner.name;
                
                if(null!=usersForAccountMap && usersForAccountMap.keySet()!=null 
                   && usersForAccountMap.keySet().contains(con.accountid)){                   
                       usersForAccountMap.get(con.accountid).add(partnerUser);                
                   }else{
                       List<PartnerUser> tempList = new List<PartnerUser>();
                       tempList.add(partnerUser);
                       usersForAccountMap.put(con.accountid,tempList);
                   }            
            }
            
            for(Account a: partnerAccounts){
                Partner partnerAccount = new Partner();
                partnerAccount.name = a.id;
                partnerAccount.accountName = a.name;
                partnerAccount.phone = a.phone;
                partnerAccount.owner = URL.getOrgDomainUrl().toExternalForm()+'/'+a.ownerid;
                partnerAccount.ownerName = a.owner.name;
                partnerAccount.billingCity = a.billingCity;
                partnerAccount.partnerUsers = usersForAccountMap.get(a.id);
                if(usersForAccountMap.containskey(a.id)){
                    partnerAccount.contacts = String.valueOf(usersForAccountMap.get(a.id).size());
                }
                partnerAccount.billingState=a.billingState;
                partnerAccount.billingPostalCode=a.BillingPostalCode;
                partnerAccount.partnerId=a.Partner_ID__c;
                partnerAccount.externalSID=a.External_SID__c;
                partnerAccount.partnerAccountName=a.Partner_Account__r.Name;
                partnerAccount.partnerChannelManager =a.Master_Agent_Channel_Manager__c;
                retList.add(partnerAccount);            
            }        
            pw.partnerList = JSON.serializePretty(retList);
            pw.listPartner=retList;
        } 
        pw.pageSize = pSize;
        pw.pageNumber = pNumber;
        pw.recordStart = offset + 1;
        pw.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        pw.totalRecords = totalRecords;
        pw.isReadOnly=isReadOnlyProfile;
        
        
        pw.isAvaya = uw.isAvaya;
        pw.isMasterAgent = uw.isMasterAgent;        
        pw.partnerCommunityName= brandNamesList;
        pw.portalTopMasterName=uw.portalTopMasterName;
        pw.portalTopMasterPartnerId=uw.portalTopMasterPartnerId;
        
        return pw;
    }  
    
    // Added for JIRA - 6994 start
    @AuraEnabled
    public static PickListWrapperForCountry getBusinessCountryStateMap(){
      PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
      Map<String,List<String>> countryStateMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Partner_Request__c.Partner_State__c);
       picklistWrapperObj.countryStateMap = countryStateMap;
       Community_Details__mdt commDetail = CommunityInfo.getCommunityDetails();
       List<Community_Detail_Child__mdt> commChildsList = [Select Id, Country_Name__c from Community_Detail_Child__mdt where Community_Details__c =: commDetail.Id];
       Set<String> countriesSet = new Set<String>();
       for(Community_Detail_Child__mdt commChild : commChildsList) {
           countriesSet.add(commChild.Country_Name__c);
       }
       picklistWrapperObj.availableCountries = countriesSet;

       List<String> brandNamesList = commDetail.Brand_Name__c.split(';');
       List<CountryBusinessIdentityMapping__c> countryMappings = [Select Brand_Name__c, Business_Identity__c, Country__c from CountryBusinessIdentityMapping__c where Brand_Name__c IN : brandNamesList];
       Map<String, Set<String>> BI_CountryMap = new Map<String, Set<String>>();
       for(CountryBusinessIdentityMapping__c countryMapping : countryMappings) {
            Set<String> countries = new Set<String>();
            if(BI_CountryMap.get(countryMapping.Business_Identity__c) != null) {
                countries = BI_CountryMap.get(countryMapping.Business_Identity__c);
            }
            countries.add(countryMapping.Country__c);
            BI_CountryMap.put(countryMapping.Business_Identity__c, countries);
       }
       picklistWrapperObj.mapBusinessCntry = BI_CountryMap;
       picklistWrapperObj.BI_Set = BI_CountryMap.keySet();
        
       return picklistWrapperObj;
    }
   // Added for JIRA - 6994 end
   // Added for PRM -55 start
    @AuraEnabled
    public static PickListWrapperForBillingFeedType getBillingFeedTypeMap(){
        PickListWrapperForBillingFeedType picklistWrapperObj = new PickListWrapperForBillingFeedType();
        Map<String,List<String>> billingFeedTypeMap = ControlAndDependentPicklstMap.getDependentPicklistValues2(Partner_Request__c.Billing_Feed_Type__c);
        picklistWrapperObj.partnrReqbillFeedMap = billingFeedTypeMap;
        return picklistWrapperObj;
    }
    // Added for PRM -55 end
   
    //<T1>*********************
    
    //Translation Start

    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }
    //Translation End
    
     //Translation Start for PRM 80

     @AuraEnabled
     public static CommunityInfo.Translationswrap getTranslations1(String objNames,String selectedLanguage)
     {        
         return CommunityInfo.getTranslations1(objNames,selectedLanguage);
     }
     //Translation End  for PRM 80

    
      //PRM 80 Start
        @AuraEnabled
    public static List<String> getCountryPicklistvalues(String objectName, String fieldapiname,Boolean nullRequired){
        List<String> countryList = new List<String>();        
        Map<String, Schema.SObjectField> fieldmap = ((SObject)Type.forName(objectName.toLowerCase()).newInstance()).getSObjectType().getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = fieldmap.get(fieldapiname).getDescribe().getPickListValues();       
        if(nullRequired == true){
            countryList.add('--None--');
        }       
        for (Schema.PicklistEntry pv : picklistValues) {
            countryList.add(pv.getValue());
        }
        System.debug('::::::::::::'+objectName+':::'+fieldapiname+'::::'+countryList);
        return countryList;
    }

    //PRM 80 End
    
    @AuraEnabled
    public static PartnerRequestListWrapper loadPartnerRegistrations (Decimal pageNumber_pr, Decimal pageSize_pr){
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        List<String> brandNamesList;
        if(comDetail.Brand_Name__c !=null)
        {
         brandNamesList = comDetail.Brand_Name__c.split(';');
        }
        
        List<Partner_Request__c> retList = new List<Partner_Request__c>();
        PartnerRequestListWrapper prWrapper = new PartnerRequestListWrapper();
        
        Integer pSize_pr = (Integer)pageSize_pr;
        Integer pNumber_pr = (Integer)pageNumber_pr;
        
        //Offset for SOQL 
        Integer offset_pr = (pNumber_pr - 1) * pSize_pr; 
        Integer recordEnd_pr = pSize_pr * pNumber_pr;  
        Integer totalRecords_pr;
        String query = '';
        String AVAYAOFFICE = '';
        String currentContactPartnerPortalView='';
        List<Contact> listOfCurrentContacts=new List<Contact>();
        
         if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AVAYAOFFICE=String.valueOf(System.Label.AVAYACLOUDOFFICE);
         }
        if(Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords_pr = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords_pr=1000;
        }
        if(brandNamesList.contains('Avaya Cloud Office')){
            query = 'Select count() From Partner_Request__c where Avaya_Partnership_Reg__c=true and (Brand_Name__c = null OR Brand_Name__c = \''+AVAYAOFFICE+'\')';
        }else{
            query = 'Select count() From Partner_Request__c where  Brand_Name__c IN: brandNamesList and Avaya_Partnership_Reg__c = true';
        }
        
        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords_pr){
            totalRecords_pr = totSize;
        }
        
        
        if(brandNamesList.contains('Avaya Cloud Office')){
            if(null!=totalRecords_pr && totalRecords_pr > 0){
                query ='Select id, Partner_Company_Name__c, Partner_City__c, Partner_Email_Address__c,Partner_State__c,Partner_Zip__c,Partner_First_Name__c,Partner_Last_Name__c, Partner_Phone__c, '+
                        ' CreatedById, Annual_Gross_Revenue__c,Partner_ID__c,External_SID__c,Brand_Name__c From Partner_Request__c where Avaya_Partnership_Reg__c=true  and (Brand_Name__c = null OR Brand_Name__c IN: brandNamesList) ';
               
                query += '  order by createddate DESC LIMIT :pSize_pr OFFSET :offset_pr';
                prWrapper.prtnrReqList = Database.query(query);
            }
        }else{
            if(null!=totalRecords_pr && totalRecords_pr > 0){
                
                query ='Select id, Partner_Company_Name__c, Partner_City__c, Partner_Email_Address__c,Partner_State__c,Partner_Zip__c,Partner_First_Name__c,Partner_Last_Name__c, Partner_Phone__c, '+
                    ' CreatedById, Annual_Gross_Revenue__c,Partner_ID__c,External_SID__c,Brand_Name__c From Partner_Request__c where Avaya_Partnership_Reg__c=true  and  Brand_Name__c IN: brandNamesList ';
                query += '  order by createddate DESC LIMIT :pSize_pr OFFSET :offset_pr';
                prWrapper.prtnrReqList = Database.query(query);
            }
            system.debug('list of reseller**'+ prWrapper.prtnrReqList);
            system.debug('brandNamesList*' + brandNamesList);
        }
        system.debug('list of reseller**'+ prWrapper.prtnrReqList);
        system.debug('brandNamesList*' + brandNamesList);
        prWrapper.pageSize_pr = pSize_pr;
        prWrapper.pageNumber_pr = pNumber_pr;
        prWrapper.recordStart_pr = offset_pr + 1;
        prWrapper.recordEnd_pr = totalRecords_pr >= recordEnd_pr ? recordEnd_pr : totalRecords_pr;
        prWrapper.totalRecords_pr = totalRecords_pr;
        
        return prWrapper;
    }
    @AuraEnabled
    public static ContactListWrapper loadListContact(string acctId){
        //code modified by Saradha for creating user from contact
        List<Contact> listContact = new List<Contact>();
        List<ContactWrapper> contactWrapperLstTmp = new List<ContactWrapper>();
        Map<Id,Id> contactIds = new Map<Id,Id>();
        if(acctId!=null && acctId!=''){
            listContact= [select id,accountid,name,email,Business_Role__c,phone, ownerid, owner.name,Partner_Portal_View__c,firstname,lastname,account.partner_account__r.name,account.partner_account__r.Partner_Role__c,account.partner_account__r.id from Contact where accountid =:acctId ORDER BY createdDate DESC];
        }
        //<T2>
        Set<Id> contactIdsToQuery = new Set<Id>();
        for(Contact contactobj : listContact){
            contactIdsToQuery.add(contactobj.id);
        }
        
        List<User> userLst = [select id,contactId from user where contact.id in : contactIdsToQuery ];
        for(User userObj : userLst){
            contactIds.put(userObj.contactId,userObj.id);
        }
        ContactListWrapper contactLstwrapperObj = new ContactListWrapper();
        contactLstwrapperObj.contactLst = listContact;
        
        for(Contact contactObjTmp : listContact){
            if(contactIds.get(contactObjTmp.id) != null){
                contactWrapperLstTmp.add(new ContactWrapper(contactObjTmp,false));
            }else{
                contactWrapperLstTmp.add(new ContactWrapper(contactObjTmp,true));
            }
        }
        
        contactLstwrapperObj.contactWrapperLst = contactWrapperLstTmp;
        
        return contactLstwrapperObj;
    }
    @AuraEnabled
    public static Account loadAccount(string acctId){
        Account acct = new Account();
        if(acctId!=null && acctId!=''){
            //PBC 10852: Added Website field in SOQL 
            acct= [select Id, name, phone, MRR__c, RC_Service_name__c,Partner_ID__c,Inside_Sales_Rep__r.name,
                   BillingCity,Parent_Partner_Account__r.Name,Partner_Account__r.Name, Channel_Manager_Name__c,
                   Current_Owner__r.Name,BillingState,BillingPostalCode,BillingCountry,RC_User_ID__c,AccountNumber,RC_Account_Status__c,Number_of_DL_s__c,RC_Upgrade_Date__c,External_SID__c, 
                   Invoice_Copy_Partner_ID__c,Partner_Type__c,Invoicing_Partner_ID__c,Settlement_type__c, 
                   BusinessIdentity__c,Partner_Classification__c,Website
                   From Account where Id=:acctId limit 1];
            
            
        }
        return acct;
    }
    @AuraEnabled
    public static UserWrapper checkUserRole(){
        User currentUser = [SELECT Id, Name, Contact.AccountId, Contact.Account.Partner_Role__c,Contact.Account.Name,Contact.Account.Partner_ID__c,UserRoleId, 
                            UserRole.Name,Contact.Partner_Portal_View__c FROM User WHERE Id = :UserInfo.getUserId()];
        UserWrapper uw = new UserWrapper();
       
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        uw.communityDetailsRecord=comDetail;
        uw.partnerMasterLabel = comDetail.MasterLabel;
        uw.portalTopMasterName = currentUser.Contact.Account.Name;
        uw.portalTopMasterPartnerId = currentUser.Contact.Account.Partner_ID__c;
        
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        if(null!=currentUser && null!= currentUser.UserRoleId && currentUser.Contact.AccountId != null ){
            if(currentUser.UserRole.Name.contains('Manager') || currentUser.UserRole.Name.contains('Executive') || isUserBelongsToDeletedMgrRole()){
                if(currentUser.Contact.AccountId == comDetail.Portal_Top_Master_Account_Id__c){
                    uw.isAvaya = true;
                    uw.isMasterAgent = false;
                }else if(currentUser.Contact.Account.Partner_Role__c == 'Master Agent'){
                    uw.isAvaya = false;
                    uw.isMasterAgent = true;
                }else{
                    uw.isAvaya = false;
                    uw.isMasterAgent = false;
                }
            }
            uw.isReadOnly=isReadOnlyProfile;
        
            uw.partnerCommunityName= brandNamesList;
            
        }
        return uw;
    }

    public static Boolean isUserBelongsToDeletedMgrRole() {
        List<String> userIDsList = new List<String>();
        for (Portal_Manager_Role_User_List__mdt listOfUserIds : [SELECT UserIdList__c FROM Portal_Manager_Role_User_List__mdt]) {
            if(listOfUserIds.UserIdList__c!=null) {
                userIDsList.addAll(listOfUserIds.UserIdList__c.split(','));
            }
        }
        return userIDsList.contains(UserInfo.getUserId());
    }

    //Method to create contact and associate Account-Contact role        
    @AuraEnabled
    public static Map<String, String> createContactRecord(Contact newContact) {
        // Forming a  string map to return response
        Map<String,String> resultMap = new Map<String,String>();
        String selectedRole = 'Signatory';
        Id accid = newContact.AccountId;
        // Adding try catch for exception handling
        try {
            
            List <RecordType> rtList = [select id, Name from RecordType where SobjectType='Contact' And Name = 'VAR Visible'];
             List<Account> accList = [select id, name, RC_Brand__c from Account where id =:accid ];
            
            if(null!=rtList && rtList.size()>0){
                newContact.RecordTypeId = rtList.get(0).id;
            }
            // Handled in Custom metadata for avaya,atos,vodafone partners
            Community_Details__mdt comm = checkUserRole().communityDetailsRecord;
             List<String> brandNamesList = comm.Brand_Name__c.split(';');
            
            newContact.OwnerId =comm.Portal_Deal_Desk_User__c;
            newContact.Marketo_Sync_Disabled__c = true;
            newContact.Avaya_Partnership_Contact__c = true;
            
            // Inserting the Contact
            insert newContact;
          
                Deal_Support__c dealSupp = new Deal_Support__c();
                dealSupp.Partner_Account__c = newContact.AccountId;
                dealSupp.Partner_Contact__c = newContact.Id;
                dealSupp.Type__c = 'New Contact Request';
                dealSupp.Name ='New Contact Request - ' +newContact.FirstName +' ' +newContact.LastName; 
                dealSupp.Brand_Name__c = accList.get(0).RC_Brand__c;
                insert dealSupp; 
          
            resultMap.put('status', 'success');
            resultMap.put('message', 'Contact created successfully!');        
        }
        catch(Exception e) {
            // Setting the error status and message in resultMap
            resultMap.put('status', 'error');
            resultMap.put('message',e.getMessage());
        }
        // Returning the result string map
        return resultMap;        
    }
    @AuraEnabled
    public static String createUserForContact(Contact contact,String accId,List<Contact> contactsLst,String userNameInput){
        String result = 'SUCCESS';
        
        String username = '';
        PartnerDetailsController pd = new PartnerDetailsController();
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        
        try{                                              
            String portalUserType = pd.creatProtalTypeForUser(contactsLst,contact);
            
            String alias =pd.getAliasFromContact(contact);
            
            //Create User 
            if(String.isNotEmpty(userNameInput) && String.isNotBlank(userNameInput)){
                if(userNameInput.endsWith(String.valueOf(comDetail.UserName_Suffix__c))){
                    username = String.escapeSingleQuotes(userNameInput);
                }else{
                    username = String.escapeSingleQuotes(userNameInput) + String.valueOf(comDetail.UserName_Suffix__c);    
                }                
            }else{
                username = createUserNameForNewUser(contact).username;
            }
            Boolean isDuplicateUserName = verifyIfUserNameExists(username).isDuplicateUserName;
            User portalUser = new User(
                Username = username,
                ContactId = contact.Id,
                ProfileId = UserInfo.getProfileId(),
                Alias = alias,
                Email = contact.email+'.invalid',
                EmailEncodingKey = 'ISO-8859-1',
                LastName = contact.LastName,
                firstname = (contact.FirstName != null && contact.FirstName != '')?contact.FirstName:'',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive =false,
                CURRENCYISOCODE = 'USD',
                PortalRole = portalUserType
            );      
        }catch(Exception e){
            System.debug('Error at line : '+e.getLineNumber() + 'and the error is : '+e.getMessage());
            result = 'ERROR ' +e.getLineNumber() + 'and the error is : '+e.getMessage();
        }
        return result;
    }
    @AuraEnabled
    public static UserNameWrapper verifyIfUserNameExists(String userName){
        UserNameWrapper uw = new UserNameWrapper();
        Boolean isDuplicateUserName = true;
        uw.userName = username;
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        uw.userNameSuffix = String.valueOf(comDetail.UserName_Suffix__c);
        uw.result = 'SUCCESS';
        try{
            List<User> usrLst = [Select id from User where userName=:username];
            if(usrLst == null || (usrLst != null && usrLst.size() == 0)) {
                isDuplicateUserName = false;
            } else {
                isDuplicateUserName = true; 
            }                
        }catch(Exception e){
            System.debug('Error at line : '+e.getLineNumber() + 'and the error is : '+e.getMessage());
            uw.result = 'ERROR ' +e.getLineNumber() + 'and the error is : '+e.getMessage();
        }
        uw.isDuplicateUserName = isDuplicateUserName;
        //uw.isDuplicateUserName = true;
        return uw;        
    } 
    
    //Added for BOB Second set of Changes for JIRA - 6286 start
    @AuraEnabled
    public static List<String> getBusinessPicklistvalues(String objectName, String fieldapiname,Boolean nullRequired){
        List<String> optionlist = new List<String>();       
        Map<String, Schema.SObjectField> fieldmap = ((SObject)Type.forName(objectName.toLowerCase()).newInstance()).getSObjectType().getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = fieldmap.get(fieldapiname).getDescribe().getPickListValues();       
        if(nullRequired == true){
            optionlist.add('--None--');
        }       
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(pv.getValue());
        }
        System.debug('::::::::::::'+objectName+':::'+fieldapiname+'::::'+optionlist);
        return optionlist;
    }
    
     //Added for PRM 80  
      @AuraEnabled
      public static boolean directPartnerReg(){
           boolean showThankss=True;
          system.debug('&&&Show Thanks value'+showThankss);
          return showThankss;
          
      }
      // Added for PRM 80
    
    @AuraEnabled
    public static string getNGBSPartnerHierarchy(String AccountId){
        string output = NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyListAura(AccountId,true,false); 
        System.debug(':::::output::::::'+output);
        return output;
    }
    //Added for BOB Second set of Changes for JIRA - 6286 end
    
    @AuraEnabled
    public static UserNameWrapper createUserNameForNewUser(Contact contact){
        UserNameWrapper uw = new UserNameWrapper();
        String masterAgentName = '';
        String username = '';
        Boolean isMasterAgent = false;
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        uw.userNameSuffix = String.valueOf(comDetail.UserName_Suffix__c);
        uw.result = 'SUCCESS';
        try{
            if(contact.account.partner_account__r.id==comDetail.Portal_Top_Master_Account_Id__c){
                isMasterAgent = false;
            }else if(contact.account.partner_account__r.Partner_Role__c == 'Master Agent'){
                isMasterAgent = true;
            }
            if(isMasterAgent){
                if(contact != null && contact.account != null && contact.account.partner_account__c != null &&
                   contact.account.partner_account__r.name != null){
                       if(contact.account.partner_account__r.Partner_Role__c != null && contact.account.partner_account__r.Partner_Role__c == 'Master Agent'){
                           if((contact.account.partner_account__r.name).indexof(':') != -1){
                               masterAgentName = (contact.account.partner_account__r.name).split(':')[1].replaceAll('[^a-zA-Z0-9+]', '').toLowercase();
                               masterAgentName = '.'+masterAgentName;
                           }
                       }else{
                           masterAgentName =''; 
                       }
                   }
            }            
            username = contact.email+masterAgentName + String.valueOf(comDetail.UserName_Suffix__c);
            uw.userName = username;
            uw = verifyIfUserNameExists(username);
        }catch(Exception e){
            System.debug('Error at line : '+e.getLineNumber() + 'and the error is : '+e.getMessage());
            uw.result = 'ERROR ' +e.getLineNumber() + 'and the error is : '+e.getMessage();
        }
        return uw;
    }
    public String creatProtalTypeForUser(List<Contact> contactsLst,Contact contact){
        Set<Id> contactIds = new Set<Id>();
        for(Contact contactobj : contactsLst){
            contactIds.add(contactobj.id);
        }
        //checking whether there is already users present for the account
        List<User> userLst = new List<User>();
        userLst = [select id from user where contact.id in : contactIds ];
            
        //Set the portal role for the creating user
        String portalUserType = '';
        if(userLst.isEmpty() || userLst == null || userLst.size() == 0){
            portalUserType = 'Manager';
        }else if(('full').equalsIgnoreCase(contact.Partner_Portal_View__c)){
            portalUserType = 'Manager';
        }else{
            portalUserType = '';
        }
        return portalUserType;
    } 
     public String getAliasFromContact(Contact contact){
        String fName1 = '';
        String fName2='';
        String alias = '';
        fName1 = (contact.FirstName != null && contact.FirstName != '')?contact.FirstName.substring(0,1):'';
        fname2 = (contact.Lastname.length() > 4)?contact.LastName.substring(0,4):contact.LastName.substring(0,contact.LastName.length());
        alias =fname1+fname2;
        return alias;
    } 
    
    public class PartnerWrapper{
        @AuraEnabled
        public Integer pageSize {get;set;}
        @AuraEnabled
        public Integer pageNumber {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled
        public Integer recordEnd {get;set;}
        @AuraEnabled
        public String partnerList {get;set;}    
        @AuraEnabled
        public boolean isAvaya {get;set;}    
        @AuraEnabled
        public List<Partner> listPartner{get;set;}  
        @AuraEnabled
        public List<Contact> listContact{get;set;} 
        @AuraEnabled
        public Account account {get;set;}
        @AuraEnabled
        public boolean isMasterAgent {get;set;}       
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public String partnerMasterLabel{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}
        @AuraEnabled
        public String portalTopMasterName{get;set;}
        @AuraEnabled
        public String portalTopMasterPartnerId{get;set;}
    }
    
    public class Partner{        
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String accountName{get;set;}
        @AuraEnabled
        public String contacts{get;set;}
        @AuraEnabled
        public String phone{get;set;}
        @AuraEnabled
        public String owner{get;set;}
        @AuraEnabled
        public String ownerName{get;set;}
        @AuraEnabled
        public String billingCity{get;set;}  
        @AuraEnabled
        public String billingState{get;set;}  
        @AuraEnabled
        public String billingPostalCode{get;set;}   
        @AuraEnabled
        public List<partnerUser> partnerUsers{get;set;}
        @AuraEnabled
        public string partnerId{get;set;}
        @AuraEnabled
        public string externalSID{get;set;}  
        @AuraEnabled
        public String partnerAccountName{get;set;}
        @AuraEnabled
        public String partnerChannelManager{get;set;}
    }
    public class UserWrapper{        
        @AuraEnabled
        public Boolean isAvaya{get;set;}
        @AuraEnabled
        public Boolean isMasterAgent{get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public String partnerMasterLabel{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;} 
    @AuraEnabled
        public String portalTopMasterName{get;set;}
        @AuraEnabled
        public String portalTopMasterPartnerId{get;set;}
    }
    public class PartnerUser{
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String userName{get;set;}
        @AuraEnabled
        public String phone{get;set;}
        @AuraEnabled
        public String billingCity{get;set;}
        @AuraEnabled
        public String owner{get;set;}
        @AuraEnabled
        public String ownerName{get;set;}
        
    }       
    public class PartnerRequestListWrapper{
        @AuraEnabled
        public Integer pageSize_pr {get;set;}
        @AuraEnabled
        public Integer pageNumber_pr {get;set;}
        @AuraEnabled
        public Integer totalRecords_pr {get;set;}
        @AuraEnabled
        public Integer recordStart_pr {get;set;}
        @AuraEnabled
        public Integer recordEnd_pr {get;set;}
        @AuraEnabled
        public List<Partner_Request__c> prtnrReqList {get;set;}
    }  
    public class ContactListWrapper{
        @AuraEnabled
        public List<Contact> contactLst {get;set;}
        @AuraEnabled
        public List<ContactWrapper> contactWrapperLst{get;set;}
    }
    public class ContactWrapper{
        @AuraEnabled
        public Contact contact{get;set;}
        @AuraEnabled
        public Boolean hasUser{get;set;}
        public ContactWrapper(Contact contact1, Boolean hasUser1){
            contact = contact1;
            hasUser = hasUser1;
        }
    }
    public class UserNameWrapper{
        @AuraEnabled
        public String userName{get;set;}
        @AuraEnabled
        public Boolean isDuplicateUserName{get;set;}
        @AuraEnabled
        public String result{get;set;}
        @AuraEnabled
        public String userNameSuffix {get;set;}
    }
    public class PickListWrapperForCountry{
        @AuraEnabled
        public Map<String,List<String>> countryStateMap {get;set;}
        @AuraEnabled
        public Map<String,Set<String>> mapBusinessCntry{get;set;}
        @AuraEnabled
        public Set<String> availableCountries{get;set;}
        @AuraEnabled
        public Set<String> BI_Set{get;set;}
    }
    public class PickListWrapperForBillingFeedType{
        @AuraEnabled
        public Map<String,List<String>> partnrReqbillFeedMap {get;set;}
    }
    //PRM 80 Start
       public class Translationswrap {
        @AuraEnabled
        public Map<String, Map<String, String>> allObjFieldsMap {get;set;}
        @AuraEnabled
        public Map<String, String> prmLabelsMap {get;set;}
        @AuraEnabled
        public Map<String, String> prmSpecificLabelsMap {get;set;}
    }
    //PRM 80 End
}