public inherited sharing class ApprovalSelector extends SObjectSelector {

    public ApprovalSelector() {
        super();
    }

    public ApprovalSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Approval__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Approval__c.Id,
            Approval__c.Account__c,
            Approval__c.Name,
            Approval__c.Opportunity__c,
            Approval__c.Account__c,
            Approval__c.Status__c,
            Approval__c.StatusLastModifiedDate__c,
            Approval__c.CreatedById,
            Approval__c.RecordTypeId,
            Approval__c.InvoiceApprovalType__c
        };
    }

    public List<String> getDNBiEmailFieldList() {
        return new List<String> {
            'RecordTypeId',
            'Partner_MRR__c',
            'Partner_Type__c',
            'Brands_Permitted_to_Sell__c',
            'VAR_Territory__c',
            'Opportunity__r.Name',
            'Invoice_Terms__c',
            'Sign_Up_Purchase_Limit__c',
            'Potential_Users__c',
            'Monthly_Credit_Limit__c',
            'Initial_Number_of_Users__c',
            'Initial_Number_of_Devices__c',
            'Price_per_User__c',
            'Reason_Customer_is_Requesting_Invoicing__c',
            'Why_RingCentral_Should_Invoice_Customer__c',
            'Legal_Physical_Address_Street__c',
            'Legal_Physical_Address_City__c',
            'Legal_Physical_Address_State_Province__c',
            'Legal_Physical_Address_Country__c',
            'Legal_Physical_Address_Zip_Code__c',
            'Billing_Address__c',
            'Company_Phone_Number__c',
            'Company_DUNS_Number__c',
            'Company_Website__c',
            'Owner.Name',
            'Payment_Terms__c',
            'CurrencyIsoCode',
            'Legal_Company_Name_Head_Office__c',
            'Account__r.Name',
            'Account__r.Invoice_Terms__c',
            'Account__r.Monthly_Credit_Limit__c',
            'Account__r.Sign_up_Purchase_Limit__c',
            'Account__r.Payment_Terms__c',
            'Account__r.Payment_Method__c',
            'Account__r.Partner_ID__c',
            'Account__r.Partner_Account_Name__c'
        };
    }

    public List<String> getFieldsForSLA() {
        return new List<String> {
            'Id',
            'Name',
            'Approval_ID__c',
            'Account__r.Id',
            'Account__r.Name'
        };
    }

    private List<String> getValidationApprovalFieldList() {
        return new List<String> {
            'Id',
            'OwnerId',
            'AccountPayableContact__c',
            'PartnerAccountPayableContact__c',
            'Status__c',
            'CreatedDate',
            'RecordTypeId',
            'LastModifiedDate',
            'Account__c',
            'Opportunity__c'
        };
    }

    public List<String> getTaxExemptionFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'Status__c',
            'RecordTypeId',
            'Account__r.Billing_ID__c',
            'Account__r.Billing_System__c',
            'Account__r.BillingCountry',
            'Account__r.BillingState',
            'Account__r.RC_Brand__c',
            'Account__r.VATNumber__c',
            'Account__c',
            'OpportunityBrand__c',
            'Opportunity__r.Brand_Name__c',
            'Opportunity__r.BusinessIdentity__c',
            'Opportunity__r.CurrencyIsoCode',
            'Opportunity__r.Account.BillingCountry',
            'FederalTaxExemption__c',
            'StateTaxExemption__c',
            'CountyTaxExemption__c',
            'LocalTaxExemption__c',
            'SalesTaxExemption__c',
            'SEZWOPExemption__c',
            'Sign_Up_Purchase_Limit__c',
            'GstNo__c',
            'VATExemption__c',
            'VATCountry__c',
            'VATCountryForCheck__c',
            'VATNumber__c',
            'GstExemptionSezCustomer__c',
            'KycFiles__c',
            'Brand__c',
            'CreatedDate',
            'CurrencyIsoCode',
            'LastModifiedDate',
            'Contact_Email__c',
            'Contact_Full_Name__c',
            'SyncWithBillingIsNotRequired__c'
        };
    }

    private List<String> getEngageLegalApprovalFieldList() {
        return new List<String> {
            'Id',
            'Approval_ID__c',
            'Source__c',
            'CreatedDate',
            'Special_Terms_and_Notes__c',
            'Send_Special_Terms_To_PDF__c'
        };
    }

    private List<String> getRefundApprovalFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'Account__r.Name',
            'Account__r.Id',
            'Account__r.RC_User_ID__c',
            'Account__r.Billing_ID__c',
            'CurrencyIsoCode',
            'Category__c',
            'Refund_Type__c',
            'Total_Refund_Amount__c',
            'Amount__c',
            'TotalRCCoreRefundAmount__c',
            'TotalProServRefundAmount__c',
            'TotalCCRefundAmount__c',
            'TotalNGBSRefundAmount__c',
            'Approval_ID__c',
            'Level1Approver__c',
            'Level1Approver__r.Email',
            'Level1Approver__r.FirstName',
            'Level1Approver__r.LastName',
            'OwnerId',
            'Owner.Email',
            'JustificationandDescription__c',
            'RecordTypeId',
            'Refund_Product_Family_1__c',
            'Refund_Product_Family_2__c',
            'Refund_Product_Family_3__c',
            'Refund_Product_Family_4__c',
            'Refund_Product_Family_5__c',
            'Refund_Product_Family_6__c'
        };
    }

    private Set<Schema.SObjectField> getFieldsForQuote() {
        return new Set<Schema.SObjectField> {
            Approval__c.Id,
            Approval__c.Contracted_Montlhy_DL_Price__c,
            Approval__c.Quote__c
        };
    }

    private List<Schema.SObjectField> getFieldListForAccount() {
        return new List<Schema.SObjectField> {
            Approval__c.Sign_Up_Purchase_Limit__c,
            Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c,
            Approval__c.Sign_Up_Purchase_Limit_Engage_Digital__c,
            Approval__c.Sign_Up_Purchase_Limit_Engage_Voice__c,
            Approval__c.SignUpPurchaseLimitProServ__c,
            Approval__c.Sign_Up_Purchase_Limit_Office__c,
            Approval__c.Sign_Up_Purchase_Limit_for_RC_Events__c,
            Approval__c.Monthly_Credit_Limit__c,
            Approval__c.Monthly_Credit_Limit_Contact_Center__c,
            Approval__c.Monthly_Credit_Limit_Engage_Digital__c,
            Approval__c.Monthly_Credit_Limit_Engage_Voice__c,
            Approval__c.MonthlyCreditLimitProServ__c,
            Approval__c.Monthly_Credit_Limit_Office__c,
            Approval__c.Monthly_Credit_Limit_for_RC_Events__c,
            Approval__c.Opportunity__c,
            Approval__c.Status__c,
            Approval__c.StatusLastModifiedDate__c,
            Approval__c.Payment_Method__c,
            Approval__c.RecordTypeId,
            Approval__c.IsChangePaymentMethodRequest__c,
            Approval__c.Record_Type_Name__c,
            Approval__c.Account__c,
            Approval__c.Payment_Terms__c,
            Approval__c.Invoice_Terms__c,
            Approval__c.AccountPayableContact__c,
            Approval__c.IsMultiProductTechnicalApproval__c,
            Approval__c.Number_of_POC_Users__c
        };
    }

    private List<String> getMasterApprovalFieldList() {
        return new List<String> {
            'MasterApproval__r.Sign_Up_Purchase_Limit__c',
            'MasterApproval__r.Sign_Up_Purchase_Limit_Contact_Center__c',
            'MasterApproval__r.Sign_Up_Purchase_Limit_Engage_Digital__c',
            'MasterApproval__r.Sign_Up_Purchase_Limit_Engage_Voice__c',
            'MasterApproval__r.Sign_Up_Purchase_Limit_Office__c',
            'MasterApproval__r.SignUpPurchaseLimitProServ__c',
            'MasterApproval__r.Sign_Up_Purchase_Limit_for_RC_Events__c',
            'MasterApproval__r.Monthly_Credit_Limit__c',
            'MasterApproval__r.Monthly_Credit_Limit_Contact_Center__c',
            'MasterApproval__r.Monthly_Credit_Limit_Engage_Digital__c',
            'MasterApproval__r.Monthly_Credit_Limit_Engage_Voice__c',
            'MasterApproval__r.Monthly_Credit_Limit_Office__c',
            'MasterApproval__r.Monthly_Credit_Limit_Office__c',
            'MasterApproval__r.Monthly_Credit_Limit_for_RC_Events__c',
            'MasterApproval__r.Opportunity__c',
            'MasterApproval__r.Status__c',
            'MasterApproval__r.StatusLastModifiedDate__c',
            'MasterApproval__r.Payment_Method__c',
            'MasterApproval__r.RecordTypeId',
            'MasterApproval__r.IsChangePaymentMethodRequest__c',
            'MasterApproval__r.Record_Type_Name__c',
            'MasterApproval__r.Account__c',
            'MasterApproval__r.Payment_Terms__c',
            'MasterApproval__r.Invoice_Terms__c',
            'MasterApproval__r.AccountPayableContact__c',
            'MasterApproval__r.IsMultiProductTechnicalApproval__c'
        };
    }

    private List<String> getAccountRelatedFieldList() {
        return new List<String> {
            'Account__c',
            'Account__r.Id',
            'Account__r.Billing_ID__c',
            'Account__r.Master_Account__c',
            'Payment_Method__c',
            'StatusLastModifiedDate__c',
            'RecordTypeId',
            'Status__c'
        };
    }

    private List<String> getKYCApprovalFieldList() {
        return new List<String> {
            'Id',
            'Status__c',
            'RecordTypeId',
            'Account__c',
            'RcPointOfPresence__c',
            'GstStateCodeOfCustomer__c',
            'GstStateNameOfCustomer__c',
            'CoDoSoWoHo__c',
            'NameOfTheAuthorisedSignatory__c',
            'NameOfFatherOrHusband__c',
            'NationalityOfAuthorisedSignatory__c',
            'PanGirNo__c',
            'GstNo__c',
            'TypeOfCustomer__c',
            'Gst__c',
            'GenderOfAuthorisedSignatory__c',
            'GstExemptionSezCustomer__c',
            'DateOfBirthOfAuthorisedSignatory__c',
            'NameOfTheCompany__c',
            'Email__c',
            'ContactNumber__c',
            'AlternateContactNumber__c',
            'FirstPhysicalVerification__c',
            'PhysicalVerificationIn6Months__c',
            'LocationVerificationIn6Months__c',
            'HouseNo__c',
            'StreetAddress__c',
            'District__c',
            'Landmark__c',
            'Area__c',
            'PinCode__c',
            'State__c',
            'City__c',
            'CreatedDate',
            'CurrencyIsoCode',
            'KycFiles__c',
            'PurposeForProcuringTheService__c',
            'DateOfSignOff__c',
            'IsMultiProductTechnicalApproval__c',
            'Other__c',
            'NGBSAmountToIncrease__c',
            'NGBSCurrentSpendingLimit__c',
            'CurrentMRR__c', 'Option__c',
            'NGBSSyncInfo__c',
            'AccountPaymentPlan__c'
        };
    }

    private List<String> getKYCApprovalForNotesAttachmentsFieldList() {
        List<String> fields = new List<String>{
            'Account__r.BillingCity',
            'Account__r.BillingCountry',
            'Account__r.BillingPostalCode',
            'Account__r.BillingState',
            'Account__r.BillingStreet'
        };
        fields.addAll(getKYCApprovalFieldList());
        return fields;
    }

    private List<String> getCreditLimitIncreaseFieldList() {
        List<String> fields = new List<String>{
                'Account__c',
                'NGBSCurrentSpendingLimit__c',
                'NGBSAmountToIncrease__c',
                'CurrentMRR__c',
                'Option__c',
                'Status__c',
                'NGBSSyncInfo__c'
        };
        fields.addAll(getValidationApprovalFieldList());
        return fields;
    }

    public QueryFactory selectApprovals() {
        return newQueryFactory()
            .setFactoryName('selectApprovals');
    }

    public QueryFactory selectApprovalsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovals')
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalForDNBi(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectApprovalForDNBi')
                .withSelectorFieldsIncluded()
                .selectFields(getDNBiEmailFieldList())
                .withoutSelectorOrderByIncluded()
                .setCondition('Id = :bind0')
                .setQueryBindings(bindings);
    }
    public List<String> getCurrentApprover() {
        return new List<String> {
            'Current_Approver__c'
        };
    }
    public QueryFactory selectApprovalCurrentApprover(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectApprovalCurrentApprover')
                .withSelectorFieldsIncluded()
                .selectFields(getCurrentApprover())
                .withoutSelectorOrderByIncluded()
                .setCondition('Id = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalsForSignUp(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForSignUp')
            .selectFields(new List<String> {'Id', 'RecordTypeId', 'Status__c'})
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_POC_ACCOUNT + '\''
                + ' AND Account__c = :bind0 AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectInvoiceApprovalsForNGBS(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectInvoiceApprovalsForNGBS')
            .selectFields(new List<String> {'Id', 'RecordTypeId', 'Opportunity__c', 'Status__c', 'Completed_Date__c'})
            .setCondition('Opportunity__c = :bind0 AND RecordTypeId = \'' + ApprovalHelper.RT_ID_INVOICING_REQUEST + '\''
                + ' AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'')
            .addOrdering(Approval__c.Completed_Date__c, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTaxExemptionApprovalsWithAccountData(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTaxExemptionApprovalsWithAccountData')
            .selectFields(new List<String> {
                'Account__r.Id',
                'Account__r.Billing_ID__c'
            })
            .setCondition('Id IN: bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPOCApprovalsForQW(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForQW')
            .selectFields(new List<String> {
                'Id',
                'RecordTypeId',
                'Status__c',
                'Quote__c',
                'Level1Approver__r.Name',
                'Level2Approver__r.Name',
                'Level3Approver__r.Name',
                'Level4Approver__r.Name',
                'Current_Approver__c'
            })
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_POC_ACCOUNT + '\''
                + ' AND Opportunity__c = :bind0')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{
                opportunityId
            });
    }

    public QueryFactory selectSecondaryDLApprovalsForAccounts(List<String> accountIds) {
        return selectSecondaryDLApprovalsForAccounts(accountIds, new List<String>());
    }

    public QueryFactory selectSecondaryDLApprovalsForAccounts(List<String> accountIds, List<String> excludedApprovalIds) {
        List<Object> bindings = new List<Object>{
            accountIds, ApprovalHelper.RT_ID_SECONDARY_DL, excludedApprovalIds
        };

        return newQueryFactory()
            .setFactoryName('selectSecondaryDLApprovals')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String> {
                'Status__c',
                'Account__r.Id'
            })
            .setCondition('Account__r.Id IN :bind0 AND RecordTypeId = :bind1 AND Id NOT IN :bind2')
            .setQueryBindings(bindings)
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectApprovalsForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForAccount')
            .selectFields(getFieldListForAccount())
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(bindings)
            .subselect(
                new ProcessInstanceSelector()
                    .selectLastProcessInstanceInApprovedStatus()
            );
    }

    public QueryFactory selectApprovalsForAccountOrderedByStatusLastModifiedDate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForAccountOrderedByStatusLastModifiedDate')
            .selectFields(getFieldListForAccount())
            .setCondition('Account__c IN :bind0 AND StatusLastModifiedDate__c != null')
            .setQueryBindings(bindings)
            .subselect(
                new ProcessInstanceSelector()
                    .selectLastProcessInstanceInApprovedStatus()
            )
            .withoutSelectorOrderByIncluded()
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectApprovalsForAccountForQuoteService(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForAccountForQuoteService')
            .selectFields(getFieldListForAccount())
            .setCondition('Account__c IN :bind0 AND StatusLastModifiedDate__c != null')
            .setQueryBindings(bindings)
            .withoutSelectorOrderByIncluded()
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectTaxExemptionApprovals() {
        return constructTaxExemptQueryFactory()
            .setFactoryName('selectTaxExemptionApprovals')
            .setCondition('RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\'');
    }

    public QueryFactory selectApprovedTaxExemptionApprovals() {
        return constructTaxExemptQueryFactory()
            .setFactoryName('selectApprovedTaxExemptionApprovals')
            .setCondition('RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\' AND '
                + 'Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'');
    }

    public QueryFactory selectApprovedTaxExemptionApprovalsForAccount(List<Object> bindings) {
        return constructTaxExemptQueryFactory(bindings)
            .setFactoryName('selectApprovedTaxExemptionApprovalsForAccount')
            .setCondition('RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\' AND '
                + 'Account__c IN :bind0 AND Status__c IN :bind1 AND Id NOT IN :bind2');
    }

    public QueryFactory selectNotRejectedTaxExemptionApprovalsForAccount(List<Object> bindings) {
        return constructTaxExemptQueryFactory(bindings)
            .setFactoryName('selectApprovedTaxExemptionApprovalsForAccount')
            .setCondition('(RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\' OR ' +
                        'RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\') AND '
                + 'Account__c IN :bind0 AND Status__c NOT IN :bind1 AND Id NOT IN :bind2')
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectTaxExemptApprovalsInStatuses(List<Object> bindings) {
        return constructTaxExemptQueryFactory(bindings)
            .setFactoryName('selectTaxExemptApprovalsInStatuses')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\''
                + ' AND Account__c = :bind0 AND Status__c IN :bind1');
    }

    public QueryFactory selectTaxExemptionApprovalsById(List<Object> bindings) {
        return constructTaxExemptQueryFactory(bindings)
            .setFactoryName('selectTaxExemptionApprovalsById')
            .setCondition('RecordTypeId = ' + '\'' + ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL + '\''
                + ' AND Id IN :bind0');
    }

    private QueryFactory constructTaxExemptQueryFactory() {
        return constructTaxExemptQueryFactory(new List<Object>());
    }

    private QueryFactory constructTaxExemptQueryFactory(List<Object> bindings) {
        return newQueryFactory()
            .withSelectorFieldsIncluded()
            .selectFields(getTaxExemptionFieldList())
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalByIdForSLA(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalByIdForSLA')
            .withoutSelectorFieldsIncluded()
            .selectFields(getFieldsForSLA())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEngageLegalApprovals() {
        return newQueryFactory()
            .setFactoryName('selectEngageLegalApprovals')
            .withoutSelectorFieldsIncluded()
            .selectFields(getFieldsForSLA())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_ENGAGE_LEGAL + '\'')
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectEngageLegalApprovalsForAccounts(List<Object> bindings) {
        return selectEngageLegalApprovals()
            .setFactoryName('selectEngageLegalApprovalsForAccounts')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_ENGAGE_LEGAL + '\' AND Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectRefundApprovalById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectRefundApprovalById')
            .withoutSelectorFieldsIncluded()
            .selectFields(getRefundApprovalFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectInvoicingApprovalsForAPCChange(Object binding) {
        return newQueryFactory()
        .setFactoryName('selectInvoicingApprovalsForAPCChange')
        .selectFields(getValidationApprovalFieldList())
        .setQueryBindings(binding)
        .setCondition('Id = :bind0');
    }

    public QueryFactory selectEngageLegalApprovalsToUncheckForPDF(List<Object> bindings) {
        return selectEngageLegalApprovals()
            .setFactoryName('selectEngageLegalApprovalsToUncheckForPDF')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_ENGAGE_LEGAL + '\''
                + ' AND Opportunity__c IN :bind0'
                + ' AND Id NOT IN :bind1'
                + ' AND Send_Special_Terms_To_PDF__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEngageLegalApprovalsForOpportunity(List<Object> bindings) {
        return selectEngageLegalApprovals()
            .selectFields(getEngageLegalApprovalFieldList())
            .setFactoryName('selectEngageLegalApprovalsForAccounts')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_ENGAGE_LEGAL + '\' AND Opportunity__c = :bind0')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectInvoicingRequestApprovalsForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectInvoicingRequestApprovalsForAccount')
            .selectFields(new List<String> {
                'Account__c',
                'RecordTypeId'
            })
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_INVOICING_REQUEST + '\' AND Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectInvoiceApprovalsForPayableInfo(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectInvoiceApprovalsForPayableInfo')
            .selectFields(getValidationApprovalFieldList())
            .setQueryBindings(bindings)
            .setCondition('RecordTypeId IN :bind0 AND '
                + ' Account__c IN :bind1 AND Status__c IN :bind2')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectInvoiceApprovalsForPayableInfoByOpportunityId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectInvoiceApprovalsForPayableInfo')
            .selectFields(getValidationApprovalFieldList())
            .setQueryBindings(bindings)
            .setCondition('RecordTypeId IN :bind0 AND '
                + ' Opportunity__c IN :bind1 AND Status__c IN :bind2')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectApprovalsForPartnerOperations(List<Object> bindings, List<String> approvalFields) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForPartnerOperations')
            .selectFields(approvalFields)
            .setQueryBindings(bindings)
            .setCondition('RecordTypeId IN :bind0 AND '
                + ' Account__c IN :bind1 AND Status__c IN :bind2 AND StatusLastModifiedDate__c != null')
            .withoutSelectorOrderByIncluded()
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectApprovedApprovalsForAccountByRecordType(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLastApprovedForAccount')
            .selectFields(getFieldListForAccount())
            .setCondition('RecordTypeId = :bind0 AND Account__c IN :bind1 '
                +' AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'')
            .setQueryBindings(bindings)
            .subselect(
                new ProcessInstanceSelector()
                    .selectLastProcessInstanceInApprovedStatus()
            );
    }

    public QueryFactory selectApprovalsForAccountsByRTSortedByApprovedDate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLastApprovedForAccount')
            .selectFields(getFieldListForAccount())
            .setCondition('RecordTypeId = :bind0 AND Account__c IN :bind1'
                + ' AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\''
                + ' AND IsMultiProductTechnicalApproval__c = false')
            .withoutSelectorOrderByIncluded()
            .addOrdering(Approval__c.StatusLastModifiedDate__c, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLastModifiedApprovalByRecordTypeId(Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsByRecordTypeId')
            .selectFields(getAccountRelatedFieldList())
            .setCondition('RecordTypeId =  \'' + recordTypeId + '\' AND StatusLastModifiedDate__c != null')
            .withoutSelectorOrderByIncluded()
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING)
            .setLimit(1);
    }

    public QueryFactory selectAllApprovalsForAccountByRecordType(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLastApprovedForAccount')
            .selectFields(getFieldListForAccount())
            .setCondition('RecordTypeId = :bind0 AND Account__c IN :bind1')
            .setQueryBindings(bindings)
            .subselect(
                new ProcessInstanceSelector()
                    .selectLastProcessInstanceInApprovedStatus()
            );
    }

    public QueryFactory selectKYCRequestApprovalsForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectKYCRequestApprovalsForAccount')
            .selectFields(getKYCApprovalFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\' ' +
                'AND Account__c IN :bind0 ' +
                'AND StatusLastModifiedDate__c != null')
            .setQueryBindings(bindings)
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectTaxExemptAndKYCApprovalsForAccount(List<Object> bindings) {
        return constructTaxExemptQueryFactory(bindings)
            .setFactoryName('selectTaxExemptAndKYCApprovalForAccount')
            .setCondition('Account__c = :bind0');
    }

    public QueryFactory selectKYCRequestApprovals() {
        return constructTaxExemptQueryFactory()
            .setFactoryName('selectKYCRequestApprovals')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\'');
    }

    public QueryFactory selectKYCApprovalsDescOrderedByStatusModifiedDate() {
        return newQueryFactory()
            .setFactoryName('selectKYCApprovals')
            .selectFields(getKYCApprovalFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\'' +
                'AND StatusLastModifiedDate__c != null')
            .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectKYCApprovedApprovals() {
        return constructTaxExemptQueryFactory()
            .setFactoryName('selectKYCRequestApprovals')
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST +
                + '\' AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'');
    }

    public QueryFactory selectKYCRequestApprovalById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectKYCRequestApprovalById')
            .selectFields(getKYCApprovalFieldList())
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\''
                + ' AND Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectKYCRequestApprovalForNotesAttachmentsById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectKYCRequestApprovalForNotesAttachmentsById')
            .selectFields(getKYCApprovalForNotesAttachmentsFieldList())
            .subselect(
                new DocumentKYCSelector().selectDocuments()
            )
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\''
                + ' AND Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalsByRecTypeForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsByRecTypeForAccount')
            .selectFields(new List<String> {
                'Id'
            })
            .setCondition('RecordTypeId IN :bind0 AND Account__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalsForPartnerAccounts(List<Object> bindings, List<String> approvalFields) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsForPartnerAccounts')
            .selectFields(approvalFields)
            .setQueryBindings(bindings)
            .setCondition('RecordTypeId IN :bind0 AND '
                + ' Account__c IN :bind1 AND Status__c IN :bind2')
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectServiceApprovalsByMasterId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectServiceApprovalsByMasterId')
            .selectFields(AquivaHelper.getAllFieldsForObject('Approval__c'))
            .selectFields(new List<String> {
                'Opportunity__r.Tier_Name__c'
            })
            .selectFields(getMasterApprovalFieldList())
            .setCondition('MasterApproval__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectApprovalsByQuoteIdsAndRecordTypeName(Set<Id> quoteIds, String recordTypeName) {
        return newQueryFactory()
            .setFactoryName('selectApprovalsByQuoteIdsAndRecordTypeName')
            .selectFields(getFieldsForQuote())
            .setCondition('Quote__c IN :bind0 AND Record_Type_Name__c = :bind1')
            .setQueryBindings(new List<Object> {quoteIds, recordTypeName});
    }

    public QueryFactory selectCreditLimitIncreaseById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCreditLimitIncreaseById')
            .selectFields(getCreditLimitIncreaseFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE + '\''
                + ' AND Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCreditLimitIncreaseByAccountIdByStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCreditLimitIncreaseByAccountIdByStatus')
            .selectFields(getCreditLimitIncreaseFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE + '\''
                    + ' AND Account__c IN :bind0 AND Status__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCreditLimitIncreaseApproved() {
        return newQueryFactory()
            .setFactoryName('selectCreditLimitIncreaseApproved')
            .selectFields(getCreditLimitIncreaseFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE + '\''
                + ' AND Status__c = \'' + ApprovalHelper.STATUS_APPROVED + '\'')
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectCreditLimitIncreaseByAccountId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCreditLimitIncreaseByAccountId')
            .selectFields(getCreditLimitIncreaseFieldList())
            .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE + '\''
                    + ' AND Account__c = :bind0 AND (Status__c = \'' + ApprovalHelper.STATUS_NEW + '\' OR Status__c = \''
                    + ApprovalHelper.STATUS_PENDING_APPROVAL + '\')')
            .setQueryBindings(bindings);
    }

}