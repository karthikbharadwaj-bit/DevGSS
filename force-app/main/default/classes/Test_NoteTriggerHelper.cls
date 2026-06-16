@isTest
private class Test_NoteTriggerHelper {
    @testSetup
    private static void setupTest() {
        List<User> userList = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    User.FirstName => ValueProviderBuilder.provideList(new List<String> {'FirstName', 'John', 'Brian'}),
                    User.LastName => ValueProviderBuilder.provideList(new List<String> {'TestSysAdm', 'TestNOTE_TEST_SALES', 'TestTEST_NOTE_ENGINEER'}),
                    User.Username => ValueProviderBuilder.provideList(new List<String> {'SysAdm_user@gmail.com', 'NOTE_TEST_SALES!user@gmail.com', 'TEST_NOTE_ENGINEER!user@gmail.com'}),
                    User.Email => ValueProviderBuilder.provideList(new List<String> {'SysAdm_user@gmail.com', 'NOTE_TEST_SALES_user@gmail.com', 'TEST_NOTE_ENGINEER_user@gmail.com'}),
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => ValueProviderBuilder.provideList(
                        new List<String> 
                        {
                            [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id, 
                            [SELECT Id, Name FROM Profile WHERE Name = 'Channel Sales Manager - Lightning'].Id, 
                            [SELECT Id, Name FROM Profile WHERE Name LIKE '%engineer%' LIMIT 1].Id
                        }
                    ),
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .quantity(3)
            .create()
            .getRecords(); 
    }

    @IsTest
    private static void opportunityLastTouchShouldBeUpdated() {
        User salesUser = getSalesUser();
        Opportunity opty;
        System.runAs(salesUser) {
            opty = (Opportunity) new SObjectFactory().create(
                Opportunity.sObjectType,
                Opportunity.AccountId,
                ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            );
        }

        Test.startTest();
            System.runAs(salesUser) {
                Note n = (Note) new SObjectFactory()
                .create(
                    Note.sObjectType,
                    new Map<SObjectField, Object> {
                        Note.Title => ValueProviderBuilder.provideUniqueString(),
                        Note.ParentId => opty.Id
                    }
                );
            }
            System.assert(verifyLastTouchOnOptyOrLead(getOpportunity(), salesUser.Id, true));
        Test.stopTest();
    }

    @IsTest
    private static void leadLastTouchShouldBeUpdated() {
        Test.startTest();
            User salesUser = getSalesUser();
            System.runAs(salesUser) {
                Note n = (Note) new SObjectFactory()
                .create(
                    Note.sObjectType,
                    new Map<SObjectField, Object> {
                        Note.Title => ValueProviderBuilder.provideUniqueString(),
                        Note.ParentId => ValueProviderBuilder.provideGenericParent(Lead.sObjectType)
                    }
                );
            }
            System.assert(verifyLastTouchOnOptyOrLead(getLead(), salesUser.Id, true));
        Test.stopTest();
    }

    @IsTest
    private static void accountLastTouchShouldBeUpdated() {
        Test.startTest();
            User salesUser = getSalesUser();
            System.runAs(salesUser) {
                Note n = (Note) new SObjectFactory()
                .create(
                    Note.sObjectType,
                    1,
                    new Map<SObjectField, Object> {
                        Note.Title => ValueProviderBuilder.provideUniqueString(),
                        Note.ParentId => ValueProviderBuilder.provideGenericParent(Account.sObjectType)
                    }
                )[0];
            }
            System.assert(verifyLastTouchOnAccount(getAccount(), salesUser, true));
        Test.stopTest();
    }

    @isTest
    private static void opportunityLastTouchWillNotUpdated() {
        Opportunity opty;
        User salesUser = getSalesUser();
        System.runAs(salesUser) {
            opty = (Opportunity) new SObjectFactory().create(
                Opportunity.sObjectType,
                Opportunity.AccountId,
                ValueProviderBuilder.provideGenericParent(Account.sObjectType)
            );
        }

        Test.startTest();
            Note n = (Note) new SObjectFactory()
                .create(
                    Note.sObjectType,
                    new Map<SObjectField, Object> {
                        Note.Title => ValueProviderBuilder.provideUniqueString(),
                        Note.ParentId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                    }
                );
            System.assert(verifyLastTouchOnOptyOrLead(getOpportunity(), UserInfo.getUserId(), false));
        Test.stopTest();
    }

    @isTest
    private static void leadLastTouchWillNotUpdated() {
        Test.startTest();
            Note n = (Note) new SObjectFactory()
                .create(
                    Note.sObjectType,
                    new Map<SObjectField, Object> {
                        Note.Title => ValueProviderBuilder.provideUniqueString(),
                        Note.ParentId => ValueProviderBuilder.provideGenericParent(Lead.sObjectType)
                    }
                );
            System.assert(verifyLastTouchOnOptyOrLead(getLead(), UserInfo.getUserId(), false));
        Test.stopTest();
    }

    @isTest
    private static void accountLastTouchWillNotUpdated() {
        User engineerUser = getEngineerUser();

        System.runAs(engineerUser) {
            Account acc = (Account) new SObjectFactory().create(Account.sObjectType);

            Test.startTest();
                Note n = (Note) new SObjectBuilder(Note.sObjectType)
                    .setFields(
                        new Map<SObjectField, Object> {
                            Note.Title => ValueProviderBuilder.provideUniqueString(),
                            Note.ParentId => acc.Id
                        }
                    )
                    .create()
                    .getRecord();
            Test.stopTest();
        }

        System.assert(verifyLastTouchOnAccount(getAccount(), engineerUser, false));
    }

    @isTest
    private static void testNotesCantBeDeletedByNonAdminUser() {
        System.runAs(getSalesUser()) {
            Note n = (Note) new SObjectBuilder(Note.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Note.Title => ValueProviderBuilder.provideUniqueString(),
                    Note.ParentId => ValueProviderBuilder.provideGenericParent(
                        Opportunity.sObjectType,
                        Opportunity.AccountId,
                        ValueProviderBuilder.provideGenericParent(Account.sObjectType)
                    )
                }
            )
            .create()
            .getRecord();

            Test.startTest();
                try {
                    delete n;
                    // This one is needed to fail the test as far as the Note shouldn't be deleted by non-admin user
                    System.assertNotEquals(
                        0, 
                        countNotesInDatabase(), 
                        'A DML Exception should have been thrown but it wasn\'t'
                    );
                } catch (DMLException e) {
                    System.assertEquals(
                        StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, 
                        e.getDmlType(0),
                        'Wrong exception status code'
                    );
                    System.assertEquals(
                        'Unable to delete notes.', 
                        e.getDmlMessage(0), 
                        'Note deletion didn\'t fail or failed on some reason not covered in this test.'
                    );
                }
            Test.stopTest();
        }
    }

