({
    afterRender : function(cmp, helper) {
        var cmpFrame = helper.getComponentFrame(cmp);
        cmpFrame.setAttribute("allowfullscreen", "true");
        cmpFrame.setAttribute("mozallowfullscreen", "true");
        cmpFrame.setAttribute("msallowfullscreen", "true");
        cmpFrame.setAttribute("oallowfullscreen", "true");
        cmpFrame.setAttribute("webkitallowfullscreen", "true");
    }
})