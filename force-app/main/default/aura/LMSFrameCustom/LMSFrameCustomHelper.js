({
    getComponentFrame : function(cmp){
        return cmp.getElements().filter(function(element){return element.tagName == "IFRAME"})[0];
    }
})