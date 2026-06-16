({
    doInit: function(component, event, helper) {
        var countries = component.get('v.countries');
        if (typeof countries === 'string') {
            var countriesText = "The phone is available only in: " + countries.replace(/;/gi, ', ');
            component.set('v.countriesText', countriesText);
        }
    },
    mouseOverIcon: function(component, event, helper){
        $A.get("e.c:PopoverEvent").setParams({
            target: event.currentTarget,
            show: true,
            showIcon: false,
            theme: 'tooltip',
            preferredPosition: 'top',
            text: component.get('v.countriesText')
        }).fire();
    },
    mouseOutIcon: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    }
});