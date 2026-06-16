@isTest
public class Test_chiliPiperRedirect {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_getchiliPiper() {
        PageReference pageRef = Page.booking;
        chiliPiperRedirect cpr = new chiliPiperRedirect();
        Test.startTest();
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('user_id','12345');
        pageRef.getParameters().put('first_name','Test');
        pageRef.getParameters().put('last_name','Test');
        pageRef.getParameters().put('email','Test@test.com');
        pageRef.getParameters().put('phone','1234567890');
        pageRef.getParameters().put('brand','BT (7710)');
        pageRef.getParameters().put('service_id','12345');
        pageRef.getParameters().put('locale','en_US');
        cpr.chiliPiperRedirectURL();
        Test.stopTest();
    }

}