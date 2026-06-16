({
    void: function (component) {
        window.open(component.get('v.envelope').getVoidUrl(), '_blank');
        component.getEvent("envelopeVoidClicked").setParams({
            params: {
                envelopeSFId: component.get('v.envelope.record.Id')
            }
        }).fire();
    }
});