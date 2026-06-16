import { LightningElement, api } from "lwc";
import getRecordsToDisplay from "@salesforce/apex/BannerInformationHelper.getRecordsToDisplay";

export default class BannerForOutage extends LightningElement {
  @api displayLocation;
  @api hideNavigation = false;

  bannerDetailsList = [];
  currentIndex = 0;
  shouldShowBanner = false;
  showButtonEventCalled = false;

  // Calculate the translateX percentage for sliding effect
  get carouselWrapperStyle() {
    const offset = -this.currentIndex * 100;
    return `transform: translateX(${offset}%)`;
  }

  //Enable/Disable Next arrow based on the silde index
  get isNextDisabled() {
    return this.currentIndex === this.bannerDetailsList.length - 1;
  }

  //Enable/Disable Previous arrow based on the silde index
  get isPrevDisabled() {
    return this.currentIndex === 0;
  }

  get navigationData() {
    return {
      isFirst: this.currentIndex === 0,
      isLast: this.currentIndex === this.bannerDetailsList.length - 1
    };
  }

  //Initial method to be executed on component load
  connectedCallback() {
    getRecordsToDisplay({ displayLocation: this.displayLocation })
      .then((result) => {
        this.bannerDetailsList = result.map((eventRecord, index) => ({
          ...eventRecord,
          titleClass: this.getTitleStyling(eventRecord.type),
          statusClass: this.getStatusStyling(eventRecord.status),
          dotClass: index === 0 ? "active-circle" : "inactive-circle",
          recordViewed: index === 0 ? true : false
        }));
        this.shouldShowBanner = this.bannerDetailsList.length > 0;
        let showButton = this.bannerDetailsList.length === 1 ? true : false;
        this.sendCaseBannerEvent(showButton);
      })
      .catch((error) => {
        console.error("Error getting data: ", error);
      });
  }

  // Get Styling for Event Title
  getTitleStyling(type) {
    let classList =
      "slds-card__body slds-border_bottom sub-header-style slds-notify_alert";
    if (type === "Incident") {
      classList += " slds-alert_error";
    } else if (type === "Notification") {
      classList += " slds-alert_offline";
    }
    return classList;
  }

  //Get Styling for Event Status
  getStatusStyling(status) {
    let colorClass = "";
    if (status === "Resolved") {
      colorClass = "slds-text-color_success";
    } else if (status === "Ongoing") {
      colorClass = "warning-text-color";
    }
    return colorClass;
  }

  //Sends event to proceed to Case Creation or show Case creation button
  sendCaseBannerEvent(showButton) {
    if (
      !this.showButtonEventCalled &&
      this.displayLocation === "Case Create Page"
    ) {
      const caseBannerEvent = new CustomEvent("manageview", {
        detail: {
          noRecords: this.bannerDetailsList.length === 0,
          showCreateButton: showButton,
          navigationData: this.navigationData
        }
      });
      this.dispatchEvent(caseBannerEvent);
      this.showButtonEventCalled = showButton;
    }
  }

  sendNavigationEvent() {
    const navigationButtonEvent = new CustomEvent("managenavigation", {
      detail: {
        navigationData: this.navigationData
      }
    });
    this.dispatchEvent(navigationButtonEvent);
  }

  // Handle dot/circle click navigation
  handleDotClick(event) {
    const index = parseInt(event.target.getAttribute("data-index"), 10);
    this.handleSlideSelection(index);
    this.sendNavigationEvent();
  }

  // Navigate to the next item in the carousel
  @api hanldeNext() {
    if (this.currentIndex !== this.bannerDetailsList.length - 1) {
      this.handleSlideSelection(this.currentIndex + 1);
    }
    this.sendNavigationEvent();
  }

  // Navigate to the previous item in the carousel
  @api hanldePrevious() {
    if (this.currentIndex !== 0) {
      this.handleSlideSelection(this.currentIndex - 1);
    }
    this.sendNavigationEvent();
  }

  // Hanldes slide selection based on button or dot/circle click
  handleSlideSelection(index) {
    var viewCounter = 0;
    this.currentIndex = index;

    this.bannerDetailsList = this.bannerDetailsList.map(
      (eventRecord, eventIndex) => {
        if (eventRecord.recordViewed) {
          viewCounter = viewCounter + 1;
        }
        if (this.currentIndex === eventIndex) {
          viewCounter = eventRecord.recordViewed
            ? viewCounter
            : viewCounter + 1;
          return {
            ...eventRecord,
            dotClass: "active-circle",
            recordViewed: true
          };
        }
        return {
          ...eventRecord,
          dotClass: "inactive-circle"
        };
      }
    );

    if (viewCounter === this.bannerDetailsList.length) {
      this.sendCaseBannerEvent(true);
    }
  }
}