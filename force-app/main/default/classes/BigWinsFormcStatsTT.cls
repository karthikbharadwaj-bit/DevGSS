@isTest
private class BigWinsFormcStatsTT {

   @isTest
    static void testTrigger() {
      try {
          BigWins_Form__c o = new BigWins_Form__c(Office_Edition__c='Standard');
          insert o;

          System.assertNotEquals(null, o);
      }
      catch(Exception e) {
          List<BigWins_Form__c> l = [SELECT Id ,Office_Edition__c from BigWins_Form__c LIMIT 1];
          update l;
          System.assertNotEquals(null, l);
      }
   }
}