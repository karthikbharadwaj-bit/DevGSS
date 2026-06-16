({
    onQuantityInputBlur: function (component) {
        var product = component.get('v.product');

        product.normaliseQuantity();
        product.saveQuantity();

        component.set('v.product', product);
        component.set('v.app', component.get('v.app'));
    },

    quantityClick: function (component, event, helper) {
        var product = component.get('v.product');
        if (!product.selected)
            product.toggleSelected();

        var app = component.get('v.app');
        app.updateSelected();

        component.set('v.product', product);
        component.set('v.app', app);

        if (product.selected)
            helper.focusQuantityInput(component);
    },

    selectToggle: function (component, event, helper) {
        var product = component.get('v.product');
        product.toggleSelected();

        var app = component.get('v.app');
        app.updateSelected();

        component.set('v.product', product);
        component.set('v.app', app);

        if (product.selected)
            helper.focusQuantityInput(component);
    },

    productChanged: function (component, event, helper) {
        helper.syncSelectedCheckbox(component);
    },

    appChanged: function (component, event, helper) {
        var product = component.get('v.product');
        component.set('v.product', product);
    },

    addAreaCode: function (component) {
        var product = component.get('v.product');
        var app = component.get('v.app');

        if (!product.selected) {
            product.toggleSelected();
            app.updateSelected();
        }
        product.addAreaCode();

        component.set('v.product', product);
        component.set('v.app', app);
    },

    toggleExpand: function (component) {
        var product = component.get('v.product');
        if(product.isExpandable) {
            product.setExpanded(!product.isExpanded);
            component.set('v.product', product);
        }
    },

    removeAreaCode: function (component, event) {
        var product = component.get('v.product');

        product.removeAreaCode(event.getParam('params').index);

        component.set('v.product', product);
    },

    areaCodeQuantityChange: function (component) {
        var product = component.get('v.product');

        product.updateQuantityFromAreaCodes();

        component.set('v.product', product);
    }
});