/**************************************************************************************************
* Project Name..........: Medallia                                                                *
* File..................: MedalliaSurveyHelper.class                                              *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 2/27/2014 11:00 PM                                                      *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 2/27/2014 11:00 PM                                                      *
* Description...........: This is a class to insert Medallia Survey (MS) records for 90 days Old, *
*                         Signature Accounts, CSAT surveys. MS records will be sent to Medallia   *
*                         server,which will send out the surveys to the end users.                *
**************************************************************************************************/
public class MedalliaSurveyHelper{
    //Declaring constant variables
    private static String NEW_CUSTOMER = 'New Customer (after 90 days)'; 
    private static String SUPPORT = 'Support';
    private static String SIGNATURE = 'Signature Accounts';
    private static String PAID = 'Paid'; 
    private static String CUSTOMER = 'Customer';
    private static String SERVICE_TYPE = 'Office';
    private static Integer NO_OF_DLS = 2;
    public static Map<Id,Medallia_Survey__c> medalliaSurveyMap = new Map<Id,Medallia_Survey__c>();
    private static final String BT_CLOUD_PHONE='BT Cloud Phone';

    public static String BT_BUSINESS {
        get {
            if(BT_BUSINESS == null) {
                BT_BUSINESS = !Test.isRunningTest() ? RcDealHealper.getBTBrand() : 'BT Business';
            }
            return BT_BUSINESS;
        }
        set;
    }

    private static Set<String> BRAND_TO_EXCLUDE = new Set<String>{BT_CLOUD_PHONE,BT_BUSINESS};
    
    @TestVisible 
    private static final String INVALID_RECORDTYPE_NAME = 'Invalid record type name';
    
    @TestVisible
    private static List<Medallia_Mapping_Email_to_Case__mdt> MedalliaSurveyEmailMappingMDT { 
        get{ 
            if (MedalliaSurveyEmailMappingMDT == null) { 
                MedalliaSurveyEmailMappingMDT = Medallia_Mapping_Email_to_Case__mdt.getAll().values();
            } 
            return MedalliaSurveyEmailMappingMDT; 
        } 
        set; 
    }

