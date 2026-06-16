/**********************************************************************************************************
Created By:     eugenebasianomutya
Created Date:   10182016
Description:    Trigger Handler Ext of Resource Object
**********************************************************************************************************/

public with sharing class ResourceTriggerHandlerExt{

    public void UpdateProjectLoE(set<Id> sProjectIds){

        map<Id,Project__c> mProjectToUpdate = new  map<Id,Project__c>();
        Boolean isBDev;

        map<Id,Boolean> mProjDev = new map<Id,Boolean>();


        for(Resources__c r : [SELECT Id, Project__c, Q1__c, Q2__c, Q3__c, Q4__c, Project_Delivery_Qtr__c, Type__c FROM Resources__c WHERE Project__c IN: sProjectIds]){
            
            string sPrjQtr = r.Project_Delivery_Qtr__c;
            Decimal Qtr = 0;

            // Case 05265380 - START
            
            /*if(sPrjQtr.contains('Q1')){Qtr = r.Q1__c;}
            if(sPrjQtr.contains('Q2')){Qtr = r.Q2__c;}
            if(sPrjQtr.contains('Q3')){Qtr = r.Q3__c;}
            if(sPrjQtr.contains('Q4')){Qtr = r.Q4__c;}*/

            Qtr = r.Q1__c + r.Q2__c + r.Q3__c + r.Q4__c;
            // Case 05265380 -  - END

            
            if(Qtr < 0){
                Qtr = Qtr * (-1);
            }

            if(r.Type__c == 'SFDC Dev'){
                mProjDev.put(r.Project__c, True);
            }

            isBDev = mProjDev.get(r.Project__c) == true ? True: False;            

            if(mProjectToUpdate.size()<=0 || !mProjectToUpdate.containsKey(r.Project__c)){
                mProjectToUpdate.put(r.Project__c, new Project__c(Id = r.Project__c, LoE_Estimate__c = True, LoE__c = Qtr,  Dev__c = isBDev));
            }else{
                Decimal QtrNew = mProjectToUpdate.get(r.Project__c).LoE__c + Qtr;
                mProjectToUpdate.put(r.Project__c, new Project__c(Id = r.Project__c, LoE_Estimate__c = True, LoE__c = QtrNew, Dev__c = isBDev));
            }
        }  

        for(Id ProjId: sProjectIds){
            if(mProjectToUpdate.get(ProjId) == NULL ){
                mProjectToUpdate.put(ProjId, new Project__c(Id = ProjId, LoE_Estimate__c = false, LoE__c = 0));
            }
        }

        if(mProjectToUpdate.size()>0){                           
            database.update(mProjectToUpdate.values(), false);      
        }
    }
}