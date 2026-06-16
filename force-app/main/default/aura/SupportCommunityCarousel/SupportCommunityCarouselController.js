({
    doInit: function doInit(cmp, event, helper) {
        if(!(typeof jQuery === "undefined" )) {
            helper.doInitJQ(cmp);
        }
    },

    dotClick: function dotClick(cmp, event, helper) {
        helper.dotClick(event.currentTarget.getAttribute("data-page") * 1);
    },
    carouselClick: function carouselClick(cmp, event, helper) {
        // window.open(,'_blank');
        // document.location.href = event.currentTarget.getAttribute("data-link");
       // window.open(event.currentTarget.getAttribute("data-link"), '_blank');
    },
    arrowClick: function arrowClick(cmp, event, helper) {
        var direction = event.currentTarget.getAttribute("data-dir");
        if (direction === "left") helper.left();else helper.right();
    },
    handleUpdate: function (cmp, event, helper) {
        var who = event.getParam("param");
        if(cmp.get('v.first_init')) {
            helper.doInitJQ(cmp);
        }
    },
});