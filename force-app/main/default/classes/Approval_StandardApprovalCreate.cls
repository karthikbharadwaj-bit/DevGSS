/*
* Created By     : Vishal
* Created Date   : 29-05-2020
* Description    : Controller for Approval_StandardApproval_Create component on Approval in lightning experience

Change History
*******************************************************************************************************************************************
SCRUM/Jira ModifiedBy      Date        Description Tag
*******************************************************************************************************************************************

*******************************************************************************************************************************************
*/

public class Approval_StandardApprovalCreate {
    @TestVisible
    private static final String ERROR_CREDIT_LIMIT_INCREASE_APPROVAL_MUST_BE_CREATED_EXISTING_BUSINESS = 'The account doesn\'t have Billing ID, credit limit approval can not be created.';
    @TestVisible
    private static final String ERROR_YOU_HAVE_TO_CLOSE_THE_OPPORTUNITY = 'You have to close the opportunity.';
    @TestVisible
    private static final String ERROR_SUBMITTED_CREDIT_LIMIT_APPROVAL_ALREADY_EXIST = 'Submitted credit limit approval already exists on the account. Please reject or approve the existing approval first.';
    @TestVisible
    private static final String ERROR_UNEXPECTED_ERROR_HAS_OCCURRED = 'Unexpected error has occurred. Please try again later. If the problem persist ask your system administrator.';
    @TestVisible
    private static final String SOLUTIONS_ENGINEER_PRIMARY_ROLE = 'Solutions Engineer (Primary)';
    @TestVisible
    private static final String POC_QUOTE_RECORD_TYPE_NAME = 'POC Quote';
    @TestVisible
    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME = Quote.SObjectType.getDescribe().getRecordTypeInfosByName();
    @TestVisible
    private static final Id POC_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(POC_QUOTE_RECORD_TYPE_NAME).getRecordTypeId();


    public static responseWrapper reswrap = new responseWrapper();

    @AuraEnabled
    public static responseWrapper getInitialData(Id recordId, Id partnerAccountId) {
        responseWrapper response = new responseWrapper();

        Id accountId;

        if (recordId != null) {

            String sObjectName = recordId.getSobjectType().getDescribe().getName();
            if (sObjectName == 'Account') {
                accountId = recordId;
            } else if (sObjectName == 'Opportunity') {
                accountId = getAccountId(recordId);
                response.showSEHelpText=shouldDisplaySEHelpText(recordId);
            } else if (sObjectName == 'Case') {
                accountId = getAccountIdFromCase(recordId);
            }

            Account approvalAccount = getAccount(accountId);
            if (partnerAccountId == null) {
                response.partnerAccountId = getPartnerAccountId(accountId);
            }
            else {
                response.partnerAccountId = partnerAccountId;
            }

            response.recordTypes = getRecordTypes(
                true,
                AccountHelper.isInvoiceOnBehalfAccount(approvalAccount),
                AccountHelper.isWholesaleAccount(approvalAccount)
            );
            validateVatIdExemption(approvalAccount, response.recordTypes);

            List<AccountContactRole> payingContacts = getPayingContacts(accountId);

            response.payingContactsExists  = !payingContacts.isEmpty();
            if (!payingContacts.isEmpty() && payingContacts.size() == 1) {
                response.payingContactId = payingContacts[0].ContactId;
            }
            response.isInvoiceApprovalRequestDisabled = isNotApprovedIndianAccount(accountId);

            List<AccountContactRole> partnerPayingContacts = getPayingContacts(response.partnerAccountId);
            response.partnerPayingContactsExists = !partnerPayingContacts.isEmpty();

            if (!partnerPayingContacts.isEmpty() && partnerPayingContacts.size() == 1) {
                response.partnerPayingContactId = partnerPayingContacts[0].ContactId;
            }

            response.isTaxExemptionAvailable = isTaxExemptionAvailable(recordId);

        } else {
            response.recordTypes = getRecordTypes(false, false, false);
        }
        response.recordTypesMap = getRecordTypesMap();

        return response;
    }

