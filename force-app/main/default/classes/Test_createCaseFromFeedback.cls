@isTest
private class Test_createCaseFromFeedback {

	private static final String CONTACT_EMAIL = 'test@test.com';
	private static final String UID = '123456789';
	private static final String CASE_DESCRIPTION = 'This is a description.\nStill being a description.\nEnd description.';
	private static final String CASE_SUBJECT = 'RingCentral iOS';

	@TestSetup
	static void makeData(){
		Account acc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
			.setField(Account.RC_User_Id__c, UID)
			.create()
			.getRecord();

		new SObjectBuilder(Contact.SObjectType)
		.setFields(new Map<SObjectField, Object>{
				Contact.AccountId => acc.Id,
				Contact.FirstName => 'Test',
				Contact.LastName => 'Test2',
				Contact.Email => CONTACT_EMAIL,
				Contact.Phone => '1234567890',
				Contact.Preferred_Language__c => 'en_US'
		})
		.create();
	}

	@isTest
    static void testEmail_whenAllDataIsCorrectAndContactMatchesWithAccount_shouldBeOk() {
		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>) Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Enterprise User ID",' +
			'"Record_API_Name_Field__c" : "AccountId",' +
			'"Special_Logic__c" : ' + '"Find Account"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Contact Email",' +
			'"Record_API_Name_Field__c" : "ContactId",' +
			'"Special_Logic__c" : ' + '"Find Contact"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Description",' +
			'"Record_API_Name_Field__c" : "Description"' + 
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;
     	// Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

       email.plainTextBody = '_*_Contact Email: '+ CONTACT_EMAIL +'\n' +
	   '_*_Enterprise User ID: ' + UID + '\n' +
	   '_*_Description: ' + CASE_DESCRIPTION;
       email.fromAddress ='test@test.com';
       email.subject = CASE_SUBJECT;
    
		email.binaryAttachments =   new Messaging.inboundEmail.BinaryAttachment[] { getBinaryAttachment() };
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { getTextAttachment() };
		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
		Test.stopTest();

		Case aCase = getCase();

		QueueSObject owner = (QueueSObject) new QueueSelector()
			.selectQueueByName(new List<Object> {'CIA Closed Loop'})
			.executeQuery()
			.get(0);

		Contact cont = (Contact) new ContactSelector().selectContactByMail(new Object[]{CONTACT_EMAIL}).executeQuery()[0];
		Account acc = (Account) new AccountSelector().selectAccountsByUserIds(new Object[]{new String[]{UID}}).executeQuery()[0];

		system.assert(aCase.description.contains(CASE_DESCRIPTION), 'Invalid description');
		system.assertEquals(cont.Id, aCase.ContactId, 'Invalid Contact Id');
		system.assertEquals(acc.Id, aCase.AccountId, 'Invalid Contact Id');
		system.assertEquals(CaseHelper.RT_ID_CUSTOMER_FEEDBACK, aCase.recordTypeId, 'Invalid RecordType');
		system.assertEquals('Medium', aCase.priority, 'Invalid priority');
		system.assertEquals('RC App', aCase.origin, 'Invalid origin');
		system.assertEquals(owner.QueueId, aCase.OwnerId, 'Invalid ownerId');
		system.assertEquals(CASE_SUBJECT, aCase.Subject, 'Invalid Subject');

