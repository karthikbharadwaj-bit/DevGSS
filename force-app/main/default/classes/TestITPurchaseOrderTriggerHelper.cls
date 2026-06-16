@isTest
public class TestITPurchaseOrderTriggerHelper{
    @testSetup
    static void createData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Employee__c emp = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Employee__c.First_Name__c => 'FirstName',
                    Employee__c.Last_Name__c => 'LastName',
                    Employee__c.Email__c => 'veryRandomSuch@Email123.com',
                    Employee__c.Location__c => 'San Mateo, US',
                    Employee__c.Department__c => 'Business Development',
                    Employee__c.Division__c => 'Sales - Development Bay',
                    Employee__c.Team__c => 'Sales - AT&T Initials'
                }
            )
            .create()
            .getRecord();     
        Contact initialCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'first@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Employee__c => emp.Id
                }
            )
            .build()
            .getRecord();
        Contact nextCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .build()
            .getRecord();
        insert new List<Contact>{initialCon,nextCon};
        IT_Purchase_Order__c itpo = (IT_Purchase_Order__c) new SObjectBuilder(IT_Purchase_Order__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    IT_Purchase_Order__c.End_User_Contact__c => initialCon.Id,
                    IT_Purchase_Order__c.Status__c => '1. New Request',
                    IT_Purchase_Order__c.Category__c => 'New Hire',
                    IT_Purchase_Order__c.Recurring__c => 'No'
                }
            )
            .create()
            .getRecord();

        itpo.Location__c = 'Manila';
        itpo.Department__c = '110 - Gateway';
        update itpo;
        
    }

    @isTest
    static void testChangeContact() {
        IT_Purchase_Order__c itpo = [SELECT Id 
                                    FROM IT_Purchase_Order__c 
                                    LIMIT 1];
        Contact con = [SELECT Id
                        FROM Contact 
                        WHERE Email = 'test@test.com' 
                        LIMIT 1];

        Test.startTest();
        itpo.End_User_Contact__c = con.Id;
        update itpo;
        Test.stopTest();

        IT_Purchase_Order__c updatedItpo = [SELECT Id, Location__c, Department__c 
                                            FROM IT_Purchase_Order__c 
                                            LIMIT 1];

        System.assertEquals(null, updatedItpo.Location__c, 'Location field should be empty');
        System.assertEquals(null, updatedItpo.Department__c, 'Department field should be empty');
    }

    @isTest
    static void testChangeMiscellaniousValue() {
        IT_Purchase_Order__c itpo = [SELECT Id, Vendor__c, Location__c, Department__c 
                                    FROM IT_Purchase_Order__c 
                                    LIMIT 1];

        Test.startTest();
        itpo.Vendor__c = 'test vendor';
        update itpo;
        Test.stopTest();

        IT_Purchase_Order__c updatedItpo = [SELECT Id, Location__c, Department__c 
                                            FROM IT_Purchase_Order__c 
                                            LIMIT 1];

        System.assertEquals('Manila', updatedItpo.Location__c, 'Location field should not be changed');
        System.assertEquals('110 - Gateway', updatedItpo.Department__c, 'Department field should not be changed');
    }
}