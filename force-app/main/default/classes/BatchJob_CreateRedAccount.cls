global class BatchJob_CreateRedAccount implements Database.Batchable<sObject>, Schedulable {

    public DateTime fromDate;
    public DateTime toDate;
    
    
    global void execute(SchedulableContext sc) {
        Database.executebatch(new BatchJob_CreateRedAccount(fromDate, toDate));
    }
    
    public BatchJob_CreateRedAccount (DateTime pFromDate, DateTime pToDate){
        fromDate = pFromDate;
        toDate = pToDate;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([       
            SELECT Id, Account__c
            FROM Adoption_Model__c
            WHERE Overall_Risk_Score__c = 5
            AND LastModifiedDate >= :fromDate
            AND LastModifiedDate <= :toDate]);
    }

    global void execute(Database.BatchableContext bc, List<Adoption_Model__c> scope){
        Set<Id> acctSet = new Set<Id>();
        List<Red_Account__c> newRedAcc = new List<Red_Account__c>();
        
        for(Adoption_Model__c am : scope){
            acctSet.add(am.Account__c);
        }
        
        if(!acctSet.isEmpty()){     
            for(Red_Account__c redAcc: [
                SELECT Id, EscalatedAccount__c 
                  FROM Red_Account__c 
                  WHERE EscalatedAccount__c = :acctSet 
                  AND Status__c != 'Resolved - Saved' 
                  AND Status__c != 'Resolved - Lost' 
                  AND Status__c != 'Resolved – Downgraded']){
                acctSet.remove(redAcc.EscalatedAccount__c);
            }
        }
        
        if(!acctSet.isEmpty()){
            for(Account acc: [SELECT Id, MRR__c FROM Account WHERE Id = :acctSet AND MRR__c >= 100 and CSM__c = null]){
                Red_Account__c redAcct = new Red_Account__c(
                    EscalatedAccount__c = acc.Id,
                    Revenue_at_Risk__c = acc.MRR__c,
                    Status__c = 'C360 Created',
                    Issue_Category__c = 'Contract',
                    Issue_Status__c = 'New'
                );
                newRedAcc.add(redAcct);
            }
        }
        
        if(!newRedAcc.isEmpty()){
            insert newRedAcc;
            sendEmailNotif(newRedAcc);
        }   
    }

    
    global void finish(Database.BatchableContext bc){

    }

    private void sendEmailNotif(List<Red_Account__c> newRedAcc){      
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        for(Red_Account__c newRedAccEmail : [SELECT Id, Name, EscalatedAccount__r.Name, EscalatedAccount__r.Owner.Name, EscalatedAccount__r.Owner.Email FROM Red_Account__c WHERE Id =: newRedAcc]){            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String[] toAddresses = new String[] {newRedAccEmail.EscalatedAccount__r.Owner.Email};
            mail.setToAddresses(toAddresses);
            
            mail.setReplyTo('atrisk@ringcentral.com');
            mail.setSenderDisplayName('At Risk Team');
            
            mail.setSubject('ALERT: one of your accounts may be at risk for cancellation');
            
            String body = 'Hello ' +  newRedAccEmail.EscalatedAccount__r.Owner.Name+ ',<br/><br/>';
            body += 'We have identified ' + newRedAccEmail.EscalatedAccount__r.Name + ' as high risk. Please review the flag <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + newRedAccEmail.Id + '">' + newRedAccEmail.Name + '</a>, and the account.<br/><br/>';
            body += 'To engage the At Risk team, change the status of the red account to <b>Cancel - 90%</b>.<br/><br/>';
            body += 'If this account has been flagged in error change the status of the red account to <b>Resolved - saved</b>. Please email CERT@ringcentral.com if you have any further questions.<br/><br/>';
            body += 'Thank you,<br/>';
            body += 'CERT At-Risk Team';
            mail.setHtmlBody(body);
            
            mails.add(mail);
        }       
            
        Messaging.sendEmail(mails);
    }
}