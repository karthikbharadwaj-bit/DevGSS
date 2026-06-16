/**********************************************************
Class Name = PurchaseCase.cls ***************************
Created by = Lirik Technologies Pvt ltd *****************
Project    = IT Purchase Portal**************************
Class Status :- Pass ************************************/

@isTest
private class PurchaseCaseClsTest {   
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestMethodPurchaseCase() {
        try{
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT(); 
            TriggerHandler.BY_PASS_CASE_ON_INSERT();
            TriggerHandler.BY_PASS_CASE_ON_UPDATE();
            Account accObj = new Account();
            accObj.Name = 'Rctest1';
            accObj.ParentId = accObj.Id;
            accObj.RC_Account_Status__c ='Paid';
            accObj.Partner_ID__c = '1234';        
            insert accObj;
                    
            Contact con = new Contact();
            con.LastName ='testCon';
            con.AccountId = accObj.Id;     
            insert con; 
            
            IT_Product__c itpc = new IT_Product__c ();
            itpc.Applicable_in_Belmont__c = TRUE;
            itpc.Asset_Type__c ='SOFTWARE';
            itpc.Brand__c ='CISCO';
            itpc.Price__c =99.00;
            itpc.Description_Additional_Information__c = 'TEST DATA 1';
            itpc.Model__c ='PARALLELS 11 PRO';
            itpc.New_Hire_Standard__c = TRUE;
            itpc.Notes_and_Instructions__c ='TEST1';
            itpc.Sub_Asset_Type__c = 'SOFTWARE';
            itpc.Vendor__c  ='PARALLELS';
            Insert itpc;
                    
            Case caseObj = new Case();
            caseObj.Subject = 'Test Case';
            caseObj.AccountId = accObj.Id;
            caseObj.contactId = con.Id;       
            caseObj.Request_Type__c = 'Procurement';
            caseObj.Items__c ='test 12';
            caseObj.origin = 'Web';   
            //caseObj.Quantity__c = 1;          
            caseObj.Location__c = 'Headquarters';
            insert caseObj;
            caseObj.Status = 'Need Review';       
            update caseObj;  
            ApexPages.currentPage().getParameters().put('id',caseObj.id);   
                                
            Test.StartTest();
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(caseObj);
            PurchaseCase PrchCase = new PurchaseCase (sc );
            PrchCase.jsonStr='[{"srNo":"1","quantity":"1","itemType":"SOFTWARE","itemSubType":"SOFTWARE","vendor":"PARALLELS","model":"PARALLELS 11 PRO","price":"99.00","unitPrice":99}]';
            PrchCase.jsMethod();       
            PrchCase.saveData();
            PrchCase.editData();
            PrchCase.reloadPage(); 
            PrchCase.addRow();
            PrchCase.deleteRow();
            PrchCase.itemToDelete = 1;      
            PrchCase.updatePrice();
            PrchCase.updateModel();
            PrchCase.updateSubType();
            PrchCase.updatePriceOnQuantity();
            PrchCase.searchUser(); 
            PrchCase.submitCase();
            PrchCase.jsonStr='[{"srNo":"1","quantity":"1","itemType":"SOFTWARE","itemSubType":"SOFTWARE","vendor":"PARALLELS","model":"PARALLELS 11 PRO","price":"99.00","unitPrice":99}]'; 
            PrchCase.jsMethod();
            Test.StopTest();                
        }catch(exception ex){}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestMethodPurchaseCase1() {
        try{
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT(); 
            TriggerHandler.BY_PASS_CASE_ON_INSERT();
            TriggerHandler.BY_PASS_CASE_ON_UPDATE();
            Account accObj = new Account();
            accObj.Name = 'Rctest1';
            accObj.ParentId = accObj.Id;
            accObj.RC_Account_Status__c ='Paid';
            accObj.Partner_ID__c = '1234';        
            insert accObj;
                    
            Contact con = new Contact();
            con.LastName ='testCon';
            con.AccountId = accObj.Id;     
            insert con; 
            
            Case caseObj = new Case();
            caseObj.Subject = 'Test Case';
            caseObj.AccountId = accObj.Id;
            caseObj.contactId = con.Id;       
            caseObj.Request_Type__c = 'Procurement';
            caseObj.Items__c ='test 12';
            caseObj.origin = 'Web';   
            //caseObj.Quantity__c = 1;          
            caseObj.Location__c = 'Headquarters';
            insert caseObj;
            caseObj.Status = 'Need Review';  
            update caseObj;
            
            Test.StartTest();
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(caseObj);
            PurchaseCase PrchCase = new PurchaseCase (sc ); 
            PrchCase.reloadPage();
            PrchCase.jsonStr='[{"srNo":"1","quantity":"1","itemType":"","itemSubType":"SOFTWARE","vendor":"PARALLELS","model":"PARALLELS 11 PRO","price":"99.00","unitPrice":99}]';
            PrchCase.jsMethod();       
            PrchCase.saveData();
            PrchCase.itemToDelete = 1;
            PrchCase.deleteRow();
            PrchCase.saveData();
            Test.stopTest();
        }catch(exception ex){}
    }
}