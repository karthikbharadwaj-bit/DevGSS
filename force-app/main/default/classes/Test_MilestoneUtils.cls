/**************************************************************************************************
* Project Name..........: Entitlement                                                             *
* File..................: MilestoneUtils.class                                                    *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 19-06-2014                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 19-06-2014                                                              *
* Description...........: Test Class for Milestone Utility.                                       *
**************************************************************************************************/
@isTest
private class Test_MilestoneUtils {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testPositiveCase1() {

        insert new Entitlement_Case_Milestone_Configuration__c(
            Name = CaseHelper.RT_NAME_SUPPORT_CASE,
            First_Response_Milestone__c = 'CSP First Response',
            FollowUp_Milestone__c = 'CSP Follow Up',
            Case_Resolution_Milestone__c = 'CSP Case Resolution'
        );

        TriggerHandler.BY_PASS_CASE_ON_INSERT();
        TriggerHandler.BY_PASS_CASE_ON_UPDATE();

        SObjectFactory factory = new SObjectFactory();

        List<Case> caseRecordList = (List<Case>) factory
            .create(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.Subject => ValueProviderBuilder.provideUniqueString('Test'),
                    Case.Status => 'Open',
                    Case.Priority => 'P3',
                    Case.Description => ValueProviderBuilder.provideUniqueString('Test description')
                }
            );

        if (caseRecordList != null) {
            // Testing for First Response Milestones
            caseRecordList[0].Status = 'Work in Progress';
            caseRecordList[0].First_Response_Timestamp__c = System.now();
            caseRecordList[0].RecordTypeId = CaseHelper.RT_ID_SUPPORT_CASE;

            caseRecordList[1].Status = 'Work in Progress';
            caseRecordList[1].First_Response_Timestamp__c = System.now();
            caseRecordList[1].RecordTypeId = CaseHelper.RT_ID_SUPPORT_CASE;
            update caseRecordList;

            // Testing for Follow Up Milestones
            caseRecordList[0].Last_Agent_Update__c = System.now();
            caseRecordList[1].Last_Agent_Update__c = System.now();
            update caseRecordList;

            // Testing for Closed Milestone
            caseRecordList[0].Status = 'Closed';
            caseRecordList[1].Status = 'Closed';
            update caseRecordList;
        }
    }

    @isTest
    private static void testIsFirstRespTmstmpNotEmptyForSpecificRecordTypesMethod() {

        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(null, null),
            'method should return false if both passed arguments is NULL'
        );

        SObjectFactory factory = new SObjectFactory();

        Case caseRecord = (Case) factory
            .build(
                Case.SObjectType,
                Case.First_Response_Timestamp__c,
                ValueProviderBuilder.provideUniqueDatetime()
            );

        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_CASE),
            'method should return true if Case.First_Response_Timestamp__c not null and Case RecordType(second parameter) is "Support-Case"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp__c
        caseRecord.First_Response_Timestamp__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_CASE),
            'method should return false if Case.First_Response_Timestamp__c is null and Case RecordType(second parameter) is "Support-Case"'
        );


        // fill Case.First_Response_Timestamp_T2__c
        caseRecord.First_Response_Timestamp_T2__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_T2),
            'method should return true if Case.First_Response_Timestamp_T2__c not null and Case RecordType(second parameter) is "Support - T2"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_T2__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_T2__c
        caseRecord.First_Response_Timestamp_T2__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_T2),
            'method should return false if Case.First_Response_Timestamp_T2__c is null and Case RecordType(second parameter) is "Support - T2"'
        );


        // fill Case.First_Response_Timestamp_T3__c
        caseRecord.First_Response_Timestamp_T3__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_T3),
            'method should return true if Case.First_Response_Timestamp_T3__c not null and Case RecordType(second parameter) is "Support - T3"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_T3__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_T3__c
        caseRecord.First_Response_Timestamp_T3__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_T3),
            'method should return false if Case.First_Response_Timestamp_T3__c is null and Case RecordType(second parameter) is "Support - T3"'
        );


        // fill Case.First_Response_Timestamp_QoS__c
        caseRecord.First_Response_Timestamp_QoS__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_QOS),
            'method should return true if Case.First_Response_Timestamp_QoS__c not null and Case RecordType(second parameter) is "Support - QoS"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_QoS__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_QoS__c
        caseRecord.First_Response_Timestamp_QoS__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_QOS),
            'method should return false if Case.First_Response_Timestamp_QoS__c is null and Case RecordType(second parameter) is "Support - QoS"'
        );


        // fill Case.First_Response_Timestamp_ERT__c
        caseRecord.First_Response_Timestamp_ERT__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM),
            'method should return true if Case.First_Response_Timestamp_ERT__c not null and Case RecordType(second parameter) is "Support - Executive Response Team"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_ERT__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_ERT__c
        caseRecord.First_Response_Timestamp_ERT__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM),
            'method should return false if Case.First_Response_Timestamp_ERT__c is null and Case RecordType(second parameter) is "Support - Executive Response Team"'
        );


        // fill Case.First_Response_Timestamp_NTD__c
      /*  caseRecord.First_Response_Timestamp_NTD__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, 'Porting'),
            'method should return true if Case.First_Response_Timestamp_NTD__c not null and Case RecordType(second parameter) contains "Porting"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_NTD__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_NTD__c
        caseRecord.First_Response_Timestamp_NTD__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, 'Porting'),
            'method should return false if Case.First_Response_Timestamp_NTD__c is null and Case RecordType(second parameter) contains "Porting"'
        );  */


        // fill Case.First_Response_Timestamp_TELUS__c
        caseRecord.First_Response_Timestamp_TELUS__c = (DateTime) ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assertEquals(
            true,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, 'Support - Telus'),
            'method should return true if Case.First_Response_Timestamp_TELUS__c not null and Case RecordType(second parameter) is "Support - Telus"'
        );
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, null),
            'method should return false if Case.First_Response_Timestamp_TELUS__c not null and Case RecordType(second parameter) is null'
        );

        // clear Case.First_Response_Timestamp_TELUS__c
        caseRecord.First_Response_Timestamp_TELUS__c = null;
        System.assertEquals(
            false,
            MilestoneUtils.isFirstRespTmstmpNotEmptyForSpecificRecordTypes(caseRecord, CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM),
            'method should return false if Case.First_Response_Timestamp_TELUS__c is null and Case RecordType(second parameter) is "Support - Telus"'
        );
    }
}