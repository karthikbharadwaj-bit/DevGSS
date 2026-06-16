/*
* Name         : PostCopyEmailsClean.cls
* Created By   : Alexander Savickiy (asavickiy@aquivalabs.com)
* Created Date : 22/February/2018
* Description  : Clean email addresses in Emails__c custom setting. Part of the Sandbox Post Copy framework.
* Dependencies : PostCopyWorker.cls
*/

public with sharing class PostCopyEmailsClean extends PostCopyWorker{
    public override String getClassName(){
        return PostCopyEmailsClean.class.getName();
    }
    //Erase email addresses
    public override void run() {
        List <Emails__c> emailsToUpdate = new List <Emails__c>();
        List<Emails__c> emailsCustomSettingRecords = Emails__c.getall().values();
        for (Emails__c email : emailsCustomSettingRecords) {
            email.Email_Address__c = null;
            emailsToUpdate.add(email);
        }
        //Update Emails__c custom settings
        Database.SaveResult[] emailsUpdate =  Database.update(emailsToUpdate, false);
        PostCopyUtil.handleSaveResults(emailsUpdate);
    }
}