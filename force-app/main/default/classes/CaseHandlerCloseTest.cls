@isTest
public with sharing class CaseHandlerCloseTest {

    public static final String UID = '123456789';
    public static final String CONTACT_FIRSTNAME = 'firstName';
    public static final String CONTACT_LASTNAME = 'lastName';
    public static final String CONTACT_EMAIL = 'test@test.com';

    @IsTest
    static void testExecuteMethod_whenAllDataIsCorrect_shouldCloseTheCase(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont);

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        Test.startTest();
            Map<String,Object> res = handlerClose.execute(req);
        Test.stopTest();

        System.assertEquals(true, (Boolean) res.get(CaseAPIUtil.SUCCESS_FIELD_NAME), 'The transaction should have gone well');
        System.assertEquals(CaseHandlerClose.SUCCESS_MESSAGE, (String) res.get(CaseAPIUtil.MESSAGE_FIELD_NAME), 'The transaction should have gone well');

        
        aCase = getCase();

        system.assertEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status value');
        system.assertEquals(cont.Id, aCase.ContactID, 'Invalid ContactId value');
        system.assertEquals(acc.Id, aCase.AccountId, 'Invalid AccountId value');
    }

    @IsTest
    static void testExecuteMethod_whenCaseIsAlreadyClosed_shouldThrowAnError(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont);

        aCase.status = CaseHelper.CASE_STATUS_CLOSED;
        update aCase;

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();

        String errorMessage;
        Boolean anErrorHasOccurred = false;

        Test.startTest();
            try{
                handlerClose.execute(req);
            } catch(Exception e) {
                errorMessage = e.getMessage();
                anErrorHasOccurred = true;
            }
        Test.stopTest();

        System.assertEquals(true, anErrorHasOccurred, 'The transaction should throw an error');
        System.assert(
            errorMessage.contains(CaseHandlerClose.ALREADY_CLOSED), 
            'It should throw the error message: ' + CaseHandlerClose.ALREADY_CLOSED +'\nCurrent message: ' + errorMessage
        );
    }

    @IsTest
    static void testExecuteMethod_whenContactIsNotAssociatedWithAccount_shouldThrowAnError(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont);

        cont.AccountId = null;
        update cont;

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        String errorMsg = '';
        Test.startTest();
            try {
                Map<String,Object> res = handlerClose.execute(req);
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerStrategy.INVALID_CONTACT_ACCOUNT),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerStrategy.INVALID_CONTACT_ACCOUNT
        );
        
        aCase = getCase();

        system.assertNotEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status value');
    }

    @IsTest
    static void testExecuteMethod_whenCaseIdWrong_shouldThrowAnError(){
        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', (Id) new ValueProvider.DummyIdProvider(Case.sObjectType).getValue());

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        String errorMsg = '';
        Test.startTest();
            try {
                Map<String,Object> res = handlerClose.execute(req);
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerStrategy.NO_CASE_FOUND),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerStrategy.NO_CASE_FOUND
        );
    }

    @IsTest
    static void testExecuteMethod_whenContactEmailIsInvalid_shouldThrowAnError(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont);

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', 'invalidemail@email.com');
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        String errorMsg = '';
        Test.startTest();
            try {
                Map<String,Object> res = handlerClose.execute(req);
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerStrategy.CONTACT_NO_RELATED_TO_CASE),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerStrategy.CONTACT_NO_RELATED_TO_CASE
        );
        
        aCase = getCase();

        system.assertNotEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status value');
    }
    
    @IsTest
    static void testExecuteMethod_whenAccountIsInvalid_shouldThrowAnError(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont);

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', '123');
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        String errorMsg = '';
        Test.startTest();
            try {
                Map<String,Object> res = handlerClose.execute(req);
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerStrategy.ACCOUNT_NO_RELATED_TO_CASE),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerStrategy.ACCOUNT_NO_RELATED_TO_CASE
        );
        
        aCase = getCase();

        system.assertNotEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status value');
    }
    
    @IsTest
    static void testValidateMethod_whenRequiredParametersAreNotPopulated_shouldThrowAnError(){
        CaseHandlerClose handlerClose = new CaseHandlerClose();

        String errorMsg = '';
        Test.startTest();
            try {
                handlerClose.validate(new Map<String, Object>());
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerClose.REQUIRED_VALUES),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerClose.REQUIRED_VALUES
        );
    }
    
    @IsTest
    static void testValidateMethod_whenActionValueIsInvalid_shouldThrowAnError(){
        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'invalid');
        req.put('uid', '123');
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', 'case id');

        CaseHandlerClose handlerClose = new CaseHandlerClose();

        String errorMsg = '';
        Test.startTest();
            try {
                handlerClose.validate(req);
            } catch(Exception e) {
                errorMsg = e.getMessage();
            }
        Test.stopTest();

        System.assert( 
            errorMsg.containsIgnoreCase(CaseHandlerClose.INVALID_ACTION),
            'Invalid error message. Actual: ' + errorMsg + '\nExpected: ' + CaseHandlerClose.INVALID_ACTION
        );
    }
    @IsTest
    static void testExecuteMethod_whenContactIsAdmin_shouldBeOk(){
        Account acc = createAccount();
        Contact cont = createContact(acc);
        AccountContactRole accContRole = createAccountContactRoleAdmin(cont, acc);

        Case aCase = createCase(acc, cont);

        aCase.ContactId = null;
        update aCase;

        Map<String, Object> req = new Map<String, Object>();
        req.put('action', 'close');
        req.put('uid', UID);
        req.put('email', CONTACT_EMAIL);
        req.put('caseId', aCase.Id);

        CaseHandlerClose handlerClose = new CaseHandlerClose();


        Test.startTest();
            Map<String,Object> res = handlerClose.execute(req);
        Test.stopTest();

        System.assertEquals(true, (Boolean) res.get(CaseAPIUtil.SUCCESS_FIELD_NAME), 'The transaction should have gone well');
        System.assertEquals(CaseHandlerClose.SUCCESS_MESSAGE, (String) res.get(CaseAPIUtil.MESSAGE_FIELD_NAME), 'The transaction should have gone well');

        
        aCase = getCase();

        system.assertEquals(CaseHandlerClose.STATUS_CLOSED_BY_CUSTOMER, aCase.Status, 'Invalid status value');
        system.assertEquals(acc.Id, aCase.AccountId, 'Invalid AccountId value');
    }

    public static Account createAccount(){
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'Unted States',
                Account.RC_User_ID__c => UID,
                Account.RC_Account_Number__c => UID
            })
            .create()
            .getRecord();
    }

    public static Contact createContact(Account acc){
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRSTNAME,
                    Contact.LastName => CONTACT_LASTNAME,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => '12345678910',
                    Contact.Phone_Ext__c => 777,
                    Contact.AccountId => acc?.Id
                }
            )
            .create()
            .getRecord();
    }

    public static Case createCase(Account acc, Contact cont) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Subject',
                    Case.Case_Severity__c => CaseHelper.CASE_SEVERITY_MEDIUM,
                    Case.Description => 'Description',
                    Case.AccountId => acc?.Id,
                    Case.ContactId => cont?.Id
                }
            )
            .create()
            .getRecord();
    }

    public static AccountContactRole createAccountContactRoleAdmin(Contact cont, Account acc) {
        return (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => cont.Id,
                AccountContactRole.Role => SCApiService.ADMIN_ROLE,
                AccountContactRole.IsPrimary => true
            })
            .create()
            .getRecord();
    }

    public static Case getCase(){
		return (Case) new CaseSelector()
			.selectCases()
			.selectFields(new Set<String>{
				'AccountId',
				'ContactId',
                'Status'
			})
			.executeQuery()[0];
	}
}