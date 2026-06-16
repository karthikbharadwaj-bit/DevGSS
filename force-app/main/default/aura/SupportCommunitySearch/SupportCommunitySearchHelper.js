/**
 * Created on 17.09.2018
 */
({
    redirect: function redirect(cmp) {
        var search_element = cmp.find("searchField");
        var lnk = cmp.get('v.link');
        window.open(lnk + "#q=" + search_element.get("v.value") + "&sort=relevancy", '_blank');
        // window.open("/rcsupport2013/#sort=relevancy&q=" + search_element.get("v.value"), '_blank');
        search_element.set("v.value", "");
    }
});