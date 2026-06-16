public with sharing class TransactionsRefundsAPI {

    public class CustomException extends Exception {}
    public static final String TRANSACTION_NGBS_TYPE_BILL = 'bill';
    public static final String TRANSACTION_NGBS_TYPE_INVOICE = 'pendingInvoice';
    public static final Set<String> TRANSACTION_NGBS_TYPES = new Set<String>{
        TRANSACTION_NGBS_TYPE_BILL, TRANSACTION_NGBS_TYPE_INVOICE
    };

    public static final String ACC_TALEND_TRANS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE
        = 'One of the required fields is empty: ' +
            'RC_User_ID__c, Start date, End date';
    public static final String ACC_TALEND_TRANS_DETAILS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE
        = 'One of the required fields is empty: ' +
            'Transaction Id, UserId';
    public static final String ACC_NGBS_TRANS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE = 'field values is null: Billing Account Id';
    public static final String ARGS_IS_NULL_ERROR_MESSAGE = 'postRefundData, approvalId args should be not null';
    public static final String TRANSACTION_DTO_ARG_IS_NULL_ERROR_MESSAGE = 'transactionDTO arg is null';
    public static final String APPROVAL_NOT_FOUND_ERROR_MESSAGE = 'approval not found';

    public static final String CATEGORY_FIELD_IS_EMPTY_ERROR_MESSAGE = 'Category__c field on approval__c is blank';
    public static final String REFUNDTYPE_FIELD_IS_EMPTY_ERROR_MESSAGE = 'Refund_Type__c field on approval__c is blank';

    public static final String ENDPOINT_TALEND_NOT_FOUND_ERROR_MESSAGE = 'not found Refunds_Service_Endpoint__c url. Check Refunds_Settings__c custom setting';
    public static final String ENDPOINT_NGBS_NOT_FOUND_ERROR_MESSAGE = 'not found BaseEndpoint__c url. Check NGBS_Settings__c custom setting';
    public static final String REQUEST_FAILED_ERROR_MESSAGE = 'failed to make request. Got status ';
    public static final String TOO_MANY_TRANSACTIONS_IN_RESPONSE = 'To request transactions, date range should be less than ';

    @TestVisible private static final String UNEXPECTED_PARAMETER_EMPTY = 'Unexpected parameter empty ';

    public static final String TRANSACTION_TYPE_RC = 'RC';
    public static final String TRANSACTION_TYPE_NON_RC = 'NonRC';
    public static final String TRANSACTION_WO_TYPE = '"transactionType":null,';
    public static final Decimal TRANSACTIONS_HEAP_SIZE_THRESHOLD = 0.4;

    private static Approval__c currentApproval;

    public class CostCenter {
        @AuraEnabled public String billingCodeId;
        @AuraEnabled public String name;
        public CostCenter(String billingCodeId, String name) {
            this.billingCodeId = billingCodeId;
            this.name = name;
        }
    }

    public class DetailsResponse {
        @AuraEnabled public List<CostCenter> costCenters;
        @AuraEnabled public List<ProductItemDTO> products;
        @AuraEnabled public String paymentType;
        public DetailsResponse(List<CostCenter> costCenters, List<ProductItemDTO> products, String paymentType) {
            this.costCenters = costCenters;
            this.products = products;
            this.paymentType = paymentType;
        }
    }

    // DTO for GetTransactionDetails request
    public class GetTransactionPageInfoDTO {
        @AuraEnabled public String userId;
        @AuraEnabled public String transactionId;
        @AuraEnabled public String transactionType;

        public GetTransactionPageInfoDTO(String userId, String transactionId, String transactionType) {
            this.userId = userId;
            this.transactionId = transactionId;
            this.transactionType = transactionType;
        }
    }

    public class SFDCTransactionPageInfoRequestDTO {
        @AuraEnabled public GetTransactionPageInfoDTO sfdcRequest;

        public SFDCTransactionPageInfoRequestDTO(GetTransactionPageInfoDTO sfdcRequest) {
            this.sfdcRequest = sfdcRequest;
        }
    }

    // DTO for GetTransactions request
    public class GetTransactionDTO {
        @AuraEnabled public String userId;
        @AuraEnabled public String transactionType;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;

        public GetTransactionDTO(String userId, String transactionType, Date startDate, Date endDate) {
            this.userId = userId;
            this.transactionType = transactionType;
            this.startDate = convertDateFormat(startDate);
            this.endDate = convertDateFormat(endDate);
        }
    }

    public class SFDCRequestDTO {
        @AuraEnabled public GetTransactionDTO sfdcRequest;

        public SFDCRequestDTO(GetTransactionDTO sfdcRequest) {
            this.sfdcRequest = sfdcRequest;
        }
    }


    public class SubSubItemDTO {
        @AuraEnabled public String productId;
        @AuraEnabled public String productDescription;
        @AuraEnabled public Decimal transactionAmount;
        @AuraEnabled public Decimal refundableAmount;
        @AuraEnabled public String transactionType;

        public SubSubItemDTO(ItemDetailsDTO item) {
            this.productId = item.productId;
            this.productDescription = item.productDescription;
            this.transactionAmount = item.transactionAmount;
            this.refundableAmount = item.refundableAmount;
            this.transactionType = item.transactionType;
        }
    }

    // Also Known As "Sub Item"
    public class ItemDetailsDTO {
        @AuraEnabled public String productId;
        @AuraEnabled public String productDescription;
        @AuraEnabled public Decimal transactionAmount;
        @AuraEnabled public Decimal refundableAmount;
        @AuraEnabled public String transactionType;
        @AuraEnabled public List<SubSubItemDTO> items;

        public ItemDetailsDTO(String productId, String productDescription, Decimal transactionAmount, String transactionType) {
            this.productId = productId;
            this.productDescription = productDescription;
            this.transactionAmount = transactionAmount;
            this.transactionType = transactionType;
        }

        public ItemDetailsDTO(ItemsDTO item) {
            this.productId = item.productId;
            this.productDescription = item.productDescription;
            this.transactionAmount = item.transactionAmount;
            this.refundableAmount = item.refundableAmount;
            this.transactionType = item.transactionType;
        }
    }

    public class ItemsDTO {
        @AuraEnabled public String productId;
        @AuraEnabled public String productDescription;
        @AuraEnabled public Decimal transactionAmount;
        @AuraEnabled public Decimal refundableAmount;
        @AuraEnabled public String transactionType;
        @AuraEnabled public List<ItemDetailsDTO> itemDetails;
        @AuraEnabled public Decimal maxRefundAmount;
        @AuraEnabled public String ngbsType;
        @AuraEnabled public String itemType;
        @AuraEnabled public String categoryId;
        @AuraEnabled public String combinedCatalogId;
        @AuraEnabled public String taxItemId;
        @AuraEnabled public String taxLevel;
        @AuraEnabled public Decimal refunded;

        public ItemsDTO() {
            this.maxRefundAmount = 0;
            this.refunded = 0;
        }

        public ItemsDTO(
            String productId,
            String productDescription,
            Decimal transactionAmount,
            String transactionOrNGBSType,
            String itemType,
            String categoryId,
            String combinedCatalogId,
            String taxItemId,
            String taxLevel,
            List<ItemDetailsDTO> itemDetails
        ) {
            this();
            this.productId = productId;
            this.productDescription = productDescription;
            this.transactionAmount = transactionAmount;
            if (TRANSACTION_NGBS_TYPES.contains(transactionOrNGBSType)) {
                this.ngbsType = transactionOrNGBSType;
            } else {
                this.transactionType = transactionOrNGBSType;
            }
            this.itemType = itemType;
            this.categoryId = categoryId;
            this.combinedCatalogId = combinedCatalogId;
            this.taxItemId = taxItemId;
            this.taxLevel = taxLevel;
            this.itemDetails = itemDetails;
        }

        public ItemsDTO(ProductItemDTO prod) {
            this();
            this.productId = prod.productId;
            this.productDescription = prod.productDescription;
            this.transactionAmount = prod.transactionAmount;
            this.refundableAmount = prod.refundableAmount;
            this.transactionType = prod.transactionType;
        }

        public ItemsDTO(NGBSAPI.CalculatedRefundTaxItem taxItem) {
            this();
            this.productDescription = taxItem.description;
            this.maxRefundAmount = taxItem.amount;
            this.transactionAmount = taxItem.amount;
            this.taxItemId = taxItem.taxItemId;
            this.transactionType = null;
            this.productId = null;
        }
    }

    public class ProductItemDTO {
        @AuraEnabled public String productId;
        @AuraEnabled public String productDescription;
        @AuraEnabled public Decimal transactionAmount;
        @AuraEnabled public Decimal refundableAmount;
        @AuraEnabled public String productType;
        @AuraEnabled public String currencyType;
        @AuraEnabled public String transactionType;

        @AuraEnabled public String featureType;
        @AuraEnabled public List<ItemsDTO> items;

        @AuraEnabled public String ngbsType;
        //for NGBS
        @AuraEnabled public String itemGroupId;
        @AuraEnabled public String categoryId;
        @AuraEnabled public String billingCodeId;
        @AuraEnabled public String lineNo;
        //for NGBS, bill type only
        @AuraEnabled public String billId;

        public ProductItemDTO() {}

        public ProductItemDTO(String productId,String productDescription,Decimal transactionAmount,String productType,String currencyType,String transactionOrNGBSType, String featureType) {
            this.productId = productId;
            this.productDescription = productDescription;
            this.transactionAmount = transactionAmount;
            this.productType = productType;
            this.currencyType = currencyType;
            this.featureType = featureType;
            this.items = new List<ItemsDTO>();
            if (TRANSACTION_NGBS_TYPES.contains(transactionOrNGBSType)) {
                this.ngbsType = transactionOrNGBSType;
            } else {
                this.transactionType = transactionOrNGBSType;
            }
        }

        public String getItemType() {
            Boolean isZeroItemExist = this.items != null && this.items[0] != null;
            return (isZeroItemExist) ? this.items[0].itemType : null;
        }

        public Boolean isFeatureCharge() {
            return getItemType() == NGBSAPI.ITEM_TYPE_FEATURE_CHARGE;
        }
    }

    // DTO for GetTransactions response
    public class TransactionsDTO {
        @AuraEnabled public String transactionId;
        @AuraEnabled public String transactionDate;
        @AuraEnabled public String refundTransactionDate;
        @AuraEnabled public String transactionStatus;
        @AuraEnabled public String paySystem;
        @AuraEnabled public String paymentType;
        @AuraEnabled public Decimal refundedAmount;
        @AuraEnabled public Decimal TotalAmount;
        @AuraEnabled public String currencyType;
        @AuraEnabled public List<ProductItemDTO> productItems;

        @AuraEnabled public String ngbsType; //bill or invoice

        public TransactionsDTO(String transactionId,String transactionDate,String refundTransactionDate, String transactionStatus,String paySystem,String paymentType,Decimal refundedAmount,List<ProductItemDTO> productItems) {
            this.transactionId = transactionId;
            this.transactionDate = transactionDate;
            this.refundTransactionDate = refundTransactionDate;
            this.transactionStatus = transactionStatus;
            this.paySystem = paySystem;
            this.paymentType = paymentType;
            this.refundedAmount = refundedAmount;
            this.productItems = productItems;
        }
    }

    public class SFDCResponseDTO {
        @AuraEnabled public String userId;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public String transactionType;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String sessionPageId;
        @AuraEnabled public List<TransactionsDTO> transactions;

        public SFDCResponseDTO(String userId, String startDate, String endDate, List<TransactionsDTO> transactions) {

            this.userId = userId;
            this.startDate = startDate;
            this.endDate = endDate;
            this.transactions = transactions;
        }

        public void normalize() {

            if (this.transactions == null || this.transactions.isEmpty()) {
                this.transactions = new List<TransactionsDTO>();
            }

            if (String.isNotBlank(this.transactionType)
                && this.transactionType != TRANSACTION_TYPE_RC) {
                return;
            }

            for (TransactionsDTO t : this.transactions) {

                if (t.productItems == null || t.productItems.isEmpty()) {
                    t.productItems = new List<ProductItemDTO>();
                }

                for (ProductItemDTO p : t.productItems) {
                    Set<String> itemsSeqIdSet = new Set<String>();

                    if (p.items == null) {
                        p.items = new List<ItemsDTO>();
                    }

                    for (ItemsDTO i : p.items) {
                        Set<String> subItemsSeqIdSet = new Set<String>();
                        itemsSeqIdSet.add(i.productId);

                        if (i.itemDetails == null) {
                            i.itemDetails = new List<ItemDetailsDTO>();
                        }

                        for (ItemDetailsDTO s : i.itemDetails) {
                            Set<String> subSubItemsSeqIdSet = new Set<String>();
                            subItemsSeqIdSet.add(s.productId);

                            if (s.items == null) {
                                s.items = new List<SubSubItemDTO>();
                            }

                            for (SubSubItemDTO si : s.items) {
                                subSubItemsSeqIdSet.add(si.productId);
                            }

                            if (!subSubItemsSeqIdSet.contains(s.productId)) {
                                ListHelper.unshift(s.items, new SubSubItemDTO(s));
                            }
                        }

                        if (!subItemsSeqIdSet.contains(i.productId)) {
                            ListHelper.unshift(i.itemDetails, new ItemDetailsDTO(i));
                        }

                    }

                    if (!itemsSeqIdSet.contains(p.productId)) {
                        ListHelper.unshift(p.items, new ItemsDTO(p));
                    }
                }
            }
        }
    }

    public class Response {
        @AuraEnabled public SFDCResponseDTO sfdcResponse;

        public Response(SFDCResponseDTO sfdcResponse) {
            this.sfdcResponse = sfdcResponse;
        }
    }

    public class GetTransactionsResponseWrapper {
        @AuraEnabled public Response body;

        public GetTransactionsResponseWrapper(Response body) {
            this.body = body;
        }
    }

    public class GetTransactionDetailsResponseWrapper {
        @AuraEnabled public Response body;

        public GetTransactionDetailsResponseWrapper(Response body) {
            this.body = body;
        }
    }

    public class TransactionInfoResponse {
        @AuraEnabled public String userId;
        @AuraEnabled public String transactionType;
        @AuraEnabled public String transactionId;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String sessionPageCount;
    }

    public class GetTransactionInfoResponse {
        @AuraEnabled public TransactionInfoResponse sfdcResponse;

        public GetTransactionInfoResponse(TransactionInfoResponse sfdcResponse) {
            this.sfdcResponse = sfdcResponse;
        }
    }

    public class GetTransactionInfoWrapper {
        @AuraEnabled public GetTransactionInfoResponse body;

        public GetTransactionInfoWrapper(GetTransactionInfoResponse body) {
            this.body = body;
        }
    }

    public class GetTransactionDetailsDTO {
        @AuraEnabled public String userId;
        @AuraEnabled public String transactionId;
        @AuraEnabled public String transactionType;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String sessionPageId;

        public GetTransactionDetailsDTO(String userId, String transactionId, String transactionType, String
        sessionId, String sessionPageId) {
            this.userId = userId;
            this.transactionId = transactionId;
            this.transactionType = transactionType;
            this.sessionId = sessionId;
            this.sessionPageId = sessionPageId;
        }
    }

    public class SFDCTransactionDetailsRequestDTO {
        @AuraEnabled public GetTransactionDetailsDTO sfdcRequest;

        public SFDCTransactionDetailsRequestDTO(GetTransactionDetailsDTO sfdcRequest) {
            this.sfdcRequest = sfdcRequest;
        }
    }

    private static String buildRoute(String transactionType) {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        switch on transactionType {
            when 'GetTransactions' {
                return featureToggle.Alternative_Refund_Transactions_Requests__c ? 'GetTransactionList' : 'GetTransactions';
            }
            when 'GetTransactionDetails' {
                return featureToggle.Large_Transactions_Processing__c ? 'GetTransactionDetails_Page' : 'GetTransactionDetails';
            }
            when 'PostRefunds' {
                return 'PostRefunds';
            }
            when else {
                return '';
            }
        }
    }

    private static String buildServiceUrl(String transactionType) {
        String baseUrl = Refunds_Settings__c.getInstance().Refunds_Service_Endpoint__c;

        if(String.isBlank(baseUrl)) {
            throw new CustomException(ENDPOINT_TALEND_NOT_FOUND_ERROR_MESSAGE);
        }

        return baseUrl + buildRoute(transactionType);
    }

    public static SFDCResponseDTO getTalendTransactions(String userId, String transactionType, Date startDate, Date endDate) {
        if(String.isBlank(userId) || startDate == null || endDate == null) {
            throw new CustomException(ACC_TALEND_TRANS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE);
        }

        String apiUrl = buildServiceUrl('GetTransactions');

        // prepare JSON body for POST request
        GetTransactionDTO testDTO = new GetTransactionDTO(
            userId,
            transactionType,
            startDate,
            endDate
        );

        SFDCRequestDTO testReqDTO = new SFDCRequestDTO(testDTO);

        String jsonStr = replaceTransactionType(JSON.serialize(testReqDTO));
        System.debug('getTransactions JSON request(pretty) >>> ' + JSON.serializePretty(testReqDTO));

        HttpResponse response = makeRequest(apiUrl, 'POST', jsonStr);

        if (response.getStatus() != 'OK') {
            throw new CustomException(REQUEST_FAILED_ERROR_MESSAGE + response.getStatus());
        }

        String jsonResponse = response.getBody();
        /* Limit the amount of transactions in response */
        if (Limits.getHeapSize() > Limits.getLimitHeapSize() * TRANSACTIONS_HEAP_SIZE_THRESHOLD) {
            throw new CustomException(TOO_MANY_TRANSACTIONS_IN_RESPONSE + startDate.daysBetween(endDate) + ' day(s)');
        }
        // replace reserved apex words
        String jsonReplacedString = TransactionsRefundsAPI.replaceReservedSymbols(jsonResponse);

        GetTransactionsResponseWrapper result = (GetTransactionsResponseWrapper) JSON.deserialize(jsonReplacedString, GetTransactionsResponseWrapper.class);

        result.body.sfdcResponse.normalize();
        System.debug('result normalized: ' + result);

        return result.body.sfdcResponse;
    }

    public static TransactionInfoResponse getTalendTransactionPagesInfo(String userId, String transactionId,
        String type) {

        if (String.isBlank(userId) || String.isBlank(transactionId)) {
            throw new CustomException(ACC_TALEND_TRANS_DETAILS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE);
        }

        String apiUrl = buildServiceUrl('GetTransactionDetails');

        // prepare JSON body for POST request
        GetTransactionPageInfoDTO sfdcRequest = new GetTransactionPageInfoDTO(
            userId,
            transactionId,
            type
        );
        SFDCTransactionPageInfoRequestDTO getTransactionInfoRequest = new SFDCTransactionPageInfoRequestDTO(sfdcRequest);
        String jsonStr = JSON.serialize(getTransactionInfoRequest);
        System.debug('getTransactionPagesInfo JSON request(pretty) >>> ' + JSON.serializePretty
        (getTransactionInfoRequest));

        HttpResponse response = makeRequest(apiUrl, 'POST', jsonStr);
        if (response.getStatus() != 'OK') {
            throw new CustomException(REQUEST_FAILED_ERROR_MESSAGE + response.getStatus());
        }

        String jsonResponse = response.getBody();
        System.debug('getTransactionInfo JSON response(pretty) >>> ' + JSON.serializePretty(jsonResponse));
        GetTransactionInfoWrapper result = (GetTransactionInfoWrapper) JSON.deserialize(jsonResponse, GetTransactionInfoWrapper.class);

        return result.body.sfdcResponse;
    }

    public static SFDCResponseDTO getTalendTransactionDetails(String userId, String transactionId, String type, String
        sessionId, String sessionPageId) {

        if (String.isBlank(userId) || String.isBlank(transactionId)) {
            throw new CustomException(ACC_TALEND_TRANS_DETAILS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE);
        }

        String apiUrl = buildServiceUrl('GetTransactionDetails');

        // prepare JSON body for POST request
        GetTransactionDetailsDTO transactionDetailsDTO = new GetTransactionDetailsDTO(
            userId,
            transactionId,
            type,
            sessionId,
            sessionPageId
        );
        SFDCTransactionDetailsRequestDTO singlePageDetailsReqDTO =
            new SFDCTransactionDetailsRequestDTO(transactionDetailsDTO);
        String jsonStr = JSON.serialize(singlePageDetailsReqDTO);
        System.debug('getTransactions JSON request(pretty) >>> ' + JSON.serializePretty(singlePageDetailsReqDTO));

        HttpResponse response = makeRequest(apiUrl, 'POST', jsonStr);

        if (response.getStatus() != 'OK') {
            throw new CustomException(REQUEST_FAILED_ERROR_MESSAGE + response.getStatus());
        }

        String jsonResponse = response.getBody();
        System.debug('getTransactionDetails JSON response(pretty) >>> ' + JSON.serializePretty(jsonResponse));
        // replace reserved apex words
        String jsonReplacedString = TransactionsRefundsAPI.replaceReservedSymbols(jsonResponse);
        GetTransactionsResponseWrapper result = (GetTransactionsResponseWrapper) JSON.deserialize(jsonReplacedString, GetTransactionsResponseWrapper.class);

        System.debug('result: ' + result);
        result.body.sfdcResponse.normalize();
        System.debug('result normalized: ' + result);

        return result.body.sfdcResponse;
    }

    public class RefundBillingItemDetail {

        @AuraEnabled public String approvalId;
        @AuraEnabled public String approverEmail;
        @AuraEnabled public String approverFirstName;
        @AuraEnabled public String approverLastName;
        @AuraEnabled public String refundApprovalDate;
        @AuraEnabled public Integer refundCategoryId;
        @AuraEnabled public String refundComment;
        @AuraEnabled public String refundRequestDate;
        @AuraEnabled public Integer refundTypeId;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String userFirstName;
        @AuraEnabled public String userLastName;

        public RefundBillingItemDetail(String approvalID, String approverEmail, String approverFirstName,
            String approverLastName, String refundApprovalDate, Integer refundCategoryId, String refundComment,
            String refundRequestDate, Integer refundTypeId, String userEmail, String userFirstName, String userLastName) {

            this.approvalId = approvalId;
            this.approverEmail = approverEmail;
            this.approverFirstName = approverFirstName;
            this.approverLastName = approverLastName;
            this.refundApprovalDate = refundApprovalDate;
            this.refundCategoryId = refundCategoryId;
            this.refundComment = refundComment;
            this.refundRequestDate = refundRequestDate;
            this.refundTypeId = refundTypeId;
            this.userEmail = userEmail;
            this.userFirstName = userFirstName;
            this.userLastName = userLastName;
        }
    }

    public class BillingItemsDTO {
        @AuraEnabled public Decimal billingItemId;
        @AuraEnabled public Decimal refundAmount;

        public BillingItemsDTO(Decimal billingItemId, Decimal refundAmount) {
            this.billingItemId = billingItemId;
            this.refundAmount = refundAmount;
        }
    }

    public class TransactionDetailDTO {
        @AuraEnabled public String billingTransactionId;
        @AuraEnabled public Decimal totalRefundAmount;
        @AuraEnabled public List<BillingItemsDTO> billingItems;
        @AuraEnabled public String userId;
        @AuraEnabled public RefundBillingItemDetail refundBillingItemDetails;
        @AuraEnabled public String transactionType;

        public TransactionDetailDTO(
            String billingTransactionId,
            Decimal totalRefundAmount,
            List<BillingItemsDTO> billingItems,
            String userId,
            RefundBillingItemDetail refundBillingItemDetails,
            String transactionType
        ) {

            this.billingTransactionId = billingTransactionId;
            this.totalRefundAmount = totalRefundAmount;
            this.billingItems = billingItems;
            this.userId = userId;
            this.refundBillingItemDetails = refundBillingItemDetails;
            this.transactionType = transactionType;
        }
    }

    public class TransactionsDetailsDTO {
        @AuraEnabled public List<TransactionDetailDTO> transactionDetails;

        public TransactionsDetailsDTO(List<TransactionDetailDTO> transactionDetails) {
            this.transactionDetails = transactionDetails;
        }
    }

    public class PostRefundsDTO {
        @AuraEnabled public TransactionsDetailsDTO transactions;

        public PostRefundsDTO(TransactionsDetailsDTO transactions) {

            this.transactions = transactions;
        }
    }

    public class PostRefundsResponseWrapper {
        @AuraEnabled public RefundResponse refund;
        public PostRefundsResponseWrapper(RefundResponse refund) {
            this.refund = refund;
        }
    }

    public class RefundResponse {
        @AuraEnabled public List<PostRefundsResponseItem> transactions;
    }

    public class PostRefundsResponseItem {
        @AuraEnabled public String billingTransactionID;
        @AuraEnabled public String status;
        @AuraEnabled public String message;

        public PostRefundsResponseItem(String billingTransactionID, String status, String message) {

            this.billingTransactionID = billingTransactionID;
            this.status = status;
            this.message = message;
        }
    }

    public class PostRefundData {
        @AuraEnabled public String billingTransactionId;
        @AuraEnabled public List<RefundItem> refundedItem;
        @AuraEnabled public String transactionType;

        public PostRefundData(String billingTransactionId, List<RefundItem> refundedItem, String transactionType) {
            this.billingTransactionId = billingTransactionId;
            this.refundedItem = refundedItem;
            this.transactionType = transactionType;
        }
    }

    public class RefundItem {
        @AuraEnabled public String billingItemId;
        @AuraEnabled public Decimal refundAmount;
        public RefundItem(String billingItemId, Decimal refundAmount) {
            this.billingItemId = billingItemId;
            this.refundAmount = refundAmount;
        }
    }

    public static PostRefundsResponseWrapper postRefund(
        List<PostRefundData> postRefundData,
        Id approvalId, String accUserId,
        String transactionType
    ) {

        if(String.isBlank(approvalId) || postRefundData == null) {
            throw new CustomException(ARGS_IS_NULL_ERROR_MESSAGE);
        }

        List<Approval__c> approvalList = [
            SELECT Id, Approval_ID__c, Owner.Email,
                Owner.FirstName, Owner.LastName, Category__c, Refund_Type__c, Level1Approver__c,
                Level1Approver__r.Email, Level1Approver__r.FirstName, Level1Approver__r.LastName,
                JustificationandDescription__c
            FROM Approval__c
            WHERE Id = :approvalId];

        currentApproval = !approvalList.isEmpty() ? approvalList.get(0) : null;

        if(currentApproval == null) {
            throw new CustomException(APPROVAL_NOT_FOUND_ERROR_MESSAGE);
        }

        if(String.isBlank(currentApproval.Category__c)) {
            throw new CustomException(CATEGORY_FIELD_IS_EMPTY_ERROR_MESSAGE);
        }else if(String.isBlank(currentApproval.Refund_Type__c)) {
            throw new CustomException(REFUNDTYPE_FIELD_IS_EMPTY_ERROR_MESSAGE);
        }

        Map<String, Transaction_History__c> transactionHistoryMap = getTransactionsHistory(postRefundData, currentApproval.Id);

        TransactionsDetailsDTO transactionDetails = new TransactionsDetailsDTO(
            preparePostRefundData(currentApproval, postRefundData, accUserId, transactionType)
        );

        return postRefund(new PostRefundsDTO(transactionDetails), transactionHistoryMap);
    }



    public static List<TransactionDetailDTO> preparePostRefundData(
        Approval__c refundApproval,
        List<PostRefundData> postRefundData,
        String accUserId,
        String transactionType
    ) {

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        Integer refundCategoryId;
        Integer refundTypeId;

        if (featureToggle != null && featureToggle.Static_Refund_Category_and_Type__c == true){
            refundCategoryId = 39;
            refundTypeId = 113;
        }else{
            refundCategoryId = findCategoryIdByName(refundApproval.Category__c);
            refundTypeId = findRefundTypeId(refundCategoryId,refundApproval.Refund_Type__c);
        }

        //Get date of the last approval step
        List <ProcessInstance> piList = [
            SELECT Id, TargetObjectId
            FROM ProcessInstance
            WHERE TargetObjectId =: refundApproval.Id LIMIT 1];

        Date lastStepCreatedDate = System.today();
        if(!piList.isEmpty()) {
            Id piRecordId = piList.get(0).Id;
            List <ProcessInstanceStep> pisList = [
                SELECT Id, StepStatus, CreatedDate
                FROM ProcessInstanceStep
                WHERE ProcessInstanceId =: piRecordId
                AND StepStatus = 'Approved'
                ORDER BY CreatedDate DESC];
            if(!pisList.isEmpty()) {
                DateTime lastStepCreatedDateTime = pisList.get(0).CreatedDate;
                lastStepCreatedDate = date.newinstance(lastStepCreatedDateTime.year(),
                    lastStepCreatedDateTime.month(),
                    lastStepCreatedDateTime.day());
            }
        }

        RefundBillingItemDetail refundBIDetail = new RefundBillingItemDetail(
            refundApproval.Approval_ID__c,
            refundApproval.Level1Approver__c != null   ? refundApproval.Level1Approver__r.Email
                : refundApproval.Owner.Email,
            refundApproval.Level1Approver__c != null   ? refundApproval.Level1Approver__r.FirstName
                : refundApproval.Owner.FirstName,
            refundApproval.Level1Approver__c != null   ? refundApproval.Level1Approver__r.LastName
                : refundApproval.Owner.LastName,
            convertDateFormat(lastStepCreatedDate),
            refundCategoryId != null ? refundCategoryId : 0,
            refundApproval.JustificationandDescription__c,
            convertDateFormat(System.today()),
            refundTypeId != null ? refundTypeId : 0,
            refundApproval.Owner.Email,
            refundApproval.Owner.FirstName,
            refundApproval.Owner.LastName
        );

        List<TransactionDetailDTO> transactionDetailsList = new List<TransactionDetailDTO>();

        for(PostRefundData transactionData : postRefundData) {

            List<BillingItemsDTO> billingItemsList = new List<BillingItemsDTO>();
            for(RefundItem refundedItem : transactionData.refundedItem) {
                BillingItemsDTO billingItem = new BillingItemsDTO(
                    Decimal.ValueOf(refundedItem.billingItemId),
                    refundedItem.refundAmount
                );

                billingItemsList.add(billingItem);
            }

            TransactionDetailDTO transactionDetail = new TransactionDetailDTO(
                transactionData.billingTransactionId,
                0,
                billingItemsList,
                accUserId,
                refundBIDetail,
                transactionType
            );
            transactionDetailsList.add(transactionDetail);
        }

        return transactionDetailsList;
    }

    /* create Transaction_History__c for posted transition */
    public static Map<String, Transaction_History__c> getTransactionsHistory(PostRefundData[] transactions, Id approvalId) {
        Map<String, Transaction_History__c> transactionHistoryMap = new Map<String, Transaction_History__c>();
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        for(PostRefundData tr : transactions) {

            Decimal totalRefundAmount = 0;
            for(RefundItem item : tr.refundedItem) {
                totalRefundAmount += item.refundAmount;
            }
            Transaction_History__c trHistory = new Transaction_History__c(
                Approval__c = approvalId,
                Name = tr.billingTransactionId,
                RefundAmount__c = totalRefundAmount,
                TransactionId__c = tr.billingTransactionId,
                Message__c = '',
                Status__c = ''
            );
            if (featureToggle.ContactCenterRefunds__c) {
                trHistory.TransactionType__c = tr.transactionType;
            }
            transactionHistoryMap.put(tr.billingTransactionId, trHistory);
        }

        return transactionHistoryMap;
    }

    public static PostRefundsResponseWrapper postRefund(
        PostRefundsDTO transactionDTO,
        Map<String, Transaction_History__c>  transactionHistoryMap
    ) {

        if(transactionDTO == null) {
            throw new CustomException(TRANSACTION_DTO_ARG_IS_NULL_ERROR_MESSAGE);
        }

        String apiUrl = buildServiceUrl('PostRefunds');

        String jsonStr = replaceTransactionType(JSON.serialize(transactionDTO));
        System.debug('post JSON request(pretty) >>> ' + JSON.serializePretty(transactionDTO));
        HttpResponse response = makeRequest(apiUrl, 'POST', jsonStr);

        if (response.getStatus() != 'OK') {
            throw new CustomException(REQUEST_FAILED_ERROR_MESSAGE + response.getStatus());
        }

        String jsonResponse = response.getBody();

        // replace reserved apex words
        String jsonReplacedString = jsonResponse.replace('"transaction":', '"transactions":');

        PostRefundsResponseWrapper result = (PostRefundsResponseWrapper) JSON.deserialize(jsonReplacedString, PostRefundsResponseWrapper.class);

        createTransactionHistory(result, transactionHistoryMap);

        return result;
    }

    @TestVisible
    private static Integer findCategoryIdByName(String refundCategoryName) {

        if(String.isBlank(refundCategoryName)) {
            return null;
        }

        Refund_Categories__c refCat = Refund_Categories__c.getAll().get(refundCategoryName) != null ?
            Refund_Categories__c.getAll().get(refundCategoryName) : null;

        if(refCat == null) {
            String errorMessage = 'Can not find specified category in ' +
                'Refund_Categories__c custom setting. Category name "' + refundCategoryName + '"';
            throw new CustomException(errorMessage);
        }

        Integer catId = refCat != null ? (Integer) refCat.Category_Id__c : null;

        return catId;
    }

    @TestVisible
    private static Integer findRefundTypeId(Integer refundCategoryId, String refundTypeName) {

        if(refundCategoryId == null || String.isBlank(refundTypeName)) {
            return null;
        }

        Integer refundTypeId = null;

        for(RefundCategoryAndTypeMapping__c item : RefundCategoryAndTypeMapping__c.getAll().values()) {
            if(item.Refund_Category_Id__c == refundCategoryId && item.Refund_Type_Name__c == refundTypeName) {
                refundTypeId = (Integer) item.Refund_Type_Id__c;
                break;
            }
        }

        if(refundTypeId == null) {
            String errorMessage = 'Can not find specified type in ' +
                'RefundCategoryAndTypeMapping__c custom setting. Category Id "' +
                refundCategoryId + '"; Type name "' + refundTypeName + '"';
            throw new CustomException(errorMessage);
        }

        return refundTypeId;
    }

    @TestVisible
    private static void createTransactionHistory(
        PostRefundsResponseWrapper response,
        Map<String, Transaction_History__c> transactionHistoryMap
    ) {
        List<Transaction_History__c> transactionHistoryToCreate = new List <Transaction_History__c>();
        for (PostRefundsResponseItem responseItem : response.refund.transactions) {
            if(responseItem.status == 'success'
                && transactionHistoryMap.get(responseItem.billingTransactionId) != null) {

                transactionHistoryMap.get(responseItem.billingTransactionId).Message__c = responseItem.message;
                transactionHistoryMap.get(responseItem.billingTransactionId).Status__c = responseItem.status;
                transactionHistoryToCreate.add(transactionHistoryMap.get(responseItem.billingTransactionId));
            }
        }
        if(!transactionHistoryToCreate.isEmpty()) {
            insert transactionHistoryToCreate;
        }
    }

    @TestVisible
    private static HttpResponse makeRequest(String url, String method, String jsonStr) {

        if(String.isBlank(url) || String.isBlank(method) || String.isBlank(jsonStr)) {
            return null;
        }

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(url);
        request.setTimeout(120000);
        request.setMethod(method);
        request.setBody(jsonStr);

        HttpResponse response = new Http().send(request);

        return response;
    }

    public static String convertDateFormat(Date dateToconvert) {
        return (dateToconvert.month() + '-' + dateToconvert.day() + '-' + dateToconvert.year());
    }

    public static List<TransactionsRefundsAPI.TransactionsDTO> getNGBSTransactions(String accountBillingId) {
        StringHelper.validateStrict(accountBillingId, UNEXPECTED_PARAMETER_EMPTY + 'accountBillingId');
        String billingApiURl = getBillingEndpoint(NGBSAPI.NGBS_BILLING_ACCOUNT_HISTORY_FORMAT, accountBillingId);

        HttpResponse response = NGBSAPI.requestNGBS(billingApiUrl, 'GET');
        String jsonResponse = TransactionsRefundsAPI.replaceReservedSymbols(response.getBody());
        System.debug('NGBS Transaction History response =>> ' + jsonResponse);

        NGBSAPI.AccountHistoryResponse NGBSResponseWrapper = (NGBSAPI.AccountHistoryResponse) JSON.deserialize(jsonResponse, NGBSAPI.AccountHistoryResponse.class);

        List<TransactionsRefundsAPI.TransactionsDTO> convertedTransactions
            = NGBSResponseWrapper.convertToListOfTransactions();


        return convertedTransactions;
    }

    public static DetailsResponse getNGBSBill(String accountBillingId, String transactionId) {
        String billDetailsResponse = getNGBSTransactionDetails(accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.BILL);
        NGBSAPI.BillDetail billDetail = getBillDetailFromResponse(billDetailsResponse);
        List<CostCenter> costCenters = parseCostCenters(billDetailsResponse);
        //remove variable value to avoid heap size issue
        billDetailsResponse = '';
        List<ProductItemDTO> productsFromBillDetails = getProductItemsFromBillDetails(billDetail);
        List<ProductItemDTO> taxCreditsUnderNegativeInvoices = getTaxCreditsUnderNegativeInvoices(productsFromBillDetails);
        productsFromBillDetails = calculateTotalAmount(productsFromBillDetails);
        productsFromBillDetails = removeTaxes(productsFromBillDetails);
        productsFromBillDetails = removeNegatives(productsFromBillDetails);
        Decimal appliedCredit = getAppliedCredit(billDetail);

        NGBSAPI.RefundApplicationMapWrapper wrapper =
            getNGBSCalculatedRefunds(productsFromBillDetails, accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.BILL, false);

        NGBSAPI.RefundApplicationMapWrapper wrapperWithSpreading =
            getNGBSCalculatedRefunds(productsFromBillDetails, accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.BILL, true);

        productsFromBillDetails =   completeProductsData(productsFromBillDetails, wrapper, wrapperWithSpreading);
        productsFromBillDetails = addTaxesAsItemsUnderProducts(productsFromBillDetails);
        productsFromBillDetails = addTaxCredits(productsFromBillDetails, taxCreditsUnderNegativeInvoices);
        String paymentType = getPaymentType(billDetail);
        return new DetailsResponse(costCenters, productsFromBillDetails, paymentType);
    }

    private static List<ProductItemDTO> addTaxCredits(List<ProductItemDTO> products, List<ProductItemDTO> taxCredits) {
        for (ProductItemDTO tc : taxCredits) {
            tc.productDescription = 'Tax Cancellation ' + tc.productDescription;
            tc.categoryId = 'Tax Cancellation ' + tc.categoryId;
            tc.items[0].productDescription = 'Tax Cancellation ' + tc.items[0].productDescription;
            tc.items[0].categoryId = 'Tax Cancellation ' + tc.items[0].categoryId;
            products.add(tc);
        }
        return products;
    }

    private static List<ProductItemDTO> getTaxCreditsUnderNegativeInvoices(List<ProductItemDTO> products) {
        List<ProductItemDTO> taxCredits = new List<ProductItemDTO>();
        Map<String, Decimal> invoiceIdToAmount = getInvoiceIdToSum(products);
        for (ProductItemDTO pi : products) {
            if (invoiceIdToAmount.get(pi.billId) >= 0) {
                continue;
            }
            if (pi.items[0].itemType != NGBSAPI.ITEM_TYPE_TAX_CREDIT) {
                continue;
            }
            taxCredits.add(pi);
        }
        return taxCredits;
    }

    private static String getPaymentType(NGBSAPI.BillDetail billDetail) {
        return billDetail.getPaymentType();
    }

    public static DetailsResponse getNGBSInvoice(String accountBillingId, String transactionId) {
        List<CostCenter> costCenters;
        List<ProductItemDTO> productsFromInvoiceDetails;
        try {
            String invoiceDetailsResponse = getNGBSTransactionDetails(accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.INVOICE);
            NGBSAPI.BillDetailBillInvoice invoiceDetail = getInvoiceDetailFromResponse(invoiceDetailsResponse);
            costCenters = parseCostCenters(invoiceDetailsResponse);
            invoiceDetailsResponse = null;
            productsFromInvoiceDetails = getProductItemsFromInvoiceDetails(invoiceDetail);
        }
        catch (Exception ex) {
            PlatformLog.logException(TransactionsRefundsAPI.class.getName(), ex);
            System.debug('TransactionsRefundsAPI::getNGBSInvoice throws an exception: ' + Json.serialize(ex));
            throw new CustomException('Error parsing NGBS response. Please, contact the support or try again later');
        }

        productsFromInvoiceDetails = calculateTotalAmount(productsFromInvoiceDetails);
        productsFromInvoiceDetails = removeTaxes(productsFromInvoiceDetails);
        productsFromInvoiceDetails = removeNegatives(productsFromInvoiceDetails);

        NGBSAPI.RefundApplicationMapWrapper wrapper =
            getNGBSCalculatedRefunds(productsFromInvoiceDetails, accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.INVOICE, false);

        NGBSAPI.RefundApplicationMapWrapper wrapperWithSpreading =
            getNGBSCalculatedRefunds(productsFromInvoiceDetails, accountBillingId, transactionId, NGBSAPI.TRANSACTION_TYPE.INVOICE, true);

        productsFromInvoiceDetails = completeProductsData(productsFromInvoiceDetails, wrapper, wrapperWithSpreading);
        productsFromInvoiceDetails = addTaxesAsItemsUnderProducts(productsFromInvoiceDetails);
        // TODO remove null
        return new DetailsResponse(costCenters, productsFromInvoiceDetails, null);
    }

    private static String getNGBSTransactionDetails(String accountBillingId, String transactionId, NGBSAPI.TRANSACTION_TYPE trType) {
        String endpoint = (trType == NGBSAPI.TRANSACTION_TYPE.BILL)
            ? NGBSAPI.NGBS_BILLING_API_URL_FOR_BILL_DETAIL : NGBSAPI.NGBS_BILLING_API_URL_FOR_INVOICE_DETAIL;
        String billingApiURl = getBillingEndpoint(endpoint, accountBillingId, transactionId);
        HttpResponse response = NGBSAPI.requestNGBS(billingApiUrl, 'GET');
        String jsonResponse = TransactionsRefundsAPI.replaceReservedSymbols(response.getBody());
        System.debug('NGBS Transaction response =>> ' + jsonResponse);
        return jsonResponse;
    }

    private static NGBSAPI.RefundApplicationMapWrapper getNGBSCalculatedRefunds(
        List<ProductItemDTO> productItems,
        String accountBillingId,
        String transactionId,
        NGBSAPI.TRANSACTION_TYPE trType,
        Boolean isSpreadCredit
    ) {
        String endpoint = (trType == NGBSAPI.TRANSACTION_TYPE.BILL)
            ? NGBSAPI.NGBS_BILL_API_FOR_CALCULATED_REFUNDS : NGBSAPI.NGBS_INVOICE_API_FOR_CALCULATED_REFUNDS;
        if (isSpreadCredit) {
            endpoint += '?' + NGBSAPI.DISTRIBUTE_CANCALLATION_CREDIT_PARAMETER;
        }
        List<ProductItemDTO> resultProductItems = new List<ProductItemDTO>();
        String billingApiURl = getBillingEndpoint(endpoint, accountBillingId, transactionId);
        String body = prepareBillingBody(productItems);
        System.debug('body to send calculate request =>> ' + body);

        HttpResponse response = NGBSAPI.requestNGBS(billingApiUrl, 'POST', body);
        String jsonResponse = TransactionsRefundsAPI.replaceReservedSymbols(response.getBody());
        System.debug('Calculated refunds response =>> ' + jsonResponse);

        return NGBSAPI.convertTaxResponseToWrappers(jsonResponse);
    }

    private static NGBSAPI.BillDetail getBillDetailFromResponse(String jsonResponse) {
        return (NGBSAPI.BillDetail) JSON.deserialize(jsonResponse, NGBSAPI.BillDetail.class);
    }

    private static NGBSAPI.BillDetailBillInvoice getInvoiceDetailFromResponse(String jsonResponse) {
        return (NGBSAPI.BillDetailBillInvoice) JSON.deserialize(jsonResponse, NGBSAPI.BillDetailBillInvoice.class);
    }

    private static List<ProductItemDTO> getProductItemsFromBillDetails(NGBSAPI.BillDetail billDetail) {
        return billDetail.convertToProductItem(TRANSACTION_NGBS_TYPE_BILL);
    }

    private static List<ProductItemDTO> getProductItemsFromInvoiceDetails(NGBSAPI.BillDetailBillInvoice invoiceDetail) {
        return invoiceDetail.convertToProductItem(TRANSACTION_NGBS_TYPE_INVOICE);
    }

    private static Decimal getAppliedCredit(NGBSAPI.BillDetail billDetail) {
        return billDetail.bill.appliedCredit;
    }

    private static List<ProductItemDTO> completeProductsData(
        List<ProductItemDTO> products,
        NGBSAPI.RefundApplicationMapWrapper wrapper,
        NGBSAPI.RefundApplicationMapWrapper wrapperWithSpreading
    ) {
        Map<String, NGBSAPI.CalculatedRefundItem> keyToMaxRefundsMap =
            getProductsMaxRefundsMap(wrapperWithSpreading);
        Map<String, List<NGBSAPI.CalculatedRefundTaxItem>> keyToTaxesWithSpreading =
            getTaxMaxRefundsMap(wrapperWithSpreading);
        Map<String, Decimal> keyToInitialAmount =
            getTaxKeyToInitialAmount(wrapper);
        products = setProductsMaxRefunds(products, keyToMaxRefundsMap);
        products = addTaxesFromCalculateResponse(products, keyToTaxesWithSpreading, keyToInitialAmount);
        return products;
    }

    private static List<ProductItemDTO> calculateTotalAmount(List<ProductItemDTO> products) {
        Map<String, ProductItemDTO> keyToPositiveProducts = getProductsWithPositiveAmount(products);
        Map<String, List<ProductItemDTO>> keyToNegativeProducts = getProductsWithNegativeAmount(products);
        return sumTotalAmount(keyToPositiveProducts, keyToNegativeProducts);
    }

    private static Map<String, ProductItemDTO> getProductsWithPositiveAmount(List<ProductItemDTO> products) {
        Map<String, ProductItemDTO> keyToPositiveProducts = new Map<String, ProductItemDTO>();
        for (ProductItemDTO currentProductItem : products) {
            String productKey = getKey(currentProductItem);
            if (String.isBlank(currentProductItem.itemGroupId)) {
                continue;
            }
            if (currentProductItem.transactionAmount <= 0) {
                continue;
            }

            // productItem that was already in map
            ProductItemDTO existingProductItem = keyToPositiveProducts.get(productKey);
            if (existingProductItem == null) {
                keyToPositiveProducts.put(productKey, currentProductItem);
            } else {
                if (currentProductItem.isFeatureCharge()) {
                    Decimal existingPiAmount = existingProductItem.transactionAmount;
                    currentProductItem.transactionAmount += existingPiAmount;
                    currentProductItem.items[0].transactionAmount += existingPiAmount;
                    keyToPositiveProducts.put(productKey, currentProductItem);
                } else {
                    existingProductItem.transactionAmount += currentProductItem.transactionAmount;
                    existingProductItem.items[0].transactionAmount += currentProductItem.transactionAmount;
                }
            }
        }
        return keyToPositiveProducts;
    }

    private static Map<String, List<ProductItemDTO>> getProductsWithNegativeAmount(List<ProductItemDTO> products) {
        Map<String, List<ProductItemDTO>> keyToNegativeProducts = new Map<String, List<ProductItemDTO>>();
        for (ProductItemDTO pi : products) {
            if (String.isBlank(pi.itemGroupId)) {
                continue;
            }
            if (pi.transactionAmount > 0) {
                continue;
            }
            String key = getKey(pi);
            if (keyToNegativeProducts.get(key) == null) {
                keyToNegativeProducts.put(key, new List<ProductItemDTO>());
            }
            keyToNegativeProducts.get(key).add(pi);
        }
        return keyToNegativeProducts;
    }

    private static List<ProductItemDTO> sumTotalAmount(
        Map<String, ProductItemDTO> keyToPositiveProducts,
        Map<String, List<ProductItemDTO>> keyToNegativeProducts
    ) {
        List<ProductItemDTO> resultProducts = new List<ProductItemDTO>();
        for (String key : keyToPositiveProducts.keySet()) {
            List<ProductItemDTO> negativeProductsForItemGroup = keyToNegativeProducts.get(key);
            ProductItemDTO positiveProductItem = keyToPositiveProducts.get(key);
            if (negativeProductsForItemGroup != null) {
                Decimal transactionAmount = positiveProductItem.transactionAmount;
                for (ProductItemDTO pi : negativeProductsForItemGroup) {
                    transactionAmount += pi.transactionAmount;
                }
                positiveProductItem.transactionAmount = transactionAmount;
                positiveProductItem.items[0].transactionAmount = transactionAmount;
            }
            resultProducts.add(positiveProductItem);
            keyToNegativeProducts.remove(key);
        }
        //add negative products that were not matched to negatives
        for (String key : keyToNegativeProducts.keySet()) {
            resultProducts.addAll(keyToNegativeProducts.get(key));
        }
        return resultProducts;
    }

    public static List<CostCenter> parseCostCenters(String jsonResponse) {
        List<CostCenter> costCentersResult = new List<CostCenter>();
        Map<String, Object> deserializedStr = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> bill = (Map<String, Object>) deserializedStr.get('bill');
        List<Object> invoices;
        if (bill == null) {
            invoices = new List<Object>{(Object)deserializedStr};
        } else {
            invoices = (List<Object>) bill.get('invoices');
        }
        for (Object invoiceObj : invoices) {
            Map<String, Object> invoiceObjTyped = (Map<String, Object>) invoiceObj;
            Map<String, Object> billingCodes = (Map<String, Object>) invoiceObjTyped.get('billingCodesData');
            if (billingCodes != null) {
                for (String billingCodeId : billingCodes.keySet()) {
                    Map<String, Object> billingCode = (Map<String, Object>) billingCodes.get(billingCodeId);
                    List<Object> path = (List<Object>) billingCode.get('path');
                    if (path.isEmpty()) {
                        continue;
                    }
                    Map<String, Object> ccNameStruct = (Map<String, Object>) path[path.size() - 1];
                    String ccName = (String) ccNameStruct.get('name');
                    costCentersResult.add(new CostCenter(billingCodeId, ccName));
                }
            }
        }
        return costCentersResult;
    }

    public static HttpResponse applyRefundNGBS(String accountId, String billId, String json) {
        String billingApi = getBillingEndpoint(NGBSAPI.NGBS_BILL_APPLY_REFUND, accountId, billId);
        return NGBSAPI.requestNGBS(billingApi, 'POST', json);
    }

    public static HttpResponse applyInvoiceAdjustmentNGBS(String accountId, String json) {
        String billingApi = getBillingEndpoint(NGBSAPI.NGBS_INVOICE_APPLY_REFUND, accountId);
        return NGBSAPI.requestNGBS(billingApi, 'POST', json);
    }

    private static String getBillingEndpoint(String endpointFormat, String parameter0) {
        return getBillingEndpoint(endpointFormat, parameter0, '');
    }

    private static String getBillingEndpoint(String endpointFormat, String parameter0, String parameter1) {
        return String.format(endpointFormat, new List<String>{parameter0, parameter1});
    }

    private static String replaceReservedSymbols(String jsonStr) {
        return jsonStr.replace('"currency":', '"currencyType":');
    }

    private static String prepareBillingBody(List<ProductItemDTO> productItems) {

        String resultBody = '';
        Map<String,Set<String>> invoiceIdToItemGroups = getItemGroups(productItems);
        try {
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeFieldName('applications');
            gen.writeStartObject();
            for (String invoiceId : invoiceIdToItemGroups.keySet()) {
                Set<String> itemGroupIds = invoiceIdToItemGroups.get(invoiceId);
                gen.writeFieldName(invoiceId);
                gen.writeStartObject();

                for (String itemGroup : itemGroupIds) {
                    gen.writeNumberField(itemGroup, 0);
                }
                gen.writeEndObject();
            }
            gen.writeEndObject();
            gen.writeFieldName('taxes');
            gen.writeStartObject();
            gen.writeEndObject();
            gen.writeEndObject();

            resultBody = gen.getAsString();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new CustomException('An exception occured when parsing JSON: ' + e.getMessage());
        }
        return resultBody;
    }

    private static Map<String,Set<String>> getItemGroups(List<ProductItemDTO> productItems) {
        Map<String,Set<String>> itemGroups = new Map<String,Set<String>>();
        Map<String, Decimal> invoiceIdToAmount = getInvoiceIdToSum(productItems);
        if (productItems == null || productItems.isEmpty()) {
            return itemGroups;
        }
        for (ProductItemDTO prItem : productItems) {
            if (String.isBlank(prItem.billId) || String.isBlank(prItem.itemGroupId)) {
                continue;
            }
//            if (prItem.transactionAmount <= 0) {
//                continue;
//            }
            // don't process negative invoices
            if (invoiceIdToAmount.get(prItem.billId) <= 0) {
                continue;
            }

            if (itemGroups.get(prItem.billId) == null) {
                itemGroups.put(prItem.billId, new Set<String>());
            }
            itemGroups.get(prItem.billId).add(prItem.itemGroupId);
        }
        return itemGroups;
    }
    // TODO rewrite to do it only once and put to static map?
    private static Map<String, Decimal> getInvoiceIdToSum(List<ProductItemDTO> products) {
        Map<String, Decimal> invoiceIdToAmount = new Map<String, Decimal>();
        for (ProductItemDTO prItem : products) {
            if (invoiceIdToAmount.get(prItem.billId) == null) {
                invoiceIdToAmount.put(prItem.billId, 0);
            }
            Decimal currentAmount = invoiceIdToAmount.get(prItem.billId);
            invoiceIdToAmount.put(prItem.billId, currentAmount + prItem.transactionAmount);
        }
        return invoiceIdToAmount;
    }

    private static List<ProductItemDTO> addTaxesAsItemsUnderProducts(List<ProductItemDTO> products) {
        List<ProductItemDTO> returnProducts = new List<ProductItemDTO>();
        if (products.isEmpty()) {
            return returnProducts;
        }
        Map<String, Map<String, ProductItemDTO>> invoiceIdToItemGroupIdToProduct =
            getInvoiceIdToItemGroupIdToProductMap(products);
        String ngbsType = products[0].ngbsType;
        List<ProductItemDTO> taxes = new List<ProductItemDTO>();
        for (ProductItemDTO pi : products) {
            if (String.isNotBlank(pi.items[0].taxItemId)) {
                taxes.add(pi);
            }
        }
        for (ProductItemDTO taxProduct : taxes) {
            if (invoiceIdToItemGroupIdToProduct.get(taxProduct.billId) == null ||
                invoiceIdToItemGroupIdToProduct.get(taxProduct.billId).get(taxProduct.itemGroupId) == null) {
                continue;
            }
            ProductItemDTO pi = invoiceIdToItemGroupIdToProduct.get(taxProduct.billId).get(taxProduct.itemGroupId);
            ItemsDTO item = pi.items[0];

            ItemsDTO taxItem = new ItemsDTO();
            taxItem.productDescription = taxProduct.productDescription;
            taxItem.maxRefundAmount = taxProduct.items[0].maxRefundAmount;
            taxItem.transactionAmount = taxProduct.items[0].transactionAmount;
            taxItem.taxItemId = taxProduct.items[0].taxItemId;
            taxItem.combinedCatalogId = item.combinedCatalogId;
            taxItem.categoryId = item.categoryId;
            taxItem.ngbsType = ngbsType;

            pi.items.add(taxItem);
        }
        for (String invoiceId : invoiceIdToItemGroupIdToProduct.keySet()) {
            for (ProductItemDTO pi : invoiceIdToItemGroupIdToProduct.get(invoiceId).values()) {
                returnProducts.add(pi);
            }
        }
        return returnProducts;
    }

    private static Map<String, Map<String, ProductItemDTO>> getInvoiceIdToItemGroupIdToProductMap(
        List<ProductItemDTO> products
    ) {
        Map<String, Map<String, ProductItemDTO>> invoiceIdToItemGroupIdToProduct =
            new Map<String, Map<String, ProductItemDTO>>();
        for (ProductItemDTO pi : products) {
            if (String.isNotBlank(pi.items[0].taxItemId)) {
                continue;
            }
            if (invoiceIdToItemGroupIdToProduct.get(pi.billId) == null) {
                invoiceIdToItemGroupIdToProduct.put(pi.billId, new Map<String, ProductItemDTO>());
            }
            if (invoiceIdToItemGroupIdToProduct.get(pi.billId).get(pi.itemGroupId) == null) {
                invoiceIdToItemGroupIdToProduct.get(pi.billId).put(pi.itemGroupId, pi);
            }
        }
        return invoiceIdToItemGroupIdToProduct;
    }
    //replace taxes from purchase response with taxes from calculate response
    private static List<ProductItemDTO> addTaxesFromCalculateResponse(
        List<ProductItemDTO> productItems,
        Map<String, List<NGBSAPI.CalculatedRefundTaxItem>> keyToTaxes,
        Map<String, Decimal> keyToInitialAmount
    ) {
        List<ProductItemDTO> productItemsToReturn = new List<ProductItemDTO>();
        for (ProductItemDTO pi : productItems) {
            productItemsToReturn.add(pi);
            List<NGBSAPI.CalculatedRefundTaxItem> taxItems = getTaxesForProduct(pi, keyToTaxes);
            if (taxItems.isEmpty()) {
                continue;
            }
            for (NGBSAPI.CalculatedRefundTaxItem refTaxItem : taxItems) {
                ItemsDTO item = pi.items[0];
                Decimal initialAmount = keyToInitialAmount.get(refTaxItem.invoiceId + ':' + refTaxItem.itemGroupId + ':' + refTaxItem.taxItemId);

                ProductItemDTO piTax = new ProductItemDTO();
                piTax.productDescription = refTaxItem.description;
                piTax.transactionAmount = initialAmount != null ? initialAmount : refTaxItem.amount;
                piTax.itemGroupId = pi.itemGroupId;
                piTax.billingCodeId = pi.billingCodeId;
                piTax.billId = pi.billId;
                // TODO set correct ngbsType or get rid of them. It works though.
                piTax.ngbsType = 'bill';
                ItemsDTO taxItem = new ItemsDTO();
                taxItem.productDescription = refTaxItem.description;
                taxItem.maxRefundAmount = refTaxItem.amount;
                taxItem.taxItemId = refTaxItem.taxItemId;
                taxItem.transactionAmount = piTax.transactionAmount;
                // TODO set correct ngbsType or get rid of them. It works though.
                taxItem.ngbsType = 'bill';
                piTax.items = new List<ItemsDTO>();
                piTax.items.add(taxItem);
                productItemsToReturn.add(piTax);
            }
        }
        return productItemsToReturn;
    }

    private static List<ProductItemDTO> removeTaxes(List<ProductItemDTO> products) {
        List<ProductItemDTO> productsWithoutTaxes = new List<ProductItemDTO>();
        for (ProductItemDTO pi : products) {
            if (pi.items[0].taxItemId != null) {
                continue;
            }
            productsWithoutTaxes.add(pi);
        }
        return productsWithoutTaxes;
    }

    private static List<ProductItemDTO> removeNegatives(List<ProductItemDTO> products) {
        List<ProductItemDTO> productsWithoutNegatives = new List<ProductItemDTO>();
        for (ProductItemDTO pi : products) {
            productsWithoutNegatives.add(pi);
        }
        return productsWithoutNegatives;
    }

    public static String getKey(ProductItemDTO pi) {
        return getKey(pi.billId, pi.itemGroupId);
    }

    public static String getKey(String billId, String itemGroupId) {
        return getKey(billId, itemGroupId, null);
    }

    public static String getKey(String billId, String itemGroupId, String taxItemId) {
        return getKey(billId, itemGroupId, taxItemId, null);
    }
    public static String getKey(String billId, String itemGroupId, String taxItemId, String productDescription) {
        return billId + ':' + itemGroupId + ':' + taxItemId + ':' + productDescription;
    }

    private static List<ProductItemDTO> setProductsMaxRefunds(
        List<ProductItemDTO> products,
        Map<String, NGBSAPI.CalculatedRefundItem> keyToMaxRefundsMap
    ) {
        for (ProductItemDTO pi : products) {
            String key = getKey(pi.billId, pi.itemGroupId);
            NGBSAPI.CalculatedRefundItem refundItem = keyToMaxRefundsMap.get(key);
            if (refundItem == null) {
                continue;
            }
            for (ItemsDTO item : pi.items) {
                item.maxRefundAmount = refundItem.amount;
            }
        }
        return products;
    }

    private static Map<String, NGBSAPI.CalculatedRefundItem> getProductsMaxRefundsMap(
        NGBSAPI.RefundApplicationMapWrapper wrapper
    ) {
        Map<String, NGBSAPI.CalculatedRefundItem> keyToMaxRefundsMap = new Map<String, NGBSAPI.CalculatedRefundItem>();
        for (NGBSAPI.CalculatedRefundItemGroup refundItemGroup : wrapper.refundItemGroups) {
            for (NGBSAPI.CalculatedRefundItem maxRefundItem: refundItemGroup.refundItems) {
                keyToMaxRefundsMap.put(getKey(maxRefundItem.invoiceId, maxRefundItem.itemGroupId), maxRefundItem);
            }
        }
        return keyToMaxRefundsMap;
    }
    private static Map<String, List<NGBSAPI.CalculatedRefundTaxItem>> getTaxMaxRefundsMap(
        NGBSAPI.RefundApplicationMapWrapper wrapper
    ) {
        Map<String, List<NGBSAPI.CalculatedRefundTaxItem>> invoiceIdToItemGroupIdsToTaxes =
            new Map<String, List<NGBSAPI.CalculatedRefundTaxItem>>();

        for (NGBSAPI.CalculatedRefundTaxItem taxItem : wrapper.refundTaxItems) {
            String key = getKey(taxItem.invoiceId, taxItem.itemGroupId);
            if (invoiceIdToItemGroupIdsToTaxes.get(key) == null) {
                invoiceIdToItemGroupIdsToTaxes.put(key, new List<NGBSAPI.CalculatedRefundTaxItem>());
            }
            invoiceIdToItemGroupIdsToTaxes.get(key).add(taxItem);
        }
        return invoiceIdToItemGroupIdsToTaxes;
    }

    private static Map<String, Decimal> getTaxKeyToInitialAmount(NGBSAPI.RefundApplicationMapWrapper wrapper) {
        Map<String, Decimal> keyToInitialAmount = new Map<String, Decimal>();
        for (NGBSAPI.CalculatedRefundTaxItem tax : wrapper.refundTaxItems) {
            String taxKey = tax.invoiceId + ':' + tax.itemGroupId + ':' + tax.taxItemId;
            keyToInitialAmount.put(taxKey, tax.initialAmount);
        }
        return keyToInitialAmount;
    }


    private static List<NGBSAPI.CalculatedRefundTaxItem> getTaxesForProduct(
        ProductItemDTO product,
        Map<String, List<NGBSAPI.CalculatedRefundTaxItem>> keyToTaxes
    ) {
        String key = getKey(product);
        List<NGBSAPI.CalculatedRefundTaxItem> taxItems = keyToTaxes.get(key);

        if (taxItems == null) {
            taxItems = new List<NGBSAPI.CalculatedRefundTaxItem>();
        }
        return taxItems;
    }

    @TestVisible
    private static String replaceTransactionType(String request) {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        if (!featureToggle.ContactCenterRefunds__c &&
            request.containsIgnoreCase(TRANSACTION_WO_TYPE)) {
            request = request.replace(TRANSACTION_WO_TYPE, '');
        }
        return request;
    }
}