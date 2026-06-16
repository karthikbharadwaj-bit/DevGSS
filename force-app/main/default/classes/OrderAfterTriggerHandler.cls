public with sharing class OrderAfterTriggerHandler {

    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
    Quote.SObjectType.getDescribe().getRecordTypeInfosByName();
    private static final Id PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get('ProServ Quote').getRecordTypeId();
    private static final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get('CC ProServ Quote').getRecordTypeId();

    private static final Map<ID,Schema.RecordTypeInfo> ordersRecTypeMap = Order.sObjectType.getDescribe().getRecordTypeInfosById();

    private static final Map<Id, Schema.RecordTypeInfo> quoteRTInfoByIdStaticMap = Quote.sObjectType.getDescribe().getRecordTypeInfosById();
    private static final Map<String, Schema.RecordTypeInfo> phaseRTInfoByNameStaticMap = Phase__c.sObjectType.getDescribe().getRecordTypeInfosByName();

    public static Map<Id, Phase__c> phaseMapStatic = new Map<Id, Phase__c>();

    public static Boolean throwTestError = false;

    // B-802 Updated Order and Site Object for CloudConnect
    public static void insertOrders( Map<Id, Order> ordersMap ) {

        List<Order> ordersProServ = filterOrdersByRecordType(ordersMap.values(), 'Professional Services');

        if( !ordersProServ.isEmpty() ) {
            createSiteRecords( ordersProServ );
        }

        if( Test.isRunningTest() && throwTestError ) {
            throw new DMLException('test dml exception');
        }

    }

    private static void createSiteRecords( LIst<Order> orders ) {
        List<Site__c> sites = new List<Site__c>();
        String address;

        for( Order o : orders ) {
            address = o.BillingStreet + ', ' + o.BillingCity + ', ' + o.BillingState + ' ' + o.BillingPostalCode + ', ' + o.BillingCountry;
            for( Integer i = 0; i < o.NumberOfSites__c; i++ ) {
                Site__c site = new Site__c(
                Name = 'Site ' + ( i + 1 ),
                Order__c = o.Id,
                Address__c = address,
                PrimaryITContactInChargeWAN__c = o.MainPointOfContact__c
                );
                sites.add( site );
            }
        }

        insert sites;
    }

    public static void activateOrdersAuto( Map<Id, Order> ordersMap ) {
        List<Order> ordersContactCenterProvisioned = returnOrderWithThisRecType( ordersMap.values(), 'Contact Center', 'Provisioned');
        if( !ordersContactCenterProvisioned.isEmpty() ) {
            for( Order o : ordersContactCenterProvisioned ) {
                ApexWebServices.activateOrderWithChildren( o.Id, true );
            }
        }
    }

    private static List<Order> returnOrderWithThisRecType( List<Order> orders, String recordTypeName, String status ) {
        List<Order> ordersWithThisRecType = new List<Order>();

        for( Order o : orders ) {
            if ( ordersRecTypeMap.get( o.recordTypeId ).getName() == recordTypeName && o.Status == status ) {
                ordersWithThisRecType.add( o );
            }
        }

        return ordersWithThisRecType;
    }

    private static List<Order> filterOrdersByRecordType(List<Order> orders, String recordTypeName) {
        List<Order> ordersWithThisRecType = new List<Order>();

        for( Order o : orders ) {
            if ( ordersRecTypeMap.get( o.recordTypeId ).getName() == recordTypeName ) {
                ordersWithThisRecType.add( o );
            }
        }

        return ordersWithThisRecType;
    }
    //Override method for case when need to receive orders simultaneously with different recordTypes and statuses
    private static List<Order> returnOrderWithThisRecType( List<Order> orders, Map<String, Set<String>> recordTypeToStatusListMap) {
        List<Order> ordersWithThisRecType = new List<Order>();

        for( Order o : orders ) {
            String recordTypeName = ordersRecTypeMap.get(o.recordTypeId).getName();
            if(recordTypeToStatusListMap.containsKey(recordTypeName)
            && recordTypeToStatusListMap.get(recordTypeName).contains(o.Status)) {
                ordersWithThisRecType.add(o);
            }
        }
        return ordersWithThisRecType;
    }

    //Prepare the data that will be used in email templates
    private static Map <Id, OpportunityInfo> prepareData(List<Order> orders) {
        //Build quote Id to order list map
        Map <Id, List <Order>> quoteIdToOrderListMap = new Map <Id, List <Order>>();
        for (Order o : orders) {
            if (!quoteIdToOrderListMap.containsKey(o.QuoteId)) {
                quoteIdToOrderListMap.put(o.QuoteId, new List<Order>());
            }
            quoteIdToOrderListMap.get(o.QuoteId).add(o);
        }

        //Build opportunity id to opportunityInfo map
        Map <Id, OpportunityInfo> opprotunityIdToOpportunityInfoMap = new Map <Id, OpportunityInfo>();
        Boolean proservOrderIsGenerated = false;
        if (!quoteIdToOrderListMap.isEmpty()) {
            //Get quotes for which orders where created
            List<Quote> quoteList = [SELECT Account.Name, Account.Number_of_DL_s__c, AccountId, OpportunityId,
            Opportunity.Primary_Opportunity_Contact__c, Total_Number_of_Digital_Lines__c
            FROM Quote
            WHERE Id IN: quoteIdToOrderListMap.keyset()];
            //Populate OpportunityInfo object records
            for (Quote item : quoteList) {
                if (!opprotunityIdToOpportunityInfoMap.containsKey(item.OpportunityId)) {
                    opprotunityIdToOpportunityInfoMap.put(item.OpportunityId, new OpportunityInfo());
                }
                //Populate OpportunityInfo object with necessary data
                OpportunityInfo optyInfo = opprotunityIdToOpportunityInfoMap.get(item.OpportunityId);
                optyInfo.accountName = item.Account.Name;
                optyInfo.accountId = item.AccountId;
                optyInfo.primaryContact = item.Opportunity.Primary_Opportunity_Contact__c;
                optyInfo.digitalLinesNumber = item.Account.Number_of_DL_s__c;

                for (Order orderRecord : quoteIdToOrderListMap.get(item.Id)) {
                    //If professional services order is generated
                    if (orderRecord.RecordTypeId ==
                    Schema.SObjectType.Order.getRecordTypeInfosByName().get(PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME).getRecordTypeId()) {
                        optyInfo.proservOrderNumber = orderRecord.OrderNumber;
                        optyInfo.proservOrderId = orderRecord.Id;
                        proservOrderIsGenerated = true;
                    }
                    //If ringCentral order is generated
                    if (orderRecord.RecordTypeId ==
                    Schema.SObjectType.Order.getRecordTypeInfosByName().get(RINGCENTRAL_ORDER_RECORDTYPE_NAME).getRecordTypeId()) {
                        optyInfo.rcOrderNumber = orderRecord.OrderNumber;
                        optyInfo.rcOrderId = orderRecord.Id;
                    }
                }
            }
        }
        //Email should be sent only when proserv order is generated
        if (proservOrderIsGenerated) {
            return opprotunityIdToOpportunityInfoMap;
        } else {
            return (new Map<Id, OpportunityInfo>());
        }
    }


    public static void syncEntitlements(Map<Id, Order> oldOrderMap, Map< Id, Order> newOrderMap) {
        Schema.DescribeSObjectResult objectDesc = Order.SObjectType.getDescribe();
        Map<Id, Schema.RecordTypeInfo> rtMapByID = objectDesc.getRecordTypeInfosById();

        for (Order ord : newOrderMap.values()) {
            if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(rtMapByID.get(ord.RecordTypeId).getName())
            && ord.Status == 'Submitted'
            && ord.Status != oldOrderMap.get(ord.Id).Status) {
                List<OrderItem> ordItems = [SELECT Id, Active__c, RC_Entitlement__c, Qty__c, Order.Submitted_Date__c,
                Insert_Entitlement__c, Pricebookentry.Product2Id,
                Pricebookentry.Product2.Family, UnitPrice, Pricebookentry.Product2.Feature__c,
                Pricebookentry.Product2.Name, Pricebookentry.Product2.Edition__c,
                Pricebookentry.CurrencyIsoCode,CurrencyIsoCode, UnitPriceWithoutDiscount__c,
                Quantity, Discount_Number__c, Discount_Type__c, Zero_Quantity__c,
                ServiceDate, Matcher_Formula__c, QuantityOrThreshold__c, Pricebookentry.Product2.Parent__c,
                (SELECT Id, QuantityOrThreshold__c, RampUpStartDate__c, RampUp__c,
                OrderItem__r.Order.Submitted_Date__c, Entitlement__c, ProductDetail__c, OrderItem__r.RC_Entitlement__c
                FROM Product_Details__r)
                FROM OrderItem
                WHERE OrderId = :ord.Id];
                EntitlementSync.syncEntitlements(ord, ordItems);
            }
        }
    }

    public static void sendMessages( Map<Id, Order> ordersMap ) {
        //Get address from custom setting to which the email should be sent
        List<String> emailAddresses = new List<String>();
        if (Emails__c.getall().get('proservleaders') == null || !String.isNotBlank(Emails__c.getall().get('proservleaders').Email_Address__c) ) {
            return;
        }
        emailAddresses.add( Emails__c.getall().get('proservleaders').Email_Address__c );
        //Get the appropriate email template
        EmailTemplate template = [SELECT Id, Name, DeveloperName, Body, HtmlValue, Subject
        FROM EmailTemplate
        WHERE DeveloperName = 'Created_Professional_Services_or_Cloud_Connect' LIMIT 1];
        String emailSubject = template.Subject;
        String emailHtmlBody = template.HtmlValue;
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        //Get orders with appropriate record type and appropriate status
        List<Order> orders = returnOrderWithThisRecType(ordersMap.values(), new Map <String, Set<String>>{
            PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME =>
            new Set<String>{'Requested', 'New', 'Submitted', 'Submitted for Partners'},
            RINGCENTRAL_ORDER_RECORDTYPE_NAME =>
            new Set<String>{'Submitted'} });

        Map <Id, OpportunityInfo> opprotunityIdToOpportunityInfoMap = prepareData(orders);
        if (!opprotunityIdToOpportunityInfoMap.isEmpty()) {
            for (OpportunityInfo item : opprotunityIdToOpportunityInfoMap.values()) {
                //Find and replace place holders with corresponding values in the template
                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', item.accountName);
                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' + item.accountId);

                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{proservOrderNumber\\}', item.proservOrderNumber);
                emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{proservOrderNumberLink\\}', baseUrl + '/' + item.proservOrderId);

                if (item.rcOrderNumber == null) {
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{RingCentral Order:\\}', '');
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{rcOrderNumber\\}', '');
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{rcOrderNumberLink\\}', '');
                } else {
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{RingCentral Order:\\}', 'RingCentral Order:');
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{rcOrderNumber\\}', item.rcOrderNumber);
                    emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{rcOrderNumberLink\\}', baseUrl + '/' + item.rcOrderId);
                }

                String quoteDigitalLinesBlock = item.digitalLinesNumber == null
                ? ''
                : ' - ' + item.digitalLinesNumber + ' users';
                emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountName\\}', item.accountName);
                emailSubject = emailSubject.replaceAll('(?i)\\$\\{QuoteDigitalLines\\}', quoteDigitalLinesBlock);

                //Send email only if proserv order is generated and if Primary_Opportunity_Contact__c on opportunity is not empty
                if (!emailAddresses.isEmpty() && String.isNotBlank(item.primaryContact) && item.proservOrderId != null) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(emailAddresses);
                    mail.setSubject(emailSubject);
                    mail.setHtmlBody(emailHtmlBody);
                    mail.setTemplateId(template.Id);
                    mail.setTreatTargetObjectAsRecipient(false);
                    mail.setSaveAsActivity(false);

                    mails.add(mail);
                }
            }
        }
        if (!mails.isEmpty()) {
            List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(mails);
        }
    }

    private static final String RINGCENTRAL_ORDER_RECORDTYPE_NAME = 'RingCentral';
    private static final String PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME = 'Professional Services';
    private static final String CC_PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME = 'CC Professional Services';
    private static final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
    private static final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';
    private static final String RC_HARDWARE_PHASE_RT_NAME = 'RingCentral Hardware Phase';
    private static final String PROSERV_PHASE_RT_NAME = 'ProServ Phase';

    public static void createPhases(Map<Id, Order> ordersNewMap) {

        Set<Id> quoteIdSet = new Set<Id>();

        for(Order item : ordersNewMap.values()) {

            String currentOrderRtName = ordersRecTypeMap.get( item.RecordTypeId ).getName();

            Boolean isSuitableRecordType = (currentOrderRtName == RINGCENTRAL_ORDER_RECORDTYPE_NAME ||
            currentOrderRtName == PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME ||
            currentOrderRtName == CC_PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME);

            if(isSuitableRecordType) {

                quoteIdSet.add(item.QuoteId);
            }
        }

        System.debug('in createPhases. quoteIdSet.size() >>> ' + quoteIdSet.size());

        if(quoteIdSet.size() > 0) {

            Map<Id, Quote> quotesMap = new Map<Id, Quote>([SELECT Id, RecordTypeId,
            OpportunityId, Products__c,
            Number_of_ProServ_Phases__c,
            Number_of_Hardware_Shipment_Phases__c
            FROM Quote
            WHERE Id IN :quoteIdSet]);

            System.debug('quotesMap.size() >>> ' + quotesMap.size());

            Map<Id, List<Quote>> opportunityIdToQuoteListMap = buildOpportunityIdToQuoteListMap(quotesMap);
            System.debug('opportunityIdToQuoteListMap.size() >>> ' + opportunityIdToQuoteListMap.size());

            List<Phase__c> createdPhasesList = new List<Phase__c>();

            for(Order item : ordersNewMap.values()) {

                if(quoteIdSet.contains(item.QuoteId) && quotesMap.containsKey(item.QuoteId)) {

                    Quote currentQuote = quotesMap.get(item.QuoteId);

                    List<String> splittedProducts = currentQuote.Products__c != null ? currentQuote.Products__c.split(';') : new List<String>();

                    Set<String> splittedProductsSet = new Set<String>(splittedProducts);

                    List<Phase__c> phasesList = generatePhases(currentQuote, item, opportunityIdToQuoteListMap, splittedProductsSet);

                    createdPhasesList.addAll(phasesList);
                }
            }

            System.debug('createdPhasesList.size() >>>> ' + createdPhasesList.size());

            if(createdPhasesList.size() > 0) {
                insert createdPhasesList;
                System.debug('createdPhasesList >>>> ' + createdPhasesList);
            }
        }
    }

    private static Map<Id, List<Quote>> buildOpportunityIdToQuoteListMap(Map<Id, Quote> quotesMap) {

        Set<Id> opportunityIdSet = new Set<Id>();

        for(Quote item : quotesMap.values()) {

            opportunityIdSet.add(item.OpportunityId);
        }

        Map<Id, List<Quote>> opportunityIdToQuoteListMap = new Map<Id, List<Quote>>();

        if(opportunityIdSet.size() > 0) {

            for(Quote item : [SELECT Id, RecordTypeId,
            OpportunityId, Products__c,
            Number_of_ProServ_Phases__c,
            Number_of_Hardware_Shipment_Phases__c
            FROM Quote
            WHERE OpportunityId IN :opportunityIdSet]) {

                if(!opportunityIdToQuoteListMap.containsKey(item.OpportunityId)) {
                    opportunityIdToQuoteListMap.put(item.OpportunityId, new List<Quote>());
                }
                opportunityIdToQuoteListMap.get(item.OpportunityId).add(item);
            }

        }

        return opportunityIdToQuoteListMap;
    }

    private static Quote findQuoteByOppIdAndRTName(Id oppId, String quoteRtName, Map<Id, List<Quote>> opportunityIdToQuoteListMap) {

        Quote result = null;

        if(oppId == null || quoteRtName == null || opportunityIdToQuoteListMap == null) {
            return result;
        }

        if(opportunityIdToQuoteListMap.containsKey(oppId)) {

            for(Quote item : opportunityIdToQuoteListMap.get(oppId)) {

                String currentQuoteRtName = quoteRTInfoByIdStaticMap.get( item.RecordTypeId ).getName();

                if(currentQuoteRtName == quoteRtName) {

                    result = item;
                }
            }
        }

        return result;
    }

    private static List<Phase__c> generatePhases(Quote currentQuote, Order currentOrder, Map<Id, List<Quote>> opportunityIdToQuoteListMap, Set<String> splittedProductsSet) {

        List<Phase__c> result = new List<Phase__c>();

        String currentOrderRtName = ordersRecTypeMap.get( currentOrder.RecordTypeId ).getName();

        Boolean productsContainsCCProServ = splittedProductsSet.contains('CC Professional Services');

        if(productsContainsCCProServ) {
            splittedProductsSet.remove('CC Professional Services');
        }

        Boolean productsContainsProServ = splittedProductsSet.contains('Professional Services');

        if(productsContainsCCProServ && !productsContainsProServ) {

            if(currentOrderRtName == CC_PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME) {

                Quote ccProServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, CC_PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(ccProServQuote != null) {

                    List<Phase__c> createdPhasesList = generateProServPhases(currentOrder, ccProServQuote.Number_of_ProServ_Phases__c);

                    result.addAll(createdPhasesList);
                }
            }

        }else if(!productsContainsCCProServ && productsContainsProServ) {

            if(currentOrderRtName == PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME) {

                Quote proServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(proServQuote != null) {

                    List<Phase__c> createdPhasesList = generateProServPhases(currentOrder, proServQuote.Number_of_ProServ_Phases__c);

                    result.addAll(createdPhasesList);
                }

            }else if(currentOrderRtName == RINGCENTRAL_ORDER_RECORDTYPE_NAME) {

                Quote proServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(proServQuote != null) {

                    List<Phase__c> createdPhasesList = generateHardwarePhases(currentOrder, proServQuote.Number_of_Hardware_Shipment_Phases__c);

                    result.addAll(createdPhasesList);
                }
            }

        }else if(productsContainsCCProServ && productsContainsProServ) {

            if(currentOrderRtName == PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME) {

                Quote proServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(proServQuote != null) {

                    List<Phase__c> createdPhasesList = generateProServPhases(currentOrder, proServQuote.Number_of_ProServ_Phases__c);

                    result.addAll(createdPhasesList);
                }

            }else if(currentOrderRtName == RINGCENTRAL_ORDER_RECORDTYPE_NAME) {

                Quote proServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(proServQuote != null) {

                    List<Phase__c> createdPhasesList = generateHardwarePhases(currentOrder, proServQuote.Number_of_Hardware_Shipment_Phases__c);

                    result.addAll(createdPhasesList);
                }

            }else if(currentOrderRtName == CC_PROFESSIONAL_SERVICES_ORDER_RECORDTYPE_NAME) {

                Quote ccProServQuote = findQuoteByOppIdAndRTName(currentQuote.OpportunityId, CC_PROSERV_QUOTE_RT_NAME, opportunityIdToQuoteListMap);

                if(ccProServQuote != null) {

                    List<Phase__c> createdPhasesList = generateProServPhases(currentOrder, ccProServQuote.Number_of_ProServ_Phases__c);

                    result.addAll(createdPhasesList);
                }

            }
        }

        return result;
    }

    private static List<Phase__c> generateProServPhases(Order currentOrder, Decimal phaseCount) {

        phaseCount = phaseCount == null ? 0 : phaseCount;

        Integer phaseCountInt = Integer.valueOf(phaseCount);

        Id proservPhaseRTId = phaseRTInfoByNameStaticMap.get(PROSERV_PHASE_RT_NAME).getRecordTypeId();

        Date todayDate = Date.today();

        List<Phase__c> createdPhases = new List<Phase__c>();

        for(Integer i = 0; i < phaseCountInt; i++) {

            String phaseName = 'ProServ Phase ' + (i + 1);

            Phase__c proServPhase = new Phase__c(
            RecordTypeId = proservPhaseRTId,
            Name = phaseName,
            Account__c = currentOrder.AccountId,
            Opportunity__c = currentOrder.OpportunityId,
            Order__c = currentOrder.Id,
            Completed_Date__c = null,
            Estimated_Completion_Date__c = todayDate
            );

            createdPhases.add(proServPhase);
        }

        return createdPhases;
    }

    private static List<Phase__c> generateHardwarePhases(Order currentOrder, Decimal phaseCount) {

        phaseCount = phaseCount == null ? 0 : phaseCount;

        Integer phaseCountInt = Integer.valueOf(phaseCount);

        Id rcHardwarePhaseRTId = phaseRTInfoByNameStaticMap.get(RC_HARDWARE_PHASE_RT_NAME).getRecordTypeId();

        List<Phase__c> createdPhases = new List<Phase__c>();

        for(Integer i = 0; i < phaseCountInt; i++) {

            String phaseName = 'Hardware Phase ' + (i + 1);

            Phase__c rcHardwarePhase = new Phase__c(
            RecordTypeId = rcHardwarePhaseRTId,
            Name = phaseName,
            Account__c = currentOrder.AccountId,
            Opportunity__c = currentOrder.OpportunityId,
            Order__c = currentOrder.Id,
            Initial_Payment__c = null,
            Rental_Phones_MRR__c = null,
            Ship_Date__c = null
            );

            createdPhases.add(rcHardwarePhase);
        }

        return createdPhases;
    }

    //Is used to map phase object to corresponding order
    public static void mapPhaseToOrder(Map<Id, Order> ordersMap) {
        //Build quote id to created order map
        Map<Id, Order> quoteIdToOrderMap = buildQuoteIdToOrderMap(ordersMap);
        //Get phases for the opportunities for which orders where created
        Map <Id, Phase__c> phaseMap = new Map<Id, Phase__c>([SELECT Id, Order__c, Opportunity__c, Quote__c FROM Phase__c WHERE Quote__c IN:quoteIdToOrderMap.keyset()]);
        if (!phaseMap.isEmpty()) {
            //Build quote id to phase list map
            Map<Id, List<Phase__c>> quoteIdToPhaseListMap = buildQuoteIdToPhaseListMap(phaseMap);
            for (Id quoteId : quoteIdToPhaseListMap.keyset()) {
                for(Phase__c ph : quoteIdToPhaseListMap.get(quoteId)) {
                    ph.Order__c = quoteIdToOrderMap.get(quoteId).Id;
                    phaseMapStatic.put(ph.Id, ph);
                }
            }
            //Update phases
            if(!phaseMapStatic.isEmpty()) {
                update phaseMapStatic.values();
            }
        }
    }


    private static Map<Id, Order> buildQuoteIdToOrderMap(Map<Id,Order> ordersMap) {
        Map<Id, Order> quoteIdToOrderMap = new Map<Id, Order>();
        for(Order item : ordersMap.values()) {
            if (item.RecordTypeId == OrderHelper.RT_ID_PROSERV || item.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) {
                quoteIdToOrderMap.put(item.QuoteId, item);
            }
        }
        return quoteIdToOrderMap;
    }

    private static Map<Id,List<Phase__c>> buildQuoteIdToPhaseListMap(Map<Id, Phase__c> phaseMap) {
        Map<Id, List <Phase__c>> quoteIdToPhaseListMap = new Map<Id, List<Phase__c>>();
        for (Phase__c ph : phaseMap.values()) {
            if (!quoteIdToPhaseListMap.keyset().contains(ph.Quote__c)) {
                quoteIdToPhaseListMap.put(ph.Quote__c, new List<Phase__c>());
            }
            quoteIdToPhaseListMap.get(ph.Quote__c).add(ph);
        }
        return quoteIdToPhaseListMap;
    }

    public class OpportunityInfo {
        public String accountName;
        public Id accountId;
        public Decimal digitalLinesNumber;
        public String rcOrderNumber;
        public Id rcOrderId;
        public String proservOrderNumber;
        public Id proservOrderId;
        public String primaryContact;
    }

    public static void updateAccsWithProServOrders(List<Order> orders) {
        List<Order> proServOrders = new List<Order>();
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsWithPServOrders = new List<Account>();

        proServOrders.addAll(filterOrdersByRecordType(orders, OrderHelper.RT_NAME_CC_PROSERV));
        proServOrders.addAll(filterOrdersByRecordType(orders, OrderHelper.RT_NAME_PROSERV));

        if (proServOrders.isEmpty()) {
            return;
        }
        for (Order psOrder : proServOrders) {
            accountIds.add(psOrder.AccountId);
        }

        accountsWithPServOrders = [SELECT Professional_Services__c FROM Account WHERE Id IN :accountIds AND Professional_Services__c = FALSE];

        if (!accountsWithPServOrders.isEmpty()) {
            for (Account acc : accountsWithPServOrders){
                acc.Professional_Services__c = true;
            }

            Triggers.switchOff();
            update accountsWithPServOrders;
            Triggers.switchOn();
        }
    }

    public static void createCreditMemo(Map<Id, Order> oldOrderMap, Map<Id, Order> newOrderMap) {
        Map<Id, Order> ccOrders = new map<Id, Order>();

        ccOrders.putAll(filterOrdersByRecordType(newOrderMap.values(), OrderHelper.RT_NAME_CC));
        ccOrders.putAll(filterOrdersByRecordType(newOrderMap.values(), OrderHelper.RT_NAME_RC_CONTACT_CENTER));

        if (ccOrders.isEmpty()) {
            return;
        }
        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        Map<Id, Order> currentOrders = new Map<Id, Order>([
        SELECT Opportunity.Brand_Name__c
        FROM Order
        WHERE Id IN :ccOrders.keySet()
        ]);

        for (Order ccOrder : ccOrders.values()) {
            if (ccOrder.BillingStatus__c == OrderHelper.STATUS_ACCEPTED
            && oldOrderMap.get(ccOrder.Id).BillingStatus__c != OrderHelper.STATUS_ACCEPTED
            && ccOrder.FSC_Total_Amount__c > 0
            && currentOrders.get(ccOrder.Id).Opportunity.Brand_Name__c.containsIgnoreCase(OpportunityHelper.BRAND_RINGCENTRAL)
            && String.isEmpty(ccOrder.CC_FSC_CreditMemo__c)) {
                acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);
            }
        }

        if (acceptedCCFSCOrders.isEmpty() || Test.isRunningTest()) {
            return;
        }
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
    }

    public class UpdateTotalFieldsOnPackage extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> masterQuoteIds = new Set<Id>();
            Set<Id> packageIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();

            for (Order orderRecord : (List<Order>) triggerRecords) {
                if (isChangedFieldTo(orderRecord, Order.Status, OrderHelper.STATUS_ACTIVATED)
                    || isChangedField(orderRecord, Order.PackageId__c) && OrderHelper.STATUS_ACTIVATED.equals(orderRecord.Status)
                ) {
                    masterQuoteIds.add(orderRecord.QuoteId);
                    packageIds.add(orderRecord.PackageId__c);
                    accountIds.add(orderRecord.AccountId);
                }
            }

            if (packageIds.isEmpty()) {
                return;
            }

            List<Package__c> packageList = (List<Package__c>) new PackageSelector()
                .selectPackagesByActivatedOrderIds(new List<Object>{packageIds, masterQuoteIds})
                .executeQuery();


            if (packageList.isEmpty()) {
                return;
            }

            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByIdsWithTechnicalAccounts(new List<Id>(accountIds))
                .executeQuery();

            Map<Id, Account> accountIdMap = new Map<Id, Account>(accounts);


            Map<Package__c, List<Order>> packageToOrdersMap = new Map<Package__c, List<Order>>();

            for (Package__c pkg: packageList) {
                packageToOrdersMap.put(pkg, pkg.Orders__r);
            }

            List<Package__c> packagesToUpdate = new List<Package__c>();

            for (Package__c pkg: packageToOrdersMap.keySet()) {
                List<Order> ordersList = packageToOrdersMap.get(pkg);
                if (ordersList.isEmpty()) {
                    continue;
                }
                PackageTotalsSvc.getCalculationStrategy(pkg, ordersList, accountIdMap)
                    .calculateTotals();
                packagesToUpdate.add(pkg);
            }

            if (!packagesToUpdate.isEmpty()) {
                if (SyncAccountWSv2.isNewSyncAccountWSExecuted) {
                    Triggers.switchOff();
                    Triggers.except(PackageTriggerHandler.UpdateAccountFieldsFromBAP.class.toString());
                }
                update packagesToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class CreateOrderItemsForNewOrders extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, List<Order>> ordersByQuoteIds = new Map<Id, List<Order>>();
            for (Order ord : (List<Order>) Trigger.new) {
                // Only process new orders
                if (ord.Status != OrderHelper.STATUS_NEW) {
                    continue;
                }

                // Only process orders with TechnicalQuoteId__c set - orders
                // that were created by OrderHelper.buildOrderForQuote method (non-legacy orders)
                // on single product orders QuoteId and TechnicalQuoteId__c will be equal
                if (ord.TechnicalQuoteId__c == null) {
                    continue;
                }

                if (!ordersByQuoteIds.containsKey(ord.TechnicalQuoteId__c)) {
                    ordersByQuoteIds.put(ord.TechnicalQuoteId__c, new List<Order>());
                }

                ordersByQuoteIds.get(ord.TechnicalQuoteId__c).add(ord);
            }

            if (ordersByQuoteIds.isEmpty()) {
                return;
            }

            List<Quote> quotesWithItems = (List<Quote>) new QuoteSelector()
                .selectQuotesByIdToQLIsForOrderCreationProcess(ordersByQuoteIds.keySet())
                .executeQuery();

            Set<Id> accountIdsToLoad = new Set<Id>();
            for (Quote qt : (List<Quote>) quotesWithItems) {
                if (!OpportunityTriggerHelperRefactored.accountMapStatic.containsKey(qt.AccountId)) {
                    accountIdsToLoad.add(qt.AccountId);
                }
            }

            if (!accountIdsToLoad.isEmpty()) {
                List<Account> accounts = (List<Account>) new AccountSelector()
                    .selectAccountsForOpportunityTrigger(accountIdsToLoad)
                    .executeQuery();

                OpportunityTriggerHelperRefactored.accountMapStatic.putAll(new Map<Id, Account>(accounts));
            }

            List<OrderItem> orderItemsToInsert = new List<OrderItem>();
            for (Quote qt : quotesWithItems) {
                if (qt.QuoteLineItems.isEmpty() || !ordersByQuoteIds.containsKey(qt.Id)) {
                    continue;
                }

                if (!ordersByQuoteIds.containsKey(qt.Id)) {
                    continue;
                }

                List<Order> ordList = ordersByQuoteIds.get(qt.Id);
                Account quoteAccount = OpportunityTriggerHelperRefactored.accountMapStatic.get(qt.AccountId);

                if (QuoteHelper.isMPUBQuote(qt, quoteAccount.Master_Accounts__r)) {
                    orderItemsToInsert.addAll(OrderItemHelper.buildOrderItemsForOrdersByProvisioning(ordList, qt.QuoteLineItems, String.isBlank(qt.BillingPackage__c)));
                    continue;
                }

                for (Order ord : ordList) {
                    orderItemsToInsert.addAll(OrderItemHelper.buildOrderItems(ord, qt.QuoteLineItems));
                }
            }

            if (!orderItemsToInsert.isEmpty()) {
                insert orderItemsToInsert;
            }
        }
    }
}