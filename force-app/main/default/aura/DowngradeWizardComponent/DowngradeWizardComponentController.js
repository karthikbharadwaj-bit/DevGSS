({
    afterScriptsLoaded: function (component, event, helper) {
        let wizardType = component.get('v.wizardType');
        const isInline = component.get('v.isInline');
        wizardType = wizardType.toLowerCase();
        let wizardName = wizardType;

        if (!wizardType) {
            helper.showError(helper.ERROR_MESSAGES.empty_wizard_type);
            return;
        }

        if (!helper.configStore[wizardType]) {
            helper.showError(helper.ERROR_MESSAGES.empty_wizard_config);
            return;
        }

        helper.showSpinner(true);

        if (!isInline) {
            component.set('v.isEditable', true);
        }

        const wizardConfig = helper.configStore[wizardType];
        let initialConf = null;

        helper.configuration = wizardConfig;

        _.mapObject(wizardConfig, (val) => {
            if (val.primary) {
                initialConf = val.config;
            }
        });

        if (helper.nameMapping[wizardType]) {
            wizardName = helper.nameMapping[wizardType]
        }

        component.set('v.wizardType', wizardType);
        component.set('v.wizardName', wizardName);

        helper.determineOpportunityId(component);
        helper.loadOppCloseInfo(component)
            .then($A.getCallback((oppData) => {
                if (!helper.isWizardFieldsFilled(component, wizardConfig, oppData)) {
                    return helper.getPanelConfig_ctrl(component, JSON.stringify(initialConf));
                } else {
                    return helper.getPanelConfigAll(component, wizardConfig);
                }
            }));
    },

    toggleEditMode: function (component, event, helper) {
        const isEditMode = component.get('v.isEditable');

        helper.setEditable(component, !isEditMode);
    },

    submit: function (component, event, helper) {
        const oppInfo = component.get('v.oppInfo');

        if (oppInfo) {
            helper.processOppInfo(component);
        } else {
            helper.modalActionOk(component);
        }
    },

    onOptionsPanelEvent: function (component, event, helper) {
        const eData = event.getParams();
        const isLoadingConfig = component.get('v.global.isLoading');
        const wizardConfig = helper.getWizardConfig(component);

        if (eData.action === 'change' && !isLoadingConfig) {
            const panelParams = eData.data;
            const configItem = helper.configuration[panelParams.name];

            helper.getErrorsByPanel(component, panelParams);

            if (configItem && configItem.dependencies) {
                const panelValues = helper.getWizardCurrentValues(component);
                const result = helper.getWizardSteps(component, wizardConfig, panelValues);

                const panelsToAdd = {};
                const panelsToRemove = {};

                _.forEach(result, (resultItem) => {
                    const configuration = helper.configuration[resultItem.name];

                    if(!_.isArray(configuration.dependencies)) {
                        return;
                    }

                    _.forEach(configuration.dependencies, (cfgDependency) => {
                        if(panelValues[resultItem.name]) {
                            const configList = helper.getConfigList(panelValues[resultItem.name], cfgDependency);

                            if(_.isArray(configList.add)) {
                                _.forEach(configList.add, (cfgToAdd) => {
                                    if (!panelsToAdd[cfgToAdd]) {
                                        panelsToAdd[cfgToAdd] = true;
                                    }
                                });
                            }

                            if(_.isArray(configList.remove)) {
                                _.forEach(configList.remove, (cfgToRemove) => {
                                    if (!panelsToRemove[cfgToRemove] && !panelsToAdd[cfgToRemove]) {
                                        panelsToRemove[cfgToRemove] = true;
                                    }
                                });
                            }
                        }
                    })
                });

                const configList = {
                    add: Object.keys(panelsToAdd),
                    remove: _.filter(Object.keys(panelsToRemove), (panel) => !panelsToAdd[panel])
                };

                helper.applyConfigList(component, configList);
            }
        }

        const canSave = helper.checkFinalPanelVisible(component)
            && helper.checkForCompletionAllForms(component) && !isLoadingConfig;

        component.set("v.canSave", canSave);
    },

    cancel: function (component, event, helper) {
        const isInline = component.get('v.isInline');
        const wizardType = component.get('v.wizardType');

        if (isInline) {
            helper.showSpinner(true);

            component.set('v.panels', []);
            helper.loadOppCloseInfo(component)
                .then($A.getCallback(() => {
                    return helper.getPanelConfigAll(component, helper.configStore[wizardType]);
                }))
                .then($A.getCallback(() => {
                    helper.setEditable(component, false);
                    helper.showSpinner(false);
                }))
                .catch($A.getCallback((res) => {
                    console.error(res);

                    helper.showSpinner(false);

                    _.forEach(res.getError(), (error) => {
                        helper.showError(error.message);
                    });
                }));
        } else {
            helper.uncheckConfirmAndClose(component).then(() => {
                helper.redirectToOpportunity(component);
            });
        }
    }
});