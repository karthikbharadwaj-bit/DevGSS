/**
 * Created on 25.09.2018
 */
({
    handleUpdateUser: function handleUpdateUser(cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') helper.getTop(cmp);
        if(cmp.get('v.place') !== 'Top')
            helper.updateTopic(cmp);
    },
    doInit: function doInit(cmp, event, helper) {
        if(cmp.get('v.place') !== 'Top')
            helper.updateTopic(cmp);
        else
            helper.getTop(cmp);
        var target = { Tab: '__blank', Here: '_self' };
        var targetAttr = cmp.get('v.targetAttr');
        cmp.set('v.target', target[targetAttr]);
    }
});