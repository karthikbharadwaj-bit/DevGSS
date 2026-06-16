@isTest
private class TestLeadSpaceWrapperCls {

    public static final String JSON_OBJECTS = '{ ' +
        '"status": "success",' +
        '"data": { ' +
            '"person": {' +
            ' "first_name": "testPersonFirstName",' +
                '"address": {' +
                    '"country": "testPersonAddressCountry"' +
                '},' +
                '"analytics": {' +
                    '"job_functions": [' +
                        '"testJobFunction"' +
                    '],' +
                    '"scores": [' +
                        '{' +
                            '"score": {' +
                                '"value": 0' +
                            '},' +
                            '"profile_name": "testPersonAnalyticsScoreProfileName"' +
                        '}' +
                    ']' +
                '}' +
            '},' +
            '"company": {' +
                '"client_id":"DunsTest",' +
                '"industry": "testIndustry",' +
                '"website": "www.testwebsite.com",' +
                '"address": {' +
                    '"country": "testCompanyCountry"' +
                '},' +
                '"size": {' +
                    '"range": "testCompanySizeRange",' +
                    '"exact": 1' +
                '},' +
                '"revenue": {' +
                    '"range": "testCompanyRevenueRange"' +
                '},' +
                '"analytics": {' +
                    '"installed_base_technologies":["testCompanyAnalyticsInstalledBaseTechnologies"]' +
                '},' +
                '"family_tree": {' +
                    '"companies": [' +
                        '{' +
                            '"type": "DU",' +
                            '"address": {' +
                                '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                            '},' +
                            '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                        '}' +
                    ']' +
                '}' +
            '},' +
            '"total_scores": [' +
                '{' +
                    '"score": {' +
                        '"value": "10"' +
                    '},' +
                    '"profile_name": "testTotalScoresProfileName"' +
                '}' +
            '],' +
            '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
            '"enrichment_status": "testEnrichmentStatus"' +
            '}' +
        '}';

    @isTest
    private static void testClassShouldBeDeserializedSuccessfully(){
        String jsonObjects = JSON_OBJECTS;
        
        Test.startTest();
            LeadSpaceWrapperCls classUnderTest = LeadSpaceWrapperCls.parse(jsonObjects);
        Test.stopTest();

        System.assertEquals('testPersonFirstName',
            classUnderTest.data.person.first_name,
            'person.first_name should be serialized successfully');
        System.assertEquals('testPersonAddressCountry',
            classUnderTest.data.person.address.country,
            'person.address.country should be serialized successfully');
        System.assertEquals('testPersonAnalyticsScoreProfileName',
            classUnderTest.data.person.analytics.scores[0].profile_name,
            'person.analytics.scores.profile_name should be serialized successfully');
        System.assertEquals('DunsTest',
            classUnderTest.data.company.client_id,
            'company.duns should be serialized successfully');
        System.assertEquals('testCompanyCountry',
            classUnderTest.data.company.address.country,
            'company.address.country should be serialized successfully');
        System.assertEquals('testCompanySizeRange',
            classUnderTest.data.company.size.range,
            'company.size.range should be serialized successfully');
        System.assertEquals('testCompanyRevenueRange',
            classUnderTest.data.company.revenue.range,
            'company.revenue.range should be serialized successfully');
        System.assertEquals('testCompanyAnalyticsInstalledBaseTechnologies',
            classUnderTest.data.company.analytics.installed_base_technologies[0],
            'company.analytics.installed_base_technologies should be serialized successfully');
        System.assertEquals('DU',
            classUnderTest.data.company.family_tree.companies[0].type,
            'classUnderTest.company.family_tree.companies.type should be serialized successfully');
        System.assertEquals('testCompanyFamilyTreeCompaniesAddressCountry',
            classUnderTest.data.company.family_tree.companies[0].address.country,
            'company.family_tree.companies.address.country should be serialized successfully');
        System.assertEquals('testCompanyFamilyTreeCompaniesDuns',
            classUnderTest.data.company.family_tree.companies[0].duns,
            'classUnderTest.company.family_tree.companies.duns should be serialized successfully');
        System.assertEquals(10,
            classUnderTest.data.total_scores[0].score.value,
            'total_scores.score.value should be serialized successfully');
        System.assertEquals('testTotalScoresProfileName',
            classUnderTest.data.total_scores[0].profile_name,
            'total_scores.profile_name should be serialized successfully');
        System.assertEquals('testMaxPositiveTotalScoreProfiles',
            classUnderTest.data.max_positive_total_score_profiles[0],
            'max_positive_total_score_profiles should be serialized successfully');
        System.assertEquals('testEnrichmentStatus',
            classUnderTest.data.enrichment_status,
            'enrichment_status should be serialized successfully');
    }
}