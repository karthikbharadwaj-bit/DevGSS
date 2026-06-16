window.buttons =
/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
Object.defineProperty(__webpack_exports__, "__esModule", { value: true });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__sign_up__ = __webpack_require__(1);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1__close__ = __webpack_require__(3);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_2__ngbs_sync_manager__ = __webpack_require__(5);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_3__generate_orders__ = __webpack_require__(7);
/* harmony reexport (binding) */ __webpack_require__.d(__webpack_exports__, "sign_up", function() { return __WEBPACK_IMPORTED_MODULE_0__sign_up__["a"]; });
/* harmony reexport (binding) */ __webpack_require__.d(__webpack_exports__, "close", function() { return __WEBPACK_IMPORTED_MODULE_1__close__["a"]; });
/* harmony reexport (binding) */ __webpack_require__.d(__webpack_exports__, "generate_orders", function() { return __WEBPACK_IMPORTED_MODULE_3__generate_orders__["a"]; });
/* harmony reexport (binding) */ __webpack_require__.d(__webpack_exports__, "NGBS_Sync_Manager", function() { return __WEBPACK_IMPORTED_MODULE_2__ngbs_sync_manager__["a"]; });






/***/ }),
/* 1 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return sign_up; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__common_CONSTANTS__ = __webpack_require__(2);
/**
 * @param signUpParams.opportunityId                {string}  Opportunity.Id
 * @param signUpParams.isBillingOpp                 {boolean} Opportunity.Is_Billing_Opportunity__c
 * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/115277847/Sign+Up
 */

/*
// usage example:
{!REQUIRESCRIPT("/soap/ajax/37.0/connection.js") }
{!REQUIRESCRIPT("/soap/ajax/37.0/apex.js") }
{!REQUIRESCRIPT("/resource/JSPolyfils/JSPolyfils.js") }
{!REQUIRESCRIPT("/resource/rcnotify/rcnotify.js") }
{!REQUIRESCRIPT("/resource/" & LEFT(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(TEXT(NOW()),":",""),"-","")," ",""),10) & "000/OpportunityButtons/buttons.js?16") }
var signUpParams = {
   opportunityId: '{! Opportunity.Id }',
   isBillingOpp: Boolean( {!Opportunity.Is_Billing_Opportunity__c} )
};
buttons.sign_up(signUpParams);
*/


function sign_up(signUpParams) {
  rcnotify.removeAllToasts();
  rcnotify.showSpinner();

  if (signUpParams.isBillingOpp) {
    signUpBilling(signUpParams.opportunityId);
  } else {
    signUpNonBilling(signUpParams.opportunityId);
  }
}

function signUpBilling(billingOppId) {
  sforce.apex.execute("SignUpCustomersBilling", "signUpCustomer", {
    targetId: billingOppId
  }, {
    onSuccess: result => {
      return handleSignUpBilling(result);
    },
    onFailure: error => {
      return handleApexError(error);
    }
  });

  function handleSignUpBilling(result) {
    rcnotify.hideSpinner();

    if (result) {
      result = JSON.parse(result);

      if (result.status === 'error' || result.status === 'warning') {
        rcnotify.addToast({
          theme: result.status,
          header: result.header,
          details: result.message
        });
      }

      if (result.status === 'action required') {
        const promptOptions = {
          trueButtonText: 'Continue',
          header: result.header,
          content: "<p>You have multiple primary quotes under this opportunity. \n                    Please choose one</p>",
          inputLabel: 'Quotes',
          inputType: 'radiobutton',
          values: (result.quotesToSelect || []).map(q => {
            const option = {
              value: q.Id,
              label: "".concat(q.Name)
            };

            if (q.RecordType && q.RecordType.Name === __WEBPACK_IMPORTED_MODULE_0__common_CONSTANTS__["a" /* CONSTANTS */].QUOTE.RT.NAME.BILLING && q.isPrimary__c) {
              option.label += ' (Primary Sales Quote)';
            }

            if (q.RecordType && q.RecordType.Name === __WEBPACK_IMPORTED_MODULE_0__common_CONSTANTS__["a" /* CONSTANTS */].QUOTE.RT.NAME.POC && q.isPrimary__c) {
              option.label += ' (Primary POC Quote)';
              option.checked = true;
            }

            return option;
          })
        };
        rcnotify.openPrompt(promptOptions, v => {
          rcnotify.showSpinner();
          signUpBilling(v);
        });
      }

      if (result.redirectUrl) {
        if (result.status === 'warning') {
          setTimeout(() => {
            window.open(result.redirectUrl, '_blank');
          }, 5000);
        } else {
          window.open(result.redirectUrl, '_blank');
        }
      }
    }
  }
}

