import { LightningElement } from "lwc";

const SEVERITY_ERROR = "error";
const EVENTS_NAME = {
    toast: "ShowToastEvent",
    modal: "ShowModalEvent",
    spinner: "ShowSpinnerEvent",
};

export default class BaseService extends LightningElement {
    /**
     * @method invokeServiceMethod method to call apex controller
     * @param {Object} action
     * @param {Object} parameters
     * @return {Promise} Promise object
     */
    static regexp = {
        email:
            "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
    };
    static invokeServiceMethod(action, parameters) {
        return new Promise((resolve, reject) => {
            const requestStr = JSON.stringify(parameters);
            action({ request: requestStr })
                .then(result => {
                    if (result.status === SEVERITY_ERROR) {
                        reject(result.messages);
                    }
                    const returnValue = result && result.data;
                    resolve(returnValue);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }
    static invokeServiceMethodWithoutParameters(action) {
        return new Promise((resolve, reject) => {
            action()
                .then(result => {
                    if (result.status === SEVERITY_ERROR) {
                        reject(result.messages);
                    }
                    const returnValue = result && result.data;
                    resolve(returnValue);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }
    static pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail,
        });
        target.dispatchEvent(cEvent);
    }
    static showToast(type, title, message) {
        BaseService.pushEvent(
            EVENTS_NAME.toast,
            {
                type,
                title,
                message,
            },
            window
        );
    }
    static errorToast(title, message) {
        BaseService.showToast(
            "error",
            title,
            Array.isArray(message) ? message.map(item => item.message).join("\n") : message.message || message
        );
    }
    static showSpinner(isShown, text = "") {
        BaseService.pushEvent(EVENTS_NAME.spinner, { text, isShown }, window);
    }
    static showModal(title, message, footer, callback, directional) {
        BaseService.pushEvent(
            EVENTS_NAME.modal,
            {
                title,
                message,
                callback,
                footer,
                directional,
            },
            window
        );
    }
    static lightningValidate(selector) {
        return [...selector].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    }
    static getUrlParameter(name) {
        name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        const regex = new RegExp("[\\?&]" + name + "=([^&#]*)");
        const results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
    }
    static setCookie(name, value, days) {
        let expires = "";
        if (days) {
            let date = new Date();
            date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = name + "=" + (value || "") + expires + "; path=/";
    }
    static getCookie(name) {
        var nameEQ = name + "=";
        var ca = document.cookie.split(";");
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) == " ") c = c.substring(1, c.length);
            if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
        }
        return null;
    }
}