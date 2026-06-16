@IsTest
private class TestSLAController {
    @testSetup
    static void setup() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                Approval__c.Account__c => acc.Id
            })
            .create()
            .getRecord();
        List<SLASettings__c> defaultSLAs = (List<SLASettings__c>) new SObjectBuilder(SLASettings__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object>{
                SLASettings__c.Name => ValueProviderBuilder.provideList(new List<String>{
                    'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'
                }),
                SLASettings__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal>{
                    40, 45, 50, 60
                }),
                SLASettings__c.UnitSize__c => 0,
                SLASettings__c.MinDowntime__c => 0,
                SLASettings__c.AvailabilityUnits__c => 'Users',
                SLASettings__c.CalculationFormula__c => '[]',
                SLASettings__c.Trigger__c => 'Availability %',
                SLASettings__c.TriggerRelation__c => 'Less Than',
                SLASettings__c.TriggerValue__c => 90,
                SLASettings__c.TriggerFormula__c => '',
                SLASettings__c.StrikeCount__c => 3,
                SLASettings__c.StrikePeriod__c => 5,
                SLASettings__c.StrikeValue__c => 80,
                SLASettings__c.CreditCharts__c => ValueProviderBuilder.provideList(new List<String>{
                    '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30',
                    '99.990, 100.00, 0\n99.950, 99.989, 5\n99.9, 99.949, 10\n0.0, 99.899, 15',
                    '99.900, 100.0, 0\n99.000, 99.899, 5\n0, 98.999, 20',
                    '99.5, 100, 0\n99.0, 99.499, 5\n0, 98.999, 20'
                })
            })
            .create()
            .getRecords();
        List<SLA__c> slaList = (List<SLA__c>) new SObjectBuilder(SLA__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object>{
                SLA__c.IsStandardSLA__c => false,
                SLA__c.Account__c => acc.Id,
                SLA__c.MinDowntime__c => 5,
                SLA__c.UnitSize__c => 0,
                SLA__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal>{
                    40, 45, 50, 60
                }),
                SLA__c.ServiceType__c => ValueProviderBuilder.provideList(new List<String>{
                    'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'
                }),
                SLA__c.AvailabilityUnits__c => 'Users',
                SLA__c.CalculationFormula__c => '[]',
                SLA__c.Trigger__c => 'Availability %',
                SLA__c.TriggerRelation__c => 'Less Than',
                SLA__c.TriggerValue__c => 95,
                SLA__c.TriggerFormula__c => '',
                SLA__c.StrikeCount__c => 5,
                SLA__c.StrikePeriod__c => 10,
                SLA__c.StrikeValue__c => 95.5
            })
            .create()
            .getRecords();
    }

    @isTest
    static void test_getSLAById() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);
        List<SLA__c> slaList = (List<SLA__c>) new SLASelector()
            .selectSLAsForAccount(new List<Object>{
                account.Id
            })
            .executeQuery();

        Test.startTest();

        Response res = SLAController.getSLAById(slaList.get(0).Id);

        Test.stopTest();

        System.assertNotEquals(res, null);
        System.assertNotEquals(res.data.isEmpty(), true);

        SLA__c record = (SLA__c) res.data.get('record');
        System.assertNotEquals(record, null);
        System.assertEquals(record.Id, slaList.get(0).Id);
        System.assertEquals(record.ServiceType__c, 'RC Office');
        System.assertEquals(record.MaxCredit__c, 40);
        System.assertEquals(record.SLACreditCharts__r.size(), 0);
        System.debug(record);

        Account resAcc = (Account) res.data.get('account');
        System.assertNotEquals(resAcc, null);
        System.assertEquals(resAcc.Name, account.Name);
        System.assertEquals(resAcc.Id, account.Id);
        System.debug(resAcc);

        Map<String, SLAController.ServiceLevelAgreement> resDefaultSLAs = (Map<String, SLAController.ServiceLevelAgreement>) res.data.get('standardSLAs');
        System.assertNotEquals(resDefaultSLAs, null);
        System.assertEquals(resDefaultSLAs.containsKey('RC Office'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC Core'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC Predictive Dialing'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC WFO'), true);
        System.debug(resDefaultSLAs);

        Map<String, SLA__c> resAccountSLAs = (Map<String, SLA__c>) res.data.get('existingSLAs');
        System.assertNotEquals(resAccountSLAs, null);
        System.assertEquals(resAccountSLAs.containsKey('RC Office'), true);
        System.assertEquals(resAccountSLAs.containsKey('CC Core'), true);
        System.assertEquals(resAccountSLAs.containsKey('CC Predictive Dialing'), true);
        System.assertEquals(resAccountSLAs.containsKey('CC WFO'), true);
        System.debug(resAccountSLAs);
    }

    @isTest
    static void test_getSLAById_withNonExistingSLA() {
        Response res = SLAController.getSLAById((Id) ValueProviderBuilder.provideDummyId(SLA__c.SObjectType).getValue());
        System.assertEquals(res.data.get('record'), null);
    }

    @isTest
    static void test_getApprovalInfo() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);
        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectApprovalsForAccount(new List<Object>{
                new Set<Id>{account.Id}
            })
            .executeQuery()
            .get(0);
        List<SLA__c> slaList = (List<SLA__c>) new SLASelector()
            .selectSLAsForAccount(new List<Object>{
                account.Id
            })
            .executeQuery();
        Test.startTest();

        Response res = SLAController.getApprovalInfo(approval.Id);

        Test.stopTest();

        System.assertNotEquals(res, null);
        System.assertNotEquals(res.data.isEmpty(), true);

        Approval__c resApproval = (Approval__c) res.data.get('approval');
        System.assertNotEquals(resApproval, null);
        System.assertEquals(resApproval.Id, approval.Id);
        System.debug(resApproval);

        Account resAccount = (Account) res.data.get('account');
        System.assertNotEquals(resAccount, null);
        System.assertEquals(resAccount.Name, account.Name);
        System.assertEquals(resAccount.Id, account.Id);
        System.debug(resAccount);

        Map<String, SLAController.ServiceLevelAgreement> resDefaultSLAs = (Map<String, SLAController.ServiceLevelAgreement>) res.data.get('standardSLAs');
        System.assertNotEquals(resDefaultSLAs, null);
        System.assertEquals(resDefaultSLAs.containsKey('RC Office'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC Core'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC Predictive Dialing'), true);
        System.assertEquals(resDefaultSLAs.containsKey('CC WFO'), true);
        System.debug(resDefaultSLAs);

        Map<String, SLA__c> resAccountSLAs = (Map<String, SLA__c>) res.data.get('existingSLAs');
        System.assertNotEquals(resAccountSLAs, null);
        System.assertEquals(resAccountSLAs.containsKey('RC Office'), true);
        System.assertEquals(resAccountSLAs.get('RC Office').Account__c, slaList.get(0).Account__c);
        System.assertEquals(resAccountSLAs.get('RC Office').ServiceType__c, slaList.get(0).ServiceType__c);
        System.assertEquals(resAccountSLAs.containsKey('CC Core'), true);
        System.assertEquals(resAccountSLAs.get('CC Core').Account__c, slaList.get(1).Account__c);
        System.assertEquals(resAccountSLAs.get('CC Core').ServiceType__c, slaList.get(1).ServiceType__c);
        System.assertEquals(resAccountSLAs.containsKey('CC Predictive Dialing'), true);
        System.assertEquals(resAccountSLAs.get('CC Predictive Dialing').Account__c, slaList.get(2).Account__c);
        System.assertEquals(resAccountSLAs.get('CC Predictive Dialing').ServiceType__c, slaList.get(2).ServiceType__c);
        System.assertEquals(resAccountSLAs.containsKey('CC WFO'), true);
        System.assertEquals(resAccountSLAs.get('CC WFO').Account__c, slaList.get(3).Account__c);
        System.assertEquals(resAccountSLAs.get('CC WFO').ServiceType__c, slaList.get(3).ServiceType__c);
        System.debug(resAccountSLAs);
    }

    @isTest
    static void test_saveSLA() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);

        SLASettings__c defaultSLA = SLASettings__c.getInstance('RC Office');
        defaultSLA.CreditCharts__c = '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30';
        update defaultSLA;

        Exception error = null;
        Test.startTest();

        SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(defaultSLA, account);
        Response res = SLAController.saveSLA(JSON.serialize(slaWrapper));

        Test.stopTest();

        System.assertNotEquals(res, null);
        System.assertNotEquals(res.data.isEmpty(), true);

        SLA__c record = (SLA__c) res.data.get('record');
        System.assertNotEquals(record.Id, null);
        System.assertEquals(record.ServiceType__c, 'RC Office');
        System.assertEquals(record.MaxCredit__c, 40);
        System.assertEquals(record.SLACreditCharts__r.size(), 5);
    }

    @isTest
    static void test_saveSLA_withNullCreditCharts() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);

        SLASettings__c defaultSLA = SLASettings__c.getInstance('RC Office');
        defaultSLA.CreditCharts__c = null;
        update defaultSLA;

        Test.startTest();
        SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(defaultSLA, account);
        Response res = SLAController.saveSLA(JSON.serialize(slaWrapper));
        Test.stopTest();

        System.assertNotEquals(res, null);
        System.assertNotEquals(res.data.isEmpty(), true);

        SLA__c record = (SLA__c) res.data.get('record');
        System.assertNotEquals(record.Id, null);
        System.assertEquals(record.ServiceType__c, 'RC Office');
        System.assertEquals(record.MaxCredit__c, 40);
        System.assertEquals(record.SLACreditCharts__r.size(), 0);
    }

    @isTest
    static void test_saveSLA_withEmptyCreditCharts() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);
        Exception error = null;

        SLASettings__c defaultSLA = SLASettings__c.getInstance('RC Office');
        defaultSLA.CreditCharts__c = '';
        update defaultSLA;

        Response res = null;
        Test.startTest();
        try {
            SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(defaultSLA, account);
            res = SLAController.saveSLA(JSON.serialize(slaWrapper));

            System.assert(false);
        } catch (Exception e) {
            error = e;
        }
        Test.stopTest();

        System.assertEquals(res, null);
        System.assertNotEquals(error, null);
    }

    @isTest
    static void test_saveSLA_withMalformedCreditCharts() {
        Account account = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{
                'John Doe'
            })
            .executeQuery()
            .get(0);
        Exception error = null;

        SLASettings__c defaultSLA = SLASettings__c.getInstance('RC Office');
        defaultSLA.CreditCharts__c = '99.900, 100.0\n99.000, 99.899, 5\n0, 98.999, 20';
        update defaultSLA;

        Response res = null;
        Test.startTest();
        try {
            SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(defaultSLA, account);
            res = SLAController.saveSLA(JSON.serialize(slaWrapper));

            System.assert(false);
        } catch (Exception e) {
            error = e;
        }
        Test.stopTest();

        System.assertEquals(res, null);
        System.assertNotEquals(error, null);
    }
}