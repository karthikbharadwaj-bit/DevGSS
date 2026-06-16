public inherited sharing class SCWrappers {

    public static final String GDPR_DEFAULT_SEVERITY = 'Level 4 - Medium';
    public static final String RT_DEVELOPER_NAME_SUPPORT_BILLING = 'Support_Billing';
    public static final String LINE_BREAK = '\n';
    public static final Decimal BODYLENGTH_TO_MB_RATIO = Decimal.valueOf(1)/(1024 * 1024);
    public static final String API_ONLY_PROFILE = 'API Only';
    public static final String DESCRIPTION_LINES = '====================';
    public static final String VIEW_DESC = 'View: ';
    public static final String CHANGE_DESC = 'Change: ';
    public static final String DOWNLOAD_DESC = 'Download: ';
    public static final String DELETE_DESC = 'Delete: ';
    public static final String ANALYTICS_DESC = 'Retain Analytics Data: ';
    public static final String GLIP_DESC = 'Retain Glip Messages: ';
    public static final String NAME_DESC = 'Name of user requiring privacy action: ';
    public static final String EMAIL_DESC = 'Email of user requiring privacy action: ';
    public static final String RCPHONE_DESC = 'RC Phone Number (if applicable) of the user requiring privacy action: ';
    public static final String RCPHONE_DESC_REGEX = 'RC Phone Number \\(if applicable\\) of the user requiring privacy action: ';
    public static final String EU_DESC = 'Is this user a Citizen or legal resident within the EU (including UK): ';
    public static final String EU_DESC_REGEX = 'Is this user a Citizen or legal resident within the EU \\(including UK\\): ';
    public static final String EU_COMMENTS = 'Comments:';

    public static final Set<String> CLOSED_STATUSES = new Set<String>{
        'duplicate',
        'invalid',
        'cancelled',
        'closed',
        'closed - endorsed',
        'closed - no contact',
        'closed - no issue',
        'closed - no response'
    };

    public class ArticleSearchRequest {

        public String titlePart;
        public String langCode;
    }

    public class Article {

        @AuraEnabled
        public String id;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public String summary;
        @AuraEnabled
        public String LastPublishedDate;

        public Article(String articleId, String title, String url, String summary, String lastModifiedDate) {

            this.id = articleId;
            this.title = title;
            this.url = url;
            this.summary = summary;
            this.LastPublishedDate = lastModifiedDate;
        }
    }

    public virtual class BaseOption {
        public String value;
        public String label;
        public BaseOption(){}
        public BaseOption(String value, String label){
            this.value = value;
            this.label = label;
        }
    }

    public class AreaOption extends BaseOption {
        @AuraEnabled
        public List<AreaOption> subLevelOptions = new List<AreaOption>();

        public AreaOption(Schema.PicklistEntry pe) {
            super(pe.value, pe.label);
        }

        public void addSubOption(AreaOption ao) {
            subLevelOptions.add(ao);
        }

        public void addSubOption(Schema.PicklistEntry pe) {
            subLevelOptions.add(new AreaOption(pe));
        }
    }

    public class ApiAreaOption extends BaseOption {
        public List<ApiSubLevelAreaOption> subLevelOptions = new List<ApiSubLevelAreaOption>();
        public List<GdprOption> gdprOptions;
        public List<String> severityOptions;
        public List<BaseOption> severityOptionsWithTranslations;
        public List<BaseOption> paymentPlanOptions;
        public List<ApiSubLevelAreaOption> roleOptions = new List<ApiSubLevelAreaOption>();
        public String message;
        public boolean supportsSubjectAndDescription = false;

        public ApiAreaOption(PicklistAPIValues p) {
            super(p.value, p.label);
        }

        public void addSubOption(ApiSubLevelAreaOption ao) {
            subLevelOptions.add(ao);
        }

        public void addSubOption(PicklistAPIValues p) {
            subLevelOptions.add(new ApiSubLevelAreaOption(p));
        }
    }

    public class ApiSubLevelAreaOption extends BaseOption {
        public List<ApiSubLevelAreaOption> subLevelOptions = new List<ApiSubLevelAreaOption>();

        public ApiSubLevelAreaOption(PicklistAPIValues p) {
            super(p.value, p.label);
        }

        public ApiSubLevelAreaOption(String value, String label) {
            super(value, label);
        }

        public void addSubOption(String value, String label) {
            subLevelOptions.add(new ApiSubLevelAreaOption(value, label));
        }
    }

    public class GdprOption {

        public String fieldType;
        public String label;

        public GdprOption(String fieldType, String label) {
            this.fieldType = fieldType;
            this.label = label;
        }
    }

    public class PicklistAPIOptions {
        public Map<String,Integer> controllerValues;
        public String defaultValue;
        public String eTag;
        public String url;
        public List<PicklistAPIValues> values;
    }

    public class PicklistAPIValues extends BaseOption {
        public String attributes;
        public List<Integer> validFor;
    }

    public class CreateCaseRequest {

        public String caseInfo;
        public String contactId;
        public Boolean isGdpr;

        public void populateCaseContactInfo(Case caseObj) {

            List<Contact> contacts = (List<Contact>) new ContactSelector()
                .selectContactById(new List<String>{this.contactId})
                .executeQuery();
            if (contacts.isEmpty()) {
                AquivaHelper.throwAquivaException('Contact not found');
            }
            caseObj.ContactId = this.contactId;
            caseObj.AccountId = contacts[0].AccountId;
        }
    }

    public class CaseRequestAPI {

        //CaseInfo parameters
        public String subject;
        public String description;
        public String selectedProduct;
        public String selectedProduct2;
        public String selectedProduct3;
        public String severityLevel;
        public String alternateEmail;
        public String callbackPhone;
        public Decimal extensionNumber;
        public String timezone;
        public String communicationPreference;
        public String site;
        public String agentFullName;
        public String agentId;

        //GDPR parameters
        public String firstName;
        public String lastName;
        public String gdprEmail;
        public String rcPhone;
        public Boolean euCitizen;
        public Boolean viewRequest;
        public Boolean changeRequest;
        public Boolean downloadRequest;
        public Boolean deleteRequest;
        public Boolean retainAnalytics;
        public Boolean retainGlip;
        public String comments;
        public Boolean isGdpr { get { return (this.isGdpr != null && this.isGdpr);}}

        // RC Events parameters
        public String paymentPlan;
        public String role;
        public String myEventIs;


        //User parameters
        public String uid;
        public String userEmail;

        private String boolToStr(Boolean bool) {
            return bool == true ? 'Yes' : 'No';
        }

        private String noneIfEmpty(String str) {
            return String.isNotBlank(str) ? str : 'None';
        }

        public virtual String getSubject() {
            if (this.isGdpr) {
                return String.format(
                    'DSR Request: "{0}"',
                    new List<String>{
                        (
                            (String.isNotBlank(this.firstName) ? this.firstName + ' ' : '')
                            + (String.isNotBlank(this.lastName) ? this.lastName : '')
                        ).trim()
                    }
                    );
            } else {
                return this.subject;
            }
        }

        public virtual String getDescription() {
            if (this.isGdpr) {
                return LINE_BREAK + LINE_BREAK + '====================' + LINE_BREAK + LINE_BREAK +
                'View: ' + boolToStr(this.viewRequest) + LINE_BREAK +
                'Change: ' + boolToStr(this.changeRequest) + LINE_BREAK +
                'Download: ' + boolToStr(this.downloadRequest) + LINE_BREAK +
                'Delete: ' + boolToStr(this.deleteRequest) + LINE_BREAK +
                (this.deleteRequest == true ?
                    'Retain Analytics Data: ' + BoolToStr(this.retainAnalytics) + LINE_BREAK +
                        'Retain Glip Messages: ' + BoolToStr(this.retainGlip) + LINE_BREAK
                    : '') +
                'Name of user requiring privacy action: ' + this.firstName + ' ' + this.lastName + LINE_BREAK +
                'Email of user requiring privacy action: ' + noneIfEmpty(this.gdprEmail) +  LINE_BREAK +
                'RC Phone Number (if applicable) of the user requiring privacy action: ' + noneIfEmpty(this.rcPhone) + LINE_BREAK +
                'Is this user a Citizen or legal resident within the EU (including UK): ' + boolToStr(this.euCitizen) + LINE_BREAK +
                (this.comments != null ? 'Comments: ' + this.comments : '');
            } else {
                return this.description;
            }
        }

        public virtual String getSeverity() {
            if (this.isGdpr) {
                return GDPR_DEFAULT_SEVERITY;
            } else {
                return this.severityLevel;
            }
        }

        public virtual String getRecordTypeId() {
            if (this.isGdpr) {
                return CaseHelper.RT_ID_GDPR_REQUEST;
            } else if (this.selectedProduct == HelperCaseDispatch.PRODUCT_ASSISTANCE_BILLING) {
               	if (HelperCaseDispatch.BILLING_CATEGORY_VALUES.contains(this.selectedProduct2)) {
                	return CaseHelper.RT_ID_SALES_CUST_FORM;
                } else if (this.selectedProduct2.equalsIgnoreCase('Monthly Credit Limit Increase')) {
                    return CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
                }
                return CaseHelper.RT_ID_SUPPORT_BILLING;
            } else {
                return CaseHelper.RT_ID_SUPPORT_CASE;
            }
        }

        public void populateCaseInfo(Case caseObj) {

            caseObj.RecordTypeId = getRecordTypeId();
            caseObj.Origin = 'Web';
            caseObj.Product_Assistance__c = this.selectedProduct;
            caseObj.Case_Category__c = this.selectedProduct2;
            caseObj.Product_Assistance_Lvl2__c = this.selectedProduct2;
            caseObj.Product_Assistance_Lvl3__c = this.selectedProduct3;
            caseObj.Alternate_Email__c = this.alternateEmail;
            caseObj.CallbackNumber__c = this.callbackPhone;
            caseObj.Extension_number__c= this.extensionNumber;
            caseObj.Timezone__c = this.timezone;
            caseObj.Case_Severity__c = getSeverity();
            caseObj.Subject = getSubject();
            caseObj.Description = getDescription();
            caseObj.Communication_Preference__c = this.communicationPreference;
            caseObj.Site__c = this.site;
            caseObj.Hire_Name__c = this.agentFullName;
            caseObj.Partner_Case_Number__c = this.agentId;
            caseObj.Payment_Plan__c = this.paymentPlan;
            caseObj.I_use_RingCentral_Events_as__c = this.role;
            caseObj.Event_Organizer_Type__c = this.myEventIs;

            if (caseObj.Subject.length() >= SCAPICaseService.MAXIMUM_SUBJECT_SIZE) {
                AquivaHelper.throwAquivaException(
                    'Subject can\'t be longer than ' + SCAPICaseService.MAXIMUM_SUBJECT_SIZE + ' characters'
                );
            }
            if (caseObj.Description != null && caseObj.Description.length() >= SCAPICaseService.MAXIMUM_DESCRIPTION_SIZE) {
                AquivaHelper.throwAquivaException(
                    'Description can\'t be longer than ' + SCAPICaseService.MAXIMUM_DESCRIPTION_SIZE + ' characters'
                );
            }
            try {
                List<Entitlement> entitlementObj = EntitlementHelper.getEntitlement(caseObj.AccountId);
                caseObj.EntitlementId = (entitlementObj == null || entitlementObj.size() == 0)
                    ? null
                    : entitlementObj.get(0).Id;
            } catch(Exception e) {}
        }
    }

    public virtual class CaseInfo {

        public String subject;
        public String description;
        public String selectedProduct;
        public String selectedProduct2;
        public String selectedProduct3;
        public String severityLevel;
        public String alternateEmail;
        public String callbackPhone;
        public String timezone;

        public virtual String getSubject() {
            return this.subject;
        }

        public virtual String getDescription() {
            return this.description;
        }

        public virtual String getSeverity() {
            return this.severityLevel;
        }

        public virtual String getRecordTypeId() {
            return OpportunityHelper.getOppRecordTypeMap('Support-Case');
        }

        public void populateCaseInfo(Case caseObj) {

            caseObj.RecordTypeId = getRecordTypeId();
            caseObj.Origin = 'Web';
            caseObj.Product_Assistance__c = this.selectedProduct;
            caseObj.Product_Assistance_Lvl2__c = this.selectedProduct2;
            caseObj.Product_Assistance_Lvl3__c = this.selectedProduct3;
            caseObj.Alternate_Email__c = this.alternateEmail;
            caseObj.CallbackNumber__c = this.callbackPhone;
            caseObj.Timezone__c = this.timezone;
            caseObj.Case_Severity__c = getSeverity();
            caseObj.Subject = getSubject();
            caseObj.Description = getDescription();
            if (caseObj.Subject.length() >= SCCaseService.MAXIMUM_SUBJECT_SIZE) {
                AquivaHelper.throwAquivaException(
                    'Subject can\'t be longer than ' + SCCaseService.MAXIMUM_SUBJECT_SIZE + ' characters'
                );
            }
            if (caseObj.Description != null && caseObj.Description.length() >= SCCaseService.MAXIMUM_DESCRIPTION_SIZE) {
                AquivaHelper.throwAquivaException(
                    'Description can\'t be longer than ' + SCCaseService.MAXIMUM_DESCRIPTION_SIZE + ' characters'
                );
            }
            try {
                List<Entitlement> entitlementObj = EntitlementHelper.getEntitlement(SCUserService.currentUser.Contact.AccountId);
                caseObj.EntitlementId = (entitlementObj == null || entitlementObj.size() == 0)
                    ? null
                    : entitlementObj.get(0).Id;
            } catch(Exception e) {}
        }

        public CaseInfo(Case caseObj) {

            this.subject = caseObj.Subject;
            this.description = caseObj.Description;
            this.selectedProduct = caseObj?.Product_Assistance__c;
            this.selectedProduct2 = caseObj?.Product_Assistance_Lvl2__c;
            this.selectedProduct3 = caseObj?.Product_Assistance_Lvl3__c;
            this.alternateEmail = caseObj.Alternate_Email__c;
            this.callbackPhone = caseObj.CallbackNumber__c;
            this.timezone = caseObj.Timezone__c;
            this.severityLevel = caseObj.Case_Severity__c;
        }

    }

    public class GdprInfo extends CaseInfo {

        public String firstName;
        public String lastName;
        public String email;
        public String rcPhone;
        public Boolean euCitizen;
        public Boolean viewRequest;
        public Boolean changeRequest;
        public Boolean downloadRequest;
        public Boolean deleteRequest;
        public Boolean retainAnalytics;
        public Boolean retainGlip;
        public String comments;

        public GdprInfo(Case caseObj) {

            super(caseObj);
        }

        private String boolToStr(Boolean bool) {
            return bool == true ? 'Yes' : 'No';
        }

        private String noneIfEmpty(String str) {
            return String.isNotBlank(str) ? str : 'None';
        }

        public override String getSubject() {
            return String.format(
                'DSR Request: "{0}"',
                new List<String>{
                    (
                        (String.isNotBlank(this.firstName) ? this.firstName + ' ' : '')
                        + (String.isNotBlank(this.lastName) ? this.lastName : '')
                    ).trim()
                }
            );
        }

        public override String getDescription() {
            return LINE_BREAK + LINE_BREAK + '====================' + LINE_BREAK + LINE_BREAK +
                'View: ' + boolToStr(this.viewRequest) + LINE_BREAK +
                'Change: ' + boolToStr(this.changeRequest) + LINE_BREAK +
                'Download: ' + boolToStr(this.downloadRequest) + LINE_BREAK +
                'Delete: ' + boolToStr(this.deleteRequest) + LINE_BREAK +
                (this.deleteRequest == true ?
                    'Retain Analytics Data: ' + BoolToStr(this.retainAnalytics) + LINE_BREAK +
                        'Retain Glip Messages: ' + BoolToStr(this.retainGlip) + LINE_BREAK
                    : '') +
                'Name of user requiring privacy action: ' + this.firstName + ' ' + this.lastName + LINE_BREAK +
                'Email of user requiring privacy action: ' + noneIfEmpty(this.email) +  LINE_BREAK +
                'RC Phone Number (if applicable) of the user requiring privacy action: ' + noneIfEmpty(this.rcPhone) + LINE_BREAK +
                'Is this user a Citizen or legal resident within the EU (including UK): ' + boolToStr(this.euCitizen) + LINE_BREAK +
                (this.comments != null ? 'Comments: ' + this.comments : '');
        }

        public override String getSeverity() {
            return GDPR_DEFAULT_SEVERITY;
        }

        public override String getRecordTypeId() {
            return OpportunityHelper.getOppRecordTypeMap('DSR Request');
        }
    }

    public class ContactInfo {

        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String extension;


        public ContactInfo(User user) {

            this.contactId = user.ContactId;
            this.firstName = user.Contact.FirstName;
            this.lastName = user.Contact.LastName;
            this.email = user.Contact.Email;
            this.phone = user.Contact.Phone;
            if (user.Contact.Phone_Ext__c != null && user.Contact.Phone_Ext__c != 0) {
                this.extension = String.valueOf(user.Contact.Phone_Ext__c);
            } else {
                this.extension = '';
            }
        }

        public ContactInfo(Contact contact) {

            this.contactId = contact.Id;
            this.firstName = contact.FirstName;
            this.lastName = contact.LastName;
            this.email = contact.Email;
            this.phone = contact.Phone;
            if (contact.Phone_Ext__c != null && contact.Phone_Ext__c != 0) {
                this.extension = String.valueOf(contact.Phone_Ext__c);
            } else {
                this.extension = '';
            }
        }

        public String upsertContact() {

            Contact contactObj = null;

            String currentPhoneExt;
            if (SCUserService.currentUser.Contact.Phone_Ext__c != null && SCUserService.currentUser.Contact.Phone_Ext__c != 0) {
                currentPhoneExt = String.valueOf(SCUserService.currentUser.Contact.Phone_Ext__c);
            } else {
                currentPhoneExt = '';
            }
            if (SCUserService.currentUser.Contact.Email != this.email
                    || SCUserService.currentUser.Contact.Phone != this.phone
                    || SCUserService.currentUser.Contact.FirstName != this.firstName
                    || SCUserService.currentUser.Contact.LastName != this.lastName
                    || currentPhoneExt != this.extension) {

                String accountId = SCUserService.currentUser.Contact.AccountId;
                if(SCUserService.currentUser.Contact.Email == this.email) {
                    contactObj = (Contact) new ContactSelector()
                        .selectContactById(new List<String>{SCUserService.currentUser.ContactId})
                        .executeQuery()
                        .get(0);
                }

                if(contactObj != null) {
                    contactObj.Email = this.email;
                    contactObj.Phone = this.phone;
                    if (this.extension != null && this.extension != '') {
                        contactObj.Phone_Ext__c = Double.valueOf(this.extension);
                    } else {
                        contactObj.Phone_Ext__c = Double.valueOf(0);
                    }
                    contactObj.FirstName = this.firstName;
                    contactObj.LastName = this.lastName;
                    update contactObj;
                } else {
                    contactObj = new Contact();
                    contactObj.FirstName = this.firstName;
                    contactObj.LastName = this.lastName;
                    contactObj.Email = this.email;
                    contactObj.AccountId = accountId;
                    contactObj.Phone = this.phone;

                    if (this.extension != null && this.extension != '') {
                        contactObj.Phone_Ext__c = Double.valueOf(this.extension);
                    } else {
                        contactObj.Phone_Ext__c = Double.valueOf(0);
                    }
                    insert contactObj;
                }
            }
            return (contactObj == null ? SCUserService.currentUser.ContactId : contactObj.Id);
        }
    }

    public class CaseListView {
        @AuraEnabled
        public List<CaseDetail> caseDetails;
        @AuraEnabled
        public Integer totalCases;

        public CaseListView(List<SCWrappers.CaseDetail> cases, Integer totalCases) {
            this.totalCases = totalCases;
            this.caseDetails = cases;
        }
    }

    public class CaseSearchRequest {
        public String searchPart;
        public String orderByField;
        public String listView;
        public String searchByField;
        public Boolean descending;
        public Integer searchLimit;
        public Integer offset;
        public Boolean count;
    }

    public class ContactInfoAPIRequest {
        public String email;
        public String uid;
    }

    public class ContactInfoAPIPostRequest {
        public String uid;
        public String email;
        public String firstName;
        public String lastName;
        public String contactEmail;
        public String phone;
        public String extension;

        public String upsertContact(Contact contact) {

            Contact contactObj = null;

            String currentPhoneExt;
            if (contact.Phone_Ext__c != null && contact.Phone_Ext__c != 0) {
                currentPhoneExt = String.valueOf(contact.Phone_Ext__c);
            } else {
                currentPhoneExt = '';
            }
            if (contact.Email != this.contactEmail
                    || contact.Phone != this.phone
                    || contact.FirstName != this.firstName
                    || contact.LastName != this.lastName
                    || currentPhoneExt != this.extension) {

                String accountId = contact.AccountId;
                if(contact.Email == this.contactEmail) {
                    contactObj = (Contact) new ContactSelector()
                        .selectContactById(new List<String>{contact.Id})
                        .executeQuery()
                        .get(0);
                }

                if(contactObj != null) {
                    contactObj.Email = this.contactEmail;
                    contactObj.Phone = this.phone;
                    if (this.extension != null && this.extension != '') {
                        contactObj.Phone_Ext__c = Double.valueOf(this.extension);
                    } else {
                        contactObj.Phone_Ext__c = Double.valueOf(0);
                    }
                    contactObj.FirstName = this.firstName;
                    contactObj.LastName = this.lastName;
                    update contactObj;
                } else {
                    contactObj = new Contact();
                    contactObj.FirstName = this.firstName;
                    contactObj.LastName = this.lastName;
                    contactObj.Email = this.contactEmail;
                    contactObj.AccountId = accountId;
                    contactObj.Phone = this.phone;

                    if (this.extension != null && this.extension != '') {
                        contactObj.Phone_Ext__c = Double.valueOf(this.extension);
                    } else {
                        contactObj.Phone_Ext__c = Double.valueOf(0);
                    }
                    insert contactObj;
                }
            }
            return (contactObj == null ? contact.Id : contactObj.Id);
        }
    }

    public class CasePostComment {
        public String caseId;
        public String email;
        public String uid;
        public String comment;
    }

    public class GetCaseListRequest {
        public String email;
        public String uid;
        public String subject;
        public String caseNumber;
        public String searchLimit;
        public String offset;
        public String contactName;
        public String sortBy;
        public String sortOrder;
        public String view;
        public String site;
        public String lang;
        public String statusFilter;
    }

    public class GetCaseDetailRequest {
        public String caseId;
        public String email;
        public String uid;
        public String lang;
    }

    public class CaseCommentAPI {
        public String email;
        public String uid;
        public String comment;
        public String createdByUser;
        public String createdByContact;
        public String authorName;

        public CaseCommentAPI(String comment) {
            this.comment = comment;
        }
    }

    public class CaseDetail {

        @AuraEnabled
        public String id;
        @AuraEnabled
        public Boolean isGdpr;
        @AuraEnabled
        public String creatorName;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String agentFullName;
        @AuraEnabled
        public String agentId;
        @AuraEnabled
        public String contactName;
        @AuraEnabled
        public String caseNumber;
        @AuraEnabled
        public String severityLevel;
        @AuraEnabled
        public String selectedProduct;
        @AuraEnabled
        public String selectedProduct2;
        @AuraEnabled
        public String selectedProduct3;
        @AuraEnabled
        public String createdDate;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public Integer fileSizeLimit;
        @AuraEnabled
        public Boolean isClosed;
        @AuraEnabled
        public String timezone;
        @AuraEnabled
        public String communicationPreference;
        @AuraEnabled
        public List<CommentWrapper> comments;
        @AuraEnabled
        public List<AttachmentWrapper> attachments;
        @AuraEnabled
        public String site;
        public Boolean isEscalatable;
        public Boolean isEscalated;
        public String escalateErrorMsg;
        public Boolean isReopenable;
        public String reopenErrorMsg;
        public List<String> functionValues;
        public Object descriptionGDPR;
        public String caseCategory;
        public String escalateTo;
        public String recordTypeName;

        public CaseDetail(Case caseObj) {
            this.id = caseObj.Id;
            this.caseNumber = caseObj.CaseNumber;
            this.subject = caseObj.Subject;
            this.createdDate = caseObj.CreatedDate.format('MM/dd/yyyy');
            this.status = caseObj.Status;
            this.contactName = caseObj.Contact.Id == null ? '' : caseObj.Contact.Name;
            this.site = caseObj.Site__c;
        }

        public CaseDetail(Case caseObj, Map<Id, User> commentators) {

            this.id = caseObj.Id;
            this.isGdpr = caseObj.RecordTypeId == CaseHelper.RT_ID_GDPR_REQUEST;
            this.contactName = caseObj.Contact.Id == null ? '' : caseObj.Contact.Name;
            this.creatorName = caseObj.RecordTypeId == CaseHelper.RT_ID_SUPPORT_CASE
                ? SCUserService.currentUser.Name
                : caseObj.Contact.Name;
            this.accountName = caseObj.Account.Name;
            this.caseNumber = caseObj.CaseNumber;
            this.severityLevel = caseObj.Case_Severity__c;
            this.selectedProduct = caseObj?.Product_Assistance__c;
            this.selectedProduct2 = caseObj?.Product_Assistance_Lvl2__c;
            this.selectedProduct3 = caseObj?.Product_Assistance_Lvl3__c;
            this.createdDate = caseObj.CreatedDate.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles');
            this.status = caseObj.Status;
            this.isClosed = CLOSED_STATUSES.contains(caseObj.Status.toLowerCase());
            this.subject = caseObj.Subject;
            this.description = caseObj.Description?.escapeHtml4();
            this.comments = new List<CommentWrapper>();
            this.fileSizeLimit = caseObj.RecordTypeId == CaseHelper.RT_ID_SUPPORT_RC_APP ? 10 : 5;
            this.communicationPreference = caseObj.Communication_Preference__c;
            this.site = caseObj.Site__c;

            for (CaseComment comment : caseObj.CaseComments) {
                CommentWrapper newComment = new SCWrappers.CommentWrapper();
                User commentator = commentators.get(comment.CreatedById);
                if (commentator == null) {
                    newComment.authorName = 'Support Agent';
                    newComment.avatarUrl = 'https://rc--c.na97.content.force.com/profilephoto/005/F';
                } else {
                    if (commentator.Contact == null) {
                        newComment.authorName = commentator.Name;
                        newComment.avatarUrl = commentator.FullPhotoUrl;
                    } else {
                        newComment.authorName = commentator.Contact.Name;
                        newComment.avatarUrl = commentator.Contact.Account.CSM__r.FullPhotoUrl == null
                            ? commentator.FullPhotoUrl
                            : commentator.Contact.Account.CSM__r.FullPhotoUrl;
                    }
                }
                newComment.id = comment.Id;
                newComment.body = comment.CommentBody;
                newComment.isCaseCreator = comment.CreatedById == caseObj.CreatedById;
                newComment.isCurrentUser = comment.CreatedById == UserInfo.getUserId();
                newComment.dateTimeStamp = comment.CreatedDate.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles');
                this.comments.add(newComment);
            }

            this.attachments = new List<AttachmentWrapper>();
            for (Attachment att : caseObj.Attachments) {
                this.attachments.add(new SCWrappers.AttachmentWrapper(att));
            }
        }

        public CaseDetail(Case caseObj, Map<Id, User> commentators, Contact contact) {
            this.id = caseObj.Id;
            this.isGdpr = caseObj.RecordTypeId == CaseHelper.RT_ID_GDPR_REQUEST;
            this.contactName = caseObj.Contact.Id == null ? '' : caseObj.Contact.Name;
            this.creatorName = caseObj.Contact.Name;
            this.accountName = caseObj.Account.Name;
            this.agentFullName = caseObj.Hire_Name__c;
            this.agentId = caseObj.Partner_Case_Number__c;
            this.caseNumber = caseObj.CaseNumber;
            this.timezone = caseObj.Timezone__c;
            this.severityLevel = caseObj.Case_Severity__c;
            this.selectedProduct = caseObj?.Product_Assistance__c;
            this.selectedProduct2 = caseObj.Product_Assistance_Lvl2__c;
            this.selectedProduct3 = caseObj.Product_Assistance_Lvl3__c;

            this.createdDate = caseObj.CreatedDate.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles');
            this.status = caseObj.Status;
            this.isClosed = CLOSED_STATUSES.contains(caseObj.Status.toLowerCase());
            this.subject = caseObj.Subject;
            this.description = caseObj.Description?.escapeHtml4();
            this.comments = new List<CommentWrapper>();
            this.fileSizeLimit = caseObj.RecordTypeId == CaseHelper.RT_ID_SUPPORT_RC_APP ? 10 : 5;
            this.communicationPreference = caseObj.Communication_Preference__c;
            this.site = caseObj.Site__c;
            this.isEscalated = caseObj.IsEscalated;
            this.isEscalatable = CaseHelper.isEscalatable(caseObj);
            this.recordTypeName = caseObj.RecordTypeName__c;

            if (caseObj.RecordTypeId == CaseHelper.RT_ID_SUPPORT_BILLING) {
                this.caseCategory = caseObj.Case_Category__c;
            }

            if (caseObj.recordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM) {
                this.caseCategory = caseObj.Case_Category__c;
                this.escalateTo = caseObj.Support_Escalate_To__c;
            }

            if (!this.isEscalatable) {
                this.escalateErrorMsg = CaseHelper.getEscalateErrorMessage(caseObj);
            }
            this.isReopenable = CaseHelper.isReopenable(caseObj);
            if (!this.isReopenable) {
                this.reopenErrorMsg = CaseHelper.getReopenErrorMessage(caseObj);
            }
            this.functionValues = CaseHelper.getFunctionValues();

            if (commentators != null && !commentators.isEmpty()) {

                Set<Id> commentIds = new Set<Id>();
                Map<Id, User> users = new Map<Id, User>();
                for (CaseComment comment : caseObj.CaseComments) {
                    commentIds.add(comment.Id);
                    users.put(comment.CreatedById, null);
                }

                List<CaseComment> caseComments = (List<CaseComment>) new CaseCommentSelector()
                                                .selectCaseCommentsByIdForAPI(new List<Object>{commentIds})
                                                .executeQuery();

                users.putAll(new Map<Id, User>((List<User>) new UserSelector()
                                                .selectUsersByIdWithContactInfoForAPI(new List<Object>{users.keySet()})
                                                .executeQuery()));

                for (CaseComment comment : caseComments) {
                    User createdByUser = users.get(comment.CreatedById);
                    CommentWrapper newComment = new SCWrappers.CommentWrapper();
                    User commentator = commentators.get(comment.CreatedById);
                    if (commentator == null) {
                        newComment.authorName = 'Support Agent';
                    } else {
                        if (createdByUser.Profile.Name.equalsIgnoreCase(API_ONLY_PROFILE)) {
                            newComment.authorName = this.contactName;
                            newComment.avatarUrl = null;
                        } else {
                            if (commentator.Contact == null) {
                                newComment.authorName = commentator.Name;
                                newComment.avatarUrl = null;
                            } else {
                                newComment.authorName = commentator.Contact.Name;
                                newComment.avatarUrl = null;
                            }
                        }
                        newComment.avatarUrl = null;
                    }
                    newComment.id = comment.Id;

                    try{
                        if (SCApiService.isJsonComment(comment.CommentBody)) {
                            CaseCommentAPI commentWrapper = (CaseCommentAPI) JSON.deserialize(
                                                                    comment.CommentBody, CaseCommentAPI.class);
                            newComment.body = commentWrapper.comment;
                            newComment.isCaseCreator = commentWrapper.createdByContact == caseObj.ContactId;
                            newComment.isCurrentUser = commentWrapper.createdByContact == contact.Id;
                        } else if(SCApiService.isApiComment(comment.commentBody)) {
                            CaseCommentAPI commentWrapper = new CaseCommentAPI(
                                comment.commentBody.split(SCApiService.COMMENT_KEY)[1].split('\n'+SCApiService.UID_KEY)[0]
                            );
                            String createdByContactId = comment.commentBody.split(SCApiService.CREATED_BY_CONTACT_KEY)[1].left(18);
                            newComment.isCaseCreator = createdByContactId == caseObj.ContactId;
                            newComment.isCurrentUser = createdByContactId == contact.Id;
                            newComment.body = commentWrapper.comment;
                        } else {
                            newComment.body = comment.CommentBody;

                            if (createdByUser != null){
                                if (createdByUser.Profile.Name.equalsIgnoreCase(API_ONLY_PROFILE)) {
                                    newComment.isCaseCreator = false;
                                    newComment.isCurrentUser = false;
                                } else {
                                    newComment.isCaseCreator = createdByUser.ContactId == caseObj.ContactId;
                                    newComment.isCurrentUser = createdByUser.ContactId == contact.Id;
                                }
                            } else {
                                newComment.isCaseCreator = false;
                                newComment.isCurrentUser = false;
                            }
                        }
                    } catch(Exception e) {
                            newComment.body = comment.CommentBody;
                    }

                    newComment.dateTimeStamp = comment.CreatedDate.format('h:mm a z, MM/dd/yyyy', 'America/Los_Angeles');
                    this.comments.add(newComment);
                }
            }

            this.attachments = new List<AttachmentWrapper>();
            for (Attachment att : caseObj.Attachments) {
                this.attachments.add(new SCWrappers.AttachmentWrapper(att));
            }
        }

        public void formatDescriptionGDPR() {

            String originalDesc = (String) this.description;
            Map<String,String> descriptionMap = new Map<String,String>();

            try {
                String[] splitDesc = originalDesc.split(VIEW_DESC);
                originalDesc = splitDesc[1];

                originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, CHANGE_DESC, 'view');

                originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, DOWNLOAD_DESC, 'change');

                originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, DELETE_DESC, 'download');

                if (originalDesc.contains(ANALYTICS_DESC)) {
                    originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, ANALYTICS_DESC, 'delete');
                    originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, GLIP_DESC, 'retainAnalytics');
                    originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, NAME_DESC, 'retainMessage');
                } else {
                    originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, NAME_DESC, 'delete');
                }

                String[] emailDesc = originalDesc.split(EMAIL_DESC);
                String[] fullName = emailDesc[0].split(' ');
                descriptionMap.put('firstName', fullName[0]);
                descriptionMap.put('lastName', fullName.size() > 1 ? fullName[1].replaceAll('\r\n|\n|\r','') : '');
                originalDesc = emailDesc[1];

                originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, RCPHONE_DESC_REGEX, 'gdprEmail');

                originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, EU_DESC_REGEX, 'rcPhone');

                if (originalDesc.contains(EU_COMMENTS)) {
                    originalDesc = addKeyToDescriptionGDPR(descriptionMap, originalDesc, EU_COMMENTS, 'euCitizen').trim();
                    descriptionMap.put('comments', String.isBlank(originalDesc) ? 'None' : originalDesc);
                } else {
                    descriptionMap.put('euCitizen', originalDesc.replaceAll('\r\n|\n|\r',''));
                    descriptionMap.put('comments', 'None');
                }

                this.descriptionGDPR = descriptionMap;
            } catch(Exception e) {
                this.descriptionGDPR = null;
            }
        }

        public void translateValues(String lang) {
            String fields = 'Timezone__c,Status,Case_Severity__c,Communication_Preference__c,Product_Assistance__c,Product_Assistance_Lvl2__c';

            String recordTypeName = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(this.recordTypeName).getName();

            Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(
                'Case',
                recordTypeName,
                lang,
                fields,
                true
            );

            this.timezone = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.timezone);
            this.status = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.status);
            this.severityLevel = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.severityLevel);
            this.communicationPreference = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.communicationPreference);
            this.selectedProduct = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.selectedProduct);
            this.selectedProduct2 = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.selectedProduct2);

            if (this.recordTypeName == RT_DEVELOPER_NAME_SUPPORT_BILLING) {
                this.caseCategory = this.selectedProduct2;
            }

            String[] metadataFields = new String[]{'reopenErrorMsg','functionValues','escalateErrorMsg'};

            translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(metadataFields, lang);

            this.reopenErrorMsg = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.reopenErrorMsg);
            this.escalateErrorMsg = CaseHelper.getTranslatedLabel(translatedLabelByValue, this.escalateErrorMsg);

            List<String> translatedFunctionValues = new List<String>();

            for (String functionValue : this.functionValues) {
                translatedFunctionValues.add(CaseHelper.getTranslatedLabel(translatedLabelByValue, functionValue));
            }

            this.functionValues = translatedFunctionValues;
        }

        private String addKeyToDescriptionGDPR(
            Map<String,String> descriptionGDPR,
            String description,
            String keyToSplit,
            String key
        ) {
            String[] splittedDescription = description.split(keyToSplit);
            descriptionGDPR.put(key, splittedDescription[0].replaceAll('\r\n|\n|\r',''));
            return splittedDescription.size() > 1 ? splittedDescription.get(1) : '';
        }
    }

    public class CommentWrapper {

        @AuraEnabled
        public String id;
        @AuraEnabled
        public String authorName;
        @AuraEnabled
        public String avatarUrl;
        @AuraEnabled
        public String body;
        @AuraEnabled
        public String dateTimeStamp;
        @AuraEnabled
        public Boolean isCaseCreator;
        @AuraEnabled
        public Boolean isCurrentUser;
    }

    public class AttachmentWrapper {

        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public Decimal fileSize;

        public AttachmentWrapper(Attachment att) {

            this.id = att.Id;
            this.name = att.Name;
            this.url = AttachmentService.getAttachmentDownloadLink(att.Id);
            this.fileSize = att.BodyLength;
        }
    }
}