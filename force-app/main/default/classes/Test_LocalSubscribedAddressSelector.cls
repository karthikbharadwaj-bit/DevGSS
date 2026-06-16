@isTest
private class Test_LocalSubscribedAddressSelector {

    @isTest
    static void testLocalSubscribedAddressesByApprovals() {
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
        List<LocalSubscribedAddress__c> listLsa = new LocalSubscribedAddressSelector()
                .selectLocalSubscribedAddressesByApprovals(LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY, new List<Object>{ new Set<Id>{kycApproval.Id} })
                .executeQuery();
        LocalSubscribedAddress__c lsaByApprovalId = (LocalSubscribedAddress__c) new LocalSubscribedAddressSelector()
                .selectLocalSubscribedAddressByApprovalId(new List<Object>{new Set<Id>{kycApproval.Id}})
                .executeQuery()
                .get(0);
        Test.stopTest();
        System.assertEquals(1, listLsa.size(), 'Local Subscribed Addresses for Approval should be retrieved');
        System.assertEquals(kycApproval.Id, lsaByApprovalId.Approval__c, 'Local Subscribed Address for Approval should be retrieved');
    }

    @IsTest
    static void testSelectLocalSubscribedAddressesBillingAddress() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();
        Approval__c testKycApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApproval',
                Approval__c.Account__c => testAcc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                Approval__c.DateOfSignOff__c => System.today()
            })
            .create()
            .getRecord();
        /* LSA Billing Address is auto-created with KYC Approval */

        Test.startTest();
        List<LocalSubscribedAddress__c> billingAddressLsa = (List<LocalSubscribedAddress__c>) new LocalSubscribedAddressSelector()
            .selectLocalSubscribedAddressesBillingAddressByApprovals(new List<Object>{new Set<Id>{testKycApproval.Id}})
            .executeQuery();
        Test.stopTest();

        System.assertEquals(1, billingAddressLsa.size(), 'Local Subscribed Address with Billing Address record type should be selected');
    }
}