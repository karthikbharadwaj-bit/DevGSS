@isTest
private class Test_ApprovalSelector {
    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_STREET = '20 Davis Drive';
    private static final String ACCOUNT_BILLING_CITY = 'Vanga';
    private static final String ACCOUNT_BILLING_STATE = 'CA';
    private static final String ACCOUNT_BILLING_POSTAL_CODE = '94002';
    private static final String ACCOUNT_BILLING_COUNTRY = 'India';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'Test Sales Opportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Approvals fields defined
    private static final String APPROVAL_NAME_APPROVED = 'approvedTaxApproval';
    private static final String APPROVAL_AREA_APPROVED = 'Test1';
    private static final String APPROVAL_NAME_REJECTED = 'rejectedTaxApproval';
    private static final String APPROVAL_AREA_REJECTED = 'Test2';
    private static final String APPROVAL_NAME_ENGAGE_LEGAL  = 'EngageLegalApproval';
    private static final String APPROVAL_NAME_INVOICING_REQUEST = 'InvoicingRequestApproval';
    private static final String APPROVAL_KYC_REQUEST = 'KYCRequestApproval';
    private static final String APPROVAL_NAME_EXCLUDED = 'excludedApproval';
    private static final String APPROVAL_NAME_CREDIT_LIMIT_INCREASE = 'Credit Limit Increase';

    //Quote fields defined
    private static final String MASTER_QUOTE_NAME = 'Master Quote';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Approvals should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong approval selected';

