({
    /**
     * Close Toast
     */
    closeToast: function(component) {
        var toast = component.find('toast');
        $A.util.addClass(toast, "slds-hide");
    },
    closeToastTimeout: function(component, timeout) {
    	var helper = this;
        setTimeout($A.getCallback(function() {
            if (component.isValid()) {
                helper.closeToast(component);
            }
        }), timeout);
    },
    setTheme: function(component){
    	var toast = component.find('toast');
        var theme = component.get('v.theme');
        if (theme) {
            $A.util.addClass(toast, 'slds-theme--' + theme);   
        }
    }
})