@isTest
private class Test_AttAccountSync {
    @testSetup
    static void createData() {
        User u = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_User_Id__c => '123456'
                }
            )
            .create()
            .getRecord();

        Account_Hierarchy__c accHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Company_Status__c => 'Active',
                    Account_Hierarchy__c.Name => 'TestAH'
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest static void testInsertAccount() {
        RestRequest request = new RestRequest();
        request.requestUri = 'test.com';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('[{' +
            '"RC_Brand":null,' +
            '"VAR_Territory":null,' +
            '"Inside_Sales_Rep_Name":"TestAtt",' +
            '"Inside_Sales_Rep_Email":"att_user@gmail.com",' +
            '"Partner_ID":null,' +
            '"MRR":null,' +
            '"AH_Name_Name":"TestAH",' +
            '"Website":"google.com",' +
            '"RC_Account_Status":null,' +
            '"Current_Owner_Name":null,' +
            '"Current_Owner_Email":null,' +
            '"RC_User_ID":"123123",' +
            '"Name":"ATT Sync Test"' +
        '}]');
        RestContext.request = request;

        Test.startTest();
            AttAccountSync.insertAccount();
        Test.stopTest();

        Account createdAccount = [
            SELECT Website, Inside_Sales_Rep__c, AH_Name__c 
            FROM Account 
            WHERE Name = 'ATT Sync Test' 
            LIMIT 1
        ];
        System.assertEquals('google.com', 
            createdAccount.Website, 
            'Website field on Account should be populated with data from request body');

        User userOnOrg = [
            SELECT Id 
            FROM User 
            WHERE Email = 'Att_user@gmail.com' 
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(userOnOrg.Id, 
            createdAccount.Inside_Sales_Rep__c, 
            'Inside_Sales_Rep__c field on Account should be populated with existing Enterprise Account Id');

        Account_Hierarchy__c ahOnOrg = [
            SELECT Id 
            FROM Account_Hierarchy__c 
            WHERE Name = 'TestAH' 
            LIMIT 1
        ];
        System.assertEquals(ahOnOrg.Id, 
            createdAccount.AH_Name__c, 
            'AH_Name__c field on Account should be populated with existing Account_Hierarchy__c Id');
    }
    
    @isTest static void testUpdateAccount() {
        RestRequest request = new RestRequest();
        request.requestUri = 'test.com';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('[{' +
            '"RC_Brand":null,' +
            '"VAR_Territory":null,' +
            '"Inside_Sales_Rep_Name":null,' +
            '"Inside_Sales_Rep_Email":null,' +
            '"Partner_ID":null,' +
            '"MRR":null,' +
            '"AH_Name_Name":"TestAH",' +
            '"Website":"google.com",' +
            '"RC_Account_Status":null,' +
            '"Current_Owner_Name":"TestAtt",' +
            '"Current_Owner_Email":"att_user@gmail.com",' +
            '"RC_User_ID":"123456"' +
        '}]');
        RestContext.request = request;
        Test.startTest();
            AttAccountSync.updateAccount();
        Test.stopTest();

        Account updatedAccount = [
            SELECT Website, Current_Owner__c, AH_Name__c 
            FROM Account 
            WHERE Name = 'testAcc' 
            LIMIT 1
        ];
        System.assertEquals('google.com', 
            updatedAccount.Website, 
            'Website field on Account should be populated with data from request body');

        User userOnOrg = [
            SELECT Id 
            FROM User 
            WHERE Email = 'Att_user@gmail.com' 
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(userOnOrg.Id, 
            updatedAccount.Current_Owner__c, 
            'Current_Owner__c field on Account should be populated with existing Enterprise Account Id');

        Account_Hierarchy__c ahOnOrg = [
            SELECT Id 
            FROM Account_Hierarchy__c 
            WHERE Name = 'TestAH' 
            LIMIT 1
        ];
        System.assertEquals(ahOnOrg.Id, 
            updatedAccount.AH_Name__c, 
            'AH_Name__c field on Account should be populated with existing Account_Hierarchy__c Id');
    }
}