public class KnowledgeArticleTriggerHelper {

    public static Boolean allowReview = false;
    public static Boolean allowCreation = false;
    public static String baseURL = System.Url.getOrgDomainUrl().toExternalForm() + '/';

    public static final String ERROR_CHANNELS_SELECTED =
        'You can\'t share article by external channels when article is internal or draft';
    public static final String ERROR_CHANNELS_NOT_SELECTED =
        'You must choose at least one external channel when making article external';
    public static final String ERROR_CHECKOUT_REJECTED_NO_ACCESS =
        'Only Knowledge Domain Expert can restore articles from archive';
    public static final String ERROR_MANUAL_REVIEW =
        'To publish/reject "Published As Draft" article, use the "Publish Internally" and "Reject" buttons '
            + 'on the Article View page';
    public static final String ERROR_MANUAL_CREATION = 'Only KCS Coach and higher roles can create articles from ' +
        'Article Management. Please use the "New Article" button on the Case view.';
    public static final String ERROR_SHARE_EXTERNAL_NO_ACCESS =
        'Only KCS Publisher and above can publish articles externally';
    public static final String ERROR_CHANGE_STATUS_FROM_COMPLIANCE =
        'Compliance-based articles can\'t be changed to any other status';
    public static final String ERROR_CHANGE_STATUS_TO_COMPLIANCE =
        'Existing articles can\'t change status to Compliance-based';
    public static final String ERROR_CHANGE_TO_REJECTED =
        'Status can\'t be changed to "Rejected" manually, either archive an article or use "Reject" button'
            + ' on the Article View page';