    /************ Method For Creating Medallia Survey Record ON OPPORTUNITY INSERT Starts *************
    * @Description - Create Medallia Survey Record if Amount > $75                                    *
    * @Author      - Simplion Technologies                                                            * 
    **************************************************************************************************/ 
    public static void insertSignatureMedalliaSurvey(List<Opportunity> opptyList){
        try{
            Set<Id> accountIdSet = new set<Id>();
            List<Account> accountList = new List<Account>();
            List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
            Map<Id,AccountContactRole> accountPrimaryContactMap = new Map<Id,AccountContactRole>();
            for(Opportunity opptyObj : opptyList){
                    Account accObj = new Account(Id=opptyObj.AccountId);
                    accountIdSet.add(opptyObj.AccountId);
                    system.debug('#$$$$$$$$$$$$$ '+ opptyObj.AccountId);
            }
            system.debug('#$$$$$$$$$$$$$ '+ accountIdSet);
            //Case - 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - START
            // Add Total_Account_DL_s__c in Query
            accountList = [SELECT Id,Annual_Gross_Revenue__c,name,RC_Account_Number__c,Current_Owner__c,Current_Owner_Manager_Name__c,Current_Owner_Manager_Email__c,Owner.Manager.email,
                                  RC_Account_Status__c,Contact_Email__c,RC_Brand__c,Current_Owner_Name__c,Most_Recent_Opportunity_Manager_Email__c,Owner_Manager_Name__c,Current_Owner_Email__c,
                                  MRR__c,NumberOfEmployees,BillingCountry,Partner_ID__c,Payment_Plan__c,RC_Attribution_Channel__c,Phone,Partner_Account_Name__c,
                                  Most_Recent_Opportunity_Owner_Email__c,Number_of_DL_s__c,RC_Service_name__c,Service_Type__c,RC_Tier__c,RC_User_ID__c,Owner.name,Industry,RC_Signup_Date__c,
                                  Type,RC_Activation_Date__c,Account_Owner_Manager_Name__c,Total_Account_DL_s__c, (SELECT AccountId, Contact.Name,Contact.FirstName,Contact.LastName,isPrimary,Role,Contact.Email,
                                                     Contact.Phone,ContactId FROM AccountContactRoles 
                                              WHERE AccountId IN: accountIdSet AND IsPrimary = true
                                                    ORDER BY LastModifiedDate ASC) FROM Account WHERE Id IN:accountIdSet];                                                    
            //Case - 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - END      
                                                    
            oppContactRoleList = [SELECT Id,ContactId,Contact.FirstName,Contact.LastName,Contact.Email,Contact.Phone,IsPrimary,OpportunityId,Role FROM OpportunityContactRole WHERE (OpportunityId IN:opptyList AND IsPrimary=true)];
            for(Account accObj :accountList) {
                AccountContactRole thisACR = accObj.AccountContactRoles;
                if(thisACR != null){
                    accountPrimaryContactMap.put(accObj.Id,thisACR);    
                }



            }                     

            // Case 04840827 - Medallia Report Update - START
            MedalliaSurveyHelperExt medSurHelpExt = new MedalliaSurveyHelperExt();
            map<Id, List<MedalliaSurveyHelperExt.myUser>> medSurHelpExtUser = new map<Id, List<MedalliaSurveyHelperExt.myUser>>();
            medSurHelpExtUser = medSurHelpExt.MedalliaSurveyHelperProcess(accountIdSet);
            List<MedalliaSurveyHelperExt.myUser> lUser = new List<MedalliaSurveyHelperExt.myUser>();            
            // Case 04840827 - Medallia Report Update - START 

            Map<Id,Account> accountMap = new Map<Id,Account>();
            Map<Id,OpportunityContactRole> oppContRoleMap = new Map<Id,OpportunityContactRole>();
            List<Medallia_Survey__c> medalliaSurveyList = new List<Medallia_Survey__c>();
            for(Account accObj : accountList){
                accountMap.put(accObj.Id,accObj);
            }
            for(OpportunityContactRole oppContRole : oppContactRoleList){
                oppContRoleMap.put(oppContRole.OpportunityId,oppContRole);
            }
            for(Opportunity opptyObj : opptyList){
                if(accountMap!= NULL && accountMap.containsKey(opptyObj.AccountId)){
                    Account acc = accountMap.get(opptyObj.AccountId);
                    if((!String.isBlank(acc.RC_Account_Status__c) && acc.RC_Account_Status__c.equalsIgnoreCase(PAID)) 
                        && (!String.isBlank(acc.RC_Brand__c) && String.valueOf(acc.RC_Brand__c).containsIgnoreCase('RingCentral')) 
                        && String.valueOf(acc.Type).equalsIgnoreCase(CUSTOMER) && acc.Number_of_DL_s__c >= NO_OF_DLS 
                        && (!String.isBlank(acc.Service_Type__c) && acc.Service_Type__c.equalsIgnoreCase(SERVICE_TYPE))){
                        Medallia_Survey__c medalliaSurveyRecord = new Medallia_Survey__c(); 

                        // Case 04840827 - Medallia Report Update - START
                        lUser = medSurHelpExtUser.get(acc.id);
                        if(lUser != null){      
                            medalliaSurveyRecord.CSM_Name__c = (lUser[0].Username != '' || lUser[0].Username != NULL ? lUser[0].Username : '');
                            medalliaSurveyRecord.CSM_Email__c= (lUser[0].UserEmail != '' || lUser[0].UserEmail != NULL ? lUser[0].UserEmail : '');                            
                            medalliaSurveyRecord.CSM_Manager_Name__c= (lUser.size()>1 ? lUser[1].Username != '' || lUser[1].Username != NULL ? lUser[1].Username : '': '');
                            medalliaSurveyRecord.CSM_Manager_Email__c = (lUser.size()>1 ? lUser[1].UserEmail != '' || lUser[1].UserEmail != NULL ? lUser[1].UserEmail: '': '');
                        }
                        // Case 04840827 - Medallia Report Update - END
 
                        medalliaSurveyRecord.Account_AnnualRevenue__c = acc.Annual_Gross_Revenue__c;// confusion
                        medalliaSurveyRecord.Account__c = acc.Id;
                        medalliaSurveyRecord.Account_SFDC_ID__c = acc.Id;
                        medalliaSurveyRecord.Account_Name__c = acc.name;
                        medalliaSurveyRecord.Account_Number__c = acc.RC_Account_Number__c;// confusion with standard AccountNumber Field
                        medalliaSurveyRecord.Account_Owner__c = acc.Owner.name;// 
                        medalliaSurveyRecord.Account_Owner_Manager__c = acc.Account_Owner_Manager_Name__c;
                        medalliaSurveyRecord.Account_Owner_Manager_Email__c = acc.Owner.Manager.email;
                        medalliaSurveyRecord.Account_Status__c = acc.RC_Account_Status__c;
                        medalliaSurveyRecord.Account_Brand__c = acc.RC_Brand__c;
                        medalliaSurveyRecord.Account_Current_Owner__c = acc.Current_Owner_Name__c; 
                        medalliaSurveyRecord.Account_Current_Owner_Email__c = acc.Current_Owner_Email__c; 
                        medalliaSurveyRecord.Account_Current_Owner_Manager_Email__c = acc.current_Owner_Manager_Email__c;
                        medalliaSurveyRecord.Account_Recent_Opportunity_Manager_Email__c = acc.Most_Recent_Opportunity_Manager_Email__c;
                        medalliaSurveyRecord.Account_Recent_Opportunity_Owner_Email__c = acc.Most_Recent_Opportunity_Owner_Email__c;
                        
                        // Case 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - START
                        //medalliaSurveyRecord.Account_Number_of_DL_s__c = String.valueOf(acc.Number_of_DL_s__c); 
                        medalliaSurveyRecord.Account_Number_of_DL_s__c = acc.Total_Account_DL_s__c != null ? String.valueOf(acc.Total_Account_DL_s__c) : '';
                        // Case 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - END
                        
                        medalliaSurveyRecord.Account_Service_name__c = acc.RC_Service_name__c;
                        medalliaSurveyRecord.Account_Service_Type__c = acc.Service_Type__c;
                        medalliaSurveyRecord.Account_Tier__c = acc.RC_Tier__c; 
                        medalliaSurveyRecord.Account_User_Id__c = acc.RC_User_ID__c;
                        if(oppContRoleMap!= NULL && oppContRoleMap.containsKey(opptyObj.Id) && oppContRoleMap.get(opptyObj.Id).contactId != null){
                            medalliaSurveyRecord.Sales_Contact_ID__c = oppContRoleMap.get(opptyObj.Id).contactId;
                            medalliaSurveyRecord.Sales_Role__c = oppContRoleMap.get(opptyObj.Id).Role;
                            medalliaSurveyRecord.Sales_FirstName__c = oppContRoleMap.get(opptyObj.Id).Contact.FirstName;
                            medalliaSurveyRecord.Sales_LastName__c = oppContRoleMap.get(opptyObj.Id).Contact.LastName;
                            medalliaSurveyRecord.Sales_isPrimary__c = oppContRoleMap.get(opptyObj.Id).IsPrimary;
                            medalliaSurveyRecord.Sales_Email__c = oppContRoleMap.get(opptyObj.Id).Contact.Email;
                            medalliaSurveyRecord.Sales_Phone__c = oppContRoleMap.get(opptyObj.Id).Contact.Phone;    
                        } else if(accountPrimaryContactMap != null && opptyObj.AccountId != null 
                            && accountPrimaryContactMap.get(opptyObj.AccountId) != null) {
                            AccountContactRole accContactRoleObj = accountPrimaryContactMap.get(opptyObj.AccountId);
                            medalliaSurveyRecord.Sales_Contact_ID__c = accContactRoleObj.contactId;
                            medalliaSurveyRecord.Sales_Role__c = accContactRoleObj.Role;
                            medalliaSurveyRecord.Sales_FirstName__c = accContactRoleObj.Contact.FirstName;
                            medalliaSurveyRecord.Sales_LastName__c = accContactRoleObj.Contact.LastName;
                            medalliaSurveyRecord.Sales_isPrimary__c = accContactRoleObj.IsPrimary;
                            medalliaSurveyRecord.Sales_Email__c = accContactRoleObj.Contact.Email;
                            medalliaSurveyRecord.Sales_Phone__c = accContactRoleObj.Contact.Phone;  
                        }
                        medalliaSurveyRecord.Account_Industry__c = acc.Industry;
                        medalliaSurveyRecord.Account_Signup_Date__c = acc.RC_Signup_Date__c;
                        medalliaSurveyRecord.Account_Activation_Date__c = acc.RC_Activation_Date__c;
                        medalliaSurveyRecord.Account_MRR__c = acc.MRR__c;
                        medalliaSurveyRecord.Account_Number_of_Employees__c = String.valueOf(acc.NumberOfEmployees);
                        medalliaSurveyRecord.Account_Billing_Country__c = acc.BillingCountry;
                        medalliaSurveyRecord.Account_Partner_ID__c = acc.Partner_ID__c;
                        medalliaSurveyRecord.Account_Payment_Plan__c = acc.Payment_Plan__c;
                        medalliaSurveyRecord.Account_Attribution_Channel__c = acc.RC_Attribution_Channel__c;
                        medalliaSurveyRecord.Account_Phone__c = acc.Phone;
                        medalliaSurveyRecord.Account_Partner_Name__c = acc.Partner_Account_Name__c;
                        medalliaSurveyRecord.Opportunity_Amount__c = opptyObj.Amount;
                        medalliaSurveyRecord.SurveyType__c = SIGNATURE;
                        
                        medalliaSurveyRecord.Opportunity_SFDC_ID__c = opptyObj.Id;
                        medalliaSurveyRecord.Account_Type__c = acc.Type;
                        
                        medalliaSurveyList.add(medalliaSurveyRecord);
                    }
                }
            }
            if(!medalliaSurveyList.isEmpty()){
                Database.SaveResult[] srList = Database.insert(medalliaSurveyList, false);
                for(Medallia_Survey__c ms : medalliaSurveyList){
                    medalliaSurveyMap.put(ms.Id,ms);
                    System.debug('@@@@@ '+medalliaSurveyMap);
                }
                sendEmailForErrors(srList,SIGNATURE);   
            }
        }catch(Exception e){
            system.debug('Exception Occured : '+ e.getMessage());
        }
    
    }
    
