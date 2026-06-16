public class QuoteDeleteHandler implements IResourceHandler {

    public ApiResponse execute(ApiRequest request) {
        try {
            System.debug('request.requestBody: ' + request.requestBody);
            Set<Id> quoteIds = new Set<Id>(
                (List<Id>) JSON.deserialize(request.requestBody, List<Id>.class)
            );

            if (quoteIds == null || quoteIds.isEmpty()) {
                return ApiResponse.error('No quote IDs provided for deletion');
            }

            List<Quote> records = new List<Quote>();
            for (Id recordId : quoteIds) {
                records.add(new Quote(Id = recordId));
            }

            delete records;

            return ApiResponse.success(new Map<String, Object>{
                'deletedQuoteIds' => new List<Id>(quoteIds)
            });
        } catch(Exception e) {
            return ApiResponse.error(e);
        }
    }
}