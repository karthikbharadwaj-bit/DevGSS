({
    doInit: function(component) {
        var doc = component.get('v.document');
        var fileExtension = (doc && doc.name && doc.name.lastIndexOf('.') > -1)
            ? doc.name.substring(doc.name.lastIndexOf('.') + 1) : '';

        var defaultIconName = 'doctype:unknown';

        // file formats supported by DocuSign: https://support.docusign.com/guides/ndse-user-guide-supported-file-formats
        var fileExtensionToIconNameMapping = new Map([
            ['doc', 'doctype:word'],
            ['docm', 'doctype:word'],
            ['docx', 'doctype:word'],
            ['dot', 'doctype:word'],
            ['dotm', 'doctype:word'],
            ['dotx', 'doctype:word'],
            ['msg', 'doctype:attachment'],
            ['wpd', 'doctype:attachment'],
            ['htm', 'doctype:html'],
            ['html', 'doctype:html'],
            ['rtf', 'doctype:rtf'],
            ['txt', 'doctype:txt'],
            ['pdf', 'doctype:pdf'],
            ['xps', 'doctype:xml'],
            ['bmp', 'doctype:image'],
            ['gif', 'doctype:image'],
            ['jpg', 'doctype:image'],
            ['jpeg', 'doctype:image'],
            ['png', 'doctype:image'],
            ['tif', 'doctype:image'],
            ['tiff', 'doctype:image'],
            ['pot', 'doctype:ppt'],
            ['potx', 'doctype:ppt'],
            ['pps', 'doctype:ppt'],
            ['ppt', 'doctype:ppt'],
            ['pptm', 'doctype:ppt'],
            ['pptx', 'doctype:ppt'],
            ['csv', 'doctype:csv'],
            ['xls', 'doctype:excel'],
            ['xlsm', 'doctype:excel'],
            ['xlsx', 'doctype:excel']
        ]);

        var iconName = (fileExtension && fileExtensionToIconNameMapping.has(fileExtension))
            ? fileExtensionToIconNameMapping.get(fileExtension) : defaultIconName;

        component.set("v.iconName", iconName);
    },
    toggleSelect: function (component) {
        component.getEvent("toggleSelectDocument").setParams({
            params: {
                index: component.get('v.index')
            }
        }).fire();
    }
});