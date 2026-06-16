/*
* Description   : Test class for AdminInterfaceToSFRedirectionController

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
public class Test_LightningSearchRedirection {
    @isTest static void testDetailRedirection() {
        
        PageReference AdminInterfaceToSFRedirectionPage = Page.AdminInterfaceToSFRedirection;
        AdminInterfaceToSFRedirectionPage.getParameters().put('EnterpriseAccountID','123456');
        Test.startTest();
        Test.setCurrentPage(AdminInterfaceToSFRedirectionPage);
        AdminInterfaceToSFRedirectionController ld = new AdminInterfaceToSFRedirectionController();
        Test.stopTest();
        
    }
    
  
}