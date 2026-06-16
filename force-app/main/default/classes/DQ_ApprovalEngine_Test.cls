@isTest
public class DQ_ApprovalEngine_Test {
    @testSetup static void setup() {
        DQApprovalTestDataFactory.generateDealQualificationWithConfig();
    }

    private static List<DQ_Deal_Qualification__c> getDealQualification() {
        return [SELECT Id,Brand__c,Deal_Type__c,Region__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c, Sub_Region__c,
                Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c, Justification_Description__c
                FROM DQ_Deal_Qualification__c ];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQTest() {
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        DQ_ApprovalEngine1.getApproversForDQ(listOfDealQualification.get(0).Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQRejectedTest() {
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',oppId);
        insert objDQ;
        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));
        Test.startTest();
        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :listOfDealQualification.get(0).Id];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Rejected';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);


        DQ_ApprovalEngine1.getApproversForDQ(listOfDealQualification.get(0).Id);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQNewTest() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',oppId);
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

            objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        update objDQ.get(0);

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Rejected';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);
        Test.stopTest();

        DQ_ApprovalEngine1.getApproversForDQ(listOfDealQualification.get(0).Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQNewSubmitTest() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',oppId);
        objDQ.get(0).Status__c = 'Pending Approval';
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Pending'];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Approved';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);


        objDQ.get(0).Initial_Term__c = '24';
        objDQ.get(0).Status__c = 'Pending Approval';
        objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        update objDQ;
        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));
        listOfDQApprover =  [SELECT Id, Status__c, Approved_By__c, APproval_Step__r.Name FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id ];
        //SYstem.assert(false, listOfDQApprover);
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Approved';
            update listOfDQApprover;
        }

        listOfDQApprover =  [SELECT Id, Status__c, Approved_By__c, Approval_Step__r.Name FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Inactive'];
        //SYstem.assert(false,listOfDQApprover );
         if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Inactive';
            update listOfDQApprover;
        }

        update listOfDQApprover;
        DQ_ApprovalMainHelper.getNextLevelStepOrderForApproval(new Map<Id, Integer> {objDQ.get(0).Id => 1});
        Test.stopTest();
        DQ_ApprovalEngine1.getApproversForDQ(objDQ.get(0).Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQNewSubmitTest2() {
        Test.startTest();

        List<DQ_Approval_Step__c> listDQApprStep = [Select Id, Name from DQ_Approval_Step__c];

        List<DQ_Approval_Type__c> listDQApprType = [Select Id, Name, Approval_type__c, Product_Category__c from DQ_Approval_Type__c];
        List<DQ_Approval_Type__c> listDQApprType1 = new List<DQ_Approval_Type__c>();
        DQ_Approval_Type__c dqApprType1 = new DQ_Approval_Type__c();
        dqApprType1.Product_Category__c = 'EES';
        dqApprType1.Approval_Type__c = 'Product Removal';
        dqApprType1.isActive__c = true;
        listDQApprType1.add(dqApprType1);
        DQ_Approval_Type__c dqApprType2 = new DQ_Approval_Type__c();
        dqApprType2.Product_Category__c = 'EES-CC';
        dqApprType2.Approval_Type__c = 'Product Removal';
        dqApprType2.isActive__c = true;
        listDQApprType1.add(dqApprType2);
        DQ_Approval_Type__c dqApprType3 = new DQ_Approval_Type__c();
        dqApprType3.Product_Category__c = 'GOA_Devices';
        dqApprType3.Approval_Type__c = 'CC Special Term';
        dqApprType3.Initial_Term_Discount__c = 50;
        dqApprType3.Initial_Term_To_Discount__c = 80;
        dqApprType3.CC_Special_Terms__c = '1 Free Month of Service';
        dqApprType3.isActive__c = true;
        listDQApprType1.add(dqApprType3);
        DQ_Approval_Type__c dqApprType4 = new DQ_Approval_Type__c();
        dqApprType4.Approval_Type__c = 'ELA Standard';
        dqApprType4.isActive__c = true;
        dqApprType4.IsCPQApprovalType__c = true;
        listDQApprType1.add(dqApprType4);
        DQ_Approval_Type__c dqApprType5 = new DQ_Approval_Type__c();
        dqApprType5.Approval_Type__c = 'Total Discount';
        dqApprType5.Threshold__c = 10.01;
        dqApprType5.isActive__c = true;
        listDQApprType1.add(dqApprType5);
        DQ_Approval_Type__c dqApprType6 = new DQ_Approval_Type__c();
        dqApprType6.Approval_Type__c = 'Total Discount';
        dqApprType6.Threshold__c = 10.01;
        dqApprType6.Product_Category__c = 'Overall Discount One-Time';
        dqApprType6.isActive__c = true;
        listDQApprType1.add(dqApprType6);
        DQ_Approval_Type__c dqApprType7 = new DQ_Approval_Type__c();
        dqApprType7.Approval_Type__c = 'Total Discount';
        dqApprType7.Threshold__c = 10.01;
        dqApprType7.Product_Category__c = 'Overall Discount Recurring';
        dqApprType7.isActive__c = true;
        listDQApprType1.add(dqApprType7);
        DQ_Approval_Type__c dqApprType8 = new DQ_Approval_Type__c();
        dqApprType8.Approval_Type__c = 'Total Discount';
        dqApprType8.Threshold__c = 10.01;
        dqApprType8.Product_Category__c = 'Overall Discount Contact Center';
        dqApprType8.isActive__c = true;
        listDQApprType1.add(dqApprType8);

        insert listDQApprType1;

        for(integer i=0; i<8; i++){
            listDQApprType.add(listDQApprType1.get(i));
        }
        update listDQApprType;

        List<DQ_Approval_Type_Step__c> listDQApprTypeStep = [Select id, name, brand__c, deal_type__C, DQ_Approval_step__c,DQ_Approval_Type__c, region__c, segment__c from DQ_Approval_Type_Step__c];
        List<DQ_Approval_Type_Step__c> listDQApprTypeStep1 = new List<DQ_Approval_Type_Step__c>();
        for(Integer i=0;i < 8; i++) {
            DQ_Approval_Type_Step__c objApprovalTypeAndStep = new DQ_Approval_Type_Step__c();
            objApprovalTypeAndStep.Brand__c = 'Avaya Cloud Office';
            objApprovalTypeAndStep.Deal_Type__c = 'Direct';
            objApprovalTypeAndStep.Discount_Threshold__c = 50;
            objApprovalTypeAndStep.Quantity_Threshold__c = 50;
            objApprovalTypeAndStep.Region__c = 'EU';
            objApprovalTypeAndStep.Segment__c = 'SOHO';
            listDQApprTypeStep1.add(objApprovalTypeAndStep);
        }

        listDQApprTypeStep1.get(0).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(0).DQ_Approval_Type__c = dqApprType1.Id;
        listDQApprTypeStep1.get(1).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(1).DQ_Approval_Type__c = dqApprType2.Id;
        listDQApprTypeStep1.get(2).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(2).DQ_Approval_Type__c = dqApprType3.Id;
        listDQApprTypeStep1.get(3).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(3).DQ_Approval_Type__c = dqApprType4.Id;
        listDQApprTypeStep1.get(4).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(4).DQ_Approval_Type__c = dqApprType5.Id;
        listDQApprTypeStep1.get(5).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(5).DQ_Approval_Type__c = dqApprType6.Id;
        listDQApprTypeStep1.get(6).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(6).DQ_Approval_Type__c = dqApprType7.Id;
        listDQApprTypeStep1.get(7).DQ_Approval_Step__c = listDQApprStep[0].Id;
        listDQApprTypeStep1.get(7).DQ_Approval_Type__c = dqApprType8.Id;

        insert listDQApprTypeStep1;
        for(integer i=0; i<8; i++){
            listDQApprTypeStep.add(listDQApprTypeStep1.get(i));
        }
        update listDQApprTypeStep;

        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',oppId);
        objDQ.get(0).Status__c = 'Pending Approval';
        objDQ.get(0).Initial_Term__c = '24';
        objDQ.get(0).CC_Special_Terms__c = '1 Free Month of Service';
        objDQ.get(0).is_ELA__c = 'Yes';
        objDQ.get(0).Overall_Discount__c = 30;
        objDQ.get(0).Overall_Discount_One_Time__c = 20;
        objDQ.get(0).Overall_Discount_Recurring__c = 25;
        objDQ.get(0).Overall_Discount_Contact_Center__c = 23;
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c,Deal_Qualification__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Pending'];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Pending';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);


        objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        update objDQ;

        DQ_ApprovalMainHelper.getNextLevelStepOrderForApproval(new Map<Id, Integer> {objDQ.get(0).Id => 1});
        Test.stopTest();
        DQ_ApprovalEngine1.getApproversForDQ(objDQ.get(0).Id);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    private static void getApproversForDQNewSubmitTest3() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',oppId);
        objDQ.get(0).Status__c = 'Pending Approval';
        //objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c, Deal_Qualification__r.IsDQCreatedFromCPQOpp__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Pending'];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Pending';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);


        objDQ.get(0).Initial_Term__c = '24';
        objDQ.get(0).Status__c = 'Rejected';
        objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        update objDQ;
        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));
        listOfDQApprover =  [SELECT Id, Status__c, Approved_By__c, Approval_Step__r.Name, Deal_Qualification__r.IsDQCreatedFromCPQOpp__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id ];
        //SYstem.assert(false, listOfDQApprover);
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Pending';
            update listOfDQApprover;
        }

        listOfDQApprover =  [SELECT Id, Status__c,Step_Order__c, Deal_Qualification__c, Approved_By__c, Approval_Step__r.Name FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Inactive'];
        //SYstem.assert(false,listOfDQApprover );
         if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Inactive';
            listOfDQApprover.get(0).Deal_Qualification__c = objDQ.get(0).Id;
            update listOfDQApprover;
        }

        update listOfDQApprover;
        DQ_ApprovalMainHelper.getNextLevelStepOrderForApproval(new Map<Id, Integer> {objDQ.get(0).Id => 1});
        Test.stopTest();
        DQ_ApprovalEngine1.getApproversForDQ(objDQ.get(0).Id);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQNewTest2() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id,IsDQCreatedFromCPQOpp__c,Status__c, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',oppId);
        objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c,Step_Order__c, Deal_Qualification__c,Deal_Qualification__r.IsDQCreatedFromCPQOpp__c, Approved_By__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Rejected';
            listOfDQApprover.get(0).Deal_Qualification__c = objDQ.get(0).Id;
            update listOfDQApprover;
        }
        // System.assert(false, listOfDQApprover);
        Test.stopTest();

        DQ_ApprovalEngine1.getApproversForDQ(listOfDealQualification.get(0).Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void getApproversForDQNewSubmitTest4() {
        Test.startTest();

        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        String oppId = listOfDealQualification.get(0).Opportunity__c;

        List<DQ_Deal_Qualification__c> objDQList = [SELECT Id, Opportunity__c FROM  DQ_Deal_Qualification__c WHERE Id =: listOfDealQualification.get(0).Id];
        if(!objDQList.isEmpty()) {
            for (DQ_Deal_Qualification__c eachDQ : objDQList) {
                eachDQ.Opportunity__c = null;
            }
            update objDQList;
        }

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','SOHO',oppId);
        objDQ.get(0).Status__c = 'Pending Approval';
        objDQ.get(0).is_ELA__c ='Yes';
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = oppId;
        quoteList[0].Primary__c = true;
        insert quoteList;


        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));

        List<DQ_Deal_Qualification_Approver__c> listOfDQApprover =
            [SELECT Id, Status__c, Approved_By__c,Deal_Qualification__c FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Pending'];
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Approved';
            update listOfDQApprover;
        }

        // System.assert(false, listOfDQApprover);


        objDQ.get(0).Initial_Term__c = '24';
        objDQ.get(0).Status__c = 'Pending Approval';
        objDQ.get(0).CC_Special_Terms__c = '1 Free Month of Service';
        objDQ.get(0).is_ELA__c = 'Yes';
        objDQ.get(0).IsDQCreatedFromCPQOpp__c = true;
        update objDQ;
        DQ_DealQualificationController.submitForApprovalForDealQualification(
            objDQ.get(0).Id, objDQ.get(0).Opportunity__c, objDQ.get(0));
        listOfDQApprover =  [SELECT Id, Status__c,Step_Order__c, Deal_Qualification__c, Approved_By__c, APproval_Step__r.Name FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id ];
        //SYstem.assert(false, listOfDQApprover);
        if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Pending';
            listOfDQApprover.get(0).Deal_Qualification__c = objDQ.get(0).Id;
            update listOfDQApprover;
        }

        listOfDQApprover =  [SELECT Id, Status__c,Step_Order__c, Deal_Qualification__c, Approved_By__c, Approval_Step__r.Name FROM DQ_Deal_Qualification_Approver__c WHERE Deal_Qualification__c = :objDQ.get(0).Id AND Status__c = 'Inactive'];
        //SYstem.assert(false,listOfDQApprover );
         if (!listOfDQApprover.isEmpty()) {
            listOfDQApprover.get(0).Status__c = 'Inactive';
            listOfDQApprover.get(0).Deal_Qualification__c = objDQ.get(0).Id;
            update listOfDQApprover;
        }

        update listOfDQApprover;
        DQ_ApprovalMainHelper.getNextLevelStepOrderForApproval(new Map<Id, Integer> {objDQ.get(0).Id => 1});
        Test.stopTest();
        DQ_ApprovalEngine1.getApproversForDQ(objDQ.get(0).Id);
    }
}