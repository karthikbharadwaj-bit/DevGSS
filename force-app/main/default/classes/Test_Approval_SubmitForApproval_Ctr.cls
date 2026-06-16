@IsTest
public class Test_Approval_SubmitForApproval_Ctr {

        @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void CreateApproval() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        String text = '1/0';
        List<Account> Acct = new List<Account>();
        List<Approval__c> Applist = new List<Approval__c>();
        Account accObj = new Account();
        accObj.Name = 'Test Account Parent ';
        accObj.Partner_ID__c = '12346';
        Acct.add(accObj);
        Account accObj1 = new Account();
        accObj1.Name = 'Test Account Parent ';
        accObj1.Partner_ID__c = '12346';
        Acct.add(accObj1);
        insert Acct;

        Approval__c app = new Approval__c();
        app.Account__c = accObj.Id;
        app.Name = 'Test Approval';
        app.Level1Approver__c = sysAdmin.Id;
        //app.Approval_Type__c = 'Refund Approval';
        app.JustificationandDescription__c = 'Test';
        app.Amount__c = 2000;
        app.Category__c = 'Account Closed';
        app.RecordTypeId = ApprovalHelper.RT_ID_REFUND_APPROVAL;
        app.Refund_Product_Family_1__c = 'RC Legacy';
        app.Refund_Ref_ID_1__c = 'Test';
        Applist.add(app);
        Approval__c app1 = new Approval__c();
        app1.Account__c = accObj1.Id;
        app1.Name = 'Test Approval1';
        app1.Level1Approver__c = sysAdmin.Id;
        //app.Approval_Type__c = 'Refund Approval';
        app1.JustificationandDescription__c = 'Test1';
        app1.Amount__c = 20000;
        app1.Category__c = 'Account Closed';
        app1.RecordTypeId = ApprovalHelper.RT_ID_REFUND_APPROVAL;
        app1.Refund_Product_Family_1__c = 'RC Legacy';
        app1.Refund_Ref_ID_1__c = 'Test1223';
        Applist.add(app1);
        insert Applist;
        Approval_SubmitForApproval_Controller.submitforApproval(app.id, null);
        Approval_SubmitForApproval_Controller.submitforApproval(app1.id, null);
        Approval_SubmitForApproval_Controller.submitforApproval(text, null);
        Approval_SubmitForApproval_Controller.recallApproval(app.id);
        Approval_SubmitForApproval_Controller.recallApproval(text);

        D_B_Credit_Check__c testDbCreditCheck = (D_B_Credit_Check__c) new SObjectBuilder(D_B_Credit_Check__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        D_B_Credit_Check__c.Approval__c => app.id
                })
                .create()
                .getRecord();
        SubmitForCreditApproval_Controller.validatesubmitforcreditcheck(app.id);
    }

    @IsTest
    private static void testGetInitialData() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                                Account.Partner_ID__c => '1234567',
                                Account.Payment_Method__c => 'Invoice',
                                Account.Payment_Plan__c => 'Monthly',
                                Account.RC_User_ID__c => '400389021061',
                                Account.Billing_ID__c => '5037001'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, testAccount.Id)
                .create()
                .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Account__c => testAccount.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Test.getStandardPricebookId()
                })
                .create()
                .getRecord();

        Test.startTest();
        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Approval__c.Quote__c => qt.Id,
                        Approval__c.Opportunity__c => qt.OpportunityId,
                        Approval__c.Account__c => qt.Account__c,
                        Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                        Approval__c.NGBSAmountToIncrease__c => 40000
                })
                .create()
                .getRecord();
        Test.stopTest();

        Approval_SubmitForApproval_Controller.ResponseWrapper response = Approval_SubmitForApproval_Controller.getInitialData(appr.Id);
        System.assert(response != null, 'Response must be not null');
        System.assert(response.isDisableSubmitButton, 'Response isDisableSubmitButton must be true');



        appr.RecordTypeId = ApprovalHelper.RT_ID_ENGAGE_LEGAL;
        update appr;
        Approval_SubmitForApproval_Controller.ResponseWrapper response2 = Approval_SubmitForApproval_Controller.getInitialData(appr.Id);
        System.assert(response.isDisableSubmitButton == false, 'Response isDisableSubmitButton must be false');
    }

}