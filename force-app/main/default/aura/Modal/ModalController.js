({
    hide: function (component, event, helper) {
        helper.hide(component);
    },

    show: function (component, event, helper) {
        return helper.show(component);
    },

    resize: function (component, event, helper) {
        return helper.resize(component, event.getParam('arguments').params.to);
    },

    onButtonClick: function (component, event, helper) {
        var buttonIndex = event.getSource().get('v.name');
        var button = component.get('v.Modal.buttons')[Number(buttonIndex)];

        if (button.name)
            helper.sendResponseEvent(component, button);

        if (button.callback)
            helper.runButtonCallback(component, button);

        if (button.closeOnClick)
            helper.hide(component);
    },

    setModal: function (component, event) {
        component.set('v.Modal', new RC.modalHelper.Modal(event.getParam('arguments').params));
    },

    updateButtons: function (component, event) {
        // Destroy all buttons manually to avoid aura error
        // "computeClassNames [Cannot read property 'toLowerCase' of undefined]"
        let b = component.find('button');
        if (b){
            if (!Array.isArray(b)){
                b = [b];
            }
            b.forEach(btn => btn.destroy());
        }

        let Modal = component.get('v.Modal');
        Modal.buttons = event.getParam('arguments').buttons;
        component.set('v.Modal', Modal);
    },
});