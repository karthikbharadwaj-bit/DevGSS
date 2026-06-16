@isTest
public with sharing class Test_ApprovalValidator {

    @isTest
    private static void signupValidatorNewBusinessTestPositive() {

        new SObjectBuilder(DirectDebitApprovalThreshold__c.sObjectType)
            .setField(DirectDebitApprovalThreshold__c.Name, 'RC')
            .setField(DirectDebitApprovalThreshold__c.Brand__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(DirectDebitApprovalThreshold__c.Currency__c, 'SGD')
            .setField(DirectDebitApprovalThreshold__c.ThresholdValue__c, 10000)
            .create();


        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c, true)
            .create();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'Test Singapore Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'SGD'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                Quote.Total_MRR_with_Taxes__c => 1000,
                Quote.Total_One_Time_with_Taxes__c => 1000,
                Quote.Total_ARR_with_Taxes__c => 1000
            })
            .create()
            .getRecord();

        Quote reselected = (Quote) new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectQuotesForPrimaryProcess')
            .selectFields(getFieldsForReselectedQuoteForNewBusiness())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {qt.Id})
            .executeQuery()
            .get(0);

        Validator directDebitSignUpValidator;
        Response resp;

        Test.startTest();

            directDebitSignUpValidator =
                new ApprovalValidator.DirectDebitThresholdValidator(reselected, true, QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT, ApprovalValidator.SIGN_UP);
            resp = directDebitSignUpValidator.validate(new Response());
            System.assertEquals(
                0,
                resp.messages.size()
            );

        Test.stopTest();
    }

    @isTest
    private static void signupValidatorNewBusinessTestNegative() {

        new SObjectBuilder(DirectDebitApprovalThreshold__c.sObjectType)
            .setField(DirectDebitApprovalThreshold__c.Name, 'RC')
            .setField(DirectDebitApprovalThreshold__c.Brand__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(DirectDebitApprovalThreshold__c.Currency__c, 'SGD')
            .setField(DirectDebitApprovalThreshold__c.ThresholdValue__c, 100)
            .create();


        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c, true)
            .create();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'Test Singapore Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'SGD'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                Quote.Total_MRR_with_Taxes__c => 1000,
                Quote.Total_One_Time_with_Taxes__c => 1000,
                Quote.Total_ARR_with_Taxes__c => 1000
            })
            .create()
            .getRecord();

        Quote reselected = (Quote) new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectQuotesForPrimaryProcess')
            .selectFields(getFieldsForReselectedQuoteForNewBusiness())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {qt.Id})
            .executeQuery()
            .get(0);

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, testAcc.Id)
            .setField(Approval__c.Status__c, 'Pending Approval')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST)
            .build()
            .getRecord();

        Validator directDebitSignUpValidator;
        Response resp;

        Test.startTest();

            directDebitSignUpValidator =
                new ApprovalValidator.DirectDebitThresholdValidator(reselected, false, QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT, ApprovalValidator.SIGN_UP);
            resp = directDebitSignUpValidator.validate(new Response());
            System.assertEquals(
                1,
                resp.messages.size(),
                'ApprovedInvoiceValidator should throw an error when Payment method is Invoice and there are pending Invoice approvals'
            );

        Test.stopTest();
    }

    @isTest
    private static void verifyDirectDebitLimitValidationNewBusiness() {
        new SObjectBuilder(DirectDebitApprovalThreshold__c.sObjectType)
            .setField(DirectDebitApprovalThreshold__c.Name, 'RC')
            .setField(DirectDebitApprovalThreshold__c.Brand__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(DirectDebitApprovalThreshold__c.Currency__c, 'SGD')
            .setField(DirectDebitApprovalThreshold__c.ThresholdValue__c, 100)
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c => true
            })
            .create();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'Test Singapore Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'SGD'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Total_ARR_with_Taxes__c => 1000,
                Quote.Total_MRR_with_Taxes__c => 10000,
                Quote.Total_One_Time_with_Taxes__c => 200000,
                Quote.Payment_Period__c => 'Monthly Payment Period',
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Quote reselecQt = (Quote) new QuoteSelector()
            .newQueryFactory()
            .selectFields(new List<String> {
                'PaymentMethod__c',
                'RecordTypeId',
                'Total_ARR_with_Taxes__c',
                'Total_MRR_with_Taxes__c',
                'Total_One_Time_with_Taxes__c',
                'isPrimary__c',
                'Brand__c',
                'CurrencyIsoCode',
                'Payment_Period__c',
                'PackageNameOld__c',
                'BillingPackage__c',
                'Upsell_Status__c',
                'Account.RC_User_ID__c',
                'Account.Billing_ID__c'
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {qt.Id})
            .executeQuery()
            .get(0);

        Response response = new ApprovalValidator.DirectDebitLimitValidation(reselecQt, QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT, ApprovalValidator.CLOSE)
            .validate(new Response());

        System.assertEquals(
            Label.Approval_Direct_Debit_Limit_Error,
            response.messages[0].messageDetails
        );
    }

    private static Set<String> getFieldsForReselectedQuoteForNewBusiness() {
        return new Set<String> {
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'Total_ARR_with_Taxes__c',
            'Brand__c',
            'CurrencyIsoCode',
            'PackageNameOld__c',
            'BillingPackage__c',
            'PaymentMethod__c',
            'Payment_Period__c',
            'Account.RC_User_ID__c',
            'Account.Billing_ID__c',
            'Upsell_Status__c'
        };
    }
}