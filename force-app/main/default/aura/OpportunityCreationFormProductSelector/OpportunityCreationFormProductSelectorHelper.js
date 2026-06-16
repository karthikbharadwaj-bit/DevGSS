({
    isShouldSyncProducts: function (component) {
        var newPricebook2Id = component.get('v.app.selectedServicePlan.record.Pricebook2Id');
        var oldPricebook2Id = component.get('v.productsForPricebook2Id');

        return newPricebook2Id !== oldPricebook2Id;
    },

    syncProducts: function (component) {
        var app = component.get('v.app');
        var pricebook2Id = component.get('v.app.selectedServicePlan.record.Pricebook2Id');
        component.set('v.productsForPricebook2Id', pricebook2Id);
        component.set('v.productComponents', []);
        var helper = this;

        app.setActiveProducts();
        if (app.productCache.isLoaded(pricebook2Id)) {
            this.rerenderActiveProducts(component);
        } else if (pricebook2Id){
            component.set('v.isProductsLoading', true);
            this.loadProductsFromSF(component)
                .then($A.getCallback(() => {
                    helper.syncProducts(component);
                    component.set('v.isProductsLoading', false);
                }));
        } else {
            component.set('v.app', app);
        }
    },

    loadProductsFromSF: function (component) {
        var app = component.get('v.app');
        var pricebook2Id = component.get('v.app.selectedServicePlan.record.Pricebook2Id');
        var opportunityRecordTypeName = component.get('v.app.opportunityRecordType.name');

        if (!pricebook2Id || !opportunityRecordTypeName)
            return Promise.resolve([]);

        return RC.salesforce.request(component, 'c.getProducts', {
                pricebook2Id: pricebook2Id,
                opportunityRecordTypeName: opportunityRecordTypeName
            })
            .then($A.getCallback(prods => {
                app.productCache.set(pricebook2Id, prods);
            }));
    },

    rerenderActiveProducts: function (component) {
        var activeProducts = component.get('v.app.activeProducts');
        var initialPricebook2Id = component.get('v.app.selectedServicePlan.record.Pricebook2Id');
        var initialRenderingProcessGUID = RC.uuidv4();
        component.set('v.renderingProcessGUID', initialRenderingProcessGUID);

        var productRenderPromise = Promise.resolve();
        activeProducts.forEach(product => {
            productRenderPromise = productRenderPromise.then($A.getCallback(() =>
                RC.components.createOne("c:OpportunityCreationFormProduct", {
                    'product': product,
                    'app': component.getReference('v.app')
                })
                .then($A.getCallback(newProductComponent => {
                    // The process is asynchronious. Check if pricebook is still the same
                    if (component.get('v.productsForPricebook2Id') === initialPricebook2Id
                        && component.get('v.renderingProcessGUID') === initialRenderingProcessGUID) {
                        return Promise.resolve(newProductComponent);

                    } else {
                        newProductComponent.destroy();
                        return Promise.reject({message: 'Service Plan Changed. Stop rendering products'});

                    }
                }))
                .then($A.getCallback(newProductComponent => {
                    var productComponents = component.get("v.productComponents");
                    productComponents.push(newProductComponent);
                    component.set("v.productComponents", productComponents);
                }))
            ));
        });

        productRenderPromise = productRenderPromise
            .then($A.getCallback(() => {
                // Touch v.app attribute to force rerendering
                component.set("v.app", component.get("v.app"));
            }))
            .catch($A.getCallback(error => console.warn(RC.salesforce.getResponseError(error))));
    },

    initAreaCodeInfoPresectionNotification: function (component) {
        var productComponents = component.get("v.productComponents");
        let notificationAreaCodesInfo = [
            {
                text: 'Please change Area Codes on Phones and Additional Local Numbers if needed',
                type: 'info',
                check: () => productComponents && productComponents.length > 0
            },
            {
                text: () => 'Softphones will be added automatically with default Area Code to make quantity of Phones with DLs to be equal to the number of DLs that will be added',
                type: 'info',
                check: () => component.get('v.app').isSoftphonesToBeAdded(component)
            }
        ];
        component.find('preselectedAreaCodesInfo').set('v.notifications', notificationAreaCodesInfo);
        component.find('preselectedAreaCodesInfo').update();
    }
});