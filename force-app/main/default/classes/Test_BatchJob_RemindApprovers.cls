@isTest
public with sharing class Test_BatchJob_RemindApprovers {


    @isTest 
    private static void TestBatch() {

        User user = new User(
            Alias = 'test123', 
            Email = 'test@nemail.com',
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Test', 
            LastName = 'Johnathanpop', 
            LanguageLocaleKey = 'en_US',
            LocalesIdKey = 'en_US', 
            ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN, 
            Country = 'United States',
            IsActive = true,
            TimezonesIdKey = 'America/Los_Angeles', 
            UserName = 'tester@noema.com'
        );

        insert user;

        String userName = user.FirstName + ' ' + user.LastName;

        new SObjectBuilder(Bill_On_Behalf_Approvers__c.SObjectType)
            .setField(Bill_On_Behalf_Approvers__c.Name, 'Level 1')
            .setField(Bill_On_Behalf_Approvers__c.Approver_Level__c, 1)
            .setField(Bill_On_Behalf_Approvers__c.User_Name__c, userName)
            .setField(Bill_On_Behalf_Approvers__c.User_Id__c, user.Id)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Partner_Type__c, AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF)
            .setField(Account.PartnerStatus__c, AccountHelper.NEW_STATUS)
            .create()
            .getRecord();

        ApprovalHelperCls.PartnerApprovalWrapper wrapper = new ApprovalHelperCls.PartnerApprovalWrapper();
        Id approvalId;
        wrapper = ApprovalHelperCls.checkPartnerAccount(acc.Id);
        if (wrapper.isValid) {
            wrapper.accountId = acc.Id;
            wrapper.partnerMRR = 566;
            approvalId = ApprovalHelperCls.createPartnerApproval(wrapper);
        }
        
        //test finance approval reminder
        insert new Attachment(
            parentId = approvalId,
            Name = 'bob test draft',
            body = Blob.toPdf('bob test draft pdf')
        );
        List<Approval__c> approvals = [select id, Status__c, Current_Approver__c, (SELECT Id FROM Attachments), (SELECT Id FROM ContentDocumentLinks) from approval__c];
        System.debug('approvals >>>>> ' + approvals);
        approvals[0].Status__c = 'Pending Finance Approval';

        Test.startTest();
        
            Integer emailLimitBefore = Limits.getEmailInvocations();
            BatchJob_RemindApprovers batch = new BatchJob_RemindApprovers(true);
            batch.start(null);
            batch.execute(null, approvals);
            batch.finish(null);

            approvals[0].Status__c = 'Pending L1 Approval';
            approvals[0].Current_Approver__c = 'Billing Credit Check';

            batch = new BatchJob_RemindApprovers(true);
            batch.start(null);
            batch.execute(null, approvals);
            batch.finish(null);

            approvals[0].Status__c = 'Pending L2 Approval';
            approvals[0].Current_Approver__c = 'Test Johnathanpop';

            batch = new BatchJob_RemindApprovers(true);
            batch.start(null);
            batch.execute(null, approvals);
            batch.finish(null);
        
        Test.stopTest();
        System.assertNotEquals(emailLimitBefore, Limits.getEmailInvocations(), 'Reminders not sent');
    }
}