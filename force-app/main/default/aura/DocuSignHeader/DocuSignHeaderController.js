({
    openManageTab: function (component) {
        let app = component.get('v.app');

        app.tabs.openManage();

        component.set('v.app', app);
    }
});