function signUpNonBilling(oppId) {
  // prepare params
  const signUpBackendMethodParams = {
    opportunityId: oppId,
    isShowProfessionalServicePrompt: false
  };
  apexWebServicesSignUpProcessWrapper(signUpBackendMethodParams);

  function apexWebServicesSignUpProcessWrapper(signUpParams) {
    apexWebServicesSignUpProcess(signUpParams).then(function (response) {
      rcnotify.hideSpinner();
      handleResponse(response);
    });
  }

  function apexWebServicesSignUpProcess(signUpBackendMethodParams) {
    return new Promise(function (resolve, reject) {
      sforce.apex.execute("ApexWebServices", "validateOnSignUpOpportunity", {
        signUpParams: JSON.stringify(signUpBackendMethodParams)
      }, {
        onSuccess: result => {
          return resolve(JSON.parse(result));
        },
        onFailure: error => {
          return handleApexError(error);
        }
      });
    });
  }

  function handleResponse(response) {
    showMessages(response, 'error');

    if (response.data.redirectUrl) {
      showMessages(response, 'success');
      redirectUser(response.data.redirectUrl);
    } else {
      showPrompts(response).then(function (updatedCloseBackendMethodParams) {
        return apexWebServicesSignUpProcessWrapper(updatedCloseBackendMethodParams);
      });
    }
  }

  function showMessages(response, severity) {
    response.messages.forEach(function (error) {
      if (error.severity === severity) {
        rcnotify.addToast({
          theme: error.severity,
          header: error.message,
          details: error.messageDetails
        });
      }
    });
  }

  function redirectUser(link) {
    window.top.location = link;
  }

  function showPrompts(response) {
    let returnPromise = Promise.resolve();

    if (response.data && response.data.isShowProfessionalServicePrompt === 'true') {
      returnPromise = returnPromise.then(() => professionalServicePrompt(response));
    }

    return returnPromise;
  }

  function professionalServicePrompt(response) {
    return new Promise(function (resolve, reject) {
      var promptOptions = {
        header: 'Sign Up with Professional Services',
        content: 'Hardware won\'t be sent to the funnel because Professional Services will ship the hardware in phases. Please do NOT change the Phones in the Funnel',
        trueButtonText: 'Continue'
      };
      rcnotify.openPrompt(promptOptions, function () {
        signUpBackendMethodParams.isShowProfessionalServicePrompt = true;
        resolve(signUpBackendMethodParams);
      });
    });
  }
}

function handleApexError(apexError) {
  rcnotify.removeAllToasts();
  rcnotify.hideSpinner();
  rcnotify.addToast({
    theme: 'error',
    header: 'Something went wrong.',
    details: "There is an error occurred during the \"Sign Up\" process.\n        Contact your System Administrator if the error persists."
  });
  console.error('SignUp apexError: ', apexError);
}



/***/ }),
/* 2 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
const BRAND_NAME = {
  RC_US: 'RingCentral',
  RC_CA: 'RingCentral Canada',
  RC_AU: 'RingCentral AU',
  RC_UK: 'RingCentral UK',
  RC_EU: 'RingCentral EU',
  AT_T: 'AT&T Office@Hand',
  TELUS: 'TELUS Business Connect',
  BT_BUSINESS: 'BT Business',
  AVAYA: 'Avaya Cloud Office'
};
/* unused harmony export BRAND_NAME */

const DO_NOT_CREATE_QUOTE_FOR = {
  BRANDS: [BRAND_NAME.AT_T, BRAND_NAME.TELUS, BRAND_NAME.BT_BUSINESS],
  SERVICES: ['Professional', 'Fax']
};
/* unused harmony export DO_NOT_CREATE_QUOTE_FOR */

const DO_NOT_CREATE_QUOTE_MESSAGE = "Quote Auto-creation is not supported for ".concat(DO_NOT_CREATE_QUOTE_FOR.BRANDS.join(', '), " Brands and ").concat(DO_NOT_CREATE_QUOTE_FOR.SERVICES.join(', '), " Services");
/* unused harmony export DO_NOT_CREATE_QUOTE_MESSAGE */

