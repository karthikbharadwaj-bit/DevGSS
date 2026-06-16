public class LeadCompanyProcessorSvc extends CompanyProcessorSvc {

    public enum LeadCountryDomainProcess{
        Email,
        DUWebsite,
        Website
    }
    public Set<String> leadStatusesForCompanyMatching = new Set<String>{'.5 Re-New', '1. New'};
    public static Integer dunsNumberLength = 9;

    public override void processAccountHierarchy(List<sObject> objectsToProcess, Map<Id, sObject> oldObjects) { 
        List<Lead> leads = (List<Lead>)objectsToProcess;
        Map<Id, Lead> oldLeads = (Map<Id, Lead>)oldObjects;
        
        Map<Double, LeadAccountHierarchy> leadsToProcess = 
            getOnlyNewLeadsOrLeadsWhichAHSearchCriteriaFieldsHaveBeenModified(leads, oldLeads);
        
        processAccountHierarchyMatchingByCountryDomain(leadsToProcess, LeadCountryDomainProcess.Website);
        processAccountHierarchyMatchingByCountryDomain(leadsToProcess, LeadCountryDomainProcess.Email);
        processAccountHierarchyMatchingByCountryDomain(leadsToProcess, LeadCountryDomainProcess.DUWebsite);
        processAccountHierarchyMatchingByDunsNumber(leadsToProcess);

        //Insert new AccountHierarchies for the leads that couldn't match any
        Map<String, AccountHierarchyToInsert> accountHierarchiesToInsert = new Map<String, AccountHierarchyToInsert>();
        for(Double lahId : leadsToProcess.keySet()){
            LeadAccountHierarchy lah = leadsToProcess.get(lahId);
            if(lah.accountHierarchy == null){ 
                Account_Hierarchy__c candidateAccountHierarchyToInsert = createCandidateAccountHierarchyFromLead(lah.lead);
                if(accountHierarchiesToInsert.get(candidateAccountHierarchyToInsert.D_U_N_S_Number__c) != null){
                    accountHierarchiesToInsert.get(candidateAccountHierarchyToInsert.D_U_N_S_Number__c).leads.add(lah.lead);
                }
            }
        }        
        if(accountHierarchiesToInsert.size() > 0){
            //Insert AHs
            List<Account_Hierarchy__c> accountHierarchiesToInsertList = new List<Account_Hierarchy__c>();
            for(AccountHierarchyToInsert ahToInsert : accountHierarchiesToInsert.values()){
                accountHierarchiesToInsertList.add(ahToInsert.accountHierarchy);
            }
            accountHierarchyDataInstance.insertAccountHierarchies(accountHierarchiesToInsertList);
            //Assign AH to Leads
            for(AccountHierarchyToInsert ahToInsert : accountHierarchiesToInsert.values()){
                for(Lead lead : ahToInsert.leads){ 
                    lead = associateExistingAccountHierarchyToLead(lead, ahToInsert.accountHierarchy); 
                }
            }
        }
        Set<Id> leadIds = new Set<Id>();
        Set<Id> previousCompanyies = new Set<Id>();
        for (Double lahId : leadsToProcess.keySet()) {
            LeadAccountHierarchy lah = leadsToProcess.get(lahId);
            if(String.isBlank(lah.accountHierarchyFoundBy)){
                previousCompanyies.add(lah.lead.AH_Name__c);
                lah.lead.AH_Name__c = null;
                lah.lead.Company_Duns__c = '';
                leadIds.add(lah.lead.Id);
            }
        }
        if (!previousCompanyies.isEmpty() && !leadIds.isEmpty()) {
            deleteCompanyPersons(previousCompanyies, leadIds);
        }
        deleteCompanyPersonsForLeadsThatHaveChangedTheirRelatedAccountHierarchy(leads, oldLeads);
    }

    private void deleteCompanyPersons(Set<Id> previousCompanyies, Set<Id> leadIds){
        List<Object> bindings = new List<Object>();
        bindings.add(previousCompanyies);
        bindings.add(leadIds);
        List<Company_Persons__c> compPersons = (List<Company_Persons__c>) new CompanyPersonSelector()
                                               .selectCountCompanyPersonsByLeadAndCompanyId(bindings)
                                               .executeQuery();
        delete compPersons;
    }
    
    @testVisible
    private String determineCountrySearchKey(Lead lead){
   
        String countryToReturn = null;
        if(!String.isEmpty(Lead.Country)){
            countryToReturn = getNormalizedCountry(lead.Country).toLowerCase();
        } else if (!String.isEmpty(lead.LS_Company_Country__c)) {
            countryToReturn = getNormalizedCountry(lead.LS_Company_Country__c).toLowerCase();
        }
        return countryToReturn; 
    }

    @testVisible
    private void processAccountHierarchyMatchingByDunsNumber(Map<Double, LeadAccountHierarchy> leadsToProcess){

        Set<String> dunsNumbersFilter = new Set<String>();
        for(LeadAccountHierarchy lah : leadsToProcess.values()){
            if(!String.isEmpty(lah.lead.SiteDunsNumber__c) && !dunsNumbersFilter.contains(lah.lead.SiteDunsNumber__c)){
                dunsNumbersFilter.add(lah.lead.SiteDunsNumber__c.rightPad(dunsNumberLength, '0'));
            }
            if(!String.isEmpty(lah.lead.Company_Duns__c) && !dunsNumbersFilter.contains(lah.lead.Company_Duns__c)){
                dunsNumbersFilter.add(lah.lead.Company_Duns__c.rightPad(dunsNumberLength, '0'));
            }
        }

        Map<String, Account_Hierarchy__c> mapAhByDunsNumbers = new Map<String, Account_Hierarchy__c>();
        if(dunsNumbersFilter.size() > 0){
            for(Account_Hierarchy__c ah : accountHierarchyDataInstance.getAccountHierarchiesByDunsNumber(dunsNumbersFilter)) {
                mapAhByDunsNumbers.put(ah.D_U_N_S_Number__c, ah);
            }
        }

        for(LeadAccountHierarchy lah : leadsToProcess.values()){
            if(lah.lead.Company_Duns__c != null && mapAhByDunsNumbers.get(lah.lead.Company_Duns__c.rightPad(dunsNumberLength, '0')) != null) {
                leadsToProcess.get(lah.id).lead = 
                    associateExistingAccountHierarchyToLead(leadsToProcess.get(lah.id).lead, 
                                                            mapAhByDunsNumbers.get(lah.lead.Company_Duns__c.rightPad(dunsNumberLength, '0')));
                leadsToProcess.get(lah.id).accountHierarchy = mapAhByDunsNumbers.get(lah.lead.Company_Duns__c.rightPad(dunsNumberLength, '0'));
                leadsToProcess.get(lah.id).accountHierarchyFoundBy = 'Lead.CompanyDuns';
                System.Debug('found by CompanyDuns:::');
            }
            else if(lah.lead.SiteDunsNumber__c != null && mapAhByDunsNumbers.get(lah.lead.SiteDunsNumber__c.rightPad(dunsNumberLength, '0')) != null){
                leadsToProcess.get(lah.id).lead = 
                    associateExistingAccountHierarchyToLead(leadsToProcess.get(lah.id).lead, 
                                                            mapAhByDunsNumbers.get(lah.lead.SiteDunsNumber__c.rightPad(dunsNumberLength, '0')));
                leadsToProcess.get(lah.id).accountHierarchy = mapAhByDunsNumbers.get(lah.lead.SiteDunsNumber__c.rightPad(dunsNumberLength, '0'));
                leadsToProcess.get(lah.id).accountHierarchyFoundBy = 'Lead.SiteDunsNumber';
            } 
        }
    }

    private Lead associateExistingAccountHierarchyToLead(Lead destinationLead, Account_Hierarchy__c accountHierarchy){
        destinationLead.AH_Name__c = accountHierarchy.Id;
        destinationLead.Company_Duns__c = accountHierarchy.D_U_N_S_Number__c;
        return destinationLead;
    }

    private void deleteCompanyPersonsForLeadsThatHaveChangedTheirRelatedAccountHierarchy(List<Lead> leads, 
        Map<Id, Lead> oldLeads){

        if(oldLeads == null) {
            return;
        }
        Set<Id> oldLeadIds = new Set<Id>();
        for (Lead lead : leads) {
            if (isLeadUpdateAndRelatedAccountHierarchyWasChanged(lead, oldLeads)){
                oldLeadIds.add(lead.Id);
            }
        }
        if(oldLeadIds.size() > 0){
            companyPersonsDataInstance.deleteCompanyPersonsByLeadIds(oldLeadIds);
        }
    }

    private Boolean isLeadUpdateAndRelatedAccountHierarchyWasChanged(Lead lead, Map<Id, Lead> oldLeads){
        if (oldLeads != null && oldLeads.get(lead.Id) != null && lead.Company_DUNS__c != oldLeads.get(lead.Id).Company_DUNS__c || lead.AH_Name__c != oldLeads.get(lead.Id).AH_Name__c) {
            return true;
        }
        return false;
    }

    private void processAccountHierarchyMatchingByCountryDomain(Map<Double, LeadAccountHierarchy> leadsToProcess,
        LeadCountryDomainProcess process){ 

        Set<String> countryDomainFilter = new Set<String>();
        String temporaryCountry;
        String temporaryDomain;
        for(Double lahId : leadsToProcess.keySet()){
            LeadAccountHierarchy lah = leadsToProcess.get(lahId);
            if(lah.accountHierarchy == null){
                temporaryCountry = determineCountrySearchKey(lah.lead);
                if(process == LeadCountryDomainProcess.Email){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromEmailAddress(lah.lead.Email);
                } else if (process == LeadCountryDomainProcess.DUWebsite){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromUrl(lah.lead.LS_Company_Website__c);
                } else if (process == LeadCountryDomainProcess.Website){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromUrl(lah.lead.Website);
                } else {
                    throw new CompanyProcessorSvcException('Invalid CountryDomainProcess:' + process);
                }

                if(!String.isEmpty(temporaryDomain) && domainManagerSvcInstance.domainIsInIgnoredDomainList(temporaryDomain)){
                    temporaryDomain = '';
                }
                
                if(String.isEmpty(temporaryCountry) || String.isEmpty(temporaryDomain)){
                    continue;
                }
                if(!countryDomainFilter.contains(getCountryDomainKey(temporaryCountry, temporaryDomain))){
                    countryDomainFilter.add(getCountryDomainKey(temporaryCountry, temporaryDomain));
                }
            }
        }

        Map<String, Account_Hierarchy__c> mapAhByCountryDomain = new Map<String, Account_Hierarchy__c>();
        if(countryDomainFilter.size() > 0){
            for(Account_Hierarchy__c ah : accountHierarchyDataInstance.getAccountHierarchiesByCountryDomain(countryDomainFilter)) {
                mapAhByCountryDomain.put(ah.Country_Domain__c, ah);
            }
        }

        for(Double lahId : leadsToProcess.keySet()){
            LeadAccountHierarchy lah = leadsToProcess.get(lahId);
            if(lah.accountHierarchy == null){ 
                temporaryCountry = determineCountrySearchKey(lah.lead);
                 if(process == LeadCountryDomainProcess.Email){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromEmailAddress(lah.lead.Email);
                } else if (process == LeadCountryDomainProcess.DUWebsite){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromUrl(lah.lead.LS_Company_Website__c);
                } else if (process == LeadCountryDomainProcess.Website){
                    temporaryDomain = domainManagerSvcInstance.getDomainPartFromUrl(lah.lead.Website);
                } else {
                    throw new CompanyProcessorSvcException('Invalid CountryDomainProcess:' + process);
                }

                if(!String.isEmpty(temporaryCountry) && !String.isEmpty(temporaryDomain) && mapAhByCountryDomain.get(getCountryDomainKey(temporaryCountry, temporaryDomain)) != null) {     
                    leadsToProcess.get(lah.id).lead = associateExistingAccountHierarchyToLead(leadsToProcess.get(lah.id).lead, 
                        mapAhByCountryDomain.get(getCountryDomainKey(temporaryCountry, temporaryDomain)));
                    leadsToProcess.get(lah.id).accountHierarchy = 
                        mapAhByCountryDomain.get(getCountryDomainKey(temporaryCountry, temporaryDomain));
                    leadsToProcess.get(lah.id).accountHierarchyFoundBy = 'CountryDomainBy' + process;
                }
            }
        }

    }

    private Account_Hierarchy__c createCandidateAccountHierarchyFromLead(Lead lead){
        Account_Hierarchy__c newAccountHierarchy = new Account_Hierarchy__c();
        newAccountHierarchy.Industry__c = lead.LS_Company_Industry__c;
        newAccountHierarchy.Sub_Industry__c = lead.LS_Company_Sub_Industry__c;
        newAccountHierarchy.Company_Name_DU__c = lead.LS_Company__c;
        if(!String.isEmpty(lead.LS_Site__c)){
            newAccountHierarchy.Name = lead.LS_Site__c.abbreviate(80);
        }
        newAccountHierarchy.Country__c = lead.LS_Company_Country__c;
        newAccountHierarchy.State__c = lead.LS_Company_State__c;
        newAccountHierarchy.City__c = lead.LS_Company_City__c;
        newAccountHierarchy.Street__c = lead.LS_Company_Street__c;
        newAccountHierarchy.ZipCode__c = lead.LS_Company_Zipcode__c;
        newAccountHierarchy.AH_Website__c = lead.LS_Site_Website__c;
        newAccountHierarchy.SIC__c =  lead.LS_Primary_SIC__c;
        newAccountHierarchy.NAIC__c = lead.LS_Primary_NAIC__c;
        newAccountHierarchy.Name = lead.AH_Name__r.Name;
        newAccountHierarchy.Effective_No_of_Employees_Range__c = lead.LS_Company_Size_Range__c;
        String emailDomain = domainManagerSvcInstance.getDomainPartFromEmailAddress(lead.Email);
        String websiteDomain = domainManagerSvcInstance.getDomainPartFromUrl(lead.LS_Company_Website__c);
        String country = determineCountrySearchKey(lead);

        if(!String.isEmpty(websiteDomain) && !domainManagerSvcInstance.domainIsInIgnoredDomainList(websiteDomain)){
            newAccountHierarchy.Country_Domain__c = getCountryDomainKey(country, websiteDomain);
        } else if(!String.isEmpty(emailDomain) && !domainManagerSvcInstance.domainIsInIgnoredDomainList(emailDomain)){
            newAccountHierarchy.Country_Domain__c =  getCountryDomainKey(country, emailDomain);
        }
        
        if(!String.isEmpty(lead.SiteDunsNumber__c)){
            newAccountHierarchy.D_U_N_S_Number__c = lead.SiteDunsNumber__c;
        } else if(!String.isEmpty(lead.Company_Duns__c)){
            newAccountHierarchy.D_U_N_S_Number__c = lead.Company_Duns__c;
        } 
        return newAccountHierarchy;
    }

    public class AccountHierarchyToInsert{
        public Account_Hierarchy__c accountHierarchy {get; set;}
        public List<Lead> leads {get; set;}

        public AccountHierarchyToInsert(){
            leads = new List<Lead>();
        }
    }

    public class LeadAccountHierarchy{
        
        public Account_Hierarchy__c accountHierarchy {get; set;}
        public Lead lead {get; set;}
        public String accountHierarchyFoundBy {get; set;}
        public Double id {get; set;}

        public LeadAccountHierarchy(Lead ld, Account_Hierarchy__c ah){
            accountHierarchy = ah;
            lead = ld;
            id = Math.random();
        }
    }
    
    @testVisible
    private Map<Double, LeadAccountHierarchy> 
        getOnlyNewLeadsOrLeadsWhichAHSearchCriteriaFieldsHaveBeenModified(List<Lead> leads, Map<Id, Lead> oldLeads){
        
        Map<Double, LeadAccountHierarchy> leadsToReturn = new Map<Double, LeadAccountHierarchy>();

        if(oldLeads == null || oldLeads.size() == 0){
            for (Lead lead : leads) {
                LeadAccountHierarchy newLah = new LeadAccountHierarchy(lead, null);
                leadsToReturn.put(newLah.id, newLah);
            }
            return leadsToReturn;
        }

        for (Lead lead : leads) {
            if (oldLeads.get(lead.Id) == null || (objectIdsToForceProcessDuringUpdate != null && objectIdsToForceProcessDuringUpdate.contains(lead.Id)) || lead.Company_DUNS__c != oldLeads.get(lead.Id).Company_DUNS__c ||
                lead.SiteDunsNumber__c != oldLeads.get(lead.Id).SiteDunsNumber__c || lead.Country != oldLeads.get(lead.Id).Country || lead.Country__c != oldLeads.get(lead.Id).Country__c || 
                lead.LS_Company_Country__c != oldLeads.get(lead.Id).LS_Company_Country__c || lead.Email != oldLeads.get(lead.Id).Email || lead.LS_Company_Website__c != oldLeads.get(lead.Id).LS_Company_Website__c ||
                lead.Website != oldLeads.get(lead.Id).Website || (lead.Status != oldLeads.get(lead.Id).Status && leadStatusesForCompanyMatching.contains(lead.Status)) ) {

                LeadAccountHierarchy newLah = new LeadAccountHierarchy(lead, null);
                leadsToReturn.put(newLah.id, newLah);
            }
        }

        return leadsToReturn;
    }

}