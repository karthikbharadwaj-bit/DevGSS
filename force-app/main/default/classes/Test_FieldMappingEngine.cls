@isTest
private class Test_FieldMappingEngine {
    
    private static String TEST_PROCESS = 'TEST_PROCESS';
    private static Schema.SObjectType ACCOUNT_API_NAME = Schema.Account.getSObjectType();
    private static Schema.SObjectType CONTACT_API_NAME = Schema.Contact.getSObjectType();
    private static String DEMAND_FUNNEL_FIELD_API_INCORRECT_OBJECT = 'Accounts.Name';
    private static String DEMAND_FUNNEL_FIELD_API_INCORRECT_FIELD = 'Account.Namess';
    private static String DEMAND_FUNNEL_FIELD_API_INCORRECT_FORMAT = 'Name';
    private static String DEMAND_FUNNEL_FIELD_API_STANDARD_OBJECT = 'Account.Name';
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_STANDARD_FIELD = Account.Name.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_TEXT = Account.Description.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_NUMBER = Account.AccountNumber.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_CHECKBOX = Account.IsPartner.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_ID = Account.LastModifiedByid.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_CURRENCY = Account.AnnualRevenue.getDescribe();
    private static Schema.DescribeFieldResult CONTACT_BIRTHDATE_FIELD = Contact.Birthdate.getDescribe();
    private static Schema.DescribeFieldResult CONTACT_LASTCUREQUESTDATE_FIELD = Contact.LastCURequestDate.getDescribe();
    private static Schema.DescribeFieldResult DEMAND_FUNNEL_FIELD_API_PICKLIST = Account.AccountSource.getDescribe();
    private static String FIELD_NAME = 'Name'.toLowerCase();
    private static String OBJECT_NAME = 'Account'.toLowerCase();
    private static final String RT_NAME_CUSTOMER_ACCOUNT = 'Customer Account';
    private static final String RT_DEV_NAME_CUSTOMER_ACCOUNT = 'Customer_Account';
    private static final Id RT_ID_CUSTOMER_ACCOUNT = Account.SObjectType.getDescribe()
                                                .getRecordTypeInfosByName()
                                                .get(RT_NAME_CUSTOMER_ACCOUNT).getRecordTypeId();
    private static String SYSTEM_PROF_ADMIN = 'System Administrator';
    private static final String FIELD_TO_FIELD  = 'FIELD TO FIELD';
    private static final String STRING_TO_FIELD  = 'STRING TO FIELD';
    private static final String BOOLEAN_TO_FIELD  = 'BOOLEAN TO FIELD';

