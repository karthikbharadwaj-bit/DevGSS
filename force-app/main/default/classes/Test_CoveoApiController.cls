@IsTest
public class Test_CoveoApiController {
    @TestSetup
    private static void setupData() {
        insert new CoveoAPISettings__c(
            TrendingDimentions__c = 'dims',
            TrendingsSortByField__c = 'sort_field',
            TrendingMetrics__c = 'metrs',
            TrendingsPeriod__c = 14,
            TrendingDimentionsFilters__c = 'filters',
            TrendingsEndpointUrl__c = 'far_far_away',
            APIKey__c = 'RC',
            OrganizationId__c = 'test'
        );
    }
    @IsTest
    private static void getSuccessResultsFromCoveo() {
        Test.setMock(HttpCalloutMock.class, new CoveoApiCombinedDataHttpCalloutMock());
        Test.startTest();
        Map<String, Object> res = CoveoApiController.getTrendings();
        Test.stopTest();
        System.assertEquals(8, res.get('totalNumberOfResults'));
        System.assertNotEquals(null, res.get('combinations'));
    }
    private class CoveoApiCombinedDataHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String jsonS = '{"combinations":[{"documentTitle":"Fax - Send fax through your RingCentral online account",' +
                '"documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000008a73","searchHubName":"Box16SupportCommunity",' +
                '"documentSysUriHash":"gCoM4MñWyzVv3Kwñ","sourceName":"Box16Knowledge","DocumentView":17},' +
                '{"documentTitle":"Printing Fax messages","documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K5L",' +
                '"searchHubName":"Box16SupportCommunity","documentSysUriHash":"pZjAvKOu5ww8e2Ud","sourceName":"Box16Knowledge",' +
                '"DocumentView":4},{"documentTitle":"Fax Troubleshooting Checklist and Frequently Asked Questions",' +
                '"documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K5G","searchHubName":"Box16SupportCommunity",' +
                '"documentSysUriHash":"o5uJ4EfUIGvGnLee","sourceName":"Box16Knowledge","DocumentView":3},' +
                '{"documentTitle":"RingCentral Fax Resources","documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K5Q",' +
                '"searchHubName":"Box16SupportCommunity","documentSysUriHash":"8ð6OzaWubelxukBl",' +
                '"sourceName":"Box16Knowledge","DocumentView":2},' +
                '{"documentTitle":"Phones & Devices - Access Phones & Devices Section | RingCentral"' +
                ',"documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K3P",' +
                '"searchHubName":"Box16SupportCommunity","documentSysUriHash":"88iDnjWbI7woA4TG",' +
                '"sourceName":"Box16Knowledge","DocumentView":1},{"documentTitle":"MLP",' +
                '"documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K4I","searchHubName":"Box16SupportCommunity"' +
                ',"documentSysUriHash":"LmCRFe4f5FQqIawQ","sourceName":"Box16Knowledge","DocumentView":1},{"documentTitle":"Test 6950"' +
                ',"documentURL":"https://rc--box16.cs12.my.salesforce.com/kA2V00000000K4N","searchHubName":"Box16SupportCommunity",' +
                '"documentSysUriHash":"T7MðDGkUðQQtWtPq","sourceName":"Box16Knowledge","DocumentView":1},{"documentTitle":null,' +
                '"documentURL":null,"searchHubName":"Box16SupportCommunity","documentSysUriHash":null,"sourceName":null,' +
                '"DocumentView":0}],"uniqueCounts":{"documentTitle":7,"documentURL":7,"searchHubName":1,"documentSysUriHash":7,' +
                '"sourceName":1},"totalNumberOfResults":8,"lastUpdated":1549638084300,"cached":true}';
            response.setBody(jsonS);
            response.setStatusCode(200);
            return response;
        }
    }
}