public with sharing class Order_SubmitButtonController {
    private static final String recordTypeDevName = 'inContact_Order';
    private static final String contactCentre = 'Contact_Center';
    private static final String warn = 'warn';
    private static final String error = 'error';
    private static final String customContactErrorMessage = 'This account has a custom Contact Center configuration. Contact BizServ Dev Team to place an order.';
    private static final String orderSubmittedErrorMessage = 'The Order is already Submitted. You need to update related InContact Order Case to send changes to InContact.';
    private static final String rampUpPeriodErrorHeader = 'Ramp Up Period is not specified';
    private static String rampUpPeriodErrorMessage = 'Following items XXXX dont have ramp up period specified';
    private static final String inContactSegmentErrorHeader = 'InContact Segment is not specified';
    private static final String inContactSegmentErrorMessage = 'You must select a value for InContact Segment before signing up the customer';
    
    
    @AuraEnabled
    public static ResponseWrapper checkSubmitOrderValidity(String orderIdStr) {
        Id orderId = Id.valueOf(orderIdStr);

        List<Case> cases = [
            Select Id, RecordType.Name, RecordType.DeveloperName from 
            Case where Order__c =: orderId AND 
            RecordType.DeveloperName =: recordTypeDevName
        ];
        
        System.debug('cases : ' + cases);
        
        if(cases.size() > 0) { //Second Validation
            return new ResponseWrapper(error, '', orderSubmittedErrorMessage);
        }
        else {
            List<Productdetail__c> rampUpOrderProducts = [
                SELECT Id,OrderItem__r.Product2.Name FROM Productdetail__c WHERE 
                RampUp__c = null AND 
                OrderItem__r.QuantityOrThreshold__c >= 0 AND 
                OrderItem__r.OrderId =: orderId
            ];
            List<Order> inContactOrders = [
                SELECT Id, RecordType.Name, RecordType.DeveloperName FROM Order WHERE 
                Id =: orderId AND
                RecordType.DeveloperName =: contactCentre and 
                inContact_Segment__c = null
            ];
            
            System.debug('rampUpOrderProducts : ' + rampUpOrderProducts.size() + '\n inContactOrders : ' + inContactOrders.size());              
                            
            if(rampUpOrderProducts.size() > 0) {
                
                String productString = '';
                List<String> productList = new List<String>();
                for(Productdetail__c pd : rampUpOrderProducts){
                    productList.add(pd.OrderItem__r.Product2.Name);
                }
                
                productString = String.join(productList,',');
                rampUpPeriodErrorMessage = rampUpPeriodErrorMessage.replace('XXXX', productString);
                
                return new ResponseWrapper(error, rampUpPeriodErrorHeader, rampUpPeriodErrorMessage);
            }
            else if(inContactOrders.size() > 0) {
                return new ResponseWrapper(error, inContactSegmentErrorHeader, inContactSegmentErrorMessage);
            }
        }
        return new ResponseWrapper('', '', '');
    }

    @AuraEnabled
    public static Boolean resubmitOrder(Id orderId) {
        Order orderItem = Database.query('SELECT Id, BillingStatus__c , BillingStatusDetails__c  FROM Order WHERE ID = ' + '\'' + orderId + '\'');
        Boolean isRejacted = false;

        if (orderItem.BillingStatus__c == 'Rejected') {
            isRejacted = true;
            orderItem.BillingStatus__c = 'Submitted';
            orderItem.BillingStatusDetails__c = ' ';

            update orderItem;
        }
        return isRejacted;
    }
    
    public class ResponseWrapper{
        @AuraEnabled
        public String theme{get;set;}
        @AuraEnabled
        public String header{get;set;}
        @AuraEnabled
        public String details{get;set;}
        public ResponseWrapper(String theme, String header, String details) {
            this.theme = String.isBlank(theme)?'':theme;
            this.header = header;
            this.details = details;
        }
    }
}