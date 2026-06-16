({
    updateInfo: function(cmp) {

        if(window.app) {
            var pageName = cmp.get('v.searchPageName');
            cmp.set('v.updated', window.app.Article.Updated);
            cmp.set('v.author', window.app.Article.AuthorName);
            cmp.set('v.updatedBy', window.app.Article.UpdatedByName);
            cmp.set('v.views', window.app.Article.PageViews);
            cmp.set('v.kbid', window.app.Article.KbId);
            cmp.set('v.tags', window.app.Article.getTagsLinks(pageName));
            cmp.set('v.tagsLen', window.app.Article.Tags.length);

        }
    }
});