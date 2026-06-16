public class DialogFlowAuth {
    private static final String GOOGLE_AUTH_URL = 'https://oauth2.googleapis.com/token';
    private static final String SERVICE_ACCOUNT_EMAIL = 'quantiphiandgss@appspot.gserviceaccount.com';
    private static final String SCOPE = 'https://www.googleapis.com/auth/dialogflow';
    private static final String AUDIENCE = 'https://oauth2.googleapis.com/token';
    private static final String CERTIFICATE_NAME = 'privatekey';
    
    public static String getAccessToken() {
        
        try {
            String jwt = generateJWT();
            return exchangeJWTForAccessToken(jwt);
        } catch (Exception e) {
            System.debug('Error generating access token: ' + e.getMessage());
            return null;
        }
    }
    
    private static String generateJWT() {
        Long issuedAt = Datetime.now().getTime() / 1000;
        Long expiryTime = issuedAt + 3600;
        
        String header = '{"alg":"RS256","typ":"JWT"}';
        String payload = '{"iss":"' + SERVICE_ACCOUNT_EMAIL + '","scope":"' + SCOPE + '","aud":"' + AUDIENCE + '","exp":' + expiryTime + ',"iat":' + issuedAt + '}';
        
        String encodedHeader = encodeBase64URL(header);
        String encodedPayload = encodeBase64URL(payload);
        
        String unsignedToken = encodedHeader + '.' + encodedPayload;
        String signature = signWithPrivateKey(unsignedToken);
        
        return unsignedToken + '.' + signature;
    }
    
    private static String encodeBase64URL(String input) {
        return EncodingUtil.base64Encode(Blob.valueOf(input))
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
    }
    
    private static String base64URLencode(Blob input){    
        String output = '';
        if (input != null) {
            output = EncodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
        }       
        return output;
    }
    @TestVisible
    private static String signWithPrivateKey(String unsignedToken) {
        Blob signature = Crypto.signWithCertificate('RSA-SHA256', Blob.valueOf(unsignedToken), CERTIFICATE_NAME);
        return base64URLencode(signature);
    }
    
    private static String exchangeJWTForAccessToken(String jwt) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(GOOGLE_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('access_token');
        } else {
            System.debug('Error: ' + res.getBody());
            return null;
        }
    }
    
    @TestVisible
    private static String generateJWTForTest() {
        Long currentTime = Datetime.now().getTime()/1000;
        
        // Create JWT header
        Map<String, String> header = new Map<String, String>{
            'alg' => 'RS256',
                'typ' => 'JWT'
                };
                    
                    // Create JWT payload
                    Map<String, Object> payload = new Map<String, Object>{
                        'iss' => 'test-issuer@test.com',
                            'scope' => 'https://www.googleapis.com/auth/dialogflow',
                            'aud' => 'https://oauth2.googleapis.com/token',
                            'exp' => currentTime + 3600,
                            'iat' => currentTime
                            };
                                
                                // Encode header and payload
                                String encodedHeader = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(header)))
                                .replace('+', '-')
                                .replace('/', '_')
                                .replace('=', '');
        
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(payload)))
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
        
        // Add a test signature
        String signature = EncodingUtil.base64Encode(Blob.valueOf('test-signature'))
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
        
        return encodedHeader + '.' + encodedPayload + '.' + signature;
    }
}