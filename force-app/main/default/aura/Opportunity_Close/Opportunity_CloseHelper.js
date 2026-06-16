({
    close: function (component, event, helper, closeParams, rcnotify) {
        console.log('closeParams: ' + JSON.stringify(closeParams));
        console.log('rcnotify: ', rcnotify);
        rcnotify.removeAllToasts();
        rcnotify.showSpinner();
        const params = {
            opportunityId: closeParams.opportunityId
        };
        this.apexWebServicesCloseProcessWrapper(component, event, helper, params, rcnotify, closeParams);

    },

    closeMultiproduct: function (component, event, helper, opps, rcnotify) {
        let oppToServiceMap = new Map();
        opps.forEach(oppty => {
            oppToServiceMap.set(oppty.Id, component.get("v.tierNameToService")[oppty.Tier_Name__c]);
        });
        component.set("v.oppIdToService", oppToServiceMap);

        this.validateMultiProduct(component, event, helper, opps, rcnotify)
    },

    closeMultiproductUB: function (component, event, helper, params, rcnotify) {
        this.validateMultiProductUB(component, event, helper, params, rcnotify)
    },

    validateMultiProduct: function (component, event, helper, opps, rcnotify) {
        let isValidationsCompleted = false;

        opps.forEach(oppty => {
            var params = {
                opportunityId: oppty.Id
            };
            helper.apexWebServicesCloseProcess(component, event, helper, params, rcnotify)
                .catch($A.getCallback(err => {
                    rcnotify.hideSpinner();
                    var toastEvent = $A.get("e.c:ToastEvent");
                    toastEvent.setParams({
                        "theme": 'error',
                        "header": 'Close Process Error',
                        "details": err
                    });
                    toastEvent.fire();
                }))
                .finally(() => {
                    rcnotify.hideSpinner();
                    if (!isValidationsCompleted && !component.get("v.isMPLHasError")) {
                        isValidationsCompleted = true;
                        let closeParams = helper.getCloseParams(opps);
                        let validationResponse = component.get("v.validationResponse");
                        helper.handleResponse(component, validationResponse, closeParams);
                    }
                });
        });
    },

    validateMultiProductUB: function (component, event, helper, params, rcnotify) {
        Promise.all(params.techQuoteIds.map(techQuoteId => {
            const validateParams = {
                opportunityId: params.opportunityId,
                mpUbTechQuoteId: techQuoteId
            };
            return helper.apexWebServicesCloseProcess(component, event, helper, validateParams, rcnotify);
        }))
        .then($A.getCallback(() => this.closeMPUBOppty(component, params.opps[0], rcnotify)))
        .catch($A.getCallback(err => {
            rcnotify.hideSpinner();
            var toastEvent = $A.get("e.c:ToastEvent");
            toastEvent.setParams({
                "theme": 'error',
                "header": 'Close Process Error',
                "details": err
            });
            toastEvent.fire();
        }))
        .finally(() => {
            rcnotify.hideSpinner();
            if (component.get("v.isMPUBHasError")) {
                return;
            }
            const closeParams = helper.getCloseParams(params.opps);
            const validationResponse = component.get("v.validationResponse");
            helper.handleResponse(component, validationResponse, closeParams);
        });
    },

    closeMPUBOppty: function (component, oppty, rcnotify) {
        if (component.get("v.isMPUBHasError")) {
            return Promise.resolve();
        }
        if (component.get("v.validationResponse").data.closeWizardURL) {
            return Promise.resolve();
        }
        if (oppty.Estimated_12M_Total_Pipeline__c < 0) {
            return Promise.resolve();
        }
        const closeOpptyParams = {
            wType: 'close',
            brandName: oppty.Brand_Name__c,
            isInline: false,
            Id: oppty.Id
        };
        return new Promise(function (resolve, reject) {
            const action = component.get("c.closeOpptyMPUB");
            action.setParams({
                "closeOpportunityParams": JSON.stringify(closeOpptyParams)
            });
            action.setCallback(this, (response) => {
                if (response.getReturnValue().status !== 'success') {
                    reject('An error occurred while closing the opportunity. Please contact the administrator.');
                }
                resolve();
            });
            $A.enqueueAction(action);
        })
    },

    getCloseParams: function(opps) {
        return {opportunityId: opps[0].Id,
                isBillingOpportunity: opps[0].Is_Billing_Opportunity__c,
                opportunityBrandName: opps[0].Brand_Name__c,
                opportunityRecordTypeId: opps[0].RecordTypeId,
                x12MonthBooking: opps[0].X12_Month_Booking__c,
                estimatedX12MonthTotalPipeline: opps[0].Estimated_12M_Total_Pipeline__c
        };
    },

    apexWebServicesCloseProcessWrapper: function (component, event, helper, params, rcnotify, closeParams) {
        this.apexWebServicesCloseProcess(component, event, helper, params, rcnotify)
            .then($A.getCallback(response => {
                rcnotify.hideSpinner();
                console.log('Before handle');
                console.log('Response' + JSON.stringify(response));
                console.log(response.data.isCCPhoneNumbersRequired);
                helper.handleResponse(component, response, closeParams);
            }))
            .catch($A.getCallback(err => {
                rcnotify.hideSpinner();
                var toastEvent = $A.get("e.c:ToastEvent");
                toastEvent.setParams({
                    "theme": 'error',
                    "header": 'Close Process Error',
                    "details": err
                });
                toastEvent.fire();
            }));
    },

    apexWebServicesCloseProcess: function (component, event, helper, closeBackendMethodParams, rcnotify) {
        return new Promise(function (resolve, reject) {
            const action = component.get("c.closeOppty");
            console.log(component.get("v.recordId"));

            const isMPL = component.get("v.isMPLClose");
            const isMPUB = component.get("v.isMPUBClose");
            const serviceName = isMPL ? component.get("v.oppIdToService").get(closeBackendMethodParams.opportunityId) : '';
            action.setParams({
                "closeOpportunityParams": JSON.stringify(closeBackendMethodParams)
            });

            action.setCallback(this, function (response) {

                const state = response.getState();
                const validateResultSerialized = response.getReturnValue();
                const resp = JSON.parse(response.getReturnValue());
                console.log('resp-validateopp' + validateResultSerialized);
                let infoMessages = '';

                if (state == 'SUCCESS' && resp.messages.length) {
                    rcnotify.hideSpinner();
                    if (isMPL) {
                        component.set("v.isMPLHasError", true);
                    } else if (isMPUB) {
                        component.set("v.isMPUBHasError", true);
                    }
                    resp.messages.forEach(message => {
                        if (message.severity != 'warning') {
                            const header = isMPL ? (serviceName + ': ' + message.message) : message.message;
                            const toastEvent = $A.get("e.c:ToastEvent");
                            toastEvent.setParams({
                                "theme": message.severity,
                                "header": header,
                                "details": message.messageDetails,
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                        } else {
                            if (!infoMessages.includes(message.messageDetails + '</br>')) {
                                infoMessages += message.messageDetails + '</br>';
                            }
                        }
                    });

                    for (let k = resp.messages.length-1; k >= 0; k--) {
                        if (infoMessages.includes(resp.messages[k].messageDetails)) {
                            resp.messages.splice(k, 1);
                            continue;
                        }
                    }

                    if (state == 'SUCCESS' && !resp.messages.length && infoMessages != '') {
                        const warningMessage = $A.get("e.c:ModalRequestEvent").setParams({
                            header: 'Device Availability Info',
                            content: infoMessages + 'Would you like to proceed?',
                            layout: 'large',
                            buttons: [
                                {
                                    label: 'Ok',
                                    variant: 'brand',
                                    callback: () => {
                                        resolve(resp);
                                    }
                                },
                                {
                                    label: 'Cancel',
                                    variant: 'brand',
                                    callback: () => {
                                        component.set('v.isActionDone', true);
                                    }
                                }
                            ],
                            isCancelShown: false
                        });
                        warningMessage.fire();
                    }
                } else if (state == 'SUCCESS' && !resp.messages.length) {
                    // every MPUB response will contain
                    if (isMPL && serviceName === 'MVP' || isMPUB) {
                        component.set("v.validationResponse", resp);
                    }
                    resolve(resp);
                } else {
                    if (isMPL) {
                        component.set("v.isMPLHasError", true);
                    } else if (isMPUB) {
                        component.set("v.isMPUBHasError", true);
                    }
                    const error = response.getError();
                    const errMsg = error && error[0] && error[0].message;
                    reject(errMsg || 'Unknown error');
                }
            });
            $A.enqueueAction(action);
        });
    },

    handleResponse: function (component, response, closeParams) {
        console.log('in handle response');
        this.showErrors(response);
        console.log('URL' + response.data.closeWizardURL);
        console.log('ccresp' + response.data.isCCPhoneNumbersRequired);

        if (response.data.isCCPhoneNumbersRequired == true) {
            component.set("v.isGenerateorderprompt", true);
            component.set("v.Rcnumber", response.data.RCAccountNumber);
        } else if (response.data.isShowRecallELPrompt) {
            component.set("v.approvalid", response.data.approvalId);
            component.set("v.isShowRecallELPrompt", response.data.isShowRecallELPrompt);
        } else if (response.data.closeWizardURL) {
            var URL = response.data.closeWizardURL;
            console.log('URl' + URL)
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                'url': URL
            });
            urlEvent.fire();
            component.set('v.isActionDone', true);
        }
        if (closeParams && closeParams.estimatedX12MonthTotalPipeline < 0) {
            console.log('opportunityId' + closeParams.opportunityId);
            var win = window.location = "/apex/Downgrade_X12_Month_Booking?id=" + closeParams.opportunityId;
            console.log('win' + win);
            var timer = setInterval(function () {
                if (win.closed) {
                    clearInterval(timer);
                    window.location.reload(); // Refresh the parent page
                }
            }, 1000);
        } else {
            $A.get('e.force:refreshView').fire();
            component.set('v.isActionDone', true);
        }
    },

    showErrors: function (response) {
        response.messages.forEach(function (error) {
            rcnotify.addToast({
                theme: error.severity,
                header: error.message,
                details: error.messageDetails
            });
        });
    },

    provideRCNumber: function (helper, rcnotify, rcNumber) {
        console.log('Inside provideRCNumber');
        var promptOptions = {
            header: 'Generate Orders',
            content: 'Please provide the number that will become the RingCentral main number',
            inputLabel: 'RingCentral main number',
            inputType: 'text',
            inputRequired: true,
            trueButtonText: 'Submit'
        };
        //rcnotify.openPrompt(promptOptions, helper.provideCCNumber(rcnotify,rcNumber));
        rcnotify.openPrompt(promptOptions, () => {
            helper.provideCCNumber(rcnotify, rcNumber);
        });
    },// Form C


    provideCCNumber: function (rcnotify, rcNumber, rcNumberInput) {
        console.log('Inside provideCCNumber');
        var promptContent = '<p>What is the primary call center number for the customer? It will show up as the caller ID for this call center</p>';

        if (rcNumber && !rcNumberInput) {
            promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumber + '</b></p>' + promptContent;
        } else if (rcNumberInput) {
            promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumberInput + '</b></p>' + promptContent;
        }

        var promptOptions = {
            header: 'Generate Orders',
            content: promptContent,
            inputLabel: 'Customer primary call center number',
            inputType: 'text',
            trueButtonText: 'Generate Orders'
        };

        // rcnotify.openPrompt(promptOptions, finalCallback.bind(null, rcNumberInput));
    },
// Form A

    open: function (component, event, helper, rcnotify, rcNumber, finalCallback) {


        var isPortingNumber = function isPortingNumber() {
            var promptOptions = {
                header: 'Generate Orders',
                content: 'Is the customer porting in a number that will become the RingCentral main number?',
                trueButtonText: 'Yes',
                falseButtonText: 'No'
            };
            helper.provideRCNumber(helper, rcnotify, rcNumber);

            rcnotify.openPrompt(promptOptions,
                function () {
                    helper.provideRCNumber(helper, rcnotify, rcNumber)
                });
        }; // Form B
        isPortingNumber();
    }

})