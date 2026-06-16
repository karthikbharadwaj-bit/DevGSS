var buttons =
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
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__change_order__ = __webpack_require__(1);
/* harmony reexport (binding) */ __webpack_require__.d(__webpack_exports__, "change_order", function() { return __WEBPACK_IMPORTED_MODULE_0__change_order__["a"]; });



/***/ }),
/* 1 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return change_order; });
/* globals sforce, console, window */
// change_order({
//     orderId: '{!Order.Id}'
// });
const defaultParams = {
  orderId: ''
};

const change_order = ({
  orderId
} = defaultParams) => {
  const executeChangeOrder = () => {
    rcnotify.showSpinner();
    sforce.apex.execute("ApexWebServices", "changeOrder", {
      orderId
    }, {
      onSuccess: result => {
        var response = JSON.parse(result);
        var changeOrderOppId = response.data ? response.data.newOppId : null;

        if (changeOrderOppId) {
          rcnotify.hideSpinner(); // show success toast

          rcnotify.addToast({
            theme: "success",
            header: "Change Order succeeded",
            details: "You should have been forwarded to the created Opportunity. <br>\n                            Please click this link If you weren\u2019t forwarded to the Opportunity:\n                            <a href='/".concat(changeOrderOppId, "'>Link to new Opportunity</a>")
          }); // wait a little bit, then redirect to new Opportunity

          setTimeout(() => {
            window.location.href = "/".concat(changeOrderOppId);
          }, 5000);
        } else if (!changeOrderOppId && response.messages.length > 0) {
          rcnotify.hideSpinner();

          for (let msg of response.messages) {
            rcnotify.addToast({
              theme: msg.severity,
              header: msg.message,
              details: ''
            });
          }
        } else {
          handleError(changeOrderOppId);
        }
      },
      onFailure: handleError
    });
  }; // check order has no phases in 'Pending Approval' status


  const checkPhasesIsPendingApproval = isOrderHasPendingForApprovalPhase => {
    if (isOrderHasPendingForApprovalPhase && isOrderHasPendingForApprovalPhase[0] && isOrderHasPendingForApprovalPhase[0] === 'true') {
      //throw error
      rcnotify.hideSpinner();
      return rcnotify.addToast({
        theme: "error",
        header: "There are Phases pending Approval.",
        details: "You can't proceed with Change Order if there are Phases in Approval Process."
      });
    } else {
      sforce.apex.execute("ApexWebServices", "checkOrderIsCompleted", {
        orderId
      }, {
        onSuccess: checkIsOrderCompleted,
        onFailure: handleError
      });
    }
  };

  const checkIsOrderCompleted = orderIsCompleted => {
    if (orderIsCompleted && orderIsCompleted[0] && orderIsCompleted[0] === 'true') {
      //throw error
      rcnotify.hideSpinner();
      return rcnotify.addToast({
        theme: "error",
        header: "You can not change this Order because it was completed already."
      });
    } else {
      var featureToogle = sforce.apex.execute("ApexWebServices", "getFeatureToogle", {});

      if (featureToogle[0] === 'true' && featureToogle[0]) {
        executeChangeOrder();
      } else {
        enterNamePrompt();
      }
    }
  };

  var promptOptions = {
    header: 'You just activated the Change Order button!',
    content: 'By clicking Confirm, you will be required to generate a new order whether you implement ' + 'any changes or not as you have just CANCELLED the existing order.',
    trueButtonText: 'Submit',
    inputType: 'text',
    inputRequired: true,
    inputLabel: 'Signed Full Name',
    inputPlaceholder: 'Enter your name (no whitespaces at the beginning allowed)',
    inputPattern: '^[^\\s]+.+',
    trueButtonText: 'Confirm',
    falseButtonText: 'Abort'
  };

  const enterNamePrompt = () => {
    rcnotify.hideSpinner();
    rcnotify.openPrompt(promptOptions, value => {
      if (value.trim()) {
        executeChangeOrder();
      } else {
        enterNamePrompt();
      }
    });
  };

  if (orderId.length > 0) {
    sforce.apex.execute("ApexWebServices", "checkPhasesIsPendingApproval", {
      orderId
    }, {
      onSuccess: checkPhasesIsPendingApproval,
      onFailure: handleError
    });
  }
};

const handleError = exception => {
  rcnotify.hideSpinner();
  let errorMsg = exception.message ? exception.message : '';
  errorMsg += exception.faultstring ? exception.faultstring : '';
  console.error(errorMsg);
  errorMsg = errorMsg.split(',')[1].split('.')[0].trim() + '.';
  rcnotify.addToast({
    theme: "error",
    header: "changeOrder webservice process fallen",
    details: errorMsg
  });
};



/***/ })
/******/ ]);