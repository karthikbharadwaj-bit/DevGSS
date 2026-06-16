@isTest
private class Test_MasterLeadUpload {
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void TestMasterLeadUpload() {
    	Messaging.InboundEmail email = new Messaging.InboundEmail();
   		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
   		Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();

   		email.subject = 'test';
   		env.fromAddress = 'user@acme.com';
		
		list<document> listdoc = [SELECT id,Name,Body FROM Document WHERE Name='TestLeadCSV' limit 1];
		try {
			inAtt.body = listdoc[0].body;
		} catch (Exception e) {
			inAtt.body = blob.valueOf('"57580213","INIT","Monik","Wagner","monik Wagner","","","","","","5627081661","Monik@vanlinemovers.com","7076231756","INITIAL","Professional","RingCentral","","testpid","Pacific Standard Time","","","","","","",""*EOL*');
		}
		inAtt.fileName = 'TestLeadCSV.csv';
		
   		email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
   		
        MasterLeadUpload objMasLeadUpd = new MasterLeadUpload();
        objMasLeadUpd.handleInboundEmail(email, env);
    }
}