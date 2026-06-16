@isTest
public class DQ_AutoApproveEngine_Test {

    @testSetup static void setup() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
		System.runAs(thisUser) {
            Group testGroup = new Group(Name='test group', Type='Queue');
            insert testGroup;

            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'DQ_Deal_Qualification_Approver__c');
            insert testQueue;

            GroupMember member = new GroupMember();
            member.UserOrGroupId = userinfo.getUserId();
            member.GroupId = testGroup.Id;
            insert member;

            DQApprovalTestDataFactory.generateDealQualificationWithConfig();
        }
    }

    private static List<DQ_Deal_Qualification__c> getDealQualification() {
        return [SELECT Id,Brand__c,Deal_Type__c,Region__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c, Sub_Region__c,
                Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c, Justification_Description__c, IsDQCreatedFromCPQOpp__c
                FROM DQ_Deal_Qualification__c];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testUpdateDelegateEmail() {
        User delegatedApprover = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.UserPreferencesReceiveNotificationsAsDelegatedApprover => true,
                User.Email => 'test@ringcentral.com'
            })
            .create()
            .getRecord();

        User approver = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.DelegatedApproverId => delegatedApprover.Id
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Level 1'
            })
            .create()
            .getRecord();

        Test.startTest();
        DQ_Deal_Qualification_Approver__c testDqApproverRecord = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Status__c => 'Inactive',
                DQ_Deal_Qualification_Approver__c.Approval_Step__c => testDqApprovalStepRecord.Id,
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.OwnerId => approver.Id
            })
            .create()
            .getRecord();
        
        DQ_Deal_Qualification_Approver__c testDqApproverRecordApproved = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Status__c => 'Approved',
                DQ_Deal_Qualification_Approver__c.Approval_Step__c => testDqApprovalStepRecord.Id,
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.OwnerId => approver.Id
            })
            .create()
            .getRecord();

        testDqApproverRecord = (DQ_Deal_Qualification_Approver__c) new ListOptional(new DealQualificationApproverSelector()
            .selectDQApprovers(testDqRecord.Id)
            .selectFields(new List<String> {'Delegate_Email__c'})
            .executeQuery()
        ).getFirst();

        List<Id> queueMembers = new List<Id>{UserInfo.getUserId()}; 
        List<Id> approvedUsers = new List<Id>{approver.Id};
        DQ_AutoApproveEngine.ifApprovedUserBelongsToQUeue(queueMembers, approvedUsers);
        
        System.assertEquals(testDqApproverRecord.Delegate_Email__c, 'test@ringcentral.com');
        Test.stopTest();
        
        testDqApproverRecord.Status__c = 'Pending';
        update testDqApproverRecord;
    }
}