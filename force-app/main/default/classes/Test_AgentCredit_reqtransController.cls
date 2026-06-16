@isTest
public class Test_AgentCredit_reqtransController {
    

      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void testTrigger() {
          
     	Account accObj = new Account();
            accObj.Name = 'Test Account Parent ';
            accObj.Partner_ID__c = '12346';
            insert accObj;          
          
      Agent_Credit__c o = new Agent_Credit__c();
          o.Name='Test';
          o.Account__c=accObj.id;
          insert o;
     AgentCredit_RequesttransferController.getCount(o.id);
     AgentCredit_RequesttransferController.getrecord(o.id);
   }

}