/**
 * Created on 23.11.2018
 */
({
    doInit: function(cmp) {
        var today = $A.localizationService.formatDate(new Date(), "YYYY");
        cmp.set('v.year', today);
    }
});