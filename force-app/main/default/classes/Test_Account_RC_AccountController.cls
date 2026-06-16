@IsTest
public class Test_Account_RC_AccountController {
    
    @IsTest
    private static void testLaunchRCAccount() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        List<Account> Acct = new List<Account>();
        Account_RC_AccountController.accdetailWrapper testAccwrapper1 = new Account_RC_AccountController.accdetailWrapper();
        Account_RC_AccountController.accdetailWrapper testAccwrapper2 = new Account_RC_AccountController.accdetailWrapper();
        Account_RC_AccountController.accdetailWrapper testAccwrapper3 = new Account_RC_AccountController.accdetailWrapper();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        accObj.RC_Brand__c = 'RingCental';
        accObj.RC_User_ID__c = sysAdmin.Id;
        
        Account accObj1 = new Account();
        accObj1.Name = 'Test Account ';
        accObj1.Partner_ID__c = '123456';
        accObj1.RC_Brand__c = 'AT&T Office@Hand';
        Acct.add(accObj);
        Acct.add(accObj1);
        insert Acct;
        String textctc = '1/0';
        testAccwrapper1 = Account_RC_AccountController.launchRCAccount(accObj.Id);
        testAccwrapper2 = Account_RC_AccountController.launchRCAccount(accObj1.Id);
        testAccwrapper3 = Account_RC_AccountController.launchRCAccount(textctc);
        System.assertEquals(testAccwrapper1.rcUserid, accObj1.RC_User_ID__c);
        System.assertEquals(testAccwrapper1.brandName, accObj1.RC_Brand__c);
        System.debug(testAccwrapper1);
        System.assertEquals(testAccwrapper2.errorMessage, 'Unable to launch RC Account. Error during processing');
        Account_Share_Sync_AccountController.shareSyncAccount(accObj.Id);
        Account_Share_Sync_AccountController.shareSyncAccount(textctc);
    }
    
    @IsTest
    private static void testGetUrlForSCPNavigation() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        List<Account> Acct = new List<Account>();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        accObj.RC_Brand__c = 'RingCental';
        accObj.RC_User_ID__c = sysAdmin.Id;
    
        Account accObj1 = new Account();
        accObj1.Name = 'Test Account ';
        accObj1.Partner_ID__c = '123456';
        accObj1.RC_Brand__c = 'AT&T Office@Hand';
        Acct.add(accObj);
        Acct.add(accObj1);
        insert Acct;
    
        String url = 'https://scp.ringcentral.com/app/accounts/active/${accountId}/account/summary';
        RingCentralVariousSettings__c rcVariousSettings = new RingCentralVariousSettings__c();
        rcVariousSettings.SetupOwnerId = UserInfo.getUserId();
        rcVariousSettings.RC_Account_SCP_URL_Template__c = url;
        insert rcVariousSettings;
        
        Response res = Account_RC_AccountController.getUrlForSCPNavigation(accObj.Id);
        System.assert(res != null);
        System.assertEquals(res.data.get('urlTemplate'), url, 'The url template should be returned');
    }
    
    @IsTest
    private static void CreateCase() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        Account_RC_AccountController.accdetailWrapper testAcc = new Account_RC_AccountController.accdetailWrapper();
        List<Account> Acct = new List<Account>();
        List<Contact> cts = new List<Contact>();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        Acct.add(accObj);
        Account accObj1 = new Account();
        accObj1.Name = 'Test Account Parent ';
        accObj1.Partner_ID__c = '12346';
        Acct.add(accObj1);
        insert Acct;
        
        Contact contactObj = new Contact();
        contactObj.AccountId = accObj.Id;
        contactObj.Email = 'test@test.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        cts.add(contactObj);
        
        Contact contactObj1 = new Contact();
        contactObj1.AccountId = accObj1.Id;
        contactObj1.Email = 'test@test.com';
        contactObj1.Phone = '9910106804';
        contactObj1.LastName = 'TestLast';
        cts.add(contactObj1);
        insert cts;
        Test.startTest();
        List<Case> cse = new List<Case>();
        Case caseObj = new Case(ContactId = contactObj.Id, AccountId = accObj.Id, Subject = 'Test', Status = 'Open', Priority = 'P3', Description = 'Test Description');
        
        Case caseObj1 = new Case(ContactId = contactObj.Id, AccountId = accObj.Id, Subject = 'Test', Status = 'Open', Priority = 'P3', Description = 'Test Description');
        cse.add(caseObj);
        cse.add(caseObj1);
        insert cse;
        
        Account_RC_AccountController.launchRCAccount(caseObj.Id);
        Case_Escalate_To_ERTController.escalate(caseObj.Id);
        Case_Form_String_To_ChatController.getCase(caseObj.Id);
        Case_Create_Update_JIRAController.loadUserAndCase(null, caseObj.Id);
        Case_Create_Update_JIRAController.loadUserAndCase(null, caseObj1.Id);
        Case_Close_Case_JeopardyContrl.getCaseId(caseObj.Id);
        Case_Close_Case_JeopardyContrl.createSolutionRecord('test title', 'Testdetails', caseObj.Id);
        Case_Close_Case_JeopardyContrl.createSolutionRecord(null, null, null);

        List <Solution> solnList = SolutionDetailViewController.fetchSolution(caseObj.Id);
        solnList[0].SolutionNote = 'Testdetails test';
        SolutionDetailViewController.updateSolution(solnList);
        
        String textctc = '0010n000016Gqp2000';
        testAcc = Account_RC_AccountController.launchRCAccount(textctc);
        Case_Create_Update_JIRAController.loadUserAndCase(textctc, caseObj.Id);
        Case_Create_Update_JIRAController.loadUserAndCase(sysAdmin.Id, caseObj1.Id);
        System.assertEquals(testAcc.errorMessage, 'Unable to launch RC Account. Error during processing');
        Test.stopTest();
    
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void CreateCase1() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        List<Account> Acct = new List<Account>();
        List<Contact> cts = new List<Contact>();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        Acct.add(accObj);
        Account accObj1 = new Account();
        accObj1.Name = 'Test Account Parent ';
        accObj1.Partner_ID__c = '12346';
        Acct.add(accObj1);
        insert Acct;
        
        Contact contactObj = new Contact();
        contactObj.AccountId = accObj.Id;
        contactObj.Email = 'test@test.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        cts.add(contactObj);
        
        Contact contactObj1 = new Contact();
        contactObj1.AccountId = accObj1.Id;
        contactObj1.Email = 'test@test.com';
        contactObj1.Phone = '9910106804';
        contactObj1.LastName = 'TestLast';
        cts.add(contactObj1);
        insert cts;
        Test.startTest();
        List<Case> cse = new List<Case>();
        Case caseObj = new Case(ContactId = contactObj.Id, AccountId = accObj.Id, Subject = 'Test', Status = 'Open', Priority = 'P3', Description = 'Test Description', Jira__c = 'testjira');
        cse.add(caseObj);
        
        insert cse;
        String textctc = '0010n000016Gqp2000';
        Account_RC_AccountController.launchRCAccount(caseObj.Id);
        Case_Escalate_To_ERTController.escalate(caseObj.Id);
        Case_Escalate_To_ERTController.escalate(textctc);
        Case_Form_String_To_ChatController.getCase(caseObj.Id);
        Case_Close_Case_JeopardyContrl.getCaseId(caseObj.Id);
        Case_Close_Case_JeopardyContrl.createSolutionRecord('test title', 'Testdetails',caseObj.Id);
        Case_Close_Case_JeopardyContrl.createSolutionRecord(null, null, null);
        
        Case_Create_Update_JIRAController.loadUserAndCase(sysAdmin.Id, caseObj.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void cuJiraTerm() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        System.assert(sysAdmin != null);
        List<Account> Acct = new List<Account>();
        List<Contact> cts = new List<Contact>();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        Acct.add(accObj);
        insert Acct;
        
        Contact contactObj = new Contact();
        contactObj.AccountId = accObj.Id;
        contactObj.Email = 'test@test.com';
        contactObj.Phone = '9910106804';
        contactObj.LastName = 'TestLast';
        cts.add(contactObj);
        insert cts;
        
        List<Case> cse = new List<Case>();
        Case caseObj = new Case(ContactId = contactObj.Id, AccountId = accObj.Id, Subject = 'Test', Status = 'Open', Priority = 'P3', Description = 'Test Description', Jira__c = 'testjira');
        cse.add(caseObj);
        insert cse;
        
        Case_CU_JIRATerminationController.loadCase(caseObj.Id);
    }
    @IsTest
    private static void testShouldHideYesButton() {
         User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        System.assert(sysAdmin != null);
        Test.startTest();
            System.runAs(sysAdmin) {
                Boolean shouldHideForRestricted = Account_RC_AccountController.shouldHideYesButton();
                System.assertEquals(false, shouldHideForRestricted, 'Yes button should be hidden for restricted profile');
            }
        Test.stopTest();
    }

}