//Description - Partner Invoice Feed Helper Class
//JIRA(s) covered - PRM-60
//Developer - ratul.saha@ringcentral.com
//Related LWC - prmInvoiceFeed
//Test Class - Test_Partner_Invoice_Feed

public with sharing class Partner_Invoice_Feed {
    @AuraEnabled
    public static List <Account> searchPartnerAccountUsingName(String name) {
      return [
        SELECT Id, Name, NGBS_Partner_Id__c FROM Account WHERE Name LIKE :name AND NGBS_Partner_Id__c != NULL AND ISPARTNER = true LIMIT 20
      ];
    }
  
    @AuraEnabled
    public static String getInvoiceFeedForPartner(String ngbsPartnerId) {
      String endpoint = 'callout:NGBS_API/restapi/invoice-feed/v1.0/partners/' + ngbsPartnerId + '/reports';
      //String endpoint = 'http://199.68.214.251:8080/restapi/invoice-feed/v1.0/partners/' + ngbsPartnerId + '/reports';
      Map <String, String> headers = new Map <String, String> ();
      headers.put('X-PartnerId', ngbsPartnerId);
  
      HttpResponse resp = APIUtility.makeHTTPRequest(endpoint, 'GET', headers, '');
      return resp.getBody();
    }
  
    @AuraEnabled
    public static String getInvoiceReportForPartner(String ngbsPartnerId, String reportId) {
      String endpoint = 'callout:NGBS_API/restapi/invoice-feed/v1.0/partners/' + ngbsPartnerId + '/reports/' + reportId;
      //String endpoint = 'http://199.68.214.251:8080/restapi/invoice-feed/v1.0/partners/' + ngbsPartnerId + '/reports/' + reportId;
      Map <String, String> headers = new Map <String, String> ();
      headers.put('X-RequestedPartnerId', ngbsPartnerId);
  
      HttpResponse resp = APIUtility.makeHTTPRequest(endpoint, 'GET', headers, '');
      return resp.getBody();
    }
  }