({
    caseTypeTab: function(component) {
        var caseTypeInternalWorkflow = component.find('caseTypeInternalWorkflow');
        var caseTypeCustomerSupport = component.find('caseTypeCustomerSupport');
        var caseType = component.get('v.caseType');
        switch (caseType) {
            case "Customer Support":
                $A.util.addClass(caseTypeCustomerSupport, "slds-active");
                $A.util.removeClass(caseTypeInternalWorkflow, "slds-active");
                break;
            case "Internal Workflow":
                $A.util.addClass(caseTypeInternalWorkflow, "slds-active");
                $A.util.removeClass(caseTypeCustomerSupport, "slds-active");
                break;
            default:
                $A.util.removeClass(caseTypeInternalWorkflow, "slds-active");
                $A.util.removeClass(caseTypeCustomerSupport, "slds-active");
        }
    },
    saveCase: function(component, caseObj) {
        console.log('saveCase', caseObj);

        var spinner = component.find('spinner');
        $A.util.removeClass(spinner, "slds-hide");

        //TODO convert fields to string
        var params = caseObj;

        // call server side saveCaseAction action
        console.log('call c.saveCaseAction');
        var action = component.get("c.saveCaseAction");
        action.setParams({ params: params })
        action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (component.isValid() && state === "SUCCESS") {
                    var newCaseObj = response.getReturnValue();
                    console.log("From server: ",newCaseObj);
                    component.set('v.caseObj',newCaseObj);
                }
                else if (component.isValid() && state === "INCOMPLETE") {
                    // do something
                }
                else if (component.isValid() && state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        console.log(errors);
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
                $A.util.addClass(spinner, "slds-hide");
            });
        $A.enqueueAction(action);
    },
    loadData: function(component){
        var helper = this;
        RC.salesforce.request(component, 'c.getPicklistValues', {}, null, true)
            .then($A.getCallback(function(data) {
                var picklists = JSON.parse(data);

                var openCustomerSupportData = helper.buildTree({
                    level_1_2: JSON.parse(picklists.OpenCustomerSupportLevel1__c),
                    level_2_3: JSON.parse(picklists.OpenCustomerSupportLevel2__c)
                });
                
                var ptToOpenCSL1Map        = JSON.parse(picklists.PT_to_OpenCSL1__c || '{}');
                var openCSL3ToCloseCSL3Map = JSON.parse(picklists.OpenCSL3_to_CloseCSL3__c || '{}');
                
                // Close Customer Support Level 3 as separate data                
                var closeCustomerSupportData = JSON.parse(picklists.CloseCustomerSupportLevel3__c);
                var closeCustomerSupportLevel3Data = closeCustomerSupportData.map(function(item) {
                    return { label: item.label, value: item.value };
                });                

                var productData = helper.buildTree({
                        level_1_2: JSON.parse(picklists.ProductType__c)
                });               
                
                // CS Product Type standalone options now come from ProductType_CS__c
                var productTypeCSRaw = JSON.parse(picklists.ProductType_CS__c);
                var productValuesData = (productTypeCSRaw || []).map(function(opt){
                    return { label: opt.label, value: opt.value };
                });

                var openInternalWorkflowData = helper.buildTree({
                    level_1_2: JSON.parse(picklists.OpenInternalWorkflowLevel1__c),
                    level_2_3: JSON.parse(picklists.OpenInternalWorkflowLevel2__c)
                });

                var closeInternalWorkflowData = helper.buildTree({
                    level_1_2: JSON.parse(picklists.CloseInternalWorkflowLevel1__c),
                    level_2_3: JSON.parse(picklists.CloseInternalWorkflowLevel2__c)
                });

                var csatPredictionAfterManagerCallbackData = JSON.parse(picklists.CSAT_Prediction_after_Manager_Callback__c);
                var csatPredictionData = JSON.parse(picklists.CSAT_Prediction__c);

                component.set('v.openCustomerSupportData',openCustomerSupportData);
                component.set('v.closeCustomerSupportLevel3Data', closeCustomerSupportLevel3Data);
                component.set('v.productData',productData);
                component.set('v.productValuesData', productValuesData);
                
                component.set('v.openInternalWorkflowData',openInternalWorkflowData);
                component.set('v.closeInternalWorkflowData',closeInternalWorkflowData);
                component.set('v.csatPredictionAfterManagerCallbackData',[{label: '--None--', value: ''}, ...csatPredictionAfterManagerCallbackData]);
                component.set('v.csatPredictionData',[{label: '--None--', value: ''}, ...csatPredictionData]);
                component.set('v.ptToOpenCSL1Map',        ptToOpenCSL1Map);
                component.set('v.openCSL3ToCloseCSL3Map', openCSL3ToCloseCSL3Map);
            }))
            .catch($A.getCallback(RC.salesforce.displayError.bind(null, 'Failed to get Picklist values')))
    },

    // build tree for use in dependent picklist
    buildTree: function(picklistsData) {
        var picklistTree = [];
        // level 1
        if (picklistsData.level_1_2) {
            for (var l1 in picklistsData.level_1_2) {
                var l1Item = {};
                l1Item.text = l1;
                var l1ItemValues = [];
                l1ItemValues.push(l1Item.text);
                l1Item.value = JSON.stringify(l1ItemValues);
                l1Item.childs = [];

                // level 2
                for (var l2 in picklistsData.level_1_2[l1Item.text]) {
                    var l2Item = {};
                    l2Item.text = picklistsData.level_1_2[l1Item.text][l2];
                    var l2ItemValues = [];
                    l2ItemValues.push(l1Item.text);
                    l2ItemValues.push(l2Item.text);
                    l2Item.value = JSON.stringify(l2ItemValues);
                    l2Item.childs = [];

                    // level 3
                    if (picklistsData.level_2_3 && picklistsData.level_2_3[l2Item.text]) {
                        for (var l3 in picklistsData.level_2_3[l2Item.text]) {
                            var l3Item = {};
                            l3Item.text = picklistsData.level_2_3[l2Item.text][l3];
                            var l3ItemValues = [];
                            l3ItemValues.push(l1Item.text);
                            l3ItemValues.push(l2Item.text);
                            l3ItemValues.push(l3Item.text);
                            l3Item.value = JSON.stringify(l3ItemValues);
                            l2Item.childs.push(l3Item);
                        }
                    }
                    l1Item.childs.push(l2Item);
                }
                picklistTree.push(l1Item);
            }
        }
        return picklistTree;
    },

    addCaseCreationPageListener: function(component){
        window.addEventListener("CaseCreationPage.saveRequest", function(){

            var isValid;
            if(component.get('v.caseType') === 'Internal Workflow'){
                component.find('CaseTaggingToolInternalWorkflow').pushChangesToRecord();
                isValid = component.find('CaseTaggingToolInternalWorkflow').validate();

            } else {
                component.find('CaseTaggingToolCustomerSupport').pushChangesToRecord();
                isValid = component.find('CaseTaggingToolCustomerSupport').validate();
            }

            window.dispatchEvent(new CustomEvent("CaseTaggingTool.saveResponse", {
                detail: {
                    isValid: isValid,
                    record: component.get('v.record')
                }
            }));
        });
    }
});