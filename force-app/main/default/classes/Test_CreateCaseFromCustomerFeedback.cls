@isTest
private class Test_CreateCaseFromCustomerFeedback {
	
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void rcIOS() {
     // Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

       email.plainTextBody = '• Vorfalls-ID: 5WACVCHF • Vollständiger Name: Test Feedback • Bei RingCentral registrierte E-Mail-Adresse: test@ringcentral.com'+
           '• RingCentral Telefonnummer: (720) 930-4282 • App-Version: iOS 20.1.11.0.58259 • Gerätemodell: Clare’s phone/iPhone 11_13.3.1'+
           '• UID:'+
           '• Beschreiben Sie bitte Ihr Problem hier: hello test';
       email.fromAddress ='test@test.com';
       String contactEmail = 'test@salesforce.com';
       email.subject = 'RingCentral iOS';
    
	// add an Binary attachment  
  	Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
  	attachment.body = blob.valueOf('my attachment text');
  	attachment.fileName = 'textfileone.txt';
  	attachment.mimeTypeSubType = 'text/plain';
  	email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
 
  	// add an Text atatchment  
  	Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
  	attachment.body = blob.valueOf('my attachment text');
  	attachment.fileName = 'textfiletwo.txt';
  	attachment.mimeTypeSubType = 'texttwo/plain';
  	email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
    
    CreateCaseFromCustomerFeedback feedback = new CreateCaseFromCustomerFeedback();
      
    Test.startTest();
    	Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
    Test.stopTest();
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void rcAndroid() {
     // Create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

       email.plainTextBody = '• Incident ID: AF079291 • Full name: Tony Lin • Email address registered with RingCentral: test@ringcentral.com<mailto:test@ringcentral.com>'+
							 '• RingCentral phone number: (650) 332-8459 • App version: 20.1.20.0.000 • Device model: SM-G9730/10 • UID: 12345'+
           					  '• Please describe your problem here: Test';
       email.fromAddress ='test@test.com';
       String contactEmail = 'test@salesforce.com';
       email.subject = 'RingCentral Android';
    
	// add an Binary attachment  
  	Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
  	attachment.body = blob.valueOf('my attachment text');
  	attachment.fileName = 'textfileone.txt';
  	attachment.mimeTypeSubType = 'text/plain';
  	email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
 
  	// add an Text atatchment  
  	Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
  	attachment.body = blob.valueOf('my attachment text');
  	attachment.fileName = 'textfiletwo.txt';
  	attachment.mimeTypeSubType = 'texttwo/plain';
  	email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
    
    CreateCaseFromCustomerFeedback feedback = new CreateCaseFromCustomerFeedback();
      
    Test.startTest();
    	Messaging.InboundEmailResult result = feedback.handleInboundEmail(email, env);
    Test.stopTest();
    }
}