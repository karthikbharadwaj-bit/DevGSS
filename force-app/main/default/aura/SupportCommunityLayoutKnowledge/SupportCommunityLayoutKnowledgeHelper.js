/**
 * Created on 29.11.2018
 */
({
    send_event: function send_event(param) {
        var updateEvent = $A.get("e.c:SupportCommunityUserEvent");
        updateEvent.setParams({ param: param });
        updateEvent.fire();
    },

    getArticle: function(cmp) {
        var this_ = this;
        var url = document.location.pathname;
        if (url !== this.url) this.loaded = false;
        if (url.length > 1 && window.app && window.app.jsUID && !this.loaded) {
            this.url = url;
            this.loaded = true;
            url = url.split("/");
            url = decodeURIComponent(url[url.length - 1]);
            RC.salesforce
                .request(cmp, "c.getKnowledgeInfo", {
                    value: JSON.stringify({ urlName: url, jsUID: window.app.jsUID, language: window.app.language }),
                })
                .then(
                    $A.getCallback(function(data) {
                        var stats = {};
                        try {
                            data.Article.Rating = data.Rating;
                            data.Article.Files = data.Docs;
                            stats = data.Stats;
                            data = data.Article;
                        } catch (e) {
                            data = null;
                        }
                        window.app.Article = data;
                        window.app.Article.Likes = {
                            PositiveVotesCount__c: stats.PositiveVotesCount__c,
                            NegativeVotesCount__c: stats.NegativeVotesCount__c,
                        };
                        this_.send_event("article");
                    })
                )
                .catch(console.error("ERROR: can't get knowledge info"));
        }
    },
});