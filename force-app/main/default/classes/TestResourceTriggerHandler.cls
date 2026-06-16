@isTest
private class TestResourceTriggerHandler {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void MyUnitTest() {

        //******************************************************************* Create Project
        Project__c p = new Project__C();
        p.Name = 'Test Ebm Project';
        p.Delivery_Qtr__c = '2016Q4';
        p.Stage__c = 'New';
        p.Type__c = 'New Functionality';
        p.Portfolio__c = 'BizServ Core';
        p.Why_this__c = 'High Level Description';

        insert p;

        //******************************************************************* Create Resource
        list<Resources__c> lResource = new list<Resources__c>();

        Resources__c res1 = new Resources__c();
        res1.Type__c = 'SFDC Dev';
        res1.Location__c = 'Manila';
        res1.Project__c = p.Id;
        res1.Type1__c = 'Estimate';
        res1.Tech_Team__c = 'CRM';
        res1.Jan__c = 5;
        res1.Year__c = '2018';
        lResource.add(res1);

        Resources__c res2 = new Resources__c();
        res2.Type__c = 'SFDC Dev';
        res2.Location__c = 'Manila';
        res2.Project__c = p.Id;
        res2.Type1__c = 'Estimate';
        res2.Tech_Team__c = 'CRM';
        res2.Feb__c = 5;
        res2.Year__c = '2018';
        lResource.add(res2);

        Resources__c res3 = new Resources__c();
        res3.Type__c = 'SFDC Dev';
        res3.Location__c = 'Manila';
        res3.Project__c = p.Id;
        res3.Type1__c = 'Estimate';
        res3.Tech_Team__c = 'CRM';
        res3.Mar__c = 5;
        res3.Year__c = '2018';
        lResource.add(res3);

        insert lResource;

    }
}