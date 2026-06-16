({
    createContent: function (component) {
        var helper = this;
        var metadata = component.get('v.metadata');
        var renderPromise = Promise.resolve();


        metadata.layoutColumns.forEach(function (columnMetadata) {
            renderPromise = renderPromise.then($A.getCallback(function () {
                return Promise.all([
                        helper.createColumn(),
                        helper.createFields(component, columnMetadata)
                    ])
                    .then($A.getCallback(function (newComponents) {
                        var newColumn = newComponents[0];
                        var newFields = newComponents[1];

                        newColumn.set('v.body', newFields);

                        var columns = component.get('v.columns');
                        columns.push(newColumn);
                        component.set('v.columns', columns);
                    }))
                    .catch($A.getCallback(function (error) {
                        console.log(error.getError());
                    }))
            }));
        });

        return renderPromise;
    },
    createColumn: function () {
        return QW.components.createOne('lightning:layoutItem', {
            'class': 'slds-col col_equal'
        });
    },
    createFields: function (component, columnMetadata) {
        var helper = this;
        var renderPromise = Promise.resolve();
        if (!Array.isArray(columnMetadata.layoutItems))
            return;

        var newFields = [];
        columnMetadata.layoutItems.forEach(function (layoutItem) {
            renderPromise = renderPromise.then($A.getCallback(function () {
                    return helper.createField(component, layoutItem);
                }))
                .then($A.getCallback(function (newField) {
                    newFields.push(newField);
                }));
        });

        return renderPromise.then($A.getCallback(function () {
                return newFields;
            }));
    },
    createField: function (component, layoutItem) {
        return QW.components.createOne('c:LayoutBuilderLayoutItem', {
            layoutItem: layoutItem,
            record: component.getReference('v.record'),
            enabledPages: component.getReference('v.enabledPages')
        });
    }


});