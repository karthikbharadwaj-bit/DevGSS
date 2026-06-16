({
    doInit: function(component, event, helper){
        helper.setTheme(component);

        var timeout = component.get('v.timeout');
        var defaultTimeout = component.get('v.defaultTimeout');
        if (timeout) {
            helper.closeToastTimeout(component, timeout);
        } else if (defaultTimeout){
            helper.closeToastTimeout(component, 5000);
        }
    },
    /**
     * Close Toast button pressed
     */
    closeToast: function(component, event, helper) {
        helper.closeToast(component);
    },
    /**
     * Set main color of toast
     */
    themeChaged: function(component, event) {
        var toast = component.find('toast');
        var oldTheme = event.getParam('oldValue');
        $A.util.removeClass(toast, 'slds-theme--' + oldTheme);

        helper.setTheme(component);
    },
    /**
     * Close toast automatically after some amount of time
     */
    timeoutChanged: function(component, event, helper) {
        var timeout = component.get('v.timeout');
        if (timeout) {
            helper.closeToastTimeout(component, timeout);
        }
    },
    /**
     * Close toast automatically after some amount of time
     */
    defaultTimeoutChanged: function(component, event, helper) {
        var defaultTimeout = component.get('v.defaultTimeout');
        if (defaultTimeout) {
            helper.closeToastTimeout(component, 5000);
        }
    }
})