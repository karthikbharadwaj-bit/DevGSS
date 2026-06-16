@isTest
public class Test_BobMultiApprovalHelper {

    public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';

    @testSetup
    static void generateData() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        new SObjectBuilder(RingCentralVariousSettings__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RingCentralVariousSettings__c.Director_BO_Invoice_Billing_Approver__c => DIRECTOR_BO_NAME,
                    RingCentralVariousSettings__c.Treasure_Manager_Invoice_Billing_Approve__c => TREASURE_MANAGER_NAME,
                    RingCentralVariousSettings__c.Treasurer_Invoice_Billing_Approve__c => TREASURER_NAME,
                    RingCentralVariousSettings__c.Controller_Invoice_Billing_Approver__c => CONTROLLER_NAME,
                    RingCentralVariousSettings__c.Controller_for_Invoice_Request__c  => INVOICE_CONTROLLER
                }
            )
            .create();
    }

    @isTest
    static void testPopulatePartnerInfoOnAccounts () {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .quantity(3)
            .create()
            .getRecords();
        Account partnerAcc = accList[2];
        List<Account> customerAcc = new List<Account>{accList[0], accList[1]};

        Map<String,String> partnerFieldNameToValueMap = new Map<String,String>{
            'Partner_Account__c' => partnerAcc.Id,
            'Partner_Account_Name__c' => 'PartnerAcc',
            'Partner_ID__c' => '12345',
            'Partner_Type__c' => 'Type',
            'Ultimate_Partner_Name__c' => 'UltimateName'
        };


        for (String field : partnerFieldNameToValueMap.keySet()) {
            for (Account acc : customerAcc) {
                acc.put(field, partnerFieldNameToValueMap.get(field));
            }
        }

        Test.startTest();
            Response resp = BobMultiApprovalHelper.populatePartnerInfoOnAccounts(JSON.serialize(customerAcc));
        Test.stopTest();
        System.assert(resp.data.isEmpty(), 'Failed to udpate partner data on customer Accounts');

        List<Account> reselectedAccs = (List<Account>) new AccountSelector()
            .selectAccountsByIds(new List<Object>{new Map<Id, Account>(customerAcc).keySet()})
            .selectFields(new List<String>(partnerFieldNameToValueMap.keySet()))
            .executeQuery();
        for (String field : partnerFieldNameToValueMap.keySet()) {
            for (Account acc : reselectedAccs) {
                System.assertEquals(
                    partnerFieldNameToValueMap.get(field),
                    (String) acc.get(field),
                    'Partner field is not updated'
                );
            }
        }
    }

    @IsTest
    static void testCreateApprovals() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        List<Approval__c> appList = (List<Approval__c>) (new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => acc.Id
            })
            .quantity(3)
            .build()
            .getRecords());

        Test.startTest();
            Response resp = BobMultiApprovalHelper.createAndSubmitApprovals(
                JSON.serialize(appList),
                JSON.serialize(new Map<Id,double>{acc.Id => 10})
            );
        Test.stopTest();
        System.assert(resp.data.isEmpty(), 'Failed to createApproval records');

        List<Approval__c> reselectedAppList = new ApprovalSelector()
            .selectApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
            .executeQuery();

        System.assertEquals(3, reselectedAppList.size(), 'Wrong amount of approval records was created');
    }

    @IsTest
    static void testGetAccountLimits() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            Response resp = BobMultiApprovalHelper.getAccountLimits('123', '456');
        Test.stopTest();

        String acclimit = (String) resp.data.get('limit');
        System.assertEquals('300000', acclimit, 'Wrong limit value was retrieved');
    }

    @IsTest
    static void testGetAccountSummary() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            Response resp = BobMultiApprovalHelper.getAccountSummary('123');
        Test.stopTest();

        String packageId = (String) resp?.data.get('packageId');
        System.assertEquals('9710001', packageId, 'Wrong package id was retrieved');
    }

    @IsTest
    static void testMoveToBobSubmitToFirstStep() {
        Triggers.switchOff();
        List<Account> accountsList = createAccounts(2);
        List<Contact> contactsList = createContacts(accountsList);

        Triggers.switchOn();
        List<AccountContactRole> accountContactRoleList = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accountsList[0].Id,
                            accountsList[1].Id
                        }
                    ),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            contactsList[0].Id,
                            contactsList[1].Id
                        }
                    ),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecords();

        Opportunity testOpp = createOpportunity(accountsList[1]);
        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                Approval__c.Account__c => accountsList[1].Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contactsList[1].Id,
                Approval__c.PartnerAccountPayableContact__c => contactsList[0].Id,
                Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                Approval__c.Monthly_Credit_Limit__c => 456,
                Approval__c.Sign_up_Purchase_Limit__c => 1462,
                Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        List<Approval__c> appListToSubmit = new List<Approval__c>{bobApproval};
        Test.startTest();
            BobMultiApprovalHelper.submitForApproval(appListToSubmit);
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByIds(new List<Object>{appListToSubmit})
            .executeQuery();
        System.assertEquals(1, updatedApprovals.size(), 'Bob Approval should be created');
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L1_APPROVAL, updatedApprovals[0].Status__c, 'Bob Approval should be in PendingL1Approval Status');
        System.assertNotEquals(ApprovalHelper.GOTOTHEFINALSTEP, updatedApprovals[0].InvoiceApprovalType__c, 'Bob Approval should be in first step in Approval Process');
    }

    @IsTest
    static void testMoveToBobSubmitToLastStep() {
        Triggers.switchOff();
        List<Account> accountsList = createAccounts(3);
        List<Contact> contactsList = createContacts(accountsList);
        List<AccountContactRole> accountContactRoleList = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accountsList[0].Id,
                            accountsList[1].Id,
                            accountsList[2].Id
                        }
                    ),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            contactsList[0].Id,
                            contactsList[1].Id,
                            contactsList[2].Id
                        }
                    ),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        Opportunity testOpp = createOpportunity(accountsList[2]);
        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                Approval__c.Account__c => accountsList[2].Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contactsList[2].Id,
                Approval__c.PartnerAccountPayableContact__c => contactsList[0].Id,
                Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                Approval__c.Monthly_Credit_Limit__c => 456,
                Approval__c.Sign_up_Purchase_Limit__c => 1462,
                Approval__c.StatusLastModifiedDate__c => System.now(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        List<Approval__c> appListToSubmit = new List<Approval__c>();
        Test.startTest();
            Approval__c bobApproval2 = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                    Approval__c.Account__c => accountsList[2].Id,
                    Approval__c.Opportunity__c => testOpp.Id,
                    Approval__c.AccountPayableContact__c => contactsList[2].Id,
                    Approval__c.PartnerAccountPayableContact__c => contactsList[1].Id,
                    Approval__c.SwitchInvoicePartnerAccount__c => accountsList[1].Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                    Approval__c.Monthly_Credit_Limit__c => 456,
                    Approval__c.Sign_up_Purchase_Limit__c => 1462,
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                })
                .create()
                .getRecord();
            appListToSubmit.Add(bobApproval2);
            BobMultiApprovalHelper.submitForApproval(appListToSubmit);
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByIds(new List<Object>{appListToSubmit})
                .executeQuery();
        System.assertEquals(1, updatedApprovals.size(), 'Bob Approval should be created');
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L1_APPROVAL, updatedApprovals[0].Status__c, 'Bob Approval should be in PendingL1Approval Status');
        System.assertNotEquals(ApprovalHelper.GOTOTHEFINALSTEP, updatedApprovals[0].InvoiceApprovalType__c, 'Bob Approval should be in last step in Approval Process');
    }

    @IsTest
    static void testMoveToInvoiceSubmitToFirstStep() {
        Triggers.switchOff();
        List<Account> accountsList = createAccounts(2);
        List<Contact> contactsList = createContacts(accountsList);
        Triggers.switchOn();
        List<AccountContactRole> accountContactRoleList = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accountsList[0].Id,
                            accountsList[1].Id
                        }
                    ),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            contactsList[0].Id,
                            contactsList[1].Id
                        }
                    ),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecords();

        Opportunity testOpp = createOpportunity(accountsList[1]);
        Approval__c invoiceApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Account__c => accountsList[1].Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contactsList[1].Id,
                Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                Approval__c.Monthly_Credit_Limit__c => 456,
                Approval__c.Sign_up_Purchase_Limit__c => 1462,
                Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        List<Approval__c> appListToSubmit = new List<Approval__c>{invoiceApproval};
        Test.startTest();
            BobMultiApprovalHelper.submitForApproval(appListToSubmit);
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByIds(new List<Object>{appListToSubmit})
            .executeQuery();
        System.assertEquals(1, updatedApprovals.size(), 'Invoice Approval should be created');
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L1_APPROVAL, updatedApprovals[0].Status__c, 'Invoice Approval should be in PendingL1Approval Status');
        System.assertNotEquals(ApprovalHelper.GOTOTHEFINALSTEP, updatedApprovals[0].InvoiceApprovalType__c, 'Invoice Approval should be in first step in Approval Process');
    }

    @IsTest
    static void testMoveToInvoiceSubmitToLastStep() {
        Triggers.switchOff();
        List<Account> accountsList = createAccounts(4);
        List<Contact> contactsList = createContacts(accountsList);

        List<AccountContactRole> accountContactRoleList = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .quantity(4)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accountsList[0].Id,
                            accountsList[1].Id,
                            accountsList[2].Id,
                            accountsList[2].Id
                        }
                    ),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            contactsList[0].Id,
                            contactsList[1].Id,
                            contactsList[2].Id,
                            contactsList[3].Id
                        }
                    ),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        Opportunity testOpp = createOpportunity(accountsList[2]);
        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                Approval__c.Account__c => accountsList[2].Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contactsList[2].Id,
                Approval__c.PartnerAccountPayableContact__c => contactsList[0].Id,
                Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                Approval__c.Monthly_Credit_Limit__c => 456,
                Approval__c.Sign_up_Purchase_Limit__c => 1462,
                Approval__c.StatusLastModifiedDate__c => System.now(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        List<Approval__c> appListToSubmit = new List<Approval__c>();
        Test.startTest();
            Approval__c invoiceApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                    Approval__c.Account__c => accountsList[2].Id,
                    Approval__c.Opportunity__c => testOpp.Id,
                    Approval__c.AccountPayableContact__c => contactsList[3].Id,
                    Approval__c.SwitchInvoicePartnerAccount__c => accountsList[3].Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                    Approval__c.Invoice_Terms__c => '1',
                    Approval__c.Monthly_Credit_Limit__c => 456,
                    Approval__c.Sign_up_Purchase_Limit__c => 1462,
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                })
                .create()
                .getRecord();
            appListToSubmit.Add(invoiceApproval);
            BobMultiApprovalHelper.submitForApproval(appListToSubmit);
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByIds(new List<Object>{appListToSubmit})
                .executeQuery();
        System.assertEquals(1, updatedApprovals.size(), 'Invoice Approval should be created');
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L1_APPROVAL, updatedApprovals[0].Status__c, 'Invoice Approval should be in PendingL1Approval Status');
        System.assertNotEquals(ApprovalHelper.GOTOTHEFINALSTEP, updatedApprovals[0].InvoiceApprovalType__c, 'Invoice Approval should be in last step in Approval Process');
    }

    @IsTest
    static void testMoveToInvoiceSubmitToApprove() {
        Triggers.switchOff();
        new SObjectBuilder(Invoice_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Invoice_GOA__c.Name => '1',
                Invoice_GOA__c.Currency__c => 'USD',
                Invoice_GOA__c.Sales_Rep__c => '500.00-999999999',
                Invoice_GOA__c.Direct_Manager__c => '350.00-499.99',
                Invoice_GOA__c.Segment_Leader__c => null,
                Invoice_GOA__c.SVP_WWS_Directs__c => null,
                Invoice_GOA__c.SVP_WWS__c => '0.01-349.99'
            })
            .create();
        List<Account> accountsList = createAccounts(4);
        List<Contact> contactsList = createContacts(accountsList);

        List<AccountContactRole> accountContactRoleList = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .quantity(4)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accountsList[0].Id,
                            accountsList[1].Id,
                            accountsList[2].Id,
                            accountsList[2].Id
                        }
                    ),
                    AccountContactRole.ContactId => ValueProviderBuilder.provideList(
                        new List<Id>{
                            contactsList[0].Id,
                            contactsList[1].Id,
                            contactsList[2].Id,
                            contactsList[3].Id
                        }
                    ),
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecords();

        Opportunity testOpp = createOpportunity(accountsList[2]);
        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                Approval__c.Account__c => accountsList[2].Id,
                Approval__c.Opportunity__c => testOpp.Id,
                Approval__c.AccountPayableContact__c => contactsList[2].Id,
                Approval__c.PartnerAccountPayableContact__c => contactsList[0].Id,
                Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                Approval__c.Monthly_Credit_Limit__c => 456,
                Approval__c.Sign_up_Purchase_Limit__c => 1462,
                Approval__c.StatusLastModifiedDate__c => System.now(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        List<Approval__c> appListToSubmit = new List<Approval__c>();
        Test.startTest();
            Approval__c invoiceApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                    Approval__c.Account__c => accountsList[2].Id,
                    Approval__c.Opportunity__c => testOpp.Id,
                    Approval__c.AccountPayableContact__c => contactsList[2].Id,
                    Approval__c.SwitchInvoicePartnerAccount__c => accountsList[0].Id,
                    Approval__c.Status__c => ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
                    Approval__c.Invoice_Terms__c => '1',
                    Approval__c.Monthly_Credit_Limit__c => 456,
                    Approval__c.Sign_up_Purchase_Limit__c => 1462,
                    Approval__c.CurrencyIsoCode => 'USD',
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                })
                .create()
                .getRecord();
            appListToSubmit.Add(invoiceApproval);
            BobMultiApprovalHelper.submitForApproval(appListToSubmit);
        Test.stopTest();

        List<Approval__c> updatedApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByIds(new List<Object>{appListToSubmit})
                .executeQuery();
        System.assertEquals(1, updatedApprovals.size(), 'Invoice Approval should be created');
        System.assertNotEquals(ApprovalHelper.STATUS_APPROVED, updatedApprovals[0].Status__c, 'Invoice Approval should be in Approved Status');
    }


    @IsTest
    static void testGetLayout() {
        Response resp = BobMultiApprovalHelper.getLayout(ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST);
        String layout = (String) resp.data.get('layout');
        System.assert(!String.isBlank(layout), 'Layout related serialized data should be returned');
    }

    private static List<Account> createAccounts(Integer quantity) {
        List<Account> accountsList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(quantity)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'test Account',
                    Account.BillingStreet => '2078 Adamsville Road',
                    Account.BillingCity => 'Laredo',
                    Account.BillingPostalCode => '78040',
                    Account.BillingState => 'Texas',
                    Account.BillingCountry => 'United States'
                }
            )
            .create()
            .getRecords();

        return accountsList;
    }

    private static List<Contact> createContacts(List<Account> accountsList) {
        List<Contact> contactsList = new List<Contact>();
        for (Account acc : accountsList) {
            Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, acc.Id)
                .build()
                .getRecord();
            contactsList.Add(cont);
        }
        insert contactsList;
        return contactsList;
    }

    private static Opportunity createOpportunity(Account account) {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => account.Id,
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Partner_Account__c => null,
                Opportunity.Partner_Contact__c => null,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();
        return testOpp;
    }
}