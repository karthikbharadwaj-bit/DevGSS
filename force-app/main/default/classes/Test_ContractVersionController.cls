/**
 * Created by Makhmud.Shafeev on 4/12/2022.
 */
@IsTest
private class Test_ContractVersionController {

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testContractVersionController() {
        Boolean autoRenewal = true;
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
                })
                .create()
                .getRecord();

        Contract testContract = (Contract) new SObjectBuilder(Contract.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Contract.Name => ValueProviderBuilder.provideUniqueString('Test Contract'),
                        Contract.AccountId => testAcc.Id,
                        Contract.Original_Signed_Date__c => System.today().addDays(-10),
                        Contract.Source__c => 'Automation',
                        Contract.Status => 'Draft',
                        Contract.Initial_Term__c => 1,
                        Contract.Original_Initial_Term__c => 1,
                        Contract.Auto_Renewal__c => autoRenewal,
                        Contract.Original_Auto_Renewal__c => autoRenewal,
                        Contract.Start_Date__c => System.today().addDays(-10),
                        Contract.Original_Start_Date__c => System.today().addDays(-10),
                        Contract.End_Date__c => System.today(),
                        Contract.Original_End_Date__c => System.today(),
                        Contract.Renewal_Term__c => 1,
                        Contract.Original_Renewal_Term__c => 1
                })
                .create()
                .getRecord();

        testContract.Status = 'Active';
        update testContract;

        new SObjectBuilder(ContractVersion__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                ContractVersion__c.Name => ValueProviderBuilder.provideUniqueString('TestName'),
                ContractVersion__c.Contract__c => testContract.Id,
                ContractVersion__c.Status__c => 'Active',
                ContractVersion__c.AutoRenewal__c => testContract.Auto_Renewal__c,
                ContractVersion__c.StartDate__c => testContract.Start_Date__c,
                ContractVersion__c.EndDate__c => testContract.End_Date__c,
                ContractVersion__c.RenewalTerm__c => testContract.Renewal_Term__c,
                ContractVersion__c.InitialTerm__c => testContract.Initial_Term__c,
                ContractVersion__c.VersionNumber__c => 1
        }).create();

        ApexPages.StandardController sc = new ApexPages.StandardController(testAcc);
        ContractVersionController controller = new ContractVersionController(sc);
        PageReference pageRef = Page.CompleteJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testAcc.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        controller.accountId = testAcc.Id;
        controller.getAllContractVersions();
        controller.getContractVersions();
        controller.getContainKey();
        controller.getnxt();
        controller.getprv();
        controller.endbtn();
        controller.prvbtn();
        Test.stopTest();

    }
}