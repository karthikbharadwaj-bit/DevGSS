@IsTest
public with sharing class Test_AccountPlanTriggerHelper {

    static User createTestUser(String firstName, String lastName) {
        String alias = String.join(new List<String>{
            firstName.toLowerCase().substring(0, 1),
            lastName.toLowerCase()
        }, '');
        String email = String.join(new List<String>{
            String.join(new List<String>{
                firstName.toLowerCase().substring(0, 1), lastName.toLowerCase()
            }, '.'),
            String.join(new List<String>{
                'example', 'com'
            }, '.')
        }, '@');
        String username = String.join(new List<String>{
            String.join(new List<String>{
                firstName.toLowerCase(), lastName.toLowerCase()
            }, '.'),
            'sftest.com'
        }, '@');
        String communityNickname = String.join(new List<String>{
            firstName.toLowerCase(),
            lastName.toLowerCase()
        }, '.');

        return createTestUser(new Map<SObjectField, Object>{
            User.Username => username,
            User.FirstName => firstName,
            User.LastName => lastName,
            User.Email => email,
            User.Alias => alias,
            User.CommunityNickname => communityNickname,
            User.TimeZoneSidKey => 'America/Los_Angeles',
            User.LocaleSidKey => 'en_US',
            User.EmailEncodingKey => 'ISO-8859-1',
            User.LanguageLocaleKey => 'en_US',
            User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
        });
    }

    static User createTestUser(Map<SObjectField, Object> fieldValues) {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(fieldValues)
            .create()
            .getRecord();
    }

    static Employee__c createTestEmployee(User user, Map<SObjectField, Object> fieldValues) {
        return (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setFields(fieldValues)
            .setField(Employee__c.User__c, user.Id)
            .setField(Employee__c.First_Name__c, user.FirstName)
            .setField(Employee__c.Last_Name__c, user.LastName)
            .setField(Employee__c.Email__c, user.Email)
            .create()
            .getRecord();
    }

    static Account_Plan__c getAccountPlan(Id accountPlanId) {
        List<Account_Plan__c> listAccountPlan = [
            SELECT
                Id, Owner_Team__c, Owner_Division__c, Owner_Email__c, Owner_Manager_Email__c, Owner_Manager_Name__c
            FROM Account_Plan__c
            WHERE Id = :accountPlanId
        ];

        return listAccountPlan.size() > 0 ? listAccountPlan.get(0) : null;
    }

    static Account_Plan__c getAccountPlan(Account_Plan__c accountPlan) {
        if (accountPlan == null) {
            return null;
        }
        return getAccountPlan(accountPlan.Id);
    }

    @isTest
    static void verifyAccountPlanTriggerHelperEnrichAccountPlanDataOnBeforeInsert() {
        User userAlice = createTestUser('Alice', 'Smith');
        Employee__c managerAlice = createTestEmployee(userAlice, new Map<SObjectField, Object>());

        User userJohn = createTestUser('Bob', 'Doe');
        Employee__c employeeJohn = createTestEmployee(userJohn, new Map<SObjectField, Object>{
            Employee__c.Manager_Employee_Number__c => managerAlice.Id,
            Employee__c.Team__c => ValueProviderBuilder.provideUniqueFixedLengthString('Team', 12),
            Employee__c.Division__c => ValueProviderBuilder.provideUniqueFixedLengthString('Division', 16)
        });

        Account_Plan__c accountPlan = (Account_Plan__c) new SObjectBuilder(Account_Plan__c.SObjectType)
            .setField(Account_Plan__c.OwnerId, userJohn.Id)
            .build()
            .getRecord();

        Test.startTest();

        System.assertEquals(null, accountPlan.Owner_Team__c);
        System.assertEquals(null, accountPlan.Owner_Division__c);
        System.assertEquals(null, accountPlan.Owner_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Name__c);

        insert accountPlan;

        accountPlan = getAccountPlan(accountPlan);

        System.assertEquals(employeeJohn.Team__c, accountPlan.Owner_Team__c);
        System.assertEquals(employeeJohn.Division__c, accountPlan.Owner_Division__c);
        System.assertEquals(employeeJohn.Email__c, accountPlan.Owner_Email__c);
        System.assertEquals(managerAlice.Email__c, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(managerAlice.First_Name__c + ' ' + managerAlice.Last_Name__c, accountPlan.Owner_Manager_Name__c);

        Test.stopTest();
    }

    @isTest
    static void verifyAccountPlanTriggerHelperEnrichAccountPlanDataWhenNoManagerIsSetOnBeforeInsert() {
        User userJohn = createTestUser('Bob', 'Doe');
        Employee__c employeeJohn = createTestEmployee(userJohn, new Map<SObjectField, Object>{
            Employee__c.Team__c => ValueProviderBuilder.provideUniqueFixedLengthString('Team', 12),
            Employee__c.Division__c => ValueProviderBuilder.provideUniqueFixedLengthString('Division', 16)
        });

        Account_Plan__c accountPlan = (Account_Plan__c) new SObjectBuilder(Account_Plan__c.SObjectType)
            .setField(Account_Plan__c.OwnerId, userJohn.Id)
            .build()
            .getRecord();

        Test.startTest();

        System.assertEquals(null, accountPlan.Owner_Team__c);
        System.assertEquals(null, accountPlan.Owner_Division__c);
        System.assertEquals(null, accountPlan.Owner_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Name__c);

        insert accountPlan;

        accountPlan = getAccountPlan(accountPlan);

        System.assertEquals(employeeJohn.Team__c, accountPlan.Owner_Team__c);
        System.assertEquals(employeeJohn.Division__c, accountPlan.Owner_Division__c);
        System.assertEquals(employeeJohn.Email__c, accountPlan.Owner_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(null, accountPlan.Owner_Manager_Name__c);

        Test.stopTest();
    }

    @isTest
    static void verifyAccountPlanTriggerHelperEnrichAccountPlanDataOnBeforeUpdate() {
        User userAlice = createTestUser('Alice', 'Smith');
        Employee__c managerAlice = createTestEmployee(userAlice, new Map<SObjectField, Object>());

        User userJohn = createTestUser('Bob', 'Doe');
        Employee__c employeeJohn = createTestEmployee(userJohn, new Map<SObjectField, Object>{
            Employee__c.Manager_Employee_Number__c => managerAlice.Id,
            Employee__c.Team__c => ValueProviderBuilder.provideUniqueFixedLengthString('Team', 12),
            Employee__c.Division__c => ValueProviderBuilder.provideUniqueFixedLengthString('Division', 16)
        });

        Account_Plan__c accountPlan = (Account_Plan__c) new SObjectBuilder(Account_Plan__c.SObjectType)
            .setField(Account_Plan__c.OwnerId, userJohn.Id)
            .create()
            .getRecord();

        Test.startTest();

        accountPlan = getAccountPlan(accountPlan);

        System.assertEquals(employeeJohn.Team__c, accountPlan.Owner_Team__c);
        System.assertEquals(employeeJohn.Division__c, accountPlan.Owner_Division__c);
        System.assertEquals(employeeJohn.Email__c, accountPlan.Owner_Email__c);
        System.assertEquals(managerAlice.Email__c, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(managerAlice.First_Name__c + ' ' + managerAlice.Last_Name__c, accountPlan.Owner_Manager_Name__c);

        User userEve = createTestUser('Eve', 'Bond');
        Employee__c employeeEve = createTestEmployee(userEve, new Map<SObjectField, Object>{
            Employee__c.Manager_Employee_Number__c => managerAlice.Id,
            Employee__c.Team__c => ValueProviderBuilder.provideUniqueFixedLengthString('Team', 12),
            Employee__c.Division__c => ValueProviderBuilder.provideUniqueFixedLengthString('Division', 16)
        });

        accountPlan.OwnerId = userEve.Id;

        update accountPlan;

        accountPlan = getAccountPlan(accountPlan);

        System.assertEquals(employeeEve.Team__c, accountPlan.Owner_Team__c);
        System.assertEquals(employeeEve.Division__c, accountPlan.Owner_Division__c);
        System.assertEquals(employeeEve.Email__c, accountPlan.Owner_Email__c);
        System.assertEquals(managerAlice.Email__c, accountPlan.Owner_Manager_Email__c);
        System.assertEquals(managerAlice.First_Name__c + ' ' + managerAlice.Last_Name__c, accountPlan.Owner_Manager_Name__c);

        Test.stopTest();
    }
}