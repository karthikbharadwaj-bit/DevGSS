import { LightningElement, track, api } from "lwc";
import createDealQuoteInfoRecord from "@salesforce/apex/DealQuoteInfoController.createDealQuoteInfoRecord";
import initDealQuoteInfo from "@salesforce/apex/DealQuoteInfoController.initDealQuoteInfo";
import getDealQuotingInfoById from "@salesforce/apex/DealQuoteInfoController.getDealQuotingInfoById";
import getQuoteInfoById from "@salesforce/apex/DealQuoteInfoController.getQuoteInfoById";
import refreshValueFromQuote from "@salesforce/apex/DealQuoteInfoController.refreshValueFromQuote";
import acceptRecommendation from "@salesforce/apex/DealQuoteInfoController.acceptRecommendation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class DealQuotingToolCmp extends LightningElement {
  @api
  recordId;
  @api
  objectName;
  @api
  get isLightning() {
	  return this._isLightning;
  }

  set isLightning(value) {
	  if (value) {
		  this._isLightning = value;
	  }
  }
  _isLightning = true;

  FALSE_CONST = false;
  isFromOpportunity = false;
  dealCharactersticTitle = "Deal Characteristic/ Quote input";
  targetPriceForDLTitle = "Target Price for DLs";
  listPriceTitle = "List Price";
  targetPriceTitle = "Target Price";
  finalPriceDiscrationTitle = "Discretion & required approval";
  finalDiscountForULTitle = "Final discount for Unlimited DLs & Approval Required";
  discrationForULTitile = "Discretion for Unlimited DLs";
  tierOptions = [
    {
      label: "Essentials",
      value: "Essentials"
    },
    {
      label: "Standard",
      value: "Standard"
    },
    {
      label: "Premium",
      value: "Premium"
    },
    {
      label: "Ultimate",
      value: "Ultimate"
    }
  ];
  get yearOptions() {
    let yearOption = [];
    for (let i = 0; i < 10; i++) {
      yearOption.push({
        label: i + "",
        value: i + ""
      });
    }
    yearOption.push({
      label: "10+",
      value: "10+"
    });
    return yearOption;
  }
  get planOptions() {
    let planOption = [
      {
        label: "Monthly",
        value: "Monthly"
      },
      {
        label: "Annual",
        value: "Annual"
      }
    ];
    return planOption;
  }
  get sectorOptions() {
    return [
      {
        label: "Public Sector",
        value: "Public Sector"
      },
      {
        label: "Education",
        value: "Education"
      },
      {
        label: "Non-Profit",
        value: "Non-Profit"
      },
      {
        label: "All other sectors",
        value: "All other sectors"
      }
    ];
  }
  get termOptions() {
    return [
      {
        label: "No",
        value: "No"
      },
      {
        label: "Yes",
        value: "Yes"
      }
    ];
  }
  get featureOptions() {
    return [
      {
        label: "All",
        value: "All"
      },
      {
        label: "Phone Only",
        value: "Phone Only"
      }
    ];
  }

  renderedCallback() {
    const container = this.template.querySelector(".container");
    const style = document.createElement("style");
    style.innerText = `
			.slds-card__header.slds-grid {
				margin: 0!important;
				padding: 0!important;
			}
			.slds-text-align_center.custom-center-align div input {
				text-align: center!important;
			}
			.required-approval div input {
				background: #f804043b!important;
			}

			.no-approval div input {
				background: #04844b40!important;
			}
		`;
    container.appendChild(style);
  }

  get approvalClassCss() {
    const approvalStatus = this.dealQuoteInfo.Approval_Different_from_GoA__c;
    let cssCls = "";
    if (approvalStatus.indexOf("Yes") !== -1) {
      cssCls = "required-approval";
    } else if (approvalStatus.indexOf("No") !== -1) {
      cssCls = "no-approval";
    }
    return cssCls;
  }

  @track dealQuoteInfo = {
    Approval_Different_from_GoA__c: "",
    Approval_Needed_for_Unlimited_DLs__c: "",
    Contract_Length_Years__c: "",
    Deal_discretion_for_Unlimited_DLs__c: 0,
    Deal_discretion_for_Unlimited_DLs_Per__c: 0,
    Discretion_vs_target_price__c: 0,
    Features__c: "",
    Final_discount_vs_list__c: 0,
    Final_discount_vs_list_percent__c: 0,
    Final_quote_price_for_Limited_Extensions__c: 0,
    Final_quote_price_for_Unlimited_DLs__c: 0,
    Final_quote_price_per_Limited_Extension__c: 0,
    Final_quote_price_per_Unlimited_DL__c: 0,
    Free_Months_Given__c: 0,
    Monthly_total_for_all_other_recurring_ch__c: 0,
    Monthly_total_for_Contact_Center__c: 0,
    Monthly_total_for_phone_rentals__c: 0,
    Monthly_total_for_ProServ_Enterprise__c: 0,
    Number_of_Limited_Exts__c: 0,
    Number_of_Unlimited_DLs__c: 0,
    Opportunity__c: "",
    Payment_Plan__c: "",
    Per_Limited_Extension_advertised__c: 0,
    Per_Unlimited_DL_advertised__c: 0,
    Potential_to_sell_contact_center_in_near__c: '',
    Quote__c: "",
    Sales_Agreement__c: "",
    Recommended_Discount_vs_list__c: 0,
    Recommended_Limited_Extensions_price_aft__c: 0,
    Recommended_price_per_Limited_Extension__c: 0,
    Recommended_price_per_Unlimited_DL_after__c: 0,
    Recommended_Unlimited_DLs_price_after_di__c: 0,
    Sector__c: "",
    Tier__c: "",
    Total_for_Limited_Extensions_advertised__c: 0,
    Total_for_Unlimited_DLs_advertised__c: 0,
    Total_Number_of_Employees__c: 0,
    Undiscounted_Unit_Price_for_Limited_Exts__c: 0,
    Undiscounted_Unit_Price_for_additional_l__c: 0,
    Number_of_additional_local_number_incl__c: 0.0 
  };
  @track roundOffCalculatorPercentage = {
    orderSizeACVDiscount: 0,
    potentialMaximumDiscount: 0,
    potentialMaximumDiscountGivenDeal: 0,
    contractLengthDiscount: 0,
    paymentPlanDiscount: 0,
    totalDiscount: 0
  };
  dealQuoteInfoBasePrice = [];
  dealQuoteInfoBListPrice = [];
  dealQuoteInfoContactCenterPotential = [];
  dealQuoteInfoFreeMonthDiscount = [];
  dealQuoteInfoFeeAndE991 = [];
  dealQuoteInfoInitialTerm = [];
  dealQuoteInfoIntercept = [];
  dealQuoteInfoLogAcv = [];
  dealQuoteInfoOrderYear = [];
  dealQuoteInfoPaymentPlan = [];
  dealQuoteInfoPotentialSeat = [];
  dealQuoteInfoSector = [];
  dealQuoteInfoFeature = [];
  @track error;
  @track selectedOpportunity;
  @track selectedQuote;
  @track selectedBaseListPrice = [];
  @track listPrice = {
    dlBucket: 0,
    paymentPlan: "",
    perDLAdvertised: 0,
    totalAdvertised: 0
  };
  @track basePriceFullyUndiscounted = {
    perDl: 0,
    total: 0
  };
  @track targetPriceCalculation = {
    suggestedDiscountVsBasePrice: 0,
    discountRecommendation: 0,
    isDlBucket1Line: false,
    isDiscountedPriceRecoHigherThanListPrice: false,
    targetPrice: 0,
    recommendedPerDiscountVsList: 0,
    isRecommenedPerDiscountVsListAbove60: false,
    finalTargetPriceReco: 0,
    finalRecommendedPerDiscountVsList: 0
  };
  @track totalDiscountCalculation = {
    officeMRR: 0,
    numberOfLimitedExts: 0,
    unDiscountedUnitPriceForLimitedExts: 0,
    limitedExtMrr: 0,
    numberOfAdditionalLocalNumber: 0,
    undiscountedUnitPriceForAdditionalLocalNumber: 0,
    basicLineMrr: 0,
    totalLines: 0,
    feesAndE911: 0,
    monthlyTotalForProservEnterprises: 0,
    montlyTotalForContactCenter: 0,
    monthlyTotalForPhoneRentals: 0,
    monthlyTotalForAllOtherRecurringCharges: 0,
    totalDealMrr: 0,
    totalDealACV: 0,
    discountGivenDealSize: 0
  };
  @track contactCenterMrrPotential = {
    potentialToSellContactCenterInNearTerm: "",
    potentialContactCenterMRR: 0
  };
  @track officeMrrPotential = {
    tierName: "",
    tierPrice: 0,
    totalNumberOfEmployees: 0,
    potentialOfficeMrr: 0,
    numberOfLimitedExts: 0,
    undiscountedUnitPriceForLimitedExts: 0,
    limitedExtsMrr: 0,
    totalLines: 0,
    feesAndE911: 0,
    numberOfAdditionalLocalNumber: 0,
    undiscountedUnitPriceForAdditionalLocalNumber: 0,
    basicLineMrr: 0,
    monthlyTotalForProservEnterprises: 0,
    monthlyTotalForContactCenter: 0,
    monthlyTotalPhoneRentals: 0,
    monthlyTotalForAllOtherRecurringCharge: 0,
    potentialTotalMrr: 0,
    PotentialAcv: 0,
    maxDiscountGivenDealRelationshipPotential: 0,
    discountGivenDealSize: 0,
    maxDiscountGivenPotential: 0,
    discountGivenDeal: 0,
    relationshipPotential: 0
  };
  @track dealTermDiscount = {
    contractLengthDiscount: 0,
    paymentPlanDiscount: 0
  };
  @track otherDiscount = {
    freeMonthAdjustment: 0,
    sectorAdjustment: 0,
    Features: 0
  };
  @track totalDiscount = 0;
  connectedCallback() {
    this.dealQuoteInfoSystemDataLoad();
  }
  dealQuoteInfoSystemDataLoad() {
    initDealQuoteInfo()
      .then((result) => {
        this.dealQuoteInfoBasePrice = result.listOfDealQuoteBasePrice;
        this.dealQuoteInfoBListPrice = result.listOfDealQuoteListPrice;
        this.dealQuoteInfoContactCenterPotential = result.listOfDealQuoteContactCenterPotential;
        this.dealQuoteInfoFreeMonthDiscount = result.listOfDealQuoteFreeMonthDiscount;
        this.dealQuoteInfoFeeAndE991 = result.listOfDealQuoteFeeAndE991;
        this.dealQuoteInfoInitialTerm = result.listOfDealQuoteInitialTerm;
        this.dealQuoteInfoIntercept = result.listOfDealQuoteIntercept;
        this.dealQuoteInfoLogAcv = result.listOfDealQuoteLogAcv;
        this.dealQuoteInfoOrderYear = result.listOfDealQuoteOrderYear;
        this.dealQuoteInfoPaymentPlan = result.listOfDealQuotePaymentPlan;
        this.dealQuoteInfoPotentialSeat = result.listOfDealQuotePotentialSeat;
        this.dealQuoteInfoSector = result.listOfDealQuoteSector;
        this.dealQuoteInfoFeature = result.listOfDealQuoteFeature;
        if (this.recordId && this.recordId !== "") {
          this.dealQuoteInfoRecordLoad(this.recordId);
        }
      })
      .catch((error) => {
        this.error = error;
      });
  }
  dealQuoteInfoRecordLoad(recordId) {
    const current = this;
    getDealQuotingInfoById({
      dealQuoteInfoId: recordId
    })
      .then((result) => {
        if (result.dealQuoteInfo) {
          current.dealQuoteInfo = { ...result.dealQuoteInfo };
          if (result.dealQuoteInfo.Opportunity__r) {
            current.selectedOpportunity = result.dealQuoteInfo.Opportunity__r.Name;
          }
          if (result.dealQuoteInfo.Sales_Agreement__r) {
            current.selectedQuote = result.dealQuoteInfo.Sales_Agreement__r.Name;
          }
        }
        if (result.salesAgreementInformation) {
          current.selectedOpportunity = result.salesAgreementInformation.Opportunity.Name;
          current.selectedQuote = result.salesAgreementInformation.Name;
          current.isFromOpportunity = true;
        }
        current.recalculateCalculation();
      })
      .catch((error) => {
        this.error = error;
      });
  }
  inputChangeEvent(event) {
    const id = event.target.dataset.id,
      current = this;
    current.dealQuoteInfo[id] = event.target.value;
    if (id === "Tier__c") {
      current.updateListPrice(event.target.value);
    }
    if (id === "Payment_Plan__c") {
      current.updatePaymentPlan(event.target.value);
    }
    if (id === "Payment_Plan__c") {
      // current.updateContractLength(event.target.value);
    }
    if (id === "Contract_Length_Years__c") {
      current.updateContractLength(event.target.value);
    }
    current.applyCalculationRule();
  }


  saveDealQuoteInfo() {
    const current = this,
      dealQuoteInfo = { ...current.dealQuoteInfo };
    console.log("Deal Quote Info", dealQuoteInfo);

	let dealQuoteInfoParam = {};
	for (const [key, value] of Object.entries(dealQuoteInfo)) {
		 if (typeof value === 'string') {
			if (value === "NaN") {
				dealQuoteInfoParam[key] =  0.0;
			} else {
				dealQuoteInfoParam[key] =  value;
			}
			
		 } else if (typeof value === 'number') {
			dealQuoteInfoParam[key] = isNaN(value) ? 0 : value;
		 }
 		 
	};

    if (dealQuoteInfoParam.Sales_Agreement__r) {
      delete dealQuoteInfoParam.Sales_Agreement__r;
    }
    if (dealQuoteInfoParam.Opportunity__r) {
      delete dealQuoteInfoParam.Opportunity__r;
    }
    createDealQuoteInfoRecord({
      dealQuotingInfo: JSON.stringify(dealQuoteInfoParam)
    })
      .then((result) => {
        current.showToast("Deal Quoting Info", "Record is saved successfully!");
        if (current.isFromOpportunity) {
          current.closeQuickAction();
        }
        console.log("result", result);
      })
      .catch((error) => {
        console.log("error", error);
        current.showToast("Deal Quoting Info", error.message);
      });
  }
  recalculateCalculation() {
    const current = this,
      dealQuoteInfo = { ...current.dealQuoteInfo };
    current.updateListPrice(dealQuoteInfo.Tier__c);
    current.updatePaymentPlan(dealQuoteInfo.Payment_Plan__c);
    current.updateContractLength(dealQuoteInfo.Contract_Length_Years__c);
    current.updateFinalQuotePricePerUnlimited(dealQuoteInfo.Final_quote_price_per_Unlimited_DL__c);
    current.applyCalculationRule();
  }
  applyCalculationRule() {
    const current = this,
      dealQuoteInfo = { ...current.dealQuoteInfo };
    current.updateFinalQuotePricePerUnlimited(dealQuoteInfo.Final_quote_price_per_Unlimited_DL__c);
    current.calculateTotalDiscountCalculation();
    current.calculatePotentialDiscount();
    current.calculateOfficeMrrPotential();
    current.calculateDealTermDiscount();
    current.calculateOtherDiscount();
    current.calculateTotalDiscount();
    current.calculateTargetPriceCalculation();
    current.calculateFinalPrice();
  }
  updateListPrice(value) {
    const current = this,
      tierComponent = current.template.querySelector(`[data-id="Tier__c"]`),
      tier_value = value ? value : tierComponent.value,
      applicableBasePrice = current.dealQuoteInfoBListPrice.filter(function (eachListPrice) {
        const developerName = eachListPrice.Base_Price_Deal__r.DeveloperName;
        if (developerName.toLowerCase() === `q2${tier_value.toLowerCase()}`) {
          return eachListPrice;
        }
      }),
      unlimitedDls = current.dealQuoteInfo.Number_of_Unlimited_DLs__c ? current.dealQuoteInfo.Number_of_Unlimited_DLs__c : 1;
    current.selectedBaseListPrice = applicableBasePrice;
    const applicableBaseListPrice = current.selectedBaseListPrice.filter(function (eachList) {
      if (unlimitedDls >= eachList.Lower_Band__c && unlimitedDls <= eachList.Upper_Band__c) {
        return eachList;
      }
    });
    const paymentPlan = current.dealQuoteInfo.Payment_Plan__c,
      contractLength = current.dealQuoteInfo.Contract_Length_Years__c;
    //console.log(JSON.stringify(applicableBaseListPrice), 'applicableBaseListPrice');
    if (applicableBaseListPrice && applicableBaseListPrice.length > 0) {
      current.listPrice.dlBucket = applicableBaseListPrice[0].Lower_Band__c + "-" + applicableBaseListPrice[0].Upper_Band__c;
      if (
        paymentPlan &&
        paymentPlan.trim().length > 0 &&
        paymentPlan === "Monthly" &&
        contractLength &&
        contractLength.trim().length > 0 &&
        contractLength === "0"
      ) {
        current.listPrice.paymentPlan = "Monthly";
      } else if (paymentPlan && paymentPlan.trim().length > 0 && paymentPlan === "Monthly") {
        current.listPrice.paymentPlan = "Monthly With Contract";
      } else {
        current.listPrice.paymentPlan = "Annual";
        current.dealQuoteInfo.Payment_Plan__c = "Annual";
      }
      if (current.listPrice.paymentPlan === "Annual") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Annual__c;
      } else if (current.listPrice.paymentPlan === "Monthly With Contract") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly_With_Contract__c;
      } else if (current.listPrice.paymentPlan === "Monthly") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly__c;
      }
      current.listPrice.totalAdvertised = (unlimitedDls * current.listPrice.perDLAdvertised).toFixed(4);
      current.basePriceFullyUndiscounted.perDl = applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c;
      current.basePriceFullyUndiscounted.total = (applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c * unlimitedDls).toFixed(
        4
      );
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = current.listPrice.perDLAdvertised;
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = current.listPrice.totalAdvertised;
    } else {
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = "Please check tier and DL bucket combination.";
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = "Please check tier and DL bucket combination.";
    }
    current.applyCalculationRule();
  }
  updateTotalUnlimitedDL(event) {
    const current = this,
      unlimitedDls = event.target.value;
    const applicableBaseListPrice = current.selectedBaseListPrice.filter(function (eachList) {
      if (unlimitedDls >= eachList.Lower_Band__c && unlimitedDls <= (eachList.Upper_Band__c || 9999999)) {
        return eachList;
      }
    });
    let paymentPlan = current.dealQuoteInfo.Payment_Plan__c,
      contractLength = current.dealQuoteInfo.Contract_Length_Years__c;
    contractLength = contractLength && contractLength.trim().length > 0 ? contractLength : "0";
    current.dealQuoteInfo.Contract_Length_Years__c = contractLength;
    //console.log(JSON.stringify(applicableBaseListPrice), 'applicableBaseListPrice');
    if (applicableBaseListPrice && applicableBaseListPrice.length > 0) {
      current.listPrice.dlBucket =
        applicableBaseListPrice[0].Lower_Band__c +
        (applicableBaseListPrice[0].Upper_Band__c ? "-" + applicableBaseListPrice[0].Upper_Band__c : "+");
      if (
        paymentPlan &&
        paymentPlan.trim().length > 0 &&
        paymentPlan === "Monthly" &&
        contractLength &&
        contractLength.trim().length > 0 &&
        contractLength === "0"
      ) {
        current.listPrice.paymentPlan = "Monthly";
      } else if (paymentPlan && paymentPlan.trim().length > 0 && paymentPlan === "Monthly") {
        current.listPrice.paymentPlan = "Monthly With Contract";
      } else {
        current.listPrice.paymentPlan = "Annual";
        current.dealQuoteInfo.Payment_Plan__c = "Annual";
      }
      if (current.listPrice.paymentPlan === "Annual") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Annual__c;
      } else if (current.listPrice.paymentPlan === "Monthly With Contract") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly_With_Contract__c;
      } else if (current.listPrice.paymentPlan === "Monthly") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly__c;
      }
      current.listPrice.totalAdvertised = (unlimitedDls * current.listPrice.perDLAdvertised).toFixed(4);
      current.basePriceFullyUndiscounted.perDl = applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c;
      current.basePriceFullyUndiscounted.total = (applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c * unlimitedDls).toFixed(
        4
      );
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = current.listPrice.perDLAdvertised;
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = current.listPrice.totalAdvertised;
    } else {
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = "Please check tier and DL bucket combination.";
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = "Please check tier and DL bucket combination.";
    }
    current.applyCalculationRule();
  }
  updatePaymentPlan(value) {
    const current = this,
      unlimitedDls = current.dealQuoteInfo.Number_of_Unlimited_DLs__c;
    const applicableBaseListPrice = current.selectedBaseListPrice.filter(function (eachList) {
      if (unlimitedDls >= eachList.Lower_Band__c && unlimitedDls <= eachList.Upper_Band__c) {
        return eachList;
      }
    });
    let paymentPlan = value,
      contractLength = current.dealQuoteInfo.Contract_Length_Years__c;
    contractLength = contractLength.trim().length > 0 ? contractLength : "0";
    current.dealQuoteInfo.Contract_Length_Years__c = contractLength;
    // console.log(JSON.stringify(applicableBaseListPrice), 'applicableBaseListPrice');
    if (applicableBaseListPrice && applicableBaseListPrice.length > 0) {
      current.listPrice.dlBucket = applicableBaseListPrice[0].Lower_Band__c + "-" + applicableBaseListPrice[0].Upper_Band__c;
      if (
        paymentPlan &&
        paymentPlan.trim().length > 0 &&
        paymentPlan === "Monthly" &&
        contractLength &&
        contractLength.trim().length > 0 &&
        contractLength === "0"
      ) {
        current.listPrice.paymentPlan = "Monthly";
      } else if (paymentPlan && paymentPlan.trim().length > 0 && paymentPlan === "Monthly") {
        current.listPrice.paymentPlan = "Monthly With Contract";
      } else {
        current.listPrice.paymentPlan = "Annual";
        current.dealQuoteInfo.Payment_Plan__c = "Annual";
      }
      if (current.listPrice.paymentPlan === "Annual") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Annual__c;
      } else if (current.listPrice.paymentPlan === "Monthly With Contract") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly_With_Contract__c;
      } else if (current.listPrice.paymentPlan === "Monthly") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly__c;
      }
      current.listPrice.totalAdvertised = (unlimitedDls * current.listPrice.perDLAdvertised).toFixed(4);
      current.basePriceFullyUndiscounted.perDl = applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c;
      current.basePriceFullyUndiscounted.total = (applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c * unlimitedDls).toFixed(
        4
      );
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = current.listPrice.perDLAdvertised;
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = current.listPrice.totalAdvertised;
    } else {
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = "Please check tier and DL bucket combination.";
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = "Please check tier and DL bucket combination.";
    }
    current.applyCalculationRule();
  }
  calculateTotalDiscountCalculation() {
    const current = this,
      perDLCost = current.basePriceFullyUndiscounted.perDl,
      unlimtedDls = current.dealQuoteInfo.Number_of_Unlimited_DLs__c;
    current.totalDiscountCalculation.officeMRR = (perDLCost * unlimtedDls).toFixed(4);
    current.totalDiscountCalculation.numberOfLimitedExts = current.dealQuoteInfo.Number_of_Limited_Exts__c;
    current.totalDiscountCalculation.unDiscountedUnitPriceForLimitedExts = current.dealQuoteInfo
      .Undiscounted_Unit_Price_for_Limited_Exts__c
      ? current.dealQuoteInfo.Undiscounted_Unit_Price_for_Limited_Exts__c
      : 0;
    current.totalDiscountCalculation.limitedExtMrr = (
      current.totalDiscountCalculation.numberOfLimitedExts * current.totalDiscountCalculation.unDiscountedUnitPriceForLimitedExts
    ).toFixed(4);
    current.totalDiscountCalculation.numberOfAdditionalLocalNumber = current.dealQuoteInfo
      .Number_of_additional_local_number_incl__c
      ? current.dealQuoteInfo.Number_of_additional_local_number_incl__c
      : 0;
    current.totalDiscountCalculation.undiscountedUnitPriceForAdditionalLocalNumber = current.dealQuoteInfo
      .Undiscounted_Unit_Price_for_additional_l__c
      ? current.dealQuoteInfo.Undiscounted_Unit_Price_for_additional_l__c
      : 0;
    current.totalDiscountCalculation.basicLineMrr =
      current.totalDiscountCalculation.numberOfAdditionalLocalNumber *
      current.totalDiscountCalculation.undiscountedUnitPriceForAdditionalLocalNumber;
    current.totalDiscountCalculation.totalLines =
      Number(current.totalDiscountCalculation.numberOfLimitedExts) + Number(unlimtedDls);
    let fees = 0;
    if (current.dealQuoteInfoFeeAndE991 && current.dealQuoteInfoFeeAndE991.length > 0) {
      const totalLines = current.totalDiscountCalculation.totalLines;
      let applicableFee;
      current.dealQuoteInfoFeeAndE991.every(function (fee) {
        if (totalLines < fee.Max_Users__c) {
          applicableFee = fee;
          return false;
        }
        return true;
      });
      if (applicableFee) {
        fees = applicableFee.Compliance_and_Administrative_cost__c;
      }
    }
    current.totalDiscountCalculation.feesAndE911 = (
      current.totalDiscountCalculation.totalLines * fees +
      current.totalDiscountCalculation.totalLines
    ).toFixed(4);
    current.totalDiscountCalculation.monthlyTotalForProservEnterprises = current.dealQuoteInfo
      .Monthly_total_for_ProServ_Enterprise__c
      ? current.dealQuoteInfo.Monthly_total_for_ProServ_Enterprise__c
      : 0;
    current.totalDiscountCalculation.monthlyTotalForContactCenter = current.dealQuoteInfo.Monthly_total_for_Contact_Center__c
      ? current.dealQuoteInfo.Monthly_total_for_Contact_Center__c
      : 0;
    current.totalDiscountCalculation.monthlyTotalForPhoneRentals = current.dealQuoteInfo.Monthly_total_for_phone_rentals__c
      ? current.dealQuoteInfo.Monthly_total_for_phone_rentals__c
      : 0;
    current.totalDiscountCalculation.monthlyTotalForAllOtherRecurringCharges = current.dealQuoteInfo
      .Monthly_total_for_all_other_recurring_ch__c
      ? current.dealQuoteInfo.Monthly_total_for_all_other_recurring_ch__c
      : 0;
    current.totalDiscountCalculation.totalDealMrr =
      Number(current.totalDiscountCalculation.officeMRR) +
      Number(current.totalDiscountCalculation.limitedExtMrr) +
      Number(current.totalDiscountCalculation.feesAndE911) +
      Number(current.totalDiscountCalculation.monthlyTotalForProservEnterprises) +
      Number(current.totalDiscountCalculation.monthlyTotalForContactCenter) +
      Number(current.totalDiscountCalculation.monthlyTotalForPhoneRentals) +
      Number(current.totalDiscountCalculation.monthlyTotalForAllOtherRecurringCharges) +
      Number(current.totalDiscountCalculation.basicLineMrr);
    current.totalDiscountCalculation.totalDealACV = (current.totalDiscountCalculation.totalDealMrr * 12).toFixed(4);
    let logAcv = 0,
      totalIntercept = 0;
    if (current.dealQuoteInfoLogAcv && current.dealQuoteInfoLogAcv.length > 0) {
      logAcv = current.dealQuoteInfoLogAcv[0].Coefficient__c;
    }
    if (current.dealQuoteInfoIntercept && current.dealQuoteInfoIntercept.length > 0) {
      const applicableIntercept = current.dealQuoteInfoIntercept.filter(intercept => {
        if (current.dealQuoteInfo.Tier__c.toLowerCase() === "standard") {
          if (intercept.MasterLabel.toLowerCase() === "standard monthly intercept".toLowerCase()) {
            return intercept;
          }
        } else {
          if (intercept.MasterLabel.toLowerCase() === "Total Intercept".toLowerCase()) {
            return intercept;
          }
        }
      });
      if (applicableIntercept.length > 0) {
        totalIntercept = applicableIntercept[0].Coefficient__c;
      }
    }
    current.totalDiscountCalculation.discountGivenDealSize = (
      (Math.log10(current.totalDiscountCalculation.totalDealACV) * logAcv + totalIntercept) *
      100
    ).toFixed(4);
  }
  calculatePotentialDiscount() {
    const current = this,
      potentialToSellContactCenterInNear = current.dealQuoteInfo.Potential_to_sell_contact_center_in_near__c,
      totalNumberOfEmployess =
        current.dealQuoteInfo.Total_Number_of_Employees__c === ""
          ? Number(0)
          : Number(current.dealQuoteInfo.Total_Number_of_Employees__c);
    current.dealQuoteInfo.Potential_to_sell_contact_center_in_near__c = potentialToSellContactCenterInNear;
    current.dealQuoteInfo.Total_Number_of_Employees__c = totalNumberOfEmployess;
    current.contactCenterMrrPotential.potentialToSellContactCenterInNearTerm = potentialToSellContactCenterInNear;
    if (
      potentialToSellContactCenterInNear &&
      potentialToSellContactCenterInNear !== "" &&
      potentialToSellContactCenterInNear === "Yes"
    ) {
      if (totalNumberOfEmployess < 1000) {
        if (current.dealQuoteInfoContactCenterPotential && current.dealQuoteInfoContactCenterPotential.length > 0) {
          const applicableCCP = current.dealQuoteInfoContactCenterPotential.filter(ccp => {
            if (totalNumberOfEmployess >= ccp.Lower_Band__c && totalNumberOfEmployess <= ccp.Upper_Band__c) {
              return ccp;
            }
          });
          if (applicableCCP.length > 0) {
            current.contactCenterMrrPotential.potentialContactCenterMRR = applicableCCP[0].Price__c.toFixed(4);
          } else {
            current.contactCenterMrrPotential.potentialContactCenterMRR = 0.0;
          }
        }
      } else {
        const applicableCCP = current.dealQuoteInfoContactCenterPotential.filter(ccp =>  {
          if (1000 >= ccp.Lower_Band__c && 1000 <= ccp.Upper_Band__c) {
            return ccp;
          }
        });
        if (applicableCCP.length > 0) {
          current.contactCenterMrrPotential.potentialContactCenterMRR = applicableCCP[0].Price__c.toFixed(4);
        } else {
          current.contactCenterMrrPotential.potentialContactCenterMRR = 0.0;
        }
      }
    } else {
      current.contactCenterMrrPotential.potentialContactCenterMRR = 0.0;
    }
  }
  calculateOfficeMrrPotential() {
    const current = this,
      tier = current.dealQuoteInfo.Tier__c,
      perDl = current.basePriceFullyUndiscounted.perDl,
      totalNumberOfEmployees = current.dealQuoteInfo.Total_Number_of_Employees__c,
      numberOfLimitedExts = current.dealQuoteInfo.Number_of_Limited_Exts__c,
      undiscountedUnitPriceForLimitedExts = current.dealQuoteInfo.Undiscounted_Unit_Price_for_Limited_Exts__c,
      monthlyTotalForProservEnterprises = current.dealQuoteInfo.Monthly_total_for_ProServ_Enterprise__c,
      monthlyTotalForContactCenter = current.dealQuoteInfo.Monthly_total_for_Contact_Center__c,
      monthlyTotalPhoneRentals = current.dealQuoteInfo.Monthly_total_for_phone_rentals__c,
      monthlyTotalForAllOtherRecurringCharge = current.dealQuoteInfo.Monthly_total_for_all_other_recurring_ch__c;
    current.officeMrrPotential.tierName = tier;
    current.officeMrrPotential.tierPrice = perDl;
    current.officeMrrPotential.totalNumberOfEmployees = totalNumberOfEmployees;
    current.officeMrrPotential.potentialOfficeMrr = (totalNumberOfEmployees * perDl).toFixed(4);
    current.officeMrrPotential.numberOfLimitedExts = numberOfLimitedExts;
    current.officeMrrPotential.undiscountedUnitPriceForLimitedExts = undiscountedUnitPriceForLimitedExts;
    current.officeMrrPotential.limitedExtsMrr = (undiscountedUnitPriceForLimitedExts * numberOfLimitedExts).toFixed(4);
    current.officeMrrPotential.totalLines = Number(numberOfLimitedExts) + Number(totalNumberOfEmployees);
    current.officeMrrPotential.feesAndE911 = 0;
    if (current.dealQuoteInfoFeeAndE991 && current.dealQuoteInfoFeeAndE991.length > 0) {
      const totalLines = current.officeMrrPotential.totalLines;
      let applicableFee;
      current.dealQuoteInfoFeeAndE991.every(function (fee) {
        if (totalLines < fee.Max_Users__c) {
          applicableFee = fee;
          return false;
        }
        return true;
      });
      if (applicableFee) {
        const cost = applicableFee.Compliance_and_Administrative_cost__c,
          feeRates = (totalLines * cost + totalLines).toFixed(4);
        current.officeMrrPotential.feesAndE911 = feeRates;
      }
    }
    current.officeMrrPotential.monthlyTotalForProservEnterprises = monthlyTotalForProservEnterprises;
    current.officeMrrPotential.monthlyTotalForContactCenter = monthlyTotalForContactCenter;
    current.officeMrrPotential.monthlyTotalPhoneRentals = monthlyTotalPhoneRentals;
    current.officeMrrPotential.monthlyTotalForAllOtherRecurringCharge = monthlyTotalForAllOtherRecurringCharge;
    current.officeMrrPotential.numberOfAdditionalLocalNumber = current.dealQuoteInfo.Number_of_additional_local_number_incl__c
      ? current.dealQuoteInfo.Number_of_additional_local_number_incl__c
      : 0;
    current.officeMrrPotential.undiscountedUnitPriceForAdditionalLocalNumber = current.dealQuoteInfo
      .Undiscounted_Unit_Price_for_additional_l__c
      ? current.dealQuoteInfo.Undiscounted_Unit_Price_for_additional_l__c
      : 0;
    current.officeMrrPotential.basicLineMrr =
      current.totalDiscountCalculation.numberOfAdditionalLocalNumber *
      current.totalDiscountCalculation.undiscountedUnitPriceForAdditionalLocalNumber;
    current.officeMrrPotential.potentialTotalMrr =
      Number(current.officeMrrPotential.potentialOfficeMrr) +
      Number(current.contactCenterMrrPotential.potentialContactCenterMRR) +
      Number(current.officeMrrPotential.limitedExtsMrr) +
      Number(current.officeMrrPotential.feesAndE911) +
      Number(current.officeMrrPotential.monthlyTotalForProservEnterprises) +
      Number(current.officeMrrPotential.monthlyTotalForContactCenter) +
      Number(current.officeMrrPotential.monthlyTotalPhoneRentals) +
      Number(current.officeMrrPotential.monthlyTotalForAllOtherRecurringCharge) +
      Number(current.officeMrrPotential.basicLineMrr);
    current.officeMrrPotential.PotentialAcv = (12 * current.officeMrrPotential.potentialTotalMrr).toFixed(4);
    let logAcv = 0,
      totalIntercept = 0;
    if (current.dealQuoteInfoLogAcv && current.dealQuoteInfoLogAcv.length > 0) {
      logAcv = current.dealQuoteInfoLogAcv[0].Coefficient__c;
    }
    if (current.dealQuoteInfoIntercept && current.dealQuoteInfoIntercept.length > 0) {
      const applicableIntercept = current.dealQuoteInfoIntercept.filter(intercept => {
        if (current.dealQuoteInfo.Tier__c.toLowerCase() === "standard") {
          if (intercept.MasterLabel.toLowerCase() === "standard monthly intercept".toLowerCase()) {
            return intercept;
          }
        } else {
          if (intercept.MasterLabel.toLowerCase() === "Total Intercept".toLowerCase()) {
            return intercept;
          }
        }
      });
      if (applicableIntercept.length > 0) {
        totalIntercept = applicableIntercept[0].Coefficient__c;
      }
    }
    current.officeMrrPotential.maxDiscountGivenDealRelationshipPotential = (
      (Math.log10(current.officeMrrPotential.PotentialAcv) * logAcv + totalIntercept) *
      100
    ).toFixed(4);
    current.officeMrrPotential.discountGivenDealSize = current.totalDiscountCalculation.discountGivenDealSize;
    current.officeMrrPotential.maxDiscountGivenPotential = (
      Number(current.officeMrrPotential.maxDiscountGivenDealRelationshipPotential) -
      Number(current.officeMrrPotential.discountGivenDealSize)
    ).toFixed(4);
    current.officeMrrPotential.discountGivenDeal = current.officeMrrPotential.maxDiscountGivenPotential;
    if (current.officeMrrPotential.discountGivenDeal >= 0) {
      // need to revisit for key value from metadata type
      let potentialSeat = 0;
      if (current.dealQuoteInfoPotentialSeat && current.dealQuoteInfoPotentialSeat.length > 0) {
        potentialSeat = current.dealQuoteInfoPotentialSeat[0].Coefficient__c;
      }
      current.officeMrrPotential.relationshipPotential = (current.officeMrrPotential.discountGivenDeal * potentialSeat).toFixed(
        4
      );
    } else {
      current.officeMrrPotential.relationshipPotential = 0.0;
    }
  }
  calculateDealTermDiscount() {
    const current = this,
      contractLengthDiscount = current.dealQuoteInfo.Contract_Length_Years__c,
      paymentPlanDiscount = current.dealQuoteInfo.Payment_Plan__c;
    try {
      if (contractLengthDiscount && contractLengthDiscount !== "" && Number(contractLengthDiscount) < 3) {
        current.dealTermDiscount.contractLengthDiscount = 0;
        if (current.dealQuoteInfoInitialTerm && contractLengthDiscount.length > 0) {
          const applicableTerm = current.dealQuoteInfoInitialTerm.filter(function (termLength) {
            if (termLength.MasterLabel === contractLengthDiscount) {
              return termLength;
            }
          });
          if (applicableTerm.length > 0) {
            current.dealTermDiscount.contractLengthDiscount = (applicableTerm[0].Coefficient__c * 100).toFixed(4);
          } else {
            current.dealTermDiscount.contractLengthDiscount = 0.0;
          }
        }
        //current.dealTermDiscount.contractLengthDiscount = 0.0;
      } else {
        if (current.dealQuoteInfoInitialTerm && contractLengthDiscount.length > 0) {
          const applicableTerm = current.dealQuoteInfoInitialTerm.filter(termLength => {
            if (termLength.MasterLabel === "3+") {
              return termLength;
            }
          });
          if (applicableTerm.length > 0) {
            current.dealTermDiscount.contractLengthDiscount = (applicableTerm[0].Coefficient__c * 100).toFixed(4);
          } else {
            current.dealTermDiscount.contractLengthDiscount = 0.0;
          }
        }
      }
    } catch (err) {
      if (current.dealQuoteInfoInitialTerm && contractLengthDiscount.length > 0) {
        const applicableTerm = current.dealQuoteInfoInitialTerm.filter(termLength => {
          if (termLength.MasterLabel === "3+") {
            return termLength;
          }
        });
        if (applicableTerm.length > 0) {
          current.dealTermDiscount.contractLengthDiscount = (applicableTerm[0].Coefficient__c * 100).toFixed(4);
        } else {
          current.dealTermDiscount.contractLengthDiscount = 0.0;
        }
      }
    }
    if (paymentPlanDiscount && paymentPlanDiscount !== "") {
      current.dealTermDiscount.paymentPlanDiscount = 0.0;
      if (current.dealQuoteInfoPaymentPlan && current.dealQuoteInfoPaymentPlan.length > 0) {
        const applicablePaymentPlan = current.dealQuoteInfoPaymentPlan.filter(paymentPlan => {
          if (paymentPlan.MasterLabel.toLowerCase() === paymentPlanDiscount.toLowerCase()) {
            return paymentPlan;
          }
        });
        if (applicablePaymentPlan.length > 0) {
          const planRate =
            applicablePaymentPlan[0].Coefficient__c && applicablePaymentPlan[0].Coefficient__c !== ""
              ? (applicablePaymentPlan[0].Coefficient__c * 100).toFixed(4)
              : 0.0;
          current.dealTermDiscount.paymentPlanDiscount = planRate;
        }
      }
    } else {
      current.dealTermDiscount.paymentPlanDiscount = 0.0;
    }
  }
  calculateOtherDiscount() {
    const current = this,
      contractLengthYear = current.dealQuoteInfo.Contract_Length_Years__c,
      freeMonthAdjustment = current.dealQuoteInfo.Free_Months_Given__c !== "" ? current.dealQuoteInfo.Free_Months_Given__c : 0,
      sectorAdjustment = current.dealQuoteInfo.Sector__c,
      featuresAdjustment = current.dealQuoteInfo.Features__c;

    let contractLengthYearVal = 0;
    try {
      contractLengthYearVal = Number(contractLengthYear);
    } catch (err) {
      contractLengthYearVal = 0;
    }
    if (current.dealQuoteInfoFreeMonthDiscount && current.dealQuoteInfoFreeMonthDiscount.length > 0) {
      const freeMonth = freeMonthAdjustment === "" ? 0 : Number(freeMonthAdjustment);
      let freeMonthAdjustDiscount = 0.0;
      if (contractLengthYearVal === 0) {
        freeMonthAdjustDiscount = (freeMonth * current.dealQuoteInfoFreeMonthDiscount[0].Coefficient__c * 100).toFixed(4);
      } else {
        freeMonthAdjustDiscount = (
          (freeMonth / contractLengthYearVal) *
          current.dealQuoteInfoFreeMonthDiscount[0].Coefficient__c *
          100
        ).toFixed(4);
      }
      current.otherDiscount.freeMonthAdjustment = freeMonthAdjustDiscount;
    } else {
      current.otherDiscount.freeMonthAdjustment = 0.0;
    }
    if (current.dealQuoteInfoSector && current.dealQuoteInfoSector.length > 0) {
      if (sectorAdjustment && sectorAdjustment !== "") {
        const sectorAdjustmentArr = current.dealQuoteInfoSector.filter(sector => {
          if (sector.MasterLabel.toLowerCase() === sectorAdjustment.toLowerCase()) {
            return sector;
          }
        });
        if (sectorAdjustmentArr.length > 0) {
          current.otherDiscount.sectorAdjustment = (Number(sectorAdjustmentArr[0].Coefficient__c) * 100).toFixed(2);
        } else {
          current.otherDiscount.sectorAdjustment = 0.0;
        }
      } else {
        current.otherDiscount.sectorAdjustment = 0.0;
      }
    }
    if (current.dealQuoteInfoFeature && current.dealQuoteInfoFeature.length > 0) {
      if (featuresAdjustment && featuresAdjustment !== "") {
        const featureAdjustmentArr = current.dealQuoteInfoFeature.filter(feature => {
          if (feature.MasterLabel.toLowerCase() === featuresAdjustment.toLowerCase()) {
            return feature;
          }
        });
        if (featureAdjustmentArr.length > 0) {
          current.otherDiscount.featureAdjustment = featureAdjustmentArr[0].Coefficient__c.toFixed(2);
        } else {
          current.otherDiscount.featureAdjustment = 0.0;
        }
      } else {
        current.otherDiscount.Features = 0.0;
      }
    }
  }
  calculateTotalDiscount() {
    const current = this,
      discountGivenDealSize = current.totalDiscountCalculation.discountGivenDealSize,
      relationshipPotentialDiscount = current.officeMrrPotential.relationshipPotential,
      contractLengthDiscount = current.dealTermDiscount.contractLengthDiscount,
      paymentPlanDiscount = current.dealTermDiscount.paymentPlanDiscount ? current.dealTermDiscount.paymentPlanDiscount : 0.0,
      freeMonthAdjustment = current.otherDiscount.freeMonthAdjustment,
      sectorAdjustment = current.otherDiscount.sectorAdjustment,
      featureAdjustment = current.otherDiscount.Features;
    let totalDiscount =
      Number(discountGivenDealSize) +
      Number(relationshipPotentialDiscount) +
      Number(contractLengthDiscount) +
      Number(paymentPlanDiscount) +
      Number(freeMonthAdjustment) +
      Number(sectorAdjustment) +
      Number(featureAdjustment);
    current.totalDiscount = totalDiscount.toFixed(4);
  }
  calculateTargetPriceCalculation() {
    const current = this,
      totalDiscount = current.totalDiscount,
      basePriceTotal = current.basePriceFullyUndiscounted.total,
      dlBucket = current.listPrice.dlBucket,
      totalAdvertised = current.listPrice.totalAdvertised;
    current.targetPriceCalculation.suggestedDiscountVsBasePrice = ((totalDiscount * basePriceTotal) / 100).toFixed(4);
    current.targetPriceCalculation.discountRecommendation =
      basePriceTotal - current.targetPriceCalculation.suggestedDiscountVsBasePrice;
    current.targetPriceCalculation.isDlBucket1Line = dlBucket === "0-1";
    current.targetPriceCalculation.isDiscountedPriceRecoHigherThanListPrice =
      current.targetPriceCalculation.discountRecommendation > totalAdvertised;
    if (
      current.targetPriceCalculation.isDiscountedPriceRecoHigherThanListPrice ||
      current.targetPriceCalculation.isDlBucket1Line
    ) {
      current.targetPriceCalculation.targetPrice = totalAdvertised;
    } else if (
      !(current.targetPriceCalculation.isDiscountedPriceRecoHigherThanListPrice || current.targetPriceCalculation.isDlBucket1Line)
    ) {
      current.targetPriceCalculation.targetPrice = current.targetPriceCalculation.discountRecommendation;
    } else {
      current.targetPriceCalculation.targetPrice = 0;
    }
    current.targetPriceCalculation.recommendedPerDiscountVsList = (
      1 -
      current.targetPriceCalculation.targetPrice / totalAdvertised
    ).toFixed(4);
    current.targetPriceCalculation.isRecommenedPerDiscountVsListAbove60 =
      current.targetPriceCalculation.recommendedPerDiscountVsList > 0.6;
    if (current.targetPriceCalculation.isRecommenedPerDiscountVsListAbove60) {
      current.targetPriceCalculation.finalTargetPriceReco = ((40 / 100) * totalAdvertised).toFixed(4);
    } else {
      current.targetPriceCalculation.finalTargetPriceReco = current.targetPriceCalculation.targetPrice;
    }
    current.targetPriceCalculation.finalRecommendedPerDiscountVsList =
      (1 - current.targetPriceCalculation.finalTargetPriceReco / totalAdvertised) * 100;
    current.dealQuoteInfo.Recommended_Unlimited_DLs_price_after_di__c = current.targetPriceCalculation.finalTargetPriceReco;
    // target price calculation
    const recommendUnlimitedDlPriceAfterDiscount = current.targetPriceCalculation.finalTargetPriceReco,
      unlimitedDls = current.handleUndefinedForField(current.dealQuoteInfo.Number_of_Unlimited_DLs__c),
      perLimitedExtension = current.handleUndefinedForField(current.dealQuoteInfo.Number_of_Limited_Exts__c),
      numberOfLimitedExtension = current.handleUndefinedForField(current.dealQuoteInfo.Undiscounted_Unit_Price_for_Limited_Exts__c),
      recommendedPerDiscountVsList = ((1 - recommendUnlimitedDlPriceAfterDiscount / totalAdvertised) * 100).toFixed(4),
      recommendedPricePerUnlimitedDlAfterDiscount = recommendUnlimitedDlPriceAfterDiscount / unlimitedDls,
      recommendedPricePerLimitedExtensionAfterDiscount = (
        numberOfLimitedExtension *
        (1 - recommendedPerDiscountVsList / 100)
      ).toFixed(4),
      recommendedLimitedExtensionPriceAfterDiscount = recommendedPricePerLimitedExtensionAfterDiscount * perLimitedExtension;
    current.dealQuoteInfo.Recommended_price_per_Unlimited_DL_after__c = recommendedPricePerUnlimitedDlAfterDiscount;
    current.dealQuoteInfo.Recommended_Unlimited_DLs_price_after_di__c = recommendUnlimitedDlPriceAfterDiscount;
    current.dealQuoteInfo.Recommended_price_per_Limited_Extension__c = this.handleUndefinedForField(recommendedPricePerLimitedExtensionAfterDiscount);
    current.dealQuoteInfo.Recommended_Limited_Extensions_price_aft__c = recommendedLimitedExtensionPriceAfterDiscount;
    current.dealQuoteInfo.Recommended_Discount_vs_list__c = this.handleUndefinedForField(recommendedPerDiscountVsList);
  }
  calculateFinalPrice() {
    const current = this,
      finalDiscountVsList = current.handleUndefinedForField(current.dealQuoteInfo.Final_discount_vs_list__c),
      totalForUnlimitedDls = current.handleUndefinedForField(current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c),
      finalQuotePriceForUnlimitedDls =  current.handleUndefinedForField(current.dealQuoteInfo.Final_quote_price_for_Unlimited_DLs__c),
      recommendedUnlimitedDLsPriceAfterDiscount = current.handleUndefinedForField( current.dealQuoteInfo.Recommended_Unlimited_DLs_price_after_di__c) ,
      dealDiscretionForUnlimitedDls = finalDiscountVsList - (totalForUnlimitedDls - recommendedUnlimitedDLsPriceAfterDiscount),
      finalDiscountVsListPer =  current.handleUndefinedForField(current.dealQuoteInfo.Final_discount_vs_list_percent__c),
      recommendedPerDiscountVsList =  current.handleUndefinedForField(current.dealQuoteInfo.Recommended_Discount_vs_list__c),
      dealDiscretionForUnlimitedDlsPer = finalDiscountVsListPer - recommendedPerDiscountVsList,
      discretionVsTargetPrice = dealDiscretionForUnlimitedDls / recommendedUnlimitedDLsPriceAfterDiscount,
      contractLength =  current.handleUndefinedForField(current.dealQuoteInfo.Contract_Length_Years__c),
      freeMonthGiven =  current.handleUndefinedForField(current.dealQuoteInfo.Free_Months_Given__c),
      totalDealAcv = current.totalDiscountCalculation.totalDealACV;
    current.dealQuoteInfo.Deal_discretion_for_Unlimited_DLs_Per__c = dealDiscretionForUnlimitedDlsPer;
    current.dealQuoteInfo.Deal_discretion_for_Unlimited_DLs__c = dealDiscretionForUnlimitedDls;
    current.dealQuoteInfo.Discretion_vs_target_price__c = (discretionVsTargetPrice * 100).toFixed(4);
	current.dealQuoteInfo.Discretion_vs_target_price__c = current.handleUndefinedForField(current.dealQuoteInfo.Discretion_vs_target_price__c );
    let reason = "";
	const finalDiscountVsListInPer = (finalDiscountVsListPer / 100 )

	const conditionContractLength = Number.isInteger(contractLength) ? (Number(freeMonthGiven) > Number(contractLength) * 2) : Number(freeMonthGiven) > 20;
    if (conditionContractLength || (totalDealAcv * Number(contractLength) > 300000 && discretionVsTargetPrice > 0.35) || finalDiscountVsListInPer > 0.5) {
        reason = "SVP/Finance Approval Needed";
    } else if (discretionVsTargetPrice > 0.25) {
      reason = "Segment Leader Approval Needed";
    } else if (discretionVsTargetPrice > 0.15) {
      reason = "L2 Approval Needed";
    } else if (discretionVsTargetPrice > 0) {
      reason = "L1 Approval Needed";
    } else if (discretionVsTargetPrice <= 0) {
      reason = "None";
    }
    current.dealQuoteInfo.Approval_Needed_for_Unlimited_DLs__c = reason;
    let goaReason = "";
    const finalDiscountVsListPerVal = finalDiscountVsListPer / 100;
    if (Number.isInteger(contractLength) && Number(freeMonthGiven) > Number(contractLength) * 2) {
      goaReason = "SVP/Finance Approval Needed";
    } else if (finalDiscountVsListPerVal >= 0.5) {
      goaReason = "SVP/Finance Approval Needed";
    } else if (finalDiscountVsListPerVal >= 0.35) {
      goaReason = "Segment Leader Approval Needed";
    } else if (finalDiscountVsListPerVal >= 0.2) {
      goaReason = "L2 Approval Needed";
    } else if (finalDiscountVsListPerVal >= 0.1) {
      goaReason = "L1 Approval Needed";
    } else if (finalDiscountVsListPerVal < 0.1) {
      goaReason = "None";
    }
    if (goaReason === reason) {
      current.dealQuoteInfo.Approval_Different_from_GoA__c = "No- No escalation change req'd";
    } else {
      current.dealQuoteInfo.Approval_Different_from_GoA__c = "Yes- Office approval reassignment req'd";
    }
  }
  handleUndefinedForField(value) {
	  if (value) {
		  return isNaN(value) ? 0 : value;
	  } 
		  return 0;
  }
  updateContractLength(value) {
    const current = this,
      unlimitedDls = current.dealQuoteInfo.Number_of_Unlimited_DLs__c;
    const applicableBaseListPrice = current.selectedBaseListPrice.filter(function (eachList) {
      if (unlimitedDls >= eachList.Lower_Band__c && unlimitedDls <= eachList.Upper_Band__c) {
        return eachList;
      }
    });
    let paymentPlan = current.dealQuoteInfo.Payment_Plan__c,
      contractLength = value;
    contractLength = contractLength.trim().length > 0 ? contractLength : "0";
    current.dealQuoteInfo.Contract_Length_Years__c = contractLength;
    // console.log(JSON.stringify(applicableBaseListPrice), 'applicableBaseListPrice');
    if (applicableBaseListPrice && applicableBaseListPrice.length > 0) {
      current.listPrice.dlBucket = applicableBaseListPrice[0].Lower_Band__c + "-" + applicableBaseListPrice[0].Upper_Band__c;
      if (
        paymentPlan &&
        paymentPlan.trim().length > 0 &&
        paymentPlan === "Monthly" &&
        contractLength &&
        contractLength.trim().length > 0 &&
        contractLength === "0"
      ) {
        current.listPrice.paymentPlan = "Monthly";
      } else if (paymentPlan && paymentPlan.trim().length > 0 && paymentPlan === "Monthly" && contractLength !== "0") {
        current.listPrice.paymentPlan = "Monthly With Contract";
      } else {
        current.listPrice.paymentPlan = "Annual";
        current.dealQuoteInfo.Payment_Plan__c = "Annual";
      }
      if (current.listPrice.paymentPlan === "Annual") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Annual__c;
      } else if (current.listPrice.paymentPlan === "Monthly With Contract") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly_With_Contract__c;
      } else if (current.listPrice.paymentPlan === "Monthly") {
        current.listPrice.perDLAdvertised = applicableBaseListPrice[0].Monthly__c;
      }
      current.listPrice.totalAdvertised = (unlimitedDls * current.listPrice.perDLAdvertised).toFixed(4);
      current.basePriceFullyUndiscounted.perDl = applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c;
      current.basePriceFullyUndiscounted.total = (applicableBaseListPrice[0].Base_Price_Deal__r.Rate__c * unlimitedDls).toFixed(
        4
      );
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = current.listPrice.perDLAdvertised;
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = current.listPrice.totalAdvertised;
    } else {
      current.dealQuoteInfo.Per_Unlimited_DL_advertised__c = "Please check tier and DL bucket combination.";
      current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c = "Please check tier and DL bucket combination.";
    }
  }
  updateLimitedExtensionAdvertised(value) {
    const current = this;
    if (value !== "") {
      current.dealQuoteInfo.Per_Limited_Extension_advertised__c = value;
    }
  }
  updateTotalLimitedExtension(event) {
    const current = this,
      id = event.target.dataset.id,
      value = event.target.value;
    if (id === "Number_of_Limited_Exts__c") {
      const undiscountedUnitPriceLimitedExts = current.dealQuoteInfo.Undiscounted_Unit_Price_for_Limited_Exts__c;
      if (undiscountedUnitPriceLimitedExts !== "") {
        current.dealQuoteInfo.Total_for_Limited_Extensions_advertised__c = (undiscountedUnitPriceLimitedExts * value).toFixed(4);
      }
    }
    if (id === "Undiscounted_Unit_Price_for_Limited_Exts__c") {
      const undiscountedUnitPriceLimitedExts = current.dealQuoteInfo.Number_of_Limited_Exts__c;
      if (undiscountedUnitPriceLimitedExts !== "") {
        current.dealQuoteInfo.Total_for_Limited_Extensions_advertised__c = (undiscountedUnitPriceLimitedExts * value).toFixed(4);
        current.dealQuoteInfo.Per_Limited_Extension_advertised__c = value;
      }
    }
    current.applyCalculationRule();
  }
  blurOnFinalQuotePricePerUnlimited(event) {
    const current = this,
      value = event.target.value,
      numberOfUnlimitedDls = current.handleUndefinedForField(current.dealQuoteInfo.Number_of_Unlimited_DLs__c);
    if (value !== "" && numberOfUnlimitedDls !== "") {
      current.dealQuoteInfo.Final_quote_price_for_Unlimited_DLs__c = (value * numberOfUnlimitedDls).toFixed(4);
      current.dealQuoteInfo.Final_discount_vs_list__c = (
		current.handleUndefinedForField(current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c) - 
		current.handleUndefinedForField(current.dealQuoteInfo.Final_quote_price_for_Unlimited_DLs__c)
      ).toFixed(4);
      current.dealQuoteInfo.Final_discount_vs_list_percent__c = (
        (
			current.handleUndefinedForField(current.dealQuoteInfo.Final_discount_vs_list__c) /  current.handleUndefinedForField(current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c)) *
        100
      ).toFixed(4);

	  current.dealQuoteInfo.Final_discount_vs_list_percent__c = current.handleUndefinedForField(current.dealQuoteInfo.Final_discount_vs_list_percent__c );
    }
  }
  updateFinalQuotePricePerUnlimited(value) {
    const current = this,
      numberOfUnlimitedDls = current.dealQuoteInfo.Number_of_Unlimited_DLs__c;
    if (value !== "" && numberOfUnlimitedDls !== "") {
      current.dealQuoteInfo.Final_quote_price_for_Unlimited_DLs__c = (value * numberOfUnlimitedDls).toFixed(4);
      current.dealQuoteInfo.Final_discount_vs_list__c = (
        current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c - current.dealQuoteInfo.Final_quote_price_for_Unlimited_DLs__c
      ).toFixed(4);
      current.dealQuoteInfo.Final_discount_vs_list_percent__c = (
        (current.dealQuoteInfo.Final_discount_vs_list__c / current.dealQuoteInfo.Total_for_Unlimited_DLs_advertised__c) *
        100
      ).toFixed(4);
	  current.dealQuoteInfo.Final_discount_vs_list_percent__c = current.handleUndefinedForField(current.dealQuoteInfo.Final_discount_vs_list_percent__c );
    }
  }
  blurOnFinalQuotePriceForLimited(event) {
    const current = this,
      value = event.target.value,
      numberOfLimitedDls = current.dealQuoteInfo.Number_of_Limited_Exts__c;
    if (value !== "" && numberOfLimitedDls !== "") {
      current.dealQuoteInfo.Final_quote_price_for_Limited_Extensions__c = (value * numberOfLimitedDls).toFixed(4);
    }
  }
  onQuoteSelection(event) {
    const current = this,
      record = event.detail;
    this.dealQuoteInfo.Sales_Agreement__c = record.selectedRecordId;
    if (record.selectedRecord) {
      current.dealQuoteInfo.Opportunity__c = record.selectedRecord.Opportunity.Id;
      current.selectedOpportunity = record.selectedRecord.Opportunity.Name;
    }
    if (record.selectedRecordId) {
      current.getQuoteInfo(record.selectedRecordId);
    }
  }
  onOpportuntiySelection(event) {
    this.dealQuoteInfo.Opportunity__c = event.detail.selectedRecordId;
  }
  showToast(title, message) {
	if (this.isLightning && this.isLightning !== 'false') {
		const event = new ShowToastEvent({
			title: title,
			message: message
		  });
		  this.dispatchEvent(event);
	} else {
		alert(message);
	}
    
  }
  getQuoteInfo(selectedQuoteId) {
    const current = this;
    let quoteDealInfo = { ...current.dealQuoteInfo };
    getQuoteInfoById({
      quoteId: selectedQuoteId
    })
      .then((result) => {
        if (result) {
          console.log("result", result);
          quoteDealInfo.Payment_Plan__c = result.Payment_Plan__c;
          if (result.Package_Info__c) {
            const editionInfo = JSON.parse(result.Package_Info__c);
            quoteDealInfo.Tier__c = editionInfo[0].edition.name;
          }
          if (result.Initial_Term_months__c) {
            quoteDealInfo.Contract_Length_Years__c = Number(result.Initial_Term_months__c) / 12 + "";
          }
          if (result.Total_Number_of_Digital_Lines__c !== undefined) {
            quoteDealInfo.Total_Number_of_Employees__c = result.Total_Number_of_Digital_Lines__c;
          }
          if (result.Special_Terms__c) {
            // Free Month Given
            if (["2-day Shipping for Ground Pricing", "Free shipping"].indexOf(result.Special_Terms__c) === -1) {
              const freeGivenService = result.Special_Terms__c.charAt(0);
              quoteDealInfo.Free_Months_Given__c = Number(freeGivenService);
            }
          }
          if (result.QuoteLineItems) {
            result.QuoteLineItems.forEach(function (quoteLine) {
              if (quoteLine.Product2 && quoteLine.Product2.Name.includes("DigitalLine Unlimited")) {
                quoteDealInfo.Number_of_Unlimited_DLs__c = quoteLine.Quantity;
              }
              if (quoteLine.Product2 && quoteLine.Product2.Name.includes("DigitalLine Basic")) {
                quoteDealInfo.Number_of_Limited_Exts__c = quoteLine.Quantity;
                if (quoteDealInfo.Payment_Plan__c === "Annual") {
                  quoteDealInfo.Undiscounted_Unit_Price_for_Limited_Exts__c = quoteLine.UnitPrice / 12;
                } else {
                  quoteDealInfo.Undiscounted_Unit_Price_for_Limited_Exts__c = quoteLine.UnitPrice;
                }
              }
            });
          }
          current.dealQuoteInfo = quoteDealInfo;
          current.recalculateCalculation();
        }
      })
      .catch((err) => {
        console.log("err", err);
      });
  }
  closeQuickAction() {
    const closeQA = new CustomEvent("close");
    // Dispatches the event.
    this.dispatchEvent(closeQA);
  }

  refreshFromQuoteClick(event) {
	  const current = this,
	  	dealQuoteInfo = {...current.dealQuoteInfo};

	 if (dealQuoteInfo.Sales_Agreement__c && dealQuoteInfo.Sales_Agreement__c !== "") {
		 const params = {
			dealQuoteInfoId: dealQuoteInfo.Id ? dealQuoteInfo.Id : '',
			quoteId: dealQuoteInfo.Sales_Agreement__c
		 }
		 refreshValueFromQuote(params).
		 then(result => {
			if (result) {
				if (result.dealQuoteInfo) {
					current.dealQuoteInfo = { ...result.dealQuoteInfo };
					if (result.dealQuoteInfo.Opportunity__r) {
					  current.selectedOpportunity = result.dealQuoteInfo.Opportunity__r.Name;
					}
					if (result.dealQuoteInfo.Sales_Agreement__r) {
					  current.selectedQuote = result.dealQuoteInfo.Sales_Agreement__r.Name;
					}
				  }
				  if (result.salesAgreementInformation) {
					current.selectedOpportunity = result.salesAgreementInformation.Opportunity.Name;
					current.selectedQuote = result.salesAgreementInformation.Name;
					current.isFromOpportunity = true;
				  }
				  current.recalculateCalculation();	
			}
		 }).
		 catch(err => {
			this.error = err;
		 })
	 } else {
		 alert('Please select quote.')
	 }
  }

  handleAcceptRecommendation() {
    const params = {
      quoteId: this.dealQuoteInfo.Sales_Agreement__c,
      targetPricePercent: this.dealQuoteInfo.Final_discount_vs_list_percent__c
    };

    acceptRecommendation(params)
    .then((result) => {
      if (result === 'true') {
        alert('Recommend set successfully!')
        window.location.reload();
      } else if (result !== 'false') {
        alert(result);
      } else if (result === 'false') {
        alert('Error is reported! Please contact your system administrator for more information.');
      }
    }).catch(err => {
      alert(err);
      this.error = err;
    });
  }
}