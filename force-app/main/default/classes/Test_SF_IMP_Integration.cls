@isTest	
public class Test_SF_IMP_Integration {
	
    @isTest
    public static void testCaseClosure(){
        
        Contact con = new Contact(lastName = 'test',email = 'test@test.com');
        insert con;
        
        Id recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Product / Platform Issues').getRecordTypeId();
        
        Case ca1 = new Case(recordTypeId = recId, Type = 'Platform Incident', ContactId = con.Id, support_jira__c = 'TEST-12345');
        insert ca1;
        
        Case ca2 = new Case(recordTypeId = recId, Type = 'Platform Incident', ContactId = con.Id, support_jira__c = 'TEST-12345');
        insert ca2;
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        String requestBody = '{"incidentList": {["incidentNo":"TEST-12345","incidentNo":"00000"]}}';
        
        req.requestURI = '/services/apexrest/sf-imp-case-close/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response= res;
        
        SF_IMP_Integration.IMPIncidentNumber inc = new SF_IMP_Integration.IMPIncidentNumber();
        inc.incidentNo = 'TEST-12345';
        SF_IMP_Integration.IMPIncidentNumber inc1 = new SF_IMP_Integration.IMPIncidentNumber();
        inc1.incidentNo = String.valueOf(System.today());
        
        List<SF_IMP_Integration.IMPIncidentNumber> incidentList = new List<SF_IMP_Integration.IMPIncidentNumber>();
        incidentList.add(inc);
        incidentList.add(inc1);
        
        
        Test.startTest();
        SF_IMP_Integration.getIncidentNumbers(incidentList);
        system.assertEquals(200, res.statusCode);
        Test.stopTest();
        
    }
    
    @isTest
    public static void testEmptyIncidentList(){
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        String requestBody = '{"incidentList": {["incidentNo":"TEST-12345","incidentNo":"00000"]}}';
        String responseBody = '{'+
                    '"statusCode":500,\n'+
                    '"message":"Incident List is empty"}';
        
        req.requestURI = '/services/apexrest/sf-imp-case-close/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response= res;
        
        List<SF_IMP_Integration.IMPIncidentNumber> incidentList = new List<SF_IMP_Integration.IMPIncidentNumber>();
        
        Test.startTest();
        SF_IMP_Integration.getIncidentNumbers(incidentList);
        system.assertEquals(500, res.statusCode);
        system.assertEquals(Blob.valueOf(responseBody), res.responseBody);
        Test.stopTest();
        
    }
    
    @isTest
    public static void testEmptyIncidentNumber(){
	        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        String requestBody = '{"incidentList": {["incidentNo":"TEST-12345","incidentNo":"00000"]}}';
        String responseBody = '{'+
                    '"statusCode":500,\n'+
                    '"message":"Incident Number is empty"}';
        
        req.requestURI = '/services/apexrest/sf-imp-case-close/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response= res;
        
        SF_IMP_Integration.IMPIncidentNumber inc = new SF_IMP_Integration.IMPIncidentNumber();
        inc.incidentNo = '';
        List<SF_IMP_Integration.IMPIncidentNumber> incidentList = new List<SF_IMP_Integration.IMPIncidentNumber>();
        incidentList.add(inc);
        
        Test.startTest();
        SF_IMP_Integration.getIncidentNumbers(incidentList);
        system.assertEquals(500, res.statusCode);
        system.assertEquals(Blob.valueOf(responseBody), res.responseBody);
        Test.stopTest();
                
    }
}