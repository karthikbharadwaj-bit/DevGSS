public with sharing class AccountPlanExtn {

    public Account_Plan__c objAccountPlan {get; set;}
    public Boolean bEnableSaveButton {get; set;}
    public Account_Plan__c objAccountReadOnlyPlan {get; set;}
    public Account objAccountObject {get; set;}

    String strAccountId = ApexPages.currentPage().getParameters().get('id');
    public Boolean bAccountPlanExist {get; set; }
    public Boolean bAccountPlanShowFromAccount {get; set; }
    public Boolean bAccountPlanShowFromPlan {get; set; }
    public Integer intDummyVal{get; set; }
    public String accountPlanDoc {get; set; }
    public String accountBrand {get; set; }

    public Boolean bShowSaveMessage {get; set; }

    public AccountPlanExtn (ApexPages.StandardController controller) {
        accountPlanDoc = HardcodedIdsMapper.getMatchedObjectId('01580000001C4QY');
        bAccountPlanExist = false;
        System.debug('In Constructor');
        intDummyVal = 0;
        checkEnableSaveButton ();
        accountBrand = [select RC_Brand__c from Account where Id = :strAccountId limit 1].RC_Brand__c;

        objAccountPlan = new Account_Plan__c();

        List<Account_Plan__c> liAccountPlan = [select Number_of_Employees__c, Number_of_Offices__c,
                                                Digital_Line_Difference__c, Industry_from_Rep__c,
                                                Industry__c, Website__c, Customer_Type__c, Primary_Contact__c,
                                                Phone_System_Details__c,  Key_Features_Used_Why_RC_for_this_User__c,
                                                Account_Plan_value__c, Asked_for_Referrals__c,
                                                Offered_line_for_Fax_Machine__c, Presented_Additional_Numbers_to_be_Local__c,
                                                Presented_Addl_No_to_track_Marketing__c, Using_Desktop_Phones__c,
                                                Offered_Line_for_Conferencing_Phone__c, International_Usage__c,
                                                Other_Upsell_Opportunities__c, Conference_Calling_Provider_Cost__c,
                                                CRM_Provider__c, Type_of_ISP_Cost__c, Primary_Mobile_Phone_Device__c,
                                                Account_Status__c, Brand__c, Service_Name__c, Tier__c, MRR__c, aMRR__c,
                                                Number_of_DL_s__c, Number_of_Extensions__c, Number_of_IP_Devices__c,No_of_Employees__c,Active_Users_on_RC__c,
                                                Sold_Licenses_to_be_Deployed__c,No_of_Licenses_to_be_Deployed__c,Flight_Plan_Created__c,No_of_employees_without_RC_seats__c,
                                                UD_or_JR_without_RC_seats__c,No_of_Desk_Phone_Users__c,No_of_Desk_Mobile_Users__c,No_of_Desktop_Application_Users__c,
                                                No_of_Locations_of_Company__c,Previous_Voice_Platform__c,Internet_Transport_Provider__c,Transport_Type__c,Mobility_Provider__c,
                                                Active_Mobile_Lines__c,Customer_Industry__c,Context_of_Usage__c,Reason_for_Change_of_Service__c,Features_from_Previous_Service__c,
                                                Email__c,Chat_Messaging__c,File_Sharing__c,Video_Conferencing__c,Audio_Conferencing__c,CRM__c,SMS_MMS__c,Other_Primary_Application__c,
                                                Mobile_Phones__c,Tablets__c,Desktop_Application_Softphone__c,IP_Phones_Desk_Phone__c,Analog_or_POTS_Lines__c,Department_Names__c,
                                                Departments_with_Unique_Requirements__c,Departments_in_Different_Locations__c,Reporting_on_Call_Volume__c,Require_Integration__c,Features_to_be_Implemented__c,
                                                Custom_Features_or_Integrations__c,Ongoing_Deployment_Opp_Identified__c,Upsell_Opportunity_Identifed__c,Adoption_Opps_Identified__c
                                                from Account_Plan__c where Account_ID__c=:strAccountId limit 1];
        if(null != liAccountPlan) {
            for( Account_Plan__c actPlan: liAccountPlan ){
                bAccountPlanExist = true;

                //fetch account plan details into objAccountPlan
                objAccountPlan.Account_Plan_Value__c = actPlan.Account_Plan_Value__c;
                objAccountPlan.Number_of_Employees__c = actPlan.Number_of_Employees__c;
                objAccountPlan.Number_of_Offices__c = actPlan.Number_of_Offices__c;
                objAccountPlan.Industry_from_Rep__c = actPlan.Industry_from_Rep__c;
                objAccountPlan.Website__c = actPlan.Website__c;
                objAccountPlan.Customer_Type__c = actPlan.Customer_Type__c;
                objAccountPlan.Primary_Contact__c = actPlan.Primary_Contact__c;
                objAccountPlan.Phone_System_Details__c = actPlan.Phone_System_Details__c;
                objAccountPlan.Key_Features_Used_Why_RC_for_this_User__c = actPlan.Key_Features_Used_Why_RC_for_this_User__c;
                objAccountPlan.Account_Plan_value__c = actPlan.Account_Plan_value__c;
                objAccountPlan.Asked_for_Referrals__c = actPlan.Asked_for_Referrals__c;
                objAccountPlan.Offered_line_for_Fax_Machine__c = actPlan.Offered_line_for_Fax_Machine__c;
                objAccountPlan.Presented_Additional_Numbers_to_be_Local__c = actPlan.Presented_Additional_Numbers_to_be_Local__c;
                objAccountPlan.Presented_Addl_No_to_track_Marketing__c = actPlan.Presented_Addl_No_to_track_Marketing__c;
                objAccountPlan.Using_Desktop_Phones__c = actPlan.Using_Desktop_Phones__c;
                objAccountPlan.Offered_Line_for_Conferencing_Phone__c = actPlan.Offered_Line_for_Conferencing_Phone__c;
                objAccountPlan.International_Usage__c = actPlan.International_Usage__c;
                objAccountPlan.Other_Upsell_Opportunities__c = actPlan.Other_Upsell_Opportunities__c;
                objAccountPlan.Conference_Calling_Provider_Cost__c = actPlan.Conference_Calling_Provider_Cost__c;
                objAccountPlan.CRM_Provider__c = actPlan.CRM_Provider__c;
                objAccountPlan.Type_of_ISP_Cost__c = actPlan.Type_of_ISP_Cost__c;
                objAccountPlan.Primary_Mobile_Phone_Device__c = actPlan.Primary_Mobile_Phone_Device__c;
                objAccountPlan.No_of_Employees__c = actPlan.No_of_Employees__c;
                objAccountPlan.Active_Users_on_RC__c = actPlan.Active_Users_on_RC__c;
                objAccountPlan.Sold_Licenses_to_be_Deployed__c = actPlan.Sold_Licenses_to_be_Deployed__c;
                objAccountPlan.No_of_Licenses_to_be_Deployed__c = actPlan.No_of_Licenses_to_be_Deployed__c;
                objAccountPlan.Flight_Plan_Created__c = actPlan.Flight_Plan_Created__c;
                objAccountPlan.No_of_employees_without_RC_seats__c = actPlan.No_of_employees_without_RC_seats__c;
                objAccountPlan.UD_or_JR_without_RC_seats__c = actPlan.UD_or_JR_without_RC_seats__c;
                objAccountPlan.No_of_Desk_Phone_Users__c = actPlan.No_of_Desk_Phone_Users__c;
                objAccountPlan.No_of_Desk_Mobile_Users__c = actPlan.No_of_Desk_Mobile_Users__c;
                objAccountPlan.No_of_Desktop_Application_Users__c = actPlan.No_of_Desktop_Application_Users__c;
                objAccountPlan.No_of_Locations_of_Company__c = actPlan.No_of_Locations_of_Company__c;
                objAccountPlan.Previous_Voice_Platform__c = actPlan.Previous_Voice_Platform__c;
                objAccountPlan.Internet_Transport_Provider__c = actPlan.Internet_Transport_Provider__c;
                objAccountPlan.Transport_Type__c = actPlan.Transport_Type__c;
                objAccountPlan.Mobility_Provider__c = actPlan.Mobility_Provider__c;
                objAccountPlan.Active_Mobile_Lines__c = actPlan.Active_Mobile_Lines__c;
                objAccountPlan.Customer_Industry__c = actPlan.Customer_Industry__c;
                objAccountPlan.Context_of_Usage__c = actPlan.Context_of_Usage__c;
                objAccountPlan.Reason_for_Change_of_Service__c = actPlan.Reason_for_Change_of_Service__c;
                objAccountPlan.Features_from_Previous_Service__c = actPlan.Features_from_Previous_Service__c;
                objAccountPlan.Email__c = actPlan.Email__c;
                objAccountPlan.Chat_Messaging__c = actPlan.Chat_Messaging__c;
                objAccountPlan.File_Sharing__c = actPlan.File_Sharing__c;
                objAccountPlan.Video_Conferencing__c = actPlan.Video_Conferencing__c;
                objAccountPlan.Audio_Conferencing__c = actPlan.Audio_Conferencing__c;
                objAccountPlan.CRM__c = actPlan.CRM__c;
                objAccountPlan.SMS_MMS__c = actPlan.SMS_MMS__c;
                objAccountPlan.Other_Primary_Application__c = actPlan.Other_Primary_Application__c;
                objAccountPlan.Mobile_Phones__c = actPlan.Mobile_Phones__c;
                objAccountPlan.Tablets__c = actPlan.Tablets__c;
                objAccountPlan.Desktop_Application_Softphone__c = actPlan.Desktop_Application_Softphone__c;
                objAccountPlan.IP_Phones_Desk_Phone__c = actPlan.IP_Phones_Desk_Phone__c;
                objAccountPlan.Analog_or_POTS_Lines__c = actPlan.Analog_or_POTS_Lines__c;
                objAccountPlan.Department_Names__c = actPlan.Department_Names__c;
                objAccountPlan.Departments_with_Unique_Requirements__c = actPlan.Departments_with_Unique_Requirements__c;
                objAccountPlan.Departments_in_Different_Locations__c = actPlan.Departments_in_Different_Locations__c;
                objAccountPlan.Reporting_on_Call_Volume__c = actPlan.Reporting_on_Call_Volume__c;
                objAccountPlan.Require_Integration__c = actPlan.Require_Integration__c;
                objAccountPlan.Features_to_be_Implemented__c = actPlan.Features_to_be_Implemented__c;
                objAccountPlan.Custom_Features_or_Integrations__c = actPlan.Custom_Features_or_Integrations__c;
                objAccountPlan.Ongoing_Deployment_Opp_Identified__c = actPlan.Ongoing_Deployment_Opp_Identified__c;
                objAccountPlan.Upsell_Opportunity_Identifed__c = actPlan.Upsell_Opportunity_Identifed__c;

         }
        }  else {
                bAccountPlanExist = false;
        }

        //if bAccountPlanExist is true, AccountPlan has been created for this account and
        //Account lookup fields must have been set set, and it will be fetched to objAccountPlan
        //If objAccountPlan is false, Account Plan object has not been created yet, and these values
        //should be taken from Account object directly
        if(bAccountPlanExist){
            System.debug ('Account plan exists');
            bAccountPlanShowFromAccount = false;
            bAccountPlanShowFromPlan = true;

            //get its readonly object Digital_Line_Difference__c
            try{
            objAccountReadOnlyPlan = [select Account_Status__c,Brand__c, name,  Service_Name__c,Tier__c, MRR__c,
                                    aMRR__c, Digital_Line_Difference__c, Number_of_DL_s__c, Number_of_Extensions__c ,
                                    Number_of_IP_Devices__c, No_of_Employees__c,Active_Users_on_RC__c,Sold_Licenses_to_be_Deployed__c,
                                    No_of_Licenses_to_be_Deployed__c,Flight_Plan_Created__c,No_of_employees_without_RC_seats__c  from Account_Plan__c
                                    where Account__r.id=:strAccountId limit 1];
            }catch(Exception ex){}
        } else {
            System.debug ('Account plan does not exist');
            bAccountPlanShowFromAccount = true;
            bAccountPlanShowFromPlan = false;

            //get its readonly object
            objAccountObject = [select Account.RC_Account_Status__c, Account.RC_Brand__c   , Account.RC_Service_name__c  ,
                                Account.RC_Tier__c  ,Account.MRR__c  ,Account.aMRR__c      ,
                                Account.Number_of_DL_s__c,Account.Number_of_Extensions__c   ,
                                Account.Number_of_IP_Devices__c,Account.Payment_Plan__c
                                from Account where id=:strAccountId limit 1];
        }


    }


     public PageReference save() {
          System.debug('In save');

          if(bAccountPlanExist ) {    //if it exists, issue an update
                List<Account_Plan__c> liAccountPlan = [select Number_of_Employees__c, Number_of_Offices__c,
                                                Digital_Line_Difference__c, Industry_from_Rep__c,
                                                Industry__c, Website__c, Customer_Type__c, Primary_Contact__c,
                                                Phone_System_Details__c,  Key_Features_Used_Why_RC_for_this_User__c,
                                                Account_Plan_value__c, Asked_for_Referrals__c,
                                                Offered_line_for_Fax_Machine__c, Presented_Additional_Numbers_to_be_Local__c,
                                                Presented_Addl_No_to_track_Marketing__c, Using_Desktop_Phones__c,
                                                Offered_Line_for_Conferencing_Phone__c, International_Usage__c,
                                                Other_Upsell_Opportunities__c, Conference_Calling_Provider_Cost__c,
                                                CRM_Provider__c, Type_of_ISP_Cost__c, Primary_Mobile_Phone_Device__c,
                                                Account_Status__c, Brand__c, Service_Name__c, Tier__c, MRR__c, aMRR__c,
                                                Number_of_DL_s__c, Number_of_Extensions__c, Number_of_IP_Devices__c,No_of_Employees__c,Active_Users_on_RC__c,Sold_Licenses_to_be_Deployed__c,                                                No_of_Licenses_to_be_Deployed__c,Flight_Plan_Created__c,No_of_employees_without_RC_seats__c,
                                                UD_or_JR_without_RC_seats__c,No_of_Desk_Phone_Users__c,No_of_Desk_Mobile_Users__c,No_of_Desktop_Application_Users__c,
                                                No_of_Locations_of_Company__c,Previous_Voice_Platform__c,Internet_Transport_Provider__c,Transport_Type__c,Mobility_Provider__c,
                                                Active_Mobile_Lines__c,Customer_Industry__c,Context_of_Usage__c,Reason_for_Change_of_Service__c,Features_from_Previous_Service__c,
                                                Email__c,Chat_Messaging__c,File_Sharing__c,Video_Conferencing__c,Audio_Conferencing__c,CRM__c,SMS_MMS__c,Other_Primary_Application__c,
                                                Mobile_Phones__c,Tablets__c,Desktop_Application_Softphone__c,IP_Phones_Desk_Phone__c,Analog_or_POTS_Lines__c,Department_Names__c,
                                                Departments_with_Unique_Requirements__c,Departments_in_Different_Locations__c,Reporting_on_Call_Volume__c,Require_Integration__c,
                                                Features_to_be_Implemented__c,Custom_Features_or_Integrations__c,Ongoing_Deployment_Opp_Identified__c,Upsell_Opportunity_Identifed__c,Adoption_Opps_Identified__c
                                                from Account_Plan__c where Account_ID__c=:strAccountId limit 1];

                if(null != liAccountPlan) {
                    for( Account_Plan__c actPlan: liAccountPlan ){

                        //repopulate account plan details into list AccountPlan
                        actPlan.Account_Plan_Value__c = objAccountPlan.Account_Plan_Value__c;
                        actPlan.Number_of_Employees__c = objAccountPlan.Number_of_Employees__c;
                        actPlan.Number_of_Offices__c = objAccountPlan.Number_of_Offices__c;
                        actPlan.Industry_from_Rep__c = objAccountPlan.Industry_from_Rep__c;
                        actPlan.Website__c = objAccountPlan.Website__c;
                        actPlan.Customer_Type__c = objAccountPlan.Customer_Type__c;
                        actPlan.Primary_Contact__c = objAccountPlan.Primary_Contact__c;
                        actPlan.Phone_System_Details__c = objAccountPlan.Phone_System_Details__c;
                        actPlan.Key_Features_Used_Why_RC_for_this_User__c = objAccountPlan.Key_Features_Used_Why_RC_for_this_User__c;
                        actPlan.Account_Plan_value__c = objAccountPlan.Account_Plan_value__c;
                        actPlan.Asked_for_Referrals__c = objAccountPlan.Asked_for_Referrals__c;
                        actPlan.Offered_line_for_Fax_Machine__c = objAccountPlan.Offered_line_for_Fax_Machine__c;
                        actPlan.Presented_Additional_Numbers_to_be_Local__c = objAccountPlan.Presented_Additional_Numbers_to_be_Local__c;
                        actPlan.Presented_Addl_No_to_track_Marketing__c = objAccountPlan.Presented_Addl_No_to_track_Marketing__c;
                        actPlan.Using_Desktop_Phones__c = objAccountPlan.Using_Desktop_Phones__c;
                        actPlan.Offered_Line_for_Conferencing_Phone__c = objAccountPlan.Offered_Line_for_Conferencing_Phone__c;
                        actPlan.International_Usage__c = objAccountPlan.International_Usage__c;
                        actPlan.Other_Upsell_Opportunities__c = objAccountPlan.Other_Upsell_Opportunities__c;
                        actPlan.Conference_Calling_Provider_Cost__c = objAccountPlan.Conference_Calling_Provider_Cost__c;
                        actPlan.CRM_Provider__c = objAccountPlan.CRM_Provider__c;
                        actPlan.Type_of_ISP_Cost__c = objAccountPlan.Type_of_ISP_Cost__c;
                        actPlan.Primary_Mobile_Phone_Device__c = objAccountPlan.Primary_Mobile_Phone_Device__c;
                         actPlan.No_of_Employees__c = objAccountPlan.No_of_Employees__c;
                        actPlan.Active_Users_on_RC__c = objAccountPlan.Active_Users_on_RC__c;
                        actPlan.Sold_Licenses_to_be_Deployed__c = objAccountPlan.Sold_Licenses_to_be_Deployed__c;
                        actPlan.No_of_Licenses_to_be_Deployed__c = objAccountPlan.No_of_Licenses_to_be_Deployed__c;
                        actPlan.Flight_Plan_Created__c = objAccountPlan.Flight_Plan_Created__c;
                        actPlan.No_of_employees_without_RC_seats__c = objAccountPlan.No_of_employees_without_RC_seats__c;
                        actPlan.UD_or_JR_without_RC_seats__c = objAccountPlan.UD_or_JR_without_RC_seats__c;
                        actPlan.No_of_Desk_Phone_Users__c = objAccountPlan.No_of_Desk_Phone_Users__c;
                        actPlan.No_of_Desk_Mobile_Users__c = objAccountPlan.No_of_Desk_Mobile_Users__c;
                        actPlan.No_of_Desktop_Application_Users__c = objAccountPlan.No_of_Desktop_Application_Users__c;
                        actPlan.No_of_Locations_of_Company__c = objAccountPlan.No_of_Locations_of_Company__c;
                        actPlan.Previous_Voice_Platform__c = objAccountPlan.Previous_Voice_Platform__c;
                        actPlan.Internet_Transport_Provider__c = objAccountPlan.Internet_Transport_Provider__c;
                        actPlan.Transport_Type__c = objAccountPlan.Transport_Type__c;
                        actPlan.Mobility_Provider__c = objAccountPlan.Mobility_Provider__c;
                        actPlan.Active_Mobile_Lines__c = objAccountPlan.Active_Mobile_Lines__c;
                        actPlan.Customer_Industry__c = objAccountPlan.Customer_Industry__c;
                        actPlan.Context_of_Usage__c = objAccountPlan.Context_of_Usage__c;
                        actPlan.Reason_for_Change_of_Service__c = objAccountPlan.Reason_for_Change_of_Service__c;
                        actPlan.Features_from_Previous_Service__c = objAccountPlan.Features_from_Previous_Service__c;
                        actPlan.Email__c = objAccountPlan.Email__c;
                        actPlan.Chat_Messaging__c = objAccountPlan.Chat_Messaging__c;
                        actPlan.File_Sharing__c = objAccountPlan.File_Sharing__c;
                        actPlan.Video_Conferencing__c = objAccountPlan.Video_Conferencing__c;
                        actPlan.Audio_Conferencing__c = objAccountPlan.Audio_Conferencing__c;
                        actPlan.CRM__c = objAccountPlan.CRM__c;
                        actPlan.SMS_MMS__c = objAccountPlan.SMS_MMS__c;
                        actPlan.Other_Primary_Application__c = objAccountPlan.Other_Primary_Application__c;
                        actPlan.Mobile_Phones__c = objAccountPlan.Mobile_Phones__c;
                        actPlan.Tablets__c = objAccountPlan.Tablets__c;
                        actPlan.Desktop_Application_Softphone__c = objAccountPlan.Desktop_Application_Softphone__c;
                        actPlan.IP_Phones_Desk_Phone__c = objAccountPlan.IP_Phones_Desk_Phone__c;
                        actPlan.Analog_or_POTS_Lines__c = objAccountPlan.Analog_or_POTS_Lines__c;
                        actPlan.Department_Names__c = objAccountPlan.Department_Names__c;
                        actPlan.Departments_with_Unique_Requirements__c = objAccountPlan.Departments_with_Unique_Requirements__c;
                        actPlan.Departments_in_Different_Locations__c = objAccountPlan.Departments_in_Different_Locations__c;
                        actPlan.Reporting_on_Call_Volume__c = objAccountPlan.Reporting_on_Call_Volume__c;
                        actPlan.Require_Integration__c = objAccountPlan.Require_Integration__c;
                        actPlan.Features_to_be_Implemented__c = objAccountPlan.Features_to_be_Implemented__c;
                        actPlan.Custom_Features_or_Integrations__c = objAccountPlan.Custom_Features_or_Integrations__c;
                        actPlan.Ongoing_Deployment_Opp_Identified__c = objAccountPlan.Ongoing_Deployment_Opp_Identified__c;
                        actPlan.Upsell_Opportunity_Identifed__c = objAccountPlan.Upsell_Opportunity_Identifed__c;
                    }
                    update liAccountPlan ;
                    bAccountPlanExist = true;
                }

             } else {
                System.debug('entered Description= ' + objAccountPlan.Account_Plan_Value__c);
                System.debug('entered primary Contact= ' + objAccountPlan.Primary_Contact__c);
                objAccountPlan.Account_ID__c = strAccountID ;
                objAccountPlan.Account__c = strAccountID ;
                insert objAccountPlan;
             List<Account_Plan__c> listAP = [Select  Id From Account_Plan__c  where Account_ID__c =: strAccountId limit 1];
            String strAccount_Plan_Id=null;
             if(null != listAP ) {
            for( Account_Plan__c  objAccountPlanc  : listAP ){
               strAccount_Plan_Id=objAccountPlanc.Id;
              }
             }

            List<Account> listACc = [SELECT  Id,Account__c FROM Account Where Id=: strAccountId LIMIT 1];
            if(listACc.size() > 0) {
                for(Account objAcc : listACc){
                    objAcc.Account__c=strAccount_Plan_Id;
                }
                update listACc;
            }

                bAccountPlanExist = true;
         }

          bShowSaveMessage = true;

          return null;
     }

     //function to set bEnableSaveButton
     //if current logged in user is owner of account, then only save button will be enabled
     private void checkEnableSaveButton (){
        bEnableSaveButton = true;
        //Get current owner of account by Owner (or Current_Owner__c)
        List<Account> liAccount = [select name, OwnerId /*Current_Owner__c*/ from Account where id=:strAccountId limit 1];

        if(null != liAccount ) {
            for( Account objAccount: liAccount ){
                if(objAccount.OwnerId == UserInfo.getUserId()) {
                   bEnableSaveButton = true;
                }
            }
        }

     }

    public PageReference navigatebacktoRec(){

        PageReference recdet = new PageReference('/lightning/r/Account/'+strAccountId+'/view');

        recdet.setRedirect(true);
        return recdet;
    }
}