    /*********************************** Code For Creating Signature Account Medallia Survey Record Ends***********************************/
    
    
    /*********************************** Method For Creating Medallia Survey Record ON CSAT- Starts here*************************************
    * @Description - Create Medallia Survey Record for CSAT                                                                                 *
    * @Author      - Simplion Technologies                                                                                                  * 
    ****************************************************************************************************************************************/    
    public static void insertSupportMedalliaSurvey(List<Case> caseList,Map<ID,Schema.RecordTypeInfo> rtMapByName){
        try{
            Set<Id> accountIdSet = new set<Id>();
            Set<Id> userIdSet = new set<Id>();
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            List<Account> accountList = new List<Account>();
            
            // Map of Account,Primary Contact Details
            Map<Id,AccountContactRole> accountPrimaryContactMap = new Map<Id,AccountContactRole>(); 
            Set<Id> contactIds = new Set<Id>();
            for(Case caseObj : caseList){
                if(caseObj.ContactId != null) {
                    contactIds.add(caseObj.ContactId);
                    userIdSet.add(caseObj.OwnerId);
                    userIdSet.add(caseObj.createdById);
                }
            }
            Map<Id,User> userMap = new Map<Id,User>([SELECT id,name,email FROM User WHERE Id IN:userIdSet]);
            if(contactIds.size() != 0) {
                
                //Case - 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - START
                // Add Total_Account_DL_s__c in Query
                contactMap = new Map<Id,Contact> ([SELECT Id, Phone, FirstName, LastName, Email, Name, AccountId, Account.Id, Account.Annual_Gross_Revenue__c,Account.Name,
                                            Account.RC_Account_Number__c,Account.Current_Owner__c,Account.Current_Owner_Manager_Name__c,
                                            Account.Current_Owner_Manager_Email__c, Account.Owner.Manager.email, Account.RC_Account_Status__c,Account.Contact_Email__c,Account.RC_Brand__c,
                                            Account.Current_Owner_Name__c,Account.Most_Recent_Opportunity_Manager_Email__c,Account.Owner_Manager_Name__c,
                                            Account.Current_Owner_Email__c,Account.MRR__c, Account.NumberOfEmployees,
                                            Account.BillingCountry, Account.Partner_ID__c, Account.Payment_Plan__c,Account.RC_Attribution_Channel__c,Account.Phone,
                                            Account.Partner_Account_Name__c, Account.Most_Recent_Opportunity_Owner_Email__c,Account.Number_of_DL_s__c,Account.RC_Service_name__c,
                                            Account.Service_Type__c,Account.RC_Tier__c,Account.RC_User_ID__c,Account.Owner.Name,Account.Industry,
                                            Account.RC_Signup_Date__c, Account.RC_Activation_Date__c,Account.Account_Owner_Manager_Name__c, Account.Type, 
                                            Account.Total_Account_DL_s__c
                                            FROM Contact WHERE Id IN:contactIds AND AccountId != NULL]);
                //Case - 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - END
            }
            for(Id contactId : contactMap.keySet()) {
                accountIdSet.add(contactMap.get(contactId).AccountId);
            }
            
            List<Medallia_Survey__c> medalliaSurveyList = new List<Medallia_Survey__c>();
            // Creating Map of Account,Primary Contact Details.
            for(AccountContactRole thisACR : [SELECT AccountId, Contact.Name,Contact.FirstName,Contact.LastName,isPrimary,Role,Contact.Email,
                                                Contact.Phone,ContactId FROM AccountContactRole WHERE ContactId IN: contactIds AND AccountId IN: accountIdSet AND IsPrimary = true
                                                ORDER BY LastModifiedDate ASC]){
                accountPrimaryContactMap.put(thisACR.ContactId,thisACR);    
            }

            // Case 04840827 - Medallia Report Update - START
            MedalliaSurveyHelperExt medSurHelpExt = new MedalliaSurveyHelperExt();
            map<Id, List<MedalliaSurveyHelperExt.myUser>> medSurHelpExtUser = new map<Id, List<MedalliaSurveyHelperExt.myUser>>();
            medSurHelpExtUser = medSurHelpExt.MedalliaSurveyHelperProcess(accountIdSet);
            List<MedalliaSurveyHelperExt.myUser> lUser = new List<MedalliaSurveyHelperExt.myUser>();            
            // Case 04840827 - Medallia Report Update - START

            for(Case caseObj : caseList){
                if(caseObj.ContactId != null && contactMap.get(caseObj.ContactId) != null){
                    Contact contactObj = contactMap.get(caseObj.ContactId);
                    //if(!BRAND_TO_EXCLUDE.contains(contactObj.Account.RC_Brand__c)){
                        // Account acc = accountMap.get(caseObj.AccountId);
                        /************************** ACCOUNT FIELDS MAPPING *****************************/
                        Medallia_Survey__c medalliaSurveyRecord = new Medallia_Survey__c(); 

                        // Case 04840827 - Medallia Report Update - START
                        lUser = medSurHelpExtUser.get(contactObj.Account.id);
                        if(lUser != null){      
                            medalliaSurveyRecord.CSM_Name__c = (lUser.size()>0 ? lUser[0].Username != '' || lUser[0].Username != NULL ? lUser[0].Username : '': '');
                            medalliaSurveyRecord.CSM_Email__c= (lUser.size()>0 ? lUser[0].UserEmail != '' || lUser[0].UserEmail != NULL ? lUser[0].UserEmail : '': '');                            
                            medalliaSurveyRecord.CSM_Manager_Name__c = (lUser.size()>1 ? lUser[1].Username != '' || lUser[1].Username != NULL ? lUser[1].Username : '': '');
                            medalliaSurveyRecord.CSM_Manager_Email__c = (lUser.size()>1 ? lUser[1].UserEmail != '' || lUser[1].UserEmail != NULL ? lUser[1].UserEmail: '': '');
                        }
                        // Case 04840827 - Medallia Report Update - END

                        medalliaSurveyRecord.Account_Type__c = contactObj.Account.Type;
                        medalliaSurveyRecord.Account_AnnualRevenue__c = contactObj.Account.Annual_Gross_Revenue__c;// confusion
                        medalliaSurveyRecord.Account__c = contactObj.Account.Id;
                        medalliaSurveyRecord.Account_SFDC_ID__c = contactObj.Account.Id;
                        medalliaSurveyRecord.Account_Name__c = contactObj.Account.name;
                        medalliaSurveyRecord.Account_Number__c = contactObj.Account.RC_Account_Number__c;// confusion with standard AccountNumber Field
                        medalliaSurveyRecord.Account_Owner__c = contactObj.Account.Owner.name;// 
                        medalliaSurveyRecord.Account_Owner_Manager__c = contactObj.Account.Account_Owner_Manager_Name__c;
                        medalliaSurveyRecord.Account_Owner_Manager_Email__c = contactObj.Account.Owner.Manager.email;
                        medalliaSurveyRecord.Account_Status__c = contactObj.Account.RC_Account_Status__c;
                        medalliaSurveyRecord.Account_Brand__c = contactObj.Account.RC_Brand__c;
                        medalliaSurveyRecord.Account_Current_Owner__c = contactObj.Account.Current_Owner_Name__c; 
                        medalliaSurveyRecord.Account_Current_Owner_Email__c = contactObj.Account.Current_Owner_Email__c; 
                        medalliaSurveyRecord.Account_Current_Owner_Manager_Email__c = contactObj.Account.current_Owner_Manager_Email__c;
                        medalliaSurveyRecord.Account_Recent_Opportunity_Manager_Email__c = contactObj.Account.Most_Recent_Opportunity_Manager_Email__c;
                        medalliaSurveyRecord.Account_Recent_Opportunity_Owner_Email__c = contactObj.Account.Most_Recent_Opportunity_Owner_Email__c;
                        
                        // Case 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - START
                        //medalliaSurveyRecord.Account_Number_of_DL_s__c = String.valueOf(contactObj.Account.Number_of_DL_s__c); 
                        medalliaSurveyRecord.Account_Number_of_DL_s__c = contactObj.Account.Total_Account_DL_s__c != null ? String.valueOf(contactObj.Account.Total_Account_DL_s__c) : '';
                        // Case 04961431 -Total DLs not being used in Medallia Support feed from SF to Medallia - END
                        
                        medalliaSurveyRecord.Account_Service_name__c = contactObj.Account.RC_Service_name__c;
                        medalliaSurveyRecord.Account_Service_Type__c = contactObj.Account.Service_Type__c;
                        medalliaSurveyRecord.Account_Tier__c = contactObj.Account.RC_Tier__c; 
                        medalliaSurveyRecord.Account_User_Id__c = contactObj.Account.RC_User_ID__c;
                        medalliaSurveyRecord.Account_Industry__c = contactObj.Account.Industry;
                        medalliaSurveyRecord.Account_Signup_Date__c = contactObj.Account.RC_Signup_Date__c;
                        medalliaSurveyRecord.Account_Activation_Date__c = contactObj.Account.RC_Activation_Date__c;
                        medalliaSurveyRecord.Account_MRR__c = contactObj.Account.MRR__c;
                        medalliaSurveyRecord.Account_Number_of_Employees__c = String.valueOf(contactObj.Account.NumberOfEmployees);
                        medalliaSurveyRecord.Account_Billing_Country__c = contactObj.Account.BillingCountry;
                        medalliaSurveyRecord.Account_Partner_ID__c = contactObj.Account.Partner_ID__c;
                        medalliaSurveyRecord.Account_Payment_Plan__c = contactObj.Account.Payment_Plan__c;
                        medalliaSurveyRecord.Account_Attribution_Channel__c = contactObj.Account.RC_Attribution_Channel__c;
                        medalliaSurveyRecord.Account_Phone__c = contactObj.Account.Phone;
                        medalliaSurveyRecord.Account_Partner_Name__c = contactObj.Account.Partner_Account_Name__c;
                        /************************************ ACCOUNT FIELD MAPPING ENDS ***********************************/
                        /************************************ CASE FIELDS MAPPING BEGINS *******************************************/
                        medalliaSurveyRecord.Case_Number__c = caseObj.CaseNumber;
                        medalliaSurveyRecord.Case_SFDC_ID__c = caseObj.id;
                        medalliaSurveyRecord.Case_Owner_Email__c = ((userMap != null && userMap.containsKey(caseObj.OwnerId) && userMap.get(caseObj.OwnerId)!= NULL)? userMap.get(caseObj.OwnerId).email : 'noEmailFound@owner.name');
                        medalliaSurveyRecord.Case_Owner__c = ((userMap != null && userMap.containsKey(caseObj.OwnerId) && userMap.get(caseObj.OwnerId)!= NULL)? userMap.get(caseObj.OwnerId).name : '');
                        //medalliaSurveyRecord.Case_Owner_Manager_Email__c = caseObj.Owner_Manager_Email__c;
                        // Field mapping update as per Xander's mail on 8th April 2014
                        medalliaSurveyRecord.Case_Owner_Manager_Email__c = caseObj.Case_Owner_Manager_Email__c;
                        medalliaSurveyRecord.Case_RecordType__c = (rtMapByName.get( caseObj.RecordTypeId ) != NULL ?rtMapByName.get( caseObj.RecordTypeId ).getName():'');
                        medalliaSurveyRecord.Case_Priority__c = caseObj.Priority;
                        medalliaSurveyRecord.Case_Origin__c = caseObj.Origin;
                        medalliaSurveyRecord.Case_IsVisibleInSelfService__c = caseObj.IsVisibleInSelfService;
                        medalliaSurveyRecord.Case_Subject__c = caseObj.Subject;
                        medalliaSurveyRecord.Case_CreatedDate__c = caseObj.CreatedDate;
                        medalliaSurveyRecord.Case_ClosedDate__c = System.now();
                        medalliaSurveyRecord.Case_Time_Since_Opened__c = String.valueOf(caseObj.Time_Since_Case_Opened__c);
                        medalliaSurveyRecord.Case_CreatedBy__c = ((userMap != null && userMap.containsKey(caseObj.CreatedById) && userMap.get(caseObj.CreatedById)!= NULL)? userMap.get(caseObj.CreatedById).name : '');
                        medalliaSurveyRecord.Case_Owner_Manager__c = caseObj.Owner_Manager__c;
                        medalliaSurveyRecord.Case_Status__c = caseObj.Status;
                        medalliaSurveyRecord.Case_Owner_Location__c = caseObj.Case_Owner_Location__c;
                        medalliaSurveyRecord.Case_Support_Disposition_Level_1__c = caseObj.Support_Disposition_Level_1__c;
                        medalliaSurveyRecord.Case_Support_Disposition_Level_2__c = caseObj.Support_Disposition_Level_2__c;
                        medalliaSurveyRecord.Case_Support_Disposition_Level_3__c = caseObj.Support_Disposition_Level_3__c;
                        medalliaSurveyRecord.Case_Support_Disposition_Level_4__c = caseObj.Support_Disposition_Level_4__c;
                        medalliaSurveyRecord.Case_Support_Disposition_Level_5__c = caseObj.Support_Disposition_Level_5__c;
                        medalliaSurveyRecord.Case_Description__c = caseObj.Description;
                        medalliaSurveyRecord.Case_Product_Assistance__c = caseObj.Product_Assistance__c;
                        // New Field added as per Xander's Request, mail dated 7th May 2014.
                        medalliaSurveyRecord.Case_Call_Category__c = caseObj.Call_Category__c; 
                        medalliaSurveyRecord.SurveyType__c = SUPPORT;
                        medalliaSurveyRecord.Case_Chat_Origin__c = caseObj.Chat_Origin__c;

                        // Case 05227461 - START
                        medalliaSurveyRecord.Imp_Express__c = caseObj.Imp_Express__c; 
                        // Case 05227461 - END

                        //Case 07169582
                        medalliaSurveyRecord.Case_OpenCustomerSupportLevel1__c = caseObj.OpenCustomerSupportLevel1__c;
                        medalliaSurveyRecord.Case_OpenCustomerSupportLevel2__c = caseObj.OpenCustomerSupportLevel2__c;
                        medalliaSurveyRecord.Case_OpenCustomerSupportLevel3__c = caseObj.OpenCustomerSupportLevel3__c;
                        medalliaSurveyRecord.Case_CloseCustomerSupportLevel1__c = caseObj.CloseCustomerSupportLevel1__c;
                        medalliaSurveyRecord.Case_CloseCustomerSupportLevel2__c = caseObj.CloseCustomerSupportLevel2__c;
                        medalliaSurveyRecord.Case_CloseCustomerSupportLevel3__c = caseObj.CloseCustomerSupportLevel3__c;
                        //~Case 07169582
                        
                        /************************************ CASE FIELDS MAPPING ENDS **********************************************/
                        // Mapping Primary Contact fields.
                        
                        medalliaSurveyRecord.Support_Contact_ID__c = contactObj.Id;
                        medalliaSurveyRecord.Support_Email__c = contactObj.Email;
                        medalliaSurveyRecord.Support_FirstName__c = contactObj.FirstName;
                        medalliaSurveyRecord.Support_LastName__c = contactObj.LastName;
                        medalliaSurveyRecord.Support_Phone__c = contactObj.Phone;
                        
                        if(!accountPrimaryContactMap.isEmpty() && accountPrimaryContactMap.get(caseObj.ContactId) != null ){
                            medalliaSurveyRecord.Support_Role__c = accountPrimaryContactMap.get(caseObj.ContactId).Role;
                            medalliaSurveyRecord.Support_isPrimary__c = accountPrimaryContactMap.get(caseObj.ContactId).isPrimary;
                        }
                        medalliaSurveyList.add(medalliaSurveyRecord);
                    //}
                }
            }
            if(!medalliaSurveyList.isEmpty()){
                Database.SaveResult[] srList = Database.insert(medalliaSurveyList, false);
                for(Medallia_Survey__c ms : medalliaSurveyList){
                        medalliaSurveyMap.put(ms.Id,ms);
                        System.debug('@@@@@ '+medalliaSurveyMap);
                }
                sendEmailForErrors(srList,'Support');   
            }
        }catch(Exception e){
            System.debug('Exception Occured : '+ e.getMessage());
        }
    
    }
    /*********************************** Code For Creating Signature Account Medallia Survey Record Ends***********************************/

