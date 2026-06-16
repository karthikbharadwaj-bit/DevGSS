public inherited sharing class OpportunitySelector extends SObjectSelector {

    public OpportunitySelector() {
        super();
    }

    public OpportunitySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public OpportunitySelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Opportunity.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Opportunity.Id,
            Opportunity.AccountId,
            Opportunity.Name,
            Opportunity.Type,
            Opportunity.CurrencyIsoCode,
            Opportunity.Forecasted_Users__c,
            Opportunity.Forecast_Contact_Center_Users__c,
            Opportunity.ForcastedDimeloUsers__c,
            Opportunity.Forecast_Connect_First_Users__c,
            Opportunity.Forecasted_Events_Users__c,
            Opportunity.StageName,
            Opportunity.Is_Billing_Opportunity__c,
            Opportunity.Tier_Name__c,
            Opportunity.isFedRamp__c,
            Opportunity.OwnerId,
            Opportunity.CloseDate
        };
    }

    public List<String> getDefaultOpptyFieldList() {
        return new List<String> {
            'Id',
            'AccountId',
            'Name',
            'Type',
            'CurrencyIsoCode',
            'Forecasted_Users__c',
            'Forecast_Contact_Center_Users__c',
            'StageName',
            'Is_Billing_Opportunity__c',
            'MasterOpportunity__c',
            'MasterOpportunity__r.AccountId',
            'MasterOpportunity__r.id',
            'MasterOpportunity__r.OwnerId',
            'MasterOpportunity__r.Primary_Opportunity_Contact__c',
            'Tier_Name__c',
            'isFedRamp__c',
            'SyncInfo__c',
            'OwnerId',
            'isTermination__c',
            'Primary_Opportunity_Contact__c',
            'Account.Master_Account__c',
            'BusinessIdentity__c',
            'Owner.SegmentPicklist__c',
            'Owner.Region__c',
            'Owner.Sub_Region__c',
            'Brand_Name__c',
            'CPQ_Opportunity__c',
            'Account.Provision_Date__c',
            'Account.inContact_account_ID__c',
            'Account.inContact_Cluster__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'Account.InContact_Service__c',
            'Account.No_of_InContact_Seats__c',
            'Account.Service_Status__c',
            'Account.GSP__c',
            'Sub_Brand__c',
            'isICBProvisioningComplete__c',
            'isSyncedToICB__c',
            'CloseDate',
            'isMultiproductTechnicalOpportunity__c',
            'isDiscountsSynced__c',
            'isContractsSynced__c',
            'isUpsellStepCompleted__c',
            'isDownsellStepCompleted__c',
            'isUpgradeStepCompleted__c',
            'isInvoiceStepCompleted__c',
            'isChargeTermSynced__c',
            'PrimaryQuote__r.Package_Info__c',
            'Order_Management_Owner__c'
        };
    }

    public List<String> getFieldsForQuoteWizard() {
        return new List<String> {
            'Id',
            'Name',
            'Brand_Name__c',
            'BusinessIdentity__c',
            'PartnerProgram__c',
            'ConfirmAndClose__c',
            'CPQ_Opportunity__c',
            'CurrencyIsoCode',
            'CustomerConfirmation__c',
            'Effective_No_of_Employees_Range__c',
            'Is_Billing_Opportunity__c',
            'isTermination__c',
            'OwnerId',
            'RecordType.Name',
            'RecordTypeName__c',
            'Special_ToS_Approval__c',
            'StageName',
            'Sub_Brand__c',
            'Tier_Name__c',
            'Type',
            'Parent_Order__c',
            'Account.Billing_ID__c',
            'Account.RC_Account_Status__c',
            'Account.Billing_System__c',
            'Account.BillingCountry',
            'Account.ELA_Account_Type__c',
            'Account.GSP__c',
            'Account.Id',
            'Account.Number_of_DL_s__c',
            'Account.Partner_Account__r.Partner_Type__c',
            'Account.Payment_Plan__c',
            'Account.RC_Tier__c',
            'Account.RC_Tier_ID__c',
            'Account.RC_User_ID__c',
            'Account.Offer_Type__c',
            'Account.Sales_Agreement_End_Date__c',
            'Account.Sales_Agreement_Start_Date__c',
            'Account.AccMigrationFlag__c',
            'Account.Partner_Contact__c',
            'Account.Name',
            'Owner.Email',
            'Owner.SegmentPicklist__c'
        };
    }

    public List<Schema.SObjectField> getApprovalFieldList() {
        return new List<Schema.SObjectField> {
            Opportunity.Partner_Owner__c,
            Opportunity.AccountId,
            Opportunity.Effective_No_of_Employees_Range__c,
            Opportunity.Forecasted_Users__c,
            Opportunity.Partner_ID__c,
            Opportunity.Partner_Lead_Source__c,
            Opportunity.Ultimate_Parent_Account_Partner_ID__c,
            Opportunity.OwnerId,
            Opportunity.Inside_Sales_Rep__c,
            Opportunity.ChangedFromRecordType__c,
            Opportunity.CurrencyIsoCode,
            Opportunity.Brand_Name__c,
            Opportunity.Tier_Name__c
        };
    }

    public static Set<String> getContactUpdateFields() {
        return new Set<String>{
            'Estimated_12M_Office_Pipeline__c',
            'Estimated_12M_Contact_Center_Pipeline__c',
            'Estimated_12M_Global_Office_Pipeline__c',
            'Estimated_12M_Engage_Digital_Pipeline__c',
            'Estimated_12M_Engage_Voice_Pipeline__c',
            'Estimated_12M_RingCentral_Video_Pipeline__c',
            'EstimatedProfessionalServices12Month__c',
            'Primary_Opportunity_Contact__c'
        };
    }

    public static Set<String> getInvoiceRequestApprovalFields() {
        return new Set<String>{
            'Id',
            'Name',
            'Is_Billing_Opportunity__c',
            'Estimated_12M_Office_Pipeline__c',
            'Estimated_12M_Contact_Center_Pipeline__c',
            'Estimated_12M_Engage_Voice_Pipeline__c',
            'Estimated_12M_Engage_Digital_Pipeline__c',
            'Calculated_12M_Total_Pipeline__c',
            'Estimated_Hardware__c',
            'Estimated_One_Time_Pipeline__c',
            'EstimatedProfessionalServices12Month__c',
            'AccountId',
            'Account.Name',
            'Account.RC_User_ID__c',
            'Account.RC_Account_Status__c',
            'Account.Payment_Method__c',
            'Account.Account_Payment_Method__c',
            'Account.MRR__c',
            'PrimaryQuote__r.Payment_Period__c'
        };
    }

    public List<String> getLeadConversionField() {
        return new List<String> {
            'Owner.name',
            'X12_Month_Booking__c',
            'RecordType.Name',
            'StageName',
            'LastModifiedDate',
            'CreatedDate'
        };
    }

    public List<String> getSignUpFieldList() {
        return new List<String> {
            'Id',
            'BMID__c',
            'OID__c',
            'Partner_ID__c',
            'Brand_Name__c',
            'Enable_Cost_Center_Management__c',
            'Tier_Name__c',
            'Type',
            'isFedRamp__c',
            'NumberToBeCCNumber__c',
            'NumberToBeRCMainNumber__c',
            'isTermination__c',
            'isMultiproductTechnicalOpportunity__c',
            'SyncInfo__c',
            'RecordTypeId',
            'BusinessIdentity__c',
            'Sub_Brand__c',
            'Account.Name',
            'Account.Timezone__c',
            'Account.Payment_Method__c',
            'Account.Tax_Exempt__c',
            'Account.SignupType__c',
            'Account.Monthly_Credit_Limit__c',
            'Account.Sign_up_Purchase_Limit__c',
            'Account.Payment_Terms__c',
            'Account.Invoice_Terms__c',
            'Account.VATNumber__c',
            'Account.PID__c',
            'Account.BillingPostalCode',
            'Account.BillingState',
            'Account.BillingCountry',
            'Account.BillingCity',
            'Account.BillingStreet',
            'Account.RC_Brand__c',
            'Account.RC_User_ID__c',
            'Account.Billing_ID__c',
            'Account.Account_Payment_Method__c',
            'Account.Master_Account__c',
            'Account.Partner_ID__c',
            'Account.Partner_Account__c',
            'Account.Partner_Type__c',
            'Account.Master_Account__r.Service_Type__c',
            'Account.Master_Account__r.RC_User_ID__c',
            'Account.VATNumber__c',
            'Account.ELA_Account_Type__c',
            'Account.Package_Status__c',
            'Account.Internal_Enterprise_Account_ID__c',
            'Account.inContact_Account_Id__c',
            'Account.EnterpriseCustomerID__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'Account.RC_Account_Status__c',
            'MasterOpportunity__c',
            'MasterOpportunity__r.Tier_Name__c'
        };
    }

    public List<String> getCloseFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'Is_Billing_Opportunity__c',
            'RecordType.Name',
            'StageName',
            'ProvisioningDetails__c',
            'NumberToBeRCMainNumber__c',
            'NumberToBeCCNumber__c',
            'ConfirmAndClose__c',
            'GoldfingerRetention__c',
            'Type',
            'Parent_Order__c',
            'Brand_Name__c',
            'Tier_Name__c',
            'AccountId',
            'Account.BillingStreet',
            'Account.BillingCity',
            'Account.BillingState',
            'Account.BillingPostalCode',
            'Account.Billing_ID__c',
            'Account.BillingCountry',
            'Account.Active_Sales_Agreement__c',
            'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Account.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Account.Active_Sales_Agreement__r.Term_months__c',
            'Account.RC_Account_Number__c',
            'Account.RC_User_ID__c',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Account.Account_Payment_Method__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'Account.Payment_Method__c',
            'Account.Master_Account__c',
            'Account.Master_Account__r.InContact_Account_Id__c',
            'Account.Master_Account__r.Name',
            'Account.EnabledLBO__c',
            'Account.Offer_Type__c',
            'Account.inContact_Account_Id__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'Account.Monthly_Credit_Limit__c',
            'Account.Sign_up_purchase_limit__c',
            'Account.Name',
            'Account.VATNumber__c',
            'Account.GSP__c',
            'Owner.Email',
            'isTermination__c',
            'Primary_Opportunity_Contact__c',
            'isOrderStepCompleted__c',
            'BusinessIdentity__c',
            'isMultiproductTechnicalOpportunity__c',
            'isSyncedToICB__c',
            'MasterOpportunity__c',
            'Partner_Account__r.Partner_Type__c',
            'Partner_Account__r.Partner_ID__c',
            'MasterOpportunity__r',
            'MasterOpportunity__r.OwnerId',
            'Estimated_12M_Total_Pipeline__c',
            'Segment_Name__c',
            'Why_We_Won__c',
            'Final_Competitor_we_won_against__c',
            'Additional_details_on_why_we_won__c',
            'Mutual_Plan__c',
            'STC_Relationship_Building_Extras__c',
            'RC_Executive_Alignment__c',
            'KDR__c',
            'Identified_Risks__c',
            'Implementation_Comments_Notes__c',
            'STC_Decision_Making__c',
            'STC_Ideal_Situation__c',
            'ProServ_Comments_Notes__c',
            'STC_Current_Situation__c',
            'STC_Problems__c',
            'Competitor_Phone__c',
            'Competitor_Message__c',
            'Video_Competition__c',
            'CC_Competitor_s__c',
            'Competitor_Digital_Channels__c',
            'Key_Deal_Integration_Other__c',
            'Message__c',
            'Phone__c',
            'Contact_Center__c',
            'Meetings__c',
            'Digital_Channels__c',
            'Incumbent_Conversation_Intelligence__c',
            'Key_Deal_Integration__c',
            'Brand_Name__c',
            'Partner_ID__c',
            'Account.GPA_Account__c',
            'PartnerProgram__c',
            'CW_Primary_Win_Reason__c'
        };
    }

    public List<String> getBillingOpptyFieldList() {
        return new List<String>{
        	'Account.Billing_ID__c',
        	'Account.Active_Sales_Agreement__c',
            'Account.BillingStreet',
            'Account.BillingCity',
            'Account.BillingState',
            'Account.BillingPostalCode',
            'Account.BillingCountry',
            'Is_Billing_Opportunity__c',
            'StageName',
            'X18_Digit_Id__c',
            'Brand_Name__c',
            'Segment_Name__c',
            'AccountId',
            'Account.ZI_Company_Country__c',
            'Account.ZI_Company_State__c'
        };
    }

    public List<String> getSyncWithNGBSFields() {
        return new List<String> {
            'Account.Billing_ID__c',
            'Account.RC_Account_Status__c',
            'Account.EnabledLBO__c',
            'Account.Name',
            'Account.BillingStreet',
            'Account.BillingCity',
            'Account.BillingState',
            'Account.BillingPostalCode',
            'Account.BillingCountry',
            'Account.Phone',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Account.RC_User_ID__c',
            'Account.RC_Brand__c',
            'Account.Active_Sales_Agreement__c',
            'Account.Master_Account__c',
            'Account.Master_Account__r.inContact_account_ID__c',
            'Account.Partner_Account__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'AccountId',
            'Owner.Email',
            'StageName',
            'Brand_Name__c',
            'isContractsSynced__c',
            'isInvoiceStepCompleted__c',
            'isOrderStepCompleted__c',
            'isDiscountsSynced__c',
            'isRepriceSynced__c',
            'isResyncContractAllowed__c',
            'IsManualProvisionCaseCreated__c',
            'IsDownsellCaseCreated__c',
            'isUpsellStepCompleted__c',
            'isDownsellStepCompleted__c',
            'isUpgradeStepCompleted__c',
            'isLicenseLimitsSynced__c',
            'IsAreaCodeCaseCreated__c',
            'isContractCancelled__c',
            'isMultiproductTechnicalOpportunity__c',
            'isFSCSynced__c',
            'isChargeTermSynced__c',
            'IsSpendingLimitRetrieveStepCompleted__c',
            'OrderDate__c',
            'CW_Primary_Win_Reason__c',
            'CW_Win_Reason_Awards__c',
            'CW_Win_Reason_Features__c',
            'CW_Win_Reason_Savings__c',
            'CW_Win_Reason_Integrations__c',
            'UCaaS_Competitor_s__c',
            'UCaaS_Incumbent_s__c',
            'CC_Competitor_s__c',
            'CC_Incumbent_s__c',
            'Type',
            'isTermination__c',
            'NGBS_Sync_Executor_Info__c',
            'isTerminationStepCompleted__c',
            'isFedRamp__c',
            'SyncInfo__c',
            'isSyncedToICB__c',
            'isICBProvisioningComplete__c',
            'Partner_Account__r.Partner_Type__c',
            'MasterOpportunity__c',
            'MasterOpportunity__r',
            'MasterOpportunity__r.OwnerId',
            'isMultiproductTechnicalOpportunity__c',
            'NumberOfOfficeDLs__c',
            'BusinessIdentity__c',
            'Order_Management_Owner__c'
        };
    }

    public List<String> getSettingServiceFields() {
        return new List<String> {
            'Id',
            'CustomerConfirmation__c',
            'Tier_Name__c',
            'Brand_Name__c',
            'RecordTypeId',
            'Parent_Order__c',
            'Parent_Order__r.MaxPhaseNumber__c',
            'Account.Id',
            'Account.Billing_ID__c',
            'Account.EnabledLBO__c',
            'Account.GSP__c',
            'Account.Partner_Account__r.Partner_Type__c'
        };
    }

    public List<String> getTotalsFields() {
        return new List<String> {
            'Estimated_One_Time_Pipeline__c',
            'Total_MRR__c'
        };
    }

    public List<String> getFreeShippingDiscountFields() {
        return new List<String> {
            'Id',
            'Account.Owner.Id',
            'Owner.Manager.Id'
        };
    }

    public List<String> getDocusignFields() {
        return new List<String> {
            'DocuSignCLMEnvelopeId__c',
            'DocuSignCLMEAEnvelopeId__c',
            'Name'
        };
    }

    public List<String> getBusinessIdentityFields() {
        return new List<String> {
            'BusinessIdentity__c'
        };
    }

    public List<String> getTotalMRRField() {
        return new List<String> {
            'Total_MRR__c'
        };
    }

    public List<String> getOpportunityAuraComponentFields() {
        return new List<String> {
            'StageName',
            'Brand_Name__c',
            'Type',
            'BusinessIdentity__c',
            'Account.GSP__c'
        };
    }

    public List<String> getOpportunityFieldsForClose() {
        return new List<String> {
            'Id',
            'AccountId',
            'StageName',
            'Account.RC_Account_Number__c',
            'X12_Month_Booking__c',
            'Estimated_12M_Total_Pipeline__c',
            'Brand_Name__c',
            'RecordTypeId',
            'Is_Billing_Opportunity__c',
            'Tier_Name__c',
            'PrimaryQuote__r.Package_Info__c'
        };
    }

    public List<String> getOpportunityFieldsForCopy() {
        return new List<String> {
            'MasterOpportunity__r.Id',
            'AreaCode__c',
            'FaxAreaCode__c',
            'StageName',
            'Primary_Opportunity_Contact__c',
            'IsMultiProductTechnicalOpportunity__c'
        };
    }

    public List<String> getOpptyEmailNotificationFields() {
        return new List<String> {
            'Id',
            'Name',
            'stageName',
            'Owner.Full_Name__c',
            'ForecastCategoryName',
            'Estimated_12M_Total_Pipeline__c',
            'CreatedDate',
            'Opportunity_Owner_s_Segment__c',
            'Tier_Name__c',
            'Total_Contract_Value__c',
            'Forecasted_Users__c',
            'Forecasted_RingCentral_Video_Users__c',
            'Forecast_Contact_Center_Users__c'
        };
    }

    public List<String> getApprovalCreationFields() {
        return new List<String> {
            'Id',
            'AccountId',
            'Brand_Name__c',
            'Account.Name',
            'Account.BillingStreet',
            'Account.BillingState',
            'Account.BillingCountry',
            'Account.BillingCity',
            'Account.BillingPostalCode',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Account.RC_User_ID__c',
            'Account.RC_Account_Status__c',
            'Account.Payment_Method__c',
            'Account.Account_Payment_Method__c',
            'Account.SegmentName__c',
            'Account.Payment_Plan__c',
            'Account.Invoice_terms__c'
        };
    }

    public List<String> getRenewalFields() {
        return new List<String> {
            'Account.Id',
            'Account.Name',
            'Account.Billing_ID__c',
            'Account.RC_Brand__c',
            'Account.Owner.IsActive',
            'Account.Owner.SegmentPicklist__c',
            'Account.Active_Sales_Agreement__c',
            'Account.Active_Sales_Agreement__r.End_Date__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Tier_Name__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Brand_Name__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Edition__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Is_Billing_Opportunity__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_beat__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Categories_Who_did_we_replace__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Primary_Win_Reason__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Secondary_Win_Reason__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_beat__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Who_did_we_replace__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Awards__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Features__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Integrations__c',
            'Account.Active_Sales_Agreement__r.Opportunity.CW_Win_Reason_Savings__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Total_Contract_Value__c',
            'Account.Active_Sales_Agreement__r.Opportunity.Primary_Opportunity_Contact__c'
        };
    }

    public List<String> getFieldsForPsCases() {
        return new List<String> {
            'Id',
            'Owner.SegmentPicklist__c',
            'CurrencyIsoCode'
        };
    }

    public List<String> selectOpptyMandatoryFieldsForIncumbentCapture() {
        return new List<String> {
            'Id',
            'StageName',
            'Why_We_Lost__c',
            'Final_Competitor_we_lost_against__c',
            'Additional_details_on_why_we_lost__c',
            'Why_We_Won__c',
            'Final_Competitor_we_won_against__c',
            'Additional_details_on_why_we_won__c',
            'Competitor_Phone__c',
            'Competitor_Message__c',
            'Video_Competition__c',
            'CC_Competitor_s__c',
            'Competitor_Digital_Channels__c',
            'Identified_Risks__c',
            'Phone__c',
            'Meetings__c',
            'Message__c',
            'Contact_Center__c',
            'Digital_Channels__c',
            'Key_Deal_Integration__c',
            'Key_Deal_Integration_Other__c',
            'Mutual_Plan__c',
            'STC_Relationship_Building_Extras__c',
            'RC_Executive_Alignment__c',
            'KDR__c',
            'STC_Decision_Making__c',
            'STC_Ideal_Situation__c',
            'STC_Current_Situation__c',
            'STC_Problems__c',
            'Implementation_Comments_Notes__c',
            'ProServ_Comments_Notes__c',
            'Segment_Name__c',
            'Estimated_12M_Total_Pipeline__c',
            'Brand_Name__c',
            'Partner_ID__c',
            'Type',
            'PartnerProgram__c'
        };
    }

    public List<String> selectOpptyFieldsForDowngradeValidation() {
        return new List<String> {
            'Id',
            'Why_We_Lost__c',
            'Final_Competitor_we_lost_against__c',
            'Additional_details_on_why_we_lost__c',
            'Segment_Name__c',
            'Estimated_12M_Total_Pipeline__c',
            'Brand_Name__c',
            'Partner_ID__c',
            'Type',
            'Tier_Name__c',
            'Parent_Order__c',
            'PartnerProgram__c'
        };
    }

    public List<String> selectOpptyFieldsForInContactCaseSharing() {
        return new List<String> {
            'Id',
            'isMultiproductTechnicalOpportunity__c',
            'OwnerId',
            'MasterOpportunity__r.Id',
            'MasterOpportunity__r.OwnerId'
        };
    }

    public List<Schema.SObjectField> getOppIdOnly() {
        return new List<Schema.SObjectField> {
            Opportunity.Id
        };
    }

    public QueryFactory selectOpportunityForQuoteWizard(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForQuoteWizard')
            .selectFields(getFieldsForQuoteWizard())
            .selectFields(getTotalsFields())
            .withSelectorFieldsIncluded()
            .setCondition('Id = :bind0')
            .withoutSelectorOrderByIncluded()
            .setLimit(1)
            .setQueryBindings(new List<Object>{oppId});

    }

    public QueryFactory selectBillingOpportunity(String condition) {
        return newQueryFactory()
            .setFactoryName('selectBillingOpportunity')
            .selectFields(getBillingOpptyFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition(condition);
    }

    public QueryFactory selectOpportunitiesForApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForApproval')
            .withSelectorFieldsIncluded()
            .selectFields(getApprovalFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesForApprovalCheck(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForApprovalCheck')
            .selectFields(getCloseFieldList())
            .subselect(new QuoteSelector()
                .selectPrimaryQuotes(bindings)
                .selectField(Quote.IsMultiProductTechnicalQuote__c)
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesOnCloseValidation(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesOnCloseValidation')
            .selectFields(getCloseFieldList())
            .subselect(
                new QuoteSelector().selectQuotesByOppIds(bindings)
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunityForSyncWithNGBS(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForSyncWithNGBS')
            .withSelectorFieldsIncluded()
            .selectFields(getSyncWithNGBSFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object> {oppId});
    }

    public QueryFactory selectOpportunitiesForSyncWithNGBSByQuoteIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForSyncWithNGBSByQuoteIds')
            .withSelectorFieldsIncluded()
            .selectFields(getSyncWithNGBSFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN (SELECT OpportunityId FROM Quote WHERE Id IN :bind0)')
            .setQueryBindings(new List<Object> {quoteIds});
    }

    public QueryFactory selectOpportunityForSyncStatus(Set<String> oppIdSet) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForSyncStatus')
            .withSelectorFieldsIncluded()
            .selectFields(getSyncWithNGBSFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setLimit(10000)
            .setQueryBindings(new List<Object>{oppIdSet});
    }

    public QueryFactory selectOpportunityForSyncWithNGBSByName(Object name) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForSyncWithNGBSByName')
            .withSelectorFieldsIncluded()
            .selectFields(getSyncWithNGBSFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{name});
    }

    public QueryFactory selectOpportunities() {
        return newQueryFactory()
            .setFactoryName('SelectOpportunities')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectOpportunityByUUID(Object uuid) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityByUUID')
            .selectFields(getDefaultFieldList())
            .setCondition('Uuid__c = :bind0')
            .withSelectFieldsSorted()
            .setQueryBindings(new List<Object>{uuid});
    }

    public QueryFactory selectOpportunityForSignUp(Object oppIds) {
        return newQueryFactory()
            .setFactoryName('SelectOpportunityForSignUp')
            .withSelectorFieldsIncluded()
            .selectFields(getSignUpFieldList())
            .selectFields(getBusinessIdentityFields())
            .subselect(
                new OpportunityContactRoleSelector().selectOpportunityContactRoles()
            )
            .setCondition('Id IN :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpportunitiesForSignUp(List<Object> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForSignUp')
            .withSelectorFieldsIncluded()
            .selectFields(getSignUpFieldList())
            .selectFields(getBusinessIdentityFields())
            .subselect(
                new OpportunityContactRoleSelector().selectOpportunityContactRoles()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(oppIds);
    }

    public QueryFactory selectOpportunityForClose(Object oppIds) {
        return newQueryFactory()
            .setFactoryName('SelectOpportunityForClose')
            .withSelectorFieldsIncluded()
            .selectFields(getCloseFieldList())
            .selectFields(getBusinessIdentityFields())
            .setCondition('Id IN :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectTechOptyForAutoSyncByMasterOppId(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectTechOptyForAutoSyncByMasterOppId')
            .selectFields(getDefaultOpptyFieldList())
            .selectFields(getSyncWithNGBSFields())
            .setCondition('MasterOpportunity__c = :bind0 OR Id = :bind0')
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(new List<Object> { oppId });
    }

    public QueryFactory selectOpportunitiesByIds(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByIds')
            .selectFields(getDefaultOpptyFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpportunitiesForDFR(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForDFR')
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectLinkedOpportunities(Id parentQuoteId) {
        return newQueryFactory()
            .setFactoryName('selectLinkedOpportunities')
            .selectFields(getDefaultFieldList())
            .subselect(
                new AttachmentSelector()
                    .selectAttachmentsDefault()
                    .addOrdering(Attachment.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            )
            .subselect(new QuoteSelector().selectQuotes())
            .subselect(new ApprovalSelector().selectApprovals())
            .setCondition('Id IN (SELECT OpportunityId FROM Quote WHERE (ParentQuote__c = :bind0 OR Id = :bind0))')
            .setQueryBindings(new List<Object>{ parentQuoteId })
            .addOrdering(Opportunity.LastModifiedDate, QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectOpportunityForSettingService(Object oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForSettingService')
            .selectFields(getSettingServiceFields())
            .selectFields(getBillingOpptyFieldList())
            .selectFields(getDocusignFields())
            .selectFields(getBusinessIdentityFields())
            .selectFields(getTotalsFields())
            .subselect(
                new QuoteSelector().selectQuotes().selectField('Enabled_LBO__c').setCondition('isPrimary__c = true')
            )
            .subselect(
                new OpportunityContactRoleSelector()
                    .selectPrimaryOpportunityContactRolesforCLM(new List<Object>{oppId})
                    .selectField('Contact.FirstName')
                    .selectField('Contact.LastName')
                    .selectField('Contact.Email')
                    .selectField('Role')
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{oppId});
    }

    public QueryFactory selectOpportunitiesByAccountId(List<Object> bindings, Integer queryLimit, Integer offset) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByAccountId')
            .selectFields(getDefaultFieldList())
            .selectfields(getLeadConversionField())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND Type != \'Renewal\' AND CreatedDate > :bind1 ' +
                          'AND (RecordType.Name = \'Sales Opportunity\' ' +
                                'OR RecordType.Name = \'New Sales Opportunity\') ' +
                          'AND (StageName = \'1. Qualify\' OR StageName = \'2. Problem\' ' +
                               'OR StageName = \'3. Solution\' OR StageName = \'3. ActivePipe\' ' +
                               'OR StageName = \'4. Proof\' OR StageName = \'5. Agreement\' ' +
                               'OR StageName = \'5. Proposal\' OR StageName = \'6. Order\') ')
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
            .addOrdering('StageName', QueryFactory.SortOrder.DESCENDING)
            .setLimit(queryLimit)
            .setOffset(offset)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOriginalOppByAccountId(Object accId) {
        return newQueryFactory()
            .setFactoryName('selectOriginalOppByAccountId')
            .selectFields(getOppIdOnly())
            .setCondition('Parent_Order__c = null AND AccountId = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{accId});
    }

    public QueryFactory selectOpportunityByAccountIdForCCMigration(Object accId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityByAccountIdForCCMigration')
            .selectField(Opportunity.Id)
            .subSelect(
                new ApprovalSelector().selectApprovals())
            .subSelect(
                new OrderSelector().selectOrders()
            )
            .setCondition('IsMultiProductTechnicalOpportunity__c = true AND AccountId = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{accId});
    }

    public QueryFactory selectEngageOpportunitiesByAccountId(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectEngageOpportunitiesByAccountId')
                .selectFields(getDefaultFieldList())
                .setCondition('AccountId IN :bind0 AND Tier_Name__c IN :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesForSignUpSync(Set<Id> accountIdSet) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForSignUpSync')
            .withoutSelectorFieldsIncluded()
            .selectField(Opportunity.AccountId)
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0 AND RecordTypeId = :bind1')
            .setQueryBindings(new List<Object>{ accountIdSet, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY });
    }

    public QueryFactory selectOpportunityWithLeadConvertFields(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityWithLeadConvertFields')
            .selectFields(OpportunityHelper.DESCRIBE.fields.getMap().values())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{oppId});
    }


    public QueryFactory selectOpportunitiesFreeShippingDiscount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesFreeShippingDiscount')
            .withSelectorFieldsIncluded()
            .selectFields(getFreeShippingDiscountFields())
            .setCondition('Id in :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesByPrimaryOpportunityContact(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectOpportunitiesByPrimaryOpportunityContact')
                .withSelectorFieldsIncluded()
                .selectField(Opportunity.Primary_Opportunity_Contact__c)
                .setCondition('Primary_Opportunity_Contact__c IN :bind0' )
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesForAcctOwnerUpdates(Set<Id> accountIdSet){
        String stageNameDowngraded = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        String stageNameClosedWon = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForAcctOwnerUpdates')
            .selectFields(getDefaultFieldList())
            .setCondition('AccountId IN :bind0 AND StageName != :bind1 AND StageName != :bind2')
            .setQueryBindings(new List<Object>{accountIdSet, stageNameDowngraded, stageNameClosedWon});
    }

    public QueryFactory selectOpportunitiesForContactUpdate(Set<Id> oppIds, Set<Id> contIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForContactUpdate')
            .selectFields(getContactUpdateFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0 OR Primary_Opportunity_Contact__c IN :bind1')
            .setQueryBindings(new List<Object>{ oppIds, contIds });
    }

    public QueryFactory selectOpportunitiesByPrimaryOpportunityContactAndOpenOpportunity(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectOpportunitiesByPrimaryOpportunityContactAndOpenOpportunity')
                .selectField(Opportunity.Name)
                .selectField(Opportunity.Primary_Opportunity_Contact__c)
                .selectField(Opportunity.StageName)
                .setCondition('Primary_Opportunity_Contact__c IN :bind0 AND isClosed = false AND isWon = false')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesByIdAndPrimaryOppContact(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByIdAndPrimaryOppContact')
            .selectField('Primary_Opportunity_Contact__c')
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0 AND Primary_Opportunity_Contact__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunityByName(Object name) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityByName')
            .withSelectorFieldsIncluded()
            .selectFields(getSyncWithNGBSFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{name});
    }

    public QueryFactory selectClosedWonOppsByPrimaryConAndOppConRoles(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectClosedWonOppsByPrimaryConAndOppConRoles')
                .selectFields(getContactUpdateFields())
                .setCondition('isClosed = true AND isWon = true AND Primary_Opportunity_Contact__c IN :bind0 AND Id NOT IN :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceOpportunitiesByMasterId(Id masterOppId) {
        return newQueryFactory()
            .setFactoryName('selectServiceOpportunitiesByMasterId')
            .selectFields(AquivaHelper.getAllFieldsForObject('Opportunity'))
            .selectFields(new Set<String> {
                'MasterOpportunity__r.Id'
            })
            .subselect(
                new QuoteSelector()
                    .selectQuotes()
                    .selectFields(new List<String> { 'Id', 'Name', 'MasterQuote__c', 'IsMultiProductTechnicalQuote__c', 'ServiceName__c', 'IsPrimary__c'})
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('MasterOpportunity__c = :bind0')
            .setQueryBindings(new List<Object> {masterOppId});
    }

    public QueryFactory selectServiceOpportunitiesByMasterIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceOpportunitiesByMasterIds')
            .selectFields(AquivaHelper.getAllFieldsForObject('Opportunity'))
            .subselect(
                new QuoteSelector()
                    .selectQuotes()
                    .selectFields(new List<String> { 'Id', 'Name', 'MasterQuote__c', 'IsMultiProductTechnicalQuote__c', 'ServiceName__c', 'IsPrimary__c'})
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('MasterOpportunity__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesForAuraComponentByIds(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForAuraComponentByIds')
            .selectFields(getOpportunityAuraComponentFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpportunitiesByIdsWithAllFields(List<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByIdsWithAllFields')
            .selectFields(AquivaHelper.getAllFieldsForObject('Opportunity'))
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpportunitiesByIdsWithAllFields(Id oppId) {
        return selectOpportunitiesByIdsWithAllFields(new List<Id> { oppId });
    }

    public QueryFactory selectOpportunitiesForClose(Id masterOppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForClose')
            .selectFields(getOpportunityFieldsForClose())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0 OR MasterOpportunity__c = :bind0')
            .addOrdering('IsMultiProductTechnicalOpportunity__c', QueryFactory.SortOrder.ASCENDING)
            .setQueryBindings(new List<Object>{masterOppId});
    }

    public QueryFactory selectTechnicalOpptysByMasterIdForCopying(List<Id> masterIds) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalOpptysByMasterIdForCopying')
            .selectFields(getOpportunityFieldsForCopy())
            .setCondition('IsMultiProductTechnicalOpportunity__c = true AND MasterOpportunity__c IN :bind0')
            .setQueryBindings(new List<Object> { masterIds });
    }

    public QueryFactory selectOpptysForCopying(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpptysForCopying')
            .selectFields(getOpportunityFieldsForCopy())
            .setCondition('(IsMultiProductTechnicalOpportunity__c = true AND MasterOpportunity__c IN :bind0) '
                + 'OR (Id IN :bind0 AND IsMultiProductTechnicalOpportunity__c = false)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpptys() {
        return newQueryFactory()
            .setFactoryName('selectOpptys')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<String>{'Id'});
    }

    public QueryFactory getOpptyFieldsForEmailNotification(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('getOpptyFieldsForEmailNotification')
            .selectFields(getOpptyEmailNotificationFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
    public QueryFactory selectOpportunityByIdAndStageName(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectOpportunityByIdAndStageName')
                .selectFields(new Set<String>{'Id','DFR_Actual_Close_DateTime__c'})
                .subselect(
                        new QuoteSelector().selectQuotes().setCondition('isPrimary__c = true')
                )
                .setCondition('AccountId = :bind0 AND StageName = :bind1')
                .withoutSelectorOrderByIncluded()
                .addOrdering(Opportunity.DFR_Actual_Close_DateTime__c, QueryFactory.SortOrder.DESCENDING)
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesForInvoiceRequestApprovalByAccId(String accId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForInvoiceRequestApprovalByAccId')
            .selectFields(getInvoiceRequestApprovalFields())
            .setCondition('AccountId = :bind0')
            .setQueryBindings(new List<Object> {accId});
    }

    public QueryFactory selectOpportunitiesForInvoiceRequestApprovalByOppId(String oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForInvoiceRequestApprovalByOppId')
            .selectFields(getInvoiceRequestApprovalFields())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object> {oppId});
    }

    public QueryFactory selectMPTechOppsByMasterIds(Set<Id> masterIds) {
        return newQueryFactory()
            .setFactoryName('selectMPTechOppsByMasterIds')
            .selectFields(new Set<String> {
                'MasterOpportunity__c', 'AccountId', 'Tier_Name__c'
            })
            .setCondition('IsMultiProductTechnicalOpportunity__c = true AND MasterOpportunity__c IN :bind0')
            .setQueryBindings(new List<Object> { masterIds });
    }

    public QueryFactory selectOpportunitiesByStagesAndAccountId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByStagesAndAccountId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0 AND StageName IN :bind1')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunitiesWithTotalMRRByIds(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesWithTotalMRRByIds')
            .selectFields(getTotalMRRField())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpportunityForApprovalCreation(String oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForApprovalCreation')
            .selectFields(getApprovalCreationFields())
            .subselect(new QuoteSelector()
                .selectQuotes()
                .selectFields(new Set<String>{'Id', 'Package_Info__c'}))
            .subselect(new ApprovalSelector()
                .selectApprovals()
                .setCondition('IsMultiProductTechnicalApproval__c = false AND (' +
                    'RecordTypeId = \'' + ApprovalHelper.RT_ID_INVOICING_REQUEST + '\' OR ' +
                    'RecordTypeId = \'' + ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL + '\')'))
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {oppId});
    }

    public QueryFactory selectRenewalOpportunitiesDowngradedByMigration(List<String> accId) {
        String stageNameDowngraded = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        String ccMigrationDowngradeReason = OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC;
        String renewalType = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;
        return newQueryFactory()
            .setFactoryName('selectRenewalOpportunitiesDowngradedByMigration')
            .selectFields(getRenewalFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND StageName = :bind1 AND Downgrade_Reason_Opp__c = :bind2 AND Type = :bind3')
            .setQueryBindings(new List<Object> { accId, stageNameDowngraded, ccMigrationDowngradeReason, renewalType });
    }

    public QueryFactory selectOpportunitiesByIdsWithQuotes(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesByIdsWithQuotes')
            .selectFields(getDefaultOpptyFieldList())
            .subselect(
                new QuoteSelector().selectQuotes()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {oppIds});
    }

    public QueryFactory selectMasterAndTechnicalOpportunitiesByMasterIdWithQuotes(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectMasterAndTechnicalOpportunitiesByMasterIdWithQuotes')
            .selectFields(getDefaultOpptyFieldList())
            .subselect(
                new QuoteSelector().selectQuotes()
            )
            .setCondition('Id IN :bind0 OR MasterOpportunity__c IN :bind0')
            .setQueryBindings(new List<Object> {oppIds});
    }

    public QueryFactory selectOpportunitiesForPsCases(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForPsCases')
            .selectFields(getFieldsForPsCases())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectOpptyMandatoryFieldsByOpptyName(String opptyName) {
        return newQueryFactory()
            .setFactoryName('selectOpptyMandatoryFieldsByOpptyName')
            .selectFields(selectOpptyMandatoryFieldsForIncumbentCapture())
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object> { opptyName });
    }

    public QueryFactory selectOpptyMandatoryFieldsByOpptyID(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpptyMandatoryFieldsByOpptyID')
            .selectFields(selectOpptyMandatoryFieldsForIncumbentCapture())
            .setCondition('Id = :bind0 and StageName in :bind1')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpptyFieldsForDowngradeValidationByOpptyID(ID opptyID) {
        return newQueryFactory()
            .setFactoryName('selectOpptyFieldsForDowngradeValidationByOpptyID')
            .selectFields(selectOpptyFieldsForDowngradeValidation())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object> { opptyID });
    }

    public QueryFactory selectOpportunityForInContactCaseSharing(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityForInContactCaseSharing')
            .withSelectorFieldsIncluded()
            .selectFields(selectOpptyFieldsForInContactCaseSharing())
            .selectFields(getCloseFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> { oppId });
    }

    public QueryFactory selectChangeOrderOpportunityByOrderId(Id orderId) {
        List<String> stageNames = new List<String> { OpportunityHelper.STAGE_NAME_DOWNGRADED, OpportunityHelper.STAGE_NAME_CLOSED_WON };
        return newQueryFactory()
            .setFactoryName('selectChangeOrderOpportunityByOrderId')
            .selectFields(getDefaultOpptyFieldList())
            .setCondition('Parent_Order__c = :bind0 AND StageName NOT IN :bind1')
            .setQueryBindings(new List<Object> { orderId, stageNames });
    }
    
    public QueryFactory selectOpportunitiesForSyncWS(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunitiesForSyncWS')
            .selectFields(new Set<String> {
                'Id',
                'AccountId'
            })
            .setCondition('AccountId IN :bind0 AND RecordTypeId = :bind1')
            .setQueryBindings(bindings);
    }
}