/**
 * Created on 05.02.2019
 */
({
    doInit: function(cmp, event, helper) {
        // cmp.set("v.siteUrl", encodeURIComponent(document.location.href));
        // cmp.set("v.siteTitle", encodeURIComponent(document.title));
        helper.init(cmp);
    },
    handleUpdate: function(cmp, event, helper) {
        if (event.getParam("param") === "article") {
            helper.init(cmp);
        }
    },

    shareClick: function(cmp, event, helper) {
        console.log(event);
        var el = event.currentTarget;
        var target = el.getAttribute("title").toLowerCase();
        var url = el.getAttribute("href");
        switch(target) {
            case 'print':
                event.preventDefault();
                helper.print();
                break;
            case 'bookmark':
                event.preventDefault();
                helper.bookmarkMe();
                break;
            case 'email':
                break;
            default:
                event.preventDefault();
                helper.openShare(target, url);
                break;
        }
    }
});