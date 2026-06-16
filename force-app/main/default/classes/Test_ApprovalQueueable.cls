@isTest
public class Test_ApprovalQueueable {
    @IsTest
    static void ApprovalUnit() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Name => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingCountry => ValueProviderBuilder.provideUniqueString()
                })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Contact.FirstName => 'John',
                        Contact.LastName => 'Doe',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'test@test.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                })
            .create()
            .getRecord();

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => System.today().addMonths(1),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Primary_Opportunity_Contact__c => con.Id
                })
            .create()
            .getRecord();

        Test.startTest();
        List<Approval__c> apprs = (List<Approval__c>) new SObjectBuilder(Approval__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Approval__c.RecordTypeId => Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                                .get('Invoicing Request')
                                .getRecordTypeId(),
                        Approval__c.Opportunity__c => opp.Id,
                        Approval__c.Account__c => acc.Id,
                        Approval__c.AccountPayableContact__c => con.Id,
                        Approval__c.Status__c => ApprovalHelper.STATUS_REQUIRED,
                        Approval__c.Potential_Users__c => 1,
                        Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                })
            .quantity(2)
            .create()
            .getRecords();

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(apprs[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result1 = Approval.process(req1);

        Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
        req2.setComments('Submitting request for approval.');
        req2.setObjectId(apprs[1].Id);
        req2.setSubmitterId(UserInfo.getUserId());
        req2.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
        req2.setSkipEntryCriteria(false);
        Approval.ProcessResult result2 = Approval.process(req2);

        Set<Id> approversIds = new Set<Id>{apprs[0].Id, apprs[1].Id};

        List<ProcessInstance> piList = [SELECT TargetObjectId,
        (SELECT OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM Workitems ORDER BY createddate DESC LIMIT 1),
        (SELECT StepStatus, OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM StepsAndWorkitems ORDER BY createddate DESC LIMIT 1)
        FROM ProcessInstance
        WHERE TargetObjectId IN :approversIds ORDER BY createddate ASC];

        List<ProcessInstanceWorkitem> piWorkItemsDelete = new List<ProcessInstanceWorkitem>();

        for (ProcessInstance processObj : piList) {
            if (processObj.Workitems != null && !processObj.Workitems.isEmpty()) {
                piWorkItemsDelete.addAll(processObj.Workitems);
            }
        }

        delete piWorkItemsDelete;

        QueueableBase.enqueJob('ApprovalQueueable', apprs);
        Test.stopTest();

        List<Approval__c> mapApprovals = new List<Approval__c>();
        mapApprovals = getMapApprovals(new List<Id>{apprs[0].id, apprs[1].id});
        Map<Id, String> mapCurrentApprovers = new Map<Id, String>();
        mapCurrentApprovers = getMapCurrentApprovers(apprs);

        System.assertEquals(mapApprovals.get(0).Current_Approver__c, mapCurrentApprovers.get(apprs[0].id));
        System.assertEquals(mapApprovals.get(0).Current_Approver__c, mapCurrentApprovers.get(apprs[1].id));
    }

    private static Map<Id,string> getMapCurrentApprovers(List<Approval__c> lstApproval) {
        List<ProcessInstance> processList = new List<ProcessInstance>();
        processList = getProcessInstance(lstApproval);

        Map<Id,string> currentApproverMap = new Map<Id,string>();
        for (ProcessInstance processObj : processList) {
            if (processObj.Workitems != null && processObj.Workitems.size() > 0) {
                currentApproverMap.put(processObj.TargetObjectId, processObj.Workitems[0].OriginalActor.Name);
            } else if (processObj.StepsAndWorkitems != null && processObj.StepsAndWorkitems.size() > 0) {
                currentApproverMap.put(processObj.TargetObjectId, processObj.StepsAndWorkitems[0].OriginalActor.Name);
            }
        }
        return currentApproverMap;
    }

    private static List<ProcessInstance> getProcessInstance(List<Approval__c> lstApproval) {
        return [SELECT TargetObjectId,
                        (SELECT OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM Workitems order by createddate desc limit 1),
                        (SELECT StepStatus, OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM StepsAndWorkitems order by createddate desc limit 1)
                        FROM ProcessInstance
                        WHERE TargetObjectId IN :lstApproval order by createddate asc];
    }

    private static List<Approval__c> getMapApprovals(List<Id> lstIdApprovals) {
        List<Approval__c> queryResult = new List<Approval__c>();
        if (lstIdApprovals.isEmpty()) {
            return queryResult;
        }
        List<Object> bindings = new List<Object>();
        bindings.add(lstIdApprovals);
        ApprovalSelector getApprovalInfo = new ApprovalSelector();
        queryResult.addAll((List<Approval__c>) getApprovalInfo
                                                   .selectApprovalCurrentApprover(bindings)
                                                   .executeQuery());
        return queryResult;
    }
}