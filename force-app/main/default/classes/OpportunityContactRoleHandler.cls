public with sharing class OpportunityContactRoleHandler {
    public class UpdateContactLogic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Contact_Update_ClosedWon_Opp__e> eventList = new List<Contact_Update_ClosedWon_Opp__e>();
            if (Trigger.isInsert) {
                for (OpportunityContactRole oppConRole : (List<OpportunityContactRole>) Trigger.new) {
                    eventList.add(
                        new Contact_Update_ClosedWon_Opp__e(
                            Opportunity_Id__c = oppConRole.OpportunityId,
                            Contact_Id__c = oppConRole.ContactId
                        )
                    );
                }
            } else if (Trigger.isDelete) {
                for (OpportunityContactRole oppConRole : (List<OpportunityContactRole>) Trigger.old) {
                    eventList.add(
                        new Contact_Update_ClosedWon_Opp__e(
                            Contact_Id__c = oppConRole.ContactId
                        )
                    );
                }
            }
            if (!eventList.isEmpty()) {
                PlatformEvents.publishPlatformEvent(eventList, 'UpdateContactLogicOppContactRole');
            }
        }
    }

    public class DeletePrimaryOppContactValidation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> opportunityIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Map<String, OpportunityContactRole> oppConRoleMap = new Map<String, OpportunityContactRole>();
            Map<String, List<OpportunityContactRole>> duplicatedOppConRole = new Map<String, List<OpportunityContactRole>>();
            for (OpportunityContactRole oppConRole : (List<OpportunityContactRole>) Trigger.old) {
                opportunityIds.add(oppConRole.OpportunityId);
                contactIds.add(oppConRole.ContactId);
                oppConRoleMap.put(oppConRole.OpportunityId + '' + oppConRole.ContactId, oppConRole);
            }
            for (
                OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOppConRolesByListConIdsAndListOppIds(new List<Object>{
                    opportunityIds, contactIds
                })
                .executeQuery()
            ) {
                String oppConKey = oppConRole.OpportunityId + '' + oppConRole.ContactId;
                if (duplicatedOppConRole.containsKey(oppConKey)) {
                    duplicatedOppConRole.get(oppConKey).add(oppConRole);
                } else {
                    duplicatedOppConRole.put(oppConKey, new List<OpportunityContactRole>{
                        oppConRole
                    });
                }
            }
            for (
                Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesByIdAndPrimaryOppContact(new List<Object>{
                    opportunityIds, contactIds
                })
                .executeQuery()
            ) {
                String oppConKey = opp.Id + '' + opp.Primary_Opportunity_Contact__c;
                if (
                    oppConRoleMap.containsKey(oppConKey) &&
                        duplicatedOppConRole.containsKey(oppConKey) &&
                        duplicatedOppConRole.get(oppConKey).size() == 1
                ) {
                    oppConRoleMap.get(oppConKey)
                        .addError(
                            'In order to remove this contact role, you first need to replace it on the Primary Opportunity Contact field.'
                        );
                }
            }
        }
    }

    public class UpdateOppPrimaryContact extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isAfter && Trigger.isUpdate) {
                System.debug('Inside Trigger Update Statment');
                Set<Id> oppIds = new Set<Id>();
                Set<Id> accIds = new Set<Id>();
                Map<Id, Opportunity> mapOpp ;
                Map<Id, Account> mapAcc ;
                Boolean primaryChange = false;
                Boolean syncAccountContactRole = false;
                String cstmLabel_RCbrandname;
                //List<AccountContactRole> lstAccRleInsert = new List<AccountContactRole>();
                //List<AccountContactRole> lstAccRleUpdate = new List<AccountContactRole>();
                List<AccountContactRole> lstAccRleUpsert = new List<AccountContactRole>();
                List<Opportunity> lstOppUpdate = new List<Opportunity>();
                List<OpportunityContactRole> lstNewOppConRole = new List<OpportunityContactRole>([
                    SELECT Id, OpportunityId, Opportunity.AccountId, IsPrimary,
                        ContactId, Role
                    FROM OpportunityContactRole
                    WHERE Id IN :Trigger.new
                ]);
                for (OpportunityContactRole oppConRole : lstNewOppConRole) {
                    OpportunityContactRole oldOppConRole = (OpportunityContactRole) Trigger.oldMap.get(oppConRole.Id);

                    if (oppConRole.IsPrimary == true && (oppConRole.IsPrimary != oldOppConRole.IsPrimary ||
                        oppConRole.ContactId != oldOppConRole.ContactId ||
                        oppConRole.Role != oldOppConRole.Role)) {
                        syncAccountContactRole = true;
                        oppIds.add(oppConRole.OpportunityId);
                        accIds.add(oppConRole.Opportunity.AccountId);
                    }

                }
                if (syncAccountContactRole) {
                    if (oppIds.size() > 0) {
                        mapOpp = new Map<Id, Opportunity>([SELECT Id, AccountId, Primary_Opportunity_Contact__c, PrimaryQuote__r.Status, Account.RC_Account_Status__c, CustomerConfirmation__c, Brand_Name__c FROM Opportunity WHERE Id IN :oppIds]);
                    }
                    if (accIds.size() > 0) {
                        mapAcc = new Map<Id, Account>([SELECT Id, (SELECT Id, ContactId, AccountId, IsPrimary, Role FROM AccountContactRoles) FROM Account WHERE Id IN :accIds]);
                    }
                    for (OpportunityContactRole ocr : lstNewOppConRole) {
                        Boolean acctrlefound = false;
                        cstmLabel_RCbrandname = System.Label.RC_BrandNames;
                        if (ocr.IsPrimary && mapOpp.get(ocr.OpportunityId) != null && cstmLabel_RCbrandname.contains(mapOpp.get(ocr.OpportunityId).Brand_Name__c) && mapOpp.get(ocr.OpportunityId).Primary_Opportunity_Contact__c != ocr.ContactId) {
                            mapOpp.get(ocr.OpportunityId).Primary_Opportunity_Contact__c = ocr.ContactId;
                            lstOppUpdate.add(mapOpp.get(ocr.OpportunityId));
                        }
                        if ((ocr.IsPrimary && mapOpp.get(ocr.OpportunityId) != null && mapOpp.get(ocr.OpportunityId).Account.RC_Account_Status__c != 'Paid')
                            && (mapOpp.get(ocr.OpportunityId).CustomerConfirmation__c != 'Confirmed'
                            || mapOpp.get(ocr.OpportunityId).PrimaryQuote__r.Status != 'Active')) {
                            Id accid = mapOpp.get(ocr.OpportunityId).AccountId;
                            if (mapAcc.get(accid) != null) {
                                for (AccountContactRole acr : mapAcc.get(accid).AccountContactRoles) {
                                    if (acr.IsPrimary && acr.ContactId == ocr.ContactId && acr.Role != ocr.Role) {
                                        // It should create a new ACR record with the OCR role
                                        System.debug('**ACR and OCR role is not matching and New ACR should be created');
                                    } else if (acr.IsPrimary && acr.ContactId == ocr.ContactId && acr.Role == ocr.Role) {
                                        acctrlefound = true;
                                        System.debug('**ACR and OCR role is not matching and New ACR should not be created');
                                    } else if (acr.IsPrimary && acr.ContactId != ocr.ContactId) {
                                        acr.IsPrimary = false;
                                        lstAccRleUpsert.add(acr);
                                        System.debug('**ACR and OCR contact id is not matching');
                                    } else if (!acr.IsPrimary && acr.ContactId == ocr.ContactId && acr.Role == ocr.Role) {
                                        acr.IsPrimary = true;
                                        acctrlefound = true;
                                        lstAccRleUpsert.add(acr);
                                        System.debug('**InsideElseIf');

                                    } else if (!acr.IsPrimary && acr.ContactId == ocr.ContactId && acr.Role != ocr.Role) {
                                        System.debug('**New ACR with ORC role and make it primary');

                                    } else if (!acr.IsPrimary && acr.ContactId != ocr.ContactId) {
                                        System.debug('**New ACR with ORC role and make it primary');

                                    }

                                }
                            }
                            if (acctrlefound == false && cstmLabel_RCbrandname.contains(mapOpp.get(ocr.OpportunityId).Brand_Name__c)) {
                                System.debug('**insideacctrlefound');
                                AccountContactRole accConRle = new AccountContactRole();
                                accConRle.AccountId = mapOpp.get(ocr.OpportunityId).AccountId;
                                accConRle.ContactId = ocr.ContactId;
                                accConRle.IsPrimary = true;
                                accConRle.Role = ocr.Role;
                                lstAccRleUpsert.add(accConRle);
                            }
                        }
                    }
                    if (lstOppUpdate.size() > 0) {
                        Triggers.switchOff();
                        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
                        update lstOppUpdate;
                        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
                        Triggers.switchOn();
                    }
                    //Insert lstAccRleInsert;
                    if (lstAccRleUpsert.size() > 0) {
                        upsert lstAccRleUpsert ;
                    }
                }
            }
        }
    }

    public class RestrictUserToCreateContactRole extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String currentUserName = Userinfo.getUserName();
            if ((ConvertLead.IS_LEAD_CONVERT_PROCESSING) || currentUserName.contains('automation')) {
                OpportunityTriggerHelperRefactored.skipOpportunityContactRoleValidations = true;
            }

            if (OpportunityTriggerHelperRefactored.skipOpportunityContactRoleValidations == false) {
                Set<id> oppids = new set<id>();
                String PERMESSIONSET_NAME_Opp = 'EditOpportunityContact';
                Boolean hasCustomPermission = FeatureManagement.checkPermission(PERMESSIONSET_NAME_Opp);

		        for (OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                    .selectOppConRolesWithId(new List<Object>{ this.triggerRecords })
                    .executeQuery()
                ) {
                    if(oppConRole.Opportunity.Account.RC_Account_Status__c != null && oppConRole.Opportunity.Account.RC_Account_Status__c == 'Paid' && !hasCustomPermission) {
                        trigger.new[0].adderror('Contact Role cannot be modified. Please contact Deal Desk for any questions.');
                    } else if(oppConRole.Opportunity.PrimaryQuote__r.Status != null && oppConRole.Opportunity.PrimaryQuote__r.Status == 'Active' && !hasCustomPermission) {
                        trigger.new[0].adderror('Contact Role cannot be modified. Please contact Deal Desk for any questions.');
                    } else if(oppConRole.Opportunity.CustomerConfirmation__c != null && oppConRole.Opportunity.CustomerConfirmation__c == 'Confirmed' && !hasCustomPermission) {
                        trigger.new[0].adderror('Contact Role cannot be modified. Please contact Deal Desk for any questions.');
                    }
                }
            }
        }
    }
}