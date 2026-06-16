//Description - Helper Class for Creating PRM Catalog and Wholesale Packages
//JIRA(s) covered - PRM-56, PBC-9756
//Developer - ratul.saha@ringcentral.com
//Related LWC - prmPackageCreator
//Test Class - Test_PRM_Package_Creator_Helper
public with sharing class PRM_Package_Creator_Helper{
  //
  @AuraEnabled
  public static Account getAccountFromNGBSPartnerId(String ngbsPartnerId){
    try{
      List<Account> accs = [SELECT id, Name, NGBS_Partner_ID__c
                      FROM Account
                      WHERE NGBS_Partner_Id__c = :Decimal.valueOf(ngbsPartnerId)
                      LIMIT 1];
      return accs.size() > 0 ? accs[0] : null;
    } catch (Exception e){
      return null;
    }
  }

  //
  @AuraEnabled
  public static String getCatalogPackageData(String packageId, String version){
    String endpoint = 'callout:NGBS_API/restapi/catalog/v1.0/packages/' + packageId + '/' + version;//Uncomment for PROD
    String httpMethod = 'GET';
    Map<String, String> headerDetails = new Map<String, String>();
    HttpResponse resp = APIUtility.makeHTTPRequest(endpoint, httpMethod, headerDetails, '');
    return resp.getBody();
  }

  //
  @AuraEnabled
  public static String getPartnerPackages(String ngbsPartnerId, Boolean includeSelf){
    String endpoint = 'callout:NGBS_API/restapi/catalog/v1.0/partners/' + ngbsPartnerId + '/packages/search?withlboxes=true';//Uncomment for PROD
    String httpMethod = 'POST';
    String body = '';
    if (includeSelf){
      body = '{"ownership": "Self","catalogPackagesSearchParams": {"isVersioned": true,"labels": {"SIGNUP_SFDCVAR": ["Active", "Active Testing"]}}}';
    } else{
      body = '{"catalogPackagesSearchParams": {"isVersioned": true,"labels": {"SIGNUP_SFDCVAR": ["Active", "Active Testing"]}}}';
    }
    Map<String, String> headerDetails = new Map<String, String>();
    headerDetails.put('Content-Type', 'application/json');
    headerDetails.put('Accept', 'application/json');
    HttpResponse resp = APIUtility.makeHTTPRequest(endpoint, httpMethod, headerDetails, body);
    return resp.getBody();
  }

  //
  @AuraEnabled
  public static String getV2ProductPackageRecordTypeId(){
    return Schema.SObjectType.Product_Package__c.getRecordTypeInfosByName().get('V2').getRecordTypeId();
  }

  //
  @AuraEnabled
  public static List<Contract_Discount__c> getContractDiscounts(){
    return [SELECT ApplicableTo__c,Contract__c,Contract__r.Available_in_packages__c,CreatedById,CreatedDate,CurrencyIsoCode,
    Discount__c FROM Contract_Discount__c where Contract__r.Active__c = true];
  }

  //
  @AuraEnabled
  public static List<NGBSHiddenLicenses__c> getNGBSLicenseSettings(){
    return NGBSHiddenLicenses__c.getAll().values();
  }

  //
  @AuraEnabled
  public static Id upsertProductPackageApex(Product_Package__c pkg){
    upsert pkg Ext_Element_Id__c;
    return pkg.id;
  }

  //
  @AuraEnabled
  public static Id upsertProduct2Apex(Product2 product){
    upsert product ExtID__c;
    return product.id;
  }

  //
  @AuraEnabled
  public static Id upsertProductCatalogueApex(Product_Catalogue__c productCatalogue){
    upsert productCatalogue ExtId__c;
    return productCatalogue.Id;
  }

  //
  @AuraEnabled
  public static Id upsertProductTierPriceApex(Product_Tier_Price__c productTierPrice){
    upsert productTierPrice ExtID__c;
    return productTierPrice.Id;
  }

  //
  @AuraEnabled
  public static Id upsertProductCatalogueRuleApex(Product_Catalogue_Rule__c productCatalogueRule){
    upsert productCatalogueRule ExtID__c;
    return productCatalogueRule.Id;
  }

  //
  @AuraEnabled
  public static Id upsertWholesalePartnerPackageApex(Wholesale_Partner_Package__c wholesalePartnerPackage){
    upsert wholesalePartnerPackage ExtID__c;
    return wholesalePartnerPackage.Id;
  }

}