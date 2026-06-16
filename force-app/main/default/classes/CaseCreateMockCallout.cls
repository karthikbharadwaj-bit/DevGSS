@isTest
global class CaseCreateMockCallout implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{'+
            '"controllerValues" : { },'+
            '"defaultValue" : null,'+
            '"eTag" : "f61012b0609de8db2c30952796ef18a8",'+
            '"url" : "/services/data/v51.0/ui-api/object-info/Case/picklist-values/01280000000UIfJAAW/Product_Assistance__c",'+
            '"values" : [ {'+
              '"attributes" : null,'+
              '"label" : "Billing",'+
              '"validFor" : [ ],'+
              '"value" : "Billing"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Contact Center Solutions",'+
              '"validFor" : [ ],'+
              '"value" : "Contact Center Solutions"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Developer Platform",'+
              '"validFor" : [ ],'+
              '"value" : "Developer Platform"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Sales Inquiry or Upgrade",'+
              '"validFor" : [ ],'+
              '"value" : "Sales Inquiry or Upgrade"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Service Downgrade or Cancellation",'+
              '"validFor" : [ ],'+
              '"value" : "Service Downgrade or Cancellation"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Engage Voice",'+
              '"validFor" : [ ],'+
              '"value" : "Engage Voice"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "Faxing",'+
              '"validFor" : [ ],'+
              '"value" : "Faxing"'+
            '}, {'+
              '"attributes" : null,'+
              '"label" : "DSR Request",'+
              '"validFor" : [ ],'+
              '"value" : "GDPR Request"'+
            '} ]'+
          '}');
        res.setStatusCode(200);
        return res;
    }
}