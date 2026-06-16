public without sharing class RefundManagementController {

    public class NGBSTProductDetailsResponseWrapper {
        @AuraEnabled public String billingAccId;
        @AuraEnabled public String transactionId;
        @AuraEnabled public String transactionSubType;
        @AuraEnabled public List<TransactionsRefundsAPI.CostCenter> costCenters;
        @AuraEnabled public List<TransactionsRefundsAPI.ProductItemDTO> productItems;
        @AuraEnabled public String paymentType;
        public NGBSTProductDetailsResponseWrapper(
            String billingAccId,
            String transactionId,
            String transactionSubType,
            List<TransactionsRefundsAPI.CostCenter> costCenters,
            List<TransactionsRefundsAPI.ProductItemDTO> productItems,
            String paymentType
        ) {
            this.billingAccId = billingAccId;
            this.transactionId = transactionId;
            this.transactionSubType = transactionSubType;
            this.costCenters = costCenters;
            this.productItems = productItems;
            this.paymentType = paymentType;
        }
    }

    @AuraEnabled
    public static Response getApprovalInfo(Id approvalId) {
        Approval__c approval = [
            SELECT Id, Name, Account__r.Name, Account__r.Id, CurrencyIsoCode, Account__r.Historical_Master_Account__c,
                    Account__r.RC_User_ID__c, Account__r.Sales_Agreement_Start_Date__c,
                    Account__r.Sales_Agreement_End_Date__c, Account__r.Billing_ID__c,
                    Total_Refund_Amount__c, Amount__c, Category__c, Refund_Type__c, Refund_Product_Family_1__c,
                    Refund_Amount_2__c, Refund_Category_2__c, Refund_Type_2__c, Refund_Product_Family_2__c,
                    Refund_Amount_3__c, Refund_Category_3__c, Refund_Type_3__c, Refund_Product_Family_3__c,
                    Refund_Amount_4__c, Refund_Category_4__c, Refund_Type_4__c, Refund_Product_Family_4__c,
                    Refund_Amount_5__c, Refund_Category_5__c, Refund_Type_5__c, Refund_Product_Family_5__c,
                    Refund_Amount_6__c, Refund_Category_6__c, Refund_Type_6__c, Refund_Product_Family_6__c,
                    TotalRCCoreRefundAmount__c, TotalProServRefundAmount__c, TotalCCRefundAmount__c
            FROM Approval__c
            WHERE Id = :approvalId
        ];

        List<Account> migratedTechnicalAccounts = [
            SELECT Id, Name, Billing_Id__c, Service_Type__c
            FROM Account
            WHERE Historical_Master_Account__c = :approval.Account__r.Id
            AND Billing_Id__c != null
        ];

        Response r = new Response();
        r.setData('approvalRecord', approval);
        r.setData('migratedTechnicalAccounts', migratedTechnicalAccounts);
        r.setData('isReadOnly', isReadOnly(approvalId));
        r.setData('featureToggle', Feature_Toggle__c.getInstance());

        return r;
    }

    @AuraEnabled
    public static TransactionsRefundsAPI.SFDCResponseDTO getTalendTransactions(
            String accUserId,
            String approvalId,
            String transactionType,
            String startDate,
            String endDate
    ) {
        validateDates(startDate, endDate);
        checkPermissions(approvalId);
        TransactionsRefundsAPI.SFDCResponseDTO response = null;
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        try {
            response = TransactionsRefundsAPI.getTalendTransactions(accUserId, (featureToggle.ContactCenterRefunds__c ? transactionType : null), Date.valueOf(startDate), Date.valueOf(endDate));
        } catch (Exception ex){
            AquivaHelper.throwAuraException(ex);
        }
        return response;
    }

    @AuraEnabled
    public static TransactionsRefundsAPI.TransactionInfoResponse getTransactionPagesInfo(String userId, 
        String approvalId, String transactionId, String transactionType) {

        checkPermissions(approvalId);
        TransactionsRefundsAPI.TransactionInfoResponse response;
        try {
            response = TransactionsRefundsAPI.getTalendTransactionPagesInfo(userId, transactionId, transactionType);
        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }
        return response;
    }

    @AuraEnabled
    public static TransactionsRefundsAPI.SFDCResponseDTO getTransactionDetails(String userId, String transactionId, 
        String approvalId, String transactionType, String sessionId, String sessionPageId) {
            
        if (!Feature_Toggle__c.getInstance().Large_Transactions_Processing__c) {
            checkPermissions(approvalId);
        }
        TransactionsRefundsAPI.SFDCResponseDTO response;
        try {
            response = TransactionsRefundsAPI.getTalendTransactionDetails(userId, transactionId, 
            transactionType, sessionId, sessionPageId);
        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }
        return response;
    }

    @AuraEnabled
    public static List <Transaction_History__c> getTalendTransactionHistory (Id approvalId) {
        return [
                SELECT Id, Message__c, RefundAmount__c, Status__c, Type__c,
                        TransactionId__c, CreatedDate, TransactionType__c
                FROM Transaction_History__c
                WHERE Approval__c =: approvalId
        ];
    }

    @AuraEnabled
    public static List<TransactionsRefundsAPI.TransactionsDTO> getNGBSTransactions(
            String accountBillingId,
            String startDate,
            String endDate
    ) {
        Boolean isGetNGBSTransactions = Feature_Toggle__c.getInstance().NGBS_PSR__c;
        if (!isGetNGBSTransactions) {
            return new List<TransactionsRefundsAPI.TransactionsDTO>();
        }

        String format = 'yyyy-MM-dd';
        startDate = NGBSAPI.convertLocalDateToUTC( Date.valueOf(startDate), format );
        endDate = NGBSAPI.convertLocalDateToUTC( Date.valueOf(endDate), format );

        validateDates(startDate, endDate);
        List<TransactionsRefundsAPI.TransactionsDTO> transactions = new List<TransactionsRefundsAPI.TransactionsDTO>();

        try {
            transactions = TransactionsRefundsAPI.getNGBSTransactions(accountBillingId);
            transactions = removeTransactionsOutsideOfRange(transactions, Date.valueOf(startDate), Date.valueOf(endDate));
        } catch (Exception ex){
            AquivaHelper.throwAuraException(ex);
        }
        return transactions;
    }

    @AuraEnabled
    public static NGBSTProductDetailsResponseWrapper getNGBSProductItems(
            String billingAccId,
            String transactionId,
            String ngbsType
    ) {
        TransactionsRefundsAPI.DetailsResponse detailsResponse;
        try {
            if (ngbsType == TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_BILL) {
                detailsResponse = TransactionsRefundsAPI.getNGBSBill(billingAccId, transactionId);
            } else if (ngbsType == TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_INVOICE) {
                detailsResponse = TransactionsRefundsAPI.getNGBSInvoice(billingAccId, transactionId);
            } else {
                AquivaHelper.throwAuraException('Unexpected transaction type received: ' +
                    ngbsType);
            }
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            AquivaHelper.throwAuraException('an exception has occured getting items for transactions ' + e.getMessage());
        }
        NGBSTProductDetailsResponseWrapper responseWrapper =
                new NGBSTProductDetailsResponseWrapper(
                    billingAccId,
                    transactionId,
                    ngbsType,
                    detailsResponse.costCenters,
                    detailsResponse.products,
                    detailsResponse.paymentType
                );
        System.debug('serialized response =>> ' + responseWrapper);
        return responseWrapper;
    }

    @AuraEnabled
    public static TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundsWrapper(
            String postRefundData,
            Id approvalId,
            String accUserId,
            String transactionType
    ) {
        // Lightning fails to properly pass custom type variable. Have to convert it first
        // https://salesforce.stackexchange.com/questions/145357/salesforce-system-error-when-accessing-a-list-in-auraenabled-method
        // Salesforce issue W-3159538
        List<TransactionsRefundsAPI.PostRefundData> postRefundDataConverted =
            new List<TransactionsRefundsAPI.PostRefundData>();
        try {
            postRefundDataConverted = (List<TransactionsRefundsAPI.PostRefundData>)
                JSON.deserialize(postRefundData, List<TransactionsRefundsAPI.PostRefundData>.class);
        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }
        return postRefunds(postRefundDataConverted, approvalId, accUserId, transactionType);
    }

    @AuraEnabled
    public static TransactionsRefundsAPI.PostRefundsResponseWrapper postRefunds(
            List<TransactionsRefundsAPI.PostRefundData> postRefundData,
            Id approvalId,
            String accUserId,
            String transactionType
    ) {
        checkPermissions(approvalId);
        TransactionsRefundsAPI.PostRefundsResponseWrapper response = null;
        try {
            response = TransactionsRefundsAPI.postRefund(postRefundData, approvalId, accUserId, transactionType);
        } catch (Exception ex){
            AquivaHelper.throwAuraException(ex);
        }
        return response;
    }

    @AuraEnabled
    public static Response applyBillingRefund(String billingAccountId, String approvalId, String transactionJson) {

        Response result = new Response();
        NGBSAPI.NGBSTransaction tr;

        try {
            tr = (NGBSAPI.NGBSTransaction) JSON.deserialize(transactionJson, NGBSAPI.NGBSTransaction.class);

            String paramsJson = JSON.serialize(
                new NGBSAPI.RefundRequest(tr)
            );
            System.debug('postRefundData ' + JSON.serialize(paramsJson));
            HttpResponse res = TransactionsRefundsAPI.applyRefundNGBS(billingAccountId, tr.id, paramsJson);

            if(res.getStatusCode() >= 400) {
                result.error();
            }
        } catch (Exception e) {
            result.error(e);
        }

        result.setData(
            'transactionHistory',
            NGBSAPI.createTransactionHistory(tr, result, approvalId)
        );

        return result;
    }

    @AuraEnabled
    public static Response applyInvoiceAdjustment(String billingAccountId, String approvalId, String transactionJson) {

        Response result = new Response();
        NGBSAPI.NGBSTransaction tr;

        try {
            tr = (NGBSAPI.NGBSTransaction) JSON.deserialize(transactionJson, NGBSAPI.NGBSTransaction.class);

            String paramsJson = JSON.serialize(
                new NGBSAPI.InvoiceRequest(tr)
            );

            HttpResponse res = TransactionsRefundsAPI.applyInvoiceAdjustmentNGBS(billingAccountId, paramsJson);

            if(res.getStatusCode() >= 400) {
                result.error();
            }
        } catch (Exception e) {
            result.error(e);
        }

        result.setData(
            'transactionHistory',
            NGBSAPI.createTransactionHistory(tr, result, approvalId)
        );

        return result;
    }

    /**
     * [Checks if refund management page is available for edition]
     * @param  approvalId   [TargetObjectId]
     * @return isReadOnly   [Boolean]
     */
    private static Boolean isReadOnly(Id approvalId) {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        if (!featureToggle.Refund_Management_Read_Only__c) {
            return false;
        }

        Boolean isReadOnly = true;
        List<ProcessInstance> processInstance = [
            SELECT Id, TargetObjectId, Status, CreatedDate
            FROM ProcessInstance
            WHERE TargetObjectId = :approvalId
            ORDER BY CreatedDate DESC
        ];
        if (processInstance.isEmpty()) {
            return isReadOnly;
        }

        List<ProcessInstanceNode> processInstanceNode = [
            SELECT Id, NodeStatus, ProcessNodeName, ProcessInstanceId
            FROM ProcessInstanceNode
            WHERE ProcessInstanceId = :processInstance[0].Id
            AND NodeStatus = 'Pending' LIMIT 1
        ];
        if (processInstanceNode.isEmpty()) {
            return isReadOnly;
        }

        if (processInstanceNode[0].ProcessNodeName == 'For Processing') {
            isReadOnly = false;
        }

        return isReadOnly;
    }

    private static void checkPermissions(Id approvalId){
        if(Test.isRunningTest()) {
            return;
        }
        List<RefundManagementHelper.ErrorWrapper> errors =
                RefundManagementHelper.checkRefundManagementPageAccessPermissions(approvalId);
        if(errors.size() > 0) {
            for(RefundManagementHelper.ErrorWrapper e : errors) {
                AquivaHelper.throwAuraException(e.message);
            }
        }
    }

    @TestVisible
    private static void validateDates(String startDateStr, String endDateStr) {
        Date startDate;
        Date endDate;
        try {
            startDate = Date.valueOf(startDateStr);
        } catch (Exception e) {
            AquivaHelper.throwAuraException('Cannot parse startDate. Received value ' + startDateStr +
                '. Error: ' + e.getMessage());
        }
        try {
            endDate = Date.valueOf(endDateStr);
        } catch (Exception e) {
            AquivaHelper.throwAuraException('Cannot parse startDate. Received value ' + endDateStr +
                '. Error: ' + e.getMessage());
        }
        if (startDate > endDate) {
            AquivaHelper.throwAuraException('End date is more than start date');
        }
    }

    private static List<TransactionsRefundsAPI.TransactionsDTO> removeTransactionsOutsideOfRange(
        List<TransactionsRefundsAPI.TransactionsDTO> transactions,
        Date startDate,
        Date endDate
    ) {
        List<TransactionsRefundsAPI.TransactionsDTO> transactionsWithinRange = new List<TransactionsRefundsAPI.TransactionsDTO>();
        if (transactions == null) {
            transactions = new List<TransactionsRefundsAPI.TransactionsDTO>();
        }
        for (TransactionsRefundsAPI.TransactionsDTO tr : transactions) {
            Date transactionDate = Date.valueOf(tr.transactionDate);
            if (transactionDate >= startDate && transactionDate <= endDate) {
                transactionsWithinRange.add(tr);
            }
        }
        return transactionsWithinRange;
    }
}