    /*********************** METHOD TO SEND EMAIL REGARDING FAILED RECORD IN MEDALLIA SURVEY OBJECT- Starts *********************************
    * @Description - Send email regarding failed records in Medallia                                                                        *
    * @Author      - Simplion Technologies                                                                                                  * 
    ****************************************************************************************************************************************/      
    public static void sendEmailForErrors(List<Database.Saveresult> srList, String surveyType) {

        Map<Id, Database.Error[]> recordIdToErrors = new Map<Id, Database.Error[]>();
        for (Database.SaveResult saveResult : srList) {
            if (!saveResult.isSuccess()) {
                recordIdToErrors.put(saveResult.getId(), saveResult.getErrors());
            }
        }

        if (!recordIdToErrors.isEmpty()) {
            sendEmailForErrors(recordIdToErrors, surveyType);
        }
    }
    
    public static void sendEmailForErrors(List<Database.UpsertResult> srList, String surveyType) {
        Map<Id, Database.Error[]> recordIdToErrors = new Map<Id, Database.Error[]>();
        for (Database.UpsertResult upsertResult : srList) {
            if (!upsertResult.isSuccess()) {
                recordIdToErrors.put(upsertResult.getId(), upsertResult.getErrors());
            }
        }

        if (!recordIdToErrors.isEmpty()) {
            sendEmailForErrors(recordIdToErrors, surveyType);
        }
    }

