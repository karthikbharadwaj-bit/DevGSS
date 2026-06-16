({
    handleRouteChange: function doInitSecond(cmp, event, helper) {
        if(document.querySelectorAll("c-sc-page-settings").length === 0) {
            const cEvent = new CustomEvent("scPageSettings", { detail: {showSnapIns: true } });
            window.dispatchEvent(cEvent);
        }
    },
    doInit: function doInit(cmp, event, helper) {
        helper.getPageSettings(cmp);
        cmp.set("v.formFactor", $A.get("$Browser.formFactor"));
        const logo = jQuery(".logo");
        if (logo && logo.length) {
            var bgimg = logo.css("background-image");
            var imgurl = bgimg.match(/\((.*?)\)/);
            if (imgurl && imgurl.length > 1) {
                imgurl = imgurl[1];
                imgurl = imgurl.substring(1, imgurl.length - 1);
                cmp.set("v.logo", imgurl);
            }
        }
        if(!window.app) {
            window.app = new SC.App();
        }
        window.app.language = helper.getLanguage();
        cmp.set("v.pageLang", window.app.language);
        helper.getInfo(cmp);
        window.app.version = $A.get("$Record.configs").version * 1;
        window.app.loginUrl = cmp.get("v.loginUrl");

        helper.swipeMenu();
        window.onscroll = function() {
            var header = document.querySelector(".header>.container");
            var hasShadow = header.classList.contains("shadow");
            if (document.body.scrollTop > 0 || document.documentElement.scrollTop > 0) {
                if (!hasShadow) header.classList.add("shadow");
            } else if (hasShadow) {
                header.classList.remove("shadow");
            }
        };
        helper.loadIcons(cmp);
    },

    hamburger: function hamburger(cmp, event, helper) {
        helper.hamburgerClick(cmp);
    },
    navigationHide: function navigationHide(cmp, event) {
        if ($(event.target).hasClass("shadow")) $(".navigation").removeClass("navigation_is-open");
    },
    handleEvent: function handleEvent(cmp, event, helper) {
        const who = event.getParam("param");
        if (who === "login_init") {
            helper.pushEvent("scLogin");
        }
        if (who === "logout_init") {
            helper.pushEvent("scLogin");
        }
    },
});