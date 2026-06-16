public with sharing class pdfGenerator {

    public static List<RC_Quote_Template__c> pdfTemplateList {get;set;}
    public static String pdfTemplateListJson {get;set;}
    public static String objectId {get;set;}
    public static String objectLabel {get;set;}

    public pdfGenerator() {
        objectId = ApexPages.currentPage().getParameters().get('objectid');
        objectLabel = AquivaHelper.getObjectLabelById(objectId);
        pdfTemplateList = getTemplates(objectId);
        pdfTemplateListJson = JSON.serialize(getTemplates(objectId));
    }

    public static List<RC_Quote_Template__c> getTemplates(String objectId) {
        String filterField = 'ObjectName__c';
        String value = AquivaHelper.getObjectNameById(objectId);
               value = value.replace('__c', '');

        return getTemplatesByField(filterField, value);
    }

    public static List<RC_Quote_Template__c> getTemplatesByField(String filterField, String value) {
        String templateObjectAPIName = 'RC_Quote_Template__c';
        String queryStr = 'SELECT Id, Name FROM '+templateObjectAPIName+' WHERE '+filterField+' =: value AND Active__c = true';

        List<RC_Quote_Template__c> templateList = Database.query(queryStr);

        return templateList;
    }

    @RemoteAction
    static public Map<string,string> attachPdf(string templateId, string objectId) {
        Map<string,string> result = new Map<string, string>();

        try {
            if(objectId != null && templateId != null) {
                PageReference pdfPage = Page.PreviewPDF;
                              pdfPage.getParameters().put('objectid', objectId);
                              pdfPage.getParameters().put('templateId', templateId);


                /* generate the pdf blob */
                Blob pdfBlob;
                if(Test.isRunningTest()) {
                    pdfBlob = EncodingUtil.base64Decode('Test');
                } else {
                    pdfBlob = pdfPage.getContent();
                }

                BigWins_Form__c bigwinRecord = [SELECT Name, Account_Name__r.Name,Account_Exective__c,Industry_ReadOnly__c,Competitors__c FROM BigWins_Form__c WHERE Id =: objectId LIMIT 1];
                if(bigwinRecord.Account_Exective__c==null) {
                    bigwinRecord.Account_Exective__c='';
                }
                String pdfName = ((bigwinRecord.Account_Name__r.Name != null) ? bigwinRecord.Account_Name__r.Name : bigwinRecord.Name)+' - '+(bigwinRecord.Industry_ReadOnly__c==null?'':bigwinRecord.Industry_ReadOnly__c)+' - '+(bigwinRecord.Competitors__c==null?'':bigwinRecord.Competitors__c);
                       pdfName = (pdfName.length() > 250) ? pdfName.substring(0, 250) : pdfName;
                       pdfName = pdfName+'.pdf';

                Attachment a = new Attachment(
                    parentId = objectId,
                    Name = pdfName,
                    body = pdfBlob
                );
                insert a;

                BigWins_Form__c bigwin = new BigWins_Form__c(
                    Id = objectId,
                    LastAttachedPDFId__c = a.Id
                );
                update bigwin;

                result.put('Status', 'OK');
            } else {
                result.put('Status', 'ERROR');
                result.put('Message', 'Template Id or Object Id is empty.');
            }

        } catch(Exception e) {
            result.put('Status', 'ERROR');
            result.put('Message', 'Error occured while generating pdf.');
        }

        return result;
    }
}