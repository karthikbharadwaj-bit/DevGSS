public with sharing class PartnerLeads {
    //Method to get lead list
    @AuraEnabled
    public static LeadListWrapper getLeadDataController(String selectedPartnerAccount, Decimal pageNumber, Decimal pageSize, String searchKeyWord, String searchBy) {
        //get list view of Leads
        LeadListWrapper objLDWrapper = new LeadListWrapper();
        List<Account> accList = new List<Account>();
        List<Lead> leadList = new List<Lead>();
        Integer pSize = (Integer) pageSize;
        Integer pNumber = (Integer) pageNumber;
        Boolean isReadOnlyProfile = Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        string[] listStatus = new string[]{
            '0. Downgraded', '1.5 Call Out', '1. New', '2. Contacted'
        };
        string nonAvayaUsers = System.Label.Non_Avaya_Users;
        string [] listUsers = nonAvayaUsers.split(';');
        //Offset for SOQL

        Integer offset = (pNumber - 1) * pSize;
        Integer recordEnd = pSize * pNumber;
        Integer totalRecords;
        String AvayaOffice = '';

        AccountListWrapper accWrapper = getAccountList();
        List<String> brandNamesList = accWrapper.partnerCommunityName;
        String masterLabel = accWrapper.communityDetailsRecord.MasterLabel;
        if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
            AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if (System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit) != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit) > 0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords = 1000;
        }
        //Single Login code starts
        Set<Id> setUserAccIds = new Set<Id>();
        if (accWrapper != null && accWrapper.listUserAccountMap != null && !accWrapper.listUserAccountMap.isEmpty()) {
            for (User_Account_Mapping__c uam : accWrapper.listUserAccountMap) {
                setUserAccIds.add(uam.Partner_Account__c);
            }
        }
        system.debug('setUserAccIds>' + setUserAccIds);
        //Single Login code ends

        if (selectedPartnerAccount == null) {
            accList = accWrapper.listPartnerAccounts;
            if (accList.size() > 0) {
                selectedPartnerAccount = accList[0].Id;
            }
        }
        String query = '';

        //Fix for PCM JIRA issue BZS-3636 - start
        Set<Id> setOfCurrentUserContactIds = new Set<Id>();
        String currentContact = '';
        if (brandNamesList.contains('RingCentral') && masterLabel == 'ignite') {
            List<User> users = [
                SELECT Id, Name, ContactId, Contact.AccountId,
                    Contact.Account.Partner_Account__c, Contact.Partner_Portal_View__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            if (users != null && !users.isEmpty() && users.size() > 0) {
                currentContact = users[0].ContactId;
            }
            List<Portal_Access__c> listOfPortalAccess = [SELECT Id, Account__c, Contact__c FROM Portal_Access__c WHERE Contact__c = :currentContact];

            if (listOfPortalAccess != null && !listOfPortalAccess.isEmpty() && listOfPortalAccess.size() > 0) {
                for (Portal_Access__c portalAccess : listOfPortalAccess) {
                    setOfCurrentUserContactIds.add(portalAccess.Contact__c);
                    system.debug('setOfCurrentUserContactIds-' + setOfCurrentUserContactIds);
                }
            }
        }
        //Fix for PCM JIRA issue BZS-3636 - end

        if (brandNamesList.contains('Avaya Cloud Office')) {
            query = 'select count() from Lead where isConverted = false and (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Lead__c = true and (Lead_Brand_Name__c = null OR Lead_Brand_Name__c = \'' + AVAYAOFFICE + '\')';
        } else {
            //added if condition for Fix for PCM JIRA issue BZS-3636
            if (brandNamesList.contains('RingCentral') && masterLabel == 'ignite') {
                query = 'select count() from Lead where isConverted = false and (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = ' + '\'' + currentContact + '\') and Lead_Brand_Name__c  IN: brandNamesList and Avaya_Partnership_Lead__c = true';
            } else if (brandNamesList.contains('Unify Office')) {
                query = 'select count() from Lead where isConverted = false and (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__r.Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Lead_Brand_Name__c  IN: brandNamesList and Avaya_Partnership_Lead__c = true';
            } else {
                query = 'select count() from Lead where isConverted = false and (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Lead_Brand_Name__c  IN: brandNamesList and Avaya_Partnership_Lead__c = true';
            }
        }
        if (null != searchKeyWord && searchKeyWord != '') {
            String searchKey = '\'%' + searchKeyWord + '%\'';
            if (searchBy == 'Number_of_Users__c') {
                query += ' And ' + searchBy + ' =' + searchKeyWord;
            } else {
                query += ' And ' + searchBy + '  Like ' + searchKey;
            }
        }
        Integer totSize = Database.countquery(query);

        if (totSize < totalRecords) {
            totalRecords = totSize;
        }

        if (null != totalRecords && totalRecords > 0) {
            if (brandNamesList.contains('Avaya Cloud Office')) {
                query = 'select company,Name,Email, Phone, Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name  from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'  AND CreatedById NOT IN: listUsers AND (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Avaya_Partnership_Lead__c = true and (Lead_Brand_Name__c = null OR Lead_Brand_Name__c = \'' + AVAYAOFFICE + '\')';
            } else {
                //added if condition for Fix for PCM JIRA issue BZS-3636
                if (brandNamesList.contains('RingCentral') && masterLabel == 'ignite') {
                    query = 'select company,Name,Email, Phone, Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'  AND CreatedById NOT IN: listUsers AND (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds  OR Partner_Account__r.Partner_Channel_Manager__c IN: setOfCurrentUserContactIds OR Partner_Account__r.Partner_Channel_Manager__c = ' + '\'' + currentContact + '\') and Lead_Brand_Name__c IN: brandNamesList and Avaya_Partnership_Lead__c = true';
                } else if (brandNamesList.contains('Unify Office')) {
                    query = 'select company,Name,Email, Phone, Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'  AND CreatedById NOT IN: listUsers AND (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__r.Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Lead_Brand_Name__c IN: brandNamesList and Avaya_Partnership_Lead__c = true';
                } else {
                    query = 'select company,Name,Email, Phone, Avaya_Cloud_Specialist__c, RC_Overlay__c,Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'  AND CreatedById NOT IN: listUsers AND (Partner_Account__c=' + '\'' + selectedPartnerAccount + '\' OR Partner_Account__c IN: setUserAccIds) and Lead_Brand_Name__c IN: brandNamesList and Avaya_Partnership_Lead__c = true';
                }
            }
            if (null != searchKeyWord && searchKeyWord != '') {
                String searchKey = '\'%' + searchKeyWord + '%\'';
                if (searchBy == 'Number_of_Users__c') {
                    query += ' And ' + searchBy + ' =' + searchKeyWord;
                } else {
                    query += ' And ' + searchBy + '  Like ' + searchKey;
                }
            }
            query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset';
            leadList = Database.query(query);
            objLDWrapper.leadList = leadList;
        }
        objLDWrapper.pageSize = pSize;
        objLDWrapper.pageNumber = pNumber;
        objLDWrapper.recordStart = offset + 1;
        objLDWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objLDWrapper.totalRecords = totalRecords;
        objLDWrapper.isReadOnly = isReadOnlyProfile;
        return objLDWrapper;
    }

    //Translation Start
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames) {
        return CommunityInfo.getTranslations(objNames);
    }
    //Translation End


    @AuraEnabled
    public static LeadListWrapper getDataForViewAll(Decimal pageNumber, Decimal pageSize, String searchKeyWord, String searchBy) {
        //get list view of Leads
        LeadListWrapper objLDWrapper = new LeadListWrapper();
        List<Account> accList = new List<Account>();
        List<Lead> leadList = new List<Lead>();
        Integer pSize = (Integer) pageSize;
        Integer pNumber = (Integer) pageNumber;
        Boolean isReadOnlyProfile = Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        string[] listStatus = new string[]{
            '0. Downgraded', '1.5 Call Out', '1. New', '2. Contacted'
        };
        string nonAvayaUsers = System.Label.Non_Avaya_Users;
        string [] listUsers = nonAvayaUsers.split(';');

        AccountListWrapper accWrapper = getAccountList();

        //Offset for SOQL
        Integer offset = (pNumber - 1) * pSize;
        Integer recordEnd = pSize * pNumber;
        String query = '';
        Integer totalRecords;
        String AvayaOffice = '';
        List<String> brandNamesList = accWrapper.partnerCommunityName;
        if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
            AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if (System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit) != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit) > 0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords = 1000;
        }
        if (brandNamesList.contains('Avaya Cloud Office')) {
            query = 'select count() from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'' +
                ' AND CreatedById NOT IN: listUsers and Avaya_Partnership_Lead__c = true and (Lead_Brand_Name__c = null OR Lead_Brand_Name__c = \'' + AVAYAOFFICE + '\')';
        } else {
            query = 'select count() from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'' +
                ' AND CreatedById NOT IN: listUsers and Lead_Brand_Name__c IN: brandNamesList and Avaya_Partnership_Lead__c = true' +
                ' AND Portal_Lead__c = true';
        }

        if (null != searchKeyWord && searchKeyWord != '') {
            String searchKey = '\'%' + searchKeyWord + '%\'';
            if (searchBy == 'Number_of_Users__c') {
                query += ' And ' + searchBy + ' =' + searchKeyWord;
            } else {
                query += ' And ' + searchBy + '  Like ' + searchKey;
            }
        }
        Integer totSize = Database.countquery(query);

        if (totSize < totalRecords) {
            totalRecords = totSize;
        }

        if (null != totalRecords && totalRecords > 0) {
            if (brandNamesList.contains('Avaya Cloud Office')) {
                query = 'select company,Name,Email, Avaya_Cloud_Specialist__c, RC_Overlay__c,Phone, Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,' +
                    'Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name  ' +
                    ' from Lead where isConverted = false AND Status IN: listStatus  AND Lead_Brand_Name__c !=\'BT Business\'' +
                    ' AND CreatedById NOT IN: listUsers  and Avaya_Partnership_Lead__c = true and (Lead_Brand_Name__c = null OR Lead_Brand_Name__c = \'' + AVAYAOFFICE + '\')';
            } else {
                query = 'SELECT company,Name,Email, Avaya_Cloud_Specialist__c, RC_Overlay__c,Phone, Partner_Contact__r.Name,Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Account__r.Partner_Channel_Manager__c,Partner_Contact__c,' +
                    ' Partner_Contact__r.FirstName,Partner_Contact__r.LastName, CreatedDate, Owner.Name,Number_of_Users__c,Status,Country__c,State__c,Portal_Cloud_Specialist__c,Portal_Cloud_Specialist__r.Name,Ignite_AE__c,Ignite_AE__r.Full_Name__c  ' +
                    ' FROM Lead where isConverted = false AND Status IN: listStatus AND Lead_Brand_Name__c != \'BT Business\'' +
                    ' AND CreatedById NOT IN: listUsers and Lead_Brand_Name__c IN: brandNamesList and Avaya_Partnership_Lead__c = true' +
                    ' AND Portal_Lead__c = true';
            }

            if (null != searchKeyWord && searchKeyWord != '') {
                String searchKey = '\'%' + searchKeyWord + '%\'';
                if (searchBy == 'Number_of_Users__c') {
                    query += ' And ' + searchBy + ' =' + searchKeyWord;
                } else {
                    query += ' And ' + searchBy + '  Like ' + searchKey;
                }
            }
            query += ' ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset';
            leadList = Database.query(query);
            objLDWrapper.leadList = leadList;
        }
        objLDWrapper.pageSize = pSize;
        objLDWrapper.pageNumber = pNumber;
        objLDWrapper.recordStart = offset + 1;
        objLDWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objLDWrapper.totalRecords = totalRecords;
        objLDWrapper.isAvaya = accWrapper.isAvaya;
        objLDWrapper.isMaster = accWrapper.isMaster;
        objLDWrapper.isReadOnly = isReadOnlyProfile;
        return objLDWrapper;
    }

    //Method to get partner accounts
    @AuraEnabled
    public static AccountListWrapper getAccountList() {
        //get ParentAccount list to be populated in drop-down of list view
        AccountListWrapper accListWrapper = new AccountListWrapper();
        List<Account> listofPartnerAccounts = new List<Account>();
        Boolean isReadOnlyProfile = Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
        System.debug('== Partner== ' + selectedPartnerAccount);

        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();

        //Single Login code starts
        Set<Id> setUserId = new Set<Id>();
        setUserId.add(UserInfo.getUserId());
        List<User_Account_Mapping__c> listUserAccountMap = new List<User_Account_Mapping__c>([
            Select Id, Partner_Account__c, Partner_User__c
            from User_Account_Mapping__c
            where Partner_User__c IN :setUserId
        ]);
        system.debug('listUserAccountMap>>' + listUserAccountMap);
        if (!listUserAccountMap.isEmpty()) {
            accListWrapper.isSingleLogin = true;
            accListWrapper.listUserAccountMap = listUserAccountMap;
        }
        //Single Login code ends

        if (selectedPartnerAccount != NULL) {
            for (Account acc : [
                SELECT Id, Name, Partner_Role__c
                FROM Account
                WHERE Id = :selectedPartnerAccount
                AND Type = 'Partner'
                order by Name
            ]) {
                listofPartnerAccounts.add(acc);
                if (acc.id == comDetail.Portal_Top_Master_Account_Id__c) {
                    accListWrapper.isAvaya = true;
                    accListWrapper.isMaster = false;
                } else if (acc.Partner_Role__c == 'Master Agent') {
                    accListWrapper.isAvaya = false;
                    accListWrapper.isMaster = true;
                }
            }
            accListWrapper.listPartnerAccounts = listofPartnerAccounts;
            accListWrapper.isReadOnly = isReadOnlyProfile;
        }
        //get the current logged in Network Name
        accListWrapper.partnerCommunityName = comDetail.Brand_Name__c.split(';');
        accListWrapper.brandList = comDetail.Brand_Name__c.split(';');
        accListWrapper.communityDetailsRecord = comDetail;
        return accListWrapper;
    }
    //Method to get lead detail
    @AuraEnabled
    public static LeadRecordWrapper getLeadDetail(String leadRecordId) {
        Lead objLead = new Lead();
        Boolean isReadOnlyProfile = Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        AccountListWrapper accWrapper = getAccountList();

        LeadRecordWrapper lw = new LeadRecordWrapper();
        //Added Is_RFP_Needed__c for ALE
        //Added Classification for PBC-9705 P2CSharing
        //Added Partners_CRM_Opporunity_ID__c under PBC-10584
        objLead = [
            Select Id, status, Name, FirstName, LastName, Title, Company, Partner_Type__c, BusinessIdentity__c, Email, Phone, Street, City, State__c, PostalCode, Country__c, Number_of_Users__c, Lead_Brand_Name__c, Lead_Tier_Name__c,
                Partner_Lead_Source__c, NumberOfEmployees__c, Number_of_Locations__c, Industry, Estimated_Close_Date__c, How_did_you_acquire_this_Lead__c, Description, website, Existing_Solution_Provider__c, Sector__c,
                Prompting_Change__c, Partner_Lead_Owner__r.Name, Deal_Registration__r.Name, Partner_Account__r.Name, Partner_Account__r.Partner_ID__c, Partner_Contact__r.Name, Competitors__c, Decision_Maker__c, Currently_in_a_contract__c, Project_budget__c, Partner_Lead_Owner__c, Deal_Registration__c, Partner_Account__c, Partner_Account__r.Partner_Classification__c,
                Partner_Contact__c, Inside_Sales_Rep__c, Inside_Sales_Rep__r.Name, Sales_Notes__c, IsAvayaConverted__c, Avaya_Cloud_Specialist__c, RC_Overlay__c, Partner_Account__r.Partner_Country__c, Owner.Name, OwnerId, Portal_Cloud_Specialist__c, Portal_Cloud_Specialist__r.Name, Deal_Registration__r.Ignite_Deal__c,
                Forecasted_RingCentral_Video_Users__c, CurrencyISOCode, Partners_CRM_Opporunity_ID__c, Type_of_Customer_or_Prospect__c, Mitel_Data_Sharing__c, Partner_Program__c,Installation_Service_Provider__c
            from Lead
            where Id = :leadRecordId
        ];
        lw.leadRecord = objLead;
        lw.isAvaya = accWrapper.isAvaya;
        lw.isMaster = accWrapper.isMaster;
        lw.isReadOnly = isReadOnlyProfile;
        Community_Details__mdt comDetail = accWrapper.communityDetailsRecord;
        lw.partnerCommunityName = comDetail.Brand_Name__c.split(';');
        lw.communityDetailsRecord = comDetail;
        lw.isSingleLogin = accWrapper.isSingleLogin;
        lw.duplicateIdList = getLeadDuplicateIds(objLead);

        List<Ignite_Excluded_Brands__mdt> igniteDisabledBrandsMDT = Ignite_Excluded_Brands__mdt.getAll().values();
          List<String> allDisabledBrands = new List<String>();
			for (Ignite_Excluded_Brands__mdt igniteDisabledBrands : igniteDisabledBrandsMDT) {
				allDisabledBrands.add(igniteDisabledBrands.Brand__c);
			}
        lw.isIgniteDisabledBrand = allDisabledBrands.contains(objLead.Lead_Brand_Name__c);
        return lw;
    }

    //Method to get lead duplicates
    @AuraEnabled
    public static List<Id> getLeadDuplicateIds(Lead l) {
        List<Datacloud.FindDuplicatesResult> findDuplicatesResults = Datacloud.FindDuplicates.findDuplicates(new List<sObject> { l });
        List<Id> result = new List<Id>();

        if (findDuplicatesResults.isEmpty()) {
            return result;
        }

        for (Datacloud.FindDuplicatesResult findDuplicatesResult : findDuplicatesResults) {
            for (Datacloud.DuplicateResult duplicateResult : findDuplicatesResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : duplicateResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord: matchResult.getMatchRecords()) {
                        result.add(matchRecord.getRecord().Id);
                    }
                }
            }
        }

        return result;
    }

    //Method to update leads
    @AuraEnabled
    public static String updateLead(Lead leadRec) {
        //upon edit,save the record
        String response = 'Success';
        try {
            update leadRec;
        } catch (Exception e) {
            response = e.getMessage();
        }
        return response;
    }

    //Method to convert lead
    @AuraEnabled
    public static CovertedLeadWrapper convertLeadRecord(Lead lead) {
        CovertedLeadWrapper objCLW = new CovertedLeadWrapper();
        objCLW.convertResponse = 'Success';
        objCLW.lead = lead;
        try {
            PartnerDealRegistrationUtil.PartnerLeadConvertResult result = PartnerDealRegistrationUtil.convertPartnerLead(lead, true);
            if (result.status == 'success') {
                objCLW.convertResponse = 'Success';
            } else {
                objCLW.convertResponse = 'Error: Problem converting Lead, Please contact your Channel Manager.';
            }

        } catch (NullPointerException e) {
            objCLW.convertResponse = 'There was some error during processing!';
        } catch (ListException e) {
            objCLW.convertResponse = 'There was some error during processing!';
        } catch (Exception e) {
            objCLW.convertResponse = e.getMessage();
            system.debug('Exception during Lead Convert' + objCLW.convertResponse);
        }
        return objCLW;
    }

    @AuraEnabled
    public static PickListWrapperForCountry getCountryStateMap(String communityBrand) {
        Map<String, List<String>> dependentPicklistValuesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Lead.State__c);
        Map<String, List<String>> countryCompetitorMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Lead.Competitors__c);
        Map<String, List<String>> countryEmployeesMap = ControlAndDependentPicklstMap.getDependentPicklistValues(Lead.NumberOfEmployees__c);
        PickListWrapperForCountry picklistWrapperObj = new PickListWrapperForCountry();
        picklistWrapperObj.countryStateMap = dependentPicklistValuesMap;
        picklistWrapperObj.countryNoOfEmployeesMap = countryEmployeesMap;
        BrandCountryWrapper brandWrapr = new BrandCountryWrapper();
        brandWrapr = PartnerLeads.getCountriesAvailableForCommunity(communityBrand);
        picklistWrapperObj.countriesAvailable = brandWrapr.countries;
        picklistWrapperObj.mapBrandCntry = brandWrapr.mapBrandCntry;

        picklistWrapperObj.countryCompetitorMap = countryCompetitorMap;
        UserInfoWrapper infowrapper = PartnerLeads.getCurrentUserInfo();
        picklistWrapperObj.loggedPartnerCountry = infowrapper.partnerCountry;
        CommunityInfo commInfo = new CommunityInfo();
        CommunityInfo.getBrandName();
        boolean isRestrictEnabled = CommunityInfo.enableRestrictCntry;
        if (isRestrictEnabled) {
            picklistWrapperObj.partnerhasAllCntryAcess = !infowrapper.partnerhasAllCntryAcess;
        } else {
            picklistWrapperObj.partnerhasAllCntryAcess = infowrapper.partnerhasAllCntryAcess;
        }
        //Added for multiple countries in ACO 3.0
        if (infowrapper != null) {
            picklistWrapperObj.partnerAvailableCountries = infowrapper.partnerAvailableCountries;
        }
        return picklistWrapperObj;
    }
    public static BrandCountryWrapper getCountriesAvailableForCommunity(String communityBrand) {
        List<String> countries = new List<String>();
        BrandCountryWrapper brandWrapper = new BrandCountryWrapper();
        Map<String, List<String>> mapBrandCntry = new Map<String, List<String>>();
        List<String> tmpLst = new List<String>();

        if (communityBrand == null || communityBrand == '') {
            Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
            communityBrand = comDetail.Brand_Name__c;
        }
        List<Community_Detail_Child__mdt> countriesForBrand = [select Country_Name__c, Brand_Country__c from Community_Detail_Child__mdt where Community_Details__r.Brand_Name__c = :communityBrand];
        for (Community_Detail_Child__mdt communityObj : countriesForBrand) {

            if (mapBrandCntry.containsKey(communityObj.Brand_Country__c)) {
                mapBrandCntry.get(communityObj.Brand_Country__c).add(communityObj.Country_Name__c);
            } else {
                tmpLst = new List<String>();
                tmpLst.add(communityObj.Country_Name__c);
                mapBrandCntry.put(communityObj.Brand_Country__c, tmpLst);
            }
            if (countries.indexOf(communityObj.Country_Name__c) == -1) {
                countries.add(communityObj.Country_Name__c);
            }
        }
        if (countries.size() == 0) {
            countries.add('United States');
        }
        brandWrapper.countries = countries;
        brandWrapper.mapBrandCntry = mapBrandCntry;
        return brandWrapper;
    }
    @AuraEnabled
    public static UserInfoWrapper getCurrentUserInfo() {
        Id currentLoggedUserId = UserInfo.getUserId();
        List<Account> userInfoDetailAccount = new List<Account>();
        UserInfoWrapper userWrapper = new UserInfoWrapper();
        Id sysAdminProfileId;
        List<Profile> sysAdminProfile = [SELECT id, Name FROM Profile Where Name = :Label.System_Administrator];

        if (!sysAdminProfile.isEmpty()) {
            sysAdminProfileId = sysAdminProfile[0].Id;
        }

        //Added Permitted_Countries__c for multi country picklist in ACO 3.0
        List<User> userInfoDetail = [
            select contact.accountid, contact.Restrict_Country__c, contact.Permitted_Countries__c
            from user
            where id = :currentLoggedUserId
        ];
        if (!userInfoDetail.isEmpty()) {
            CustomPermissionHelper ph = new CustomPermissionHelper();
            userWrapper.customPermissions = ph.getPermissionSet();
            userInfoDetailAccount = [select id, name, Partner_country__c from account where id = :userInfoDetail.get(0).contact.accountid];
            userWrapper.partnerhasAllCntryAcess = userInfoDetail.get(0).contact.Restrict_Country__c;
            //ACO 3.0
            String permittedCountries = userInfoDetail.get(0).contact.Permitted_Countries__c;
            if (permittedCountries != null && permittedCountries != '') {
                List<String> permittedCountriesLst = permittedCountries.split(';');
                Set<String> permittedCountriesSet = new Set<String>();
                permittedCountriesSet.addAll(permittedCountriesLst);
                userWrapper.partnerAvailableCountries = permittedCountriesSet;
            }
        }
        if (!userInfoDetailAccount.isEmpty()) {
            userWrapper.partnerCountry = userInfoDetailAccount.get(0).Partner_country__c;
        }

        return userWrapper;

    }
    public class LeadListWrapper {
        @AuraEnabled
        public Integer pageSize { get; set; }
        @AuraEnabled
        public Integer pageNumber { get; set; }
        @AuraEnabled
        public Integer totalRecords { get; set; }
        @AuraEnabled
        public Integer recordStart { get; set; }
        @AuraEnabled
        public Integer recordEnd { get; set; }
        @AuraEnabled
        public List<Lead> leadList { get; set; }
        @AuraEnabled
        public boolean isAvaya { get; set; }
        @AuraEnabled
        public boolean isMaster { get; set; }
        @AuraEnabled
        public boolean isReadOnly { get; set; }
    }
    Public class CovertedLeadWrapper {
        @AuraEnabled
        public string convertResponse { get; set; }
        @AuraEnabled
        public Lead lead { get; set; }

    }

    public class AccountListWrapper {
        @AuraEnabled
        public List<Account> listPartnerAccounts { get; set; }
        @AuraEnabled
        public boolean isAvaya { get; set; }
        @AuraEnabled
        public boolean isMaster { get; set; }
        @AuraEnabled
        public boolean isReadOnly { get; set; }
        @AuraEnabled
        public boolean isSingleLogin { get; set; }
        @AuraEnabled
        public List<String> partnerCommunityName { get; set; }
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord { get; set; }
        @AuraEnabled
        public List<String> brandList { get; set; }
        @AuraEnabled
        public List<User_Account_Mapping__c> listUserAccountMap { get; set; } //added for Single Login
    }
    public class LeadRecordWrapper {
        @AuraEnabled
        public Lead leadRecord { get; set; }
        @AuraEnabled
        public boolean isAvaya { get; set; }
        @AuraEnabled
        public boolean isMaster { get; set; }
        @AuraEnabled
        public boolean isReadOnly { get; set; }
        @AuraEnabled
        public boolean isSingleLogin { get; set; }
        @AuraEnabled
        public List<String> partnerCommunityName { get; set; }
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord { get; set; }
        @AuraEnabled
        public List<Id> duplicateIdList { get; set; }
        @AuraEnabled
        public boolean isIgniteDisabledBrand { get; set; }
    }
    //Request method to convert deal to lead
    //check IsAvayaConverted to true
    @AuraEnabled
    public static String requestToConvertLead(String leadId) {
        String message = '';
        SavePoint sp = Database.setSavepoint();
        String AvayaOffice = '';
        List<String> brandNamesList = getAccountList().partnerCommunityName;
        String salesOverlayQueue = getAccountList().communityDetailsRecord.Portal_SalesOverlay_Queue__c;
        if (System.Label.AVAYACLOUDOFFICE != null && String.valueOf(System.Label.AVAYACLOUDOFFICE) != null) {
            AvayaOffice = String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        try {
            //CHECK ISAVAYACONVERTED TO TRUE
            if (leadId != null) {
                Lead objLead = new Lead(Id = leadId);
                if (objLead != null) {
                    Deal_Support__c dealSupp = new Deal_Support__c();
                    objLead.IsAvayaConverted__c = true;
                    update objLead;
                    message = 'SUCCESS';

                    Lead leadRec = getLeadDetail(leadId).leadRecord;
                }
            } else {
                message = 'ERROR';
            }
        } catch (Exception e) {
            Database.rollback(sp);
            message = 'ERROR';
            System.debug('Error at ' + e.getlineNumber() + ' : ' + e.getMessage());
        }
        return message;
    }
    public class PickListWrapperForCountry {
        @AuraEnabled
        public Map<String, List<String>> countryStateMap { get; set; }
        @AuraEnabled
        public List<String> countriesAvailable { get; set; }
        @AuraEnabled
        public Map<String, List<String>> countryCompetitorMap { get; set; }
        @AuraEnabled
        public Map<String, List<String>> countryNoOfEmployeesMap { get; set; }
        @AuraEnabled
        public String loggedPartnerCountry { get; set; }
        @AuraEnabled
        public boolean partnerhasAllCntryAcess { get; set; }
        @AuraEnabled
        public Map<String, List<String>> mapBrandCntry { get; set; }
        @AuraEnabled
        public Set<String> partnerAvailableCountries { get; set; }//ACO 3.0
    }
    public class BrandCountryWrapper {
        public List<String> countries { get; set; }
        public Map<String, List<String>> mapBrandCntry { get; set; }
    }
    public class UserInfoWrapper {
        @AuraEnabled
        public Set<String> customPermissions { get; set; }
        @AuraEnabled
        public String partnerCountry { get; set; }
        @AuraEnabled
        public boolean partnerhasAllCntryAcess { get; set; }
        @AuraEnabled
        public Set<String> partnerAvailableCountries { get; set; }//ACO 3.0
    }
}