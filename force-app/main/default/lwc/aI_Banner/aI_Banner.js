import { LightningElement, wire, track } from 'lwc';
import getBannerSettings from '@salesforce/apex/AIBannerController.getBannerSettings';
import aiImage from '@salesforce/resourceUrl/ai_image';
import aiImage2 from '@salesforce/resourceUrl/ai_image2';
import hasSupportAgentPermission from '@salesforce/customPermission/Support_Agent_AI_GCP';

export default class AiBanner extends LightningElement {
    @track bannerData = {};
    @track showBanner = false;
    @track error;
    @track isDismissed = false;

    hasPermission = hasSupportAgentPermission;

    @wire(getBannerSettings)
    wiredBanner(result) {
        if (result.data && this.hasPermission) {
            this.bannerData = result.data;

            //if dismissed in this session.
            const dismissed = sessionStorage.getItem('aiBannerDismissed');
            
            if (!dismissed) {
                this.showBanner = this.shouldShowBanner();
            } else {
                this.showBanner = false;
            }

            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.bannerData = {};
            this.showBanner = false;
        }
    }

    shouldShowBanner() {
        return this.bannerData &&
               this.bannerData.isVisible &&
               this.bannerData.content &&
               this.bannerData.content.trim() !== '' &&
               !this.isDismissed;
    }

    get bannerHeading() {
        return this.bannerData.heading || '';
    }

    get hasHeading() {
        return this.bannerHeading && this.bannerHeading.trim() !== '';
    }

    get bannerContent() {
        return this.bannerData.content || '';
    }

    get hasContent() {
        return this.bannerContent && this.bannerContent.trim() !== '';
    }

    get aiImageUrl() {
        const gifResource = this.bannerData.gifResource;
        
        if (gifResource === 'ai_image2') {
            return aiImage2;
        } else if (gifResource === 'ai_image') {
            return aiImage;
        }
        
        return aiImage;
    }

    get bannerBackgroundStyle() {
        const bgColor = this.bannerData.backgroundColor;
        // Default gradient if no color is specified
        const defaultBackground = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
        const background = bgColor && bgColor.trim() !== '' ? bgColor : defaultBackground;
        return `background: ${background};`;
    }

    handleCloseBanner() {
        this.isDismissed = true;
        this.showBanner = false;

        sessionStorage.setItem('aiBannerDismissed', 'true');
    }
}