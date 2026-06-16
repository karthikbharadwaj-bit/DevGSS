({
    doInit: function(component, event, helper) {
        helper.setValues(component);
        helper.checkInputs(component);
        helper.showHideTab(component);
        component.set('v.tabName', component.getLocalId());
    },
    caseTypeChange: function(component, event, helper){
        helper.showHideTab(component);
    },
    csatPredictionDataChange: function(component) {
        const csatPrediction = component.get('v.csatPrediction')
        const csatPredictionData = component.get('v.csatPredictionData')
        if (!csatPrediction && csatPredictionData.length > 0) {
            component.set('v.csatPrediction', csatPredictionData[0].value);
        }
    },
    csatPredictionAfterManagerCallbackDataChange : function(component) {
        const csatPredictionAMC = component.get('v.csatPredictionAMC')
        const csatPredictionAfterManagerCallbackData = component.get('v.csatPredictionAfterManagerCallbackData')
        if (!csatPredictionAMC && csatPredictionAfterManagerCallbackData.length > 0) {
            component.set('v.csatPredictionAMC', csatPredictionAfterManagerCallbackData[0].value);
        }
    },
    changeResolveType: function(component, event, helper){
        var closeInternalWorkflowRequired = component.get('v.closeInternalWorkflowRequired');
        var caseObj = component.get('v.caseObj');
        if (caseObj.Status === 'Closed' || caseObj.Status === 'Closed - No Response') {
            // do nothing
        } else {
            if (!closeInternalWorkflowRequired) {
                var resolveNow = event.target.dataset.value;
                component.set('v.resolveNow',!!resolveNow);
            } else {
                component.set('v.resolveNow',true);
            }
        }

    },

    validateOpenInternalWorkflowRequiredChange: function(component, event, helper){
        helper.validateOpenInternalWorkflowRequired(component, {suppressIfEmpty:true});
        helper.pushChangesToRecordRecord(component);
    },
    validateCloseInternalWorkflowRequiredChange: function(component, event, helper){
        helper.validateCloseInternalWorkflowRequired(component, {suppressIfEmpty:true});
        helper.pushChangesToRecordRecord(component);
    },
    validateProductRequiredChange: function(component, event, helper){
        helper.validateProductRequired(component, {suppressIfEmpty:true});
        helper.pushChangesToRecordRecord(component);
    },
    save: function(component, event, helper){
        helper.save(component);
    },
    discard: function(component, event, helper){
        helper.discard(component);
    },
    caseObjChange: function(component, event, helper){
        helper.checkInputs(component);
    },

    pushChangesToRecordRecord: function(component, event, helper){
        helper.pushChangesToRecordRecord(component);
    },

    validate: function(component, event, helper){
        return helper.validate(component);
    },

    clearInputs: function(component, event, helper) {
        var tabModified = event.getParam('tab');
        if(component.getLocalId() !== tabModified) helper.clearInputs(component);
    },
    changeActionfire: function(component) {
        $A.get("e.c:CaseTaggingToolPickListChangeEvent").setParams({
          tab: component.get('v.tabName')
        }).fire();
    }
});