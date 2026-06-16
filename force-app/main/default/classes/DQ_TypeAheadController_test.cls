@isTest
public class DQ_TypeAheadController_test {
    @testSetup static void setup() {
        //Insert Account
    	Account ObjAcc = new Account();
        ObjAcc.Name = 'Test 1';
        insert ObjAcc;     
        // insert Opp
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'Test 1';
        objOpp.StageName = '7. Closed Won';
        objOpp.CloseDate = System.today();
        insert objOpp;
        // generate step..
        List<DQ_Approval_Step__c> objDQApprovalStepList = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        objDQApprovalStepList[0].Name = 'Level 1';
        insert objDQApprovalStepList;
        
        //Generate generateDQApprovalType
        //Integer noOfRecords,Boolean IsActive,String ProductCatagory,String approvalType, Integer threshold
        List<DQ_Approval_Type__c> objDQApprovalTypeList = DQApprovalTestDataFactory.generateDQApprovalType(1,true,'GOA_Devices','Discount',40);
    	insert objDQApprovalTypeList;
        //generateDQApprovalTypeAndStep
        //Integer noOfRecords,String approvalTypeId,String approvalStepId,String brand, Integer quantiythreshold, 
         //String dealType,String region,String segment,Integer discountThreshold
        List<DQ_Approval_Type_Step__c> objApprovalTypeStepList = DQApprovalTestDataFactory.generateDQApprovalTypeAndStep(1,
                                                         objDQApprovalTypeList[0].Id,objDQApprovalStepList[0].Id,'Avaya Cloud Office',
                                                         40,'Direct','EU','Small Business',40);
        insert objApprovalTypeStepList;
        
        //List<DQ_Approval_Step_Approver__c> generateDQApprovalStepApprover
        //Integer noOfRecords,String approvalStepId,String brand, String approvalType,String dealType,String region,String segment
        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(1,
                                                                           objDQApprovalStepList[0].Id,'Avaya Cloud Office','Approval','Direct','EU','Small Business');
    	insert objDQApprovalStepApproverList;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	public static void fetchLookUpValues_Test() {
        List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;
            
            insert packageList;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;
        List < sObject > sobjectList = DQ_TypeAheadController.fetchLookUpValues('Test','Product_Catalogue__c','Devices',packageList[0].Id,false,null);
        List<Account> listOfAccount = [SELECT Id FROM Account];
        DQ_TypeAheadController.getSelectedRecord(productList[0].Id,'Product_Catalogue__c',false,null);
    }
    
}