@isTest
public class docuSignRedirect_Test {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_docuSignRedirectURL() {
        PageReference pageRef = Page.docuSignRedirect;
        docuSignRedirect cpr = new docuSignRedirect();
        Test.startTest();
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('CRL','12345');
        pageRef.getParameters().put('RED','Test');
        pageRef.getParameters().put('SourceID','Test');
        pageRef.getParameters().put('DESID','Test@test.com');

        cpr.docusignRedirectURL();
        Test.stopTest();
    }

}