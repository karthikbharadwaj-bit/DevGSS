/*
* @Created By : Vidya Sampath
* @Created Date : 09/July/2020
* @Purpose : Utility class for API integrations
* @Test Class : Test_APIUtility
* */

public class APIUtility {
    
    public static HttpResponse makeHTTPRequest(String endpoint, String httpMethod, Map<String,String> headerDetails, String requestBody){
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(endpoint);
        request.setMethod(httpMethod);
        
        if(!headerDetails.isEmpty()){
            for(String header : headerDetails.keySet()){
                request.setHeader(header, headerDetails.get(header));
            }
        }
        
        if(requestBody != '') {
            request.setBody(requestBody);   
        }
        
        HttpResponse response = http.send(request);        
        return response;
    }
}