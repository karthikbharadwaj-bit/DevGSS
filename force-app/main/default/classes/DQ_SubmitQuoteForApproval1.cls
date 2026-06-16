public class DQ_SubmitQuoteForApproval1 {
    private static final List<String> listOfStatus = new List<String> {'Approved', 'Pending Approval'};
    private static final String REVISION_PENDING = 'Revision Pending';
    @TestVisible
    private static final String DQ_REVISE_MESSAGE = 'Deal Qualification is already {0}. Do you want to continue?';
    private static final String QUOTE_APPROVED_MESSAGE = 'Quote is already {0}.';
    private static final String PRODUCT_GROUP_OBJECT_KEY = 'regular';
    @TestVisible
    private static final String PRODUCT_KEY_SEPERATOR = '-';
    private static final String DISCOUNT_TYPE = 'Percentage';
    public static final String DQ_SEGMENT = 'SOHO';
    private static final String DQ_STATUS_NEW = 'New';
    private static final String DQ_TYPE = 'Original';
    private static final String SALES_QUOTE_LINE = 'Sales Quote Line';
    private static final String PROSERV_QUOTE_LINE = 'Proserv Quote Line';
    @TestVisible
    private static final String CC_PROSERV_QUOTE_LINE = 'CC Proserv Quote Line';
    private static final Id PROSERV_RECORD_TYPE_ID = Schema.SObjectType.Quote.RecordTypeInfosByName.get('ProServ Quote').RecordTypeId;
    private static final Id CC_PROSERV_RECORD_TYPE_ID = Schema.SObjectType.Quote.RecordTypeInfosByName.get('Contact Center Quote').RecordTypeId;
    private static final Id DQ_SALE_RECORD_TYPE_ID = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.RecordTypeInfosByName.get('Sales Quote').RecordTypeId;
    private static final Id DQ_PROSERV_RECORD_TYPE_ID = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.RecordTypeInfosByName.get('ProServ').RecordTypeId;
    private static final Id DQ_CC_RECORD_TYPE_ID = Schema.SObjectType.DQ_Deal_Qualification_Discounts__c.RecordTypeInfosByName.get('Contact Center').RecordTypeId;
    private static final String APPROVED_STATUS_QUOTE = 'Approved';
    @TestVisible
    private static final String REQUIRED_STATUS_QUOTE = 'Required';
    public static Id submitQuteForApprovalBatchMethod(Set<Id> setOfOpportunityId, Set<Id> setOfQuoteId, Boolean isConsider) {

    Id oppId = null;
    List<Quote> listOfQuote;

    if (setOfQuoteId != null && !setOfQuoteId.isEmpty()) {
      listOfQuote = getQuoteById(setOfQuoteId);

      if (listOfQuote.isEmpty()) {
        throw new DQSubmitQuoteException('No Quote Record Found');
      }

      if(!listOfQuote.isEmpty()) {
        oppId = listOfQuote.get(0).OpportunityId;
      }
    }

        Id dqId = null;

        Map<Id, DQ_Deal_Qualification__c> mapOfOppIdVsDealQualification = getMapOfDQOForOpportunity(new Set<Id> {oppId});

        List<QuoteLineItem> listOfQuoteLineItem = new List<QuoteLineItem>();

        DQ_Deal_Qualification__c dqRecord = null;

        if (setOfOpportunityId != null && !setOfOpportunityId.isEmpty()) {
             dqRecord = mapOfOppIdVsDealQualification.get(new List<Id>(setOfOpportunityId).get(0));
        }


        if(listOfQuote != null && !listOfQuote.isEmpty()) {
            Quote eachQuoteRecord = listOfQuote.get(0);

            if (eachQuoteRecord.Initial_Term_months__c == null && eachQuoteRecord.Package_Info__c != null && isConsider) {
                List<BillingWrappers.QuotePackageInfo> pInfos =
                        (List<BillingWrappers.QuotePackageInfo>)
                            JSON.deserialize(eachQuoteRecord.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                    if (pInfos.size() > 0)
                    {
                        BillingWrappers.QuotePackageInfo qtPackageInfo = pInfos[0];
                        if(qtPackageInfo.contract != null)
                        {
                            throw new AuraHandledException('Initial Term can not be blank!');
                        }
                    }
            }

            DQ_ApprovalEngine1.DQWrapperDetail dqWrapperDetailRecord = createDQWrapperDetail(eachQuoteRecord, mapOfOppIdVsDealQualification.values());

            List<DQ_ApprovalEngine1.ApproverWrapper> listOfQuoteApprovers = DQ_ApprovalEngine1.getApproversForQuoteDQ(dqWrapperDetailRecord);

            if(listOfQuoteApprovers.size() > 0) {
                DQ_Deal_Qualification__c dealQualificationRecord = mapOfOppIdVsDealQualification.get(eachQuoteRecord.OpportunityId);

                if (dealQualificationRecord == null) {
                    dealQualificationRecord = createDealQualificationForOpp(eachQuoteRecord);
                    insert dealQualificationRecord;
                }
                dqId = dealQualificationRecord.Id;
                List<DQ_Deal_Qualification_Discounts__c> listOfDealQualDiscount =
                    getListOfDealQualDiscount(new Set<Id> {dealQualificationRecord.Id});
                Map<String, DQ_Deal_Qualification_Discounts__c> mapOfProductFamilyAndIdVsDealQualDiscount =
                    new Map<String, DQ_Deal_Qualification_Discounts__c>();
                if (!listOfDealQualDiscount.isEmpty()) {
                    mapOfProductFamilyAndIdVsDealQualDiscount = getMapOfProductFamilyVsDealQualDiscount(listOfDealQualDiscount);
                }

                if (!eachQuoteRecord.QuoteLineItems.isEmpty()) {
                    Id productPackageId = DQ_DealQualificationController.getPackageIdFromQuote(eachQuoteRecord.Id);
                    for (QuoteLineItem eachQuoteLine : eachQuoteRecord.QuoteLineItems) {
                        String productCategory = 'Default';
                        if(eachQuoteLine.Product2.GOA_Group_V3__c != null && !String.isEmpty(eachQuoteLine.Product2.GOA_Group_V3__c)) {
                            Map<String, Object> goaGroupObject = (Map<String, Object>) JSON.deserializeUntyped(eachQuoteLine.Product2.GOA_Group_V3__c);
                            if (goaGroupObject.get(PRODUCT_GROUP_OBJECT_KEY) != null) {
                                productCategory = (String)goaGroupObject.get(PRODUCT_GROUP_OBJECT_KEY) ;
                            }
                        }

                        String key = productCategory + PRODUCT_KEY_SEPERATOR + eachQuoteLine.Product2Id;
                        String dealQualDiscountKey = productPackageId + PRODUCT_KEY_SEPERATOR + key;
                        DQ_Deal_Qualification_Discounts__c dealQualDiscount = mapOfProductFamilyAndIdVsDealQualDiscount.get(dealQualDiscountKey);

                        if (dealQualDiscount == null && eachQuoteLine.Discount != null && eachQuoteLine.Discount != 0) {
                            dealQualDiscount = createDealQualificationDiscountObj(dealQualificationRecord.Id, eachQuoteLine.Quantity);
                            dealQualDiscount.Product_Category__c = productCategory;
                            dealQualDiscount.Product__c = eachQuoteLine.Product2Id;
                            dealQualDiscount.Discount__c = eachQuoteLine.Discount.setScale(2);
                            dealQualDiscount.recordTypeId = DQ_SALE_RECORD_TYPE_ID;
                            dealQualDiscount.Product_Package__c = productPackageId;
                        }

                        if(dealQualDiscount != null) {
                            dealQualDiscount.Discount__c = eachQuoteLine.Discount.setScale(2);
                            dealQualDiscount.Quantity__c = eachQuoteLine.Quantity;
                            mapOfProductFamilyAndIdVsDealQualDiscount.put(dealQualDiscountKey, dealQualDiscount);
                            listOfQuoteLineItem.add(eachQuoteLine);
                        }
                    }
                }

                List<Quote> listOfCCProServQuote = getQuoteByOppIdAndQuoteRecordType(setOfOpportunityId, CC_PROSERV_RECORD_TYPE_ID);
                String ccSpecialTerms;//Added for CC-FSC
                String ccInitialTerms;//Added for CC-FSC
                if (!listOfCCProServQuote.isEmpty()) {

                    Id productPackageId = DQ_DealQualificationController.getPackageIdFromQuote(listOfCCProServQuote.get(0).Id);
                    List<QuoteLineItem> listOfCCQuoteLineItem = getQuoteLineItemByQuoteId(listOfCCProServQuote.get(0).Id);
                    ccSpecialTerms = listOfCCProServQuote.get(0).Special_Terms__c;//Added for CC-FSC
                    ccInitialTerms = listOfCCProServQuote.get(0).Initial_Term_months__c;//Added for CC-FSC
                    for (QuoteLineItem eachQuoteLine : listOfCCQuoteLineItem) {
                        String productCategory = 'Default';
                        if(eachQuoteLine.Product2.GOA_Group_V2__c != null && !String.isEmpty(eachQuoteLine.Product2.GOA_Group_V2__c)) {
                            productCategory = eachQuoteLine.Product2.GOA_Group_V2__c;
                        }

                        String key = productCategory + PRODUCT_KEY_SEPERATOR + eachQuoteLine.Product2Id;
                        String dealQualDiscountKey = productPackageId + PRODUCT_KEY_SEPERATOR + key;

                        DQ_Deal_Qualification_Discounts__c dealQualDiscount = mapOfProductFamilyAndIdVsDealQualDiscount.get(dealQualDiscountKey);

                        if (dealQualDiscount == null && eachQuoteLine.Discount != null && eachQuoteLine.Discount != 0) {
                            dealQualDiscount = createDealQualificationDiscountObj(dealQualificationRecord.Id, eachQuoteLine.Quantity);
                            dealQualDiscount.Product_Category__c = productCategory;
                            dealQualDiscount.Product__c = eachQuoteLine.Product2Id;
                            dealQualDiscount.Discount__c = eachQuoteLine.Discount.setScale(2);
                            dealQualDiscount.recordTypeId = DQ_CC_RECORD_TYPE_ID;
                        }

                        if(dealQualDiscount != null) {
                            dealQualDiscount.Discount__c = eachQuoteLine.Discount.setScale(2);
                            dealQualDiscount.Quantity__c = eachQuoteLine.Quantity;
                            mapOfProductFamilyAndIdVsDealQualDiscount.put(dealQualDiscountKey, dealQualDiscount);
                            listOfQuoteLineItem.add(eachQuoteLine);
                        }
                    }
                }

                try {
                    if (dealQualificationRecord != null) {
                        String dealQualStatus = dealQualificationRecord.Status__c;
                        dealQualificationRecord.Deal_Size__c = eachQuoteRecord.Total_First_Year_Cost__c.setScale(2);
                        dealQualificationRecord.Special_Terms__c = eachQuoteRecord.Special_Terms__c;
                        dealQualificationRecord.CC_Special_Terms__c = ccSpecialTerms;//Added for CC-FSC
                        dealQualificationRecord.CC_Initial_Term__c = ccInitialTerms;//Added for CC-FSC
                        dealQualificationRecord.Free_Shipping_Terms_Options__c = null;
                        if(isFreeShippingApprovalNeeded(eachQuoteRecord))
                        {
                            dealQualificationRecord.Free_Shipping_Terms_Options__c = eachQuoteRecord.Shipping_Option__c;
                        }
                        dealQualificationRecord.Initial_Term__c = eachQuoteRecord.Initial_Term_months__c;
                        dealQualificationRecord.Renewal_Term__c = eachQuoteRecord.Term_months__c;
                        dealQualificationRecord.Overall_Discount__c = getAverageDiscount(listOfQuoteLineItem);
                        if (listOfStatus.contains(dealQualStatus)) {
                            DQ_DealQualificationController.revisedDealQualification(dealQualificationRecord);
                        } else {
                            update dealQualificationRecord;
                        }
                    }

                    if(!mapOfProductFamilyAndIdVsDealQualDiscount.values().isEmpty()) {
                        upsert mapOfProductFamilyAndIdVsDealQualDiscount.values();
                    }
                }catch (Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }
            }
        }
        return dqId;
    }

    public static List<DQ_ApprovalEngine1.ApproverWrapper> getApproverByOppId(Id oppId, Id quoteId, Boolean isIntialTermConsider) {
        List<Quote> listOfQuote = new List<Quote>();
        List<DQ_Deal_Qualification__c> listOfDealQualificationRecord1 = getDealQualification(oppId);

        if (!listOfDealQualificationRecord1.isEmpty()) {
          quoteId = listOfDealQualificationRecord1.get(0).Quote__c;
        }

        if (quoteId == null) {
            listOfQuote = getPrimaryQuoteByOppId(new Set<Id> {oppId});
        } else {
            listOfQuote = getQuoteById(new Set<Id> {quoteId});
        }

        System.debug('listOfQuote >> ' + listOfQuote);
        if(listOfQuote != null && !listOfQuote.isEmpty()) {
            Quote eachQuoteRecord = listOfQuote.get(0);

            if (eachQuoteRecord.Approved_Status__c == APPROVED_STATUS_QUOTE) {
                 throw new AuraHandledException('Quote is already Approved');
            }

            if (isIntialTermConsider && eachQuoteRecord.Initial_Term_months__c == null && eachQuoteRecord.Package_Info__c != null) {
                List<BillingWrappers.QuotePackageInfo> pInfos =
                        (List<BillingWrappers.QuotePackageInfo>)
                            JSON.deserialize(eachQuoteRecord.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                    if (pInfos.size() > 0)
                    {
                        BillingWrappers.QuotePackageInfo qtPackageInfo = pInfos[0];
                        if(qtPackageInfo.contract != null)
                        {
                            throw new AuraHandledException('Initial Term can not be blank!');
                        }
                    }
            }

            List<DQ_Deal_Qualification__c> listOfDealQualificationRecord = getDealQualification(oppId);
            DQ_ApprovalEngine1.DQWrapperDetail dqWrapperDetailRecord =  createDQWrapperDetail(eachQuoteRecord, listOfDealQualificationRecord);
            return DQ_ApprovalEngine1.getApproversForQuoteDQ(dqWrapperDetailRecord);
        }
        return null;
    }

    public static List<DQ_ApprovalEngine1.ApproverWrapper> getApproverByOppId(Id oppId, Id quoteId) {
        List<Quote> listOfQuote = new List<Quote>();

        List<DQ_Deal_Qualification__c> listOfDealQualificationRecord1 = getDealQualification(oppId);

        if (!listOfDealQualificationRecord1.isEmpty()) {
          quoteId = listOfDealQualificationRecord1.get(0).Quote__c;
        }

        if (quoteId == null) {
            listOfQuote = getPrimaryQuoteByOppId(new Set<Id> {oppId});
        } else {
            listOfQuote = getQuoteById(new Set<Id> {quoteId});
        }

        if(listOfQuote != null && !listOfQuote.isEmpty()) {
            Quote eachQuoteRecord = listOfQuote.get(0);
            List<DQ_Deal_Qualification__c> listOfDealQualificationRecord = getDealQualification(oppId);
            DQ_ApprovalEngine1.DQWrapperDetail dqWrapperDetailRecord =  createDQWrapperDetail(eachQuoteRecord, listOfDealQualificationRecord);
            return DQ_ApprovalEngine1.getApproversForQuoteDQ(dqWrapperDetailRecord);
        }
        return null;
    }

    private static List<DQ_Deal_Qualification__c> getDealQualification(String OppId){
        return  [SELECT opportunity__r.Name,Free_Shipping_Terms_Options__c,Overall_Discount_Contact_Center__c,Overall_Discount_One_Time__c,Overall_Discount_Recurring__c,IsDQCreatedFromCPQOpp__c, Charge_Term__c, Initial_Term__c, Renewal_Term__c, Type__c, Opportunity__c, Status__c,
                 Minimum_Package_s__c, Number_of_DLs__c, Max_Discount__c, Deal_Size__c, Quote__c,
                 Overall_Discount__c, Special_Terms__c,CC_Special_Terms__c, CC_Initial_Term__c,Is_ELA__c, Minimum_Baseline__c, Maximum_Potential__c,
                 ELA_Initial_Terms__c, Start_Date__c, Roll_Out_Plan__c, Additional_Info__c, Global_Office_Location__c,
                 Cost_of_One_Time_items__c, New_Annual_Recurring_Charges__c, Brand__c, Region__c, Sub_Region__c,
                 Segment__c, Deal_Type__c, True_Up_Terms__c, Id, Name, OwnerId, Justification_Description__c, Opportunity_Owner_s_Email__c,
                 Quote__r.Approved_Status__c
                 FROM DQ_Deal_Qualification__c
                 WHERE Opportunity__c = :OppId];
    }

    public static List<Quote> getPrimaryQuoteByOppId(Set<Id> setOfOppId) {

        return [SELECT Id, Name, Pricebook2Id,FreeShippingTerms__c,Shipping_Option__c, Opportunity.EES_CC_Removal_Approval__c,Opportunity.EES_Removal_Approval__c,OpportunityId, ContactId, QuoteNumber, IsSyncing,
                Package_Info__c, Term_months__c, TotalPrice, Initial_Term__c,Opportunity.Brand_Name__c,Payment_Plan__c,
                Opportunity.owner.Division, Opportunity.RecordType.Name, Total_First_Year_Cost__c,Initial_Term_months__c,
                Opportunity.CurrencyIsoCode,Opportunity.Segment_Name__c, Total_One_Time__c, Monthly_Recurring_Revenue__c, Opportunity.Owner.Region__c,
                Opportunity.Owner.Sub_Region__c,Opportunity.Owner.SegmentPicklist__c, Special_Terms__c,JustificationandDescription__c, Opportunity.Owner.Email, Approved_Status__c,
                (SELECT Id, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, Product_Family__c, Product2Id, Product2.GOA_Group__c,
                 UnitPrice, Discount, Description, Discount_type__c, is_Active__c, Entitlement__c, TotalPrice, SubTotal , Product2.GOA_Group_V3__c
                 FROM QuoteLineItems WHERE (Discount != 0 AND Discount != null AND Promotion__c = null))
                FROM Quote
                WHERE OpportunityId = :setOfOppId AND Is_Selected_From_Wizard__c = true];

    }

    public static List<Quote> getEligibleQuoteByOppId(Set<Id> setOfOppId) {
        return [SELECT Id, Name, Pricebook2Id, FreeShippingTerms__c,Shipping_Option__c,Opportunity.EES_CC_Removal_Approval__c,Opportunity.EES_Removal_Approval__c,OpportunityId, ContactId, QuoteNumber, IsSyncing,
                Package_Info__c, Term_months__c, TotalPrice, Initial_Term__c,Opportunity.Brand_Name__c,Payment_Plan__c,
                Opportunity.owner.Division, Opportunity.RecordType.Name, Total_First_Year_Cost__c,Initial_Term_months__c,
                Opportunity.CurrencyIsoCode,Opportunity.Segment_Name__c, Total_One_Time__c, Monthly_Recurring_Revenue__c,
                Opportunity.Owner.Region__c, Opportunity.Owner.Sub_Region__c,Opportunity.Owner.SegmentPicklist__c, Special_Terms__c,JustificationandDescription__c,
                Opportunity.Owner.Email, Approved_Status__c,
                (SELECT Id, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, Product_Family__c, Product2Id, Product2.GOA_Group__c,
                 UnitPrice, Discount, Description, Discount_type__c, is_Active__c, Entitlement__c, TotalPrice, SubTotal , Product2.GOA_Group_V3__c
                 FROM QuoteLineItems WHERE (Discount != 0 AND Discount != null AND Promotion__c = null))
                FROM Quote
                WHERE OpportunityId = :setOfOppId AND Approved_Status__c != 'Approved'];
    }

    public static List<Quote> getQuoteByOppIdAndQuoteRecordType(Set<Id> setOfOppId, Id recordTypeId) {
        return [SELECT Id, Name, Pricebook2Id, FreeShippingTerms__c,Shipping_Option__c,Opportunity.EES_Removal_Approval__c,Opportunity.EES_CC_Removal_Approval__c,OpportunityId, ContactId, QuoteNumber, IsSyncing, Payment_Plan__c,
                Package_Info__c, Term_months__c, TotalPrice, Initial_Term__c,Opportunity.Brand_Name__c,
                Opportunity.owner.Division, Opportunity.RecordType.Name, Total_First_Year_Cost__c,
                Opportunity.CurrencyIsoCode,Opportunity.Segment_Name__c, Monthly_Recurring_Revenue__c,Initial_Term_months__c,
                Opportunity.Owner.Region__c, Opportunity.Owner.Sub_Region__c, Opportunity.Owner.SegmentPicklist__c,Special_Terms__c,JustificationandDescription__c,
                Opportunity.Owner.Email, Approved_Status__c
                FROM Quote
                WHERE OpportunityId = :setOfOppId AND RecordTypeId = :recordTypeId ORDER BY LastModifiedDate DESC];
    }

    public static List<QuoteLineItem> getQuoteLineItemByQuoteId(Id quoteId) {
        return [ SELECT Id, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, Product_Family__c, Product2Id, Product2.GOA_Group__c,
                UnitPrice, Discount, Description, Discount_type__c, is_Active__c, Entitlement__c, TotalPrice, SubTotal , Product2.GOA_Group_V3__c,
                Product2.GOA_Group_V2__c, Discount_number__c
                FROM QuoteLineItem WHERE QuoteId =: quoteId  AND (Discount != 0 AND Discount != null AND Promotion__c = null)];
    }

    private static List<Quote> getQuoteById(Set<Id> setOfQuoteId) {
        return [SELECT Id, Name, Pricebook2Id,FreeShippingTerms__c,Shipping_Option__c, Opportunity.EES_Removal_Approval__c,Opportunity.EES_CC_Removal_Approval__c,OpportunityId, ContactId, QuoteNumber, IsSyncing,
                Package_Info__c, Term_months__c, TotalPrice, Initial_Term__c,Opportunity.Brand_Name__c,Payment_Plan__c,
                Opportunity.owner.Division, Opportunity.RecordType.Name, Total_First_Year_Cost__c,Initial_Term_months__c,
                Opportunity.CurrencyIsoCode,Opportunity.Segment_Name__c, Total_One_Time__c, Monthly_Recurring_Revenue__c,
                Opportunity.Owner.Region__c, Opportunity.Owner.Sub_Region__c,Opportunity.Owner.SegmentPicklist__c, Special_Terms__c,JustificationandDescription__c,
                Opportunity.Owner.Email, Approved_Status__c,
                (SELECT Id, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, Product_Family__c, Product2Id, Product2.GOA_Group__c,
                 UnitPrice, Discount, Description, Discount_type__c, is_Active__c, Entitlement__c, TotalPrice, SubTotal , Product2.GOA_Group_V3__c
                 FROM QuoteLineItems  WHERE (Discount != 0 AND Discount != null AND Promotion__c = null))
                FROM Quote  WHERE Id = :setOfQuoteId];
    }

    private static DQ_Deal_Qualification_Discounts__c createDealQualificationDiscountObj(Id dqId, Decimal quanity) {
        DQ_Deal_Qualification_Discounts__c dealQualDiscountRecord = new DQ_Deal_Qualification_Discounts__c();
        dealQualDiscountRecord.Deal_Qualification__c = dqId;
        dealQualDiscountRecord.Discount_Type__c = DISCOUNT_TYPE;
        dealQualDiscountRecord.Quantity__c = quanity;
        return dealQualDiscountRecord;
    }

    private static Map<Id, DQ_Deal_Qualification__c> getMapOfDQOForOpportunity(Set<Id> setOfOpportunityId) {
        Map<Id, DQ_Deal_Qualification__c> mapOfDQIdVSDealQualification = new Map<Id, DQ_Deal_Qualification__c>();
        List<DQ_Deal_Qualification__c> listOfDealQualification =
            [SELECT Free_Shipping_Terms_Options__c,Overall_Discount_Contact_Center__c,Overall_Discount_One_Time__c,Overall_Discount_Recurring__c,IsDQCreatedFromCPQOpp__c,opportunity__r.Name, Charge_Term__c, Initial_Term__c, Renewal_Term__c, Type__c, Opportunity__c, Status__c,
             Minimum_Package_s__c, Number_of_DLs__c, Max_Discount__c, Deal_Size__c,
             Overall_Discount__c, Special_Terms__c,CC_Special_Terms__c,CC_Initial_Term__c, Is_ELA__c, Minimum_Baseline__c, Maximum_Potential__c, Quote__c,
             ELA_Initial_Terms__c, Start_Date__c, Roll_Out_Plan__c, Additional_Info__c, Global_Office_Location__c,
             Cost_of_One_Time_items__c, New_Annual_Recurring_Charges__c, Brand__c, Region__c, Sub_Region__c,Quote__r.Approved_Status__c,
             Segment__c, Deal_Type__c, True_Up_Terms__c, Id, Name, OwnerId, Justification_Description__c, Opportunity_Owner_s_Email__c
             FROM DQ_Deal_Qualification__c
             WHERE Opportunity__c =:setOfOpportunityId];
        for(DQ_Deal_Qualification__c eachDealQualificationRecord : listOfDealQualification) {
            mapOfDQIdVSDealQualification.put(eachDealQualificationRecord.Opportunity__c, eachDealQualificationRecord);
        }
        return mapOfDQIdVSDealQualification;
    }

    private static List<DQ_Deal_Qualification_Discounts__c> getListOfDealQualDiscount(Set<Id> setOfDqIds) {
        return [SELECT Id, Name, Product_Category__c, Discount__c, Deal_Qualification__c, Product_Sub_Categories__c,
                Discount_Type__c, Quantity__c, Product__c, Product_Family__c, Product_Package__c
                FROM DQ_Deal_Qualification_Discounts__c
                WHERE Deal_Qualification__c IN :setOfDqIds];
    }

    @TestVisible
    private static Map<String, DQ_Deal_Qualification_Discounts__c> getMapOfProductFamilyVsDealQualDiscount(List<DQ_Deal_Qualification_Discounts__c> listOfDealQualDiscount) {
        Map<String, DQ_Deal_Qualification_Discounts__c> mapOfProductFamilyAndIdVsDealQualDiscount =
            new Map<String, DQ_Deal_Qualification_Discounts__c>();
        for (DQ_Deal_Qualification_Discounts__c eachDqQualDiscount : listOfDealQualDiscount) {
            String key = eachDqQualDiscount.Product_Package__c + PRODUCT_KEY_SEPERATOR + eachDqQualDiscount.Product_Category__c + PRODUCT_KEY_SEPERATOR + eachDqQualDiscount.Product__c;
            DQ_Deal_Qualification_Discounts__c dealQualDiscountRecord =
                mapOfProductFamilyAndIdVsDealQualDiscount.get(key);
            if (dealQualDiscountRecord == null) {
                mapOfProductFamilyAndIdVsDealQualDiscount.put(key, eachDqQualDiscount);
                dealQualDiscountRecord = eachDqQualDiscount;
            }

            if (dealQualDiscountRecord.Discount__c < eachDqQualDiscount.Discount__c) {
                mapOfProductFamilyAndIdVsDealQualDiscount.put(key, eachDqQualDiscount);
            }
        }
        return mapOfProductFamilyAndIdVsDealQualDiscount;
    }

    private static DQ_Deal_Qualification__c createDealQualificationForOpp(Quote quoteRecord) {
        DQ_Deal_Qualification__c dealQualificationRecord = new DQ_Deal_Qualification__c();
        dealQualificationRecord.Charge_Term__c = null;
        dealQualificationRecord.Minimum_Package_s__c = null;
        dealQualificationRecord.Number_of_DLs__c = null;
        dealQualificationRecord.Opportunity__c = quoteRecord.OpportunityId;
        dealQualificationRecord.Renewal_Term__c = quoteRecord.Term_months__c;
        dealQualificationRecord.Initial_Term__c = quoteRecord.Initial_Term_months__c;
        dealQualificationRecord.Status__c = DQ_STATUS_NEW;
        dealQualificationRecord.Type__c = DQ_TYPE;
        dealQualificationRecord.Special_Terms__c = quoteRecord.Special_Terms__c;
        //Added for CC-FSC
        List<Quote> listOfCCProServQuote = getQuoteByOppIdAndQuoteRecordType(new Set<Id>{quoteRecord.OpportunityId}, CC_PROSERV_RECORD_TYPE_ID);
        if(!listOfCCProServQuote.isEmpty())
        {
            dealQualificationRecord.CC_Special_Terms__c = listOfCCProServQuote.get(0).Special_Terms__c;
            dealQualificationRecord.CC_Initial_Term__c = listOfCCProServQuote.get(0).Initial_Term_months__c;
        }
        dealQualificationRecord.Free_Shipping_Terms_Options__c = null;
        if(isFreeShippingApprovalNeeded(quoteRecord))
        {
            dealQualificationRecord.Free_Shipping_Terms_Options__c = quoteRecord.Shipping_Option__c;
        }
        dealQualificationRecord.Deal_Size__c = quoteRecord.Total_First_Year_Cost__c.setScale(2);
        dealQualificationRecord.Cost_of_One_Time_items__c = quoteRecord.Total_One_Time__c;
        dealQualificationRecord.New_Annual_Recurring_Charges__c = quoteRecord.Monthly_Recurring_Revenue__c;
        dealQualificationRecord.Minimum_Baseline__c = null;
        dealQualificationRecord.Quote__c = quoteRecord.Id;
        dealQualificationRecord.Maximum_Potential__c = null;
        dealQualificationRecord.True_Up_Terms__c = null;
        dealQualificationRecord.Charge_Term__c = null;
        dealQualificationRecord.ELA_Initial_Terms__c = null;
        dealQualificationRecord.Justification_Description__c = quoteRecord.JustificationandDescription__c;
        dealQualificationRecord.Opportunity_Owner_s_Email__c = quoteRecord.Opportunity.Owner.Email;


        return dealQualificationRecord;
    }

    public static String getRegionValueByOppCurrencyISO(String currencyIso) {
        Map<String, String> mapOfCurrencyISOVsCountry = new Map<String, String>
        {
            'USD'=> 'US', 'EUR' => 'EU', 'AUS'=> 'Australia'
        };

        if (mapOfCurrencyISOVsCountry.containsKey(currencyIso)) {
            return mapOfCurrencyISOVsCountry.get(currencyIso);
        }
        return mapOfCurrencyISOVsCountry.get('USD');
    }

    public static String getDealType(String oppRecordTypeName) {
        String dealType = 'Direct';
        if(oppRecordTypeName.contains('Sales')) {
            dealType = 'Direct';
        }
        if (oppRecordTypeName.contains('VAR')) {
            dealType = 'Indirect';
        }
        return dealType;
    }

    private static DQ_ApprovalEngine1.DQWrapperDetail createDQWrapperDetail(
        Quote quoteRecord, List<DQ_Deal_Qualification__c> listOfDealQualification) {
            Map<String, List<QuoteLineItem>> mapOfQuoteLineTypeVsListOfQuoteLineItem = new Map<String, List<QuoteLineItem>>();
            List<QuoteLineItem> listOfQuoteLineItem = new List<QuoteLineItem>();
            if (quoteRecord.QuoteLineItems != null && !quoteRecord.QuoteLineItems.isEmpty()) {
                listOfQuoteLineItem.addAll(quoteRecord.QuoteLineItems);
                mapOfQuoteLineTypeVsListOfQuoteLineItem.put(SALES_QUOTE_LINE, new List<QuoteLineItem> (quoteRecord.QuoteLineItems));
            }

            List<Quote> listOfCCProServQuote = getQuoteByOppIdAndQuoteRecordType(new Set<Id> {quoteRecord.OpportunityId}, CC_PROSERV_RECORD_TYPE_ID);
            String ccSpecialTerms;//Added for CC-FSC
            String ccInitialTerms;//Added for CC-FSC
            if (!listOfCCProServQuote.isEmpty()) {
                ccSpecialTerms = listOfCCProServQuote.get(0).Special_Terms__c;//Added for CC-FSC
                ccInitialTerms = listOfCCProServQuote.get(0).Initial_Term_months__c;//Added for CC-FSC
                List<QuoteLineItem> listOfCCQuoteLineItem = getQuoteLineItemByQuoteId(listOfCCProServQuote.get(0).Id);
                listOfQuoteLineItem.addAll(listOfCCQuoteLineItem);
                mapOfQuoteLineTypeVsListOfQuoteLineItem.put(CC_PROSERV_QUOTE_LINE, listOfCCQuoteLineItem);
            }

            DQ_ApprovalEngine1.DQWrapperDetail wrapperRecord = new DQ_ApprovalEngine1.DQWrapperDetail();
            wrapperRecord.opportunityId = quoteRecord.OpportunityId;
            wrapperRecord.dqInitialTerm = quoteRecord.Initial_Term_months__c != null ? Decimal.valueOf(quoteRecord.Initial_Term_months__c) : 0.0;
            wrapperRecord.dqRenewalTerm = quoteRecord.Term_months__c != null ? Decimal.valueOf(quoteRecord.Term_months__c) : 0.0;
            wrapperRecord.dqRegion = quoteRecord.Opportunity.Owner.Region__c == null ? 'US' : quoteRecord.Opportunity.Owner.Region__c ;
            if(quoteRecord.Opportunity.Owner.Region__c == null) {
                 wrapperRecord = DQ_ApprovalEngine1.assignDefaultRegionSubregion(wrapperRecord);
            }
            String dqSegment = quoteRecord.Opportunity.Brand_Name__c == 'Avaya Cloud Office' ? quoteRecord.Opportunity.Segment_Name__c : quoteRecord.Opportunity.Owner.SegmentPicklist__c;
            wrapperRecord.dqSegment = dqSegment != null ? dqSegment : 'Default';
            wrapperRecord.dqDealType = getDealType(quoteRecord.Opportunity.RecordType.Name);
            wrapperRecord.dqBrand = quoteRecord.Opportunity.Brand_Name__c;
            wrapperRecord.dqSubRegion = quoteRecord.Opportunity.Owner.Sub_Region__c;
            wrapperRecord.overAllDiscount = getAverageDiscount(listOfQuoteLineItem);
            wrapperRecord.dealSize = quoteRecord.Total_First_Year_Cost__c;
            wrapperRecord.mapOfCurrentProductCategoryIdVsMapOfData = getMapOfProductCategoryIdVsMapOfData(mapOfQuoteLineTypeVsListOfQuoteLineItem);
            wrapperRecord.mapOfHistoryProductCategoryIdVsMapOfData = new Map<String, Map<String, Map<String, Object>>>();
            wrapperRecord.dqMaxRenewalHistory = 0.0;
            wrapperRecord.dqMaxInitialHistory = 0.0;
            wrapperRecord.dealQualRecord = createDealQualificationForOpp(quoteRecord);
            wrapperRecord.dealQualRecordHistory = null;
            if (listOfDealQualification != null && !listOfDealQualification.isEmpty()) {
                wrapperRecord.dealQualRecord = updateDealQualRecordWithQuote(listOfDealQualification.get(0), quoteRecord);
                //Added for CC-FSC
                if(ccSpecialTerms != wrapperRecord.dealQualRecord.CC_Special_Terms__c)
                {
                    wrapperRecord.dealQualRecord.CC_Special_Terms__c = ccSpecialTerms;
                }
                if(ccInitialTerms != wrapperRecord.dealQualRecord.CC_Initial_Term__c)
                {
                    wrapperRecord.dealQualRecord.CC_Initial_Term__c = ccInitialTerms;
                }
                wrapperRecord = updateApprovalInformationFromDQ(wrapperRecord, listOfDealQualification.get(0));
            }
            return wrapperRecord;
        }

        private static DQ_Deal_Qualification__c updateDealQualRecordWithQuote(DQ_Deal_Qualification__c dqRecord, Quote quoteRecord) {
            if (quoteRecord.Special_Terms__c != dqRecord.Special_Terms__c) {
                dqRecord.Special_Terms__c = quoteRecord.Special_Terms__c;
            }
            if (quoteRecord.Initial_Term_months__c != null && quoteRecord.Initial_Term_months__c != dqRecord.Initial_Term__c) {
                dqRecord.Initial_Term__c = quoteRecord.Initial_Term_months__c;
            }
            if (quoteRecord.JustificationandDescription__c != dqRecord.Justification_Description__c) {
                dqRecord.Justification_Description__c = quoteRecord.JustificationandDescription__c;
            }
            if (quoteRecord.Opportunity.Owner.Email != dqRecord.Opportunity_Owner_s_Email__c) {
                dqRecord.Opportunity_Owner_s_Email__c = quoteRecord.Opportunity.Owner.Email;
            }
            dqRecord.Free_Shipping_Terms_Options__c = null;
            if(isFreeShippingApprovalNeeded(quoteRecord))
            {
                dqRecord.Free_Shipping_Terms_Options__c = quoteRecord.Shipping_Option__c;
            }
            return dqRecord;
        }

    public static DQ_ApprovalEngine1.DQWrapperDetail updateApprovalInformationFromDQ(
        DQ_ApprovalEngine1.DQWrapperDetail wrapperRecord, DQ_Deal_Qualification__c dqRecord){

            List<DQ_Deal_Qualification_History__c> listOfDQHistory = DQ_ApprovalEngine1.getApprovedDealQualificationHistoryByIds(new Set<Id> {dqRecord.Id}, DQ_ApprovalEngine1.DQ_APPROVED_STATUS);
            Decimal dqMaxRenewalHistory = 0.0;
            Decimal dqMaxInitialHistory = 0.0;

            Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData =
                new Map<String, Map<String, Map<String, Object>>>();
                DQ_Deal_Qualification_History__c dealQualHistoryRecord;
            for (DQ_Deal_Qualification_History__c eachDQHistoryRecord : listOfDQHistory) {
                dealQualHistoryRecord  = eachDQHistoryRecord;
                Decimal historyRenewalTerm =  eachDQHistoryRecord.Renewal_Term__c == null ? 0 : Decimal.valueOf(eachDQHistoryRecord.Renewal_Term__c);
                Decimal historyInitialTerm =  eachDQHistoryRecord.Initial_Term__c == null ? 0 : Decimal.valueOf(eachDQHistoryRecord.Initial_Term__c);
                if (historyRenewalTerm > dqMaxRenewalHistory) {
                    dqMaxRenewalHistory = historyRenewalTerm;
                }

                if (historyInitialTerm > dqMaxInitialHistory) {
                    dqMaxInitialHistory = historyInitialTerm;
                }

                // create map from history record which already approved as per logic for skip level if already approved
                for (DQ_Deal_Qualification_Discount_History__c eachProductHistory : eachDQHistoryRecord.DQ_Deal_Qualification_Discounts_History__r) {

                    Map<String, Map<String, Object>> mapOfHistoryCategoryProductVsMapOfData =
                        mapOfHistoryProductCategoryIdVsMapOfData.get(eachProductHistory.Product_Category__c);

                    if (mapOfHistoryCategoryProductVsMapOfData == null) {
                        mapOfHistoryCategoryProductVsMapOfData = new Map<String, Map<String, Object>>();
                    }

                    String key = eachProductHistory.Product_Category__c + PRODUCT_KEY_SEPERATOR + eachProductHistory.Product__c;

                    Map<String, Object> mapOfDataAndValue = mapOfHistoryCategoryProductVsMapOfData.get(key);
                    if (mapOfDataAndValue == null) {
                        mapOfDataAndValue = new Map<String, Object>();
                    }

                    Decimal discount = eachProductHistory.Discount__c;
                    Decimal quantity = eachProductHistory.Quantity__c;

                    if (mapOfDataAndValue.keySet().isEmpty()) {
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discount);
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantity);
                    }

                    Decimal discountValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD);
                    Decimal quantityValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD);

                    if (discount > discountValueFromMap) {
                        discountValueFromMap = discount;
                    }

                    if (quantity > quantityValueFromMap) {
                        quantityValueFromMap = quantity;
                    }

                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discountValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantityValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_PRODUCT_PACKAGE_KEYWORD, eachProductHistory.Product_Package__c);

                    mapOfHistoryCategoryProductVsMapOfData.put(key, mapOfDataAndValue);
                    mapOfHistoryProductCategoryIdVsMapOfData.put(eachProductHistory.Product_Category__c, mapOfHistoryCategoryProductVsMapOfData);
                }
            }
            if (dealQualHistoryRecord != null) {
                wrapperRecord.historyDQElaValue = dealQualHistoryRecord.Is_ELA__c;
            }
            wrapperRecord.dqMaxRenewalHistory = dqMaxRenewalHistory;
            wrapperRecord.dqMaxInitialHistory = dqMaxInitialHistory;
            wrapperRecord.mapOfHistoryProductCategoryIdVsMapOfData = new Map<String, Map<String, Map<String, Object>>>();

            if(DQ_ApprovalEngine1.needToConsiderApprovalHistoryWithDQComparision(dqRecord, dealQualHistoryRecord)) {
                Boolean isNeedToConsiderApproverHistory = DQ_ApprovalEngine1.needToConsiderApproveHistory(
                wrapperRecord.mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);
                Boolean isNeedToConsiderQuantityApproverHistory = DQ_ApprovalEngine1.isNeedToConsiderApproveDueToQuantity(
                    wrapperRecord.mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData,
                    isNeedToConsiderApproverHistory );

                if (isNeedToConsiderApproverHistory && isNeedToConsiderQuantityApproverHistory) {
                    wrapperRecord.dealQualRecordHistory = dealQualHistoryRecord;
                    wrapperRecord.mapOfHistoryProductCategoryIdVsMapOfData = mapOfHistoryProductCategoryIdVsMapOfData;
                } else {
                    wrapperRecord.mapOfHistoryProductCategoryIdVsMapOfData = DQ_ApprovalEngine1.includeNonUpdatebleDiscountRecords(
                        wrapperRecord.mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);
                    wrapperRecord.dealQualRecordHistory = dealQualHistoryRecord;
                }
            }


            return wrapperRecord;
        }


    @TestVisible
    private static Map<String, Map<String, Map<String, Object>>> getMapOfProductCategoryIdVsMapOfData(
        Map<String, List<QuoteLineItem>> mapOfQuoteLineTypeVsListOfQuoteLineItem) {

            Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData =
                new Map<String, Map<String, Map<String, Object>>>();

            if (mapOfQuoteLineTypeVsListOfQuoteLineItem.get(SALES_QUOTE_LINE) != null && !mapOfQuoteLineTypeVsListOfQuoteLineItem.get(SALES_QUOTE_LINE).isEmpty()) {
                Id productPackageId = DQ_DealQualificationController.getPackageIdFromQuote(mapOfQuoteLineTypeVsListOfQuoteLineItem.get(SALES_QUOTE_LINE).get(0).QuoteId);
                for(QuoteLineItem eachQuoteLine : mapOfQuoteLineTypeVsListOfQuoteLineItem.get(SALES_QUOTE_LINE)){

                    String productCategory = 'Default';

                    if(eachQuoteLine.Product2.GOA_Group_V3__c  != null && !String.isEmpty(eachQuoteLine.Product2.GOA_Group_V3__c)) {
                        Map<String, Object> goaGroupObject = (Map<String, Object>) JSON.deserializeUntyped(eachQuoteLine.Product2.GOA_Group_V3__c);
                        if (goaGroupObject.get(PRODUCT_GROUP_OBJECT_KEY) != null && eachQuoteLine.Discount != null) {
                            productCategory = (String)goaGroupObject.get(PRODUCT_GROUP_OBJECT_KEY);
                        }
                    }

                    Map<String, Map<String, Object>> mapOfCurrentCategoryProductVsMapOfData =
                        mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory);

                    if (mapOfCurrentCategoryProductVsMapOfData == null) {
                        mapOfCurrentCategoryProductVsMapOfData = new Map<String, Map<String, Object>>();
                    }

                    String key = productCategory + PRODUCT_KEY_SEPERATOR + eachQuoteLine.Product2Id;

                    Map<String, Object> mapOfDataAndValue = mapOfCurrentCategoryProductVsMapOfData.get(key);
                    if (mapOfDataAndValue == null) {
                        mapOfDataAndValue = new Map<String, Object>();
                    }

                    Decimal discount = eachQuoteLine.Discount.setScale(2);
                    Decimal quantity = eachQuoteLine.Quantity;

                    if (mapOfDataAndValue.keySet().isEmpty()) {
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discount);
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantity);
                    }

                    Decimal discountValueFromMap = (Decimal)mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD);
                    Decimal quantityValueFromMap = (Decimal)mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD);

                    if (discount > discountValueFromMap) {
                        discountValueFromMap = discount;
                    }

                    if (quantity > quantityValueFromMap) {
                        quantityValueFromMap = quantity;
                    }

                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discountValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantityValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_PRODUCT_PACKAGE_KEYWORD, productPackageId);

                    mapOfCurrentCategoryProductVsMapOfData.put(key, mapOfDataAndValue);

                    mapOfCurrentProductCategoryIdVsMapOfData.put(productCategory, mapOfCurrentCategoryProductVsMapOfData);
                }
            }

            List<QuoteLineItem> listOfQuoteLineItems = new List<QuoteLineItem>();

            if (mapOfQuoteLineTypeVsListOfQuoteLineItem.get(PROSERV_QUOTE_LINE) != null && !mapOfQuoteLineTypeVsListOfQuoteLineItem.get(PROSERV_QUOTE_LINE).isEmpty()) {
                listOfQuoteLineItems.addAll(mapOfQuoteLineTypeVsListOfQuoteLineItem.get(PROSERV_QUOTE_LINE));
            }

            if (mapOfQuoteLineTypeVsListOfQuoteLineItem.get(CC_PROSERV_QUOTE_LINE) != null && !mapOfQuoteLineTypeVsListOfQuoteLineItem.get(CC_PROSERV_QUOTE_LINE).isEmpty()) {
                listOfQuoteLineItems.addAll(mapOfQuoteLineTypeVsListOfQuoteLineItem.get(CC_PROSERV_QUOTE_LINE));
            }

            if (!listOfQuoteLineItems.isEmpty()) {
                Id productPackageId = DQ_DealQualificationController.getPackageIdFromQuote(listOfQuoteLineItems.get(0).QuoteId);

                for(QuoteLineItem eachQuoteLine : listOfQuoteLineItems){

                    String productCategory = 'Default';

                    if(eachQuoteLine.Product2.GOA_Group_V2__c != null &&
                       !String.isEmpty(eachQuoteLine.Product2.GOA_Group_V2__c)) {
                        productCategory = eachQuoteLine.Product2.GOA_Group_V2__c;
                    }

                    Map<String, Map<String, Object>> mapOfCurrentCategoryProductVsMapOfData =
                        mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory);

                    if (mapOfCurrentCategoryProductVsMapOfData == null) {
                        mapOfCurrentCategoryProductVsMapOfData = new Map<String, Map<String, Object>>();
                    }

                    String key = productCategory + PRODUCT_KEY_SEPERATOR + eachQuoteLine.Product2Id;

                    Map<String, Object> mapOfDataAndValue = mapOfCurrentCategoryProductVsMapOfData.get(key);
                    if (mapOfDataAndValue == null) {
                        mapOfDataAndValue = new Map<String, Object>();
                    }

                    Decimal discount = eachQuoteLine.Discount.setScale(2);
                    Decimal quantity = eachQuoteLine.Quantity;

                    if (mapOfDataAndValue.keySet().isEmpty()) {
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discount);
                        mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantity);
                    }

                    Decimal discountValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD);
                    Decimal quantityValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD);


                    if (discount > discountValueFromMap) {
                        discountValueFromMap = discount;
                    }

                    if (quantity > quantityValueFromMap) {
                        quantityValueFromMap = quantity;
                    }

                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_DISCOUNT_KEYWORD, discountValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_QUANTITY_KEYWORD, quantityValueFromMap);
                    mapOfDataAndValue.put(DQ_ApprovalEngine1.DQ_PRODUCT_PACKAGE_KEYWORD, productPackageId);
                    mapOfCurrentCategoryProductVsMapOfData.put(key, mapOfDataAndValue);

                    mapOfCurrentProductCategoryIdVsMapOfData.put(productCategory, mapOfCurrentCategoryProductVsMapOfData);
                }
            }

            return mapOfCurrentProductCategoryIdVsMapOfData;
        }


    private static Double getAverageDiscount (List<QuoteLineItem> quoteLines) {
        double averageDiscount = 0.0;
        double subTotal = 0.0;
        double total = 0.0;
        for (QuoteLineItem eachQuoteLine : quoteLines) {
            if (eachQuoteLine.TotalPrice != null) {
                total = total + eachQuoteLine.TotalPrice;
                subTotal = subTotal + eachQuoteLine.SubTotal;
            }
        }
        return subtotal == 0 ? 0 : Decimal.valueOf((((subTotal - total) / subtotal) * 100)).setscale(2);
    }

  public static boolean isFreeShippingApprovalNeeded(Quote qt) {
        if (qt.FreeShippingTerms__c != QuoteHelper.FREESHIPPING) {
            return false;
        }
    //add contract condition
    if (qt.Package_Info__c != null) {
            List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                if (pInfos.size() > 0)
                {
                    BillingWrappers.QuotePackageInfo qtPackageInfo = pInfos[0];
                    if(qtPackageInfo.contract == null)
                    {
                        return false;
                    }
                }
        }
        List<QuoteLineItem> qlis = [Select Id,PackageInfo__c,Zero_Quantity__c,Quantity from QUoteLineItem where QuoteId = :qt.Id];
        if(qlis != null && qlis.size() > 0)
        {
            return isQuoteHasShippingDevices(qlis)
                && (qt.Shipping_Option__c == QuoteHelper.SHIPPING_OPTION_OVERNIGHT ||
                qt.Shipping_Option__c == QuoteHelper.SHIPPING_OPTION_2_DAY);
        }
        return false;
    }
    private static boolean isQuoteHasShippingDevices(List<QuoteLineItem> qlis) {
        for (QuoteLineItem qli : qlis) {
            if (qli.PackageInfo__c != null) {
                BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                    JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
                if (qliPackageInfo.CategoryCode != null
                    && Product2Helper.SHIPPING_PHONES.contains(qliPackageInfo.CategoryCode)
                    && !qli.Zero_Quantity__c
                    && qli.Quantity > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    public static String getQuoteApprovalStatus(String quoteId) {
        String status = APPROVED_STATUS_QUOTE;
        List<Quote> listOfQuoteRecord = [SELECT Id, OpportunityId, Initial_Term_months__c FROM Quote WHERE Id=:quoteId];
        if (!listOfQuoteRecord.isEmpty()) {
                List<DQ_ApprovalEngine1.ApproverWrapper> listOfApprover = getApproverByOppId(listOfQuoteRecord.get(0).OpportunityId, quoteId);
                if(listOfApprover != null && !listOfApprover.isEmpty()) {
                    status = REQUIRED_STATUS_QUOTE;
                }
        }
        return status;
    }

    public static void  autoApprovedOpportunityQuoteWithNoApproval(Id oppId) {
        if (!DQGoa.isDQGoaEnabled()) {
            List<Quote> listOfQuoteForApprove = new List<Quote>();
            List<Quote> listOfQuote = getEligibleQuoteByOppId(new Set<Id> {oppId});

            if (!listOfQuote.isEmpty()) {
                for (Quote eachQuote : listOfQuote) {
                    if (getQuoteApprovalStatus(eachQuote.Id) == APPROVED_STATUS_QUOTE) {
                        listOfQuoteForApprove.add(new Quote(Id = eachQuote.Id, Approved_Status__c = APPROVED_STATUS_QUOTE));
                    }
                }
            }

            if (!listOfQuoteForApprove.isEmpty()) {
                update listOfQuoteForApprove;
            }
        }
    }

    public class DQStatusWrapper {
        @AuraEnabled
        public Boolean isDQValidForSubmit;
        @AuraEnabled
        public String promptMessage;
        @AuraEnabled
        public Boolean isApproverAvailable;

        public DQStatusWrapper() {}

        public DQStatusWrapper(Boolean isDQValidForSubmit, String promptMessage, Boolean isApproverAvailable) {
            this.promptMessage = promptMessage;
            this.isDQValidForSubmit = isDQValidForSubmit;
            this.isApproverAvailable = isApproverAvailable;
        }
    }

    public virtual class DQSubmitQuoteException extends Exception {}
}