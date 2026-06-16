/*       
* Created By    : Girish
* Created Date  : 22-11-2019
* Description   : Controller class for Partner_Customer component
* Test Class    :       

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class Partner_Customer_Controller {
    
    public static String selectedUserAccountId {get;set;}
    public static String selectedUserPartnerAccountId {get;set;}
    public static String selUserUltimatePartnerAccountId {get;set;}
    public static String selectedUserContactId {get;set;}
    public static String selectedStatus {get;set;}
    //Method to get all customer details
    @AuraEnabled
    public static CustomerDataTableWrapper getCustomerDataController(String searchKeyWord, String searchBy,
                                                                     Decimal pageNumber, Decimal pageSize) {
                                                                         
                                                                         Integer pSize = (Integer)pageSize;
                                                                         Integer pNumber = (Integer)pageNumber;
                                                                         Integer totalRecords;
                                                                         String AvayaOffice='';
                                                                         CommunityInfo comm = new CommunityInfo();   
                                                                         Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
                                                                         List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
                                                                         
                                                                         //Single Login code starts
                                                                         Set<Id> setUserId = new Set<Id>();
                                                                         setUserId.add(UserInfo.getUserId());
                                                                         List<User_Account_Mapping__c> listUserAccountMap = new List<User_Account_Mapping__c>([Select Id, Partner_Account__c, Partner_User__c 
                                                                                                                                                               from User_Account_Mapping__c 
                                                                                                                                                               where Partner_User__c IN:setUserId]);
                                                                         system.debug('listUserAccountMap>>'+listUserAccountMap);
                                                                         Set<Id> setUserAccIds = new Set<Id>();
                                                                         if(listUserAccountMap != null && !listUserAccountMap.isEmpty()){
                                                                             for(User_Account_Mapping__c uam : listUserAccountMap){
                                                                                 setUserAccIds.add(uam.Partner_Account__c);
                                                                             }
                                                                         }
                                                                         system.debug('setUserAccIds>'+setUserAccIds);
                                                                         //Single Login code ends
                                                                         
                                                                         if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
                                                                             AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
                                                                         }
                                                                         if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
                                                                             totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
                                                                         } else {
                                                                             totalRecords=1000;
                                                                         }
                                                                         User currentUser = [SELECT Id, IsPortalEnabled, Partner_Account_Id__c,
                                                                                             ContactId, Contact.Account.Id,Contact.Account.Partner_ID__c, 
                                                                                             Contact.Account.Ultimate_Partner_ID__c 
                                                                                             FROM User WHERE Id = :UserInfo.getUserId()];
                                                                         if(currentUser != NULL && currentUser.ContactId != NULL){
                                                                             selectedUserAccountId = currentUser.Contact.Account.Id;  
                                                                             selectedUserContactId = currentUser.ContactId;
                                                                             selectedUserPartnerAccountId = currentUser.Contact.Account.Partner_ID__c;
                                                                             selUserUltimatePartnerAccountId = currentUser.Contact.Account.Ultimate_Partner_ID__c;
                                                                             selectedStatus = 'Approved';                       
                                                                         }
                                                                         
                                                                         //Offset for SOQL 
                                                                         Integer offset = (pNumber - 1) * pSize;  
                                                                         
                                                                         String query = '';
                                                                         if(brandNamesList.contains('Avaya Cloud Office')){
                                                                             query = 'select count() from Account where type='+'\'Customer\' and Avaya_Partnership_Account__c = true and (RC_Brand__c = null OR RC_Brand__c = \''+AvayaOffice+'\') and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')';  
                                                                         }else if(brandNamesList.contains('Unify Office')){
                                                                             query = 'select count() from Account where type='+'\'Customer\' and Avaya_Partnership_Account__c = true and RC_Brand__c IN: brandNamesList and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')'; 

                                                                         }else{ 
                                                                                 query = 'select count() from Account where type='+'\'Customer\' and Avaya_Partnership_Account__c = true and RC_Brand__c IN: brandNamesList and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')';      
                                                                         }
                                                                         if(setUserAccIds != null && setUserAccIds.size() >0){
                                                                             query += ' and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\')';
                                                                         }
                                                                         if(null!= searchKeyWord && searchKeyWord != ''){
                                                                             String searchKey =  '\'%'+searchKeyWord + '%\'';
                                                                             query += ' And '+ searchBy+ ' Like '+searchKey;
                                                                         }  
                                                                         Integer totSize = Database.countquery(query);
                                                                         
                                                                         if(totSize<totalRecords){
                                                                             totalRecords = totSize;
                                                                         }
                                                                         
                                                                         Integer recordEnd = pSize * pNumber;
                                                                         
                                                                         //Instance of Customer DataTable Wrapper Class
                                                                         CustomerDataTableWrapper objDT =  new CustomerDataTableWrapper();  
                                                                         objDT.pageSize = pSize;
                                                                         objDT.pageNumber = pNumber;
                                                                         objDT.recordStart = offset + 1;
                                                                         objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                                                                         objDT.totalRecords = totalRecords;
                                                                         objDT.communityDetailsRecord=comDetail;
                                                                         if(listUserAccountMap != null && !listUserAccountMap.isEmpty()) {
                                                                             objDT.isSingleLogin = true;
                                                                         }
                                                                         if(brandNamesList.contains('Avaya Cloud Office')){
                                                                             query = 'select Id,Parent_Partner_Account__r.Parent_Partner_Account__c, Partner_Role__c,Name, Phone, MRR__c, RC_Service_name__c, Partner_Account__r.name,Partner_ID__c,RC_Upgrade_Date__c,RC_Account_Status__c,DLs_of_current_customers__c, Partner_Account_Name__c,'+
                                                                                 'BillingCity,Parent_Partner_Account__r.Name, Partner_Account__r.Partner_Channel_Manager__c,Partner_Channel_Manager__c,Number_of_DL_s__c'+
                                                                                 ' FROM Account  Where type= '+'\'Customer\' and Avaya_Partnership_Account__c = true and (RC_Brand__c = null OR RC_Brand__c = \''+AvayaOffice+'\') and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')';
                                                                         } else if(brandNamesList.contains('Unify Office')){
                                                                             query = 'select Id,Parent_Partner_Account__r.Parent_Partner_Account__c, Partner_Role__c,Name, Phone, MRR__c, RC_Service_name__c, Partner_Account__r.name,Partner_ID__c,RC_Upgrade_Date__c,RC_Account_Status__c,DLs_of_current_customers__c, Partner_Account_Name__c,'+
                                                                            'BillingCity,Parent_Partner_Account__r.Name, Partner_Account__r.Partner_Channel_Manager__c,Partner_Channel_Manager__c,Number_of_DL_s__c'+
                                                                            ' FROM Account  Where type= '+'\'Customer\' and Avaya_Partnership_Account__c = true and RC_Brand__c IN: brandNamesList and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')';
                                                                         }else{
                                                                            query = 'select Id,Parent_Partner_Account__r.Parent_Partner_Account__c, Partner_Role__c,Name, Phone, MRR__c, RC_Service_name__c, Partner_Account__r.name,Partner_ID__c,RC_Upgrade_Date__c,RC_Account_Status__c,DLs_of_current_customers__c, Partner_Account_Name__c,'+
                                                                            'BillingCity,Parent_Partner_Account__r.Name, Partner_Account__r.Partner_Channel_Manager__c,Partner_Channel_Manager__c,Number_of_DL_s__c'+
                                                                            ' FROM Account  Where type= '+'\'Customer\' and Avaya_Partnership_Account__c = true and RC_Brand__c IN: brandNamesList and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedUserAccountId+'\')';
                                                                         }
                                                                         if(setUserAccIds != null && setUserAccIds.size() >0){
                                                                             query += ' and (Partner_Account__c IN: setUserAccIds or Partner_account__c = '+'\''+selectedUserAccountId+'\')';
                                                                         }
                                                                         if(null!= searchKeyWord && searchKeyWord != ''){
                                                                             String searchKey =  '\'%'+searchKeyWord + '%\'';
                                                                             query += ' And '+ searchBy+ ' Like '+searchKey;
                                                                         }
                                                                         query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset'; 
                                                                         objDT.customerList = Database.query(query);  
                                                                         List<Account> listPartnerAccounts= objDT.customerList;
                                                                         System.debug('objDT.customerLis+++'+objDT.customerList);
                                                                         if(objDT.customerList.size() > 0){
                                                                         	System.debug('objDT.customerLis+++'+objDT.customerList.get(0).Parent_Partner_Account__r.Parent_Partner_Account__c);    
                                                                         }
                                                                         
                                                                         String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
                                                                         if(selectedPartnerAccount != NULL){
                                                                             for(Account acc : [SELECT Id, Name,Partner_Role__c FROM Account WHERE Id =:selectedPartnerAccount 
                                                                                                AND Type='Partner' order by Name]){
                                                                                                    
                                                                                                    if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                                                                                        objDT.isAvaya=true;
                                                                                                        objDT.isMaster=false;
                                                                                                    }
                                                                                                    else if(acc.Partner_Role__c=='Master Agent'){
                                                                                                        objDT.isAvaya=false;
                                                                                                        objDT.isMaster=true;
                                                                                                    }
                                                                                                }
                                                                             
                                                                         }
                                                                         objDT.partnerCommunityName = brandNamesList;
                                                                         return objDT;
                                                                     }
    
    
    @AuraEnabled
    public static String getSelectedAccountDetails (String accountId){
        SelectedAccountWrapper selWrapper = new SelectedAccountWrapper();
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        selWrapper.partnerCommunityName= brandNamesList;
        selWrapper.communityDetailsRecord=comDetail;
        
        List<String> contactRoles = new List<String>();
        for(Schema.PicklistEntry ple:AccountContactRole.Role.getDescribe().getPicklistValues()){
            if(!ple.getLabel().startsWith('RC')){
                contactRoles.add(ple.getLabel());
            } 
        }
        
        selWrapper.contactRoles = contactRoles;
        
        List<String> accountChecklistTypes = new List<String>();
        for(Schema.PicklistEntry ple:Account_Checklist__c.Type__c.getDescribe().getPicklistValues()){
            accountChecklistTypes.add(ple.getLabel());
        }          
        
        //Added Primary_Contact_Phone__c,Contract_Status_Change_To__c, Contract_Status_Request_Reason__c for ALE
        //added Partner_Classification__c for PBC-9705 P2CSharing
        //added Sector__c for PBC-9537 EDU
        Account a = [select Id, name, phone, MRR__c, RC_Service_name__c,BillingStreet,
                     BillingCity,(SELECT Id,Name,CreatedDate, CreatedBy.Name,Account__c,Account_Cancellation_Date__c,Account_Cancellation_Reason__c,Company_Details__c,
                                  Cost_Center__c,Covert_POC_to_Paid_Account__c,Payment_Method__c,Primary_Contact_Email__c,Primary_Contact_First_Name__c,Primary_Contact_Last_Name__c,
                                  Primary_Contact_Phone__c, Refund_Request_Amount__c,Refund_Request_Reason__c,Status__c,Tax_Exemption_Location_changes__c,
                                  Accounts_Payable_email_address__c,Legal_City__c,Legal_Company_Name__c,Legal_Country__c,Legal_Physical_Address__c,
                                  Legal_State__c,Legal_Zip_Code__c, Contract_Status_Change_To__c, Contract_Status_Request_Reason__c FROM Account_Change_Requests__r),Parent_Partner_Account__r.Name, 
                     Current_Owner__r.Name,BillingState,BillingPostalCode,BillingCountry,RC_User_ID__c,AccountNumber,RC_Account_Status__c,Number_of_DL_s__c,RC_Upgrade_Date__c,Sales_Notes__c, 
                     Inside_Sales_Rep__c,Inside_Sales_Rep__r.Name,Inside_Sales_Rep__r.Full_Name__c,RC_Account_Number__c,BusinessIdentity__c,Type_of_Customer_or_Prospect__c,Partner_Contact__r.Name, Mitel_Data_Sharing__c, Partner_Account__r.Partner_Classification__c, Sector__c 
                     From Account where Id=:accountId limit 1];
        if(null!=a && null!= a.id){
            selWrapper.showNewOppBtn = false;
            if(a.RC_Account_Status__c != null && (a.RC_Account_Status__c.equalsIgnoreCase('Paid') || a.RC_Account_Status__c.equalsIgnoreCase('Poc'))) {
                selWrapper.showNewOppBtn = true; 
            }
            selWrapper.account=a;
            List<Account_Change_Request__c> accountCheckList = new List<Account_Change_Request__c>();
            List<AccountCheckListWrapper> accWrpList = new List<AccountCheckListWrapper>();
            accountCheckList = a.Account_Change_Requests__r;     
            for(Account_Change_Request__c accCheckList: accountCheckList){
                AccountCheckListWrapper accWrp = new AccountCheckListWrapper();
                accWrp.accChecklistRec = accCheckList;
                Datetime dt = (Datetime)accCheckList.CreatedDate;
                accWrp.submittedDate = dt.date();
                accWrp.paymentMethod = accCheckList.Payment_Method__c;
                accWrp.costCenter = accCheckList.Cost_Center__c;
                accWrp.converttoPaidAccount = accCheckList.Covert_POC_to_Paid_Account__c;
                accWrp.billingAddress = accCheckList.Company_Details__c;
                accWrp.locationChange = accCheckList.Tax_Exemption_Location_changes__c;
                accWrpList.add(accWrp);
            }
            selWrapper.accountCheckLists = accWrpList;     
        }
        if(accountId!=null || accountId!=''){   
            
            List<Contract> listContract = [Select Id,ContractNumber,Status,Source__c from Contract where Account.Id=:accountId];
            if(listContract.size()>0){
                selWrapper.contractList=listContract;
            }
        }
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
        if(selectedPartnerAccount != NULL){
            for(Account acc : [SELECT Id, Name,Partner_Role__c FROM Account WHERE Id =:selectedPartnerAccount 
                               AND Type='Partner' order by Name]){
                                   if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                       selWrapper.isAvayaOnly=true;
                                   }
                               }
            
        }
        
        List<Contact> contacts = [SELECT Id, name, RC_Customer_Role__c,phone
                                  FROM Contact
                                  WHERE account.id=:accountId];        
        List<AccountContactRole> acctContactRoles = [SELECT Id,toLabel(role),isPrimary,Contact.Name,Contact.FirstName,Contact.LastName,
                                                     Contact.Phone,Contact.Email,Contact.Id
                                                     FROM AccountContactRole
                                                     WHERE AccountId=:accountId];
        //changes June 01, 2020 - Adding Cases tab to Customer tab in Internal RC - Y
        List<Case> listCases = [SELECT Id,  CaseNumber, Status, Contact_Name__c, CreatedDate, Brand_Account__c, OwnerId, Owner.Name, ClosedDate 
                            FROM Case 
                            WHERE AccountId=:accountId];
        if(listCases.size()>0){
            selWrapper.casesList = listCases; //june 01, 2020 - Y 
        }
        
        selWrapper.name = a.name;
        selWrapper.phone = a.phone;
        selWrapper.mrr = String.valueOf(a.MRR__c);
        selWrapper.billingCity = a.BillingCity;                   
        selWrapper.Id = a.Id;
        
        
        selWrapper.contactsList = contacts;
        selWrapper.accountContactsList = acctContactRoles; 
        selWrapper.isReadOnly=isReadOnlyProfile;                                                             
        return JSON.serializePretty(selWrapper);
    }
    
    //Method to get opportunities under a customer
    @AuraEnabled
    public static List<Opportunity> getOpportunity(String accountId){
        List<Opportunity> listOppt = new List<Opportunity>();
        if(accountId!=null && accountId!=''){
            listOppt = [select Id,Name,StageName,Tier_Name__c,CloseDate,Forecasted_Users__c,CreatedDate,Owner.Name from Opportunity where account.id=:accountId];
        }
        return listOppt;
    }
    
     //Translation Start
     @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }
    
    //Translation End
    
    //Method to create contact and associate Account-Contact role        
    @AuraEnabled
    public static Map<String, String> createContactRecord(Contact newContact) {
        // Forming a  string map to return response
        Map<String,String> resultMap = new Map<String,String>();
        resultMap = Partner_Customer_ContactController.createContactRecord(newContact);
        // Returning the result string map
        return resultMap; 
    }
    //Method to insert account checklist records
    @AuraEnabled
    public static Map<String, String>  insertAccountCheckList (String typeName, String comments, String acctId){  
        Map<String,String> resultMap = new Map<String,String>();
        try{
            Account_Checklist__c acctCheckList = new Account_Checklist__c();
            acctCheckList.Type__c = typeName;
            acctCheckList.Comments__c = comments;
            acctCheckList.Account__c = acctId;        
            insert acctCheckList;
            resultMap.put('status', 'success');
            resultMap.put('message', typeName+' request submitted!');  
            return resultMap;
        }catch(Exception exp){
            resultMap.put('status', 'error');
            resultMap.put('message',exp.getMessage());
            return resultMap;
        }        
    }
    //Method to delete account checklist records
    @AuraEnabled
    public static Map<String, String> deleteChecklistRecords (String accChkLstId){  
        Map<String,String> resultMap = new Map<String,String>();
        try{
            Account_Checklist__c acctCheckList = new Account_Checklist__c();
            acctCheckList.id = accChkLstId;             
            delete acctCheckList;
            resultMap.put('status', 'success');
            resultMap.put('message', ' Request revoked');  
            return resultMap;
        }catch(Exception exp){
            resultMap.put('status', 'error');
            resultMap.put('message',exp.getMessage());
            return resultMap; 
        } 
    }    
    //Method to retrieve Attachments
    @AuraEnabled
    public static List<Attachment> getAttachments(String parentId){
        List<Attachment> listAtt = new List<Attachment>();
        if(parentId!=null || parentId!=null){
            //Added contentType as part of fix to include files from Lightning
            listAtt = [select Name,Description,Parent.Name,contentType from Attachment where ParentId=:parentId];
        }
        return listAtt;
    }
    @AuraEnabled  
    public static List<ContentDocument> getContractFiles(string recordId){ 
        //get list of attachments to be displayed in record detail page for selected deal support
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        return [SELECT Id,Title,FileType FROM ContentDocument WHERE id IN: documentIds];  
    }
    @AuraEnabled
    public static String updateAccountContactRole(String accountId,String FirstName,String LastName,
                                                  String Email,String Phone,String CustomerRole,Boolean Target_Account_Primary_Member,
                                                  String accContactRoleId,String contactId){
                                                      String msg = Partner_Customer_ContactController.updateAccountContactRole(accountId,FirstName,LastName,Email,Phone,CustomerRole,Target_Account_Primary_Member,accContactRoleId,contactId);                                                      
                                                      return msg;
                                                  }
    public class SelectedAccountWrapper {       
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String phone {get;set;}
        @AuraEnabled
        public String mrr {get;set;}
        @AuraEnabled
        public String serviceName {get;set;}
        @AuraEnabled
        public String billingCity {get;set;}        
        @AuraEnabled
        public List<Contact> contactsList {get;set;}
        @AuraEnabled
        public List<Case> casesList {get;set;}
        @AuraEnabled
        public List<String> contactRoles{get;set;}
        @AuraEnabled
        public List<AccountContactRole> accountContactsList{get;set;}        
        @AuraEnabled
        public boolean isPrimaryAlreadyExists {get;set;} 
        @AuraEnabled
        public List<AccountCheckListWrapper> accountCheckLists {get;set;}
        @AuraEnabled
        public Account account {get;set;}
        @AuraEnabled
        public List<Contract> contractList {get;set;}
        @AuraEnabled
        public boolean isAvayaOnly {get;set;}
        @AuraEnabled
        public boolean showNewOppBtn {get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}
    }
    public class ContactWrapper{
        @AuraEnabled
        public Contact contact {get;set;}
        @AuraEnabled
        public boolean isPrimary {get;set;}      
        @AuraEnabled
        public String role {get;set;}
    }
    
    //Wrapper Class For Customer DataTable  
    public class CustomerDataTableWrapper {
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
        public List<Account> customerList {get;set;} 
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
    }
    public class AccountCheckListWrapper {
        @AuraEnabled
        public Account_Change_Request__c accChecklistRec {get;set;}
        @AuraEnabled
        public Date submittedDate {get;set;}
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String paymentMethod {get;set;}
        @AuraEnabled
        public String costCenter {get;set;}
        @AuraEnabled
        public Boolean converttoPaidAccount {get;set;}
        @AuraEnabled
        public String refundRequest {get;set;}
        @AuraEnabled
        public String accountCancellation {get;set;}
        @AuraEnabled
        public String billingAddress {get;set;}
        @AuraEnabled
        public String locationChange {get;set;}
        @AuraEnabled
        public boolean isAvailable {get;set;}
        @AuraEnabled
        public boolean isApprovalTagged {get;set;}
        @AuraEnabled
        public String typeName {get;set;}
        @AuraEnabled
        public String approvalStatus {get;set;}
        @AuraEnabled
        public String comments {get;set;}
        @AuraEnabled
        public boolean fileUpload {get;set;}
    }
}