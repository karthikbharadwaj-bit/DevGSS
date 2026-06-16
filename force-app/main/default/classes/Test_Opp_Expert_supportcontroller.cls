@istest
public class Test_Opp_Expert_supportcontroller {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void  Createrecord()
     { 
       
             Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, new ValueProvider.ListProvider(new List<String>{'testOpp_1'}))
            .quantity(1)
            .create()
            .getRecord(0);
         
         Opportunity_Expert_supportcontroller.getopprecord(opp.id);
      
      	

     }

}