@isTest
private class Test_LocalSubscribedAddressTrigger {
    static final String KYC_USER_NAME = 'Test KYC User For LSA';
    static final String NO_ERROR_MSG = 'There is no error on LSA SObject';
    static final String ERRORS_NOT_FOUND = 'Errors were not found';
    static final String ACC_NAME = 'testAcc';

    @TestSetup
    static void testSetUp() {
        Account testAcc = createAccount(ACC_NAME);

        insert buildApproval(testAcc.Id);

        Profile profile = (Profile) new ListOptional(new ProfileSelector()
            .selectProfileByName(new List<Object> {'Global Operations'})
            .executeQuery()
        ).getFirst();

        new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.ProfileId => profile.Id,
                User.LastName => KYC_USER_NAME
            })
            .create();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateRegisteredAddress() {
        Triggers.switchOff();
        Approval__c kycApproval = buildApproval(createAccount(ACC_NAME).Id);
        new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LocalSubscribedAddress__c.Approval__c => kycApproval.Id,
                LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        LocalSubscribedAddress__c duplicatedLSA = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LocalSubscribedAddress__c.Approval__c => kycApproval.Id,
                LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
            })
            .build()
            .getRecord();

        Test.startTest();
            LocalSubscribedAddressTriggerHandler.ValidateRegisteredAddress triggerHandler = new LocalSubscribedAddressTriggerHandler.ValidateRegisteredAddress(
                TriggerOperation.BEFORE_INSERT, new List<LocalSubscribedAddress__c> {duplicatedLSA}
            );
            triggerHandler.handle();
        Test.stopTest();

        assertErrorMsg(Label.OnlyOneRegisteredAddress, 'Duplicated records was created', duplicatedLSA);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidationOnChangedFieldsAfterApprove() {
        User testUser = selectUser();

        System.runAs(testUser) {
            Triggers.switchOff();
            Approval__c testApproval = buildApproval(createAccount(ACC_NAME).Id);
            testApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
            insert testApproval;
            Triggers.switchOn();

            List<LocalSubscribedAddress__c> testLSAddresses = (List<LocalSubscribedAddress__c>) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    LocalSubscribedAddress__c.Id => ValueProviderBuilder.provideDummyId(LocalSubscribedAddress__c.sObjectType).getValue(),
                    LocalSubscribedAddress__c.Approval__c => testApproval.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY,
                    LocalSubscribedAddress__c.LatitudeLongitudeEvery6Months__c => ValueProviderBuilder.provideList(new List<String> {null, 'Test Latitude'}),
                    LocalSubscribedAddress__c.PinCode__c => ValueProviderBuilder.provideList(new List<String> {null, 'Test PinCode'})
                })
                .quantity(2)
                .build()
                .getRecords();

            List<LocalSubscribedAddress__c> oldRecords = new List<LocalSubscribedAddress__c> {testLSAddresses[0]};
            List<LocalSubscribedAddress__c> newRecords = new List<LocalSubscribedAddress__c> {testLSAddresses[1]};

            Test.startTest();
                LocalSubscribedAddressTriggerHandler.ValidateChangedFieldsAfterApprove triggerHandler = new LocalSubscribedAddressTriggerHandler.ValidateChangedFieldsAfterApprove(
                    TriggerOperation.BEFORE_UPDATE, 
                    newRecords,
                    oldRecords
                );
                triggerHandler.handle();
            Test.stopTest();

            assertErrorMsg(
                Label.LocalSubscribedAddressCannotBeChangedAfterApprove, 
                'Can not edit LSA record fields if the last KYC Approval Request has Approved status',
                newRecords[0]
            );
        }
    }

    @IsTest
    static void testPassedValidationOnChangedFieldsAfterApprove() {
        Approval__c testApproval = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovals()
            .executeQuery()
            .get(0);
        LocalSubscribedAddress__c testLSAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                LocalSubscribedAddress__c.Approval__c => testApproval.Id,
                LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval.ProcessResult result = ApprovalHelper.setApprovalAction(testApproval.Id, 'Approve', 'Ok');
            testLSAddress.LatitudeLongitudeEvery6Months__c = 'not empty data';
            testLSAddress.RevisionDate__c = System.today();
            update testLSAddress;
        Test.stopTest();

        Assert.isFalse(testLSAddress.hasErrors(), 'The error was occured');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLSACreationAfterApproveReject() {
        User testUser = assignPermissionSetToUser();
        
        System.runAs(testUser) {
            Triggers.switchOff();
            Approval__c testApproval = buildApproval(createAccount(ACC_NAME).Id);
            testApproval.Status__c = ApprovalHelper.STATUS_REJECTED;
            insert testApproval;
            Triggers.switchOn();
                
            LocalSubscribedAddress__c testLSAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    LocalSubscribedAddress__c.Approval__c => testApproval.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                })
                .build()
                .getRecord();

            Test.startTest();
                LocalSubscribedAddressTriggerHandler.RestrictAddressCreationAfterApproveReject triggerHandler = new LocalSubscribedAddressTriggerHandler.RestrictAddressCreationAfterApproveReject(
                    TriggerOperation.BEFORE_INSERT, new List<LocalSubscribedAddress__c> {testLSAddress}
                );
                triggerHandler.handle();
            Test.stopTest();

            assertErrorMsg(Label.SiteDeletionCreationIsRestrictedAfterApproveReject, 'LSA creation should be restricted', testLSAddress);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLSADeletionAfterApproveReject() {
        User testUser = assignPermissionSetToUser();

        System.runAs(testUser) {
            Triggers.switchOff();
            Approval__c testApproval = buildApproval(createAccount(ACC_NAME).Id);
            testApproval.Status__c = ApprovalHelper.STATUS_REJECTED;
            insert testApproval;
            Triggers.switchOn();

            LocalSubscribedAddress__c testLSAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    LocalSubscribedAddress__c.Approval__c => testApproval.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                })
                .build()
                .getRecord();

            Test.startTest();
                LocalSubscribedAddressTriggerHandler.RestrictAddressDeletionAfterApproveReject triggerHandler = new LocalSubscribedAddressTriggerHandler.RestrictAddressDeletionAfterApproveReject(
                    TriggerOperation.BEFORE_DELETE, new List<LocalSubscribedAddress__c> {testLSAddress}
                );
                triggerHandler.handle();
            Test.stopTest();

            assertErrorMsg(Label.SiteDeletionCreationIsRestrictedAfterApproveReject, 'LSA deletion should be restricted', testLSAddress);
        }
    }

    @IsTest
    static void testRestrictToCreateMoreThanOneLsaWithBillingAddressRt() {
        Approval__c kycApproval = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovals()
            .executeQuery()
            .get(0);

        Test.startTest();
            try {
                LocalSubscribedAddress__c lsaBillingAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        LocalSubscribedAddress__c.Approval__c => kycApproval.Id,
                        LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS
                    })
                    .create()
                    .getRecord();
                Assert.fail('Error should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(
                    ex.getMessage().contains(Label.OnlyOneLsaWithBillingAddressRt),
                    'Error message is expected because only one Local Subscribed Address record with Billing Address record type can exist'
                );
            }
        Test.stopTest();
    }

    @IsTest
    static void testRestrictToDeleteLsaWithBillingAddressRecordType() {
        Approval__c kycApproval = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovals()
            .executeQuery()
            .get(0);

        LocalSubscribedAddress__c billingAddressLsa = (LocalSubscribedAddress__c) new LocalSubscribedAddressSelector()
            .selectLocalSubscribedAddressesBillingAddressByApprovals(new List<Object> {new Set<Id> {kycApproval.Id}})
            .executeQuery()
            .get(0);

        User testUser = (User) new UserSelector()
            .selectUserByLastName(new List<Object> {new Set<String> {KYC_USER_NAME}})
            .executeQuery()
            .get(0);

        Test.startTest();
            System.runAs(testUser) {
                try {
                    delete billingAddressLsa;
                    Assert.fail('Error should be thrown');
                } catch (Exception ex) {
                    Assert.isTrue(
                        ex.getMessage().contains(Label.LsaWithBillingAddressRtCantBeDeleted),
                        'Error message expected because Local Subscribed Address with Billing Address record type can not be deleted'
                    );
                }
            }
        Test.stopTest();
    }

    static Approval__c buildApproval(Id accountId) {
        return (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Name => 'testApproval',
                Approval__c.Account__c => accountId,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                Approval__c.DateOfSignOff__c => System.today(),
                Approval__c.Other__c => 'test other',
                Approval__c.NameOfTheAuthorisedSignatory__c => 'test name of Authorised Signatory',
                Approval__c.NameOfFatherOrHusband__c => 'test name of father',
                Approval__c.GenderOfAuthorisedSignatory__c => 'Male',
                Approval__c.NationalityOfAuthorisedSignatory__c => 'India',
                Approval__c.DateOfBirthOfAuthorisedSignatory__c => System.today().addYears(-20),
                Approval__c.KycFiles__c => 'file1;file2;file3;file4;;file6;file7;file8;file9',
                Approval__c.PanGirNo__c => '1324567890',
                Approval__c.HouseNo__c => '1',
                Approval__c.StreetAddress__c => 'test Street',
                Approval__c.Area__c => 'test Area',
                Approval__c.City__c => 'test City',
                Approval__c.District__c => 'test District',
                Approval__c.State__c => 'Assam',
                Approval__c.PinCode__c => '123456'
            })
            .build()
            .getRecord();
    }

    static Account createAccount(String name) {
        return (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => name
            })
            .create()
            .getRecord();
    }

    static User assignPermissionSetToUser() {
        User testUser = selectUser();

        PermissionSet permSet = (PermissionSet) new ListOptional(new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object> {new List<String> {'KYC_Approval_Edit'}})
            .executeQuery()
        ).getFirst();

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PermissionSetAssignment.PermissionSetId => permSet.Id,
                PermissionSetAssignment.AssigneeId => testUser.Id
            })
            .create();
        return testUser;
    }

    static User selectUser() {
        return (User) new ListOptional(new UserSelector()
            .selectUserByLastName(new List<Object> {new Set<String> {KYC_USER_NAME}})
            .executeQuery()
        ).getFirst();
    }

    static void assertErrorMsg(String expectedValue, String msg, LocalSubscribedAddress__c record) {
        Assert.isTrue(record.hasErrors(), NO_ERROR_MSG);
        Assert.areEqual(1, record.getErrors().size(), ERRORS_NOT_FOUND);
        Assert.areEqual(
            expectedValue, 
            record.getErrors().get(0).getMessage(), 
            msg
        );
    }
}