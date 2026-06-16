public class PartnerAccountContactConvertBatch implements Database.Batchable<sObject>{
    public final String Query;  
    public List<String> brandNames = new List<String>(); 
    
    public PartnerAccountContactConvertBatch(){
    
	Query = 'Select AD__c,AFN__c,AID__c,Annual_Gross_Revenue__c,Avaya_External_ID__c,Avaya_Partnership_Reg__c,Avg_No_Employees_Per_Location__c,Brand_Name__c,BusinessIdentity__c,Business_Description__c,Business_Industry__c,Certifications_Other__c,Certifications__c,Closest_Metro_Area__c,Company_size_typically_sell_to__c,ConnectionReceivedId,ConnectionSentId,CreatedById,CreatedDate,CurrencyIsoCode,Current_Telephone_System_Solution_s__c,Customer_ready_to_place_an_order_now__c,Description_of_Your_Business_Other__c,Direct_Partner__c,DSR_USER__c,External_SID__c,FoundDuplicateAccountIds__c,Franchise_Avg_Employee_Per_Location__c,How_did_you_hear_about_the_RC_Part_Prog__c,How_d_you_like_us_to_follow_up_with_you__c,Id,Invoice_Copy_Partner_ID__c,Invoicing_Partner_ID__c,IsDeleted,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Master_Agent_Channel_Manager__c,Master_Partner_Contact__c,Name,Notes__c,No_Franchise_Locations__c,No_of_Employees__c,Original_Partner_Phone__c,OwnerId,Partner_Additional_Information__c,Partner_Address1__c,Partner_Address2__c,Partner_Average_Customer_Size__c,Partner_Best_Contact_Time__c,Partner_Cisco_Reseller__c,Partner_City__c,Partner_Classification__c,Partner_Company_Name__c,Partner_Country__c,Partner_Currently_Resell_Other__c,Partner_Currently_resell__c,Partner_Description_of_Your_Business__c,Partner_Email_Address_Accounts_Payable__c,Partner_Email_Address_Billing_Support__c,Partner_Email_Address__c,Partner_First_Name_Accounts_Payable__c,Partner_First_Name_Billing_Support__c,Partner_First_Name__c,Partner_ID__c,Partner_Job_Function__c,Partner_Last_Name_Accounts_Payable__c,Partner_Last_Name_Billing_Support__c,Partner_Last_Name__c,Partner_Mobile__c,Partner_Phone_Accounts_Payable__c,Partner_Phone_Billing_Support__c,Partner_Phone__c,Partner_Portal_View__c,Partner_Release_Date__c,Partner_Request_Source__c,Partner_Role__c,Partner_State__c,Partner_Title__c,Partner_Type__c,Partner_Website__c,Partner_Zip__c,PR_Processed__c,Ready_For_Processing__c,Reseller_Partner_Type__c,Sales_Model__c,Software_Classification_Category__c,SystemModstamp,Technical_Certification__c,Type_of_Integration_or_App__c,Which_verticals_do_you_sell_to_most__c FROM   Partner_Request__c where Ready_For_Processing__c = true and Brand_Name__c= \'RingCentral\' and PR_Processed__c=false' ; 
       }
       
        public Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('PartnerAccountContactConvert query from start --> ' + Query);
        return Database.getQueryLocator(Query);
    }
    public void execute(Database.BatchableContext BC, List<sObject> objLst){
        List<Partner_Request__c> partnerRequestList = (List<Partner_Request__c>)objLst;        
        for(Partner_Request__c eachPartnerRequest : partnerRequestList){
            PRMHelper prmhelper =  new PRMHelper();
            prmhelper.onInsertPRM(partnerRequestList);
            eachPartnerRequest.PR_Processed__c=true;
        }
        Update partnerRequestList;
    }
 
    public void finish(Database.BatchableContext BC){
        }
    }