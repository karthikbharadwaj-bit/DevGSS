/*       
* Created By    : Ishwarya.
* Created Date  : 24-03-2020
* Description   : Test class for Lead_ConvertController class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_LeadConvertController {
    @isTest
    public static void leadConvert(){
        Lead l=new Lead(LastName='Test LName',Company='Test Cmpy',email='abct@test.com',
                        LeadSource='ISV Generated',Industry='Insurance',Status='2. Contacted',ownerid=UserInfo.getUserId());
        insert l;
        Id ownerId=(l.ownerid);
        Lead_Owners_For_Lead_Conversion__mdt lowner=[select Id,Label,LeadOwner_Id__c from Lead_Owners_For_Lead_Conversion__mdt order by label limit 1];
        Id leadowner=lowner.LeadOwner_Id__c;
        Test.startTest();
        Lead_ConvertController.convertLead(l.Id);
        Test.stopTest();
        system.assertNotEquals(l.OwnerId, leadowner);
    }
}