({
    handleUpdate: function (cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') {
            helper.helperInit(cmp);
        }
    },
    doInit: function doInit(cmp, event, helper) {
        helper.helperInit(cmp);
        var target = { Tab: '__blank', Here: '_self' };
        var targetAttr = cmp.get('v.targetAttr');
        cmp.set('v.target', target[targetAttr]);
    }
});