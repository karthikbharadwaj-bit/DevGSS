/*-----------------------------------------------------------------------------
* Project Name..........: Replace New Oppty Campaign Selection with Contact Selection         
* File..................: Test method of  OpportunityContactRole Class              *
* Version...............: 1.0                                                       *
* Created by............: Simplion Technologies                                     *
* Created Date..........: 07-23-2014                                                *
* Last Modified by......: Simplion Technologies                                     *
* Description...........: This is Testmethod for OpportunityContactSelection class  *
------------------------------------------------------------------------------>*/
@isTest
private class Test_OpportunityContactSelection {
    @isTest
    static void myUnitOpportunityContactSelection() {
        Account acctest1 = new Account();
        acctest1.Name = 'TestAccount';
        insert acctest1;

        Contact objcon = new Contact();
        objcon.FirstName='test';
        objcon.LastName ='testl';
        objcon.AccountId = acctest1.id;
        objcon.Phone= '4098764563';
        objcon.email = 'Test123@simplion.com';
        insert objcon;

        Order__c orderVal = new  Order__c();
        orderVal.Name = '12345678';
        insert  orderVal;

        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest1.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = OpportunityHelper.defaultOpportunityStage;
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.OwnerId = Userinfo.getUserId();
        Oppval.Primary_Opportunity_Contact__c= objcon.id;
        insert Oppval;

        ApexPages.currentPage().getParameters().put('RecordType',
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId());
        ApexPages.currentPage().getParameters().put('accid','accId');
        ApexPages.currentPage().getParameters().put('retURL','/006/o');
        ApexPages.currentPage().getParameters().put('CF00N80000004jUBx_lkid',orderVal.Id);            
        ApexPages.currentPage().getParameters().put('accid','oppObj.AccountId');             
        ApexPages.currentPage().getParameters().put('retURL','returnString');
        ApexPages.StandardController sc1 = new ApexPages.standardController(Oppval);
        OpportunityContactRoleExtension oppConSel = new OpportunityContactRoleExtension(sc1);   
        String strAccountId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Test.startTest();
        oppConSel.callDispatcher();
        oppConSel.getContactLstOnAccountSelection();
        oppConSel.getContactList(strAccountId);
        oppConSel.createOpportunity();
        PageReference pgRef = new PageReference('/006/o');
        ApexPages.currentPage().getParameters().put('retURL',pgRef.getUrl());
        PageReference cancelPage = oppConSel.cancel();
        PageReference cancelTestPage = new PageReference('/006/o');
        PageReference opptyPage = oppConSel.createOpportunity();
        PageReference dispatcherPage = oppConSel.callDispatcher();
        Test.stopTest();

        System.assertEquals(String.valueOf(cancelPage), String.valueOf(cancelTestPage));
        System.assertEquals(opptyPage, null);
        System.assertEquals(dispatcherPage, null);
    }
}