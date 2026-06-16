/**
 * Created on 13.09.2018
 */
({
    doInit: function doInit(cmp, event, helper) {
        const html = document.getElementsByTagName("html");
        var curLang = "en_US";
        if (html.length > 0) curLang = html[0].getAttribute("lang").replace("-", "_");
        helper.languages = [
            { label: "US", value: "en_US", checked: false },
            { label: "AU", value: "en_AU", checked: false },
            { label: "CA", value: "en_CA", checked: false },
            { label: "FR", value: "fr", checked: false },
            { label: "DE", value: "de", checked: false },
            { label: "IE", value: "en_IE", checked: false },
            { label: "NL", value: "nl_NL", checked: false },
            { label: "SG", value: "en_SG", checked: false },
            { label: "ES", value: "es", checked: false },
            { label: "EN", value: "en_GB", checked: false }
        ];
        helper.renewLang(cmp, curLang);
    },
    handleEvent: function handleEvent(cmp, event, helper) {
        const who = event.getParam("param");
        if (who === "language_change") {
            helper.changeLanguage(cmp,event.getParam("value"));
        }
    },
    select: function select(cmp, event, helper) {
        const el = event.currentTarget;
        const lang = el.getAttribute("data-value");
        helper.changeLanguage(cmp,lang);
    }
});