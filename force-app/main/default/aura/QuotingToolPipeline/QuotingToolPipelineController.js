({
    currentCartItemsChanged: function(component, event, helper) {
        let Tabs = component.get('v.Tabs');

        Tabs.cart.label = helper.getCartItemsLabel(component);

        component.set('v.Tabs', Tabs);
    },

    onTabClick: function(component, event) {
        let Tabs = component.get('v.Tabs');

        Tabs.openByName(event.currentTarget.dataset.name);

        component.set('v.Tabs', Tabs);
    },

    onPreviousClick: function(component){
        let Tabs = component.get('v.Tabs');

        Tabs.openPrevious();

        component.set('v.Tabs', Tabs);
    },

    onNextClick: function(component){
        let Tabs = component.get('v.Tabs');

        Tabs.openNext();

        component.set('v.Tabs', Tabs);
    }
});