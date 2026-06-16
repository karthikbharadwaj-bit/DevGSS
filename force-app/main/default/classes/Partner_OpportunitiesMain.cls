/*
* Created By    : Ishwarya
* Created Date  : 03-12-2019
* Description   : Apex class for component Partner_OpportunitiesMain - Opportunities Page

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/

public class Partner_OpportunitiesMain {

    //Translation Start
      @AuraEnabled
      public static CommunityInfo.Translationswrap getTranslations(String objNames)
      {
          return CommunityInfo.getTranslations(objNames);
      }
      //Translation End

      //Method to get list of Opportunities to display in list view
      @AuraEnabled
      public static OppListWrapper getOppDataController(String selectedPartnerAccount, Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord) {
          //get list view of Opportunities
          OppListWrapper obj=new OppListWrapper();
          List<Account> accList = new List<Account>();
          List<Opportunity> oppList = new List<Opportunity>();
          Integer pSize = (Integer)pageSize;
          Integer pNumber = (Integer)pageNumber;
          //Offset for SOQL
          Integer offset = (pNumber - 1) * pSize;
          Integer recordEnd = pSize * pNumber;
          Integer totalRecords;
          String query = '';
          String AvayaOffice='';
          List<String> brandNamesList = getAccountList().partnerCommunityName;
          String masterLabel=getAccountList().communityDetailsRecord.MasterLabel;
          if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
              AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
          }
          if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
          totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
          } else {
              totalRecords=1000;
          }
          //Single Login code starts
          Set<Id> setUserAccIds = new Set<Id>();
          if(getAccountList().listUserAccountMap != null && !getAccountList().listUserAccountMap.isEmpty()){
              for(User_Account_Mapping__c uam : getAccountList().listUserAccountMap){
                  setUserAccIds.add(uam.Partner_Account__c);
              }
          }
          system.debug('setUserAccIds>'+setUserAccIds);
          //Single Login code ends

          String searchQry = '';
          if(null!= searchKeyWord && searchKeyWord!=''){
              String searchKey =  '\'%'+searchKeyWord + '%\'';
              if(searchBy=='Forecasted_Users__c'){
                  searchQry = ' And '+ searchBy+' ='+searchKeyWord;
              }else {
                  searchQry = ' and '+ searchBy+ '  Like '+searchKey;
              }
          }
          if(selectedPartnerAccount == null){
              accList = getAccountList().listPartnerAccounts;
              if(accList.size() > 0)
              {
                  selectedPartnerAccount = accList[0].Id;
              }
          }

          //Fix for PCM JIRA issue BZS-3636 - start
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
          //Fix for PCM JIRA issue BZS-3636 - end
          if(brandNamesList.contains('Avaya Cloud Office')){
               query = 'select count() from Opportunity where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')'+searchQry;
          }else{
              //added if condition for Fix for PCM JIRA issue BZS-3636
              if(brandNamesList.contains('RingCentral')&&masterLabel == 'ignite'){
                  query = 'select count() from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Avaya_Partnership_Opportunity__c = true '+searchQry;
              }else if(brandNamesList.contains('Unify Office')){
                  query = 'select count() from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true '+searchQry;
              }else{
                  query = 'select count() from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true '+searchQry;
              }
          }
          Integer totSize = Database.countquery(query);

          if(totSize<totalRecords){
              totalRecords = totSize;
          }
          if(null!=totalRecords && totalRecords > 0){
              if(brandNamesList.contains('Avaya Cloud Office')){
              query = 'select Name,type ,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name   from Opportunity where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
              }
              else{
                  //added if condition for Fix for PCM JIRA issue BZS-3636
                  if(brandNamesList.contains('RingCentral')&&masterLabel == 'ignite'){
                      query = 'select Name,type ,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = '+'\''+currentContact+'\') and Avaya_Partnership_Opportunity__c = true';
                  }else if(brandNamesList.contains('Unify Office')){
                      query = 'select Name,type ,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true';
                  }else{
                      query = 'select Name,type ,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Avaya_Cloud_Specialist__c, RC_Overlay__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Opportunity where Brand_Name__c IN: brandNamesList and (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Opportunity__c = true';
                  }
              }
              query += searchQry;
              query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset';
              oppList = Database.query(query);
              obj.oppList = oppList;
          }
          System.debug('query in opp list '+query);
          obj.pageSize = pSize;
          obj.pageNumber = pNumber;
          obj.recordStart = offset + 1;
          obj.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
          obj.totalRecords = totalRecords;
          return obj;
      }
      @AuraEnabled
      public static Boolean isIgniteUQTFlow(){
        return FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_IGNITE_UQT_FLOW);
      }

      @AuraEnabled
      public static AccountListWrapper getAccountList(){
          //get ParentAccount list to be populated in drop-down of list view
          AccountListWrapper accListWrapper=new AccountListWrapper();
          List<Account> listofPartnerAccounts =new List<Account>();
          String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
          CommunityInfo comm = new CommunityInfo();
          Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
          List<String> brandNamesList = comDetail.Brand_Name__c.split(';');

          //Single Login starts
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
          //Single Login code ends

          if(selectedPartnerAccount != NULL){
              for(Account acc : [SELECT Id, Name,Partner_Role__c FROM Account WHERE Id =:selectedPartnerAccount
                                 AND Type='Partner' order by Name]){
                                     listofPartnerAccounts.add(acc);

                                     if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                         accListWrapper.isAvaya=true;
                                         accListWrapper.isMaster=false;
                                     }
                                     else if(acc.Partner_Role__c=='Master Agent'){
                                         accListWrapper.isAvaya=false;
                                         accListWrapper.isMaster=true;
                                     }
                                 }
              accListWrapper.listPartnerAccounts=listofPartnerAccounts;
          }
          accListWrapper.partnerCommunityName= brandNamesList;
          accListWrapper.communityDetailsRecord=comDetail;
          return accListWrapper;
      }

      //Method to get partner quote details
      @AuraEnabled
      public static String getPartnerQuote(String selectedOpportunity){
          Partner_Quote__c primaryPartnerQuote =new Partner_Quote__c();
          String primaryQuoteId = '';
          Opportunity opportunityRecord = new Opportunity();
          ID recordId = selectedOpportunity;
          DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
          List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
          String query = ' SELECT ' + String.join( fieldNames, ',' ) +',(Select Id from Partner_Quotes__r where Primary__c = true LIMIT 1)'+ ' FROM ' + describeResult.getName() +
              ' WHERE ' + ' Id = :recordId ' + ' LIMIT 1 ';

          // return generic list of sobjects or typecast to expected type
          List<SObject> records = Database.query(query);
          opportunityRecord = (Opportunity)records[0];
          if(opportunityRecord.Partner_Quotes__r != null && opportunityRecord.Partner_Quotes__r.size()>0)
          {
              primaryPartnerQuote = opportunityRecord.Partner_Quotes__r[0];
              primaryQuoteId = primaryPartnerQuote.Id;
          }
          return primaryQuoteId;
      }

      @AuraEnabled
      public static OppWrapper getOppRecordList(String OppRecordId){
          //get data for record detail page for selected opportunity
          Opportunity oppRecord =new Opportunity();
          OppWrapper ow = new OppWrapper();
          List<Contact> userInfoContact = new List<Contact>();
          AccountListWrapper accListWrapper=getAccountList();

          Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
          Boolean hasReadAccess = false;
          List<UserRecordAccess> listOfUserRecordAccess = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId =:UserInfo.getUserId() AND RecordId =:OppRecordId];
          if(!listOfUserRecordAccess.isEmpty() && listOfUserRecordAccess[0].HasReadAccess) {
              hasReadAccess = true;
          }
          if(hasReadAccess){
              //Added RFP__c for ALE
              //Removed RFP__c for BZS-4808
              //Added Partner_Classification__c for PBC-9705 P2CSharing
              //added Account.Sector__c for PBC-9537 EDU
              //Added Partners_CRM_Opporunity_ID__c under PBC-10584
              oppRecord= [select Id,Avaya_Cloud_Specialist__c, RC_Overlay__c, (SELECT Id FROM Partner_Quotes__r WHERE RecordType.Name = 'Change Order Request' AND Status__c = 'Pending Order'),Name, Inside_Sales_Rep__r.Name,Inside_Sales_Rep__r.Full_Name__c,
                          RecordType.DeveloperName,Primary_Opportunity_Contact__r.Name,AccountId,Account.Name, Account.CSM__c, Account.OwnerId, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,
                      Partner_Account__r.Partner_ID__c,Partner_Contact__c,Partner_Account__r.Partner_Classification__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Inside_Sales_Rep__c,
                      Brand_Name__c,Lead_Score__c,Description,Number_of_Employees__c,Expiration_Date__c,CreateDateTime__c,Existing_Solution_Provider__c,Prompting_Change__c,Decision_Maker__c,Partner_ID__c,LeadSource
                      ,Primary_Opportunity_Contact__c,Probability,Forecasted_Users__c,Forecasted_RingCentral_Video_Users__c,ForecastCategoryName,Currently_in_a_contract__c,Project_budget__c,Sales_Notes__c,(select Id,dsfs__Opportunity__c,Name,dsfs__Sender__c,dsfs__Subject__c,dsfs__Envelope_Status__c,dsfs__Hrs_Sent_to_Sign__c,
                                                                                                                                                                        dsfs__Sent_Date_Time__c,dsfs__Completed_Date_Time__c from dsfs__R00N80000002fD9vEAE__r where dsfs__Envelope_Status__c='Completed'),
                      (Select id,Name,Status__c,Type__c,CreatedDate from Deal_Supports__r),Type,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Account.Sector__c,Deal_Registration__r.Ignite_Deal__c,Mitel_Data_Sharing__c,Partners_CRM_Opporunity_ID__c, OwnerId,Installation_Service_Provider__c, (Select id,name,isPrimary__c,Approved_Status__c from Quotes where isPrimary__c=true LIMIT 1) from Opportunity
                      where Id=:OppRecordId];
              ow.oppty = oppRecord;
              ow.accCountry = oppRecord.Account.billingCountry;//ACO 3.0
              ow.isAvaya = accListWrapper.isAvaya;
              ow.isMaster = accListWrapper.isMaster;
              ow.isReadOnly=isReadOnlyProfile;
              ow.isSingleLogin= accListWrapper.isSingleLogin;
              if(!oppRecord.quotes.isEmpty() && oppRecord.quotes.size() > 0 ){
                  ow.salesQuote = oppRecord.quotes[0];
                  Id salesQuoteId = oppRecord.quotes[0].Id;
                  List<Deal_Support__c> objDealSupportList = [Select Id,Type__c,Status__c FROM Deal_Support__c WHERE Sales_Agreement__c = :salesQuoteId and (Type__c = 'Initial Order' or Type__c = 'Change Order') and (Status__c != 'Closed-Approved' or Status__c != 'Closed') ORDER BY CreatedDate DESC limit 1];
                  if(objDealSupportList != null && !objDealSupportList.isEmpty()) {
                      ow.dealSupportRec = objDealSupportList[0];
                      ow.isProcessOrderRequestExist = true;
                  }
              }
          }
          List<User> userInfoDetail =  [SELECT ContactId FROM User WHERE Id =: UserInfo.getUserId()];
          if(!userInfoDetail.isEmpty()){
               userInfoContact =  [SELECT Id, Name, Certified_Ignite_partner_contact__c
                                         FROM Contact
                                         WHERE Id =: userInfoDetail.get(0).ContactId];
          }
          if(!userInfoContact.isEmpty()){
              ow.isIgnite = userInfoContact.get(0).Certified_Ignite_partner_contact__c;
          }
          ow.hasReadAccess=hasReadAccess;
          CommunityInfo comm = new CommunityInfo();
          Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
          ow.partnerCommunityName = comDetail.Brand_Name__c.split(';');
          ow.communityDetailsRecord=comDetail;
          return ow;
      }

      @AuraEnabled
      public static Partner_Quote__c createPartnerQuoteForUpsell(String accID) {

          List<Subscription__c> listOfSubscription = new List<Subscription__c>();
          Partner_Quote__c partnerQuoteRec;
          listOfSubscription =  [SELECT Id, Account__c, Active__c FROM Subscription__c WHERE Account__c = :accID and Active__c = true ];

          return partnerQuoteRec;
      }

      @AuraEnabled
      public static Quote_PartnerDetailController.AccountCheckListWrapper checkPartnerQuoteExistFORAccount(String accID) {
          Quote_PartnerDetailController.AccountCheckListWrapper obj = Quote_PartnerDetailController.CheckAccountListExist(accID);
          return obj;
      }

      @AuraEnabled
      public static void updateAccountChecklist(Account_Checklist__c objCheckListRec , String accId) {
          Quote_PartnerQuoteUtil.updateAccountChecklist(objCheckListRec,accId);
      }

      @AuraEnabled
      public static String updateOpportunity(Opportunity oppty){
          //upon edit,save the record
          String response = 'Success';
          try
          {
              update oppty;
          }
          catch(Exception e)
          {
              response = e.getMessage();
          }
          return response;
      }
    @AuraEnabled
    public static OppResponseWrapper createOpportunity(Opportunity oppty,String accountId,String chosenCloudSpecialistValue){
        OppResponseWrapper oppWrapper = new OppResponseWrapper();
        oppWrapper.responseMessage = 'Success';
        oppWrapper.opp = new Opportunity();
        Id partnerAccount = null;
        Id parentPartnerAccount = null;
        String businessIdentityId = '';
        String businessIdentityCurrency = '';
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        List<String> brandNamesList = getAccountList().partnerCommunityName;

        Community_Details__mdt comDetail=getAccountList().communityDetailsRecord;
        if(accountId != null){
            try
            {
                for(Account a : [Select id,Partner_Account__c,Partner_ID__c,BusinessIdentity__c,CurrencyIsoCode,
                                Partner_Contact__c,partner_owner__c,Parent_Partner_Account__c,RC_Brand__c,OwnerId,
                                (select id, CurrencyIsoCode,Tier_Name__c from opportunities order by createddate ASC),(SELECT Id,Name from contacts limit 1)
                                from account where id= :accountId])
                {
                    if(null!=a.opportunities && a.opportunities.size()>0  && !a.opportunities.isEmpty()){
                        oppty.CurrencyIsoCode = a.opportunities[0].CurrencyIsoCode;
                        if(a.opportunities[0].Tier_Name__c !=null) {
                            oppty.Tier_Name__c=a.opportunities[0].Tier_Name__c;
                        }
                    }

                    oppty.AccountId = a.Id;
                    oppty.Partner_Account__c = a.Partner_Account__c;
                    oppty.Partner_Contact__c = a.Partner_Contact__c;
                    oppty.partner_owner__c = a.partner_owner__c;
                    oppty.Partner_ID__c = a.Partner_ID__c;
                    partnerAccount = a.Partner_Account__c;
                    parentPartnerAccount = a.Parent_Partner_Account__c;
                    oppty.Brand_Name__c = a.RC_Brand__c;
                    oppty.OwnerId = a.OwnerId;
                    if(a.contacts!=null && a.contacts.size()>0 && !a.contacts.isEmpty()){
                        oppty.Primary_Opportunity_Contact__c=a.contacts[0].Id;
                    }

                    for (PackageBusinessIdentityMapping__c biMapping : PackageBusinessIdentityMapping__c.getAll().values()) {
                        if (biMapping.Active__c && biMapping.BiName__c.equalsIgnoreCase(a.BusinessIdentity__c)
                            && biMapping.Currency__c.equalsIgnoreCase(a.CurrencyIsoCode))
                        {
                            businessIdentityId = biMapping.BiId__c;
                            businessIdentityCurrency = biMapping.Currency__c;
                        }
                    }
                    if (businessIdentityId != '' && businessIdentityCurrency != '') {
                        oppty.BusinessIdentity__c = OpportunityHelper.businessIdentitySerialize(Integer.ValueOf(businessIdentityId), businessIdentityCurrency);
                    }
                }

                //BZS-5535 Changing "Upsell" to "Existing Business "
                oppty.Type ='Existing Business';

                String AvayaOffice = '';
                if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
                    AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
                }
                oppty.Is_Billing_Opportunity__c = true;
                oppty.StageName = '1. Qualify';

                //BZS-5535 Changing "VAR opportunity" to "New Sales Opportunity "
                Id recordTypeId =   [SELECT Id FROM RecordType WHERE DeveloperName = 'New_Sales_Opportunity' AND sObjectType = 'Opportunity'].Id;
                oppty.RecordTypeId = recordTypeId ;

                oppty.OwnerId = comDetail.Portal_Deal_Desk_User__c;
                if(chosenCloudSpecialistValue!=null && chosenCloudSpecialistValue!='') {
                    oppty.Avaya_Cloud_Specialist__c=chosenCloudSpecialistValue;
                }
                oppty.Avaya_Partnership_Opportunity__c = true;
                insert oppty;
                oppWrapper.opp = getOppRecordList(oppty.Id).oppty;
            }
            catch(Exception e)
            {
                oppWrapper.responseMessage = e.getMessage();
            }
        } else {
            oppWrapper.responseMessage = 'No account related to the Opportunity!';
        }
        return oppWrapper;
    }

      @AuraEnabled
      public static OppListWrapper getDataForViewAll(Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord){
          //get list view of Leads
          OppListWrapper objOppWrapper = new OppListWrapper();

          List<Opportunity> oppList = new List<Opportunity>();
          Integer pSize = (Integer)pageSize;
          Integer pNumber = (Integer)pageNumber;

          //Offset for SOQL
          Integer offset = (pNumber - 1) * pSize;
          Integer recordEnd = pSize * pNumber;
          String query = '';
          Integer totalRecords;
          String AvayaOffice='';
          List<String> brandNamesList = getAccountList().partnerCommunityName;
          if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
              AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
          }
          if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
          } else {
            totalRecords=1000;
          }
          String searchQry = '';
          if(null!= searchKeyWord && searchKeyWord!=''){
              String searchKey =  '\'%'+searchKeyWord + '%\'';
              if(searchBy=='Forecasted_Users__c'){
                  searchQry = ' And '+ searchBy+' ='+searchKeyWord;
              }else {
                  searchQry = ' and '+ searchBy+ '  Like '+searchKey;
              }
          }
          if(brandNamesList.contains('Avaya Cloud Office')) {
              query = 'select count() from Opportunity where Avaya_Partnership_Opportunity__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
          } else {
              query = 'select count() from Opportunity where Brand_Name__c IN: brandNamesList and Avaya_Partnership_Opportunity__c = true';
          }
            if(null!= searchKeyWord) {
              query += searchQry;
            }
          System.debug('FinalQuery=====>' + query);
          Integer totSize = Database.countquery(query);
          System.debug('TotalSize=====>' + totSize);

          if(totSize<totalRecords){
              totalRecords = totSize;
          }

          if(null!=totalRecords && totalRecords > 0){
             if(brandNamesList.contains('Avaya Cloud Office')) {
              query = 'select Name,type ,Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name  from Opportunity where Avaya_Partnership_Opportunity__c = true and (Brand_Name__c = null OR Brand_Name__c = '+'\''+AvayaOffice+'\')';
             } else {
              query = 'select Name,type ,Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Description,AccountId,Account.Name, Tier_Name__c, StageName, CloseDate, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,RecordTypeId,RecordTypeName__c,Forecasted_Users__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,Account.BillingState,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Opportunity where Brand_Name__c IN: brandNamesList and Avaya_Partnership_Opportunity__c = true';
             }
              query += searchQry;
              query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset';

              System.debug('FinalQuery2=====>' + query);
              oppList = Database.query(query);

              objOppWrapper.oppList = oppList;
          }
          System.debug('query in view all '+query);
          objOppWrapper.pageSize = pSize;
          objOppWrapper.pageNumber = pNumber;
          objOppWrapper.recordStart = offset + 1;
          objOppWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
          objOppWrapper.totalRecords = totalRecords;
          return objOppWrapper;
      }

      @AuraEnabled
      public static Boolean isShowUnifiedQuotingWizard(Id oppId){
          if (String.isBlank(oppId)) {
              return false;
          }

          List<Opportunity> opp = (List<Opportunity>) new OpportunitySelector()
              .selectOpportunityForQuoteWizard(oppId)
              .setLimit(1)
              .executeQuery();

          if (opp.isEmpty()) {
              return false;
          }

          Opportunity currentOpp = opp.get(0);
          String partnerProgram = currentOpp.PartnerProgram__c;

          if (currentOpp.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS) {
              opp = (List<Opportunity>) new OpportunitySelector()
                  .newQueryFactory()
                  .selectFields(new List<String>{'Id', 'Type', 'PartnerProgram__c'})
                  .setCondition('AccountId = :bind0 AND Type = :bind1')
                  .addOrdering('CreatedDate', QueryFactory.SortOrder.ASCENDING)
                  .setQueryBindings(new List<Object>{ currentOpp.AccountId, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS })
                  .setLimit(1)
                  .executeQuery();

              partnerProgram = opp.isEmpty() ? null : opp.get(0).PartnerProgram__c;
          }

          List<Ignite_Excluded_Brands__mdt> igniteDisabledBrandsMDT = Ignite_Excluded_Brands__mdt.getAll().values();
          List<String> allDisabledBrands = new List<String>();
			for (Ignite_Excluded_Brands__mdt igniteDisabledBrands : igniteDisabledBrandsMDT) {
				allDisabledBrands.add(igniteDisabledBrands.Brand__c);
			}

          return FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_IGNITE_UQT_FLOW) && !allDisabledBrands.contains(currentOpp.Brand_Name__c) && partnerProgram == 'Ignite';
      }

      @AuraEnabled
      public static String getDOSCaseRecordTypeId() {
         return CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
      }

     @AuraEnabled
     public static Boolean isExistingBusiness(String accId) {
            if (String.isBlank(accId)) {
                return false;
            }

            Account acc = (Account) new AccountSelector()
                            .selectAccountById(Id.valueOf(accId))
                            .executeQuery()
                            .get(0);

            return acc!=null && String.isNotBlank(acc.RC_User_ID__c) && String.isNotBlank(acc.Billing_ID__c);
     }

      public class OppListWrapper{
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
          public List<Opportunity> oppList {get;set;}

      }
      public class OppResponseWrapper{
          @AuraEnabled
          public String responseMessage {get;set;}
          @AuraEnabled
          public Opportunity opp {get;set;}
      }
      public class OppWrapper{
          @AuraEnabled
          public Boolean isAvaya {get;set;}
          @AuraEnabled
          public Opportunity oppty {get;set;}
          @AuraEnabled
          public boolean isMaster {get;set;}
          @AuraEnabled
          public boolean isReadOnly {get;set;}
          @AuraEnabled
          public List<String> partnerCommunityName{get;set;}
           @AuraEnabled
          public boolean hasReadAccess{get;set;}
          @AuraEnabled
          public boolean isIgnite{get;set;}
          @AuraEnabled
          public boolean isSingleLogin {get;set;}
          @AuraEnabled
          public Community_Details__mdt communityDetailsRecord {get;set;}
          @AuraEnabled
          public String accCountry{get;set;}//ACO 3.0
          @AuraEnabled
          Public Quote salesQuote {get;set;}
          @AuraEnabled
          public boolean isProcessOrderRequestExist {get;set;}
          @AuraEnabled
          public Deal_Support__c dealSupportRec {get;set;}
      }
      public class AccountListWrapper{
          @AuraEnabled
          public List<Account> listPartnerAccounts {get;set;}
          @AuraEnabled
          public boolean isAvaya {get;set;}
          @AuraEnabled
          public boolean isMaster {get;set;}
          @AuraEnabled
          public boolean isSingleLogin {get;set;}
          @AuraEnabled
          public List<String> partnerCommunityName{get;set;}
          @AuraEnabled
          public Community_Details__mdt communityDetailsRecord {get;set;}
          @AuraEnabled
          public List<User_Account_Mapping__c> listUserAccountMap {get;set;} //added for Single Login
      }
  }