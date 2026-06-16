({
    doInit: function(component, event, helper) {
        helper.addCaseCreationPageListener(component);
        helper.caseTypeTab(component);
    },
    setCaseType: function(component, event, helper) {
        var caseType = event.target.dataset.value;
        component.set('v.caseType',caseType);
        helper.caseTypeTab(component);
    },
    saveCase: function(component, event, helper) {
        var status = event.getParam('status');
        switch (status) {
            case "new":
                var caseObj = event.getParam('caseObj');
                helper.saveCase(component, caseObj);
                break;
            default:
                console.log('unexpected status for case save');
        }
    },
    caseTypeChange: function(component, event, helper) {
        helper.caseTypeTab(component);
    },
    afterScriptsLoaded: function(component, event, helper){
        helper.loadData(component);
    },

    recordChanged: function(component){
        window.dispatchEvent(new CustomEvent("CaseTaggingTool.valuesChanged", {
            detail: {
                record: component.get('v.record')
            }
        }));
    }
});