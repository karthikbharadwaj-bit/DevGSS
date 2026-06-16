@isTest
private class Test_BatchJob_CheckCompanyPersonType {

    @isTest
    private static void testPopulateSetNegativeValue() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c comp = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        Company_Persons__c person = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => ld.Id,
                    Company_Persons__c.Company__c => comp.Id
                }
            )
            .create()
            .getRecord();    

        Test.startTest();
            BatchJob_CheckCompanyPersonType personBatch = new BatchJob_CheckCompanyPersonType();
            Database.executeBatch(personBatch);
        Test.stopTest();

        ld = [
                SELECT The_Set__c
                FROM Lead
                WHERE Id =: ld.Id
            ];
        System.assertEquals(ld.The_Set__c,
                            'No',
                            'The Set field was populated incorrectly from Company Person.');
    }

    @isTest
    private static void testPopulateSetPositiveValue() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c comp = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        Company_Persons__c person = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => ld.Id,
                    Company_Persons__c.Company__c => comp.Id,
                    Company_Persons__c.Company_Person_Type__c => 'The Set'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            BatchJob_CheckCompanyPersonType personBatch = new BatchJob_CheckCompanyPersonType();
            Database.executeBatch(personBatch);
        Test.stopTest();

        ld = [
                SELECT The_Set__c
                FROM Lead
                WHERE Id =: ld.Id
            ];
        System.assertEquals(ld.The_Set__c,
                            'Yes',
                            'The Set field was populated incorrectly from Company Person.');
    }

    @isTest
    private static void testPopulateSetIndividualRun() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c comp = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        Company_Persons__c person = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => ld.Id,
                    Company_Persons__c.Company__c => comp.Id,
                    Company_Persons__c.Company_Person_Type__c => 'The Set'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            BatchJob_CheckCompanyPersonType personBatch = new BatchJob_CheckCompanyPersonType(ld.Id);
            Database.executeBatch(personBatch);
        Test.stopTest();

        ld = [
                SELECT The_Set__c
                FROM Lead
                WHERE Id =: ld.Id
            ];
        System.assertEquals(ld.The_Set__c,
                            'Yes',
                            'The Set field was populated incorrectly from Company Person.');
    }

    @isTest
    private static void testPopulateSetOrderBy() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c comp = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        Company_Persons__c person = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => ld.Id,
                    Company_Persons__c.Company__c => comp.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            BatchJob_CheckCompanyPersonType personBatch = new BatchJob_CheckCompanyPersonType(true);
            Database.executeBatch(personBatch);
        Test.stopTest();

        ld = [
                SELECT The_Set__c
                FROM Lead
                WHERE Id =: ld.Id
            ];
        System.assertEquals(ld.The_Set__c,
                            'No',
                            'The Set field was populated incorrectly from Company Person.');
    }

    @isTest
    private static void testDoubleTimeBatchRun() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c comp = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        Company_Persons__c person = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => ld.Id,
                    Company_Persons__c.Company__c => comp.Id,
                    Company_Persons__c.Company_Person_Type__c => 'The Set'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            BatchJob_CheckCompanyPersonType personBatch = new BatchJob_CheckCompanyPersonType();
            Database.executeBatch(personBatch);
        Test.stopTest();
        Database.executeBatch(personBatch);

        List<AsyncApexJob> lastBatchRun = [SELECT CompletedDate 
                                            FROM AsyncApexJob 
                                            WHERE ApexClass.Name = 'BatchJob_CheckCompanyPersonType' 
                                            AND CompletedDate != null];
        System.assertEquals(lastBatchRun.size(),
                            2,
                            'Batch was incorrectly ran double time.');
    }
}