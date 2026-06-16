/**
 * Created on 06.12.2018
 */
({
    updateInfo:function(cmp) {
        var files = window.app.Article.Files;
        if(!(files && files.length > 0) )
            cmp.set('v.files_show', false);
        else {
            cmp.set('v.files_show', true);
            cmp.set('v.files', files);
        }
    }
});