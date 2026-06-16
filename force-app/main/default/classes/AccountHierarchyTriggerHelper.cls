public without sharing class AccountHierarchyTriggerHelper {

    public static final Integer ACCOUNTS_ROWS_UPDATE_LIMIT = 400;
    public static final Integer LEAD_ROWS_UPDATE_LIMIT = 200;

    public class UpdateTargetAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Account_Hierarchy__c[] companies = (List<Account_Hierarchy__c>) Trigger.new;
            Map<Id, Account_Hierarchy__c> oldCompaniesMap = (Map<Id, Account_Hierarchy__c>) Trigger.oldMap;

            Map<Id, Account_Hierarchy__c> companyMap = new Map<Id, Account_Hierarchy__c>();
            for (Account_Hierarchy__c ah : companies) {
                if ((AccountHierarchyHelper.TARGET_COMPANY_STATUSES.contains(ah.Company_Status__c)
                    && !AccountHierarchyHelper.TARGET_COMPANY_STATUSES.contains(oldCompaniesMap.get(ah.Id).Company_Status__c))
                    || (!AccountHierarchyHelper.TARGET_COMPANY_STATUSES.contains(ah.Company_Status__c)
                    && AccountHierarchyHelper.TARGET_COMPANY_STATUSES
                        .contains(oldCompaniesMap.get(ah.Id).Company_Status__c))) {
                    companyMap.put(ah.Id, ah);
                }
            }

            if (companyMap.size() > 0) {
                List<Account> accsToUpdate = new List<Account>();
                List<Lead> leadsToUpdate = new List<Lead>();

                for (Account acc : [
                        SELECT Id, AH_Name__c, Target_Account__c
                        FROM Account
                        WHERE AH_Name__c IN :companyMap.keySet()
                ]) {
                    if (acc.Target_Account__c != AccountHierarchyHelper.TARGET_COMPANY_STATUSES
                            .contains(companyMap.get(acc.AH_Name__c).Company_Status__c)) {
                        acc.Target_Account__c = AccountHierarchyHelper.TARGET_COMPANY_STATUSES
                            .contains(companyMap.get(acc.AH_Name__c).Company_Status__c);
                        accsToUpdate.add(acc);
                    }
                }
                
                for (Lead ld : [
                        SELECT Id, AH_Name__c, Target_Account__c
                        FROM Lead
                        WHERE AH_Name__c IN :companyMap.keySet()
                ]) {
                    if (ld.Target_Account__c != AccountHierarchyHelper.TARGET_COMPANY_STATUSES
                            .contains(companyMap.get(ld.AH_Name__c).Company_Status__c)) {
                        ld.Target_Account__c = AccountHierarchyHelper.TARGET_COMPANY_STATUSES
                            .contains(companyMap.get(ld.AH_Name__c).Company_Status__c);
                        leadsToUpdate.add(ld);
                    }
                }

                if (accsToUpdate.size() > 0){
                    
                    if (runUpdateInAsync(accsToUpdate, leadsToUpdate)) {
                        QueueableDMLExecuter.enqueueJob(
                            accsToUpdate, QueueableDMLExecuter.DMLType.DML_UPDATE, ACCOUNTS_ROWS_UPDATE_LIMIT, null
                        );
                    } else {
                        update accsToUpdate;
                    }
                }
                if (leadsToUpdate.size() > 0) {
                    // list will be processed in several itterations by 200 records in each
                    // update of 400 records uses ~15000 CPU time
                    if (runUpdateInAsync(accsToUpdate, leadsToUpdate)) {
                        QueueableDMLExecuter.enqueueJob(
                            leadsToUpdate, QueueableDMLExecuter.DMLType.DML_UPDATE, LEAD_ROWS_UPDATE_LIMIT, null
                        );
                    } else {
                        update leadsToUpdate;
                    }
                }
            }
        }

        private boolean runUpdateInAsync(List<Account> accs, List<Lead> leads) {
            if (accs != null && accs.size() > 150 || leads != null && leads.size() > 100) {
                return true;
            }
            return false;
        }
    }

    public class UpdateInvoiceRequests extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) Trigger.new;
            Map<Id, Account_Hierarchy__c> oldCompaniesMap = (Map<Id, Account_Hierarchy__c>) Trigger.oldMap;
            Set<Id> compIds = new Set<Id>();

            for (Account_Hierarchy__c company: companies) {
                if (isChangedField(company, Account_Hierarchy__c.D_U_N_S_Number__c)
                    || isChangedField(company, Account_Hierarchy__c.AH_Website__c)
                    || isChangedField(company, Account_Hierarchy__c.AH_Phone__c)) {
                    compIds.add(company.Id);
                }
            }

            Map<Id, Account> accs = new Map<Id, Account>([
                    SELECT Id, AH_Name__c
                    FROM Account
                    WHERE AH_Name__c IN :compIds
            ]);
            List<Approval__c> approvals = new List<Approval__c>([
                    SELECT Id, Account__c
                    FROM Approval__c
                    WHERE Account__c IN :accs.keySet()
                        AND Record_Type_Name__c = 'Invoicing Request'
                        AND Opportunity__c != null
            ]);

            Map<Id, List<Approval__c>> approvalToCompany = new Map<Id, List<Approval__c>>();

            if (!approvals.isEmpty()) {
                for (Approval__c approval: approvals) {
                    for (Account account: accs.values()) {
                        if (approval.Account__c == account.Id) {
                            if (approvalToCompany.containsKey(account.AH_Name__c)) {
                                List<Approval__c> listOfApprs = approvalToCompany.get(account.AH_Name__c);
                                listOfApprs.add(approval);
                                approvalToCompany.put(account.AH_Name__c, listOfApprs);
                            } else {
                                approvalToCompany.put(account.AH_Name__c, new List<Approval__c>{approval});
                            }
                        }
                    }
                }

                List<Approval__c> approvalsToUpdate = new List<Approval__c>();
                for (Account_Hierarchy__c company: companies) {
                    if (compIds.contains(company.Id)) {
                        List<Approval__c> apprs = approvalToCompany.get(company.Id);
                        for (Approval__c appr: apprs) {
                            appr.Company_Phone_Number__c = company.AH_Phone__c;
                            appr.Company_DUNS_Number__c = company.D_U_N_S_Number__c;
                            appr.Company_Website__c = company.AH_Website__c;
                            approvalsToUpdate.add(appr);
                        }
                    }
                }
                update approvalsToUpdate;
            }
        }
    }

    public class AccountHierarchyBefore extends Triggers.TriggerHandlerBase {
        List<Account_Hierarchy__c> companies = Trigger.isDelete
                                                ? (List<Account_Hierarchy__c>) Trigger.old
                                                : (List<Account_Hierarchy__c>) Trigger.new;
        Map<String, User> ownerUsers = new Map<String, User>();

        override public void handle() {
            for (Account_Hierarchy__c company : companies) {
                if (String.isNotBlank(company.Protected_Owner__c)) {
                    ownerUsers.put(company.Protected_Owner__c, null);
                }
                if (String.isNotBlank(company.AH_Owner__c)) {
                    ownerUsers.put(company.AH_Owner__c, null);
                }
            }

            ownerUsers = new Map<String, User>([
                SELECT Id, isActive, Name
                FROM User
                WHERE Id IN :ownerUsers.keySet()
                    OR Name = :UserHelper.MARKETO_USER_NAME
            ]);

            for (User us : ownerUsers.values()) {
                if (us.Name.equalsIgnoreCase(UserHelper.MARKETO_USER_NAME)) {
                    ownerUsers.put(UserHelper.MARKETO_USER_NAME, us);
                    break;
                }
            }

            for (Account_Hierarchy__c company : companies) {
                if (String.isBlank(company.Company_Status__c)
                    || company.Company_Status__c.equalsIgnoreCase('Invalid')) {
                    company.OwnerId = (ownerUsers.get(UserHelper.MARKETO_USER_NAME) == null
                        ? null
                        : ownerUsers.get(UserHelper.MARKETO_USER_NAME).Id);
                } else {
                    if (String.isNotBlank(company.Protected_Owner__c)
                        && ownerUsers.get(company.Protected_Owner__c).isActive) {
                        company.OwnerId = company.Protected_Owner__c;
                    } else {
                        if (String.isNotBlank(company.AH_Owner__c)
                            && ownerUsers.get(company.AH_Owner__c).isActive) {
                            company.OwnerId = company.AH_Owner__c;
                        } else {
                            if (String.isBlank(company.AH_Owner__c)) {
                                company.OwnerId = (ownerUsers.get(UserHelper.MARKETO_USER_NAME) == null
                                    ? null
                                    : ownerUsers.get(UserHelper.MARKETO_USER_NAME).Id);
                            }
                        }
                    }
                }
            }
        }
    }

    public class CheckCompanyAndTerritoryOwners extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Account_Hierarchy__c> companies = (List<Account_Hierarchy__c>) Trigger.new;
            List<Territory_Data__c> territories = TerritoryHelper.getListOfSuitableTerritories(companies);
            Map<String, List<Territory_Data__c>> stateToTerritories = getStateToTerritoriesMap(territories);

            if (!territories.isEmpty()) {
                for (Account_Hierarchy__c company : companies) {
                    if (company.ZipCode__c != null) {
                        Territory_Data__c territoryToRemember;
                        Boolean isUpdated = false;
                        String companyState = TerritoryHelper.getState(company.State__c);
                        List<Territory_Data__c> territoriesWithState = stateToTerritories.get(companyState);

                        if (territoriesWithState != null) {
                            for (Territory_Data__c territory : territoriesWithState) {
                                if (isSuitableTerritory(company, territory)) {
                                    if (territory.Industry__c != null && company.Industry__c == territory.Industry__c) {
                                        company.Territory__c = territory.Id;
                                        company.AH_Territory_Name__c = territory.Name;
                                        company.AH_Owner__c = territory.Territory_Owner__c;
                                        company.AH_Alternate_Owner__c = territory.Alternate_Owner__c;
                                        isUpdated = true;
                                        break;
                                    } else if (territory.Industry__c == null) {
                                        territoryToRemember = territory;
                                    }
                                }
                            }
                        }

                        if (territoryToRemember != null && !isUpdated) {
                            company.Territory__c = territoryToRemember.Id;
                            company.AH_Territory_Name__c = territoryToRemember.Name;
                            company.AH_Owner__c = territoryToRemember.Territory_Owner__c;
                            company.AH_Alternate_Owner__c = territoryToRemember.Alternate_Owner__c;
                        }
                    }
                }
            }
        }

        @TestVisible
        private Map<String, List<Territory_Data__c>> getStateToTerritoriesMap(List<Territory_Data__c> territories) {
            Map<String, List<Territory_Data__c>> stateToTerritories = new Map<String, List<Territory_Data__c>>();
            for (Territory_Data__c territory : territories) {
                if (!stateToTerritories.containsKey(territory.State_Province__c)) {
                    stateToTerritories.put(territory.State_Province__c, new List<Territory_Data__c>());
                }
                stateToTerritories.get(territory.State_Province__c).add(territory);
            }
            return stateToTerritories;
        }

        @TestVisible
        private Boolean isZipCodeInRange(Account_Hierarchy__c company, Territory_Data__c territory) {
            Boolean res = false;
            String companyCountry = TerritoryHelper.getCountry(company.Country__c);
            if (companyCountry == AccountHierarchyHelper.CANADA) {
                String companyZipBegin = company.ZipCode__c.length() <= 3 ? company.ZipCode__c.substring(0, company.ZipCode__c.length()) : company.ZipCode__c.substring(0, 3); //17Nov2020 CR-54101: Canadian Zip Codes Mapping - Updated Canadian Zip Code from 1 to ZipCode's length
                res = companyZipBegin >= territory.Postal_Begin__c && companyZipBegin <= territory.Postal_End__c;
            } else if (companyCountry == AccountHierarchyHelper.USA) {
                Integer companyZipCode;
                Integer territoryPostalBegin;
                Integer territoryPostalEnd;
                try {
                    companyZipCode = Integer.valueOf(company.ZipCode__c.substringBefore('-'));
                    territoryPostalBegin = Integer.valueOf(territory.Postal_Begin__c);
                    territoryPostalEnd = Integer.valueOf(territory.Postal_End__c);
                    res = companyZipCode >= territoryPostalBegin && companyZipCode <= territoryPostalEnd;
                } catch (TypeException e) {
                    System.debug('Invalid zip code format.Cannot find territory');
                }
            }
            return res;
        }

        @TestVisible
        private Boolean isSuitableTerritory(Account_Hierarchy__c company, Territory_Data__c territory) {
            return TerritoryHelper.getCountry(company.Country__c) == territory.Country__c
                && company.Effective_No_of_Employees_Range__c == territory.Segment__c
                && isZipCodeInRange(company, territory);
        }
    }
}