/**
 * This class contains unit tests for validating the behavior of Apex class 'ApprovalHelperCls'.
 */
@isTest
private class ApprovalHelperClsTest {
    public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testBadValue() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        //TriggerHandler.BY_PASS_LEAD_UPDATE();
        Map<Id,Id> approvalToPartnerContactMap = new Map<Id,Id>();
         //ApprovalHelperCls.updateRelatedParentObjectsBasedContact(approvalToPartnerContactMap);
        List<Lead> leadList = new List<Lead>();
        Lead leadObj = new Lead();
        leadObj.FirstName='testFirst';
        leadObj.LastName='testLast';
        leadObj.Company='testCompany';
        leadObj.Email='test2.test@test.com';
        leadObj.Phone='9910106804';
        leadObj.LeadSource = 'Inbound Call';
        leadObj.Notes__c = 'Test Notes';
        leadObj.Website = 'http://test.com';
        leadObj.NumberOfEmployees = 123;
        leadObj.Industry = 'Other';
        leadObj.NumberOfEmployees__c = '50-249';
        leadObj.Number_of_Locations__c = '50+';
        leadObj.Agent_Email_Address__c = 'test@test.com';
        leadObj.Eligible_Protection_Period__c = system.today();
        leadObj.Status = '2. Contacted';
        leadObj.Country__c='USA';
        leadObj.Zip_Code__c = '100';
        //leadObj.OwnerId = user.Id;
        leadObj.LS_Primary_NAIC__c='1';
        leadObj.Employees_Override__c='50-249';
       // insert leadObj;
        Lead leadObj2 = new Lead();
        leadObj2.FirstName='testFirst';
        leadObj2.LastName='testLast';
        leadObj2.Company='testCompany';
        leadObj2.Email='test2.test@test.com';
        leadObj2.Phone='9910106804';
        leadObj2.LeadSource = 'Inbound Call';
        leadObj2.Notes__c = 'Test Notes';
        leadObj2.Website = 'http://test.com';
        leadObj2.NumberOfEmployees = 123;
        leadObj2.Industry = 'Other';
        leadObj2.NumberOfEmployees__c = '20';
        leadObj2.Number_of_Locations__c = '50+';
        leadObj2.Agent_Email_Address__c = 'test@test.com';
        leadObj2.Eligible_Protection_Period__c = system.today();
        leadObj2.Status = '2. Contacted';
        leadObj2.Country__c='USA';
        leadObj2.Zip_Code__c = '100';
        //leadObj2.OwnerId = user.Id;
        leadObj2.LS_Primary_NAIC__c='1';
        leadObj2.Employees_Override__c='50-249';

        Lead leadObj1 = new Lead();
        leadObj1.FirstName='testFirst';
        leadObj1.LastName='testLast';
        leadObj1.Company='testCompany';
        leadObj1.Email='test2.test@test.com';
        leadObj1.Phone='9910106804';
        leadObj1.LeadSource = 'Inbound Call';
        leadObj1.Notes__c = 'Test Notes';
        leadObj1.Website = 'http://test.com';
        leadObj1.NumberOfEmployees = 123;
        leadObj1.Industry = 'Other';
        leadObj1.NumberOfEmployees__c = '20+';
        leadObj1.Number_of_Locations__c = '50+';
        leadObj1.Agent_Email_Address__c = 'test@test.com';
        leadObj1.Eligible_Protection_Period__c = system.today();
        leadObj1.Status = '2. Contacted';
        leadObj1.Country__c='USA';
        leadObj1.Zip_Code__c = '100';
        //leadObj1.OwnerId = user.Id;
        leadObj1.LS_Primary_NAIC__c='1';
        leadObj1.Employees_Override__c='50-249';
        leadList.add(leadObj1);
        leadList.add(leadObj);
        leadList.add(leadObj2);
        String expected = ''
                + '"FieldName","delimit1","BadValues","delimit2","GoodValues","delimit3","EOL"\n'
                + '"NumberOfEmployees__c","#","20+","#","Oct-49","#","#EOL#"\n'
                + '"NumberOfEmployees__c","#","20-24","#","Oct-49","#","#EOL#"\n'
                ;
            Folder fd = [SELECT Id FROM Folder WHERE Name='Public Documents' LIMIT 1];
            Document dummyDocument = new Document();
            dummyDocument.name = 'No_Employee_Mapping';
            dummyDocument.body = Blob.valueOf(expected);
            dummyDocument.folderId=fd.Id;
            dummyDocument.isPublic=true;
            dummyDocument.type='csv';
            insert dummyDocument;
            LeadTriggerHelperExt.getCheckForBadValue(leadList);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAgentCreditSplit() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_Approver_Trigger = true;
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        Triggers.switchOff();
        Account accObj = new Account();
        accObj.Name = 'Rctest1';
        accObj.RC_Account_Status__c ='Paid';
        accObj.recordTypeId = rtMapByName.get('Customer Account').getRecordTypeId();
        system.debug('======= accObj.recordTypeId ====== '+ accObj.recordTypeId);
        accObj.RC_Signup_Date__c = System.Now();
        accObj.Employees_Override__c = 45;
        insert accObj;

