public class DocuSignController {
    public final static Integer MAX_ATTACHMENT_NAME_LENGTH = 96;
    public final static Integer RESERVED_MARKER_LENGTH = 21;

    @AuraEnabled public static Response getDataOnInit(Id opportunityId, Id quoteId) {
        Response r = new Response();

        try {
            r.setData(getAttachments(opportunityId));
            r.setData(getRecipients(opportunityId));
            r.setData(getEnvelopes(opportunityId, quoteId));
            r.setData('featureToggle', Feature_Toggle__c.getInstance());
            r.setData(getLinkedOpportunityList(quoteId));
        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }

        return r;
    }

    private static void setAttachments(List<Id> attachmentIds, Id targetId) {
        List<Attachment> attachmentList = [
            SELECT Id, Name, ParentId, Body
            FROM Attachment
            WHERE Id IN :attachmentIds
        ];

        Set<Id> parentIds = new Set<Id>();
        for (Attachment att : attachmentList) {
            parentIds.add(att.ParentId);
        }

        List<Opportunity> parents = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesByIds(parentIds)
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('Id = \'' + targetId + '\''))
            .executeQuery();
        Map<Id, Opportunity> parentsMap = new Map<Id, Opportunity>(parents);

        Id targetOptyId = getTargetOpty(parents) != null 
            ? getTargetOpty(parents).Id
            : null;

        delete [SELECT Id FROM Attachment WHERE ParentId = :targetId];

