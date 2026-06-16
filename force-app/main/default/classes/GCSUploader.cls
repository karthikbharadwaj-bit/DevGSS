/**
 * @description Utility class to upload files to Google Cloud Storage using OAuth2 JWT authentication
 * 
 * PREREQUISITES:
 * 1. Remote Site Settings must be configured for:
 *    - https://oauth2.googleapis.com
 *    - https://storage.googleapis.com
 * 2. Certificate & Key Management must contain the service account certificate
 * 3. Service account must have appropriate GCS permissions
 * 4. Custom Metadata Type 'Ringo_GCS_Configuration__mdt' must have an active record
 * 
 * CONFIGURATION:
 * - Configuration is managed via Custom Metadata Type: Ringo_GCS_Configuration__mdt
 * - Create a record with IsActive__c = true in Setup → Custom Metadata Types
 */
public without sharing class GCSUploader {

    // Configuration cache
    private static Ringo_GCS_Configuration__mdt config;
    
    // Token cache for the current execution
    private static String cachedAccessToken;
    private static Long cachedTokenExpiryEpoch;

    /**
     * @description Retrieves the active GCS configuration from Custom Metadata
     * Configuration is cached after first retrieval for performance
     * @return Active GCS configuration record
     * @throws ConfigurationException if no active configuration found
     */
    private static Ringo_GCS_Configuration__mdt getConfiguration() {
        if (config != null) {
            return config;
        }
        
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT BucketName__c, ServiceAccountEmail__c, SigningCertificateName__c, DeveloperName,
                   TokenURI__c, Scope__c, UploadTimeoutSeconds__c, TokenTimeoutSeconds__c
            FROM Ringo_GCS_Configuration__mdt
            WHERE IsActive__c = true
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            String errorMsg = 'No active GCS Configuration found. Please create an active record in Ringo_GCS_Configuration__mdt';
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new ConfigurationException(errorMsg);
        }
        
        config = configs[0];
        
        // Validate required fields
        if (String.isBlank(config.BucketName__c)) {
            throw new ConfigurationException('BucketName__c is required in GCS Configuration');
        }
        if (String.isBlank(config.ServiceAccountEmail__c)) {
            throw new ConfigurationException('ServiceAccountEmail__c is required in GCS Configuration');
        }
        if (String.isBlank(config.SigningCertificateName__c)) {
            throw new ConfigurationException('SigningCertificateName__c is required in GCS Configuration');
        }
        
        System.debug('GCS Configuration loaded: ' + config.DeveloperName);
        return config;
    }

    /**
     * @description Upload a specific ContentVersion to Google Cloud Storage
     * @param contentVersionId The ID of the ContentVersion to upload
     * @param fileTitle The title to use for the uploaded file
     * @throws CalloutException if upload fails
     */
    public static void uploadFile(Id contentVersionId, String fileTitle) {
        
        if (contentVersionId == null || String.isBlank(fileTitle)) {
            throw new IllegalArgumentException('contentVersionId and fileTitle are required');
        }

        // 1. Fetch binary content with error handling
        List<ContentVersion> cvList = [
            SELECT VersionData, Title, FileExtension
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];
        
        if (cvList.isEmpty()) {
            throw new IllegalArgumentException('ContentVersion not found: ' + contentVersionId);
        }
        
        ContentVersion cv = cvList[0];
        Blob fileBlob = cv.VersionData;
        
        if (fileBlob == null) {
            throw new IllegalArgumentException('File has no content: ' + fileTitle);
        }
        
        String fileName = fileTitle + (String.isNotBlank(cv.FileExtension) ? '.' + cv.FileExtension : '');

        // 2. Get OAuth token (cached)
        String accessToken = getAccessToken();

        // 3. Get configuration
        Ringo_GCS_Configuration__mdt gcsConfig = getConfiguration();
        
        // 4. Upload file with improved error handling
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://storage.googleapis.com/upload/storage/v1/b/' +
                gcsConfig.BucketName__c +
                '/o?uploadType=media&name=' +
                EncodingUtil.urlEncode(fileName, 'UTF-8');
            
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'text/csv');
            req.setBodyAsBlob(fileBlob);
            
            // Use configured timeout or default to 120 seconds
            Integer timeout = (gcsConfig.UploadTimeoutSeconds__c != null ? 
                              Integer.valueOf(gcsConfig.UploadTimeoutSeconds__c) * 1000 : 120000);
            req.setTimeout(timeout);

            Http http = new Http();
            HttpResponse res = http.send(req);

            Integer statusCode = res.getStatusCode();
            String responseBody = res.getBody();
            
            System.debug('GCS Upload - File: ' + fileName + 
                         ' | Status: ' + statusCode + 
                         ' | Size: ' + fileBlob.size() + ' bytes');

            if (statusCode >= 200 && statusCode < 300) {
                System.debug('SUCCESS: File uploaded to GCS: ' + fileName);
            } else {
                String errorMsg = 'Failed to upload file ' + fileName + 
                                  ' | Status: ' + statusCode + 
                                  ' | Response: ' + responseBody;
                System.debug(LoggingLevel.ERROR, errorMsg);
                throw new CalloutException(errorMsg);
            }
        } catch (CalloutException ce) {
            throw ce; // Re-throw CalloutException
        } catch (Exception e) {
            String errorMsg = 'Unexpected error uploading file ' + fileName + ': ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new CalloutException(errorMsg);
        }
    }

    /**
     * @description Get an OAuth2 token from Google using signed JWT
     * Token is cached to avoid regenerating for each file (1-hour validity)
     * @return Access token for Google Cloud Storage API
     * @throws CalloutException if token request fails
     */
    private static String getAccessToken() {

        Long nowEpoch = DateTime.now().getTime() / 1000;

        // If token cached & still valid (with 60 second buffer) → reuse it
        if (cachedAccessToken != null &&
            cachedTokenExpiryEpoch != null &&
            nowEpoch < cachedTokenExpiryEpoch - 60) {
            
            System.debug('Using cached GCS access token');
            return cachedAccessToken;
        }

        System.debug('Generating new GCS access token');
        
        // Get configuration
        Ringo_GCS_Configuration__mdt gcsConfig = getConfiguration();
        
        try {
            // Generate new token (valid 1 hour)
            Long expiry = nowEpoch + 3600;

            // JWT header
            String headerJson = '{"alg":"RS256","typ":"JWT"}';

            // JWT claim
            String claimJson =
                '{"iss":"' + gcsConfig.ServiceAccountEmail__c + '",' +
                '"scope":"' + gcsConfig.Scope__c + '",' +
                '"aud":"' + gcsConfig.TokenURI__c + '",' +
                '"iat":' + nowEpoch + ',' +
                '"exp":' + expiry + '}';

            String base64Header = base64Url(Blob.valueOf(headerJson));
            String base64Claim  = base64Url(Blob.valueOf(claimJson));

            String unsignedJwt = base64Header + '.' + base64Claim;

            // Sign JWT with certificate
            Blob signature = Crypto.signWithCertificate(
                'RSA-SHA256',
                Blob.valueOf(unsignedJwt),
                gcsConfig.SigningCertificateName__c
            );

            String signedJwt = unsignedJwt + '.' + base64Url(signature);

            // Request token from Google
            HttpRequest req = new HttpRequest();
            req.setEndpoint(gcsConfig.TokenURI__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(
                'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' +
                signedJwt
            );
            
            // Use configured timeout or default to 60 seconds
            Integer timeout = (gcsConfig.TokenTimeoutSeconds__c != null ? 
                              Integer.valueOf(gcsConfig.TokenTimeoutSeconds__c) * 1000 : 60000);
            req.setTimeout(timeout);

            Http http = new Http();
            HttpResponse res = http.send(req);

            Integer statusCode = res.getStatusCode();
            String responseBody = res.getBody();

            if (statusCode != 200) {
                String errorMsg = 'Google token request failed | Status: ' + statusCode + 
                                  ' | Response: ' + responseBody;
                System.debug(LoggingLevel.ERROR, errorMsg);
                throw new CalloutException(errorMsg);
            }

            Map<String, Object> parsed = (Map<String, Object>)
                JSON.deserializeUntyped(responseBody);

            if (parsed.containsKey('access_token')) {
                cachedAccessToken = (String) parsed.get('access_token');
                cachedTokenExpiryEpoch = nowEpoch + 3500; // 58 minutes (buffer for safety)
                System.debug('SUCCESS: GCS access token generated');
                return cachedAccessToken;
            } else {
                throw new CalloutException('No access_token in response: ' + responseBody);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error generating access token: ' + e.getMessage());
            throw new CalloutException('Failed to generate GCS access token: ' + e.getMessage());
        }
    }

    /**
     * @description Converts a Blob to base64url format (Google JWT requirement)
     * Base64url encoding differs from standard base64 by using URL-safe characters
     * @param b The Blob to encode
     * @return Base64url encoded string
     */
    private static String base64Url(Blob b) {
        return EncodingUtil.base64Encode(b)
            .replace('=', '')  // Remove padding
            .replace('+', '-') // Replace + with -
            .replace('/', '_'); // Replace / with _
    }
    
    /**
     * @description Custom exception class for configuration-related errors
     */
    public class ConfigurationException extends Exception {}
}