        Contact con = new Contact();
        Schema.DescribeSObjectResult result1 = Contact.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName1= result1.getRecordTypeInfosByName();
        con.recordTypeId =rtMapByName1.get('VAR Visible').getRecordTypeId();
        con.LastName ='testCon';
        con.AccountId = accObj.Id ;
        insert con;

        Opportunity opp = new Opportunity();
        opp.name = 'testOppoty';
        opp.AccountId = accObj.id;
        opp.Forecasted_Users__c = 50;
        opp.StageName = '3. Qualified';
        opp.Partner_Owner__c = userInfo.getUserId();
        opp.CloseDate = System.today();
        insert opp;

        Triggers.switchOn();

        Agent_Credit__c agnetCredit = new Agent_Credit__c(Account__c=accObj.Id);
        insert agnetCredit;

        // Inserting Partner User
        Id p = [select id from profile where name='RC Partner Modify'].id;
        //Contact con = new Contact(LastName ='testCon',AccountId = accObj0.Id);
        //insert con;
        User user = new User(alias = 'test123', email='test@nemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id,Division='Manager',
                timezonesidkey='America/Los_Angeles', username='tester@noema.com');

        insert user;

        Approval__c appObj = new Approval__c();
        Schema.DescribeSObjectResult result2 = Approval__c.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName2= result2.getRecordTypeInfosByName();
        appObj.RecordTypeId =rtMapByName2.get('Agent Credit Split').getRecordTypeId();
        appObj.Account__c = accObj.id;
        appObj.Type__c = 'Direct to VAR';
        appObj.Opportunity__c = opp.id;
        appObj.Status__c = 'Approved';
        appObj.Territory_DSR__c =true;
        appObj.Approver_Quote__c ='ttest';
        appObj.Account_Segment__c = 'test';
        appObj.Account_InContract__c = true;
        appObj.Credit_Split_Between_Agent_2__c = user.id;
        appObj.Agent_2_Manager__c = user.id;
        appObj.Agent_Credit__c = agnetCredit.Id;
        insert appObj;

        Approval__c appObjOld = new Approval__c(Status__c = 'Approved1');

