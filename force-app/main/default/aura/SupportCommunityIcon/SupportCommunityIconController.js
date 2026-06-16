/**
 * Created on 09.11.2018
 */
({
    updateIcon: function(cmp, event, helper) {
        var icon_init = cmp.get('v.init');
        if (!icon_init && window.app != undefined && window.app.ie === true) {
            cmp.set('v.IE',true);
            var Id = cmp.get('v.Id');
            if(window.app.icons[Id] != undefined && window.app.icons != null) {
                if(cmp.find("custom-icon").getElement() !== null) {
                    cmp.set('v.init', true);
                    cmp.find("custom-icon").getElement().innerHTML = window.app.icons[Id];
                }
            }
        }
    }
});