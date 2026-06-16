({
    showList: function (component) {
        var isShowList = component.get('v.isShowList');
        isShowList = !isShowList;
        component.set('v.isShowList', isShowList);
    }
});