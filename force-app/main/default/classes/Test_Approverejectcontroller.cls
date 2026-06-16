@istest
public class Test_Approverejectcontroller {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testItemstoApprove(){

        Triggers.switchOff();

        SObjectFactory factory = new SObjectFactory();

        Account acc = (Account) factory
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {
                    Account.BillingStreet => 'TestStreet',
                    Account.BillingCity => 'Test',
                    Account.BillingState => 'AZ',
                    Account.BillingPostalCode => '123564',
                    Account.BillingCountry => 'US'
                }
            );

        Opportunity opportunity = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CloseDate => System.today()
                }
         );

        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        System.debug('sysAdmin user ID : '  + sysAdmin.Id);
        System.debug('Current user ID : '  + UserInfo.getUserId());

        Approval__c app = new Approval__c();
            app.Account__c= acc.id;
            app.Opportunity__c = opportunity.Id;
            app.Name='Test Approval';
            app.Level1Approver__c=sysAdmin.Id;
            app.JustificationandDescription__c='Test';
            app.Amount__c =2000;
            app.Category__c='Account Closed';
            app.RecordTypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Secondary DL').getRecordTypeId();
            app.Refund_Product_Family_1__c='RC Legacy';
            app.Refund_Ref_ID_1__c='Test';
            app.Status__c = 'Required';

        insert app;

        Triggers.switchOn();

        try{
            update new Opportunity(Id = app.Opportunity__c, Special_TOS_Approval__c = app.Id);
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(app.Id);
            req.setSubmitterId(UserInfo.getUserId());
            req.setProcessDefinitionNameOrId('ApprovalProcessForSecondaryDL');
            Approval.process(req);
        } catch (DmlException ex) {
            system.debug(ex.getDmlMessage(0));
        }

        List<ProcessInstanceWorkItem> approvalItems = [SELECT ID ,ActorId,CreatedDate FROM ProcessInstanceWorkItem];
        System.debug('Process items : ' + approvalItems);

        if(!approvalItems.isEmpty()){
            ProcessInstanceWorkItem apItem = approvalItems[0];
            apItem.ActorId = UserInfo.getUserId();
            update apItem;
        }

        Approverejectcontroller.getSubmittedRecords(true,5);
        Approverejectcontroller.getSubmittedRecords(false,5);

        String processType = 'Approve';
        List<string> lstWorkItemIds = new List<string>();
        for(ProcessInstanceWorkItem apItem : approvalItems){
            lstWorkItemIds.add(apItem.Id);
        }

        Approverejectcontroller.processRecords(lstWorkItemIds,processType);

        Approverejectcontroller.getObjectName(app.id);
        Approverejectcontroller.SubmittedRecordsWrapper  testwrap = new Approverejectcontroller.SubmittedRecordsWrapper();
        testwrap.workItemId = (Id) new ValueProvider.DummyIdProvider(ProcessInstanceWorkitem.sObjectType).getValue();
        testwrap.recordId = 'app1.id';
        testwrap.relatedTo = 'Test';
        testwrap.recordName ='Test';
        testwrap.submittedBy = 'Test123';
        testwrap.submittedDate = '02/01/2021 11:32 AM';

    }



}