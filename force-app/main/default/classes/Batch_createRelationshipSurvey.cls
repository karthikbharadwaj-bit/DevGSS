/* 
*Class Name         : Batch_createRelationshipSurvey
*Business Purpose   : Send Invitation to Medallia for Relationship Survey
*Developer Name     : Elakkiya Natarajan
Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
24/02/2022                                      Elakkiya                          New Batch Class
*/
global class Batch_createRelationshipSurvey implements Database.Batchable<sObject>{
    public final String Query; 
    public Batch_createRelationshipSurvey(){
       Query = 'SELECT Id, RC_Account_Status__c, Main_point_of_contact__c,SegmentName__c, RC_Signup_Date__c, RC_Upgrade_Date__c, Primary_Contact_Fields_Medallia__c, RC_Service_name__c,wave__c,RC_Brand__c '
            +' FROM Account'
            +' WHERE (RC_Account_Status__c = \'Paid\' and RC_Upgrade_Date__c != null and wave__c != null)';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(Query);
    }
    global void execute(Database.BatchableContext BC, List<Account> accList){
		 List<String> ContactRoles = System.label.Contact_Roles.split(',');

        List<Medallia_Invitation__mdt> medList = Medallia_Invitation__mdt.getAll().values();  
        List<Medallia_Invitation__mdt> medAccList = new List<Medallia_Invitation__mdt>();
        List<AccountContactRole> acrList = new List<AccountContactRole>();
         List<Contact>  contactList = new List<Contact>();
        Map<Id, Medallia_Invitation__mdt> invitationMap = new Map<Id, Medallia_Invitation__mdt>();
        Map<String,Medallia_Region__mdt> regionTimings = new Map<String,Medallia_Region__mdt>();
        Map<Id, Datetime> dateToSendMap = new Map<Id, Datetime>();
        Map<String, Medallia_Survey_schedule__mdt> scheduleMap = new Map<String, Medallia_Survey_schedule__mdt>();
        Map<Id, Id> conAcctMap = new Map<Id, Id>();
        Map<Id, list<AccountContactRole>> acrmap = new Map<Id,list<AccountContactRole>>();
		set<Id> accIdset = new set<Id>();
        
        try
        {
        if (medList.size() > 0){
            for(Medallia_Invitation__mdt med : medList){
                if(med.DeveloperName == 'Relationship_Survey'){
                    medAccList.add(med);
                }
            }
        }

        for(Medallia_Region__mdt mr :Medallia_Region__mdt.getAll().values() ){
            for(String s : mr.RC_Service_Name__c.split(',')){
                regionTimings.put(s,mr);
            }
        }
        for(Medallia_Survey_schedule__mdt mr :Medallia_Survey_schedule__mdt.getAll().values() ){
            scheduleMap.put(mr.label,mr);
        }
         
        for (Account acc: accList){
            accIdset.add(acc.Id);
        }
        
        if(!accIdset.isEmpty())
        {
        acrList = [SELECT ContactId, Role, IsPrimary,AccountId FROM AccountContactRole  WHERE (Role IN :ContactRoles OR IsPrimary = true) AND Contact.Email != null AND AccountId in :accIdset];
        contactList = [SELECT Id,AccountId, email FROM Contact WHERE email != null and AccountId in :accIdset];
        }
        for(AccountContactRole acr:acrList)
        {
            if(acrmap.containskey(acr.AccountId))
            {
                acrmap.get(acr.AccountId).add(acr);
            }
            else
            {
                acrmap.put(acr.AccountId,new LisT<AccountContactRole>{acr});
            }
        }
        for(Contact c: contactList){
            conAcctMap.put(c.Id, c.AccountId);
        }
        for (Account a: accList){
            for (Medallia_Invitation__mdt m : medAccList){
                if(DateTime.now() > a.RC_Upgrade_Date__c.addMonths(Integer.valueOf(m.Months__c)) &&  !schedulemap.isEmpty() && a.wave__c != null && schedulemap.containsKey(a.wave__c)){
                    if(scheduleMap.get(a.Wave__c).Batch_Schedule__c.contains(Datetime.now().format('MMMM')) || test.isRunningTest()) { // Check if the custom data schedule contains current month 
                        List<String> statusList = m.Status__c != null ? m.Status__c.split(',') : new List<String>();
                        List<String> rcServiceList = m.Exclude_RC_Service__c != null ? m.Exclude_RC_Service__c.split(',') : new List<String>();
                        List<String> rcBrandList = m.Exclude_RC_Brand__c != null ? m.Exclude_RC_Brand__c.split(',') : new List<String>();
                        List<String> segmentList = m.Segment_Name__c != null ? m.Segment_Name__c.split(','): new List<String>();
                        Boolean isAccBrandInvalid = false;
                        for(String brand : rcBrandList) {
                            if (a.RC_Brand__c!= null && a.RC_Brand__c.contains(brand)) {
                                isAccBrandInvalid = true;
                                break;
                            }
                        }
                        if(statusList.contains(a.RC_Account_Status__c) && !rcServiceList.contains(a.RC_Service_name__c) && !isAccBrandInvalid && segmentList.contains(a.SegmentName__c)){
                            Date sendDate = system.today();
                            Time sendTime;
                            DateTime sendDateTime;
                            if(regionTimings!=null && regionTimings.size()>0 && regionTimings.get(a.RC_Service_name__c)!=null ){                               
                               	sendDate = sendDate.addDays((Integer)regionTimings.get(a.RC_Service_name__c).GMT_Days__c);
                                sendTime = Time.newInstance((Integer)regionTimings.get(a.RC_Service_name__c).GMT__c, 0, 0, 0).addMinutes(-30);
                            }else if(regionTimings!=null && regionTimings.size()>0) {
                                sendDate = sendDate.addDays((Integer)regionTimings.get('Default').GMT_Days__c);
                                sendTime = Time.newInstance((Integer)regionTimings.get('Default').GMT__c, 0, 0, 0).addMinutes(-30);
                            }
                            
                            sendDateTime = DateTime.newInstanceGMT(sendDate, sendTime); 

                            if (acrmap != null && !acrmap.isEmpty() && acrmap.get(a.Id) != null) {
                                for (AccountContactRole acr : acrmap.get(a.Id)){
                                    if(conAcctMap.containsKey(acr.ContactId) && conAcctMap.get(acr.ContactId) == a.Id){
                                            invitationMap.put(acr.ContactId, m);
                                            dateToSendMap.put(acr.ContactId, sendDateTime);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
            system.debuG('Test6'+invitationMap+dateToSendMap);
            if(invitationMap!=null && !invitationMap.isEmpty() && dateToSendMap!=null && !dateToSendMap.isEmpty()){
                MedalliaSurveyHelper.processMedalliaInvitation(invitationMap, dateToSendMap);
            }
        }
        catch(Exception ex) {
            throw new BatchJobQueueException(ex.getMessage());
        }
    } 
    global void finish(Database.BatchableContext BC) {
    }
}