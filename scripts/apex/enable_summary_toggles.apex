// Enable Account and Opportunity Summary toggles for named users on GCP_Feature_Toggle__c.
// Checks for an existing USER-LEVEL row per user: updates it if present, creates it if not.
// Run: sf apex run --file scripts/apex/enable_summary_toggles.apex --target-org <ALIAS>
// Dry run by default. Set isDryRun = false to apply.
Boolean isDryRun = true;

List<String> emails = new List<String>{
    'andy.voso@ringcentral.com', 'bill.farmer@ringcentral.com', 'carie.conner@ringcentral.com',
    'caroline.craycraft@ringcentral.com', 'claude.giorgio@ringcentral.com', 'daniel.weiss@ringcentral.com',
    'david.chao@ringcentral.com', 'greg.giannell@ringcentral.com', 'jeff.robinson@ringcentral.com',
    'kelli.silver@ringcentral.com', 'mike.deer@ringcentral.com', 'ramon.largaespada@ringcentral.com',
    'raychel.barfield@ringcentral.com', 'sam.miller@ringcentral.com'
};

Map<String, User> emailToUserMap = new Map<String, User>();
for (User u : [
    SELECT Id, Name, Username, Email, IsActive, Profile.Name
    FROM User
    WHERE UserType = 'Standard' AND (Username IN :emails OR Email IN :emails)
    ORDER BY IsActive ASC
]) {
    String key = emails.contains(u.Username.toLowerCase()) ? u.Username.toLowerCase() : u.Email.toLowerCase();
    emailToUserMap.put(key, u); // ascending IsActive means an active user overwrites an inactive one
}

Set<Id> userIds = new Map<Id, User>(emailToUserMap.values()).keySet();
Map<Id, GCP_Feature_Toggle__c> ownerToRowMap = new Map<Id, GCP_Feature_Toggle__c>();
for (GCP_Feature_Toggle__c row : [
    SELECT Id, SetupOwnerId, Enable_Account_Summary__c, Enable_Account_Summary_Enrichment__c,
        Enable_Opportunity_Summary__c, Enable_Opportunity_Summary_Enrichment__c,
        Account_Summary_Call_Transcripts__c, Opportunity_Summary_Call_Transcripts__c
    FROM GCP_Feature_Toggle__c
    WHERE SetupOwnerId IN :userIds
]) {
    ownerToRowMap.put(row.SetupOwnerId, row);
}

List<GCP_Feature_Toggle__c> toInsert = new List<GCP_Feature_Toggle__c>();
List<GCP_Feature_Toggle__c> toUpdate = new List<GCP_Feature_Toggle__c>();
for (String email : emails) {
    User u = emailToUserMap.get(email);
    if (u == null) {
        System.debug('NOT FOUND: ' + email);
        continue;
    }
    GCP_Feature_Toggle__c existing = ownerToRowMap.get(u.Id);
    GCP_Feature_Toggle__c row = existing == null
        ? new GCP_Feature_Toggle__c(SetupOwnerId = u.Id)
        : new GCP_Feature_Toggle__c(Id = existing.Id);
    row.Enable_Account_Summary__c = true;
    row.Enable_Account_Summary_Enrichment__c = true;
    row.Enable_Opportunity_Summary__c = true;
    row.Enable_Opportunity_Summary_Enrichment__c = true;
    row.Account_Summary_Call_Transcripts__c = true;
    row.Opportunity_Summary_Call_Transcripts__c = true;
    System.debug(u.Name + ' | ' + u.Profile.Name + ' | active=' + u.IsActive + ' | '
        + (existing == null ? 'CREATE' : 'UPDATE, before: acct=' + existing.Enable_Account_Summary__c
            + ' acctEnrich=' + existing.Enable_Account_Summary_Enrichment__c
            + ' opp=' + existing.Enable_Opportunity_Summary__c
            + ' oppEnrich=' + existing.Enable_Opportunity_Summary_Enrichment__c
            + ' acctTranscripts=' + existing.Account_Summary_Call_Transcripts__c
            + ' oppTranscripts=' + existing.Opportunity_Summary_Call_Transcripts__c));
    if (existing == null) {
        toInsert.add(row);
    } else {
        toUpdate.add(row);
    }
}

if (isDryRun) {
    System.debug('DRY RUN: ' + toInsert.size() + ' to create, ' + toUpdate.size() + ' to update.');
} else {
    List<Database.SaveResult> results = new List<Database.SaveResult>();
    results.addAll(Database.insert(toInsert, false));
    results.addAll(Database.update(toUpdate, false));
    for (Database.SaveResult result : results) {
        System.debug(result.isSuccess() ? 'OK ' + result.getId() : 'FAILED ' + result.getErrors());
    }
}
