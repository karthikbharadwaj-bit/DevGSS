/**
 * Created on 06.11.2018
 */
({
    helperInit: function(cmp) {
        if(window.app) {
            var action = cmp.get("c.getPictures");
            var index = cmp.get("v.icon");
            var item = {};
            action.setParams({ place: "links", imgOrder: index, country: window.app.language });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var items = response.getReturnValue();
                    if (Array.isArray(items)) items = items[0];
                    cmp.set("v.item", items);
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }
    }
});