const CONSTANTS = {
  OPPORTUNITY: {
    ID_PREFIX: '006',
    // StageName
    STAGE_NAME: {
      QUALIFY: '1. Qualify',
      ORDER: '6. Order',
      CLOSED_WON: '7. Closed Won',
      CLOSED_CHURNED: '8. Closed Churned',
      CLOSED_SAVED: '9. Closed Saved',
      CLOSED_WINBACK: '10. Closed Winback'
    },
    //Brand names
    BRAND_NAME,
    TIER_NAME: {
      OFFICE: 'Office',
      FAX: 'Fax',
      PROFESSIONAL: 'Professional',
      CC: 'Contact Center',
      BT_OFFICE: 'BT Office',
      RC_MEETINGS: 'RC Meetings',
      RC_OFFICE: 'RC Office'
    },

    get NGBS_BRANDS() {
      return [this.BRAND_NAME.RC_US, this.BRAND_NAME.RC_CA];
    },

    // CustomerConfirmation__c
    CUSTOMER_CONFIRMATION: {
      PENDING: 'Pending'
    },
    INVALID_INFO: {
      INVALID_QUOTE: 'This Quote is locked because it doesn\'t reflect current Account Status. You have to create new Quote',
      INVALID_WIZARD: 'This Quote is locked because it doesn\'t reflect current Account Status. ' + 'Account was migrated to New Billing System. Please switch to Quote Tool 2.0 by using toggle in upper left corner.'
    }
  },
  // Quote
  QUOTE: {
    SOBJECT_TYPE: 'Quote',
    ID_PREFIX: '0Q0',
    // RecordType
    RT: {
      DEVELOPER_NAME: {
        CC_PROSERV: 'CC_ProServ_Quote',
        PROSERV: 'ProServ_Quote',
        SALES: 'Sales_Quote',
        BILLING: 'Sales_Quote_v2',
        CONTACT_CENTER: 'Contact_Center_Quote'
      },
      NAME: {
        CC_PROSERV: 'CC ProServ Quote',
        PROSERV: 'ProServ Quote',
        SALES: 'Sales Quote',
        BILLING: 'Sales Quote v2',
        POC: 'POC Quote'
      }
    },
    // ProServ_Status__c
    PROSERV_STATUS: {
      SYNCED: 'Synced',
      CANCELLED: 'Cancelled',
      IN_PROGRESS: 'In progress',
      SOLD: 'Sold',
      CREATED: 'Created',
      OUT_FOR_SIGNATURE: 'Out for Signature'
    },
    // Products__c
    PRODUCTS: {
      CONTACT_CENTER: 'Contact Center',
      RC_CONTACT_CENTER: 'RingCentral Contact Center'
    },
    // Package_Info__c
    PACKAGE_INFO: {
      PRODUCT_NAME: {
        OFFICE: 'Office'
      },
      DURATION: {
        MONTHLY: 'Monthly',
        ANNUAL: 'Annual'
      },
      EDITION: {
        ESSENTIALS: 'Essentials'
      }
    },
    // Upsell_Status__c
    UPSELL_STATUS: {
      UPSELL: {
        VALUE: 'Upsell',
        LABEL: 'Up-Sell'
      },
      UPGRADE: {
        VALUE: 'Upgrade',
        LABEL: 'Upgrade'
      },
      NEW_CUSTOMER: {
        VALUE: 'New',
        LABEL: 'New Customer',
        LABEL_ALTERNATIVE: 'New Business'
      }
    },
    // QuoteType__c
    QUOTE_TYPE: {
      QUOTE: 'Quote',
      AGREEMENT: 'Agreement'
    },
    // Status
    STATUS: {
      DRAFT: 'Draft',
      PRESENTED: 'Presented',
      ACTIVE: 'Active'
    }
  },
  // QuoteLineItem
  QUOTE_LINE_ITEM: {
    SOBJECT_TYPE: 'QuoteLineItem',
    ID_PREFIX: '0QL',
    //Discount_type__c
    DISCOUNT_TYPE: {
      CURRENCY: 'Currency',
      PERCENTAGE: 'Percentage'
    }
  },
  // Pricebook2
  PRICEBOOK2: {
    SOBJECT_TYPE: 'Pricebook2',
    ID_PREFIX: '01s',
    //Service__c
    SERVICE: {
      OFFICE: 'Office',
      MEETINGS: 'Meetings'
    },
    PLAN: {
      ANNUAL: 'Annual',
      MONTHLY: 'Monthly',
      MONTHLY_CONTRACT: 'Monthly - Contract'
    },
    // Edition__c
    EDITION: {
      STANDARD: 'Standard',
      ESSENTIALS: 'Essentials'
    }
  },
  // Product2
  PRODUCT2: {
    ID_PREFIX: '01t',
    // Name
    NAME: {
      // Name contains
      EXTENDED_ENTERPRISE_SUPPORT: 'Extended Enterprise Support',
      SEAT: 'Seat'
    },
    // Family
    FAMILY: {
      MINUTES_BUNDLE: 'Minutes Bundle',
      INBOUND_MINUTES_BUNDLE: 'Inbound Minutes Bundle',
      OUTBOUND_MINUTES_BUNDLE: 'Outbound Minutes Bundle',
      SUPPORT_PACKAGE: 'Support Package',
      TAXES: 'Taxes',
      SITE: 'Site',
      OVERAGE: 'Overage',
      DISCOUNTED_PHONES: 'Discounted Phones',
      CC_SERVICE: 'CC Service',
      PHONES: 'Phones',
      RENTAL_PHONES: 'Rental Phones',
      REFURBISHED_PHONES: 'Refurbished Phones' // Family contains

    },
    // Sub_Category__c
    SUB_CATEGORY: {
      CONTACT_CENTER: 'Contact Center',
      RC_CONTACT_CENTER: 'RingCentral Contact Center'
    },
    // Product_Type__c
    PRODUCT_TYPE: {
      SEAT: 'Seat',
      PORT: 'Port'
    },
    // Charge_Term__c
    CHARGE_TERM: {
      ONE_TIME: 'One - Time',
      ANNUAL: 'Annual',
      MONTHLY: 'Monthly'
    },
    // Feature
    FEATURE: {
      SERVICE_PLAN: 17,
      SERVICE_PLAN_FAX: 28,
      LIMITED_EXTENSION: 12,
      GLOBAL_OFFICE: 47,
      GLOBAL_OFFICE_LIMITED_EXTENSION: 63,
      CC_EXTENDED_ENTERPRISE_SUPPORT: 69,
      EXTENDED_ENTERPRISE_SUPPORT: 70,
      INCONTACT_INTERCONNECT: 65,
      SOFTPHONE: 11,
      ADDITIONAL_LOCAL_NUMBER: 3,
      ADDITIONAL_TOLL_FREE_NUMBER: 2,
      TRUE_800_NUMBER_SETUP: 4,
      VANITY_TOLL_FREE_NUMBER_SETUP: 5
    },
    // Sub_Feature__c
    SUB_FEATURE: {
      SOFTPHONE: -1
    }
  },
  // Hardware_Line_Item__c
  HARDWARE_LINE_ITEM: {
    ID_PREFIX: 'a7v'
  },
  // Asset
  ASSET: {
    SOBJECT_TYPE: 'Asset',
    ID_PREFIX: '02i'
  },
  // Phase__c
  PHASE: {
    API_NAME: 'Phase__c',
    // Status__c
    STATUS: {
      NEW: 'New',
      APPROVED: 'Approved',
      CANCELLED: 'Cancelled',
      PENDING_APPROVAL: 'Pending Approval',
      RECALLED: 'Recalled',
      REJECTED: 'Rejected',
      COMPLETED: 'Completed',
      LOCKED: 'Locked',
      DELETED: 'Deleted'
    },
    // Phase_Type__c
    PHASE_TYPE: {
      API_NAME: 'Phase_Type__c'
    }
  },
  ACCOUNT: {
    PLAN: {
      ANNUAL: 'Annual',
      MONTHLY: 'Monthly',
      MONTHLY_CONTRACT: 'Monthly - Contract'
    }
  },
  // Account Contact Role
  ACCOUNT_CONTACT_ROLE: {
    ROLE: {
      SIGNATORY: 'Signatory'
    }
  },
  // Area_Code__c
  AREA_CODE: {
    // Type__c
    TYPE: {
      LOCAL: 'Local',
      TOLL_FREE: 'Toll-Free'
    }
  },
  BILLING_SYSTEM: {
    NGBS: 'NGBS',
    LEGACY: 'Legacy'
  }
};
/* harmony export (immutable) */ __webpack_exports__["a"] = CONSTANTS;


