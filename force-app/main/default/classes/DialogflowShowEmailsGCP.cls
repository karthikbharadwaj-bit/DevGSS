@RestResource(urlMapping='/getCaseEmailsForGCP')
global with sharing class DialogflowShowEmailsGCP {

    // ---------- DTO (single email) ----------
    global class EmailDTO {
        public String  Subject;
        public String  FromAddress;
        public String  ToAddress;
        public String  CcAddress;
        public String  BccAddress;
        public Datetime MessageDate;
        public Datetime CreatedDate;
        public String  BodyPlain;      // Text-only body (HTML stripped if needed)
        public String  CaseNumber;

        public EmailDTO(EmailMessage em) {
            this.Subject              = em.Subject;
            this.FromAddress          = em.FromAddress;
            this.ToAddress            = em.ToAddress;
            this.CcAddress            = em.CcAddress;
            this.BccAddress           = em.BccAddress;
            this.MessageDate          = em.MessageDate;
            this.CreatedDate          = em.CreatedDate;
            this.BodyPlain            = normalizeBody(em);
            this.CaseNumber           = (em.Parent != null) ? em.Parent.CaseNumber : null;
        }
    }

    // ---------- REST entry (returns the latest email only) ----------
    @HttpPost
    global static void getEmailsByCaseId() {
        try {
            // Parse body
            RestRequest req = RestContext.request;
            String raw = (req.requestBody == null) ? '' : req.requestBody.toString();

            Map<String, Object> body =
                (Map<String, Object>) JSON.deserializeUntyped(raw);

            Id recordId = (Id) body.get('recordId');
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Missing recordId');
            }

            // Pull only the most recent email for the case
            // (Prefer MessageDate; fall back to CreatedDate and Id for tie-break)
            EmailMessage latest;
            try {
                latest = [
                    SELECT Id, ParentId, Subject, FromAddress, ToAddress, CcAddress, BccAddress,
                           MessageDate, CreatedDate, TextBody, HtmlBody, Parent.CaseNumber
                    FROM EmailMessage
                    WHERE ParentId = :recordId
                    ORDER BY MessageDate DESC, CreatedDate DESC, Id DESC
                    LIMIT 1
                ];
            } catch (QueryException qe) {
                // No rows
                latest = null;
            }

            Map<String, Object> resp = new Map<String, Object>();
            resp.put('success', true);

            if (latest == null) {
                resp.put('hasEmail', false);
                resp.put('message', 'No email messages found for this case.');
            } else {
                resp.put('hasEmail', true);
                resp.put('email', new EmailDTO(latest));
            }

            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(resp));

        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }

    // ---------- helpers ----------
    private static String normalizeBody(EmailMessage em) {
        String body = em.TextBody;
        if (String.isBlank(body) && em.HtmlBody != null) {
            body = stripHtml(em.HtmlBody);
        }
        if (body != null) {
            Integer MAX = 100000; // keep payloads reasonable
            if (body.length() > MAX) { 
                body = body.substring(0, MAX);
            }
            body = body.replaceAll('[\\u00A0\\s]+', ' ').trim(); // collapse whitespace incl. &nbsp;
        }
        return body;
    }

    private static String stripHtml(String html) {
        String txt = html != null ? html : '';
        txt = txt.replaceAll('<[^>]+>', ' ');             // remove tags
        txt = txt.replace('&nbsp;', ' ')                  // quick entity decode
                 .replace('&amp;', '&')
                 .replace('&lt;', '<')
                 .replace('&gt;', '>');
        return txt;
    }
}