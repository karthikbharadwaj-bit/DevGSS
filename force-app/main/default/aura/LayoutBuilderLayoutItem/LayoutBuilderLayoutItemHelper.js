({
    getField: function(component){
        var params = {
            sObjectName: 'Case',
            fieldName: component.get('v.layoutItem.field')
        };
        return QW.salesforce.request(component, 'c.getField',params , null, true)
            .then($A.getCallback(function (result) {
                return JSON.parse(result);
            }));
    },
    createField: function(component){
        var helper = this;
        var isCreateFieldmarkUp = false;

       return helper.getField(component)
            .then($A.getCallback(function (fieldMetadata) {
                isCreateFieldmarkUp = helper.validateField(component, fieldMetadata);
                if (isCreateFieldmarkUp) {
                    return helper.createFieldMarkup(component, fieldMetadata);
                }
            }))
            .catch($A.getCallback(function (error) {
                console.error(component.get('v.layoutItem.field'), error.getError());
            }))
            .then($A.getCallback(function () {
                component.find('LoadingPlaceholder').set('v.isShown', false);
            }))
    },
    isPageEnabled: function(enabledPages, pageName){
        return Array.isArray(enabledPages) && enabledPages.filter(function(enabledPageName){
            return enabledPageName.page === pageName;
        }).length > 0;
    },
    createPage: function(component){
        var layoutItem = component.get('v.layoutItem');
        var page = component.get('v.enabledPages').filter(function(enabledPageName){
            return enabledPageName.page === layoutItem.page_x;
        })[0];

        var lightningParams = {
            record: component.getReference('v.record')
        };
        if (page.params){
            lightningParams = Object.assign(lightningParams, page.params);
        }

        return QW.components.createOne(page.lightning, lightningParams)
            .then($A.getCallback(function (newPage) {
                component.set('v.content', newPage);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error.getError());
            }))
            .then($A.getCallback(function () {
                component.find('LoadingPlaceholder').set('v.isShown', false);
            }))
    },
    createFieldMarkup: function(component, fieldMetadata){
            var layoutItem = component.get('v.layoutItem');
            var params = {
                label: this.setFieldLabel(fieldMetadata),
                class: 'slds-m-vertical_x-small',
                required: layoutItem.behavior === 'Required',
                onchange: component.getReference('c.onchange'),
                value: component.get('v.record')[layoutItem.field],
                'aura:id': 'inputField'
            };
            if (fieldMetadata.type === 'picklist') {
                params.options = fieldMetadata.picklistValues;
            }
            if (fieldMetadata.type === 'reference') {
                var lastReferenceIndex = fieldMetadata.referenceTo.length - 1;
                params.sObjectName = fieldMetadata.referenceTo[lastReferenceIndex];
                params.icon = params.sObjectName.toLowerCase();
                params.placeholder = 'Start Typing to search for '+params.sObjectName+'s';
            }

            return QW.components.createField(fieldMetadata.type, params)
                .then($A.getCallback(function (newField) {
                    component.set('v.content', newField);
                }))
    },
    setFieldLabel: function(fieldMetadata) {
        let label = '';
        if (fieldMetadata.label === 'Body' ) {
            label = 'Internal Comments';
        } else {
            label = fieldMetadata.label;
        }
        return label;
    },
    getUserProfile: function(component) {
        return QW.salesforce.request(component, 'c.getUserProfile')
            .then($A.getCallback(function (result) {
                return result;
            }))
            .catch($A.getCallback(function(error) {
                console.error(error, QW.salesforce.getResponseError(error));

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get user profile',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
                QW.spinner.hide();
            }));
    },
    validateField: function(component, fieldMetadata) {
        if (fieldMetadata.createable ) {
            //Owner field should be available only for System Administrators
            if(fieldMetadata.namePointing && component.get('v.profileName') === 'System Administrator') {
                return true;
            }
            if(!fieldMetadata.namePointing && fieldMetadata.name !== 'RecordTypeId') {
                return true;
            }
        } else {
            return false;
        }
    }
});