@isTest
global class Test_TaxExemptionController {

    private static String taxExemptionResponse =
    '{"VATExemption":false,"federalTaxExemption":false,"stateTaxExemption":false,"countyTaxExemption":false,"localTaxExemption":false,"salesTaxExemption":false,"SEZWOPExemption":false}';

    private static String VATnumberResponse;

    @TestSetup
    static void createData() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123456')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'email@example.com')
            .setField(Contact.FirstName, 'FirstName')
            .setField(Contact.LastName, 'LastName')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.EUR)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();
        Triggers.switchOn();

        List <Approval__c> approvals =  (List <Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => con.Id,
                    Approval__c.VATNumber__c => ValueProviderBuilder.provideList(new List<String> {'', '23423255'}),
                    Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<String> {'', opp.Id}),
                    Approval__c.VATCountryForCheck__c => ValueProviderBuilder.provideList(new List<String> {'', 'AT'})
                }
            )
            .create()
            .getRecords();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.CountryName__c, 'aut;austria')
            .setField(CountryCodes__c.CountryNameShort__c, 'AT')
            .setField(CountryCodes__c.Name, 'AUT')
            .create();

        new SObjectBuilder(NGBS_Tax_Settings__c.SObjectType)
            .setField(NGBS_Tax_Settings__c.NGBSVATvalidationEndpoint__c, 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService.wsdl')
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c, true)
            .create();
    }

    @isTest
    static void testGetApproval() {
        Approval__c app = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id
            })
            .executeQuery()
            .get(0);
        Test.startTest();
            Approval__c testApp = TaxExemptionController.getApproval(app.Id);
            Approval__c testNull = TaxExemptionController.getApproval(null);
        Test.stopTest();

        System.assertNotEquals(null, testApp, 'There should exist an approval');
        System.assertEquals(app.Id, testApp.Id, 'Wrong approval was selected');

        System.assertEquals(null, testNull, 'No approval should be found');
    }

    @isTest
    static void testSuccessfulUpdateApproval() {
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
        Test.startTest();
            TaxExemptionController.updateApproval(app.Id, new Map<String, String> {
                'federal' => TaxExemptionHelper.CURRENT,
                'state' => TaxExemptionHelper.APPROVED,
                'county' => TaxExemptionHelper.APPROVED,
                'local' => TaxExemptionHelper.CURRENT,
                'VATNumber__c' => '252429421',
                'VATCountryForCheck__c' => 'DE'
            });
        Test.stopTest();
        Approval__c updatedApp = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.Account__c
            })
            .executeQuery()
            .get(0);


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
        System.assertEquals(TaxExemptionHelper.CURRENT, updatedApp.FederalTaxExemption__c, 'Tax exemption state should be current');
        System.assertEquals(TaxExemptionHelper.APPROVED, updatedApp.StateTaxExemption__c, 'Tax exemption state should be approved');
        System.assertEquals(TaxExemptionHelper.APPROVED, updatedApp.CountyTaxExemption__c, 'Tax exemption state should be approved');
        System.assertEquals(TaxExemptionHelper.CURRENT, updatedApp.LocalTaxExemption__c, 'Tax exemption state should be current');
    }

    @isTest
    static void testFailedUpdateApproval() {
        Test.startTest();
            try{
                TaxExemptionController.updateApproval(null, new Map<String, String> {
                    'federal' => TaxExemptionHelper.CURRENT,
                    'state' => TaxExemptionHelper.APPROVED,
                    'county' => TaxExemptionHelper.APPROVED,
                    'local' => TaxExemptionHelper.CURRENT
                });
            }catch(Exception ex) {
                System.assert(ex.getMessage().contains('Approval update failed'), 'Wrong error message');
            }
        Test.stopTest();
    }

    @isTest
    static void testValidateExemptions() {
        Approval__c approvalToTest = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<Schema.SObjectField>{
                Approval__c.Id
            })
            .executeQuery()
            .get(0);

        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery()
            .get(0);

        List<Contact> contactList = new ContactSelector().selectContacts().executeQuery();
        Contact contact = contactList.get(0);

        Approval__c app =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Tax Exempt Approval')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Contact__c, contact.Id)
            .setField(Approval__c.FederalTaxExemption__c, TaxExemptionHelper.REQUESTED)
            .setField(Approval__c.StateTaxExemption__c, TaxExemptionHelper.REQUESTED)
            .setField(Approval__c.CountyTaxExemption__c, TaxExemptionHelper.REQUESTED)
            .setField(Approval__c.LocalTaxExemption__c, TaxExemptionHelper.REQUESTED)
            .create()
            .getRecord();
        /* Emulate that record was submitted for approval */
        app.Status__c = ApprovalHelper.STATUS_PENDING_APPROVAL;
        Triggers.switchOff();
        update app;
        Triggers.switchOn();

        Response resp;
        Test.startTest();
            resp = TaxExemptionController.validateExemptions(approvalToTest, (new Map<String,String>{
                'federal' => TaxExemptionHelper.REQUESTED,
                'state' => TaxExemptionHelper.REQUESTED,
                'county' => TaxExemptionHelper.REQUESTED,
                'local' => TaxExemptionHelper.REQUESTED
            }));
        Test.stopTest();

        String errorMessage = String.valueOf(resp.data.get('isExemptExist'));
        System.assert(errorMessage.contains(TaxExemptionController.EXEMPT_EXISTS), 'Error message is not correct');
        System.assert(errorMessage.contains('federal exemption'), 'Federal exemption should not be saved');
        System.assert(errorMessage.contains('state exemption'), 'State exemption should npt be saved');
        System.assert(errorMessage.contains('county exemption'), 'County exemption should not be saved');
        System.assert(errorMessage.contains('local exemption'), 'Local exemption should not be saved');
    }

    @isTest
    static void testSubmitForApproval() {
        /* Make account as new business */
        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery()
            .get(0);
        acc.Billing_ID__c = null;
        update acc;

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        Response resp;
        Test.startTest();
            resp = TaxExemptionController.submitForApproval(approvalList[0]);
        Test.stopTest();

        Approval__c approvedApproval = (Approval__c) resp.data.get('record');

        System.assertEquals(ApprovalHelper.STATUS_PENDING_APPROVAL, approvedApproval.Status__c, 'Approval should be in approval process');
    }

    @isTest
    static void testSaveApproval() {
        List<Approval__c> appList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToSave = appList[0];

        Test.startTest();
            Response resp;
            resp = TaxExemptionController.saveApproval(appToSave, new Map<String, String>{
                'federal' => TaxExemptionHelper.REQUESTED,
                'state' => TaxExemptionHelper.REQUESTED,
                'county' => TaxExemptionHelper.CURRENT,
                'local' => TaxExemptionHelper.CURRENT
            });
        Test.stopTest();

        Approval__c appToTest = (Approval__c) resp.data.get('record');
        System.assertEquals(TaxExemptionHelper.REQUESTED, appToTest.FederalTaxExemption__c, 'Invalid federal status value');
        System.assertEquals(TaxExemptionHelper.REQUESTED, appToTest.StateTaxExemption__c, 'Invalid state status value');
        System.assertEquals(TaxExemptionHelper.CURRENT, appToTest.CountyTaxExemption__c, 'Invalid county status value');
        System.assertEquals(TaxExemptionHelper.CURRENT, appToTest.LocalTaxExemption__c, 'Invalid local status value');
    }

    @isTest
    static void testSaveLockedApproval() {
        List<Approval__c> appList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToSave = appList[0];

        /* Submit record for approval process */
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval');
        req.setObjectId(appToSave.Id);
        req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_TAX_EXEMPTION_APPROVAL_PROCESS);
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);

        System.assert(result.isSuccess(), 'Record is not in approval process');
        System.assert(Approval.isLocked(appToSave.id), 'Approval record should be locked');

        Test.startTest();
            Response resp;
            resp = TaxExemptionController.saveApproval(appToSave, new Map<String, String>{
                'federal' => TaxExemptionHelper.CURRENT,
                'state' => TaxExemptionHelper.REQUESTED,
                'county' => TaxExemptionHelper.REQUESTED,
                'local' => TaxExemptionHelper.CURRENT
            });
        Test.stopTest();

        Approval__c appToTest = (Approval__c) resp.data.get('record');
        System.assertEquals(TaxExemptionHelper.CURRENT, appToTest.FederalTaxExemption__c, 'Federal exempt value should be current');
        System.assertEquals(TaxExemptionHelper.REQUESTED, appToTest.StateTaxExemption__c, 'State exempt value should be requested');
        System.assertEquals(TaxExemptionHelper.REQUESTED, appToTest.CountyTaxExemption__c, 'County exempt value should be requested');
        System.assertEquals(TaxExemptionHelper.CURRENT, appToTest.LocalTaxExemption__c, 'Local exempt value should be current');
    }
    @isTest
    static void testSetApprovalAction() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        /* Set exemptions for NGBS */
        taxExemptionResponse = '{"VATExemption":false,"federalTaxExemption":true,"stateTaxExemption":false,"countyTaxExemption":false,"localTaxExemption":true,"salesTaxExemption":false,"SEZWOPExemption":false}';

        List<Approval__c> appList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToTest = appList[0];

        appToTest.FederalTaxExemption__c = TaxExemptionHelper.CURRENT;
        appToTest.StateTaxExemption__c = TaxExemptionHelper.REQUESTED;
        appToTest.CountyTaxExemption__c = TaxExemptionHelper.REQUESTED;
        appToTest.LocalTaxExemption__c = TaxExemptionHelper.CURRENT;
        update appToTest;

        /* Submit record for approval process */
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval');
        req.setObjectId(appToTest.Id);
        req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_TAX_EXEMPTION_APPROVAL_PROCESS);
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
        System.assert(result.isSuccess(), 'Record is not in approval process');

        Response resp;
        Test.startTest();
            resp = TaxExemptionController.setApprovalAction(appToTest, new Map<String, String>{
                'action' => 'Reject'
            });
        Test.stopTest();

        Approval__c rejectedApproval = (Approval__c) resp.data.get('record');
        System.assertEquals('Rejected', rejectedApproval.Status__c, 'Record should be rejected');
    }

    @isTest
    static void testInitTaxExemptionPage() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        /* Set exemptions for NGBS */
        taxExemptionResponse = '{"VATExemption":false,"federalTaxExemption":true,"stateTaxExemption":true,"countyTaxExemption":true,"localTaxExemption":true,"salesTaxExemption":false,"SEZWOPExemption":false}';

        List<Approval__c> appList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToTest = appList[0];

        Response resp;
        Test.startTest();
            resp = TaxExemptionController.initTaxExemptionPage(appToTest.Id);
        Test.stopTest();

        Approval__c initializedApproval = (Approval__c) resp.data.get('record');
        System.assertEquals(ApprovalHelper.STATUS_REJECTED, initializedApproval.Status__c, 'Approval should have status Rejected');
    }

    @isTest
    static void testVATExemptionMethods() {

        Test.setMock(HttpCalloutMock.class, new MockVATNumber());
        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery()
            .get(0);

        acc.BillingCountry = 'austria';

        update acc;

        taxExemptionResponse = '{"VATExemption":true,"federalTaxExemption":true,"stateTaxExemption":false,"countyTaxExemption":false,"localTaxExemption":true,"VATCountry":"AT","VATNumber": "12334","SEZWOPExemption":false}';

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .selectField('Opportunity__c')
            .executeQuery();

        Approval__c app = approvalList[1];
        app.VATCountryForCheck__c = 'AT';
        app.VATNumber__c = '34360288';

        update app;

        Test.startTest();

        VATnumberResponse = '{"result":{"vatNumberStatus":"VALID"},"SAFAS_SID":"5b33ec730ebfe2a79e744295af62f5dce42676fc9b66b43d71f7fceaef521893","id":null}';

        Response res = new Response();

        System.assertEquals(true, TaxExemptionController.isShowVATExemption(app.Id), 'isShowVATExemption must return true');
        System.assertEquals(true, TaxExemptionController.isVATFieldsEnabled(app.Id), 'isVATFieldsEnabled must return true');

        res = TaxExemptionController.validateVATNumber(app.VATCountryForCheck__c, app.VATNumber__c, null);
        System.assertEquals(true, res.data.get('isValid'), 'isValid must return true');
        System.assertEquals('', res.data.get('error'), 'Error message must be null');

        res = TaxExemptionController.validateVATNumber(null, app.VATNumber__c, null);
        System.assertEquals(false, res.data.get('isValid'), 'isValid must return false');
        System.assertEquals('VAT Country is not defined.', res.data.get('error'), 'Error message must be "VAT Country is not defined."');

        res = TaxExemptionController.validateVATNumber(app.VATCountryForCheck__c, null, null);
        System.assertEquals(false, res.data.get('isValid'), 'isValid must return false');
        System.assertEquals('VAT Number is not defined.', res.data.get('error'), 'Error message must be "VAT Number is not defined."');

        Test.stopTest();
    }

    @isTest
    static void testSubmitIndianExemption() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = (Account) new AccountSelector().selectAccounts()
            .selectFields(new List<Schema.SObjectField>{
                Account.Id
            })
            .executeQuery()
            .get(0);

        acc.BillingCountry = 'India';
        update acc;

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();

        Approval__c app = approvalList[0];
        System.assertEquals(ApprovalHelper.STATUS_NEW, app.Status__c, 'Approval should be approved');

        Test.startTest();
        Response resp;
        resp = TaxExemptionController.submitForApproval((sObject) app);
        Test.stopTest();

        Approval__c approvedApproval = (Approval__c) resp.data.get('record');
        System.assertEquals(ApprovalHelper.STATUS_APPROVED, approvedApproval.Status__c, 'Approval should be approved');
    }


    @IsTest
    static void testIsShowVATExemption() {
        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .selectFields(new Set<String> {'Opportunity__c', 'Opportunity__r.Brand_Name__c', 'Opportunity__r.CurrencyIsoCode'})
            .executeQuery()
            .get(0);

        Test.startTest();
        Boolean showVATExemption = TaxExemptionController.isShowVATExemption(approval.Id);
        Test.stopTest();

        System.assertEquals(ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL, approval.RecordTypeId, 'Approval record type should be Tax Exempt Approval');
        System.assertEquals(false, showVATExemption, 'Should not show VAT exemption');
    }

    @IsTest
    static void testIsShowIndianExemption() {
        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery()
            .get(0);

        System.assertEquals(ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL, approval.RecordTypeId, 'Approval record type should be Tax Exempt Approval');
        System.assertEquals(false, TaxExemptionController.isShowIndianTaxExemption(approval.Id), 'Should not show Indian exemption');

        Account acc = (Account) new AccountSelector()
            .selectAccountById(approval.Account__c)
            .executeQuery()
            .get(0);
        acc.BillingCountry = TaxExemptionHelper.INDIA_COUNTRY;
        update acc;

        System.assertEquals(true, TaxExemptionController.isShowIndianTaxExemption(approval.Id), 'Indian exemption should be shown');
    }

    @IsTest
    static void testIsShowSalesExemption() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Test')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'email@example.com')
            .setField(Contact.FirstName, 'FirstName')
            .setField(Contact.LastName, 'LastName')
            .create()
            .getRecord();

        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.BusinessIdentity__c => ValueProviderBuilder.provideList(new List<String> {'{"currency":"USD","biId":"4"}', '{"currency":"USD","biId":"62005"}'}),
                    Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId =>  acc.Id
                }
            )
            .create()
            .getRecords();

        test.startTest();

        List<Approval__c> approvals =  (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => con.Id,
                    Approval__c.Opportunity__c =>  ValueProviderBuilder.provideList(new List<String> {opps.get(0).Id, opps.get(1).Id})
                }
            )
            .create()
            .getRecords();

        System.assertEquals(false, TaxExemptionController.isShowSalesTaxExemption(approvals.get(0).Id), 'Sales exemption should not be shown for RingCentral BI');
        System.assertEquals(true, TaxExemptionController.isShowSalesTaxExemption(approvals.get(1).Id), 'Sales exemption should be shown for Amazon BI');

        test.stopTest();
    }

    @IsTest
    static void testIsShowVATExemptionVATBrand() {
        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .selectField('Opportunity__r.Brand_Name__c')
            .executeQuery()
            .get(1);

        approval.Opportunity__r.Brand_Name__c = RingCentralHelper.BRAND_RINGCENTRAL_EU;

        Test.startTest();

        update new Opportunity(Id = approval.Opportunity__c, Brand_Name__c = RingCentralHelper.BRAND_RINGCENTRAL_EU, CurrencyIsoCode = RingCentralHelper.EUR);
        Boolean showVATExemption = TaxExemptionController.isShowVATExemption(approval.Id);
        Test.stopTest();

        System.assertEquals(RingCentralHelper.BRAND_RINGCENTRAL_EU, approval.Opportunity__r.Brand_Name__c, 'Opportunity Brand should be one that supports VAT');
        System.assertEquals(ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL, approval.RecordTypeId, 'Approval record type should be Tax Exempt Approval');
        System.assertEquals(true, showVATExemption, 'Should show VAT exemption');
    }

    @IsTest
    static void testIsShowVATExemptionAvayaBrandVATCurrency() {
        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .selectFields(new Set<String>{'Opportunity__r.Brand_Name__c', 'Opportunity__r.CurrencyIsoCode'})
            .executeQuery()
            .get(1);

        approval.Opportunity__r.Brand_Name__c = RingCentralHelper.BRAND_AVAYA;
        approval.Opportunity__r.CurrencyIsoCode = RingCentralHelper.GBP;

        Test.startTest();

        update new Opportunity(
            Id = approval.Opportunity__r.Id,
            Brand_Name__c = RingCentralHelper.BRAND_AVAYA,
            CurrencyIsoCode = RingCentralHelper.GBP
        );

        Boolean showVATExemption = TaxExemptionController.isShowVATExemption(approval.Id);
        Test.stopTest();

        System.assertEquals(RingCentralHelper.BRAND_AVAYA, approval.Opportunity__r.Brand_Name__c, 'Opportunity Brand should be Avaya Cloud Office');
        System.assertEquals(RingCentralHelper.GBP, approval.Opportunity__r.CurrencyIsoCode, 'Opportunity currency ISO code should be GBP');
        System.assertEquals(ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL, approval.RecordTypeId, 'Approval record type should be Tax Exempt Approval');
        System.assertEquals(true, showVATExemption, 'Should show VAT exemption');
    }

    public class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(taxExemptionResponse);
            return res;
        }
    }

    public class MockVATNumber implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            res.setBody(VATnumberResponse);
            return res;
        }
    }

    @IsTest
    private static void verifySaveVATNumber() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123456')
            .setField(Account.VATNumber__c, '')
            .create()
            .getRecord();

        String validVatNumber = 'DK34042462';
        try {
            TaxExemptionController.saveVATNumber(acc.Id, validVatNumber, '');
        } catch(Exception e) {
            System.assert(false);
        }

        Account testAcc1 = (Account) new AccountSelector()
            .selectAccounts().withoutSelectorOrderByIncluded().withoutSelectorFieldsIncluded()
            .selectFields(new Set<String> {'Id', 'VATNumber__c'})
            .setQueryBindings(new List<Object> { new List<Id>{ acc.Id } })
            .setCondition('Id = :bind0')
            .executeQuery().get(0);

        System.assertEquals(testAcc1.VATNumber__c, validVatNumber, 'Vat number must be filled');

        try {
            TaxExemptionController.saveVATNumber(acc.Id, '', '');
        } catch(Exception e) {
            System.assert(false);
        }

        Account testAcc2 = (Account) new AccountSelector()
            .selectAccounts().withoutSelectorOrderByIncluded().withoutSelectorFieldsIncluded()
            .selectFields(new Set<String> {'Id', 'VATNumber__c'})
            .setQueryBindings(new List<Object> { new List<Id>{ acc.Id } })
            .setCondition('Id = :bind0')
            .executeQuery().get(0);

        System.assertEquals(testAcc2.VATNumber__c, null, 'Vat number must be filled');
    }

    @IsTest
    private static void verifyGetCountryCode() {

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.CountryName__c, 'aus;australia')
            .setField(CountryCodes__c.CountryNameShort__c, 'AU')
            .setField(CountryCodes__c.Name, 'AUS')
            .create();

        List<String> values = new List<String>{'AustRaliA', 'AuS', 'Au'};
        String value1 = TaxExemptionController.getCountryCode(values[0]);
        String value2 = TaxExemptionController.getCountryCode(values[1]);
        String value3 = TaxExemptionController.getCountryCode(values[2]);
        String value4 = TaxExemptionController.getCountryCode(null);
        System.assertEquals(value1, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value2, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value3, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value4, null, 'Value must be returned null');
    }

    @IsTest
    private static void verifyVATExemptionErrors() {

        Test.startTest();
        Response res = new Response();
        res = TaxExemptionController.validateVATNumber(null, '123', null);
        System.assertEquals(res.data.get('isValid'), false, 'Response must be invalid');
        System.assertEquals(res.data.get('error'), 'VAT Country is not defined.', 'Error must be "VAT Country is not defined."');

        res = TaxExemptionController.validateVATNumber('Test', null, null);
        System.assertEquals(res.data.get('isValid'), false, 'Response must be invalid');
        System.assertEquals(res.data.get('error'), 'VAT Number is not defined.', 'Error must be "VAT Number is not defined."');

        Test.stopTest();
    }

    @isTest
    static void testUpdateVatNumberInBilling() {
        String vatNumber = '61954506077';
        String vatCountry = 'FR';
        String billingId = '123';
        String resultResponse = '{"typeName":null,"status":"success","stackTrace":null,"messages":[],"data":{"vatCountry":"FR","vatNumber":"61954506077"}}';

        Test.startTest();

            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);
            Response vatNumberResponse = TaxExemptionController.updateVatNumberInBilling(vatCountry, vatNumber, billingId);

        Test.stopTest();

        String result = JSON.serialize(vatNumberResponse);
        System.assertEquals(result, resultResponse, 'The answer should contain the country and vat number');
    }

    @IsTest
    public static void testGetAttachmentsName() {
        Approval__c app = (Approval__c) new ApprovalSelector().selectApprovals()
            .setCondition('Account__c != null')
            .executeQuery()
            .get(0);

        ContentVersion cv = (ContentVersion) new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentVersion.Title => 'SampleTitle.jpg',
                ContentVersion.PathOnClient => 'SampleTitle.jpg',
                ContentVersion.VersionData => Blob.valueOf('Unit Test ContentVersion Body'),
                ContentVersion.origin => 'H'
            })
            .create()
            .getRecord();

        ContentVersion cv2 = (ContentVersion) new ContentVersionSelector()
            .selectContentVersionById(new List<Object>{new List<Id>{cv.id}})
            .selectFields(new List<Schema.SObjectField>{
                ContentVersion.Id,
                ContentVersion.Title,
                ContentVersion.ContentDocumentId
            })
            .executeQuery()
            .get(0);

        ContentDocumentLink contentLink = (ContentDocumentLink) new SObjectBuilder(ContentDocumentLink.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ContentDocumentLink.LinkedEntityId => app.Id,
                ContentDocumentLink.ContentDocumentId => cv2.ContentDocumentId,
                ContentDocumentLink.ShareType => 'V'
            })
            .create()
            .getRecord();

        Test.startTest();
        Map<String, String> res = TaxExemptionController.getAttachmentsName(new List<Id>{cv2.ContentDocumentId});
        Test.stopTest();

        System.assertEquals(res.get(cv2.ContentDocumentId), cv.Title, 'Values should be equal');
        System.assertEquals(res.get(cv2.ContentDocumentId), 'SampleTitle.jpg', 'Values should be equal');
    }

    @IsTest
    private static void testGetJSONVatBody(){
        String pattern = '{\n' +
                '  "params" : {\n' +
                '    "vatNumber" : "U63436027",\n' +
                '    "countryCode" : "AT",\n' +
                '    "brandContext" : null\n' +
                '  },\n' +
                '  "method" : "validation.checkVatNumber"\n' +
                '}';
        TaxExemptionController.VatParams params = new TaxExemptionController.VatParams();
        params.vatNumber = 'U63436027';
        params.countryCode = 'AT';
        TaxExemptionController.VATBody body = new TaxExemptionController.VATBody();
        body.method = 'validation.checkVatNumber';
        body.params  = params;
        String jsonBody = JSON.serializePretty(body);
        System.assertEquals(jsonBody, pattern, 'Json must match the pattern');
    }

    @IsTest
    private static void testUpdateVATNumberOnAccount() {
        List<Approval__c> appList = new ApprovalSelector()
            .selectTaxExemptionApprovals()
            .executeQuery();
        Approval__c appToTest1 = appList[0];
        Approval__c appToTest2 = appList[1];

        Response response = TaxExemptionController.updateVATNumberOnAccount(appToTest1);
        System.assertEquals('', response.data.get('success'), 'Success message must be empty');
        System.assertEquals(appToTest1, response.data.get('record'), 'Records must be equal');

        Response response2 = TaxExemptionController.updateVATNumberOnAccount(appToTest2);
        Approval__c appToCheck = (Approval__c) response2.data.get('record');
        System.assertEquals(appToTest2.Id, appToCheck.Id, 'Records Ids must be equal');
    }
}