public with sharing class BigWinsFormTriggerHandler {
    public class BigWinsFormAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<RC_Quote_Template__c> templateIds = [SELECT Id FROM RC_Quote_Template__c WHERE Name = 'Glip Message' LIMIT 1];
            RingCentralVariousSettings__c cs = RingCentralVariousSettings__c.getInstance();
            String email = cs.Glip_Email__c;
            String orgWideEmail = cs.Send_From__c;
            List<OrgWideEmailAddress> orgWideEmailIds = [SELECT Id FROM OrgWideEmailAddress where Address = :orgWideEmail limit 1];

            List<BigWins_Form__c> bwNewList = (List<BigWins_Form__c>) Trigger.New;
            Map<Id, BigWins_Form__c> bwOldMap = (Map<Id, BigWins_Form__c>) Trigger.oldMap;

            if (templateIds.size() > 0 && orgWideEmailIds.size() > 0) {
                for (BigWins_Form__c bw : bwNewList) {
                    if (bw.Publishing_Date__c != null && bwOldMap.get(bw.Id).Publishing_Date__c == null) {
                        sendUpdateToGlip(bw.Id, bw.LastAttachedPDFId__c, templateIds[0].id, email, orgWideEmailIds[0].id);
                    }
                }
            }
        }
    }

    @future(callout=true)
    public static void sendUpdateToGlip(String bigWinFormId, String pdfId, String templateId, String email, String orgWideEmailId) {
        String templateBody;
        Map <String, Map <String, String> > templateMap = new Map <String, Map <String, String> >();

        templateMap = TemplateEngine.getTemplateBody(templateId);
        templateBody = TemplateEngine.createFromString(bigWinFormId, templateMap.get('template').get('content'), templateMap.get('parameters'));

        if (orgWideEmailId != null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new String[]{
                email
            });
            message.setOrgWideEmailAddressId(orgWideEmailId);
            message.setEntityAttachments(new String[]{
                pdfId
            });
            message.setHtmlBody(templateBody);
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{
                message
            };
            Messaging.sendEmail(messages);
        }
    }
}