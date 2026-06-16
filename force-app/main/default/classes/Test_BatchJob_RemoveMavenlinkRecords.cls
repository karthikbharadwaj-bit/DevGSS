@isTest
private class Test_BatchJob_RemoveMavenlinkRecords {
    private final static String TEST_STRING = 'TestString';

    @TestSetup
    static void testDataSetup(){
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true);
    }

    @isTest
    private static void testUnsucessfulRemove() {
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestBatch1',
                    User.Username => 'TestBatch1!user@gmail.com',
                    User.Email => 'TestBatch1_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
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
        DateTime dateNow = System.now();    
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                        Opportunity.EstimatedProfessionalServices12Month__c => 10
                    }
                )
                .create()
                .getRecord();
        PriceBook2 pB2 = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office'
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
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => pB2.Id
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV,
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day())
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id,
                    Phase__c.Initial_Payment__c => 10
                }
            )
            .create()
            .getRecord();                                                        
        List<Mavenlink_Integrator__c> mlRecordsBefore = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        
            BatchJob_RemoveMavenlinkRecords mlRecordBatch = new BatchJob_RemoveMavenlinkRecords();
            Database.executeBatch(mlRecordBatch);
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecordsAfter = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        System.assertNotEquals(mlRecordsBefore.size(),
                                0,
                                'Mavenlink Integrator record was not created.');
        System.assertEquals(mlRecordsBefore.size(),
                                mlRecordsAfter.size(),
                                'Mavenlink Integrator record was removed incorrectly.');
    }

    @isTest
    private static void testSucessfulRemove() {
        Mavenlink_Integrator__c mlRecord = new Mavenlink_Integrator__c();
        mlRecord.Direction__c = 'Inbound';
        mlRecord.ProjectBillingStatus__c = TEST_STRING;
        mlRecord.ProcessStatus__c = 'P';
        DateTime dateNow = System.now();
        mlRecord.ProcessedDate__c = Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day());
        mlRecord.ProjectStatus__c = TEST_STRING;
        mlRecord.ProjectStatusSummary__c = TEST_STRING;
        mlRecord.ProjectAtRiskReason__c = TEST_STRING;
        mlRecord.PhaseName__c = TEST_STRING;
        MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger = false;
        insert mlRecord;

        Test.startTest();
            BatchJob_RemoveMavenlinkRecords mlRecordBatch = new BatchJob_RemoveMavenlinkRecords();
            Database.executeBatch(mlRecordBatch);
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecordsAfter = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        System.assertEquals(0,
                            mlRecordsAfter.size(),
                            'Mavenlink Integrator record was not removed.');
    }

    @isTest
    private static void testSucessfulRemoveWithLimit() {
        Mavenlink_Integrator__c mlRecord = new Mavenlink_Integrator__c();
        mlRecord.Direction__c = 'Inbound';
        mlRecord.ProjectBillingStatus__c = TEST_STRING;
        mlRecord.ProcessStatus__c = 'P';
        DateTime dateNow = System.now();
        mlRecord.ProcessedDate__c = Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day());
        mlRecord.ProjectStatus__c = TEST_STRING;
        mlRecord.ProjectStatusSummary__c = TEST_STRING;
        mlRecord.ProjectAtRiskReason__c = TEST_STRING;
        mlRecord.PhaseName__c = TEST_STRING;
        MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger = false;
        insert mlRecord;
        Test.startTest();
            BatchJob_RemoveMavenlinkRecords mlRecordBatch = new BatchJob_RemoveMavenlinkRecords(1);
            Database.executeBatch(mlRecordBatch);
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecordsAfter = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        System.assertEquals(0,
                            mlRecordsAfter.size(),
                            'Mavenlink Integrator record was not removed.');
    }

    @isTest
    private static void testSucessfulRemoveWithId() {
        Mavenlink_Integrator__c mlRecord = new Mavenlink_Integrator__c();
        mlRecord.Direction__c = 'Inbound';
        mlRecord.ProjectBillingStatus__c = TEST_STRING;
        mlRecord.ProcessStatus__c = 'P';
        DateTime dateNow = System.now();
        mlRecord.ProcessedDate__c = Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day());
        mlRecord.ProjectStatus__c = TEST_STRING;
        mlRecord.ProjectStatusSummary__c = TEST_STRING;
        mlRecord.ProjectAtRiskReason__c = TEST_STRING;
        mlRecord.PhaseName__c = TEST_STRING;
        MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger = false;
        insert mlRecord;

        Test.startTest();
            BatchJob_RemoveMavenlinkRecords mlRecordBatch = new BatchJob_RemoveMavenlinkRecords(mlRecord.Id);
            Database.executeBatch(mlRecordBatch);
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecordsAfter = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        System.assertEquals(0,
                            mlRecordsAfter.size(),
                            'Mavenlink Integrator record was not removed.');
    }

    @isTest
    private static void testSucessfulSchedulable() {
        Mavenlink_Integrator__c mlRecord = new Mavenlink_Integrator__c();
        mlRecord.Direction__c = 'Inbound';
        mlRecord.ProjectBillingStatus__c = TEST_STRING;
        mlRecord.ProcessStatus__c = 'P';
        DateTime dateNow = System.now();
        mlRecord.ProcessedDate__c = Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day());
        mlRecord.ProjectStatus__c = TEST_STRING;
        mlRecord.ProjectStatusSummary__c = TEST_STRING;
        mlRecord.ProjectAtRiskReason__c = TEST_STRING;
        mlRecord.PhaseName__c = TEST_STRING;
        MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger = false;
        insert mlRecord;

        Test.startTest();
            BatchJob_RemoveMavenlinkRecords mlRecordBatch = new BatchJob_RemoveMavenlinkRecords(mlRecord.Id);
            String sch = '0 0 23 * * ?';
            System.schedule('Remove Mavenlink Records', sch, mlRecordBatch);
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecordsAfter = [SELECT Id
                                                        FROM Mavenlink_Integrator__c];
        System.assertEquals(1,
                            mlRecordsAfter.size(),
                            'Mavenlink Integrator record was not removed.');
    }

}