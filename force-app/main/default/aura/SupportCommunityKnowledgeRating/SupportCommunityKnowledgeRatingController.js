({
    handleUpdate: function(cmp,event,helper) {
        if (event.getParam("param") === 'article')
            helper.updateInfo(cmp);
    },
    doInit: function(cmp,event,helper) {
        if(window.app)
            helper.updateInfo(cmp);
    },
    likeClick: function(cmp,event,helper) {
        cmp.set('v.wait',true);
        var cls = cmp.get('v.like_class');
        var rate = 0;
        if(cls === '') {
            cmp.set('v.like_class', 'active');
            cmp.set('v.dislike_class','');
            rate = 5;
        }
        else
            cmp.set('v.like_class','');
        helper.sendRating(cmp,{ rate: rate },true);
    },
    dislikeClick: function(cmp,event,helper) {
        var cls = cmp.get('v.dislike_class');
        cmp.set('v.wait',true);
        var rate = 0;
        if(cls === '')
        {
            cmp.set('v.dislike_class','active');
            cmp.set('v.like_class','');
            rate = 1;
        }
        else
            cmp.set('v.dislike_class','');
        helper.sendRating(cmp,{ rate: rate },true);
    },
    sendClick: function(cmp, event, helper) {
        if(window.app &&  window.app.Article.Id) {
            var comment = cmp.find('comment');
            if(comment.get('v.validity').valid){
                helper.sendRating(cmp,{ comm: comment.get("v.value") },false);
            }
        }

    },
    closeModal: function(cmp, event, helper) {
        cmp.set('v.module_class', '');
    }
});