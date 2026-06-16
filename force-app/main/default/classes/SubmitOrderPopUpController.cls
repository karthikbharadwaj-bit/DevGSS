public with sharing class SubmitOrderPopUpController {

    private final Order order;

    public List<OrderItem> orderItems;

    public String accountName {get; set;}

    public String ccOrderType {get; set;}
    public List<SelectOption> getCcOrderTypeValues() {
        return buildSelectOptions('Case', 'CC_Order_Type__c');
    }

    public Integer inContactBuId {get; set;}
    public String ringCentralUId {get; set;}
    public String contactCenterNumber {get; set;}
    public String ringCentralAccountNumber {get; set;}


    private static final String EMPTY_TIMEZONE_LABEL = '--None--';
    private static final String EMPTY_TIMEZONE_VALUE = 'None';

    public String defaultTimeZone {get; set;}
    public List<SelectOption> getDefaultTimeZoneValues() {
        List<SelectOption> opts = buildSelectOptions('Account', 'Timezone__c');
        opts.add( new SelectOption(EMPTY_TIMEZONE_VALUE, EMPTY_TIMEZONE_LABEL) );
        return opts;
    }

    public Id newCaseId {get; set;}

    public String geoRegion {get; set;}
    public List<SelectOption> getGeoRegionValues() {
        return buildSelectOptions('Case', 'Geo_Region__c');
    }


    public String description {get; set;}
    public String subject {get; set;}

    private static final String CASE_ORIGIN_DEFAULT = 'Web';
    public String caseOrigin {get; set;}
    public List<SelectOption> getCaseOriginValues() {
        return buildSelectOptions('Case', 'Origin');
    }


    public String productOrService {get; set;}
    public List<SelectOption> getProductOrServiceValues() {
        return buildSelectOptions('Case', 'Product_or_Service__c');
    }


    public String contactName {get; set;}

    public String implementationTeam {get; set;}
    public List<SelectOption> getImplementationTeamValues() {
        return buildSelectOptions('Case', 'Implementation_Team__c');
    }
    public String inContactSegment {get; set;}
    public List<SelectOption> getInContactSegmentValues() {
        return buildSelectOptions('Case', 'inContact_Segment__c');
    }

    public Boolean customerNotification {get; set;}

    public Boolean isRejectedOrderWithWrongDomesticMinutesOverage {get; set;}

    private static final Map<Id, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_ID = Order.SObjectType.getDescribe().getRecordTypeInfosById();

    public SubmitOrderPopUpController() {

        Id currentOrderId = ApexPages.currentPage().getParameters().get('id');

        order = [SELECT Id, Status, Contact_Center_Number__c, Type, AccountId, RingCentral_Account_Number__c, Submitted_Date__c,
                Account.Name, Account.inContact_Account_Id__c, Account.RC_User_Id__c,
                Account.RC_Account_Number__c, Account.Timezone__c,
                OpportunityId, Opportunity.Brand_Name__c, Opportunity.BusinessIdentity__c,
                RecordTypeId,inContact_Segment__c,
                Quote.Id, (SELECT Id FROM Phases__r)
                FROM Order WHERE Id = :currentOrderId];

        orderItems = [select Id, OrderId, Quantity, Zero_Quantity__c, Active__c, BillingStatus__c, Threshold__c,
            PricebookEntry.Product2.CatID__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Product_Type__c,
            PricebookEntry.Product2.InContact_Name__c, PricebookEntry.Product2.inContact_Price__c,
            PricebookEntry.Product2.Name, PriceBookEntry.Product2.Sub_Category__c, PricebookEntry.UnitPrice
            from OrderItem where OrderId = :currentOrderId];
        System.debug('orderItems >>> ' + orderItems);

        populatePopUpFields(order, orderItems);
    }

    public Order getOrder() {
        return order;
    }

    private void showErrorOnPopUp(String errorText) {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, errorText);
        ApexPages.addMessage(msg);
    }


    private void populatePopUpFields(Order currentOrder, List<OrderItem> orderItemsList) {

        accountName = currentOrder.Account.Name;
        ccOrderType = String.isBlank(currentOrder.Account.inContact_Account_Id__c) ? OrderHelper.TYPE_NEW_ORDER : 'Change Order';

        if( !String.isBlank( currentOrder.Account.inContact_Account_Id__c ) ) {
            inContactBuId = Integer.valueOf(currentOrder.Account.inContact_Account_Id__c);
        }else{
            inContactBuId = null;
        }

        //inContactBuId = String.isBlank( currentOrder.Account.inContact_Account_Id__c ) ? 0 : Integer.valueOf(currentOrder.Account.inContact_Account_Id__c);

        ringCentralUId = currentOrder.Account.RC_User_Id__c;

        contactCenterNumber = currentOrder.Contact_Center_Number__c;
        ringCentralAccountNumber = currentOrder.RingCentral_Account_Number__c;

        //defaultTimeZone = currentOrder.Account.Timezone__c;
        if( currentOrder.Account.Timezone__c == null ) {
            defaultTimeZone = EMPTY_TIMEZONE_VALUE;
        }else{
            defaultTimeZone = currentOrder.Account.Timezone__c;
        }

        geoRegion = getDefaultPickListValue('Case', 'Geo_Region__c');

        String descr = 'ADD PRODUCTS: \n';
        String reduceDescr = 'REDUCE PRODUCTS: \n';
        String tempDescr = '';
        String overagesDescr = '';
        String inactiveOveragesDescr = '';
        List<OrderItem> overagesWithSeat = new List<OrderItem>();


        for(OrderItem item : orderItemsList) {
            if(item.PricebookEntry.Product2.Family == 'Overage' &&
            (item.PricebookEntry.Product2.Product_Type__c == 'Port' ||
            item.PricebookEntry.Product2.catID__c == '309-11-171' ||
            item.PricebookEntry.Product2.catID__c == '309-565-000' ||
            item.PricebookEntry.Product2.catID__c == '309-566-000')) {
                overagesWithSeat.add(item);
            }
        }

        for(OrderItem overage : overagesWithSeat) {
            if(overage.Zero_Quantity__c && overage.Active__c) {
                overagesDescr += '' +
                        '0.00' +
                        '[' + overage.PricebookEntry.Product2.CatID__c + ']' + ' - ' +
                        (String.isEmpty(overage.PricebookEntry.Product2.InContact_Name__c) == true ?
                            overage.PriceBookEntry.Product2.Name : overage.PricebookEntry.Product2.InContact_Name__c) + ' $' +
                        (overage.PricebookEntry.Product2.inContact_Price__c != null ? String.valueof(overage.PricebookEntry.Product2.inContact_Price__c) : '') + '\n';
             }

             if(overage.Zero_Quantity__c && !overage.Active__c) {
                inactiveOveragesDescr += '' +
                        '0.00' +
                        '[' + overage.PricebookEntry.Product2.CatID__c + ']' + ' - ' +
                        (String.isEmpty(overage.PricebookEntry.Product2.InContact_Name__c) == true ?
                            overage.PriceBookEntry.Product2.Name : overage.PricebookEntry.Product2.InContact_Name__c) + ' $' +
                        (overage.PricebookEntry.Product2.inContact_Price__c != null ? String.valueof(overage.PricebookEntry.Product2.inContact_Price__c) : '') + '\n';
             }
        }

        OrderItem parentMinutesBundle;
        OrderItem overageDomesticMinutes;

        for(OrderItem item : orderItemsList) {
            if(!Product2Helper.FAMILY_MINUTES_BUNDLE_LIST.contains(item.PricebookEntry.Product2.Family)) {

                if (item.PricebookEntry.Product2.Name == 'Domestic Minutes Overage') {
                    overageDomesticMinutes = item; // We save the Domestic Minutes Overage orderItem for later comparison
                }

                tempDescr = serializeOrderItem(item);

                if(item.Quantity > 0 && !item.Zero_Quantity__c) {
                    descr += tempDescr;

                    if(Pattern.matches('Contact\\sCenter.+Seat.*', item.PricebookEntry.Product2.Name) && item.PricebookEntry.Product2.Family == 'CC Service') {
                        descr += overagesDescr;
                    }
                } else if (!item.Zero_Quantity__c
                        && !(Product2Helper.isOverage(item.PricebookEntry.Product2) 
                            && Product2Helper.PRODUCT_TYPES_BUNDLES.contains(item.PricebookEntry.Product2.Product_Type__c))) {
                    reduceDescr += tempDescr;

                    if(Pattern.matches('Contact\\sCenter.+Seat.*', item.PricebookEntry.Product2.Name) && item.PricebookEntry.Product2.Family == 'CC Service') {
                        reduceDescr += inactiveOveragesDescr;
                    }
                } else if (Product2Helper.getCCBundleTypeName(item.PricebookEntry.Product2) == Product2Helper.PRODUCT_TYPE_MESSAGES
                        && Product2Helper.isOverage(item.PriceBookEntry.Product2)) { // textel overage ? add serialized str to desc or reduceDesc
                    if (item.BillingStatus__c == 'Replaced' || item.BillingStatus__c == 'Cancelled') {
                        reduceDescr += tempDescr;
                    } else {
                        descr += tempDescr;
                    }
                }
            }  else if (Product2Helper.FAMILY_MINUTES_BUNDLE.contains(item.PricebookEntry.Product2.Family)) {
                parentMinutesBundle = item; // We save the Minutes Bundle orderItem for later comparison
            }
        }

        // CPS-564 : In case that the Domestic Minutes Overage has an incorrect zero value, set the order status as rejected so CRM team can correct it before sending to DWH
        isRejectedOrderWithWrongDomesticMinutesOverage = false;

        if (parentMinutesBundle != null) {
            // There is a Minutes Bundle, so the threshold of the Domestic Minutes Overage should be different than zero

            if (overageDomesticMinutes == null || overageDomesticMinutes.Threshold__c == null || overageDomesticMinutes.Threshold__c == 0) {
                isRejectedOrderWithWrongDomesticMinutesOverage = true;
            }
        }


        List<OrderItem> incntctProvisionedOIList = findIncontactProvisionedOrderItems(currentOrder);
        if(incntctProvisionedOIList.size() > 0) {

            for(OrderItem item : incntctProvisionedOIList) {

                tempDescr = '' +
                    item.Quantity +
                    '[' + item.PricebookEntry.Product2.CatID__c + ']' + ' - ' +
                    item.PricebookEntry.Product2.InContact_Name__c + ' $' +
                    item.PricebookEntry.Product2.inContact_Price__c + '\n';

                if(item.Quantity > 0 && !item.Zero_Quantity__c) {
                    descr += tempDescr;
                } else {
                    if(!item.Zero_Quantity__c) {
                        reduceDescr += tempDescr;
                    }
                }
            }
        }


        descr += reduceDescr;

        descr += 'SERVICES: \n NOTES:\n';
        descr += 'TELECOM CHARGES:\n';
        descr += '12619-328-000-XX Domestic Toll-Free Number - Setup $0.50\n';
        descr += '1051-371-000-XX Domestic Toll-Free Number - Account Activation $0.00\n';
        descr += '1270-136-000 Domestic Toll-Free Number - Monthly Recurring Charge $0.40\n';
        descr += 'DOM_TF_FLAT_48INTRA_MIN Domestic Toll-Free Number - Flat Per-minute (Intrastate for 48 States) $0.008\n';
        descr += 'DOM_TF_FLAT_INTER_MIN Domestic Toll-Free Number - Flat Per-minute (Interstate) $0.008\n';
        descr += '12619-333-000 Domestic Local Number - Setup $0.00\n';
        descr += '1051-372-000-XX Domestic Local Number - Account Activation $0.00\n';
        descr += '1012-150-000 Domestic Local Number - Monthly Recurring Charge $0.40\n';
        descr += 'DOM_LN_MIN Domestic Local Number - Per-minute Charge $0.008\n';
        descr += 'DOM_TERM_FLAT_INTER_MIN Domestic Termination - Flat Per-minute (Interstate) $0.008\n';
        descr += 'DOM_TERM_FLAT_48INTRA_MIN Domestic Termination - Flat Standard Per-minute (Intrastate for 48 States) $0.008\n';

        description = descr;

        // If CC Order Type == "New Order" - value should be "NBU <ACCOUNT NAME>",
        // if CC Order Type == "Change Order" - value should be "Change Order <ACCOUNT NAME>"
        subject = (ccOrderType == OrderHelper.TYPE_NEW_ORDER)
            ? CaseHelper.NBU_CASE_SUBJECT + ' ' + currentOrder.Account.Name
            : (ccOrderType == 'Change Order') ? 'Change Order ' + currentOrder.Account.Name : '';


        //caseOrigin = getDefaultPickListValue('Case', 'Origin');
        caseOrigin = CASE_ORIGIN_DEFAULT;
        productOrService = getDefaultPickListValue('Case', 'Product_or_Service__c');
        contactName = getCaseDefaultFieldValue('Contact_Name__c');
        implementationTeam = getDefaultPickListValue('Case', 'Implementation_Team__c');
        //inContactSegment = getDefaultPickListValue('Case', 'inContact_Segment__c');
		inContactSegment = currentOrder.inContact_Segment__c;
        customerNotification = false;
    }

    private List<OrderItem> findIncontactProvisionedOrderItems(Order currentOrder) {

        List<OrderItem> incontactProvisionedOrderItemsList = new List<OrderItem>();

        if(currentOrder == null) {

            return incontactProvisionedOrderItemsList;
        }

        String currentOrderRecordTypeName = ORDER_RT_INFO_BY_ID.get( currentOrder.RecordTypeId ).getName();

        if(currentOrderRecordTypeName == 'Contact Center') {

            Id currentOppId = currentOrder.OpportunityId;

            List<Order> ordersList = [select Id, RecordTypeId,
                                            (select Id, Quantity, QuoteLineItemId,
                                                Zero_Quantity__c,
                                                PricebookEntry.Product2.CatID__c,
                                                PricebookEntry.Product2.InContact_Name__c,
                                                PricebookEntry.Product2.inContact_Price__c,
                                                QuoteLineItem.Provisioned_by_inContact__c
                                            from OrderItems)
                                        from Order
                                        where OpportunityId = :currentOppId];

            for(Order ord : ordersList) {

                String currentRtName = ORDER_RT_INFO_BY_ID.get( ord.RecordTypeId ).getName();

                if(currentRtName == 'CC Professional Services') {

                    for(OrderItem oi : ord.OrderItems) {

                        if(oi.QuoteLineItem.Provisioned_by_inContact__c == true) {

                            incontactProvisionedOrderItemsList.add(oi);
                        }
                    }
                }
            }
        }

        return incontactProvisionedOrderItemsList;
    }

    public void validateFromVF() {
        if( !isValidPopUpValues() ) {
            // show error
            showErrorOnPopUp('All the required fields should be populated to Submit an Order to inContact');
        }
    }

    public Boolean isValidPopUpValues() {

        // all commented fields - disabled on popup form

        //if( String.isEmpty(accountName) || String.isEmpty(ccOrderType) || /*String.isEmpty( String.valueOf(inContactBuId) ) || */
        //    /*String.isEmpty(ringCentralUId) ||*/ String.isEmpty(contactCenterNumber) || /*String.isEmpty(ringCentralAccountNumber) ||*/
        //    String.isEmpty(defaultTimeZone) || String.isEmpty(geoRegion) || String.isEmpty(description) ||
        //    String.isEmpty(subject) || /*String.isEmpty(caseOrigin) || String.isEmpty(productOrService) ||*/ String.isEmpty(contactName) ||
        //    String.isEmpty(implementationTeam) ) {

        //    return false;
        //}else{
        //    return true;
        //}

        System.debug('in validate inContactBuId >>> ' + inContactBuId);
        System.debug('in validate ccOrderType >>> ' + ccOrderType);



        if( String.isEmpty(accountName) || String.isEmpty(ccOrderType) || String.isEmpty(contactCenterNumber) ||
            String.isEmpty(defaultTimeZone) || String.isEmpty(geoRegion) || String.isEmpty(description) ||
            String.isEmpty(subject) || String.isEmpty(contactName) || String.isEmpty(implementationTeam) || String.isEmpty(inContactSegment)) {

            return false;

        }else{
            return true;
        }

    }

    public PageReference createCaseFromVF() {

        if( isValidPopUpValues() ) {

            Id inContactOrderRTId = CaseHelper.RT_ID_INCONTACT_ORDER;

            if(inContactBuId == 0) {
                inContactBuId = null;
            }
            System.debug('inContactBuId before insert >>> ' + inContactBuId);

            if( defaultTimeZone == EMPTY_TIMEZONE_VALUE ) {
                defaultTimeZone = null;
            }

            Case newCase = new Case(
                AccountId = order.AccountId,
                Order__c = order.Id,
                Opportunity_Reference__c = order.OpportunityId,
                CC_Order_Type__c = ccOrderType,
                //inContact_BU_ID__c = inContactBuId != null ? Decimal.valueOf(inContactBuId) : null,
                inContact_BU_ID__c = inContactBuId,
                //ringCentralUId = ringCentralUId,
                Contact_Center_Number__c = contactCenterNumber,
                RingCentral_Account_Number__c = ringCentralAccountNumber,
                Default_Time_Zone__c = defaultTimeZone,
                Geo_Region__c = geoRegion,
                description = description,
                subject = subject,
                Origin = caseOrigin,
                Product_or_Service__c = productOrService,
                Contact_Name__c = contactName,
                Implementation_Team__c = implementationTeam,
                inContact_Segment__c = inContactSegment,
                Customer_Notification__c = customerNotification,
                RecordTypeId = inContactOrderRTId
            );

            System.debug('newCase >>>> ' + newCase);

            //insert newCase;
            Database.SaveResult sr = Database.insert(newCase);

            if(sr.isSuccess()) {

                newCaseId = newCase.Id;

                // update Order.Status
                // order.Status = 'Submitted';
                // update order;

                // CPS-564 : In case that the Domestic Minutes Overage has an incorrect zero value, set the order status as rejected so CRM team can correct it before sending to DWH
                if (isRejectedOrderWithWrongDomesticMinutesOverage) {
                    order.Status = 'Requires Attention';
                    order.BillingStatus__c = 'Rejected';
                    order.BillingStatusDetails__c = 'There is an incorrect value on the Domestic Minutes Overage. Please do not modify any values and contact the CRM team.';
                    order.Submitted_Date__c = System.now();
                } else {
                    order.Status = OpportunityHelper.isVerizon(order.Opportunity)
                        ? OrderHelper.STATUS_SUBMITTED_PARTNERS
                        : OrderHelper.STATUS_SUBMITTED;
                }

                update order;
                updateOrderItemsBillingStatus(order.Id);
            }else{
                for(Database.Error err : sr.getErrors()) {
                    System.debug('insert case Error. ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }

            return null;

        }else{

            // show error
            showErrorOnPopUp('All the required fields should be populated to Submit an Order to inContact');

            return null;
        }
    }


    private List<SelectOption> buildSelectOptions(String objectName, String picklistName) {

        List<SelectOption> options = new List<SelectOption>();
        for (Schema.PicklistEntry pv : getPickListValues( objectName, picklistName )) {
            options.add( new SelectOption(pv.getLabel(), pv.getValue()) );
        }
        return options;

    }


    private static List<Schema.PicklistEntry> getPickListValues(String objName, String fieldName) {

        List<Schema.PicklistEntry> picklistValues = new List<Schema.PicklistEntry>();
        String[] types = new String[]{objName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSobjectResult res = results[0];
        picklistValues =   res.fields.getMap().get(fieldName).getDescribe().getPicklistValues();

        return picklistValues;
    }



    private static String getDefaultPickListValue(String objName, String fieldName) {
        String defaultVal;
        List<Schema.PicklistEntry> picklistValues = new List<Schema.PicklistEntry>();
        String[] types = new String[]{objName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSobjectResult res = results[0];
        picklistValues =   res.fields.getMap().get(fieldName).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry pv : picklistValues) {
            if (pv.isDefaultValue()) {
                defaultVal = pv.getValue();
            }
        }

        return defaultVal;
    }

    private static String getCaseDefaultFieldValue(String fieldName) {

        // create new Record. firstParam - RecordType, second - specify all default values should be populated or not
        Case record = (Case)Case.SObjectType.newSobject(null, true);

        String fieldValue = (String) record.get(fieldName);

        return fieldValue;

    }

    public PageReference updateBillingStatus() {
        Set<Quote> quotesToUpdate = new Set<Quote>();
//        Set<Order> ordersToUpdate = new Set<Order>();
        Set<Phase__c> phasesToUpdate = new Set<Phase__c>();

        quotesToUpdate.add(new Quote(
            Id = this.order.Quote.Id,
            BillingStatus__c = 'Submitted'
        ));

//        ordersToUpdate.add(new Order(
//            Id = this.order.Id,
//            BillingStatus__c = 'Submitted'
//            ));

        for(Phase__c p : this.order.Phases__r) {
            phasesToUpdate.add(new Phase__c(
                Id = p.Id,
                BillingStatus__c = 'Submitted'
            ));
        }

        update new List<Quote>(quotesToUpdate);
//        update new List<Order>(ordersToUpdate);
        update new List<Phase__c>(phasesToUpdate);

        return null;
    }

    public static void updateOrderItemsBillingStatus(Id orderId) {
        Order currentOrder = [SELECT Status, Submitted_Date__c, RecordTypeId, (Select BillingStatus__c From OrderItems) FROM Order WHERE Id = :orderId LIMIT 1];

        if ((currentOrder.RecordTypeId == OrderHelper.RT_ID_CC || currentOrder.RecordTypeId == OrderHelper.RT_ID_RC_CONTACT_CENTER)
            && (OrderHelper.STATUS_SUBMITTED_PARTNERS.equalsIgnoreCase(currentOrder.Status) || OrderHelper.STATUS_SUBMITTED.equalsIgnoreCase(currentOrder.Status))
            && ((currentOrder.Submitted_Date__c != null && currentOrder.Submitted_Date__c.day() >= 15))) {

            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
            for (OrderItem orderItem : currentOrder.orderItems) {
                if (orderItem.BillingStatus__c == 'Replaced') {
                    orderItem.BillingStatus__c = 'Cancelled';
                    orderItemsToUpdate.add(orderItem);
                }
            }

            update orderItemsToUpdate;
        }
    }

    @TestVisible
    private static String serializeOrderItem(OrderItem orderItem) {
        String qty = String.valueOf(orderItem.Quantity);
        String catId = orderItem.PricebookEntry.Product2.CatID__c;
        String name = orderItem.PricebookEntry.Product2.InContact_Name__c;
        String price = String.valueOf(orderItem.PricebookEntry.Product2.inContact_Price__c);

        if (Product2Helper.PRODUCT_TYPES_BUNDLES.contains(orderItem.PricebookEntry.Product2.Product_Type__c)) {
            final Matcher matcher = Product2Helper.BUNDLE_VOLUME_PATTERN.matcher(orderItem.PricebookEntry.Product2.Name);
            matcher.find();
            final String bundleVolume = matcher.group()?.remove(',');
            qty = (orderItem.Quantity < 0 ? '-' : '') + bundleVolume + '.00';
            if (!Product2Helper.isOverage(orderItem.PriceBookEntry.Product2)) {
                catId = catId.substringBeforeLast('-') + '-000';
            }
            if (orderItem.PricebookEntry.Product2.Product_Type__c == Product2Helper.PRODUCT_TYPE_MESSAGES) {
                qty = orderItem.Quantity < 0 ? '-1.00' : '1.00';
                if (Product2Helper.isOverage(orderItem.PriceBookEntry.Product2)) {
                    qty = (orderItem.BillingStatus__c == 'Replaced' || orderItem.BillingStatus__c == 'Cancelled') 
                        ? '-0.00' 
                        : '0.00';
                    name = String.format(
                        'Textel Overage Rate Beyond {0} (per Message)',
                        new List<Object>{Product2Helper.BUNDLE_STRING_BY_VOLUME.get(bundleVolume)}
                    );
                }
            }
        }

        return String.format(
            '{0}[{1}] {2} ${3}\n', 
            new List<Object>{
                qty,
                catId,
                name,
                price
            }
        );
    }
}