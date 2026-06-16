/*
* Name         : GenerateOrders
* Created By   : Fedor Golovanov (fgolovanov@newmarketinc.com)
* Created Date : 28/October/2016
* Description  : B-800 (Sprint 21 Moscow). Order Autocreation. As a Sals Rep I want Orders to be created when I click button on the Opportunity so I won't need to create them manually.
               : B-751 (Sprint 21 Moscow). CC orchestration. As a Sales Rep I would like to have fields on Contact Center Order so I could add all the required information on the record.
               : Artem Kniazev (akniazev@aquivalabs.com) B-1079 (Sprint 24 Moscow). Generate Order Form for Account Number population
* Dependencies : No
*/
global class GenerateOrders {

    public static Opportunity opp;
    public static Quote primaryQuote;
    public static List<Entitlement__c> entitlements; //B-1457
    public static List<Quote> quotes;
    public static Quote sourceQuoteForCancelOrder;
    //Contains quote items wrapper sorted by product sub-category
    public static Map<String, ItemsWrapper> subCategoryItems = new Map<String, ItemsWrapper>();
    //Contains order wrapper to insert sorted by product sub category
    public static Map<String, List<OrderWrapper>> subCategoryOrderWrapper = new Map<String, List<OrderWrapper>>();
    //Contains order products wrapper to insert sorted by product sub category
    public static Map<String, List<OrderItemWrapper>> subCategoryOrderItemsWrapper = new Map<String, List<OrderItemWrapper>>();

    public static final String EXCEPTION_CATCHED_ERROR_MESSAGE = Label.GenerateOrders_ExceptionCatched_ErrorMessage;

    public static final String BIZSERV_CASE_DESCRIPTION_PLACEHOLDER = Label.GenerateOrdersError_Case_Description_Template;

    public static final String RINGCENTRAL_SUBCATEGORY = 'RingCentral';

    public static final Set <String> PROSERV_PRODUCT_SUBCATEGORIES =
        new Set <String>{Product2Helper.SUBCATEGORY_PROSERV, Product2Helper.SUBCATEGORY_CC_PROSERV};

    public static final Integer ORDER_NAME_MAX_LENGTH = Order.Name.getDescribe().getLength();
    public static final String ORDER_NAME_MORE_QUIALIFIER = '…';

    /**
     * Method to generate Orders
     * @param oppId - Opportunity id
     * @param rcNumber - Need to populate Orders.RingCentral_Account_Number__c on orders with Record Type "Contact Center"
     * @param ccNumber - Need to populate Orders.Contact_Center_Number__c on orders with Record Type "Contact Center"
     * @param skipValidation - Checks, if all validations are required, no need for Cancel Opportunity
     * @return serialized JSON with status, message (details, additional params)
     */

    @AuraEnabled
    public static Opportunity getOppBillingDetail(String OppId){
        Opportunity Opp;
        try {

            Opp = [Select Id,Is_Billing_Opportunity__c from Opportunity where Id = :OppId];

        } catch (Exception ex) {
        }
        return Opp;
    }

    @AuraEnabled
    webservice static String processData(Id oppId, String rcNumber, String ccNumber)
    {
        return processDataUniversal(oppId,rcNumber,ccNumber,null, false);
    }
    webService static String processDataForCancellation(Id oppId, String rcNumber, String ccNumber, Boolean skipValidation) {
        return processDataUniversal(oppId, rcNumber, ccNumber, null, skipValidation);
    }

    @future
    public static void processDataFuture(Id oppId, String rcNumber, String ccNumber) {
        processDataUniversal(oppId, rcNumber, ccNumber, null, false);
    }

    public static String processDataUniversal(Id oppId, String rcNumber, String ccNumber, List<Quote> quotesToProcess, Boolean skipValidation)
    {
        //Contains status and message to response.
        Map<String, String> response = new Map<String, String>();

        //B-1963
        Map<Id, QuoteLineItem> qliIdMap = new Map<Id, QuoteLineItem>();
        Map<Id, List<OrderItem>> parentUpdateMap = new Map<Id, List<OrderItem>>();

        //Select the opportunity
        try{
            opp = getOpportunityRecord(oppId);
        }catch(Exception ex) {
            return JSON.serialize( getResponseError('error',
                Label.GenerateOrderNotificationWhileSelectingOppty,
                ex.getMessage() ));
        }
        //Check if there are no errors related to opportunity
        if (!skipValidation) {
            String opportunityError = getValidationErrors(new List <Opportunity>{ opp });
            if (opportunityError != null) {
                return opportunityError;
            }
        }

        //Select all quotes except sales/non-primary quotes under Opportunity
        try{
            if(quotesToProcess==null) {
                quotes = getQuotes(oppId);
            } else {
                quotes=quotesToProcess;
            }
        }catch (Exception ex) {
            return JSON.serialize(getResponseError ('error',
                Label.GenerateOrderNotificationWhileSelectingQuotes,
                ex.getMessage()));
        }
        //Check if there are no quotes generated for this opportunity
        if (quotes.isEmpty()) {
            return JSON.serialize(
                getResponseError('error',
                    Label.GenerateOrderNotificationNoQuotesForOppty,
                    null));
        }
        //Check if there are no errors on quote
        if (!skipValidation) {
            String quoteError = getValidationErrors(quotes);
            if (quoteError != null) {
                return quoteError;
            }
        }

        primaryQuote = QuoteHelper.getPrimaryQuote(quotes, opp.Is_Billing_Opportunity__c);

        List<Entitlement__c> ccEnts = [
            SELECT Id, Quantity__c, Price__c, Discount__c, Discount_Type__c, Active__c,
                Product__c, Product__r.Edition__c, Product__r.Number_of_Minutes__c, Product__r.Family,
                Product__r.Product_Type__c, Product__r.Sub_Category__c,
                Product__r.Name, Product__r.PBE_Matcher_Formula__c, Product__r.ExtID__c, Total_Monthly_Price__c,
                Product__r.Parent__c
            FROM Entitlement__c
            WHERE Account__c = :opp.AccountId
            AND Product__r.Sub_Category__c = :Product2Helper.CONTACT_CENTER_SUBCATEGORIES
            AND Active__c = true
        ];

        // Get related order items for entitlements
        List<OrderItem> ordeItemsForEntitlements = [
            SELECT Id, RC_Entitlement__c, RC_Entitlement__r.Active__c, Quantity,
                Zero_Quantity__c, UnitPrice, PricebookEntryId,
                QuoteLineItem.Quote.Id, QuoteLineItem.Quote.CurrencyIsoCode,
                QuoteLineItem.Quote.Upsell_Status__c, QuoteLineItem.Quote.End_Date__c,
                QuoteLineItem.Quote.Pricebook2Id, QuoteLineItem.Quote.SOW_Type__c,
                QuoteLineItem.Quote.RecordTypeId,
                QuoteLineItem.Quote.Signed_SOW__c, QuoteLineItem.Quote.CreatedById,
                QuoteLineItem.Quote.CreatedBy.ManagerId, QuoteLineItem.Product2.Sub_Category__c,
                QuoteLineItem.Product2.Family, QuoteLineItem.Product2Id,
                QuoteLineItem.Product2.Charge_Term__c,
                Order.PriceBook2Id
            FROM OrderItem
            WHERE RC_Entitlement__c
            IN :ccEnts
        ];

        // Build Entitlement Id => OrderItem Map
        Map<Id,OrderItem> entIdToOrderItemMap = buildEntIdToOiMap(ordeItemsForEntitlements);

        sourceQuoteForCancelOrder = getSourceQuoteForCancelOrder(entIdToOrderItemMap);
        // Populate maps to use them further
        populateMaps(quotes, ccEnts, qliIdMap, subCategoryItems, opp);
        if(subCategoryItems.isEmpty()){
            return JSON.serialize(
                getResponseError('warning', Label.GenerateOrderNotificationNoQuoteLineItems, null)
            );
        }

        List<Package__c> packages = new PackageSelector()
            .selectPackagesForNewReferences(new List<Object> {new Set<Id>{opp.AccountId}})
            .executeQuery();

        // Loop to create orders and orderItems
        for (String subcategory : subCategoryItems.keySet()) {
            // Create orders
            // For each subcategory can be created both: Ordinary order and Cancel order
            List<OrderWrapper> categoryOrders = prepareOrders(opp, subcategory, packages);
            if (categoryOrders.isEmpty()) {
                continue;
            }

            // For contact center orders a few more fields should be populated
            for (OrderWrapper newOrder : categoryOrders) {
                // Ask to provide RingCentral_Account_Number__c and Contact_Center_Number__c for non cancel order
                if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(subcategory) && !newOrder.isCancelOrder) {
                    if(String.isEmpty(rcNumber) && String.isEmpty(ccNumber) && ccEnts.size() == 0) {
                        response.put('status', 'action required');
                        response.put('message', 'Provide "RingCentral Account Number" and "Contact Center Number" please');
                        return JSON.serialize(response);
                    }
                }

                // Populate fields specific for the contact center orders, no matter cancel or ordinary order
                if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(subcategory)) {
                    // Ask to provide RingCentral_Account_Number__c and Contact_Center_Number__c
                    if (ccEnts.size() != 0) {
                        //For change orders get CC Number and RC Number from New Customer order
                        newOrder.order.RingCentral_Account_Number__c = opp.Account.AccountNumber;
                    } else {
                        //For New Customer order get CC Number and RC Number from popup
                        newOrder.order.Contact_Center_Number__c = ccNumber;
                        newOrder.order.RingCentral_Account_Number__c = rcNumber;
                    }

                    newOrder.order.Partner_Sales_Rep__c = subCategoryItems.get(subcategory).qliList[0].Quote.CreatedById;

                    newOrder.order.inContact_Account_ID__c = opp.AccountId != null
                        ? opp.Account.inContact_account_ID__c
                        : null;
                    newOrder.order.Default_Time_Zone__c = opp.AccountId != null ? opp.Account.Timezone__c : null;
                    newOrder.order.PM_Name__c = subCategoryItems.get(subcategory).qliList[0].Quote.CreatedBy.ManagerId;
                    newOrder.order.CC_Order_Type__c = getCCOrderType(subCategoryItems.get(subcategory).qliList, ccEnts);
                }

                if (!subCategoryOrderWrapper.containsKey(subcategory)) {
                    subCategoryOrderWrapper.put(subcategory, new List<OrderWrapper>());
                }
                subCategoryOrderWrapper.get(subcategory).add(newOrder);
            }

            // Create Order Items for each order
            ItemsWrapper itemsWrapper = subCategoryItems.get(subcategory);

            for (OrderWrapper ow : subCategoryOrderWrapper.get(subcategory)) {
                TotalPrices totalPrices = new TotalPrices();
                // Create cancel order items
                if (ow.isCancelOrder) {
                    // Bypass Cancel Order Generation
                    continue;
                }
                // Create ordinary order items
                if (!ow.isCancelOrder) {
                    for (QuoteLineItem qli : itemsWrapper.qliList) {
                        // Should not create order items for contact center qlis which have not changed
                        if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(qli.Product2.Sub_Category__c)
                            && !isItemChanged(qli)) {
                            continue;
                        }
                        // create order item
                        OrderItem newOrderItem = createOrderItemFromQli(qli);
                        OrderItemWrapper orderItemWrapper = new OrderItemWrapper(newOrderItem, false);

                        if (!subCategoryOrderItemsWrapper.containsKey(subcategory)) {
                            subCategoryOrderItemsWrapper.put(subcategory, new List<OrderItemWrapper>());
                        }
                        subCategoryOrderItemsWrapper.get(subcategory).add(orderItemWrapper);


                        //B-1963 Link Overages to their parent items
                        if (qli.Overage_parent__c != null) {
                            if (!parentUpdateMap.containsKey(qli.Overage_parent__c)){
                                parentUpdateMap.put(qli.Overage_parent__c, new List<OrderItem>{newOrderItem});
                            }
                            parentUpdateMap.get(qli.Overage_parent__c).add(newOrderItem);
                        }

                        // Calculate Estimated_ProServ_OTP__c
                        Decimal unitPrice = newOrderItem.UnitPrice != null ? newOrderItem.UnitPrice : 0;
                        if (qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ONE_TIME) {
                            totalPrices.totalPricesOneTimeSumm += newOrderItem.Quantity * unitPrice;
                        }

                        // Calculate Estimated_Proserv_MRR_c
                        if (PROSERV_PRODUCT_SUBCATEGORIES.contains(qli.Product2.Sub_Category__c)) {
                            if (qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                                totalPrices.totalPricesAnnualSumm += newOrderItem.Quantity * unitPrice;
                            }

                            String chargeTerm = qli.Product2.Charge_Term__c;
                            if (qli.Product2.Charge_Term__c == Product2Helper.CHARGE_TERM_MONTHLY
                                || chargeTerm == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT) {
                                    totalPrices.totalPricesMonthlySumm += newOrderItem.Quantity * unitPrice;
                                }
                        }
                    }
                }
                // Populate order fields that are based on qli values
                ow.order.Estimated_ProServ_OTP__c = totalPrices.totalPricesOneTimeSumm;

                if (subcategory == Product2Helper.SUBCATEGORY_RINGCENTRAL) {
                    ow.order.Estimated_ProServ_MRR__c =
                        totalPrices.totalPricesMonthlySumm + totalPrices.totalPricesAnnualSumm / 12;
                }
            }
        }

        SavePoint sp = Database.setSavePoint();
        try {
            // Insert orders
            List<Order> ordersToInsert = new List<Order>();
            for (List<OrderWrapper> owList : subCategoryOrderWrapper.values()) {
                for (OrderWrapper ow : owList) {
                    ordersToInsert.add(ow.order);
                }
            }
            insert ordersToInsert;

            Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
            if (featureToggleSetting.NewChangeOrderFlow__c && opp.Parent_Order__c != null) {
                //If opportunity has a parent order that means it is a proserv "change order" opportunity and it has only one new order
                Order currentChangeOrder = ordersToInsert.get(0);
                reuseOriginalPhases(opp, quotes, currentChangeOrder);
            }

            // Populate Order lookUp on order item object
            List<OrderItem> orderItemsToInsert = new List<OrderItem>();
            for (String subcategory : subCategoryOrderItemsWrapper.keySet()) {
                Order ordinaryOrder = getOrdinaryOrder(subcategory);

                for (OrderItemWrapper oiw : subCategoryOrderItemsWrapper.get(subcategory)) {
                    if (oiw.isCancelOrder) {

                        // Bypass Cancel Order Generation
                        continue;
                    }

                    if (!oiw.isCancelOrder) {
                        oiw.orderItem.OrderId = ordinaryOrder.Id;
                    }
                    orderItemsToInsert.add(oiw.orderItem);
                }
            }

            if (opp.Parent_Order__c != null) {
                Order parentOrder = fillChangeOrderLookup(opp.Parent_Order__c, subCategoryOrderWrapper);
                if (parentOrder != null) {
                    update parentOrder;
                }
            }
            // Insert Order Items
            insert orderItemsToInsert;

            //B-1963
            List<OrderItem> oiUpdateList = new List<OrderItem>();
            for (Id key : parentUpdateMap.keySet()) {
                Id parentPbeId = qliIdMap.containsKey(key) ? qliIdMap.get(key).PriceBookEntryId : null;
                if (parentPbeId != null) {
                    OrderItem parentOI;
                    for (OrderItem oi : orderItemsToInsert) {
                        if (oi.PriceBookEntryId == parentPbeId) {
                            parentOI = oi;
                            break;
                        }
                    }

                    for (OrderItem uoi : parentUpdateMap.get(key)) {
                        uoi.Parent_Order_Product__c = parentOI.Id;
                        oiUpdateList.add(uoi);
                    }
                }
            }
            update oiUpdateList;


            //B-2035 Entitlements generation for RC Native products
            System.debug('subCategoryOrder: ' + subCategoryOrderWrapper.keyset());
            Order rcOrder = getOrdinaryOrder(Product2Helper.SUBCATEGORY_RINGCENTRAL);
            System.debug(rcOrder);
            if (rcOrder != null) {
                List<OrderItem> rcOrderItems = [SELECT Id, Active__c, RC_Entitlement__c,
                    Insert_Entitlement__c, Pricebookentry.Product2Id,
                    Pricebookentry.Product2.Family, UnitPrice, Pricebookentry.Product2.Feature__c,
                    Pricebookentry.Product2.Name, Pricebookentry.Product2.Edition__c,
                    Pricebookentry.CurrencyIsoCode,CurrencyIsoCode, UnitPriceWithoutDiscount__c,
                    Quantity, Discount_Number__c, Discount_Type__c, Zero_Quantity__c,
                    ServiceDate, Matcher_Formula__c, QuantityOrThreshold__c
                FROM OrderItem
                WHERE OrderId = :rcOrder.Id
                AND (PricebookEntry.Product2.Charge_Term__c != 'One - Time' OR
                    Pricebookentry.Product2.Feature__c IN :Product2Helper.ONE_TIME_FEATURE_SET)];
                EntitlementSync.syncEntitlements(rcOrder, rcOrderItems);
            }

            //B-3752
            //update BillingStatus__c on Quote, Order and Phase
            Set<Id> orderIds = new Set<Id>();
            for(List<OrderWrapper> owList : subCategoryOrderWrapper.values()) {
                for (OrderWrapper ow : owList) {
                    orderIds.add(ow.order.Id);
                }
            }

            Set<Quote> quotesToUpdate = new Set<Quote>();
            Set<Phase__c> phasesToUpdate = new Set<Phase__c>();
            List<Order> allDependentObjs = [
                SELECT Id, Quote.Id, Quote.RecordTypeId,
                (SELECT Id FROM Phases__r)
                FROM Order
                WHERE Id IN :orderIds AND Status IN ('Submitted', 'Submitted for Partners')
            ];


            for(Order o : allDependentObjs) {
                if(new Set<Id>{QuoteHelper.RT_ID_PROSERV,QuoteHelper.RT_ID_CC_PROSERV}.contains(o.Quote.RecordTypeId)) {
                    continue;
                }
                quotesToUpdate.add(new Quote(
                    Id = o.Quote.Id,
                    BillingStatus__c = PhaseHelper.BILLING_STATUS_SUBMITTED
                ));
                for(Phase__c p : o.Phases__r) {
                    phasesToUpdate.add(new Phase__c(
                        Id = p.Id,
                        BillingStatus__c = PhaseHelper.BILLING_STATUS_SUBMITTED
                    ));
                }
            }

            QuoteTriggerHelper.byPassProServStatusUpdate = true;
            update new List<Quote>(quotesToUpdate);
            update new List<Phase__c>(phasesToUpdate);
            QuoteTriggerHelper.byPassProServStatusUpdate = false;
        } catch(Exception ex) {
            String exceptionDetailsStr = handleCatchException(ex, sp);
            System.debug('exceptionDetailsStr >>> ' + exceptionDetailsStr);

            Boolean isEmailSent = emailApexErrorsAboutError(exceptionDetailsStr, oppId);

            String htmlLink = 'An error has occured generating orders. ' +
                'Please try again or fill a case for support team. Admin info: ' + ex.getMessage() + '. ';
            htmlLink += 'An email has ';
            htmlLink += (isEmailSent) ? ' been sent.' : ' not been sent becuase of error.';

            return JSON.serialize(getResponseError('error',
                EXCEPTION_CATCHED_ERROR_MESSAGE,
                htmlLink));
        }

        //Create/update asset
        processAssetCreation();
        return JSON.serialize(getResponseError('success',
            Label.GenerateOrderNotificationSuccessfullyCreated,
            null));
    }

    @TestVisible
    private static void reuseOriginalPhases(Opportunity opp, List<Quote> quotes, Order currentChangeOrder) {
        Map<Id, Id> phaseIdToParentPhaseId = new Map<Id, Id>();
        Map<Id, Phase__c> parentPhaseIdToNewPhase = new Map<Id, Phase__c>();
        Set<Id> idPhasesToDelete = new Set<Id>();

        for (Phase__c phase : opp.Phases__r) {
            if (phase.Last_Phase__c != null) {
                parentPhaseIdToNewPhase.put(phase.Last_Phase__c, phase);
                phaseIdToParentPhaseId.put(phase.Id, phase.Last_Phase__c);
                idPhasesToDelete.add(phase.Id);
            }
        }

        Order initialOrder = new List<Order>([
            SELECT Id, (SELECT Id, Status__c FROM Phases__r),
                       (SELECT Id, Asset__c, Asset__r.Delivered_Quantity__c FROM OrderItems)
            FROM Order
            WHERE Id = :opp.Parent_Order__c
            LIMIT 1
        ]).get(0);

        if (initialOrder != null) {

            Approval.unlock(initialOrder.Phases__r);
            Approval.unlock(initialOrder);

            initialOrder.Status = OrderHelper.STATUS_REVISED;

            List<Hardware_Line_Item__c> phaseLineItemsToUpdate = [
                SELECT Id, RingCentral_Hardware_Phase__c
                FROM Hardware_Line_Item__c
                WHERE RingCentral_Hardware_Phase__c IN :phaseIdToParentPhaseId.keySet()
            ];
            for (Hardware_Line_Item__c lineItem : phaseLineItemsToUpdate) {
                lineItem.RingCentral_Hardware_Phase__c = phaseIdToParentPhaseId.get(lineItem.RingCentral_Hardware_Phase__c);
            }

            List<Phase__c> initialPhasesToUpdate = new List<Phase__c>();
            for (Phase__c oldPhase : initialOrder.Phases__r) {
                if (parentPhaseIdToNewPhase.get(oldPhase.Id) != null) {
                    oldPhase.Status__c = parentPhaseIdToNewPhase.get(oldPhase.Id).Status__c;
                    if (oldPhase.Status__c == PhaseHelper.STATUS_DELETED) {
                        oldPhase.Initial_Payment__c = null;
                    }
                    oldPhase.Estimated_Completion_Date__c = parentPhaseIdToNewPhase.get(oldPhase.Id).Estimated_Completion_Date__c;
                    oldPhase.PhaseDescription__c = parentPhaseIdToNewPhase.get(oldPhase.Id).PhaseDescription__c;
                    oldPhase.Order__c = currentChangeOrder.Id;
                    oldPhase.Quote__c = currentChangeOrder.QuoteId;

                    initialPhasesToUpdate.add(oldPhase);
                }
            }
            for (Quote quote : quotes) {
                for (Phase__c phase : quote.Phases__r) {
                    if (phase.Last_Phase__c != null) {
                        idPhasesToDelete.add(phase.Id);
                    }
                }
            }

            List<Phase__c> phasesToDelete = new List<Phase__c>();
            for (Id phaseId : idPhasesToDelete) {
                phasesToDelete.add(new Phase__c(Id = phaseId));
            }

            List<Hardware_Line_Item__c> phaseLineItemsToDelete = [
                SELECT Id
                FROM Hardware_Line_Item__c
                WHERE RingCentral_Hardware_Phase__c IN :parentPhaseIdToNewPhase.keySet()
            ];

            List<Asset> initialAssetsToUpdate = new List<Asset>();
            for (OrderItem oi : initialOrder.OrderItems) {
                if (oi.Asset__c != null) {
                    Asset assetRecord = new Asset( Id = oi.Asset__c );
                    assetRecord.Quantity = oi.Asset__r.Delivered_Quantity__c;
                    initialAssetsToUpdate.add(assetRecord);
                }
            }

            update initialOrder;
            PhaseTriggerHandler.isMLRecordAlreadyInserted = true;
            update initialPhasesToUpdate;
            delete phaseLineItemsToDelete;
            PhaseTriggerHandler.isMLRecordAlreadyInserted = false;
            update phaseLineItemsToUpdate;
            update initialAssetsToUpdate;
            delete phasesToDelete;
        }
    }

    /**
     * prepareOrders   - precreates both order types(ordinary and cancel)
     * @return  return - list of orders featured by cancel order flag
     */
    private static List<OrderWrapper> prepareOrders(Opportunity opp, String subcategory, List<Package__c> packages) {
        List<OrderWrapper> categoryOrderList = new List<OrderWrapper>();

        categoryOrderList.add(createNewOrder(opp, subcategory, false, packages));

        return categoryOrderList;
    }

    private static Order getOrdinaryOrder(String subcategory) {
        Order ordinaryOrder;
        List<OrderWrapper> orderWrapperList = subCategoryOrderWrapper.get(subcategory);
        if (orderWrapperList == null) {
            return null;
        }

        for (OrderWrapper ow : orderWrapperList) {
            if (!ow.isCancelOrder) {
                ordinaryOrder = ow.order;
            }
        }
        return ordinaryOrder;
    }

    private static List<OrderItem> getOrdinaryOrderItems(String subcategory) {
        List<OrderItem> orderItemList = new List<OrderItem>();
        List<OrderItemWrapper> oiwList = subCategoryOrderItemsWrapper.get(subcategory);
        for (OrderItemWrapper oiw : oiwList) {
            if (!oiw.isCancelOrder) {
                orderItemList.add(oiw.orderItem);
            }
        }
        return orderItemList;
    }

    /**
     * createOrderItemFromQli   - quote line item new order item will be created from
     * @return   return         - order item that should be created
     */
    private static OrderItem createOrderItemFromQli(QuoteLineItem qli) {

        Boolean isDeactivatedCcOverage = Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(qli.Product2.Family)
                                         && qli.Deactivated__c;

        OrderItem newOrderItem = new OrderItem (
            PricebookEntryId = qli.PricebookEntryId,
            Quantity = isDeactivatedCcOverage ? -1 : (qli.Quantity != 0 ? qli.Quantity : 1),
            Threshold__c = (isDeactivatedCcOverage && qli.Threshold__c == null) ? 0 : qli.Threshold__c,
            QuoteLineItemId = qli.Id,
            UnitPrice = qli.EffectivePrice__c,
            UnitPriceWithoutDiscount__c = qli.UnitPrice,
            Discount_Type__c = qli.Discount_Type__c,
            Discount_Number__c = qli.Discount_Number__c,
            Active__c = !qli.Deactivated__c,
            BillingStatus__c = (qli.BillingStatus__c == PhaseHelper.BILLING_STATUS_REPLACED
                ? qli.BillingStatus__c
                : (qli.Deactivated__c
                    ?PhaseHelper.BILLING_STATUS_CANCELLED
                    :PhaseHelper.BILLING_STATUS_ACTIVE)),
            Zero_Quantity__c = isDeactivatedCcOverage ? false : qli.Zero_Quantity__c,
            RC_Entitlement__c = qli.Entitlement__c
        );

        return newOrderItem;
    }

    /**
     * buildEntIdToOiMap   - matches entitlement id to its order item
     * @return   return    - map of entitlement id => order item
     */
    private static Map<Id,OrderItem> buildEntIdToOiMap(List<OrderItem> oiList) {
        Map<Id,OrderItem> entIdToOrderItemMap = new Map<Id,OrderItem>();
        for (OrderItem oi : oiList) {
            entIdToOrderItemMap.put(oi.RC_Entitlement__c, oi);
        }
        return entIdToOrderItemMap;
    }
    /**
     * getSourceQuoteForCancelOrder - gets the quote which is the source for Pricebook and other field values
     * @return   return             - source quote
     */
    private static Quote getSourceQuoteForCancelOrder(Map<Id,OrderItem> entIdToOrderItemMap) {
        Quote sourceQuote;
        for (OrderItem oi : entIdToOrderItemMap.values()) {
            sourceQuote = oi.QuoteLineItem.Quote;
            break;
        }
        return sourceQuote;
    }
    /**
     * isItemChanged  - checks if quote line items has changed on comparison with its entitlement
     * @return return - true if there are some changes
     */
    private static Boolean isItemChanged(QuoteLineItem qli) {
        Boolean isItemChanged = false;

        if (qli.Entitlement__c == null) {
            return true;
        }

        Decimal entitlementDiscount = qli.Entitlement__r.Discount__c != null ? qli.Entitlement__r.Discount__c : 0;
        Decimal qliDiscount = qli.Discount_number__c != null ? qli.Discount_number__c : 0;

        if (
            entitlementDiscount != qliDiscount
            || qli.Entitlement__r.Discount_Type__c != qli.Discount_type__c
            || qli.Quantity_or_Threshold__c != 0
            || QuoteLineItemHelper.getQuantity(qli) != 0
            || qli.Entitlement__r.Product__c != qli.Product2Id
            || qli.Deactivated__c
        ) {
            isItemChanged = true;
        }

        return isItemChanged;
    }

    // Method is used to create, update asset object. Assets are created only for proserv one-time orders
    private static void processAssetCreation() {
        //List of quote line items for which where created proserv orders
        List <QuoteLineItem> proservQliList = new List<QuoteLineItem>();
        //List of proserv orders
        List <Order> proservOrderList = new List <Order>();
        //List of proserv order items list
        List <OrderItem> proservOliList = new List <OrderItem>();
        //Set of proserv orders ids
        Set <Id> ordersIds = new Set<Id>();
        for (String subcategory : subCategoryItems.keyset()) {
            if (PROSERV_PRODUCT_SUBCATEGORIES.contains(subcategory)) {
                proservQliList.addall(subCategoryItems.get(subcategory).qliList);
                proservOrderList.add(getOrdinaryOrder(subcategory));
                proservOliList.addall(getOrdinaryOrderItems(subcategory));
                ordersIds.add(getOrdinaryOrder(subcategory).Id);
            }
        }

        //Get all asset records under account
        List <Asset> existingAssetRecords = new List <Asset>();
        if (!proservOrderList.isEmpty()) {
            existingAssetRecords = [SELECT id, Quantity, Completion_Date__c, Product2Id, Delivered_Quantity__c, AccountId
            FROM Asset
            WHERE AccountId =: proservOrderList.get(0).AccountId];
        }

        Map <Id, Asset> assetIdToAssetMap = new Map<Id, Asset>(existingAssetRecords);

        //Get order items with corresponding phase line items
        List <OrderItem> oliList = [SELECT Id, Pricebookentry.Product2Id,
        (SELECT Id, Quantity__c, Order_Line_Item__c, RingCentral_Hardware_Phase__r.Completed_Date__c
        FROM Hardware_Line_Items__r)
        FROM OrderItem
        WHERE OrderId IN: ordersIds];
        //Build product id to phase line item list map
        Map<Id, List<Hardware_Line_Item__c>> productIdToPhaseLineItemListMap= new Map<Id, List<Hardware_Line_Item__c>>();
        for (OrderItem oi : oliList) {
            if (!productIdToPhaseLineItemListMap.keyset().contains(oi.Pricebookentry.Product2Id)) {
                productIdToPhaseLineItemListMap.put(oi.Pricebookentry.Product2Id, new List<Hardware_Line_Item__c>());
            }
            for (Hardware_Line_Item__c hli : oi.Hardware_Line_Items__r) {
                if(hli.RingCentral_Hardware_Phase__r.Completed_Date__c != null) {
                    productIdToPhaseLineItemListMap.get(oi.Pricebookentry.Product2Id).add(hli);
                }
            }
        }

        //Product id to order ltem map
        Map <Id, OrderItem> productIdToOrderLineItemMap = new Map <Id, OrderItem>();
        //Product2 id to asset map
        Map <Id, Asset> assetToUpsertMap = new Map <Id, Asset>();

        //If there are already assets under account
        for (QuoteLineItem qli : proservQliList) {
            if(qli.Product2.Charge_Term__c == 'One - Time') {
                if (!existingAssetRecords.IsEmpty()) {
                    //If there are no assets for this product - create new one
                    if(qli.Asset__c == null) {
                        Asset assetRecord = createAsset(qli,productIdToPhaseLineItemListMap.get(qli.Product2.Id));
                        assetToUpsertMap.put(qli.Product2Id, assetRecord);
                        //Update existing asset
                    } else {
                        Asset existingAsset = assetIdToAssetMap.get(qli.Asset__c);
                        if(existingAsset != null){
                            existingAsset.Delivered_Quantity__c
                                += calculateDeliveredQuantity(productIdToPhaseLineItemListMap.get(qli.Product2Id));
                            existingAsset.Discount_Type__c = qli.Discount_type__c;
                            existingAsset.Discount_Number__c = qli.Discount_number__c != null ? qli.Discount_number__c : 0;
                            existingAsset.Unit_Price__c = qli.UnitPrice;
                            existingAsset.Quantity = qli.NewQuantity__c;
                            existingAsset.Total_Price__c = (qli.UnitPrice == null ? 0 : qli.UnitPrice) * qli.NewQuantity__c;
                            existingAsset.Start_Date__c = Date.today();
                            assetToUpsertMap.put(qli.Product2Id, existingAsset);
                        }
                    }
                } else {
                    //If there are no assets then create new one
                    Asset assetRecord = createAsset(qli,productIdToPhaseLineItemListMap.get(qli.Product2.Id));
                    assetToUpsertMap.put(qli.Product2Id, assetRecord);
                }
                //Build product id to order item map
                for (OrderItem oiObject : proservOliList) {
                    if (oiObject.QuoteLineItemId == qli.Id) {
                        productIdToOrderLineItemMap.put(qli.Product2Id, oiObject);
                    }
                }
            }
        }

        //Upsert assets
        if (!assetToUpsertMap.isEmpty()) {
            upsert assetToUpsertMap.values();
        }

        //Populate asset lookUps on order line item object
        for (Id productId : assetToUpsertMap.keyset()) {
            productIdToOrderLineItemMap.get(productId).Asset__c = assetToUpsertMap.get(productId).Id;
        }
        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        update productIdToOrderLineItemMap.values();
        QuoteTriggerHelper.byPassProServStatusUpdate = false;
    }

    private static Asset createAsset (QuoteLineItem qli, List<Hardware_Line_Item__c> hliList) {
        Asset assetRecord = new Asset(
            Name = qli.Product2.Name,
            SOW_Type__c = (qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_PROSERV
                            ? Product2Helper.SOW_TYPE_PROSERV
                            : Product2Helper.SOW_TYPE_CC_PROSERV),
            Discount_Type__c = qli.Discount_type__c,
            Discount_Number__c = qli.Discount_number__c != null ? qli.Discount_number__c : 0,
            Unit_Price__c = qli.UnitPrice,
            Quantity = qli.NewQuantity__c,
            AccountId = qli.Quote.AccountId,
            Product2Id = qli.Product2.Id,
            Total_Price__c = (qli.UnitPrice == null ? 0 : qli.UnitPrice) * qli.NewQuantity__c,
            Start_Date__c = Date.today(),
            Delivered_Quantity__c = calculateDeliveredQuantity(hliList),
            Active__c = true
        );
        return assetRecord;
    }

    private static Decimal calculateDeliveredQuantity(List <Hardware_Line_Item__c> hliList) {
        Decimal deliveredQuanity = 0;
        if (!hliList.isEmpty()) {
            for(Hardware_Line_Item__c hli : hliList) {
                deliveredQuanity+=hli.Quantity__c;
            }
        }
        return deliveredQuanity;
    }

    @TestVisible
    private static Order fillChangeOrderLookup(Id parentOrderId, Map<String, List<OrderWrapper>> subCategoryOrderWrapper) {

        if(parentOrderId == null || subCategoryOrderWrapper == null || subCategoryOrderWrapper.isEmpty()) {
            return null;
        }

        List<Id> orderIds = new List<Id>();

        for(List<OrderWrapper> owList : subCategoryOrderWrapper.values()) {
            for (OrderWrapper ow : owList) {
                // changeOrder can be ProServ or CCProServ only
                if(ow.order.RecordTypeId == OrderHelper.RT_ID_PROSERV ||
                    ow.order.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) {
                    orderIds.add(ow.order.Id);
                }
            }
        }

        Id changeOrderId = !orderIds.isEmpty() ? orderIds.get(0) : null;

        if(changeOrderId == null) {
            return null;
        }

        return new Order(
            Id = parentOrderId,
            Change_Order__c = changeOrderId,
            Change_Order_18DigitId__c = Id.valueOf(changeOrderId)
        );
    }

    private static Boolean emailApexErrorsAboutError(String exceptionDetails, Id opportunityId) {
        Emails__c emailSetting = Emails__c.getValues('apexerrors');
        if (emailSetting == null) {
            return false;
        }
        String emailAddress = emailSetting.Email_Address__c;
        if (String.isBlank(emailAddress)) {
            return false;
        }

        List<String> fillers = new List<String>{
            exceptionDetails,
            String.valueOf( opportunityId ),
            String.valueOf( UserInfo.getName() ),
            String.valueOf( UserInfo.getProfileId() ),
            String.valueOf( UserInfo.getUserId() ),
            String.valueOf( DateTime.now() )
        };

        String emailBody = String.format(BIZSERV_CASE_DESCRIPTION_PLACEHOLDER, fillers);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); //instantiate a new message object
        String[] toAddresses = new String[] {emailAddress}; //denote the email address for receiving the message
        mail.setToAddresses(toAddresses); //to
        mail.setSubject('Error on clicking Generate Orders button.'); //subject
        mail.setPlainTextBody(emailBody); //body
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail}); //send
            return true;
        }
        catch (Exception e) {
            System.debug('cannot send e-mail about case error');
            System.debug(e.getMessage());
            return false;
        }
    }

    private static String handleCatchException(Exception ex, System.SavePoint sp) {

        System.debug('in handleCatchException. ex >>> ' + ex);

        String exceptionDetailsStr = ex.getTypeName() + ': ' + ex.getMessage() + '. Stacktrace: ' + ex.getStackTraceString();

        Database.rollback(sp);

        return exceptionDetailsStr;
    }

    private static String convertSubCategory(String subCategory){
        return (Product2Helper.SUBCATEGORY_RINGCENTRAL.equalsIgnoreCase(subCategory)
                || Product2Helper.SUBCATEGORY_CLOUDCONNECT.equalsIgnoreCase(subCategory))
                    ? RINGCENTRAL_SUBCATEGORY
                    : subCategory;
    }

    private static String determineOrderStatus(String subcategory, String brand) {

        String result = OrderHelper.STATUS_NEW;

        String subcatConverted = convertSubCategory(subcategory);

        Boolean setSubmittedStatus = RINGCENTRAL_SUBCATEGORY.equalsIgnoreCase(subcatConverted)
                                    || Product2Helper.SUBCATEGORY_PROSERV.equalsIgnoreCase(subcatConverted)
                                    || Product2Helper.SUBCATEGORY_CC_PROSERV.equalsIgnoreCase(subcatConverted);

        if(setSubmittedStatus) {
            result = (brand == RingCentralHelper.BRAND_VERIZON
                    ? OrderHelper.STATUS_SUBMITTED_PARTNERS
                    : OrderHelper.STATUS_SUBMITTED);
        }

        return result;
    }

    private static String convertStatus(String status){
        return (status == 'New' ? 'New Customer' : (status == 'Upsell' ? 'Up-sell' : status));
    }

    public static Map<String, Schema.RecordTypeInfo> getSObjectTypes(String obj){
        return ((SObject)Type.forName(obj).newInstance()).getSObjectType().getDescribe().getRecordTypeInfosByName();
    }

    @TestVisible
    private static Opportunity getOpportunityRecord(Id oppId) {
        return [SELECT Id, Name, OwnerId, CloseDate, StageName, AccountId, Owner.Name, RecordType.Name,
            Account.AccountNumber, Account.Name, Account.Timezone__c, Account.BillingCity, Tier_Name__c,
            Account.BillingCountry, Account.BillingStreet, Account.BillingPostalCode,
            Account.BillingState, Account.inContact_account_ID__c, Account.inContact_Cluster__c,
            Account.RC_Account_Number__c, Account.GSP__c, Primary_Opportunity_Contact__c, Parent_Order__c,
            Parent_Order__r.MaxPhaseNumber__c, PrimaryQuote__r.Package_Info__c, PrimaryQuote__r.IsMultiProductTechnicalQuote__c,  Is_Billing_Opportunity__c, BusinessIdentity__c, Brand_Name__c,
        (SELECT Id, RecordTypeId FROM Orders),
        (SELECT Id, Status__c, Estimated_Completion_Date__c, Initial_Payment__c,
                    PhaseDescription__c, Last_Phase__c FROM Phases__r),
        (SELECT Id, RecordTypeId, ServiceName__c, Package_Info__c, IsMultiProductTechnicalQuote__c FROM Quotes)
        FROM Opportunity
        WHERE Id =: oppId];
    }

    private static Map<Id, List<QuoteLineItem>> getQuoteLineItems(List<Quote> quotes) {
        Set<Id> quoteIds = new set<Id>();
        Map<Id, List<QuoteLineItem>> qlisByQuoteId = new Map<Id, List<QuoteLineItem>>();

        for(Quote qt: quotes) {
            quoteIds.add(qt.Id);
        }

        List<QuoteLineItem>qlis = [SELECT Id, ListPrice, Product2Id, PriceBookEntryId, PricebookEntry.Pricebook2Id,Discount,
            QuoteRecordType__c,Sub_Category__c, Product_Type__c, Charge_Term__c,
            Quantity, UnitPrice, Product2.Product_Type__c, Product2.ExtID__c, EffectivePrice__c,
            Discount_type__c, Discount_number__c, Product2.Sub_Category__c, Matcher_Fields__c, Entitlement__c,
            Entitlement__r.Discount__c, Entitlement__r.Discount_Type__c, Entitlement__r.Quantity__c,
            Zero_Quantity__c, Deactivated__c, Product2.Edition__c, Product2.Number_of_Minutes__c, Package_Info_QLI__c,
            Product2.Family, Product2.Charge_Term__c, Product2.Name, Threshold__c, PackageInfo__c,Product2.Matcher_Formula__c,
            BillingStatus__c, Quantity_or_Threshold__c, Overage_parent__c, Quote.Id, Quote.CurrencyIsoCode,
            Quote.InvalidGlobalOfficePhonesQuantity__c,Quote.InvalidLimitedExtensionPhonesQuantity__c,
            Quote.Upsell_Status__c, Quote.End_Date__c, Quote.Pricebook2Id, Quote.Credit_Amount__c,
            Quote.CreatedById, Quote.CreatedBy.ManagerId, Quote.Account.Id, Quote.IsPrimary__c, Quote.Free_Service_Taxes__c,
            Quote.SOW_Type__c, Quote.Signed_SOW__c, Quote.RecordTypeId, NewQuantity__c, Asset__c, Quote.Special_Terms__c,
            Entitlement__r.Product__c, Display_Name__c, Entitlement__r.DisplayQuantity__c, Package_Info__c
        FROM QuoteLineItem
        WHERE Quote.Id IN :quoteIds
        AND Product2.Sub_Category__c != null
        AND Product2.Family !='Taxes'];

        for(QuoteLineItem qli: qlis){
            if(qlisByQuoteId.get(qli.Quote?.Id) == null) {
                qlisByQuoteId.put(qli.Quote.Id, new List<QuoteLineItem>());
            }
            qlisByQuoteId.get(qli.Quote?.Id).add(qli);
        }
        return qlisByQuoteId;
    }

    private static List<Quote> getQuotes(Id oppId) {
        List <Quote> quotes = new List <Quote>();
        Boolean isSoldPS = false;
        for (Quote qt : [SELECT Id, Credit_Amount__c, CurrencyIsoCode, IsPrimary__c, Upsell_Status__c, ProServ_Status__c,
                InvalidGlobalOfficePhonesQuantity__c,InvalidLimitedExtensionPhonesQuantity__c, Pricebook2.Plan__c, Payment_Plan__c, QuoteNumber,
                LastModifiedDate, Pricebook2Id, End_Date__c, InvalidDiscountedPhonesQuantity__c, SOW_Type__c, Signed_SOW__c,
                Invalid_GO_LE_Phones_Quantity__c, CreatedById, CreatedBy.ManagerId, RecordTypeId,Opportunity.StageName,Brand__c,
                Pricebook2.AllowedRecordType__c,Opportunity.Is_Billing_Opportunity__c,Package_Info__c,Account.Billing_ID__c
            FROM Quote
            WHERE opportunityId =: oppId
            AND (
                RecordTypeId != :QuoteHelper.RT_ID_BILLING
                OR isPrimary__c = true
            )]) {

            isSoldPS = qt.ProServ_Status__c == QuoteHelper.PROSERVSTATUS_SOLD;    
            if(qt.Opportunity.Is_Billing_Opportunity__c) {
                if (
                    QuoteHelper.isNewBillingQuote(qt) ||
                    (QuoteHelper.isProservQuote(qt) && isSoldPS) ||
                    (QuoteHelper.isCCProServQuote(qt) && isSoldPS) ||
                    QuoteHelper.isCCQuote(qt)
                ) {
                    quotes.add(qt);
                }
            } else {
                if (qt.RecordTypeId == QuoteHelper.RT_ID_SALES) {
                    if (qt.IsPrimary__c == true) {
                        quotes.add(qt);
                    }
                } else if (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV ||
                           qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV) {
                    if (isSoldPS) {
                        quotes.add(qt);
                    }
                } else {
                    quotes.add(qt);
                }
            }
        }
        return quotes;
    }

    @TestVisible
    private static String getValidationErrors(List <SObject> sObj) {
        String error;
        List<String> serviceNames = new List<String>{
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };
        //Validations for opportunity
        if(sObj.get(0).getSObjectType() == Opportunity.SObjectType) {
            Opportunity opp = (Opportunity)sObj.get(0);
            // Check if opportunity brand is Ringcentral with Verizon and stage
            // is 7.1 Closed Won for ProServ
            if(OpportunityHelper.isVerizon(opp) && !OpportunityHelper.isClosedWonProServ(opp.StageName)) {
                error = JSON.serialize(getResponseError('error',
                        Label.GenerateOrderNotificationNotClosedWonProServ,
                        null));
            }

           // Check if opportunity stage not equals to closed
            if(!OpportunityHelper.isClosed(opp.StageName)) {
                error = JSON.serialize(getResponseError('error',
                    Label.GenerateOrderNotificationOnlyOpptiesInCloseWonStage,
                    null));
            }


            if (opp.Is_Billing_Opportunity__c) {
                Boolean hasCCQuote = false;
                Boolean hasProServQuote = false;

                Boolean isEngageOrInContact = false;
                for (Quote q : opp.Quotes) {
                    if (QuoteHelper.isEngageOrInContact(q)) {
                        isEngageOrInContact = true;
                        break;
                    }
                }

                for (Quote q : opp.Quotes) {
                    if (q.RecordTypeId == QuoteHelper.RT_ID_CC) {
                        hasCCQuote = true;
                    }
                    if (q.RecordTypeId == QuoteHelper.RT_ID_PROSERV ||
                        (isEngageOrInContact || QuoteHelper.isMultiProductQuoteHasServicePackage(opp.PrimaryQuote__r, serviceNames)) && q.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV) {
                        hasProServQuote = true;
                    }
                }
                if (!hasCCQuote && !hasProServQuote) {
                    error = JSON.serialize(getResponseError('info',
                        Label.GenerateOrderNotificationNoCCOrProServQuotes,
                        null));
                }
            }

            //Check if orders were already generated for this opportunity
            if (!opp.Orders.isEmpty()) {
                for (Order orderItem: opp.Orders) {
                    if (orderItem.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV || orderItem.RecordTypeId == OrderHelper.RT_ID_PROSERV) {
                        error = JSON.serialize(getResponseError('info', Label.GenerateOrderNotificationAlreadyGenerated, null));
                    }
                }
            }
        }

        //Validations for quote
        if (sObj.get(0).getSObjectType() == Quote.SObjectType) {
            for(SObject obj : sObj) {
                Quote q = (Quote)obj;
                //Check if there are errors on Quote
                if (q.isPrimary__c &&
                    !QuoteHelper.isNewBillingQuote(q) &&
                    !QuoteHelper.isPOCQuote(q) &&
                    opp.RecordType.Name != 'Cancel Opportunity' &&
                    (q.InvalidDiscountedPhonesQuantity__c ||
                        q.InvalidGlobalOfficePhonesQuantity__c ||
                        q.InvalidLimitedExtensionPhonesQuantity__c ||
                        q.Invalid_GO_LE_Phones_Quantity__c )) {
                    error = JSON.serialize(
                        getResponseError('error',
                            Label.GenerateOrderNotificationDifferentNumberPhonesAndDLsText,
                            Label.GenerateOrderNotificationDifferentNumberPhonesAndDLsHelpText
                        )
                    );
                }
            }
        }
        return error;
    }

    private static Map<String, String> getResponseError (String status, String message, String details) {
        Map<String, String> response = new Map<String, String>();
        response.put('status', status);
        response.put('message', message);
        if (details != null) {
            response.put('details', details);
        }
        return response;
    }

    private static OrderWrapper createNewOrder (Opportunity opp, String subcategory, Boolean isCancelOrder, List<Package__c> packages) {
        String convertedSubcategory = convertSubCategory(subcategory);

        Quote qt = subCategoryItems.get(subcategory).qliList[0].Quote;

        Order newOrder = new Order(
            AccountId = opp.AccountId,
            BillingCity = (opp.AccountId !=null ? opp.Account.BillingCity : null),
            BillingStreet = (opp.AccountId !=null ? opp.Account.BillingStreet : null),
            BillingPostalCode = (opp.AccountId !=null ? opp.Account.BillingPostalCode : null),
            BillingCountry = (opp.AccountId !=null ? opp.Account.BillingCountry : null),
            BillingState = (opp.AccountId !=null ? opp.Account.BillingState : null),
            BillToContactId = opp.Primary_Opportunity_Contact__c,
            OpportunityId = opp.Id,
            CurrencyIsoCode = qt.CurrencyIsoCode,
            Name = generateOrderName(opp.Name, convertedSubcategory),
            OwnerId = opp.OwnerId,
            Type = (QuoteHelper.isProservQuote(qt) || QuoteHelper.isCcProservQuote(qt))
                ? OrderHelper.TYPE_INITIAL_ORDER
                : convertStatus(primaryQuote.Upsell_Status__c),
            QuoteId = qt.Id,
            End_Date__c = qt.End_Date__c,
            ShippingCity = (opp.AccountId !=null ? opp.Account.BillingCity : null),
            ShippingStreet = (opp.AccountId !=null ? opp.Account.BillingStreet : null),
            ShippingPostalCode = (opp.AccountId !=null ? opp.Account.BillingPostalCode : null),
            ShippingCountry = (opp.AccountId !=null ? opp.Account.BillingCountry : null),
            ShippingState = (opp.AccountId !=null ? opp.Account.BillingState : null),
            ShipToContactId = opp.Primary_Opportunity_Contact__c,
            Pricebook2Id = qt.Pricebook2Id,
            RecordTypeId = getSObjectTypes('Order').get(convertedSubcategory).getRecordTypeId(),
            EffectiveDate = opp.CloseDate,
            Status = determineOrderStatus(subcategory, OpportunityHelper.getBrand(opp)),
            inContact_Cluster__c = opp.Account.inContact_Cluster__c,
            Submitted_Date__c = subcategory == Product2Helper.SUBCATEGORY_RINGCENTRAL ? System.now() : null,
            SOW_Type__c = qt.SOW_Type__c,
            MaxPhaseNumber__c = (opp.Parent_Order__c != null && opp.Parent_Order__r.MaxPhaseNumber__c != null) ? opp.Parent_Order__r.MaxPhaseNumber__c : null,
            Signed_SOW__c = qt.Signed_SOW__c,
            Is_Cancel_Order__c = isCancelOrder
        );

        if (QuoteHelper.isCCQuote(qt)) {
            if (qt.Special_Terms__c != null && QuoteHelper.getNumberFromString(qt.Special_Terms__c) != null) {
                newOrder.Credit_Amount__c = qt.Credit_Amount__c;
                newOrder.Taxes_Amount__c = qt.Free_Service_Taxes__c;
                newOrder.FSC_Terms__c = QuoteHelper.getNumberFromString(qt.Special_Terms__c);
            }
        }

        OrderWrapper ow = new OrderWrapper(newOrder, isCancelOrder);
        return ow;
    }

    private static String generateOrderName(String optyName, String convertedSubcategory) {
        if ((optyName.length() + convertedSubcategory.length() + 1) > ORDER_NAME_MAX_LENGTH) {
            return optyName.substring(0, ORDER_NAME_MAX_LENGTH - convertedSubcategory.length() - ORDER_NAME_MORE_QUIALIFIER.length())
                + ORDER_NAME_MORE_QUIALIFIER
                + convertedSubcategory;
        }
        return optyName + ' ' + convertedSubcategory;
    }

    private static String getCCOrderType (List<QuoteLineItem> qlis, List<Entitlement__c> Ents){
        Decimal totalMrr = 0;
        Entitlement__c mEnt;
        Boolean isDeactivatedExist = false;
        Boolean isActivatedExist = false;

        for (QuoteLineItem qli : qlis){
            if (String.isNotBlank(qli.Matcher_Fields__c)) {

                if (!qli.Deactivated__c && isCCSeat(qli)) {
                    isActivatedExist = true;
                }

                if (qli.Deactivated__c && isCCSeat(qli)) {
                    isDeactivatedExist = true;
                }

                for (Entitlement__c ent : Ents) {
                    if (doesEntCoincidesQli(qli,ent)) {
                        mEnt = ent;
                        break;
                    }
                }
            } else {
                List<Entitlement__c> matcherResult =
                    (Entitlement__c[])RecordsMatcher.match(Ents, qli.Product2, 'Matcher_Formula__c');
                mEnt = (matcherResult.size() > 0 ? matcherResult[0] : null);
            }
            Decimal totalMonthlyPriceWithEntitlement = QuoteLineItemHelper.getTotalMonthlyPriceWithEntitlement(qli);
            totalMrr += totalMonthlyPriceWithEntitlement - (mEnt == null ? 0 : mEnt.Total_Monthly_Price__c);
        }

        return Ents.size() > 0
            ? isActivatedExist == false && isDeactivatedExist == true
                ? OrderHelper.CC_ORDER_TYPE_CHURN
                : totalMrr < 0
                    ? OrderHelper.CC_ORDER_TYPE_DOWNSELL
                    : OrderHelper.CC_ORDER_TYPE_UPSELL
            : OrderHelper.CC_ORDER_TYPE_NEW;
    }

    private static Boolean doesEntCoincidesQli (QuoteLineItem qli, Entitlement__c ent){
        return ent.Product__r.Family == qli.Product2.Family
            && ent.Product__r.Product_Type__c == qli.Product2.Product_Type__c;
    }

    private static Boolean isCCSeat(QuoteLineItem qli){
        return qli.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER &&
            qli.Product_Type__c == Product2Helper.PRODUCT_TYPE_SEAT;
    }

    public static void populateMaps(List<Quote> quotes, List<Entitlement__c> ccEnts, Map<Id, QuoteLineItem> qliIdMap, Map<String, ItemsWrapper> subCategoryItems, Opportunity opp) {

        Boolean isBillingOpportunity = opp.Is_Billing_Opportunity__c;
        String primaryQuoteChargeTerm = QuoteHelper.getPlan(QuoteHelper.getPrimaryQuote(quotes, isBillingOpportunity));

        // Build product id to entitlement map
        Map<Id, Entitlement__c> productIdToEntitlement = new Map<Id, Entitlement__c>();
        for (Entitlement__c ent : ccEnts) {
            productIdToEntitlement.put(ent.Product__c, ent);
        }
        Map<id, List<QuoteLineItem>> qlisByQuoteId = getQuoteLineItems(quotes);

        ItemsWrapper itemsWrapper = new ItemsWrapper();
        for (Quote qt : quotes) {
            if (qlisByQuoteId.get(qt.id) != null) {
                for(QuoteLineItem qli : qlisByQuoteId.get(qt.id)) {
                    // All non One-Time products should go to RingCentral order
                    Boolean shouldGoToRCOrder = (PROSERV_PRODUCT_SUBCATEGORIES.contains(qli.Product2.Sub_Category__c)
                        && (qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME));

                    Boolean proservProduct = PROSERV_PRODUCT_SUBCATEGORIES.contains(qli.Product2.Sub_Category__c);
                    if (qt.RecordTypeId == QuoteHelper.RT_ID_SALES || qt.RecordTypeId == QuoteHelper.RT_ID_CC) {
                        // Take into account only products with Sub_Category__c = Main
                        if(shouldGoToRCOrder) {
                            if(!subCategoryItems.containsKey(Product2Helper.SUBCATEGORY_RINGCENTRAL)) {
                                subCategoryItems.put(Product2Helper.SUBCATEGORY_RINGCENTRAL, new ItemsWrapper());
                            }
                            subCategoryItems.get(Product2Helper.SUBCATEGORY_RINGCENTRAL).qliList.add(qli);
                            qliIdMap.put(qli.Id, qli);
                        }else {
                            if(!proservProduct) {

                                if(!subCategoryItems.containsKey(qli.Product2.Sub_Category__c)){
                                    subCategoryItems.put(qli.Product2.Sub_Category__c, new ItemsWrapper());
                                }

                                subCategoryItems.get(qli.Product2.Sub_Category__c).qliList.add(qli);
                                qliIdMap.put(qli.Id, qli);
                            }
                        }
                    } else {

                        Boolean isGSP = SettingsService.onlyProServQuotesAvailable(opp);
                        Boolean isChangeOrderQuote = (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV
                            || qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV)
                            && (qt.Upsell_Status__c == QuoteHelper.STATUS_UPSELL || isGSP);

                        // If there is also a proserv quote
                        if(!shouldGoToRCOrder && !qt.IsPrimary__c) {
                            if(!subCategoryItems.containsKey(qli.Product2.Sub_Category__c)){
                                subCategoryItems.put(qli.Product2.Sub_Category__c, new ItemsWrapper());
                            }
                            subCategoryItems.get(qli.Product2.Sub_Category__c).qliList.add(qli);
                            qliIdMap.put(qli.Id, qli);
                            // If there is only one quote and it is proserv quote
                        } else if(!(qt.RecordTypeId == QuoteHelper.RT_ID_SALES) && qt.IsPrimary__c && isChangeOrderQuote) {
                            if(!subCategoryItems.containsKey(qli.Product2.Sub_Category__c)){
                                subCategoryItems.put(qli.Product2.Sub_Category__c, new ItemsWrapper());
                            }
                            subCategoryItems.get(qli.Product2.Sub_Category__c).qliList.add(qli);
                        }
                    }

                    // Match entitlements, remove that entitlements which are matched with qli
                    if (productIdToEntitlement.get(qli.Product2Id) != null) {
                        productIdToEntitlement.remove(qli.Product2Id);
                    }
                }
            }
        }
    }
    /*
     * As Generate orders class is able to create ordinary and cancel orders
     * the source order items are created from has different nature.
     * Ordinary order items are created from quote line items, cancel order items are created from entitlements.
     * ItemsWrapper is used as storage for both of them.
     */
    public class ItemsWrapper {
        private List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        private List<Entitlement__c> entList = new List<Entitlement__c>();
    }
    /*
     * Wrapper for Order object, stores info if order is cancel or not
     */
    public class OrderWrapper {
        private Order order;
        private Boolean isCancelOrder;

        public OrderWrapper(Order order, Boolean isCancelOrder) {
            this.order = order;
            this.isCancelOrder = isCancelOrder;
        }
    }
    /*
     * Wrapper for OrderItem object, stores info if order item is cancel or not
     */
    public class OrderItemWrapper {
        private OrderItem orderItem;
        private Boolean isCancelOrder;

        public OrderItemWrapper(OrderItem orderItem, Boolean isCancelOrder) {
            this.orderItem = orderItem;
            this.isCancelOrder = isCancelOrder;
        }
    }

    public class TotalPrices{
        Double totalPricesOneTimeSumm = 0;
        Double totalPricesAnnualSumm = 0;
        Double totalPricesMonthlySumm = 0;
    }
}