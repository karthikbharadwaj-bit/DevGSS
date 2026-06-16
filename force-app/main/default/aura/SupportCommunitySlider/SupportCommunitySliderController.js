({
    handleUpdate: function (cmp, event, helper) {
        var who = event.getParam("param");
        if (who === 'init') {
            helper.getSlides(cmp, 'slider', 'Full');
            helper.getSlides(cmp, 'slider.mobile', 'Mob');
        }
    },
    doInit: function (cmp, event, helper) {
        helper.getSlides(cmp, 'slider', 'Full');
        helper.getSlides(cmp, 'slider.mobile', 'Mob');
    }
});