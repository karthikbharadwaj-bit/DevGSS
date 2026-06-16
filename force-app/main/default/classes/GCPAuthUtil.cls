public class GCPAuthUtil {

    public static final String ESCALATION_SENTIMENT = 'escalation sentiment';
    public static final String JIRA_COMMENT_SUMMARY = 'jiraCommentSummary';
    public static final String CHAT_TRANSCRIPT_SUMMARY = 'chatTranscriptSummary';
    public static final String AGENT_DASHBOARD = 'agentDashboard';
    public static final String FEED_SUMMARY = 'feedSummary';
    public static final String RED_ACCOUNT_SUMMARY = 'redAccountSummary';
    public static final String NEXT_STEPS = 'nextSteps';
    
    public class GCPConfig {
        public String serviceAccountEmail;
        public String audience;
        public String identityTokenUrl;
        public String cloudRunEndpoint;
        public String certificate;
    }

    public static GCPConfig loadConfig(String mode) {
        GCP_Endpoint_Settings__c config = GCP_Endpoint_Settings__c.getInstance();
        if (config == null) {
            throw new GCPCalloutException('GCP_Endpoint_Settings__c is Empty.');
        }

        String m = (mode == null) ? '' : mode.trim().toLowerCase();

        GCPConfig result = new GCPConfig();
        result.serviceAccountEmail = config.Service_Account_Email__c;
        result.identityTokenUrl    = config.Identity_Token_URL__c;
        result.certificate         = config.Certificate_Name__c;
        // Choose endpoint based on mode
        if (m == 'article' || m == 'articles' || m == 'knowledge' || m == 'knowledgearticles') {
            result.audience         = config.Article_Cloud_Run_Endpoint__c;
            result.cloudRunEndpoint = config.Article_Cloud_Run_Endpoint__c;
        } else if (m == 'casecomment' || m == 'comments' || m == 'casecomments') {
            // case comment summary
            result.audience         = config.Case_Comment_Cloud_Run_Endpoint__c ;
            result.cloudRunEndpoint = config.Case_Comment_Cloud_Run_Endpoint__c ;
        } else if (m == 'email' || m == 'emails' || m == 'emailsummary' || m == 'caseemail' || m == 'caseemails') {
            // email summary
            result.audience         = config.Case_Emails_Cloud_Run_Endpoint__c ;  
            result.cloudRunEndpoint = config.Case_Emails_Cloud_Run_Endpoint__c ;   
        } else if (m.equalsIgnoreCase(JIRA_COMMENT_SUMMARY)) {
            // jira comment summary
            result.audience         = config.Jira_Comment_Summary_Endpoint__c ;
            result.cloudRunEndpoint = config.Jira_Comment_Summary_Endpoint__c ;
        } else if (m.equalsIgnoreCase(CHAT_TRANSCRIPT_SUMMARY)) {
            // chat transcript summary
            result.audience         = config.Chat_Transcript_Summary_Endpoint__c ;
            result.cloudRunEndpoint = config.Chat_Transcript_Summary_Endpoint__c ;  
        } else if (m.equals(ESCALATION_SENTIMENT)) {
            // email summary
            result.audience         = config.Escalation_Sentiment_Endpoint__c ;  
            result.cloudRunEndpoint = config.Escalation_Sentiment_Endpoint__c ;   
            } else if (m.equalsIgnoreCase(AGENT_DASHBOARD)) {
            // agent dashboard
            result.audience         = config.Agent_Dashboard_Endpoint__c ;
            result.cloudRunEndpoint = config.Agent_Dashboard_Endpoint__c ;
            } else if (m.equalsIgnoreCase(FEED_SUMMARY)) {
                // feed summary
                result.audience         = config.Feed_Summary_Endpoint__c;
                result.cloudRunEndpoint = config.Feed_Summary_Endpoint__c;
            } else if (m.equalsIgnoreCase(RED_ACCOUNT_SUMMARY)) {
                result.audience         = config.Red_Account_Summary_Endpoint__c;
                result.cloudRunEndpoint = config.Red_Account_Summary_Endpoint__c;
            } else if (m.equalsIgnoreCase(NEXT_STEPS)) {
                result.audience         = config.Next_Steps_Endpoint__c;
                result.cloudRunEndpoint = config.Next_Steps_Endpoint__c;
            }
            else{
            // default = Similar Cases
            result.audience         = config.Cloud_Run_Endpoint__c;
            result.cloudRunEndpoint = config.Cloud_Run_Endpoint__c;
        }

        if (String.isBlank(result.serviceAccountEmail) ||
            String.isBlank(result.identityTokenUrl) ||
            String.isBlank(result.audience) ||
            String.isBlank(result.cloudRunEndpoint) ||
            String.isBlank(result.certificate)) {
            throw new GCPCalloutException('One or more required GCP_Endpoint_Settings__c fields are missing or blank.');
        }
        return result;
    }

    public static String createSignedJWT(GCPConfig config) {
        Long iat = DateTime.now().getTime() / 1000;
        Long exp = iat + 3600;

        Map<String, Object> claims = new Map<String, Object>{
            'iss' => config.serviceAccountEmail,
            'sub' => config.serviceAccountEmail,
            'aud' => config.identityTokenUrl,
            'iat' => iat,
            'exp' => exp,
            'target_audience' => config.audience
        };

        return jwtEncode(claims, config.certificate, 'RS256');
    }

    public static String exchangeJWTForIdentityToken(String jwt, String identityTokenUrl) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(identityTokenUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + EncodingUtil.urlEncode(jwt, 'UTF-8'));

        Http h = new Http();
        HttpResponse res = h.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String idToken = (String) resBody.get('id_token');
            if (String.isBlank(idToken)) {
                throw new CalloutException('ID Token not found in response: ' + res.getBody());
            }
            return idToken;
        } else {
            throw new CalloutException('Failed to get ID Token: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }

    private static String jwtEncode(Map<String, Object> claims, String certName, String algorithm) {
        String headerJson = '{"alg":"RS256","typ":"JWT"}';
        String claimsJson = JSON.serialize(claims);
        String encodedHeader = base64UrlEncode(Blob.valueOf(headerJson));
        String encodedClaims = base64UrlEncode(Blob.valueOf(claimsJson));
        String signatureBase = encodedHeader + '.' + encodedClaims;

        Blob signature = Crypto.signWithCertificate('RSA-SHA256', Blob.valueOf(signatureBase), certName);
        String encodedSignature = base64UrlEncode(signature);

        return signatureBase + '.' + encodedSignature;
    }

    private static String base64UrlEncode(Blob input) {
        String encoded = EncodingUtil.base64Encode(input);
        return encoded.replace('+', '-').replace('/', '_').replaceAll('=+$', '');
    }
    
    public static Boolean getRedactionFlag() {
        AI_Feature_Pilot_Control__c customSettingRow = AI_Feature_Pilot_Control__c.getInstance();
        Boolean result = false;
        if (customSettingRow != null) {
            result = customSettingRow.Redaction_Needed__c;
        }
        return result;
    }

    public class GCPCalloutException extends Exception {}
}