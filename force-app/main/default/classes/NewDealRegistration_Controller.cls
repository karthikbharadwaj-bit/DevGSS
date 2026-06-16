public class NewDealRegistration_Controller {
    
    //pbc-10695
    @AuraEnabled
    public static Community_Details__mdt getCommunityDetails(String SFBrandName){
        Map<String,Community_Details__mdt> commdetails = CommunityInfo.getAllCommunityDetails();
        Community_Details__mdt commDetail = commdetails.get(SFBrandName);
        return commDetail;
    }
    
    @AuraEnabled
    public static PickListWrapperForCountry getCountryStateMap(String communityBrand){
        system.debug('communityBrand>>'+communityBrand);
        Map<String,List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.State__c);
        Map<String,List<String>> countryCompetitorMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.Competitor_s__c);
        Map<String,List<String>> countryEmployeesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Deal_Registration__c.Number_of_Employees__c);
        PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
        picklistWrapperObj.countryStateMap = dependentPicklistValuesMap;
        picklistWrapperObj.countryNoOfEmployeesMap = countryEmployeesMap;
        BrandCountryWrapper brandWrapr = new BrandCountryWrapper();
        brandWrapr = NewDealRegistration_Controller.getCountriesAvailableForCommunity(communityBrand);
        picklistWrapperObj.countriesAvailable = brandWrapr.countries;
        picklistWrapperObj.mapBrandCntry = brandWrapr.mapBrandCntry;        
        picklistWrapperObj.countryCompetitorMap=countryCompetitorMap;
        return picklistWrapperObj;        
       
    }
    public static BrandCountryWrapper getCountriesAvailableForCommunity(String communityBrand){
        BrandCountryWrapper brandWrapper = new BrandCountryWrapper();
        List<String> countries = new List<String>();
        Map<String,List<String>> mapBrandCntry = new Map<String,List<String>>();
        List<String> tmpLst = new List<String>();
        
        if(communityBrand == null || communityBrand == ''){
            Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
            communityBrand = comDetail.Brand_Name__c;
        }

        List<Community_Detail_Child__mdt> countriesForBrand =[select Country_Name__c,Brand_Country__c from Community_Detail_Child__mdt where Brand_Country__c =: communityBrand];
        
        for(Community_Detail_Child__mdt communityObj : countriesForBrand){
            if(mapBrandCntry.containsKey(communityObj.Brand_Country__c)){
                mapBrandCntry.get(communityObj.Brand_Country__c).add(communityObj.Country_Name__c);
            }else{
                tmpLst = new List<String>(); 
                tmpLst.add(communityObj.Country_Name__c);
                mapBrandCntry.put(communityObj.Brand_Country__c,tmpLst);
            }
            if(countries.indexOf(communityObj.Country_Name__c) == -1) {
            	countries.add(communityObj.Country_Name__c);
            }
        }
        if(countries.size() == 0){
            countries.add('United States');
        }
        system.debug('mapBrandCntry>>'+mapBrandCntry);
        brandWrapper.countries = countries;
        brandWrapper.mapBrandCntry = mapBrandCntry;
        return brandWrapper;
    }
    
    @AuraEnabled
    public static List<Strategic_Partner_Account__c> getStrategicPartnerManagers(String userName){
        List<Strategic_Partner_Account__c> strategicmanagers = Partner_DealRegStrategicPartnerManager.getStrategicPartnerManagers(userName);
        return strategicmanagers;
    }
    @AuraEnabled
    public static AccountListWrapper getAccountDetails(String selectedPartnerAccount){
        List<Account> listofPartnerAccounts = new List<Account>();
        AccountListWrapper accListWrapper=new AccountListWrapper();
        if(selectedPartnerAccount != NULL){
            for(Account acc : [SELECT Id, Name,Partner_Role__c, Partner_Type__c, VAR_Territory__c, Permitted_Brands__c, 
                               Master_Agent_Channel_Manager__c  FROM Account WHERE Id =:selectedPartnerAccount 
                               AND Type='Partner' order by Name]){
                                   listofPartnerAccounts.add(acc);
        	}
    	}
        accListWrapper.listPartnerAccounts=listofPartnerAccounts;
        return accListWrapper;
    }
    // BZS-9016
    @AuraEnabled
    public static List<CountryBusinessIdentityMapping__c> getBICountriesCSList(){
        List<CountryBusinessIdentityMapping__c> BICountryCSList = CountryBusinessIdentityMapping__c.getAll().values();
        return BICountryCSList;
    }    
    @AuraEnabled
    public static PSServiceProviderWrapper getServiceProvider(String partnerContact){
        PSServiceProviderWrapper psWrapper = new PSServiceProviderWrapper();
        String deliveryPartner;
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Deal_Registration__c.Installation_Service_Provider__c.getDescribe();
        List<Schema.PicklistEntry> plValues = fieldResult.getPicklistValues();

        if (plValues != null) {
            for (Schema.PicklistEntry ple : plValues) {
                Contact contactRecord = [Select Id, Name, AccountId, Account.Certified_Delivery_Partner_Status__c from Contact where Id=: partnerContact];
                if (contactRecord != null) {
                    deliveryPartner = contactRecord.Account.Certified_Delivery_Partner_Status__c;
                }
                if (contactRecord != null && (deliveryPartner == PartnerDealRegistrationUtil.COMPLETE
                                              || deliveryPartner == PartnerDealRegistrationUtil.PSPREMIERPARTNER)) {
                    if (ple.getValue() != PartnerDealRegistrationUtil.ENROLLCDPSTATUS) {
                        picklistValues.add(ple.getValue());
                    }
                } else {
                    if (ple.getValue() != PartnerDealRegistrationUtil.PARTNERINSTALLSTATUS) {
                        picklistValues.add(ple.getValue());
                    }
                }
            }
        }
        psWrapper.picklistValues = picklistValues;

        if(psWrapper.picklistValues != null) {
            psWrapper.showISPField = true;
        }
        return psWrapper;
    }

    public class AccountListWrapper{        
        @AuraEnabled
        public List<Account> listPartnerAccounts {get;set;}
    }

    public class PSServiceProviderWrapper {
        @AuraEnabled
        public List<String> picklistValues {get;set;}
        @AuraEnabled
        public Boolean showISPField {get;set;}
    }
       
    public class PickListWrapperForCountry{
        @AuraEnabled
        public Map<String,List<String>> countryStateMap {get;set;}
        @AuraEnabled
        public List<String> countriesAvailable {get;set;}
        @AuraEnabled
        public Map<String,List<String>> countryCompetitorMap{get;set;}
        @AuraEnabled
        public Map<String,List<String>> countryNoOfEmployeesMap{get;set;}
        @AuraEnabled
        public String loggedPartnerCountry{get;set;}
        @AuraEnabled
        public Map<String,List<String>> mapBrandCntry{get;set;}
    }
    
    public class BrandCountryWrapper{
        public List<String> countries{get;set;}
        public Map<String,List<String>> mapBrandCntry{get;set;}
    }
}