public with sharing class DealDeskCaseGenerator {

    public static final String CASE_SUBJECT_AREA_CODES = 'Products for area code assignment';
    public static final String CASE_SUBJECT_MANUAL_PROVISION = 'Products for manual provisioning for Account: ';
    public static final String CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION = 'Manual Order Required for Quote';
    public static final String CASE_SUBJECT_NGBSAPI_ERROR = 'NGBSAPI Error';
    public static final String URL_TO_ACCOUNT_TEMPLATE = 'Account: ' + URL.getOrgDomainUrl().toExternalForm() + '/{0}\n';
    public static final String URL_TO_OPPORTUNITY_TEMPLATE = 'Opportunity: ' + URL.getOrgDomainUrl().toExternalForm() + '/{0}\n';
    public static final String CASE_SUBJECT_DOWNSELL_SIMPLIFIED_LBO = 'Products for manual removal and deprovisioning';
    public static final String CASE_SUBJECT_MANUAL_PROVISION_MPUB = 'Products for manual provisioning';
    public static final String CASE_DESCRIPTION_BODY_MANUAL_PROVISION_MPUB = 'The following products should be provisioned manually:';

    public static final String CASE_TYPE_DOWNSELL = 'Downsell';
    public static final String CASE_TYPE_PROVISIONING = 'Provisioning';

    public static final String DOWNSELL_CASE_TEMPLATE_TYPE = 'Downsell';
    public static final String DEPROVISIONING_CASE_TEMPLATE_TYPE = 'Deprovisioning';
    public static final String PROVISIONING_CASE_TEMPLATE_TYPE = 'Provisioning';

    public static final String CASE_DESCRIPTION_HEADER = 'Account: {0}\nOpportunity: {1}';
    public static final String CASE_LINE_ITEM_DESCRIPTION_SIMPLIFIED_LBO_DOWNSELL = 'Product Name: {0}; Charge Term: {1}; Price: {2}; Quantity: {3}; Discount: {4}{5};';
    public static final String CASE_LINE_ITEM_DESCRIPTION_MANUAL_PROVISION_MPUB = 'Product Name: {0}; Charge Term: {1}; Quantity: {2}; Discount: {3}{4};';

    public static final QueueSObject DEAL_DESK_QUEUE = (QueueSObject)new QueueSelector().selectQueueByName(new List<Object> {'Sales Order Except Desk Queue'}).executeQuery().get(0);
    public static final QueueSObject BIZ_SERV_INNOVATION_QUEUE = (QueueSObject)new QueueSelector().selectQueueByName(new List<Object> {'Biz Serv Innovation Team'}).executeQuery().get(0);

    @TestVisible
    public static List<NGBSProcessOrderCaseTemplate__mdt> sortedSimplifiedLBODownsellCaseTemplateConfigList {
        get{
            if (sortedSimplifiedLBODownsellCaseTemplateConfigList == null) {
                sortedSimplifiedLBODownsellCaseTemplateConfigList = new NGBSProcessOrderCaseTemplateSelector()
                    .selectSpecifiedSorterActiveNGBSProcessOrderCaseTemplates(new Set<String>{DOWNSELL_CASE_TEMPLATE_TYPE, DEPROVISIONING_CASE_TEMPLATE_TYPE})
                    .executeQuery();
            }
            return sortedSimplifiedLBODownsellCaseTemplateConfigList;
        }
        private set;
    }

    @TestVisible
    public static List<NGBSProcessOrderCaseTemplate__mdt> sortedMPUBProvisioningCaseTemplateConfigList {
        get{
            if (sortedMPUBProvisioningCaseTemplateConfigList == null) {
                sortedMPUBProvisioningCaseTemplateConfigList = new NGBSProcessOrderCaseTemplateSelector()
                    .selectSpecifiedSorterActiveNGBSProcessOrderCaseTemplates(new Set<String>{PROVISIONING_CASE_TEMPLATE_TYPE})
                    .executeQuery();
            }
            return sortedMPUBProvisioningCaseTemplateConfigList;
        }
        private set;
    }

    public static void createCase (Quote qt, Opportunity opp, Boolean validationException, String caseReason, NGBSSyncables.ISyncable syncable) {
        ServiceInfo__c serviceInfo;
        if (qt.ServiceInfo__r == null) {
            serviceInfo = (ServiceInfo__c) new ServiceInfoSelector()
                .selectServiceInfoForSync(new List<Object> {new Set<Id> {qt.Id}})
                .executeQuery()
                .get(0);
        } else if (!qt.ServiceInfo__r.isEmpty()) {
            serviceInfo = qt.ServiceInfo__r[0];
        }

        Boolean isMPUB = serviceInfo != null;

        if ((qt.Enabled_LBO__c || QuoteHelper.isPhoenix(qt)) && !validationException) {
            if (qt.LBODealDeskProvision__c && !opp.IsAreaCodeCaseCreated__c && caseReason == null) {
                createDealDeskCaseWithAreaCodes(qt);
            }
            if (!isMPUB
                && !QuoteHelper.isPhoenix(qt)
                && !qt.QuoteLineItems.isEmpty()
                && !opp.IsManualProvisionCaseCreated__c
                && caseReason == null
            ) {
                List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(opp?.BusinessIdentity__c);
                Map<String, String> exceptionMap = SWNHelper.getLBOBillingExceptions(qt.QuoteLineItems, bypassLicenses);
                if (!exceptionMap.isEmpty()) {
                    createDealDeskCaseForManualProvision(qt, exceptionMap);
                }
            }
            if (!qt.QuoteLineItems.isEmpty() && !syncable.isDownsellCaseCreated() && qt.CountOfDownsellQLI__c > 0 && caseReason == CaseHelper.CASE_REASON_DOWNSELL) {
                createDealDeskCaseUpgradeDowngradeDownsellException(new Opportunity(), qt, CaseHelper.CASE_REASON_DOWNSELL, syncable);
            }
            if (caseReason != null && caseReason != CaseHelper.CASE_REASON_DOWNSELL) {
                createDealDeskCaseUpgradeDowngradeDownsellException(opp, qt, caseReason, syncable);
            }
            if (validationException && caseReason != null) {
                createDealDeskCaseUpgradeDowngradeDownsellException(opp, qt, caseReason, syncable);
            }
        }
        if (validationException && caseReason != null) {
            createDealDeskCaseUpgradeDowngradeDownsellException(opp, qt, caseReason, syncable);
        }
    }
    public static void createDealDeskCaseWithAreaCodes (Quote quote) {
        Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => getSubjectPrefix(quote) + CASE_SUBJECT_AREA_CODES,
                Case.RecordTypeId   => CaseHelper.RT_ID_DEALDESK_CASE,
                Case.OwnerId    => DEAL_DESK_QUEUE.QueueId,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Priority => CaseHelper.CASE_PRIORITY_MEDIUM,
                Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL,
                Case.Description => ''
            })
            .build()
            .getRecord();
        List<QuoteLineItem> qlis = new List <QuoteLineItem>();
        List<Id> qliIds = new List<Id>();
        Map<Id,List<QuoteLineItem>> oppQLIMap = new Map<Id,List<QuoteLineItem>>();
        if (quote != null) {
            for (QuoteLineItem qli : quote.QuoteLineItems) {
                qliIds.add(qli.Id);
            }
        }

        if (!qliIds.isEmpty()) {
            qlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByIdWithAreaCodes(new List<Object> {qliIds})
                .executeQuery();

            if (!qlis.isEmpty()) {

                List<QuoteLineItem> qlisForMap = new List<QuoteLineItem>();
                for (QuoteLineItem qli : qlis) {
                    if (!qli.Area_Code_Line_Items__r.isEmpty()) {
                        qlisForMap.add(qli);
                        oppQLIMap.put(qli.Quote.OpportunityId, qlisForMap);
                    }
                }
            }

            if (!oppQLIMap.isEmpty()) {
                for (Id oppId : oppQLIMap.keySet()) {
                    dealDeskCase.OpportunityOwnerEmail__c = quote.Opportunity.Owner.Email;
                    for (QuoteLineItem qli : oppQLIMap.get(oppId)) {
                        for (Area_Code_Line_Item__c ari : qli.Area_Code_Line_Items__r) {
                            if (!String.isBlank(dealDeskCase.Description)) {
                                dealDeskCase.Description += 'License: ' + qli.Product2.Name + ' - ' + ari.Area_Code__r.Country__c + ', ' + ari.Area_Code__r.State__c + ', ' + ari.Area_Code__r.City__c + ' (' + ari.Area_Code__r.Name + ') - ' + ari.Quantity__c + '\n';
                            } else {
                                dealDeskCase.Description = 'License: ' + qli.Product2.Name + ' - ' + ari.Area_Code__r.Country__c + ', ' + ari.Area_Code__r.State__c + ', ' + ari.Area_Code__r.City__c + ' (' + ari.Area_Code__r.Name + ') - ' + ari.Quantity__c + '\n';
                            }
                        }
                    }
                    dealDeskCase.Description += '\n';
                    dealDeskCase.Description += String.format(URL_TO_ACCOUNT_TEMPLATE, new List<String>{quote.AccountId});
                    dealDeskCase.Description += String.format(URL_TO_OPPORTUNITY_TEMPLATE, new List<String>{oppId});
                    dealDeskCase.AccountId = quote.AccountId;
                    dealDeskCase.Opportunity_Reference__c = oppId;
                }
            }
        }

        insert dealDeskCase;
        update new Opportunity(
            Id = quote.OpportunityId,
            IsAreaCodeCaseCreated__c = true
        );
    }

    public static void createDealDeskCaseForManualProvision (Quote quote, Map<String, String> exceptionMap) {
        Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId   => CaseHelper.RT_ID_DEALDESK_CASE,
                Case.OwnerId    => DEAL_DESK_QUEUE.QueueId,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Priority => CaseHelper.CASE_PRIORITY_MEDIUM,
                Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL
            })
            .build()
            .getRecord();

        Boolean needToCreate = false;

        if (!quote.QuoteLineItems.isEmpty()) {
            for (QuoteLineItem qli : quote.QuoteLineItems) {
                if (exceptionMap.get(qli.Product_Lic_Id__c) != null && !qli.Zero_Quantity__c) {
                    needToCreate = true;
                    break;
                }
            }
        }

        String caseDescription;
        if (quote.Id != null && needToCreate) {
            dealDeskCase.Subject = getSubjectPrefix(quote) + CASE_SUBJECT_MANUAL_PROVISION + quote.Account.Name;
            dealDeskCase.Opportunity_Reference__c = quote.OpportunityId;
            dealDeskCase.OpportunityOwnerEmail__c = quote.Opportunity.Owner.Email;
            dealDeskCase.AccountId = quote.AccountId;
            AccountHelper.FunnelNotSupportedProductsHandler handler =
                new AccountHelper.FunnelNotSupportedProductsHandler(quote.AccountId, quote.OpportunityId);
            caseDescription = handler.getHeaderDescription() + '\n\n';
            if (!quote.QuoteLineItems.isEmpty()) {
                for (QuoteLineItem qli : quote.QuoteLineItems) {
                    if (exceptionMap.get(qli.Product_Lic_Id__c) != null && !qli.Zero_Quantity__c) {
                        caseDescription += handler.getQLIdescription(qli, Integer.valueOf(String.valueOf(qli.Quantity))) + '\n\n';
                    }
                }
                dealDeskCase.Description = caseDescription;
            }
        }
        if (needToCreate) {
            insert dealDeskCase;
            update new Opportunity(
                Id = quote.OpportunityId,
                IsManualProvisionCaseCreated__c = true
            );
        }
    }

    public static void createDealDeskCaseUpgradeDowngradeDownsellException (Opportunity opp, Quote quote, String caseReason, NGBSSyncables.ISyncable syncable) {
        Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => getSubjectPrefix(quote) + CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION,
                Case.RecordTypeId   => CaseHelper.RT_ID_DEALDESK_CASE,
                Case.OwnerId    => DEAL_DESK_QUEUE.QueueId,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Priority => CaseHelper.CASE_PRIORITY_MEDIUM,
                Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL,
                Case.Description => ''
            })
            .build()
            .getRecord();

        String accId;
        String oppId;
        String ownerEmail;
        if (opp.Id != null) {
            accId = opp.AccountId;
            oppId = opp.Id;
            ownerEmail = opp.Owner.Email;
        }

        if (quote.Id != null) {
            accId = quote.AccountId;
            oppId = quote.OpportunityId;
            ownerEmail = quote.Opportunity.Owner.Email;
        }

        dealDeskCase.Opportunity_Reference__c = oppId;
        dealDeskCase.OpportunityOwnerEmail__c = ownerEmail;
        dealDeskCase.AccountId = accId;
        dealDeskCase.Description += String.format(URL_TO_ACCOUNT_TEMPLATE, new List<String>{accId});
        dealDeskCase.Description += String.format(URL_TO_OPPORTUNITY_TEMPLATE, new List<String>{oppId}) + '\n';
        dealDeskCase.Description += QuoteHelper.isPhoenix(quote) ? 'Manual Order is required for this Quote. The reason, the ' + caseReason + '.' + '\n' : 'Manual Order is required for this LBO Quote. The reason, the ' + caseReason + '.' + '\n';
        dealDeskCase.Description += 'Please check Opportunity in SFDC and Service Web to confirm which items need to be updated or purchased.';

        insert dealDeskCase;
        if (caseReason == CaseHelper.CASE_REASON_DOWNSELL) {
            syncable.setIsDownsellCaseCreated();
        }
    }

    public static void createDealDeskCaseApprovalNGBSAPIException (Approval__c app, Account acc, String caseReason) {
        Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => CASE_SUBJECT_NGBSAPI_ERROR,
                Case.RecordTypeId   => CaseHelper.RT_ID_DEALDESK_CASE,
                Case.OwnerId    => DEAL_DESK_QUEUE.QueueId,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Priority => CaseHelper.CASE_PRIORITY_MEDIUM,
                Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL
            })
            .build()
            .getRecord();

        dealDeskCase.Opportunity_Reference__c = null;
        dealDeskCase.OpportunityOwnerEmail__c = acc.Most_Recent_Opportunity_Owner_Email__c;
        dealDeskCase.AccountId = acc.Id;
        dealDeskCase.Description = 'Link to account: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '\n';
        dealDeskCase.Description += 'Link to approval: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + app.Id + '\n\n';
        dealDeskCase.Description += 'NGBSAPI Error:: ' + caseReason + '\n';
        dealDeskCase.Description += 'Please check Approval in SFDC and resubmit data to NGBS';

        insert dealDeskCase;
    }

    public static String getSubjectPrefix (Quote qt) {
        return QuoteHelper.isPhoenix(qt) ? 'RingCentral Video: ' : qt.PackageNameNew__c.contains('Rainbow') ? 'ALE - LBO: ' : qt.PackageNameNew__c.contains('Avaya') ? 'ACO - LBO: ' : qt.PackageNameNew__c.contains('Unify') ? 'ATOS - LBO: ' : 'LBO: ';
    }

    @Future
    public static void createCaseForManualProvisioningMPUBFuture(Set<Id> orderIds) {
        try {
            List<Order> ordersWithItems = (List<Order>) new OrderSelector()
                .selectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB(orderIds)
                .executeQuery();
            createCaseForManualProvisioningMPUB(ordersWithItems);
        } catch (Exception e) {
            PlatformLog.logException('createCaseForManualProvisioningMPUBFuture for Order Ids: ' + orderIds, e);
        }
    }

    public static void createCaseForManualProvisioningMPUB(List<Order> orders) {
        Map<Id, List<Order>> quoteIdToOrders = new Map<Id, List<Order>>();
        for (Order order : orders) {
            if (!quoteIdToOrders.containsKey(order.TechnicalQuoteId__c)) {
                quoteIdToOrders.put(order.TechnicalQuoteId__c, new List<Order>());
            }
            quoteIdToOrders.get(order.TechnicalQuoteId__c).add(order);
        }

        List<Case> casesToInsert = new List<Case>();
        for (Id quoteId : quoteIdToOrders.keySet()) {

            List<OrderItem> orderItemsForQuote = new List<OrderItem>();
            for (Order order : quoteIdToOrders.get(quoteId)) {

                for (OrderItem orderItem : order.OrderItems) {
                    String productOrderType = QuoteHelper.isExistingBusiness(order.TechnicalQuoteId__r)
                        ? orderItem.Product2.UpsellType__c
                        : orderItem.Product2.InitialOrderType__c;

                    if (String.isNotBlank(productOrderType) && !orderItem.Zero_Quantity__c && orderItem.Quantity > 0) {
                        orderItemsForQuote.add(orderItem);
                    }
                }
            }
            if (!orderItemsForQuote.isEmpty()) {
                DealDeskCaseGeneratorWrappers.CaseSourceWrapper source = new DealDeskCaseGeneratorWrappers.CaseSourceWrapper(quoteIdToOrders.get(quoteId).get(0));
                Case caseToInsert = buildCaseForProcessing(CASE_TYPE_PROVISIONING, source, null, orderItemsForQuote);
                if (caseToInsert != null) {
                    casesToInsert.add(caseToInsert);
                }
            }
        }

        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }
    }

    public static void createSimplifiedLBODownsellCaseFromQuote (Quote qt, Map<String, List<QuoteLineItem>> qlisForCaseCreationMap) {
        if (qlisForCaseCreationMap.get(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE).isEmpty()
            && qlisForCaseCreationMap.get(SWNHelper.DOWNSELL_TYPE_MANUAL).isEmpty()
            && qlisForCaseCreationMap.get(SWNHelper.DOWNSELL_TYPE_EXCEPTION).isEmpty()) {
                return;
        }

        DealDeskCaseGeneratorWrappers.CaseSourceWrapper source = new DealDeskCaseGeneratorWrappers.CaseSourceWrapper(qt);
        Case dealDeskCase = buildCaseForProcessing(CASE_TYPE_DOWNSELL, source, qlisForCaseCreationMap, null);

        if (dealDeskCase != null) {
            insert dealDeskCase;
        }
    }

    private static Case buildCaseForProcessing(String caseType, DealDeskCaseGeneratorWrappers.CaseSourceWrapper source, Map<String, List<QuoteLineItem>> qlisForCaseCreationMap, List<OrderItem> orderLineItems) {
        Case caseForProcessing;

        LineItemFactory lineItemFactory = new LineItemFactory();
        List<DealDeskCaseGeneratorWrappers.LineItem> lineItems = lineItemFactory.getLineItems(qlisForCaseCreationMap, orderLineItems);

        CaseBuilderFactory caseBuilderFactory = new CaseBuilderFactory();
        CaseBuilder caseBuilder = caseBuilderFactory.getCaseBuilder(caseType);

        if (caseBuilder != null) {
            caseForProcessing = caseBuilder.buildCase(source, lineItems);
        }
        return caseForProcessing;
    }

    public class LineItemFactory {
        public List<DealDeskCaseGeneratorWrappers.LineItem> getLineItems(Map<String, List<QuoteLineItem>> qlisForCaseCreationMap, List<OrderItem> orderLineItems) {
            List<DealDeskCaseGeneratorWrappers.LineItem> lineItems = new List<DealDeskCaseGeneratorWrappers.LineItem>();
            if (qlisForCaseCreationMap != null) {
                for (String qliType:  qlisForCaseCreationMap.keyset()) {
                    for (QuoteLineItem qli: qlisForCaseCreationMap.get(qliType)) {
                        lineItems.add(new DealDeskCaseGeneratorWrappers.QuoteLineItemWrapper(qli, qliType));
                    }
                }
            } else if (orderLineItems != null) {
                for (OrderItem oli: orderLineItems) {
                    lineItems.add(new DealDeskCaseGeneratorWrappers.OrderLineItemWrapper(oli));
                }
            }
            return lineItems;
        }
    }

    public class CaseBuilderFactory {
        public CaseBuilder getCaseBuilder(String caseType) {
            if (caseType == CASE_TYPE_DOWNSELL) {
                return new DownsellCaseBuilder();
            } else if (caseType == CASE_TYPE_PROVISIONING) {
                return new ProvisioningCaseBuilder();
            }
            return null;
        }
    }

    public abstract class CaseBuilder {
        public Case buildCase(DealDeskCaseGeneratorWrappers.CaseSourceWrapper source, List<DealDeskCaseGeneratorWrappers.LineItem> lineItems) {
            if (lineItems.isEmpty()) {
                return null;
            }

            Case dealDeskCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Description => getDescriptionHeader(source) + getDescriptionBody(lineItems),
                    Case.RecordTypeId => CaseHelper.RT_ID_DEALDESK_CASE,
                    Case.OwnerId => DEAL_DESK_QUEUE.QueueId,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Priority => CaseHelper.CASE_PRIORITY_MEDIUM,
                    Case.Opportunity_Reference__c => source.opportunityId,
                    Case.AccountId => source.accountId
                })
                .build()
                .getRecord();

            populateSpecificCaseFields(dealDeskCase, source);
            return dealDeskCase;
        }

        protected abstract String getDescriptionBody(List<DealDeskCaseGeneratorWrappers.LineItem> lineItems);
        protected abstract void populateSpecificCaseFields(Case dealDeskCase, DealDeskCaseGeneratorWrappers.CaseSourceWrapper source);

        protected String getDescriptionHeader(DealDeskCaseGeneratorWrappers.CaseSourceWrapper source) {
            return String.format(
                CASE_DESCRIPTION_HEADER,
                new List<Object> {
                    Url.getOrgDomainUrl().toExternalForm() + '/' + source.accountId,
                    Url.getOrgDomainUrl().toExternalForm() + '/' + source.opportunityId
                }
            ) + '\n\n';
        }
    }

    public class DownsellCaseBuilder extends CaseBuilder {
        protected override void populateSpecificCaseFields(Case cs, DealDeskCaseGeneratorWrappers.CaseSourceWrapper source) {
            cs.Subject = CASE_SUBJECT_DOWNSELL_SIMPLIFIED_LBO;
        }

        protected override String getDescriptionBody(List<DealDeskCaseGeneratorWrappers.LineItem> lineItems) {
            String description = '';

            Map<Id, List<DealDeskCaseGeneratorWrappers.LineItem>> templateIdToLineItems = matchTemplateIdsToLineItems(lineItems, sortedSimplifiedLBODownsellCaseTemplateConfigList);

            for (NGBSProcessOrderCaseTemplate__mdt template : sortedSimplifiedLBODownsellCaseTemplateConfigList) {
                String templateType = template.Type__c;
                if (!templateIdToLineItems.containsKey(template.Id)) {
                    continue;
                }
                List<DealDeskCaseGeneratorWrappers.LineItem> lineItemsApplicableForTemplate = templateIdToLineItems.get(template.Id);
                if (lineItemsApplicableForTemplate.isEmpty()) {
                    continue;
                }
                String instructionItems = '';

                for (DealDeskCaseGeneratorWrappers.LineItem li: lineItemsApplicableForTemplate) {
                    String lineItemType = li.getType();
                    if (lineItemType == SWNHelper.DOWNSELL_TYPE_MANUAL ||
                        lineItemType == SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE && templateType == DEPROVISIONING_CASE_TEMPLATE_TYPE ||
                        lineItemType == SWNHelper.DOWNSELL_TYPE_EXCEPTION && templateType == DOWNSELL_CASE_TEMPLATE_TYPE) {
                        instructionItems += getLineItemDescription(CASE_TYPE_DOWNSELL, li) + '\n';
                    }
                }

                if (String.isNotBlank(instructionItems)) {
                    description += template.Instruction__c + ': \n' + instructionItems + '\n';
                }
            }

            return description;
        }
    }

    public class ProvisioningCaseBuilder extends CaseBuilder {
        protected override void populateSpecificCaseFields(Case cs, DealDeskCaseGeneratorWrappers.CaseSourceWrapper source) {
            cs.Subject = CASE_SUBJECT_MANUAL_PROVISION_MPUB;
            cs.Origin = CaseHelper.CASE_ORIGIN_AUTO_EMAIL;
            cs.OpportunityOwnerEmail__c = source.ownerEmail;
        }

        protected override String getDescriptionBody(List<DealDeskCaseGeneratorWrappers.LineItem> lineItems) {

            String description = CASE_DESCRIPTION_BODY_MANUAL_PROVISION_MPUB + '\n';
            Map<Id, List<DealDeskCaseGeneratorWrappers.LineItem>> templateIdToLineItems = matchTemplateIdsToLineItems(lineItems, sortedMPUBProvisioningCaseTemplateConfigList);

            Integer iterator = 1;
            for (NGBSProcessOrderCaseTemplate__mdt template : sortedMPUBProvisioningCaseTemplateConfigList) {
                if (!templateIdToLineItems.containsKey(template.Id)) {
                    continue;
                }
                List<DealDeskCaseGeneratorWrappers.LineItem> lineItemsApplicableForTemplate = templateIdToLineItems.get(template.Id);
                if (lineItemsApplicableForTemplate.isEmpty()) {
                    continue;
                }

                description += '\t' + iterator++ + '. ' + template.Instruction__c + '\n';
                String instuctionItems = '';
                for (DealDeskCaseGeneratorWrappers.LineItem li: lineItemsApplicableForTemplate) {
                    description += '\t\t￮ ' + getLineItemDescription(CASE_TYPE_PROVISIONING, li) + '\n';
                }
            }

            return description;
        }
    }

    @TestVisible
    private static Map<Id, List<DealDeskCaseGeneratorWrappers.LineItem>> matchTemplateIdsToLineItems(List<DealDeskCaseGeneratorWrappers.LineItem> lineItems, List<NGBSProcessOrderCaseTemplate__mdt> sortedCaseTemplateConfigList) {
        Map<Id, List<DealDeskCaseGeneratorWrappers.LineItem>> templateIdToLineItems = new Map<Id, List<DealDeskCaseGeneratorWrappers.LineItem>>();

        // Group templates by template types
        Map<String, List<NGBSProcessOrderCaseTemplate__mdt>> templateTypeToTemplateList = new Map<String, List<NGBSProcessOrderCaseTemplate__mdt>>();
        for (NGBSProcessOrderCaseTemplate__mdt template : sortedCaseTemplateConfigList) {
            String templateType = template.Type__c;
            if (!templateTypeToTemplateList.containsKey(templateType)) {
                templateTypeToTemplateList.put(templateType, new List<NGBSProcessOrderCaseTemplate__mdt>());
            }
            templateTypeToTemplateList.get(templateType).add(template);
        }

        Map<String, Map<String, Id>> templateTypeToTemplateApplicationMap = new Map<String, Map<String, Id>>();
        for (String templateType:  templateTypeToTemplateList.keySet()) {
            Map<String, Id> applicationToTemplateId = new Map<String, Id>();
            for (NGBSProcessOrderCaseTemplate__mdt templateConfig : templateTypeToTemplateList.get(templateType)) {
                List<String> applications = templateConfig.LicenceIdOrCategoryCode__c != null ? templateConfig.LicenceIdOrCategoryCode__c.split(';') : new List<String>();
                for (String application: applications) {
                    applicationToTemplateId.put(application.trim(), templateConfig.Id);
                }
            }
            templateTypeToTemplateApplicationMap.put(templateType, applicationToTemplateId);
        }

        // Need to iterate through template types as there should be default template for each type
        for (String templateType:  templateTypeToTemplateList.keySet()) {
            List<NGBSProcessOrderCaseTemplate__mdt> templates = templateTypeToTemplateList.get(templateType);
            Map<String, Id> applicationToTemplateId = templateTypeToTemplateApplicationMap.get(templateType);

            for (DealDeskCaseGeneratorWrappers.LineItem li: lineItems) {
                Id matchedTemplateConfigId = null;

                // Check if Line Item matches any template's LicenceId or CategoryCode
                if (applicationToTemplateId.containsKey(li.getLicenseId())) {
                    matchedTemplateConfigId = applicationToTemplateId.get(li.getLicenseId());
                } else if (applicationToTemplateId.containsKey(li.getCategoryCode())) {
                    matchedTemplateConfigId = applicationToTemplateId.get(li.getCategoryCode());
                }

                // If there is no license id or category code among templates, add the Line Item to the default template
                if (matchedTemplateConfigId == null) {
                    for (NGBSProcessOrderCaseTemplate__mdt template : templates) {
                        if (String.isEmpty(template.LicenceIdOrCategoryCode__c)) {
                            matchedTemplateConfigId = template.Id;
                            break;
                        }
                    }
                }

                // Skip the Line Item if there is no template for it
                if (matchedTemplateConfigId == null) {
                    continue;
                }

                if (!templateIdToLineItems.containsKey(matchedTemplateConfigId)) {
                    templateIdToLineItems.put(matchedTemplateConfigId, new List<DealDeskCaseGeneratorWrappers.LineItem>());
                }
                templateIdToLineItems.get(matchedTemplateConfigId).add(li);
            }
        }

        return templateIdToLineItems;
    }

    @TestVisible
    private static String getLineItemDescription(String caseType, DealDeskCaseGeneratorWrappers.LineItem li) {
        String description = '';

        if (caseType == CASE_TYPE_DOWNSELL) {
            description = String.format(
                CASE_LINE_ITEM_DESCRIPTION_SIMPLIFIED_LBO_DOWNSELL,
                new List<Object> { li.getName(), li.getPaymentPlan(), li.getUnitPrice(), li.getQuantity(), li.getDiscount(), li.getDiscountType() }
            );
        } else if (caseType == CASE_TYPE_PROVISIONING) {
            description = String.format(
                CASE_LINE_ITEM_DESCRIPTION_MANUAL_PROVISION_MPUB,
                new List<Object> { li.getName(), li.getChargeTerm(), li.getQuantity(), li.getDiscount(), li.getDiscountType() }
            );
        }

        return description;
    }

}