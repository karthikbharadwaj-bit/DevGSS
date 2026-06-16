({
    doInit : function(component, event, helper){
        let reference = component.get("v.pageReference");
        let state = reference.state;
        let base64Context = state.inContextOfRef;
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        let addressableContext = JSON.parse(window.atob(base64Context));
        component.set('v.recordId', addressableContext.attributes.recordId);
        component.set('v.parentObject', addressableContext.attributes.objectApiName);
        component.set('v.recTypeId', addressableContext.attributes.recTypeId);
        component.set('v.partnerAccountId', addressableContext.attributes.partnerAccountId);
        component.set('v.defaultFieldValues', addressableContext.attributes.defaultFieldValues);

        helper.receiveInitialData(component);
    },

    createApproval : function(component, event, helper) {

        let recordTypeId;
        if (document.querySelector('input[name="recordTypeRadio"]:checked')) {
            recordTypeId = document.querySelector('input[name="recordTypeRadio"]:checked').id;
        }
        else {
            recordTypeId = component.get('v.recTypeId');
        }
        var accid;
        var oppid;
        var caseid;
        var agentcredid;
        var recid;
        let recordId = component.get("v.recordId");
        let payingContact = component.get("v.payingContactId");
        let partnerPayingContact = component.get("v.partnerPayingContactId");
        let partnerAccountId = component.get("v.partnerAccountId");
        let defaultFieldValues = component.get("v.defaultFieldValues");
        let recordTypes = component.get("v.recordTypesMap");

        if (recordTypeId) {
            if (recordId !== undefined) {
                if (recordId.startsWith("001")) {
                    accid = recordId;
                    recid = accid;
                }
                if (recordId.startsWith("006")) {
                    oppid = recordId;
                    recid = oppid;
                }
                if (recordId.startsWith("500")) {
                    caseid = recordId;
                    recid = caseid;
                }
                if (recordId.startsWith("a0B")) {
                    agentcredid = recordId;
                    recid = agentcredid;
                }
            }

            let recordTypeDeveloperName = (recordTypes[recordTypeId] !== undefined) ? recordTypes[recordTypeId] : null;
            if (recid == null) {
                recid = "lightning/o/Approval__c/list";
                component.set("v.retURL", recid);
            } else {
                component.set("v.retURL", recid);
            }

            //Invoking method
            var action = component.get("c.fetchFieldValues");
            if (recordTypeDeveloperName !== null && recordTypeDeveloperName === 'Credit_Limit_Increase') {
                action = component.get("c.fetchFieldCreditLimitValues");
                action.setParams({
                    accountId: accid,
                    recordTypeId: recordTypeId,
                    opportunityId: oppid
                });
            } else {
                action.setParams({
                    accountId: accid,
                    rectypeId: recordTypeId,
                    opporId: oppid
                });
            }

            action.setCallback(this, function (response) {
                $A.get("e.force:closeQuickAction").fire();
                var state = response.getState();
                if (state === "SUCCESS") {
                    var retResponse = response.getReturnValue();
                    if (retResponse != null) {
                        if (retResponse.errorMessage != null) {
                            let toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": retResponse.errorMessage,
                                "mode": 'dismissible'
                            });
                            toastEvent.fire();
                        } else {

                            //Creating Record
                            var userId = $A.get("$SObjectType.CurrentUser.Id");

                            var approvalrecord = defaultFieldValues == null ? {} : defaultFieldValues;
                            const kycApprovalsMap = retResponse["kycApprovalFieldsToValuesMap"];
                            for (var fieldName in kycApprovalsMap) {
                                approvalrecord[fieldName] = kycApprovalsMap[fieldName];
                            }
                            approvalrecord.Name = retResponse.approvalName || null;

                            if (retResponse.managerId_access) {
                                approvalrecord.Level1Approver__c = retResponse.managerId ? retResponse.managerId : null;
                            }

                            if (retResponse.refundOwner_access) {
                                approvalrecord.Refund_Owner__c = retResponse.refundOwner ? retResponse.refundOwner : null;
                            }

                            approvalrecord.Account__c = retResponse.accountIdContrl ? retResponse.accountIdContrl : accid;

                            if (retResponse.Case_access) {
                                approvalrecord.Case__c = caseid ? caseid : null;
                            }

                            if (retResponse.CreditTransferToAgent_access) {
                                approvalrecord.Credit_Transfer_To_Agent__c = userId ? userId : null;
                            }

                            if (retResponse.AgentCredit_access) {
                                approvalrecord.Agent_Credit__c = agentcredid ? agentcredid : null;
                            }

                            if (retResponse.Opportunity_access) {
                                approvalrecord.Opportunity__c = oppid ? oppid : null;
                            }

                            if (retResponse.editionComp_access) {
                                approvalrecord.Edition__c = retResponse.editionComp ? retResponse.editionComp : "";
                            }

                            if (retResponse.claimingrequestor_access) {
                                approvalrecord.Claiming_Requestor__c = retResponse.claimingrequestor ? retResponse.claimingrequestor : null;
                            }

                            if (retResponse.accountType_access) {
                                approvalrecord.AccountType__c = retResponse.accountType ? retResponse.accountType : "";
                            }

                            if (defaultFieldValues == null) {
                                if (retResponse.invoiceTerms_access) {
                                    approvalrecord.Invoice_Terms__c = retResponse.invoiceTerms ? retResponse.invoiceTerms : "";
                                }

                                if (retResponse.paymentTerms_access) {
                                    approvalrecord.Payment_Terms__c = retResponse.paymentTerms ? retResponse.paymentTerms : "";
                                }

                                if (retResponse.monthlycredLimit_access) {
                                    approvalrecord.Monthly_Credit_Limit__c = retResponse.monthlycredLimit ? retResponse.monthlycredLimit : "";
                                    approvalrecord.Monthly_Credit_Limit__c = Math.round(approvalrecord.Monthly_Credit_Limit__c * 100) / 100;
                                }

                                if (retResponse.monthlycredLimit_Office_access && retResponse.monthlycredLimitOffice) {
                                    approvalrecord.Monthly_Credit_Limit_Office__c = retResponse.monthlycredLimitOffice;
                                    approvalrecord.Monthly_Credit_Limit_Office__c = Math.round(approvalrecord.Monthly_Credit_Limit_Office__c * 100) / 100;
                                }

                                if (retResponse.monthlycredLimit_ProServ_access && retResponse.monthlycredLimitProServ) {
                                    approvalrecord.MonthlyCreditLimitProServ__c = retResponse.monthlycredLimitProServ;
                                    approvalrecord.MonthlyCreditLimitProServ__c = Math.round(approvalrecord.MonthlyCreditLimitProServ__c * 100) / 100;
                                }

                                if (retResponse.monthlycredLimit_Contact_Center_access && retResponse.monthlycredLimitContactCenter) {
                                    approvalrecord.Monthly_Credit_Limit_Contact_Center__c = retResponse.monthlycredLimitContactCenter;
                                    approvalrecord.Monthly_Credit_Limit_Contact_Center__c = Math.round(approvalrecord.Monthly_Credit_Limit_Contact_Center__c * 100) / 100;
                                }

                                if (retResponse.monthlycredLimit_Engage_Voice_access && retResponse.monthlycredLimitEngageVoice) {
                                    approvalrecord.Monthly_Credit_Limit_Engage_Voice__c = retResponse.monthlycredLimitEngageVoice;
                                    approvalrecord.Monthly_Credit_Limit_Engage_Voice__c = Math.round(approvalrecord.Monthly_Credit_Limit_Engage_Voice__c * 100) / 100;
                                }

                                if (retResponse.monthlycredLimit_Engage_Digital_access && retResponse.monthlycredLimitEngageDigital) {
                                    approvalrecord.Monthly_Credit_Limit_Engage_Digital__c = retResponse.monthlycredLimitEngageDigital;
                                    approvalrecord.Monthly_Credit_Limit_Engage_Digital__c = Math.round(approvalrecord.Monthly_Credit_Limit_Engage_Digital__c * 100) / 100;
                                }
                                
                                if (retResponse.monthlycredLimit_RCEvents_access && retResponse.monthlycredLimitRCEvents) {
                                    approvalrecord.Monthly_Credit_Limit_for_RC_Events__c = retResponse.monthlycredLimitRCEvents;
                                    approvalrecord.Monthly_Credit_Limit_for_RC_Events__c = Math.round(approvalrecord.Monthly_Credit_Limit_for_RC_Events__c * 100) / 100;
                                }

                                if (retResponse.signUpPurchaseLimit_access) {
                                    approvalrecord.Sign_Up_Purchase_Limit__c = retResponse.signUpPurchaseLimit ? retResponse.signUpPurchaseLimit : "";
                                    approvalrecord.Sign_Up_Purchase_Limit__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit__c * 100) / 100;
                                    console.log('approvalrecord.Sign_Up_Purchase_Limit__c' + approvalrecord.Sign_Up_Purchase_Limit__c);
                                }

                                if (retResponse.signUpPurchaseLimit_Office_access && retResponse.signUpPurchaseLimitOffice) {
                                    approvalrecord.Sign_Up_Purchase_Limit_Office__c = retResponse.signUpPurchaseLimitOffice;
                                    approvalrecord.Sign_Up_Purchase_Limit_Office__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit_Office__c * 100) / 100;
                                }

                                if (retResponse.signUpPurchaseLimit_ProServ_access && retResponse.signUpPurchaseLimitProServ) {
                                    approvalrecord.SignUpPurchaseLimitProServ__c = retResponse.signUpPurchaseLimitProServ;
                                    approvalrecord.SignUpPurchaseLimitProServ__c = Math.round(approvalrecord.SignUpPurchaseLimitProServ__c * 100) / 100;
                                }

                                if (retResponse.signUpPurchaseLimit_Contact_Center_access && retResponse.signUpPurchaseLimitContactCenter) {
                                    approvalrecord.Sign_Up_Purchase_Limit_Contact_Center__c = retResponse.signUpPurchaseLimitContactCenter;
                                    approvalrecord.Sign_Up_Purchase_Limit_Contact_Center__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit_Contact_Center__c * 100) / 100;
                                }

                                if (retResponse.signUpPurchaseLimit_Engage_Voice_access && retResponse.signUpPurchaseLimitEngageVoice) {
                                    approvalrecord.Sign_Up_Purchase_Limit_Engage_Voice__c = retResponse.signUpPurchaseLimitEngageVoice;
                                    approvalrecord.Sign_Up_Purchase_Limit_Engage_Voice__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit_Engage_Voice__c * 100) / 100;
                                }

                                if (retResponse.signUpPurchaseLimit_Engage_Digital_access && retResponse.signUpPurchaseLimitEngageDigital) {
                                    approvalrecord.Sign_Up_Purchase_Limit_Engage_Digital__c = retResponse.signUpPurchaseLimitEngageDigital;
                                    approvalrecord.Sign_Up_Purchase_Limit_Engage_Digital__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit_Engage_Digital__c * 100) / 100;
                                }
                                
                                if (retResponse.signUpPurchaseLimit_RCEvents_access && retResponse.signUpPurchaseLimitRCEvents) {
                                    approvalrecord.Sign_Up_Purchase_Limit_for_RC_Events__c = retResponse.signUpPurchaseLimitRCEvents;
                                    approvalrecord.Sign_Up_Purchase_Limit_for_RC_Events__c = Math.round(approvalrecord.Sign_Up_Purchase_Limit_for_RC_Events__c * 100) / 100;
                                }


                                if (retResponse.potentialUsers_access) {
                                    approvalrecord.Potential_Users__c = retResponse.potentialUsers ? retResponse.potentialUsers : "";
                                }
                            }

                            if (retResponse.addressLegal_access) {
                                approvalrecord.Legal_Physical_Address_Head_Office__c = retResponse.addressLegal ? retResponse.addressLegal : "";
                                approvalrecord.Legal_Physical_Address_Street__c = retResponse.legal_physical_address_street ? retResponse.legal_physical_address_street : "";
                                approvalrecord.Legal_Physical_Address_City__c = retResponse.legal_physical_address_city ? retResponse.legal_physical_address_city : "";
                                approvalrecord.Legal_Physical_Address_State_Province__c = retResponse.legal_physical_address_state_province ? retResponse.legal_physical_address_state_province : "";
                                approvalrecord.Legal_Physical_Address_Country__c = retResponse.legal_physical_address_country ? retResponse.legal_physical_address_country : "";
                                approvalrecord.Legal_Physical_Address_Zip_Code__c = retResponse.legal_physical_address_zip_code ? retResponse.legal_physical_address_zip_code : "";
                            }

                            if (retResponse.initialnumOfUsers_access) {
                                approvalrecord.Initial_Number_of_Users__c = retResponse.initialnumOfUsers ? retResponse.initialnumOfUsers : "";
                            }
                            if (retResponse.moving_to_invoice_billing_access) {
                                approvalrecord.Moving_to_Invoice_Billing__c = retResponse.moving_to_invoice_billing ? retResponse.moving_to_invoice_billing : "";
                            }
                            if (retResponse.account_segment_access) {
                                approvalrecord.Account_Segment__c = retResponse.account_segment ? retResponse.account_segment : "";
                            }
                            if (retResponse.payment_plan_access) {
                                approvalrecord.Payment_Plan__c = retResponse.payment_plan ? retResponse.payment_plan : "";
                            }
                            if (payingContact) {
                                approvalrecord.AccountPayableContact__c = payingContact;
                            }

                            if (partnerPayingContact) {
                                approvalrecord.PartnerAccountPayableContact__c = partnerPayingContact;
                            }

                            if (partnerAccountId) {
                                approvalrecord.SwitchInvoicePartnerAccount__c = partnerAccountId;
                            }

                            approvalrecord.NGBSCurrentSpendingLimit__c = retResponse.NGBSCurrentSpendingLimit;
                            approvalrecord.NGBSAmountToIncrease__c = retResponse.NGBSAmountToIncreaseSpendingLimit;
                            if (retResponse.opportunityQuoteMap != null) {
                                const opportunityQuoteMap = retResponse["opportunityQuoteMap"];
                                for (var opportunityId in opportunityQuoteMap) {
                                    if (oppid && oppid === opportunityId ) {
                                        approvalrecord.Opportunity__c = opportunityId;
                                        approvalrecord.Quote__c  = opportunityQuoteMap[opportunityId];
                                    } else if (!oppid){
                                        approvalrecord.Opportunity__c = opportunityId;
                                        approvalrecord.Quote__c  = opportunityQuoteMap[opportunityId];
                                        break;
                                    }
                                }
                            }

                            if (approvalrecord.Quote__c != null && approvalrecord.Opportunity__c != null) {
                                approvalrecord.Option__c = 'Automatic';
                            } else if ((approvalrecord.Opportunity__c == null || approvalrecord.Quote__c) && oppid == null) {
                                approvalrecord.Option__c = 'Manual';
                            }
                            approvalrecord.CurrentMRR__c = retResponse.currentMRR;

                            var createRecordEvent = $A.get("e.force:createRecord");

                            createRecordEvent.setParams({
                                "entityApiName": "Approval__c",
                                "recordTypeId": (retResponse.recordType == null) ? recordTypeId : retResponse.recordType,
                                'defaultFieldValues': approvalrecord
                            });
                            createRecordEvent.fire();
                        }
                    }
                } else {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "There is some error while processing",
                        "mode": 'dismissible'
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        } else {
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Record Type is not selected!",
                "message": "Please, select Record Type",
                "mode": 'dismissible'
            });
            toastEvent.fire();
        }
    },

    cancelApprovalCreation: function(component) {

        const recordId = component.get("v.recordId");
        if (recordId != null) {
            let navigationEvent = $A.get("e.force:navigateToSObject");
            navigationEvent.setParams({
                "recordId": recordId
            });
            navigationEvent.fire();
        } else {
            let navigateLightning = component.find("navigate");
            const targetObject = component.get("v.parentObject");
            let targetPage = {
                type: "standard__objectPage",
                attributes: {
                    objectApiName: targetObject,
                    actionName: "list"
                },
                state: {
                    filterName: "Recent"
                }
            };

            navigateLightning.navigate(targetPage);
        }

        component.destroy();
    },

    showSpinner: function(component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    navigateBack : function(component, event, helper){
        var recid = component.get("v.retURL");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/"+recid
        });
        urlEvent.fire();
        component.destroy();
    },
})