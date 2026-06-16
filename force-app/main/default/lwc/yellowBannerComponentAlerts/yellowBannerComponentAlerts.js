import { LightningElement, api } from 'lwc';

export default class YellowBannerComponentAlerts extends LightningElement {
    @api domainType;
    @api emailTitle;
    @api emailMessage;
    @api isDoNotCall = false;
    @api isHasOptedOutOfEmail = false;
    @api isDoNotSms = false;
    @api isBTApproved = false;
    @api isDoNotDirectMail = false;
    @api showDoNotEmailGermany = false;
    @api isFreeTrialLead = false;

    get noEmail() {
        return this.showDoNotEmailGermany || this.isHasOptedOutOfEmail;
    }

    get showEmailMessage() {
        return !this.isDoNotDirectMail && !this.noEmail && this.emailTitle;
    }
}