    public static void sendEmailForErrors(Map<Id, Database.Error[]> recordIdToDbErrors, String surveyType) {
        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
        emailToSend.setSubject('Medallia Survey Insertion Status');
        
        String[] medalliaErrorMailboxes = getMedalliaErrorMailboxes();
        if (medalliaErrorMailboxes == null) {
            PlatformLog.logResult(MedalliaSurveyHelper.class.getName(), 'Could not find email addresses to send emails',
                'MedalliaSurveyHelper.sendEmailForErrors', null, null, false);
            return;
        }
        emailToSend.setToAddresses(medalliaErrorMailboxes);

        String header = 'Medallia Survey insertion failed for ' + surveyType;
        if (surveyType.equalsIgnoreCase(SUPPORT) || surveyType.equalsIgnoreCase(SIGNATURE) || surveyType.equalsIgnoreCase(NEW_CUSTOMER)) {
            header +=' for Account ';
        } 

        String emailBody = '';
        for (Id recordId : recordIdToDbErrors.keySet()) {
            emailBody += header;
            if (medalliaSurveyMap != null && medalliaSurveyMap.get(recordId) != null) {
                emailBody += medalliaSurveyMap.get(recordId).Account_SFDC_ID__c;
            }
            emailBody += ' Reason for Error - ' + recordIdToDbErrors.get(recordId) + '\r\n\r\n';
        }

        emailToSend.setPlainTextBody(emailBody);
        
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { emailToSend });
        } catch (Exception ex) {
            PlatformLog.logException(MedalliaSurveyHelper.class.getName(), ex);
        }
    }

    private static String[] getMedalliaErrorMailboxes() {
        List<String> result = null;

        Emails__c emailAddresses = Emails__c.getInstance('MedalliaSurveysErrors');
        if (emailAddresses != null && !String.isBlank(emailAddresses.Email_Address__c)) {
            result = emailAddresses.Email_Address__c.split(',');
        }

        return result;
    }
    
    /**********************METHOD TO SEND EMAIL REGARDING FAILED RECORD IN MEDALLIA SURVEY OBJECT- Ends *****************************/
    
    /**************************** MEDALLIA REFINED CONDITIONS Methods End *******************************/
    
    /******************************************************************************
    * @Description : Method to execute the 90days for batch.                      *
    * @Params      : void                                                         *
    * @Return      : void                                                         * 
    ******************************************************************************/
    public void call90DaysBatch() {
        MedalliaActiveAccountsBatch obj = new MedalliaActiveAccountsBatch();
        Database.executeBatch(obj, 10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '90 days Account survey batch has just started.'));
    }
    
    /******************************************************************************
    * @Description : Method to execute the survey retrieve for batch.             *
    * @Params      : void                                                         *
    * @Return      : void                                                         * 
    ******************************************************************************/
    public void medalliaSurveyRetrieveBatch() {
        MedalliaFetchSurveyBatch obj = new MedalliaFetchSurveyBatch();
        Database.executeBatch(obj, 10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Survey fetch batch has just started.'));
    }

    //CR-86101 New Medallia Process
    public static void sendMedalliaInvitation(List<Case> caseRecords, List<Account> accRecords){
        if(!ByPassTrigger__c.getInstance().Bypass_Medallia_Invitation_Trigger__c){
            List<String> excludedBrands=Label.BizMerge_Brand_Exclusion_List.length()>0?Label.BizMerge_Brand_Exclusion_List.split(','):new List<String>(); //Added as a part of BizMerge Project
            List<Medallia_Invitation__mdt> medCaseList = new List<Medallia_Invitation__mdt>();
            List<Medallia_Invitation__mdt> medAccList = new List<Medallia_Invitation__mdt>();
            Map<Id, Medallia_Invitation__mdt> invitationMap = new Map<Id, Medallia_Invitation__mdt>();
            List<Medallia_Invitation__mdt> medList = [SELECT Active__c, MasterLabel, DeveloperName, Object__c, Recordtype__c, Send_Invite__c, Service__c, Status__c,
                                                      Months__c, Case_Origin__c, FieldSet__c, Case_Call_Outcome__c, Exclude_RC_Brand__c
                                                      FROM Medallia_Invitation__mdt WHERE Active__c = true];
            system.debug('medList SIZE: ' + medList.size());
            if (medList.size() > 0){
                for(Medallia_Invitation__mdt med : medList){
                    if(med.Object__c == 'Case'){
                        medCaseList.add(med);
                    }
                    else if(med.Object__c == 'Account'){
                        medAccList.add(med);
                    }
                }
                system.debug('caseRecords: ' + caseRecords);
                system.debug('accRecords: ' + accRecords);
                if ((caseRecords.size() > 0 || caseRecords != null) && medCaseList.size() > 0){
                    for (Case c : caseRecords){
                        if(!(excludedBrands.contains(c.Brand_Account__c))){ //Added as a part of BizMerge Project
                       for (Medallia_Invitation__mdt m : medCaseList){
                            List<String> statusList = m.Status__c != null ? m.Status__c.split(',') : new List<String>();
                            List<String> originList = m.Case_Origin__c != null ? m.Case_Origin__c.split(',') : new List<String>();
                            List<String> rectypeList = m.Recordtype__c != null ? m.Recordtype__c.split(',') : new List<String>();
                            List<String> calloutcome = m.Case_Call_Outcome__c != null ? m.Case_Call_Outcome__c.split(',') : new List<String>();
                            List<String> churnexcludedbrands = m.Exclude_RC_Brand__c != null ? m.Exclude_RC_Brand__c.split(',') : new List<String>();
                            if(rectypeList.contains(c.RecordTypeName__c) && 
                            ((m.DeveloperName == 'Churn_Survey' && calloutcome.contains(c.Call_Outcome__c) && statusList.contains(c.Status) && (!churnexcludedbrands.contains(c.Brand_Account__c)))
                            || (m.DeveloperName == 'Status_Update' && statusList.contains(c.Status))
                                || (m.DeveloperName == 'Support_Survey' && statusList.contains(c.Status))
                               )){
                                   invitationMap.put(c.Id , m);
                               }
                        }
                        }
                    }
                }
                if((accRecords.size() > 0 || accRecords != null) && medAccList.size() > 0){
                    for (Account a : accRecords){
                        if(!(excludedBrands.contains(a.RC_Brand__c))){ //Added as a part of BizMerge Project
                        for (Medallia_Invitation__mdt m : medAccList){
                            List<String> statusList = m.Status__c != null ? m.Status__c.split(',') : new List<String>();
                            List<String> churnexcludedbrands = m.Exclude_RC_Brand__c != null ? m.Exclude_RC_Brand__c.split(',') : new List<String>();
                                if(statusList.contains(a.RC_Account_Status__c) && (!churnexcludedbrands.contains(a.RC_Brand__c))){
                                invitationMap.put(a.Id , m);
                            }
                        }
                        }
                    }
                }
                processMedalliaInvitation(invitationMap,null);
            }
        }
    }
    
    public static void processMedalliaInvitation(Map<Id, Medallia_Invitation__mdt> invitationMap, Map<Id, Datetime> dateToSendMap){
        if (invitationMap != null || !invitationMap.isEmpty()){
            List<medallia_xm.QueueItemPayload> payloads = new List<medallia_xm.QueueItemPayload>();
            for (Id inv : invitationMap.keyset()){
                medallia_xm.QueueItemPayload payload = new medallia_xm.QueueItemPayload();
                payload.fieldSet = invitationMap.get(inv).FieldSet__c;
                payload.recordId = inv;
                payload.service = invitationMap.get(inv).Service__c;
                if(invitationMap.get(inv).Months__c != null && dateToSendMap != null && dateToSendMap.get(inv) != null){
                    Integer months = integer.valueOf(invitationMap.get(inv).Months__c);
                    Datetime dateToSend = dateToSendMap.get(inv); // .addMonths(months);
                    payload.whenToSend = dateToSend;
                }

                else{
                    payload.whenToSend = Datetime.Now();
                }
                //payload.medProgramId = 'Replace with Program Id or Medallia Spec
                payload.sendInvite = invitationMap.get(inv).Send_Invite__c;
                payloads.add(payload);
            }
            if (payloads.size() > 0){
                medallia_xm.MedGenericProcess.Process(payloads);
            }
        }
    }

    @InvocableMethod(label='Send Invitation for Support Survey' description='Send medallia ivitation to the orphan cases that are created from NTD Helpdesk E2C')
    
    Public static void supportSurveyForOrphanCases(List<Id> caseIds){
        List<medallia_xm.QueueItemPayload> payloads = new List<medallia_xm.QueueItemPayload>();
        List<EmailMessage> emList = [SELECT Id, ToAddress, CreatedDate,ParentId, Parent.SuppliedEmail FROM EmailMessage WHERE ParentId IN :caseIds AND ToAddress = :Label.Porting_Phone_Helpdesk_Email LIMIT 50000];
        List<Id> CaseIdList = new List<Id>();
        if((!emList.isempty()) && (emList != null)){
            for(EmailMessage e : emList){
            if((!CaseIdList.contains(e.ParentId)) && (e.Parent.SuppliedEmail != null)){
                medallia_xm.QueueItemPayload payload = new medallia_xm.QueueItemPayload();
                if(System.Label.Support_Survey_Service!=null) {
                payload.service = System.Label.Support_Survey_Service;
                }
                if(System.Label.Support_Survey_Fieldset!=null){
                    payload.fieldSet = System.Label.Support_Survey_Fieldset;
                }
                payload.whenToSend = Datetime.Now();
                payload.recordId = e.ParentId;
                payload.sendInvite = true;
                payload.sendInviteToRole = e.Parent.SuppliedEmail;
                payloads.add(payload);
                CaseIdList.add(e.ParentId);
            }
        }
        }
        if (payloads.size() > 0){
            medallia_xm.MedGenericProcess.Process(payloads);
        }
    }

    public static Map<String, Medallia_Mapping_Email_to_Case__mdt> getMedalliaSurveyEmailMappingToCase(String recordTypeName) {
        Map<String, Medallia_Mapping_Email_to_Case__mdt> medalliaSurveyEmailMapping = new Map<String, Medallia_Mapping_Email_to_Case__mdt>();
        Boolean isValidValue = false;

        for (PicklistEntry picklist : SFDescribeHelper.getOptions('Medallia_Mapping_Email_to_Case__mdt', 'Record_Type__c')) {
            if (picklist.isActive() && picklist.value.equalsIgnoreCase(recordTypeName)) {
                isValidValue = true;
                break;
            }
        }

        if (!isValidValue) {
            throw new HandledException(INVALID_RECORDTYPE_NAME);
        }

        for (Medallia_Mapping_Email_to_Case__mdt medalliaMapping : MedalliaSurveyEmailMappingMDT) {
            if (medalliaMapping.Record_Type__c.equalsIgnoreCase(recordTypeName)) {
                medalliaSurveyEmailMapping.put(medalliaMapping.Key_tag_in_Email__c, medalliaMapping);
            }
        }

        return medalliaSurveyEmailMapping;
    }
}