    @TestVisible
    private static Boolean isNotApprovedIndianAccount(Id accId) {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{accId}})
            .executeQuery();
        return !kycApprovals.isEmpty()
            && kycApprovals[0].Status__c != ApprovalHelper.STATUS_APPROVED;
    }

    @AuraEnabled
    public static ResponseWrapper fetchFieldValues(String accountId, String rectypeId, String opporId) {
        String packageId;
        String address;
        String errMsg;
        Boolean showError = false;
        BillingWrappers.QuotePackageInfo packageInfo;
        Map<String, Quote> quotesByServicesMap = new Map<String, Quote>();
        Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
        Boolean isMultiProductUBEnabled = featureToggleSetting.EnableMultiProductUnifiedBilling__c;

        String approvalRecordTypeDeveloperName;
        Schema.DescribeSObjectResult approvalDescribeSObjectResult = Approval__c.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> approvalRecordTypeMapByName = approvalDescribeSObjectResult.getRecordTypeInfosById();
        if(String.isNotBlank(rectypeId)) {
            approvalRecordTypeDeveloperName = approvalRecordTypeMapByName.get(rectypeId).getDeveloperName();
        }
        Map<String, String> countryCodes = SettingsService.getCountryCodes();

        checkfieldAccess();

        if (opporId == null && rectypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
            showError = true;
            errMsg = 'Tax exemption approval must be created from Opportunity.';
        } else {
            if (opporId != null) {
                Opportunity opp = (Opportunity) new OpportunitySelector()
                    .selectOpportunitiesForApprovalCheck(new List<Object>{
                        new Set<Id>{
                            opporId
                        }
                    }
                    )
                    .executeQuery()[0];
                if (opp != null && rectypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && TaxExemptionHelper.VATBRANDS.contains(opp.Brand_Name__c)
                    && TaxExemptionHelper.VATCURRENCIES.contains(opp.CurrencyIsoCode)
                    && opp.Account.BillingCountry != null) {

                    if (opp.Account.Billing_ID__c != null) {
                        try {
                            address = getAddress(opp.Account.Billing_ID__c);
                        } catch (Exception e) {
                            System.debug('errorOnGetAddress:: ' + e.getMessage());
                        }
                    }

                    System.debug('address>>>' + address);

                    if (address != null && address != '') {
                        if (!test.isRunningTest()) {
                            BillingWrappers.BIAddress billingAddress = (BillingWrappers.BIAddress) JSON.deserialize(address, BillingWrappers.BIAddress.class);
                            if (billingAddress != null) {
                                System.debug('Country Codes***' + countryCodes.get(opp.Account.BillingCountry.toLowerCase()));
                                if (billingAddress.country != countryCodes.get(opp.Account.BillingCountry.toLowerCase())) {
                                    errMsg = 'Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.';
                                    showError = true;
                                }
                            }
                        }
                    } else {
                        if (!countryCodes.containsKey(opp.Account.BillingCountry.toLowerCase())) {
                            errMsg = 'Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.';
                            showError = true;
                        }
                    }

                    if (opp.Quotes.size() > 0) {
                        for (Quote q : opp.Quotes) {
                            if (q.Package_Info__c == null) {
                                continue;
                            } else {
                                List<BillingWrappers.QuotePackageInfo> pInfos =
                                    (List<BillingWrappers.QuotePackageInfo>)
                                        JSON.deserialize(q.Package_Info__c,
                                            List<BillingWrappers.QuotePackageInfo>.class
                                        );

                                if (pInfos.size() > 0 && q.RecordType.Name == QuoteHelper.RT_NAME_BILLING) {
                                    BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
                                    if (pInfo.id != null) {
                                        packageId = pInfo.id;
                                        packageInfo = pInfo;
                                    }
                                }
                            }
                        }
                    }
                    if (packageId != null) {
                        if (packageInfo?.packageBusinessIdentities?.approvedBi?.address?.country != null) {
                            String countryBI = countryCodes.get(packageInfo.packageBusinessIdentities.approvedBi.address.country.toLowerCase());
                            String country = countryCodes.get(opp.Account.BillingCountry.toLowerCase());
                            if (country != null && !SettingsService.isSwitzerland(opp.Account.BillingCountry) && !SettingsService.isTaiwan(opp.Account.BillingCountry) && countryBI != null && countryBI == country) {
                                errMsg = 'VAT exemption is not available for this country!';
                                showError = true;
                            }
                        } else {
                            errMsg = 'VAT exemption is not available for this quote due to BI absence (the quote may be too old). Please re-create the quote.';
                            showError = true;
                        }
                    }
                }

                if (opp != null &&
                    rectypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    TaxExemptionHelper.VATBRANDS.contains(opp.Brand_Name__c) &&
                    opp.Account.BillingCountry == null) {
                    showError = true;
                    errMsg = 'Please fill up Billing Country on Account';
                }

                if (opp != null && rectypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && TaxExemptionHelper.isIndiaCountry(opp.Account.BillingCountry)) {
                    Map<Id, Approval__c> approvalsByAccount =
                        TaxExemptionHelper.getLastApprovedKYCApprovalByAccounts(new List<Id>{
                            opp.Account.Id
                        });
                    Approval__c kycApproval = approvalsByAccount.get(opp.Account.Id);
                    errMsg = TaxExemptionHelper.getKycErrorForTEACreation(kycApproval);
                    showError = String.isNotBlank(errMsg);
                }

                if (opp != null && rectypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    reswrap = handleKycApprovalFieldsPopulation(opp.AccountId);
                }
            }
        }

        if (showError) {
            reswrap.errorMessage = errMsg;
            return reswrap;
        }

        User currentUser = [SELECT ManagerId,Manager.Name, Division, Team__c from User WHERE Id = :UserInfo.getUserId()];
        reswrap.managerId = currentUser.ManagerId;

        Set<String> approvalTypes = new Set<String> {
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL
        };

        if (accountId != null) {

            String accId = accountId;
            String accBillingAddress = '';

            Account acc = (Account) new AccountSelector()
                .selectAccountWithAllApprovals(accId, approvalTypes)
                .executeQuery()
                .get(0);

            List<Approval__c> invoicingRequestApprovals = new List<Approval__c>();
            List<Approval__c> billingDateChangeRequestApprovals = new List<Approval__c>();

            for (Approval__c app : acc.Approvals__r) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                    invoicingRequestApprovals.add(app);
                } else if (app.RecordTypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL) {
                    billingDateChangeRequestApprovals.add(app);
                }
            }
            if (ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                setLegalAddressOnApproval(reswrap, acc);
                setMovingToInvoiceBillingOnApproval(reswrap, acc);
                setAccountFieldsOnApproval(reswrap, acc.SegmentName__c, acc);
            }
            if (rectypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                reswrap = handleKycApprovalFieldsPopulation(accountId);
            }

            if (acc.BillingPostalCode != null) {
                accBillingAddress += acc.BillingPostalCode;
            }
            if (acc.BillingCountry != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += acc.BillingCountry;
            }
            if (acc.BillingState != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += acc.BillingState;
            }
            if (acc.BillingCity != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += acc.BillingCity;
            }
            if (acc.BillingStreet != null) {
                if (accBillingAddress != '') {
                    accBillingAddress += ', ';
                }
                accBillingAddress += acc.BillingStreet;
            }
            if (rectypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL && acc.Name != null) {
                reswrap.approvalName = 'Change Billing Date "' + acc.Name + '" ' + String.valueOf(billingDateChangeRequestApprovals.size() + 1);
            }
            if (rectypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST && acc.Name != null) {
                reswrap.approvalName = 'Invoicing Request "' + acc.Name + '" ' + String.valueOf(invoicingRequestApprovals.size() + 1);
            }

            List<Opportunity> opps = new OpportunitySelector()
                .selectOpportunitiesForInvoiceRequestApprovalByAccId(accId)
                .executeQuery();

            if (opps.size() == 1) {
                List<Quote> quote = [
                    SELECT Id, TotalPrice, Monthly_Recurring_Revenue__c, Total_Number_of_Digital_Lines__c, isPrimary__c, RecordType.Name, Payment_Period__c,
                    Package_Info__c, AccountId, OpportunityId, Total_MRR_New__c, Upsell_Status__c
                    FROM Quote
                    WHERE OpportunityId = :opps.get(0).Id AND isPrimary__c = TRUE AND RecordType.Name != :QuoteHelper.RT_NAME_POC_QUOTE
                ];
                Set<Id> qIds = new Set<Id>();
                Id primaryQuoteId;

                for (Quote q: quote) {
                    qIds.add(q.Id);
                    if(q.isPrimary__c && q.RecordType.Name == 'Sales Quote v2') {
                        primaryQuoteId = q.Id;
                        break;
                    }
                }
                Decimal potentialUsers = 0;
                if (!quote.isEmpty() && !opps.get(0).Is_Billing_Opportunity__c) {
                    List<QuoteLineItem> quoteLineItems = [
                        SELECT Id, NewQuantity__c, Entitlement__r.Quantity__c, Quote.RecordType.Name, Product2.Family, QuoteId
                        FROM QuoteLineItem
                        WHERE QuoteId IN :qIds AND Quote.RecordType.Name = 'Sales Quote' AND Product2.Family = 'Service'
                        LIMIT 1
                    ];
                    if (!quoteLineItems.isEmpty()) {
                        if (quoteLineItems.get(0).NewQuantity__c == null) {
                            if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                                potentialUsers = 0;
                            } else {
                                potentialUsers = potentialUsers - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                            }
                        } else if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                            potentialUsers = quoteLineItems.get(0).NewQuantity__c;
                        } else {
                            potentialUsers = quoteLineItems.get(0).NewQuantity__c - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                        }
                        reswrap.potentialUsers = String.valueOf(potentialUsers);
                    }
                }
                if (!quote.isEmpty()) {
                    quotesByServicesMap = isMultiProductUBEnabled ? getQuotesByServicesUB(quote.get(0)) : getQuotesByServices(quote.get(0));
                    Map<String, Account> technicalAccounts = AccountHelper.getTechnicalAccountsByMasterId(quote.get(0).AccountId);
                    Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(quote.get(0).OpportunityId, technicalAccounts);
                    if (ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName) && !isMultiProductUBEnabled) {
                        if (opps.get(0).PrimaryQuote__r.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
                            setAnnualInvoiceSignUpPurchaseLimit(reswrap, opps.get(0), acc);
                        }
                        else if (opps.get(0).PrimaryQuote__r.Payment_Period__c == QuoteHelper.MONTHLY_PAYMENT_METHOD) {
                            setMonthlyInvoiceSignUpPurchaseLimit(reswrap, opps.get(0), acc);
                        }
                        setInvoiceMonthlyCreditLimit(reswrap, opps.get(0), acc);
                    } else {
                        reswrap.signUpPurchaseLimit = getInvoiceSignUpPurchaseLimit(quote.get(0), acc);
                        reswrap.monthlycredLimit = getInvoiceMonthlyCreditLimit(quote.get(0), acc);
                    }
                    if (quote.get(0).Total_Number_of_Digital_Lines__c != null) {
                        reswrap.initialnumOfUsers = String.valueOf(
                            quote.get(0).Total_Number_of_Digital_Lines__c);
                    }

                    if (isMultiProductUBEnabled && ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                        Boolean isSingleQuote = quotesByServicesMap.isEmpty();
                        Approval__c lastApprovedApproval = ApprovalHelper.getLastApprovedApprovalByQuoteType(opps.get(0), isSingleQuote, rectypeId);
                        setInvoiceApprovalLimits(lastApprovedApproval, quotesByServicesMap, reswrap, acc);
                    } else {
                        prepopulateMultiProductLimits(quotesByServicesMap, reswrap, opps.get(0), technicalOpportunities, acc);
                    }
                }
                /*if(approvalPage.getParameters().get('retURL') != null && !approvalPage.getParameters().get('retURL').startsWith('/001')){
                    approvalPage.getParameters().put('CF00N80000004j6pF', opps.get(0).Name);
                    approvalPage.getParameters().put('CF00N80000004j6pF_lkid', opps.get(0).Id);
                    OpporId = opps.get(0).Id;

                }*/
            }
            reswrap.accountIdContrl = accountId;
            reswrap.addressLegal = accBillingAddress;
        }

        if(opporId != null) {
            String oppId = opporId;
            String accId = '';
            String accName = '';
            String accBillingAddress = '';
            Opportunity opp;
            List<Approval__c> invoicingRequestApprovals = new List<Approval__c>();
            List<Approval__c> billingDateChangeRequestApprovals = new List<Approval__c>();

            try {
                opp = (Opportunity) new OpportunitySelector()
                    .selectOpportunityForApprovalCreation(oppId)
                    .executeQuery()
                    .get(0);

                accId = opp.AccountId;

                Account acc = (Account) new AccountSelector()
                .selectAccountWithAllApprovals(accId, approvalTypes)
                .executeQuery()
                .get(0);

                for (Approval__c app : acc.Approvals__r) {
                    if (app.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                        invoicingRequestApprovals.add(app);
                    } else if (app.RecordTypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL) {
                        billingDateChangeRequestApprovals.add(app);
                    }
                }

                if (ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                    setLegalAddressOnApproval(  reswrap,
                                                new Account(
                                                    Name = opp.Account.Name,
                                                    BillingStreet = opp.Account.BillingStreet,
                                                    BillingCity = opp.Account.BillingCity,
                                                    BillingState = opp.Account.BillingState,
                                                    BillingCountry = opp.Account.BillingCountry,
                                                    BillingPostalCode = opp.Account.BillingPostalCode
                                                    )
                                            );
                    setMovingToInvoiceBillingOnApproval( reswrap,
                                                        new Account (
                                                            RC_User_ID__c = opp.Account.RC_User_ID__c,
                                                            RC_Account_Status__c = opp.Account.RC_Account_Status__c,
                                                            Account_Payment_Method__c = opp.Account.Account_Payment_Method__c
                                                        )
                    );
                    setAccountFieldsOnApproval( reswrap,
                                                opp.Account.SegmentName__c,
                                                new Account (
                                                    Payment_Plan__c = opp.Account.Payment_Plan__c
                                                )
                    );
                }
                if (opp.Account.BillingPostalCode != null) {
                    accBillingAddress += opp.Account.BillingPostalCode;
                }
                if (opp.Account.BillingCountry != null) {
                    if (accBillingAddress != '') {
                        accBillingAddress += ', ';
                    }
                    accBillingAddress += opp.Account.BillingCountry;
                }
                if (opp.Account.BillingState != null) {
                    if (accBillingAddress != '') {
                        accBillingAddress += ', ';
                    }
                    accBillingAddress += opp.Account.BillingState;
                }
                if (opp.Account.BillingCity != null) {
                    if (accBillingAddress != '') {
                        accBillingAddress += ', ';
                    }
                    accBillingAddress += opp.Account.BillingCity;
                }
                if (opp.Account.BillingStreet != null) {
                    if (accBillingAddress != '') {
                        accBillingAddress += ', ';
                    }
                    accBillingAddress += opp.Account.BillingStreet;
                }
                if (opp.Account.Invoice_Terms__c != null && (opp.Account.Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE
                    || opp.Account.Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF
                    || opp.Account.Payment_Method__c == AccountHelper.PAYMENT_METHOD_WHOLESALE)
                ) {
                    reswrap.invoiceTerms = opp.Account.Invoice_Terms__c;
                }
                if (rectypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL && acc.Name != null) {
                    reswrap.approvalName = 'Change Billing Date "' + acc.Name + '" ' + String.valueOf(billingDateChangeRequestApprovals.size() + 1);
                }
                if (rectypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST && acc.Name != null) {
                    reswrap.approvalName = 'Invoicing Request "' + acc.Name + '" ' + String.valueOf(invoicingRequestApprovals.size() + 1);
                }

            } catch(Exception ex) {
                System.debug('Not able to find the opportunity.');
            }
            reswrap.accountIdContrl = accId;
            reswrap.addressLegal = accBillingAddress;

            List<Quote> quote = [
                SELECT Id, TotalPrice, Monthly_Recurring_Revenue__c, Total_Number_of_Digital_Lines__c, Package_Info__c, AccountId, OpportunityId,
                    Total_One_Time__c, Total_MRR_New__c, Entitlement_Total_MRR__c, isPrimary__c, RecordType.Name, Payment_Period__c, Upsell_Status__c
                FROM Quote
                WHERE OpportunityId = :oppId AND isPrimary__c = TRUE AND RecordType.Name != :QuoteHelper.RT_NAME_POC_QUOTE
            ];

            List<Opportunity> opps = new OpportunitySelector()
                .selectOpportunitiesForInvoiceRequestApprovalByOppId(oppId)
                .executeQuery();

            Account acc = opps.get(0).Account;
            Set<Id> qIds = new Set<Id>();
            Id primarySalesQuoteId;

            for (Quote q: quote) {
                qIds.add(q.Id);
                if (q.isPrimary__c && q.RecordType.Name == 'Sales Quote v2') {
                    primarySalesQuoteId = q.Id;
                    break;
                }
            }
            Decimal potentialUsers = 0;
            if (!quote.isEmpty()) {
                quotesByServicesMap = isMultiProductUBEnabled ? getQuotesByServicesUB(quote.get(0)) : getQuotesByServices(quote.get(0));
                Map<String, Account> technicalAccounts = AccountHelper.getTechnicalAccountsByMasterId(quote.get(0).AccountId);
                Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(quote.get(0).OpportunityId, technicalAccounts);

                List<QuoteLineItem> quoteLineItems = [
                    SELECT Id, NewQuantity__c, Entitlement__r.Quantity__c, Quote.RecordType.Name, Product2.Family, QuoteId
                    FROM QuoteLineItem
                    WHERE QuoteId IN :qIds AND Quote.RecordType.Name = 'Sales Quote' AND Product2.Family = 'Service' LIMIT 1
                ];
                if (!quoteLineItems.isEmpty() && !opps.isEmpty() && !opps.get(0).Is_Billing_Opportunity__c) {
                    if (quoteLineItems.get(0).NewQuantity__c == null) {
                        if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                            potentialUsers = 0;
                        } else {
                            potentialUsers = potentialUsers - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                        }
                    } else if (quoteLineItems.get(0).Entitlement__r.Quantity__c == null) {
                        potentialUsers = quoteLineItems.get(0).NewQuantity__c;
                    } else {
                        potentialUsers = quoteLineItems.get(0).NewQuantity__c - quoteLineItems.get(0).Entitlement__r.Quantity__c;
                    }
                    reswrap.potentialUsers = String.valueOf(potentialUsers);
                }

                if (ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName) && !isMultiProductUBEnabled) {
                    if (opps.get(0).PrimaryQuote__r.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
                        setAnnualInvoiceSignUpPurchaseLimit(reswrap, opps.get(0), acc);
                    }
                    else if (opps.get(0).PrimaryQuote__r.Payment_Period__c == QuoteHelper.MONTHLY_PAYMENT_METHOD) {
                        setMonthlyInvoiceSignUpPurchaseLimit(reswrap, opps.get(0), acc);
                    }
                } else {
                    reswrap.signUpPurchaseLimit = getInvoiceSignUpPurchaseLimit(quote.get(0), acc);
                }
                if (ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName) && !isMultiProductUBEnabled) {
                    setInvoiceMonthlyCreditLimit(reswrap, opps.get(0), acc);
                } else {
                    reswrap.monthlycredLimit = getInvoiceMonthlyCreditLimit(quote.get(0), acc);
                }

                if (quote.get(0).Total_Number_of_Digital_Lines__c != null){
                    reswrap.initialnumOfUsers = String.valueOf(quote.get(0).Total_Number_of_Digital_Lines__c);
                }
                if (AccountHelper.isWholesaleAccount(opp.Account)) {
                    Decimal monthlyRecurringCharges = quote.get(0).Entitlement_Total_MRR__c == null
                        ? quote.get(0).Total_MRR_New__c
                        : quote.get(0).Total_MRR_New__c + quote.get(0).Entitlement_Total_MRR__c;
                    Decimal newMonthlyCreditLimit = monthlyRecurringCharges * 1.5;
                    if (!ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                        reswrap.monthlycredLimit = String.valueOf(newMonthlyCreditLimit);
                        reswrap.signUpPurchaseLimit = String.valueOf(quote.get(0).Total_One_Time__c * 1.5 + newMonthlyCreditLimit);
                    }
                }
                if (isMultiProductUBEnabled && ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                    Boolean isSingleQuote = quotesByServicesMap.isEmpty();
                    Approval__c lastApprovedApproval = ApprovalHelper.getLastApprovedApprovalByQuoteType(opps.get(0), isSingleQuote, rectypeId);
                    setInvoiceApprovalLimits(lastApprovedApproval, quotesByServicesMap, reswrap, acc);
                } else {
                    prepopulateMultiProductLimits(quotesByServicesMap, reswrap, opps.get(0), technicalOpportunities, acc);
                }
            }
        }

        Map<Id, Account> accMap = new Map<Id, Account>();
        String accId = accountId;
        if (accId != null) {
            accMap = new Map<Id, Account>([
                SELECT Id, Number_of_POC_Users__c, RC_User_ID__c, RC_Tier__c,
                    RC_Account_Status__c, Payment_Method__c, Account_Payment_Method__c, Monthly_Credit_Limit__c,
                    Sign_up_purchase_limit__c, Payment_terms__c, Invoice_terms__c, RC_Service_Name__c
                FROM Account
                WHERE id = :accId]);
        }

        if(!string.Isblank(rectypeId)) {
            string recordTypeId = rectypeId;
            Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
            Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
            if(rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_REFUND_APPROVAL) {
                reswrap.refundOwner = UserInfo.getUserId();
            }
            if( rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_FARMING_CLAIM_OWNER) {
                reswrap.claimingrequestor = UserInfo.getUserId();
            }
            if (rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_ENGAGE_LEGAL) {
                reswrap.recordType = Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                    .get('Engage Legal').getRecordTypeId();
            }
            if (rtMapByName.get(recordTypeId).getName() == ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME
            || rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL
            || rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_INVOICE_WHOLESALE_REQUEST_APPROVAL) {
                Account acc = accMap.get(accId);
                Map<String, Account> technicalAccounts = accId != null ? AccountHelper.getTechnicalAccountsByMasterId(accId) : new Map<String, Account>();

                List<Opportunity> opps = new OpportunitySelector()
                    .selectOpportunitiesForInvoiceRequestApprovalByAccId(accId)
                    .executeQuery();

                if (accId != null && accMap.containsKey(accId) &&
                (acc.Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE
                || acc.Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF
                || acc.Payment_Method__c == AccountHelper.PAYMENT_METHOD_WHOLESALE)) {
                    if (!ApprovalHelper.APPROVAL_INVOICE_RECORD_TYPES.contains(approvalRecordTypeDeveloperName)) {
                        reswrap.monthlycredLimit = String.valueOf(acc.Monthly_Credit_Limit__c);
                        reswrap.signUpPurchaseLimit =  String.valueOf(acc.Sign_up_purchase_limit__c);
                    }
                    reswrap.paymentTerms = acc.Payment_Terms__c;
                    reswrap.invoiceTerms = acc.Invoice_Terms__c;
                }

                if (isMultiProductUBEnabled) {
                    Approval__c approval = ApprovalHelper.getLastApprovedApproval(accId, ApprovalHelper.RT_ID_INVOICING_REQUEST);

                    if (approval != null && opps.size() != 1 && opporId == null) {
                        if (ApprovalHelper.isSingleQuoteApproval(approval)) {
                            reswrap.signUpPurchaseLimit = String.valueOf(approval.Sign_up_purchase_limit__c);
                            reswrap.monthlycredLimit = String.valueOf(approval.Monthly_Credit_Limit__c);
                        } else {
                            reswrap.signUpPurchaseLimitOffice = String.valueOf(approval.Sign_Up_Purchase_Limit_Office__c);
                            reswrap.monthlycredLimitOffice = String.valueOf(approval.Monthly_Credit_Limit_Office__c);
                            reswrap.signUpPurchaseLimitContactCenter = String.valueOf(approval.Sign_Up_Purchase_Limit_Contact_Center__c);
                            reswrap.monthlycredLimitContactCenter = String.valueOf(approval.Monthly_Credit_Limit_Contact_Center__c);
                            reswrap.signUpPurchaseLimitEngageVoice = String.valueOf(approval.Sign_Up_Purchase_Limit_Engage_Voice__c);
                            reswrap.monthlycredLimitEngageVoice = String.valueOf(approval.Monthly_Credit_Limit_Engage_Voice__c);
                            reswrap.signUpPurchaseLimitEngageDigital = String.valueOf(approval.Sign_Up_Purchase_Limit_Engage_Digital__c);
                            reswrap.monthlycredLimitEngageDigital = String.valueOf(approval.Monthly_Credit_Limit_Engage_Digital__c);
                            reswrap.signUpPurchaseLimitRCEvents = String.valueOf(approval.Sign_Up_Purchase_Limit_for_RC_Events__c);
                            reswrap.monthlycredLimitRCEvents = String.valueOf(approval.Monthly_Credit_Limit_for_RC_Events__c);
                        }
                    }
                } else {
                    if (!technicalAccounts?.values().isEmpty() && opps.size() != 1 ) {
                        reswrap.signUpPurchaseLimitOffice = acc.Sign_up_purchase_limit__c != null ?  String.valueOf(acc.Sign_up_purchase_limit__c) : ' ';
                        reswrap.monthlycredLimitOffice = acc.Monthly_Credit_Limit__c != null ? String.valueOf(acc.Monthly_Credit_Limit__c) : ' ';

                        if (technicalAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null) {
                            reswrap.signUpPurchaseLimitContactCenter = technicalAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Sign_up_purchase_limit__c != null? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Sign_up_purchase_limit__c) : ' ';
                            reswrap.monthlycredLimitContactCenter = technicalAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Monthly_Credit_Limit__c != null ? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Monthly_Credit_Limit__c) : ' ';
                        }
                        if (technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null) {
                            reswrap.signUpPurchaseLimitEngageVoice = technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Sign_up_purchase_limit__c != null ? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Sign_up_purchase_limit__c) : ' ';
                            reswrap.monthlycredLimitEngageVoice = technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Monthly_Credit_Limit__c != null ? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Monthly_Credit_Limit__c) : ' ';
                        }
                        if (technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null) {
                            reswrap.signUpPurchaseLimitEngageDigital = technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Sign_up_purchase_limit__c != null ? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Sign_up_purchase_limit__c) : ' ';
                            reswrap.monthlycredLimitEngageDigital = technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Monthly_Credit_Limit__c != null ? String.valueOf(technicalAccounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Monthly_Credit_Limit__c) : ' ';
                        }
                    }
                }
            }
            if (rtMapByName.get(recordTypeId).getName() == ApprovalHelper.RT_NAME_FEATURE_ADD_ONS_APPROVAL) {

                if ( accId != null && accMap.containsKey(accId) ) {
                    reswrap.managerId = '';
                    String rcUserID = accMap.get(accId).RC_User_ID__c;
                    String rcAccountStatus = accMap.get(accId).RC_Account_Status__c;
                    Decimal numberOfPOCUsers = getNumberOfPOCUsers(accId);
                    String accType = '';
                    String edition = '';

                    // Fill AccountType__c field according to the logic below
                    if (numberOfPOCUsers > 0 && !AccountHelper.FEATURE_ADD_ONS_ACCOUNT_STATUSES.contains(rcAccountStatus?.toLowerCase())) {
                        accType = 'POC';
                    } else if (String.isNotBlank(rcUserID)) {
                        accType = 'Existing';
                    } else {
                        accType = 'New';
                    }

                    reswrap.accountType = accType;

                    Map<Id, String> accToTierMap = createMapAccToTier(accMap.values());
                    Map<String, String> tierToEditionMap = createMapTierToEdition(accToTierMap.values());

                    edition = tierToEditionMap.get(accToTierMap.get(accId));
                    reswrap.editionComp = edition;
                }
            }
        }
        return reswrap;
    }

    @TestVisible
    private static Decimal getNumberOfPOCUsers(Id accountId) {
        Decimal numberOfPOCUsers = 0;
        Approval__c approval = ApprovalHelper.getLastApprovedApproval(accountId, ApprovalHelper.RT_ID_POC_ACCOUNT);

        if (approval != null) {
            numberOfPOCUsers = approval.Number_of_POC_Users__c;
        }

        return numberOfPOCUsers;
    }

    private static Map<String, Quote> getQuotesByServices(Quote quote) {
        List<String> quoteServiceNames = new List<String>();
        Map<String, Account> technicalAccounts = AccountHelper.getTechnicalAccountsByMasterId(quote.AccountId);
        Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(quote.OpportunityId, technicalAccounts);
        Map<String, Quote> quotesByServicesMap = new Map<String, Quote>();

        if (technicalOpportunities.values().isEmpty()) {
            return quotesByServicesMap;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(
                            quote.Package_Info__c,
                            List<BillingWrappers.QuotePackageInfo>.class
                    );
        for(BillingWrappers.QuotePackageInfo pInfo: pInfos) {
            quoteServiceNames.add(pInfo.productName);
        }

        if (quoteServiceNames.size() > 1) {
            quotesByServicesMap = QuoteHelper.getTechnicalQuotesByMasterId(quote.Id, quoteServiceNames, technicalOpportunities);
            for (String serviceName: technicalOpportunities.keySet()) {
                if (quotesByServicesMap.get(serviceName) == null) {
                    quotesByServicesMap.put(serviceName, new Quote());
                }
            }
        } else {
            if (!QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(quoteServiceNames[0]) && quoteServiceNames[0] != QuoteHelper.NGBS_OFFICE_PRODUCT) {
                return quotesByServicesMap;
            }

            for (String serviceName: technicalOpportunities.keySet()) {
                if (serviceName == quoteServiceNames[0]) {
                    quotesByServicesMap.put(serviceName, quote);
                } else {
                    quotesByServicesMap.put(serviceName, new Quote());
                }
            }

            if (quoteServiceNames[0] == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                quotesByServicesMap.put(quoteServiceNames[0], quote);
            } else{
                quotesByServicesMap.put(QuoteHelper.NGBS_OFFICE_PRODUCT, new Quote());
            }
        }
        return quotesByServicesMap;
    }

    @TestVisible
    private static Map<String, Quote> getQuotesByServicesUB(Quote quote) {
        List<String> quoteServiceNames = new List<String>();
        Map<String, Quote> quotesByServicesMap = new Map<String, Quote>();

        if (String.isEmpty(quote.Package_Info__c)) {
            return quotesByServicesMap;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(
                            quote.Package_Info__c,
                            List<BillingWrappers.QuotePackageInfo>.class
                    );

        for (BillingWrappers.QuotePackageInfo pInfo: pInfos) {
            quoteServiceNames.add(pInfo.productName);
        }

        if (quoteServiceNames.size() > 1) {
            quotesByServicesMap = QuoteHelper.getTechnicalQuotesByMasterIdUB(quote, quoteServiceNames);
        }

        return quotesByServicesMap;
    }

    private static void prepopulateMultiProductLimits(
        Map<String, Quote> quotesByServicesMap,
        ResponseWrapper reswrap,
        Opportunity masterOpp,
        Map<String, Opportunity> techOppties,
        Account account
        ) {
        if (quotesByServicesMap.isEmpty()) {
            return;
        }
        if (masterOpp.PrimaryQuote__r.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
            if (quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT) != null) {
                reswrap.signUpPurchaseLimitOffice = setMultiproductAnnualInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Office_Pipeline__c, account, techOppties, null, true);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null) {
                Opportunity ccOpp = techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT);
                reswrap.signUpPurchaseLimitContactCenter = setMultiproductAnnualInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Contact_Center_Pipeline__c, account, techOppties, ccOpp, false);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null) {
                Opportunity engVOpp = techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
                reswrap.signUpPurchaseLimitEngageVoice = setMultiproductAnnualInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Engage_Voice_Pipeline__c, account, techOppties, engVOpp, false);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null) {
                Opportunity engDOpp = techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
                reswrap.signUpPurchaseLimitEngageDigital = setMultiproductAnnualInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Engage_Digital_Pipeline__c, account, techOppties, engDOpp, false);
            }
        } else if (masterOpp.PrimaryQuote__r.Payment_Period__c == QuoteHelper.MONTHLY_PAYMENT_METHOD) {
            if (quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT) != null) {
                reswrap.signUpPurchaseLimitOffice = setMultiproductMonthlyInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Office_Pipeline__c, account, techOppties, null, true);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null) {
                Opportunity ccOpp = techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT);
                reswrap.signUpPurchaseLimitContactCenter = setMultiproductMonthlyInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Contact_Center_Pipeline__c, account, techOppties, ccOpp, false);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null) {
                Opportunity engVOpp = techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
                reswrap.signUpPurchaseLimitEngageVoice = setMultiproductMonthlyInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Engage_Voice_Pipeline__c, account, techOppties, engVOpp, false);
            }
            if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null) {
                Opportunity engDOpp = techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
                reswrap.signUpPurchaseLimitEngageDigital = setMultiproductMonthlyInvoiceSignUpPurchaseLimit(masterOpp, masterOpp.Estimated_12M_Engage_Digital_Pipeline__c, account, techOppties, engDOpp, false);
            }
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT) != null) {
            reswrap.monthlycredLimitOffice = setMultiproductInvoiceMonthlyCreditLimit(masterOpp.Estimated_12M_Office_Pipeline__c, account);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null) {
            reswrap.monthlycredLimitContactCenter = setMultiproductInvoiceMonthlyCreditLimit(masterOpp.Estimated_12M_Contact_Center_Pipeline__c, account);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null) {
            reswrap.monthlycredLimitEngageVoice = setMultiproductInvoiceMonthlyCreditLimit(masterOpp.Estimated_12M_Engage_Voice_Pipeline__c, account);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null) {
            reswrap.monthlycredLimitEngageDigital = setMultiproductInvoiceMonthlyCreditLimit(masterOpp.Estimated_12M_Engage_Digital_Pipeline__c, account);
        }
    }

    private static void setInvoiceApprovalLimits(Approval__c approval, Map<String, Quote> quotesByServicesMap, ResponseWrapper reswrap, Account acc) {
        // prepopulate Single Products limits from last approved Invoice Approval
        if (approval != null) {
            reswrap.signUpPurchaseLimit = String.valueOf(approval.Sign_Up_Purchase_Limit__c);
            reswrap.monthlycredLimit = String.valueOf(approval.Monthly_Credit_Limit__c);
        }

        if (quotesByServicesMap.isEmpty()) {
            return;
        }
        // prepopulate Multiproduct limits from last approved Invoice Approval
        if (quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT) != null) {
            reswrap.signUpPurchaseLimitOffice = approval?.Sign_Up_Purchase_Limit_Office__c > 0
                ? String.valueOf(approval.Sign_Up_Purchase_Limit_Office__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT), acc);
            reswrap.monthlycredLimitOffice = approval?.Monthly_Credit_Limit_Office__c > 0
                ? String.valueOf(approval.Monthly_Credit_Limit_Office__c)
                : getInvoiceMonthlyCreditLimit(quotesByServicesMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT), acc);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null) {
            reswrap.signUpPurchaseLimitContactCenter = approval?.Sign_Up_Purchase_Limit_Contact_Center__c > 0
                ? String.valueOf(approval.Sign_Up_Purchase_Limit_Contact_Center__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT), acc);
            reswrap.monthlycredLimitContactCenter = approval?.Monthly_Credit_Limit_Contact_Center__c > 0
                ? String.valueOf(approval.Monthly_Credit_Limit_Contact_Center__c)
                : getInvoiceMonthlyCreditLimit(quotesByServicesMap.get(QuoteHelper.NGBS_RCCC_PRODUCT), acc);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null) {
            reswrap.signUpPurchaseLimitEngageVoice = approval?.Sign_Up_Purchase_Limit_Engage_Voice__c > 0
                ? String.valueOf(approval.Sign_Up_Purchase_Limit_Engage_Voice__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT), acc);
            reswrap.monthlycredLimitEngageVoice = approval?.Monthly_Credit_Limit_Engage_Voice__c > 0
                ? String.valueOf(approval.Monthly_Credit_Limit_Engage_Voice__c)
                : getInvoiceMonthlyCreditLimit(quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT), acc);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null) {
            reswrap.signUpPurchaseLimitEngageDigital = approval?.Sign_Up_Purchase_Limit_Engage_Digital__c > 0
                ? String.valueOf(approval.Sign_Up_Purchase_Limit_Engage_Digital__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT), acc);
            reswrap.monthlycredLimitEngageDigital = approval?.Monthly_Credit_Limit_Engage_Digital__c > 0
                ? String.valueOf(approval.Monthly_Credit_Limit_Engage_Digital__c)
                : getInvoiceMonthlyCreditLimit(quotesByServicesMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT), acc);
        }
        if (quotesByServicesMap.get(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) != null) {
            reswrap.signUpPurchaseLimitProServ = approval?.SignUpPurchaseLimitProServ__c > 0
                ? String.valueOf(approval.SignUpPurchaseLimitProServ__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT), acc);
            reswrap.monthlycredLimitProServ = approval?.MonthlyCreditLimitProServ__c > 0
                ? String.valueOf(approval.MonthlyCreditLimitProServ__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT), acc);
        }
        if (quotesByServicesMap.get(Constants.CONST_RC_EVENT) != null) {
            reswrap.signUpPurchaseLimitRCEvents = approval?.Sign_Up_Purchase_Limit_for_RC_Events__c > 0
                ? String.valueOf(approval.Sign_Up_Purchase_Limit_for_RC_Events__c)
                : getInvoiceSignUpPurchaseLimit(quotesByServicesMap.get(Constants.CONST_RC_EVENT), acc);
            reswrap.monthlycredLimitRCEvents = approval?.Monthly_Credit_Limit_for_RC_Events__c > 0
                ? String.valueOf(approval.Monthly_Credit_Limit_for_RC_Events__c)
                : getInvoiceMonthlyCreditLimit(quotesByServicesMap.get(Constants.CONST_RC_EVENT), acc);
        }
    }

    private static void setLegalAddressOnApproval (ResponseWrapper reswrap, Account acc) {
        reswrap.legal_physical_address_street = acc?.BillingStreet;
        reswrap.legal_physical_address_city = acc?.BillingCity;
        reswrap.legal_physical_address_state_province = acc?.BillingState;
        reswrap.legal_physical_address_country = acc?.BillingCountry;
        reswrap.legal_physical_address_zip_code = acc?.BillingPostalCode;
    }

    private static void setMovingToInvoiceBillingOnApproval (ResponseWrapper reswrap, Account acc) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            reswrap.moving_to_invoice_billing = true;
        }
    }

    private static Boolean isExistingCustomerCreditToInvoice(Account acc) {
        return String.isNotBlank(acc?.RC_User_ID__c)
            && acc?.RC_Account_Status__c == AccountHelper.PAID_STATUS
            && AccountHelper.isCreditCardAccount(acc);
    }

    private static void setAccountFieldsOnApproval (ResponseWrapper reswrap, String accountSegmentName, Account acc) {
        reswrap.account_segment = accountSegmentName;
        reswrap.payment_plan = acc?.Payment_Plan__c;
    }

    private static void setAnnualInvoiceSignUpPurchaseLimit(ResponseWrapper reswrap, Opportunity opp, Account acc) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            reswrap.signUpPurchaseLimit = String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0)
                    * 24
                );
        }
        else {
            reswrap.signUpPurchaseLimit = String.valueOf(
                (
                    Double.valueOf(opp.Calculated_12M_Total_Pipeline__c != null ? opp.Calculated_12M_Total_Pipeline__c : 0) +
                    Double.valueOf(opp.Estimated_Hardware__c != null ? opp.Estimated_Hardware__c : 0) +
                    Double.valueOf(opp.Estimated_One_Time_Pipeline__c != null ? opp.Estimated_One_Time_Pipeline__c : 0) +
                    Double.valueOf(opp.EstimatedProfessionalServices12Month__c != null ? opp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        }
    }

    private static void setMonthlyInvoiceSignUpPurchaseLimit (ResponseWrapper reswrap, Opportunity opp, Account acc) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            reswrap.signUpPurchaseLimit = String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0)
                    * 2
                );
        }
        else {
            reswrap.signUpPurchaseLimit = String.valueOf(
                (
                    Double.valueOf(opp.Calculated_12M_Total_Pipeline__c != null ? opp.Calculated_12M_Total_Pipeline__c / 12 : 0) +
                    Double.valueOf(opp.Estimated_Hardware__c != null ? opp.Estimated_Hardware__c : 0) +
                    Double.valueOf(opp.Estimated_One_Time_Pipeline__c != null ? opp.Estimated_One_Time_Pipeline__c : 0) +
                    Double.valueOf(opp.EstimatedProfessionalServices12Month__c != null ? opp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        }
    }

    private static String setMultiproductMonthlyInvoiceSignUpPurchaseLimit(
        Opportunity masterOpp,
        Decimal estimated12MPipeline,
        Account acc,
        Map<String, Opportunity> techOppties,
        Opportunity techOpp,
        Boolean isOffice
        ) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            return String.valueOf(
                Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0) * 2
                );
        }
        else if (isOffice) {
            Double ccEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            Double engVEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            Double engDEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            return String.valueOf(
                (
                    Double.valueOf(estimated12MPipeline != null ? estimated12MPipeline / 12 : 0) +
                    Double.valueOf(masterOpp.Estimated_Hardware__c != null ? masterOpp.Estimated_Hardware__c : 0) +
                    Double.valueOf(masterOpp.Estimated_One_Time_Pipeline__c != null ? masterOpp.Estimated_One_Time_Pipeline__c - ccEstimatedOneTime - engDEstimatedOneTime - engVEstimatedOneTime : 0) +
                    Double.valueOf(masterOpp.EstimatedProfessionalServices12Month__c != null ? masterOpp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        } else {
            return String.valueOf(
                (
                    Double.valueOf(estimated12MPipeline != null ? estimated12MPipeline / 12 : 0) +
                    Double.valueOf(techopp?.Estimated_One_Time_Pipeline__c != null ? techopp.Estimated_One_Time_Pipeline__c : 0) +
                    Double.valueOf(masterOpp.EstimatedProfessionalServices12Month__c != null ? masterOpp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        }
    }

    private static String setMultiproductAnnualInvoiceSignUpPurchaseLimit(
        Opportunity masterOpp,
        Decimal estimated12MPipeline,
        Account acc,
        Map<String, Opportunity> techOppties,
        Opportunity techOpp,
        Boolean isOffice
        ) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            return String.valueOf(
                Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0) * 24
                );
        }
        else if (isOffice) {
            Double ccEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_RCCC_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            Double engVEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            Double engDEstimatedOneTime = techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) != null ? techOppties.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).Estimated_One_Time_Pipeline__c : 0;
            return String.valueOf(
                (
                    Double.valueOf(estimated12MPipeline != null ? estimated12MPipeline : 0) +
                    Double.valueOf(masterOpp.Estimated_Hardware__c != null ? masterOpp.Estimated_Hardware__c : 0) +
                    Double.valueOf(masterOpp.Estimated_One_Time_Pipeline__c != null ? masterOpp.Estimated_One_Time_Pipeline__c - ccEstimatedOneTime - engDEstimatedOneTime - engVEstimatedOneTime : 0) +
                    Double.valueOf(masterOpp.EstimatedProfessionalServices12Month__c != null ? masterOpp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        } else {
            return String.valueOf(
                (
                    Double.valueOf(estimated12MPipeline != null ? estimated12MPipeline : 0) +
                    Double.valueOf(techopp?.Estimated_One_Time_Pipeline__c != null ? techopp.Estimated_One_Time_Pipeline__c : 0) +
                    Double.valueOf(masterOpp.EstimatedProfessionalServices12Month__c != null ? masterOpp.EstimatedProfessionalServices12Month__c : 0)
                )
                * 2
            );
        }
    }

    private static void setInvoiceMonthlyCreditLimit(ResponseWrapper reswrap, Opportunity opp, Account acc) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            reswrap.monthlycredLimit = String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0) * 2
                );
        } else {
            reswrap.monthlycredLimit = String.valueOf(
                Double.valueOf(opp.Calculated_12M_Total_Pipeline__c != null ? opp.Calculated_12M_Total_Pipeline__c / 6 : 0)
            );
        }
    }

    private static String setMultiproductInvoiceMonthlyCreditLimit(Decimal estimated12MPipeline, Account acc) {
        if(isExistingCustomerCreditToInvoice(acc)) {
            return String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0)
                    * 2
                );
        }
        else {
            return String.valueOf(
                Double.valueOf(estimated12MPipeline != null ? estimated12MPipeline / 6 : 0)
            );
        }
    }

    private static String getInvoiceSignUpPurchaseLimit(Quote quote, Account acc) {
        String signUpPurchaseLimit = ' ';
        if(isExistingCustomerCreditToInvoice(acc)) {
            signUpPurchaseLimit = String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0)
                    * 2
                );
        }
        else {
            if (quote.TotalPrice != null) {
                signUpPurchaseLimit = String.valueOf(quote.TotalPrice * 1.5);
            }
        }
        return signUpPurchaseLimit;
    }

    private static String getInvoiceMonthlyCreditLimit(Quote quote, Account acc) {
        String monthlycredLimit = ' ';
        if(isExistingCustomerCreditToInvoice(acc)) {
            monthlycredLimit = String.valueOf(
                    Double.valueOf(acc.MRR__c != null ? acc.MRR__c : 0) * 2
                );
        } else {
            monthlycredLimit = String.valueOf(calculateMRV(quote.Id) * 1.5);
        }
        return monthlycredLimit;
    }

    @AuraEnabled
    public static ResponseWrapper fetchFieldCreditLimitValues(String accountId, String recordTypeId, String opportunityId) {
        String errMsg;
        Boolean showError = false;
        String localAccountId = accountId;
        Decimal currentSpendingLimit;

        Account acc = null;
        Map<String, String> opportunityQuoteMap = new Map<String, String>();
        List<Opportunity> opportunities = new List<Opportunity>();
        Map<Id, Id> approvals = new Map<Id, Id>();

        if (isApprovalCreateOnAccount(accountId, opportunityId)) {
            acc = getAccount(accountId);
            opportunities = getOpportunityIds(accountId, OpportunityHelper.STAGE_NAME_CLOSED_WON);
            opportunityQuoteMap = getOpportunityQuoteMap(opportunities);
            approvals = getCreditLimitApprovals(accountId);
        } else {
            localAccountId = getAccountId(opportunityId);
            acc = getAccount(localAccountId);
            opportunities = getOpportunityIds(localAccountId, OpportunityHelper.STAGE_NAME_CLOSED_WON);
            opportunityQuoteMap = getOpportunityQuoteMap(opportunities);
            approvals = getCreditLimitApprovals(localAccountId);
        }
        if (recordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE && acc != null && acc.Billing_ID__c == null) {
            showError = true;
            errMsg = ERROR_CREDIT_LIMIT_INCREASE_APPROVAL_MUST_BE_CREATED_EXISTING_BUSINESS;
        } else if (recordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE && accountId == null && opportunityQuoteMap.isEmpty()) {
            showError = true;
            errMsg = ERROR_YOU_HAVE_TO_CLOSE_THE_OPPORTUNITY;
        } else if (recordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE && !approvals.isEmpty()) {
            showError = true;
            errMsg = ERROR_SUBMITTED_CREDIT_LIMIT_APPROVAL_ALREADY_EXIST;
        } else if (recordTypeId != ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE) {
            return fetchFieldValues(accountId, recordTypeId, opportunityId);
        }

        if (!showError && localAccountId != null) {

            reswrap.currentMRR = getCurrentMRR(opportunities, opportunityId, acc.Billing_ID__c, showError, errMsg);

            reswrap.accountIdContrl = localAccountId;
            try {
                currentSpendingLimit = ApprovalHelper.getCurrentSpendingLimit(localAccountId);
                if (currentSpendingLimit != null) {
                    reswrap.NGBSCurrentSpendingLimit = currentSpendingLimit;
                } else {
                    showError = true;
                    errMsg = ERROR_UNEXPECTED_ERROR_HAS_OCCURRED;
                }
            } catch (Exception e) {
                showError = true;
                errMsg = ERROR_UNEXPECTED_ERROR_HAS_OCCURRED;
            }
        }

        if (showError) {
            reswrap.errorMessage = errMsg;
            return reswrap;
        }

        if (!opportunityQuoteMap.isEmpty()) {
            reswrap.opportunityQuoteMap = opportunityQuoteMap;
            reswrap.NGBSAmountToIncreaseSpendingLimit = getAmountToIncreaseSpendingLimit(opportunities, opportunityId);
        }

        return reswrap;
    }

    public static Decimal calculateMRV(Id qId) {

        Decimal sumMVR = 0;
        if (qId == null) {
            return sumMVR;
        }

        List<QuoteLineItem> qliList = [SELECT Id, Discount, QuoteRecordType__c, UnitPrice, NewQuantity__c, QuoteId, Zero_Quantity__c,
            PackageInfo__c, TotalPrice, Subtotal, Product2.Family, Product2.Charge_Term__c, Product2.Billing_Type__c, IsMultiProductTechnicalQLI__c
        FROM QuoteLineItem
        WHERE Quote.Id = :qId];

        for(QuoteLineItem qli: qliList) {
            String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            Decimal discount = qli.Discount != null ? qli.Discount : 0;
            Decimal totalPrice = ((1 - discount / 100) * qli.UnitPrice).setScale(2) * qli.NewQuantity__c;

            if (qli.IsMultiProductTechnicalQLI__c && qli.Product2.Billing_Type__c == 'Usage') {
                continue;
            }

            if ((chargeTerm == 'Monthly - Contract' || chargeTerm == 'Monthly') && qli.Product2.Family != 'Taxes') {
                sumMVR = sumMVR + totalPrice;
            }
            if (chargeTerm == 'Annual' && qli.Product2.Family != 'Taxes') {
                sumMVR = sumMVR + totalPrice / 12;
            }
        }
        return sumMVR.setScale(2);
    }

    public static Map<Id, String> createMapAccToTier( List<Account> accs) {
        Pattern regexPattern = Pattern.compile('\\[\\d+\\]');
        Map<Id, String> accToTierMap = new Map< Id, String>();

        for (Account acc : accs ) {
            String tier = acc.RC_Tier__c == null ? '' : acc.RC_Tier__c;
            Matcher regexMatcher = regexPattern.matcher( tier );
            if ( regexMatcher.find() ) {
                accToTierMap.put( acc.Id , regexMatcher.group().removeStart('[').removeEnd(']') );
            } else {
                accToTierMap.put( acc.Id , null );
            }
        }
        return accToTierMap;
    }

    public static Map<String, String> createMapTierToEdition( List<String> tiers) {
        Map<String, String> tierToEditionMap = new Map<String, String>();
        List<Pricebook2> pb2s = [ SELECT Tier_ID__c, Edition__c FROM Pricebook2 WHERE Tier_ID__c IN :tiers ];

        for( Pricebook2 pb2 : pb2s ) {
            tierToEditionMap.put( pb2.Tier_ID__c, pb2.Edition__c );
        }

        return tierToEditionMap;
    }

    public static String getAddress(String billingId) {
        if (test.isRunningTest()) {
            return 'test Address';
        }
        String responseBody;
        if (billingId != null) {
            String endpoint = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + billingId + '/address?type=Billing';
            responseBody = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody();
        }
        return responseBody;
    }

    public static void checkfieldAccess(){
        if (Schema.sObjectType.Approval__c.fields.Level1Approver__c.isAccessible()) {
            reswrap.managerId_access = true;
        } else{
            reswrap.managerId_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Potential_Users__c.isAccessible()) {
            reswrap.potentialUsers_access = true;
        } else {
            reswrap.potentialUsers_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_access = true;
        } else {
            reswrap.signUpPurchaseLimit_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit_Office__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_Office_access = true;
        } else {
            reswrap.signUpPurchaseLimit_Office_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.SignUpPurchaseLimitProServ__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_ProServ_access = true;
        } else {
            reswrap.signUpPurchaseLimit_ProServ_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit_Contact_Center__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_Contact_Center_access = true;
        } else {
            reswrap.signUpPurchaseLimit_Contact_Center_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit_Engage_Voice__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_Engage_Voice_access = true;
        } else {
            reswrap.signUpPurchaseLimit_Engage_Voice_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit_Engage_Digital__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_Engage_Digital_access = true;
        } else {
            reswrap.signUpPurchaseLimit_Engage_Digital_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Sign_Up_Purchase_Limit_for_RC_Events__c.isAccessible()) {
            reswrap.signUpPurchaseLimit_RCEvents_access = true;
        } else {
            reswrap.signUpPurchaseLimit_RCEvents_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit__c.isAccessible()) {
            reswrap.monthlycredLimit_access = true;
        } else {
            reswrap.monthlycredLimit_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit_Office__c.isAccessible()) {
            reswrap.monthlycredLimit_Office_access = true;
        } else {
            reswrap.monthlycredLimit_Office_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.MonthlyCreditLimitProServ__c.isAccessible()) {
            reswrap.monthlycredLimit_ProServ_access = true;
        } else {
            reswrap.monthlycredLimit_ProServ_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit_Contact_Center__c.isAccessible()) {
            reswrap.monthlycredLimit_Contact_Center_access = true;
        } else {
            reswrap.monthlycredLimit_Contact_Center_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit_Engage_Voice__c.isAccessible()) {
            reswrap.monthlycredLimit_Engage_Voice_access = true;
        } else {
            reswrap.monthlycredLimit_Engage_Voice_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit_Engage_Digital__c.isAccessible()) {
            reswrap.monthlycredLimit_Engage_Digital_access = true;
        } else {
            reswrap.monthlycredLimit_Engage_Digital_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Monthly_Credit_Limit_for_RC_Events__c.isAccessible()) {
            reswrap.monthlycredLimit_RCEvents_access = true;
        } else {
            reswrap.monthlycredLimit_RCEvents_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Initial_Number_of_Users__c.isAccessible()) {
            reswrap.initialnumOfUsers_access = true;
        } else {
            reswrap.initialnumOfUsers_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Legal_Physical_Address_Head_Office__c.isAccessible()) {
            reswrap.addressLegal_access = true;
        } else {
            reswrap.addressLegal_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Payment_Terms__c.isAccessible()) {
            reswrap.paymentTerms_access = true;
        } else {
            reswrap.paymentTerms_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Invoice_Terms__c.isAccessible()) {
            reswrap.invoiceTerms_access = true;
        } else {
            reswrap.invoiceTerms_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.AccountType__c.isAccessible()) {
            reswrap.accountType_access = true;
        } else {
            reswrap.accountType_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Claiming_Requestor__c.isAccessible()) {
            reswrap.claimingrequestor_access = true;
        } else {
            reswrap.claimingrequestor_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Refund_Owner__c.isAccessible()) {
            reswrap.refundOwner_access = true;
        } else {
            reswrap.refundOwner_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Edition__c.isAccessible()) {
            reswrap.editionComp_access = true;
        } else {
            reswrap.editionComp_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Case__c.isAccessible()) {
            reswrap.Case_access = true;
        } else {
            reswrap.Case_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Credit_Transfer_To_Agent__c.isAccessible()) {
            reswrap.CreditTransferToAgent_access = true;
        } else {
            reswrap.CreditTransferToAgent_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Agent_Credit__c.isAccessible()) {
            reswrap.AgentCredit_access = true;
        } else {
            reswrap.AgentCredit_access = false;
        }

        if (Schema.sObjectType.Approval__c.fields.Opportunity__c.isAccessible()) {
            reswrap.Opportunity_access = true;
        } else {
            reswrap.Opportunity_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Moving_to_Invoice_Billing__c.isAccessible()) {
            reswrap.moving_to_invoice_billing_access = true;
        } else {
            reswrap.moving_to_invoice_billing_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Account_Segment__c.isAccessible()) {
            reswrap.account_segment_access = true;
        } else {
            reswrap.account_segment_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Payment_Plan__c.isAccessible()) {
            reswrap.payment_plan_access = true;
        } else {
            reswrap.payment_plan_access = false;
        }
        System.debug('Access wrap'+reswrap);
    }

    private static Id getAccountId(Id opportunityId) {
        List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id> {opportunityId})
            .executeQuery();
        Opportunity opp = opportunities[0];
        return opp.AccountId;
    }

    @TestVisible
    private static Boolean shouldDisplaySEHelpText(Id oppId) {
       
        Set<Id> oppIdSet = new Set<Id>{oppId};
        List<String> teamRolesList = new List<String>{SOLUTIONS_ENGINEER_PRIMARY_ROLE};
                
        List<OpportunityTeamMember> oppTeamMembersListWithSERole = (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
            .selectByOpportunityIdsAndRoles(new List<Object> {oppIdSet, teamRolesList})
            .executeQuery();
       
        List<Quote> pocQuotesListWithMinDL = (List<Quote>) new QuoteSelector()
            .selectPocQuotesByOpportunityWithMinDLs(oppIdSet, POC_QUOTE_RT_ID, 20)
            .executeQuery();
        
           return oppTeamMembersListWithSERole.isEmpty() && !pocQuotesListWithMinDL.isEmpty();
        }


    private static Id getAccountIdFromCase(Id caseId) {
        List<Case> queryResult = (List<Case>) new CaseSelector().newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'AccountId' })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ caseId })
            .setQueryCaching(false)
            .executeQuery();
        Case currentCase = queryResult[0];
        return currentCase.AccountId;
    }

    private static Account getAccount(Id accountId) {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(accountId)
            .executeQuery();
        Account acc = accounts[0];
        return acc;
    }

    private static Id getPartnerAccountId(Id accountId) {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccountById(accountId)
            .executeQuery();
        Account acc = accounts[0];
        return acc.Partner_Account__c;
    }

    public static List<AccountContactRole> getPayingContacts(Id accountId) {
        List<AccountContactRole> accountPayableContacts = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountPayableContactRolesByAccount(new List<Object> { accountId, null })
            .executeQuery();
        return accountPayableContacts;
    }

    @TestVisible
    private static List<RecordType> getRecordTypes(Boolean hasRecordId, Boolean isInvoiceOnBehalf, Boolean isWholesale) {
        Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>([
            SELECT Description, Name, DeveloperName
            FROM RecordType
            WHERE SobjectType =: ApprovalHelper.APPROVAL_OBJECT_NAME
            AND IsActive = TRUE
        ]);

        Boolean isSelectPackageByBI = Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c;

        Schema.SObjectType  objType = Approval__c.SObjectType;
        for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()){
            if (!rt.isAvailable()) {
                recordTypesMap.remove(rt.getRecordTypeId());
            }
            if (hasRecordId) {
                if (rt.getName() == ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME && (isInvoiceOnBehalf || isWholesale)) {
                    recordTypesMap.remove(rt.getRecordTypeId());
                }

                if (rt.getName() == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL && !isInvoiceOnBehalf) {
                    recordTypesMap.remove(rt.getRecordTypeId());
                }

                if (rt.getName() == ApprovalHelper.RT_NAME_INVOICE_WHOLESALE_REQUEST_APPROVAL && !isWholesale) {
                    recordTypesMap.remove(rt.getRecordTypeId());
                }
            } else {
                if (
                    rt.getName() == ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME
                    || rt.getName() == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL
                    || rt.getName() == ApprovalHelper.RT_NAME_INVOICE_WHOLESALE_REQUEST_APPROVAL
                ) {
                    recordTypesMap.remove(rt.getRecordTypeId());
                }
            }
            if (isSelectPackageByBI && rt.getName() == ApprovalHelper.RT_NAME_TAX_EXEMPT_APPROVAL && !hasRecordId) {
                recordTypesMap.remove(rt.getRecordTypeId());
            }
        }
        return recordTypesMap.values();
    }

    private static Map<Id, String> getRecordTypesMap() {
        Map<Id, String> result = new Map<Id, String>();
        Map<String, Schema.RecordTypeInfo> approvalRecordTypes = Approval__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        for (RecordTypeInfo recTypeObj : approvalRecordTypes.values()) {
            result.put(recTypeObj.getRecordTypeId(), recTypeObj.getDeveloperName());
        }
        return result;
    }

    @TestVisible
    private static Boolean isTaxExemptionAvailable(Id recordId) {
        if (!Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c || recordId == null) {
            return true;
        }

        Boolean result = true;

        if (recordId.getSobjectType() == Account.getSobjectType()) {

            Account acc = (Account) new AccountSelector()
                .selectAccountById(recordId)
                .executeQuery()
                .get(0);

            result = !AccountHelper.isSingaporeBillingCountry(acc)
                && !AccountHelper.isAustraliaBillingCountry(acc);

        } else if (recordId.getSobjectType() == Opportunity.getSobjectType()) {

            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesForApprovalCheck(new List<Object>{new Set<Id>{recordId}})
                .executeQuery()
                .get(0);

            result = !OpportunityHelper.isSingapore(opp)
                && !OpportunityHelper.isAustralia(opp);
        }

        return result;
    }

    private static ResponseWrapper handleKycApprovalFieldsPopulation(Id accId) {
        List<Approval__c> sourceApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{accId}})
            .setLimit(1)
            .executeQuery();
        ResponseWrapper response = new ResponseWrapper();
        Approval__c sourceApproval;
        if (!sourceApprovals.isEmpty() && sourceApprovals[0]?.Status__c == ApprovalHelper.STATUS_APPROVED) {
            sourceApproval = sourceApprovals[0];
        } else {
            response.kycApprovalFieldsToValuesMap = new Map<String, Object>();
            response.kycApprovalFieldsToValuesMap.put('NationalityOfAuthorisedSignatory__c', 'India');
            return response;
        }

        List<String> approvalFields = new List<String>{
            'KycFiles__c', 'DateOfSignOff__c'
        };
        approvalFields.addAll(ApprovalService.getApprovalLayoutInfo(ApprovalHelper.LAYOUT_KYC_APPROVAL_NAME));
        List<String> formulaicFields = new List<String>{
            'Account__c',
            'AlternateContactNumber__c',
            'ContactNumber__c',
            'Email__c',
            'Name',
            'NameOfTheCompany__c',
            'Status__c'
        };

        response.kycApprovalFieldsToValuesMap = new Map<String, Object>();
        for (String fieldName : approvalFields) {
            if (!formulaicFields.contains(fieldName) && sourceApproval.get(fieldName) != null) {
                response.kycApprovalFieldsToValuesMap.put(fieldName, sourceApproval.get(fieldName));
            }
        }
        return response;
    }

    @TestVisible
    private static void validateVatIdExemption(Account acc, List<RecordType> recordTypes) {
        List<String> switzerlandCountry = new List<String>{'switzerland', 'che', 'ch'};
        if (String.isNotBlank(acc.VATNumber__c) && String.isNotBlank(acc.BillingCountry) && switzerlandCountry.contains(acc.BillingCountry.toLowerCase())
                || String.isNotBlank(acc.BillingCountry) && !switzerlandCountry.contains(acc.BillingCountry.toLowerCase())
                || String.isBlank(acc.BillingCountry)) {
            for (Integer index = 0; index < recordTypes.size(); index++) {
                if (recordTypes.get(index).DeveloperName == ApprovalHelper.RT_DEVELOPER_NAME_VAT_ID_Exemption) {
                    recordTypes.remove(index);
                    break;
                }
            }
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public String approvalName {get;set;}
        @AuraEnabled
        public String managerId {get;set;}
        @AuraEnabled
        public boolean managerId_access {get;set;}
        @AuraEnabled
        public String potentialUsers {get;set;}
        @AuraEnabled
        public boolean potentialUsers_access {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimit {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_access {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimitOffice {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimitProServ {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_Office_access {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_ProServ_access {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimitContactCenter {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_Contact_Center_access {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimitEngageVoice {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_Engage_Voice_access {get;set;}
        @AuraEnabled
        public String signUpPurchaseLimitEngageDigital {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_Engage_Digital_access {get;set;}
        @AuraEnabled
        public boolean signUpPurchaseLimit_RCEvents_access {get;set;}
        @AuraEnabled
        public String monthlycredLimit {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_access {get;set;}
        @AuraEnabled
        public String monthlycredLimitOffice {get;set;}
        @AuraEnabled
        public String monthlycredLimitProServ {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_Office_access {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_ProServ_access {get;set;}
        @AuraEnabled
        public String monthlycredLimitContactCenter {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_Contact_Center_access {get;set;}
        @AuraEnabled
        public String monthlycredLimitEngageVoice {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_Engage_Voice_access {get;set;}
        @AuraEnabled
        public String monthlycredLimitEngageDigital {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_Engage_Digital_access {get;set;}
        @AuraEnabled
        public boolean monthlycredLimit_RCEvents_access {get;set;}
        @AuraEnabled
        public String initialnumOfUsers {get;set;}
        @AuraEnabled
        public boolean initialnumOfUsers_access {get;set;}
        @AuraEnabled
        public String addressLegal {get;set;}
        @AuraEnabled
        public boolean addressLegal_access {get;set;}
        @AuraEnabled
        public String accountIdContrl {get;set;}////
        @AuraEnabled
        public String paymentTerms {get;set;}
        @AuraEnabled
        public boolean paymentTerms_access {get;set;}
        @AuraEnabled
        public String invoiceTerms {get;set;}
        @AuraEnabled
        public boolean invoiceTerms_access {get;set;}
        @AuraEnabled
        public String accountType {get;set;}
        @AuraEnabled
        public boolean accountType_access {get;set;}
        @AuraEnabled
        public String recordType {get;set;}////
        @AuraEnabled
        public String claimingrequestor {get;set;}
        @AuraEnabled
        public boolean claimingrequestor_access {get;set;}
        @AuraEnabled
        public String refundOwner {get;set;}
        @AuraEnabled
        public boolean refundOwner_access {get;set;}
        @AuraEnabled
        public String editionComp {get;set;}
        @AuraEnabled
        public boolean editionComp_access {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        @AuraEnabled
        public boolean Case_access {get;set;}
        @AuraEnabled
        public boolean CreditTransferToAgent_access {get;set;}
        @AuraEnabled
        public boolean AgentCredit_access {get;set;}
        @AuraEnabled
        public boolean Opportunity_access {get;set;}
        @AuraEnabled
        public Id payingContactId {get;set;}
        @AuraEnabled
        public Id partnerPayingContactId {get;set;}
        @AuraEnabled
        public Id partnerAccountId {get;set;}
        @AuraEnabled
        public List<RecordType> recordTypes { get; set; }
        @AuraEnabled
        public Map<Id, String> recordTypesMap { get; set; }
        @AuraEnabled
        public Boolean payingContactsExists {get;set;}
        @AuraEnabled
        public Boolean partnerPayingContactsExists {get;set;}
        @AuraEnabled
        public Boolean isTaxExemptionAvailable {get;set;}
        @AuraEnabled
        public Map<String, Object> kycApprovalFieldsToValuesMap {get;set;}
        @AuraEnabled
        public boolean isInvoiceApprovalRequestDisabled {get;set;}
        @AuraEnabled
        public String legal_physical_address_city;
        @AuraEnabled
        public String legal_physical_address_country;
        @AuraEnabled
        public String legal_physical_address_state_province;
        @AuraEnabled
        public String legal_physical_address_street;
        @AuraEnabled
        public String legal_physical_address_zip_code;
        @AuraEnabled
        public Boolean moving_to_invoice_billing;
        @AuraEnabled
        public Boolean moving_to_invoice_billing_access;
        @AuraEnabled
        public String account_segment;
        @AuraEnabled
        public Boolean account_segment_access;
        @AuraEnabled
        public String payment_plan;
        @AuraEnabled
        public Boolean payment_plan_access;
        @AuraEnabled
        public String paymentMethod {get; set;}
        @AuraEnabled
        public String paymentPlan {get; set;}
        @AuraEnabled
        public Decimal NGBSCurrentSpendingLimit { get; set; }
        @AuraEnabled
        public Decimal NGBSAmountToIncreaseSpendingLimit { get; set; }
        @AuraEnabled
        public Map<String, String> opportunityQuoteMap { get; set; }
        @AuraEnabled
        public Decimal currentMRR {get; set;}
        @AuraEnabled 
        public Boolean showSEHelpText {get; set;}
        @AuraEnabled
        public String signUpPurchaseLimitRCEvents {get;set;}
        @AuraEnabled
        public String monthlycredLimitRCEvents {get;set;}
    }

    public static List<Opportunity> getOpportunityIds(String accountId, String stageName) {
        List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunityByIdAndStageName(new List<Object>{
                        accountId, stageName
                })
                .executeQuery();

        return opportunities;
    }

    public static Map<String, String> getOpportunityQuoteMap(List<Opportunity> opportunities) {
        Map<String, String> result = new Map<String, String>();

        if (opportunities != null && !opportunities.isEmpty()) {
            for (Opportunity opp : opportunities) {
                if (opp.Quotes != null && !opp.Quotes.isEmpty()) {
                    result.put(opp.Id, opp.Quotes[0].Id);
                }
            }
        }

        return result;
    }

    public static Map<Id, Id> getCreditLimitApprovals(String accountId) {
        Map<Id, Id> result = new Map<Id, Id>();
        List<Approval__c> approvalsToProcess = (List<Approval__c>) new ApprovalSelector()
                .selectCreditLimitIncreaseByAccountId(new List<Object>{accountId})
                .executeQuery();

        for (Approval__c approvalObj : approvalsToProcess) {
            result.put(accountId, approvalObj.Id);
            break;
        }
        return result;
    }

    public static Boolean isApprovalCreateOnAccount(String accountId, String oppId) {
        Boolean result = false;
        if (accountId != null && oppId == null) {
            result = true;
        }
        return result;
    }

    public static Decimal getCurrentMRR(List<Opportunity> opportunities, String opportunityId, String billingId, Boolean showError, String errMessage) {
        Decimal result = null;
        try {

            if (opportunities != null && !opportunities.isEmpty()) {
                result = getCurrentMRR(opportunities, opportunityId);
            } else {
                BillingWrappers.NGBSAccount ngbsAccount = NGBSAPI.getNGBSAccount(billingId);
                if (ngbsAccount != null) {
                    String endpoint = String.format(NGBSAPI.NGBS_ACCOUNT_RECURRING_CHARGES, new List<String>{
                            billingId, ngbsAccount.getPackage().id
                    });
                    HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
                    if (response != null) {
                        Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        if (ngbsAccount != null && !ngbsAccount.packages.isEmpty() && ngbsAccount.packages[0].masterDuration == 'Annual') {
                            result = (Decimal) meta.get('amount') * 12;
                        } else {
                            result = (Decimal) meta.get('amount');
                        }
                    }
                }
            }
        } catch (Exception e) {
            showError = true;
            errMessage = ERROR_UNEXPECTED_ERROR_HAS_OCCURRED;
        }

        return result;
    }

    public static Decimal getAmountToIncreaseSpendingLimit(List<Opportunity> opportunities, String oppId) {
        Decimal result;
        if (opportunities != null && !opportunities.isEmpty()) {
            for (Opportunity opp : opportunities) {
                if (oppId != null) {
                    if (opp.Id == oppId) {
                        result = opp.Quotes[0].Total_Initial_Payment__c;
                        break;
                    }
                } else {
                    result = opp.Quotes[0].Total_Initial_Payment__c;
                    break;
                }
            }
        }

        return result;
    }

    public static Decimal getCurrentMRR(List<Opportunity> opportunities, String oppId) {
        Decimal result;
        if (opportunities != null && !opportunities.isEmpty()) {
            for (Opportunity opp : opportunities) {
                if (oppId != null) {
                    if (opp.Id == oppId) {
                        result = opp.Quotes[0].Entitlement_Total_MRR__c;
                        break;
                    }
                } else {
                    result = opp.Quotes[0].Entitlement_Total_MRR__c;
                    break;
                }
            }
        }

        return result;
    }
}