/***/ }),
/* 3 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return close; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__promptCCPhoneNumbers__ = __webpack_require__(4);
/* globals sforce, console, window */

/**
 * Documentation:
 * https://aquiva.atlassian.net/wiki/spaces/RC/pages/164593680/Close
 *
 * @param closeParams
 * @param closeParams.opportunityId                {string}  Opportunity.Id
 * @param closeParams.opportunityBrandName         {string}  Opportunity.Brand_Name__c
 * @param closeParams.opportunityRecordTypeId      {string}  Opportunity.RecordTypeId
 * @param closeParams.isBillingOpportunity {boolean} Opportunity.Is_Billing_Opportunity__c
 */

function close(closeParams) {
  rcnotify.removeAllToasts();
  rcnotify.showSpinner();
  let closeBackendMethodParams = {
    opportunityId: closeParams.opportunityId
  };
  apexWebServicesCloseProcessWrapper(closeBackendMethodParams);

  function apexWebServicesCloseProcessWrapper(closeParams) {
    apexWebServicesCloseProcess(closeParams).then(function (response) {
      rcnotify.hideSpinner();
      handleResponse(response);
    });
  }

  function apexWebServicesCloseProcess(closeBackendMethodParams) {
    return new Promise(function (resolve, reject) {
      sforce.apex.execute("ApexWebServices", "validateOnCloseOpportunity", {
        closeOpportunityParams: JSON.stringify(closeBackendMethodParams)
      }, {
        onSuccess: validateResultSerialized => {
          return resolve(JSON.parse(validateResultSerialized));
        },
        onFailure: error => {
          return resolve(JSON.parse(error));
        }
      });
    });
  }

  function handleResponse(response) {
    showErrors(response);

    if (response.data.closeWizardURL) {
      redirectUser(response.data.closeWizardURL);
    } else {
      showPrompts(response).then(function (updatedCloseBackendMethodParams) {
        return apexWebServicesCloseProcessWrapper(updatedCloseBackendMethodParams);
      });
    }
  }

  ;

  function showErrors(response) {
    response.messages.forEach(function (error) {
      rcnotify.addToast({
        theme: error.severity,
        header: error.message,
        details: error.messageDetails
      });
    });
  }

  ;

  function redirectUser(link) {
    window.top.location = link;
  }

  ;

  function showPrompts(response) {
    let returnPromise = Promise.resolve();

    if (response.data.isCCPhoneNumbersRequired) {
      returnPromise = returnPromise.then(() => generateOrdersPrompt(response));
    }

    if (response.data.isShowRecallELPrompt) {
      returnPromise = returnPromise.then(() => recallELPrompt(response));
    }

    return returnPromise;
  }

  ;

  function generateOrdersPrompt(response) {
    return new Promise(function (resolve, reject) {
      __WEBPACK_IMPORTED_MODULE_0__promptCCPhoneNumbers__["a" /* open */](response.data.RCAccountNumber, function (rcNumberInput, ccNumberInput) {
        let rcNumber = rcNumberInput || response.data.RCAccountNumber;
        let ccNumber = ccNumberInput || rcNumber;
        closeBackendMethodParams.rcNumber = rcNumber;
        closeBackendMethodParams.ccNumber = ccNumber;
        resolve(closeBackendMethodParams);
      });
    });
  }

  function recallELPrompt(response) {
    return new Promise(function (resolve, reject) {
      var promptOptions = {
        header: 'Recall the Engage Legal Approval?',
        content: 'Please note that Legal Engagement approval is in progress. You must recall the approval to close the opportunity',
        trueButtonText: 'Recall Legal Engagement and Close'
      };
      rcnotify.openPrompt(promptOptions, function () {
        closeBackendMethodParams.approvalId = response.data.approvalId;
        resolve(closeBackendMethodParams);
      });
    });
  }
}



