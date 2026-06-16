({
    initApp: function (component) {
        const app = new SLA.classes.App();

        app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);
    },

    searchParamsId: function() {
        return new URL(window.location.href).searchParams.get('id');
    },

    searchParamsApprovalId: function() {
        return new URL(window.location.href).searchParams.get('approvalId');
    },

    initPage: function(component) {
        if(!!this.searchParamsApprovalId()) {
            return this.loadApproval(component);
        } else if(!!this.searchParamsId()) {
            return this.loadSLAById(component);
        }

        return Promise.reject(new Error('Please provide approvalId or id URL parameters'));
    },

    loadApproval: function (component) {
        const app = component.get('v.app');
        const approvalId = this.searchParamsApprovalId();

        if(!approvalId) {
            return Promise.resolve();
        }

        app.isRequestInProgress = true;
        app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);

        return RC.salesforce.request(component, 'c.getApprovalInfo', {approvalId: approvalId})
            .then($A.getCallback(function (response) {
                if(!_.isEmpty(response.data)) {
                    try {
                        app.isRequestInProgress = false;
                        app.openAccountSLAs({
                            approval: response.data.approval,
                            account: response.data.account,
                            serviceTypes: response.data.serviceTypes,
                            existingSLAs: response.data.existingSLAs,
                            standardSLAs: response.data.standardSLAs
                        });

                        app.updateView();
                    } catch (e) {
                        app.isReadOnly = true;

                        return Promise.reject(e);
                    } finally {
                        app.updateView();

                        component.set('v.app', app);
                        component.set('v.view', app.view);
                        component.set('v.accountId', app.account.id);
                        component.set('v.engageLegalLookupParams', { accountId: app.account.id });

                        component.find('NotificationsBar').update();
                    }
                } else {
                    return Promise.reject(new Error('No data in response'));
                }
            }));
    },

    loadSLAById: function(component) {
        const app = component.get('v.app');
        const slaId = this.searchParamsId();

        if(!slaId) {
            return Promise.resolve();
        }

        app.isRequestInProgress = true;
        app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);

        return RC.salesforce.request(component, 'c.getSLAById', {slaId})
            .then($A.getCallback(function (response) {
                if(!_.isEmpty(response.data)) {
                    try {
                        app.isRequestInProgress = false;
                        app.openSingleSLA({
                            sla: response.data.record,
                            account: response.data.account,
                            serviceTypes: response.data.serviceTypes,
                            existingSLAs: response.data.existingSLAs,
                            standardSLAs: response.data.standardSLAs
                        });

                        app.updateView();
                    } catch (e) {
                        app.isReadOnly = true;
                        return Promise.reject(e);
                    } finally {
                        component.set('v.app', app);
                        component.set('v.view', app.view);
                        component.set('v.accountId', app.account.id);
                        component.set('v.engageLegalLookupParams', { accountId: app.account.id });

                        component.find('NotificationsBar').update();
                    }
                } else {
                    return Promise.reject(new Error('No data in response'));
                }
            }));
    },

    saveSLA: function(component) {
        const app = component.get('v.app');

        app.isRequestInProgress = true;
        app.updateView();

        component.set('v.view', app.view);

        return RC.salesforce.request(component, 'c.saveSLA', {data : JSON.stringify(app.sla.json())})
            .then($A.getCallback(function (response) {
                if(!_.isEmpty(response.data)) {
                    try {
                        app.sla.record = response.data.record;
                        app.sla.loadFromRecord();
                        app.accountSLAs[app.sla.serviceType] = app.sla.clone();

                        app.isRequestInProgress = false;
                        app.updateView();

                        $A.get("e.c:ToastEvent").setParams({
                            theme: 'success',
                            header: 'Saved successfully',
                            defaultTimeout: true,
                        }).fire();
                    } catch (e) {
                        app.isReadOnly = true;

                        return Promise.reject(new Error('No data in response'));
                    } finally {
                        component.set('v.view', app.view);

                        component.find('NotificationsBar').update();
                    }
                } else {
                    return Promise.reject(new Error('No data in response'));
                }
            }));
    },

    saveRangeItem: function (component) {
        const app = component.get('v.app');
        const view = component.get('v.view');

        app.sla.addCreditChart({
            min: view.SLA.NextChart.MinAvailability,
            max: view.SLA.NextChart.MaxAvailability,
            credit: view.SLA.NextChart.Credit
        });
        app.updateView();

        component.set('v.view', app.view);
    },

    removeRangeItem: function(component) {
        const app = component.get('v.app');

        app.sla.popCreditChart();
        app.updateView();

        component.set('v.view', app.view);
    },

    changeEngageLegalValue: function(component) {
        const app = component.get('v.app');

        app.updateFromView();

        component.set('v.app', app);
        component.set('v.view', app.view);
    },

    changeServiceType: function(component) {
        const app = component.get('v.app');

        app.updateFromView();
        app.loadSLAByServiceType(app.slaServiceType);

        app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);
        component.find('NotificationsBar').update();
    },

    changeValues: function(component) {
        const app = component.get('v.app');

        app.view.SLA.validate();
        app.updateFromView();
        app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);
    },

    changeNewChartValues: function(component) {
        const app = component.get('v.app');

        app.view.SLA.NextChart.validate();
        app.updateFromView();

        component.set('v.view', app.view);
    },

    updateValues: function (component) {
        const app = component.get('v.app');

        app.updateFromView();
        app.view.SLA.validate();
        // app.updateView();

        component.set('v.app', app);
        component.set('v.view', app.view);
    },

    cancel: function (component) {
        const app = component.get('v.app');

        if(!!app.approval) {
            self.top.close();
        } else {
            window.location.href = `/${app.sla.id}`;
        }
    }
});