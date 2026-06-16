/**
 * Created on 13.09.2018
 */
({
    languages: [],
    getURLParameter: function getURLParameter(name) {
        return decodeURIComponent((location.search.match(RegExp("[?|&]" + name + '=(.+?)(&|$)')) || [, null])[1]);
    },
    checkLang: function checkLang(val) {
        var out = { 'label': 'US', 'value': 'en_US' };
        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
            for (var _iterator = this.languages[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                var lang = _step.value;

                if (lang.value === val) {
                    lang.checked = true;
                    out = lang;
                } else lang.checked = false;
            }
        } catch (err) {
            _didIteratorError = true;
            _iteratorError = err;
        } finally {
            try {
                if (!_iteratorNormalCompletion && _iterator.return) {
                    _iterator.return();
                }
            } finally {
                if (_didIteratorError) {
                    throw _iteratorError;
                }
            }
        }

        return out;
    },
    renewLang: function renewLang(cmp, curLang) {
        var selected = this.checkLang(curLang);
        cmp.set('v.options', this.languages);
        cmp.set('v.current', selected);
    },
    changeLanguage: function (cmp, lang) {
        var link = null;
        switch (lang) {
            case "en_AU":
                link = "https://www.ringcentral.com.au/";
                break;
            case "en_CA":
                link = "https://www.ringcentral.ca/";
                break;
            case "fr":
                link = "https://success.ringcentral.com/lc/cms/FR_Ressources";
                break;
            case "de":
                link = "https://success.ringcentral.com/lc/cms/DE_Ressourcen";
                break;
            case "en_IE":
                link = "https://www.ringcentral.ie/";
                break;
            case "nl_NL":
                link = "https://www.ringcentral.nl/en/";
                break;
            case "en_SG":
                link = "https://www.ringcentral.sg/";
                break;
            case "es":
                link = "https://success.ringcentral.com/lc/cms/ES_Recursos";
                break;
            case "en_GB":
                link = cmp.get("v.UK") + "?language=en_GB";
                break;
            case "en_US":
                link = cmp.get("v.US") + "?language=en_US";
                break;
        }
        if (link) window.location.href = link;

    }
});