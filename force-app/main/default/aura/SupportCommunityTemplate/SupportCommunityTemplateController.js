/**
 * Created on 03.12.2018
 */
({
    handleUpdateUser: function handleUpdateUser(cmp, event, helper) {
        var who = event.getParam("param");
        if (who === "init") {
            cmp.set("v.first_init", false);
            helper.doInit(cmp);
        }
    },
    doInit: function(cmp, event, helper) {
        if (window.app) {
            cmp.set("v.first_init", false);
            helper.doInit(cmp);
        }
    },
});