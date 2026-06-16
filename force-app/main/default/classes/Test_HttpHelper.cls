@isTest
public class Test_HttpHelper {
    @isTest
    static void testing(){
        System.assert(HttpHelper.prepareBasicAuthHeader('login', 'pass') != null);
        System.assert(HttpHelper.prepareBasicAuthRequest('endpoint', 'method', 'authHeader', 'body') != null);
    }
}