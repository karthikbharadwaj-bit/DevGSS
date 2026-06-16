@isTest
private class Test_AssetTriggerHelper {
	@testSetup static void setup(){
		Account testAcc = new Account(Name = 'testAcc');
		insert testAcc;
	}

	@isTest 
	//Is used to test if Active__c field value is changed when delivered quantity becomes equal to quantity
	static void test_StatusUpdate() {
		Account testAcc = [SELECT id FROM Account LIMIT 1];
		Asset testAsset1 = new Asset(
			Name = 'TestAsset1',
			AccountId = testAcc.Id,
			Quantity = 5,
			Active__c = true);
		Asset testAsset2 = new Asset(
			Name = 'TestAsset2',
			AccountId = testAcc.Id,
			Quantity = 10,
			Active__c = true);
		Asset testAsset3 = new Asset(
			Name = 'TestAsset3',
			AccountId = testAcc.Id,
			Quantity = 15,
			Active__c = true);
		insert (new List <Asset>{testAsset1, testAsset2, testAsset3});
		//Scenario equal to that when we complete phases
		Test.startTest();
			testAsset1.Delivered_Quantity__c = 5;
			testAsset2.Delivered_Quantity__c = 5;
			testAsset3.Delivered_Quantity__c = 15;
			update (new List <Asset>{testAsset1, testAsset2, testAsset3});
		Test.stopTest();
		//Check Active__c field value
		List <Asset> assetList = [SELECT Id, Active__c, Quantity FROM Asset Order By Quantity]; 
		Boolean status = false;
		for (Asset assetRecord : assetList) {
			System.AssertEquals(assetRecord.Active__c, status);
			status = !status;
		}
	}
}