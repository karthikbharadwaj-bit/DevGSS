/**
 * Created on 06.11.2018
 */
({
    helperInit: function(cmp) {
        try {
        if(window && window.app) {
        var this_ = this;
        var action = cmp.get("c.getPictures");
        var index = cmp.get("v.image_inx");
        var item = {};
        action.setParams({ place: "knowledge banner", imgOrder: index, country: window.app.language });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var items = response.getReturnValue();
                if (Array.isArray(items)) items = items[0];
                if(items) {
                    cmp.set('v.image_url',items.Image__c || '');
                    cmp.set('v.link_url',items.Link__c || '');
                    this_.createDescription(cmp)
                }
            } else {
                console.error("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        }
        }catch(e){console.error(e);}
    },
    createDescription: function(cmp) {
        var before = '';
        var after = '';
        var template = cmp.get('v.description');
        template = template.replace(/\\n/g,'\n');
        var parse = template.split('${link}');
        if(Array.isArray(parse) && parse.length === 2) {
            before = parse[0];
            after = parse[1];
        }
        else {
            parse = template.replaceAll('${link}','');
            before = parse;
            after = '';
        }
        cmp.set('v.description_before',before);
        cmp.set('v.description_after',after);
    }
});