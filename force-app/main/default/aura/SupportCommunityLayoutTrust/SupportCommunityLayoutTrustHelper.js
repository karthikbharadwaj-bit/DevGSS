/**
 * Created on 29.11.2018
 */
({
    send_event: function send_event(param) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ "param": param });
        updateEvent.fire();
    },

    getArticle: function(cmp) {
        //this.send_event('article');
    },

});