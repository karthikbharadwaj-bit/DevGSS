public without sharing class CoveoApiController {

        private static CoveoAPISettings__c settings = CoveoAPISettings__c.getOrgDefaults();

        private static String getTrendingsEcodedDimentions() {
            System.debug('getTrendingsEcodedDimentions');
            String configFieldValue = settings.TrendingDimentions__c;
            if(String.isBlank(configFieldValue)) {
                return '';
            }
            List<String> vals = configFieldValue.split(';');
            return encodeUrlValues(vals, 'd');
        }
        private static String getEncodedOrderByField() {
            System.debug('getEncodedOrderByField');
            String configFieldValue = settings.TrendingsSortByField__c;
            if(String.isBlank(configFieldValue)) {
                return '';
            }
            List<String> val = configFieldValue.split('#');
            String res = '';
            if(val.size() > 0) {
                res += '&s=' + val[0];
                if(val.size() > 1) {
                    String value = val[1].equalsIgnoreCase('ASC') ? 'true' : 'false';
                    res += '&asc=' + value;
                }
            }
            return res;
        }
        private static String getTrendingsEcodedMetrics() {
            System.debug('getTrendingsEcodedMetrics');
            String configFieldValue = settings.TrendingMetrics__c;
            if(String.isBlank(configFieldValue)) {
                return '';
            }
            List<String> vals = configFieldValue.split(';');
            return encodeUrlValues(vals, 'm');
        }

        private static String getTrendingsEncodedPeriod() {
            System.debug('getTrendingsEncodedPeriod');
            Decimal days = settings.TrendingsPeriod__c;
            if(days == null) {
                days = 14;
            }
            System.debug(days);
            DateTime endOfperiod = System.now();
            DateTime startOfPeriod = endOfperiod.addDays(-Integer.valueOf(days));
            String dataFormat = 'yyyy-MM-dd';
            return '&from=' + startOfPeriod.format(dataFormat) + 'T00:00:00.000Z'
                + '&to=' + endOfperiod.format(dataFormat) + 'T00:00:00.000Z';
        }

        private static String getTrendingsEncodedDimentionsFilters() {
            System.debug('getTrendingsEncodedDimentionsFilters');
            String configFieldValue = settings.TrendingDimentionsFilters__c;
            if(String.isBlank(configFieldValue)) {
                return '';
            }
            List<String> vals = configFieldValue.split(';');
            return encodeUrlValues(vals, 'f');
        }

        private static String encodeUrlValues(List<String> values, String parameterName) {
            String res = '';
            String dif = '&' + parameterName + '=';
            for (String curVa : values) {
                res += dif + curVa.trim();
            }
            return res;
        }

        public static Map<String, Object> getTrendings(){
            Http localHttpClient = new Http();
            HttpRequest req = new HttpRequest();
            String endpoint = settings.TrendingsEndpointUrl__c
                + '?bindOnLastSearch=true&access_token=' + settings.APIKey__c
                + '&org=' + settings.OrganizationId__c
                + '&n=50'
                + '&d=DocumentTitle&d=DocumentUrl&d=SEARCHHUBNAME'
                + '&m=DocumentView'
                + getTrendingsEncodedPeriod()
                + getTrendingsEcodedDimentions()
                + getTrendingsEcodedMetrics()
                + getTrendingsEncodedDimentionsFilters()
                + getEncodedOrderByField();

            req.setEndpoint(endpoint);
            req.setMethod('GET');
            String responseBody;
            HttpResponse httpRes;
            try {
                httpRes =  localHttpClient.send(req);
                responseBody = httpRes.getBody();
                System.debug(responseBody);
            } catch (Exception e){
                onError('', e);
            }
            return (Map<String, Object>)JSON.deserializeUntyped(responseBody);

        }
        private static void onError(String message, Exception e) {
            if (e != null) {
                System.debug(e.getMessage() + ' ##### ' + e.getStackTraceString());
            }
            throw new CoveoApiException(e.getMessage());
        }

        private class CoveoApiException extends Exception{}
}