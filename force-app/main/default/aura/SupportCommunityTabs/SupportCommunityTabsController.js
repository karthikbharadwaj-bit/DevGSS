({
    doInit: function doInit(cmp, event, helper) {
        helper.updateUser(cmp, null);
        helper.updateCases(cmp, null);
    },
    handleChangeUser: function (cmp, event, helper) {
        helper.updateUser(cmp, event.getParam("user"));
    },
    handleChangeCases: function (cmp, event, helper) {
        helper.updateCases(cmp, event.getParam("cases"), event.getParam("isMock"));
    },

    loginClick: function loginClick(cmp, event, helper) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ param: 'login_init' });
        updateEvent.fire();
    }
});