@isTest
public class DQ_PendingApprovalController_Test {
	 @testSetup static void setup() {
        DQApprovalTestDataFactory.generateDealQualificationWithConfig();
    }
    private static List<DQ_Deal_Qualification__c> getDealQualification() {
        return [SELECT Id,Brand__c,Deal_Type__c,Region__c,IsDQCreatedFromCPQOpp__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c, Sub_Region__c,
                Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c, Justification_Description__c
                FROM DQ_Deal_Qualification__c ];
    }

    @isTest
    private static void testGetApproversForRejectedDQ() {
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        Test.startTest();
            DQ_DealQualificationController.submitForApprovalForDealQualification(
            listOfDealQualification.get(0).Id, listOfDealQualification.get(0).Opportunity__c, listOfDealQualification.get(0));
            List<DQ_Deal_Qualification_Approver__c> dqApproverList = new DealQualificationApproverSelector()
                .selectDQApprovers(listOfDealQualification.get(0).Id)
                .executeQuery();
            System.assert(dqApproverList.size() > 0, 'No approvers for DQ');
            System.assertEquals(DQGoa.APPROVER_NOTIFICATION_TYPE_PENDING, dqApproverList[0].Status__c, 'Approvers should be pending approval');
            DQ_PendingApprovalController.loadPendingApproval();
            DQ_PendingApprovalController.rejectApproveAction(new List<String>{dqApproverList[0].Id},'Reject','test reject');
            List<DQ_Deal_Qualification_Approver__c> newDQApproverList = new DealQualificationApproverSelector()
                .selectDQApprovers(listOfDealQualification.get(0).Id)
                .executeQuery();
            System.assertEquals(DQ_PendingApprovalController.REJECTED_STATUS, newDQApproverList[0].Status__c, 'Approvers should be rejected!');
        Test.stopTest();
    }

     @isTest
    private static void testGetApproversForApprovedDQ() {
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        Test.startTest();
            DQ_DealQualificationController.submitForApprovalForDealQualification(
            listOfDealQualification.get(0).Id, listOfDealQualification.get(0).Opportunity__c, listOfDealQualification.get(0));
            List<DQ_Deal_Qualification_Approver__c> dqApproverList = new DealQualificationApproverSelector()
                .selectDQApprovers(listOfDealQualification.get(0).Id)
                .executeQuery();
            System.assert(dqApproverList.size() > 0, 'No approvers for DQ');
            System.assertEquals(DQGoa.APPROVER_NOTIFICATION_TYPE_PENDING, dqApproverList[0].Status__c, 'Approvers should be pending approval');
            DQ_PendingApprovalController.loadPendingApproval();
            DQ_PendingApprovalController.rejectApproveAction(new List<String>{dqApproverList[0].Id},'Approve','test approve');
            List<DQ_Deal_Qualification_Approver__c> newDQApproverList = new DealQualificationApproverSelector()
                .selectDQApprovers(listOfDealQualification.get(0).Id)
                .executeQuery();
            System.assertEquals(DQGoa.APPROVED_STATUS, newDQApproverList[0].Status__c, 'Approvers should be approved!');
        Test.stopTest();
    }
}