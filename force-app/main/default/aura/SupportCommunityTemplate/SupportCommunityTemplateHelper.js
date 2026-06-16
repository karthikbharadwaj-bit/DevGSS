/**
 * Created on 03.12.2018
 */
({
    doInit: function(cmp) {
        this.getCommunity(cmp);
    },
    send_event: function send_event(param) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ "param": param });
        updateEvent.fire();
    },
    getCommunity: function getCommunity(cmp) {
        var _this2 = this;
        RC.salesforce.request(cmp, 'c.getTopicsInfo', {langCode:  window.app.language}).then($A.getCallback(function (res) {
            window.app.topics = res;
            _this2.send_event("topics");
        })).catch($A.getCallback(function (error) {
            console.error("Failed with state: " + error);
        }));
    },
    getCases: function getCases(cmp, accId, contact, profile) {
        var _this3 = this;
        RC.salesforce.request(cmp, 'c.CasesInfo', { "accId": accId, "contactId": contact, "profile": profile }).then($A.getCallback(function (res) {
            cmp.set('v.preloader', false);
            window.app.Cases = res;
            _this3.send_event("cases");
        })).catch($A.getCallback(function (error) {
            cmp.set('v.preloader', false);
            console.error("Failed with state: " + error);
        }));
    },

});