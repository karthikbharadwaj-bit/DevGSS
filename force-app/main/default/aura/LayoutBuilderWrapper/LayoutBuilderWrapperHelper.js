({
    loadLayout: function(component){
        var helper = this;
        QW.salesforce.request(component, 'c.getLayout', null, $A, true)
            .then($A.getCallback(function(layoutMetadataStr) {
                var layoutMetadata = JSON.parse(layoutMetadataStr);
                helper.parseLayoutMetadata(component, layoutMetadata);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error.getError());
            }))
            .then($A.getCallback(function() {
                component.find('LoadingPlaceholder').set('v.isShown', false);
            }))
    },
    parseLayoutMetadata: function (component, layoutMetadata) {
        var helper = this;
        var renderPromise = Promise.resolve();

        layoutMetadata.layoutSections.forEach(function (sectionMetadata) {
            renderPromise = renderPromise.then($A.getCallback(function () {
                    return helper.createSection(component, sectionMetadata);
                }))
                .catch($A.getCallback(function (error) {
                    console.error(error.getError());
                }))
        });
    },
    createSection: function(component, sectionMetadata){
        return QW.components.createOne('c:LayoutBuilderSection', {
                'metadata': sectionMetadata,
                'record': component.getReference('v.record'),
                'enabledPages': component.getReference('v.enabledPages')
            })
            .then($A.getCallback(function (newSection) {
                var sections = component.get("v.sections");
                sections.push(newSection);
                component.set("v.sections", sections);
            }))
            .catch($A.getCallback(function(error) {
                console.error(error.getError());
            }))
    },
    saveRecord: function(component){
        QW.spinner.show('Saving record...');
        var helper  = this;
        QW.salesforce.request(component, 'c.saveRecord', {
                record: component.get('v.record')
            })
            .then($A.getCallback(function (recordId) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'success',
                    header: 'Saved succesfully',
                    details: 'Redirecting...',
                    defaultTimeout: false
                }).fire();
                window.open('/'+recordId, '_self');
                //Populate "Comments" field on Case object
                helper.createAdditionalObject(component, recordId);
            }))
            .catch($A.getCallback(function(error) {
                console.error(error, QW.salesforce.getResponseError(error));

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to save',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
                QW.spinner.hide();
            }));
    },

    //"Comments" field on Case object is represented as CaseComment object,
    //it is populated when child CaseComment object is created
    createAdditionalObject: function(component, caseId) {
        var caseRecord = component.get('v.record');
        QW.salesforce.request(component, 'c.createAdditionalRecord', {
            caseId: caseId,
            commentBody: caseRecord.Comments
        })
            .catch($A.getCallback(function(error) {
                console.error(error, QW.salesforce.getResponseError(error));

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to populate Internal Comment field',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
                QW.spinner.hide();
            }));
    }
});