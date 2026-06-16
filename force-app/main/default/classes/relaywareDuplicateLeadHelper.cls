/*
* Name         : relaywareDuplicateLeadHelper.cls
* Created By   : Golovanov Fedor (fgolovanov@newmarketinc.com) 
* Created Date : 1/September/2016
* Description  : Check if new lead is already exists on the org (based on the email addresss), if yes delete, create a case and send email to the partner.
* Dependencies : No
*/
public with sharing class relaywareDuplicateLeadHelper {
    
    // Map contains the emails for already existing leads or contacts
    public static Map<String, sObject> alreadyExistedEmails = new Map<String, sObject>();

    // Contains partner Account record ids
    public static Set<Id> partnerAccountIds = new Set<Id>();

    // Getting existing Default Private Indicidual Org Settings
    public static Relayware_Duplicate_Settings__c settings = Relayware_Duplicate_Settings__c.getOrgDefaults();

    public class CheckDuplicates extends Triggers.TriggerHandlerBase {
        override public void handle(){
               
            //Get emails from the incoming leads
            for (Lead l : (List<Lead>)trigger.new){
                if(l.Email != null){
                    alreadyExistedEmails.put(l.Email, null);
                }
            }

            //Check existing records for the same email
            alreadyExistedEmails = CheckObjects(alreadyExistedEmails, 'Lead');
            alreadyExistedEmails = CheckObjects(alreadyExistedEmails, 'Contact');

            //Mark Lead to be deleted and populate context varaible to skip before trigger logic 
            for (Lead l : (List<Lead>)trigger.new){
                if(alreadyExistedEmails.get(l.Email) != null){
                    l.Relayware_duplicate_delete__c = true;
                    partnerAccountIds.add(l.Partner_Account__c);
                }else{
                    alreadyExistedEmails.remove(l.Email);
                }
            }

            //Remove nulls if partner account is not populated
            partnerAccountIds.remove(null);    
        }   
    }

    //Query for the existing sObjects with the same emails
    public static Map<String, sObject> CheckObjects(Map<String, sObject> contextEmails, String sObj) {
            
            Set<String> keys = contextEmails.keySet();
            String q = 'SELECT Id, Email' + (sObj == 'Contact' ? ', AccountId' : '') + ' FROM ' + sObj + ' WHERE Email IN : keys';
            for(sObject obj: Database.query(q)){
                //Prevent adding new record if one is already found
                if(alreadyExistedEmails.get((String)obj.get('Email')) == null){
                    alreadyExistedEmails.put((String)obj.get('Email'), obj);
                }
            }

            return alreadyExistedEmails;
    }

}