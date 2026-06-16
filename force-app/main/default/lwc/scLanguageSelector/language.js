export class Language {
    constructor(obj, pageLang) {
        this.domain = obj.domain || document.location.origin + document.location.pathname;
        this.code = obj.code || null;
        this.shortTitle = obj.shortTitle || null;
        this.language = obj.language || null;
        this.label = obj.title || this.code;
        this.isCommunity = obj.domain ? obj.isCommunity : true;
        this.isCurrent = this.language === pageLang;
        this.inx = obj.inx || 0;
    }
    get cssClass() {
        return "country-switcher__item" + (this.isCurrent ? " country-switcher__item--active" : "");
    }
    get changeLangParam() {
        return document.location.origin + document.location.pathname + this.addLangParam() + document.location.hash;
    }
    get link() {
        return this.isCommunity ? this.domain + "?language=" + this.language : this.domain;
    }
    get isCurrentDomain() {
        const protocolSplitter = "://";
        const curDomain = document.location.host + document.location.pathname;
        return (
            curDomain.indexOf(this.domain.substr(this.domain.indexOf(protocolSplitter) + protocolSplitter.length)) === 0
        );
    }
    addLangParam() {
        let params = this.getUrlVars().filter(item => item.name !== "language");
        params.push({ name: "language", value: this.language });
        return "?" + params.map(item => `${item.name}=${item.value}`).join("&");
    }
    getUrlVars() {
        const url = document.location.search;
        let params = [];
        const hashes = url.slice(url.indexOf("?") + 1).split("&");
        for (let i = 0; i < hashes.length; i++) {
            const hash = hashes[i].split("=");
            params.push({ name: hash[0], value: hash[1] });
        }
        return params;
    }
}