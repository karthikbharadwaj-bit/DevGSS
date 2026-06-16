({

    appChanged: function (component, event, helper) {
        if (helper.isShouldSyncProducts(component))
            helper.syncProducts(component);
            component.find('preselectedAreaCodesInfo').update();
    },

    filterProds: function (component) {
        const app = component.get('v.app');

        if (app.isOnlyPreviouslySoldShown) {
            app.filterPreviouslySoldProducts();
        } else {
            app.filterActiveProducts();
        }

        component.set('v.app', app);
    },

    toggleCheckAll: function (component) {
        const app = component.get('v.app');
        app.activeProducts.forEach(p => {
            p.selected = p.isVisible && app.isAllSelected;
        });
        component.set('v.app', app);
    },

    showSelectedOnly: function (component) {
        const app = component.get('v.app');

        app.showSelectedOnlyToggle(true);

        component.set('v.app', app);
    },

    showPreviouslySoldOnly: function(component) {
        const app = component.get('v.app');

        app.showPreviouslySoldOnlyToggle(true);

        component.set('v.app', app);
    },

    showAll: function (component) {
        const app = component.get('v.app');

        app.showSelectedOnlyToggle(false);
        app.showPreviouslySoldOnlyToggle(false);

        component.set('v.app', app);
    },

    productComponentsChanged: function (component, event, helper) {
        helper.initAreaCodeInfoPresectionNotification(component);
    },

    showSpinner: function (component, event) {
        component.find('spinner').show(event.getParam('arguments').text);
    },

    hideSpinner: function (component) {
        component.find('spinner').hide();
    }
});