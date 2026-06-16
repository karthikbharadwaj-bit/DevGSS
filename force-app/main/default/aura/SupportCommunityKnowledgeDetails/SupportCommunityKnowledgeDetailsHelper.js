/**
 * Created on 06.12.2018
 */
({
    updateDetails: function(cmp) {
        var summary = jQuery('<div>').html(window.app.Article.Summary);
        var art = jQuery(window.app.Article.Info);

        jQuery('.cSupportCommunityKnowledgeDetails').append(summary).append(art);
        // jQuery('.cSupportCommunityKnowledgeDetails').html('<iframe src="https://youtube.com/"/>');
       // document.querySelector('.cSupportCommunityKnowledgeDetails').innerHTML = window.app.Article.Info
    }
});