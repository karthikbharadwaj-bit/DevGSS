@isTest
public class Test_BatchJob_CreateRedAccount {

    @testSetup
    private static void setup() {
    
        Account[] testAccs = new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, new ValueProvider.ListProvider(new List<String>
                {'acc-1', 'acc-2', 'acc-3', 'acc-4', 'acc-5', 'acc-6'}))
            .setField(Account.MRR__c, new ValueProvider.ListProvider(new List<Integer>
                {1000, 2000, 3000, 4000, 5000, 6000}))
            .quantity(6)
            .build()
            .create()
            .getRecords();
            
       
        new SObjectBuilder(Adoption_Model__c.sObjectType)
            .setField(Adoption_Model__c.Overall_Risk_Score__c, new ValueProvider.ListProvider(new List<Integer>
                {1, 5, 5, 3, 5, 5}))
            .setField(Adoption_Model__c.Account__c, new ValueProvider.ListProvider(new List<String>
                {testAccs[0].Id, testAccs[1].Id, testAccs[2].Id, testAccs[3].Id, testAccs[4].Id, testAccs[5].Id}))
            .quantity(6)
            .build()
            .create();
            
       new SObjectBuilder(Red_Account__c.sObjectType)
            .setField(Red_Account__c.Revenue_at_Risk__c, new ValueProvider.ListProvider(new List<Decimal>
                {testAccs[0].MRR__c, testAccs[1].MRR__c, testAccs[4].MRR__c}))
            .setField(Red_Account__c.EscalatedAccount__c, new ValueProvider.ListProvider(new List<String>
                {testAccs[0].Id, testAccs[1].Id, testAccs[4].Id}))
            .setField(Red_Account__c.Status__c , new ValueProvider.ListProvider(new List<String>
                {'Downgrade 90% - Confirmed Intent', 'Resolved - Saved', 'Downgrade 90% - Confirmed Intent'}))
            .setField(Red_Account__c.Issue_Category__c , new ValueProvider.ListProvider(new List<String>
                {'Contract', 'Contract', 'Contract'}))
            .setField(Red_Account__c.Issue_Status__c , new ValueProvider.ListProvider(new List<String>
                {'New', 'New', 'New'}))
            .quantity(3)
            .build()
            .create();
    }
    
    @isTest
    private static void testBatch() {
    
        Datetime toDate = Datetime.now();
        Datetime fromDate = todate.adddays(-1);
        
        Test.startTest();        
             (new BatchJob_CreateRedAccount(fromDate, toDate)).execute(null);
        Test.stopTest();
        
        for(Red_Account__c redAcct: [SELECT Id, Status__c, EscalatedAccount__r.Name FROM Red_Account__c WHERE Status__c = 'C360 created']){
             if (redAcct.EscalatedAccount__r.Name.startsWith('acc-3') || redAcct.EscalatedAccount__r.Name.startsWith('acc-6') || redAcct.EscalatedAccount__r.Name.startsWith('acc-2')) {
                System.assertEquals('C360 created', redAcct.Status__c,
                    'Red Account for Account \'' + redAcct.EscalatedAccount__r.Name + '\' should be created by the batch.');
            }else{
                System.assertNotEquals('C360 created', redAcct.Status__c,
                    'No Red Account for Account \'' + redAcct.EscalatedAccount__r.Name + '\' should be created by the batch with C360 created status.');
            }
        }    
    }
}