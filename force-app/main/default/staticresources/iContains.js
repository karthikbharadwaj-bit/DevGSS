/**
 * Example use:
 * $('div:icontains("Text in page")');
 * Will return jQuery object containing any/all of the following:
 * <div>text in page</div>
 * <div>TEXT in PAGE</div>
 * <div>Text in page</div>
 */
$.expr[':'].icontains = $.expr.createPseudo(function(text) {
    return function(e) {
        return $(e).text().toUpperCase().indexOf(text.toUpperCase()) >= 0;
    };
});