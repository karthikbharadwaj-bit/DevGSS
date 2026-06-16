public with sharing class CreditMemoService implements Queueable,  Database.AllowsCallouts {

    private Map<Id, Order> acceptedCCFSCOrders;
    private static final String ORDER_NOT_ACCEPTED_ERROR = 'Billing Status is not Accepted';
    private static final String IS_NOT_CC_ORDER_ERROR = 'Available only for Contact Center orders';
    private static final String ORDER_FSC_TOTAL_ERROR = 'FSC Total Amount value is less or equal zero';
    private static final String ORDER_CREDIT_MEMO_ERROR = 'Credit Memo Id alredy exist on Order';
    private static final String ORDER_FAILED_RESPONSE_ERROR = 'Failed to get Credit Memo Id';
    private static final String BRAND_ERROR = 'Available only for RingCentral brands';
    private static final String SUBMITTED_ERROR = 'Order is not Submitted';
    private static final String SUCCESS_MESSAGE = 'Sync FSC successfully passed';
    private static final String WARNING_STATUS = 'warning';
    private static final String ERROR_STATUS = 'error';
    private static final String SUCCESS_STATUS = 'success';
    private static Date revRecStart;
    private static Date revRecEnd;

    public CreditMemoService(Map<Id, Order> acceptedCCFSCOrders) {
        this.acceptedCCFSCOrders = acceptedCCFSCOrders;
    }

    public void execute(QueueableContext context) {
        getCreditMemoIds(acceptedCCFSCOrders, false);
    }

    @AuraEnabled
    public static SyncFSCWrapper reSyncFSCButton(Id orderId) {
        Map<Id, Order> reSyncOrder = new Map<Id, Order>(
            [SELECT Submitted_Date__c, FSC_Total_Amount__c, CurrencyIsoCode, Opportunity.Brand_Name__c, 
                    CC_FSC_CreditMemo__c, BillingStatus__c, RecordType.Name 
            FROM Order 
            WHERE Id =: orderId]
        );
        if (!reSyncOrder.get(orderId).RecordType.Name.containsIgnoreCase(OrderHelper.RT_NAME_CC)) {
            return new SyncFSCWrapper(WARNING_STATUS, IS_NOT_CC_ORDER_ERROR);
        } else if (reSyncOrder.get(orderId).BillingStatus__c != OrderHelper.STATUS_ACCEPTED) {
            return new SyncFSCWrapper(WARNING_STATUS, ORDER_NOT_ACCEPTED_ERROR);
        } else if (reSyncOrder.get(orderId).FSC_Total_Amount__c <= 0) {
            return new SyncFSCWrapper(WARNING_STATUS, ORDER_FSC_TOTAL_ERROR);
        } else if (!String.isEmpty(reSyncOrder.get(orderId).CC_FSC_CreditMemo__c)) {
            return new SyncFSCWrapper(WARNING_STATUS, ORDER_CREDIT_MEMO_ERROR);
        } else if (!reSyncOrder.get(orderId).Opportunity.Brand_Name__c.containsIgnoreCase(OpportunityHelper.BRAND_RINGCENTRAL)) {
            return new SyncFSCWrapper(WARNING_STATUS, BRAND_ERROR);
        } else if (reSyncOrder.get(orderId).Submitted_Date__c == null) {
            return new SyncFSCWrapper(WARNING_STATUS, SUBMITTED_ERROR);
        } else {
            String resultMessage = getCreditMemoIds(reSyncOrder, true);
            if (resultMessage == SUCCESS_MESSAGE) {
                return new SyncFSCWrapper(SUCCESS_STATUS, resultMessage);
            } else {
                return new SyncFSCWrapper(ERROR_STATUS, resultMessage);
            }
        }
    }

    public class SyncFSCWrapper {
        @auraEnabled public String status;
        @auraEnabled public String message;

        public SyncFSCWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }

    public static String getCreditMemoIds(Map<Id, Order> ccOrders, Boolean isResyncButton) {
        TaxWrappers.SFDCCreditMemoRequest cMemoRequest = getCMemoRequestBody(ccOrders);
    
        return getCreditMemoCallout(JSON.serialize(cMemoRequest), ccOrders.keySet());
    }
    
    public static TaxWrappers.SFDCCreditMemoRequest getCMemoRequestBody(Map<Id, Order> ccOrders) {
        List<Order> currentOrders = [SELECT Account.RC_User_ID__c, Quote.Initial_Term_months__c, Quote.Payment_Plan__c  
                                    FROM Order 
                                    WHERE Order.Id IN :ccOrders.keySet()];

        TaxWrappers.SFDCCreditMemoRequest requestBody = new TaxWrappers.SFDCCreditMemoRequest();
        requestBody.SFDCFSCRequest = new TaxWrappers.FSCCreditMemoRequest();
        requestBody.SFDCFSCRequest.requestTimestamp = String.valueOf(DateTime.now());
        requestBody.SFDCFSCRequest.RequestData = new List<TaxWrappers.FSCCreditMemoRequestData>();

        for (Order currentOrder : currentOrders) {
            String rcUserId = String.isBlank(currentOrder.Account.RC_User_ID__c) ? '0' : currentOrder.Account.RC_User_ID__c;
            
            if (ccOrders.get(currentOrder.Id).Submitted_Date__c != null) {
                Date submittedDate = ccOrders.get(currentOrder.Id).Submitted_Date__c.date();
                Integer termMonths = Integer.valueOf(currentOrder.Quote.Initial_Term_months__c);
                calculateDates(submittedDate, termMonths);
            } else {
                revRecStart = null;
                revRecEnd = null;
            }

            String paymentPlan = Product2Helper.isMonthly(currentOrder.Quote.Payment_Plan__c) ? 
                                Product2Helper.CHARGE_TERM_MONTHLY : Product2Helper.CHARGE_TERM_ANNUAL;

            TaxWrappers.FSCCreditMemoRequestData dataItem = new TaxWrappers.FSCCreditMemoRequestData();
            dataItem.userId = rcUserId;
            dataItem.orderId = currentOrder.Id;
            dataItem.revRecStartDate = revRecStart;
            dataItem.revRecEndDate = revRecEnd;
            dataItem.FSCTotal = ccOrders.get(currentOrder.Id).FSC_Total_Amount__c;
            dataItem.currencyCode = ccOrders.get(currentOrder.Id).CurrencyIsoCode;
            dataItem.term = paymentPlan;

            requestBody.SFDCFSCRequest.RequestData.add(dataItem);
        }

        return requestBody;
    }

    private static void calculateDates(Date submittedDate, Integer termMonths) {
        Date calcDate;

        if (submittedDate.day() > 15) {
            submittedDate = submittedDate.addMonths(1);
        }

        calcDate = submittedDate.toStartOfMonth();
        revRecStart = submittedDate.toStartOfMonth();

        calcDate = calcDate.addMonths(termMonths);
        calcDate = calcDate.addMonths(-1);
        
        Integer lastDayOfMonth = Date.daysInMonth(calcDate.year(), calcDate.month());
        revRecEnd = Date.newInstance(calcDate.year(), calcDate.month(), lastDayOfMonth);
    }

    public static String getCreditMemoCallout(String cMemoRequest, Set<Id> ccOrders) {
        Map<String, String> orderIdToCreditMemoId = new Map<String, String>();

        Contact_Center_FSC__c settings = Contact_Center_FSC__c.getInstance(UserInfo.getUserId());
        if (settings == null || String.isEmpty(settings.Credit_Memo_Endpoint__c)) {
            settings = Contact_Center_FSC__c.getInstance();
        }

        String creditMemoEndpoint = settings.Credit_Memo_Endpoint__c;

        if (String.isEmpty(creditMemoEndpoint)) {
            sendLogEmail(settings, ccOrders, null, null);
            return ORDER_FAILED_RESPONSE_ERROR;
        }

        HTTP http = new HTTP();
        HTTPRequest request = new HTTPRequest();

        request.setEndpoint(creditMemoEndpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setTimeout(120000);
        request.setBody(cMemoRequest);

        HTTPResponse response = http.send(request);

        String failureMessage = '';
        if(response.getStatusCode() == 200) {
            TaxWrappers.FSCCreditMemoResponse responseWrapper = TaxWrappers.parseCreditMemoResponse(response.getBody());

            for (TaxWrappers.FSCCreditMemoResponseData item : responseWrapper.responseData) {
                if (item.status == 'success') {
                    orderIdToCreditMemoId.put(item.orderId, item.NSCreditMemoId);
                } else if (String.isEmpty(failureMessage)){
                    failureMessage = response.getBody();
                }
            }
        } else {
            failureMessage += response.toString();
        }

        updateOrderCreditMemo(orderIdToCreditMemoId);

        if (!String.isEmpty(failureMessage)) {
            sendLogEmail(settings, null, JSON.serialize(cMemoRequest), failureMessage);
            return ORDER_FAILED_RESPONSE_ERROR;
        } else {
            return SUCCESS_MESSAGE;
        }
    }

    public static void updateOrderCreditMemo(Map<String, String> orderIdToCreditMemoId) {
        if (orderIdToCreditMemoId.isEmpty()){
            return;
        }

        Map<Id, Order> ordersToUpdate = new Map<Id, Order>();

        for (String orderId : orderIdToCreditMemoId.keySet()) {
            Order updateOrder = new Order(
                Id = orderId,
                CC_FSC_CreditMemo__c = orderIdToCreditMemoId.get(orderId)
            );

            ordersToUpdate.put(updateOrder.Id, updateOrder);
        }

        Triggers.switchOff();
        update ordersToUpdate.values();
        Triggers.switchOn();
    }

    private static void sendLogEmail(Contact_Center_FSC__c settings, Set<Id> ordersIds, String request, String response) {
        if (String.isEmpty(settings.EmailForCreditMemoFailures__c)){
            return;
        }

        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setSaveAsActivity(false);
        emailMessage.setToAddresses(new List<String>{settings.EmailForCreditMemoFailures__c});
        emailMessage.setSubject('Failure on getting Credit Memo Id for CC Orders');

        if (String.isEmpty(settings.Credit_Memo_Endpoint__c)) {
            String allIds = '' + ordersIds;
            emailMessage.setHtmlBody(
                'Empty endpoint for getting Credit Memo Id'
                + '<br/>Timestamp: ' + System.now().formatGmt('dd/MM/yyyy HH:mm:ss')
                + '<br/><br/>CC Order Ids:<br/>' + allIds
            );
        } else if (!String.isEmpty(request) && !String.isEmpty(response)){
            emailMessage.setHtmlBody(
                'Failure on getting Credit Memo Id for CC Orders: '
                + '<br/>Timestamp: ' + System.now().formatGmt('dd/MM/yyyy HH:mm:ss')
                + '<br/><br/>Request:<br/>' + request.escapeHtml4()
                + '<br/><br/>Response:<br/>' + response.escapeHtml4()
            );
        }

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
    }

}