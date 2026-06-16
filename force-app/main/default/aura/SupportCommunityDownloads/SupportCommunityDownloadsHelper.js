/**
 * Created on 06.11.2018
 */
({
    initItems: function(cmp) {
        if (window.app) {
            var action = cmp.get("c.getPictures");
            var downloads = [];
            action.setParams({ place: "downloads", country: window.app.language });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var items = response.getReturnValue();
                    for (var i = 0; i < items.length && i < 3; i++) {
                        var download = {};

                         try {
                            download.image = items[i].Image__c;
                            download.title = items[i].Name;
                            download.mac = cmp.get('v.dl_' + (i + 1) + '_mac');
                            download.win = cmp.get('v.dl_' + (i + 1) + '_win');
                        } catch (e) {
                             download = null;
                             console.error(e, items[i]);
                         }
                        if (download) downloads.push(download);
                    }
                    cmp.set("v.downloads", downloads);
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }
    }
});