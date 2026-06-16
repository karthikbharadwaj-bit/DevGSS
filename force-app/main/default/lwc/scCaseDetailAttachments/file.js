export class File {
    id;
    name;
    url;
    ext;
    size;
    get fileSize() {
        return File.humanFileSize(this.size, true);
    }
    static humanFileSize(bytes, si) {
        const thresh = si ? 1000 : 1024;
        if (Math.abs(bytes) < thresh) {
            return bytes + " B";
        }
        const units = si
            ? ["kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
            : ["KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"];
        let u = -1;
        do {
            bytes /= thresh;
            ++u;
        } while (Math.abs(bytes) >= thresh && u < units.length - 1);
        return bytes.toFixed(1) + " " + units[u];
    }
    constructor(id, name, url, size) {
        this.id = id;
        this.name = name || "";
        this.url = url;
        this.size = size;
        const spName = name.split(".");
        this.ext = spName.pop();
        this.label = spName.join(".");
        if(this.label.length === 0) {
            this.label = name;
            this.ext = "";
        }
    }
}