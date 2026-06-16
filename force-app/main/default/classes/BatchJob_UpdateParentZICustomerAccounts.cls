public without sharing class BatchJob_UpdateParentZICustomerAccounts implements Database.Batchable<SObject>, Database.stateful, Schedulable {
  private Integer recordsProcessed = 0;
  private Integer recordsFailed = 0;
  private boolean runParentAgain = false;
  @testVisible
  private List<String> errorLogs = new List<String>();
  private List<Id> parentsForReprocessing = new List<Id>();
  private Account parent;

  public BatchJob_UpdateParentZICustomerAccounts(List<Id> parentsForReprocessing) {
    this.parentsForReprocessing = parentsForReprocessing;
  }

  public BatchJob_UpdateParentZICustomerAccounts() {
    this.parentsForReprocessing = new List<Id>();
  }

  private void bypassAccountTriggers(Boolean bypass){
    TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = bypass;
    TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = bypass;
    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = bypass;  
    TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER = bypass;
    TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = bypass;
    TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = bypass;
    if(bypass){
        Triggers.switchOff();
    }
}

  public Database.QueryLocator start(Database.BatchableContext context) {
    if (!parentsForReprocessing.isEmpty()) {
      return new AccountSelector()
        .selectAccountsByIdNoFields(
          new List<Object>{ parentsForReprocessing }
        )
        .selectFields(new List<String>{
    'Id', 'Name', 'ParentId', 'EVA_Journey__c', 'EVA_Awareness_Score__c', 
    'EVA_RNG_EX_Score__c', 'EVA_RNG_CX_Score__c', 'EVA_RNG_Sense_Score__c', 
    'EVA_RNG_Events_Score__c', 'EVA_RNG_RC_Intent_Score__c', 
    'EVA_RNG_External_Intent_Score__c', 'EVA_Journey_Classification__c', 
    'Is_EVA_Processed__c', 'EVA_Journey_Stage_Date__c'})
        .executeQueryLocator();
    } else {
      return new AccountSelector()
      .selectAccountsWithSpecificRecordType(
        new List<Object>{ 'ZI Customer Shell Account' }
      )
      .executeQueryLocator();
    }
  }

  public void execute(
    Database.BatchableContext context,
    List<SObject> parentAccounts
  ) {
    Map<Id, Account> parentAccsMap = new Map<Id, Account>(
      (List<Account>) parentAccounts
    );
    List<Account> childAccounts = fetchChildAccounts(parentAccsMap.keySet());
    List<Account> parentAccountsToUpdate = new List<Account>();
    List<Account> childAccountsToUpdate = new List<Account>();
    Boolean hasChanges = false;
    Boolean isParentMapped = false;
    parent = parentAccsMap.values().get(0);
    Map<String, Object> parentFields = getParentFieldsMap(parent);
    if (parent != null && !parent.Is_EVA_Processed__c) {
      parent.Is_EVA_Processed__c = true;
      parentAccountsToUpdate.add(parent);
    }
    
    for (Account child : childAccounts) {
      if (runParentAgain) {
        break;
      }
      try {
        hasChanges = updateChildAccountFromParent(child, parent, parentFields);
        if (hasChanges) {
          if (childAccountsToUpdate.size() < 3000) {
            childAccountsToUpdate.add(child);
          } else {
            runParentAgain = true;
            parentsForReprocessing.add(parent.Id);
          }
        }
      } catch (Exception ex) {
        recordsFailed++;
        errorLogs.add(child.Id + ',' + ex.getMessage());
      }
    }

    saveResults(childAccountsToUpdate, parentAccountsToUpdate);
  }

  public void finish(Database.BatchableContext context) {
    AsyncApexJob jobDetails = fetchJobDetails(context.getJobId());
    sendCompletionEmail(jobDetails);
    if (runParentAgain) {
      Database.executeBatch(new BatchJob_UpdateParentZICustomerAccounts(parentsForReprocessing), 1);
    }
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new BatchJob_UpdateParentZICustomerAccounts(), 1);
  }

  private Map<String, Object> getParentFieldsMap(Account parent) {
    return new Map<String, Object>{
        'EVA_Journey__c' => parent.EVA_Journey__c,
        'EVA_Awareness_Score__c' => parent.EVA_Awareness_Score__c,
        'EVA_RNG_EX_Score__c' => parent.EVA_RNG_EX_Score__c,
        'EVA_RNG_CX_Score__c' => parent.EVA_RNG_CX_Score__c,
        'EVA_RNG_Sense_Score__c' => parent.EVA_RNG_Sense_Score__c,
        'EVA_RNG_Events_Score__c' => parent.EVA_RNG_Events_Score__c,
        'Eva_RNG_RC_Intent_Score__c' => parent.Eva_RNG_RC_Intent_Score__c,
        'EVA_RNG_External_Intent_Score__c' => parent.EVA_RNG_External_Intent_Score__c,
        'EVA_Journey_Classification__c' => parent.EVA_Journey_Classification__c,
        'EVA_Journey_Stage_Date__c' => parent.EVA_Journey_Stage_Date__c
    };
}

  private List<Account> fetchChildAccounts(Set<Id> parentIds) {
    return new AccountSelector()
      .selectAccountsWithSpecificRecordTypeAndParentId(
        new List<Object>{ 'Customer Account', parentIds }
      )
      .executeQuery();
  }

  private Boolean updateChildAccountFromParent(Account child, Account parent, Map<String, Object> parentFields) {
    Boolean hasChanges = false;
    if (parent != null) {
        for (String fieldName : parentFields.keySet()) {
            if (child.get(fieldName) != parentFields.get(fieldName)) {
                child.put(fieldName, parentFields.get(fieldName));
                hasChanges = true;
            }
        }
    }
    return hasChanges;
}

  private void saveResults(
    List<Account> childAccounts,
    List<Account> parentAccounts
  ) {
    bypassAccountTriggers(true);
    if (!childAccounts.isEmpty()) {
      handleSaveResults(Database.update(childAccounts, false), childAccounts);
    }
    if (!parentAccounts.isEmpty()) {
      handleSaveResults(Database.update(parentAccounts, false), parentAccounts);
    }
  }

  private void handleSaveResults(
    List<Database.SaveResult> results,
    List<Account> accounts
  ) {
    for (Integer i = 0; i < results.size(); i++) {
      if (results[i].isSuccess()) {
        recordsProcessed++;
      } else {
        for (Database.Error err : results[i].getErrors()) {
          errorLogs.add(accounts[i].Id + ',' + err.getMessage());
          recordsFailed++;
        }
      }
    }
  }

  private AsyncApexJob fetchJobDetails(Id jobId) {
    return (AsyncApexJob) new AsyncApexJobSelector()
      .selectBatchById(jobId)
      .selectField('JobItemsProcessed')
      .selectField('TotalJobItems')
      .selectField('NumberOfErrors')
      .selectField('CreatedBy.Email')
      .setQueryBindings(new List<Object>{ jobId })
      .executeQuery()[0];
  }

  @testVisible
  private void sendCompletionEmail(AsyncApexJob jobDetails) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setSubject('Batch Result for updateParentZICustomerAccounts');
    email.setToAddresses(getEmailAddresses());
    email.setHTMLBody(buildEmailBody(jobDetails));

    if (recordsFailed > 0) {
      Messaging.EmailFileAttachment attachment = generateErrorLogAttachment();
      email.setFileAttachments(
        new List<Messaging.EmailFileAttachment>{ attachment }
      );
    }

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }

  private String buildEmailBody(AsyncApexJob jobDetails) {
    String body = '<h3>Batch job updateParentZICustomerAccounts has finished. ' + (DateTime.Now()) +'</h3>\n' ;
    body += '<p>Job Id: ' + jobDetails.Id + ' </p>\n';
    body +=
      '<p>Jobs processed: ' +
      jobDetails.JobItemsProcessed +
      ' / ' +
      jobDetails.TotalJobItems +
      '</p>\n';
    body += 'Number of errors encountered: ' + jobDetails.NumberOfErrors + '\n';
    body += '<p>Total Accounts Processed: ' + recordsProcessed + '</p>\n';
    if (recordsFailed > 0) {
      body += 'Total number of records Failed: ' + recordsFailed + '\n';
      body += 'Please view attatched file for details';
    }
    return body;
  }

  @testVisible
  private Messaging.EmailFileAttachment generateErrorLogAttachment() {
    String csvContent = 'AccountId,Error\n';
    for (String errorLog : errorLogs) {
      csvContent += errorLog + '\n';
    }
    Blob csvBlob = Blob.valueOf(csvContent);
    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFileName('ErrorLog.csv');
    attachment.setBody(csvBlob);
    return attachment;
  }

  List<String> getEmailAddresses(){
    BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('BatchJob_UpdateZICustomerAccounts');
    List<String> emailsToSend = new List<String>();
    if (bjc != null && String.isNotBlank(bjc.ErrorEmailDistributionList__c)) {
        emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');
    }
    return emailsToSend;
  }
}