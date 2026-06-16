/*
* Name         : ImplementationTriggerHelper
* Created By   : Alexander Savickiy (asavickiy@aquivalabs.com)
* Created Date : 26/January/2018
* Description  : LegacyCodeProcessing.cls contains old legacy code
: Alexander Savickiy (asavickiy@aquivalabs.com) added ProfessionalServicesCheckBoxPopulation.cls
* Dependencies : No
*/



public class ImplementationTriggerHelper {
	public class LegacyCodeProcessing extends Triggers.TriggerHandlerBase {
		override public void handle() {
            // Flag to check if trigger is to be executed or not.
            if(TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE){
                System.debug('### RETURNED FROM IMPLEMENTATION BEFORE TRG ###');
                return;
            }else{
                System.debug('### STILL CONTINUE FROM IMPLEMENTATION BEFORE TRG ###');
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = true;
            }
            List<Implementation__c> newImplementations = (List<Implementation__c>) Trigger.new;
            Map<Id, Implementation__c> newImplementationsByIds = (Map<Id, Implementation__c>) Trigger.newMap;
            Map<Id, Implementation__c> oldImplementationsByIds = (Map<Id, Implementation__c>) Trigger.oldMap;
		    /* Below logic has been put in place to update the CC Sales Agent and CC Sales Agent Manager field on Implementation Record.
		    These fields are to be used to send out reminder emails for Implementation Appointment #implememtationScehduler. */
		    Set<Id> accountIdSet = new Set<Id>();
		    Map<Id,Account> accountMap;
		    for(Implementation__c implementVal : (List <Implementation__c>)Trigger.new) {
		        if(implementVal != null && implementVal.Account__c != null){
		            accountIdSet.add(implementVal.Account__c);
		        }
		    }
		    if(!accountIdSet.isEmpty()) {
		        accountMap = new Map<Id,Account>([SELECT Id,BillingCountry,RC_Brand__c,Most_Recent_Opportunity_Owner__r.Email,
		        										Most_Recent_Opportunity_Owner__r.Manager.Email,
		        										(SELECT Account__c, Implementation__c
		        										FROM Network_Informations__r)
		        								FROM Account
		        								WHERE Id IN :accountIdSet]);
		    }
		    for(Implementation__c thisRecord : (List <Implementation__c>)Trigger.new) {
		        /* Code to update the CC Sales Agent and CC Sales Agent Manager field in Implementation Record. */
		        if(accountMap != null && thisRecord.Account__c != null && accountMap.get(thisRecord.Account__c) != null) {
		            // Implementation__c implementationRecord = thisRecord;
		            Account accObj = accountMap.get(thisRecord.Account__c);
		            thisRecord.CC_Sales_Agent__c = accObj.Most_Recent_Opportunity_Owner__r.Email;
		            thisRecord.CC_Sales_Agent_Manager__c = accObj.Most_Recent_Opportunity_Owner__r.Manager.Email;
		            /********** ADDED BY VIREN 2nd March 2014 ************/
		            String newBrand = (String.isNotBlank(accObj.RC_Brand__c) && accObj.RC_Brand__c.containsIgnoreCase('BT') ? 'BT Business' : thisRecord.Brand__c);
		            if(oldImplementationsByIds == null) {
		                thisRecord.Brand__c = newBrand;
		            } else {
		                String oldBrand = oldImplementationsByIds.get(thisRecord.Id).Brand__c;
		                if(newBrand != oldBrand) {
		                    thisRecord.Brand__c = newBrand;
		                }
		            }
		        }
		    }

		    if(Trigger.isInsert) {
				    	    /*  Creating dummy event, on Implementation Insertion.
		        This event will be used as a dummy event to sent out to schedule the,Initial Implementation Event. */
		        /*system.debug('#### calling method to create dummy event.');
		        //-------------------As/Simplion/3/13/2015-----------------------
		        //-------------------shifting below line into implementation after trigger
		        ImplementationHelper.createDummyEvent(trigger.new);*/

		        Set<Id> implAccountSet = new Set<Id>();
		        List<String> rcUserIdList =  new List<String>();
		        Profile prof = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
		        for(Implementation__c implementObj : (List <Implementation__c>)Trigger.new) {
		            if(implementObj.Account__c != null) {
		                implAccountSet.add(implementObj.Account__c);
		            }
		            if(implementObj.RC_USER_ID__c != null) {
		                rcUserIdList.add(implementObj.RC_USER_ID__c);
		            }
		            if(implementObj.Implementation_Status_2__c != null) {
		                // To Record the date of  WIP_Timestamp__c when status is changed to Work in Progress.
		                if(implementObj.Implementation_Status_2__c.equalsIgnoreCase('Work in Progress') && implementObj.WIP_Status__c != true ){
		                    implementObj.Implementation_Start_Date__c = System.Now();
		                    implementObj.WIP_Status__c = true;
		                    System.debug('#### Implementation_Start_Date - '+ implementObj.Implementation_Start_Date__c);
		                }
		                // To record the date of Implementation_Close_Date__c when status is changed to Completed.
		                if(implementObj.Implementation_Status_2__c.containsIgnoreCase('Completed') ||
		                implementObj.Implementation_Status_2__c.equalsIgnoreCase('Account Cancelled') ||
		                implementObj.Implementation_Status_2__c.equalsIgnoreCase('No Response') ||
		                implementObj.Implementation_Status_2__c.equalsIgnoreCase('Invalid Implementations')) {

		                    //alow system admin to set date to past and populate date when close date is blank
		                    if(prof.Name.equalsIgnoreCase('System Administrator')){
		                        if(implementObj.Implementation_Close_Date__c == null  ){
		                            implementObj.Implementation_Close_Date__c = System.Today();
		                        }
		                    }else{
		                        implementObj.Implementation_Close_Date__c = System.Today();
		                    }
		                }
		            }
		        }

		        /*********************************************************************************
		        * Association of LeadQualification of Account of Implementation                  *
		        * This code is for only creat event                                              *
		        * If multiple LeadQualification present for Account, choose last modified one    *
		        **********************************************************************************/
		        if(implAccountSet.size() > 0){
		            Map<Id,Account> implAccountMAp = new Map<Id,Account>([SELECT Id,
		            														(SELECT Id FROM Lead_Qualifications__r
		            														ORDER BY LastModifiedDate DESC LIMIT 1)
		            													FROM Account  WHERE Id IN :implAccountSet]);
		            for(Implementation__c implementObj : (List <Implementation__c>)Trigger.new) {
		                if(implAccountMAp != null && implementObj.Account__c != null
		                	&& implAccountMAp.get(implementObj.Account__c) != null
		                	&& implAccountMAp.get(implementObj.Account__c).Lead_Qualifications__r.size() > 0) {
		                    implementObj.Lead_Qualification__c = implAccountMAp.get(implementObj.Account__c).Lead_Qualifications__r[0].id;
		                }
		            }
		        }

		        /* Code for updating the Most Recent Implementation Event Id and Implementation Owner update.
		        if Implementation Owner is RCSF Sync and an Initial Implementation already exists,
		        update the Implementation Owner, with the advisor invited to the event. */
		        try{
		            Map<String,Event> rcUserIdEventMap = new Map<String,Event>();
		            Map<String,Event> rcUserIdDummyEventMap = new Map<String,Event>();
		            Schema.DescribeSObjectResult r = User.sObjectType.getDescribe();
		            String userObjectPrefix = r.getKeyPrefix();
		            for(Event thisRecord : [SELECT Id, CustomerId__c, Type,
		            							(SELECT RelationId
		            							FROM EventRelations
		            							ORDER BY LastModifiedDate ASC LIMIT 1)
		            						FROM Event
		            						WHERE CustomerId__c IN : rcUserIdList
		            						AND IsChild != true order by CreatedDate DESC]) {
		                if(thisRecord.Type != null && !thisRecord.Type.equalsIgnoreCase('System Use')) {
		                    rcUserIdEventMap.put(thisRecord.CustomerId__c, thisRecord);
		                }else if(thisRecord.Type != null && thisRecord.Type.equalsIgnoreCase('System Use')) {
		                    rcUserIdDummyEventMap.put(thisRecord.CustomerId__c, thisRecord);
		                }
		            }

		            for(Implementation__c thisRecord : (List <Implementation__c>)Trigger.new) {
		                if(thisRecord.RC_USER_ID__c != null && rcUserIdEventMap != null
		                	&& rcUserIdEventMap.size() > 0 && rcUserIdEventMap.get(thisRecord.RC_USER_ID__c) != null) {

		                    thisRecord.Most_Recent_Implementation_Event__c = rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).Id;
		                    if(rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).EventRelations != null
		                    	&& rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).EventRelations.size() > 0
		                    	&& rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).Type != null
		                    	&& rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).Type.EqualsIgnoreCase('Initial Implementation')
		                    	&& rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).EventRelations[0].RelationId != null
		                    	&& String.valueOf(rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).EventRelations[0].RelationId).startsWith(userObjectPrefix)) {
		                        thisRecord.OwnerId = rcUserIdEventMap.get(thisRecord.RC_USER_ID__c).EventRelations[0].RelationId;
		                    }
		                } else if(thisRecord.RC_USER_ID__c != null && rcUserIdDummyEventMap != null
		                	&& rcUserIdDummyEventMap.size() > 0 && rcUserIdDummyEventMap.get(thisRecord.RC_USER_ID__c) != null) {
		                    thisRecord.Most_Recent_Implementation_Event__c = rcUserIdDummyEventMap.get(thisRecord.RC_USER_ID__c).Id;
		                }
		            }
		        }catch(Exception ex) {
		            system.debug('#### Error at line = '+ex.getLineNumber()+' Message = '+ex.getMessage());
		        }

		        ImplementationHelper.markAsPremiumSupportOIDs((List <Implementation__c>)Trigger.new);
		        ImplementationHelper.assignSalesAgent((List <Implementation__c>)Trigger.new);
		    }


		    if(Trigger.isUpdate) {
        		List<Profile> salesProfile = [SELECT Name, Id FROM Profile  WHERE Name Like 'Sales %'];
        		Set<Id> ids = new Set<Id>();
        		for(Profile p : salesProfile) {
            		ids.add(p.Id);
        		}

		        Set<Id> contactIdSet = new Set<Id>();
		        Set<Id> ownerIdSet = new Set<Id>();
		        Profile prof = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
				Map<String, Rise_Partner_CRM_Configuration__c> risePartnerSettings =  Rise_Partner_CRM_Configuration__c.getAll();

		        for(Implementation__c implementVal : newImplementationsByIds.values()) {
		            Implementation__c oldVall = oldImplementationsByIds.get(implementVal.Id);
		            if(implementVal.Implementation_Status_2__c != null) {
		                // To Record the date of  WIP_Timestamp__c when status is changed to Work in Progress.
		                if(implementVal.Implementation_Status_2__c.equalsIgnoreCase('Work in Progress') && implementVal.WIP_Status__c != true ) {
		                    implementVal.Implementation_Start_Date__c = System.Now();
		                    implementVal.WIP_Status__c = true;
		                    System.debug('### Implementation_Start_Date - '+ implementVal.Implementation_Start_Date__c);
		                }
		                // To record the date of Implementation_Close_Date__c when status is changed to Completed.
		                if( oldVall.Implementation_Status_2__c != implementVal.Implementation_Status_2__c && (implementVal.Implementation_Status_2__c.containsIgnoreCase('Completed')) ||
		                implementVal.Implementation_Status_2__c.equalsIgnoreCase('Account Cancelled') ||
		                implementVal.Implementation_Status_2__c.equalsIgnoreCase('No Response') ||
		                implementVal.Implementation_Status_2__c.equalsIgnoreCase('Invalid Implementations')){

		                    if(!'System Administrator'.equalsIgnoreCase(prof.Name)) {
								if(implementVal.Brand__c != 'AT&T Office@Hand'){
		                        Decimal oldVal = oldImplementationsByIds.get(implementVal.Id).Count_of_Escalation__c;
                                Decimal newVal = newImplementationsByIds.get(implementVal.Id).Count_of_Escalation__c;
                                system.debug('oldEscalation: ' + oldVal + ' newEscalation: ' + newVal);
                                if(oldVal == newVal) {
                                    implementVal.Implementation_Close_Date__c = Date.Today();
                                }

		                        system.debug('&&&&&&&&&&&&&&&&&&'+implementVal.Implementation_Close_Date__c);
		                    }
							else{
									if(implementVal.Implementation_Status_2__c.containsIgnoreCase('Completed')
									|| implementVal.Implementation_Status_2__c.equalsIgnoreCase('Account Cancelled')
									|| implementVal.Implementation_Status_2__c.equalsIgnoreCase('No Response')
									|| implementVal.Implementation_Status_2__c.equalsIgnoreCase('Invalid Implementations')) {
										implementVal.Implementation_Close_Date__c = Date.Today();
									}
								}
						}

		                }
		            }

		            if(implementVal != null) {
		                if(implementVal.contact__c != null) {
		                    contactIdSet.add(implementVal.contact__c);
		                }
		                if(implementVal.OwnerId != null) {
		                    ownerIdSet.add(implementVal.OwnerId);
		                }
		                if(implementVal.CreatedById != null) {
		                    ownerIdSet.add(implementVal.CreatedById);
		                }
		            }
		        }

		        Map<Id,Implementation__c> implementSurveyMap;
		        Map<Id,Implementation__c> rogersImplementSurveyMap;
		        Map<Id,Implementation__c> aTTImplementSurveyMap;
		        Map<Id,Contact> contactMap;
		        Map<Id,User> userMap;

		        if(contactIdSet != null && contactIdSet.size() > 0) {
		            contactMap = new Map<Id,Contact>([SELECT id,firstName, email FROM Contact WHERE Id IN :contactIdSet]);
		        }

		        if(ownerIdSet != null && ownerIdSet.size() >0) {
		            userMap = new Map<Id,User>([SELECT id, email, managerid, userroleid, IsActive ,name, UserRole.Name, Manager.name,
		            Manager.email FROM User WHERE Id IN : ownerIdSet]);
		        }

		        if(Trigger.newMap.keySet() != null) {
		            implementSurveyMap = new Map<Id,Implementation__c>([SELECT Name,
		            														(SELECT Name, SurveyType__c
		            														FROM Surveys__r
		            														WHERE SurveyType__c = 'Implementation')
		            													FROM Implementation__c
		            													WHERE Id IN : Trigger.newMap.keySet()]);
		            rogersImplementSurveyMap = new Map<Id,Implementation__c>([SELECT Name,
		            															(SELECT Name, SurveyType__c
		            															FROM Surveys__r
		            															WHERE SurveyType__c = 'Rogers Implementation')
		            														FROM Implementation__c
		            														WHERE Id IN : Trigger.newMap.keySet()]);
		            attImplementSurveyMap = new Map<Id,Implementation__c>([SELECT Name,
		            														(SELECT Name, SurveyType__c
		            														FROM Surveys__r
		            														WHERE SurveyType__c = 'ATT Implementation')
		            													FROM Implementation__c
		            													WHERE Id IN : Trigger.newMap.keySet()]);
		        }

		        List<Survey__c> surveyLst = new List<Survey__c>();

                Id userProfileId = UserInfo.getProfileId();

                for(Id implemenId : Trigger.newMap.keySet()) {

                    Implementation__c oldVal = oldImplementationsByIds.get(implemenId);
                    Implementation__c newVal = newImplementationsByIds.get(implemenId);
                    if(oldVal != null && newVal != null) {
                        // EU Phase 3 IT and Sales Changes - START
                        List<Id> SupportImplProfIDs=HardcodedIdsMapper.getMatchedObjectId(System.Label.Support_Implementations_Profile_ID.split(','));// ------ stores support implementations and its EU restricted profile ids
                        Boolean IsSupportImplementProfID=SupportImplProfIDs.size()>0?SupportImplProfIDs.contains(userProfileId):false;

                        Set<String> SEMgrProfiles = new Set<String>();//------created to store SE Manager and its EU restricted profiles
                        List<EU_Component_Reference__mdt> euComponent = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%ImplementationTriggerHelper%' and DeveloperName = 'SEManagerProfiles'];
                        String SEprofilesList  = (euComponent.size() > 0) ? euComponent[0].Values__c : '';
                        if(String.isNotBlank(SEprofilesList)) {
                            SEMgrProfiles.addAll(SEprofilesList.split(','));
						}
                        /*
                        Business process rules
                        */
                        if(userProfileId != HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ')
                            && !SEMgrProfiles.contains(userProfileId)
                            && !IsSupportImplementProfID )
                        {
                            List<String> SalesCRMSupportProfiles=new List<String>();// ---- created for storing Sales Operations Lightning and CRM Support Engineer with EU restricted profiles
                            List<EU_Component_reference__mdt> euComp=[Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%ImplementationTriggerHelper%' and DeveloperName='Profile_Check_For_Admin_Or_SE_Manager'];
                            String profilesList  = (euComp.size() > 0) ? euComp[0].Values__c : '';
                            if(String.isNotBlank(profilesList))
                            {
                                SalesCRMSupportProfiles.addall(profilesList.split(','));
                            }
                            if(
                                userProfileId != HardcodedIdsMapper.getMatchedObjectId('00e80000001OK9tAAG') // ----------create 24/09/2014 by India Team [profile name = GW API]
                                && !FeatureManagement.checkPermission('Support_Director_permission') //-------------Added as part of profile consolidation of Support Agent profiles - T1
                                && !FeatureManagement.checkPermission('Support_Manager_QA_permission') //-------------Added as part of profile consolidation of Support Agent profiles - T1
                                && !FeatureManagement.checkPermission('Support_Agent_T1_Permission')//added as part of Support T1 profile consolidation- T1
                                && !FeatureManagement.checkPermission('Professional_Services_Manager_Permission')//-------------T1 added Professional Services Lightning id as well as part of profile consolidation on 3/7/2020
                                && (!(SalesCRMSupportProfiles.contains(userProfileId)))
                                //EU Phase 3 IT and Sales Profile Changes - END
                            ) {
                                // -----------create 06/18/2016 by Jaffit Padilla case 04730692 [profile name = SE Manager - (Var & Partners)]
                                // if user does not have SE Manager or SE profile +Sales Agent a& Manager
                                if(newVal.OwnerId != HardcodedIdsMapper.getMatchedObjectId('00580000003eEhrAAE') &&
                                   newVal.OwnerId != HardcodedIdsMapper.getMatchedObjectId('005800000036sJJAAY') &&
                                   newVal.OwnerId != UserInfo.getUserId()) {
                                       //  if new owner is not SE Dispatcher or RCSF Sync
                                       if(!ids.contains(userProfileId)) {
                                           newVal.addError(' You can only assign Implementations to yourself, SE Dispatcher or RCSF Sync.');
                                       }
                                   }
                            }
                        }

                        if(
                            (
                                (
                                    newVal.Implementation_Status__c != '6a. Completed'
                                    && oldVal.Implementation_Status__c == '6a. Completed'
                                ) || (
                                    newVal.Implementation_Status__c != '6b. Completed - No Help Needed'
                                    && oldVal.Implementation_Status__c == '6b. Completed - No Help Needed'
                                ) || (
                                    newVal.Implementation_Status__c != '6c. Completed - Account Cancelled'
                                    && oldVal.Implementation_Status__c == '6c. Completed - Account Cancelled'
                                )
                            )
                            && userProfileId != HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ')
                        ) {
                            // if any of the fields available to a rep have been changed after being set to a completed status
                            newVal.addError(' Once a Implementation has been completed you cannot change its status. Please cancel your changes. You can still add a note to this implementation');
                        }

                        if(
                            newVal.Implementation_Status__c == oldVal.Implementation_Status__c
                            && newVal.Implementation_Status__c.contains('Completed')
                            && userProfileId != HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ')
                        ) {
		                    if((newVal.Number_of_Lines_Implemented__c != oldVal.Number_of_Lines_Implemented__c) ||
		                    (newVal.Was_a_warm_transfer__c != oldVal.Was_a_warm_transfer__c)) {
		                        // if any of the fields available to a rep have been changed after being set to a completed status
		                        newVal.addError(' Once a Implementation has been completed you cannot change its fields. Please cancel your changes. You can still add a note to this implementation');
		                    }
		                }

		                /*********** Check Network Information*******26 June****  */

		                if(newVal.Implementation_Status__c == '6a. Completed' &&
		                	newVal.Account__c != null &&
		                	accountMap != null &&
		                	accountMap.containskey(newVal.Account__c)) {
		                    List<Network_Information__c> networkInfoList =  accountMap.get(newVal.Account__c).Network_Informations__r;
		                    if(networkInfoList == null || networkInfoList.size()== 0) {
		                        newVal.addError(' Please create a new Network Information record for this account before closing the implementation');
		                    }
		                }
		                /*
		                Create and sent implementation survey
		                */
		                /*Implementation conditions are changed on March 19, 2012*/
		                if (newVal.Implementation_Status__c != null
		                    && newVal.Brand__c != null  && (!'System Administrator'.equalsIgnoreCase(prof.Name) || Test.isRunningTest())) {
								if(newVal.Brand__c != 'AT&T Office@Hand'){
		                    Decimal oldEscCount = oldImplementationsByIds.get(implemenId).Count_of_Escalation__c;
                            Decimal newEscCount = newImplementationsByIds.get(implemenId).Count_of_Escalation__c;
                            if(oldEscCount == newEscCount) {
                                newVal.Implementation_Close_Date__c = Date.Today();
                            }
						}
						Boolean isRiseAcct = risePartnerSettings.containsKey(newVal.Sub_brand__c);
						if (newVal.Implementation_Status__c != null
						&& newVal.Brand__c != null
						&& (
							(oldVal.Implementation_Status__c != '6a. Completed' && newVal.Implementation_Status__c == '6a. Completed')
							|| (oldVal.Implementation_Status_2__c != 'Completed' && newVal.Implementation_Status_2__c == 'Completed')
						)
						&& (
							newVal.Brand__c.containsIgnoreCase('BT')/*Suppress Implementations Survey for ConvergeOne Accounts - B-10077 - October 29, 2019*/
							|| (newVal.Brand__c == 'Vodafone Business with RingCentral'
								&& IsSupportImplementProfID
								&& (accountMap.get(oldVal.Account__c).BillingCountry == 'Germany' || accountMap.get(newVal.Account__c).BillingCountry == 'Germany')
							)
                                || (newVal.Brand__c == 'Frontier with RingCentral' && IsSupportImplementProfID)
								|| (isRiseAcct && IsSupportImplementProfID)) /* Do not Remove this condition is added for RISE brands survey creation */

		                /*Suppress Implementations Survey for ConvergeOne Accounts - B-10077 - October 29, 2019*/
		                        && newVal.Partner_ID__c != '51911'
		                        && newVal.Partner_ID__c != '66162'
		                        && newVal.Partner_ID__c != '51912') {
		                        	if(newVal.Contact__c == Null) {
		                            	newVal.Contact__c.addError('Please SELECT the contact you have been working with before setting the Status to Completed');
		                        	} else {
		                            	Integer sCheck;
		                            	Integer cCheck;
		                            	try {
			                                // check for an existing implementation survey tied to this implementation
			                                if( implementSurveyMap != null && (implementSurveyMap.get(newVal.Id).Surveys__r) != null) {
			                                    sCheck = (implementSurveyMap.get(newVal.Id).Surveys__r).size();
			                                }
		                            	} catch(System.Exception e){}

		                                if(sCheck == 0) {
		                                    try {
		                                        Survey__c surveyObj = new Survey__c();
		                                        surveyObj.SurveyType__c = newVal.ProfessionalServices__c == true ? 'Professional Services' : 'Implementation';
		                                        surveyObj.Account__c = newVal.Account__c;
		                                        surveyObj.Implementation__c = newVal.Id;
		                                        if(userMap != null && userMap.containsKey(newVal.OwnerId)) {
		                                            User userObj = userMap.get(newVal.OwnerId);
		                                            if(userObj != null) {
		                                                surveyObj.Agent__c = userObj.Id;
		                                                surveyObj.Agent_Email__c = userObj.email;
		                                                surveyObj.Agent_Name__c = userObj.name;
		                                            }
		                                            surveyObj.Agent_Team__c = userMap.get(newVal.OwnerId).UserRole.Name;

		                                            if(userMap != null && userMap.get(newVal.OwnerId).Manager.Name != null) {
		                                                surveyObj.Agent_Manager_Name__c = userMap.get(newVal.OwnerId).Manager.Name;
		                                            }
		                                            if(userMap != null && userMap.get(newVal.OwnerId).Manager.Email != null) {
		                                                surveyObj.Agent_Manager_Email__c = userMap.get(newVal.OwnerId).Manager.Email;
		                                            }
		                                        }
		                                        surveyObj.Contact__c = newVal.Contact__c;
		                                        if(contactMap != null && surveyObj.Contact__c != null && contactMap.containsKey(surveyObj.Contact__c)) {
		                                            Contact contactObj = contactMap.get(surveyObj.Contact__c);
		                                            surveyObj.contact_email__c = contactObj.email;
		                                            surveyObj.name = (newVal.ProfessionalServices__c == true ? 'Professional Services - ' : 'Implementation - ') + Datetime.now().format();
		                                        }
		                                        if(userMap != null && userMap.containsKey(newVal.CreatedById)) {
		                                            User userObj = userMap.get(newVal.CreatedById);
		                                            if(userObj != null && userObj.isActive == true) {
		                                                surveyObj.OwnerId = newVal.CreatedById;
		                                            }
		                                        }
		                                        surveyLst.add(surveyObj);
		                                    } catch(Exception ex) {}
		                                }
		                            }
		                                /* Else condition for ATT Office @ Hand*/
		                    } else if (newVal.Implementation_Status__c != null && newVal.Brand__c != null
		                                        && ((oldVal.Implementation_Status__c != '6a. Completed' && newVal.Implementation_Status__c == '6a. Completed')
		                                        || (oldVal.Implementation_Status_2__c != 'Completed' && newVal.Implementation_Status_2__c == 'Completed'))
		                                        && (newVal.Brand__c.equalsIgnoreCase('AT&T Office@Hand') || newVal.Brand__c.equalsIgnoreCase('RingCentral Office@Hand from AT&T'))) {
		                        if(newVal.Contact__c == null) {
		                            newVal.Contact__c.addError('Please SELECT the contact you have been working with before setting the Status to Completed');
		                        } else {
                                    Integer sCheck = 0;
                                    Integer cCheck = 0;
                                    sCheck = 0;
                                    if(sCheck == 0) {
                                        try {
                                            Survey__c surveyObj = new Survey__c();
                                            surveyObj.SurveyType__c = 'ATT Implementation';
                                            surveyObj.Account__c = newVal.Account__c;
                                            surveyObj.Implementation__c = newVal.Id;
                                            if(userMap != null && userMap.containsKey(newVal.OwnerId)) {
                                                User userObj = userMap.get(newVal.OwnerId);
                                                surveyObj.Agent__c = userObj.Id;
                                                surveyObj.Agent_Email__c = userObj.email;
                                                surveyObj.Agent_Name__c = userObj.name;
                                                surveyObj.Agent_Team__c = userMap.get(newVal.OwnerId).UserRole.Name;

                                                if(userMap != null && userMap.get(newVal.OwnerId).Manager.Name != null) {
                                                    surveyObj.Agent_Manager_Name__c = userMap.get(newVal.OwnerId).Manager.Name;
                                                }
                                                if(userMap != null && userMap.get(newVal.OwnerId).Manager.Email != null) {
                                                    surveyObj.Agent_Manager_Email__c = userMap.get(newVal.OwnerId).Manager.Email;
                                                }
                                            }

                                            surveyObj.Contact__c = newVal.Contact__c;
                                            if(contactMap != null && surveyObj.Contact__c != null && contactMap.containsKey(surveyObj.Contact__c)) {
                                                Contact contactObj = contactMap.get(surveyObj.Contact__c);
                                                surveyObj.contact_email__c = contactObj.email;
                                                surveyObj.name = 'ATT Implementation - ' + Datetime.now().format();
                                            }
                                            surveyLst.add(surveyObj);
                                        } catch(Exception ex) {}
                                    }
		                        }
		                        /* Else for Rogers */
		                    }else if (newVal.Implementation_Status__c != null
                                    && newVal.Brand__c != null
                                    && ((oldVal.Implementation_Status__c != '6a. Completed' && newVal.Implementation_Status__c == '6a. Completed')
                                    || (oldVal.Implementation_Status_2__c != 'Completed' && newVal.Implementation_Status_2__c == 'Completed'))
                                    && (newVal.Brand__c.equalsIgnoreCase('Rogers'))) {
                                if(newVal.Contact__c == Null) {
                                    newVal.Contact__c.addError('Please SELECT the contact you have been working with before setting the Status to Completed');
                                } else {
	                                Integer sCheck;
	                                try {
	                                    if( rogersImplementSurveyMap != null && (rogersImplementSurveyMap.get(newVal.Id).Surveys__r) != null) {
	                                        sCheck = (rogersImplementSurveyMap.get(newVal.Id).Surveys__r).size();
	                                    }
	                                }
                                    catch(System.Exception e){}

                                    if(sCheck == 0) {
                                        try {
                                            Survey__c surveyObj = new Survey__c();
                                            surveyObj.SurveyType__c = 'Rogers Implementation';
                                            surveyObj.Account__c = newVal.Account__c;
                                            surveyObj.Implementation__c = newVal.Id;

                                            if(userMap != null && userMap.containsKey(newVal.OwnerId)) {
                                                User userObj = userMap.get(newVal.OwnerId);
                                                surveyObj.Agent__c = userObj.Id;
                                                surveyObj.Agent_Email__c = userObj.email;
                                                surveyObj.Agent_Name__c = userObj.name;
                                                surveyObj.Agent_Team__c = userMap.get(newVal.OwnerId).UserRole.Name;

                                                if(userMap != null && userMap.get(newVal.OwnerId).Manager.Name != null) {
                                                    surveyObj.Agent_Manager_Name__c = userMap.get(newVal.OwnerId).Manager.Name;
                                                }
                                                if(userMap != null && userMap.get(newVal.OwnerId).Manager.Email != null) {
                                                    surveyObj.Agent_Manager_Email__c = userMap.get(newVal.OwnerId).Manager.Email;
                                                }
                                            }

                                            surveyObj.Contact__c = newVal.Contact__c;
                                            if(contactMap != null && contactMap.containsKey(surveyObj.Contact__c)) {
                                                Contact contactObj = contactMap.get(surveyObj.Contact__c);
                                                surveyObj.contact_email__c = contactObj.email;
                                                surveyObj.name = 'Rogers Implementation - ' + Datetime.now().format();
                                            }
                                            surveyLst.add(surveyObj);
                                        } catch(Exception ex) { }
	                                }
		                        }
                            }
                        }
                    }
                }
                if(surveyLst != null && surveyLst.size()>0) {
                    try {
                        insert surveyLst;
                    } catch(DMLException ex) {}
                }
            }
            if(Trigger.isUpdate || Trigger.isInsert) {
                /*
* Graduation Score card Implementation Phase Start
*/
                try{
                    String strAction = GraduationScoreCardHelper.STR_INSERT;
                    if(Trigger.isUpdate){
                        strAction = GraduationScoreCardHelper.STR_UPDATE;
                    }
                    for(Implementation__c imp: newImplementations) {
                        GraduationScoreCardHelper.ScoreCardWrapper objScoreCardWrapper = new GraduationScoreCardHelper.ScoreCardWrapper();
                        if(Trigger.isUpdate){
                            objScoreCardWrapper = GraduationScoreCardHelper.getImplementationCompletionDetails(imp, oldImplementationsByIds.get(imp.Id), strAction);
                        }else{
                            objScoreCardWrapper = GraduationScoreCardHelper.getImplementationCompletionDetails(imp, null, strAction);
                        }
                        system.debug('objScoreCardWrapper.dCompletionRate--->'+objScoreCardWrapper.dCompletionRate);
                        imp.Implementation_Phase_Completion_Rate__c = objScoreCardWrapper.dCompletionRate != null ? objScoreCardWrapper.dCompletionRate : 0;
                        imp.Account_Graduation_Status__c = 'New';
                        if(objScoreCardWrapper.dCompletionRate == 100){
                            if(objScoreCardWrapper.bUpdateAcount){
                                imp.Account_Graduation_Date_0_30__c = objScoreCardWrapper.completionDate != null ? objScoreCardWrapper.completionDate : system.now();
                            }
                            imp.Account_Graduation_Status__c = 'Done';
                        }
                        if(objScoreCardWrapper.dCompletionRate >0 && objScoreCardWrapper.dCompletionRate <100){
                            imp.Account_Graduation_Status__c = 'Implementation Phase';
                        }
                    }
                }catch(Exception ex){
                    system.debug('Error---->'+ex.getMessage());
                }
                /* Graduation Score card Implementation Phase END*/
            }
        }
    }
    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Implementation__c.sObjectType);
        }
    }
	public class ProfessionalServicesCheckBoxPopulation extends Triggers.TriggerHandlerBase {
		override public void handle() {

            //Build account id to implementation list map
            Map <Id, List <Implementation__c>> accountIdToImplementationListMap= new Map <Id, List <Implementation__c>>();
            for (Implementation__c impRecord : (List <Implementation__c>)Trigger.new) {
                if(!accountIdToImplementationListMap.containsKey(impRecord.Account__c )) {
                    accountIdToImplementationListMap.put(impRecord.Account__c, new List<Implementation__c>());
                }
                accountIdToImplementationListMap.get(impRecord.Account__c).add(impRecord);
            }
            //Get quotes which belong to implementation.Account
            List <Quote> quotesUnderAccounts = [SELECT Id, ProServ_Status__c, AccountId, RecordTypeId
                                                FROM Quote
                                                WHERE AccountId IN : accountIdToImplementationListMap.keySet()];
            for (Quote q: quotesUnderAccounts) {
                if(q.ProServ_Status__c == 'Sold'
                   && (q.RecordTypeId == QuoteHelper.RT_ID_PROSERV || q.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV)) {
                       for (Implementation__c impRecord: accountIdToImplementationListMap.get(q.AccountId)) {
                           impRecord.ProfessionalServices__c = true;
                       }
                   }
            }
        }
    }

	public class PopulateImplemantationFieldsWithPackageFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
			List<Implementation__c> implementationsToProcess = (List<Implementation__c>) this.triggerRecords;

            for (Implementation__c impl : implementationsToProcess) {
                if (impl.Account__c != null) {
                    accIds.add(impl.Account__c);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {accIds})
                .executeQuery();

			if (packages.isEmpty()) {
                return;
            }

			for (Implementation__c impl : implementationsToProcess) {
				Map<Id, Package__c> officePackageToProcessMap = PackageHelper.filterPackagesByService(packages, AccountHelper.SERVICE_TYPE_OFFICE);
				if (!officePackageToProcessMap.containsKey(impl.Account__c)) {
					continue;
				}
				Package__c officePackage = officePackageToProcessMap.get(impl.Account__c);
				impl.Service_Version_Name__c = officePackage != null ? officePackage.Service_Version_Label__c : '';
			}
        }
	}
}