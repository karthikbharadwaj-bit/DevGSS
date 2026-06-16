/**
 * Created on 29.11.2018
 */
({
    handleUpdateUser: function handleUpdateUser(cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') {
            helper.getArticle(cmp);
        }
    },
    doInit: function(cmp,event,helper) {
        helper.getArticle(cmp);
    },

});