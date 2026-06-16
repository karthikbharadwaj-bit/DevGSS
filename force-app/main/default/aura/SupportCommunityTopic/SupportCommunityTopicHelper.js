/**
 * Created on 28.09.2018
 */
({
    updateTopic: function updateTopic(cmp) {
        var data = [[], []];
        try {
            data = window.app.topics;
        } catch (e) {}
        var place = cmp.get('v.place');
        var topics = [];
        var topicList = [];
        try {
            topics = data[0];
        } catch (e) {}

        topics = topics.filter(function (item) {
            return item.Place__c.toLowerCase() === place.toLowerCase();
        });
        topics.sort(function (a, b) {
            return a.Position__c - b.Position__c;
        });
        topics.forEach(function (item) {
           item.Url = 'article/' + item.Url__c;
        });
        topics = topics.filter(function (t) {
            return t.Name !== null;
        });
        cmp.set('v.topics', topics);
    },
    getTop: function getTop(cmp) {
        if (window.app) {
            var action = cmp.get("c.getTopTopics");
            var count = cmp.get('v.count');
            action.setParams({ value: JSON.stringify({ count: count, country: window.app.language }) });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var data = response.getReturnValue();
                    var topics = [];
                    for (var i in data) {
                        var topic = { Name: data[i].Title, Url: 'article/' + encodeURIComponent(data[i].UrlName) };
                        topics.push(topic);
                    }
                    cmp.set('v.topics', topics);
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }
    }
});