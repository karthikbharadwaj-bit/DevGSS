public class Lead_ConvertController {

    public static Lead getLead(String recordId) {
        Lead lead = null;
        List<Lead> leads = new LeadSelector()
            .selectShortDataLead(new List<Object>{new Set<Id>{recordId}})
            .executeQuery();

        if (!leads.isEmpty()) {
            lead = leads.get(0);
        }

        return lead;
    }

    public class LeadConvertResponse {
        @AuraEnabled public String response;
        @AuraEnabled public Boolean isUseNewConvertLeadPage;

        public LeadConvertResponse(String response, Boolean isUseNewConvertLeadPage) {
            this.response = response;
            this.isUseNewConvertLeadPage = isUseNewConvertLeadPage;
        }
    }

    @AuraEnabled
    public static LeadConvertResponse convertLead(String recordId) {
        String response;
        LeadConvertResponse lcr;
        // Set<String> setLeadOwnerIds=new Set<String>{'0053400000CII2J','0053400000BqoYu','0053400000BqoYp','0053400000C176u','005340000093aVC'};
        Set<Id> setLeadOwnerIds = new Set<Id>();

        for (Lead_Owners_For_Lead_Conversion__mdt lowner : [select Id, Label, LeadOwner_Id__c from Lead_Owners_For_Lead_Conversion__mdt order by label]) {
            setLeadOwnerIds.add(lowner.LeadOwner_Id__c);
        }

        system.debug('setLeadOwnerIds' + setLeadOwnerIds);

        try {
            Lead l = [select Id, Name, ownerid from Lead where Id = :recordId];
            //String leadOwnerId = ((String)(l.ownerid)).substring(0,15);

            system.debug('lownerid' + l.ownerid);

            if (setLeadOwnerIds.contains(l.ownerid)) {
                response = 'Unable to convert record. Please change ownership before converting';
            } else {
                response = LeadHelperCls.convert(recordId);

                system.debug('response' + response);

                if (response == null) {
                    response = 'Success';
                } else {
                    response = 'Unable to convert Record. ' + response;
                }
            }
        } catch (Exception e) {
            response = 'Unable to convert record. Error during processing.';
        }

        lcr = new LeadConvertResponse(response, Feature_Toggle__c.getInstance().NewConvertLeadPage__c);

        return lcr;
    }

    @AuraEnabled
    public static Boolean validateLeadConvertAccess(String recordId) {
        Boolean isSearchPackagesEnabled = Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c;
        Boolean isAccessAvailable = !isSearchPackagesEnabled;
        Lead lead = getLead(recordId);

        if (isSearchPackagesEnabled && lead != null) {
            isAccessAvailable = isUserProfileWithinPackageBIMapping(lead.Lead_Brand_Name__c);
        }

        return isAccessAvailable;
    }

    public static Boolean isUserProfileWithinPackageBIMapping(String brand) {
        Boolean hasProfile = false;
        Map<String, PackageBusinessIdentityMapping__c> packageBIMap = PackageBusinessIdentityMapping__c.getAll();
        Profile userProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        for (PackageBusinessIdentityMapping__c packageBI: packageBIMap.values()) {
            if (packageBI.Active__c && (packageBI.DefaultBrand__c.equalsIgnoreCase(brand) || String.isEmpty(brand))) {
                List<String> profiles = StringHelper.safeSplit(packageBI.Profile__c, ',');

                for (String profile: profiles) {
                    if (userProfile.Name.equalsIgnoreCase(profile)) {
                        hasProfile = true;
                        break;
                    }
                }

                if (hasProfile) {
                    break;
                }
            }
        }

        return hasProfile;
    }
}