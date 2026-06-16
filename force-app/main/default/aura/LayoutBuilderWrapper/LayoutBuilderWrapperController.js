({
    afterScriptsLoaded: function (component, event, helper) {
        helper.loadLayout(component);
    },

    onsubmit: function (component, event, helper) {
        event.preventDefault();
        helper.saveRecord(component);
    },

    cancel: function () {
        let retURL =
            new URL(window.location).searchParams.get("retURL");
        retURL ?
            window.open(retURL, '_parent') :
            history.back();
    }
});