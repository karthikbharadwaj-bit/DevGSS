@isTest
private class Test_LiveAgentPreChatControllerGCC {

    @isTest
	public static void testController_1() {

        String testAccountNumber = '8668803358';
        String testEmail = 'test@test.com';

        Map<String, String> params = new Map<String, String>{ 'accountNumber' => testAccountNumber, 'email' => testEmail };

        Account testAcc = new Account(
            RC_Account_Number__c = testAccountNumber,
            Name = 'testAcc',
            Total_DLs__c = 21,
            Number_of_DL_s__c = 21,
            Service_Type__c = 'Office',
            RC_Service_name__c = 'RingCentral Fax'
        );
        insert testAcc;

        Test.startTest();

            Map<String, String> result = LiveAgentPreChatControllerGCC.getAccount(params);
            System.debug('result >> ' + result);

        Test.stopTest();

        Account reselectedAcc = [select Id, Total_Account_DL_s__c, Service_Type__c, RC_Service_name__c from Account where Id = :testAcc.Id];

        System.assert( Decimal.valueOf( result.get('Total_Account_DL_s__c') ) == reselectedAcc.Total_Account_DL_s__c, result.get('Total_Account_DL_s__c') + ' != ' + reselectedAcc.Total_Account_DL_s__c);
        System.assert(result.get('Service_Type__c') == reselectedAcc.Service_Type__c, result.get('Service_Type__c') + ' != ' + reselectedAcc.Service_Type__c);
        System.assert(result.get('RC_Service_name__c') == reselectedAcc.RC_Service_name__c, result.get('RC_Service_name__c') + ' != ' + reselectedAcc.RC_Service_name__c);

    }

    @isTest
	public static void testController_2() {

        String testAccountNumber = '8668803358';
        String testEmail = 'test@test.com';

        Map<String, String> params = new Map<String, String>{ 'accountNumber' => testAccountNumber, 'email' => testEmail };

        Account testAcc = new Account(
            Name = 'testAcc',
            Total_DLs__c = 21,
            Number_of_DL_s__c = 21,
            Service_Type__c = 'Office',
            RC_Service_name__c = 'RingCentral Fax'
        );
        insert testAcc;


        Contact testContact = new Contact(
            Email = testEmail,
            AccountId = testAcc.Id,
            FirstName = 'testFirstName',
            LastName = 'testLastName'
        );
        insert testContact;


        Test.startTest();

            Map<String, String> result = LiveAgentPreChatControllerGCC.getAccount(params);
            System.debug('result >> ' + result);

        Test.stopTest();


        Contact reselectedContact = [SELECT Account.Total_Account_DL_s__c, Account.Service_Type__c, Account.RC_Service_name__c FROM Contact WHERE Id = :testContact.Id];

        System.assert( Decimal.valueOf( result.get('Total_Account_DL_s__c') ) == reselectedContact.Account.Total_Account_DL_s__c, result.get('Total_Account_DL_s__c') + ' != ' + reselectedContact.Account.Total_Account_DL_s__c);
        System.assert(result.get('Service_Type__c') == reselectedContact.Account.Service_Type__c, result.get('Service_Type__c') + ' != ' + reselectedContact.Account.Service_Type__c);
        System.assert(result.get('RC_Service_name__c') == reselectedContact.Account.RC_Service_name__c, result.get('RC_Service_name__c') + ' != ' + reselectedContact.Account.RC_Service_name__c);

    }
    
}