        ApprovalHelperCls.AgentCreditSplit(new Map<Id,Approval__c>{appObj.Id => appObj},new Map<Id,Approval__c>{appObj.Id => appObjOld});
    }

    // Test validity of EL process after calling recall() and submitForApproval() webservices for positive cases
    @isTest
    static void testRecallingAndResubmittingOfEL() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
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
        System.runAs(testUser) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc'
                    }
                )
                .create()
                .getRecord();
            Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'something@mostcommon.fake',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
            Triggers.switchOff();
            Product2 p2 = (Product2) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Product2.Name => 'Connect Pro - Annual Fee',
                                Product2.IsActive => true,
                                Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                                Product2.Family => 'RingCentral'
                        }
                )
                .create()
                .getRecord();
            Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Opportunity.Name => 'Test Opportunity 2016',
                            Opportunity.Type => 'Syndicated - New',
                            Opportunity.StageName => OpportunityHelper.STAGE_NAME_PLANNING,
                            Opportunity.CloseDate => system.today().addMonths(1),
                            Opportunity.AccountId => acc.Id,
                            Opportunity.Primary_Opportunity_Contact__c => contact.Id
                        }
                    )
                    .create()
                    .getRecord();
            Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'quotetest',
                        Quote.OpportunityId => oppty.Id,
                        Quote.Total_Number_of_Digital_Lines__c => 10,
                        Quote.Account__c => oppty.AccountId,
                        Quote.Pricebook2Id => Test.getStandardPriceBookId()
                    }
                )
                .create()
                .getRecord();
            // Keep triggers off to prevent Opportunity trigger from firing
            // Triggers.switchOn();
            Approval__c engageLegal = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Approval__c.Quote__c => q.Id,
                        Approval__c.Opportunity__c => q.OpportunityId,
                        Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                        Approval__c.Account__c => q.Account__c,
                        Approval__c.RecordTypeId => ApprovalHelperCls.RT_ID_ENGAGE_LEGAL
                    }
                )
                .create()
                .getRecord();
            Triggers.switchOn();

            Test.startTest();
                // Enable only Approval trigger for the test operations
                Triggers.switchOn();
                
                // Bypass Opportunity trigger to prevent SOQL limit issues
                ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
                if (bypassTrigger == null) {
                    bypassTrigger = new ByPassTrigger__c();
                }
                bypassTrigger.Bypass_Opportunity_Trigger__c = true;
                upsert bypassTrigger;
                
                engageLegal.RecordTypeId = ApprovalHelper.RT_ID_RETENTION_REFUNDS;
                engageLegal.Status__c = 'Returned';
                Triggers.switchOff();
                Triggers.except(ApprovalTriggerHandler.LegalRequestRecalledApproval.class.toString());
                update engageLegal;
                Triggers.switchOn();

                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setObjectId(engageLegal.Id);
                request.setSubmitterId(testUser.Id);
                request.setSkipEntryCriteria(true);
                Approval.ProcessResult result = Approval.process(request);

                System.assert(result.isSuccess());

                try{
                    ApprovalHelperCls.recall(engageLegal.Id);
                }catch(Exception ex) {
                    ExceptionHelper.checkIsMassEmailException(ex);
                    return;
                }

                Approval__c recalledEngageLegal = [SELECT Id, Status__c FROM Approval__c WHERE Id = :engageLegal.Id];
                Opportunity opportunity = [SELECT Special_TOS_Approval__c FROM Opportunity WHERE Id = :engageLegal.Opportunity__c];

                System.assertEquals(null, opportunity.Special_TOS_Approval__c);

                recalledEngageLegal.Status__c = ApprovalHelperCls.STATUS_REQUIRED;
                Triggers.switchOff();
            	Triggers.except(ApprovalTriggerHandler.LegalRequestRecalledApproval.class.toString());
                update recalledEngageLegal;
                Triggers.switchOn();

                ApprovalHelperCls.submitForApproval(recalledEngageLegal.Id, null);

                Approval__c submittedEngageLegal = [SELECT Id, Status__c FROM Approval__c WHERE Id = :engageLegal.Id];
                opportunity = [SELECT Special_TOS_Approval__c FROM Opportunity WHERE Id = :engageLegal.Opportunity__c];

                System.assertEquals(submittedEngageLegal.Id, opportunity.Special_TOS_Approval__c);
                
                // Clean up bypass trigger
                if (bypassTrigger != null) {
                    bypassTrigger.Bypass_Opportunity_Trigger__c = false;
                    upsert bypassTrigger;
                }
            Test.stopTest();
        }
    }

    @isTest
    static void testSignMeUpMethod() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
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

        List<Group> groupList = new GroupSelector()
            .selectGroupBasedOnDeveloperNames(
                new List<Object>{
                    new Set<String>{
                        'Sales_Desk_Legal'
                    }
                }
            )
            .executeQuery();

        Group salesDeskLegalQueue = groupList.get(0);

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => salesDeskLegalQueue.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            System.runAs(testUser) {
                String result = ApprovalHelperCls.signMeUp(testApproval.Id);
                System.assert(result == null, 'ApprovalHelperCls.signMeUp() should return null if no errors occured');
            }

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.OwnerId,
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            'In Progress',
            reselectedApproval.Status__c,
            'Approval.Status__c should be "In Progress"'
        );
        System.assertEquals(
            testUser.Id,
            reselectedApproval.OwnerId,
            'Approval.Owner should be user who run ApprovalHelperCls.signMeUp() method'
        );
    }

    @isTest
    static void testSignMeUpMethodWithIncorrectOwnerId() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.signMeUp(testApproval.Id);
            System.assertEquals(
                Label.Approval_Error_OnSignMeUp_AssignedToYou,
                result,
                'ApprovalHelperCls.signMeUp() should return error message from ' +
                '"Label.Approval_Error_OnSignMeUp_AssignedToYou" if Approval__c record assigned to you'
            );

        Test.stopTest();
    }

    @isTest
    static void testSignMeUpMethodWithIncorrectStatus() {

        List<Group> groupList = new GroupSelector()
            .selectGroupBasedOnDeveloperNames(
                new List<Object>{
                    new Set<String>{
                        'Sales_Desk_Legal'
                    }
                }
            )
            .executeQuery();

        Group salesDeskLegalQueue = groupList.get(0);

        List<Approval__c> approvalList = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => salesDeskLegalQueue.Id,
                    Approval__c.Status__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            ApprovalHelper.STATUS_REQUIRED,
                            ApprovalHelper.STATUS_RECALLED
                        }
                    )
                }
            )
            .create()
            .getRecords();

        Test.startTest();

            String result1 = ApprovalHelperCls.signMeUp(approvalList.get(0).Id);
            System.assertEquals(
                String.format(Label.Approval_Error_OnSignMeUp_IncorrectStatus, new List<String>{ApprovalHelper.STATUS_REQUIRED}),
                result1,
                'ApprovalHelperCls.signMeUp() should return error message from ' +
                '"Label.Approval_Error_OnSignMeUp_IncorrectStatus" if Approval__c record has incorrect status("Required", "Recalled")'
            );

            String result2 = ApprovalHelperCls.signMeUp(approvalList.get(1).Id);
            System.assertEquals(
                String.format(Label.Approval_Error_OnSignMeUp_IncorrectStatus, new List<String>{ApprovalHelper.STATUS_RECALLED}),
                result2,
                'ApprovalHelperCls.signMeUp() should return error message from ' +
                '"Label.Approval_Error_OnSignMeUp_IncorrectStatus" if Approval__c record has incorrect status("Required", "Recalled")'
            );

        Test.stopTest();
    }

    @isTest
    static void testRecallCompletedApproval() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_COMPLETED
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.recall(testApproval.Id);

            System.assertEquals(
                String.format(Label.Approval_Error_OnRecall_IncorrectStatus, new List<String>{testApproval.Status__c}),
                result,
                'Recall Approval__c in "Completed" Status should return ' +
                'error from Label.Approval_Error_OnRecall_IncorrectStatus'
            );

        Test.stopTest();
    }

    @isTest
    static void testRecallMethod() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.recall(testApproval.Id);
            System.assertEquals(null, result, 'recall() method should return null in case if no errors occurred');

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);
        System.assertEquals(
            ApprovalHelper.STATUS_RECALLED,
            reselectedApproval.Status__c,
            'Approval__c.Status__c should be "Recalled"'
        );
    }

    @isTest
    static void testReadyForSignatureMethod() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.readyForSignature(testApproval.Id);
            System.assert(result == null, 'ApprovalHelperCls.readyForSignature() should return null if no errors occured');

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.OwnerId,
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            ApprovalHelper.STATUS_READY_FOR_SIGNATURE,
            reselectedApproval.Status__c,
            'Approval.Status__c should be "Ready For Signature"'
        );
    }

    @isTest
    static void testReadyForSignatureMethodWithIncorrectOwnerId() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
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

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => testUser.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            String result = ApprovalHelperCls.readyForSignature(testApproval.Id);
            System.assertEquals(
                Label.Approval_Error_OnReadyForSignature_NotOwner,
                result,
                'ApprovalHelperCls.readyForSignature() should return error message from ' +
                '"Label.Approval_Error_OnReadyForSignature_NotOwner" if Approval__c record not assigned to you'
            );

        Test.stopTest();
    }

    @isTest
    static void testReadyForSignatureMethodWithIncorrectStatus() {

        List<Approval__c> approvalList = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            ApprovalHelper.STATUS_REQUIRED,
                            ApprovalHelper.STATUS_RECALLED
                        }
                    )
                }
            )
            .create()
            .getRecords();

        Test.startTest();

            String result1 = ApprovalHelperCls.readyForSignature(approvalList.get(0).Id);
            System.assertEquals(
                String.format(Label.Approval_Error_OnReadyForSignature_IncorrectStatus, new List<String>{ApprovalHelper.STATUS_REQUIRED}),
                result1,
                'ApprovalHelperCls.readyForSignature() should return error message from ' +
                '"Label.Approval_Error_OnReadyForSignature_IncorrectStatus" if Approval__c record has incorrect status("Required", "Recalled")'
            );

            String result2 = ApprovalHelperCls.readyForSignature(approvalList.get(1).Id);
            System.assertEquals(
                String.format(Label.Approval_Error_OnReadyForSignature_IncorrectStatus, new List<String>{ApprovalHelper.STATUS_RECALLED}),
                result2,
                'ApprovalHelperCls.readyForSignature() should return error message from ' +
                '"Label.Approval_Error_OnReadyForSignature_IncorrectStatus" if Approval__c record has incorrect status("Required", "Recalled")'
            );

        Test.stopTest();
    }

    @isTest
    static void testApproveOrRejectMethodSetApprove() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Boolean isSetApproved = true;
            String result = ApprovalHelperCls.approveOrReject(testApproval.Id, isSetApproved);
            System.assert(result == null, 'ApprovalHelperCls.approveOrReject() should return null if no errors occured');

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            ApprovalHelper.STATUS_READY_FOR_SIGNATURE,
            reselectedApproval.Status__c,
            'Approval.Status__c should be "Ready For Signature"'
        );
    }


    @isTest
    static void testApproveOrRejectMethodSetReject() {

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Boolean isSetApproved = false;
            String result = ApprovalHelperCls.approveOrReject(testApproval.Id, isSetApproved);
            System.assert(result == null, 'ApprovalHelperCls.approveOrReject() should return null if no errors occured');

        Test.stopTest();

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            ApprovalHelper.STATUS_REJECTED,
            reselectedApproval.Status__c,
            'Approval.Status__c should be "Rejected"'
        );
    }

    @isTest
    static void testApproveOrRejectMethodWithIncorrectOwnerId() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
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

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => testUser.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Boolean isSetApproved = true;
            String result = ApprovalHelperCls.approveOrReject(testApproval.Id, isSetApproved);
            System.assertEquals(
                'You are not the owner of this record, therefore you can\'t change statuses.',
                result,
                'ApprovalHelperCls.approveOrReject() should return error message if Approval__c record has wrong OwnerId'
            );


            isSetApproved = false;
            result = ApprovalHelperCls.approveOrReject(testApproval.Id, isSetApproved);
            System.assertEquals(
                'You are not the owner of this record, therefore you can\'t change statuses.',
                result,
                'ApprovalHelperCls.approveOrReject() should return error message if Approval__c record has wrong OwnerId'
            );

        Test.stopTest();
    }


    @isTest
    static void testCreateAccntSplitDirToVarMethod() {
        Triggers.switchOff();

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.Employees_Override__c => 10
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccnt.Id,
                    Opportunity.Forecasted_Users__c => 5,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContact'),
                    Contact.AccountId => testAccnt.Id
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Lead testConvertedLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.IsConverted => true,
                    Lead.OwnerId => UserInfo.getUserId(),
                    Lead.ConvertedAccountId => testAccnt.Id,
                    Lead.ConvertedOpportunityId => testOpp.Id,
                    Lead.ConvertedContactId => testContact.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Type__c => 'Direct to VAR',
                    Approval__c.Partner_Contact__c => testContact.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        testApproval.Account__c = testAccnt.Id;
        testApproval.Opportunity__c = testOpp.Id;
        testApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
        update testApproval;

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c,
                    Approval__c.Completed_Date__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testApproval.Id })
            .executeQuery();

        Approval__c reselectedApproval = approvalList.get(0);

        System.assertEquals(
            ApprovalHelper.STATUS_COMPLETED,
            reselectedApproval.Status__c,
            'Approval__c.Status__c should be "Completed"'
        );
        System.assertEquals(
            System.today(),
            reselectedApproval.Completed_Date__c,
            'Approval__c.Completed_Date__c should be filled with today\'s date'
        );

        List<Account_Split__c> accSplitList = [SELECT Id, Account__c, Sales_Agent__c, Role__c,
                PartnerId__c, Agent_Credit_Split__c, beginDateUpdateOnStatusChange__c,
                Agent_Credit_Sub_Type__c, Market_Segment__c, Commission__c, Begin_Date__c
            FROM Account_Split__c];

        System.assert(!accSplitList.isEmpty(), 'Account_Split__c record should be created');

        Account_Split__c createdAccountSplitRecord = accSplitList.get(0);

        System.assertEquals(
            testAccnt.Id,
            createdAccountSplitRecord.Account__c,
            'Account_Split__c record should be related with Account from Approval__c'
        );

        System.assertEquals(
            testApproval.OwnerId,
            createdAccountSplitRecord.Sales_Agent__c,
            'Account_Split__c.Sales_Agent__c field should be filled with Approval__c.OwnerId'
        );

        System.assertEquals(
            'DSR Shared Agent',
            createdAccountSplitRecord.Role__c,
            'Account_Split__c.Role__c field should have "DSR Shared Agent" value.'
        );

        System.assertEquals(
            'Overlay Shared',
            createdAccountSplitRecord.Agent_Credit_Sub_Type__c,
            'Account_Split__c.Agent_Credit_Sub_Type__c field should have "Overlay Shared" value.'
        );

        System.assertEquals(
            'Overlay',
            createdAccountSplitRecord.Agent_Credit_Split__c,
            'Account_Split__c.Agent_Credit_Split__c field should have "Overlay" value.'
        );

        System.assertEquals(
            80,
            createdAccountSplitRecord.Commission__c,
            'Account_Split__c.Commission__c field should be 80.'
        );

        System.assertEquals(
            System.today(),
            createdAccountSplitRecord.Begin_Date__c,
            'Account_Split__c.Begin_Date__c field should have today\'s date value.'
        );

        List<Opportunity> reselectedOppsList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.Partner_Contact__c,
                    Opportunity.Partner_Account__c,
                    Opportunity.Partner_Lead_Source__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testOpp.Id })
            .executeQuery();

        Opportunity reselectedOpp = reselectedOppsList.get(0);

        System.assertEquals(
            testAccnt.Id,
            reselectedOpp.Partner_Account__c,
            'Opportunity.Partner_Account__c should not be empty'
        );
        System.assertEquals(
            testContact.Id,
            reselectedOpp.Partner_Contact__c,
            'Opportunity.Partner_Contact__c should not be empty'
        );
        System.assertEquals(
            'RingCentral',
            reselectedOpp.Partner_Lead_Source__c,
            'Opportunity.Partner_Lead_Source__c should have value "RingCentral"'
        );
    }

    @isTest
    static void testCreateAccntSplitDirToVarMethodForPartnerOwner() {
        Triggers.switchOff();

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.Employees_Override__c => 10
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccnt.Id,
                    Opportunity.Forecasted_Users__c => 5,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContact'),
                    Contact.AccountId => testAccnt.Id
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Lead testConvertedLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.IsConverted => true,
                    Lead.OwnerId => UserInfo.getUserId(),
                    Lead.ConvertedAccountId => testAccnt.Id,
                    Lead.ConvertedOpportunityId => testOpp.Id,
                    Lead.ConvertedContactId => testContact.Id
                }
            )
            .create()
            .getRecord();

        User testPartnerOwnerUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testUser',
                    User.ProfileId => ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                    User.ContactId => testContact.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.OwnerId => UserInfo.getUserId(),
                    Approval__c.Type__c => 'Direct to VAR',
                    Approval__c.Partner_Owner__c => testPartnerOwnerUser.Id,
                    Approval__c.Account__c => testAccnt.Id,
                    Approval__c.Opportunity__c => testOpp.Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        testApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
        update testApproval;

        List<Account_Split__c> accSplitList = [SELECT Id, Account__c, Sales_Agent__c, Role__c,
                PartnerId__c, Agent_Credit_Split__c, beginDateUpdateOnStatusChange__c,
                Agent_Credit_Sub_Type__c, Market_Segment__c, Commission__c, Begin_Date__c
            FROM Account_Split__c];

        System.assert(!accSplitList.isEmpty(), 'Account_Split__c record should be created');

        Account_Split__c createdAccountSplitRecord = accSplitList.get(0);

        System.assertEquals(
            testAccnt.Id,
            createdAccountSplitRecord.Account__c,
            'Account_Split__c record should be related with Account from Approval__c'
        );

        System.assertEquals(
            testApproval.OwnerId,
            createdAccountSplitRecord.Sales_Agent__c,
            'Account_Split__c.Sales_Agent__c field should be filled with Approval__c.OwnerId'
        );

        System.assertEquals(
            'DSR Shared Agent',
            createdAccountSplitRecord.Role__c,
            'Account_Split__c.Role__c field should have "DSR Shared Agent" value.'
        );

        System.assertEquals(
            'Overlay Shared',
            createdAccountSplitRecord.Agent_Credit_Sub_Type__c,
            'Account_Split__c.Agent_Credit_Sub_Type__c field should have "Overlay Shared" value.'
        );

        System.assertEquals(
            'Overlay',
            createdAccountSplitRecord.Agent_Credit_Split__c,
            'Account_Split__c.Agent_Credit_Split__c field should have "Overlay" value.'
        );

        System.assertEquals(
            80,
            createdAccountSplitRecord.Commission__c,
            'Account_Split__c.Commission__c field should be 80.'
        );

        System.assertEquals(
            System.today(),
            createdAccountSplitRecord.Begin_Date__c,
            'Account_Split__c.Begin_Date__c field should have today\'s date value.'
        );

        List<Opportunity> reselectedOppsList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.Partner_Contact__c,
                    Opportunity.Partner_Account__c,
                    Opportunity.Partner_Lead_Source__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testOpp.Id })
            .executeQuery();

        Opportunity reselectedOpp = reselectedOppsList.get(0);

        System.assertEquals(
            null,
            reselectedOpp.Partner_Account__c,
            'Opportunity.Partner_Account__c should be empty'
        );
        System.assertEquals(
            null,
            reselectedOpp.Partner_Contact__c,
            'Opportunity.Partner_Contact__c should be empty'
        );
        System.assertEquals(
            'RingCentral',
            reselectedOpp.Partner_Lead_Source__c,
            'Opportunity.Partner_Lead_Source__c should have value "RingCentral"'
        );
    }

    @isTest
    static void testChnageOpportunityRecordType() {

        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccnt.Id,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Approval__c.Type__c => 'Direct to VAR',
                        Approval__c.Opportunity__c => testOpp.Id,
                        Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                        Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL
                    }
                )
                .create()
                .getRecord();

            Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
                .selectOpportunities()
                .selectFields(
                    new Set<SObjectField>{
                        Opportunity.RecordTypeId
                    }
                )
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testOpp.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                OpportunityHelper.RT_ID_VAR_OPPORTUNITY,
                reselectedOpp.RecordTypeId,
                'Opportunity.RecordType should be "VAR Opportunity"'
            );

            // update Approval__c.Status__c to 'Rejected' and verify Opportuinty.RecordType is changed
            testApproval.Status__c = ApprovalHelper.STATUS_REJECTED;
            update testApproval;

        Test.stopTest();

        reselectedOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.RecordTypeId
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testOpp.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
            reselectedOpp.RecordTypeId,
            'Opportunity.RecordType should be "Sales Opportunity"'
        );
    }

    @IsTest
    public static void testCreateTechnicalApprovals() {
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => masterAccount.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        List<String> serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, masterAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => masterAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApp',
                Approval__c.Account__c => masterAccount.Id,
                Approval__c.Opportunity__c => masterOpp.Id,
                Approval__c.IsMultiProductTechnicalApproval__c => false,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .build()
            .getRecord();

        Test.startTest();
        insert testApproval;
        Test.stopTest();

        List<Approval__c> technicalApprovals =  new ApprovalSelector()
            .selectServiceApprovalsByMasterId(new List<Object>{new Set<Id>{testApproval.Id}})
            .executeQuery();

        System.assert(!technicalApprovals.isEmpty(), 'technicalApprovals should not be empty');
        System.assert(technicalApprovals.size() == 4, 'technicalApprovals should contain 4 entries');
    }

    @IsTest
    public static void testUpdateTechnicalApprovals() {
        Triggers.switchOff();
        new SObjectBuilder(RingCentralVariousSettings__c.sObjectType)
            .setField(RingCentralVariousSettings__c.Director_BO_Invoice_Billing_Approver__c, DIRECTOR_BO_NAME)
            .setField(RingCentralVariousSettings__c.Treasure_Manager_Invoice_Billing_Approve__c, TREASURE_MANAGER_NAME)
            .setField(RingCentralVariousSettings__c.Treasurer_Invoice_Billing_Approve__c, TREASURER_NAME)
            .setField(RingCentralVariousSettings__c.Controller_Invoice_Billing_Approver__c, CONTROLLER_NAME)
            .setField(RingCentralVariousSettings__c.Controller_for_Invoice_Request__c, INVOICE_CONTROLLER)
            .create()
            .getRecord();

        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                    Account.Sign_Up_Purchase_Limit__c => 0
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => masterAccount.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        List<String> serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, masterAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => masterAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApp',
                Approval__c.Account__c => masterAccount.Id,
                Approval__c.Opportunity__c => masterOpp.Id,
                Approval__c.IsMultiProductTechnicalApproval__c => false,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Sign_Up_Purchase_Limit_Office__c => 5000,
                Approval__c.Monthly_Credit_Limit_Office__c => 1000,
                Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c => 4000,
                Approval__c.Monthly_Credit_Limit_Contact_Center__c => 4000,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        Test.startTest();
            testApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
            update testApproval;
        Test.stopTest();

        List<Approval__c> technicalApprovals =  new ApprovalSelector()
            .selectServiceApprovalsByMasterId(new List<Object>{new Set<Id>{testApproval.Id}})
            .executeQuery();

        serviceAccounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);
        masterAccount = (Account) new AccountSelector().selectAccountsForApproval(new List<Object>{new Set<Id>{testApproval.Account__c}})
            .executeQuery()
            .get(0);

        System.assert(!technicalApprovals.isEmpty(), 'technicalApprovals should not be empty');
        System.assert(technicalApprovals.size() == 4, 'technicalApprovals should contain 4 entries');

        System.assertEquals(
            technicalApprovals[0].Status__c,
            ApprovalHelper.STATUS_APPROVED,
            'Status__c should be Approved'
        );
        System.assertEquals(
            masterAccount.Sign_Up_Purchase_Limit__c,
            testApproval.Sign_Up_Purchase_Limit_Office__c,
            'Approval__с.Sign_Up_Purchase_Limit_Office__c should be copied ' +
            'to Account.Sign_Up_Purchase_Limit__c of Office Service Account'
        );
        System.assertEquals(
            serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Sign_Up_Purchase_Limit__c,
            testApproval.Sign_Up_Purchase_Limit_Contact_Center__c,
            'Approval__с.Sign_Up_Purchase_Limit_Contact_Center__c should be copied ' +
            'to Account.Sign_Up_Purchase_Limit__c of Contact Center Service Account'
        );
    }

    @isTest
    private static void testAutoApproveTreasuryCreditCheckStepCreditLimitApproval() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.Account_Payment_Method__c => 'Invoice',
                    Account.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Approval__c creditLimitApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.NGBSAmountToIncrease__c => 5000,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                    Approval__c.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();
        Test.startTest();
         ApprovalHelperCls.submitForApproval(creditLimitApproval.Id, 'test');
        Test.stopTest();
        List<ProcessInstanceNode> processSteps = (List<ProcessInstanceNode>) new QueryFactory(ProcessInstanceNode.SObjectType)
            .selectFields(new Set<String>{'NodeStatus', 'ProcessInstance.TargetObjectId', 'ProcessNodeName'})
            .setCondition('ProcessNodeName = \'Billing Credit Check\' AND ProcessInstance.TargetObjectId IN: bind0')
            .setQueryBindings(new List<Object> {new Set<Id>{creditLimitApproval.Id}})
            .executeQuery();

        System.assert(!processSteps.isEmpty(), 'Process step must be returned');
        ProcessInstanceNode processStep = processSteps[0];
        System.assertEquals(ApprovalHelper.STATUS_APPROVED, processStep.NodeStatus, 'Step must with status "Approved"');
    }
}