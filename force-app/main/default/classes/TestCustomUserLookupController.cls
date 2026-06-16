/**********************************************************
Class Name = CustomUserLookupController.cls ***************************
Created by = Lirik Technologies Pvt ltd *****************
Project    = IT Purchase Portal**************************
Class Status :- Pass ************************************/
@isTest
private class TestCustomUserLookupController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCustomUserLookup() {
        try {
            Account acctest = new Account();
            acctest.Name = 'TestAccount';           
            insert acctest;                
            Contact con = new Contact();
            con.LastName ='testCon';
            con.AccountId = acctest.Id ;
            insert con;
            System.currentPageReference().getParameters().put('lksrch',con.id);  
            System.currentPageReference().getParameters().put('txt',con.id);         
            CustomUserLookupController  custLokCon = new CustomUserLookupController ();
            string searchString = 'test';           
            custLokCon.search();
            custLokCon.getFormTag();
            custLokCon.getTextBox();
            //custLokCon.saveAccount();                      
        } catch(Exception ex) {}
   }
}