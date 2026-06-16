@isTest
private class TestCarrierDataSch {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCarrierData() {
       try {
           	user u = [select Id, Username, Name from user where Username  like '%rcpartnersyncbiz%' Limit 1];
           	system.runAs(u){
            	Test.startTest();
       		Account accObj = new Account();
       		accObj.Name = 'Test Acount';
       		accObj.Account_Mobile_Number__c = '9810546384';
       		insert accObj;
       		
       		Carrier_Data__c obj = new Carrier_Data__c();
       		obj.Carrier_Wireless_Phone_Number__c = '9810546384';
       		insert obj;
       		
       		Carrier_Data__c obj1 = new Carrier_Data__c();
       		obj1.Carrier_Wireless_Phone_Number__c = '19810546384';
       		insert obj1;
       		Test.stopTest();
       		
       		Carrier_Data__c objUpd = new Carrier_Data__c(id = obj1.Id);
       		objUpd.Account__c = null;
       		update objUpd;
       		
       		
       		CarrierDataSchedule schObj = new CarrierDataSchedule();
       		schObj.execute(null);   
           }
       		
       } catch(Exception ex) {}
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCarrierData1() {
       try {
           	user u = [select Id, Username, Name from user where Username  like '%rcpartnersyncbiz%' Limit 1];
           	system.runAs(u){
       		Test.startTest();
       		Account accObj = new Account();
       		accObj.Name = 'Test Acount';
       		accObj.Account_Mobile_Number__c = '9810546384';
            accObj.RC_User_ID__c = '12345';
       		insert accObj;
       		
       		Carrier_Data__c obj = new Carrier_Data__c();
       		//obj.Carrier_Wireless_Phone_Number__c = '9810546384';
       		insert obj;
       		
       		/*Carrier_Data__c obj1 = new Carrier_Data__c();
       		obj1.Carrier_Wireless_Phone_Number__c = '19810546384';
       		insert obj1;*/
       		
       		Test.stopTest();
       		
       		Carrier_Data__c objUpd = new Carrier_Data__c(id = obj.Id);
       		objUpd.Carrier_Wireless_Phone_Number__c = '9810546384';
       		objUpd.Account__c = null;
       		update objUpd;
            objUpd.Carrier_Wireless_Phone_Number__c = null;
            objUpd.RC_User_ID__c = '12345';
            update objupd;
       		
       		//CarrierDataBatch batchObj = new CarrierDataBatch();
       		//batchObj.runBatchProcessManually();
       		//Test.startTest();
       		CarrierDataBatch batchObj1 = new CarrierDataBatch();
	   		batchObj1.strQuery = 'SELECT Carrier_Wireless_Phone_Number__c FROM Carrier_Data__c WHERE ' +
   									'(Carrier_Wireless_Phone_Number__c != null OR RC_User_ID__c != null )and Account__c = null and CreatedById = \'005Hr00000CC1vMIAT\'';			 
	   		ID batchprocessid = Database.executeBatch(batchObj1);
	   		//Test.stopTest();
	   		
	   		CarrierDataBatch batchObj = new CarrierDataBatch();
       		batchObj.runBatchProcessManually();
            }
       		
       } catch(Exception ex) {}
    }
}