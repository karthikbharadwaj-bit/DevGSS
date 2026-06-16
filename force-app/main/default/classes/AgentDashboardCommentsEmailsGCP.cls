@RestResource(urlMapping='/cases/email-comments')
global with sharing class AgentDashboardCommentsEmailsGCP {

    private static final Integer DEFAULT_CASE_COUNT = 30;
    
    private static Integer getCaseCount() {
        GCP_Feature_Toggle__c gcp = GCP_Feature_Toggle__c.getInstance();
        return (gcp != null && gcp.Agent_Dashboard_CaseCount__c != null)
            ? Integer.valueOf(gcp.Agent_Dashboard_CaseCount__c)
            : DEFAULT_CASE_COUNT;
    }

    // ===== Request Wrapper =====
    global class RequestWrapper {
        public List<Id> recordIDs;
    }

    // ===== Response Wrapper =====
    global class CaseData {
        public Id recordID;
        public List<String> emails = new List<String>();
        public List<String> comments = new List<String>();
    }

    @HttpPost
    global static List<CaseData> getEmailAndComments() {
        List<CaseData> response = new List<CaseData>();
        RestRequest req = RestContext.request;
        if (req == null || req.requestBody == null) {
            return response;
        }
        RequestWrapper request;
        try {
            request = (RequestWrapper) JSON.deserialize(req.requestBody.toString(), RequestWrapper.class);
        } catch (Exception e) {
            return response;
        }
        if (request == null || request.recordIDs == null || request.recordIDs.isEmpty()) {
            return response;
        }
        
        Integer caseCount = getCaseCount();

        List<Id> caseIds = new List<Id>();
        for (Integer i = 0; i < request.recordIDs.size() && i < caseCount; i++) {
            caseIds.add(request.recordIDs[i]);
        }

        Map<Id, CaseData> caseDataMap = new Map<Id, CaseData>();

        for (Id cId : caseIds) {
            CaseData cd = new CaseData();
            cd.recordID = cId;
            caseDataMap.put(cId, cd);
        }

        for (Case c : [
            SELECT Id,
                (SELECT TextBody FROM EmailMessages ORDER BY CreatedDate DESC LIMIT 1)
            FROM Case
            WHERE Id IN :caseIds
        ]) {
            CaseData cd = caseDataMap.get(c.Id);
            if (cd != null && c.EmailMessages != null && !c.EmailMessages.isEmpty()) {
                String body = c.EmailMessages[0].TextBody;
                if (String.isNotBlank(body)) {
                    cd.emails.add(stripHtml(body));
                    system.debug('Emails::'+cd.emails.size());
                }
            }
        }

        for (CaseComment cc : [
            SELECT ParentId, CommentBody
            FROM CaseComment
            WHERE ParentId IN :caseIds
        ]) {
            CaseData cd = caseDataMap.get(cc.ParentId);
            if (cd != null && String.isNotBlank(cc.CommentBody)) {
                cd.comments.add(stripHtml(cc.CommentBody));
            }
        }

        for (Id cId : caseIds) {
            response.add(caseDataMap.get(cId));
        }
        return response;
    }

    private static String stripHtml(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String s = input.replaceAll('<[^>]+>', ' ');
        s = s.replaceAll('&nbsp;', ' ');
        s = s.replaceAll('&amp;', '&');
        s = s.replaceAll('&lt;', '<');
        s = s.replaceAll('&gt;', '>');
        s = s.replaceAll('&quot;', '"');
        s = s.replaceAll('\\s+', ' ').trim();
        return s;
    }
}