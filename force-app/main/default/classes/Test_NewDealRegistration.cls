@isTest
public class Test_NewDealRegistration {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_one() {
        String brandName = 'RingCentral';
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        NewDealRegistration_Controller.getCountryStateMap(brandName);        
        NewDealRegistration_Controller.getAccountDetails(AVAYA_PARTNER_ACCOUNT_ID);
        NewDealRegistration_Controller.getCountriesAvailableForCommunity(null);
    }

    @isTest
    static void test_method_two() {
        Account accObj = new Account(Name = 'Simplion',
                                     Partner_ID__c = 'Test12322',
                                     Number_of_DL_s__c = 2,
                                     Current_Owner_Email__c = 'test@test3.com',
                                     Avaya_Partnership_Account__c = true);
        insert accObj;
        Contact contactObj = new Contact(AccountId =  accObj.Id,
                                        Email = 'test@test.com',
                                        Phone = '9910106804',
                                        LastName = 'TestLast',
                                        FirstName='Test',
                                        Avaya_Partnership_Contact__c = true);
        insert contactObj;

        Account accObj2 = new Account(Name = 'Simplion',
                                     Partner_ID__c = 'Test12322',
                                     Number_of_DL_s__c = 2,
                                     Current_Owner_Email__c = 'test@test3.com',
                                     Avaya_Partnership_Account__c = true,
                                     Certified_Delivery_Partner_Status__c = 'Complete');
        insert accObj2;
        Contact contactObj2 = new Contact(AccountId =  accObj.Id,
                                        Email = 'test@test.com',
                                        Phone = '9910106804',
                                        LastName = 'TestLast',
                                        FirstName='Test',
                                        Avaya_Partnership_Contact__c = true);
        insert contactObj2;

        Test.startTest();
            if (contactObj != null) {
                NewDealRegistration_Controller.PSServiceProviderWrapper psWrapper = NewDealRegistration_Controller.getServiceProvider(contactObj.Id);
                System.assertEquals(psWrapper.showISPField, true);
            	System.assertEquals(psWrapper.picklistValues.size(),4);
            }
        	if (contactObj2 != null) {
                NewDealRegistration_Controller.PSServiceProviderWrapper psWrapper2 =NewDealRegistration_Controller.getServiceProvider(contactObj2.Id);
                System.assertEquals(psWrapper2.showISPField, true);
            	System.assertEquals(psWrapper2.picklistValues.size(),4);
            }
        Test.stopTest();
    }
}