    @testSetup
    static void testData(){
        Triggers.SwitchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.BillingStreet => ACCOUNT_BILLING_STREET,
                    Account.BillingCity => ACCOUNT_BILLING_CITY,
                    Account.BillingState => ACCOUNT_BILLING_STATE,
                    Account.BillingPostalCode => ACCOUNT_BILLING_POSTAL_CODE,
                    Account.BillingCountry => ACCOUNT_BILLING_COUNTRY
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => acc.Id,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                    Opportunity.Name => OPPORTUNITY_NAME,
                    Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                    Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                }
            )
            .create()
            .getRecord();

        List<Approval__c> testApprovals = new List<Approval__c>();
        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_APPROVED,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Area__c => APPROVAL_AREA_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_REJECTED,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Status__c => ApprovalHelper.STATUS_REJECTED,
                    Approval__c.Area__c => APPROVAL_AREA_REJECTED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_ENGAGE_LEGAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Send_Special_Terms_To_PDF__c => true,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_INVOICING_REQUEST,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_KYC_REQUEST,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_KYC_REQUEST,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_POC_ACCOUNT,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_EXCLUDED,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_SECONDARY_DL,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_CREDIT_LIMIT_INCREASE,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        testApprovals.add((Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => APPROVAL_NAME_CREDIT_LIMIT_INCREASE,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.StatusLastModifiedDate__c => System.now(),
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .build()
            .getRecord());

        insert testApprovals;
        Triggers.SwitchOn();
    }

    @isTest
    static void testSelectApprovals(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector(true, true)
            .selectApprovals()
            .executeQuery();

        System.assert(approvals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectSecondaryDLApprovalsForAccounts(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector(true, true)
            .selectSecondaryDLApprovalsForAccounts(new List<String>{accounts[0].Id})
            .executeQuery();

        System.assert(approvals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectTaxExemptApprovalsInStatuses(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> taxExemptApprovalsInStatuses = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptApprovalsInStatuses(new List<Object> {
                new Set<Id>{accounts[0].Id},
                new Set<String>{ApprovalHelper.STATUS_APPROVED}
            })
            .executeQuery();

        System.assert(taxExemptApprovalsInStatuses.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsByIds(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalsByIds = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByIds(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(approvalsByIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalForDNBi(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalForDNBi = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalForDNBi(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(approvalForDNBi.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalCurrentApprover(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalCurrentApprover = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalCurrentApprover(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(approvalCurrentApprover.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsForSignUp(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalsForSignUp = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForSignUp(new List<Object> {new Set<Id>{approvals[4].Account__c}})
            .executeQuery();

        System.assert(approvalsForSignUp.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectInvoiceApprovalsForNGBS(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> invoiceApprovalsForNGBS = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForNGBS(new List<Object> {new Set<Id> {approvals[0].Opportunity__c}})
            .executeQuery();

        System.assert(invoiceApprovalsForNGBS.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectPOCApprovalsForQW(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> pOCApprovalsForQW = (List<Approval__c>) new ApprovalSelector()
            .selectPOCApprovalsForQW(approvals[0].Opportunity__c)
            .executeQuery();

        System.assert(pOCApprovalsForQW.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectTaxExemptionApprovalsWithAccountData(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> taxExemptionApprovalsWithAccountData = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptionApprovalsWithAccountData(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(taxExemptionApprovalsWithAccountData.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectSecondaryDLApprovalsForAccountsWithTwoParams(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> secondaryDLApprovalsForAccounts = (List<Approval__c>) new ApprovalSelector()
            .selectSecondaryDLApprovalsForAccounts(
                new List<String> {accounts[0].Id},
                new List<String> {approvals[6].Id}
            )
            .executeQuery();

        System.assert(secondaryDLApprovalsForAccounts.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccount(new List<Object> {new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(approvalsForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectTaxExemptionApprovals(){
        List<Approval__c> taxExemptionApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        System.assert(taxExemptionApprovals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testApprovedTaxExemptionApprovals(){
        List<Approval__c> approvedTaxExemptionApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovedTaxExemptionApprovals()
            .executeQuery();

        System.assert(approvedTaxExemptionApprovals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovedTaxExemptionApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvedTaxExemptionApprovalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectApprovedTaxExemptionApprovalsForAccount(
                new List<Object> {
                    new Set<Id>{accounts[0].Id},
                    new Set<String>{ApprovalHelper.STATUS_APPROVED},
                    new Set<Id>()
                }
            )
            .executeQuery();

        System.assert(approvedTaxExemptionApprovalsForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectNotRejectedTaxExemptionApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> notRejectedTaxExemptionApprovalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectNotRejectedTaxExemptionApprovalsForAccount(
                new List<Object> {
                        new Set<Id>{accounts[0].Id},
                        new Set<String>{ApprovalHelper.STATUS_APPROVED},
                        new Set<Id>()
                    }
            )
            .executeQuery();

        System.assert(notRejectedTaxExemptionApprovalsForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectTaxExemptionApprovalsById(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> taxExemptionApprovalsById = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptionApprovalsById(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(taxExemptionApprovalsById.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalByIdForSLA(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalByIdForSLA = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalByIdForSLA(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(approvalByIdForSLA.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectEngageLegalApprovals(){
        List<Approval__c> engageLegalApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectEngageLegalApprovals()
            .executeQuery();

        System.assert(engageLegalApprovals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectEngageLegalApprovalsForAccounts(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> engageLegalApprovalsForAccounts = (List<Approval__c>) new ApprovalSelector()
            .selectEngageLegalApprovalsForAccounts(new List<Object> {new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(engageLegalApprovalsForAccounts.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectRefundApprovalById(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> refundApprovalById = (List<Approval__c>) new ApprovalSelector()
            .selectRefundApprovalById(new List<Object> {new Set<Id>{approvals[0].Id}})
            .executeQuery();

        System.assert(refundApprovalById.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectInvoicingApprovalsForAPCChange(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> invoicingApprovalsForAPCChange = (List<Approval__c>) new ApprovalSelector()
            .selectInvoicingApprovalsForAPCChange(new Set<Id>{approvals[0].Id})
            .executeQuery();

        System.assert(invoicingApprovalsForAPCChange.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testEngageLegalApprovalsToUncheckForPDF(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> engageLegalApprovalsToUncheckForPDF = (List<Approval__c>) new ApprovalSelector()
            .selectEngageLegalApprovalsToUncheckForPDF(new List<Object> {
                new Set<Id>{approvals[0].Opportunity__c}, new Set<Id>()
            })
            .executeQuery();

        System.assert(engageLegalApprovalsToUncheckForPDF.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectEngageLegalApprovalsForOpportunity(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> engageLegalApprovalsForOpportunity = (List<Approval__c>) new ApprovalSelector()
            .selectEngageLegalApprovalsForOpportunity(new List<Object> {new Set<Id>{approvals[0].Opportunity__c}})
            .executeQuery();

        System.assert(engageLegalApprovalsForOpportunity.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectInvoicingRequestApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> invoicingRequestApprovalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectInvoicingRequestApprovalsForAccount(new List<Object> {new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(invoicingRequestApprovalsForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectInvoiceApprovalsForPayableInfo(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> invoiceApprovalsForPayableInfo = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfo(
                new List<Object> {
                        new Set<String>{ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL},
                        new Set<Id>{accounts[0].Id},
                        new Set<String>{ApprovalHelper.STATUS_APPROVED}
                    }
            )
            .executeQuery();

        System.assert(invoiceApprovalsForPayableInfo.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsForPartnerOperations(){
        ApprovalSelector appSelector = new ApprovalSelector();
        List<String> fieldsForSLA = appSelector.getFieldsForSLA();

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvalsForPartnerOperations = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForPartnerOperations(
                new List<Object> {
                        new Set<String>{ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL},
                        new Set<Id>{accounts[0].Id},
                        new Set<String>{ApprovalHelper.STATUS_APPROVED}
                    },
                fieldsForSLA
            )
            .executeQuery();

        System.assert(approvalsForPartnerOperations.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovedApprovalsForAccountByRecordType(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvedApprovalsForAccountByRecordType = (List<Approval__c>) new ApprovalSelector()
            .selectApprovedApprovalsForAccountByRecordType(new List<Object> {
                new Set<String>{approvals[0].RecordTypeId}, new Set<String>{approvals[0].Account__c}
            })
            .executeQuery();

        System.assert(approvedApprovalsForAccountByRecordType.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectTaxExemptAndKYCApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> taxExemptAndKYCApprovalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptAndKYCApprovalsForAccount(new List<Object> {new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(taxExemptAndKYCApprovalsForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectKYCRequestApprovals(){
        List<Approval__c> kYCRequestApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovals()
            .executeQuery();

        System.assert(kYCRequestApprovals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectKYCApprovalsDescOrderedByStatusModifiedDate(){
        List<Approval__c> kYCApprovalsDescOrderedByStatusModifiedDate = (List<Approval__c>) new ApprovalSelector()
            .selectKYCApprovalsDescOrderedByStatusModifiedDate()
            .executeQuery();

        System.assert(kYCApprovalsDescOrderedByStatusModifiedDate.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectKYCApprovedApprovals(){
        List<Approval__c> kYCApprovedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCApprovedApprovals()
            .executeQuery();

        System.assert(kYCApprovedApprovals.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectKYCRequestApprovalById(){
        List<Approval__c> kYCApprovedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCApprovedApprovals()
            .executeQuery();

        List<Approval__c> kYCRequestApprovalById = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalById(new List<Object> {new Set<Id>{kYCApprovedApprovals[0].Id}})
            .executeQuery();

        System.assert(kYCRequestApprovalById.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectKYCRequestApprovalForNotesAttachmentsById(){
        List<Approval__c> kYCApprovedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCApprovedApprovals()
            .executeQuery();

        List<Approval__c> kYCRequestApprovalForNotesAttachmentsById = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalForNotesAttachmentsById(new List<Object> {new Set<Id>{kYCApprovedApprovals[0].Id}})
            .executeQuery();

        System.assert(kYCRequestApprovalForNotesAttachmentsById.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectLastModifiedApprovalByRecordTypeId(){
        List<Approval__c> lastModifiedApprovalByRecordTypeId = (List<Approval__c>) new ApprovalSelector()
            .selectLastModifiedApprovalByRecordTypeId(ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .executeQuery();

        System.assert(lastModifiedApprovalByRecordTypeId.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSlectAllApprovalsForAccountByRecordType(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> allApprovalsForAccountByRecordType = (List<Approval__c>) new ApprovalSelector()
            .selectAllApprovalsForAccountByRecordType(new List<Object> {
                ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL, new Set<Id>{accounts[0].Id}
            })
            .executeQuery();

        System.assert(allApprovalsForAccountByRecordType.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectKYCRequestApprovalsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> kYCRequestApprovalsForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(kYCRequestApprovalsForAccount.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectApprovalsByRecTypeForAccount(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalsByRecTypeForAccount = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByRecTypeForAccount(new List<Object> {
                new Set<String>{approvals[0].RecordTypeId}, new Set<Id>{approvals[0].Account__c}
            })
            .executeQuery();

        System.assert(approvalsByRecTypeForAccount.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsForPartnerAccounts(){
        ApprovalSelector appSelector = new ApprovalSelector();
        List<String> fieldsForSLA = appSelector.getFieldsForSLA();

        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Approval__c> approvalsForPartnerAccounts = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForPartnerAccounts(
                new List<Object> {
                        new Set<String>{ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL},
                        new Set<Id>{accounts[0].Id},
                        new Set<String>{ApprovalHelper.STATUS_APPROVED}
                    },
                fieldsForSLA
            )
            .executeQuery();

        System.assert(approvalsForPartnerAccounts.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectInvoiceApprovalsForPayableInfoByOpportunityId(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> invoiceApprovalsForPayableInfoByOpportunityId = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfoByOpportunityId(
                new List<Object> {
                        new Set<String>{approvals[0].RecordTypeId},
                        new Set<Id>{approvals[0].Opportunity__c},
                        new Set<String>{ApprovalHelper.STATUS_APPROVED}
                    }
            )
            .executeQuery();

        System.assert(invoiceApprovalsForPayableInfoByOpportunityId.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectApprovalsForAccountOrderedByStatusLastModifiedDate(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalsForAccountOrderedByStatusLastModifiedDate = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccountOrderedByStatusLastModifiedDate(new List<Object> {new Set<Id>{approvals[0].Account__c}})
            .executeQuery();

        System.assert(approvalsForAccountOrderedByStatusLastModifiedDate.size() > 0, ASSERT_MESSAGE);
    }


    @isTest
    static void testSelectApprovalsForAccountForQuoteService(){
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvalsForAccountForQuoteService = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccountForQuoteService(new List<Object> {new Set<Id>{approvals[0].Account__c}})
            .executeQuery();

        System.assert(approvalsForAccountForQuoteService.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectApprovalsByQuoteIdsAndRecordTypeName() {
        Approval__c testApproval = [
            SELECT Id, Name, Opportunity__c, Account__c
            FROM Approval__c
            WHERE Name = :APPROVAL_NAME_ENGAGE_LEGAL
            LIMIT 1
        ];

        Triggers.switchOff();
        Quote testActiveQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'testActiveQuote',
                    Quote.OpportunityId => testApproval.Opportunity__c,
                    Quote.Account__c => testApproval.Account__c,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        testApproval.Quote__c = testActiveQuote.Id;
        update testApproval;
        Triggers.switchOn();

        Test.startTest();
            List<Approval__c> approvalsByQuoteIdsAndRecordTypeName = (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByQuoteIdsAndRecordTypeName(new Set<Id> {testActiveQuote.Id}, ApprovalHelper.RT_NAME_ENGAGE_LEGAL)
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, approvalsByQuoteIdsAndRecordTypeName.size(), ASSERT_MESSAGE);
        System.assertEquals(testApproval.Name, approvalsByQuoteIdsAndRecordTypeName[0].Name, 'Wrong approval was retrieved');
    }

    @IsTest
    static void testSelectCreditLimitIncreaseById() {
        Approval__c creditLimitApproval = (Approval__c) new ApprovalSelector()
                .selectApprovals()
                .setCondition('Name = \'Credit Limit Increase\'')
                .setLimit(1)
                .executeQuery()
                .get(0);

        List<Approval__c> creditLimitApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectCreditLimitIncreaseById(new List<Object>{
                new Set<Id>{creditLimitApproval.Id}
            })
            .executeQuery();

        System.assertEquals(1, creditLimitApprovals.size(), 'Should select 1 approval');
    }

    @IsTest
    static void testSelectCreditLimitIncreaseByAccountIdByStatus() {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> approvedCreditLimitApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectCreditLimitIncreaseByAccountIdByStatus(new List<Object>{new Set<Id>{approvals[7].Account__c}, new Set<String>{ApprovalHelper.STATUS_APPROVED}})
            .executeQuery();

        System.assertEquals(1, approvedCreditLimitApprovals.size(), 'List of approvals must have one record');
    }

    @IsTest
    static void testSelectCreditLimitIncreaseApproved() {
        List<Approval__c> approvedCreditLimitApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectCreditLimitIncreaseApproved()
            .executeQuery();

        System.assertEquals(1, approvedCreditLimitApprovals.size(), 'List of approvals must have one record');
    }

    @IsTest
    static void testSelectCreditLimitIncreaseByAccountId() {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovals()
            .executeQuery();

        List<Approval__c> newCreditLimitApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectCreditLimitIncreaseByAccountId(new List<Object>{approvals[8].Account__c})
            .executeQuery();

        System.assertEquals(1, newCreditLimitApprovals.size(), 'List of approvals must have one record');
    }

    @IsTest
    static void testSelectApprovalsForAccountsByRTSortedByApprovedDate() {
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        QueryFactory qf = new ApprovalSelector()
            .selectApprovalsForAccountsByRTSortedByApprovedDate(
                new List<Object> {
                    ApprovalHelper.RT_ID_POC_ACCOUNT,
                    new Set<Id>{ accounts[0].Id }
                }
            )
            .setQuery();
        String query = qf.getQuery();

        System.assert(
            query.contains('RecordTypeId = :bind0 AND Account__c IN :bind1 AND Status__c = \'Approved\' AND IsMultiProductTechnicalApproval__c = false'),
            'Wrong SOQL filter'
        );
        System.assert(query.contains('ORDER BY StatusLastModifiedDate__c DESC'), 'Wrong SOQL ordering');

        List<Approval__c> approvalsForAccountsByRTSortedByApprovedDate = (List<Approval__c>) qf.executeQuery();

        System.assertEquals(1, approvalsForAccountsByRTSortedByApprovedDate.size(), ASSERT_MESSAGE);
        System.assertEquals(ApprovalHelper.RT_ID_POC_ACCOUNT, approvalsForAccountsByRTSortedByApprovedDate[0].RecordTypeId, ASSERT_MESSAGE);
    }
}