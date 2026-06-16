import getAccounts from '@salesforce/apex/LookupController.getAccounts';
import getContacts from '@salesforce/apex/LookupController.getContacts';
import getRecords from '@salesforce/apex/LookupController.getRecords';

import { LookupResult } from './lookupResult';

export default class LookupService {
    constructor(methodName) {
        if (!window.lwcLookupRecordCache) {
            window.lwcLookupRecordCache = new RecordCache();
        }
        this.recordCache = window.lwcLookupRecordCache;
        this.fetchFunction = this.getFetchFunction(methodName);
    }

    search(params) {
        const isRecordSearch = !!params.recordId;
        if (isRecordSearch && this.recordCache.has(params.recordId)) {
            return Promise.resolve([this.recordCache.get(params.recordId)]);
        }
        return this.fetch(params)
            .then(result => {
                if (isRecordSearch && result && result.length > 0) {
                    this.recordCache.set(result[0]);
                }
                return result;
            });
    }

    fetch(params) {
        return this.fetchFunction({
            searchText: params.searchText,
            recordId: params.recordId,
            queryLimit: params.queryLimit,
            params: params.params
        })
            .then(result => {
                return result.map(r => new LookupResult(r));
            });
    }

    getFetchFunction(methodName) {
        switch (methodName) {
            case 'getAccounts':
                return getAccounts;
            case 'getContacts':
                return getContacts;
            case 'getRecords':
                return getRecords;
            default:
                return null;
        }
    }
}

class RecordCache {
    constructor() {
        this.cache = new Map();
    }

    set(result) {
        if (!result) {
            return;
        }
        this.cache.set(result.id, result);
    }

    has(resultId) {
        return this.cache.has(resultId);
    }

    get(resultId) {
        return this.cache.get(resultId);
    }
}