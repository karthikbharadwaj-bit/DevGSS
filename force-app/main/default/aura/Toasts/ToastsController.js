({
    /**
     * Create Toast
     */
    toast: function(component, event, helper){
        var toastParams = event.getParams();
        helper.createToast(component, toastParams);
    }
})