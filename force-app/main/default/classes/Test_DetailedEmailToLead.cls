/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class Test_DetailedEmailToLead {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestDetailedEmailToLead() {
        
		DetailedEmailToLead detl = new DetailedEmailToLead();
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
		Messaging.InboundEmail.TextAttachment inAttText = new Messaging.InboundEmail.TextAttachment();
		email.subject = 'test';
		env.fromAddress = 'user@acme.com';
		inAtt.body = blob.valueOf('"57580213","INIT","Monik","Wagner","monik Wagner","","","","","","5627081661","Monik@vanlinemovers.com","7076231756","INITIAL","Professional","RingCentral","","testpid","Pacific Standard Time","","","","","","",""*EOL*');
		inAtt.fileName = 'attach.csv';
		inAttText.fileName = 'attach.csv';
		email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
		detl.handleInboundEmail(email, env );  		
	
    }
}