/**
 * Created on 01.11.2018
 */
({
    handleUpdate: function handleUpdate(cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') helper.initItems(cmp);
    },
    doInit: function doInit(cmp, event, helper) {
       helper.initItems(cmp);
    }
});