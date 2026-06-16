class ScAdminTopic {
    constructor(data, isCustom, domain, position) {
        try {
            data = JSON.parse(JSON.stringify(data));
        } catch (e) {
            console.error(e);
            data = {};
        }
        this.id = data.id || '0';
        this.name = data.name || '';
        this.isCustom = isCustom || false;
        this.position = position || data.position || null;
        this.url = data.url || '';
        this.langCode = data.langCode || 'en_US';
        this.cname = '#';
        this.hl = false;
        this.cName = {defaultClass: 'slds-item'};
        this.domain = domain || '';
        this.isEmpty = data.isEmpty || false;
    }
    isEqualId(id) {
        return this.id === id;
    }
    toJSON() {
        return JSON.stringify({
            id: this.id,
            name: this.name,
            isCustom: this.isCustom,
            url: this.url,
            langCode: this.langCode,
            position: this.position
        });
    }
    toApex() {
        return {
            id: this.id,
            name: this.name,
            langCode: this.langCode,
            position: this.position,
            url: this.url
        };
    }

    set cName(p) {
        this.cname = p.defaultClass
            + (this.position === p.overIndex ? ' drop' : '')
            + (this.isCustom ? ' custom':'')
            + (this.isEmpty ? ' empty':'')
            + (this.hl ? ' highlight':'');
    }
    set highlight(hItem) {
        if(hItem) {
            this.hl = this.id === hItem;
        } else {
            this.hl = false;
        }
    }
    get highlight() {
        return this.hl;
    }
    get cName() {
        return this.cname;
    }
    get link() {
        return `${this.domain}article/${this.url}?language=${this.langCode}`
    }
}

export { ScAdminTopic };