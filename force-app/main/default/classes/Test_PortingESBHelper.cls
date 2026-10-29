@isTest
private class Test_PortingESBHelper {

    private static Map<string,Schema.RecordTypeInfo> rtMapById =
        Case.SObjectType.getDescribe().getRecordTypeInfosByName();
    private static Map<ID,Schema.RecordTypeInfo> rtMapByName =
        Case.SObjectType.getDescribe().getRecordTypeInfosById();

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
      try{
      User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
          Test.startTest();
          Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
           Case caseObj = new Case();
             Id recordTypeId = rtMapById.get('Porting - In (NeuStar)').getRecordTypeId();
             caseObj.RecordTypeId = recordTypeId;
             caseObj.Subject = 'Test Case ';
             caseObj.Status = 'New';
             caseObj.AccountId = accObj.id;
             caseObj.ContactId = contObj.id;
             caseObj.RC_Porting_Order_ID__c = 5.00;
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj.IsUpdatePermitted__c = false;
          caseObj.Porting_last_status_change_date__c = date.parse('9/10/2013');
          caseObj.Status ='Open';
          caseObj.Convert_to_Internal_Porting__c = 'Porting - In (RC)';
          Test_Utils tutilsss = new Test_Utils();
             tutilsss.initialiseTriggerBypass();
          update caseObj;
          caseObj.RC_Porting_Order_ID__c = null;
          caseObj.Porting_last_status_change_date__c = date.parse('8/10/2013');
          update caseObj;
          tutilsss.deInitialiseTriggerBypass();

          Case caseObj1 = new Case();
             Id recordTypeId1 = rtMapById.get('Porting - In (RC)').getRecordTypeId();
             caseObj1.RecordTypeId = recordTypeId1;
             caseObj1.Subject = 'Test Case ';
             caseObj1.Status = 'New';
             caseObj1.AccountId = accObj.id;
             caseObj1.ContactId = contObj.id;
             caseObj1.RC_Porting_Order_ID__c = 5.00;
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj1;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
        caseObj1.RC_Porting_Order_ID__c = 1.00;//Porting_last_status_change_date__c
          caseObj1.Porting_last_status_change_date__c = date.parse('9/10/2013');
          caseObj1.Status ='Open';
             tutilsss.initialiseTriggerBypass();
          update caseObj1;
          caseObj1.Status = 'Transfer Date Confirmed';
          caseObj1.Porting_Estimated_Completion_Date__c = null;
          update caseObj1;
          tutilsss.deInitialiseTriggerBypass();
          Test.stopTest();
        }
      }catch(exception ex){}
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitTest2() {
        try{
          Test_Utils tutils = new Test_Utils();
          Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
      Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
      User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
      Test.startTest();
        System.runAs(testUser){
        Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
             Case caseObj2 = new Case();
             Id recordTypeId4 = rtMapById.get('Porting - In (RC)').getRecordTypeId();
             caseObj2.RecordTypeId = recordTypeId4;
             caseObj2.Subject = 'Test Case ';
             caseObj2.Status = 'New';
             caseObj2.AccountId = accObj.id;
             caseObj2.ContactId = contObj.id;
             caseObj2.RC_Porting_Order_ID__c = 5.00;
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj2;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj2.Status = 'Rejected' ;
          caseObj2.Porting_Reject_Reason__c = null;
          tutils.initialiseTriggerBypass();
          update caseObj2;
          tutils.deInitialiseTriggerBypass();

        }
        Test.stopTest();

        }catch(exception ex){}

      }
      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
       @isTest
    static void myUnitTest3() {
        try{
            Test_Utils tutils = new Test_Utils();
            Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
          Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
        User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        Test.startTest();
          System.runAs(testUser){
          Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
             Case caseObj2 = new Case();
             Id recordTypeId4 = rtMapById.get('Porting - In (RC)').getRecordTypeId();
             caseObj2.RecordTypeId = recordTypeId4;
             caseObj2.Subject = 'Test Case ';
             caseObj2.Status = 'New';
             caseObj2.AccountId = accObj.id;
             caseObj2.ContactId = contObj.id;
             caseObj2.RC_Porting_Order_ID__c = 5.00;
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj2;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj2.Status = 'Transfer Date Confirmed' ;
                caseObj2.Porting_Estimated_Completion_Date__c = null;
                tutils.initialiseTriggerBypass();
                update caseObj2;
                tutils.deInitialiseTriggerBypass();
        }
        Test.stopTest();
        }catch(exception ex){}
      }
      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitTest4() {
        try{
          Test_Utils tutils = new Test_Utils();
          Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
      Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
      User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
      Test.startTest();
        System.runAs(testUser){
          Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
             Case caseObj2 = new Case();
             Id recordTypeId4 = rtMapById.get('Porting - In (RC)').getRecordTypeId();
             caseObj2.RecordTypeId = recordTypeId4;
             caseObj2.Subject = 'Test Case ';
             caseObj2.Status = 'New';
             caseObj2.RC_Porting_Order_ID__c = 5.00;
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj2;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj2.Status = null ;
                tutils.initialiseTriggerBypass();
                update caseObj2;
                tutils.deInitialiseTriggerBypass();

        }
          Test.stopTest();
        }catch(exception ex){}

      }
      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitTest5() {
        try{
          Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
      Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
      Test_Utils tutils = new Test_Utils();

          Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
             Test.startTest();
             Case caseObj2 = new Case();
             Id recordTypeId4 = rtMapById.get('Porting - In (NeuStar)').getRecordTypeId();
             caseObj2.RecordTypeId = recordTypeId4;
             caseObj2.Subject = 'Test Case ';
             caseObj2.Status = 'New';
             caseObj2.AccountId = accObj.id;
             caseObj2.ContactId = contObj.id;
             caseObj2.RC_Porting_Order_ID__c = 5.00;
             caseObj2.Last_Case_Comment__c = 'test';
             caseObj2.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj2;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj2.Last_Case_Comment__c = '123test';
             caseObj2.Status = 'open';
             caseObj2.Porting_Estimated_Completion_Date__c = date.parse('11/10/2013');
             tutils.initialiseTriggerBypass();
                update caseObj2;
                tutils.deInitialiseTriggerBypass();
                Test.stopTest();


        }catch(exception ex){}

      }
      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void myUnitTest6() {
        try{
          Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
      Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
      Test_Utils tutils = new Test_Utils();
      User testUser = [select Id,Name FROM User Where Name= 'RCESB'];
        System.runAs(testUser){
          Account accObj = new Account();
             accObj.Name = 'testName';
             accObj.RC_User_ID__c = '123456';
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
             insert accObj;
             TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
             Contact contObj = new Contact();
             contObj.LastName = 'testLast';
             contObj.AccountId = accObj.id;
             contObj.email='test@rc112.com';
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
             insert contObj;
             TriggerHandler.BY_PASS_CONTACT_ON_INSERT=false;
             Test.startTest();
             Case caseObj2 = new Case();
             Id recordTypeId4 = rtMapById.get('Porting - In (NeuStar)').getRecordTypeId();
             caseObj2.RecordTypeId = recordTypeId4;
             caseObj2.Subject = 'Test Case ';
             caseObj2.Status = 'New';
             caseObj2.AccountId = accObj.id;
             caseObj2.ContactId = contObj.id;
             caseObj2.RC_Porting_Order_ID__c = 5.00;
             caseObj2.Last_Case_Comment__c = 'test';
             caseObj2.Porting_Estimated_Completion_Date__c = date.parse('9/10/2013');
             TriggerHandler.BY_PASS_CASE_ON_INSERT();
             insert caseObj2;
             TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
             caseObj2.Last_Case_Comment__c = '123test';
             caseObj2.Status = 'open';
             caseObj2.Porting_Estimated_Completion_Date__c = date.parse('11/10/2013');
             tutils.initialiseTriggerBypass();
                update caseObj2;
                tutils.deInitialiseTriggerBypass();
                Test.stopTest();
            }


        }catch(exception ex){}

      }

      @isTest
      static void testSystemOperationCasesWillNotProcessed() {
        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('System Operations').getRecordTypeId();
        insert testCase;

        testCase.Status = 'Open';
        Test.startTest();
            try {
                update testCase;
            }
            catch (DmlException dex) {
                System.assert(true == false, 'DmlException was throw (see debug log). Possible ESB validation rules violation');
                System.debug(dex);
            }
            catch(Exception ex) {
                throw ex;
            }
        Test.stopTest();
      }

      @isTest
      static void testSystemOperationCasesWillBeProcessed() {
        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('System Operations').getRecordTypeId();
        insert testCase;

        testCase.Status = 'Open';
        testCase.RC_Porting_Order_ID__c = 123;
        Boolean dmlExceptionThrowed = false;

        Test.startTest();
            try {
                update testCase;
            }
            catch (DmlException dex) {
                System.debug(dex);
                dmlExceptionThrowed = true;
            }
            catch(Exception ex) {
                throw ex;
            }
        Test.stopTest();

        System.assert(dmlExceptionThrowed = true, 'DML exceptrion was not thrown as expected!');
      }

    @isTest
    private static void testUpdateContactNameWithUpdate() {
        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'RCESB'
            LIMIT 1
        ];
        //System.runAs(us) {
            insert new Feature_Toggle__c(
                ESBPortingNewFlow__c = true
            );
            List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ValueProviderBuilder.provideList(new List<String> {'testAcc', 'TELUS House Account'})
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            List<Contact> contList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => ValueProviderBuilder.provideList(new List<Id> {accList[0].Id, accList[1].Id}),
                        Contact.Email => ValueProviderBuilder.provideList(new List<String> {'testAcc@gmail.com', 'fake.fake@test.com'}),
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .quantity(2)
                .create()
                .getRecords();
            Case cs = new Case();
            Test.startTest();
                cs = (Case) new SObjectBuilder(Case.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Case.Status => 'New',
                            Case.RecordTypeId => rtMapById.get('Porting - In (RC EU)').getRecordTypeId(),
                            Case.Contact_Email__c => contList[1].Email,
                            Case.AccountId => accList[1].Id,
                            Case.ContactId => contList[0].Id
                        }
                    )
                    .create()
                    .getRecord();
            Test.stopTest();

            cs = [
                SELECT ContactId, Priority, Account.Name, Subject
                FROM Case
                WHERE Id = :cs.Id
            ];
            System.assertNotEquals(
                cs.ContactId,
                contList[1].Id,
                'Case Contact was not updated during the ESB Porting.'
            );
            System.assertNotEquals(
                cs.Priority,
                'Medium',
                'Case Priority was not updated during the ESB Porting.'
            );
            System.assertNotEquals(
                cs.Subject,
                'Port-In Case for ' + cs.Account.Name,
                'Case Subject was not updated during the ESB Porting.'
            );
        //}
    }

    @isTest
    private static void testUpdateContactNameWithoutUpdate() {
        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'RCESB'
            LIMIT 1
        ];
        //System.runAs(us) {
            List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ValueProviderBuilder.provideList(new List<String> {'testAcc', 'testAcc_01'})
                    }
                )
                .quantity(2)
                .create()
                .getRecords();
            List<Contact> contList = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => ValueProviderBuilder.provideList(new List<Id> {accList[0].Id, accList[1].Id}),
                        Contact.Email => ValueProviderBuilder.provideList(new List<String> {'testAcc@gmail.com', 'fake.fake@test.com'}),
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .quantity(2)
                .create()
                .getRecords();
            Case cs = new Case();

            Test.startTest();
                cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => 'New',
                        Case.RecordTypeId => rtMapById.get('Porting - In (RC EU)').getRecordTypeId(),
                        Case.Contact_Email__c => contList[1].Email,
                        Case.AccountId => accList[1].Id,
                        Case.ContactId => contList[0].Id
                    }
                )
                .create()
                .getRecord();
            Test.stopTest();

            cs = [
                SELECT ContactId, Priority
                FROM Case
                WHERE Id = :cs.Id
            ];
            System.assertEquals(
                cs.ContactId,
                contList[0].Id,
                'Case Contact was not updated during the ESB Porting.'
            );
            System.assertNotEquals(
                cs.Priority,
                'Medium',
                'Case Priority was not updated during the ESB Porting.'
            );
        //}
    }

    @isTest
    private static void testValidateOnAfterUpdateWithExtraEsb() {
        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'RCESB'
            LIMIT 1
        ];
        System.runAs(us) {
            Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'TELUS House Account'
                    }
                )
                .create()
                .getRecord();
            Contact testCon = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => testAcc.Id,
                        Contact.Email => 'something@mostcommon.fake',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

            Case cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => 'New',
                        Case.RecordTypeId => rtMapById.get('Porting - In (RC EU)').getRecordTypeId(),
                        Case.Contact_Email__c => testCon.Email,
                        Case.AccountId => testAcc.Id,
                        Case.ContactId => testCon.Id
                    }
                )
                .create()
                .getRecord();
            TriggerHandler.ESB_START = true;

            Test.startTest();
                cs.Status = CaseHelper.CASE_STATUS_WAITING_ON_LOA;
                update cs;
            Test.stopTest();

            System.assertEquals([
                    SELECT Status
                    FROM Case
                    WHERE Id = :cs.Id
                ].Status,
                CaseHelper.CASE_STATUS_WAITING_ON_LOA,
                'ESB callout was not invoked during the ESB Porting.'
            );
        }
    }

    @isTest
    private static void testGetAccountIdsFromPortingCases() {
        // accountId populated, contactId empty, record types correct
        List<Case> records = new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Case.AccountId => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    getRTIdByName(PortingESBHelper.PortingInNeuStar),
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(PortingESBHelper.PortingInRCUK)
                })
            })
            .build()
            .getRecords();
        Set<Id> accIds = PortingESBHelper.getAccountIdsFromPortingCases(records, rtMapByName);
        System.assertEquals(accIds.size(), 3);

        // accountId not populated, contactId empty, record types correct
        records = new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    getRTIdByName(PortingESBHelper.PortingInNeuStar),
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(PortingESBHelper.PortingInRCUK)
                })
            })
            .build()
            .getRecords();
        accIds = PortingESBHelper.getAccountIdsFromPortingCases(records, rtMapByName);
        System.assertEquals(accIds.size(), 0);

        // accountId populated, contactId not empty, record types correct
        records = new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Case.ContactId => ValueProviderBuilder.provideDummyId(Contact.SObjectType),
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    getRTIdByName(PortingESBHelper.PortingInNeuStar),
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(PortingESBHelper.PortingInRCUK)
                })
            })
            .build()
            .getRecords();
        accIds = PortingESBHelper.getAccountIdsFromPortingCases(records, rtMapByName);
        System.assertEquals(accIds.size(), 0);

        // accountId populated, contactId empty, sone record types incorrect
        records = new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Case.AccountId => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    getRTIdByName(PortingESBHelper.PortingInNeuStar),
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(CaseHelper.RT_NAME_IT_HELPDESK)
                })
            })
            .build()
            .getRecords();
        accIds = PortingESBHelper.getAccountIdsFromPortingCases(records, rtMapByName);
        System.assertEquals(accIds.size(), 2);
    }

    private static Id getRTIdByName(String name) {
        return rtMapById.get(name).getRecordTypeId();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void shouldRestrictUpdatesWhenNonIntegrationUserInsertsPortingCase() {
        User nonIntegrationUser = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();
        List<Case> cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setField(
                Case.RecordTypeId,
                ValueProviderBuilder.provideList(new List<Id> {
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(CaseHelper.RT_NAME_IT_HELPDESK)
                })
            )
            .quantity(2)
            .build()
            .getRecords();

        System.runAs(nonIntegrationUser) {
            Test.startTest();
                PortingESBHelper.validateOnBeforeInsertEvent(cases, rtMapByName);
            Test.stopTest();
        }

        String portingCaseMessage = 'A non-integration user should not be permitted to insert a porting case';
        String nonPortingCaseMessage = 'A non-integration user should be permitted to insert a non-porting case';
        Assert.isFalse(cases[0].IsUpdatePermitted__c, portingCaseMessage);
        Assert.isTrue(cases[1].IsUpdatePermitted__c, nonPortingCaseMessage);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testValidationsAfterUpdate() {
        List<Case> records = new SObjectBuilder(Case.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Case.AccountId => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    getRTIdByName(PortingESBHelper.PortingInNeuStar),
                    getRTIdByName(PortingESBHelper.PortingInRC),
                    getRTIdByName(PortingESBHelper.PortingInRCUK)
                })
            })
            .build()
            .getRecords();

        Map<Id, Case> caseMap = new Map<Id, Case>();
        for(Case cs : records){
           caseMap.put(cs.id, cs);
        }

        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

        PortingESBHelper.validateOnAfterUpdateEvent(records , caseMap , rtMapByName);

        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'RCESB'
            LIMIT 1
        ];
            Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'TELUS House Account'
                    }
                )
                .create()
                .getRecord();
            Contact c = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => testAcc.Id,
                        Contact.Email => 'something@mostcommon.fake',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

            Case cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => 'New',
                        Case.RecordTypeId => rtMapById.get('System Operations').getRecordTypeId(),
                        Case.Contact_Email__c => 'test@testcoverage.com',
                        Case.AccountId => testAcc.Id,
                        Case.ContactId => c.Id
                    }
                )
                .create()
                .getRecord();
            TriggerHandler.ESB_START = true;

            Test.startTest();
                cs.Status = CaseHelper.CASE_STATUS_WAITING_ON_LOA;
                update cs;
            Test.stopTest();
    }

    @isTest
    static void testValidateOnBeforeUpdateEvent() {
        List<Case> cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Case.Id => ValueProviderBuilder.provideDummyId(Case.SObjectType).getValue(),
                Case.RecordTypeId => rtMapById.get(PortingESBHelper.PortingInNeuStar).getRecordTypeId(),
                Case.Status => ValueProviderBuilder.provideList(new List<Object> {CaseHelper.CASE_STATUS_NEW, CaseHelper.CASE_STATUS_COMPLETED, CaseHelper.CASE_STATUS_COMPLETED}),
                Case.Porting_Reject_Reason__c => ValueProviderBuilder.provideList(new List<String> {'', 'test', 'test2'})
            })
            .quantity(3)
            .build()
            .getRecords();

        Map<Id, Case> oldMap = new Map<Id, Case> {cases[0].Id => cases.remove(0)};
        cases[0].RecordTypeId = rtMapById.get(PortingESBHelper.PortingInRC).getRecordTypeId();
        Profile prof = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
        Test.startTest();
            PortingESBHelper.validateOnBeforeUpdateEvent(cases, oldMap, prof);
        Test.stopTest();

        Case resultedCaseNotPortingInNeuStar = cases[0];
        Case resultedCasePortingInNeuStar = cases[1];
        System.assertEquals(null, resultedCasePortingInNeuStar.Porting_last_status_change_date__c, 'Porting_last_status_change_date__c must not be updated for Porting In NeuStar cases');
        System.assertNotEquals(null, resultedCaseNotPortingInNeuStar.Porting_last_status_change_date__c, 'Porting_last_status_change_date__c must be updated for non Porting In NeuStar cases');
    }
}
