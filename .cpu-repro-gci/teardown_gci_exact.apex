Id runUserId = '005Ot00000tJey9IAC';

List<Case> runCases = [
    SELECT Id FROM Case
    WHERE Subject LIKE '[LOADTEST] Customer Feedback RCINT-LT-%'
    AND CreatedById = :runUserId
];
if (!runCases.isEmpty()) delete runCases;

List<Contact> runContacts = [
    SELECT Id FROM Contact
    WHERE FirstName = 'Case Contact'
    AND Email = 'contact.loadtest@ringcentral.com'
    AND CreatedById = :runUserId
];
if (!runContacts.isEmpty()) delete runContacts;

List<Account> runAccounts = [
    SELECT Id FROM Account
    WHERE Name LIKE '[LOADTEST] Account RCINT-LT-%'
    AND CreatedById = :runUserId
];
if (!runAccounts.isEmpty()) delete runAccounts;

List<JIRA_Case__c> runJiraCases = [
    SELECT Id FROM JIRA_Case__c
    WHERE Name LIKE 'RCINT-LT-%'
    AND Assignee_Email__c = 'jira.loadtest@ringcentral.com'
    AND CreatedById = :runUserId
];
if (!runJiraCases.isEmpty()) delete runJiraCases;

System.debug('CLEANUP|cases=' + runCases.size()
    + '|contacts=' + runContacts.size()
    + '|accounts=' + runAccounts.size()
    + '|jiraCases=' + runJiraCases.size());
