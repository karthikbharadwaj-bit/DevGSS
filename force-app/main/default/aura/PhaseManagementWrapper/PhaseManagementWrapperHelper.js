({
    getOrder: function(component){
        return PM.salesforce.request(component, 'c.getOrder', {
                orderId: component.get('v.orderId')
            }, $A)
            .then($A.getCallback(function (order) {
                component.set('v.order', order);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                ``
            }))
    },

    getUserPermissions: function(component){
        return PM.salesforce.request(component, 'c.getUserPermissions', null, $A)
            .then($A.getCallback(function (userPermissions) {
                component.set('v.userPermissions', userPermissions);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get user permissions',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }));
    },

    getIsNewChangeOrder: function(component) {
        return PM.salesforce.request(component, 'c.getIsNewChangeOrder', null, $A)
            .then($A.getCallback(function (isNewChangeOrderFlow) {
                component.set('v.isNewChangeOrder', isNewChangeOrderFlow);
            }))
            .catch($A.getCallback(function (error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get feature toggle',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }));
    },

    getRcVariousSettings: function(component){
        return PM.salesforce.request(component, 'c.getRcVariousSettings')
            .then($A.getCallback(function (rcVariousSettings) {
                component.set('v.rcVariousSettings', rcVariousSettings);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to get Ring Central various settings', error)));
    },

    getIsNewProservFlow: function(component) {
      return PM.salesforce.request(component, 'c.getIsNewProservFlow', {
        orderId: component.get('v.orderId')
      }, $A)
        .then($A.getCallback(function (isNewProservFlow) {
          component.set('v.isNewProservFlow', isNewProservFlow);
        }))
        .catch($A.getCallback(function (error) {
          console.error(error);
        }));
    }
});