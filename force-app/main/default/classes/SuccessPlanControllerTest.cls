@isTest
Private with sharing class SuccessPlanControllerTest {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void validateSuccessPlanController() 
        {
            Id partnerAccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
            Id customerAccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
            Account acc1 = New Account();
            acc1.name='Valid Test Account';
            acc1.Partner_ID__c='11224466';
            acc1.Partner_Type__c='General Partner';
            acc1.recordtypeId= partnerAccRecId;
            insert acc1;
            
            Account acc2 = New Account();
            acc2.name='Invalid Test Account2';
            acc2.Partner_Type__c='Public Sector';
            acc2.recordtypeId= customerAccRecId;
            insert acc2;
            
            Success_Plan__c sucPln2 = new Success_Plan__c();
            sucPln2.Account__c=acc2.Id;
            sucPln2.Partner_Persona_Job_Aid__c='www.google.com';
            sucPln2.RBE_Notes__c='RBE Tips Notes2';
            insert sucPln2;

            SuccessPlanController.canDisplayGenerateButton(acc1.Id);
            SuccessPlanController.canGenerateSuccessPlan(acc1.Id);
            SuccessPlanController.insertSucessPlanAndActivities(acc1.Id);
            
            Success_Plan__c sucPln = [SELECT Id, RBE_Notes__c, Partner_Readiness_Score__c FROM success_plan__c where account__c= :acc1.Id];
            List<SuccessPlanActivity__c> sucPlnActs = new List<SuccessPlanActivity__c>();

            SuccessPlanActivity__c sucPlnAct1 = new SuccessPlanActivity__c();
            sucPlnAct1.SuccessPlan__c=sucPln.Id;
            sucPlnAct1.ActivityName__c='Test Activity1';
            sucPlnAct1.Stage__c='30';
            sucPlnAct1.PartnerReadinessScore__c=5;
            sucPlnAct1.What_do_you_need_to_do__c='testing1';
            sucPlnActs.add(sucPlnAct1);

            SuccessPlanActivity__c sucPlnAct2 = new SuccessPlanActivity__c();
            sucPlnAct2.SuccessPlan__c=sucPln.Id;
            sucPlnAct2.ActivityName__c='Test Activity1';
            sucPlnAct2.Stage__c='60';
            sucPlnAct2.PartnerReadinessScore__c=15;
            sucPlnAct2.What_do_you_need_to_do__c='testing2 testing2';
            sucPlnActs.add(sucPlnAct2);

            SuccessPlanActivity__c sucPlnAct3 = new SuccessPlanActivity__c();
            sucPlnAct3.SuccessPlan__c=sucPln.Id;
            sucPlnAct3.ActivityName__c='Test Activity1';
            sucPlnAct3.Stage__c='60';
            sucPlnAct3.PartnerReadinessScore__c=10;
            sucPlnAct3.What_do_you_need_to_do__c='testing3 testing3';
            sucPlnActs.add(sucPlnAct3);

            insert sucPlnActs;
            SuccessPlanController.canDisplayGenerateButton(acc1.Id);
            SuccessPlanController.canGenerateSuccessPlan(acc1.Id);
            SuccessPlanController.getSuccessPlan(acc1.Id);
            SuccessPlanController.getSuccessPlanWire(acc1.Id);
            SuccessPlanController.hasSuccessPlanProfiles();
            SuccessPlanController.isEditable();
            SuccessPlanController.getSuccessPlanActivityRecords(acc1.Id, '30');
            SuccessPlanController.getSuccessPlanActivityRecords(acc1.Id, '60');
            SuccessPlanController.getSuccessPlanActivityRecords(acc1.Id, '90');
            SuccessPlanController.saveDraftValues(sucPlnActs);
            SuccessPlanController.checkNegativeScenario(acc2.Id);
            SuccessPlanController.checkNegativeScenario(acc1.Id);
            
            User user1 =[select id, Name from user where isactive=true and Profile.Name='Sales Operations Lightning' Limit 1];
            Test.startTest();
            System.runAs(user1)
            {
            	SuccessPlanController.hasSuccessPlanProfiles();
            	SuccessPlanController.isEditable();
                
                User user2 =[select id, Name from user where isactive=true and Profile.Name='Support T1' Limit 1];
                System.runAs(user2)
            	{
            	SuccessPlanController.hasSuccessPlanProfiles();
            	}
 
            }
            Test.stopTest();
        }
}