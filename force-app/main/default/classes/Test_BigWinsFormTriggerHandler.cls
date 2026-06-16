@isTest
private class Test_BigWinsFormTriggerHandler {

    @testSetup static void prepareData() {
        BigWins_Form__c bw = new BigWins_Form__c(
                            HUD__c = 'Irrelevant',
                            Softphone__c = 'Irrelevant',
                            Website__c = '123'
                        );
        insert bw;

        String body = 'testBody';
        Blob bl = Blob.valueOf(body);

        Attachment att = new Attachment(
            ParentId = bw.Id,
            Name = 'TestPDF.pdf',
            Body = bl
        );
        insert att;

        bw.LastAttachedPDFId__c = att.Id;
        update bw;

        RC_Quote_Template__c template = new RC_Quote_Template__c();
        insert template;
    }

    @isTest
    static void testEmailSending() {
        Integer emailLimitsBefore = Limits.getEmailInvocations();

        Test.startTest();

        BigWins_Form__c bw = [SELECT id, LastAttachedPDFId__c 
                                FROM BigWins_Form__c 
                                LIMIT 1];
        List<OrgWideEmailAddress> orgWideEmailIds = [SELECT Id 
                                                    FROM OrgWideEmailAddress 
                                                    ORDER BY CreatedDate ASC];
        List<RC_Quote_Template__c> templateIds = [SELECT id 
                                                  FROM RC_Quote_Template__c];
        String email = 'test@email.com';

        bw.Publishing_Date__c = Date.today();

        try{
            BigWinsFormTriggerHandler.sendUpdateToGlip(bw.Id, bw.LastAttachedPDFId__c, templateIds[0].id, email, orgWideEmailIds[0].id);
            // it is a future method - we should call Test.stopTest() inside try expression
            Test.stopTest();
        }catch(Exception ex) {
            ExceptionHelper.checkIsMassEmailException(ex);
            return;
        }

        System.assertEquals(emailLimitsBefore, Limits.getEmailInvocations());
    }
}