/***/ }),
/* 4 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (immutable) */ __webpack_exports__["a"] = open;
function open(rcNumber, finalCallback) {
  // Form A
  var isPortingNumber = function isPortingNumber() {
    var promptOptions = {
      header: 'Generate Orders',
      content: 'Is the customer porting in a number that will become the RingCentral main number?',
      trueButtonText: 'Yes',
      falseButtonText: 'No'
    };
    var callbackIfNo = rcNumber ? provideCCNumber : provideRCNumber;
    rcnotify.openPrompt(promptOptions, provideRCNumber, callbackIfNo);
  }; // Form B


  var provideRCNumber = function provideRCNumber() {
    var promptOptions = {
      header: 'Generate Orders',
      content: 'Please provide the number that will become the RingCentral main number',
      inputLabel: 'RingCentral main number',
      inputType: 'text',
      inputRequired: true,
      trueButtonText: 'Submit'
    };
    rcnotify.openPrompt(promptOptions, provideCCNumber);
  }; // Form C


  var provideCCNumber = function provideCCNumber(rcNumberInput) {
    var promptContent = '<p>What is the primary call center number for the customer? It will show up as the caller ID for this call center</p>';

    if (rcNumber && !rcNumberInput) {
      promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumber + '</b></p>' + promptContent;
    } else if (rcNumberInput) {
      promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumberInput + '</b></p>' + promptContent;
    }

    var promptOptions = {
      header: 'Generate Orders',
      content: promptContent,
      inputLabel: 'Customer primary call center number',
      inputType: 'text',
      trueButtonText: 'Generate Orders'
    };
    rcnotify.openPrompt(promptOptions, finalCallback.bind(null, rcNumberInput));
  };

  isPortingNumber();
}

