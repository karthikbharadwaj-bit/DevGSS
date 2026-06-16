public inherited sharing class AEMWrappers {
    public class AEMCases {
        public String caseId;
        public String caseNumber;
        public String subject;
        public String status;

        public AEMCases(String caseId, String caseNumber, String subject, String status) {
            this.caseId = caseId;
            this.caseNumber = caseNumber;
            this.subject = subject;
            this.status = status;
        }
    }

    public class AEMBilling {
        public String nextBillingDate;
        public String billingCycle;
        public String paymentSchedule;
        public String servicePlan;
        public String salesAgreementEndDate;
        public Decimal numberOfDigitalLines;
        public Decimal totalAccountDLs;
        public String currentOwnerName;
        public String currentOwnerEmail;
        public String currentOwnerPhone;

        public AEMBilling(Contact contact, String lang) {
            if (contact == null || contact.Account == null) {
                this.nextBillingDate = null;
                this.salesAgreementEndDate = null;
                this.billingCycle = null;
                this.paymentSchedule = null;
                this.servicePlan = null;
                this.numberOfDigitalLines = null;
                this.currentOwnerName = null;
                this.currentOwnerEmail = null;
                this.currentOwnerPhone = null;
            } else {
                Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(
                    'Account',
                    contact.Account.Recordtype.Name,
                    lang,
                    'Payment_Plan__c',
                    false
                );
                this.nextBillingDate = StringHelper.safeString(contact.Account.Next_Renewal_Date__c);
                this.salesAgreementEndDate = StringHelper.safeString(contact.Account.Sales_Agreement_End_Date__c);
                this.billingCycle = StringHelper.safeString(contact.Account.Invoice_Terms__c);
                this.paymentSchedule = StringHelper.safeString(CaseHelper.getTranslatedLabel(translatedLabelByValue, contact.Account.Payment_Plan__c));
                this.servicePlan = StringHelper.safeString(contact.Account_Tier__c);
                this.numberOfDigitalLines = contact.Account_Number_of_DLs__c != null ?
                                            contact.Account_Number_of_DLs__c : 0;
                this.totalAccountDLs = contact.Account.Total_Account_DL_s__c != null ?
                                        contact.Account.Total_Account_DL_s__c : 0;
                this.currentOwnerName = StringHelper.safeString(contact.Account?.Current_Owner__r?.Name);
                this.currentOwnerEmail = StringHelper.safeString(contact.Account?.Current_Owner__r?.Email);
                this.currentOwnerPhone = StringHelper.safeString(contact.Account?.Current_Owner__r?.Phone);
            }
        }
    }

    //PBC-31596
    public class proServProjectManager {
        public String id;
        public String name;
        public String email;
        public String phoneNumber;

        public proServProjectManager(User projectManagerUser) {
            this.id = StringHelper.safeString(projectManagerUser?.Id);
            this.name = StringHelper.safeString(projectManagerUser?.Name);
            this.email = StringHelper.safeString(projectManagerUser?.Email);
            this.phoneNumber = StringHelper.safeString(projectManagerUser?.Phone);
        }
    }

    //PBC-31596
    public class AEMProServProject {
        public String id;
        public proServProjectManager projectManager;
        public String projectName;

        public AEMProServProject(ProServ_Project__c proServProject) {
            if (proServProject == null) {
                this.id = '';
                this.projectManager = new proServProjectManager(null);
                this.projectName = '';
                return;
            }

            this.id = StringHelper.safeString(proServProject.Id);
            this.projectManager = new proServProjectManager(proServProject.ProServProjectManager__r);
            this.projectName = StringHelper.safeString(proServProject.Project_Name__c);
        }
    }

    public class AEMContactInfo {
        public String name;
        public String businessType;
        public String role;
        public String email;
        public String phoneNumber;
        public String mainContact;
        public String companyAddress;
        public String csm_name = '';
        public String csm_email = '';
        public String csm_smallPhotoUrl;
        public String csm_fullPhotoUrl;
        public String csm_phone;
        public String accountStatus;
        public String brand;
        public String packageName;
        public String implementationStatus;
        public String packageStatus;
        public String videoProvider;
        public String accountCreatedDate;
        public String inContact_Cluster;
        public String Account_POD;
        public String enterpriseSupportStartDate;
        public String enterpriseSupportEndDate;
        public String technicalAccountManager;
        public List<AEMProServProject> proServProjects;
        public String UCESServiceLevel;
        public Boolean is_partner_sold_ES;
        public Boolean enterpriseSupportDesignatedContact;

        public AEMContactInfo(Contact contact, String lang) {
            this(contact, lang, new List<ProServ_Project__c>());
        }

        public AEMContactInfo(
            Contact contact,
            String lang,
            List<ProServ_Project__c> proServProjects
        ) {
            Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(
                'Account',
                contact.Account.Recordtype.Name,
                lang,
                'UC_ES_Service_Level__c',
                false
            );
            User csmUser = getUserToFillCSMData(contact);

            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {new Set<Id>{contact.AccountId}})
                .executeQuery();
            Map<Id, Package__c> officePackageToProcessMap = PackageHelper.filterPackagesByService(packages, AccountHelper.SERVICE_TYPE_OFFICE);
            Package__c officePackageToProcess = officePackageToProcessMap.get(contact.AccountId);

            if (csmUser != null) {
                this.csm_name = csmUser.FirstName != null ? csmUser.FirstName + ' ' + csmUser.LastName : csmUser.LastName;
                this.csm_email = StringHelper.safeString(csmUser.Email);
                this.csm_smallPhotoUrl = StringHelper.safeString(csmUser.SmallPhotoUrl);
                this.csm_fullPhotoUrl = StringHelper.safeString(csmUser.FullPhotoUrl);
                this.csm_phone = StringHelper.safeString(contact.Account.CSM__r.Phone);
            }

            this.name = StringHelper.safeString(contact.Name);
            this.businessType = StringHelper.safeString(contact.Account.Segment_Name__r.Name);
            this.role = StringHelper.safeString(contact.Job_Role__c);
            this.email = StringHelper.safeString(contact.Email);
            this.phoneNumber = StringHelper.safeString(contact.Phone);
            this.mainContact = StringHelper.safeString(contact.Owner.Name);
            this.companyAddress = StringHelper.constructAddress(contact.Account.BillingAddress);
            this.accountStatus = StringHelper.safeString(contact.Account.RC_Account_Status__c);
            this.brand = StringHelper.safeString(contact.Account_Brand__c);
            this.packageName = StringHelper.safeString(contact.Package_Name__c);
            this.implementationStatus = StringHelper.safeString(contact.Implementation_Status__c);
            this.packageStatus = officePackageToProcess != null ? StringHelper.safeString(officePackageToProcess.Package_Status__c) : null;
            this.videoProvider = officePackageToProcess != null ? StringHelper.safeString(officePackageToProcess.VideoProvider__c) : null;
            this.accountCreatedDate = StringHelper.safeString(contact.Account.CreatedDate);
            this.inContact_Cluster = StringHelper.safeString(contact.Account.inContact_Cluster__c);
            this.Account_POD = officePackageToProcess != null ? StringHelper.safeString(officePackageToProcess.Account_POD__c) : null;
            this.enterpriseSupportStartDate = StringHelper.safeString(contact.Account.enterprise_Support_Start_Date__c);
            this.enterpriseSupportEndDate = StringHelper.safeString(contact.Account.enterprise_Support_End_Date__c);
            this.technicalAccountManager = StringHelper.safeString(contact.Account.technical_Account_Manager__c);
            this.proServProjects = buildProServProjects(proServProjects);
            this.UCESServiceLevel = StringHelper.safeString(CaseHelper.getTranslatedLabel(translatedLabelByValue, contact.Account.UC_ES_Service_Level__c));
            this.is_partner_sold_ES = ContactHelper.isPartnerSoldEnterpriseSupport(contact);
            this.enterpriseSupportDesignatedContact = BooleanHelper.toBoolean(contact.ES_Designated_Contact__c);
        }

        //PBC-31596
        private List<AEMProServProject> buildProServProjects(List<ProServ_Project__c> proServProjects) {
            List<AEMProServProject> wrappedProjects = new List<AEMProServProject>();

            if (proServProjects == null || proServProjects.isEmpty()) {
                return wrappedProjects;
            }

            for (ProServ_Project__c proServProject : proServProjects) {
                wrappedProjects.add(new AEMProServProject(proServProject));
            }

            return wrappedProjects;
        }

        public User getUserToFillCSMData(Contact contact){
            User csmUser = null;
            if (String.isNotBlank(contact.Account.CSM__c)) {
                csmUser = contact.account.CSM__r;
            }
            return csmUser;
        }
    }

    public class AEMWrapper {
        public List<AEMCases> cases = new List<AEMCases>();
        public AEMBilling billing;
        public AEMContactInfo contactInfo;
        public Boolean isAdmin;
        public Integer totalUserCases;
        public Integer totalAccCases;

        public AEMWrapper() {}

        public void populateCaseDetails(List<Case> cases, String lang) {

            Map<String, List<Case>> casesByRecordTypeName = new Map<String, List<Case>>();

            for (Case cs : cases) {
                if (!casesByRecordTypeName.containsKey(cs.recordType.Name)) {
                    casesByRecordTypeName.put(cs.recordType.Name, new Case[]{});
                }
                casesByRecordTypeName.get(cs.recordType.Name).add(cs);
            }

            for (String recordTypeName : casesByRecordTypeName.keySet()) {
                Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(
                    'Case',
                    recordTypeName,
                    lang,
                    'Status',
                    false
                );

                for (Case cs : casesByRecordTypeName.get(recordTypeName)) {
                    this.cases.add(new AEMCases(
                        cs.Id,
                        cs.caseNumber,
                        cs.subject,
                        CaseHelper.getTranslatedLabel(translatedLabelByValue, cs.Status)
                    ));
                }
            }
        }
    }
}