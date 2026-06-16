@isTest
public class Test_ProservProjectTrigger
{

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testProservProjectCreation()
    {
        //create order and its related references
        List<Order> orderList = new List<Order>();
        //creating account reference
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
         //creating contact reference
        Contact c = new Contact();
        c.firstname='test';
        c.LastName ='Contact';
        c.AccountId = acc.Id;
        c.Email ='123@gmail.com';
         //creating Opportunity reference
        Opportunity opp = new Opportunity();
        opp.name='test Opportunity';
        opp.AccountId = acc.Id;
        opp.ContactId = c.Id;
        opp.CloseDate = System.today();
        Order ord = new Order();
        ord.Name='test OrderCC';
        ord.AccountId= acc.Id;
        ord.OpportunityId = opp.Id;
        ord.EffectiveDate = System.today();
        ord.Status = 'Submitted';
        Id recIdForCCProfessional = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CC Professional Services').getRecordTypeId();
        ord.RecordTypeId =recIdForCCProfessional;
        orderList.add(ord);
        Order ord2 = new Order();
        ord2.Name='test OrderCC';
        ord2.AccountId= acc.Id;
        ord2.OpportunityId = opp.Id;
        ord2.EffectiveDate = System.today();
        ord2.Status = 'Submitted';
        Id recIdForProfessional = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        ord2.RecordTypeId =recIdForProfessional;
        orderList.add(ord2);
         insert orderList;
    }
}