    private static Account setupAccount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test')
            .setField(Account.AccountSource, 'Data.com')            
            .setField(Account.RecordTypeId, RT_ID_CUSTOMER_ACCOUNT)
            .create()
            .getRecord();
        return acc;
    }
    private static Account setupAccountWithOutRecordType() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test')
            .setField(Account.AccountSource, 'Data.com')            
            .create()
            .getRecord();
        return acc;
    }
    private static Contact setupContact() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.LeadSource, 'Developer Platform')
            .setField(Contact.Department, 'Department1')
            .setField(Contact.Time_Frame__c, 'Less than 1 month')
            .setField(Contact.Demographic_Score__c, 10)
            .setField(Contact.Behavior_Score__c, 20)   
            .setField(Contact.BMID__c, '123')  
            .setField(Contact.PID__c, '456')
            .setField(Contact.AID__c, '789')
            .setField(Contact.Lead_Entry_Source__c, 'Demo Page')
            .setField(Contact.Most_Recent_Campaign__c, setupCampaign().Id)
            .create()
            .getRecord();

        return con;
    }

    private static Lead setupLead() {
        Lead l = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.FirstName, 'John')
            .setField(Lead.LastName, 'Doe')
            .setField(Lead.Email, 'test@test.com')
            .setField(Lead.LeadSource, 'Developer Platform')
            .setField(Lead.Time_Frame__c, 'Less than 1 month')
            .setField(Lead.Demographic_Score__c, 10)
            .setField(Lead.Behavior_Score__c, 20)   
            .setField(Lead.BMID__c, '123')  
            .setField(Lead.PID__c, '456')
            .setField(Lead.AID__c, '789')
            .setField(Lead.Lead_Entry_Source__c, 'Demo Page')
            .setField(Lead.Most_Recent_Campaign__c, setupCampaign().Id)
            .create()
            .getRecord();

        return l;
    }
    private static Campaign setupCampaign() {
        Campaign c = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Test')
            .create()
            .getRecord();

        return c;
    }

    private static INVOCA_FOR_SF__Invoca_Call_Log__c setupInvoca(){
        return (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, 'test3:d')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_29__c, '100.24')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_25__c, '200')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_26__c, '10000.01')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_27__c, 'incorrect format')
            .create()
            .getRecord();
    }

    @isTest
    static void verifyLeadMappingFromInvoca() {
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = setupInvoca();
        Lead ld = new Lead();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('assignInvocaValues', invocaRecord, ld);
        mapp.processFieldsMappings();
        Test.stopTest();

        System.assertEquals(Decimal.valueOf(invocaRecord.INVOCA_FOR_SF__Customer_String_Value_29__c), ld.LTV__c, 'Incorrect mapping');
        System.assertEquals(null, ld.Recurring_Sales_Price__c, 'Incorrect mapping');
        System.assertEquals(Decimal.valueOf(invocaRecord.INVOCA_FOR_SF__Customer_String_Value_26__c), ld.Total_Sales_Price__c, 'Incorrect mapping');
        System.assertEquals(Decimal.valueOf(invocaRecord.INVOCA_FOR_SF__Customer_String_Value_25__c), ld.Number_Of_Lines__c, 'Incorrect mapping');

    }

    @isTest
    static void verifyEOLMasterMappingFromContact () {
        Contact con = setupContact();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('EOLMasterMappingFromContact', con, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(con.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }


    @isTest
    static void verifyEOLMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('EOLMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyMQLBackfillMapping () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('MQLBackfillMapping', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyMQLMasterMappingFromContact () {
        Contact con = setupContact();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('MQLMasterMappingFromContact', con, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(con.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyMQLMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('MQLMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyOnCreationMapping () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('OnCreationMapping', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyProspectBackfillMapping () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('ProspectBackfillMapping', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyProspectMasterMappingFromContact () {
        Contact con = setupContact();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('ProspectMasterMappingFromContact', con, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(con.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyProspectMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('ProspectMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifySALBackfillMapping () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('SALBackfillMapping', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifySALMasterMappingFromContact () {
        Contact con = setupContact();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('SALMasterMappingFromContact', con, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(con.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifySALMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('SALMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifySQLMasterMappingFromContact () {
        Contact con = setupContact();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('SQLMasterMappingFromContact', con, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(con.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifySQLMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('SQLMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyTALMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('TALMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyTQLMasterMappingFromLead () {
        Lead ld = setupLead();
        Demand_Funnel__c dfr = new Demand_Funnel__c();
        Test.startTest();
        FieldMappingEngine mapp = new FieldMappingEngine('TQLMasterMappingFromLead', ld, dfr);
        mapp.processFieldsMappings();
        Test.stopTest();
        for(Fields_Mapping__mdt fieldMapp : mapp.getFieldsMapping().values()) {
            if(fieldMapp.Type_of_Mapping__c == FIELD_TO_FIELD) {
                System.assertEquals(ld.get(FieldMappingEngine.getFieldString(fieldMapp.Source__c)), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == STRING_TO_FIELD) {
                System.assertEquals(fieldMapp.Source__c, dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            } else if(fieldMapp.Type_of_Mapping__c == BOOLEAN_TO_FIELD) {
                System.assertEquals(Boolean.valueOf(fieldMapp.Source__c), dfr.get(FieldMappingEngine.getFieldString(fieldMapp.Target_Field__c)));
            }
        }
    }

    @isTest
    static void verifyFieldMappingEngine() {
        Account acc = setupAccount();
        Contact con = setupContact();
        Test.startTest();
        FieldMappingEngine fieldMapp = new FieldMappingEngine(TEST_PROCESS, con, acc, 'ALL');
        Test.stopTest();
        System.assertEquals(TEST_PROCESS, fieldMapp.process, 'Process incorrect.');
        System.assertEquals(FieldMappingEngine.STRING_ALL, fieldMapp.profileName, 'Profile incorrect.');
        System.assertEquals(
            FieldMappingEngine.getRecordTypeName(acc),
            fieldMapp.recordTypeName,
            'recordTypeName incorrect.'
        );
        System.assertEquals(
            FieldMappingEngine.getRecordTypeDeveloperName(acc),
            fieldMapp.recordTypeDeveloperName,
            'recordTypeDeveloperName incorrect.'
        );
        System.assertEquals(con, fieldMapp.sourceObject, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(con.getSObjectType(), fieldMapp.sourceObjectType, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(acc, fieldMapp.targetObject, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(acc.getSObjectType(), fieldMapp.targetObjectType, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(5, fieldMapp.validFieldMappings.size(), 'validFieldMappings incorrect.');
    } 
    @isTest
    static void verifyFieldMappingEngineProfile() {
        Account acc = setupAccount();
        Contact con = setupContact();
        Test.startTest();
        FieldMappingEngine fieldMapp = new FieldMappingEngine(TEST_PROCESS, con, acc, SYSTEM_PROF_ADMIN);
        Test.stopTest();
        System.assertEquals(TEST_PROCESS, fieldMapp.process, 'Process incorrect.');
        System.assertEquals(SYSTEM_PROF_ADMIN, fieldMapp.profileName, 'Profile incorrect.');
        System.assertEquals(
            FieldMappingEngine.getRecordTypeName(acc),
            fieldMapp.recordTypeName,
            'recordTypeName incorrect.'
        );
        System.assertEquals(
            FieldMappingEngine.getRecordTypeDeveloperName(acc),
            fieldMapp.recordTypeDeveloperName,
            'recordTypeDeveloperName incorrect.'
        );
        System.assertEquals(con, fieldMapp.sourceObject, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(con.getSObjectType(), fieldMapp.sourceObjectType, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(acc, fieldMapp.targetObject, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(acc.getSObjectType(), fieldMapp.targetObjectType, 'recordTypeDeveloperName incorrect.');
        System.assertEquals(5, fieldMapp.validFieldMappings.size(), 'validFieldMappings incorrect.');
    } 
    @isTest
    static void verifygetValidFieldsMapping() {
        Account acc = setupAccount();
        Contact con = setupContact();
        Test.startTest();
        FieldMappingEngine fieldMapp = new FieldMappingEngine(TEST_PROCESS, con, acc);
        Test.stopTest();
        System.assertEquals(
            fieldMapp.validFieldMappings.size(),
            fieldMapp.getValidFieldsMapping().size(),
            'getValidFieldsMapping incorrect.'
        );
    }
    @isTest
    static void verifyprocessFieldsMappings() {
        Account acc = setupAccount();
        Contact con = setupContact();
        Test.startTest();
        FieldMappingEngine fieldMapp = new FieldMappingEngine(TEST_PROCESS, con, acc);
        fieldMapp.processFieldsMappings();
        Test.stopTest();
        System.assertEquals(con.Name, acc.Name, 'getValidFieldsMapping incorrect.');
        System.assertEquals(con.LeadSource, acc.AccountSource, 'getValidFieldsMapping incorrect.');
    }
    @isTest
    static void verifyhasRecordType() {
        System.assertEquals(
            TRUE,
            FieldMappingEngine.hasRecordType(setupAccount()),
            'The Record has not RecordType'
        );
    }
    @isTest
    static void verifyhasNotRecordType() {
        System.assertEquals(
            FALSE,
            FieldMappingEngine.hasRecordType(setupAccountWithOutRecordType()),
            'The Record has RecordType'
        );
    }
    @isTest
    static void verifygetRecordTypeName() {
        System.assertEquals(
            RT_NAME_CUSTOMER_ACCOUNT,
            FieldMappingEngine.getRecordTypeName(setupAccount()),
            'The Record Type Name is incorrect'
        );
    }
    @isTest
    static void verifygetRecordTypeNameAll() {
        System.assertEquals(
            FieldMappingEngine.STRING_ALL,
            FieldMappingEngine.getRecordTypeName(setupAccountWithOutRecordType()),
            'The Record Type Name is incorrect'
        );
    }
    @isTest
    static void verifygetRecordTypeDeveloperName() {
        System.assertEquals(
            RT_DEV_NAME_CUSTOMER_ACCOUNT,
            FieldMappingEngine.getRecordTypeDeveloperName(setupAccount()),
            'The Record Type Name is incorrect'
        );
    }
    @isTest
    static void verifygetRecordTypeDeveloperNameAll() {
        System.assertEquals(
            FieldMappingEngine.STRING_ALL,
            FieldMappingEngine.getRecordTypeDeveloperName(setupAccountWithOutRecordType()),
            'The Record Type Name is incorrect'
        );
    }
    @isTest
    static void verifygetObjectString() {
        System.assertEquals(
            OBJECT_NAME,
            FieldMappingEngine.getObjectString(DEMAND_FUNNEL_FIELD_API_STANDARD_OBJECT),
            'The Object Name is incorrect'
        );
    }
    @isTest
    static void verifygetFieldString() {
        System.assertEquals(
            FIELD_NAME,
            FieldMappingEngine.getFieldString(DEMAND_FUNNEL_FIELD_API_STANDARD_OBJECT),
            'The Field Name is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthStandard() {        
        System.assertEquals(
            Account.Name.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_STANDARD_FIELD),
            'The FieldLength for Standard Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthText() {        
        System.assertEquals(
            Account.Description.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_TEXT),
            'The FieldLength for Text Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthNumber() {        
        System.assertEquals(
            Account.AccountNumber.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_NUMBER),
            'The FieldLength for Number Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthCheckbox() {        
        System.assertEquals(
            Account.IsPartner.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_CHECKBOX),
            'The FieldLength for Checkbox Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthId() {        
        System.assertEquals(
            Account.LastModifiedByid.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_ID),
            'The FieldLength for Id Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthCurrency() {        
        System.assertEquals(            
            Account.AnnualRevenue.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_CURRENCY),
            'The FieldLength for Currency Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthDate() {        
        System.assertEquals(
            Contact.Birthdate.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(Contact_Birthdate_Field),
            'The FieldLength for Date Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthDateTime() {        
        System.assertEquals(
            Contact.LastCURequestDate.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(Contact_LastCURequestDate_Field),
            'The FieldLength for DateTime Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldLengthPicklist() {        
        System.assertEquals(            
            Account.AccountSource.getDescribe().getLength(),
            FieldMappingEngine.getFieldLength(DEMAND_FUNNEL_FIELD_API_PICKLIST),
            'The FieldLength for Picklist Field is incorrect'
        );
    }
    @isTest
    static void verifygetFieldType() {
        System.assertEquals(
            Account.Name.getDescribe().getType(),
            FieldMappingEngine.getFieldType(DEMAND_FUNNEL_FIELD_API_STANDARD_FIELD),
            'The FieldType is incorrect'
        );
    }
    @isTest
    static void verifygetObjectType() {
        System.assertEquals(
            Account.SObjectType,
            FieldMappingEngine.getObjectType(DEMAND_FUNNEL_FIELD_API_STANDARD_OBJECT),
            'The ObjectType is incorrect'
        );
    }
}