    public class KCSBeforeCreateHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            User currentUser = (User) new UserSelector()
                .selectManagerEmailByIds(new List<Object>{new List<String>{UserInfo.getUserId()}})
                .executeQuery()
                .get(0);
            DateTime presentTime = System.now();
            for (Knowledge__kav kav : (List<Knowledge__kav>) triggerRecords) {

                if (!KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.COACH)
                        && ((kav.KnowledgeArticleId == null && !allowCreation)
                            || kav.ValidationStatus == KnowledgeArticleService.STATUS_COMPLIANCE)) {
                    kav.addError(ERROR_MANUAL_CREATION);
                }
                if (kav.ValidationStatus == KnowledgeArticleService.STATUS_REJECTED) {
                    if (KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.EXPERT)) {
                        kav.ValidationStatus = KnowledgeArticleService.STATUS_INTERNAL;
                    } else {
                        kav.addError(ERROR_CHECKOUT_REJECTED_NO_ACCESS);
                    }
                }
                // AutoReview when skipping Draft phase
                if (kav.KnowledgeArticleId == null && 
                        (kav.ValidationStatus == KnowledgeArticleService.STATUS_INTERNAL
                            || kav.ValidationStatus == KnowledgeArticleService.STATUS_COMPLIANCE
                            || kav.ValidationStatus == KnowledgeArticleService.STATUS_EXTERNAL)) {
                    kav.RC_Knowledge_Article_ReviewDateTime__c = presentTime;
                }
                KnowledgeArticleTriggerHelper.validateChannels(kav);
                KnowledgeArticleTriggerHelper.ensureDraftPrefix(kav);

                /* initialize fields for workflow rules (for email notifications) */
                defineEmailKCSDETeam(kav);
                defineKnowledgeArticleURL(kav);
                if (kav.RC_Knowledge_Article_EmailOfArticleCre11__c == null) {
                    kav.RC_Knowledge_Article_EmailOfArticleCre11__c = currentUser.Manager.Email;
                }
            }
        }
    }
    /* if KnowledgeArticleURL was not defined because KnowledgeArticleId is null - define it in after trigger */
    public class KCSAfterCreateHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Knowledge__kav> kaList = (List<Knowledge__kav>) triggerRecords;
            List<Knowledge__kav> rcKAList = new KnowledgeArticleSelector()
                .selectArticlesByIdsWithNullKnowledgeArticleURL(new List<Object>{kaList})
                .executeQuery();
            
            for (Knowledge__kav kav : rcKAList) { 
                kav.RC_Knowledge_Article_Knowledge_Article10__c = baseURL + kav.KnowledgeArticleId;
            }
            
            if(!rcKAList.isEmpty()) {
                update rcKAList;
            }
        }
    }
    public class KCSBeforeUpdateHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Knowledge__kav> oldKAMap = (Map<Id, Knowledge__kav>) Trigger.oldMap;
            Set<Id> idUsersNeededToClarifyManagerEmail = new Set<Id>();
           
            for (Knowledge__kav kav : (List<Knowledge__kav>) triggerRecords) {

                if (!allowReview) {
                    if (kav.ValidationStatus == KnowledgeArticleService.STATUS_REJECTED) {
                        kav.addError(ERROR_CHANGE_TO_REJECTED);
                        break;
                    }
                    if (isChangedFieldFrom(
                                kav,
                                Knowledge__kav.ValidationStatus,
                                KnowledgeArticleService.STATUS_DRAFT)) {
                        kav.addError(ERROR_MANUAL_REVIEW);
                    }
                }
                if (isChangedFieldFrom(
                        kav,
                        Knowledge__kav.ValidationStatus,
                        KnowledgeArticleService.STATUS_COMPLIANCE)) {
                    kav.addError(ERROR_CHANGE_STATUS_FROM_COMPLIANCE);
                    break;
                }
                if (isChangedFieldTo(
                        kav,
                        Knowledge__kav.ValidationStatus,
                        KnowledgeArticleService.STATUS_COMPLIANCE)) {
                    kav.addError(ERROR_CHANGE_STATUS_TO_COMPLIANCE);
                    break;
                }
                if (isChangedFieldTo(
                            kav,
                            Knowledge__kav.ValidationStatus,
                            KnowledgeArticleService.STATUS_EXTERNAL)) {
                    if (!KnowledgeArticleService.isCurrentUserKCSRoleAtLeast(KnowledgeArticleService.KCSRole.PUBLISHER)) {
                        kav.addError(ERROR_SHARE_EXTERNAL_NO_ACCESS);
                    } else {
                        kav.RC_Knowledge_Article_DecisionMaker__c = UserInfo.getUserId();
                    }
                }

                KnowledgeArticleTriggerHelper.validateChannels(kav);
                KnowledgeArticleTriggerHelper.ensureDraftPrefix(kav);

                /* initialize fields for workflow rules (for email notifications) */
                defineEmailKCSDETeam(kav);
                defineKnowledgeArticleURL(kav);
                if (isChangedField(kav, Knowledge__kav.ValidationStatus)) {
                    idUsersNeededToClarifyManagerEmail.add(kav.CreatedById);
                }
                kav.RC_Knowledge_Article_Old_ValidationSta24__c = oldKAMap.get(kav.Id).ValidationStatus;
            }
            
            /* clarify manager email (for email notifications) */
            Map<Id, User> mapUserIdToUserWithManagerEmail = new Map<Id, User>(
                (List<User>) new UserSelector()
                    .selectManagerEmailByIds(new List<Object>{idUsersNeededToClarifyManagerEmail})
                    .executeQuery()
            );
            for (Knowledge__kav kav : (List<Knowledge__kav>) triggerRecords) {
                if (isChangedField(kav, Knowledge__kav.ValidationStatus) 
                        && mapUserIdToUserWithManagerEmail.get(kav.CreatedById) != null) {
                    kav.RC_Knowledge_Article_EmailOfArticleCre11__c = 
                        mapUserIdToUserWithManagerEmail.get(kav.CreatedById).Manager.Email;
                }
            }
        }
    }

    public static void defineKnowledgeArticleURL(Knowledge__kav kav) {
        if (kav.RC_Knowledge_Article_Knowledge_Article10__c == null && kav.KnowledgeArticleId != null) {
            kav.RC_Knowledge_Article_Knowledge_Article10__c = baseURL + kav.KnowledgeArticleId;
        }
    }
    
    public static void validateChannels(Knowledge__kav kav) {

        if ((kav.ValidationStatus == KnowledgeArticleService.STATUS_INTERNAL
                    || kav.ValidationStatus == KnowledgeArticleService.STATUS_COMPLIANCE
                    || kav.ValidationStatus == KnowledgeArticleService.STATUS_DRAFT)
                && (kav.IsVisibleInPkb || kav.IsVisibleInCsp || kav.IsVisibleInPrm)) {
            kav.addError(ERROR_CHANNELS_SELECTED);
        }
        if (kav.ValidationStatus == KnowledgeArticleService.STATUS_EXTERNAL
                && (!(kav.IsVisibleInPkb || kav.IsVisibleInCsp || kav.IsVisibleInPrm))) {
            kav.addError(ERROR_CHANNELS_NOT_SELECTED);
        }
    }

    public static void ensureDraftPrefix(Knowledge__kav kav) {

        if (kav.ValidationStatus == KnowledgeArticleService.STATUS_DRAFT
                && !kav.Title.startsWith(KnowledgeArticleService.DRAFT_PREFIX)) {
            kav.Title = KnowledgeArticleService.DRAFT_PREFIX + kav.Title;
        }
        if (kav.ValidationStatus != KnowledgeArticleService.STATUS_DRAFT
                && kav.Title.startsWith(KnowledgeArticleService.DRAFT_PREFIX)) {
            kav.Title = kav.Title.removeStart(KnowledgeArticleService.DRAFT_PREFIX);
        }
    }

    public static void defineEmailKCSDETeam(Knowledge__kav kav) {
        KCSSettings__c kcsSetting = KCSSettings__c.getInstance();
        kav.RC_Knowledge_Article_EmailKCSDETeam__c = kcsSetting.OverallEmail__c;
    }

    // This code is to delete the existing attachment in the knowledge record if there is a content added to the detatil field during updation. 
    
    public class HandleContentDeletion extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Knowledge__kav> newKnowledge = (List<Knowledge__kav>) Trigger.new;
            handleAfterUpdate(newKnowledge);
        }
        
        public void handleAfterUpdate(List<Knowledge__kav> newKnowledge) {
            // Get the IDs of Knowledge__kav records with Knowledge Detail field not null and not equal to the custom text value added in the custom label
            Set<Id> knowledgeIds = new Set<Id>();
            for (Knowledge__kav record : newKnowledge) {
                if (isChangedField(record, Knowledge__kav.RC_Knowledge_Article_Details__c) && record.RC_Knowledge_Article_Details__c != null && record.RC_Knowledge_Article_Details__c != System.Label.Knowledge_Detail_Preview_Message && record.RC_Knowledge_Article_Details__c != System.Label.Knowledge_Detail_Preview_Message_HTML) {
                    knowledgeIds.add(record.Id);
                }               
            }
            
            List<ContentDocument> documentsToDelete = new List<ContentDocument>();
            List<ContentVersion> olderContentVersions = (List<ContentVersion>) new ContentVersionSelector()
                .selectContentVersionsByKnowledgeIds(knowledgeIds)
                .executeQuery();
            
            for (ContentVersion cv : olderContentVersions) {              
                documentsToDelete.add(new ContentDocument(Id = cv.ContentDocumentId));               
            }
            
            if (!documentsToDelete.isEmpty()) {
                try {
                    delete documentsToDelete;
                }catch (DmlException e) {
                    Exception_And_Notification_History__c exceptionRecord = new Exception_And_Notification_History__c();
                    exceptionRecord.File_Associated__c = 'HandleContentDeletion';
                    ExceptionAndNotificationHelper.trackExceptions(exceptionRecord, e);
                }
            }    
        }
    } 

}