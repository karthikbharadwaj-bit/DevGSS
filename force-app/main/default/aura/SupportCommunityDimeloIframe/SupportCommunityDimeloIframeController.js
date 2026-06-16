({
    handleMessage: function (component, event, helper) {
    },
    
    handleError: function (component, event, helper) {
        var error = event.getParams();
        console.log(error);
    }
})