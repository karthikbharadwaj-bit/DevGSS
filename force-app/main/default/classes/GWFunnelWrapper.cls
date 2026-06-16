/*
* Name         : GWFunnelWrapper
* Created By   : Fedor Golovanov (fgolovanov@newmarketinc.com)
* Created Date : 06/March/2016
* Description  : B-53 (Sprint 5 Moscow). Refactor SingUp process to use new data model. B-111 (Sprint 7 Moscow) Use old functionality for Pro and Fax Service Plans and Redirect to Old Page.
* Dependencies : SignUpCustomers.cls
*/
public with sharing class GWFunnelWrapper {

    public contactInfo contactInfo{get;set;}
    public Object accountNumbers{get;set;}
    public salesAgentInfo salesAgentInfo{get;set;}
    public List<additionalNumbersInfo> additionalNumbers{get;set;}
    public List<shippingGroupInfo> shippingGroups{get;set;}
    public List<linesInfo> lines{get;set;}

    public Map<String, billingCodeGroupsInfo> billingCodeGroups{get;set;}

    public GWFunnelWrapper(){
    }

    public GWFunnelWrapper(contactInfo contactInfo,
        Object accountNumbers,
        salesAgentInfo salesAgentInfo,
        List<additionalNumbersInfo> additionalNumbers,
        List<shippingGroupInfo>   shippingGroups,
        Map<String, billingCodeGroupsInfo> billingCodeGroups,
        List<linesInfo> lines){

        this.contactInfo = contactInfo;
        this.accountNumbers = accountNumbers;
        this.salesAgentInfo = salesAgentInfo;
        this.additionalNumbers = additionalNumbers;
        this.shippingGroups = shippingGroups;
        this.billingCodeGroups = billingCodeGroups;
        this.lines = lines;
    }

    public class shippingGroupInfo{
        public shippingData shippingAddress;
        public Map<String, Integer> involvedLinesUids{get;set;}

        public shippingGroupInfo(shippingData shippingAddress, Map<String, Integer> involvedLinesUids){
            this.shippingAddress = shippingAddress;
            this.involvedLinesUids = involvedLinesUids;
        }

        public shippingGroupInfo(){
            this.shippingAddress = null;
            this.involvedLinesUids = null;
        }
    }

    public class contactInfo{
        public Integer numberOfLines{get;set;}
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String email{get;set;}
        public String contactPhone{get;set;}
        public String companyName{get;set;}
        public String location{get;set;}
        public Integer areaCode{get;set;}

        public contactInfo(Integer numberOfLines, String firstName, String lastName,
            String email, String contactPhone, String companyName, String location, Integer areaCode){
            this.numberOfLines = numberOfLines;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.contactPhone = contactPhone;
            this.companyName = companyName;
            this.location = location;
            this.areaCode = areaCode;
        }

        public contactInfo(Integer numberOfLines, String firstName, String lastName,
            String email, String contactPhone, String companyName){
            this.numberOfLines = numberOfLines;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.contactPhone = contactPhone;
            this.companyName = companyName;
        }

        public contactInfo(){
            this.numberOfLines = 0;
            this.firstName = null;
            this.lastName = null;
            this.email = null;
            this.contactPhone = null;
            this.companyName = null;
            this.location = null;
            this.areaCode = null;
        }
    }

    public class mainNumberInfo{
        public String paymentType{get;set;}
        public String freePrefix{get;set;}
        public Integer areaCode {get;set;}
        public String country {get;set;}
        public String city {get;set;}

        public mainNumberInfo(String paymentType, String freePrefix, Integer areaCode, String country, String city){
            this.paymentType = paymentType;
            this.freePrefix = freePrefix;
            this.areaCode = areaCode;
            this.country = country;
            this.city = city;
        }

        public mainNumberInfo(){
            this.paymentType = null;
            this.freePrefix = null;
            this.areaCode = null;
            this.country = country;
            this.city = city;
        }
    }

    public class faxNumberInfo{
        public String paymentType{get;set;}
        public String freePrefix{get;set;}
        public Integer areaCode{get;set;}
        public String country{get;set;}
        public String city{get;set;}

        public faxNumberInfo(String paymentType, String freePrefix, Integer areaCode, String country, String city){
            this.paymentType = paymentType;
            this.freePrefix = freePrefix;
            this.areaCode = areaCode;
            this.country = country;
            this.city = city;
        }

        public faxNumberInfo(){
            this.paymentType = null;
            this.freePrefix = null;
            this.areaCode = null;
            this.country = null;
            this.city = null;
        }
    }

    public class salesAgentInfo{
        public String salesAgentId{get;set;}
        public String name{get;set;}

        public salesAgentInfo(String salesAgentId, String name){
            this.salesAgentId = salesAgentId;
            this.name = name;
        }

        public salesAgentInfo(){
            this.salesAgentId = null;
            this.name = null;
        }
    }

    public class phoneNumber{
        public Integer areaCode{get;set;}
        public String country{get;set;}
        public String city{get;set;}

        public phoneNumber(Integer areaCode, String country, String city){
            this.areaCode = areaCode;
            this.country = country;
            this.city = city;
        }

        public phoneNumber(){
            this.areaCode = null;
            this.country = null;
            this.city = null;
        }
    }

    public class deviceType{
        public String id{get;set;}
        public String purchaseType{get;set;}

        public deviceType(String id, String purchaseType){
            this.id = id;
            this.purchaseType = purchaseType;
        }

        public deviceType(){
            this.id = null;
            this.purchaseType = null;
        }
    }

    public class linesInfo{
        public Integer qty{get;set;}
        public phoneNumber phoneNumberInfo{get;set;}
        public deviceType deviceTypeInfo{get;set;}
        public String digitalLineType{get;set;}
        public List<Decimal> itemUids {get;set;}

        public linesInfo(Decimal qty, Integer areaCode, String country, String city,
            String id, String purchaseType, String digitalLineType){
            this.qty = Integer.valueOf(qty);
            this.phoneNumberInfo = new phoneNumber(areaCode, country, city);
            this.deviceTypeInfo = new deviceType(id, purchaseType);
            this.digitalLineType = digitalLineType;
            this.itemUids = null;
        }

        public linesInfo(){
            this.qty = 0;
            this.phoneNumberInfo = new phoneNumber(null, null, null);
            this.deviceTypeInfo = new deviceType(null, null);
            this.digitalLineType = null;
            this.itemUids = null;
        }
    }

    public class paramWrapper{
        public string SAFID{get;set;}
        public string SPID{get;set;}
        public string PARTNERID{get;set;}
        public string OPPID{get;set;}
        public string PID{get;set;}
        public string BMID{get;set;}
        public string TIERTYPE{get;set;}
        public string OID{get;set;}
        public boolean isAdmin{get;set;}
        public integer Qty_lines{get;set;}
        public integer Sa_lines{get;set;}
        public string billtype{get;set;}
        public boolean contract{get;set;}
        public string action{get;set;}
        public boolean annual{get;set;}
        public string bc{get;set;}
        public string abt{get;set;}
        public string brandName{get;set;}

        public string firstName{get;set;}
        public string lastName{get;set;}
        public string email{get;set;}
        public string phone{get;set;}
        public string companyName{get;set;}
        public string numberOfLines{get;set;}
        public string location{get;set;}

        public Integer mainAreaCode{get;set;}
        public Integer faxAreaCode{get;set;}
        public string mainAreaCodePaymentType{get; set;}
        public string mainAreaFreePrefix{get; set;}
        public string faxAreaFreePrefix{get; set;}
        public string faxAreaCodePaymentType{get; set;}
        public string freePrefix{get; set;}
        public string mainAreaCity{get; set;}
        public string mainAreaCountry{get; set;}
        public string faxAreaCity{get; set;}
        public string faxAreaCountry{get; set;}
        public boolean shouldIncludeFaxAreaCode{get; set;}

        public string tierId{get;set;}
        public string approvalId{get;set;}
        public string salesAgentId{get; set;}
        public string salesAgentName{get; set;}

        public string purchaseType{get; set;}
        public Integer qty {get; set;}
        public String products {get; set;}
        public List<QuoteLineItem> lineItemsList = new List<QuoteLineItem>();
        public string areaCode {get; set;}

        public string shippingZipCode{get; set;}
        public string shippingCountry{get; set;}
        public string shippingState{get; set;}
        public string shippingCity{get; set;}
        public List<string> involvedLinesUids{get; set;}
        public string shippingAddressLine1{get; set;}
        public string accountName{get; set;}
        public string taxExempt{get; set;}
        public Boolean setTaxExempt{get; set;}
        public Double freeServiceCredit{get; set;}
        public String creditPhase{get; set;}

        public paramWrapper(){}
    }

    public class ResponseWrapper{
        public string URL {get; set;}
        public string OPPID {get; set;}
        public string SALESAGENTID {get; set;}
        public string GWAPISID {get;set;}

        public ResponseWrapper(){}

        public ResponseWrapper(string URL, string OPPID, string SALESAGENTID, String GWAPISID){
            this.URL = URL;
            this.OPPID = OPPID;
            this.SALESAGENTID = SALESAGENTID;
            this.GWAPISID = GWAPISID;
        }
    }

    public class additionalNumbersInfo{
        public String paymentType{get;set;}
        public String freePrefix{get;set;}
        public Integer qty{get;set;}
        public String areaCode{get;set;}
        public String city{get;set;}
        public String country{get;set;}
        public Map<String, Integer> itemUids{get;set;}

        public additionalNumbersInfo(String paymentType, String freePrefix, Integer qty,
            String areaCode, String city, String country, Map<String, Integer> itemUids){
            this.paymentType = paymentType;
            this.freePrefix = freePrefix;
            this.qty = qty;
            this.areaCode = areaCode;
            this.city = city;
            this.country = country;
            this.itemUids = itemUids;
        }

        public additionalNumbersInfo(){
            this.paymentType = null;
            this.freePrefix = null;
            this.qty = 0;
            this.areaCode = null;
            this.city = null;
            this.country = null;
            this.itemUids = null;
        }
    }

    public class shippingData{

        public String shippingId{get;set;}
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String companyName{get;set;}
        public String addressLine1{get;set;}
        public String country{get;set;}
        public String state{get;set;}
        public String city{get;set;}
        public String zipCode{get;set;}

        public shippingData( String shippingId,
            String firstName, String lastName, String companyName,
            String addressLine1, String country, String state, String city, String zipCode){
            this.shippingId = shippingId;
            this.firstName = firstName;
            this.lastName = lastName;
            this.companyName = companyName;
            this.addressLine1 = addressLine1;
            this.country = country;
            this.state = state;
            this.city = city;
            this.zipCode = zipCode;
        }

        public shippingData(){
            this.shippingId = null;
            this.firstName = null;
            this.lastName = null;
            this.companyName = null;
            this.addressLine1 = null;
            this.country = null;
            this.state = null;
            this.city = null;
            this.zipCode = null;
        }
    }

    public virtual class accountNumbersInfo{
        public mainNumberInfo mainNumber{get;set;}

        public accountNumbersInfo(){}

        public accountNumbersInfo(mainNumberInfo mainNumber){
            this.mainNumber = mainNumber;
        }

    }

    public class accountNumbersInfoWithFax extends accountNumbersInfo{
        public faxNumberInfo faxNumber{get;set;}

        public accountNumbersInfoWithFax(){}

        public accountNumbersInfoWithFax(mainNumberInfo mainNumber, faxNumberInfo faxNumber){
            this.mainNumber = mainNumber;
            this.faxNumber = faxNumber;
        }
    }

    public class billingCodeGroupsInfo{
        public String bcgKey{get;set;}
        public String name{get;set;}
        public String parentBCGId{get;set;}
        public Map<String, String> childBCGIds{get;set;}
        public Map<String, Integer> shippingGroupsItemUids{get;set;}
        public Map<String, Integer> linesItemUids{get;set;}
        public Map<String, Integer> additionalNumbersItemUids{get;set;}

        public billingCodeGroupsInfo(String bcgKey, String name, String parentBCGId,
            Map<String, String> childBCGIds, Map<String, Integer> shippingGroupsItemUids,
            Map<String, Integer> linesItemUids, Map<String, Integer> additionalNumbersItemUids){
            this.bcgKey = bcgKey;
            this.name = name;
            this.parentBCGId = parentBCGId;
            this.childBCGIds = childBCGIds;
            this.shippingGroupsItemUids = shippingGroupsItemUids;
            this.linesItemUids = linesItemUids;
            this.additionalNumbersItemUids = additionalNumbersItemUids;
        }

        public billingCodeGroupsInfo(){
            this.bcgKey = null;
            this.name = null;
            this.parentBCGId = null;
            this.childBCGIds = null;
            this.shippingGroupsItemUids = null;
            this.linesItemUids = null;
            this.additionalNumbersItemUids = null;
        }
    }

    public class LineItemOrder implements Comparable {

        public Decimal  quantity;
        public sObject obj;

        public LineItemOrder(Decimal q, sObject o) {
            Quantity = q;
            obj = o;
        }

        public Integer compareTo(Object compareTo) {
            LineItemOrder compareToLI = (LineItemOrder)compareTo;
            if (quantity == compareToLI.quantity) {
                return 0;
            }
            if (quantity > compareToLI.quantity) {
                return 1;
            }
            return -1;
        }
    }

    public String createJSONRequest(paramWrapper paramWrapperObj){
        Integer counter = 0;

        contactInfo contactInfoObject = new contactInfo(
                (paramWrapperObj.numberOfLines != NULL ? Integer.valueOf(paramWrapperObj.numberOfLines) : 0),
                paramWrapperObj.firstName,
                paramWrapperObj.lastName,
                paramWrapperObj.email,
                paramWrapperObj.phone,
                paramWrapperObj.companyName,
                paramWrapperObj.location,
                paramWrapperObj.mainAreaCode);

        mainNumberInfo mainNumberInfoObject = new mainNumberInfo(
                paramWrapperObj.mainAreaCodePaymentType,
                paramWrapperObj.mainAreaFreePrefix,
                paramWrapperObj.mainAreaCode,
                paramWrapperObj.mainAreaCountry,
                paramWrapperObj.mainAreaCity);


        faxNumberInfo faxNumberInfoObject = new faxNumberInfo(
                paramWrapperObj.faxAreaCodePaymentType,
                paramWrapperObj.faxAreaFreePrefix,
                paramWrapperObj.faxAreaCode,
                paramWrapperObj.faxAreaCountry,
                paramWrapperObj.faxAreaCity);

        Object accountNumbersObject = paramWrapperObj.shouldIncludeFaxAreaCode ?
                new accountNumbersInfoWithFax(mainNumberInfoObject, faxNumberInfoObject) :
                new accountNumbersInfo(mainNumberInfoObject);

        salesAgentInfo salesAgentInfoObject = new salesAgentInfo(
                paramWrapperObj.salesAgentId,
                paramWrapperObj.salesAgentName);

        
        Map<String, linesInfo> linesInfoMap = createMapOfLinesInfoObjects( paramWrapperObj, counter );
        List<linesInfo> linePhones = linesInfoMap.values();

        Map<String, additionalNumbersInfo> additionalNumbersInfoMap = processAdditionalNumbers(
                paramWrapperObj.lineItemsList,
                counter);
          


        shippingData shippingData = new shippingData(
                null,
                paramWrapperObj.firstName,
                paramWrapperObj.lastName,
                paramWrapperObj.accountName,
                paramWrapperObj.shippingAddressLine1,
                paramWrapperObj.shippingCountry,
                paramWrapperObj.shippingState,
                paramWrapperObj.shippingCity,
                paramWrapperObj.shippingZipCode);

        Map<String, Integer> involvedLinesUids = new Map<String, Integer> ();

        shippingGroupInfo shippingGroupInfoObject = new shippingGroupInfo(shippingData, involvedLinesUids);
        shippingGroups = new List<shippingGroupInfo>();
        shippingGroups.add(shippingGroupInfoObject );

        Map<String, billingCodeGroupsInfo> billingCodeGroupsInfoMap = new Map<String, billingCodeGroupsInfo>();
        billingCodeGroupsInfo billingCodeGroupsInfoObject = new billingCodeGroupsInfo();
        billingCodeGroupsInfoMap.put(String.valueOf(counter), billingCodeGroupsInfoObject);

        GWFunnelWrapper gWFunnelWrapperObject = new GWFunnelWrapper(contactInfoObject, accountNumbersObject,
                                                    salesAgentInfoObject, additionalNumbersInfoMap.values(), shippingGroups,
                                                    billingCodeGroupsInfoMap, linePhones);
        String requestJSON = JSON.serializePretty(gWFunnelWrapperObject);
        System.debug('JSON val is>>>>'+requestJSON);

        String encodedJSON = EncodingUtil.Base64Encode( Blob.valueOf(requestJSON) );
        System.debug('Encoded JSON is>>>>'+encodedJSON);

        return encodedJSON;
    }

    private Map<String, linesInfo> createMapOfLinesInfoObjects( paramWrapper paramWrapperObj, Integer counter ) {

        return processOtherBrands( paramWrapperObj, counter );
    }

    private static final String COMMON_PHONE_DL_TYPE = 'CommonPhone';
    private static final String DIGITAL_LINE_DL_TYPE = 'DigitalLine';
    private List<String> funnelNotSupportedProductsInfoList = new List<String>();
    //Pre-define items families that needs to be covered  
    Set<String> familiesToProcess = new Set<String> {'Discounted Phones', 'Rental Phones', 'Refurbished Phones', 'Common Phones'};

    private Map<String, linesInfo> processOtherBrands(paramWrapper paramWrapperObj, Integer counter ) {
        Map<String, linesInfo> linesInfoMap = new Map<String, linesInfo>();
        
        Boolean isProServ = false;
        Decimal quantity = 0;

        if ( paramWrapperObj.products != null && paramWrapperObj.products.contains('Professional Services') ) {
            isProServ = true;
        }


        Map<String, Integer> flMap = buildFunnelLimitationMap();

        Map<Id, QuoteLineItem> notSendedQliMap = new Map<Id, QuoteLineItem>();

        Decimal qliQuantitySum = 0;
        Boolean quantityIsValid = false;

        for (QuoteLineItem lineItem : paramWrapperObj.lineItemsList) {

            String purchaseType;
            String digitalLineType;
            String productCode;

            if (lineItem.Product2.Feature__c == 11) {
                purchaseType = 'PUR';
            } else if (lineItem.Product2.Feature__c == 39) {
                purchaseType = 'REF';
            } else if (lineItem.Product2.Feature__c == 34) {
                purchaseType = 'REN';
            }

            if (lineItem.Product2.Family == 'Common Phones') {
                digitalLineType = COMMON_PHONE_DL_TYPE;
            } else {
                digitalLineType = DIGITAL_LINE_DL_TYPE;
            }
            if (lineItem.Product2.Feature__c == 3 || lineItem.Product2.Feature__c == 2) {
                qliQuantitySum +=lineItem.Quantity;
                quantityIsValid = qliQuantitySum > checkFunnelLimitation(lineItem);
            }

            productCode = lineItem.Product2.ProductCode;

            if (purchaseType != null) {

                //Update line item info with the softphones when professional services exists
                if(isProServ){
                    if(digitalLineType == DIGITAL_LINE_DL_TYPE){
                        purchaseType = 'PUR';
                        productCode = 'SP';
                    }else{
                        productCode = 'PLCM_VVX311';
                    }
                }


                //Set key as areacode + productcode
                String key = isProServ ? ((lineItem.Quote.AreaCode__c != null ? String.valueOf(lineItem.Quote.AreaCode__c) : '') + digitalLineType) : String.valueOf(lineItem.Id);
                
                String fKey = buildKeyForFunnelMap(lineItem);
                Integer currentFunnelLimitation = flMap.get(fKey);

                if(familiesToProcess.contains(lineItem.Product2.Family)) {
                    if(lineItem.Area_Code_Line_Items__r.isEmpty() && lineItem.Quote.AreaCode__c != null) {

                        //process single item
                        Integer quantityToSend = Integer.valueOf(lineItem.Quantity);

                        if( currentFunnelLimitation != null) {

                            Boolean isCanSendThisQuantityToFunnel = currentFunnelLimitation == -1 || ((currentFunnelLimitation - lineItem.Quantity) > 0 );

                            if(!isCanSendThisQuantityToFunnel) {

                                quantityToSend = currentFunnelLimitation == -1 ? quantityToSend : currentFunnelLimitation;

                                Integer quantityOfNotSendedProducts = Integer.valueOf(lineItem.Quantity - quantityToSend);

                                if(quantityOfNotSendedProducts > 0) {

                                    String descr = makeDescription(quantityOfNotSendedProducts, lineItem, null, funnelNotSupportedProductsInfoList.size());

                                    funnelNotSupportedProductsInfoList.add( descr );
                                }
                            }

                            flMap.put(fKey, flMap.get(fKey) - quantityToSend);
                        }

                        if(quantityToSend > 0) {

                            linesInfoMap = processLineInfoWithAreaCodes(linesInfoMap, key, quantityToSend,
                                                            Integer.ValueOf(lineItem.Quote.AreaCode__r.Name), lineItem.Quote.AreaCode__r.Country__c,
                                                            lineItem.Quote.AreaCode__r.City__c, productCode, purchaseType, digitalLineType);

                        }
                    }else {

                        //process multiply items
                        for(Area_Code_Line_Item__c areaCodeLineItem : lineItem.Area_Code_Line_Items__r) {

                            currentFunnelLimitation = flMap.get(fKey);
                        

                            Integer quantityToSend = Integer.valueOf(areaCodeLineItem.Quantity__c);


                            if( currentFunnelLimitation != null ) {

                                Boolean isCanSendThisQuantityToFunnel = currentFunnelLimitation == -1 || ((currentFunnelLimitation - areaCodeLineItem.Quantity__c) > 0 );

                                if(!isCanSendThisQuantityToFunnel) {

                                    quantityToSend = currentFunnelLimitation == -1 ? quantityToSend : currentFunnelLimitation;

                                    Integer quantityOfNotSendedProducts = Integer.valueOf(areaCodeLineItem.Quantity__c - quantityToSend);

                                    if(quantityOfNotSendedProducts > 0) {

                                        String descr = makeDescription(quantityOfNotSendedProducts, lineItem, areaCodeLineItem, funnelNotSupportedProductsInfoList.size());

                                        funnelNotSupportedProductsInfoList.add( descr );
                                    }
                                }

                                flMap.put(fKey, flMap.get(fKey) - quantityToSend);
                            }


                            if(quantityToSend > 0) {

                                key = isProServ ? areaCodeLineItem.Area_Code__c + digitalLineType : areaCodeLineItem.Id;
                                linesInfoMap = processLineInfoWithAreaCodes(linesInfoMap, key, quantityToSend,
                                                                        Integer.ValueOf(areaCodeLineItem.Area_Code__r.Name), areaCodeLineItem.Area_Code__r.Country__c,
                                                                        areaCodeLineItem.Area_Code__r.City__c, productCode, purchaseType, digitalLineType);
                            }
                        }
                    }

                }else{
                    notSendedQliMap.put(lineItem.Id, lineItem);
                }

            }else {
                notSendedQliMap.put(lineItem.Id, lineItem);
            }

        }

        if(notSendedQliMap.size() > 0) {

            funnelNotSupportedProductsInfoList = processNotSendedProducts(notSendedQliMap.values(), funnelNotSupportedProductsInfoList, linesInfoMap);
        }


        Map<Id, Account> accIdToAccountMap = new Map<Id, Account>();

        if( funnelNotSupportedProductsInfoList.size() > 0 ) {

            String headerForFunnelNotSupported = makeHeaderForFunnelNotSupported(paramWrapperObj.lineItemsList[0].Quote.AccountId, paramWrapperObj.lineItemsList[0].Quote.OpportunityId);

            for (QuoteLineItem lineItem : paramWrapperObj.lineItemsList) {

                Integer feature17Limit = getFunnelLimitForFeature17();

                Boolean populateFunnelNotSupported = (lineItem.Quote.isPrimary__c == true) 
                                                    && (lineItem.Quote.Total_Number_of_Digital_Lines__c > feature17Limit || quantityIsValid);

                // if funnel limit == -1 - it is mean there is no limit
                if(feature17Limit == -1) {
                    populateFunnelNotSupported = false;
                }

                String funnelNotSupportedValue;

                if(populateFunnelNotSupported) {

                    funnelNotSupportedValue = (headerForFunnelNotSupported + String.join(funnelNotSupportedProductsInfoList, '\n\n'));

                }else{
                    funnelNotSupportedValue = null;
                }

                accIdToAccountMap.put(
                    lineItem.Quote.AccountId,
                    new Account(
                        Id = lineItem.Quote.AccountId,
                        Funnel_not_supported__c = funnelNotSupportedValue
                    )
                );
            }

        }else{
            for (QuoteLineItem lineItem : paramWrapperObj.lineItemsList) {

                accIdToAccountMap.put(
                    lineItem.Quote.AccountId,
                    new Account(
                        Id = lineItem.Quote.AccountId,
                        Funnel_not_supported__c = null
                    )
                );
            }
        }

        if(accIdToAccountMap.size() > 0) {

            // update accs after callout!
            SignUpCustomers.accsToUpdateFunnelNotSupported = accIdToAccountMap.values();
        }


        return linesInfoMap;
    }


    //Process quote line item to create or update line item infos
    private Map<String, linesInfo> processLineInfoWithAreaCodes(Map<String, linesInfo> linesInfoMap, String key, Decimal qty, 
                                                                Integer areaCode, String country, String city,
                                                                String devId, String purchaseType, String digitalLineType){

        if(linesInfoMap.containsKey(key)){
            //only add qty if needed
            linesInfoMap.get(key).qty += Integer.ValueOf((qty != null ? qty : 0));

        }else{
            //create new item
            linesInfo tempInfo = new linesInfo(qty, areaCode, country, city, devId ,purchaseType, digitalLineType);
            linesInfoMap.put(key, tempInfo);

        }

        return linesInfoMap;
    }


    private List<String> processNotSendedProducts(List<QuoteLineItem> notSendedQlis, List<String> funnelNotSupportedProductsInfoList, Map<String, linesInfo> linesInfoMap) {
        
        // accumulates areaCodeLineItems Quantity for Products with features 2 & 3
        Integer accum = 0;

        for(QuoteLineItem qli : notSendedQlis) {

            Integer currentFunnelLimitation = checkFunnelLimitation(qli);
            
            Boolean isDigitalLineProduct = qli.Product2.Family == 'Service' && qli.Product2.Feature__c == 17;

            Boolean isHotDeskingProduct = qli.Product2.Feature__c == 50 && qli.Quote.isPrimary__c ==true;

            Boolean isAdditionalNumber = (qli.Product2.Feature__c == 2 || qli.Product2.Feature__c == 3) && qli.Quote.isPrimary__c ==true;
            
            if(isDigitalLineProduct) {

                Integer sendedDigitalLineCount = 0;

                for(linesInfo item : linesInfoMap.values()) {

                    if(item.digitalLineType == DIGITAL_LINE_DL_TYPE) {
                        sendedDigitalLineCount += item.qty;
                    }
                }

                Integer notSendedDigitalLineCount = Integer.valueOf(qli.Quantity) - sendedDigitalLineCount;

                if(notSendedDigitalLineCount > 0) {

                    String descr = makeDescription(notSendedDigitalLineCount, qli, null, funnelNotSupportedProductsInfoList.size());

                    funnelNotSupportedProductsInfoList.add( descr );
                }

            }else if(isHotDeskingProduct) {

                Integer sendedCommonPhonesCount = 0;

                for(linesInfo item : linesInfoMap.values()) {

                    if(item.digitalLineType == COMMON_PHONE_DL_TYPE) {
                        sendedCommonPhonesCount += item.qty;
                    }
                }

                Integer notSendedCommonPhonesCount = Integer.valueOf(qli.Quantity) - sendedCommonPhonesCount;

                if(notSendedCommonPhonesCount > 0) {

                    String descr = makeDescription(notSendedCommonPhonesCount, qli, null, funnelNotSupportedProductsInfoList.size());

                    funnelNotSupportedProductsInfoList.add( descr );
                }

            }else if (isAdditionalNumber) {

                Integer sendedAdditionalNumber = currentFunnelLimitation;
                Integer notSendedAdditionalNumber = Integer.valueOf(qli.Quantity) - sendedAdditionalNumber;

                // When quantity of additional numbers in the cart > is allowed in "Supported_In_Funnel__c" custom setting
                if (notSendedAdditionalNumber > 0 || 
                    Integer.valueOf(qli.Quantity) > (currentFunnelLimitation - accum)) {

                    Integer leftItemsToSend = 0;


                    //if there are Area_Code_Line_Items under the product
                    if (qli.Area_Code_Line_Items__r.size() > 0){
                        //Sort descending by quantity AreaCodeLineItems inside one QuoteLineItem
                        List <Area_Code_Line_Item__c> acliSorted = customSort(qli.Area_Code_Line_Items__r,'Area_Code_Line_Item__c');
              
                        for(Area_Code_Line_Item__c areaCodeLineItem : acliSorted) {

                            leftItemsToSend = currentFunnelLimitation - accum;

                            if (leftItemsToSend > 0){

                                // don't send to the Funnel and store them in "Funnel not supported" on Account
                                if (leftItemsToSend <=  Integer.valueOf(areaCodeLineItem.Quantity__c)){
                                    String descr = makeDescription(Integer.valueOf(areaCodeLineItem.Quantity__c - leftItemsToSend) , qli, areaCodeLineItem, funnelNotSupportedProductsInfoList.size());
                                    funnelNotSupportedProductsInfoList.add( descr );
                                }

                            } else {

                                String descr = makeDescription(Integer.valueOf(areaCodeLineItem.Quantity__c) , qli, areaCodeLineItem, funnelNotSupportedProductsInfoList.size());
                                funnelNotSupportedProductsInfoList.add( descr );
                            }
                            accum += Integer.valueOf(areaCodeLineItem.Quantity__c);
                        }
                    }
                    //if there are no Area_Code_Line_Items under the product
                    else {
                        leftItemsToSend = currentFunnelLimitation - accum;

                        if (leftItemsToSend > 0){

                            // don't send to the Funnel and store them in "Funnel not supported" on Account
                            if (leftItemsToSend <=  Integer.valueOf(qli.Quantity)){
                                String descr = makeDescription(Integer.valueOf(qli.Quantity - leftItemsToSend) , qli, null, funnelNotSupportedProductsInfoList.size());
                                funnelNotSupportedProductsInfoList.add( descr );
                            }

                        } else {

                            String descr = makeDescription(Integer.valueOf(qli.Quantity) , qli, null, funnelNotSupportedProductsInfoList.size());
                            funnelNotSupportedProductsInfoList.add( descr );
                        }
                        accum += Integer.valueOf(qli.Quantity);    

                    }

                }else {
                    accum += Integer.valueOf(qli.Quantity);
                }

            }else if(currentFunnelLimitation != -1) {

                if(qli.Area_Code_Line_Items__r.isEmpty()) {

                    String descr = makeDescription(Integer.valueOf(qli.Quantity), qli, null, funnelNotSupportedProductsInfoList.size());

                    funnelNotSupportedProductsInfoList.add( descr );

                }else {

                    for(Area_Code_Line_Item__c areaCodeLineItem : qli.Area_Code_Line_Items__r) {

                        String descr = makeDescription(Integer.valueOf(areaCodeLineItem.Quantity__c), qli, areaCodeLineItem, funnelNotSupportedProductsInfoList.size() );
                        
                        funnelNotSupportedProductsInfoList.add( descr );
                    }
                }

            }

        }

        return funnelNotSupportedProductsInfoList;
    }

    private String makeHeaderForFunnelNotSupported(Id accountId, Id opportunityId) {

        String headerStirng = '';

        String urlToAccount = URL.getOrgDomainUrl().toExternalForm() + '/' + accountId;
        String urlToOpportunity = URL.getOrgDomainUrl().toExternalForm() + '/' + opportunityId;

        headerStirng += 'Account: "' + urlToAccount + '" \n';
        headerStirng += 'Opportunity: "' + urlToOpportunity + '" \n\n';

        headerStirng += 'Products that should be provisioned manually: \n\n';

        return headerStirng;
    }

    private String makeDescription(Integer quantity, QuoteLineItem qli, Area_Code_Line_Item__c acli, Integer funnelNotSupportedSize) {

        String descrForCurrentProduct = makeDescriptionForProduct(quantity, qli, acli);

        String serialNumber = String.valueOf(funnelNotSupportedSize + 1) + '. ';
        
        return serialNumber + descrForCurrentProduct;
    }

    private String makeDescriptionForProduct(Integer quantity, QuoteLineItem qli, Area_Code_Line_Item__c acli) {
        
        String resultStr = '';

        resultStr += 'Product Name: "' + qli.Product2.Name + '"\n';
        resultStr += 'Charge Term: "' + qli.Product2.Charge_Term__c + '"\n';
        resultStr += 'Category: "' + qli.Product2.Family + '"\n';
        resultStr += 'Quantity: ' + quantity + '\n';
        if(qli.Discount_number__c != null) {
            resultStr += 'Discount: ' + qli.Discount_number__c + ' ' + (qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ? '% ' : qli.CurrencyIsoCode) + ' \n\n';
        }else{
            resultStr += 'Discount: ' + '0 ' + (qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ? ' % ' : qli.CurrencyIsoCode) + ' \n\n';
        }

        Boolean shouldAddAreaCodesInfo = qli.Product2.Family != null && (familiesToProcess.contains(qli.Product2.Family) || qli.Product2.Feature__c == 2 || qli.Product2.Feature__c == 3);

        if( shouldAddAreaCodesInfo ) {

            if(acli != null) {
                String areaCodeCity = acli.Area_Code__r.City__c != null ? acli.Area_Code__r.City__c : '';
                resultStr += 'Area Code: ' + acli.Area_Code__r.Name + ' ' + areaCodeCity + ' ' + acli.Area_Code__r.Country__c + '\n';
            }else {
                resultStr += 'Area Code: ' + qli.Quote.AreaCode__r.Name + ' ' + qli.Quote.AreaCode__r.City__c + ' ' + qli.Quote.AreaCode__r.Country__c + '\n';
            }
        }

        return resultStr;
    }

    private Integer checkFunnelLimitation(QuoteLineItem qli) {
        // if product does not exist in custom setting - return null
        // if product exist but FunnelLimitation == null - return -1
        // in other cases return limit as integer

        Integer result;

        for(Supported_In_Funnel__c item : Supported_In_Funnel__c.getAll().values()) {

            Set<String> featureSet = splitAndMakeSet(item.Feature__c);

            Boolean isAnyFeature = (featureSet.size() == 1 && featureSet.contains('any'));

            Set<String> familySet = splitAndMakeSet(item.Family__c);
            Boolean isAnyFamily = (familySet.size() == 1 && familySet.contains('any'));

            Set<String> subFeatureSet = splitAndMakeSet(item.SubFeature__c);
            Boolean isAnySubFeature = (subFeatureSet.size() == 1 && subFeatureSet.contains('any'));

            if(isAnyFeature || featureSet.contains( String.valueOf(qli.Product2.Feature__c) ) || ((qli.Product2.Feature__c == null) && (featureSet.size() == 0))) {

                if(isAnySubFeature || subFeatureSet.contains( String.valueOf(qli.Product2.Sub_Feature__c) ) || ((qli.Product2.Sub_Feature__c == null) && (subFeatureSet.size() == 0))) {

                    if(isAnyFamily || familySet.contains(qli.Product2.Family) || ((qli.Product2.Family == null) && (familySet.size() == 0))) {
                        
                        result = (item.Funnel_Limitation__c == null) ? -1 : Integer.valueOf(item.Funnel_Limitation__c);
                    }
                }
            }
        }

        return result;
    }

    public static Integer getFunnelLimitForFeature17() {
        // find limit in custom setting for Feature '17' and Family 'Service'

        Integer result;

        List<Supported_In_Funnel__c> sifList = Supported_In_Funnel__c.getAll() == null ? null : Supported_In_Funnel__c.getAll().values();

        if(sifList == null || sifList.isEmpty()) {
            return result;
        }

        for(Supported_In_Funnel__c item : sifList) {

            Set<String> featureSet = splitAndMakeSet(item.Feature__c);
            Boolean isAnyFeature = (featureSet.size() == 1 && featureSet.contains('any'));

            Set<String> familySet = splitAndMakeSet(item.Family__c);
            Boolean isAnyFamily = (familySet.size() == 1 && familySet.contains('any'));

            Set<String> subFeatureSet = splitAndMakeSet(item.SubFeature__c);
            Boolean isAnySubFeature = (subFeatureSet.size() == 1 && subFeatureSet.contains('any'));

            if(isAnyFeature || featureSet.contains( '17' )) {

                if(isAnySubFeature) {

                    if(isAnyFamily || familySet.contains('Service')) {

                        result = (item.Funnel_Limitation__c == null) ? -1 : Integer.valueOf(item.Funnel_Limitation__c);
                    }
                }
            }
        }

        return result;
    }

    private static Set<String> splitAndMakeSet(String fieldValue) {

        Set<String> resultSet = new Set<String>();

        if( String.isNotBlank(fieldValue) ) {

            if(fieldValue.contains(',')) {

                for(String splittedVal : fieldValue.split(',')) {
                    resultSet.add( splittedVal.trim() );
                }

            }else {
                resultSet.add(fieldValue);
            }
        }

        return resultSet;
    }


    public String buildKeyForFunnelMap(QuoteLineItem qli) {

        String key;

        for(Supported_In_Funnel__c item : Supported_In_Funnel__c.getAll().values()) {

            Set<String> featureSet = splitAndMakeSet(item.Feature__c);
            Boolean isAnyFeature = (featureSet.size() == 1 && featureSet.contains('any'));

            Set<String> familySet = splitAndMakeSet(item.Family__c);
            Boolean isAnyFamily = (familySet.size() == 1 && familySet.contains('any'));

            Set<String> subFeatureSet = splitAndMakeSet(item.SubFeature__c);
            Boolean isAnySubFeature = (subFeatureSet.size() == 1 && subFeatureSet.contains('any'));

            Integer fLimit = (item.Funnel_Limitation__c == null) ? -1 : Integer.valueOf(item.Funnel_Limitation__c);

            Map<Integer, Integer> hashCodeToFunnelLimitationMap = new Map<Integer, Integer>();

            if(isAnyFeature || featureSet.contains( String.valueOf(qli.Product2.Feature__c) ) || ((qli.Product2.Feature__c == null) && (featureSet.size() == 0))) {

                if(isAnySubFeature || subFeatureSet.contains( String.valueOf(qli.Product2.Sub_Feature__c) ) || ((qli.Product2.Sub_Feature__c == null) && (subFeatureSet.size() == 0))) {

                    if(isAnyFamily || familySet.contains(qli.Product2.Family) || ((qli.Product2.Family == null) && (familySet.size() == 0))) {

                        key = '' + System.hashCode(featureSet) + System.hashCode(familySet) + System.hashCode(subFeatureSet);
                    }
                }
            }
        }

        return key;
    }

    public Map<String, Integer> buildFunnelLimitationMap() {

        Map<String, Integer> funnelLimitationMap = new Map<String, Integer>();

        for(Supported_In_Funnel__c item : Supported_In_Funnel__c.getAll().values()) {

            Set<String> featureSet = splitAndMakeSet(item.Feature__c);
            Boolean isAnyFeature = (featureSet.size() == 1 && featureSet.contains('any'));

            Set<String> familySet = splitAndMakeSet(item.Family__c);
            Boolean isAnyFamily = (familySet.size() == 1 && familySet.contains('any'));

            Set<String> subFeatureSet = splitAndMakeSet(item.SubFeature__c);
            Boolean isAnySubFeature = (subFeatureSet.size() == 1 && subFeatureSet.contains('any'));

            Integer fLimit = (item.Funnel_Limitation__c == null) ? -1 : Integer.valueOf(item.Funnel_Limitation__c);


            String key = '' + System.hashCode(featureSet) + System.hashCode(familySet) + System.hashCode(subFeatureSet);

            funnelLimitationMap.put(key, fLimit);
        }

        return funnelLimitationMap;
    }

    private Map<String, additionalNumbersInfo> processAdditionalNumbers(List<QuoteLineItem> items, Integer globalCounter){

        Map<String, additionalNumbersInfo> additionalNumbersMap = new Map<String, additionalNumbersInfo>();
        Map<Id, String> areaCodeItem = new Map<Id, String>();
        String localCounter = '';

        // accumulates areaCodeLineItems Quantity for Products with features 2 & 3
        Integer accum = 0;

        //Collect area code information from the line items
        for(QuoteLineItem lineItem : items){
            Integer quantityToSend;
            Integer leftItemsToSend = 0;
            Integer currentFunnelLimitation = checkFunnelLimitation(lineItem);
            if(lineItem.Product2.Feature__c == 2 || lineItem.Product2.Feature__c == 3){
                if(lineItem.Product2.Feature__c == 3 && lineItem.Area_Code_Line_Items__r.isEmpty() && lineItem.Quote.AreaCode__c != null){
                    
                    quantityToSend = Integer.ValueOf(lineItem.Quantity);
                    if (accum < currentFunnelLimitation) {
                        leftItemsToSend = currentFunnelLimitation - accum;
                        if (leftItemsToSend <= Integer.ValueOf(lineItem.Quantity)) {
                            quantityToSend = leftItemsToSend;
                        }
                        //Create temp Area_Code_Line_Item__c for the non existing items.
                        if(!areaCodeItem.containsKey(lineItem.Quote.AreaCode__c)){
                            additionalNumbersInfo tempInfo = populateAdditionalInfoFields(new additionalNumbersInfo(), 
                                                                                          lineItem.Quote.AreaCode__r.Type__c,
                                                                                          Integer.ValueOf(lineItem.Quantity) != null ?quantityToSend :0,
                                                                                          lineItem.Quote.AreaCode__r.Name,
                                                                                          lineItem.Quote.AreaCode__r.City__c,
                                                                                          lineItem.Quote.AreaCode__r.Country__c);
                            localCounter = String.valueOf(globalCounter++);
                            areaCodeItem.put(lineItem.Quote.AreaCode__c, localCounter);
                            additionalNumbersMap.put(localCounter, tempInfo);

                        }else{
                            //Add more quantity if there is already created additional number with the same area code id.
                            additionalNumbersMap.get(areaCodeItem.get(lineItem.Quote.AreaCode__c)).qty += Integer.ValueOf(lineItem.Quantity);
                        
                        }
                    }
                accum += Integer.ValueOf(LineItem.Quantity);

                }else{
                    
                    //Sort descending by quantity AreaCodeLineItems inside one QuoteLineItem
                    List <Area_Code_Line_Item__c> acliSorted = customSort(lineItem.Area_Code_Line_Items__r,'Area_Code_Line_Item__c');

                    //If area code line items exists process them and create additionalNumbersInfos.
                    for(Area_Code_Line_Item__c areaCodeLineItem : acliSorted){
                        
                            quantityToSend = Integer.ValueOf(areaCodeLineItem.Quantity__c);
                            
                            if (accum < currentFunnelLimitation) {
                                leftItemsToSend = currentFunnelLimitation - accum;
                                if (leftItemsToSend <= Integer.ValueOf(areaCodeLineItem.Quantity__c)) {
                                    quantityToSend = leftItemsToSend;
                                }
                                if(!areaCodeItem.containsKey(areaCodeLineItem.Area_Code__c)){
                                additionalNumbersInfo tempInfo = populateAdditionalInfoFields(new additionalNumbersInfo(), 
                                                                                      areaCodeLineItem.Area_Code__r.Type__c,
                                                                                      (areaCodeLineItem.Quantity__c != null ? quantityToSend : 0),
                                                                                      areaCodeLineItem.Area_Code__r.Name,
                                                                                      areaCodeLineItem.Area_Code__r.City__c,
                                                                                      areaCodeLineItem.Area_Code__r.Country__c);
                                localCounter = String.valueOf(globalCounter++);
                                areaCodeItem.put(areaCodeLineItem.Area_Code__c, localCounter);
                                additionalNumbersMap.put(localCounter, tempInfo);
                                } else{
                                    //Add more quantity if there is already created additional number with the same area code id.
                                    additionalNumbersMap.get(areaCodeItem.get(areaCodeLineItem.Area_Code__c)).qty += (areaCodeLineItem.Quantity__c != null ? Integer.ValueOf(areaCodeLineItem.Quantity__c) : 0);
                                }
                            }
                        accum += Integer.ValueOf(areaCodeLineItem.Quantity__c);
                    }
                }
            }
        }
        
        return additionalNumbersMap;
    }

    private additionalNumbersInfo populateAdditionalInfoFields(additionalNumbersInfo addInfo, String areaCodeType, Integer areaCodeQty,  
                                                             String areaCodeName, String areaCodeCity, String areaCodeCountry){

        if(areaCodeType == 'Toll-Free'){
            addInfo.freePrefix = areaCodeName;
        }else if(areaCodeType == 'Local'){
            addInfo.areaCode = areaCodeName;
            addInfo.city = areaCodeCity;
        }

        addInfo.paymentType = (areaCodeType!=null ? areaCodeType.remove('-') : null);
        addInfo.country = areaCodeCountry;
        addInfo.qty = areaCodeQty;

        return addInfo;

    }
    
    //Sorts Objects in descending order by Quantity
    public List<sObject> customSort(List<sObject> objectList, String sobjectName){
        List<sObject> sortedObjectList = objectList;
        List<LineItemOrder> itemsList = new List<LineItemOrder> ();
        sortedObjectList = new List<sObject>();
        for (sObject obj : objectList){
            if ('Area_Code_Line_Item__c'.equalsIgnoreCase(sobjectName)){
                Area_Code_Line_Item__c qli = (Area_Code_Line_Item__c) obj;
                LineItemOrder item = new LineItemOrder(
                        qli.Quantity__c,
                        obj
                );
                itemsList.add(item);
            }
            if ('QuoteLineItem'.equalsIgnoreCase(sobjectName)){
                QuoteLineItem qli = (QuoteLineItem) obj;
                LineItemOrder item = new LineItemOrder(
                        qli.Quantity,
                        obj
                );
                itemsList.add(item);
            }
        }
        itemsList.sort();
        for(Integer i = itemsList.size() - 1; i >= 0; i--){
            sortedObjectList.add(itemsList[i].obj);
        }   
        return sortedObjectList;         
    }
}