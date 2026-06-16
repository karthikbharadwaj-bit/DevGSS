/**
 * Created on 15.10.2018
 */
({
    languages: [],
    currentLanguage: null,
    menuLoadFirst: true,
    getURLParameter: function getURLParameter(name) {
        return decodeURIComponent((location.search.match(RegExp("[?|&]" + name + "=(.+?)(&|$)")) || [, null])[1]);
    },
    send_event: function send_event(param, value) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ param: param, value: value });
        updateEvent.fire();
    },
    renewLang: function renewLang(cmp, selected) {
        this.currentLanguage = selected;
        cmp.set("v.options", this.languages);
        cmp.set("v.current", selected);
        this.updateMenu(cmp);
    },
    isSupporedForCurL: function isSupporedForCurL(langs) {
        if (this.currentLanguage) {
            var sLang = langs.split(";");
            for (var i = 0; i < sLang.length; i++) {
                if (sLang[i].toLowerCase() === this.currentLanguage.label.toLowerCase()) {
                    return true;
                }
            }
        }
        return false;
    },
    renewMenu: function renewMenu(bufMenu) {
        var menu = [];
        for (var i = 0; i < bufMenu.length; i++) {
            var menuItem = bufMenu[i];
            if (menuItem.id === 0) continue; // Case11291354: Skip the 'Home' button that appears by default in navigation
            if (menuItem.subMenu) {
                menuItem.subMenu = this.renewMenu(menuItem.subMenu);
            }
            if (menuItem.label.indexOf("::") > 0) {
                const parseLabel = menuItem.label.split("::");
                if (this.isSupporedForCurL(parseLabel[0])) {
                    menuItem.label = parseLabel[1];
                    menu.push(menuItem);
                }
            } else menu.push(menuItem);
        }
        return menu;
    },
    updateMenu: function updateMenu(cmp, menuItems) {
        if (menuItems && Array.isArray(menuItems)) {
            this.menu = menuItems;
        }
        if (this.menu) {
            cmp.set("v.menuItemsNew", this.renewMenu(JSON.parse(JSON.stringify(this.menu))));
        }
        cmp.set("v.loading", false);
        var user = false;
        if (window.app) {
            user = window.app.hasUser();
        }
        cmp.set("v.user", user);
    }
});