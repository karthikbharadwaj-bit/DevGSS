/**
 * Created on 15.10.2018
 */
({
    getSlides: function getSlides(cmp, place, variable) {
        if (window.app) {
            var action = cmp.get("c.getPictures");
            action.setParams({ place: place, country: window.app.language });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var items = response.getReturnValue();
                    items = items.filter(function(item) {
                        return item.Image__c !== null;
                    });

                    if (items.length > 0) {
                        cmp.set("v.sliderItems" + variable, items);
                        cmp.set("v.init" + variable, true);
                        // console.log('slider', items,domain);
                    }

                    // } else {
                    //     console.error("Failed with state: " + state);
                }

            });
            $A.enqueueAction(action);
        }
    }
});