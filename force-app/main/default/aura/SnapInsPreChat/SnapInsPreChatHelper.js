({
    startChat: function (component, helper, type) {
        var prechatFields = component.get('v.prechatFields');
        var fields = prechatFields.map(function(f) {
            return { name: f.name, label: f.label, value: f.value };
        });
        
        var site;
        try {
            site = (self != top)
                ? document.referrer
                : document.location.href;
        } catch (cannotGetSite) {
            site = '';
        }
        this.getField(fields, 'Site__c').value = site;
        
        var employeeNumber = this.getField(fields, 'NumberOfEmployees__c');
        employeeNumber.value = component.get('v.inputEmployeeNumber');

        var companyName = this.getField(fields, 'Company__c');
        companyName.value = component.get('v.inputCompany');

        var chatRouting = this.getField(fields, 'Original_SFDC_Source__c');
        if (type == 'sales') {
            this.isSalesBucketAgentsOnline(component, helper);
            chatRouting.value = 'sales-' + component.get('v.sales');
        } else if (type == 'support') {
            chatRouting.value = 'support-'+ component.get('v.support');
        }
        component.find("prechatAPI").startChat(fields);
    },

    populateAuthInfo: function (component) {
        var fields = component.get('v.prechatFields');

        this.getField(fields, 'FirstName').value = component.get('v.inputFirstName');
        this.getField(fields, 'LastName').value = component.get('v.inputLastName');
        this.getField(fields, 'Email').value = component.get('v.inputEmail');
        this.getField(fields, 'Phone').value = component.get('v.inputPhone');
        this.getField(fields, 'Company__c').value = component.get('v.inputCompany');

        component.set('v.name', this.getFieldValue(fields, 'FirstName'));
        component.set('v.company', this.getFieldValue(fields, 'Company__c'));
    },

    getTypeService: function(component) {
        var fields = component.get('v.prechatFields');
        var salesOrSupport = this.getFieldValue(fields, 'Original_SFDC_Source__c');
        salesOrSupport = salesOrSupport ? salesOrSupport : "both";	// if undefined - would be both sales and support
        if (salesOrSupport.indexOf('-') > -1) { // format: seviceType-pageType
            var partsArray = salesOrSupport.split('-');
            component.set('v.typeService', partsArray[0]);
            component.set("v.pageType", partsArray[1]);
        } else { // this is not GW or SW -> routing to bot 
            component.set('v.typeService', 'both');
            component.set('v.supportRouting', 'bot'); // routing support to bot
        }
    },

    getFieldsInfoFromParams: function (component) {
        var fields = component.find("prechatAPI").getPrechatFields();
        component.set('v.prechatFields', fields);
    },

    isEnoughInfoToAuthenticate: function (component) {
        var fields = component.get('v.prechatFields');

        var fn = this.getFieldValue(fields, 'FirstName') || '';
        var ln = this.getFieldValue(fields, 'LastName') || '';
        var email = this.getFieldValue(fields, 'Email') || '';
        var company = this.getFieldValue(fields, 'Company__c') || '';
        var phone = this.getFieldValue(fields, 'Phone') || '';

        component.set('v.inputFirstName', fn);
        component.set('v.inputLastName', ln);
        component.set('v.inputEmail', email);
        component.set('v.inputPhone', phone);
        component.set('v.inputCompany', company);

        return fn.trim() && ln.trim() && email.trim();
    },

    openAuthScreen: function (component) {
        component.set('v.screen', 'auth');
        this.dispatchEvent('form', 'success', 'AuthEnter');
    },

    openAuthNotFoundScreen: function (component) {
        component.set('v.screen', 'authnf');
        this.dispatchEvent('form', 'success', 'AuthNotFoundEnter');
    },

    openAuthAdditionalInformation: function (component) {
        component.set('v.screen', 'authai');
        this.dispatchEvent('form', 'success', 'AuthAdditionalInfoEnter');
    },

    openGreetingScreen: function (component) {
        component.set('v.screen', 'greeting');
        this.dispatchUserDetailEvent(component, 'initUserData'); // when user authorize - send data to script
        this.dispatchEvent('form', 'success', 'MainMenuEnter');
    },

    openSearchScreen: function (component) {
        component.set('v.screen', 'search');
        this.dispatchEvent('form', 'success', 'SearchEnter');
    },

    normalizeField: function (component) {
        if (!component) {
            return;
        }
        component.set('v.value', (component.get('v.value') || '').trim());
        component.showHelpMessageIfInvalid();
    },

    isFormValid: function (component, helper) {
        return helper.auraValidateForm(component,'inputAuthForm');
    },

    //	get all information about contact:
    //	sales, support, company name, employee number, isFreeRCMeetingCustomer
    searchUsers: function (component, helper) {
        this.request(component, "c.searchContacts", {
            email: component.get("v.inputEmail")
        }).then($A.getCallback(function (response) {
                if (response) {
                    if (response.length === 1) {
                        helper.defineSalesAndSupport(component, response, helper);
                        helper.dispatchEvent('form', 'success', 'LoginCompleteManual');
                        //helper.openGreetingScreen(component);
                    } else {
                        helper.openAuthNotFoundScreen(component);
                        helper.dispatchEvent('form', 'error', 'LoginFailed');
                    }
                }
            })).catch($A.getCallback(function (response) {
                /* Open error screen */
            }));
        },

    //	get all information about contact:
    //	sales, support, company name, employee number, isFreeRCMeetingCustomer take into account page type
        defineSalesAndSupport: function (component, params, helper) {
            this.request(component, "c.defineSalesAndSupportInformation", {
                contacts: params,
                pageType: component.get("v.pageType"),
                supportRouting : component.get("v.supportRouting")
            }).then($A.getCallback(function (response) {
                if (response) {
                    component.set("v.sales", response[0]);
                    component.set("v.support", response[1]);
                    component.set("v.inputCompany", response[2]);
                    component.set("v.inputEmployeeNumber", response[3]);
                    component.set("v.isFreeRCMeetingCustomer", response[4]);

                    helper.openGreetingScreen(component);
                }
            })).catch($A.getCallback(function (response) {
                /* Open error screen */
            }));
        },

        // define support, company name, employee number, isFreeRCMeetingCustomer
        defineSupport: function (component, params, helper) {
            this.request(component, "c.defineSupportInformation", {
                contacts: params,
                supportRouting : component.get("v.supportRouting")
            }).then($A.getCallback(function (response) {
                if (response) {
                    component.set("v.support", response[0]);
                    component.set("v.inputCompany", response[1]);
                    component.set("v.inputEmployeeNumber", response[2]);
                    component.set("v.isFreeRCMeetingCustomer", response[3]);

                    helper.openGreetingScreen(component);	// for GW Support greeting is a coveo search result and button call agent
                }
            })).catch($A.getCallback(function (response) {
                /* Open error screen */
            }));
        },

        getEmployeePicklistValues: function (component) {
            this.request(component, "c.getPicklistValues", {
                objectType: "Contact",
                selectedField: "CompanyEmployeeNumber__c"
            }).then($A.getCallback(function (response) {
                if (response) {
                    component.set("v.employeepkl", response);
                }
            })).catch($A.getCallback(function (response) {
                /* Open error screen */
            }));
        },

    //define Sales By EmployeeNumber take into account page type
    defineSalesByEmployeeNumber: function (component, helper) {
        this.request(component, "c.defineSalesByEmployeeNumber", {
            employeeNumber: component.get("v.inputEmployeeNumber"),
            pageType: component.get("v.pageType")
        }).then($A.getCallback(function (response) {
            if (response) {
                component.set("v.sales", response);
                helper.startChat(component, helper, 'sales');
                helper.dispatchDetailEvent(component, 'click', '', 'Sales');
            }
        })).catch($A.getCallback(function (response) {
            /* Open error screen */
        }));
    },
    
    getKAUrls: function (component) {
        var action = component.get("c.getUrlPathForKA");

        action.setCallback(this, function (response) {
            if (component.isValid() && response !== null && response.getState() == 'SUCCESS') {
                component.set("v.urlWhyRequired", response.getReturnValue().PathForArticleRequireData__c);
                component.set("v.urlHowToUpgrade", response.getReturnValue().PathForArticleHowToUpgrade__c);
            }
        });

        $A.enqueueAction(action);
    },

    /*if user not found - create new*/
	salesLogic: function(component, helper) {
        this.request(component, "c.searchContacts", {
            email: component.get("v.inputEmail")
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    if (response.length === 1) {
                        helper.defineSalesAndCall(component, response, helper);
                    } else {
                        helper.defineSalesByEmployeeNumber(component, helper);
                    }
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    },

    /*if user not found - user should enter another*/
	searchUsersForSales: function(component, helper) {
        this.request(component, "c.searchContacts", {
            email: component.get("v.inputEmail")
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    if (response.length === 1) {
                        helper.defineSalesAndCall(component, response, helper);
                        helper.dispatchEvent('form', 'success', 'LoginCompleteManual');
                    } else {
                        helper.dispatchEvent('form', 'error', 'LoginFailed');
                        helper.openAuthScreen(component);
                    }
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    },

    //	define sales, company name, employee number take into account page type
    defineSalesAndCall: function(component, params, helper) {
        this.request(component, "c.defineSalesInformation", {
            contacts: params,
            pageType: component.get("v.pageType")
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    component.set("v.sales", response[0]);
                    component.set("v.inputCompany", response[1]);
                    component.set("v.inputEmployeeNumber", response[2]);

                   	helper.startChat(component, helper, 'sales');
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    },

    //	if US_Team_All sales agents offline create event 'SalesAgentsOffline'
    isSalesBucketAgentsOnline: function(component, helper) {
        this.request(component, "c.isSalesBucketAgentsOnline", {
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    if(response === 'offline') {
                        helper.dispatchUserDetailEvent(component, 'SalesAgentsOffline');
                    }
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    },

    isEnoughInfoToAuthenticateForSales: function(component, helper) {
        return helper.auraValidateForm(component,'inputSalesForm');
    },

    isEnoughInfoToAuthenticateForSupport: function(component, helper) {
        return helper.auraValidateForm(component,'inputSupportForm');
    },

    validateEmail: function(component){
        var email = component.get('v.inputEmail') || '';
        var re = new RegExp("^\\w+([-+.']\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$");
    	return re.test(email.trim());
    },

    validatePhone: function(component){
        var phone = component.get('v.inputPhone') || '';
        var re = new RegExp("^\\d{3,15}$");
    	return re.test(phone.trim());
    },
    auraValidateForm: function(component, auraid) {
        var validExpense = false;
	    try {
            const cmps = component.find(auraid);
            if(cmps.length)
                validExpense = cmps.reduce(function (validSoFar, inputCmp) {
                        inputCmp.showHelpMessageIfInvalid();
                        return validSoFar && inputCmp.get('v.validity').valid;
                    }, true);
            else
                validExpense = cmps.get('v.validity').valid;
        } catch(e){
	        console.error(e);
        }
        return validExpense;
    },
	searchUsersForSupport: function(component, helper) {
        this.request(component, "c.searchContacts", {
            email: component.get("v.inputEmail")
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    if (response.length === 1) {
                        helper.defineSupport(component, response, helper);
                        helper.dispatchEvent('form', 'success', 'LoginCompleteManual');
                    } else {
                        helper.dispatchEvent('form', 'error', 'LoginFailed');
                        helper.openAuthNotFoundScreen(component);
                    }
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    },

    isEnoughAdditionalInformation: function(component, formName) {
        return this.auraValidateForm(component, formName);
    },

    request: function (component, controller, params) {
        return new Promise(function (resolve, reject) {
            var action = component.get(controller);
            if (params) {
                action.setParams(params);
            }

            action.setCallback(null, function (response) {
                if (response.getState() === 'SUCCESS') {
                    var res = response.getReturnValue();
                    resolve(res);
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        });
    },

    getField: function(fields, name) {
        return fields.find(function(f) {
            return f.name === name;
        });
    },

    getFieldValue: function(fields, name) {
        return (this.getField(fields, name)).value;
    },

    dispatchEvent: function (eType, sType, eName) {
        var evt = new CustomEvent("snap-in", { detail: { type: eType,
                subtype: sType,
                event: { guid: '',
                    name: eName
                }
            }
        });
        document.dispatchEvent(evt);
    },

    dispatchDetailEvent: function (component, eType, sType, eName) {
        var fields = component.get('v.prechatFields');
        var evt = new CustomEvent("snap-in", { detail: { type: eType,
                subtype: sType,
                event: { guid: '',
                    name: eName,
                    user: { firstname: this.getFieldValue(fields, 'FirstName') || '',
                        lastname: this.getFieldValue(fields, 'LastName') || '',
                        email: this.getFieldValue(fields, 'Email') || ''
                    },
                    date: new Date().toLocaleString()
                }
            }
        });
        document.dispatchEvent(evt);
    },
    
    dispatchUserDetailEvent: function (component, eventName) {
        var fn = component.get('v.inputFirstName');
        var ln = component.get('v.inputLastName');
        var email = component.get('v.inputEmail');
        var phone = component.get('v.inputPhone') || ''; 
        var company = component.get('v.inputCompany') || '';
        var employeeNumber = component.get('v.inputEmployeeNumber');

        var event = new CustomEvent(eventName, {
            detail: {
                firstName:              fn,
                lastName:               ln,
                email:                  email,
                phone:                  phone,
                company:                company,
                NumberOfEmployees__c:   employeeNumber
            }
        });
        document.dispatchEvent(event);
    },

    defineRoutingType: function(component) {
        this.request(component, "c.isOmniChannelRoutingEnable", {
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    var chatType = response ? 'omniChannel' : 'liveAgent';
                    component.set("v.liveChatType", chatType);
                }
            })
        ).catch (
            $A.getCallback(function(response) {
                /* Open error screen */
            })
        );
    }  
    
});