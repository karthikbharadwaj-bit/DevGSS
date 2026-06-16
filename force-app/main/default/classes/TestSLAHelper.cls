@IsTest
private class TestSLAHelper {

    @isTest
    static void test_loadSLAById() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        SLA__c sla = (SLA__c) new SObjectBuilder(SLA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                SLA__c.IsStandardSLA__c => false,
                SLA__c.Account__c => acc.Id,
                SLA__c.MinDowntime__c => 5,
                SLA__c.UnitSize__c => 0,
                SLA__c.MaxCredit__c => 40,
                SLA__c.ServiceType__c => 'CC Core',
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
            .getRecord();

        SLA__c received = SLAHelper.loadSLAById(sla.Id);

        System.assertEquals(sla.Id, received.Id);
        System.assertEquals(sla.IsStandardSLA__c, received.IsStandardSLA__c);
    }

    @isTest
    static void test_loadApproval() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                Approval__c.Account__c => acc.Id
            })
            .create()
            .getRecord();

        Approval__c received = SLAHelper.loadApproval(approval.Id);

        System.assertEquals(approval.Id, received.Id);
    }

    @isTest
    static void test_loadSLAByServiceTypeForAccount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        List<SLA__c> slaList = (List<SLA__c>) new SObjectBuilder(SLA__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLA__c.IsStandardSLA__c => false,
                SLA__c.Account__c => acc.Id,
                SLA__c.MinDowntime__c => 5,
                SLA__c.UnitSize__c => 0,
                SLA__c.MaxCredit__c => 40,
                SLA__c.ServiceType__c => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
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

        Map<String, SLA__c> slaByServiceTypeMap = SLAHelper.loadSLAByServiceTypeForAccount(acc.Id);

        System.assertEquals(new Set<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}, slaByServiceTypeMap.keySet());
        System.assertEquals(slaList.get(0).Id, slaByServiceTypeMap.get('RC Office').Id);
        System.assertEquals('RC Office', slaByServiceTypeMap.get('RC Office').ServiceType__c);

        System.assertEquals(slaList.get(1).Id, slaByServiceTypeMap.get('CC Core').Id);
        System.assertEquals('CC Core', slaByServiceTypeMap.get('CC Core').ServiceType__c);

        System.assertEquals(slaList.get(2).Id, slaByServiceTypeMap.get('CC Predictive Dialing').Id);
        System.assertEquals('CC Predictive Dialing', slaByServiceTypeMap.get('CC Predictive Dialing').ServiceType__c);

        System.assertEquals(slaList.get(3).Id, slaByServiceTypeMap.get('CC WFO').Id);
        System.assertEquals('CC WFO', slaByServiceTypeMap.get('CC WFO').ServiceType__c);

    }

    @isTest
    static void test_loadMultipleSLAsById() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        List<SLA__c> slaList = (List<SLA__c>) new SObjectBuilder(SLA__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLA__c.IsStandardSLA__c => false,
                SLA__c.Account__c => acc.Id,
                SLA__c.MinDowntime__c => 5,
                SLA__c.UnitSize__c => 0,
                SLA__c.MaxCredit__c => 40,
                SLA__c.ServiceType__c => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
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
        Set<Id> slaIds = new Set<Id>();
        for(SLA__c sla : slaList) {
            slaIds.add(sla.Id);
        }

        slaList = SLAHelper.loadMultipleSLAsById(slaIds);

        System.assertEquals(slaList.size(), 4);
    }

    @isTest
    static void test_getStandardSLA() {
        List<SLASettings__c> defaultSLAs = (List<SLASettings__c>) new SObjectBuilder(SLASettings__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLASettings__c.Name => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
                SLASettings__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal> { 40, 45, 50, 60 }),
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
                SLASettings__c.CreditCharts__c => ValueProviderBuilder.provideList(new List<String> {
                    '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30',
                    '99.990, 100.00, 0\n99.950, 99.989, 5\n99.9, 99.949, 10\n0.0, 99.899, 15',
                    '99.900, 100.0, 0\n99.000, 99.899, 5\n0, 98.999, 20',
                    '99.5, 100, 0\n99.0, 99.499, 5\n0, 98.999, 20'
                })
            })
            .create()
            .getRecords();

        SLAController.ServiceLevelAgreement slaWrapper = SLAHelper.getStandardSLA('RC Office');

        System.assertEquals(slaWrapper.serviceType, 'RC Office');

        slaWrapper = SLAHelper.getStandardSLA('Foobar');

        System.assertEquals(slaWrapper, null);
    }

    @isTest
    static void test_getStandardSLAsByServiceType() {
        List<SLASettings__c> defaultSLAs = (List<SLASettings__c>) new SObjectBuilder(SLASettings__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLASettings__c.Name => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
                SLASettings__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal> { 40, 45, 50, 60 }),
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
                SLASettings__c.CreditCharts__c => ValueProviderBuilder.provideList(new List<String> {
                    '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30',
                    '99.990, 100.00, 0\n99.950, 99.989, 5\n99.9, 99.949, 10\n0.0, 99.899, 15',
                    '99.900, 100.0, 0\n99.000, 99.899, 5\n0, 98.999, 20',
                    '99.5, 100, 0\n99.0, 99.499, 5\n0, 98.999, 20'
                })
            })
            .create()
            .getRecords();

        Map<String, SLAController.ServiceLevelAgreement> received = SLAHelper.getStandardSLAsByServiceType();

        System.assertEquals(new Set<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}, received.keySet());

        System.assertEquals(defaultSLAs.get(0).Name, received.get('RC Office').serviceType);
        System.assertEquals(defaultSLAs.get(1).Name, received.get('CC Core').serviceType);
        System.assertEquals(defaultSLAs.get(2).Name, received.get('CC Predictive Dialing').serviceType);
        System.assertEquals(defaultSLAs.get(3).Name, received.get('CC WFO').serviceType);
    }

    @isTest
    static void test_saveSLA() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        List<SLASettings__c> defaultSLAs = (List<SLASettings__c>) new SObjectBuilder(SLASettings__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLASettings__c.Name => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
                SLASettings__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal> { 40, 45, 50, 60 }),
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
                SLASettings__c.CreditCharts__c => ValueProviderBuilder.provideList(new List<String> {
                    '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30',
                    '99.990, 100.00, 0\n99.950, 99.989, 5\n99.9, 99.949, 10\n0.0, 99.899, 15',
                    '99.900, 100.0, 0\n99.000, 99.899, 5\n0, 98.999, 20',
                    '99.5, 100, 0\n99.0, 99.499, 5\n0, 98.999, 20'
                })
            })
            .create()
            .getRecords();
        SLASettings__c standardSLA = defaultSLAs.get(0);
        SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(standardSLA);
        slaWrapper.account = acc.Id;

        SLA__c sla = SLAHelper.saveSLA(slaWrapper);

        System.assertNotEquals(sla.Id, null);
        System.assertEquals(sla.ServiceType__c, 'RC Office');
        System.assertEquals(sla.MaxCredit__c, 40);
        System.assertEquals(sla.SLACreditCharts__r.size(), 5);
    }

    @isTest
    static void test_getSLAsByAccountIdByServiceType() {
        List<Account> acc = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> { 'Alice Smith', 'Bob Doe', 'Mary Jane'})
            })
            .create()
            .getRecords();
        List<Approval__c> approvals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id> { acc.get(0).Id, acc.get(1).Id, acc.get(2).Id })
            })
            .create()
            .getRecords();
        List<SLA__c> slas = (List<SLA__c>) new SObjectBuilder(SLA__c.SObjectType)
            .quantity(12)
            .setFields(new Map<SObjectField, Object> {
                SLA__c.IsStandardSLA__c => false,
                SLA__c.Account__c => ValueProviderBuilder.provideList(new List<Id> { acc.get(0).Id, acc.get(1).Id, acc.get(2).Id }),
                SLA__c.MinDowntime__c => 5,
                SLA__c.UnitSize__c => 0,
                SLA__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal> { 30, 35, 40, 45, 30, 35, 40, 45, 30, 35, 40, 45}),
                SLA__c.ServiceType__c => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO', 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO', 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
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

        Map<Id, Map<String, SLA__c>> slaMap = SLAHelper.getSLAsByAccountIdByServiceType(approvals);

        System.assertEquals(slaMap.containsKey(acc.get(0).Id), true);
        System.assertEquals(slaMap.get(acc.get(0).Id).containsKey('RC Office'), true);
        System.assertEquals(slaMap.get(acc.get(0).Id).containsKey('CC Core'), true);
        System.assertEquals(slaMap.get(acc.get(0).Id).containsKey('CC Predictive Dialing'), true);
        System.assertEquals(slaMap.get(acc.get(0).Id).containsKey('CC WFO'), true);
        System.assertEquals(slaMap.get(acc.get(0).Id).get('RC Office').ServiceType__c, 'RC Office');
        System.assertEquals(slaMap.get(acc.get(0).Id).get('RC Office').Account__c, acc.get(0).Id);
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC Core').ServiceType__c, 'CC Core');
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC Core').Account__c, acc.get(0).Id);
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC Predictive Dialing').ServiceType__c, 'CC Predictive Dialing');
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC Predictive Dialing').Account__c, acc.get(0).Id);
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC WFO').ServiceType__c, 'CC WFO');
        System.assertEquals(slaMap.get(acc.get(0).Id).get('CC WFO').Account__c, acc.get(0).Id);

        System.assertEquals(slaMap.containsKey(acc.get(1).Id), true);
        System.assertEquals(slaMap.get(acc.get(1).Id).containsKey('RC Office'), true);
        System.assertEquals(slaMap.get(acc.get(1).Id).containsKey('CC Core'), true);
        System.assertEquals(slaMap.get(acc.get(1).Id).containsKey('CC Predictive Dialing'), true);
        System.assertEquals(slaMap.get(acc.get(1).Id).containsKey('CC WFO'), true);
        System.assertEquals(slaMap.get(acc.get(1).Id).get('RC Office').ServiceType__c, 'RC Office');
        System.assertEquals(slaMap.get(acc.get(1).Id).get('RC Office').Account__c, acc.get(1).Id);
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC Core').ServiceType__c, 'CC Core');
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC Core').Account__c, acc.get(1).Id);
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC Predictive Dialing').ServiceType__c, 'CC Predictive Dialing');
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC Predictive Dialing').Account__c, acc.get(1).Id);
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC WFO').ServiceType__c, 'CC WFO');
        System.assertEquals(slaMap.get(acc.get(1).Id).get('CC WFO').Account__c, acc.get(1).Id);

        System.assertEquals(slaMap.containsKey(acc.get(2).Id), true);
        System.assertEquals(slaMap.get(acc.get(2).Id).containsKey('RC Office'), true);
        System.assertEquals(slaMap.get(acc.get(2).Id).containsKey('CC Core'), true);
        System.assertEquals(slaMap.get(acc.get(2).Id).containsKey('CC Predictive Dialing'), true);
        System.assertEquals(slaMap.get(acc.get(2).Id).containsKey('CC WFO'), true);
        System.assertEquals(slaMap.get(acc.get(2).Id).get('RC Office').ServiceType__c, 'RC Office');
        System.assertEquals(slaMap.get(acc.get(2).Id).get('RC Office').Account__c, acc.get(2).Id);
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC Core').ServiceType__c, 'CC Core');
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC Core').Account__c, acc.get(2).Id);
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC Predictive Dialing').ServiceType__c, 'CC Predictive Dialing');
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC Predictive Dialing').Account__c, acc.get(2).Id);
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC WFO').ServiceType__c, 'CC WFO');
        System.assertEquals(slaMap.get(acc.get(2).Id).get('CC WFO').Account__c, acc.get(2).Id);
    }

    @isTest
    static void test_saveMultipleSLAs() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'John Doe'
            })
            .create()
            .getRecord();
        List<SLASettings__c> defaultSLAs = (List<SLASettings__c>) new SObjectBuilder(SLASettings__c.SObjectType)
            .quantity(4)
            .setFields(new Map<SObjectField, Object> {
                SLASettings__c.Name => ValueProviderBuilder.provideList(new List<String> { 'RC Office', 'CC Core', 'CC Predictive Dialing', 'CC WFO'}),
                SLASettings__c.MaxCredit__c => ValueProviderBuilder.provideList(new List<Decimal> { 40, 45, 50, 60 }),
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
                SLASettings__c.CreditCharts__c => ValueProviderBuilder.provideList(new List<String> {
                    '99.999, 100.000, 0\n99.5, 99.998, 5\n99.0, 99.499, 10\n95.0, 98.999, 20\n0, 94.999, 30',
                    '99.990, 100.00, 0\n99.950, 99.989, 5\n99.9, 99.949, 10\n0.0, 99.899, 15',
                    '99.900, 100.0, 0\n99.000, 99.899, 5\n0, 98.999, 20',
                    '99.5, 100, 0\n99.0, 99.499, 5\n0, 98.999, 20'
                })
            })
            .create()
            .getRecords();

        List<SLAController.ServiceLevelAgreement> slaWrapperList = new List<SLAController.ServiceLevelAgreement>();
        for(SLASettings__c defaultSLA : defaultSLAs) {
            SLAController.ServiceLevelAgreement slaWrapper = new SLAController.ServiceLevelAgreement(defaultSLA);

            slaWrapper.account = acc.Id;

            slaWrapperList.add(slaWrapper);
        }

        List<SLA__c> savedSLAs = SLAHelper.saveMultipleSLAs(slaWrapperList);

        System.assertEquals(savedSLAs.size(), 4);

        System.assertEquals(savedSLAs.get(0).ServiceType__c, 'RC Office');
        System.assertEquals(savedSLAs.get(0).MaxCredit__c, 40);
        System.assertEquals(savedSLAs.get(0).SLACreditCharts__r.size(), 5);

        System.assertEquals(savedSLAs.get(1).ServiceType__c, 'CC Core');
        System.assertEquals(savedSLAs.get(1).MaxCredit__c, 45);
        System.assertEquals(savedSLAs.get(1).SLACreditCharts__r.size(), 4);

        System.assertEquals(savedSLAs.get(2).ServiceType__c, 'CC Predictive Dialing');
        System.assertEquals(savedSLAs.get(2).MaxCredit__c, 50);
        System.assertEquals(savedSLAs.get(2).SLACreditCharts__r.size(), 3);

        System.assertEquals(savedSLAs.get(3).ServiceType__c, 'CC WFO');
        System.assertEquals(savedSLAs.get(3).MaxCredit__c, 60);
        System.assertEquals(savedSLAs.get(3).SLACreditCharts__r.size(), 3);

        slaWrapperList.get(0).id = savedSLAs.get(0).Id;
        slaWrapperList.get(1).id = savedSLAs.get(1).Id;
        slaWrapperList.get(2).id = savedSLAs.get(2).Id;
        slaWrapperList.get(3).id = savedSLAs.get(3).Id;

        savedSLAs = SLAHelper.saveMultipleSLAs(slaWrapperList);

        System.assertEquals(savedSLAs.size(), 4);
    }
}