/***/ }),
/* 5 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__common_salesforceHelper__ = __webpack_require__(6);
/**
 *
 * @param params
 * @param params.opportunityId        {string}  Opportunity.Id
 * @param params.isBillingOpportunity {boolean} Opportunity.Is_Billing_Opportunity__c
 * @param params.rcnotify {rcnotify}
 * @param params.sforce {sforce}
 */

class NGBS_Sync_Manager {
  constructor(params) {
    if (!params) {
      return;
    }

    this.opportunityId = params.opportunityId;
    this.isBillingOpportunity = params.isBillingOpportunity;
    this.rcnotify = params.rcnotify;
    this.sforce = params.sforce;
  }

  getMessage(value) {
    const pre = 'Please make sure that items were canceled on Service site.';
    const commonText = 'This will cause immediate pricing change on Account in NGBS. Are you sure you want to continue?';
    let result = commonText;

    if (value) {
      result = pre + ' \n\r' + result;
    }

    return result;
  }

  reprice() {
    return __WEBPACK_IMPORTED_MODULE_0__common_salesforceHelper__["a" /* salesforceHelper */].executeApex(this.sforce, 'SyncWithNGBS', 'priceChange', {
      opportunityId: this.opportunityId
    });
  }

  repriceProcess() {
    this.startSync();
    this.reprice().then(res => {
      return JSON.parse(res);
    }).then(res => this.handleResults(res)).catch(ex => this.handleException(ex)).finally(() => this.handleFinally());
  }

  validateSyncWithNgbsPromise(params) {
    return __WEBPACK_IMPORTED_MODULE_0__common_salesforceHelper__["a" /* salesforceHelper */].executeApex(this.sforce, 'SyncWithNGBS', 'validateSyncWithNGBS', params).then(res => JSON.parse(res));
  }

  getSyncNGBSTypePromise() {
    return __WEBPACK_IMPORTED_MODULE_0__common_salesforceHelper__["a" /* salesforceHelper */].executeApex(this.sforce, 'SyncWithNGBS', 'getSyncNGBSType', {}).then(res => res && res[0]);
  }

  processSyncWithNgbs() {
    return this.getSyncNGBSTypePromise().then(val => {
      if (val === 'v1') {
        return this.oldSyncWithNGBS(this.opportunityId);
      } else if (val === 'v2') {
        this.rcnotify.hideSpinner();
        this.openModal(this.opportunityId);
      } else {
        this.rcnotify.hideSpinner();
      }
    });
  }

  openModal(opportunityId) {
    rcnotify.openModal({
      type: 'iframe',
      size: 'large',
      height: '500px',
      header: '',
      url: '/apex/syncWithNGBS?id=' + opportunityId,
      taglines: 'description...'
    });
  }

  sync() {
    
      const errors = this.validate();

      if (errors.length > 0) {
        errors.forEach(error => rcnotify.addToast(error));
	return Promise.reject();
      }

      rcnotify.showSpinner();
      this.validateSyncWithNgbsPromise({
        opportunityId: this.opportunityId
      }).then(res => {
        if (res.length > 0) {
          rcnotify.hideSpinner();
          this.handleResults(res);
        } else {
          return this.processSyncWithNgbs();
        }
      })
   
  }

  validate() {
    const errors = [];

    if (!this.isBillingOpportunity) {
      errors.push({
        theme: 'info',
        header: 'Not Billing Opportunity',
        details: 'You may execute sync with NGBS only for billing opportunities'
      });
    }

    return errors;
  }

  handleException(ex) {
    if (!ex) {
      return;
    }

    this.rcnotify.addToast({
      theme: 'error',
      header: 'Unexpected error occurred',
      details: 'Please contact Administrator'
    });
  }

  handleFinally() {
    this.rcnotify.hideSpinner();
  }

