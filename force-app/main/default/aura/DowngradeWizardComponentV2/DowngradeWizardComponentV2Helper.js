({
    nameMapping: {
        'downgrade': 'Downgrade',
        'close': 'Close'
    },
    
    ERROR_MESSAGES: {
        default: 'Something went wrong',
        empty_wizard_type: 'Wizard type missing or unsupported',
        empty_wizard_config: 'Configuration for this wizard type was not found',
        empty_opportunityId: 'Missing Opportunity Id',
    },

    showError: function (message, details) {
        $A.get("e.c:ToastEvent").setParams({
            theme: 'error',
            header: message || this.ERROR_MESSAGES.default,
            details: details,
            defaultTimeout: false
        }).fire();
    },

    showSuccess: function (message, details) {
        $A.get("e.c:ToastEvent")
            .setParams({
                theme: 'success',
                header: message || 'Success',
                details: details,
                defaultTimeout: 5
            })
            .fire()
    },

    request: function (component, controller, params) {
        return new Promise((resolve, reject) => {
            const action = component.get(controller);
            if (params) {
                action.setParams(params);
            }
            action.setCallback(null, (response) => {
                if (response.getState() === 'SUCCESS') {
                    const res = response.getReturnValue();
                    resolve(res);
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        });
    },

    formSubmit: function (component, fieldValues) {
        const helper = this;

        helper.showSpinner(true);

        return this.request(component, 'c.submitForm', {params: fieldValues})
            .then($A.getCallback((res) => {
                helper.showSpinner(false);
                window.location = '/' + res;
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                helper.showSpinner(false);

                res.getError().forEach((error) => {
                    helper.showError(error.message);
                });

            }));
    },

    showSpinner: function (value, text) {
        $A.get('e.c:SpinnerEvent').setParams({
            value: value,
            text: text,
        }).fire();
    },

    modalActionOk: function (component) {
        const helper = this;
        const fields = component.get('v.fieldValues');
        const oppId = component.get('v.oppId');
        const wType = component.get('v.wizardType').toLowerCase();
        const isInline = component.get('v.isInline');

        if (!oppId) {
            helper.showError(helper.ERROR_MESSAGES.empty_opportunityId);
            return;
        }

        const fieldValues = {};
        fieldValues.Id = oppId;
        
        Object.assign(fieldValues,fields );

        console.log(fieldValues);
       /* _.forEach(panels, (panel) => {
            const params = panel.get('v.params');
            Object.assign(fieldValues, params.values);
        });*/

        fieldValues['wType'] = wType;
        fieldValues['isInline'] = isInline;
        fieldValues['brandName'] = component.get("v.opportunityWizardData")['Brand_Name__c'];
        
        helper.formSubmit(component, fieldValues);
    },

    redirectToOpportunity: function (component) {
        const oppId = component.get('v.oppId');

        if (oppId) {
            window.location = '/' + oppId;
        }
    },

    loadOppCloseInfo: function (component) {
        const helper = this;
        const oppId = component.get('v.oppId');

        if (!oppId) {
            return new Promise().resolve(null);
        }

        return helper.request(component, 'c.getOpportunityCloseWizardData', {opportunityId: oppId})
            .then($A.getCallback((res) => {
                component.set('v.opportunityWizardData', res);
                helper.showSpinner(false);
                return res;
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                helper.showSpinner(false);

                res.getError().forEach((error) => {
                    helper.showError(error.message);
                });
            }))
    },

    processOppInfo: function (component) {
        const helper = this;
        const oppInfo = component.get('v.oppInfo');
        const opty = JSON.parse(oppInfo);

        const isShowModal = opty.optyName.toLowerCase().indexOf('change order') === -1
            && opty.optyName.toLowerCase().indexOf('migration') === -1
            && !opty.parentOrder
            && !opty.isRenewalWithoutChanges
            && !opty.isSingleOne;

        if (isShowModal) {
            helper.showModal(component);
        } else {
            helper.modalActionOk(component);
        }
    },
    
    showModal: function (component) {
        const helper = this;

        $A.get("e.c:ModalRequestEvent").setParams({
            header: $A.get("$Label.c.DW_Title_CloseOpportunity"),
            content: $A.get("$Label.c.DW_Message_CloseOpportunity"),
            buttons: [{
                label: 'Ok',
                variant: 'brand',
                callback: () => {
                    helper.modalActionOk(component);
                }
            }]
        }).fire();
    }
});