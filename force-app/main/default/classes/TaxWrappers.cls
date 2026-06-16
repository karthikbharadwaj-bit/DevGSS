public with sharing class TaxWrappers {

    public class SFDCResponseTax {
        public TaxResponse SFDCTaxResponse;
    }

    public class TaxResponse {
        public TaxResponseData responseData;
        public String requestType;
        public String responseTimestamp;
    }

    public class TaxResponseData {
        public String userId;
        public String quoteId;
        public List<TaxResponseItem> itemList;
        public String status;
        public String message;
    }

    public class TaxResponseItem {
        public String lineId;
        public String RCTaxType;
        public String lineStatus;
        public String lineMessage;
        public List<TaxResponseDataItem> taxData;
    }

    public class TaxResponseDataItem {
        public Integer categoryId;
        public String categoryDescription;
        public String description;
        public Decimal rate;
        public Decimal taxAmount;
        public Integer taxLevel;
        public Integer taxType;
        public Decimal TaxableMeasure;
    }

    public static TaxResponse parse(String json) {
        System.debug('RESPONSE BODY >>>>>>>> ');
        System.debug(json);
        SFDCResponseTax response = (SFDCResponseTax) System.JSON.deserialize(json, SFDCResponseTax.class);
        return response.SFDCTaxResponse;
    }

    public class SFDCRequestTax {
        public TaxRequest SFDCTaxRequest;
    }

    public class TaxRequest {
        public TaxRequestData RequestData;
        public String requestType;
        public String requestTimestamp;
    }

    public class TaxRequestData {
        public String userId;
        public String quoteId;
        public List<TaxRequestItem> itemList;
    }

    public class TaxRequestItem {
        public String lineId;
        public Decimal amount;
        public Decimal NoOfLines;
        public String taxCategory;
        public String currencyCode;
        public String city;
        public String state;
        public String postalCode;
        public String countryCode;
    }
    
    // FSC Credit Memo

    public class SFDCCreditMemoRequest {
        public FSCCreditMemoRequest SFDCFSCRequest;
    }

    public class FSCCreditMemoRequest {
        public List<FSCCreditMemoRequestData> RequestData;
        public String requestTimestamp;
    }

    public class FSCCreditMemoRequestData {
        public String userId;
        public String orderId;
        public Date revRecStartDate;
        public Date revRecEndDate;
        public Decimal FSCTotal;
        public String currencyCode;
        public String term;
    }

    public class SFDCCreditMemoResponse {
        public FSCCreditMemoResponse SFDCFSCResponse;
    }

    public class FSCCreditMemoResponse {
        public List<FSCCreditMemoResponseData> responseData;
        public String responseTimestamp;
    }

    public class FSCCreditMemoResponseData {
        public String userId;
        public String orderId;
        public String status;
        public String NSCreditMemoId;
        public String message;
    }

    public static FSCCreditMemoResponse parseCreditMemoResponse(String json) {
        System.debug('CREDIT MEMO RESPONSE BODY >>>>>>>> ');
        System.debug(json);
        SFDCCreditMemoResponse response = (SFDCCreditMemoResponse) System.JSON.deserialize(json, SFDCCreditMemoResponse.class);
        return response.SFDCFSCResponse;
    }
}