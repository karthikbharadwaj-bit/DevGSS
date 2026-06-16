global class Batch_populateWaveforAccount  implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id,RC_Upgrade_Date__c,RC_Account_Status__c, wave__c from Account WHERE (RC_Account_Status__c = 'Paid' and RC_Upgrade_Date__c != null)]); 
    }
    global void execute(Database.BatchableContext BC, List<Account> accList){
        List<Medallia_Survey_schedule__mdt> msList = Medallia_Survey_schedule__mdt.getAll().values(); 
        List<Account> accountList = new List<Account>();    
        for (Account acc: accList){  
                Integer Paidmonth = acc.RC_Upgrade_Date__c.month();
                for(Medallia_Survey_schedule__mdt ms:msList)
                {
                    if(paidmonth >= ms.MonthRange1__c && paidmonth <= ms.MonthRange2__c && acc.wave__c != ms.label)
                    {
                        acc.wave__c = ms.label;
                        accountList.add(acc);
                    }
                }                  
        }  
if(accountList.size() >  0)
        {
            Triggers.switchOff();
            update accountList;
            Triggers.switchOn();
        }       
    }
    global void finish(Database.BatchableContext BC) {
        
        
    } 
}