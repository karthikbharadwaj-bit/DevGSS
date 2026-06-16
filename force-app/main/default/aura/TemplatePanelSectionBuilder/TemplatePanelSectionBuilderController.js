/* global ace */
({
    templatePanelHelperLoaded: function(component, event, helper){
        helper.initEditor(component);
    },
    openTemplateList: function(component, event, helper){
        component.set('v.autoSave',false);
        $A.get("e.c:TemplatePanelEvent").setParams({
            target: 'templateList'
        }).fire();
    },
    onTemplatePanelEvent: function(component, event, helper){
        var params = event.getParams();
        if(params.target === 'sectionBuilder'){
            helper.init(component);
        }
    },
    save: function(component, event, helper){
        helper.saveSection(component);
        var saveTimeout = component.get('v.saveTimeout');
        clearTimeout(saveTimeout);
        component.set('v.saveTimeout',saveTimeout);
    },
    previewPDF: function(component, event, helper){
        var previewTimeout = component.get('v.previewTimeout');
        clearTimeout(previewTimeout);
        component.set('v.previewTimeout',previewTimeout);
        helper.previewPDF(component);
    },
    help: function(component, event, helper){
        $A.util.addClass(component.find('helpModal'), 'slds-slide-up-saving');
        $A.util.addClass(component.find('helpModalBackdrop'), 'slds-backdrop_open');
    },
    closeHelp: function(component, event, helper){
        $A.util.removeClass(component.find('helpModal'), 'slds-slide-up-saving');
        $A.util.removeClass(component.find('helpModalBackdrop'), 'slds-backdrop_open');
    },
    fixEditorResize: function(component){
    	var templateBodyEditor = component.get('v.templateBodyEditor');
	    templateBodyEditor.resize();
    	component.set('v.templateBodyEditor',templateBodyEditor);
    	
	}
})