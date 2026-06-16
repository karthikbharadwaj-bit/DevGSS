({
    setCategories: function (component) {
        var data = component.get('v.data');
        var entitlementsByCategory = [];

        for (var key in data) {
            if (data.hasOwnProperty(key)) {
                var name = key;
                if (key.toLowerCase() === 'main') name = 'RingCentral';

                entitlementsByCategory.push({
                    name: name,
                    list: data[key]
                });
            }

        }

        component.set('v.entitlementsByCategory', entitlementsByCategory);
    }
});