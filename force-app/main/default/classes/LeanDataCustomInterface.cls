global class LeanDataCustomInterface extends LeanData.CustomInterface {
  
  // ========================================
  // KEEP: All existing working functionality
  // ========================================
  
  public static List<SObject> getContactEmailExactMatches(
    SObject primary,
    List<SObject> matchedSObjects
  ) {
    String mode;
    if (
      !matchedSObjects.isEmpty() &&
      matchedSObjects[0].getSObjectType() == Opportunity.SObjectType
    ) {
      mode = 'Opportunity Match';
    } else {
      mode = 'Account Match';
    }

    List<SObject> newMatchedSObjects = new List<SObject>();
    Lead leadPrimary = (Lead) primary;
    String leadEmail = String.isEmpty(leadPrimary.Email)
      ? ''
      : leadPrimary.Email.toLowerCase().trim();
    Set<Id> matchedAccountIds = new Set<Id>();
    Map<Id, List<SObject>> accountToOpportunities = new Map<Id, List<SObject>>();
    Map<Id, SObject> idToAccountMap = new Map<Id, SObject>();

    if (mode == 'Opportunity Match') {
      for (SObject matchedOpportunity : matchedSObjects) {
        Opportunity o = (Opportunity) matchedOpportunity;
        matchedAccountIds.add(o.AccountId);
        if (accountToOpportunities.get(o.AccountId) == null) {
          accountToOpportunities.put(o.AccountId, new List<SObject>());
        }
        accountToOpportunities.get(o.AccountId).add(matchedOpportunity);
      }
    } else {
      for (SObject matchedAccount : matchedSObjects) {
        matchedAccountIds.add(matchedAccount.Id);
        idToAccountMap.put(matchedAccount.Id, matchedAccount);
      }
    }

    Set<Id> touchedAccounts = new Set<Id>();

    for (Contact c : [
      SELECT AccountId, Email
      FROM Contact
      WHERE AccountId IN :matchedAccountIds
      ORDER BY LastActivityDate DESC NULLS LAST, CreatedDate DESC
      LIMIT 2000
    ]) {
      String contactEmail = String.isEmpty(c.Email)
        ? ''
        : c.Email.toLowerCase().trim();
      if (
        leadEmail.equals(contactEmail) && !touchedAccounts.contains(c.AccountId)
      ) {
        if (mode == 'Account Match') {
          newMatchedSObjects.add(idToAccountMap.get(c.AccountId));
        } else if (mode == 'Opportunity Match') {
          newMatchedSObjects.addAll(accountToOpportunities.get(c.AccountId));
        }
        touchedAccounts.add(c.AccountId);
      }
    }

    return newMatchedSObjects;
  }

  global override List<SObject> customTiebreakerRule(
    SObject primary,
    List<SObject> matchedSObjects,
    String parameter
  ) {
    List<SObject> newMatchedSObjects = new List<SObject>();
    if (
      primary.getSObjectType() == Lead.SObjectType &&
      parameter == 'contact email xact match'
    ) {
      newMatchedSObjects = getContactEmailExactMatches(
        primary,
        matchedSObjects
      );
    }
    return newMatchedSObjects;
  }

  global override List<SObject> customFilter(
    SObject primary,
    List<SObject> matchedSObjects,
    String parameter
  ) {
    List<SObject> newMatchedSObjects = new List<SObject>();
    if (
      primary.getSObjectType() == Lead.SObjectType &&
      parameter == 'contact email xact match'
    ) {
      newMatchedSObjects = getContactEmailExactMatches(
        primary,
        matchedSObjects
      );
    }
    return newMatchedSObjects;
  }

  public String getActivityQuery(Lead leadPrimary) {
    Id primaryCompanyId = leadPrimary.AH_Name__c;
    Id companyOwner = leadPrimary.AH_Name__r.AH_Alternate_Owner__c;
    if (primaryCompanyId == null || companyOwner == null) {
      return 'SELECT Id FROM Task WHERE Id = null';
    }
    LeanDataCustomInterfaceSettings__c leadRoutingSettings = LeanDataCustomInterfaceSettings__c.getOrgDefaults();
    String leadCondition = leadRoutingSettings.RelevantLeadCondition__c;
    String activityCondition = leadRoutingSettings.RelevantActivityCondition__c;
    String query = 'SELECT Id FROM Task WHERE OwnerId = \'' + companyOwner;
    query +=
      '\' AND WhoId IN (SELECT Id FROM Lead WHERE AH_Name__c = \'' +
      primaryCompanyId +
      '\' ';
    if (!String.isEmpty(leadCondition)) {
      query += ' AND ' + leadCondition;
    }
    query += ')';
    if (!String.isEmpty(activityCondition)) {
      query += ' AND ' + activityCondition;
    }
    query += ' LIMIT 1';
    return query;
  }

  public String activityBasedRouting(
    Lead leadPrimary,
    Map<String, SObject> chosenSObjects
  ) {
    String returnEdge;
    if (!Database.query(getActivityQuery(leadPrimary)).isEmpty()) {
      leadPrimary.OwnerId = leadPrimary.AH_Name__r.AH_Alternate_Owner__c;
      returnEdge = 'Next Node';
    } else {
      returnEdge = 'False';
    }
    return returnEdge;
  }

  public class GlipQueueable implements Queueable, Database.AllowsCallouts {
    public Id templateId { get; set; }
    public Id ownerId { get; set; }
    public Lead routingLead { get; set; }

    public GlipQueueable(Id templateId, Id ownerId, Id routingId) {
      this.templateId = templateId;
      this.ownerId = ownerId;
      this.routingLead = new Lead(Id = routingId);
    }

    public void execute(QueueableContext context) {
      GlipRoutingHelper.sendGlipNotification(routingLead, ownerId, templateId);
    }
  }

  // ========================================
  // UPDATE: Change method signature to v1.623 format
  // ========================================
  
  global override String customRoutingRule(
    SObject primary,
    Map<String, SObject> chosenSObjects,
    String parameter,
    Map<String,Object> additionalParameters  // NEW: v1.623 requires this parameter
  ) {
    
    if (parameter == 'Activity Based Routing') {
      return activityBasedRouting((Lead) primary, chosenSObjects);
      
    } else if (parameter == 'Glip Webhook Alert') {
      // KEEP: Your existing working Glip Webhook Alert logic
      String endpointUrl = (String) additionalParameters.get('Endpoint URL');
      String payload = generateLeadJson(primary);
      System.enqueueJob(new SendRestRequestJob(endpointUrl, payload));
      return 'Next Node';
      
    } else if (parameter == 'Custom Merge') {
      Lead originalLead = (Lead) chosenSObjects.get('Dupe');
      Lead newLead = new Lead(Id = originalLead.Id);
      Lead newDuplicateLead = new Lead(Id = primary.Id);
      Database.merge(newLead, newDuplicateLead);
      return 'Next Node';
      
    } else if (parameter == 'Future Glip Notification') {
      String inputId = (String) additionalParameters.get('Template Id');
      System.enqueueJob(
        new GlipQueueable(
          Id.valueOf(inputId),
          (Id) primary.get('OwnerId'),
          primary.Id
        )
      );
      return 'Next Node';
      
    } else if (parameter == 'Send Glip Notification') {
      String inputId = (String) additionalParameters.get('Template Id');
      Lead routingLead = (Lead) primary;
      String edge = GlipRoutingHelper.sendGlipNotification(
        routingLead,
        routingLead.OwnerId,
        Id.valueOf(inputId)
      );
      return edge;
      
    } else if (parameter == 'Sales Agent Email Routing') {
      Lead varLead = (Lead) primary;
      Set<String> emailsToCheck = new Set<String>();
      User varUser;
      List<Object> bindings = new List<Object>();
      bindings.add(new Set<String>{ 'DO NOT CONTACT - VAR' });
      List<User> varUsers = (List<User>) new UserSelector()
        .selectUserByName(bindings)
        .executeQuery();
      if (varUsers.size() > 0) {
        varUser = varUsers[0];
      }
      if (varLead.Lead_Owner_Email_Address__c != null) {
        emailsToCheck.add(varLead.Lead_Owner_Email_Address__c);
      }
      if (varLead.Sales_Agent_Email__c != null) {
        emailsToCheck.add(varLead.Sales_Agent_Email__c);
      }
      if (emailsToCheck.isEmpty()) {
        return 'Next Node';
      }
      bindings.clear();
      bindings.add(emailsToCheck);
      List<String> fields = new List<String>{
        'Id',
        'Profile.Name',
        'IsActive',
        'Contact.Account.Partner_Id__c',
        'Contact.Account.Ultimate_Parent_Partner_ID__c',
        'Contact.Account.Ultimate_Parent_Account_Name__c',
        'Contact.Account.Inside_Sales_Rep__c',
        'Contact.Account.Current_Owner__c',
        'Contact.Account.Current_Owner__r.IsActive',
        'Contact.Account.Name',
        'Contact.Account.VAR_Territory__c'
      };
      //String condition = 'UserName IN :bind0 AND (IsActive = true OR Contact.Account.Current_Owner__r.IsActive = true)'; - Old Code
      //String condition = 'Email IN :bind0 AND (IsActive = true OR Contact.Account.Current_Owner__r.IsActive = true)'; //Changed UserName to Email by Charles 06-27-2025 11:08PM PHT
      //Added identifier for Sandbox/Production 07-10-2025 Start
      String fieldToCheck = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ? 'Email' : 'UserName';
      String condition = fieldToCheck + ' IN :bind0 AND (IsActive = true OR Contact.Account.Current_Owner__r.IsActive = true)';
      //End
      List<User> matchedUsers = (List<User>) new UserSelector()
        .selectUserByName(bindings)
        .selectFields(fields)
        .setCondition(condition)
        .executeQuery();
      if (matchedUsers.isEmpty()) {
        return 'False';
      }
      User matchedUser = matchedUsers[0];
      if (matchedUser.Profile.Name == 'RC Partner Modify') {
        primary.put(
          'LeadPartnerID__c',
          matchedUser.Contact.Account.Partner_Id__c
        );
        primary.put(
          'Inside_Sales_Rep__c',
          matchedUser.Contact.Account.Inside_Sales_Rep__c
        );
        primary.put('Partner_Lead_Owner__c', matchedUser.Id);
        primary.put('Partner_Lead_Source__c', 'RingCentral');
        primary.put(
          'RecordTypeId',
          Schema.Sobjecttype.Lead.getRecordTypeInfosByName()
            .get('Partner Leads')
            .getRecordTypeId()
        );
        primary.put(
          'Partner_Account_Name__c',
          matchedUser.Contact.Account.Name
        );
        primary.put(
          'Ultimate_Parent_Account_Partner_ID__c',
          matchedUser.Contact.Account.Ultimate_Parent_Partner_ID__c
        );
        primary.put(
          'Ultimate_Parent_Account_Name__c',
          matchedUser.Contact.Account.Ultimate_Parent_Account_Name__c
        );
        primary.put(
          'VAR_Territory__c',
          matchedUser.Contact.Account.VAR_Territory__c
        );
        if (matchedUser.Profile.Name != 'RC Partner Modify') {
          primary.put('OwnerId', matchedUser.Id);
        } else if (
          matchedUser.Contact.Account.Current_Owner__r.IsActive == true
        ) {
          primary.put('OwnerId', matchedUser.Contact.Account.Current_Owner__c);
        } else {
          primary.put('OwnerId', varUser.Id);
        }
      } else {
        primary.put('OwnerId', matchedUser.Id);
      }
      return 'Next Node';
    }

    // REMOVED: The commented-out field mapping code (confirmed not in use)
    
    return 'Next Node';
  }

  // ========================================
  // ADD: Required methods for v1.623 Flow Builder UI
  // ========================================
  
  // Makes dropdown options appear in LeanData Flow Builder
  global override Map<String, List<String>> getMapOfCustomInterfaceNodeNamesToEdges(){
    Map<String, List<String>> customInterfaceMap = new Map<String, List<String>>();
    customInterfaceMap.put('Activity Based Routing', new List<String>{'Next Node','False'});
    customInterfaceMap.put('Glip Webhook Alert', new List<String>{'Next Node','False'});
    customInterfaceMap.put('Custom Merge', new List<String>{'Next Node','False'});
    customInterfaceMap.put('Future Glip Notification', new List<String>{'Next Node','False'});
    customInterfaceMap.put('Send Glip Notification', new List<String>{'Next Node','False'});
    customInterfaceMap.put('Sales Agent Email Routing', new List<String>{'Next Node','False'});
    return customInterfaceMap;
  }

  // Creates parameter input fields in LeanData Flow Builder
  global override Map<String,Object> additionalParametersMap() {
    Map<String,Object> additionalParameters = new Map<String,Object>();
    additionalParameters.put('Glip Webhook Alert', new List<String>{'Endpoint URL'});
    additionalParameters.put('Future Glip Notification', new List<String>{'Template Id'});
    additionalParameters.put('Send Glip Notification', new List<String>{'Template Id'});
    return additionalParameters;
  }

  // ========================================
  // KEEP: All existing supporting methods
  // ========================================
  
  global override Set<String> getCustomLeadFields() {
    Set<String> customFields = new Set<String>();
    for (
      LeanDataPostFields__mdt record : LeanDataPostFields__mdt.getAll().values()
    ) {
      customFields.add(record.FieldName__c);
    }
    return customFields;
  }

  public String generateLeadJson(SObject lead) {
    Set<String> fieldsToInclude = getCustomLeadFields();
    Map<String, Object> leadData = new Map<String, Object>();
    for (String field : fieldsToInclude) {
      leadData.put(field, lead.get(field));
    }
    String jsonPayload = JSON.serialize(leadData);
    return jsonPayload;
  }

  public class SendRestRequestJob implements Queueable, Database.AllowsCallouts {
    private String endpointUrl;
    private String payload;

    public SendRestRequestJob(String endpointUrl, String payload) {
      this.endpointUrl = endpointUrl;
      this.payload = payload;
    }

    public void execute(QueueableContext context) {
      HttpResponse response;
      try {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);
        Http http = new Http();
        response = http.send(request);

        if (response.getStatusCode() >= 400) {
          ExceptionHelper.createExceptionAndNotificacionHistoryForIntegration(
            response,
            'Lead Exception'
          );
        }
      } catch (Exception e) {
        if (response != null) {
          ExceptionHelper.createExceptionAndNotificacionHistoryForIntegration(
            response,
            'Lead Exception'
          );
        }
      }
    }
  }
}