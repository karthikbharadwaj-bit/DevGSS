/*       
* Created By    : Ranjani N
* Created Date  : 14-05-2020
* Description   : Controller class for Contact_New_Booking,Contact_marketo_Activities lightning components
* Test Class    :Test_Contact_New_BookingController      

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public class Contact_New_BookingController {
    
    @AuraEnabled
    public static Contact getContact(String recordId){
        Contact c = [Select Id,ContactID18Digit__c, Phone,BB_Service_ID__c,FirstName,LastName,Email,User_Id__c From Contact Where Id = :recordId];
        return c;
    }

}