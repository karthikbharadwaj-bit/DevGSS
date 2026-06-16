/*       
        * Created By    : 
        * Created Date  : 25-02-2020
        * Description   : Test class for Partner_HelpController class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerHelpController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    public static void helpSupport(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Messaging.SingleEmailMessage Message = new Messaging.SingleEmailMessage();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            Partner_HelpController.sendEmailController('dear user','test body');
        }
        Test.stopTest();
    }
}