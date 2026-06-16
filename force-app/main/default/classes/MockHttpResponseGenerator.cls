@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {                
        // It is used to send a mock response for a EndPoint URL
        //System.assertEquals('http://199.68.214.238:8088/RCBilling/Services/TAXRequestAPI', req.getEndpoint());
        //System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"SFDCTaxResponse":{"responseData":{"userId":"0","quoteId":"aEK6w0000004FJZGA2","status":"success","message":" ","itemList":[{"lineId":"aEG6w000000WQwJGAW","RCTaxType":"Variable","lineStatus":"Success","lineMessage":" ","taxData":[{"categoryId":"8","categoryDescription":"UTILITY USER TAXES","description":"Utility Users Tax","rate":"0.06","taxAmount":"10.923715","taxLevel":"3","taxType":"16","TaxableMeasure":"182.06192"},{"categoryId":"1","categoryDescription":"SALES AND USE TAXES","description":"Sales Tax","rate":"0.04","taxAmount":"6.8273363","taxLevel":"3","taxType":"1","TaxableMeasure":"182.0623"},{"categoryId":"1","categoryDescription":"SALES AND USE TAXES","description":"Sales Tax","rate":"0.07","taxAmount":"11.83405","taxLevel":"1","taxType":"1","TaxableMeasure":"182.0623"},{"categoryId":"5","categoryDescription":"CONNECTIVITY CHARGES","description":"FUSF (VoIP)","rate":"0.14","taxAmount":"21.14859","taxLevel":"0","taxType":"162","TaxableMeasure":"149.99"}]},{"lineId":"aEG6w000000WQyaGAG","RCTaxType":"Variable","lineStatus":"Success","lineMessage":" ","taxData":[{"categoryId":"8","categoryDescription":"UTILITY USER TAXES","description":"Utility Users Tax","rate":"0.06","taxAmount":"8.010243","taxLevel":"3","taxType":"16","TaxableMeasure":"133.50406"},{"categoryId":"1","categoryDescription":"SALES AND USE TAXES","description":"Sales Tax","rate":"0.04","taxAmount":"5.0065813","taxLevel":"3","taxType":"1","TaxableMeasure":"133.50883"},{"categoryId":"1","categoryDescription":"SALES AND USE TAXES","description":"Sales Tax","rate":"0.07","taxAmount":"8.678074","taxLevel":"1","taxType":"1","TaxableMeasure":"133.50883"},{"categoryId":"5","categoryDescription":"CONNECTIVITY CHARGES","description":"FUSF (VoIP)","rate":"0.14","taxAmount":"15.50859","taxLevel":"0","taxType":"162","TaxableMeasure":"109.99"}]}]},"requestType":"quote","responseTimestamp":"2021-06-14 23:30:58"}}');
        res.setStatusCode(200);              
        
        return res;
    }
}