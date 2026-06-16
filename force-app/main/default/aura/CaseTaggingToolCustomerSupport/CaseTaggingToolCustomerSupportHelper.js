({
    setValues: function(component) {
        var caseObj = component.get('v.caseObj');
        var caseType = component.get('v.caseType');
        component.set('v.csatPrediction', caseObj.CSAT_Prediction__c);
        component.set('v.csatPredictionAMC', caseObj.CSAT_Prediction_after_Manager_Callback__c);
        component.set('v.isCleaned', false);
        var openCustomerSupportValues = [];
        if (caseObj.OpenCustomerSupportLevel1__c) {
            openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel1__c);
            if (caseObj.OpenCustomerSupportLevel2__c) {
                openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel2__c);
                if (caseObj.OpenCustomerSupportLevel3__c) {
                    openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel3__c);
                }
            }
        }
        component.set('v.openCustomerSupportValues', openCustomerSupportValues);
        if(openCustomerSupportValues.length !== 0 || caseType === undefined) component.set('v.caseType','Customer Support');
        
        // Detect if Internal Workflow tab has data
        var internalHasAny = !!(
            caseObj.OpenInternalWorkflowLevel1__c || caseObj.OpenInternalWorkflowLevel2__c || caseObj.OpenInternalWorkflowLevel3__c ||
            caseObj.CloseInternalWorkflowLevel1__c || caseObj.CloseInternalWorkflowLevel2__c || caseObj.CloseInternalWorkflowLevel3__c ||
            caseObj.ProductVersionModelPlatform__c
        );
        
        // Detect if CS already has its own data
        var csHasAny = (openCustomerSupportValues.length > 0) ||
            !!caseObj.CloseCustomerSupportLevel3__c ||
            !!(caseObj.Final_Fix__c && caseObj.Final_Fix__c.trim && caseObj.Final_Fix__c.trim().length);
        
        // Mask only when IW has data and CS doesn’t
        var mask = internalHasAny && !csHasAny;
        component.set('v.maskProductOnCS', mask);        
        // Show blank in the CS UI when masked; otherwise show actual case value
        component.set('v.productValue', mask ? '' : (caseObj.ProductType_CS__c || ''));
        component.set('v.finalFix',     mask ? '' : (caseObj.Final_Fix__c   || ''));     
        component.set('v.closeCustomerSupportLevel3Value', caseObj.CloseCustomerSupportLevel3__c);
        
        // Ensure current values are visible even if not in the options/mapping        
        this.ensureCurrentOptionVisible(component, 'productValuesData', 'productValue');
        this.ensureCurrentOptionVisible(component, 'closeCustomerSupportLevel3FilteredData', 'closeCustomerSupportLevel3Value');       
        this.checkUserProfile(component);
        
        var closeCustomerSupportLevel3Value = caseObj.CloseCustomerSupportLevel3__c;
        if (closeCustomerSupportLevel3Value) {
            component.set('v.resolveNow', true);
        } else {
            component.set('v.resolveNow', false);
        }
        this.filterOpenCSByProduct(component);  // NEW
        this.filterCloseL3ByOpenL3(component);  // NEW
        this.ensureCurrentOptionVisible(component, 'productValuesData', 'productValue');
        this.ensureCurrentOptionVisible(component, 'closeCustomerSupportLevel3FilteredData', 'closeCustomerSupportLevel3Value');
        component.set('v.isInitComplete', true);
    },
    recomputeMaskFromRecord: function(component){
        var rec = component.get('v.record') || {};
        var openCS = component.get('v.openCustomerSupportValues') || [];
        var csHasAny =
            (openCS.length > 0) ||
            !!component.get('v.closeCustomerSupportLevel3Value') ||
            !!(component.get('v.productValue') && component.get('v.productValue').trim().length) ||
            !!(component.get('v.finalFix')     && component.get('v.finalFix').trim().length);
        
        var internalHasAny = !!(
            rec.OpenInternalWorkflowLevel1__c || rec.OpenInternalWorkflowLevel2__c || rec.OpenInternalWorkflowLevel3__c ||
            rec.CloseInternalWorkflowLevel1__c || rec.CloseInternalWorkflowLevel2__c || rec.CloseInternalWorkflowLevel3__c ||
            rec.ProductVersionModelPlatform__c
        );
        
        var nextMask = internalHasAny && !csHasAny;
        var prevMask = component.get('v.maskProductOnCS');
        
        if (nextMask !== prevMask) {
            component.set('v.maskProductOnCS', nextMask);
            // When Internal Workflow tab owns it, blank the CS UI so the user sees that Customer Support does not own these fields
            if (nextMask) {
                if (component.get('v.productValue')) component.set('v.productValue', '');
                if (component.get('v.finalFix'))     component.set('v.finalFix', '');
            }
        }
    },
    checkUserProfile: function(component){
        var action = component.get("c.getFinalFixMode");
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                component.set("v.finalFixMode", resp.getReturnValue() || 'READONLY');
            } else {
                // Safe fallback
                component.set("v.finalFixMode", 'READONLY');
                console.error('Error retrieving Final Fix mode');
            }
        });
        $A.enqueueAction(action);
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
                    var openCustomerSupportReadonly = false;
                    var closeCustomerSupportReadonly = false;
                    var productReadonly = false;
                    var resolveNow = false;
                    break;
                case "Resolved":
                    // "Function", "Specific Action being taken", "Where the action was taken if needed" in "What did you do to resolve the issue?" sections are editable and required
                    var openCustomerSupportReadonly = false;
                    var closeCustomerSupportReadonly = false;
                    var productReadonly = false;
                    var resolveNow = true;
                    break;
                case "Closed":
                case "Closed - No Response":
                    // "Function", "Specific Action being taken", "Where the action was taken if needed" in "What did you do to resolve the issue?" sections are locked and show current selected choices
                    var openCustomerSupportReadonly = true;
                    var closeCustomerSupportReadonly = true;
                    var productReadonly = true;
                    var resolveNow = false;
                    break;
                default:
                    var openCustomerSupportReadonly = false;
                    var closeCustomerSupportReadonly = false;
                    var productReadonly = false;
                    var resolveNow = false;
            }
            component.set('v.openCustomerSupportReadonly', openCustomerSupportReadonly);
            component.set('v.closeCustomerSupportReadonly', closeCustomerSupportReadonly);
            component.set('v.productReadonly', productReadonly);
            if (resolveNow) {
                component.set('v.resolveNow',true);
            }
        }
    },
    save: function(component) {
        if (this.validate(component)) {
            // make sure mask reflects the latest changes on either tab
            this.recomputeMaskFromRecord(component);
            var masked = component.get('v.maskProductOnCS') === true;
            
            var caseId = component.get('v.caseObj.Id');
            var openVals = component.get('v.openCustomerSupportValues');
            var productValue = component.get('v.productValue');
            var csatPredictionAMC = component.get('v.csatPredictionAMC');
            var csatPrediction    = component.get('v.csatPrediction');
            var closeL3           = component.get('v.closeCustomerSupportLevel3Value');
            var finalFix          = component.get('v.finalFix');
            
            var caseObj = {
                Id: caseId,
                OpenCustomerSupportLevel1__c: openVals[0] || null,
                OpenCustomerSupportLevel2__c: openVals[1] || null,
                OpenCustomerSupportLevel3__c: openVals[2] || null,
                CSAT_Prediction_after_Manager_Callback__c: csatPredictionAMC,
                CSAT_Prediction__c: csatPrediction,
                CloseCustomerSupportLevel3__c: closeL3,
                ProductType__c: null,
                // Always clear Internal Workflow fields from the Customer Support tab payload, as before
                ProductVersionModelPlatform__c: null,
                OpenInternalWorkflowLevel1__c: null,
                OpenInternalWorkflowLevel2__c: null,
                OpenInternalWorkflowLevel3__c: null,
                CloseInternalWorkflowLevel1__c: null,
                CloseInternalWorkflowLevel2__c: null,
                CloseInternalWorkflowLevel3__c: null
            };
            
            if (!masked && productValue && productValue.trim() !== '') {
                caseObj.ProductType_CS__c = productValue;
            }
            if (!masked && component.get('v.finalFixMode') === 'EDIT') {
                caseObj.Final_Fix__c = finalFix;
            }
            
            component.getEvent("SaveCase").setParams({
                status: 'new',
                caseObj: caseObj
            }).fire();
        }
    }, 
    pushChangesToRecordRecord: function(component){
        var openCustomerSupportValues = component.get('v.openCustomerSupportValues');
        var productValue  = component.get('v.productValue');
        var csatPredictionAMC = component.get('v.csatPredictionAMC');
        var csatPrediction    = component.get('v.csatPrediction');
        var closeLevel3       = component.get('v.closeCustomerSupportLevel3Value');
        var finalFix          = component.get('v.finalFix');
        var record            = component.get('v.record');
        var isCleaned         = component.get('v.isCleaned');
        if (!record) return;
        
        // Recompute mask from the live shared record + current Customer Support values
        this.recomputeMaskFromRecord(component);
        var masked = component.get('v.maskProductOnCS') === true;
        
        // Mirror open levels
        record.OpenCustomerSupportLevel1__c = openCustomerSupportValues[0] || null;
        record.OpenCustomerSupportLevel2__c = openCustomerSupportValues[1] || null;
        record.OpenCustomerSupportLevel3__c = openCustomerSupportValues[2] || null;
        
        if (!isCleaned) {
            if (!masked) {
                record.ProductType_CS__c = productValue;
            }
            record.ProductVersionModelPlatform__c = null; // always clear here as before
        }
        
        record.CSAT_Prediction_after_Manager_Callback__c = csatPredictionAMC;
        record.CSAT_Prediction__c = csatPrediction;
        
        record.CloseCustomerSupportLevel1__c = null;
        record.CloseCustomerSupportLevel2__c = null;
        record.CloseCustomerSupportLevel3__c = closeLevel3;
        
        // Final Fix follows the same masking rule as Product
        if (!masked && component.get('v.finalFixMode') === 'EDIT') {
            record.Final_Fix__c = finalFix;
        }        
        component.set('v.record', record);
    },
    validateCSATPredictionRequired: function(component) {
        const csatPredictionSelect = component.find('csatPredictionSelect');
        csatPredictionSelect.showHelpMessageIfInvalid();
        return csatPredictionSelect.checkValidity();
    },    
    validateOpenCustomerSupportRequired: function(component, params) {
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        
        // Determine validity from the tokens we already track in the parent
        var openVals = component.get('v.openCustomerSupportValues') || [];
        var isValid = (openVals.length === 3);
        
        // Keep the attribute in sync for any other logic that reads it
        component.set('v.openCustomerSupportValid', isValid);
        
        if (isValid) {
            // Ensure any previous message is cleared
            component.set('v.openCustomerSupportErrors', []);
            return true;
        } else {
            this.checkIsValid(component, 'openCustomerSupportPicklist');            
            // Control the parent-side error list
            component.set(
                'v.openCustomerSupportErrors',
                suppressIfEmpty ? [] : ['This field is required']
            );
            return false;
        }
    },
    validateCloseCustomerSupportRequired: function(component, params){
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;
        var resolveNow = component.get('v.resolveNow');
        var value = component.get('v.closeCustomerSupportLevel3Value') || '';
        var isValid = !resolveNow || value !== '';
        component.set('v.closeCustomerSupportValid', isValid);
        component.set('v.closeCustomerSupportErrors', isValid ? [] : (suppressIfEmpty ? [] : ['This field is required']));
        return isValid;
    },
    validateProductRequired: function(component, params) {
        var suppressIfEmpty = params ? params.suppressIfEmpty : false;        
        // When Internal Workflow owns Product, Customer Support UI shows blank but it's valid.
        if (component.get('v.maskProductOnCS') === true) {
            component.set('v.productValid', true);
            component.set('v.productErrors', []);
            return true;
        }        
        // Compute basic validity
        var ok = !!component.get('v.productValue');
        component.set('v.productValid', ok);        
        // During init/change with suppressIfEmpty=true, don't try to poke the DOM
        if (suppressIfEmpty) {
            component.set('v.productErrors', []);
            return ok;
        }       
        // Only now (explicit validation) try to surface the native message
        var sel = component.find('prodTypeSelect'); // matches aura:id in markup
        if (sel && typeof sel.showHelpMessageIfInvalid === 'function') {
            try { sel.showHelpMessageIfInvalid(); } catch (e) { /* no-op */ }
        }        
        component.set('v.productErrors', ok ? [] : ['This field is required']);
        return ok;
    },
    showHideTab: function(component) {
        var caseType = component.get('v.caseType');
        var wrapperTab = component.find('wrapperTab');
        if (caseType === 'Customer Support') {
            $A.util.removeClass(wrapperTab, 'slds-hide');
        } else {
            $A.util.addClass(wrapperTab, 'slds-hide');
        }
    },    
    discard: function(component) {
        var caseObj = component.get('v.caseObj');
        
        var openCustomerSupportValues = [];
        var csatPredictionAMC, csatPrediction, productValue, closeLevel3, finalFixValue;
        
        if (caseObj) {
            if (caseObj.OpenCustomerSupportLevel1__c) {
                openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel1__c);
                if (caseObj.OpenCustomerSupportLevel2__c) {
                    openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel2__c);
                    if (caseObj.OpenCustomerSupportLevel3__c) {
                        openCustomerSupportValues.push(caseObj.OpenCustomerSupportLevel3__c);
                    }
                }
            }
            csatPredictionAMC = caseObj.CSAT_Prediction_after_Manager_Callback__c;
            csatPrediction    = caseObj.CSAT_Prediction__c;
            productValue      = caseObj.ProductType_CS__c || '';
            closeLevel3       = caseObj.CloseCustomerSupportLevel3__c || '';
            
            // --- recompute mask & blank the UI value if IW owns the data ---
            var internalHasAny = !!(
                caseObj.OpenInternalWorkflowLevel1__c || caseObj.OpenInternalWorkflowLevel2__c || caseObj.OpenInternalWorkflowLevel3__c ||
                caseObj.CloseInternalWorkflowLevel1__c || caseObj.CloseInternalWorkflowLevel2__c || caseObj.CloseInternalWorkflowLevel3__c ||
                caseObj.ProductVersionModelPlatform__c
            );
            var csHasAny = (openCustomerSupportValues.length > 0) ||
                !!caseObj.CloseCustomerSupportLevel3__c ||
                !!(caseObj.Final_Fix__c && caseObj.Final_Fix__c.trim && caseObj.Final_Fix__c.trim().length);
            
            var mask = internalHasAny && !csHasAny;
            component.set('v.maskProductOnCS', mask);
            if (mask) { productValue = ''; } // UI shows blank, backend untouched
            finalFixValue = mask ? '' : (caseObj.Final_Fix__c || '');
        } else {
            csatPredictionAMC = null;
            csatPrediction    = null;
            productValue      = '';
            closeLevel3       = '';
            finalFixValue     = '';
        }
        
        component.set('v.openCustomerSupportValues', openCustomerSupportValues);
        component.set('v.productValue', productValue);
        component.set('v.csatPredictionAMC', csatPredictionAMC);
        component.set('v.csatPrediction', csatPrediction);
        component.set('v.closeCustomerSupportLevel3Value', closeLevel3);
        component.set('v.finalFix', finalFixValue);
        
        // Re-sync filtered datasets with the restored values
        this.filterOpenCSByProduct(component);
        this.filterCloseL3ByOpenL3(component);
        
        if (component.get('v.reRenderOpenCSPicklist')) {
            component.set('v.reRenderOpenCSPicklist', false);
            window.setTimeout($A.getCallback(function () {
                if (component.isValid()) {
                    component.set('v.reRenderOpenCSPicklist', true);
                }
            }), 0);
        }
    },    
    // ProductType_CS__c -> OpenCustomerSupportLevel1__c    
    filterOpenCSByProduct: function(component, opts){
        var clearOnPTChange = opts && opts.clearOnPTChange;
        
        var fullTree   = component.get('v.openCustomerSupportData') || [];
        var mapPTtoL1  = component.get('v.ptToOpenCSL1Map') || {};
        var selectedPT = component.get('v.productValue') || '';
        
        if (!fullTree.length) {
            return;
        }
        
        var allowedL1 = new Set(mapPTtoL1[selectedPT] || []);
        var vals      = component.get('v.openCustomerSupportValues') || [];
        
        // Default filtered view
        var filtered = (selectedPT && allowedL1.size)
        ? fullTree.filter(l1 => allowedL1.has(l1.text))
        : fullTree;
        
        // Keep legacy node visible if needed
        if (vals[0] && !filtered.some(n => n.text === vals[0])) {
            var legacyNode = fullTree.find(n => n.text === vals[0]);
            if (legacyNode) filtered = [legacyNode].concat(filtered);
        }
               
        // If user cleared tokens and then changed Product Type, some child state can keep old rows.
        // Clearing first guarantees a fresh render.
        var forceClear = clearOnPTChange && (!vals || vals.length === 0);
        if (forceClear) {
            component.set('v.openCustomerSupportDataFiltered', []);
        }
        // Deep clone to force immediate re-render in child
        component.set('v.openCustomerSupportDataFiltered', JSON.parse(JSON.stringify(filtered)));
        
        // Clear chain only when Product Type truly changed AND current Open Customer Support Level 1 is invalid for it
        if (clearOnPTChange && selectedPT && vals[0] && !allowedL1.has(vals[0])) {
            component.set('v.openCustomerSupportValues', []);
            component.set('v.closeCustomerSupportLevel3Value', '');
        }
    },  
    // OpenCustomerSupportLevel3__c -> CloseCustomerSupportLevel3__c
    filterCloseL3ByOpenL3: function(component){
        var fullCloseL3 = component.get('v.closeCustomerSupportLevel3Data') || [];
        var map         = component.get('v.openCSL3ToCloseCSL3Map') || {};
        var openVals    = component.get('v.openCustomerSupportValues') || [];
        var selectedL3  = openVals[2] || '';
        
        if (!fullCloseL3.length || !Object.keys(map).length) {
            return;
        }
        
        var filtered = fullCloseL3;
        if (selectedL3) {
            var allowed = new Set(map[selectedL3] || []);
            filtered = allowed.size ? fullCloseL3.filter(o => allowed.has(o.label)) : fullCloseL3;
        }
        
        var cur = component.get('v.closeCustomerSupportLevel3Value') || '';
        if (cur && !filtered.some(o => o.value === cur)) {
            filtered = [{ label: cur, value: cur, legacy: true }].concat(filtered);
        }
        
        component.set('v.closeCustomerSupportLevel3FilteredData', filtered);
    },
    // Adds the current bound value as a "legacy" option if it isn't present already    
    ensureCurrentOptionVisible: function (component, listAttr, valueAttr, labelMaker) {
        var list = component.get('v.' + listAttr) || [];
        var val  = component.get('v.' + valueAttr);
        if (val && !list.some(o => o.value === val)) {
            var label = labelMaker ? labelMaker(val) : val;
            component.set('v.' + listAttr, [{ label, value: val, legacy: true }].concat(list));
        }
    },   
    validate: function (component) {
        var bypassProduct = component.get('v.maskProductOnCS') === true;
        var mode         = component.get('v.finalFixMode');
        var resolveNow   = component.get('v.resolveNow') === true;
        
        // Close L3 is required only when resolving now
        var level3Valid = !resolveNow || !!(component.get('v.closeCustomerSupportLevel3Value'));
        
        // Final Fix is required only when resolveNow && EDIT && not masked
        var isFinalFixValid = true;
        if (resolveNow && mode === 'EDIT' && !bypassProduct) {
            var finalFixCmp = component.find('finalFixField');
            if (finalFixCmp && finalFixCmp.showHelpMessageIfInvalid) {
                finalFixCmp.showHelpMessageIfInvalid();
            }
            var v = finalFixCmp ? finalFixCmp.get('v.value') : '';
            isFinalFixValid = !!(v && v.trim().length > 0);
        }
        
        return [
            this.validateOpenCustomerSupportRequired(component),
            bypassProduct || (!!component.get('v.productValue')),
            level3Valid,
            this.validateCSATPredictionRequired(component),
            isFinalFixValid
        ].every(Boolean);
    },
    clearInputs: function(component) {
        component.set('v.isCleaned', true);
        component.set('v.openCustomerSupportValues',[]);
        component.set('v.csatPredictionAMC', []);
        component.set('v.closeCustomerSupportLevel3Value', '');
        component.set('v.productValue', '');
        component.set('v.finalFix', '');            
        component.set('v.csatPrediction', []);
        component.set('v.isCleaned', false);
    },    
    checkIsValid: function (component, cmpName) {
        var cmp = component.find(cmpName);
        if (cmp)
            cmp.checkIsValid();
    }
});