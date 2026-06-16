/**
 * Created on 05.12.2018
 */
({
    doInit: function(cmp,event,helper) {
        if(window.app)
            helper.updateTitle(cmp);
    },
    handleUpdate: function(cmp,event,helper) {
        if (event.getParam("param") === 'article')
            helper.updateTitle(cmp);
    }
});