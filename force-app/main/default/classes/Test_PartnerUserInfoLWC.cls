/*       
        * Created By    : 
        * Created Date  : 27-02-2020
        * Description   : Test class for partnerUserInfoLWCController class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerUserInfoLWC {
        @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
    public static void getPartnerDetails(){
            PartnerRecordsUtil obj=new PartnerRecordsUtil();
            User user=PartnerRecordsUtil.runAsSysAdmin;
            partnerUserInfoLWCController.getUserInfo(user.Id);
         
    }
}