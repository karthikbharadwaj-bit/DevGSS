({
    createApp: function (component) {
        let helper = this;
        let app = new DS.classes.App(window.DocuSignApp);
        window.DocuSignApp = app;
        app.opportunityId = component.get('v.opportunityId');
        app.setIsVoidEnvelopesAllowed(component.get('v.isVoidEnvelopesAllowed'));
        app.tabs.addOnSendOpenCallback(() => {
            let Modal = component.find('modal').get('v.Modal');
            component.find('modal').updateButtons([{
                label: 'Send',
                variant: 'brand',
                closeOnClick: false,
                callback: () => {
                    let app = component.get('v.app');

                    let isValid = app.validateBeforeSend();
                    if (isValid) {
                        helper.proceedDocuSign(component)
                    }
                    component.set('v.app', app);
                }
            }]);
            component.find('modal').set('v.Modal', Modal);

            let app = component.get('v.app');

            if (app.documents.length === 1 && !app.documents[0].isSelected){
                app.documents[0].select(true);
            }

            component.set('v.app', app);

        });
        app.tabs.addOnManageOpenCallback(() => {
            component.find('modal').updateButtons([]);
        });
        component.set('v.app', app);
    },

    getDataOnInit: function (component) {
        component.set('v.isEnvelopesLoading', true);
        component.set('v.isDocumentsLoading', true);
        component.set('v.isRecipientsLoading', true);
        let app = component.get('v.app');
        RC.salesforce.request(component, 'c.getDataOnInit', {
                opportunityId: app.opportunityId,
                quoteId: component.get('v.primaryQuoteId')
            })
            .then($A.getCallback(result => {
                app.setDocuments(result.data.attachmentList);
                app.setRecipients(result.data.recipientList);
                app.setFeatureToggle(result.data.featureToggle);
                app.setEnvelopes(result.data.envelopeList);

                if (result.data.isOpportunityHasActiveEnvelopes || app.isNewEnvelopePending) {
                    app.tabs.openManage();
                } else {
                    app.tabs.openSend();
                }
                component.set('v.app', app);

                component.getEvent('docuSignEnvelopeListRefresh').setParams({
                    params: {
                        isOpportunityHasActiveEnvelopes: result.data.isOpportunityHasActiveEnvelopes,
                        isAnyEnvelopeVoidPending: app.isAnyEnvelopeVoidPending,
                        isNewEnvelopePending: app.isNewEnvelopePending
                    }
                }).fire();
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError(error)))
            .then($A.getCallback(() => {
                component.set('v.isEnvelopesLoading', false);
                component.set('v.isDocumentsLoading', false);
                component.set('v.isRecipientsLoading', false);
            }));
    },

    proceedDocuSign: function (component) {
        RC.spinner.show();
        let app = component.get('v.app');
        return RC.salesforce.request(component, 'c.send', {
            quoteId: component.get('v.primaryQuoteId'),
            attachmentIds: app.getSelectedDocumentsId()
        })
            .then($A.getCallback(r => {
                const newWindowOpened = window.open(app.getResultURL(r.data.quoteId) + '&nw=1', '_blank');
                if (newWindowOpened) {
                    app.tabs.openManage();
                    app.setIsNewEnvelopePending(true);
                    window.onfocus = $A.getCallback(() => {
                        let envelopeList = component.find('envelopeList');
                        if (envelopeList) {
                            envelopeList.refreshEnvelopes();
                        }
                        window.onfocus = null;
                    });
                }
                component.set('v.app', app);
                RC.spinner.hide();
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'success',
                    header: 'DocuSign envelope prepared succesfully',
                    defaultTimeout: false
                }).fire();
            }))
            .catch($A.getCallback(error => {
                RC.salesforce.displayError(error);
                RC.spinner.hide();
                return Promise.reject();
            }));
    },

    validateBeforeStart: function (component) {
        RC.spinner.show();
        return RC.salesforce.request(component, 'c.validateBeforeStart', {
                opportunityId: component.get('v.opportunityId'),
                selectedQuoteId: null
            })
            .then($A.getCallback(response => {
                RC.spinner.hide();
                let errors = null;
                if (response.data.errorsSerialized) {
                    errors = JSON.parse(response.data.errorsSerialized);
                }
                let additionalValidationResult = response.data.additionalValidationResult;

                if (errors){
                    errors.forEach(err => {
                        $A.get("e.c:ToastEvent").setParams({
                            theme: 'error',
                            header: err.header,
                            details: err.message,
                            defaultTimeout: false
                        }).fire();
                    });
                    return false;
                }

                const recallMsg = additionalValidationResult.messages.find(m => m.message.indexOf('Please') !== -1);
                if (recallMsg) {
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'error',
                        header: 'Unable to send an opportunity with DocuSign',
                        details: recallMsg,
                        defaultTimeout: false
                    }).fire();
                    return false;
                } else if (additionalValidationResult.data.approvalId){
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'error',
                        header: 'Unable to send an opportunity with DocuSign',
                        details: 'Please note that Legal Engagement approval is in progress. You must recall the approval to send the opportunity with DocuSign',
                        defaultTimeout: false
                    }).fire();
                    return false;
                }
                return true;
            }))
            .catch($A.getCallback(error => {
                RC.salesforce.displayError(error);
                RC.spinner.hide();
                return Promise.reject();
            }));
    },
});