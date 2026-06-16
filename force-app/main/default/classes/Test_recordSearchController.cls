/* 
*Class Name 		: Test_recordSearchController

*Business Purpose 	: This is the test class for the apex class -  recordSearchController

*Developer Name 	: Manovasanth Balasankar
Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
18/04/2022         CRM 4864                   Manovasanth Balasankar            New Class
06/05/2022         CRM 4864                   Manovasanth Balasankar            Changes done
*/
@isTest
public class Test_recordSearchController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
 	@isTest
    static void test_SearchTermMethod(){
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Test 1'));
        testAccounts.add(new Account(Name = 'Test 2'));
        insert testAccounts;
        List<Account> testChildAccounts = new List<Account>();
        testChildAccounts.add(new Account(Name = 'Test 1 3', parentId = testAccounts[0].Id));
        testChildAccounts.add(new Account(Name = 'Test 1 4', parentId = testAccounts[0].Id));
        insert testChildAccounts;
        Test.startTest();
       	recordSearchController.getAccountsByName('Test');
        recordSearchController.getContactsByName('Test');
        recordSearchController.getOpportunitiesByName('Test');
        recordSearchController.getAccountsByName('Test-_!');
        recordSearchController.getContactsByName('Test-_!');
        recordSearchController.getOpportunitiesByName('Test-_!');
        recordSearchController.findHierarchyData(testChildAccounts[0].Id);
        Test.stopTest();
    }
}