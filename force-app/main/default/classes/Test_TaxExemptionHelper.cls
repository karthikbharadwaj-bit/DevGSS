@isTest
public class Test_TaxExemptionHelper {

    static void createData(Boolean isExistingBusinnes) {
        Account acc;
        Contact con;

        if(isExistingBusinnes){
            acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.BillingStreet, 'Wall street')
                .setField(Account.BillingCity, 'NYC')
                .setField(Account.BillingState, 'NY')
                .setField(Account.BillingPostalCode, '123890')
                .setField(Account.BillingCountry, 'US')
                .setField(Account.Billing_ID__c, '123')
                .create()
                .getRecord();

            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, acc.Id)
                .create()
                .getRecord();
        } else {
            acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.BillingStreet, 'Wall street')
                .setField(Account.BillingCity, 'NYC')
                .setField(Account.BillingState, 'NY')
                .setField(Account.BillingPostalCode, '123890')
                .setField(Account.BillingCountry, 'US')
                .create()
                .getRecord();

            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, acc.Id)
                .create()
                .getRecord();
        }

        new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Tax Exemption Approval')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Contact__c, con.Id)
            .setField(Approval__c.Contact__c, con.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_NEW)
            .create();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c, true)
            .create();
    }

    @isTest
    static void testTaxExemptionGetRequest() {
        createData(false);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Test.startTest();
            NGBSAPI.TaxExemption taxExemptions = TaxExemptionHelper.getTaxExemption('123');
        Test.stopTest();

        System.assertEquals(true, taxExemptions.getFederalTaxExemption(), 'Federal tax exemption should be set to true');
        System.assertEquals(false, taxExemptions.getStateTaxExemption(), 'State tax exemption should be set to false');
        System.assertEquals(true, taxExemptions.getCountyTaxExemption(), 'County tax exemption should be set to true');
        System.assertEquals(false, taxExemptions.getlocalTaxExemption(), 'Local tax exemption should be set to false');
        System.assertEquals(false, taxExemptions.getVatExemption(), 'Local tax exemption should be set to false');
        System.assertEquals(false, taxExemptions.getSEZWOPExemption(), 'Indian tax exemption should be set to false');
        System.assertEquals(null, taxExemptions.getVatCountry(), 'VAT country should be set to null');
        System.assertEquals(null, taxExemptions.getVatNumber(), 'VAT number should be set to null');
        System.assertEquals(null, taxExemptions.getGSTNumber(), 'GST number should be set to null');
    }

    @isTest
    static void testTaxExemptionPostRequest() {
        createData(false);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Boolean federalTaxExemption = true;
        Boolean stateTaxExemption = false;
        Boolean countyTaxExemption = true;
        Boolean localTaxExemption = false;
        Boolean salesTaxExemption = false;
        Boolean vatExemption = false;
        Boolean sezwopExemption = false;
        String vatCountry = 'AT';
        String vatNumber = '123123';
        HttpResponse response;

        Test.startTest();
            response = TaxExemptionHelper.postTaxExemption('123',
                federalTaxExemption,
                stateTaxExemption,
                countyTaxExemption,
                localTaxExemption,
                salesTaxExemption,
                vatExemption,
                sezwopExemption,
                vatCountry,
                vatNumber,
                null
                );
        Test.stopTest();

        NGBSAPI.TaxExemption taxExemptions =
            (NGBSAPI.TaxExemption) JSON.deserialize(response.getBody(), NGBSAPI.TaxExemption.class);

        System.assertEquals(federalTaxExemption,
            taxExemptions.getFederalTaxExemption(),
            'Federal tax exemption should\'ve been set to true');
        System.assertEquals(stateTaxExemption,
            taxExemptions.getStateTaxExemption(),
            'State tax exemption should\'ve been set to false');
        System.assertEquals(countyTaxExemption,
            taxExemptions.getCountyTaxExemption(),
            'County tax exemption should\'ve been set to true');
        System.assertEquals(localTaxExemption,
            taxExemptions.getlocalTaxExemption(),
            'Local tax exemption should\'ve been set to false');
        System.assertEquals(vatExemption,
            taxExemptions.getVatExemption(),
            'VAT tax exemption should\'ve been set to false');
        System.assertEquals(sezwopExemption,
            taxExemptions.getSEZWOPExemption(),
            'SEZWOP tax exemption should\'ve been set to false');
    }

    @isTest
    static void testIsAccountBasedTaxExemptionFlow() {
        createData(false);
        Approval__c approval = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.VATExemption__c,
                Approval__c.SEZWOPExemption__c
            })
            .executeQuery()
            .get(0);
        Boolean isAccountBasedFlow = false;

        Test.startTest();
            isAccountBasedFlow = TaxExemptionHelper.isAccountBasedTaxExemptionFlow(approval);
            System.assertEquals(false, isAccountBasedFlow, 'Should be none Account based tax exemption flow');

            approval.FederalTaxExemption__c = TaxExemptionHelper.REQUESTED;
            update approval;
            isAccountBasedFlow = TaxExemptionHelper.isAccountBasedTaxExemptionFlow(approval);
        Test.stopTest();

        System.assertEquals(true, isAccountBasedFlow,
            'One requested checkbox - should be considered as Account based exemption flow');
    }

    @isTest
    static void testGetExemptChangesApprovalIsNotCurrent() {
        createData(false);
        List<Approval__c> app = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        NGBSAPI.TaxExemption taxExemption = new NGBSAPI.TaxExemption(true, true, true, true, false, false, false, null, null, null);
        Response resp;
        Test.startTest();
            resp = TaxExemptionHelper.getExemptChanges(app[0], taxExemption);
        Test.stopTest();

        System.assertEquals(true, (Boolean) resp.data.get('isFederalChanged'), 'Wrong federal exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isStateChanged'), 'Wrong state exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isCountyChanged'), 'Wrong county exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isLocalChanged'), 'Wrong local exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isNGBSExemptionsChanged'), 'One of exempts value is wrong');
    }

    @isTest
    static void testGetExemptChangesApprovalIsCurrent() {
        createData(false);
        List<Approval__c> app = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToUpdate = app[0];
        appToUpdate.FederalTaxExemption__c = TaxExemptionHelper.CURRENT;
        appToUpdate.StateTaxExemption__c = TaxExemptionHelper.CURRENT;
        appToUpdate.CountyTaxExemption__c = TaxExemptionHelper.CURRENT;
        appToUpdate.LocalTaxExemption__c = TaxExemptionHelper.CURRENT;
        update appToUpdate;

        NGBSAPI.TaxExemption taxExemption = new NGBSAPI.TaxExemption(false, false, false, false, false, false, false, null, null, null);
        Response resp;
        Test.startTest();
            resp = TaxExemptionHelper.getExemptChanges(appToUpdate, taxExemption);
        Test.stopTest();

        System.assertEquals(true, (Boolean) resp.data.get('isFederalChanged'), 'Wrong federal exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isStateChanged'), 'Wrong state exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isCountyChanged'), 'Wrong county exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isLocalChanged'), 'Wrong local exempt value');
        System.assertEquals(true, (Boolean) resp.data.get('isNGBSExemptionsChanged'), 'One of exempts value is wrong');
    }

    @IsTest
    public static void testUpdateVATNumberOnAccount() {
        createData(false);

        Approval__c app = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.Account__c
            })
            .setCondition('Account__c != null')
            .executeQuery()
            .get(0);
        System.assert(app != null);
        System.assert(app.Account__c != null);

        app.VATNumber__c = '252429421';
        app.VATCountryForCheck__c = 'DE';
        update app;

        Test.startTest();
        TaxExemptionHelper.updateVATNumberOnAccount(new List<Approval__c>{ app });
        Test.stopTest();

        Account testAcc = (Account) new AccountSelector().selectAccounts()
            .setQueryBindings(new List<Object>{
                app.Account__c
            })
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.Account__c,
                Account.VATNumber__c
            })
            .setCondition('Id = :bind0')
            .executeQuery()
            .get(0);
        String vatNumber = 'DE252429421';

        System.assert(testAcc != null, 'Account should be not null');
        System.assertEquals(testAcc.VATNumber__c, vatNumber, 'Vat Number on account and approval should be not identical');
    }

    @isTest
    static void testCompleteApprovalForExistingBusiness() {
         createData(true);
         Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

         List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector().selectApprovals()
            .selectFields(new List<String>{'Id'})
            .executeQuery();

        approvals.get(0).Status__c = ApprovalHelper.STATUS_APPROVED;
        update approvals.get(0);

        Test.startTest();
            TaxExemptionHelper.completeApproval(new List<Id>(new Map<Id, Approval__c>(approvals).keySet()), false);
        Test.stopTest();

         List<Approval__c> approvalsToUpdate = (List<Approval__c>) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c})
            .executeQuery();

        List<Account> accountsToUpdate = (List<Account>) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.Name,
                Account.TaxExemptionApprovals__c})
            .executeQuery();

        System.assertEquals(TaxExemptionHelper.CURRENT, approvalsToUpdate.get(0).FederalTaxExemption__c, 'Federal tax exemption field should be set to Current');
        System.assertEquals(null, approvalsToUpdate.get(0).StateTaxExemption__c, 'State tax exemption field should be set to null');
        System.assertEquals(true, accountsToUpdate.get(0).TaxExemptionApprovals__c, 'Tax Exemption Approvals field should be set to true');
    }

    @isTest
    static void testCompleteApprovalForExistingBusinessWithRejection() {
        createData(true);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Approval__c approval = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.VATExemption__c,
                Approval__c.VATNumber__c,
                Approval__c.Status__c,
                Approval__c.VATCountryForCheck__c,
                Approval__c.VATCountry__c,
                Approval__c.Account__c,
                Approval__c.Contact__c
            })
            .executeQuery()
            .get(0);

        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.VATNumber__c,
                Account.Billing_ID__c
            })
            .executeQuery()
            .get(0);

        acc.Billing_ID__c = '123';
        update acc;

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.AccountId => acc.Id})
                .create()
                .getRecord();
        Test.startTest();
        approval.VATCountryForCheck__c = 'Test';
        approval.Opportunity__c = opp.Id;
        approval.VATExemption__c = ApprovalHelper.STATUS_APPROVED;
        approval.Status__c = ApprovalHelper.STATUS_APPROVED;
        approval.VATNumber__c = '111111';
        update approval;

        Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
            new Map<SObjectField, Object>{
                Approval__c.Name => 'Tax Exemption Approval',
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                Approval__c.Account__c => approval.Account__c,
                Approval__c.Contact__c => approval.Contact__c,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.CountyTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.FederalTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.LocalTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.StateTaxExemption__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.Opportunity__c => opp.Id})
            .create()
            .getRecord();

        TaxExemptionHelper.completeApproval(new List<Id>{approval.Id}, false);
        Test.stopTest();

        Approval__c reselectApp = (Approval__c) new ApprovalSelector().selectTaxExemptionApprovalsById(new List<Object>{new List<Id>{app.Id}})
                .executeQuery()
                .get(0);

        System.assertEquals(reselectApp.CountyTaxExemption__c, ApprovalHelper.STATUS_REJECTED);
        System.assertEquals(reselectApp.FederalTaxExemption__c, ApprovalHelper.STATUS_REJECTED);
        System.assertEquals(reselectApp.LocalTaxExemption__c, ApprovalHelper.STATUS_REJECTED);
        System.assertEquals(reselectApp.StateTaxExemption__c, ApprovalHelper.STATUS_REJECTED);
        System.assertEquals(reselectApp.Status__c, ApprovalHelper.STATUS_REJECTED);
    }

    @isTest
    static void testSetVATNumberToAccount() {
        createData(true);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Approval__c approval = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.VATExemption__c,
                Approval__c.VATNumber__c,
                Approval__c.Status__c,
                Approval__c.VATCountryForCheck__c,
                Approval__c.VATCountry__c
            })
            .executeQuery()
            .get(0);

        Account acc = (Account) new AccountSelector().selectAccounts()
                .selectFields(new List<Schema.SObjectField>{
                        Account.VATNumber__c,
                        Account.Billing_ID__c
                })
                .executeQuery()
                .get(0);

        acc.Billing_ID__c = '123';
        update acc;
        Test.startTest();
        approval.VATCountryForCheck__c = 'Test';
        approval.VATExemption__c = ApprovalHelper.STATUS_APPROVED;
        approval.Status__c = ApprovalHelper.STATUS_APPROVED;
        approval.VATNumber__c = '111111';
        update approval;

        TaxExemptionHelper.completeApproval(new List<Id>{approval.Id}, false);
        Test.stopTest();

        Account reselectAcc = (Account) new AccountSelector().selectAccounts()
                .selectFields(new List<Schema.SObjectField>{
                        Account.VATNumber__c
                })
                .executeQuery()
                .get(0);
        System.assertEquals(approval.VATCountryForCheck__c + approval.VATNumber__c, reselectAcc.VATNumber__c, 'VAT number from approval must be set to Account');
    }

    @isTest
    static void testDontVATNumberToAccountForIndianAccounts() {
        createData(false);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Approval__c approval = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.VATExemption__c,
                Approval__c.VATNumber__c,
                Approval__c.Status__c,
                Approval__c.VATCountryForCheck__c,
                Approval__c.VATCountry__c
            })
            .executeQuery()
            .get(0);

        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.VATNumber__c,
                Account.BillingCountry
            })
            .executeQuery()
            .get(0);

        acc.BillingCountry = TaxExemptionHelper.INDIA_COUNTRY;
        update acc;

        Test.startTest();
        approval.VATCountryForCheck__c = 'Test';
        approval.VATExemption__c = ApprovalHelper.STATUS_APPROVED;
        approval.Status__c = ApprovalHelper.STATUS_APPROVED;
        approval.VATNumber__c = '111111';
        update approval;

        TaxExemptionHelper.completeApproval(new List<Id>{approval.Id}, false);
        Test.stopTest();

        Account reselectAcc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.VATNumber__c
            })
            .executeQuery()
            .get(0);
        System.assertEquals(null, reselectAcc.VATNumber__c, 'VAT number from approval dont have to be copied to Account');
    }

    @isTest
    static void testCompleteApproval() {
        createData(false);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector().selectApprovals()
            .selectFields(new List<String>{'Id'})
            .executeQuery();

        approvals.get(0).Status__c = ApprovalHelper.STATUS_APPROVED;
        update approvals.get(0);

        Test.startTest();
            TaxExemptionHelper.completeApproval(new List<Id>(new Map<Id, Approval__c>(approvals).keySet()), false);
        Test.stopTest();

        List<Approval__c> approvalsToUpdate = (List<Approval__c>) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.VATExemption__c})
            .executeQuery();

        List<Account> accountsToUpdate = (List<Account>) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.Name,
                Account.TaxExemptionApprovals__c})
            .executeQuery();

        System.assertEquals(null, approvalsToUpdate.get(0).FederalTaxExemption__c, 'Federal tax exemption field should be set to null');
        System.assertEquals(null, approvalsToUpdate.get(0).StateTaxExemption__c, 'State tax exemption field should be set to null');
        System.assertEquals(true, accountsToUpdate.get(0).TaxExemptionApprovals__c, 'Tax Exemption Approvals field should be set to true');
    }

    @isTest
    static void testCheckAttachIdsForIndia() {
        System.assertEquals(false, TaxExemptionHelper.checkAttachIdsForIndia(''), 'Must be false for empty string');
        System.assertEquals(false, TaxExemptionHelper.checkAttachIdsForIndia(';;;'), 'Must be false for short string');
        System.assertEquals(false, TaxExemptionHelper.checkAttachIdsForIndia(';;;;;'), 'Must be false for empty part');
        System.assertEquals(false, TaxExemptionHelper.checkAttachIdsForIndia(';;;;;,;'), 'Must be false for empty parts');
        System.assertEquals(true, TaxExemptionHelper.checkAttachIdsForIndia(';;;;;,asdasd;'), 'Must be true');
        System.assertEquals(true, TaxExemptionHelper.checkAttachIdsForIndia(';;;;;asdasd,asdasd;'), 'Must be true');
    }

    @isTest
    static void testKycErrorForTEACreation() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => 'Lenin',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'India',
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => 'INR'
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval__c kyc = (Approval__c) new ApprovalSelector()
                .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
                .selectFields(new List<String> {'Id', 'Status__c', 'GstNo__c', 'KycFiles__c'})
                .executeQuery()
                .get(0);

            System.assertEquals(TaxExemptionHelper.TEA_ERROR_APPROVED_KYC_NOT_FOUND, TaxExemptionHelper.getKycErrorForTEACreation(null), 'Must be: ' + TaxExemptionHelper.TEA_ERROR_APPROVED_KYC_NOT_FOUND);

            kyc.Status__c = ApprovalHelper.STATUS_APPROVED;
            kyc.DateOfSignOff__c = System.today();
            kyc.Other__c = 'test other';
            kyc.NameOfTheAuthorisedSignatory__c = 'test name of Authorised Signatory';
            kyc.NameOfFatherOrHusband__c = 'test name of father';
            kyc.GenderOfAuthorisedSignatory__c = 'Male';
            kyc.NationalityOfAuthorisedSignatory__c = 'India';
            kyc.DateOfBirthOfAuthorisedSignatory__c = System.today().addYears(-20);
            kyc.KycFiles__c = 'file1;file2;file3;file4;file5;;file7;file8;file9';
            kyc.PanGirNo__c = '1234567890';
            kyc.PinCode__c = '123456';
            kyc.HouseNo__c = '1';
            kyc.StreetAddress__c = 'Test street';
            kyc.Area__c = 'Test area';
            kyc.City__c = 'Test city';
            kyc.District__c = 'Test district';
            kyc.State__c = 'Assam';
            kyc.Other__c = 'Test other';

            new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        LocalSubscribedAddress__c.Approval__c => kyc.Id,
                        LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                    }
                )
                .create();

            update kyc;
            System.assertEquals(TaxExemptionHelper.TEA_ERROR_SEZ_CERT_NOT_FOUND, TaxExemptionHelper.getKycErrorForTEACreation(kyc), 'Must be: ' + TaxExemptionHelper.TEA_ERROR_SEZ_CERT_NOT_FOUND);
            kyc.KycFiles__c = ';;;;;file6;;;';
            update kyc;
            System.assertEquals(true, String.isBlank(TaxExemptionHelper.getKycErrorForTEACreation(kyc)), 'Must be blank');
        Test.stopTest();
    }

    @IsTest
    static void testIsIndiaCountry() {
        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CountryCodes__c.CountryName__c => 'ind;india',
                CountryCodes__c.Name => 'IND'
            })
            .create();
        Test.startTest();
        System.assertEquals(true, TaxExemptionHelper.isIndiaCountry('India'), 'Must be true');
        System.assertEquals(true, TaxExemptionHelper.isIndiaCountry('IND'), 'Must be true');
        System.assertEquals(true, TaxExemptionHelper.isIndiaCountry('inD'), 'Must be true');
        System.assertEquals(true, TaxExemptionHelper.isIndiaCountry('india'), 'Must be true');
        System.assertEquals(true, TaxExemptionHelper.isIndiaCountry('In'), 'Must be true');
        System.assertEquals(false, TaxExemptionHelper.isIndiaCountry('india '), 'Must be false');
        System.assertEquals(false, TaxExemptionHelper.isIndiaCountry(' india'), 'Must be false');
        Test.stopTest();
    }

    @IsTest
    static void testIndiaTaxExemptionReject() {
        createData(true);
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Approval__c approval = (Approval__c) new ApprovalSelector().selectApprovals()
                .selectFields(new List<Schema.SObjectField>{
                        Approval__c.Account__c,
                        Approval__c.FederalTaxExemption__c,
                        Approval__c.StateTaxExemption__c,
                        Approval__c.CountyTaxExemption__c,
                        Approval__c.LocalTaxExemption__c,
                        Approval__c.VATExemption__c,
                        Approval__c.SEZWOPExemption__c,
                        Approval__c.GstNo__c
                })
                .executeQuery()
                .get(0);
        update new Account(Id = approval.Account__c, BillingCountry = 'India');
        approval.SEZWOPExemption__c = ApprovalHelper.STATUS_APPROVED;
        approval.GstNo__c = 'TestGst';
        approval.Status__c = ApprovalHelper.STATUS_APPROVED;
        update approval;

        Test.startTest();
        TaxExemptionHelper.completeApproval(new List<Id>(new Map<Id, Approval__c>(new List<Approval__c>{approval}).keySet()), true);
        Test.stopTest();

        List<Approval__c> approvalsToUpdate = (List<Approval__c>) new ApprovalSelector().selectApprovals()
                .selectFields(new List<Schema.SObjectField>{
                        Approval__c.Id,
                        Approval__c.FederalTaxExemption__c,
                        Approval__c.StateTaxExemption__c,
                        Approval__c.CountyTaxExemption__c,
                        Approval__c.LocalTaxExemption__c,
                        Approval__c.VATExemption__c,
                        Approval__c.SEZWOPExemption__c,
                        Approval__c.GstNo__c,
                        Approval__c.Status__c})
                .executeQuery();

        System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalsToUpdate.get(0).Status__c, 'Approval status must be set to "Rejected"');
        System.assertEquals(ApprovalHelper.STATUS_REJECTED, approvalsToUpdate.get(0).SEZWOPExemption__c, 'SEZWOPExemption status must be set to "Rejected"');
        System.assertEquals('TestGst', approvalsToUpdate.get(0).GstNo__c, 'GstNumber must not be clear');
    }

    @isTest
    private static void verifyMasterApprovalIsPopulatedCorrectly() {
        Triggers.switchOff();
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Validate Account'),
                    Account.Partner_ID__c => '1234567',
                    Account.Payment_Method__c => 'Invoice',
                    Account.Payment_Plan__c => 'Monthly',
                    Account.RC_User_ID__c => '400389021062',
                    Account.Billing_ID__c => '5037002',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.AccountId => account.Id,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
                })
            .create()
            .getRecord();

        Approval__c approval = new Approval__c();
        Triggers.switchOn();

        TaxExemptionHelper.populateFieldsForSalesTaxExemptionApprovals(approval, opportunity, null);

        Assert.areEqual(opportunity.Id, approval.Opportunity__c, 'should have a lookup on test Opportunity');
        Assert.areEqual(ApprovalHelper.STATUS_APPROVED, approval.Status__c, 'should be approved on creating Amazon TE Approval');
        Assert.areEqual(ApprovalHelper.STATUS_APPROVED, approval.SalesTaxExemption__c, 'should be approved Sales Tax Amazon TE Approval');
        Assert.areEqual(true, String.isBlank(approval.OwnerId), 'should be empty (then default) Owner Id on non-Technical Approval prepopulation');
        Assert.areEqual(false, approval.IsMultiProductTechnicalApproval__c, 'should be false MP Technical flag on non-Technical Approval prepopulation');
        Assert.areEqual(true, String.isBlank(approval.MasterApproval__c), 'should be empty Master Approval Lookup on non-Technical Approval prepopulation');
    }

    @isTest
    private static void verifyTechnicalApprovalIsPopulatedCorrectly() {
        Triggers.switchOff();
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Validate Account'),
                    Account.Partner_ID__c => '1234567',
                    Account.Payment_Method__c => 'Invoice',
                    Account.Payment_Plan__c => 'Monthly',
                    Account.RC_User_ID__c => '400389021062',
                    Account.Billing_ID__c => '5037002',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();

        Account techAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Validate Account'),
                    Account.Partner_ID__c => '12345678',
                    Account.OwnerId => testUser.Id,
                    Account.Payment_Method__c => 'Invoice',
                    Account.Payment_Plan__c => 'Monthly',
                    Account.RC_User_ID__c => '4003890210621',
                    Account.Billing_ID__c => '50370021',
                    Account.IsMultiProductTechnicalAccount__c => true,
                    Account.Master_Account__c => masterAccount.Id,
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.AccountId => masterAccount.Id,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
                })
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.OwnerId => testUser.Id,
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.AccountId => techAccount.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.MasterOpportunity__c => masterOpp.Id,
                    Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.BusinessIdentity__c => OpportunityHelper.businessIdentitySerialize(Integer.valueOf(OpportunityHelper.BI_ID_AMAZON), RingCentralHelper.USD)
                })
            .create()
            .getRecord();

        Approval__c masterApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Name => 'test approval',
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.Account__c => masterAccount.Id,
                Approval__c.Opportunity__c => masterOpp.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        Approval__c approval = new Approval__c();
        Triggers.switchOn();

        TaxExemptionHelper.populateFieldsForSalesTaxExemptionApprovals(approval, techOpp, new Map<Id, Approval__c>{ masterOpp.Id => masterApproval });

        Assert.areEqual(testUser.Id, approval.OwnerId, 'should be populated with Technical Opportunity Owner Id');
        Assert.areEqual(true, approval.IsMultiProductTechnicalApproval__c, 'should be true MP Technical flag on Technical Approval prepopulation');
        Assert.areEqual(masterApproval.Id, approval.MasterApproval__c, 'should be populated with Master Approval Id on Technical Approval prepopulation');
    }
    
    @isTest
    static void testGetApproval() {
        createData(false);
        
        Approval__c originalApproval = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.Name
            })
            .executeQuery()
            .get(0);
        
        Test.startTest();
            Approval__c retrievedApproval = TaxExemptionHelper.getApproval(originalApproval.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, retrievedApproval, 'Retrieved approval should not be null');
        System.assertEquals(originalApproval.Id, retrievedApproval.Id, 'Retrieved approval should match original approval ID');
    }
}