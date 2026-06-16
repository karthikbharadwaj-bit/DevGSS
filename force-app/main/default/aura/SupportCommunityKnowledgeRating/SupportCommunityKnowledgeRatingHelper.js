/**
 * Created on 06.12.2018
 */
({
    updateInfo:function(cmp) {
        switch (window.app.Article.Rating) {
            case 0:
                cmp.set('v.like_class', '');
                cmp.set('v.dislike_class','');
                break;
            case 5:
                cmp.set('v.like_class', 'active');
                cmp.set('v.dislike_class','');
                break;
            case 1:
                cmp.set('v.like_class', '');
                cmp.set('v.dislike_class','active');
                break;
            default:
                cmp.set('v.like_class', '');
                cmp.set('v.dislike_class','');
                break;
        }
        if(window.app.Article.Rating !== 0) {
            cmp.set('v.comment_sended', true);
            cmp.set('v.comment_show', false);
            cmp.set('v.likesCount', window.app.Article.Likes.likes);
            cmp.set('v.dislikesCount', window.app.Article.Likes.dislikes);
            cmp.set('v.likesCount_show', true);
        }
    },
    sendRating: function(cmp, value, isLike) {
        var this_ = this;

        value.jsuid = window.app.jsUID;
        value.versionId = window.app.Article.Id;
        value.artid = window.app.Article.KbIdStr;
        var action = cmp.get("c.saveCommentAndRating");
        action.setParams( {value: JSON.stringify(value)});
        action.setCallback(this, function (response) {
            cmp.set('v.wait',false);
            const state = response.getState();
            const resValue = response.getReturnValue();
            if (state === "SUCCESS" && resValue.success === true) {
                console.log(resValue);

                if(!isLike) {
                    cmp.set('v.label_show',true);
                    // cmp.set('v.comment_header', 'Thank you for your feedback!');
                    // cmp.set('v.comment_message', 'The comment was successfully sent!');
                    // cmp.set('v.module_class', 'slds-fade-in-open');
                    cmp.set('v.comment_sended', true);
                    cmp.set('v.comment_show', false);
                    cmp.find('comment').set("v.value",'');
                    cmp.set('v.likesCount_show', true);
                }
                else {
                    if(resValue.Stat) {
                        window.app.Article.Likes = {PositiveVotesCount__c:resValue.Stat.PositiveVotesCount__c,NegativeVotesCount__c:resValue.Stat.NegativeVotesCount__c};
                        cmp.set('v.likesCount', window.app.Article.Likes.likes);
                        cmp.set('v.dislikesCount', window.app.Article.Likes.dislikes);
                    }
                    else {
                        cmp.set('v.likesCount','');
                        cmp.set('v.dislikesCount','');
                    }
                    cmp.set('v.comment_sended', false);
                    cmp.set('v.comment_show', value.rate !== 0);

                    cmp.set('v.likesCount_show', true);
                }

            } else {
                console.error("Failed with state: " + state, resValue);
                cmp.set('v.comment_sended', false);
                if(!isLike) {
                    cmp.set('v.comment_header', 'Error');
                    cmp.set('v.comment_message', 'Error sending comment!');
                    cmp.set('v.module_class', 'slds-fade-in-open');
                }
            }
        });
        $A.enqueueAction(action);
    }

});