  startSync() {
    this.rcnotify.removeAllToasts();
    this.rcnotify.showSpinner();
  }

  handleResults(rawResults) {
    if (!rawResults) {
      return;
    }

    rawResults.forEach(result => {
      const status = result.status;
      const header = result.header || '';
      const details = result.message || '';

      if (!result.action) {
        this.rcnotify.addToast({
          theme: status,
          header: header,
          details: details
        });
      }
    });
  }

  isShowPopUpWindow(rawResults) {
    if (!rawResults) {
      return;
    }

    let isShowPopUp = rawResults.some(result => {
      return result.status == 'success' && result.action == 'reprice';
    });
    return isShowPopUp;
  }

  oldSyncWithNGBS(opportunityId) {
    return __WEBPACK_IMPORTED_MODULE_0__common_salesforceHelper__["a" /* salesforceHelper */].executeApex(this.sforce, 'SyncWithNGBS', 'syncWithNGBS', {
      opportunityId
    }).then(res => JSON.parse(res)).then(res => {
      this.rcnotify.hideSpinner();
      this.handleResults(res);

      if (this.isShowPopUpWindow(res)) {
        const promptOptions = {
          header: 'Sync with NGBS',
          content: this.getMessage(),
          trueButtonText: 'Continue'
        };
        rcnotify.openPrompt(promptOptions, () => {
          this.repriceProcess();
        });
      }
    });
  }

}
/* harmony export (immutable) */ __webpack_exports__["a"] = NGBS_Sync_Manager;


/***/ }),
/* 6 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return salesforceHelper; });
/**
* @param sforce         {object}    salesforce library to execute apex
* @param className      {string}    name of the class in which call the method to execute apex
* @param methodName     {string}    name of the method in the class
* @param params         {object}        params of the method
*/
function executeApex(sforce, className, methodName, params) {
  return new Promise((resolve, reject) => {
    sforce.apex.execute(className, methodName, params, {
      onSuccess: res => resolve(res),
      onFailure: res => reject(res)
    });
  });	
}

const salesforceHelper = {
  executeApex: executeApex
};


/***/ }),
/* 7 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (immutable) */ __webpack_exports__["a"] = generate_orders;
/**
 * Documentation:
 * https://aquiva.atlassian.net/wiki/spaces/RC/pages/181010433/Order+generation
 *
 * @param generateOrdersParams
 * @param generateOrdersParams.opportunityId        {string}  Opportunity.Id
 * @param generateOrdersParams.isBillingOpportunity {boolean} Opportunity.Is_Billing_Opportunity__c
 */
