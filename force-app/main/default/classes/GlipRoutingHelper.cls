public with sharing class GlipRoutingHelper {

    public class GlipRoutingException extends Exception{}

    //do we want this flow?
    //what to do with credentials?
    public static Glip_Routing_Settings__c glipRoutingSettings = Glip_Routing_Settings__c.getOrgDefaults();

    public static final String RINGCENTRAL_CLIENTID = EncodingUtil.urlEncode(glipRoutingSettings.RC_ClientId__c, 'UTF-8');
    public static final String RINGCENTRAL_CLIENT_SECRET = EncodingUtil.urlEncode(glipRoutingSettings.RC_ClientSecret__c, 'UTF-8');
    public static final String RINGCENTRAL_SERVER = glipRoutingSettings.RC_Server__c;
    public static final String BOT_USER_ID = glipRoutingSettings.RC_BotId__c;
    public static final String BOT_EMAIL = glipRoutingSettings.RC_BotEmail__c;
    public static final String GLIP_WEBHOOK_URL = glipRoutingSettings.Webhook_URL__c;
    
    public static final String SUCCESSFUL_NOTIFICATION_EDGE = 'Next Node';
    public static final String UNSUCCESSFUL_NOTIFICATION_EDGE = 'False';
    public static final String TOKEN_FAILURE_EDGE = 'True';

    public static String refreshToken;
    public static String accessToken;
    public static Integer expirationSeconds;

    public static void sendAccessTokenExceptionNotification() {
        //Send a notification at most every 20 minutes
        if (glipRoutingSettings.Last_MOPS_Notification_Time__c == null || Datetime.now() > glipRoutingSettings.Last_MOPS_Notification_Time__c.addMinutes(20)) {
            String jsonPayload = '{"title": "LeanData Glip Token Failed","body": "Refresh Token for LeanData app invalid or expired."}';
            HttpResponse rcResponse = sendPostRequest('POST', 'application/json', 'application/json', GLIP_WEBHOOK_URL, jsonPayload, null);
            glipRoutingSettings.Last_MOPS_Notification_Time__c = Datetime.now();
            update glipRoutingSettings;
        }
    }

    public static String getCachedRefreshToken() {
        String refreshToken0 = glipRoutingSettings.RC_Refresh_Token_0__c;
        String refreshToken1 = glipRoutingSettings.RC_Refresh_Token_1__c;
        GlipRoutingHelper.refreshToken = refreshToken0 + refreshToken1;
        return GlipRoutingHelper.refreshToken;
    }

    public static String getCachedAccessToken() {
        String accessToken0 = glipRoutingSettings.RC_Access_Token_0__c;
        String accessToken1 = glipRoutingSettings.RC_Access_Token_1__c;
        GlipRoutingHelper.accessToken = accessToken0 + accessToken1;
        return GlipRoutingHelper.accessToken;
    }	

    public static void cacheNewTokens() {
        glipRoutingSettings.RC_Access_Token_0__c = GlipRoutingHelper.accessToken.substring(0,200);
        glipRoutingSettings.RC_Access_Token_1__c = GlipRoutingHelper.accessToken.substring(200);
        glipRoutingSettings.RC_Refresh_Token_0__c = GlipRoutingHelper.refreshToken.substring(0,200);
        glipRoutingSettings.RC_Refresh_Token_1__c = GlipRoutingHelper.refreshToken.substring(200);
        //let's give a 5 minute margin
        glipRoutingSettings.Access_Token_Expiration_Time__c = Datetime.now().addSeconds(expirationSeconds - 300);
        //if we're caching the token, this token is good,
        //so we erase notifications on past bad tokens.
        glipRoutingSettings.Last_MOPS_Notification_Time__c = null;
        update glipRoutingSettings;
    }


    public static HttpResponse sendPostRequest(String method, String acceptForm, String contentType, String endPoint, String body, String authorization){
        Http http = new Http();
        HttpRequest rcAPIRequest = new HttpRequest();
        rcAPIRequest.setEndpoint(endPoint);
        rcAPIRequest.setMethod(method);
        rcAPIRequest.setHeader('Accept', acceptForm);
        rcAPIRequest.setHeader('Content-Type', contentType);
        rcAPIRequest.setBody(body);
        if (authorization != null) {
            rcAPIRequest.setHeader('Authorization', authorization);
        }
        return http.send(rcAPIRequest);
    }

    public static String sendGlipNotification(Lead l, Id userId, Id templateId) {
        //any reason to null check/query list?
        UserSelector uSelector = new UserSelector();
        User userWithEmail = (User) uSelector.selectUserByIdForGlip(new list<Object>{userId})
                                                                                        .executeQuery()[0];
        String glipMessageBody = generateGlipMessageBody(l, userWithEmail.FirstName, templateId);
        String accessToken;
        String returnEdge = SUCCESSFUL_NOTIFICATION_EDGE;
        Boolean newTokensReceived = false;
		
            if (glipRoutingSettings.Access_Token_Expiration_Time__c != null && Datetime.now() < glipRoutingSettings.Access_Token_Expiration_Time__c) {
                getCachedAccessToken();
            } else {
                try {
                    getAccessToken();
                    newTokensReceived = true;
                } catch (Exception e) {
                    sendAccessTokenExceptionNotification();
                    return TOKEN_FAILURE_EDGE;
                }
            }
            
            try {
                String rcUserId = getRCUserId(userWithEmail.Email, GlipRoutingHelper.accessToken);
                String rcChatId = findOrCreateRCConversation(rcUserId, userWithEmail.Email, GlipRoutingHelper.accessToken);
                postGlipMessage(glipMessageBody, rcChatId, GlipRoutingHelper.accessToken);
            } catch (Exception e) {
                returnEdge = UNSUCCESSFUL_NOTIFICATION_EDGE;
            }
            
            //DML must be performed after callout,
            //otherwise we'd perform this logic earlier
            if (newTokensReceived) {
                cacheNewTokens();
            }
        return returnEdge;
    }

    public static String findOrCreateRCConversation(String userId, String userEmail, String accessToken) {
        List<Map<String,Object>> userList = new List<Map<String,Object>>{
            new Map<String,Object>{'id' => userId, 'email' => userEmail},
            new Map<String,Object>{'id' => BOT_USER_ID, 'email' => BOT_EMAIL} 
        };
        Map<String,Object> userParams = new Map<String,Object>{'members' => userList};
        HttpResponse rcResponse = sendPostRequest('POST', 'application/json', 'application/json', RINGCENTRAL_SERVER + '/restapi/v1.0/glip/conversations', JSON.serialize(userParams), 'Bearer ' + accessToken);
        String responseBodyString = rcResponse.getBody();
        Map<String,Object> responseBody = (Map<String,Object>) JSON.deserializeUntyped(responseBodyString);
        System.debug(responseBodyString);
        String chatId = (String) responseBody.get('id');
        System.debug(chatId);
        return chatId;
    }

    public static String getRCUserId(String email, String accessToken) {
        Map<String,Object> searchParams = new Map<String,Object>{'searchString' => email};
        HttpResponse rcResponse = sendPostRequest('POST', 'application/json', 'application/json', RINGCENTRAL_SERVER + '/restapi/v1.0/account/~/directory/entries/search', JSON.serialize(searchParams), 'Bearer ' + accessToken);
        String responseBodyString = rcResponse.getBody();
        Map<String,Object> responseBody = (Map<String,Object>) JSON.deserializeUntyped(responseBodyString);
        List<Object> userRecords = (List<Object>) responseBody.get('records');
        Map<String,Object> user = (Map<String,Object>) userRecords[0];
        String userId = (String) user.get('id');
        return userId;
    }

    public static String generateGlipMessageBody(Lead l, String firstName, Id emailTemplateId) {
        //later make this html
        String emailBody;
        List<EmailTemplate> emailTemplateList = [SELECT Body FROM EmailTemplate WHERE Id = :emailTemplateId];
        if (!emailTemplateList.isEmpty()) {
            EmailTemplate emailTemplate = emailTemplateList[0];
            String emailTemplateBody = emailTemplate.Body;
            List<Messaging.RenderEmailTemplateBodyResult> emailTemplateResults = Messaging.renderEmailTemplate(l.Id, null, new List<String>{emailTemplateBody});
            emailBody = emailTemplateResults[0].getMergedBody();
        } else {
            emailBody = firstName + ',\r\n';
            emailBody += 'Lead with source ' + ((String) l.LeadSource) + ' routed via LeanData.';
        }
        
        return emailBody;
    }


    public static String generateBodyPayload() {
        return '&grant_type=refresh_token'
            + '&refresh_token=' + getCachedRefreshToken();
    }

    public static void postGlipMessage(String glipMessage, String rcChatId, String accessToken) {
        HttpResponse rcResponse = sendPostRequest('POST', 'application/json', 'application/json', RINGCENTRAL_SERVER
                                                  + '/restapi/v1.0/glip/chats/' + rcChatId
                                                  + '/posts', JSON.serialize(new Map<String,Object>{'text' => glipMessage}),
                                                  'Bearer ' + accessToken);
    }

    public static String getAccessToken() {
        String authcode = EncodingUtil.base64Encode
                                            (Blob.valueOf(RINGCENTRAL_CLIENTID + ':' + RINGCENTRAL_CLIENT_SECRET));
        HttpResponse rcResponse = sendPostRequest('POST', 'application/json', 'application/x-www-form-urlencoded', RINGCENTRAL_SERVER + '/restapi/oauth/token', generateBodyPayload(), 'Basic ' + authcode);
        if (rcResponse.getStatusCode() != 200) {
            throw new GlipRoutingException('Failed to Generate Access Code');
        }
        Map<String,Object> responseObject = (Map<String,Object>) JSON.deserializeUntyped(rcResponse.getBody());
        String accessToken = (String) responseObject.get('access_token');
        String refreshToken = (String) responseObject.get('refresh_token');
        Integer expirationSeconds = (Integer) responseObject.get('expires_in');
        GlipRoutingHelper.expirationSeconds = expirationSeconds; 
        GlipRoutingHelper.refreshToken = refreshToken;
        GlipRoutingHelper.accessToken = accessToken;
        return accessToken;
    }

    public class MockGlipResponder implements HttpCalloutMock {
        
        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            HttpResponse res = new HttpResponse();
            if (endpoint.indexOf('conversations') != -1) {
                res.setBody('{"id":"666"}');
            } else if (endpoint.indexOf('directory') != -1) {
                res.setBody('{"records":[{"id":"555"}]}');
            } else if (endpoint.indexOf('chats') != -1) {
                res.setBody('{"status":"success"}');
            } else if (endpoint.indexOf('oauth') != -1) {
                String respBody = '{"expires_in" : 3600,';
                respBody += '"access_token" : "XXXCXXXasdfddkkkkkkkkkfjasdfasdfasdfasdzaeqwadfssagafwefdsagasdfasdfasdfweqfdsafasdgawrfwa';
                respBody += 'efasdfasdfweqadsfwaedsfrwgaeafgefawdsfawegrawfedsawdsfawefasdfasdfasdgawrfawefawefasedfasdfasdfasegfrefarsfdfasdfasdfasdf",';
                respBody += '"refresh_token" : "XXXCXXXasdfddkkkkkkkkkfjasdfasdfasdfasdzaeqwadfssagafwefdsagasdfasdfasdfweqf';
                respBody += 'dsafasdgawrfwaefasdfasdfweqadsfwaedsfrwgaeafgefawdsfawegrawfedsawdsfawefasdfasdfasdgawrfawefawefasedfasdfasdfasegfrefarsfdfasdfasdfasdf"}';
                res.setStatusCode(200);
                res.setBody(respBody);
            }
            return res;
        }
    }
}