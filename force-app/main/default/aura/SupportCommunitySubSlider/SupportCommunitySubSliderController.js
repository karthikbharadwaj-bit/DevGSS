/**
 * Created on 18.10.2018
 */
({

    doInit: function doInit(cmp, event, helper) {
        var items = cmp.get('v.sliderItems');
        cmp.set("v.count", items.length);
        helper.autoscroll = cmp.get('v.autoscroll');
        helper.nextSlide(cmp);
    },

    dotClick: function dotClick(cmp, event, helper) {
        helper.dotClick(cmp, event.currentTarget);
    },
    touchstart: function touchstart(cmp, event, helper) {
        helper.bodyTouchstart(event, cmp);
    },
    touchmove: function touchstart(cmp, event, helper) {
        helper.bodyTouchmove(event, cmp);
    },
    touchend: function touchend(cmp, event, helper) {
        helper.bodyTouchend(event, cmp);
    }
});