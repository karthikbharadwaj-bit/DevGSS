@IsTest
public class Test_QtcMetricsController {
    @testSetup
    static void setup() {

        QTC_Metrics_Settings__c qtcSettings = new QTC_Metrics_Settings__c(CaseOriginsForCreateACase__c = 'Account,Opportunity');
        insert qtcSettings;

        System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR)) {

            Triggers.switchOff();

            Account acc = TestDataGenerator.createAccount('Test Account');
            Opportunity opp = TestDataGenerator.createOpportunity(acc);
            
            Quote qt = TestDataGenerator.createActiveAgreement(opp);
            qt.isPrimary__c = true;
            update qt;

            opp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL;
            opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;
            opp.RecordTypeId = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY;
            opp.CPQ_Opportunity__c = false;
            opp.PrimaryQuote__c = qt.id;
            update opp;

            dsfs__DocuSign_Status__c dsStatus = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
                    dsfs__DocuSign_Status__c.dsfs__Opportunity__c => opp.Id,
                    dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => 'Sent'
                })
                .create()
                .getRecord();

            Triggers.switchOn();

            // need to set assignment to have the internal logic alligned with the flow that share cases
            AssignmentRule assignmentRule = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= assignmentRule.id;

            Case caseCreatedForDD = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Case.Status => CaseHelper.CASE_STATUS_NEW,
                        Case.AccountId => acc.Id,
                        Case.Opportunity_Reference__c => opp.Id,
                        Case.RecordTypeId => CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT,
                        Case.Subject => 'test case',
                        Case.Description => 'test',
                        Case.Case_Category__c => CaseHelper.CASE_CATEGORY_SYSTEM_ISSUE,
                        Case.Case_Subcategory__c => CaseHelper.CASE_SUB_CATEGORY_OPPORTUNITY,
                        Case.Origin => 'Opportunity'
                    })
                .build()
                .getRecord();

            Case caseCreatedForSustaining = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Case.Status => CaseHelper.CASE_STATUS_NEW,
                        Case.AccountId => acc.Id,
                        Case.Opportunity_Reference__c => opp.Id,
                        Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                        Case.Subject => 'test case',
                        Case.Description => 'test',
                        Case.Case_Category__c => CaseHelper.CASE_CATEGORY_SYSTEM_ISSUE,
                        Case.Case_Subcategory__c => CaseHelper.CASE_SUB_CATEGORY_OPPORTUNITY,
                        Case.Origin => 'Opportunity'
                    })
                .build()
                .getRecord();
            
            caseCreatedForDD.setOptions(dmlOpts);
            caseCreatedForSustaining.setOptions(dmlOpts);
            insert caseCreatedForDD;
            insert caseCreatedForSustaining;
        }
    }

    private static User createTestUser(String profileName) {
        String uniqueUserName = 'testUser' + DateTime.now().getTime() + '@ringcentral.com.test';
        Profile p = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{profileName})
            .executeQuery()
            .get(0);

        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        return testUser;
    }

    
    @isTest
    static void testGetFilteredDataWithoutLastNDays() {
        
        QtcMetricsController.ChartFilter filter = new QtcMetricsController.ChartFilter();
        filter.brands = new List<String>{ OpportunityHelper.BRAND_RINGCENTRAL };
        filter.types = new List<String>{ OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS };
        filter.oppRecordTypes = new List<String>{ OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY };
        filter.lastNDaysApply = false;

        String formattedDate = Date.today().year() + '-' + String.valueOf(Date.today().month()).leftPad(2, '0');

        List<QtcMetricsController.ChartWrapper> result = QtcMetricsController.getFilteredData(filter, formattedDate);

        System.assertEquals(true, result.size() > 0, 'the response must be populated for testGetFilteredDataWithoutLastNDays');
    }

    @isTest
    static void testGetFilteredDataWithLastNDaysOfMonth() {

        QtcMetricsController.ChartFilter filter = new QtcMetricsController.ChartFilter();
        filter.brands = new List<String>{ OpportunityHelper.BRAND_RINGCENTRAL };
        filter.types = new List<String>{ OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS };
        filter.oppRecordTypes = new List<String>{ OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY };
        filter.lastNDaysApply = true;
        filter.lastNDaysPeriod = QtcMetricsController.PERIOD_MONTH;
        filter.lastNDaysNumber = '3';

        Date previousYearDate = Date.today().addYears(-1);
        String formattedDate = previousYearDate.year() + '-' + String.valueOf(previousYearDate.month()).leftPad(2, '0');

        List<QtcMetricsController.ChartWrapper> result = QtcMetricsController.getFilteredData(filter, formattedDate);

        System.assertEquals(true, result[0].data.isEmpty(), 'there is no populated data in testGetFilteredDataWithLastNDaysOfMonth');

    }

    @isTest
    static void testGetFilteredDataWithLastNDaysOfQuarter() {

        QtcMetricsController.ChartFilter filter = new QtcMetricsController.ChartFilter();
        filter.brands = new List<String>{ OpportunityHelper.BRAND_RINGCENTRAL };
        filter.types = new List<String>{ OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS };
        filter.oppRecordTypes = new List<String>{ OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY };
        filter.lastNDaysApply = true;
        filter.lastNDaysPeriod = QtcMetricsController.PERIOD_QUARTER;
        filter.lastNDaysNumber = '3';

        Date firstDayOfPreviousYear = Date.newInstance(Date.today().year() - 1, 1, 1);
        String formattedDate = firstDayOfPreviousYear.year() + '-' + String.valueOf(firstDayOfPreviousYear.month()).leftPad(2, '0');

        List<QtcMetricsController.ChartWrapper> result = QtcMetricsController.getFilteredData(filter, formattedDate);

        System.assertEquals(true, result[0].data.isEmpty(), 'there is no populated data in testGetFilteredDataWithLastNDaysOfQuarter');
    }

    @isTest
    static void testGetCasesStatistic() {

        String formattedDate = Date.today().year() + '-' + String.valueOf(Date.today().month()).leftPad(2, '0');

        QtcMetricsController.TableFilter filter = new QtcMetricsController.TableFilter();
        filter.caseOrigins = new List<String>{ 'Opportunity' };

        QtcMetricsController.TableRowData result = QtcMetricsController.getCasesStatistic(filter, formattedDate);

        System.assertEquals('1', result.casesForDD, 'there should be 1 case created via "Create a Case" for DD team');
        System.assertEquals('1', result.casesInSustainingQueueViaCreateACase, 'there should be 1 case created via "Create a Case" in sustaining');
    }

    @isTest
    static void testGetCasesStatisticOptions() {
        
        QtcMetricsController.TableOptionsWrapper options = QtcMetricsController.getCasesStatisticOptions();

        System.assertEquals(2, options.caseOrigins.size(), 'there should be 2 listed origins');
    }

    @isTest
    static void testGetPicklistValues() {
        QtcMetricsController.PicklistOptionsWrapper optionsWrapper = QtcMetricsController.getPicklistValues();

        System.assertNotEquals(null, optionsWrapper);
        System.assertNotEquals(null, optionsWrapper.brands);
        System.assertNotEquals(null, optionsWrapper.types);
        System.assertNotEquals(null, optionsWrapper.oppRecordTypes);
        System.assertNotEquals(null, optionsWrapper.accountSegments);

    }
}