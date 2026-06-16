({
    show: function (component) {
        return new Promise(resolve => {
            setTimeout($A.getCallback(function () {
                $A.util.addClass(component.find('modal'), 'slds-slide-up-saving');
                $A.util.addClass(component.find('backdrop'), 'slds-backdrop_open');
                switch (component.get('v.Modal.layout')) {
                    case 'fullscreen':
                        $A.util.addClass(component.find('modal'), 'modal_fullscreen');
                        break;
                    case 'large':
                        $A.util.addClass(component.find('modal'), 'slds-modal_large');
                        break;
                }
                $A.util.removeClass(component, 'slds-hide');
                resolve();
            }));
        });
    },

    hide: function (component) {
        $A.util.addClass(component.find('modal'), 'slds-transition-hide');
        $A.util.addClass(component.find('backdrop'), 'slds-transition-hide');
        setTimeout($A.getCallback(function () {
            $A.util.removeClass(component.find('modal'), 'slds-slide-up-saving');
            $A.util.removeClass(component.find('backdrop'), 'slds-backdrop_open');
            $A.util.removeClass(component.find('modal'), 'slds-transition-hide');
            $A.util.removeClass(component.find('backdrop'), 'slds-transition-hide');
            $A.util.addClass(component, 'slds-hide');
            switch (component.get('v.Modal.layout')) {
                case 'fullscreen':
                    $A.util.removeClass(component.find('modal'), 'modal_fullscreen');
                    break;
                case 'large':
                    $A.util.removeClass(component.find('modal'), 'slds-modal_large');
                    break;
            }
        }), 500);
    },

    sendResponseEvent: function (component, button) {
        $A.get("e.c:ModalResponseEvent").setParams({
            guid: component.get('v.Modal.guid'),
            buttonName: button.name,
            params: component.get('v.Modal.params')
        }).fire();
    },

    runButtonCallback: function (component, button) {
        button.callback();
    },

    resize: function(component, to) {
        switch (component.get('v.Modal.layout')) {
            case 'fullscreen':
                $A.util.removeClass(component.find('modal'), 'modal_fullscreen');
                break;
            case 'large':
                $A.util.removeClass(component.find('modal'), 'slds-modal_large');
                break;
        }

        if (to === 'fullscreen') {
            $A.util.addClass(component.find('modal'), 'modal_fullscreen');
        }
        if (to === 'large') {
            $A.util.addClass(component.find('modal'), 'slds-modal_large');
        }

        component.set('v.Modal.layout', to);
    }
});