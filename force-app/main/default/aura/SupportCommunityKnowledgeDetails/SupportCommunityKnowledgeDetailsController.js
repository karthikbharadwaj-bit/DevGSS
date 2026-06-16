({
    doInit: function(cmp,event,helper) {
        if(window.app)
            helper.updateDetails(cmp);
    },
    handleUpdate: function(cmp,event,helper) {
        if (event.getParam("param") === 'article')
            helper.updateDetails(cmp);
    }
});