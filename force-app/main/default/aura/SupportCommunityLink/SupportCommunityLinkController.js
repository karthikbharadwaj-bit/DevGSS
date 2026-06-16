({
    handleUpdate: function handleUpdate(cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') helper.helperInit(cmp);
    },
    doInit: function doInit(cmp, event, helper) {
       helper.helperInit(cmp);
    }
});