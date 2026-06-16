export class File {
    constructor(record) {
        this.id = record.id;
        this.pathOnClient = record.pathOnClient;
        this.title = record.title;
        this.contentSize = record.contentSize;
        this.contentDocumentId = record.contentDocumentId;
        this.contentUrl = record.contentUrl;
        this.fileType = record.fileType;
        this.lastModifiedDate = record.lastModifiedDate;
        this.latestPublishedVersionId = record.latestPublishedVersionId;

        this.parentId = record.parentId;
        this.isDeleted = false;
        this.sectionId = '';
        this.size = this.contentSize;
        this.name = this.title;
        this.lastModified = this.lastModifiedDate;
        this.uid = new Date().getTime() + Math.random();
    }
}