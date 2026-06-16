({
    setup: function (component, event, helper) {
        const getOppRecordAction = component.get("c.getOpprecord");
        const opportunityId = component.get("v.recordId");
        getOppRecordAction.setParams({
            'recordId': opportunityId
        });
        getOppRecordAction.setCallback(this, function (response) {
            const state = response.getState();
            console.log('**state' + state);
            if (state !== "SUCCESS") {
                return;
            }
            let opps = response.getReturnValue();
            component.set("v.Rcnumber", opps[0].Account.RC_Account_Number__c);
            component.set("v.x12MonthBooking", opps[0].X12_Month_Booking__c);

            // Create a promise chain for MPUB checking and processing
            new Promise(function(resolve) {
                // First check if the account is MPUB
                const isMPUBAction = component.get("c.getIsMPUB");
                isMPUBAction.setParams({
                    'accountId': opps[0].Account.Id
                });

                isMPUBAction.setCallback(this, function(isMPUBResponse) {
                    let isMPUB = isMPUBResponse.getReturnValue();
                    resolve({ isMPUB, opps });
                });

                $A.enqueueAction(isMPUBAction);
            })
            .then($A.getCallback(result => {
                // If account is MPUB, get technical quote IDs
                if (!result.isMPUB || result.opps.length > 1) {
                    return result;
                }
                return new Promise(function(resolve) {
                    const techQuotesAction = component.get("c.getMPUBTechnicalQuotesIds");
                    techQuotesAction.setParams({
                        'oppId': opportunityId
                    });

                    techQuotesAction.setCallback(this, function(techResponse) {
                        if (techResponse.getState() === "SUCCESS") {
                            let techQuoteIds = techResponse.getReturnValue();
                            resolve({
                                isMPUB: result.isMPUB,
                                opps: result.opps,
                                techQuoteIds: techQuoteIds
                            });
                        } else {
                            resolve(result);
                        }
                    });

                    $A.enqueueAction(techQuotesAction);
                });
            }))
            .then($A.getCallback(result => {
                // Process based on results
                if(result.opps.length > 1) {
                    // Multi-product case
                    component.set("v.isMPLClose", true);
                    helper.closeMultiproduct(component, event, helper, result.opps, this.rcnotify);
                } else if (result.isMPUB && result.techQuoteIds && result.techQuoteIds.length > 0) {
                    // MPUB case with technical quotes
                    component.set("v.isMPUBClose", true);
                    let params = {
                        opportunityId: opportunityId,
                        techQuoteIds: result.techQuoteIds,
                        opps: result.opps
                    };
                    helper.closeMultiproductUB(component, event, helper, params, this.rcnotify);
                } else {
                    // Standard case
                    let closeParams = helper.getCloseParams(result.opps);
                    helper.close(component, event, helper, closeParams, this.rcnotify);
                }
            }));
        });
        $A.enqueueAction(getOppRecordAction);
    },

    showSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    provideRCNumber: function (component, event, helper) {
        component.set("v.isGenerateorderprompt", false);
        component.set("v.isRCnumberprompt", true);

        console.log('Inside provideRCNumber');

    },// Form C

    provideCCNumber: function (component, event, helper) {
        component.set("v.isGenerateorderprompt", false);
        component.set("v.isRCnumberprompt", false);
        component.set("v.isCCnumberprompt", true);
        var Rcnumberinput = component.get("v.Rcnumberinput");
        var Rcnumber = component.get("v.Rcnumber");
        console.log('Inside provideCCNumber');

        var promptContent = '<p>What is the primary call center number for the customer? It will show up as the caller ID for this call center</p>';

        if (Rcnumber != null && Rcnumberinput == null) {
            promptContent = '<p>Main number on the RingCentral account: <b>' + Rcnumber + '</b></p>' + promptContent;
        } else if (Rcnumberinput != null) {
            promptContent = '<p>Main number on the RingCentral account: <b>' + Rcnumberinput + '</b></p>' + promptContent;
        }
        // rcnotify.openPrompt(promptOptions, finalCallback.bind(null, rcNumberInput));
    },

    generateorders: function (component, event, helper) {
        var Rcnumber = component.get("v.Rcnumberinput");
        var CCnumber = component.get("v.CCnumber");
        var recId = component.get("v.recordId");
        var closeBackendMethodParams = {
            opportunityId: recId,
            rcNumber: Rcnumber,
            ccNumber: CCnumber
        };
        var closeParams = {
            opportunityId: recId,
            x12MonthBooking: component.get('v.x12MonthBooking'),
        };
        helper.apexWebServicesCloseProcessWrapper(component, event, helper, closeBackendMethodParams, rcnotify, closeParams);
    },

    closeModel: function (component, event, helper) {
        if (component.get("v.isGenerateorderprompt")) {
            // Set isModalOpen attribute to false
            component.set("v.isGenerateorderprompt", false);
        } else if (component.get("v.isRCnumberprompt")) {
            component.set("v.isRCnumberprompt", false);
        } else if (component.get("v.isCCnumberprompt")) {
            component.set("v.isCCnumberprompt", false);
        } else if (component.get("v.isShowRecallELPrompt")) {
            component.set("v.isShowRecallELPrompt", false);
        }
    },

    checkRC: function (component, event, helper) {
        var Rcnumberacc = component.get("v.Rcnumber");
        component.set("v.isGenerateorderprompt", false);
        if (Rcnumberacc == 'undefined' || Rcnumberacc == null) {
            component.set("v.isRCnumberprompt", true);
        } else {
            component.set("v.Rcnumberinput", Rcnumberacc);
            component.set("v.isCCnumberprompt", true);
        }
    },

    Recallengagement: function (component, event, helper) {
        var approvalid = component.get("v.approvalid");
        var closeBackendMethodParams = {
            approvalid: approvalid
        }
        var closeParams = {
            opportunityId: recId,
            x12MonthBooking: component.get('v.x12MonthBooking'),
        };
        helper.apexWebServicesCloseProcessWrapper(component, event, helper, closeBackendMethodParams, rcnotify, closeParams);
    },

    closeQuickActionWindow: function () {
        $A.get("e.force:closeQuickAction").fire();
    },
})