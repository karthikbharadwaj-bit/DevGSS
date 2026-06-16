public class AttachmentTriggerHelper {
    static final String signedPostfix = '_Signed.pdf';
    public static final String BOB_APPROVERS_QUEUE_NAME = 'Finance Revenue Team';

    static final String BOB_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME = 'BoB_Partner_Review_Draft';
    static final String BOB_PARTNER_REVIEW_FINAL_TEMPLATE_NAME = 'BoB_Partner_Review_Final';
    static final String WHOLESALE_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME = 'Wholesale_Partner_Review_Draft';
    static final String WHOLESALE_PARTNER_REVIEW_FINAL_TEMPLATE_NAME = 'Wholesale_Partner_Review_Final';

    static final List<String> ACCOUNT_PARTNER_REVIEW_TEMPLATE_NAMES = new List<String>{
        BOB_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME,
        BOB_PARTNER_REVIEW_FINAL_TEMPLATE_NAME,
        WHOLESALE_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME,
        WHOLESALE_PARTNER_REVIEW_FINAL_TEMPLATE_NAME
    };

    public class BillOnBehalfProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isAfter && Trigger.isInsert) {
                List<Id> approvalIdsToProcess = new List<Id>();

                for (Attachment currentRecord: (List<Attachment>)Trigger.new) {
                    approvalIdsToProcess.add(currentRecord.ParentId);
                }

                processApprovalRecords (approvalIdsToProcess);
            }
        }
    }

    public class BillOnBehalfProcessing_Aura extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isAfter && Trigger.isInsert) {
                List<Id> approvalIdsToProcess = new List<Id>();

                for (ContentDocumentLink currentRecord: (List<ContentDocumentLink>)Trigger.new) {
                    approvalIdsToProcess.add(currentRecord.LinkedEntityId);
                }
                processApprovalRecords (approvalIdsToProcess);
            }
        }
    }

    private static void processApprovalRecords (List<Id> approvalIdsToProcess) {
        List<Approval__c> approvalsToProcess = [select Id, Record_Type_Name__c, OwnerId, Status__c,
                                                    (select Id from Attachments),
                                                    (select Id from ContentDocumentLinks)
                                                from Approval__c
                                                where Id in :approvalIdsToProcess];

        Map<String,Id> emailTemplatesMap = new Map<String,Id>();
        for (EmailTemplate currentTemplate: [select id, name, developername from EmailTemplate where developername IN :ACCOUNT_PARTNER_REVIEW_TEMPLATE_NAMES]) {
            emailTemplatesMap.put(currentTemplate.DeveloperName, currentTemplate.Id);
        }

        List<GroupMember> groupMembers = (List<GroupMember>) new GroupMemberSelector()
            .selectGroupMembersByGroupName(BOB_APPROVERS_QUEUE_NAME)
            .addOrdering('SystemModstamp', QueryFactory.SortOrder.ASCENDING)
            .setQueryCaching(true)
            .executeQuery();

        Set<Id> queueMemberIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            queueMemberIds.add(member.UserOrGroupId);
        }

        List<User> approversList = (List<User>) new UserSelector().newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'Hierarchy_Role__c', 'Email' })
            .setCondition('IsActive = True AND Id IN :bind0')
            .setQueryBindings(new List<Object>{ queueMemberIds })
            .setQueryCaching(true)
            .executeQuery();

        for (Approval__c currentRecord: approvalsToProcess) {
            if (currentRecord.Record_Type_Name__c == ApprovalHelper.RT_NAME_BOB_APPROVAL
                || currentRecord.Record_Type_Name__c == ApprovalHelper.RT_NAME_WHOLESALE_APPROVAL) {
                Id templateIdForUse;
                String templateName;
                if ((currentRecord.Attachments.size() + currentRecord.ContentDocumentLinks.size()) == 1) {
                    templateName = currentRecord.Record_Type_Name__c == ApprovalHelper.RT_NAME_BOB_APPROVAL ?
                                    BOB_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME :
                                    WHOLESALE_PARTNER_REVIEW_DRAFT_TEMPLATE_NAME;

                    templateIdForUse = emailTemplatesMap.get(templateName);
                } else if ((currentRecord.Attachments.size() + currentRecord.ContentDocumentLinks.size()) > 1 
                            && currentRecord.Status__c != ApprovalHelper.STATUS_APPROVED) {
                    templateName = currentRecord.Record_Type_Name__c == ApprovalHelper.RT_NAME_BOB_APPROVAL ?
                                    BOB_PARTNER_REVIEW_FINAL_TEMPLATE_NAME :
                                    WHOLESALE_PARTNER_REVIEW_FINAL_TEMPLATE_NAME;
                                    
                    templateIdForUse = emailTemplatesMap.get(templateName);
                }
                for (User currentApprover: approversList) {
                    sendSingleEmail(templateIdForUse, currentApprover.Id, currentRecord.Id);
                }
            }
        }

    }

    private static void sendSingleEmail (String templateId, Id userId, Id whatId) {
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, userId, whatId);

        String emailSubject = email.getSubject();
        String emailTextBody = email.getPlainTextBody();

        email.setSubject(emailSubject);
        email.setPlainTextBody(emailTextBody);
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        return;
    }

    /******************************** TELUS S2S ATTACHMENT SHARING ****************************/
    public class TellusProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if(Trigger.isBefore){
                TelusExternalSharingHelperCls.reParentAttachmentOnRC(Trigger.new);
            } else {
                List<Attachment> localAttachmentList = new List<Attachment>();
                for(Attachment attch : (List <Attachment>)Trigger.New){
                    if(attch.ConnectionReceivedId == NULL){// Local record
                        localAttachmentList.add(attch);
                    }
                }
                TelusExternalSharingHelperCls.shareWithTelus((List<sObject>) localAttachmentList);
            }
        }
    }
    public class LegacyProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
                /*********************************************************************************************/
            
            Profile currentUserProfileRecord = null;
            if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
                currentUserProfileRecord = ProfileHelper.getCurrentUserProfileWithCache();
            }
            else {
                currentUserProfileRecord = [select Name from Profile where Id = :UserInfo.getProfileId()];
            }
            if (!'System Administrator'.equalsIgnoreCase(currentUserProfileRecord.Name) || Test.isRunningTest()) {
                Set<Id> attParentIdSet = new Set<Id>();
                for(Attachment attVal : (List <Attachment>)Trigger.New) {
                    if(attVal != null && attVal.ParentId !=null) {
                        attParentIdSet.add(attVal.ParentId);
                    }
                }
                Map<Id,Opportunity> opportunityMap;
                Map<Id,Lead> leadMap;
                Map<Id,Case> caseMap;
                Map<Id,Group> groupMap;
                Map<Id,User> userMap;
                if(attParentIdSet != null && attParentIdSet.size() >0) {
                     opportunityMap = new Map<Id,Opportunity>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c FROM Opportunity where id in : attParentIdSet]);
                     leadMap = new Map<Id,Lead>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c from Lead WHERE id in : attParentIdSet]);
                     caseMap = new Map<Id,Case>([SELECT id,Subject,Description,ConnectionReceivedId,CaseNumber,Ownerid,Owner.Name FROM Case WHERE id in : attParentIdSet]);
                     if(caseMap != null && caseMap.size() > 0) {
                         Set<Id> caseOwnerId = new Set<Id>();
                         for(Case casVal : caseMap.values()) {
                           caseOwnerId.add(casVal.OwnerId);
                         }
                         if(caseOwnerId !=null && caseOwnerId.size()>0) {
                             //Case 04362176 - Remove distribution list from notification - START
                             groupMap = new Map<Id,Group>([SELECT email, Name FROM Group WHERE Id IN :caseOwnerId ]);
                             //Case 04362176 - Remove distribution list from notification - END
                             userMap = new Map<Id,User>([SELECT email FROM User WHERE Id IN :caseOwnerId]);
                         }
                    }
                }

                List<Opportunity> oppLst = new  List<Opportunity>();
                List<Lead> leadLst = new  List<Lead>();
                Set<Id> leadId = new  Set<Id>();
                Set<Id> opportunityId = new  Set<Id>();

                for(Attachment attVal : (List <Attachment>)Trigger.New) {
                    if(opportunityMap != null && attVal.ParentId != null) {
                        Opportunity oppVal = opportunityMap.get(attVal.ParentId);
                          if(oppVal != null) {
                            if(oppVal.Responded_Date__c == null && oppVal.Responded_By__c == null) {
                                oppVal.Responded_Date__c = Datetime.now();
                                oppVal.Responded_By__c = UserInfo.getUserId();
                            }
                            oppVal.Last_Touched_Date__c  = Datetime.now();
                            oppVal.Last_Touched_By__c = UserInfo.getUserId();
                            if(opportunityId != null && !(opportunityId.Contains(attVal.ParentId))) {
                                  oppLst.add(oppVal);
                                  opportunityId.add(attVal.ParentId);
                               }
                         }
                    }

                   if(leadMap != null && attVal.ParentId != null) {
                           Lead leadVal = leadMap.get(attVal.ParentId);
                           if(leadVal != null) {
                            if(leadVal.Responded_Date__c == null && leadVal.Responded_By__c==null) {
                                leadVal.Responded_Date__c = Datetime.now();
                                leadVal.Responded_By__c = UserInfo.getUserId();
                            }
                            leadVal.Last_Touched_Date__c  = Datetime.now();
                            leadVal.Last_Touched_By__c = UserInfo.getUserId();
                            if(leadId != null && !(leadId.Contains(attVal.ParentId))) {
                                  leadLst.add(leadVal);
                                  leadId.add(attVal.ParentId);
                               }
                           }
                   }

                  if(caseMap != null && attVal.ParentId != null) {
                        Case caseVal = caseMap.get(attVal.ParentId);
                        if(caseVal != null) {
                           String email = '';
                        /* ownerId may belong to a group, so need to get the email from group if exists
                           The below loop will run for one iteration only, so need not to worry about performance.
                        */
                        /* for(Group groupObj: [SELECT Email FROM Group WHERE Id=: caseVal.Ownerid LIMIT 1]) {
                            email = groupObj.email;
                        } */

                        if(groupMap != null) {
                            //Case 04362176 - Remove distribution list from notification - START

                            if(caseVal.Ownerid != null && groupMap.containsKey(caseVal.Ownerid)){
                                if(groupMap.get(caseVal.Ownerid).name != 'US Support Tier 3' && groupMap.get(caseVal.Ownerid).name != 'Support Tier 3'){
                                    //If the case's owner's name is US Support then the ent.us.support@ringcentral.com email should be used
                                    if (groupMap.get(caseVal.Ownerid).name == 'US Support') {
                                        email = 'ent.us.support@ringcentral.com';
                                    } else {
                                        email = groupMap.get(caseVal.Ownerid).email;
                                    }
                                }
                            }
                            /*
                            if(caseVal.Ownerid != null && groupMap.containsKey(caseVal.Ownerid))
                                email = groupMap.get(caseVal.Ownerid).email;
                            */

                            //Case 04362176 - Remove distribution list from notification - START
                        }
                        /* if the owner does not belong to group, need to check it from User and get the email from the same
                            below the for loop will run for one iteration only,The below pattern will handle  the assignment exceptions so no need to worry about performance.

                        */
                        if(email == '') {
                            /*for(User userdata: [Select Email from User where id =:  caseVal.Ownerid LIMIT 1]) {
                                email = userdata.email;
                            }*/
                            if(userMap != null) {
                                if(caseVal.Ownerid != null && userMap.containsKey(caseVal.Ownerid)){
                                    //Konstantyn user should not receive emails when an Attachment is added
                                    if ('konstantyn.koniukhev@ringcentral.com' != userMap.get(caseVal.ownerId).email) {
                                        email = userMap.get(caseVal.Ownerid).email;
                                    }
                                }
                            }
                        }
                        /*
                        The email will be sent if the email is not blank, the below check will handle the exception
                        */
                        if(email != '') {
                          MailHelper mailObj = new MailHelper();
                          try {
                                 /*mailObj.createMail('Attachment Description: ' + caseVal.Description + ' Added' , null, null , null, true, 'Salesforce Support',
                                 'New Attachment has been Added to : ' + (caseVal.Subject == null ? ' case #' + caseVal.CaseNumber : caseVal.Subject), email);*/
                                 mailObj.createMail('Attachment Description: ' + caseVal.Description + ' Added' , null, null , null, true, 'Salesforce Support',
                                 'New Attachment has been Added to Case : ' + caseVal.CaseNumber + ' '+(String.isBlank(caseVal.Subject) ? '' : caseVal.Subject), email);

                          } catch(Exception ex) { }
                        }
                        }
                   }
                }
                if(oppLst != null && oppLst.size() > 0) {
                    try {
                        update oppLst;
                    } catch(DMLException e) { }
                }
                if(leadLst != null && leadLst.size() > 0) {
                    try {
                        update leadLst;
                    } catch(DMLException e){}
                }
            }

            set<Id> caseIdPortingSet = new set<Id>();
            for(Attachment attVal : (List <Attachment>)Trigger.New) {
                if(attVal != null && attVal.ParentId != null && string.valueOf(attVal.ParentId).startsWith('500')) {
                    caseIdPortingSet.add(attVal.ParentId);
                }
            }

            map<Id,Case> caseMapPorting = new map<Id,Case>([select Id,ConnectionReceivedId from Case where ID IN : caseIdPortingSet
                                                            and (RecordType.Name = 'Porting - In (NeuStar)'
                                                                    OR RecordType.Name = 'Porting - In (RC)' OR RecordType.Name = 'Porting - In (TELUS)' OR  RecordType.Name = 'Porting - In (RC UK)')]);

            Set<Id> localToPartnerCaseSet = new Set<Id>();
            for (PartnerNetworkRecordConnection connectionCase : [SELECT Id, Status, PartnerRecordId,ConnectionId, LocalRecordId
                                                                  FROM PartnerNetworkRecordConnection
                                                                  WHERE LocalRecordId IN :caseIdPortingSet]){
                localToPartnerCaseSet.add(connectionCase.LocalRecordId);
            }

            Boolean hasCustomPermissionAgentPorting = FeatureManagement.checkPermission('Support_Agent_Porting_Permission');
			system.debug('hasCustomPermissionAgentPorting'+hasCustomPermissionAgentPorting);
            Boolean hasCustomPermissionManagerPorting = FeatureManagement.checkPermission('Support_Manager_Porting_Permission');
			system.debug('hasCustomPermissionManagerPorting'+hasCustomPermissionManagerPorting);

            List<Case> caseListTOuUpd = new List<Case>();
            for(Attachment attVal : (List <Attachment>)Trigger.New) {
                if(attVal != null && attVal.ParentId != null && string.valueOf(attVal.ParentId).startsWith('500')) {
                    if(caseMapPorting != null && caseMapPorting.get(attVal.ParentId) != null && currentUserProfileRecord.Name != 'System Administrator'
                        && UserInfo.getName() != 'RCESB'
                        && !localToPartnerCaseSet.contains(attVal.ParentId) && !hasCustomPermissionAgentPorting && !hasCustomPermissionManagerPorting)
                    //Added Support Porting Shipping as part of profile consolidation on Support Porting profiles- T1
                    {
                            /*Case caseObjTOUpd = new Case(Id = attVal.ParentId);
                            caseObjTOUpd.IsUpdatePermitted__c = false;
                            caseListTOuUpd.add(caseObjTOUpd);*/
                        attVal.addError('Not Authorized to add Attachments.');
                    }
                }
            }
        }
    }

    //This class will process attachments under DocuSign status:
    //Once DocuSign status is changed to the "Completed", signed version of docs
    //will replace not signed attaches on the DocuSign records. Here we will catch this event
    //and copy all attachments to recent active contract under related account
    //See logic behind active contract creation in: DocuSignStatusTriggerHandler
    public class DocuSignAttachmentProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Id> attachmentToDocuSignIds = getAttachmentToDocuSignId(Trigger.new);
            Map<Id, dsfs__DocuSign_Status__c> attachmentIdToCompletedDocuSignId = getCompletedDocuSigns(attachmentToDocuSignIds, (Map<Id,Attachment>)Trigger.newMap);

            Map<Id, List<Attachment>> accountIdToAttachmentMap = new Map<Id, List<Attachment>>();
            for (Attachment att : (List<Attachment>) Trigger.new) {
                dsfs__DocuSign_Status__c completedDocusign = attachmentIdToCompletedDocuSignId.get(att.Id);
                if (completedDocusign == null) {
                    continue;
                }

                String accId = getAccountId(att.Name, completedDocusign);

                Boolean isValidId = SFDescribeHelper.isValidSalesforceId(accId, Schema.Account.sObjectType);

                if (isValidId) {
                    if (!accountIdToAttachmentMap.containsKey(accId)) {
                        accountIdToAttachmentMap.put(accId, new List<Attachment>());
                    }
                    accountIdToAttachmentMap.get(accId).add(att);
                }
            }

            if (accountIdToAttachmentMap.isEmpty()) {
                return;
            }

            List<Account> accountList = getAccountsWithContracts(accountIdToAttachmentMap.keySet());

            List<Attachment> clonedAttachments = new List<Attachment>();
            for (Account acc : accountList) {
                Attachment clonedAttachForAccount;
                Contract newParent = acc.Contracts.isEmpty() ? null : acc.Contracts[0];
                if (newParent != null) {
                    for (Attachment att : accountIdToAttachmentMap.get(acc.Id)) {
                        //add attachment to contract
                        clonedAttachments.add(cloneAttachment(att, newParent.Id));
                        //add attachment to account
                        //discussed to store duplicate value with trigger logic
                        clonedAttachments.add(cloneAttachment(att, acc.Id));
                    }
                }
            }
            insert clonedAttachments;
        }

        private Attachment cloneAttachment(Attachment att, String parentId) {
            Attachment clonedAttachment = att.clone();
            clonedAttachment.ParentId = parentId;
            return clonedAttachment;
        }

        private String getAccountId(String attachmentName, dsfs__DocuSign_Status__c completedDocusign) {
            String accountId = '';

            Pattern regexPattern = Pattern.compile('(?<=\\{)([\\s\\S]+?)(?=\\})'); // find ...{AccountId}...
            Matcher regexMatcher = regexPattern.matcher(attachmentName);
            if (regexMatcher.find()) {
                accountId = regexMatcher.group(1);
            } else {
                accountId = completedDocusign.dsfs__Company__c;
            }
            return accountId.trim();
        }

        private List<Account> getAccountsWithContracts(Set<Id> accIdSet) {
            List<Account> accList = (List<Account>) new AccountSelector()
                    .selectAccountsWithActiveContract(new List<Object>{new List<Id>(accIdSet)})
                    .executeQuery();
            return accList;
        }

        private Map<Id, Id> getAttachmentToDocuSignId(Attachment[] newRecords) {
            Map<Id, Id> result = new Map<Id, Id>();
            for (Attachment entry : newRecords) {
                if (entry.ParentId.getSObjectType() == dsfs__DocuSign_Status__c.SObjectType) {
                    result.put(entry.Id, entry.ParentId);
                }
            }
            return result;
        }

        private Map<Id, dsfs__DocuSign_Status__c> getCompletedDocuSigns(Map<Id, Id> attachmentToDocuSignIds, Map<Id, Attachment> attachments) {
            Map<Id, dsfs__DocuSign_Status__c> result = new Map<Id, dsfs__DocuSign_Status__c>();

			DocuSignStatusSelector docuSignStatusSelector = new DocuSignStatusSelector();
			List<Object> bindings = new List<Object>();
            bindings.add(DocuSignHelper.ENVELOPE_STATUS_COMPLETED);
            bindings.add(attachmentToDocuSignIds.values());

			List<dsfs__DocuSign_Status__c> completedDocuSignsList = (List<dsfs__DocuSign_Status__c>) docuSignStatusSelector
                    .selectDocuSignStatusesByAttachments(bindings)
                    .executeQuery();

			Map<Id, dsfs__DocuSign_Status__c> completedDocuSigns = new Map<Id, dsfs__DocuSign_Status__c>(completedDocuSignsList);

            for (Id entry : attachmentToDocuSignIds.keySet()) {
                if (completedDocuSigns.containsKey(attachmentToDocuSignIds.get(entry))) {
                    result.put(entry, completedDocuSigns.get(attachments.get(entry).ParentId));
                }
            }
            return result;
        }
    }

    private static boolean isNdaForDocusignEnvelope(Attachment a) {
        return a.Name.startsWithIgnoreCase(AttachmentHelper.NDA_NAME_PREFIX)
            && a.ParentId.getSobjectType() == Schema.dsfs__DocuSign_Status__c.SObjectType;
    }

    public class CopySignedNdaAttachmentToAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Attachment> newAttachmentsForAccount = new List<Attachment>();
            Set<Attachment> ndaPdfs = new Set<Attachment>();
            Set<Id> envelopeIds = new Set<Id>();

            for (Attachment att : (List<Attachment>) Trigger.new) {
                if (isNdaForDocusignEnvelope(att)) {
                    ndaPdfs.add(att);
                    envelopeIds.add(att.ParentId);
                }
            }

            if (!ndaPdfs.isEmpty()) {
                Map<Id, dsfs__DocuSign_Status__c> completedEnvelopes = new Map<Id, dsfs__DocuSign_Status__c>(
                    (List<dsfs__DocuSign_Status__c>) new DocuSignStatusSelector()
                        .selectCompletedDocuSignStatusesForNdaById(new List<Object> {envelopeIds})
                        .executeQuery()
                );

                for (Attachment att : ndaPdfs) {
                    Attachment newAttachmentForAccount = createAttachmentForAccount(att, completedEnvelopes);
                    if (newAttachmentForAccount != null) {
                        newAttachmentsForAccount.add(newAttachmentForAccount);
                    }
                }
            }

            insert newAttachmentsForAccount;
        }

        private Attachment createAttachmentForAccount(Attachment att, Map<Id, dsfs__DocuSign_Status__c> completedEnvelopes) {
            Attachment newAtt;

            dsfs__DocuSign_Status__c envelopeForAttachment = completedEnvelopes.get(att.ParentId);

            if (envelopeForAttachment != null) {
                newAtt = att.clone(false, true, false, false);
                newAtt.ParentId = envelopeForAttachment.dsfs__Company__c;
                newAtt.Name = newAtt.Name.removeEnd('.pdf') + signedPostfix;
            }

            return newAtt;
        }
    }

    public class PopulateNdaStatusOnAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Account> accountsToUpdate = new List<Account>();
            Map<Id, Id> envelopeIdToAccountId = getEnvelopeIdToAccountIdMap();
            Map<Id, List<Attachment>> envelopeIdToAttachments = getEnvelopeIdToAttachments();

            for (Attachment a : (List<Attachment>) Trigger.new) {
                if (isNdaPdfForAccount(a)) {
                    accountsToUpdate.add(
                        new Account(
                            Id = a.ParentId,
                            NdaStatus__c = AccountHelper.NDA_GENERATED)
                    );
                }

                if (isNdaForDocusignEnvelope(a)
                    && envelopeIdToAccountId.size() > 0
                    && !isDuplicateAttachment(envelopeIdToAttachments, a)) {
                    accountsToUpdate.add(
                        new Account(
                            Id = envelopeIdToAccountId.get(a.ParentId),
                            NdaStatus__c = AccountHelper.NDA_OUT_FOR_SIGNATURE)
                    );
                }
            }

            update accountsToUpdate;
        }

        private Map<Id, Id> getEnvelopeIdToAccountIdMap() {
            Map<Id, Id> envelopeIdToAccountId = new  Map<Id, Id>();
            Set<Id> envelopeIds = new Set<Id>();

            for (Attachment a : (List<Attachment>) Trigger.new) {
                if (isNdaForDocusignEnvelope(a)) {
                    envelopeIds.add(a.ParentId);
                }
            }

            if (envelopeIds.size() > 0) {
                List<dsfs__DocuSign_Status__c> envelopes = (List<dsfs__DocuSign_Status__c>) new DocuSignStatusSelector()
                    .selectDocuSignStatusesByIds(new List<Object> {envelopeIds})
                    .executeQuery();

                for (dsfs__DocuSign_Status__c e : envelopes) {
                    envelopeIdToAccountId.put(e.Id, e.dsfs__Company__c);
                }
            }

            return envelopeIdToAccountId;
        }

        private Map<Id, List<Attachment>> getEnvelopeIdToAttachments() {
            Map<Id, List<Attachment>> envelopeIdToAttachments = new Map<Id, List<Attachment>>();
            Set<Id> envelopeIds = new Set<Id>();

            for (Attachment a : (List<Attachment>) Trigger.new) {
                if (isNdaForDocusignEnvelope(a)) {
                    envelopeIds.add(a.ParentId);
                }
            }

            if (envelopeIds.size() > 0) {
                List<Attachment> attachments = (List<Attachment>) new AttachmentSelector()
                    .selectAttachmentsByParentIds(new List<Object>{envelopeIds})
                    .executeQuery();

                for (Attachment a : attachments) {
                    if (!Trigger.newMap.keySet().contains(a.Id)) {
                        List<Attachment> currentAttachments = envelopeIdToAttachments.get(a.ParentId);

                        if (currentAttachments == null) {
                            envelopeIdToAttachments.put(a.ParentId, new List<Attachment>{a});
                        } else {
                            List<Attachment> newAttachmentList = currentAttachments;
                            newAttachmentList.add(a);
                            envelopeIdToAttachments.put(a.ParentId, newAttachmentList);
                        }
                    }
                }
            }

            return envelopeIdToAttachments;
        }

        private boolean isNdaPdfForAccount(Attachment a) {
            return a.Name.startsWithIgnoreCase(AttachmentHelper.NDA_NAME_PREFIX)
                && !a.Name.endsWithIgnoreCase(signedPostfix)
                && a.ParentId.getSobjectType() == Schema.Account.SObjectType;
        }

        private Boolean isDuplicateAttachment( Map<Id, List<Attachment>> envelopeIdToAttachments, Attachment a) {
            List<Attachment> attachmentsForEnvelope = envelopeIdToAttachments.get(a.ParentId);
            Boolean isDuplicate = false;

            if (attachmentsForEnvelope != null) {
                for (Attachment existingAttachment : attachmentsForEnvelope) {
                    if (existingAttachment.Name == a.Name) {
                        isDuplicate = true;
                        break;
                    }
                }
            }

            return isDuplicate;
        }
    }
    public class ExecSupportProcessing extends Triggers.TriggerHandlerBase {

        override public void handle(){
            if(!Test.isRunningTest()){
                EmailMessageTriggerHandler.handleAttachmentsExecSupport(Trigger.newmap.keySet());
            }
        }
    }
    
    //This code is to provide access to content document records owned by Integration user to the Ringcentral Users
    
    public class KnowledgeContentSharing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            // Retrieve all records from the custom setting
            Map<String, Knowledge_Attachment_Settings__c> knowledgeAttachmentSettings = Knowledge_Attachment_Settings__c.getAll();
            // Store the current user ID to avoid repeated calls
            Id currentUserId = UserInfo.getUserId();
            // Check if the current user is one of the users specified in the custom setting
            Boolean isIntegrationUser = false;
            for (Knowledge_Attachment_Settings__c setting : knowledgeAttachmentSettings.values()) {
                if (currentUserId == setting.User_Id__c) {
                    isIntegrationUser = true;
                    break;
                }
            }
            // Exit if the current user is not an Integration Services user
            if (!isIntegrationUser) {
                return;
            }
            Id orgId = UserInfo.getOrganizationId();
            List<ContentDocumentLink> contentsLinkedToKnowledge = new List<ContentDocumentLink>();
            if (Trigger.isAfter && Trigger.isInsert) {
                for (ContentDocumentLink cl : (List<ContentDocumentLink>) Trigger.new) {
                    if (cl.LinkedEntityId != null && (isKnowledgeObject(cl.LinkedEntityId.getSObjectType()) || Test.isRunningTest())) {
                        ContentDocumentLink cl1 = new ContentDocumentLink();
                        cl1.ContentDocumentId = cl.ContentDocumentId;
                        cl1.LinkedEntityId = orgId; 
                        cl1.ShareType = 'V'; 
                        cl1.Visibility = 'AllUsers';
                        contentsLinkedToKnowledge.add(cl1);
                    }
                }
                if (!contentsLinkedToKnowledge.isEmpty()) {
                    try {
                        insert contentsLinkedToKnowledge;
                    } catch (DmlException e) {
                        Exception_And_Notification_History__c exceptionRecord = new Exception_And_Notification_History__c();
                        exceptionRecord.File_Associated__c = 'KnowledgeContentSharing';
                        ExceptionAndNotificationHelper.trackExceptions(exceptionRecord, e);
                    }
                } 
            }
        }
        // Helper method to check if the object is Knowledge__kav
        private Boolean isKnowledgeObject(Schema.SObjectType objectType) {
            if (objectType == null) {
                return false;
            }
            return objectType.getDescribe().getName() == 'Knowledge__kav';
        }
    }
}