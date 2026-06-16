({
    setFormPositionAsync: function (component) {
        setTimeout($A.getCallback(() => this.setFormPosition(component)));
    },

    setFormPosition: function (component) {
        const iconRect = component.find('editIcon').getElement().getBoundingClientRect();
        const ICON_SIZE = 11;

        // form
        let formRect = component.find('locationForm').getElement().getBoundingClientRect();
        const NUBBIN_SIZE = 11;
        const formTopOffset = formRect.height / 2;
        const formTop = iconRect.top - formTopOffset + ICON_SIZE;
        const formLeft = iconRect.left - formRect.width - NUBBIN_SIZE;
        let formStyle = `left: ${formLeft}px;top: ${formTop}px;`;
        component.set('v.nubbinPosition', 'right');
        component.set('v.style', formStyle);

        // Backdrop
        const bgTop = iconRect.top + ICON_SIZE;
        const bg = `background-image: radial-gradient( circle 30rem at ${iconRect.left}px ${bgTop}px, transparent, rgba(126, 140, 153, .5) );`;
        const opacity = `opacity: 1;`;
        const backdropStyle = `${bg}${opacity}`;
        component.set('v.backdropStyle', backdropStyle);
    },

    valueToForm: function (component) {
        component.set('v.country',      component.get('v.value.country'));
        component.set('v.city',         component.get('v.value.city'));
        component.set('v.state',        component.get('v.value.state'));
        component.set('v.addressLine',  component.get('v.value.addressLine'));
        component.set('v.postalCode',   component.get('v.value.postalCode'));

        component.set('v.shippingOption',        component.get('v.value.shippingOption'));
        component.set('v.shipAttentionTo',       component.get('v.value.shipAttentionTo'));
        component.set('v.additionalAddressLine', component.get('v.value.additionalAddressLine'));
        component.set('v.customerName',          component.get('v.value.customerName'));
        component.set('v.multipleLocations',     component.get('v.value.multipleLocations'));
    },

    formToValue: function (component) {
        component.set('v.value', {
            country:     component.get('v.country'),
            city:        component.get('v.city'),
            state:       component.get('v.state'),
            addressLine: component.get('v.addressLine'),
            postalCode:  component.get('v.postalCode'),

            shippingOption:        component.get('v.shippingOption'),
            shipAttentionTo:       component.get('v.shipAttentionTo'),
            additionalAddressLine: component.get('v.additionalAddressLine'),
            customerName:          component.get('v.customerName'),
            multipleLocations:     component.get('v.multipleLocations'),
        });
    },

    setForm: function (component) {
        let helper = this;
        let emptyLabel = '--None--';
        let form = {
            get customerName(){
                return component.get('v.value.customerName') || emptyLabel;
            },

            get locationString() {
                let cityAdress = [
                    component.get('v.value.addressLine'),
                    component.get('v.value.additionalAddressLine'),
                    component.get('v.value.city')
                ].filter(helper.isNotEmpty).join(', ');
                let statePostal = [
                    component.get('v.value.state'),
                    component.get('v.value.postalCode')
                ].filter(helper.isNotEmpty).join(' ');
                let addressString = [
                    cityAdress,
                    statePostal,
                    component.get('v.value.country')
                ].filter(helper.isNotEmpty).join(', ') || emptyLabel;
                return addressString;
            },

            get shipAttentionTo() {
                return component.get('v.value.shipAttentionTo') || emptyLabel;
            },

            get shippingOption() {
                return component.get('v.value.shippingOption') || emptyLabel;
            },

            get isHasAccountBillingAddress() {
                return [
                    component.get('v.account.BillingCountry'),
                    component.get('v.account.BillingCity'),
                    component.get('v.account.BillingState'),
                    component.get('v.account.BillingStreet'),
                    component.get('v.account.BillingPostalCode')
                ].some(v => v);
            },

            get isCountryDisabled() {
                return !!(component.get('v.country')
                    && component.get('v.isUseAccountBillingAddress')
                    && component.get('v.country') === component.get('v.account.BillingCountry'))
            },

            get isCityDisabled() {
                return !!(component.get('v.city')
                    && component.get('v.isUseAccountBillingAddress')
                    && component.get('v.city') === component.get('v.account.BillingCity'))
            },

            get isStateDisabled() {
                return !!(component.get('v.state')
                    && component.get('v.isUseAccountBillingAddress')
                    && component.get('v.state') === component.get('v.account.BillingState'))
            },

            get isAddressLineDisabled() {
                return !!(component.get('v.addressLine')
                    && component.get('v.isUseAccountBillingAddress')
                    && component.get('v.addressLine') === component.get('v.account.BillingStreet'))
            },

            get isPostalCodeDisabled() {
                return !!(component.get('v.postalCode')
                    && component.get('v.isUseAccountBillingAddress')
                    && component.get('v.postalCode') === component.get('v.account.BillingPostalCode'))
            }
        };
        component.set('v.form', form);
    },

    isNotEmpty: function (value) {
        return value && value.trim();
    },

    openForm: function (component) {
        component.set('v.isOpen', true);
        this.setFormPositionAsync(component);
    },

    closeForm: function (component) {
        component.set('v.backdropStyle', '');
        component.set('v.isOpen', false);
    },

    fireOnClick: function (component) {
        var onclick = component.get('v.onclick');
        if (onclick) {
            $A.enqueueAction(onclick);
        }
    },

    fireOnChange: function (component) {
        var onchange = component.get('v.onchange');
        if (onchange) {
            $A.enqueueAction(onchange);
        }
    },

    copyFromBillingAddress: function (component) {
        [
            {formVal: 'country',     billinngVal: 'BillingCountry'},
            {formVal: 'city',        billinngVal: 'BillingCity'},
            {formVal: 'state',       billinngVal: 'BillingState'},
            {formVal: 'addressLine', billinngVal: 'BillingStreet'},
            {formVal: 'postalCode',  billinngVal: 'BillingPostalCode'},
        ].forEach(v => {
            let bVal = component.get(`v.account.${v.billinngVal}`);
            if (bVal) {
                component.set(`v.${v.formVal}`, bVal);
            }
        });
    },

    addEventListeners: function (component) {
        var helper = this;
        window.addEventListener('scroll', $A.getCallback(() => {
            if (component.get('v.isOpen')) {
                helper.setFormPosition(component);
            }
        }));
        window.addEventListener('resize', $A.getCallback(() => {
            if (component.get('v.isOpen')) {
                helper.setFormPosition(component);
            }
        }));
    },

    setInitialValue: function(component){
        component.set('v.initialValue', {
            country:        null,
            city:           null,
            state:          null,
            addressLine:    null,
            postalCode:     null,

            shippingOption:         component.get('v.shippingOption'),
            get shipAttentionTo() {
                return component.get('v.contactName');
            },
            additionalAddressLine:  null,
            get customerName() {
                return component.get('v.account.Name');
            }
        });
    },

    checkIfAccountBillingAddressUsed: function (cmp) {
        return [
            cmp.get('v.country')     && cmp.get('v.country')     === cmp.get('v.account.BillingCountry'),
            cmp.get('v.city')        && cmp.get('v.city')        === cmp.get('v.account.BillingCity'),
            cmp.get('v.state')       && cmp.get('v.state')       === cmp.get('v.account.BillingState'),
            cmp.get('v.addressLine') && cmp.get('v.addressLine') === cmp.get('v.account.BillingStreet'),
            cmp.get('v.postalCode')  && cmp.get('v.postalCode')  === cmp.get('v.account.BillingPostalCode'),
        ].every(v => v);
    },

    updateForm: function (component) {
        component.set('v.form', component.get('v.form'));
    },

    reset: function (component) {
        component.set('v.isUseAccountBillingAddress', false);
        component.set('v.value', JSON.parse(JSON.stringify(component.get('v.initialValue'))));
    },

    prepopulateShipAttentionTo: function (component) {
        var value = component.get('v.value');
        if(!value){
            value = {};
        }
        value.shipAttentionTo = component.get('v.contactName');
        component.set('v.value', value);
    },

    forceInputsRevalidation: function (component) {
        component.find('input').forEach(input => {
            if (input.get('v.value')) {
                input.showHelpMessageIfInvalid();
            }
        });
    }
});