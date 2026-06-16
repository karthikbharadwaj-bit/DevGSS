import { statusList } from "./statusList";

export default class ScTrustStatusHelper {
    static list = statusList;
    static get defaultStatus() {
        return ScTrustStatusHelper.list[0] || null;
    }
    static searchByField(field, query) {
        const search = ScTrustStatusHelper.list.filter(status => status[field] === query);
        return search.length > 0 ? search[0] : ScTrustStatusHelper.defaultStatus;
    }
    static getByLevel(lvl) {
        return ScTrustStatusHelper.searchByField("level", lvl);
    }
    static getByLabel(label) {
        return ScTrustStatusHelper.searchByField("label", label);
    }
    static getByName(name) {
        return ScTrustStatusHelper.searchByField("name", name);
    }
}