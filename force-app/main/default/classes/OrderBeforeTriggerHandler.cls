public with sharing class OrderBeforeTriggerHandler {

    public OrderBeforeTriggerHandler() {

    }

    private static final String CC_SERVICE = 'CC Service';
    private static final String MINUTES_BUNDLE = 'Minutes Bundle';
    private static final String CONTRACT_COMPLETE = 'Contract Complete';
    private static final String TRAINING = 'Training';

    private static final String ANNUAL = 'Annual';
    private static final String MONTHLY_CONTRACT = 'Monthly - Contract';
    private static final String MONTHLY = 'Monthly';
    private static final String CONTACT_CENTER = 'Contact Center';
    private static final String RINGCENTRAL_CONTACT_CENTER = 'RingCentral Contact Center';

    public static Set<Id> processedAccIds = new Set<Id>();

    public static void updateAccs(Map<Id, Order> accountIdToOrderMap) {

        Set<Id> accountIdToUpdate = accountIdToOrderMap.keySet();
        System.debug('accountIdToUpdate >>> ' + accountIdToUpdate);

        Set<Id> quoteIdSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        for(Order item : accountIdToOrderMap.values()) {
            orderIdSet.add(item.Id);
            quoteIdSet.add(item.QuoteId);
        }

        // select orderItems
        List<OrderItem> orderItemList = [select Id, PricebookEntryId, OrderId, TotalPrice,
                PricebookEntry.Product2Id, Quantity, PricebookEntry.Product2.Number_of_Minutes__c, PricebookEntry.Product2.Sub_Category__c,
                PricebookEntry.Product2.Edition__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Charge_Term__c,
                Zero_Quantity__c,Active__c
        from OrderItem where OrderId in : orderIdSet];

        // build map OrderId = List<OrderItem>
        Map<Id, List<OrderItem>> orderIdToOrderItemListMap = new Map<Id, List<OrderItem>>();

        for(OrderItem item : orderItemList) {

            if(!orderIdToOrderItemListMap.containsKey(item.OrderId)){
                orderIdToOrderItemListMap.put(item.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItemListMap.get(item.OrderId).add(item);

        }


        // select QuoteLineItems
        List<QuoteLineItem> qliList = [select Id, QuoteId, Product2Id, Sub_Category__c,
                EffectivePrice__c, Product2.Family, Product2.Charge_Term__c, Product2.Edition__c, TotalPrice, TotalInitialPrice__c,Deactivated__c
        from QuoteLineItem where QuoteId in : quoteIdSet];

        // build map QuoteId = List<QuoteLineItem>
        Map<Id, List<QuoteLineItem>> quoteIdToQLIListMap = new Map<Id, List<QuoteLineItem>>();

        for(QuoteLineItem item : qliList) {

            if(!quoteIdToQLIListMap.containsKey(item.QuoteId)){
                quoteIdToQLIListMap.put(item.QuoteId, new List<QuoteLineItem>());
            }
            quoteIdToQLIListMap.get(item.QuoteId).add(item);

        }

        List<Account> processedAccsList = new List<Account>();
        Map<Id, Package__c> processedPckgsMap = new Map<Id, Package__c>();
        List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {accountIdToUpdate})
                .setQueryCaching(true)
                .executeQuery();

        Map<Id, Package__c> ccPackageToProcessMap = PackageHelper.filterPackagesByService(packages, AccountHelper.SERVICE_TYPE_RCCC);

        // process accounts
        for(Account currentAcc : [
                SELECT Id, inContact_Cluster__c, InContact_Service__c, No_of_InContact_Seats__c,
                    inContact_account_ID__c, Additional_Products_MRR__c, Provision_Date__c,
                    (SELECT Id, Product__r.Number_of_Minutes__c, Total_Monthly_Price__c
                    FROM SupportEntitlements__r
                    WHERE Active__c = true AND Product__r.Family = :MINUTES_BUNDLE
                        AND Product__r.Sub_category__c = :CONTACT_CENTER)
                FROM Account
                WHERE Id IN :accountIdToUpdate
            ]) {

            if( !processedAccIds.contains(currentAcc.Id) ) { //avoid trigger running twice

                Order currentOrder = accountIdToOrderMap.get(currentAcc.Id);
                Package__c ccPkg = ccPackageToProcessMap.get(currentAcc.Id);

                // set inContact_Cluster__c
                if( String.isEmpty(currentAcc.inContact_Cluster__c) ) {
                    String inContactClusterValue = currentOrder.inContact_Cluster__c;
                    currentAcc.inContact_Cluster__c = inContactClusterValue;
                }


                // set Service_Status__c
                currentAcc.Service_Status__c = CONTRACT_COMPLETE;


                // set InContactService__c, No_of_InContact_Seats__c, Minute_Bundle__c
                if(orderIdToOrderItemListMap.containsKey(currentOrder.Id)) {

                    List<OrderItem> itemsForCurrentOrder = orderIdToOrderItemListMap.get(currentOrder.Id);

                    // set No_of_InContact_Seats__c
                    Decimal oldNoOfIncontactSeats = currentAcc.No_of_InContact_Seats__c;
                    String service = currentAcc.InContact_Service__c;
                    currentAcc.No_of_InContact_Seats__c = computeNoOfInContactSeats(itemsForCurrentOrder, oldNoOfIncontactSeats, service);


                    // set InContactService__c
                    String inContactServiceValue = computeInContactServiceValue(itemsForCurrentOrder);

                    if( !String.isEmpty(inContactServiceValue) ) {
                        currentAcc.InContact_Service__c = inContactServiceValue;
                    }

                    // set Minute_Bundle__c
                    Map<String,Decimal> minutesAndPrice = computeMinutesAndPrice(currentAcc.SupportEntitlements__r);
                    if(minutesAndPrice.get('minutes') >= 0) {
                        currentAcc.Minute_Bundle__c = minutesAndPrice.get('minutes');
                    }
                    // set Actual_transport_MRR__c
                    if (ccPkg != null) {
                        ccPkg.Actual_transport_MRR__c = minutesAndPrice.get('price');
                        processedPckgsMap.put(ccPkg.Id, ccPkg);
                    }
                }

                // set Price_per_Seat__c, Additional_Products_MRR__c
                if(quoteIdToQLIListMap.containsKey(currentOrder.QuoteId)) {

                    List<QuoteLineItem> qliForCurrentOrder = quoteIdToQLIListMap.get(currentOrder.QuoteId);
                    System.debug('qliForCurrentOrder >> ' + qliForCurrentOrder);

                    Boolean hasAnnualChargeTerm = false;
                    Double pricePerSeat = 0;
                    Double monthlyTotalPrice = 0;
                    Double annualTotalPrice = 0;
                    for(QuoteLineItem item : qliForCurrentOrder) {

                        if( item.Product2.Family == CC_SERVICE && !String.isEmpty(item.Product2.Edition__c) && !item.Deactivated__c) {
                            if( item.Product2.Charge_Term__c == ANNUAL || item.Product2.Charge_Term__c == MONTHLY_CONTRACT ) {
                                pricePerSeat += item.EffectivePrice__c;
                            }

                            if( item.Product2.Charge_Term__c == ANNUAL ) {
                                hasAnnualChargeTerm = true;
                            }
                        }


                        if( (item.Product2.Family == TRAINING) ||
                                (item.Product2.Family == MINUTES_BUNDLE) ||
                                ( (item.Product2.Family == CC_SERVICE) && ( !String.isEmpty(item.Product2.Edition__c) ) ) ) {

                            // do not use this products for calculate Additional_Products_MRR__c
                            continue;

                        }else{

                            if( item.Sub_Category__c == CONTACT_CENTER || item.Sub_Category__c == RINGCENTRAL_CONTACT_CENTER) {

                                if( item.Product2.Charge_Term__c == MONTHLY_CONTRACT || item.Product2.Charge_Term__c == MONTHLY ) {
                                    monthlyTotalPrice += item.TotalInitialPrice__c;
                                }

                                if( item.Product2.Charge_Term__c == ANNUAL ) {
                                    annualTotalPrice += item.TotalInitialPrice__c;
                                }

                            }

                        }

                    }

                    // set Price_per_Seat__c
                    if(pricePerSeat > 0 && ccPkg != null) {
                        if(hasAnnualChargeTerm) {
                            ccPkg.Price_per_Seat__c = pricePerSeat / 12;
                        }else{
                            ccPkg.Price_per_Seat__c = pricePerSeat;
                        }
                        processedPckgsMap.put(ccPkg.Id, ccPkg);
                    }

                }


                // set Provision_Date__c
                if( currentAcc.Provision_Date__c == null ) {
                    currentAcc.Provision_Date__c = currentOrder.Provision_Date__c;
                }

                // set inContact_account_ID__c
                if( currentAcc.inContact_account_ID__c == null ) {
                    currentAcc.inContact_account_ID__c = currentOrder.inContact_Account_ID__c;
                }



                processedAccsList.add(currentAcc);

            }

        }


        if(processedAccsList.size() > 0) {

            update processedAccsList;

            for(Account item : processedAccsList) {
                processedAccIds.add(item.Id);
            }

        }
        List<Package__c> processedPckgsList = new List<Package__c>(processedPckgsMap.values());

        if (!processedPckgsList.isEmpty()) {
            Triggers.switchOff();
            update processedPckgsList;
            Triggers.switchOn();
        }
    }

    private static String computeInContactServiceValue(List<OrderItem> itemsForCurrentOrder) {

        // set InContactService__c
        String inContactServiceValue = '';
        for(OrderItem oi : itemsForCurrentOrder) {

            if( oi.PricebookEntry.Product2.Family == CC_SERVICE ) {
                if( oi.PricebookEntry.Product2.Edition__c!= null && oi.Active__c) {
                    inContactServiceValue = oi.PricebookEntry.Product2.Sub_Category__c + ' ' +oi.PricebookEntry.Product2.Edition__c;
                }
            }

        }
        return inContactServiceValue;
    }

    private static Map<String, Decimal> computeMinutesAndPrice(List<Entitlement__c> entitlements) {
        Decimal minutes = 0;
        Decimal price = 0;
        for(Entitlement__c ent : entitlements){
            price += ent.Total_Monthly_Price__c;
            minutes += (ent.Product__r != null ? ent.Product__r.Number_of_Minutes__c : 0);
        }
        return new Map<String,Decimal>{'minutes' => minutes, 'price' => price};
    }

    private static Decimal computeNoOfInContactSeats(List<OrderItem> itemsForCurrentOrder, Decimal oldNoOfInContSeats, String service) {

        if( oldNoOfInContSeats == null ) {
            oldNoOfInContSeats = 0;
        }

        if(service == null) {
            service = '';
        }

        // set No_of_InContact_Seats__c
        Decimal quantitySum = 0;
        Boolean accContainsProductEdition = false;
        for(OrderItem oi : itemsForCurrentOrder) {

            if( oi.PricebookEntry.Product2.Family == CC_SERVICE  && oi.PricebookEntry.Product2.Edition__c != null) {

                if(!oi.Zero_Quantity__c) {
                    quantitySum += oi.Quantity;
                }
            }

        }

        oldNoOfInContSeats += quantitySum;

        return oldNoOfInContSeats;
    }



    public static Map<Id, List<QuoteLineItem>> quoteIdToProductsMap = new Map<Id, List<QuoteLineItem>>();

    /**
     *	B-1196 Live Reports in Quote Tool
     */
    public static void updateRCRT(Map<Id, Order> quoteIdToOrderMap) {

        System.debug('quoteIdToOrderMap >>>' + quoteIdToOrderMap);

        Set<Id> quoteIdSet = new Set<Id>();
        for(Order item : quoteIdToOrderMap.values()) {
            if(String.isNotEmpty(item.QuoteId)) {
                quoteIdSet.add(item.QuoteId);
            }
        }

        if(quoteIdSet.size() > 0) {
            // select QuoteLineItems
            List<QuoteLineItem> qliList = [
                SELECT Id, Product2.Name, EffectivePrice__c, Quantity, QuoteId, Zero_Quantity__c,
                    Product2.Charge_Term__c, Product2.Feature__c,Deactivated__c
                FROM QuoteLineItem
                WHERE QuoteId IN : quoteIdSet
            ];

            System.debug('qliList >>>' + qliList);

            Map<Id, List<QuoteLineItem>> quoteIdToQLIListMap = new Map<Id, List<QuoteLineItem>>();

            for(QuoteLineItem item : qliList) {

                if(!quoteIdToQLIListMap.containsKey(item.QuoteId)){
                    quoteIdToQLIListMap.put(item.QuoteId, new List<QuoteLineItem>());
                }
                quoteIdToQLIListMap.get(item.QuoteId).add(item);

            }

            for(Order item : quoteIdToOrderMap.values()){

                Decimal lrQuantity = 0;
                Decimal lrPricePerLicense = 0;

                Decimal icQuantity = 0;
                Decimal icPricePerLicense = 0;

                if (!quoteIdToQLIListMap.containsKey(item.QuoteId)) {
                    continue;
                }

                for(QuoteLineItem qli : quoteIdToQLIListMap.get(item.QuoteId)){

                    if((qli.Product2.Name == 'Live Reports Add-On' || qli.Product2.Feature__c == Product2Helper.FEATURE_LIVE_REPORTS)
                        && !qli.Zero_Quantity__c) {
                        String chargeTerm = (String.isNotBlank(qli.Product2.Charge_Term__c)) ? qli.Product2.Charge_Term__c : '';
                        lrPricePerLicense = (chargeTerm.contains('Annual')) ? qli.EffectivePrice__c/12 : qli.EffectivePrice__c;

                        lrQuantity = qli.Quantity;
                        // B-1196 - "Live Reports Sign Up Date" field populated with Order creation date value
                        item.Live_Reports_Sign_Up_Date__c = System.today();

                        // B-1196 - Populated as numeric value reflecting how many licenses were purchased by the customer,
                        // Quantity of the Quote Line Item in the related Quote where Product Name is "Live Reports Add-On"
                        item.Number_of_Live_Reports_Licenses__c = lrQuantity;

                        // B-1196 - EffectivePrice__c of the Quote Line Item in the related Quote where Product Name is "Live Reports Add-On"
                        item.Price_per_Live_Report_License__c = lrPricePerLicense;

                    }

                    //B-4726: populating fields of inContact Interconnect section on RingCentral Order layout
                    if(qli.Product2.Feature__c == Product2Helper.FEATURE_INCONTACT_INTERCONNECT) {
                        String chargeTerm = (String.isNotBlank(qli.Product2.Charge_Term__c)) ? qli.Product2.Charge_Term__c : '';
                        icPricePerLicense = (chargeTerm.contains('Annual')) ? qli.EffectivePrice__c/12 : qli.EffectivePrice__c;

                        icQuantity = qli.Quantity;
                        item.inContact_Interconnect_Sign_Up_Date__c = System.today();

                        item.inContact_Interconnect_Licenses_Quantity__c = icQuantity;

                        item.Price_per_inContact_Interconnect_License__c = icPricePerLicense;

                    }

                }
            }
        }
    }

    // B-802 Updated Order and Site Object for CloudConnect
    public static void populateFields( List<Order> orders ) {
        Decimal quantityProServ,
                quantityCloudExchange,
                quantityCloudCustom,
                quantityCloudConnect;
        Set<Id> oppIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        List<Quote> quotes = new List<Quote>();
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppToPrimaryContactMap = new Map<Id, Opportunity>();
        Map<Id, Decimal> quoteToQuantityProServMap = new Map<Id, Decimal>();
        Map<Id, Decimal> quoteToQuantityCloudConnecMap = new Map<Id, Decimal>();

        for( Order o : orders ) {
            oppIds.add( o.OpportunityId );
            quoteIds.add( o.QuoteId );
        }

        if ( oppIds.size() > 0 ) {
            oppById = new Map<Id, Opportunity>([SELECT Id, Primary_Opportunity_Contact__c, Brand_Name__c, BusinessIdentity__c FROM Opportunity WHERE Id IN :oppIds]);
            for( Opportunity op: oppById.values() ) {
                oppToPrimaryContactMap.put(op.Id, new Opportunity ( Id = op.Id, Primary_Opportunity_Contact__c = op.Primary_Opportunity_Contact__c));
            }
        }

        if ( quoteIds.size() > 0 ) {
            quotes = [
                    SELECT Id,
                            (SELECT Id, Product2.Id, Product2.Name, Quantity
                            FROM QuoteLineItems
                            WHERE Product2.Sub_Category__c = 'Professional Services'
                            AND Quantity != null)
                    FROM Quote
                    WHERE Id IN :quoteIds
            ];
        }
        for( Quote q : quotes ) {
            quantityProServ = 0;
            quantityCloudExchange = 0;
            quantityCloudCustom = 0;
            quantityCloudConnect = 0;

            for( QuoteLineItem qli : q.QuoteLineItems ) {
                if ( qli.Product2.Name == 'CloudConnect ProServ Setup') {
                    quantityProServ += qli.Quantity;
                } else if ( qli.Product2.Name == 'CloudConnect - Standard 200 Mbps') {
                    quantityCloudExchange += qli.Quantity;
                } else if ( qli.Product2.Name == 'CloudConnect - Custom 1 Gbps') {
                    quantityCloudCustom += qli.Quantity;
                }
            }

            quantityCloudConnect = quantityCloudExchange * 0.2 + quantityCloudCustom;
            quoteToQuantityProServMap.put( q.Id, quantityProServ );
            quoteToQuantityCloudConnecMap.put( q.Id, quantityCloudConnect );
        }

        for( Order o : orders ) {
            Opportunity opp = oppById.get(o.OpportunityId);
            o.Status = OpportunityHelper.isVerizon(opp) ? OrderHelper.STATUS_SUBMITTED_PARTNERS : OrderHelper.STATUS_SUBMITTED;
            o.Submitted_Date__c = System.now();
            o.MainPointOfContact__c = oppToPrimaryContactMap.get( o.OpportunityId ).Primary_Opportunity_Contact__c;
            o.NumberOfSites__c = quoteToQuantityProServMap.get( o.QuoteId );
            o.TotalBandwidthOnQuote__c = quoteToQuantityCloudConnecMap.get( o.QuoteId );
            if(o.TotalBandwidthOnQuote__c == 0.0) {

                o.TotalBandwidthOnQuote__c = null;
            }
        }

    }

    public static void updateCloudConnect( List<Order> orders ) {

        for( Order o : orders ) {
            if ( o.Status == 'Activated' ) {
                o.Status = 'Project Completed';
                o.ProjectCompletedDate__c = Date.today();
                if ( o.TotalBandwidthOnQuote__c != o.TotalBandwidthOnOrder__c ) {
                    o.addError('To complete the project you should make Total Bandwidth on Order to be the same as you had on Quote');
                }
            }
        }
    }

    public static void setBillingStatus(List<Order> orders, Map<Id, Order> oldOrderMap) {
        Set<String> completedStatuses = new Set<String>{
                OrderHelper.STATUS_COMPLETED,
                OrderHelper.STATUS_SUBMITTED,
                OrderHelper.STATUS_SUBMITTED_PARTNERS
        };
        Boolean isInsert = oldOrderMap == null;
        for (Order ord : orders) {
            if (completedStatuses.contains(ord.Status)
                && ord.BillingStatus__c==null
                && ord.inContact_Account_ID__c!=null) {
                    ord.BillingStatus__c = 'Submitted';
            }
        }
    }

}