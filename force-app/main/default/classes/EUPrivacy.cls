/* Epic - CRM-5094 - Added as part of EU Data Privacy Project */
public without sharing class EUPrivacy {
    public Set<String> EURestrictedCountriesSet = new Set<String>();
    public Set<String> EURestrictedProfileNameSet = new Set<String>();
    public Set<String> EURestrictedAccountBrandsSet = new Set<String>();
    public Set<String> EUSupportRestrictedProfileSet = new Set<String>();
    public Set<String> EURestrictedExceptionalProfileNameSet = new Set<String>();
    public Set<String> CompletelyRestrictedConuntriesSet = new Set<String>();
    public Set<String> EURestrictedAccountStatusSet = new Set<String>();
    public Boolean RestrictBasedOnSpecificAccBrands = false;
    
    public EUPrivacy(){
        List<EU_Privacy_Setup__mdt> EUPrivacyList = (List<EU_Privacy_Setup__mdt>) new CustomMetadataSelector()
            .selectEUPrivacyMDT()
            .setQueryCaching(true)
            .executeQuery();

        for(EU_Privacy_Setup__mdt eu : EUPrivacyList){
            if(eu.DeveloperName == 'Restricted_Country_Setup'){
                for(String s : eu.Restricted__c.Split(',')){
                    EURestrictedCountriesSet.add(s.trim().toLowercase());
                }
            }else if(eu.DeveloperName == 'Restricted_Profile_Setup'){
                for(String s : eu.Restricted__c.Split(',')){
                    EURestrictedProfileNameSet.add(s.trim());
                }
            }else if(eu.DeveloperName == 'Completely_Restricted_Countries'){
                   for(String s : eu.Restricted__c.Split(',')){
                    CompletelyRestrictedConuntriesSet.add(s.trim());
                } 
            }else if(eu.DeveloperName == 'Restricted_Account_Brands'){
                RestrictBasedOnSpecificAccBrands = eu.Restrict_Based_on_Specific_Account_Brand__c;
                for(String s : eu.Restricted__c.Split(',')){
                    EURestrictedAccountBrandsSet.add(s.trim().toLowercase());
                }
            }else if(eu.DeveloperName == 'Restricted_Support_Profile_Setup'){
                for(String s : eu.Restricted__c.Split(',')){
                    EUSupportRestrictedProfileSet.add(s.trim());
                }  
            }else if(eu.DeveloperName == 'Restricted_Paid_Status_Setup'){
                for(String s : eu.Restricted__c.Split(',')){
                    EURestrictedAccountStatusSet.add(s.trim());
                }  
            }else if(eu.DeveloperName == 'Restricted_Profile_Exception_Name') {
                for(String s : eu.Restricted__c.Split(',')){
                    EURestrictedExceptionalProfileNameSet.add(s.trim());
                }
            }
        }
    }
    public Set<String> getEURestrictedCountries(){
        return EURestrictedCountriesSet;
    }
    public Set<String> getEURestrictedProfileNames(){
        return EURestrictedProfileNameSet; 
    }
    public Set<String> getEURestrictedAccountBrands(){
        return EURestrictedAccountBrandsSet;  
    }
    public Set<String> getEUSupportRestrictedProfiles(){
        return EUSupportRestrictedProfileSet;  
    }
    public Set<String> getEURestrictedAccountStatus(){
        return EURestrictedAccountStatusSet;  
    }
    public Set<String> getEURestrictedExceptionalProfileNames(){
        return EURestrictedExceptionalProfileNameSet;  
    }
    
    public boolean showComponent(id recordId, String Origin) {
        System.debug('::: Record Id = '+recordId);
        if(String.isBlank(recordId)) {
            return false;
        }
        DescribeSObjectResult sObjectResult = recordId.getSobjectType().getDescribe();        
        String objectName = sObjectResult.getName();
        
        System.debug('::: sObjectResult Name >>> '+objectName);
        
        String qryString = 'SELECT Id ';
        if(objectName == 'Account') {
            qryString += ','+'BillingCountry, SM_Country__c,RC_Brand__c, RC_Account_Status__c';
        } else if(objectName == 'Contact' || objectName == 'Case') {
            qryString += ','+'Account.BillingCountry, Account.SM_Country__c,Account.RC_Brand__c, Account.RC_Account_Status__c';
        } else if(objectName == 'Opportunity') {
            qryString += ','+'Account.BillingCountry,Account.SM_Country__c,Account.RC_Brand__c,Account.RC_Account_Status__c,Primary_Opportunity_Contact__r.Account.BillingCountry, Primary_Opportunity_Contact__r.Account.SM_Country__c, Primary_Opportunity_Contact__r.Account.RC_Brand__c, Primary_Opportunity_Contact__r.Account.RC_Account_Status__c';
        }else if(objectName == 'LiveChatTranscript') {
            qryString += ','+'Case.Account.BillingCountry, Case.Account.SM_Country__c, Case.Account.RC_Brand__c, Case.Account.RC_Account_Status__c';
        }
        qryString += ' FROM '+objectName+' where Id='+'\''+recordId+'\''+' LIMIT 1';
        System.debug('::: Query String - '+qryString);
        List<SObject> dataResults = Database.query(qryString);
        System.debug('::: Data Result - '+dataResults);
        
        String profileName;
        String billing_OR_SMCountry;
        String SMCountry;
        String brandName;
        String accStatus;
        User userProfile = [Select Id, Profile.Name,country__c from User where Id=:UserInfo.getUserId()];
        profileName = userProfile.Profile.Name;
        
        if(objectName == 'Account') {
            Account acc = (Account)dataResults[0];
            billing_OR_SMCountry = String.isBlank(acc.BillingCountry) ? acc.SM_Country__c : acc.BillingCountry;
            brandName = acc.RC_Brand__c;
            accStatus = acc.RC_Account_Status__c;
        } else if(objectName == 'Contact') {
            Contact con = (Contact)dataResults[0];
            billing_OR_SMCountry = String.isBlank(con.Account.BillingCountry) ? con.Account.SM_Country__c : con.Account.BillingCountry;
            brandName = con.Account.RC_Brand__c;
            accStatus = con.Account.RC_Account_Status__c;
        } else if(objectName == 'Case') {
            Case cs = (Case)dataResults[0];
            billing_OR_SMCountry = String.isBlank(cs.Account.BillingCountry) ? cs.Account.SM_Country__c : cs.Account.BillingCountry;
            brandName = cs.Account.RC_Brand__c;
            accStatus = cs.Account.RC_Account_Status__c;
        } else if(objectName == 'Opportunity') {
            Opportunity opp = (Opportunity)dataResults[0];
            billing_OR_SMCountry = String.isBlank(opp.Account.BillingCountry) ? opp.Account.SM_Country__c : opp.Account.BillingCountry;
            brandName = opp.Account.RC_Brand__c;
            accStatus = opp.Account.RC_Account_Status__c;
        } else if(objectName == 'LiveChatTranscript') {
            LiveChatTranscript lct = (LiveChatTranscript)dataResults[0];
            billing_OR_SMCountry = String.isBlank(lct.Case.Account.BillingCountry) ? lct.Case.Account.SM_Country__c : lct.Case.Account.BillingCountry;
            brandName = lct.Case.Account.RC_Brand__c;
            accStatus = lct.Case.Account.RC_Account_Status__c;
        }
        
        Boolean isRestrictedCountry = false;
        if(String.isNotBlank(billing_OR_SMCountry)){
            isRestrictedCountry = EURestrictedCountriesSet.contains(billing_OR_SMCountry.toLowerCase());
        }
        Boolean isCompletelyRestrictedCountry = false;
        if(CompletelyRestrictedConuntriesSet.contains(userProfile.country__c))
        {
            isCompletelyRestrictedCountry = true;
        }
        if(Origin.equalsIgnoreCase('NotesController')){
            Boolean showComponent = false;
            if(!profileName.containsIgnoreCase('EU Restricted') || !EURestrictedAccountStatusSet.contains(accStatus) || String.isEmpty(brandName) || !isRestrictedCountry) {
                showComponent = true; //no need to show as it is non restricted profile
                system.debug('1st Condn:'+showComponent);
            } else if(EURestrictedExceptionalProfileNameSet.contains(profileName)){
                showComponent = true;
                system.debug('2st Condn:'+showComponent);
            } else if(EURestrictedAccountStatusSet.contains(accStatus) && EUSupportRestrictedProfileSet.contains(profileName) && !isCompletelyRestrictedCountry && String.isNotEmpty(brandName) && RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.contains(brandName.toLowerCase())){
                showComponent = true;
                system.debug('3rd Condn:'+showComponent);
            } 
            system.debug('Final:'+showComponent);
            return showComponent;
        } 
        else if(Origin.equalsIgnoreCase('EURestrictedNotificationController')) {
            Boolean showNotifcation = true;

            if(!profileName.containsIgnoreCase('EU Restricted') || !EURestrictedAccountStatusSet.contains(accStatus) || String.isEmpty(brandName) || !isRestrictedCountry) {
                showNotifcation = false; //no need to show as it is non restricted profile and not in acceptance criteria
            } else if(EURestrictedAccountStatusSet.contains(accStatus) && EUSupportRestrictedProfileSet.contains(profileName) && !isCompletelyRestrictedCountry && String.isNotEmpty(brandName) && RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.contains(brandName.toLowerCase())){
                showNotifcation = false;
            }
            return showNotifcation;
        } 
        else if(Origin.equalsIgnoreCase('EuprivacyFieldsetControllerNew')) {
           Boolean showComponent = false;
            if(!profileName.containsIgnoreCase('EU Restricted') || !EURestrictedAccountStatusSet.contains(accStatus) || String.isEmpty(brandName) || !isRestrictedCountry) {
                showComponent = true; //no need to show as it is non restricted profile
            }
            else if(EURestrictedAccountStatusSet.contains(accStatus) && EUSupportRestrictedProfileSet.contains(profileName) && !isCompletelyRestrictedCountry && String.isNotEmpty(brandName) && RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.contains(brandName.toLowerCase())){
                showComponent = true;
				}
            return showComponent;
        }
        //CRM-5807 - RelatedFiles Component - EU Privacy Logic addition - START
        else if(Origin.equalsIgnoreCase('Account_RelatedFiles')){
            Boolean viewEUDPEnforcedObjectFiles = false;
            if(!profileName.containsIgnoreCase('EU Restricted') || !EURestrictedAccountStatusSet.contains(accStatus) || String.isEmpty(brandName) || !isRestrictedCountry) {
                viewEUDPEnforcedObjectFiles = true;
            } else if(EURestrictedExceptionalProfileNameSet.contains(profileName)) {
                viewEUDPEnforcedObjectFiles = true;
            } else if(EURestrictedAccountStatusSet.contains(accStatus) && EUSupportRestrictedProfileSet.contains(profileName) && !isCompletelyRestrictedCountry && String.isNotEmpty(brandName) && RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.contains(brandName.toLowerCase())) {
                viewEUDPEnforcedObjectFiles = true;   
            } else {
                viewEUDPEnforcedObjectFiles = false;
            }
            return viewEUDPEnforcedObjectFiles;
        }
        //CRM-5807 - RelatedFiles Component - EU Privacy Logic addition - END
        else if(Origin.equalsIgnoreCase('hideNotes')){

            
            if(!profileName.containsIgnoreCase('EU Restricted') || !EURestrictedAccountStatusSet.contains(accStatus) || String.isEmpty(brandName) || !isRestrictedCountry) {
                return false;
            } else if(EURestrictedExceptionalProfileNameSet.contains(profileName)){
                return false;
            } else if(EURestrictedAccountStatusSet.contains(accStatus) && EUSupportRestrictedProfileSet.contains(profileName) && String.isNotEmpty(brandName) && RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.contains(brandName.toLowerCase())){
                return false;
            } else {
                return true;
            }
        }
        return false;
    }
}/* Epic - CRM-5094 - Added as part of EU Data Privacy Project */