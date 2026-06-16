import { LightningElement, track } from "lwc";
import BaseService from "c/lwcBaseService";

const LEARN_MORE_LINK = 'https://go.ringcentral.com/rs/075-DTB-715/images/RINGCENTRAL_PARTNER_TERMS_AND_CONDITIONS.pdf';
const CONSENT_COOKIE = 'Cookie';

export default class LwcCookieConsent extends LightningElement {
    @track isModalOpen;
    terms = LEARN_MORE_LINK;

    connectedCallback() {
        const consentCookie = BaseService.getCookie(CONSENT_COOKIE);
        
        if (!consentCookie) {
            this.openModal();
        }
    }

    openModal() {
        this.isModalOpen = true;
        this.isError = false;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    learnMoreLink() {
        window.open(LEARN_MORE_LINK);
    }

    acceptCookie() {
        document.cookie = CONSENT_COOKIE + "=1; max-age="+60*60*24*30;
        if (document.cookie) {
            this.closeModal();
         } else { 
            alert("Cookie can't be set! Please unblock this site from the cookie setting of your browser.");
        }
    }

    removeCookie() {
        document.cookie = CONSENT_COOKIE + '=; Path=/; SameSite=Strict; Expires=Thu, 01 Jan 1970 00:00:01 GMT;'
    }

    get backdrop() {
        return `slds-backdrop slds-backdrop_open ${this.signUp ? "custom_backdrop" : ""}`;
    }

}