        List<Attachment> toInsert = new List<Attachment>();
        for (Attachment a : attachmentList) {
            Attachment newAtt = a.clone();
            newAtt.ParentId = targetId;
            /* Marker should be added only for attachments from child accounts */
            if (a.ParentId != targetOptyId) {
                String accountId = parentsMap.get(a.ParentId).AccountId;
                newAtt.Name = addMarkerForAttachmentName(a.Name, accountId);
            }

            toInsert.add(newAtt);
        }
        insert toInsert;
    }

    @AuraEnabled
    public static Response send(Id quoteId, List<Id> attachmentIds) {
        Response r = new Response();
        setAttachments(attachmentIds, quoteId);
        r.setData('quoteId', quoteId);

        return r;
    }

    @AuraEnabled
    public static Response getRecipients(Id opportunityId) {
        Response r = new Response();
        List<Recipient> result = new List<Recipient>();

        List<Contact> contacts = [
            SELECT Id, Name, FirstName, LastName, Email
            FROM Contact
            WHERE Id IN (
                SELECT Primary_Opportunity_Contact__c
                FROM Opportunity
                WHERE Id = :opportunityId
            )
        ];

        if (contacts.size() > 0) {
            result.add(new Recipient(contacts.get(0)));
        }

        Boolean hasEngageLegal = [
            SELECT COUNT()
            FROM Approval__c
            WHERE Opportunity__c = :opportunityId
            AND RecordTypeId = :ApprovalHelper.RT_ID_ENGAGE_LEGAL
            AND Status__c != :ApprovalHelper.STATUS_RECALLED
            LIMIT 1
        ] > 0;

        if (hasEngageLegal) {
            Id leaderId = getSegmentLeaderOrHigherId(opportunityId);
            User leader = null;
            if (leaderId != null) {
                leader = [
                    SELECT Id, Name, FirstName, LastName, Email, SmallPhotoUrl
                    FROM USER
                    WHERE Id = :leaderId
                ];
                result.add(new Recipient(leader));
            }
        }

        Integer i = 1;
        for (Recipient rec : result) {
            rec.Role = 'Signer ' + i++;
            rec.Action = 'Signer';
        }
        r.setData('recipientList', result);
        return r;
    }

    private static Id getSegmentLeaderOrHigherId(Id opportunityId) {
        Id result = null;
        Opportunity opp = [SELECT OwnerId, Owner.Hierarchy_Role__c FROM Opportunity WHERE Id = :opportunityId];
        List<Map<Id, String>> userIdToHRMapsList = new ApproversSearch().findManagersByRoleName(UserHelper.hierarchyRolesOrderToNameMap.values(), opp.OwnerId);

        Integer leaderIndex = UserHelper.hierarchyRolesNameToOrderMap.get(UserHelper.SEGMENT_LEADER_ROLE);
        Integer userIndex = UserHelper.hierarchyRolesNameToOrderMap.get(opp.Owner.Hierarchy_Role__c);
        userIndex = userIndex == null ? -1 : userIndex;
        Boolean isFound = false;
        for (Map<Id, String> pair : userIdToHRMapsList) {
            if (isFound) {
                break;
            }
            for (Id userId : pair.keySet()) {
                String role = pair.get(userId);
                Integer roleIndex = UserHelper.hierarchyRolesNameToOrderMap.get(role);
                if (roleIndex >= leaderIndex && roleIndex > userIndex) {
                    result = userId;
                    isFound = true;
                    break;
                }
            }
        }
        return result;
    }

    public class Recipient {
        @AuraEnabled public String Name;
        @AuraEnabled public String Id;
        @AuraEnabled public String FirstName;
        @AuraEnabled public String LastName;
        @AuraEnabled public String Email;
        @AuraEnabled public String PhotoUrl;
        @AuraEnabled public String Role;
        @AuraEnabled public String Action;

        public Recipient(User usr) {
            this.Name = usr.Name;
            this.FirstName = usr.FirstName;
            this.LastName = usr.LastName;
            this.Email = usr.Email;
            this.PhotoUrl = usr.SmallPhotoUrl;
            this.Id = usr.Id;
        }

        public Recipient(Contact cntct) {
            this.Name = cntct.Name;
            this.FirstName = cntct.FirstName;
            this.LastName = cntct.LastName;
            this.Email = cntct.Email;
            this.Id = cntct.Id;
        }
    }

    @AuraEnabled
    public static Response validateBeforeStart(Id opportunityId, Id selectedQuoteId) {
        Response r = new Response();
        r.setData('errorsSerialized', SendWithDocuSign.processData(opportunityId, selectedQuoteId));
        r.setData('additionalValidationResult', ApexWebServices.validateELOpportunity(opportunityId, 'Send with DocuSign'));
        return r;
    }

    @AuraEnabled
    public static Response getEnvelopes(Id opportunityId, Id quoteId) {
        Response r = new Response();
        List<dsfs__DocuSign_Status__c> currentEnvelopesList = new List<dsfs__DocuSign_Status__c>();
        List<dsfs__DocuSign_Status__c> envelopeList = new List<dsfs__DocuSign_Status__c>();
        if (opportunityId != null) {
            envelopeList = [
                SELECT Id, Name, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c, LastModifiedDate, CreatedDate,
                    dfsq__Quote__c, (
                    SELECT Id, Name, BodyLength, ContentType, LastModifiedBy.Name, LastModifiedDate, ParentId
                    FROM Attachments
                )
                FROM dsfs__DocuSign_Status__c
                WHERE dsfs__Opportunity__c = :opportunityId
            ];
        }

        if (!envelopeList.isEmpty()) {
            for (dsfs__DocuSign_Status__c envelope : envelopeList) {
                if (envelope.dfsq__Quote__c == quoteId) {
                    currentEnvelopesList.add(envelope);
                }
            }
        }
        r.setData('envelopeList', currentEnvelopesList);

        Boolean isOpportunityHasActiveEnvelopes = false;
        for (dsfs__DocuSign_Status__c ds : envelopeList) {
            if (new Set<String>{
                'Sent', 'Delivered', 'Completed'
            }.contains(ds.dsfs__Envelope_Status__c)) {
                isOpportunityHasActiveEnvelopes = true;
                break;
            }
        }
        r.setData('isOpportunityHasActiveEnvelopes', isOpportunityHasActiveEnvelopes);
        return r;
    }

    @AuraEnabled
    public static Response getAttachments(Id opportunityId) {
        Response r = new Response();
        List<Attachment> attachmentList = [
            SELECT Id, Name, BodyLength, ContentType, LastModifiedBy.Name, LastModifiedDate, ParentId
            FROM Attachment
            WHERE ParentId = :opportunityId
        ];
        r.setData('attachmentList', attachmentList);
        return r;
    }

    @AuraEnabled
    public static Response getLinkedOpportunityList(Id quoteId) {
        Response r = new Response();
        Opportunity[] opportunities = (Opportunity[]) new OpportunitySelector()
            .selectLinkedOpportunities(quoteId)
            .executeQuery();
        Map<Id, Response> opportunityIdToErrorsMap = new Map<Id, Response>();
        for (Opportunity o : opportunities) {

            // Validate Quotes
            Response oppErrors = new Response();
            Quote q = new Map<Id,Quote>(o.Quotes).get(quoteId);
            if (q == null) {
                q = QuoteHelper.getPrimaryQuote(o.Quotes, o.Is_Billing_Opportunity__c);
            }
            Id selectedQuote = q != null ? q.Id : null;
            SendWithDocuSign.ErrorWrapper[] dsErrors = SendWithDocuSign.getErrors(o, selectedQuote);
            if (dsErrors != null) {
                for (SendWithDocuSign.ErrorWrapper err : dsErrors) {
                    oppErrors.addMessage(err.message, Response.SEVERITY_ERROR);
                }
            }

            // Validate Engage Legal
            Response elErrors = ApexWebServices.validateELApprovals(o.Approvals__r, 'Send with DocuSign');
            if (elErrors.data.get('approvalId') != null) {
                oppErrors.addMessage(
                    'Please note that Legal Engagement approval is in progress.' +
                        ' You must recall the approval to send the opportunity with DocuSign',
                    Response.SEVERITY_ERROR
                );
            }
            oppErrors.setData(elErrors);

            opportunityIdToErrorsMap.put(o.Id, oppErrors);
        }
        r.setData('opportunityList', opportunities);
        r.setData('opportunityErrors', opportunityIdToErrorsMap);
        return r;
    }

    public static String addMarkerForAttachmentName(String attachName, Id accountId) {
        String shortenName = attachName.length() > MAX_ATTACHMENT_NAME_LENGTH - RESERVED_MARKER_LENGTH
            ? attachName.subString(0, MAX_ATTACHMENT_NAME_LENGTH - RESERVED_MARKER_LENGTH)
            : attachName.subString(0, attachName.lastIndexOf('.'));
        String attType = attachName.subString(attachName.lastIndexOf('.'), attachName.length());

        return shortenName + ' {' + accountId + '}' + attType;
    }

    public static Response completeEnvelope(Id envelopeId) {
        Response r = new Response();

        dsfs__DocuSign_Status__c envelope = [SELECT Id from dsfs__DocuSign_Status__c WHERE Id =: envelopeId LIMIT 1];
        envelope.dsfs__Envelope_Status__c = 'Completed';
        update envelope;

        return r;
    }

    public static Opportunity getTargetOpty(List<Opportunity> optyList) {
      Opportunity targetOpty;
      for (Opportunity opp : optyList) {
          if (!opp.Quotes.IsEmpty()) {
              targetOpty = opp;
              break;
          }
      }
      return targetOpty;
  }
}