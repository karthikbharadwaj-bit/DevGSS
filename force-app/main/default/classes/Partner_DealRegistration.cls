/*
* Created By    : Ishwarya
* Created Date  : 16-12-2019
* Description   : Apex class for component Partner_DealRegistration - Deal Registrations page

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class Partner_DealRegistration {
    @AuraEnabled
    public static Boolean isGuestUser()
    { 
        Boolean isGuestUser = false;
        User currentUser = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('currentUser--> '+currentUser);
        if(currentUser.Profile.UserLicense.Name == 'Guest User License')
        {
            isGuestUser = true;
        }
        return isGuestUser;
    }
    //Method to get list of deal registrations
    @AuraEnabled
    public static DealRegListWrapper getDealRegDataController(String selectedPartnerAccount,String selectedDealStatus,Decimal pageNumber, Decimal pageSize,String searchKeyWord, String searchBy) {
        //get list view of Opportunities
        DealRegListWrapper obj=new DealRegListWrapper();
        List<Account> accList = new List<Account>();       
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        Integer totalRecords;
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;  
        String AvayaOffice='';
        
        AccountListWrapper accWrapper = getAccountList();
        List<String> brandNamesList= accWrapper.partnerCommunityName;
        String masterLabel=accWrapper.communityDetailsRecord.MasterLabel;
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if(System.Label.Avaya_Pagination_Limit != null&&Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords = 1000;
        }
        //Single Login code starts
        Set<Id> setUserAccIds = new Set<Id>();
        if(accWrapper != null && accWrapper.listUserAccountMap != null && !accWrapper.listUserAccountMap.isEmpty()){
            for(User_Account_Mapping__c uam : accWrapper.listUserAccountMap){
                setUserAccIds.add(uam.Partner_Account__c);
            }
        }
        system.debug('setUserAccIds>'+setUserAccIds);
        //Single Login code ends
        
         Set<Id> setOfCurrentUserContactIds = new Set<Id>();
        String currentContact='';
        if(brandNamesList.contains('RingCentral')&&masterLabel == 'ignite'){
            List<User> users = [SELECT Id, Name, ContactId, Contact.AccountId,
                                Contact.Account.Partner_Account__c,Contact.Partner_Portal_View__c                          
                                FROM User WHERE Id = :UserInfo.getUserId()];
            
            if(users!=null && !users.isEmpty() && users.size()>0){
                currentContact=users[0].ContactId;
            }
            List<Portal_Access__c> listOfPortalAccess = [SELECT Id,Account__c,Contact__c FROM Portal_Access__c WHERE Contact__c = : currentContact];
           
            if(listOfPortalAccess!=null && !listOfPortalAccess.isEmpty() && listOfPortalAccess.size()>0){
                for(Portal_Access__c portalAccess : listOfPortalAccess){
                    setOfCurrentUserContactIds.add(portalAccess.Contact__c);
                    system.debug('setOfCurrentUserContactIds-'+setOfCurrentUserContactIds);
                }
            }
        }
        
        String query='';
        if(selectedPartnerAccount == null)
        {
            accList = accWrapper.listPartnerAccounts;
            if(accList.size() > 0)
            {
                selectedPartnerAccount = accList[0].Id; 
                
            }            
        }
        if(selectedDealStatus == null){
            selectedDealStatus='Pending Approval';         
        } 
        if(brandNamesList.contains('Avaya Cloud Office')){
            if(selectedDealStatus=='Any'){
                query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Deal__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
            }
            else{
                query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Avaya_Partnership_Deal__c = true and (Brand_Name__c = null  OR Brand_Name__c = '+'\''+AvayaOffice+'\')';            
            }
        }else{
            if(brandNamesList.contains('RingCentral')&&masterLabel == 'ignite'){
                if(selectedDealStatus=='Any'){
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds  OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true'; 
                }
                else{
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds  OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true';            
                }
            }else if(brandNamesList.contains('Unify Office')){
                if(selectedDealStatus=='Any'){
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\'OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\'OR Partner_Account__c IN: setUserAccIds) and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true'; 
                }
                else{
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\'OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true';            
                }

            }else{
                if(selectedDealStatus=='Any'){
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true'; 
                }
                else{
                    query = 'select count() from Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true';            
                }
            }
        }
        if(null!= searchKeyWord && searchKeyWord != ''){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            if(searchBy=='Forecasted_Users__c'){
                query += ' And '+ searchBy+' ='+searchKeyWord;
            }else {
                query += ' And '+ searchBy+ '  Like '+searchKey;
            }
        }
        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        
        if(null!=totalRecords && totalRecords > 0){
            if(brandNamesList.contains('Avaya Cloud Office')){
                if(selectedDealStatus=='Any'){
                    query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c, Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name  FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Deal__c = true and (Brand_Name__c =null  OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
                }
                else{
                    query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c,Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c, Partner_Account__r.Partner_Channel_Manager__c,Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Avaya_Partnership_Deal__c = true and (Brand_Name__c =null  OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
                }
            }
            else{
                if(brandNamesList.contains('RingCentral')){
                   if(selectedDealStatus=='Any'){
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c, Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Forecasted_Contact_Center_Users__c FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds  OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true'; 
                    }
                    else{
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c,Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c,Forecasted_Contact_Center_Users__c FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds  OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true';
                    } 
                }else if(brandNamesList.contains('Unify Office')){
                    if(selectedDealStatus=='Any'){
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c, Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\'OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true'; 
                    }
                    else{
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c,Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\'OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true';
                    }

                }else{
                    if(selectedDealStatus=='Any'){
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c, Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true'; 
                    }
                    else{
                        query = 'SELECT Id, Name, Company_Name__c, Avaya_Cloud_Specialist__c, RC_Overlay__c,Contact__c,Is_Pending_Due_to_Domain__c,Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c, Partner_Account__r.Name,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c FROM Deal_Registration__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true';
                    } 
                }
            }
            if(null!= searchKeyWord && searchKeyWord != ''){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                if(searchBy=='Forecasted_Users__c'){
                    query += ' And '+ searchBy+' ='+searchKeyWord;
                }else {
                    query += ' And '+ searchBy+ ' Like '+searchKey;
                }
            }
            query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset'; 
            
            dealRegList = Database.query(query);
            obj.dealRegList = dealRegList;
        }
        obj.pageSize = pSize;
        obj.pageNumber = pNumber;
        obj.recordStart = offset + 1;
        obj.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        obj.totalRecords = totalRecords;        
        return obj;
    }
    
    //Translation Start
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }
    //Translation End
    
    // Installation field change start
    @AuraEnabled
    public static List<String> getServiceProvider(String partnerContact){
        String deliveryPartner;
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Deal_Registration__c.Installation_Service_Provider__c.getDescribe();
        List<Schema.PicklistEntry> plValues = fieldResult.getPicklistValues();
        if(!plValues.isEmpty()){
            for (Schema.PicklistEntry ple : plValues) {
                Contact contactRecord = [Select Id, Name, AccountId, Account.Certified_Delivery_Partner_Status__c from Contact where Id=: partnerContact];
                if (contactRecord != null && (contactRecord.Account.Certified_Delivery_Partner_Status__c == PartnerDealRegistrationUtil.COMPLETE 
                                              || contactRecord.Account.Certified_Delivery_Partner_Status__c == PartnerDealRegistrationUtil.PSPREMIERPARTNER)) {
                                                  if (ple.getValue() != PartnerDealRegistrationUtil.ENROLLCDPSTATUS) {
                                                      picklistValues.add(ple.getValue());                    
                                                  }
                                              } else {
                                                  if (ple.getValue() != PartnerDealRegistrationUtil.PARTNERINSTALLSTATUS) {
                                                      picklistValues.add(ple.getValue());
                                                  }
                                              }
            }
        }
        return picklistValues;
    }

    @AuraEnabled
    public static List<String> getServiceProviderByUser(String userId) {
        List<String> picklistValues = new List<String>();
        User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1];
        
        if (currentUser.ContactId != null) {
            Contact contactRecord = [SELECT Id, Name, AccountId, Account.Certified_Delivery_Partner_Status__c FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
            
            Schema.DescribeFieldResult fieldResult = Deal_Registration__c.Installation_Service_Provider__c.getDescribe();
            List<Schema.PicklistEntry> plValues = fieldResult.getPicklistValues();
            if(!plValues.isEmpty()){
                for (Schema.PicklistEntry ple : plValues) {
                    if (contactRecord != null && (contactRecord.Account.Certified_Delivery_Partner_Status__c == PartnerDealRegistrationUtil.COMPLETE 
                                                  || contactRecord.Account.Certified_Delivery_Partner_Status__c == PartnerDealRegistrationUtil.PSPREMIERPARTNER)) {
                                                      if (ple.getValue() != PartnerDealRegistrationUtil.ENROLLCDPSTATUS) {
                                                          picklistValues.add(ple.getValue());                    
                                                      }
                                                  } else {
                                                      if (ple.getValue() != PartnerDealRegistrationUtil.PARTNERINSTALLSTATUS) {
                                                          picklistValues.add(ple.getValue());
                                                      }
                                                  }
                }
            }
        }
        
        return picklistValues;
    }
   // Installation field  change End 
   
    @AuraEnabled
    public static DealRegListWrapper getDataForViewAll(Decimal pageNumber, Decimal pageSize, String selectedDealStatus,String searchKeyWord, String searchBy){
        //get list view of Opportunities
        DealRegListWrapper obj = new DealRegListWrapper();
        List<Account> accList = new List<Account>();       
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;          
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId(); 
        Integer totalRecords;
        String AvayaOffice='';
        
        AccountListWrapper accWrapper = getAccountList();
        List<String> brandNamesList= accWrapper.partnerCommunityName;
        system.debug('brandNamesList'+brandNamesList);
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if(System.Label.Avaya_Pagination_Limit != null&&Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords=1000;
        }
        String query = '';
        if(selectedDealStatus == null)
        {
            selectedDealStatus='Pending Approval';         
        }
        if(brandNamesList.contains('Avaya Cloud Office')){
            if(selectedDealStatus=='Any'){
                query = 'select count() from Deal_Registration__c where Avaya_Partnership_Deal__c = true and (Brand_Name__c = null  OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
            }
            else{
                query = 'select count() from Deal_Registration__c where  Status__c='+'\''+selectedDealStatus+'\' and Avaya_Partnership_Deal__c = true and (Brand_Name__c = null  OR Brand_Name__c ='+'\''+AvayaOffice+'\')';         
            }
        }
        else{
            if(selectedDealStatus=='Any'){
                query = 'select count() from Deal_Registration__c where Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true'; 
            }
            else{
                query = 'select count() from Deal_Registration__c where  Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true';             
            }
        }
        if(null!= searchKeyWord && searchKeyWord != ''){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            if(searchBy=='Forecasted_Users__c'){
                query += ' And '+ searchBy+' ='+searchKeyWord;
            }else {
                query += ' And '+ searchBy+ '  Like '+searchKey;
            }
        }
        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        
        if(null!=totalRecords && totalRecords > 0){
            if(brandNamesList.contains('Avaya Cloud Office')){
                if(selectedDealStatus=='Any'){
                    query = 'SELECT Id, Name, Company_Name__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Is_Pending_Due_to_Domain__c, Contact__c,  Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c,Partner_Account__r.Name, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name  FROM Deal_Registration__c where Avaya_Partnership_Deal__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')'; 
                }
                else{
                    query = 'SELECT Id, Name, Company_Name__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Is_Pending_Due_to_Domain__c, Contact__c,  Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c,Partner_Account__r.Name, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c FROM Deal_Registration__c where Status__c='+'\''+selectedDealStatus+'\' and Avaya_Partnership_Deal__c = true and (Brand_Name__c = null  OR Brand_Name__c='+'\''+AvayaOffice+'\')';
                }
            }
            else{
                if(selectedDealStatus=='Any'){
                    query = 'SELECT Id, Name, Company_Name__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Is_Pending_Due_to_Domain__c, Contact__c,  Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c,Partner_Account__r.Name, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Forecasted_Contact_Center_Users__c FROM Deal_Registration__c where Brand_Name__c IN: brandNamesList  and Avaya_Partnership_Deal__c = true'; 
                }
                else{
                    query = 'SELECT Id, Name, Company_Name__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Is_Pending_Due_to_Domain__c, Contact__c,  Email_Address__c, Status__c, Forecasted_Users__c,CreatedDate, Partner_Account__c,Partner_Account__r.Name, Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.Name,OwnerId,Owner.Name,Avaya_CloudOffice_Specialist__c,Brand_Name__c,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c,Forecasted_Contact_Center_Users__c FROM Deal_Registration__c where Status__c='+'\''+selectedDealStatus+'\' and Brand_Name__c IN: brandNamesList and Avaya_Partnership_Deal__c = true'; 
                }
            }
            if(null!= searchKeyWord && searchKeyWord != ''){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                if(searchBy=='Forecasted_Users__c'){
                    query += ' And '+ searchBy+' ='+searchKeyWord;
                }else {
                    query += ' And '+ searchBy+ '  Like '+searchKey;    
                }            
            }
            query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset'; 
            
            dealRegList = Database.query(query);
            obj.dealRegList = dealRegList;
        } 
        obj.pageSize = pSize;
        obj.pageNumber = pNumber;
        obj.recordStart = offset + 1;
        obj.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        obj.totalRecords = totalRecords; 
        obj.isAvaya = accWrapper.isAvaya;
        obj.isMaster=accWrapper.isMaster;
        return obj;
        
    }
    
    // Added for BZS-9016
    @AuraEnabled
    public static List<CountryBusinessIdentityMapping__c> getBICountriesCSList(){
        List<CountryBusinessIdentityMapping__c> BICountryCSList = CountryBusinessIdentityMapping__c.getAll().values();
        return BICountryCSList;
    }
    
    //Method to get list of accounts
    @AuraEnabled
    public static AccountListWrapper getAccountList(){
        //get ParentAccount list to be populated in drop-down of list view
        AccountListWrapper accListWrapper=new AccountListWrapper();
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        List<Account> listofPartnerAccounts =new List<Account>();
        List<Contact> listofPartnerContacts =new List<Contact>();
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
        String currentUserContactAccess=PartnerDealRegistrationUtil.getCurrentUserPartnerContactAccess();
        
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        //Single Login code starts
        Set<Id> setUserId = new Set<Id>();
        setUserId.add(UserInfo.getUserId());
        List<User_Account_Mapping__c> listUserAccountMap = new List<User_Account_Mapping__c>([Select Id, Partner_Account__c, Partner_User__c 
                                                                                              from User_Account_Mapping__c 
                                                                         where Partner_User__c IN:setUserId]);
        system.debug('listUserAccountMap>>'+listUserAccountMap);
        if(!listUserAccountMap.isEmpty()){
            accListWrapper.isSingleLogin = true; 
            accListWrapper.listUserAccountMap = listUserAccountMap;
        }
        ///Single Login code ends
        
        System.debug('selectedPartnerAccount++++'+selectedPartnerAccount);
        if(selectedPartnerAccount != NULL){
            for(Account acc : [SELECT Id, Name,Partner_Role__c, Partner_Account__r.Partner_Type__c, Partner_Type__c, VAR_Territory__c,BusinessIdentity__c,
                               Permitted_Brands__c,Master_Agent_Channel_Manager__c,Inside_Sales_Rep__c,Partner_Hierarchy_Level__c,Partner_Classification__c FROM Account WHERE Id =:selectedPartnerAccount 
                               AND Type='Partner' order by Name]){
                                   System.debug('acc++++'+acc);
                                   listofPartnerAccounts.add(acc);
                                   if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                       accListWrapper.isAvaya=true;
                                       accListWrapper.isMaster=false;
                                   }
                                   else if(acc.Partner_Role__c=='Master Agent'){
                                       accListWrapper.isAvaya=false;
                                       accListWrapper.isMaster=true;
                                   }
                                   if(acc.Partner_Hierarchy_Level__c=='Reseller'){
                                       accListWrapper.isReseller=true;
                                   }
                                   if(CommunityInfo.CommunityName == 'ignite'){ 
                                       accListWrapper.isMitel = true;
                                   } //added for mitel partners 
                               }
            accListWrapper.listPartnerAccounts=listofPartnerAccounts;
            accListWrapper.isReadOnly=isReadOnlyProfile;
            accListWrapper.currentUserContactAccess=currentUserContactAccess;
        }
        //get the current logged in Network Name
        
        accListWrapper.partnerCommunityName = brandNamesList;
        accListWrapper.communityDetailsRecord=comDetail;
        return accListWrapper;
    }
    
    //Method to get Deal Registration detail
    @AuraEnabled
    public static DealRecordWrapper getDealRecordList(String DealRecordId){
        //get data for record detail page for selected opportunity
        Deal_Registration__c dealRecord =new Deal_Registration__c();
        AccountListWrapper accWrapper = getAccountList();
        List<String> brandNamesList=accWrapper.partnerCommunityName;
        // need Partner Classification in query for PBC-9705 P2CSharing
        
        DealRecordWrapper drw = new DealRecordWrapper();
        dealRecord=[select Id,Partner_Account__c,Partner_Type__c,Is_Pending_Due_to_Domain__c,Partner_Account__r.Name,Partner_Account__r.Partner_Classification__c,Partner_Contact__c,Partner_Contact__r.Name,First_Name__c,Last_Name__c,Business_Title__c,Company_Name__c,Email_Address__c,Phone_Number__c,Address__c,City__c,
                    State__c,Postal_Code__c,Country__c,Forecasted_Users__c,Forecasted_RingCentral_Video_Users__c,Brand_Name__c,Tier_Name__c,Edition__c,Term__c,Number_of_Employees__c,Number_of_Locations__c,Industry__c,Estimated_Close_Date__c,Website__c,How_did_you_acquire_this_Lead__c,
                    Description__c,Existing_Solution_Provider__c,Existing_Solution_Provider_Others__c,What_s_prompting_change__c,Whats_prompting_change__c,What_s_prompting_change_Other__c,Competitor_s__c,Competitors_Other__c,Decision_Maker__c,Decision_Maker_Other__c,Currently_in_a_contract__c,Budget_available_for_project__c,Status__c,Deal_Rejection_Reason__c,Sales_Notes__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Avaya_CloudOffice_Specialist__c,
                    Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_Deal__c, Inside_Sales_Rep__c,Inside_Sales_Rep__r.Name,Inside_Sales_Rep__r.Full_Name__c,Forecasted_Contact_Center_Users__c,Partners_CRM_Opportunity_ID__c,Preferred_Language__c,Name,Mitel_Customer_or_Prospect__c,Type_of_Customer_or_Prospect__c,Mitel_Data_Sharing__c,Partner_Program__c, Installation_Service_Provider__c
                    from Deal_Registration__c where Id=:DealRecordId];
        drw.dealReg = dealRecord;
        drw.isAvaya = accWrapper.isAvaya;
        drw.isMaster=accWrapper.isMaster;
        drw.isMitel=accWrapper.isMitel;
        //get the current logged in Network Name
        Community_Details__mdt comDetail=accWrapper.communityDetailsRecord;
        drw.partnerCommunityName= brandNamesList;
        drw.communityDetailsRecord=comDetail;
        drw.isSingleLogin = accWrapper.isSingleLogin;
        return drw;
    } 
    //Method to get NDA Document 
    @AuraEnabled
    public static Id getNDADocument(){
        List<Document> listDoc= [select Id from document where developername='NDA_RingCentral'];
        if(listDoc.size()>0){
            return listDoc[0].Id;
        }
        return null;
    }
    @AuraEnabled
    public static PickListWrapperForCountry getCountryStateMap(String communityBrand){
        Map<String,List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
        Map<String,List<String>> countryCompetitorMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.Competitor_s__c);
        Map<String,List<String>> countryEmployeesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.Number_of_Employees__c);
        PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
        picklistWrapperObj.countryStateMap = dependentPicklistValuesMap;
        picklistWrapperObj.countryNoOfEmployeesMap = countryEmployeesMap;
        BrandCountryWrapper brandWrapr = new BrandCountryWrapper();
        brandWrapr = Partner_DealRegistration.getCountriesAvailableForCommunity(communityBrand);
         picklistWrapperObj.countriesAvailable = brandWrapr.countries;
        picklistWrapperObj.mapBrandCntry = brandWrapr.mapBrandCntry;
        
        picklistWrapperObj.countryCompetitorMap=countryCompetitorMap;
        UserInfoWrapper userWrapper = new UserInfoWrapper();
        userWrapper = Partner_DealRegistration.getCurrentUserInfo();
        if(null != userWrapper){
            picklistWrapperObj.loggedPartnerCountry = userWrapper.partnerCountry;
            CommunityInfo.getBrandName();
            boolean isRestrictEnabled = CommunityInfo.enableRestrictCntry;
            if(isRestrictEnabled){
                picklistWrapperObj.partnerhasAllCntryAcess= !userWrapper.partnerhasAllCntryAcess;    
            }else{
                picklistWrapperObj.partnerhasAllCntryAcess= userWrapper.partnerhasAllCntryAcess;
            }
        }
       //Added for multiple countries in ACO 3.0
        if(userWrapper != null){
            picklistWrapperObj.partnerAvailableCountries = userWrapper.partnerAvailableCountries;
        }
        return picklistWrapperObj;
    }
    public static BrandCountryWrapper getCountriesAvailableForCommunity(String communityBrand){
        BrandCountryWrapper brandWrapper = new BrandCountryWrapper();
        List<String> countries = new List<String>();
        Map<String,List<String>> mapBrandCntry = new Map<String,List<String>>();
        List<String> tmpLst = new List<String>();
        
        if(communityBrand == null || communityBrand == ''){
            Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
            communityBrand = comDetail.Brand_Name__c;
        }
        communityBrand = '%' + communityBrand + '%';
        List<Community_Detail_Child__mdt> countriesForBrand =[select Country_Name__c,Brand_Country__c from Community_Detail_Child__mdt where Community_Details__r.Brand_Name__c like: communityBrand];
        
        for(Community_Detail_Child__mdt communityObj : countriesForBrand){
            if(mapBrandCntry.containsKey(communityObj.Brand_Country__c)){
                mapBrandCntry.get(communityObj.Brand_Country__c).add(communityObj.Country_Name__c);
            }else{
                tmpLst = new List<String>(); 
                tmpLst.add(communityObj.Country_Name__c);
                mapBrandCntry.put(communityObj.Brand_Country__c,tmpLst);
            }
            if(countries.indexOf(communityObj.Country_Name__c) == -1) {
                countries.add(communityObj.Country_Name__c);
            }
        }
        if(countries.size() == 0){
            countries.add('United States');
        }
        
        brandWrapper.countries = countries;
        brandWrapper.mapBrandCntry = mapBrandCntry;
        return brandWrapper;
    }
    
    @AuraEnabled
    public static List<Strategic_Partner_Account__c> getStrategicPartnerManagers(String userName){
        List<Strategic_Partner_Account__c> strategicmanagers = Partner_DealRegStrategicPartnerManager.getStrategicPartnerManagers(userName);
        return strategicmanagers;
    }
    
    @AuraEnabled
    public static UserInfoWrapper getCurrentUserInfo(){
        Id currentLoggedUserId = UserInfo.getUserId();
        List<Account> userInfoDetailAccount = new List<Account>();
        UserInfoWrapper userWrapper = new UserInfoWrapper();
         Id sysAdminProfileId;
        List<Profile> sysAdminProfile = [SELECT id, Name FROM Profile Where Name =:Label.System_Administrator];
       
         if(!sysAdminProfile.isEmpty())
        {
            sysAdminProfileId = sysAdminProfile[0].Id;
        }

              if(UserInfo.getProfileId() == sysAdminProfileId){
            return null;
        }else{
            //Added Permitted_Countries__c for multi country picklist in ACO 3.0
            List<User> userInfoDetail =  [select contact.accountid,contact.Restrict_Country__c,contact.Permitted_Countries__c 
                                          from user where id =: currentLoggedUserId];
            if(!userInfoDetail.isEmpty()){
                userInfoDetailAccount =  [select id,name,Partner_country__c from account where id =: userInfoDetail.get(0).contact.accountid ];
                userWrapper.partnerhasAllCntryAcess = userInfoDetail.get(0).contact.Restrict_Country__c;
                //ACO 3.0
                String permittedCountries = userInfoDetail.get(0).contact.Permitted_Countries__c;
                if(permittedCountries != null && permittedCountries != ''){
                    List<String> permittedCountriesLst = permittedCountries.split(';');
                    Set<String> permittedCountriesSet = new Set<String>();
                    permittedCountriesSet.addAll(permittedCountriesLst);
                    userWrapper.partnerAvailableCountries = permittedCountriesSet;
                } 
            }
            if(!userInfoDetailAccount.isEmpty()){
                userWrapper.partnerCountry = userInfoDetailAccount.get(0).Partner_country__c;
            }
        }
        return userWrapper;
        
    }
    
    @AuraEnabled
    public static string PartnerAccountMasterAgtChlMgr(String accountMasterAgentChlMgr){
        List<Contact> listOfContacts=new List<Contact>();
        String masterAgentChlMgrId='';
        Contact cloudSpecialistContact;
        if(accountMasterAgentChlMgr !=null && accountMasterAgentChlMgr != '') {
            cloudSpecialistContact=Partner_CloudSpecialistSearchController.PartnerAccountMasterAgtChlMgr(accountMasterAgentChlMgr);
        }
        if(cloudSpecialistContact!=null) {
          return cloudSpecialistContact.Id;
        } else {
            return null;
        }
    }
    
    // BZS-9020 starts
    /**
     * checks if logged in user is a wholesale partner and returns package editions else returns null
     */
    @AuraEnabled
    public static List<string> checkWholesalePartnerEditions(){
        User u = [select AccountId,Contact.AccountId, Contact.Account.Partner_Type__c from user where id = :System.UserInfo.getUserId()];
        if (u != null && u.Contact.Account.Partner_Type__c.containsIgnoreCase('Wholesale-Reseller')) {
            return getWholesalePartnerPackageEditions(u.Contact.AccountId);
        }
        return null;
    }

    @AuraEnabled
    public static List<string> getWholesalePartnerPackageEditions(String partnerAccountId){
        Set<String> partnerPackageEditions = new Set<String>();
        if (partnerAccountId != null && partnerAccountId != '') {
        List<Wholesale_Partner_Package__c> wholesalePartnerPckgList = [SELECT id, Wholesale_Partner_Account__c, Parent_Product_Package__r.Package_Edition__c FROM Wholesale_Partner_Package__c WHERE Wholesale_Partner_Account__c = :partnerAccountId];
        for (Wholesale_Partner_Package__c wPackage : wholesalePartnerPckgList) {
            if (wPackage.Parent_Product_Package__r != null && (wPackage.Parent_Product_Package__r.Package_Edition__c != null || wPackage.Parent_Product_Package__r.Package_Edition__c != '')) {
                partnerPackageEditions.add(wPackage.Parent_Product_Package__r.Package_Edition__c);
            }
        }
    }
        return new List<String>(partnerPackageEditions);
    }
    // BZS-9020 ends
    
    public class DealRegListWrapper{
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
        public boolean isAvaya {get;set;}
        @AuraEnabled
        public boolean isMaster {get;set;}
        @AuraEnabled
        public List<Deal_Registration__c> dealRegList {get;set;}
        
    }
    
    public class AccountListWrapper{
        @AuraEnabled
        public List<Account> listPartnerAccounts {get;set;}
        @AuraEnabled
        public boolean isMaster {get;set;}
        @AuraEnabled
        public boolean isAvaya {get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public boolean isSingleLogin {get;set;} //added for single login
        @AuraEnabled
        public boolean isReseller {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}       
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;} 
        @AuraEnabled
        public List<Contact> listPartnerContacts {get;set;}
        @AuraEnabled
        public String currentUserContactAccess{get;set;}
        @AuraEnabled
        public List<User_Account_Mapping__c> listUserAccountMap {get;set;} //added for single login
        @AuraEnabled
        public boolean isMitel{get;set;} //added for mitel
    }
    public class DealRecordWrapper{
        @AuraEnabled
        public Deal_Registration__c dealReg {get;set;}
        @AuraEnabled
        public boolean isMaster {get;set;}
        @AuraEnabled
        public boolean isAvaya {get;set;}
        @AuraEnabled
        public boolean isSingleLogin {get;set;} //added for single login
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}
        @AuraEnabled
        public boolean isMitel{get;set;} //added for mitel 
    }
    public class PickListWrapperForCountry{
        @AuraEnabled
        public Map<String,List<String>> countryStateMap {get;set;}
        @AuraEnabled
        public List<String> countriesAvailable {get;set;}
        @AuraEnabled
        public Map<String,List<String>> countryCompetitorMap{get;set;}
        @AuraEnabled
        public Map<String,List<String>> countryNoOfEmployeesMap{get;set;}
        @AuraEnabled
        public String loggedPartnerCountry{get;set;}
        @AuraEnabled
        public boolean partnerhasAllCntryAcess{get;set;}
        @AuraEnabled
        public Map<String,List<String>> mapBrandCntry{get;set;}
        @AuraEnabled
        public Set<String> partnerAvailableCountries{get;set;}//ACO 3.0
    }
    public class BrandCountryWrapper{
        public List<String> countries{get;set;}
        public Map<String,List<String>> mapBrandCntry{get;set;}
    }
    public class UserInfoWrapper{
        public String partnerCountry{get;set;}
        public boolean partnerhasAllCntryAcess{get;set;}
        public Set<String> partnerAvailableCountries{get;set;}//ACO 3.0
    }
}