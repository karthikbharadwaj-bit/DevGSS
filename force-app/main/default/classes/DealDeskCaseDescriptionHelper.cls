public with sharing class DealDeskCaseDescriptionHelper {
    public static final String SHIPPING_CASE_TEMPLATE_TYPE = 'Shipping';
    public static final String INITIAL_ORDER_CASE_TEMPLATE_TYPE = 'Initial Order';
    public static final String CHANGE_ORDER_CASE_TEMPLATE_TYPE = 'Change Order';

    public static final Map<String, String> TEMPLATE_TYPES_TO_PRODUCT2_FIELD = new Map<String, String>{
        SHIPPING_CASE_TEMPLATE_TYPE => 'ShippingType__c',
        INITIAL_ORDER_CASE_TEMPLATE_TYPE => 'InitialOrderType__c',
        CHANGE_ORDER_CASE_TEMPLATE_TYPE => 'UpsellType__c'
    };

    public static final Map<String, String> TEMPLATE_TYPES_TO_CASE_TEMPLATE_FIELD = new Map<String, String>{
        SHIPPING_CASE_TEMPLATE_TYPE => 'ShippingReq__c',
        INITIAL_ORDER_CASE_TEMPLATE_TYPE => 'InitialOrderType__c',
        CHANGE_ORDER_CASE_TEMPLATE_TYPE => 'UpsellType__c'
    };

    public static final Map<String, String> TEMPLATE_TYPES_TO_DEFAULT_SUBJECT = new Map<String, String>{
        SHIPPING_CASE_TEMPLATE_TYPE => CaseHelper.CASE_SUBJECT_MANUAL_SHIPPING,
        INITIAL_ORDER_CASE_TEMPLATE_TYPE => CaseHelper.CASE_SUBJECT_MANUAL_PROVISIONING,
        CHANGE_ORDER_CASE_TEMPLATE_TYPE => CaseHelper.CASE_SUBJECT_MANUAL_PROVISIONING
    };

    @TestVisible
    private static List<NGBSProcessOrderCaseTemplate__mdt> templatesMetadata;
    private static Set<String> validOwnerIds;
    private static Map<Id, Template> templatesMap;

    @TestVisible
    private class Template {
        public Id id;
        public String type;
        public String labelValue;
        public String licenseIdOrCategoryCode;

        public String subject;
        public String ownerId;
        public String description;
        public String instruction;

        public Template(NGBSProcessOrderCaseTemplate__mdt metadata) {
            this.id = metadata.Id;
            this.type = metadata.Type__c;
            this.labelValue = (String) metadata.get(TEMPLATE_TYPES_TO_CASE_TEMPLATE_FIELD.get(this.type));
            this.licenseIdOrCategoryCode = metadata.LicenceIdOrCategoryCode__c;
            this.subject = String.isNotBlank(metadata.Subject__c)
                ? metadata.Subject__c
                : TEMPLATE_TYPES_TO_DEFAULT_SUBJECT.get(this.type);
            this.ownerId = validOwnerIds.contains(metadata.Owner__c)
                ? metadata.Owner__c
                : DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId;
            this.description = metadata.Description__c;
            this.instruction = metadata.Instruction__c;
        }
    }

    @TestVisible
    private class CaseDescriptionMapping {

        @TestVisible
        private List<Template> licenseIdOrCategoryCodeTemplates {get; private set;}

        @TestVisible
        private List<Template> defaultTemplates {get; private set;}

        public CaseDescriptionMapping() {
            this.licenseIdOrCategoryCodeTemplates = new List<Template>();
            this.defaultTemplates = new List<Template>();
        }

        public void addLicenseIdOrCategoryCodeTemplate(Template template) {
            this.licenseIdOrCategoryCodeTemplates.add(template);
        }

        public void addDefaultTemplate(Template template) {
            this.defaultTemplates.add(template);
        }
    }

    @TestVisible
    private class QLIsByLabelsData {
        public List<QuoteLineItem> qlisWithShippingLabel = new List<QuoteLineItem>();
        public List<QuoteLineItem> qlisWithInitialOrderTypeLabel = new List<QuoteLineItem>();
        public List<QuoteLineItem> qlisWithUpsellTypeLabel = new List<QuoteLineItem>();

        public Boolean isEmpty() {
            return qlisWithShippingLabel.isEmpty() && qlisWithInitialOrderTypeLabel.isEmpty() && qlisWithUpsellTypeLabel.isEmpty();
        }
    }

    @TestVisible
    private class TemplateData {
        public String templateType = '';
        public Map<Id, List<QuoteLineItem>> templateIdToQLIs = new Map<Id, List<QuoteLineItem>>();

        public TemplateData(String templateType, Map<Id, List<QuoteLineItem>> templateIdToQLIs) {
            this.templateType = templateType;
            this.templateIdToQLIs = templateIdToQLIs;
        }
    }

    private abstract class CaseDescriptionBuilder {
        private Quote qt;
        private Map<Id, List<QuoteLineItem>> templateIdToQLIs;

        CaseDescriptionBuilder(Quote qt, Map<Id, List<QuoteLineItem>> templateIdToQLIs) {
            this.qt = qt;
            this.templateIdToQLIs = templateIdToQLIs;
        }

        private String getDescriptionHeader(String templateDesc) {
            String descriptionHeader = '';
            String accountUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + this.qt.Account__c;
            descriptionHeader += 'Account: ' + accountUrl + '\n\n';
            String opportunityUrl =  URL.getOrgDomainUrl().toExternalForm() + '/' + this.qt.OpportunityId;
            descriptionHeader += 'Opportunity: ' + opportunityUrl + '\n\n';
            descriptionHeader += templateDesc;
            return descriptionHeader;
        }
    }

    private abstract class InitialChangeOrderCaseDescriptionBuilder extends CaseDescriptionBuilder {
        private List<AssignmentLineItem__c> assignmentLineItems;
        private List<Area_Code_Line_Item__c> areaCodeLineItems;

        private final String PRODUCTS_TEMPLATE = '\n\n{0}. Product Name: {1}; Charge Term: {2}; Price: {3}; Quantity: {4}; Discount: {5};';
        private final String ASSIGNED_PRODUCT_TEMPLATE = '\nProduct Name: {0}; Charge Term: {1}; Price: {2}; Quantity: {3}; Discount: {4};';
        private final String AREA_CODE_TEMPLATE = '\nArea Code: {0};';

        public InitialChangeOrderCaseDescriptionBuilder(
            Quote qt,
            Map<Id, List<QuoteLineItem>> templateIdToQLIs,
            List<AssignmentLineItem__c> assignmentLineItems,
            List<Area_Code_Line_Item__c> areaCodeLineItems
        ) {
            super(qt, templateIdToQLIs);
            this.assignmentLineItems = assignmentLineItems;
            this.areaCodeLineItems = areaCodeLineItems;
        }

        public List<DealDeskCaseDescription__c> buildDealDeskCaseDescriptions() {
            List<DealDeskCaseDescription__c> result = new List<DealDeskCaseDescription__c>();

            for (Id templateId : this.templateIdToQLIs.keySet()) {
                Template template = templatesMap.get(templateId);
                Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(
                    this.templateIdToQLIs.get(templateId)
                );
                String description = composeDescription(
                    template.description, qlisMap
                );

                if (!String.isBlank(template.instruction)) {
                    description += '\n\n' + template.instruction;
                }

                DealDeskCaseDescription__c caseDescription =
                    (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        DealDeskCaseDescription__c.CaseDescription__c => description,
                        DealDeskCaseDescription__c.Account__c => qt.Account__c,
                        DealDeskCaseDescription__c.Subject__c => generateCaseSubject(template.subject, qt.Opportunity.Name),
                        DealDeskCaseDescription__c.CaseOwner__c => template.ownerId
                    })
                    .build()
                    .getRecord();

                result.add(caseDescription);
            }

            return result;
        }

        @TestVisible
        private String composeDescription(String templateDesc, Map<Id, QuoteLineItem> qlisMap) {
            String description = '';
            Integer qliCounter = 0;
            Map<Id, Integer> qliQuantityMap = new Map<Id, Integer>();

            // get header of the description
            description += this.getDescriptionHeader(templateDesc);

            // get list of products
            for (QuoteLineItem qli : qlisMap.values()) {
                qliQuantityMap.put(qli.Id, Math.round(qli.Quantity));
            }

            for (AssignmentLineItem__c ali : this.assignmentLineItems) {
                QuoteLineItem qli = qlisMap.get(ali.Parent__c);
                if (qli != null) {
                    description += composeProductDescription(qli, ++qliCounter, ali.Quantity__c);
                    description += composeAssignedProductDescription(ali);
                    description += composeAreaCodeDescription(ali.AreaCode__r);

                    qliQuantityMap.put(qli.Id, getUpdatedQuantity(qliQuantityMap, qli.Id, ali.Quantity__c));
                }
            }

            for (Area_Code_Line_Item__c acli : this.areaCodeLineItems) {
                QuoteLineItem qli = qlisMap.get(acli.Quote_Line_Item__c);
                if (qli != null) {
                    description += composeProductDescription(qli, ++qliCounter, acli.Quantity__c);
                    description += composeAreaCodeDescription(acli.Area_Code__r);

                    qliQuantityMap.put(qli.Id, getUpdatedQuantity(qliQuantityMap, qli.Id, acli.Quantity__c));
                }
            }

            for (QuoteLineItem qli : qlisMap.values()) {
                if (qliQuantityMap.get(qli.Id) > 0) {
                    description += composeProductDescription(qli, ++qliCounter, qliQuantityMap.get(qli.Id));
                }
            }

            return description;
        }

        private Integer getUpdatedQuantity(Map<Id, Integer> qliQuantityMap, Id qliId, Decimal newQuantity) {
            return Math.round(qliQuantityMap.get(qliId) - newQuantity);
        }

        private String composeProductDescription(QuoteLineItem qli, Integer qliCounter, Decimal quantity) {
            return String.format(
                this.PRODUCTS_TEMPLATE,
                new List<String>{
                    String.valueOf(qliCounter),
                    qli.Display_Name__c,
                    qli.Charge_Term__c,
                    calculatePrice(qli),
                    String.valueOf(Math.round(quantity)),
                    calculateDiscount(qli)
                }
            );
        }

        private String composeAssignedProductDescription(AssignmentLineItem__c ali) {
            return String.format(
                this.ASSIGNED_PRODUCT_TEMPLATE,
                new List<String>{
                    ali.Child__r.Display_Name__c,
                    ali.Child__r.Charge_Term__c,
                    calculatePrice(ali.Child__r),
                    String.valueOf(Math.round(ali.Quantity__c)),
                    calculateDiscount(ali.Child__r)
                }
            );
        }

        private String composeAreaCodeDescription(Area_Codes__c areaCode) {
            String areaCodeCity = areaCode.City__c != null ? areaCode.City__c : '';
            return String.format(
                this.AREA_CODE_TEMPLATE,
                new List<String>{
                    areaCode.Area_Code__c + ' ' + areaCodeCity + ' ' + areaCode.Country__c
                }
            );
        }
    }

    @TestVisible
    private class ShippingCaseDescriptionBuilder extends CaseDescriptionBuilder {
        private List<CustomAddressAssignments__c> addressAssignments;
        private List<CustomAddress__c> customAddresses;

        private final String SHIPPING_GROUP_TEMPLATE = '\n\nShipping Group {0}: {1}';
        private final String PRODUCTS_TEMPLATE = '\n\n{0}. Product Name: {1}; Quantity: {2};';

        public ShippingCaseDescriptionBuilder(
            Quote qt,
            Map<Id, List<QuoteLineItem>> templateIdToQLIs,
            List<CustomAddressAssignments__c> addressAssignments,
            List<CustomAddress__c> customAddresses
        ) {
            super(qt, templateIdToQLIs);
            this.addressAssignments = addressAssignments;
            this.customAddresses = customAddresses;
        }

        public List<DealDeskCaseDescription__c> buildDealDeskCaseDescriptions() {
            List<DealDeskCaseDescription__c> result = new List<DealDeskCaseDescription__c>();

            Boolean isCustomAddressAssignmentNeeded = !QuoteHelper.isNewBusiness(this.qt) || Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c;
            for (Id templateId : this.templateIdToQLIs.keySet()) {
                Template template = templatesMap.get(templateId);
                String description;
                Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(this.templateIdToQLIs.get(templateId));
                if (isCustomAddressAssignmentNeeded) {
                    Map<Id, List<CustomAddressAssignments__c>> addressIdToCaasMap = this.getAddressToCaasMap(this.addressAssignments, qlisMap);
                    description = this.composeDescription(template.description, addressIdToCaasMap, qlisMap);
                } else {
                    description = this.composeDescription(template.description, qlisMap.values());
                }

                if (!String.isBlank(template.instruction)) {
                    description += '\n\n' + template.instruction;
                }

                DealDeskCaseDescription__c caseDescription =
                    (DealDeskCaseDescription__c) new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        DealDeskCaseDescription__c.CaseDescription__c => description,
                        DealDeskCaseDescription__c.Account__c => qt.Account__c,
                        DealDeskCaseDescription__c.Subject__c => generateCaseSubject(template.subject, qt.Opportunity.Name),
                        DealDeskCaseDescription__c.CaseOwner__c => template.ownerId
                    })
                    .build()
                    .getRecord();

                result.add(caseDescription);
            }
            return result;
        }

        @TestVisible
        private Map<Id, List<CustomAddressAssignments__c>> getAddressToCaasMap(List<CustomAddressAssignments__c> addressAssignments, Map<Id, QuoteLineItem> qlisMap) {
            Map<Id, List<CustomAddressAssignments__c>> addressIdToCaasMap = new Map<Id, List<CustomAddressAssignments__c>>();

            for (CustomAddressAssignments__c assignment : addressAssignments) {
                if (qlisMap.containsKey(assignment.QuoteLineItem__c)) {
                    if (!addressIdToCaasMap.containsKey(assignment.CustomAddress__c)) {
                        addressIdToCaasMap.put(assignment.CustomAddress__c, new List<CustomAddressAssignments__c>());
                    }
                    addressIdToCaasMap.get(assignment.CustomAddress__c).add(assignment);
                }
            }

            return addressIdToCaasMap;
        }

        @TestVisible
        private String composeDescription(String templateDesc, Map<Id, List<CustomAddressAssignments__c>> addressIdToCaasMap, Map<Id, QuoteLineItem> qlisMap) {
            Map<Id, CustomAddress__c> customAddressesMap = new Map<Id, CustomAddress__c>(this.customAddresses);
            Integer addressCounter = 0;
            String description = '';

            description += this.getDescriptionHeader(templateDesc);

            for (Id addressId : addressIdToCaasMap.keySet()) {
                Integer qliCounter = 0;
                description += composeShippingGroupHeader(customAddressesMap.get(addressId), ++addressCounter);
                for(CustomAddressAssignments__c caa : addressIdToCaasMap.get(addressId)) {
                    description += composeProductDescription(qlisMap.get(caa.QuoteLineItem__c), ++qliCounter, caa.Quantity__c);
                }
            }

            return description;
        }

        @TestVisible
        private String composeDescription(String templateDesc, List<QuoteLineItem> qliList) {
            String description = '';
            Integer qliCounter = 0;

            description += this.getDescriptionHeader(templateDesc);

            for (QuoteLineItem qli : qliList) {
                description += composeProductDescription(qli, ++qliCounter, qli.Quantity);
            }

            return description;
        }

        private String composeShippingGroupHeader(CustomAddress__c customAddress, Integer addressCounter) {
            String street = customAddress.Street__c == null ? '' : customAddress.Street__c;
            String city = customAddress.City__c == null ? '' : customAddress.City__c;
            String state = customAddress.State__c == null ? '' : customAddress.State__c;
            String postalCode = customAddress.PostalCode__c == null ? '' : customAddress.PostalCode__c;
            String stateAndPostalCode = state + ' ' + postalCode;
            String country = customAddress.Country__c == null ? '' : customAddress.Country__c;
            String address = String.join(new List<String> {street, city, stateAndPostalCode, country}, ', ');

            return String.format(
                this.SHIPPING_GROUP_TEMPLATE,
                new List<String>{
                    String.valueOf(addressCounter),
                    address
                }
            );
        }

        private String composeProductDescription(QuoteLineItem qli, Integer qliCounter, Decimal quantity) {
            return String.format(
                this.PRODUCTS_TEMPLATE,
                new List<String>{
                    String.valueOf(qliCounter),
                    qli.Display_Name__c,
                    String.valueOf(quantity)
                }
            );
        }
    }

    @TestVisible
    private class InitialOrderCaseDescriptionBuilder extends InitialChangeOrderCaseDescriptionBuilder {

        public InitialOrderCaseDescriptionBuilder(
            Quote qt,
            Map<Id, List<QuoteLineItem>> templateIdToQLIs,
            List<AssignmentLineItem__c> assignmentLineItems,
            List<Area_Code_Line_Item__c> areaCodeLineItems
        ) {
            super(qt, templateIdToQLIs, assignmentLineItems, areaCodeLineItems);
        }
    }

    @TestVisible
    private class ChangeOrderCaseDescriptionBuilder extends InitialChangeOrderCaseDescriptionBuilder {

        public ChangeOrderCaseDescriptionBuilder(
            Quote qt,
            Map<Id, List<QuoteLineItem>> templateIdToQLIs,
            List<AssignmentLineItem__c> assignmentLineItems,
            List<Area_Code_Line_Item__c> areaCodeLineItems
        ) {
            super(qt, templateIdToQLIs, assignmentLineItems, areaCodeLineItems);
        }
    }

    public static String calculatePrice(QuoteLineItem qli) {
        Decimal formattedPriceValue = qli.UnitPrice.setScale(2, RoundingMode.HALF_UP);
        return String.valueOf(formattedPriceValue) + ' ' + qli.CurrencyIsoCode;
    }

    public static String calculateDiscount(QuoteLineItem qli) {
        String discountValue;
        Decimal discountNumber = qli.Discount_number__c == null ? 0 : qli.Discount_number__c;

        if (qli.Discount_type__c.equals(QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)) {
            discountValue = String.valueOf(discountNumber.setScale(2, RoundingMode.HALF_UP)) + '%';
        } else {
            discountValue = String.valueOf(discountNumber.setScale(2, RoundingMode.HALF_UP)) + ' ' + qli.CurrencyIsoCode;
        }
        return discountValue;
    }

    public static List<DealDeskCaseDescription__c> handleDealDeskCaseDescriptionsForSignUp(Quote qt) {
        return handleDealDeskCaseDescriptions(qt, true);
    }

    public static List<DealDeskCaseDescription__c> handleDealDeskCaseDescriptionsForSyncWithNGBS(Quote qt) {
        return handleDealDeskCaseDescriptions(qt, false);
    }

    @TestVisible
    private static List<DealDeskCaseDescription__c> handleDealDeskCaseDescriptions(Quote qt, Boolean isSignUp) {

        initializeTemplatesMap();

        // if we already have DealDeskCaseDescription__c records for the account - delete them before creating new
        new NoSharing().deleteExistingDealDeskCaseDescriptions(qt.Account__c);

        if(qt == null) {
            return new List<DealDeskCaseDescription__c>();
        }

        QLIsByLabelsData qliData = getQuoteLineItemsByLabels(qt.BusinessIdentity__c, qt.QuoteLineItems);
        if(qliData.isEmpty()) {
            return new List<DealDeskCaseDescription__c>();
        }

        Map<String, TemplateData> templateDataMap = getTemplateDataMap(qliData);

        Map<Id,QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(qt.QuoteLineItems);
        List<CustomAddressAssignments__c> addressAssignments =
            (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
            .selectCAAForShipping(new List<Object>{qlisMap.keySet()})
            .executeQuery();
        Set<Id> customAddressIds = new Set<Id>();
        for(CustomAddressAssignments__c assignment : addressAssignments) {
            customAddressIds.add(assignment.CustomAddress__c);
        }
        List<CustomAddress__c> customAddresses = new List<CustomAddress__c>();
        if(!QuoteHelper.isNewBusiness(qt) || Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c) {
            customAddresses = (List<CustomAddress__c>) new CustomAddressSelector()
                .selectCustomAddressesByIds(new List<Object>{customAddressIds})
                .executeQuery();
        }

        List<AssignmentLineItem__c> assignmentLineItems = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForDealDeskCaseDescription(new List<Object>{qlisMap.keySet()})
            .executeQuery();

        List<Area_Code_Line_Item__c> areaCodeLineItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
            .selectACLIForDealDeskCaseDescription(new List<Object>{qlisMap.keySet()})
            .executeQuery();

        List<DealDeskCaseDescription__c> dealDeaskCaseDescriptionsToInsert = getDealDeskCaseDescriptions(
                qt,
                templateDataMap,
                addressAssignments,
                customAddresses,
                assignmentLineItems,
                areaCodeLineItems,
                isSignUp
            );

        return dealDeaskCaseDescriptionsToInsert;
    }

    @TestVisible
    private static List<DealDeskCaseDescription__c> getDealDeskCaseDescriptions(
        Quote qt,
        Map<String, TemplateData> templateDataMap,
        List<CustomAddressAssignments__c> addressAssignments,
        List<CustomAddress__c> customAddresses,
        List<AssignmentLineItem__c> assignmentLineItems,
        List<Area_Code_Line_Item__c> areaCodeLineItems,
        Boolean isSignUp
    ) {
        List<DealDeskCaseDescription__c> dealDeaskCaseDescriptionsToInsert = new List<DealDeskCaseDescription__c>();

        for (String templateType : templateDataMap.keySet()) {
            TemplateData data = templateDataMap.get(templateType);
            if (templateType == SHIPPING_CASE_TEMPLATE_TYPE) {
                List<DealDeskCaseDescription__c> caseDescriptionForShippingType = new ShippingCaseDescriptionBuilder(
                    qt, data.templateIdToQLIs, addressAssignments, customAddresses
                ).buildDealDeskCaseDescriptions();

                dealDeaskCaseDescriptionsToInsert.addAll(caseDescriptionForShippingType);
            } else if (templateType == INITIAL_ORDER_CASE_TEMPLATE_TYPE && isSignUp && qt.ServiceInfo__r.isEmpty()) {
                List<DealDeskCaseDescription__c> caseDescriptionForInitialOrderType = new InitialOrderCaseDescriptionBuilder(
                    qt, data.templateIdToQLIs, assignmentLineItems, areaCodeLineItems
                ).buildDealDeskCaseDescriptions();

                dealDeaskCaseDescriptionsToInsert.addAll(caseDescriptionForInitialOrderType);
            } else if (templateType == CHANGE_ORDER_CASE_TEMPLATE_TYPE && !isSignUp && qt.ServiceInfo__r.isEmpty()) {
                List<DealDeskCaseDescription__c> caseDescriptionForUpsellType = new ChangeOrderCaseDescriptionBuilder(
                    qt, data.templateIdToQLIs, assignmentLineItems, areaCodeLineItems
                ).buildDealDeskCaseDescriptions();

                dealDeaskCaseDescriptionsToInsert.addAll(caseDescriptionForUpsellType);
            }
        }

        return dealDeaskCaseDescriptionsToInsert;
    }

    @TestVisible
    private static Map<String, TemplateData> getTemplateDataMap(QLIsByLabelsData qliData) {
        Map<String, TemplateData> templateDataMap = new Map<String, TemplateData>();
        Map<String, CaseDescriptionMapping> mappingsForCaseTypes = getLicenseIdOrCategoryCodeToTemplate();

        CaseDescriptionMapping shippingMapping = mappingsForCaseTypes.get(SHIPPING_CASE_TEMPLATE_TYPE);
        Map<Id, List<QuoteLineItem>> shippingTemplateIdToQLI = getTemplateIdToQLIsMap(shippingMapping, qliData.qlisWithShippingLabel);
        if (!shippingTemplateIdToQLI.isEmpty()) {
            templateDataMap.put(SHIPPING_CASE_TEMPLATE_TYPE, new TemplateData(SHIPPING_CASE_TEMPLATE_TYPE, shippingTemplateIdToQLI));
        }

        CaseDescriptionMapping initialOrderMapping = mappingsForCaseTypes.get(INITIAL_ORDER_CASE_TEMPLATE_TYPE);
        Map<Id, List<QuoteLineItem>> initialOrderTemplateIdToQLI = getTemplateIdToQLIsMap(initialOrderMapping, qliData.qlisWithInitialOrderTypeLabel);
        if (!initialOrderTemplateIdToQLI.isEmpty()) {
            templateDataMap.put(INITIAL_ORDER_CASE_TEMPLATE_TYPE, new TemplateData(INITIAL_ORDER_CASE_TEMPLATE_TYPE, initialOrderTemplateIdToQLI));
        }

        CaseDescriptionMapping changeOrderMapping = mappingsForCaseTypes.get(CHANGE_ORDER_CASE_TEMPLATE_TYPE);
        Map<Id, List<QuoteLineItem>> changeOrderTemplateIdToQLI = getTemplateIdToQLIsMap(changeOrderMapping, qliData.qlisWithUpsellTypeLabel);
        if (!changeOrderTemplateIdToQLI.isEmpty()) {
            templateDataMap.put(CHANGE_ORDER_CASE_TEMPLATE_TYPE, new TemplateData(CHANGE_ORDER_CASE_TEMPLATE_TYPE, changeOrderTemplateIdToQLI));
        }

        return templateDataMap;
    }

    @TestVisible
    private static Map<String, CaseDescriptionMapping> getLicenseIdOrCategoryCodeToTemplate() {
        Map<String, CaseDescriptionMapping> templateTypeToMappindDataMap = new Map<String, CaseDescriptionMapping>();

        if (templatesMap == null || templatesMap.isEmpty()) {
            return templateTypeToMappindDataMap;
        }

        for (Template template : templatesMap.values()) {
            if (!TEMPLATE_TYPES_TO_PRODUCT2_FIELD.keySet().contains(template.type)) {
                continue;
            }
            if (!templateTypeToMappindDataMap.containsKey(template.type)) {
                templateTypeToMappindDataMap.put(template.type, new CaseDescriptionMapping());
            }
            CaseDescriptionMapping mapping = templateTypeToMappindDataMap.get(template.type);

            if (String.isNotBlank(template.licenseIdOrCategoryCode)) {
                mapping.addLicenseIdOrCategoryCodeTemplate(template);
            } else {
                mapping.addDefaultTemplate(template);
            }
        }

        return templateTypeToMappindDataMap;
    }

    @TestVisible
    private static Map<Id, List<QuoteLineItem>> getTemplateIdToQLIsMap(CaseDescriptionMapping mapping, List<QuoteLineItem> qliList) {
        Map<Id, List<QuoteLineItem>> templateIdToQLI = new Map<Id, List<QuoteLineItem>>();

        if (mapping == null || qliList == null || qliList.isEmpty()) {
            return templateIdToQLI;
        }

        for (QuoteLineItem qli : qliList) {
            BillingWrappers.QLIPackageInfo qliPackageInfo = BillingWrappers.parseQLIPackageInfo(qli.PackageInfo__c);

            Boolean isQliAssignedToNonDefaultTemplate = false;

            if (!mapping.licenseIdOrCategoryCodeTemplates.isEmpty()) {
                for (Template template : mapping.licenseIdOrCategoryCodeTemplates) {
                    Set<String> licenseIdOrCategoryCodes = splitToSet(template.licenseIdOrCategoryCode);
                    if (isTemplateApplicable(template, qli.Product2) && (licenseIdOrCategoryCodes.contains(qli.Product_Lic_Id__c) || licenseIdOrCategoryCodes.contains(qliPackageInfo.categoryCode))) {
                        if (!templateIdToQLI.containsKey(template.id)) {
                            templateIdToQLI.put(template.id, new List<QuoteLineItem>());
                        }
                        templateIdToQLI.get(template.id).add(qli);
                        isQliassignedToNonDefaultTemplate = true;
                    }
                }
            }

            if (!mapping.defaultTemplates.isEmpty() && !isQliAssignedToNonDefaultTemplate) {
                for (Template defaultTemplate : mapping.defaultTemplates) {
                    if (isTemplateApplicable(defaultTemplate, qli.Product2)) {
                        if (!templateIdToQLI.containsKey(defaultTemplate.id)) {
                            templateIdToQLI.put(defaultTemplate.id, new List<QuoteLineItem>());
                        }
                        templateIdToQLI.get(defaultTemplate.id).add(qli);
                    }
                }
            }
        }

        return templateIdToQLI;
    }

    @TestVisible
    private static QLIsByLabelsData getQuoteLineItemsByLabels(String businessIdentity, List<QuoteLineItem> qliList) {
        QLIsByLabelsData result = new QLIsByLabelsData();
        if (qliList == null || qliList.isEmpty()) {
            return result;
        }

        List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings = Product2Helper.getLicensesLabelsOverridesForBusinessIdentity(businessIdentity);
        List<QuoteLineItem> qlisWithShippingLabel = new List<QuoteLineItem>();
        List<QuoteLineItem> qlisWithInitialOrderTypeLabel = new List<QuoteLineItem>();
        List<QuoteLineItem> qlisWithUpsellTypeLabel = new List<QuoteLineItem>();

        for (QuoteLineItem qli : qliList) {
            Boolean isUpsellQli = QuoteLineItemHelper.isUpsell(qli);
            Boolean isShippingLabelManual = Product2Helper.isShippingTypeManual(qli.Product2);
            Boolean isInitalOrderTypeLabelManual = Product2Helper.isInitialOrderTypeManual(qli.Product2, licensesLabelsOverrideSettings);
            Boolean isInitialOrderTypeLabelAuto = Product2Helper.isInitialOrderTypeAuto(qli.Product2, licensesLabelsOverrideSettings);
            Boolean isUpsellTypeLabelManual = Product2Helper.isUpsellTypeManual(qli.Product2, licensesLabelsOverrideSettings);
            Boolean isUpsellTypeLabelAuto = Product2Helper.isUpsellTypeAuto(qli.Product2, licensesLabelsOverrideSettings);
            if (isShippingLabelManual) {
                qlisWithShippingLabel.add(qli);
            }
            if (isUpsellQli && (isUpsellTypeLabelManual || isUpsellTypeLabelAuto)) {
                qlisWithUpsellTypeLabel.add(qli);
            }
            if (isInitalOrderTypeLabelManual || isInitialOrderTypeLabelAuto) {
                qlisWithInitialOrderTypeLabel.add(qli);
            }
        }

        result.qlisWithShippingLabel = qlisWithShippingLabel;
        result.qlisWithInitialOrderTypeLabel = qlisWithInitialOrderTypeLabel;
        result.qlisWithUpsellTypeLabel = qlisWithUpsellTypeLabel;

        return result;
    }

    @TestVisible
    private static Set<String> splitToSet(String stringToSplit) {
        return !String.isBlank(stringToSplit)
            ? new Set<String>(stringToSplit.split(';'))
            : new Set<String>();
    }

    private static Boolean isTemplateApplicable(Template template, Product2 product) {
        return template != null && product != null && product.get(TEMPLATE_TYPES_TO_PRODUCT2_FIELD.get(template.type)) == template.labelValue;
    }

    @TestVisible
    private static void initializeTemplatesMap() {
        if (!Test.isRunningTest()) {
            templatesMetadata = new NGBSProcessOrderCaseTemplateSelector()
                .selectActiveNGBSProcessOrderCaseTemplates()
                .executeQuery();
        } else if (templatesMetadata == null) {
            templatesMetadata = new List<NGBSProcessOrderCaseTemplate__mdt>();
        }
        validOwnerIds = fetchValidOwnerIds(templatesMetadata);
        templatesMap = new Map<Id, Template>();
        for (NGBSProcessOrderCaseTemplate__mdt metadata : templatesMetadata) {
            if (TEMPLATE_TYPES_TO_CASE_TEMPLATE_FIELD.containsKey(metadata.Type__c)) {
                templatesMap.put(metadata.Id, new Template(metadata));
            }
        }
    }

    private static Set<String> fetchValidOwnerIds(List<NGBSProcessOrderCaseTemplate__mdt> metadataList) {
        Set<String> result = new Set<String>();
        if (metadataList.isEmpty()) {
            return result;
        }
        Set<String> templatesOwnerIds = new Set<String>();
        for (NGBSProcessOrderCaseTemplate__mdt mdt : metadataList) {
            if (String.isNotBlank(mdt.Owner__c)) {
                templatesOwnerIds.add(mdt.Owner__c);
            }
        }
        if (templatesOwnerIds.isEmpty()) {
            return result;
        }
        for (User u : (List<User>) new UserSelector()
                .selectUsers()
                .setCondition('Id IN :bind0 AND IsActive = TRUE')
                .setQueryBindings(new List<Object>{new List<String>(templatesOwnerIds)})
                .executeQuery()) {
            result.add(u.Id);
        }
        for (Group g : (List<Group>) new GroupSelector()
                .selectQueuesById(new List<String>(templatesOwnerIds))
                .executeQuery()) {
            result.add(g.Id);
        }
        return result;
    }

    @TestVisible
    private static String generateCaseSubject(String templateSubject, String opportunityName) {
        String fullSubject = templateSubject + ' for Opportunity: ' + opportunityName;
        String finalSubject = fullSubject.length() > 255 ? fullSubject.substring(0, 255) : fullSubject;
        return finalSubject;
    }

    private without sharing class NoSharing {
        public void deleteExistingDealDeskCaseDescriptions(Id accountId) {
            if (accountId == null) {
                return;
            }
            List<DealDeskCaseDescription__c> existingDescsForAccount = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
                .selectDealDeskCaseDescriptionsForAccounts(new List<Object>{new Set<Id>{accountId}})
                .executeQuery();
            delete existingDescsForAccount;
        }
    }
}