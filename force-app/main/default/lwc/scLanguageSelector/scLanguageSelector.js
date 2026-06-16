import { LightningElement, track, api } from "lwc";
import getLanguages from "@salesforce/apex/SupportCommunityUsers.getLanguages";
import { Language } from "./language";
export default class ScLanguageSelector extends LightningElement {
    @track languages = [];
    @track isLoaded = false;
    @api pageLang = "";
    default = new Language({ code:"En", language: "en_US", title: "United States", shortTitle: "US" }, "en_US");
    shareLanguages() {
        const evt = new CustomEvent("sc-language_list", {
            bubbles: true,
            cancelable: false,
            detail: JSON.parse(JSON.stringify(this.languages)),
        });
        document.dispatchEvent(evt);
    }
    findDomainLanguage() {
        const lang = this.languages.filter(lang => lang.isCurrentDomain);
        if (lang.length > 0) return lang[0];
        else return this.default;
    }
    get isBuilder() {
        return (
            document.location.host.indexOf("livepreview") >= 0 &&
            document.location.search.indexOf("app=commeditor") >= 0
        );
    }
    get currentLanguage() {
        const curLang = this.languages.filter(lang => lang.isCurrent);
        if (curLang.length > 0) {
            if (!curLang[0].isCurrentDomain && !this.isBuilder) {
                document.location.href = this.findDomainLanguage().changeLangParam;
            }
            return curLang[0];
        } else {
            console.warn(`Language list don't have current page language (${this.pageLang})!`);
            return this.default;
        }
    }
    loadLanguages() {
        getLanguages()
            .then(result => {
                if (result) {
                    this.languages = result
                        .map(lang => new Language(lang, this.pageLang))
                        .sort((a, b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
                    this.isLoaded = true;
                    this.shareLanguages();
                }
                this.error = undefined;
            })
            .catch(error => {
                console.warn(error);
                this.error = error;
            });
    }
    changeLanguage(selectedLangCode) {
        const selectedLanguage = this.languages.filter(lang => lang.language === selectedLangCode);
        if (selectedLanguage.length > 0) document.location.href = selectedLanguage[0].link;
        else console.warn(`${selectedLangCode} not in languages list!`);
    }
    select(e) {
        const selectedLangCode = e.currentTarget.getAttribute("data-value");
        this.changeLanguage(selectedLangCode);
    }
    constructor() {
        super();
        this.loadLanguages();
        document.addEventListener(
            "sc-language_change",
            e => {
                this.changeLanguage(e.detail);
            },
            false
        );
    }
}