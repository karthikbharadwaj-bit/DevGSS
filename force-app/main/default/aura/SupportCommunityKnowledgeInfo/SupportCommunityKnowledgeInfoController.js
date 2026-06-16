({
    doInit: function(cmp,event,helper) {
        if(window.app)
            helper.updateInfo(cmp);
    },
    handleUpdate: function(cmp,event,helper) {
        if (event.getParam("param") === 'article')
            helper.updateInfo(cmp);
    }
});