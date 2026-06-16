/**
 * Created on 05.10.2018
 */
({
    doInit: function doInit(cmp, event, helper) {
        document.addEventListener(
            "sc-language_list",
            function(e) {
                helper.languages = e.detail.map(function(item) {
                    return { label: item.shortTitle, value: item.language, checked: item.isCurrent };
                });
                const curLang = helper.languages.filter(function(item) {
                    return item.checked;
                });
                if (curLang.length > 0) helper.renewLang(cmp, curLang[0]);
            },
            false
        );
        helper.updateMenu(cmp, cmp.get("v.menuItems"));
    },
    itemsChange: function(cmp, event, helper) {
        helper.updateMenu(cmp, JSON.parse(JSON.stringify(event.getParam("value"))));
    },
    onClick: function onClick(component, event) {
        const id = event.target.dataset.menuItemId;
        if (id) {
            component.getSuper().navigate(id);
        }
    },
    select: function select(cmp, event, helper) {
        const el = event.currentTarget;
        const lang = el.getAttribute("data-value");
        const evt = new CustomEvent("sc-language_change", {
            bubbles: true,
            cancelable: false,
            detail: lang
        });
        document.dispatchEvent(evt);
    },
    loginButton: function loginButton(cmp, event, helper) {
        helper.send_event("login_init");
    },
    logoutClick: function logoutClick(cmp, event, helper) {
        helper.send_event("logout_init");
    },
    openSubMenu: function openSubMenu(cmp, event, helper) {
        var el = jQuery(event.currentTarget);
        var isOpen = el.parent().hasClass("open");
        jQuery(".community-navigation-menu .tab-item").removeClass("open");
        if (!isOpen) el.parent().addClass("open");
    }
});