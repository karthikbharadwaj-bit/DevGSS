({
    openSendTab: function (component) {
        let app = component.get('v.app');

        app.tabs.openSend();

        component.set('v.app', app);
    },

    refreshEnvelopes: function (component, event, helper) {
        helper.refreshEnvelopes(component);
    },

    envelopeVoidClicked: function (component, event, helper) {
        window.onfocus = $A.getCallback(() => {
            helper.refreshEnvelopes(component);
            window.onfocus = null;
        });

        let app = component.get('v.app');
        app.envelopeVoidClickedOn(event.getParams().params.envelopeSFId);
        component.set('v.app', app);
    }
});