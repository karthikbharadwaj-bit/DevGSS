@isTest
private class Test_BatchJob_UpdateZICustomerAccounts {
  @TestSetup
  static void setupTestData() {
    List<Account> parentAccounts = new List<Account>();
    for (Integer i = 0; i < 5; i++) {
      parentAccounts.add(
        (Account) new SObjectBuilder(Account.SObjectType)
          .setField(Account.Name, 'Parent Account ' + i)
          .setField(
            Account.RecordTypeId,
            getRecordTypeId('ZI Customer Shell Account')
          )
          .setField(Account.Is_EVA_Processed__c, false)
          .setField(Account.EVA_Journey_Stage_Date__c, Date.today())
          .create()
          .getRecord()
      );
    }
    List<Account> childAccounts = new List<Account>();
    for (Account parent : parentAccounts) {
      childAccounts.add(
        (Account) new SObjectBuilder(Account.SObjectType)
          .setField(Account.Name, 'Child Account for ' + parent.Name)
          .setField(Account.ParentId, parent.Id)
          .setField(Account.RecordTypeId, getRecordTypeId('Customer Account'))
          .setField(Account.EVA_Journey__c, 'Unaware')
          .setField(Account.EVA_Awareness_Score__c, 10)
          .create()
          .getRecord()
      );
    }
    BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
    setting.Name = 'BatchJob_UpdateZICustomerAccounts';
    setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
    insert setting;
  }
  @isTest
  static void testBatchJobUpdateZICustomerAccounts() {
    Test.startTest();
    BatchJob_UpdateParentZICustomerAccounts batchJob = new BatchJob_UpdateParentZICustomerAccounts();
    Database.executeBatch(batchJob, 200);
    Test.stopTest();
    List<Account> parentAccounts = (List<Account>) new AccountSelector()
      .selectAccountsWithSpecificRecordType(
        new List<Object>{ 'ZI Customer Shell Account' }
      )
      .selectFields(
        new List<String>{
          'Id',
          'EVA_Journey__c',
          'EVA_Awareness_Score__c',
          'EVA_RNG_EX_Score__c',
          'EVA_RNG_CX_Score__c',
          'EVA_RNG_Sense_Score__c',
          'EVA_RNG_Events_Score__c',
          'Eva_RNG_RC_Intent_Score__c',
          'Eva_RNG_External_Intent_Score__c',
          'EVA_Journey_Classification__c',
          'EVA_Journey_Stage_Date__c'
        }
      )
      .executeQuery();
    List<Account> childAccounts = (List<Account>) new AccountSelector()
      .selectAccountsWithSpecificRecordType(
        new List<Object>{ 'Customer Account' }
      )
      .selectFields(
        new List<String>{
          'Id',
          'ParentId',
          'EVA_Journey__c',
          'EVA_Awareness_Score__c',
          'EVA_RNG_EX_Score__c',
          'EVA_RNG_CX_Score__c',
          'EVA_RNG_Sense_Score__c',
          'EVA_RNG_Events_Score__c',
          'Eva_RNG_RC_Intent_Score__c',
          'Eva_RNG_External_Intent_Score__c',
          'EVA_Journey_Classification__c',
          'EVA_Journey_Stage_Date__c'
        }
      )
      .executeQuery();
    Map<Id, Account> parentMap = new Map<Id, Account>();
    for (Account parent : parentAccounts) {
      parentMap.put(parent.Id, parent);
    }
    for (Account child : childAccounts) {
      Account parent = parentMap.get(child.ParentId);
      if (parent != null) {
        System.assertEquals(
          parent.EVA_Journey__c,
          child.EVA_Journey__c,
          'EVA_Journey__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_Awareness_Score__c,
          child.EVA_Awareness_Score__c,
          'EVA_Awareness_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_RNG_EX_Score__c,
          child.EVA_RNG_EX_Score__c,
          'EVA_RNG_EX_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_RNG_CX_Score__c,
          child.EVA_RNG_CX_Score__c,
          'EVA_RNG_CX_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_RNG_Sense_Score__c,
          child.EVA_RNG_Sense_Score__c,
          'EVA_RNG_Sense_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_RNG_Events_Score__c,
          child.EVA_RNG_Events_Score__c,
          'EVA_RNG_Events_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.Eva_RNG_RC_Intent_Score__c,
          child.Eva_RNG_RC_Intent_Score__c,
          'Eva_RNG_RC_Intent_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.Eva_RNG_External_Intent_Score__c,
          child.Eva_RNG_External_Intent_Score__c,
          'EVA_External_Intent_Score__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_Journey_Classification__c,
          child.EVA_Journey_Classification__c,
          'EVA_Journey_Classification__c should match parent value.'
        );
        System.assertEquals(
          parent.EVA_Journey_Stage_Date__c,
          child.EVA_Journey_Stage_Date__c,
          'EVA_Journey_Stage_Date__c should match parent value.'
        );
      }
    }
  }
  @isTest
  static void testSendCompletionEmail() {
    AsyncApexJob mockJob = new AsyncApexJob();
    BatchJob_UpdateParentZICustomerAccounts batchJob = new BatchJob_UpdateParentZICustomerAccounts();
    Test.startTest();
    batchJob.sendCompletionEmail(mockJob);
    Integer emailInvocations = Limits.getEmailInvocations();
    System.assertEquals(1, emailInvocations, 'An email should be sent');
    Test.stopTest();
  }
  @isTest
  static void testGenerateErrorLogAttachment() {
    BatchJob_UpdateParentZICustomerAccounts batchJob = new BatchJob_UpdateParentZICustomerAccounts();
    batchJob.errorLogs.add('00123,Error 1');
    batchJob.errorLogs.add('00456,Error 2');
    Messaging.EmailFileAttachment attachment = batchJob.generateErrorLogAttachment();
    System.assertEquals(
      'ErrorLog.csv',
      attachment.getFileName(),
      'The file name should be ErrorLog.csv'
    );
    String expectedContent = 'AccountId,Error\n00123,Error 1\n00456,Error 2\n';
    String actualContent = attachment.getBody().toString();
    System.assertEquals(
      expectedContent,
      actualContent,
      'The content of the attachment is incorrect'
    );
    batchJob.errorLogs.clear();
    attachment = batchJob.generateErrorLogAttachment();
    expectedContent = 'AccountId,Error\n';
    actualContent = attachment.getBody().toString();
    System.assertEquals(
      expectedContent,
      actualContent,
      'The content should be only the header when there are no error logs'
    );
  }
  private static Id getRecordTypeId(String recordTypeName) {
    return Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordTypeName)
      .getRecordTypeId();
  }
}