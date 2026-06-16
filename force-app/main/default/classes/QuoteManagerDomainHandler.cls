/**
 * Domain handler for Quote Manager
 * Handles all requests for the quote-manager domain
 */
public class QuoteManagerDomainHandler extends DomainHandler {

    public QuoteManagerDomainHandler() {
        super();
        register('v1', 'test', 'GET', TestResourceHandler.class);
        register('v1', 'quotes', 'POST', QuoteUpsertHandler.class);
        register('v1', 'quotes/missing/bulk', 'POST', QuoteDeleteHandler.class);
        register('v1', 'quote/approvers', 'GET', QuoteApprovalsHandler.class);
    }

    /**
     * Test resource handler for the quote-manager domain
     * Handles test endpoints
     */
    public class TestResourceHandler implements IResourceHandler {
        /**
         * Execute the handler for test requests
         * @param request The API request details
         * @return ApiResponse containing the response data
         */
        public ApiResponse execute(ApiRequest request) {
            // Simple test response
            Map<String, Object> responseData = new Map<String, Object>{
                'message' => 'Test endpoint successful',
                'timestamp' => System.now()
            };

            return ApiResponse.success(responseData);
        }
    }

    public class QuoteApprovalsHandler implements IResourceHandler {
        public ApiResponse execute(ApiRequest request) {

            try {
                String quoteId = request.params.get('quoteId');
                if (String.isBlank(quoteId)) {
                    return ApiResponse.error('Quote ID is required');
                }

                List<Quote> quotes = (List<Quote>) new QuoteSelector()
                    .selectQuoteApprovalsInfo(quoteId)
                    .executeQuery();

                // Legacy logic
                // Note: The logic for showing the "Submit for Approval" button on the frontend depends on permission fields.
                Quote masterQuote = QuoteService.populateAvailableApprovalActions(quotes, SettingsService.isUserCanApprove()).get(0);

                Triggers.switchOff();
                update masterQuote;
                Triggers.switchOn();
                // end legacy logic

                return ApiResponse.success(masterQuote);
            } catch(Exception e) {
                return ApiResponse.error(e.getMessage());
            }
        }
    }
}