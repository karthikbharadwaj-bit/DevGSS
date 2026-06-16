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
    changeResolveType: function(component, event){
        var closeCustomerSupportRequired = component.get('v.closeCustomerSupportRequired');
        var caseObj = component.get('v.caseObj');
        if (caseObj.Status === 'Closed' || caseObj.Status === 'Closed - No Response') {
            // do nothing
        } else {
            if (!closeCustomerSupportRequired) {
                var resolveNow = event.target.dataset.value;
                component.set('v.resolveNow',!!resolveNow);
            } else {
                component.set('v.resolveNow',true);
            }
        }
    },
    validateOpenCustomerSupportRequiredChange: function(component, event, helper){
        helper.validateOpenCustomerSupportRequired(component, {suppressIfEmpty:true});
        helper.pushChangesToRecordRecord(component);
        helper.filterCloseL3ByOpenL3(component);          
    },
    validateCloseCustomerSupportRequiredChange: function(component, event, helper){
        helper.validateCloseCustomerSupportRequired(component, { suppressIfEmpty: true });
        helper.pushChangesToRecordRecord(component);
    },         
    validateProductRequiredChange: function(component, event, helper){
        helper.validateProductRequired(component, {suppressIfEmpty:true});
        helper.pushChangesToRecordRecord(component);        
        var oldVal = event && event.getParam ? event.getParam('oldValue') : undefined;
        var newVal = component.get('v.productValue') || '';
        var userChange = component.get('v.isInitComplete') && (typeof oldVal !== 'undefined') && (oldVal !== newVal);        
        var openVals = component.get('v.openCustomerSupportValues') || [];
        if (userChange && openVals.length === 0) {
            component.set('v.reRenderOpenCSPicklist', false);
            component.set('v.openCustomerSupportDataFiltered', []);
        }        
        helper.filterOpenCSByProduct(component, { clearOnPTChange: userChange });
        helper.filterCloseL3ByOpenL3(component);        
        if (userChange && openVals.length === 0) {
            window.setTimeout($A.getCallback(function () {
                component.set('v.reRenderOpenCSPicklist', true);
            }), 0);
        }
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
        if(!tabModified || component.getLocalId() !== tabModified) helper.clearInputs(component);
    },
    changeActionfire: function(component) {
        $A.get("e.c:CaseTaggingToolPickListChangeEvent").setParams({
            tab: component.get('v.tabName')
        }).fire();
    },
    refreshFiltersFromData: function(component, event, helper){
        helper.filterOpenCSByProduct(component);
        helper.filterCloseL3ByOpenL3(component);
        helper.ensureCurrentOptionVisible(component, 'productValuesData', 'productValue');
        helper.ensureCurrentOptionVisible(component, 'closeCustomerSupportLevel3FilteredData', 'closeCustomerSupportLevel3Value');
    },
    recordChanged: function(component, event, helper){
        helper.recomputeMaskFromRecord(component);
    }
});