@isTest
public class Test_GSPLoginFormController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLogin() {
        PartnerRecordsUtil recordsUtil = new PartnerRecordsUtil();
        GSPLoginFormController.doLogin(PartnerRecordsUtil.runAsSysAdmin.username,'12345678','');
        GSPLoginFormController.doLogin(PartnerRecordsUtil.runAsSysAdmin.username,'12345678',null);
        GSPLoginFormController.doResetPassword(PartnerRecordsUtil.runAsSysAdmin.username);
    }
}