		system.assertEquals(
			2, 
			new AttachmentSelector()
				.selectAttachmentsByParentIds(new Object[]{new String[]{aCase.Id}})
				.executeQuery().size(),
			'There should be 2 attachments and associated with the created case.'
		);
    }
	@isTest
	static void testEmail_whenEmailSentInvalidFieldValue_shouldCreateCaseAndPopulatesTechnicalIssuesField() {
		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>) Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Enterprise User ID",' +
			'"Record_API_Name_Field__c" : "AccountId",' +
			'"Special_Logic__c" : ' + '"Find Account"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Contact Email",' +
			'"Record_API_Name_Field__c" : "ContactId",' +
			'"Special_Logic__c" : ' + '"Find Contact"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Description",' +
			'"Record_API_Name_Field__c" : "Description"' + 
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;
		// Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		email.plainTextBody = '_*_Contact Email: '+ CONTACT_EMAIL +'\n' +
		'_*_Enterprise User ID: ' + UID + '\n' +
		'_*_Description: ' + CASE_DESCRIPTION + '\n' +
		'_*_Custom Field: "Custom Value"';
		email.fromAddress ='test@test.com';
		email.subject = CASE_SUBJECT;

		email.binaryAttachments =   new Messaging.inboundEmail.BinaryAttachment[] { getBinaryAttachment() };
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { getTextAttachment() };
		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
		Test.stopTest();

		Case aCase = getCase();

		QueueSObject owner = (QueueSObject) new QueueSelector()
			.selectQueueByName(new List<Object> {'CIA Closed Loop'})
			.executeQuery()
			.get(0);

		Contact cont =(Contact) new ContactSelector().selectContactByMail(new Object[]{CONTACT_EMAIL}).executeQuery()[0];
		Account acc = (Account) new AccountSelector().selectAccountsByUserIds(new Object[]{new String[]{UID}}).executeQuery()[0];

		system.assert(aCase.description.contains(CASE_DESCRIPTION), 'Invalid description');
		system.assertEquals(cont.Id, aCase.ContactId, 'Invalid Contact Id');
		system.assertEquals(acc.Id, aCase.AccountId, 'Invalid Contact Id');
		system.assertEquals(CaseHelper.RT_ID_CUSTOMER_FEEDBACK, aCase.recordTypeId, 'Invalid RecordType');
		system.assertEquals('Medium', aCase.priority, 'Invalid priority');
		system.assertEquals('RC App', aCase.origin, 'Invalid origin');
		system.assertEquals(owner.QueueId, aCase.OwnerId, 'Invalid ownerId');
		system.assertEquals(CASE_SUBJECT, aCase.Subject, 'Invalid Subject');

		String expectedErrorMessage = 'The following value: &quot;<b>Custom Field</b>: <b>&quot;Custom Value&quot;</b>&quot; could not be deserialized';
		system.assert(
			aCase.Technical_Issues__c.containsIgnoreCase(expectedErrorMessage), 
			'Technical Issues field should contains ' + expectedErrorMessage + ' Current: ' + aCase.Technical_Issues__c
		);
	}
	@isTest
	static void testEmail_whenAllDataIsCorrectButMDTIsNotCorrectlyConfigured_shouldCreateCaseAndPopulatesTechnicalIssuesField() {
		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>) Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Enterprise User ID",' +
			'"Record_API_Name_Field__c" : "AccountId",' +
			'"Special_Logic__c" : ' + '"Find Account"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Contact Email",' +
			'"Record_API_Name_Field__c" : "ContactId",' +
			'"Special_Logic__c" : ' + '"Find Contact"' +
			'},' +
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Description",' +
			'"Record_API_Name_Field__c" : "BadCustomField__c"' + 
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;
		// Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		email.plainTextBody = '_*_Contact Email: '+ CONTACT_EMAIL +'\n' +
		'_*_Enterprise User ID: ' + UID + '\n' +
		'_*_Description: ' + CASE_DESCRIPTION + '\n' +
		'_*_Custom Field: "Custom Value"';
		email.fromAddress ='test@test.com';
		email.subject = CASE_SUBJECT;

		email.binaryAttachments =   new Messaging.inboundEmail.BinaryAttachment[] { getBinaryAttachment() };
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { getTextAttachment() };
		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
		Test.stopTest();

		Case aCase = getCase();

		QueueSObject owner = (QueueSObject) new QueueSelector()
			.selectQueueByName(new List<Object> {'CIA Closed Loop'})
			.executeQuery()
			.get(0);

		system.assertEquals(CaseHelper.RT_ID_CUSTOMER_FEEDBACK, aCase.recordTypeId, 'Invalid RecordType');
		system.assertEquals('Medium', aCase.priority, 'Invalid priority');
		system.assertEquals('RC App', aCase.origin, 'Invalid origin');
		system.assertEquals(owner.QueueId, aCase.OwnerId, 'Invalid ownerId');
		system.assertEquals(CASE_SUBJECT, aCase.Subject, 'Invalid Subject');

		String expectedErrorMessage = 'Could not be possible populate the case properly.';
		system.assert(
			aCase.Technical_Issues__c.containsIgnoreCase(expectedErrorMessage), 
			'Technical Issues field should contains ' + expectedErrorMessage + ' Current: ' + aCase.Technical_Issues__c
		);
	}
	@isTest
	static void testEmail_whenEmailBodyIsNotCorrectlyFormatted_shouldCreateCaseAndPopulatesTechnicalIssuesField() {
		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>) Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Enterprise User ID",' +
			'"Record_API_Name_Field__c" : "AccountId",' +
			'"Special_Logic__c" : ' + '"Find Account"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Contact Email",' +
			'"Record_API_Name_Field__c" : "ContactId",' +
			'"Special_Logic__c" : ' + '"Find Contact"' +
			'},' +
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Description",' +
			'"Record_API_Name_Field__c" : "BadCustomField__c"' + 
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;
		// Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		email.plainTextBody = '_*_Contact Email: '+ CONTACT_EMAIL +'\n' +
		'_*_Enterprise User ID: ' + UID + '\n' +
		'_*_Description: ' + CASE_DESCRIPTION + '\n' +
		'_*_Custom Field Bad Formatting email';
		email.fromAddress ='test@test.com';
		email.subject = CASE_SUBJECT;

		email.binaryAttachments =   new Messaging.inboundEmail.BinaryAttachment[] { getBinaryAttachment() };
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { getTextAttachment() };
		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
		Test.stopTest();

		Case aCase = getCase();

		QueueSObject owner = (QueueSObject) new QueueSelector()
			.selectQueueByName(new List<Object> {'CIA Closed Loop'})
			.executeQuery()
			.get(0);

		system.assertEquals(CaseHelper.RT_ID_CUSTOMER_FEEDBACK, aCase.recordTypeId, 'Invalid RecordType');
		system.assertEquals('Medium', aCase.priority, 'Invalid priority');
		system.assertEquals('RC App', aCase.origin, 'Invalid origin');
		system.assertEquals(owner.QueueId, aCase.OwnerId, 'Invalid ownerId');
		system.assertEquals(CASE_SUBJECT, aCase.Subject, 'Invalid Subject');

		String expectedErrorMessage = 'doesn&#39;t follow the structure';
		system.assert(
			aCase.Technical_Issues__c.containsIgnoreCase(expectedErrorMessage), 
			'Technical Issues field should contains ' + expectedErrorMessage + ' Current: ' + aCase.Technical_Issues__c
		);
	}
	
	@isTest
	static void testEmail_whenEmailIsOkButAccountIsNotFound_shouldCreateCaseAndPopulatesTechnicalIssuesField() {
		delete (Account) new AccountSelector().selectAccountsByUserIds(new Object[]{new String[]{UID}}).executeQuery()[0];

		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>) Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Enterprise User ID",' +
			'"Record_API_Name_Field__c" : "AccountId",' +
			'"Special_Logic__c" : ' + '"Find Account"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Contact Email",' +
			'"Record_API_Name_Field__c" : "ContactId",' +
			'"Special_Logic__c" : ' + '"Find Contact"' +
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;
		// Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		email.plainTextBody = '_*_Contact Email: '+ CONTACT_EMAIL +'\n' +
		'_*_Enterprise User ID: ' + UID + '\n' +
		'_*_Description: ' + CASE_DESCRIPTION + '\n';
		email.fromAddress ='test@test.com';
		email.subject = CASE_SUBJECT;
 
		email.binaryAttachments =   new Messaging.inboundEmail.BinaryAttachment[] { getBinaryAttachment() };
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { getTextAttachment() };
		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
		Test.stopTest();

		Case aCase = getCase();

		QueueSObject owner = (QueueSObject) new QueueSelector()
			.selectQueueByName(new List<Object> {'CIA Closed Loop'})
			.executeQuery()
			.get(0);

		system.assertEquals(CaseHelper.RT_ID_CUSTOMER_FEEDBACK, aCase.recordTypeId, 'Invalid RecordType');
		system.assertEquals('Medium', aCase.priority, 'Invalid priority');
		system.assertEquals('RC App', aCase.origin, 'Invalid origin');
		system.assertEquals(owner.QueueId, aCase.OwnerId, 'Invalid ownerId');
		system.assertEquals(CASE_SUBJECT, aCase.Subject, 'Invalid Subject');

		String expectedErrorMessage = 'The Account could not be assigned.';
		system.assert(
			aCase.Technical_Issues__c.containsIgnoreCase(expectedErrorMessage), 
			'Technical Issues field should contains ' + expectedErrorMessage + ' Current: ' + aCase.Technical_Issues__c
		);
	}
	@isTest
	static void testEmail_whenInboundEmailIsNull_shouldReturnError() {		
		createCaseFromFeedback feedback = new createCaseFromFeedback();
		
		Test.startTest();
			Messaging.InboundEmailResult result = feedback.handleInboundEmail(null, null);
		Test.stopTest();

		system.assertEquals(false, result.success, 'It should failed.');
	}

	private static Case getCase(){
		return (Case) new CaseSelector()
			.selectCases()
			.selectFields(new Set<String>{
				'AccountId',
				'ContactId',
				'Description',
				'Subject',
				'recordTypeId',
				'priority',
				'origin',
				'OwnerId',
				'Technical_Issues__c'
			})
			.executeQuery()[0];
	}

	private static Messaging.InboundEmail.BinaryAttachment getBinaryAttachment(){
		Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		binaryAttachment.body = blob.valueOf('my attachment text');
		binaryAttachment.fileName = 'textfileone.txt';
		binaryAttachment.mimeTypeSubType = 'text/plain';
		return binaryAttachment;
	}
	private static Messaging.InboundEmail.TextAttachment getTextAttachment(){
		Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
		textAttachment.body = 'my attachmenttext text';
		textAttachment.fileName = 'textfiletwo.txt';
		textAttachment.mimeTypeSubType = 'texttwo/plain';
		return textAttachment;
	}
}