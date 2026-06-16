({
    setValues: function(component) {
        var caseObj = component.get('v.caseObj');
        component.set('v.csatPrediction', caseObj.CSAT_Prediction__c);
        component.set('v.csatPredictionAMC', caseObj.CSAT_Prediction_after_Manager_Callback__c);
        component.set('v.isCleaned', false);
        var openInternalWorkflowValues = [];
        if (caseObj.OpenInternalWorkflowLevel1__c) {
            openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel1__c);
            if (caseObj.OpenInternalWorkflowLevel2__c) {
                openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel2__c);
                if (caseObj.OpenInternalWorkflowLevel3__c) {
                    openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel3__c);
                }
            }
        }
        component.set('v.openInternalWorkflowValues', openInternalWorkflowValues);
        if(openInternalWorkflowValues.length !== 0) component.set('v.caseType','Internal Workflow');
        var productValues = [];
        if(openInternalWorkflowValues.length > 0) {
            if (caseObj.ProductType__c) {
                productValues.push(caseObj.ProductType__c);
                if (caseObj.ProductVersionModelPlatform__c) {
                    productValues.push(caseObj.ProductVersionModelPlatform__c);
                }
            }
        }
        component.set('v.productValues', productValues);

        var closeInternalWorkflowValues = [];
        if (caseObj.CloseInternalWorkflowLevel1__c) {
            closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel1__c);
            if (caseObj.CloseInternalWorkflowLevel2__c) {
                closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel2__c);
                if (caseObj.CloseInternalWorkflowLevel3__c) {
                    closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel3__c);
                }
            }
        }
        component.set('v.closeInternalWorkflowValues', closeInternalWorkflowValues);

        if (Array.isArray(closeInternalWorkflowValues) && closeInternalWorkflowValues.length > 0) {
            component.set('v.resolveNow', true);
        } else {
            component.set('v.resolveNow', false);
        }
    },
    checkInputs: function(component) {
        var caseObj = component.get('v.caseObj');
        if (caseObj) {
            switch (caseObj.Status) {
                case "New":
                case "Work In Progress":
                case "PKI Hold":
                case "Waiting on Customer":
                case "Updated by Customer":
                    // "Function", "Specific Action being taken", "Where the action was taken if needed" in "What did you do to resolve the issue?" sections are editable and not required.
                    var openInternalWorkflowReadonly = false;
                    var closeInternalWorkflowReadonly = false;
                    var productReadonly = false;
                    var productRequired = true;
                    var resolveNow = false;
                    break;
                case "Resolved":
                    // "Function", "Specific Action being taken", "Where the action was taken if needed" in "What did you do to resolve the issue?" sections are editable and required
                    var openInternalWorkflowReadonly = false;
                    var closeInternalWorkflowReadonly = false;
                    var productReadonly = false;
                    var productRequired = true;
                    var resolveNow = true;
                    break;
                case "Closed":
                case "Closed - No Response":
                    // "Function", "Specific Action being taken", "Where the action was taken if needed" in "What did you do to resolve the issue?" sections are locked and show current selected choices
                    var openInternalWorkflowReadonly = true;
                    var closeInternalWorkflowReadonly = true;
                    var productReadonly = true;
                    var productRequired = false;
                    var resolveNow = false;
                    break;
                default:
                    var openInternalWorkflowReadonly = false;
                    var closeInternalWorkflowReadonly = false;
                    var productReadonly = false;
                    var productRequired = true;
                    var resolveNow = false;
            }
            component.set('v.openInternalWorkflowReadonly', openInternalWorkflowReadonly);
            component.set('v.closeInternalWorkflowReadonly', closeInternalWorkflowReadonly);
            component.set('v.productReadonly', productReadonly);
            component.set('v.productRequired', productRequired);
            if (resolveNow) {
                component.set('v.resolveNow',true);
            }
        }
    },

    pushChangesToRecordRecord: function(component){
        var openInternalWorkflowValues = component.get('v.openInternalWorkflowValues');
        var productValues = component.get('v.productValues');
        var csatPredictionAMC = component.get('v.csatPredictionAMC');
        var csatPrediction = component.get('v.csatPrediction');
        var closeInternalWorkflowValues = component.get('v.closeInternalWorkflowValues');
        var record = component.get('v.record');
        var isCleaned = component.get('v.isCleaned');
        if (!record)
            return;

        // set values to object
        record.OpenInternalWorkflowLevel1__c = openInternalWorkflowValues[0] ? openInternalWorkflowValues[0] : null;
        record.OpenInternalWorkflowLevel2__c = openInternalWorkflowValues[1] ? openInternalWorkflowValues[1] : null;
        record.OpenInternalWorkflowLevel3__c = openInternalWorkflowValues[2] ? openInternalWorkflowValues[2] : null;
        if(!isCleaned) {
            record.ProductType__c = productValues[0] ? productValues[0] : null;
            record.ProductVersionModelPlatform__c = productValues[1] ? productValues[1] : null;
        }

        record.CSAT_Prediction_after_Manager_Callback__c = csatPredictionAMC;
        record.CSAT_Prediction__c = csatPrediction;
        
        record.CloseInternalWorkflowLevel1__c = closeInternalWorkflowValues[0] ? closeInternalWorkflowValues[0] : null;
        record.CloseInternalWorkflowLevel2__c = closeInternalWorkflowValues[1] ? closeInternalWorkflowValues[1] : null;
        record.CloseInternalWorkflowLevel3__c = closeInternalWorkflowValues[2] ? closeInternalWorkflowValues[2] : null;

        component.set('v.record', record);
    },

    save: function(component) {
        if (this.validate(component)) {
            var caseId = component.get('v.caseObj.Id');
            // get values from fields
            var openInternalWorkflowValues = component.get('v.openInternalWorkflowValues');
            var productValues = component.get('v.productValues');
            var csatPredictionAMC = component.get('v.csatPredictionAMC');
            var csatPrediction = component.get('v.csatPrediction');
            var closeInternalWorkflowValues = component.get('v.closeInternalWorkflowValues');

            // set values to object
            var caseObj = {
                    Id: caseId,
                    OpenInternalWorkflowLevel1__c: openInternalWorkflowValues[0] ? openInternalWorkflowValues[0] : null,
                    OpenInternalWorkflowLevel2__c: openInternalWorkflowValues[1] ? openInternalWorkflowValues[1] : null, 
                    OpenInternalWorkflowLevel3__c: openInternalWorkflowValues[2] ? openInternalWorkflowValues[2] : null,
                    ProductType__c: productValues[0] ? productValues[0] : null,
                    ProductVersionModelPlatform__c: productValues[1] ? productValues[1] : null,
                    CSAT_Prediction_after_Manager_Callback__c: csatPredictionAMC,
                    CSAT_Prediction__c: csatPrediction,
                    CloseInternalWorkflowLevel1__c: closeInternalWorkflowValues[0] ? closeInternalWorkflowValues[0] : null,
                    CloseInternalWorkflowLevel2__c: closeInternalWorkflowValues[1] ? closeInternalWorkflowValues[1] : null,
                    CloseInternalWorkflowLevel3__c: closeInternalWorkflowValues[2] ? closeInternalWorkflowValues[2] : null,
                    //Empty values on CaseTaggingCustomerSuuportTab 
                    OpenCustomerSupportLevel1__c : null,
                    OpenCustomerSupportLevel2__c : null,
                    OpenCustomerSupportLevel3__c : null,
                    CloseCustomerSupportLevel1__c : null,
                    CloseCustomerSupportLevel2__c : null,
                    CloseCustomerSupportLevel3__c : null,
                    ProductType_CS__c : null,
                    Final_Fix__c: null
                }
                // fire save event
            component.getEvent("SaveCase").setParams({
                status: 'new',
                caseObj: caseObj
            }).fire();
        }
    },
    validateCSATPredictionRequired: function(component) {
        const csatPredictionSelect = component.find('csatPredictionSelect');
        csatPredictionSelect.showHelpMessageIfInvalid();
        return csatPredictionSelect.checkValidity();
    },
    validateOpenInternalWorkflowRequired: function(component, params) {
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var isValidated = true;
        var errors = [];
        this.checkIsValid(component, 'openInternalWorkflowPicklist');
        var openInternalWorkflowValid = component.get('v.openInternalWorkflowValid');
        if (!openInternalWorkflowValid) {
            isValidated = false;
            if (suppressIfEmpty !== true) {
                var openInternalWorkflowErrors = ['This field is required'];
            }
        }
        component.set('v.openInternalWorkflowErrors', openInternalWorkflowErrors);
        return isValidated;
    },
    validateCloseInternalWorkflowRequired: function(component, params) {
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var isValidated = true;
        var errors = [];
        this.checkIsValid(component, 'closeInternalWorkflowPicklist');
        var closeInternalWorkflowValid = component.get('v.closeInternalWorkflowValid');
        var resolveNow = component.get('v.resolveNow');
        if(resolveNow) {
            if (!closeInternalWorkflowValid) {
                isValidated = false;
                if (suppressIfEmpty !== true) {
                    var closeInternalWorkflowErrors = ['This field is required'];
                }
            }
        }
        component.set('v.closeInternalWorkflowErrors', closeInternalWorkflowErrors);
        return isValidated;
    },
    validateProductRequired: function(component, params) {
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var productRequired = component.get('v.productRequired');
        var isValidated = true;
        var errors = [];
        if (productRequired === true) {
            this.checkIsValid(component, 'productPicklist');
            var productValid = component.get('v.productValid');
            if (!productValid) {
                isValidated = false;
                if (suppressIfEmpty !== true) {
                    var productErrors = ['This field is required'];
                }
            }
        }
        component.set('v.productErrors', productErrors);
        return isValidated;
    },
    showHideTab: function(component) {
        var caseType = component.get('v.caseType');
        var wrapperTab = component.find('wrapperTab');

        if (caseType === 'Internal Workflow') {
            $A.util.removeClass(wrapperTab, 'slds-hide');
        } else {
            $A.util.addClass(wrapperTab, 'slds-hide');
        }
    },
    discard: function(component) {
        var caseObj = component.get('v.caseObj');
        if (caseObj) {
            var openInternalWorkflowValues = [];
            if (caseObj.OpenInternalWorkflowLevel1__c) {
                openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel1__c);
                if (caseObj.OpenInternalWorkflowLevel2__c) {
                    openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel2__c);
                    if (caseObj.OpenInternalWorkflowLevel3__c) {
                        openInternalWorkflowValues.push(caseObj.OpenInternalWorkflowLevel3__c);
                    }
                }
            }
            var productValues = [];
            if (caseObj.ProductType__c) {
                productValues.push(caseObj.ProductType__c);
                if (caseObj.ProductVersionModelPlatform__c) {
                    productValues.push(caseObj.ProductVersionModelPlatform__c);
                }
            }
            var csatPredictionAMC = caseObj.CSAT_Prediction_after_Manager_Callback__c;
            var csatPrediction = caseObj.CSAT_Prediction__c;
            var closeInternalWorkflowValues = [];
            if (caseObj.CloseInternalWorkflowLevel1__c) {
                closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel1__c);
                if (caseObj.CloseInternalWorkflowLevel2__c) {
                    closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel2__c);
                    if (caseObj.CloseInternalWorkflowLevel3__c) {
                        closeInternalWorkflowValues.push(caseObj.CloseInternalWorkflowLevel3__c);
                    }
                }
            }
        } else {
            var openInternalWorkflowValues = [];
            var productValues = [];
            var closeInternalWorkflowValues = [];
            var csatPredictionAMC = null;
            var csatPrediction = null;
        }
        component.set('v.openInternalWorkflowValues', openInternalWorkflowValues);
        component.set('v.productValues', productValues);
        component.set('v.csatPredictionAMC', csatPredictionAMC);
        component.set('v.csatPrediction', csatPrediction);
        component.set('v.closeInternalWorkflowValues', closeInternalWorkflowValues);
    },

    validate: function(component){
        return [
            this.validateOpenInternalWorkflowRequired(component),
            //this.validateProductRequired(component),
            this.validateCloseInternalWorkflowRequired(component),
            this.validateCSATPredictionRequired(component)
        ].every(isValidated => isValidated);
    },

    clearInputs: function(component) {
        component.set('v.isCleaned', true);
        component.set('v.openInternalWorkflowValues', []);
        component.set('v.closeInternalWorkflowValues', []);
        component.set('v.csatPredictionAMC', []);
        component.set('v.csatPrediction', []);
        component.set('v.productValues', []);
        component.set('v.isCleaned', false);
    },

    checkIsValid: function (component, cmpName) {
        var cmp = component.find(cmpName);
        if (cmp)
            cmp.checkIsValid();
    }
});