import { LightningElement, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

import getAccountFromNGBSPartnerId from '@salesforce/apex/PRM_Package_Creator_Helper.getAccountFromNGBSPartnerId';
import getNGBSLicenseSettings from '@salesforce/apex/PRM_Package_Creator_Helper.getNGBSLicenseSettings';
import getContractDiscounts from '@salesforce/apex/PRM_Package_Creator_Helper.getContractDiscounts';
import getPartnerPackages from '@salesforce/apex/PRM_Package_Creator_Helper.getPartnerPackages';
import getCatalogPackageData from '@salesforce/apex/PRM_Package_Creator_Helper.getCatalogPackageData';
import upsertProductTierPriceApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductTierPriceApex';
import upsertProductCatalogueApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductCatalogueApex';
import upsertProductCatalogueRuleApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductCatalogueRuleApex';

import {
  upsertProductPackage,
  upsertPartnerProductPackage,
  upsertProduct2,
  upsertProductCatalogue,
  upsertProductTierPrice,
  upsertProductCatalogueRule,
  upsertLboxProductCatalogueRule,
  upsertWholesalePartnerPackageLink
} from './prmPackageCreatorHelper';

import catalogParentOverrideMapping from './catalogParentOverrideMapping';
import dependentQuantityProductMapping from './dependentQuantityProductMapping';

export default class PrmPackageCreator extends LightningElement {
  ngbsPartnerId;
  ngbsPackageId;
  ngbsPackageVersion;
  partnerAccount;
  output;
  logs = 'Waiting for user input...';
  transientLogs;
  count;
  inProgress = false;
  inCatalogProgress = false;
  isSelfChecked = false;
  topLevelTierPrices = [];
  hiddenLicenses = [];

  handleTabChange = (_) => {
    this.logs = 'Waiting for user input...';
    this.transientLogs = '';
    this.isSelfChecked = false;
    this.ngbsPartnerId = '';
    this.ngbsPackageId = '';
    this.ngbsPackageVersion = '';
    this.topLevelTierPrices = [];
  }

  handleNgbsPartnerIdInputChange = (event) => {
    this.ngbsPartnerId = event.detail.value;
  }

  handleNgbsPackageIdInputChange = (event) => {
    this.ngbsPackageId = event.detail.value;
  }

  handleNgbsPackageVersionInputChange = (event) => {
    this.ngbsPackageVersion = event.detail.value;
  }

  handleSelfToggleChange = (event) => {
    this.isSelfChecked = event.detail.checked;
  }

  handleSubmitButtonClick = async () => {
    if (!this.ngbsPartnerId) {
      this.inProgress = false;
      return;
    }
    this.inProgress = true;
    this.logs = '';

    this.logs = `Checking if Partner Exists....` + this.logs;
    this.partnerAccount = await getAccountFromNGBSPartnerId({ ngbsPartnerId: this.ngbsPartnerId });

    if (!this.partnerAccount) {
      this.logs = `Wholesale Partner Account with NGBS ID ${this.ngbsPartnerId} doesn't exist. Please try another ID.\n` + this.logs;
      this.inProgress = false;
      return;
    }

    this.logs = `\n=====================================================\nDone....` + this.logs;
    this.logs = `Retrieving Partner Packages from NGBS....` + this.logs;

    let partnerPackageData;
    try {
      partnerPackageData = JSON.parse(await getPartnerPackages({ ngbsPartnerId: `${this.ngbsPartnerId}`, includeSelf: this.isSelfChecked }));
      this.logs = `\n=====================================================\nDone....` + this.logs;
    } catch (error) {
      this.logs = `Process Failed. Please retry...\n` + this.logs;
      this.inProgress = false;
      return;
    }

    if (partnerPackageData.message) {
      this.logs = `${partnerPackageData.message}\n` + this.logs;
    } else if (partnerPackageData.length === 0) {
      this.logs = `No packages have been assigned to this partner yet...\n` + this.logs;
    }

    for (let i = 0; i < partnerPackageData.length; i++) {
      this.topLevelTierPrices = [];
      /**UPSERT CATALOG PRODUCT PACKAGE STARTS*/
      this.logs = `Retrieving Catalog Package ${partnerPackageData[i].id}v${partnerPackageData[i].version} from NGBS....` + this.logs;
      let packageData;
      try {
        packageData = JSON.parse(await getCatalogPackageData({ packageId: partnerPackageData[i].id, version: partnerPackageData[i].version }));
      } catch (error) {
        this.logs = `Process Failed. Please retry...\n` + this.logs;
        this.inProgress = false;
        return;
      }
      this.logs = `\n=====================================================\nDone....` + this.logs;
      const upsertedCatalogPackage = await this.upsertCataloguePackage(packageData);
      /**UPSERT CATALOG PRODUCT PACKAGE ENDS*/

      /**UPSERT WHOLESALE CATALOG PRODUCT PACKAGE STARTS*/
      for (let j = 0; j < partnerPackageData[i].partnerPackages.length; j++) {
        await this.upsertPartnerCataloguePackage(packageData, partnerPackageData[i].partnerPackages[j], upsertedCatalogPackage.Id);
      }
      this.logs = `\n=====================================================\nDone....` + this.logs;
      /**UPSERT WHOLESALE CATALOG PRODUCT PACKAGE ENDS*/
    }
    this.inProgress = false;
    this.logs = `Process Complete....\n` + this.logs;
  }

  handleCatalogSubmitButtonClick = async () => {
    if (!(this.ngbsPackageId && this.ngbsPackageVersion)) {
      this.inCatalogProgress = false;
      return;
    }

    this.inCatalogProgress = true;
    this.logs = `Retrieving Catalog Package ${this.ngbsPackageId}v${this.ngbsPackageVersion} from NGBS....`;

    let packageData;
    try {
      packageData = JSON.parse(await getCatalogPackageData({ packageId: this.ngbsPackageId, version: this.ngbsPackageVersion }));
      this.logs = `\n=====================================================\nDone....` + this.logs;
    } catch (error) {
      this.logs = `Process Failed. Please retry...\n` + this.logs;
      this.inCatalogProgress = false;
      return;
    }

    if (packageData.message) {
      this.logs = `${packageData.message}\n` + this.logs;
    } else {
      this.topLevelTierPrices = [];
      await this.upsertCataloguePackage(packageData, true);
    }

    this.logs = `\n=====================================================\nDone....` + this.logs;
    this.logs = `Process Complete....\n` + this.logs;
    this.inCatalogProgress = false;
  }

  upsertCataloguePackage = (pkg, isV2Package = false) => {
    return new Promise(async (resolve, reject) => {
      try {
        //Get List of NGBS Hidden License Custom Settings
        this.logs = `\nGetting NGBS License Settings...` + this.logs;
        const ngbsLicenseSettings = await getNGBSLicenseSettings({});

        //Get list of Contract Discounts
        this.logs = `\nGetting Contract Discount Records...` + this.logs;;
        const contractDiscounts = await getContractDiscounts({});

        this.count = 0;
        const productPackage = await upsertProductPackage(pkg, isV2Package);
        this.output = productPackage;

        this.logs = `Upserting [${pkg.id}${isV2Package ? '|' : '~'}${pkg.version} - ${pkg.displayName}] Catalog Package in SFDC\n` + this.logs;
        this.logs = `Upserted Product Package Id ==> ${productPackage.Id}\n` + this.logs;

        await this.licenseParser(pkg.licenses, null, pkg.currency, productPackage, `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version}`, null, ngbsLicenseSettings, contractDiscounts);
        await this.cboxParser(pkg.cboxes, null, pkg.currency, productPackage, `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version}`, ngbsLicenseSettings, contractDiscounts);
        await this.lboxParser(pkg.lboxes, pkg.currency, productPackage, `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version}`, ngbsLicenseSettings, contractDiscounts);
        await this.upsertTopLevelTierPrice(false, `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version}`, productPackage.Id);
        await this.upsertProductCatalogueDataCorrections(productPackage.productCatalogues, productPackage.productCatalogueRules);
        await this.deleteEmptyTierPrices(productPackage.productCatalogues);

        //Download Logic
        const hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/json;charset=utf-8,' + encodeURI(JSON.stringify(this.output));
        hiddenElement.target = '_self';
        hiddenElement.download = `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version} - ${pkg.displayName} - out.json`;
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        document.body.removeChild(hiddenElement);

        this.transientLogs = '';
        this.logs = `${this.count} Product Catalogues upserted.\n=====================================================\n` + this.logs;

        resolve(productPackage);
      } catch (error) {
        reject(error);
      }
    });
  }

  upsertPartnerCataloguePackage = (pkg, wholesalePkg, catalogPackageId) => {
    return new Promise(async (resolve, reject) => {
      try {
        this.logs = `Upserting [${pkg.id}~${pkg.version}~${wholesalePkg.id}~${wholesalePkg.version} - ${wholesalePkg.displayName} v${wholesalePkg.version}] Wholesale Package in SFDC\n` + this.logs;
        const productPackage = await upsertPartnerProductPackage(pkg, wholesalePkg);
        await this.upsertTopLevelTierPrice(true, `${wholesalePkg.id}~${wholesalePkg.version}`, productPackage.Id);
        this.logs = `Upserted Product Package Id ==> ${productPackage.Id}\n` + this.logs;

        const wholesalePackageLink = await upsertWholesalePartnerPackageLink(JSON.parse(JSON.stringify(this.partnerAccount)), productPackage, catalogPackageId);
        this.logs = `Upserted Wholesale Partner Package Link ==> ${wholesalePackageLink.Id}\n` + this.logs;
        this.logs = `----------------------------------------\n` + this.logs;

        this.transientLogs = '';

        resolve(productPackage);
      } catch (error) {
        reject(error);
      }
    });
  }

  upsertTopLevelTierPrice = (isWholeSale, packageExtId, packageSfdcId) => {
    return Promise.all(this.topLevelTierPrices && this.topLevelTierPrices.map(async (productTierPrice) => {
      const suffix = isWholeSale ? `Partner~${packageExtId}` : `Catalog~${packageExtId}`;
      delete productTierPrice.Id;
      delete productTierPrice.Product_Catalogue__c;
      productTierPrice.ExtID__c = `${productTierPrice.ExtID__c}~${suffix}`
      await upsertProductTierPriceApex({ productTierPrice: { ...productTierPrice, ...{ Product_Package__c: packageSfdcId } } });
    }));
  }

  upsertProductCatalogueDataCorrections = (productCatalogList, productCatalogueRules) => {
    const finalProductCatalogList = [];

    //Fix parent from parent override
    productCatalogList && productCatalogList.filter(productCatalogue => catalogParentOverrideMapping.hasOwnProperty(productCatalogue.Element_ID__c))
      .map((productCatalogue) => {
        const actualParent = productCatalogList.filter(x => x.Element_ID__c === catalogParentOverrideMapping[productCatalogue.Element_ID__c]);
        productCatalogue.Parent__c = actualParent.length > 0 ? actualParent[0].Id : null;
        finalProductCatalogList.push(productCatalogue);
      });

    //Add Dependent Quantity Product
    productCatalogList && productCatalogList.filter(productCatalogue => dependentQuantityProductMapping.hasOwnProperty(productCatalogue.Element_ID__c))
      .map(async (productCatalogue) => {
        const actualParents = productCatalogList.filter(x => dependentQuantityProductMapping[productCatalogue.Element_ID__c] && dependentQuantityProductMapping[productCatalogue.Element_ID__c].indexOf(x.Element_ID__c) > -1);
        productCatalogue.Quantity_Dependent_Product_1__c = actualParents.length > 0 ? actualParents[0].Id : null;
        productCatalogue.Quantity_Dependent_Product_2__c = actualParents.length > 1 ? actualParents[1].Id : null;
        finalProductCatalogList.push(productCatalogue);
      });

    //Add CB_40 CBOX Rule to 'Additional-Toll Free' Product_Catalogue and add `Additional-Toll Free` in CB_40
    productCatalogList && productCatalogList.filter(productCatalogue => productCatalogue.Element_ID__c === 'LC_ATN_39')
      .map(async (productCatalogue) => {
        const CB_40 = productCatalogueRules.filter(x => x.Name === 'CB_40');
        if (CB_40.length > 0) {
          CB_40[0].Count_Dependent_On__c = productCatalogue.Id;
          const Id = await upsertProductCatalogueRuleApex({ productCatalogueRule: CB_40[0] });

          productCatalogue.Product_Catalogue_Rule__c = Id;
          await upsertProductCatalogueApex({ productCatalogue });
        }
      });

    return Promise.all(finalProductCatalogList.map(async productCatalogue => {
      await upsertProductCatalogueApex({ productCatalogue });
    }));
  }

  deleteEmptyTierPrices = (productCatalogList) => {
    const tierPricesTobeDeleted = [];

    productCatalogList && productCatalogList.map((productCatalogue) => {
      if (productCatalogue.productTierPrices.length > 1) {
        productCatalogue.productTierPrices = productCatalogue.productTierPrices.filter((tierPrice) => {
          if (tierPrice.Monthly_Price__c === 0 && tierPrice.Monthly_Price__c === 0) {
            tierPricesTobeDeleted.push(tierPrice);
            return false;
          } else {
            return true;
          }
        })
      }
    });

    return Promise.all(tierPricesTobeDeleted.filter(tierPrice => tierPrice.Id).map(tierPrice => deleteRecord(tierPrice.Id)));
  }

  licenseParser = async (licenses, parentLicense, currencyCode, productPackage, packageExtId, productCatalogueRule, ngbsLicenseSettings, contractDiscounts) => {
    licenses = licenses ?? [];

    return Promise.all(licenses && licenses.map(async (license) => {
      //Log
      this.transientLogs = `UPSERTING <==> ${++this.count} [${license.elementID}] - ${license.displayName}\n`;

      //Generate and upsert Product2
      const product2 = await upsertProduct2(license);

      //Generate and upsert Product_Catalogue__c
      const productCatalogue = await upsertProductCatalogue(license, parentLicense, product2, productPackage, packageExtId, productCatalogueRule, ngbsLicenseSettings, contractDiscounts);
      this.output.productCatalogues.push(productCatalogue);

      //Generate and upsert list of Product_Tier_Price__c for Product_Catalogue__c
      const priceRanges = this.featureParser(license.features);
      priceRanges.map(async (range) => {
        const productTierPrice = await upsertProductTierPrice(license.features[license.features.length - 1], currencyCode, range, license.elementID, product2, productCatalogue, packageExtId, range.monthlyPrice, range.yearlyPrice, true);
        productCatalogue.productTierPrices.push(productTierPrice);
        if (license.elementID === 'LC_DL-UNL_50' || license.elementID === 'LC_SM_405' || license.elementID === 'LC_SC_1') { //DigitalLine Unlimited special case
          this.topLevelTierPrices.push(productTierPrice);
        }
      });

      await this.licenseParser(license.licenses, productCatalogue, currencyCode, productPackage, `${packageExtId}~${license.elementID}`, null, ngbsLicenseSettings, contractDiscounts);
      await this.cboxParser(license.cboxes, productCatalogue, currencyCode, productPackage, `${packageExtId}~${license.elementID}`, ngbsLicenseSettings, contractDiscounts);
    }));
  }

  featureParser = (features) => {
    features = features ?? [];

    let allRangesPriceMaps = features.map((feature) => {
      let temp;
      let monthlyPrice;
      let yearlyPrice;

      try {
        temp = JSON.parse(feature.raterConfiguration);
      } catch (error) { }

      if (temp && temp.counterBase && temp.ranges && temp.ranges.length > 0) {
        //ranges
        const rangePriceMap = new Map();
        temp.ranges.forEach((range) => {
          if (!rangePriceMap.has(`${range.from}~${range.to}`)) {
            rangePriceMap.set(`${range.from}~${range.to}`, { from: range.from, to: range.to, monthlyPrice: 0, yearlyPrice: 0 });
            monthlyPrice = 0;
            yearlyPrice = 0;
          } else {
            monthlyPrice = rangePriceMap.get(`${range.from}~${range.to}`).monthlyPrice;
            yearlyPrice = rangePriceMap.get(`${range.from}~${range.to}`).yearlyPrice;
          }
          range.plans.forEach(plan => {
            if (plan.planDuration === 'Monthly')
              monthlyPrice += plan.price;
            else if (plan.planDuration === 'Annual')
              yearlyPrice += plan.price;
            else if (plan.planDuration === 'OneTime') {
              monthlyPrice += plan.price;
              yearlyPrice += plan.price;
            }
          });
          rangePriceMap.set(`${range.from}~${range.to}`, { from: range.from, to: range.to, monthlyPrice, yearlyPrice });
        });

        //Upsert the Product_Tier_Price__c
        return rangePriceMap;
      } else if (temp && temp.counterBase && temp.masterPlans && temp.masterPlans.length > 0) {
        //masterplans
        const plans = new Map();
        temp.masterPlans.forEach((masterPlan) => {
          masterPlan.ranges && masterPlan.ranges.forEach((range) => {
            if (plans.has(`${range.from}~${range.to}`)) {
              plans.get(`${range.from}~${range.to}`).monthlyPrice = masterPlan.masterPlanDuration === 'Annual' ? plans.get(`${range.from}~${range.to}`).monthlyPrice : range.price;
              plans.get(`${range.from}~${range.to}`).yearlyPrice = masterPlan.masterPlanDuration === 'Monthly' ? plans.get(`${range.from}~${range.to}`).yearlyPrice : range.price;
            } else {
              plans.set(`${range.from}~${range.to}`, {
                from: range.from,
                to: range.to,
                monthlyPrice: masterPlan.masterPlanDuration === 'Annual' ? 0 : range.price,
                yearlyPrice: masterPlan.masterPlanDuration === 'Monthly' ? 0 : range.price
              });
            }
          });
        });

        //Upsert the Product_Tier_Price__c
        return plans;
      } else if (temp && temp.length > 0 && temp[0].planDuration) {
        temp.forEach((element) => {
          if (element.planDuration === 'Monthly')
            monthlyPrice = element.price;
          else if (element.planDuration === 'Annual')
            yearlyPrice = element.price;
          else if (element.planDuration === 'OneTime') {
            monthlyPrice = element.price;
            yearlyPrice = element.price;
          }
        });

        const plans = new Map();
        let zeroPriceCount = 0;
        //Upsert the Product_Tier_Price__c
        if (!(monthlyPrice === 0 && yearlyPrice === 0)) {
          plans.set(`1~1`, { from: 1, to: 1, monthlyPrice, yearlyPrice });
        } else {
          zeroPriceCount++;
        }
        if (plans.size === 0 && zeroPriceCount > 0) {
          plans.set(`1~1`, { from: 1, to: 1, monthlyPrice: 0, yearlyPrice: 0 });
        }
        return plans;
      }
    });

    const finalPriceMap = new Map();
    for (let i = 0; i < allRangesPriceMaps.length; i++) {
      const tempMap = allRangesPriceMaps[i];
      if (!tempMap) {
        continue;
      }
      for (const [key, value] of tempMap.entries()) {
        if (finalPriceMap.has(key)) {
          finalPriceMap.get(key).monthlyPrice += value.monthlyPrice;
          finalPriceMap.get(key).yearlyPrice += value.yearlyPrice;
        } else {
          finalPriceMap.set(key, value);
        }
      }
    }

    if (finalPriceMap.has(`0~1`) && finalPriceMap.has(`1~1`)) {
      finalPriceMap.delete(`1~1`);
    }

    return Array.from(finalPriceMap.values());
  }

  cboxParser = async (cboxes, parentLicense, currencyCode, productPackage, packageExtId, ngbsLicenseSettings, contractDiscounts) => {
    cboxes = cboxes ?? [];
    return Promise.all(cboxes && cboxes.map(async (cbox) => {
      //Generate and upsert Product_Catalogue_Rule__c
      const productCatalogueRule = await upsertProductCatalogueRule(cbox, currencyCode, productPackage, packageExtId);
      this.output.productCatalogueRules.push(productCatalogueRule);
      await this.licenseParser(cbox.licenses, parentLicense, currencyCode, productPackage, `${packageExtId}~${cbox.elementID}`, productCatalogueRule, ngbsLicenseSettings, contractDiscounts);
      await this.cboxParser(cbox.cboxes, parentLicense, currencyCode, productPackage, `${packageExtId}~${cbox.elementID}`, ngbsLicenseSettings, contractDiscounts);
    }));
  }

  lboxParser = async (lboxes, currencyCode, productPackage, packageExtId, ngbsLicenseSettings, contractDiscounts) => {
    lboxes = lboxes ?? [];
    return Promise.all(lboxes && lboxes.map(async (lbox) => {
      //Generate and upsert Product_Catalogue_Rule__c
      const productCatalogueRule = await upsertLboxProductCatalogueRule(lbox, currencyCode, productPackage, packageExtId);
      this.output.productCatalogueRules.push(productCatalogueRule);
      //licenseParser(lbox.licenses, currencyCode, productPackage, `${packageExtId}~${lbox.elementID}`, productCatalogueRule);
    }));
  }
}