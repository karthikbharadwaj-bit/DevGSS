({
    doInit: function doInit(cmp, evt, helper) {

    },
    redirectKey: function redirectKey(cmp, evt, helper) {
        var isEnterKey = evt.keyCode === 13;
        if (isEnterKey) helper.redirect(cmp);
    },
    searchClick: function searchClick(cmp, event, helper) {
        helper.redirect(cmp)
    }
});