function generate_orders(generateOrdersParams) {
  return new Promise(resolve => {
    rcnotify.removeAllToasts();
    rcnotify.showSpinner(); //Get Opportunity id

    var opId = generateOrdersParams.opportunityId;
    var rcNumber;
    var rcNumberInput = null;
    var ccNumberInput = null;
    var messages = []; //Call proccessData method by passing that Opportunity id

    var populateAndGenerateOrders = function populateAndGenerateOrders(ccNumber) {
      //If "What is the primary call center number for the customer? It will show up as the caller ID for this call center" was NOT empty on form C,
      //set Contact_Center_Number__c of the Order with "Contact Center" Record Type to value entered in "What is the primary call center number for the customer? It will show up as the caller ID for this call center" field.
      //If "What is the primary call center number for the customer? It will show up as the caller ID for this call center" was empty on form C,
      //set Contact_Center_Number__c of the Order with "Contact Center" Record Type to Account.RC_Account_Number__c.
      //Set RingCentral_Account_Number__c of the Order with "Contact Center" Record Type to value from first Label on form C:
      //<Number entered on Form B> or <Account.RC_Account_Number__c> depending on how the questions were answered on previous from.
      rcNumberInput = rcNumberInput ? rcNumberInput : rcNumber;
      ccNumberInput = ccNumber ? ccNumber : rcNumberInput;
      rcnotify.showSpinner();

      if (generateOrdersParams.isBillingOpportunity) {
        processDataNewBilling();
      } else {
        processData();
      }
    }; // Form B


    var provideRCNumber = function provideRCNumber(headerMessage) {
      var promptOptions = {
        header: 'Generate Orders',
        content: 'Please provide the number that will become the RingCentral main number',
        inputLabel: 'RingCentral main number',
        inputType: 'text',
        inputRequired: true,
        trueButtonText: 'Submit'
      };
      rcnotify.openPrompt(promptOptions, provideCCNumber);
    }; // Form C


    var provideCCNumber = function provideCCNumber(result) {
      if (result !== null) {
        rcNumberInput = result;
      }

      var promptContent = '<p>What is the primary call center number for the customer? It will show up as the caller ID for this call center</p>';

      if (rcNumber && typeof rcNumberInput !== 'string') {
        promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumber + '</b></p>' + promptContent;
      } else if (typeof rcNumberInput === 'string') {
        promptContent = '<p>Main number on the RingCentral account: <b>' + rcNumberInput + '</b></p>' + promptContent;
      }

      var promptOptions = {
        header: 'Generate Orders',
        content: promptContent,
        inputLabel: 'Customer primary call center number',
        inputType: 'text',
        trueButtonText: 'Generate Orders'
      };
      rcnotify.openPrompt(promptOptions, populateAndGenerateOrders);
    }; // try to generate orders and show form A if required


    function processData() {
      var processDataOptions = {
        oppId: opId,
        rcNumber: null,
        ccNumber: null
      }; // add parameters if needed for Contact Center orders

      if (rcNumberInput) {
        processDataOptions.rcNumber = rcNumberInput;
      }

      if (ccNumberInput) {
        processDataOptions.ccNumber = ccNumberInput;
      }

      sforce.apex.execute("GenerateOrders", "processData", processDataOptions, {
        onSuccess: function onSuccess(rawResult) {
          rcnotify.hideSpinner();
          var result = JSON.parse(rawResult[0]);
          var options = {};

          switch (result.status) {
            case 'success':
              ;
              options.details = 'The page will be reloaded';
              location.reload();

            case 'error':
            case 'info':
              options.theme = result.status;

              if (result.hasOwnProperty('details')) {
                options.header = result.message;
                options.details = result.details;
              } else {
                options.header = result.message;
                options.details = result.message;
              }

              if (result.message === 'Orders are already generated for this Opportunity') {
                options.details = 'You can find them in the <a href=#' + opId + '_RelatedOrderList>related list below</a>';
              }

              addMessage(options);
              showMessages();
              break;

            case 'action required':
              askForRCandCCNumbers(result);
              break;

            default:
              // proccessData
              break;
          }

          resolve();
        },
        onFailure: function onFailure(error) {
          rcnotify.hideSpinner();
          var options = {
            theme: 'error',
            header: 'Generate Orders webservice call failed',
            details: error
          };
          addMessage(options);
          showMessages();
          resolve();
        }
      });
    }

    function processDataNewBilling() {
      /* Request to create/update contract */
      var processDataOptions = {
        oppId: opId,
        rcNumber: rcNumberInput,
        ccNumber: ccNumberInput
      };

      try {
        var result = sforce.apex.execute("GenerateOrders", "processData", processDataOptions);

        if (result) {
          result = JSON.parse(result);

          if (result.status == 'action required') {
            askForRCandCCNumbers(result);
          } else {
            addMessageResult(result);
          }
        }
      } catch (e) {
        addMessage({
          theme: 'error',
          header: 'An error has occurred processing request to webservices',
          details: 'Please contact administrator'
        });
      } finally {
        showMessages();
        resolve();
      }
    }

    function askForRCandCCNumbers(result) {
      rcNumber = result['Account.RC_Account_Number__c'];
      var options = {
        header: 'Generate Orders',
        content: 'Is the customer porting in a number that will become the RingCentral main number?',
        trueButtonText: 'Yes',
        falseButtonText: 'No'
      };
      var callbackIfNo = rcNumber ? provideCCNumber : provideRCNumber;
      rcnotify.openPrompt(options, provideRCNumber, callbackIfNo);
    }

    function addMessage(result) {
      if (!result || !result.details) {
        return;
      }

      var isMessageAlreadyExists = messages.length !== 0 && messages.find(message => message.details === result.details);

      if (isMessageAlreadyExists) {
        return;
      }

      messages.push({
        theme: result.theme,
        header: result.header,
        details: result.details
      });
    }

    function addMessageResult(result) {
      if (!result) {
        return;
      }

      addMessage({
        theme: result.status,
        header: result.header ? result.header : result.message,
        details: result.message ? result.message : ""
      });
    }

    function showMessages() {
      messages.forEach(message => rcnotify.addToast(message));
      rcnotify.hideSpinner();
    }

    if (generateOrdersParams.isBillingOpportunity) {
      processDataNewBilling();
    } else {
      // start Generate Orders
      processData();
    }
  });
}

/***/ })
/******/ ]);