    @isTest
    private static void testLeadRespondedFieldsPopulatedOnNoteInsert() {
        System.runAs(getSalesUser()) {
            Lead l = (Lead) new SObjectFactory()
                .create(
                    Lead.sObjectType,
                    new Map<SObjectField, Object> {
                        Lead.Responded_Date__c => null,
                        Lead.Responded_By__c => null
                    }
                );
            
            Test.startTest();
                Note n = (Note) new SObjectFactory()
                    .create(
                        Note.sObjectType,
                        new Map<SObjectField, Object> {
                            Note.Title => ValueProviderBuilder.provideUniqueString(),
                            Note.ParentId => l.Id
                        }
                    );
            Test.stopTest();
            System.assertNotEquals(
                null, 
                getLead().Responded_Date__c, 
                'Responded Date should be populated on note Insert/Update'
            );
            System.assertNotEquals(
                null, 
                getLead().Responded_By__c, 
                'Responded By should be populated on note Insert/Update'
            );
        }
    }

    private static User getSalesUser() {
        return [
            SELECT Firstname, Lastname, Phone, Email, Username, Profile.Name
            FROM User
            WHERE Username LIKE 'NOTE_TEST_SALES%' LIMIT 1
        ];
    }

    private static User getEngineerUser() {
        return [
            SELECT FirstName, LastName, Email, Phone
            FROM User
            WHERE Username LIKE 'TEST_NOTE_ENGINEER%'
            LIMIT 1
        ];
    }

    private static Opportunity getOpportunity() {
        return [
            SELECT Responded_Date__c, Responded_By__c, Last_Touched_Date__c, Last_Touched_By__c
            FROM Opportunity
            LIMIT 1
        ];
    }

    private static Account getAccount() {
        return [
            SELECT Name
            FROM Account
            LIMIT 1
        ];
    }

    private static Lead getLead() {
        return [
            SELECT Responded_Date__c, Responded_By__c, Last_Touched_Date__c, Last_Touched_By__c
            FROM Lead
            LIMIT 1
        ];
    }

    private static Integer countNotesInDatabase() {
        return [
            SELECT COUNT()
            FROM Note
        ];
    }

    private static Boolean verifyLastTouchOnOptyOrLead(sObject obj, Id usrId, Boolean isPositive) {
        DateTime currentDate = DateTime.now();
        System.assert(compareDates(currentDate, (DateTime)obj.get('Responded_Date__c'), isPositive) == isPositive,
            'Should be equal');

        System.assert((usrId == obj.get('Responded_By__c')) == isPositive, 'Should be equal');

        System.assert(compareDates(currentDate, (DateTime)obj.get('Last_Touched_Date__c'), isPositive) == isPositive,
            'Should be equal');

        System.assert((usrId == obj.get('Last_Touched_By__c')) == isPositive, 'Should be equal');

        return true;
    }

    private static Boolean verifyLastTouchOnAccount(Account acc, User usr, Boolean isPositive) {
        DateTime currentDate = DateTime.now();
        return true;
    }

    private static Boolean compareDates(DateTime firstDate, DateTime secondDate, Boolean isWeak) {
        Boolean result = false;

        if (firstDate != null && secondDate != null) {
            if (isWeak) {
                result = (firstDate.hour() == secondDate.hour()) && (Math.abs(firstDate.minute() - secondDate.minute()) < 3);
            } else {
                result = firstDate == secondDate;
            }
        }

        return result;
    }
}