export class LookupResult {
    constructor(lookupResult) {
        this.id = lookupResult.Id;
        this.text = lookupResult.Text;
        this.meta = lookupResult.Meta;
        this.recordObj = lookupResult.RecordObj;
    }
}