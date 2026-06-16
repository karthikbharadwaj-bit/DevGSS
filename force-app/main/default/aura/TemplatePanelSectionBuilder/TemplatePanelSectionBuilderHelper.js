/* global TP */
({
    init: function(component){
        var templateBodyEditor = component.get('v.templateBodyEditor');
        var stylesEditor =  component.get('v.stylesEditor');

        var selectedSection = component.get('v.selectedSection');
        var selectedTemplate = component.get('v.selectedTemplate');

        var sectionBody = this.getSectionBody(selectedSection);
        var previewBody = this.getPreviewBody(
            component,
            selectedSection.Id,
            selectedTemplate,
            sectionBody);
        templateBodyEditor.setValue(sectionBody, -1);
        component.set('v.templateBodyEditor',templateBodyEditor);
        component.set('v.previewBody', previewBody);

        var sectionStyles = this.getSectionStyles(selectedSection);
        var previewStyles = this.getPreviewStyles(
            component,
            selectedSection.Id,
            selectedTemplate,
            sectionStyles);
        stylesEditor.setValue(sectionStyles, -1);
        component.set('v.stylesEditor',stylesEditor);
        component.set('v.previewStyles', previewStyles);

        component.set('v.previewParameters', selectedTemplate.Parameters__c);

        this.previewPDF(component);

    },
    initEditor: function(component){
        var helper = this;

        // Template Body Editor
        var templateBodyEditor = TP.ace.edit("body-editor");
        templateBodyEditor.setTheme("ace/theme/monokai");
        templateBodyEditor.getSession().setUseSoftTabs(true);
        templateBodyEditor.setShowPrintMargin(true);
        templateBodyEditor.setOption("wrap", 120);
        templateBodyEditor.setPrintMarginColumn(120);
        templateBodyEditor.getSession().setMode("ace/mode/html");
        templateBodyEditor.setOptions({
            enableBasicAutocompletion: true,
            enableSnippets: true,
            enableLiveAutocompletion: false
        });
        templateBodyEditor.getSession().on('change', function(aceEvent){
            helper.templateBodyEditorChange(component, templateBodyEditor);
        });
        component.set('v.templateBodyEditor',templateBodyEditor);

        // Styles Editor
        var stylesEditor = TP.ace.edit("styles-editor");
        stylesEditor.setTheme("ace/theme/monokai");
        stylesEditor.getSession().setUseSoftTabs(true);
        stylesEditor.setShowPrintMargin(true);
        stylesEditor.setOption("wrap", 120);
        stylesEditor.setPrintMarginColumn(120);
        stylesEditor.getSession().setMode("ace/mode/css");
        stylesEditor.setOptions({
            enableBasicAutocompletion: true,
            enableSnippets: true,
            enableLiveAutocompletion: false
        });
        stylesEditor.getSession().on('change', function(aceEvent){
            helper.stylesEditorChange(component, stylesEditor);
        });
        component.set('v.stylesEditor',stylesEditor);
    },
    /**
     * User changed text in editor
     */
    templateBodyEditorChange: function(component, templateBodyEditor){
        var previewBody = this.getPreviewBody(
            component,
            component.get('v.selectedSection.Id'),
            component.get('v.selectedTemplate'),
            templateBodyEditor.getValue());
        component.set('v.previewBody',previewBody);
        this.schedulePreview(component);
        if(component.get('v.autoSave')){
            this.scheduleSave(component);
        }
    },
    /**
     * User changed text in editor
     */
    stylesEditorChange: function(component, stylesEditor){
        var previewStyles = this.getPreviewStyles(
            component,
            component.get('v.selectedSection.Id'),
            component.get('v.selectedTemplate'),
            stylesEditor.getValue());
        component.set('v.previewStyles', previewStyles);
        this.schedulePreview(component);
        if(component.get('v.autoSave')){
            this.scheduleSave(component);
        }
    },
    schedulePreview: function(component){
        var helper = this;
        var previewTimeout = component.get('v.previewTimeout');
        clearTimeout(previewTimeout);
        previewTimeout = setTimeout($A.getCallback(function() {
            if (component.isValid()) {
                helper.previewPDF(component);
            }
        }), 5000);
        component.set('v.previewTimeout',previewTimeout);
    },
    scheduleSave: function(component){
        var helper = this;
        var saveTimeout = component.get('v.saveTimeout');
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout($A.getCallback(function() {
            if (component.isValid()) {
                helper.saveSection(component, true);
            }
        }), 5000);
        component.set('v.saveTimeout',saveTimeout);
    },
    previewPDF: function(component){
        component.find('previewPDFForm').getElement().submit();
    },
    getSectionBody: function(section){
        var sectionBody = '';
        var contentKeys = [
            'Content_1__c',
            'Content_2__c',
            'Content_3__c',
            'Content_4__c',
            'Content_5__c'];
        contentKeys.forEach(function(key){
            sectionBody += section[key] || '';
        });
        return sectionBody;
    },
    getSectionStyles: function(section){
        var sectionStyles = '';
        sectionStyles += section.CSS_Styles_1__c || '';
        return sectionStyles;
    },
    getPreviewStyles: function(component,sectionId, template, sectionStyles){
        var helper = this;
        var previewStyles = '';
        var sections = component.get('v.sections');
        previewStyles += template.CSS_Styles_1__c || '';
        var sectionsMap = {};
        sections.forEach(function (s) { sectionsMap[s.Id] = s; });

        template.TemplateSectionJunction__r.forEach(function (j) {
            if (j.Template_Section__c === sectionId){
                previewStyles += sectionStyles || '';
            } else {
                previewStyles += helper.getSectionStyles(sectionsMap[j.Template_Section__c]);
            }
        });
        return previewStyles;
    },
    getPreviewBody: function(component, sectionId, template, sectionBody){
        var helper = this;
        var previewBody = '';
        var sections = component.get('v.sections');
        var sectionsMap = {};
        sections.forEach(function (s) { sectionsMap[s.Id] = s; });

        template.TemplateSectionJunction__r.forEach(function (j) {
            if (j.Template_Section__c === sectionId){
                previewBody += sectionBody
            } else {
                previewBody += helper.getSectionBody(sectionsMap[j.Template_Section__c]);
            }
        });
        return previewBody;
    },
    saveSection: function(component, isHideSuccessToast){
        var stylesEditor = component.get('v.stylesEditor');
        var templateBodyEditor = component.get('v.templateBodyEditor');
        var selectedSection = component.get('v.selectedSection');
        component.find('saveButton').set('v.disabled',true);
        component.find('saveButton').set('v.label','Saving...');
        TP.salesforce.request(component, 'c.saveSection',{
                sectionId: selectedSection.Id,
                content: templateBodyEditor.getValue(),
                styles: stylesEditor.getValue()
            })
            .then($A.getCallback(function() {
                if(!isHideSuccessToast){
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'success',
                        header: selectedSection.Name+' Section Saved Successfully',
                        defaultTimeout: true
                    }).fire();
                }
            }))
            .catch($A.getCallback(function(error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed To Save '+selectedSection.Name+'Section',
                    details: TP.salesforce.getResponseError(error)
                }).fire();
                console.error(error);
            }))
            .then($A.getCallback(function() {
                component.find('saveButton').set('v.disabled',false);
                component.find('saveButton').set('v.label','Save');
            }))
    }
})