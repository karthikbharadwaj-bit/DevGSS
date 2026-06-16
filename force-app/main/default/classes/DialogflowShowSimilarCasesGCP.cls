@RestResource(urlMapping='/getCaseDetailsForGCP')
global with sharing class DialogflowShowSimilarCasesGCP {

    public class CaseDTO {
        public String CaseNumber;
        public String Subject;
        public String Description;
        public String Resolution;

        public CaseDTO(Case c) {
            this.CaseNumber = c.CaseNumber;
            this.Subject = c.Subject;
            this.Description = c.Description;
            this.Resolution = c.Resolution__c;

        }
    }

    @HttpPost
    global static void getCaseDetailsBySubject() {
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            String recordId = (String) bodyMap.get('recordId');
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Missing recordId');
            }

            List<Case> allClosedCases = CaseSelectorDialogflow.getInstance().getRelevantClosedCases(recordId);

            List<CaseDTO> caseList = new List<CaseDTO>();
            for (Case c : allClosedCases) {
                caseList.add(new CaseDTO(c));
            }

            Map<String, Object> finalResponse = new Map<String, Object>{
                'cases' => caseList,
                'caseCount' => caseList.size()
            };

            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(finalResponse));
            res.statusCode = 200;
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}