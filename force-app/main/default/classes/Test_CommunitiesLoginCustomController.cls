/*       
        * Created By    : Ishwarya
        * Created Date  : 25-02-2020
        * Description   : Test class for CommunitiesLoginCustomController and Partner_ForgotPasswordController
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_CommunitiesLoginCustomController {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void loginTestMethod(){
        PartnerRecordsUtil testuser = new PartnerRecordsUtil();
        
        CommunitiesLoginCustomController commObj = new CommunitiesLoginCustomController();
        commObj.userName = PartnerRecordsUtil.runAsSysAdmin.username;
        commObj.password = '12345678';
        commObj.doLogin();
        commObj.forgotPassword();
        
        Test.startTest();
        Partner_ForgotPasswordController forgotPwd = new Partner_ForgotPasswordController();
        forgotPwd.username = PartnerRecordsUtil.runAsSysAdmin.username;
        forgotPwd.forgotPassword();
        PageReference forgotPasswordResult;
        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            forgotPasswordResult = forgotPwd.forgotPassword();
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void loginTestUnify(){
        PartnerRecordsUtil testuser = new PartnerRecordsUtil();
        
        UnifyLoginController commObj = new UnifyLoginController();
        commObj.userName = PartnerRecordsUtil.runAsSysAdmin.username;
        commObj.password = '12345678';
        commObj.doLogin();
        commObj.forgotPassword();
        
        Test.startTest();
        UnifyForgotPasswordController forgotPwd = new UnifyForgotPasswordController();
        forgotPwd.username = PartnerRecordsUtil.runAsSysAdmin.username;
        forgotPwd.forgotPassword();
        PageReference forgotPasswordResult;
        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            forgotPasswordResult = forgotPwd.forgotPassword();
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void loginTestAle(){
        PartnerRecordsUtil testuser = new PartnerRecordsUtil();
        
        RainbowOfficeLoginController commObj = new RainbowOfficeLoginController();
        commObj.userName = PartnerRecordsUtil.runAsSysAdmin.username;
        commObj.password = '12345678';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            commObj.doLogin();
            commObj.forgotPassword();
        }
        
        Test.startTest();
        RainbowOfficeForgotPasswordController forgotPwd = new RainbowOfficeForgotPasswordController();
        forgotPwd.username = PartnerRecordsUtil.runAsSysAdmin.username;
        forgotPwd.forgotPassword();
        PageReference forgotPasswordResult;
        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            forgotPasswordResult = forgotPwd.forgotPassword();
        }
        Test.stopTest();
    }
    
}