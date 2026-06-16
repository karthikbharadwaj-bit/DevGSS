@isTest
public with sharing class Test_Partner_Invoice_Feed {
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_searchPartnerAccountUsingName() {
    Partner_Invoice_Feed.searchPartnerAccountUsingName('Test');
  }

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_getInvoiceFeedForPartner() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    Partner_Invoice_Feed.getInvoiceFeedForPartner('10');
  }

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_getInvoiceReportForPartner() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    Partner_Invoice_Feed.getInvoiceReportForPartner('10', '20');
  }
}