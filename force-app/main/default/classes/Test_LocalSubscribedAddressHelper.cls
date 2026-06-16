@isTest
private class Test_LocalSubscribedAddressHelper {

    @isTest
    static void testGetApprovalLocalSubscribedAddressesMap() {
        Map<Id, LocalSubscribedAddress__c> approvalIdToLocalSubscribedAddressesMap;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021'
                }
            )
            .create()
            .getRecord();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 22072021',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_NAME_INR,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
                }
            )
            .create()
            .getRecord();
        Approval__c kycApproval = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
            .executeQuery()
            .get(0);
        LocalSubscribedAddress__c lsa = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LocalSubscribedAddress__c.Approval__c => kycApproval.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                }
            )
            .create()
            .getRecord();
        Test.startTest();
            approvalIdToLocalSubscribedAddressesMap = LocalSubscribedAddressHelper.getApprovalLocalSubscribedAddressesMap(LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY, new Set<Id>{kycApproval.Id});
        Test.stopTest();
        System.assertEquals(lsa.Id, approvalIdToLocalSubscribedAddressesMap.get(kycApproval.Id).Id, 'Local Subscribed Address for Approval should be retrieved');      
    }
}