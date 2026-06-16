import getV2ProductPackageRecordTypeId from '@salesforce/apex/PRM_Package_Creator_Helper.getV2ProductPackageRecordTypeId';
import upsertProductPackageApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductPackageApex';
import upsertProduct2Apex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProduct2Apex';
import upsertProductCatalogueApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductCatalogueApex';
import upsertProductTierPriceApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductTierPriceApex';
import upsertProductCatalogueRuleApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertProductCatalogueRuleApex';
import upsertWholesalePartnerPackageApex from '@salesforce/apex/PRM_Package_Creator_Helper.upsertWholesalePartnerPackageApex';

import categoryOverrideMapping from './categoryOverrideMapping';
import cboxOverrideMapping from './cboxOverrideMapping';

const upsertProductPackage = async (pkg, isV2Package = false) => {
  const productPackageRequest = {
    RecordTypeId: isV2Package ? await getV2ProductPackageRecordTypeId({}) : null,
    Name: `${pkg.id}.${pkg.version}-${pkg.edition && pkg.edition.name ? pkg.edition.name : pkg.displayName}-${pkg.currency}`,
    Product_Categories__c: 'Service;Phones;Add-Ons;Bundles;International;Conferencing',
    CurrencyIsoCode: pkg.currency,
    Description__c: pkg.displayName,
    Brand_Name__c: pkg.labels.Brand && pkg.labels.Brand.length > 0 ? pkg.labels.Brand[0] : '',
    SIGNUP_ECOM__c: pkg.labels.SIGNUP_SFDCVAR && pkg.labels.SIGNUP_SFDCVAR.length > 0 ? pkg.labels.SIGNUP_SFDCVAR[0] === 'Active' : true,
    SIGNUP_SFDC__c: pkg.labels.SIGNUP_SFDC && pkg.labels.SIGNUP_SFDC.length > 0 ? pkg.labels.SIGNUP_SFDC[0] === 'Active' : true,
    Display_Name__c: `${pkg.id}.${pkg.version}-${pkg.displayName}-${pkg.currency}`,
    Ext_Element_Id__c: `${pkg.id}${isV2Package ? '|' : '~'}${pkg.version}`,
    Status__c: pkg.status,
    Offer_Type__c: pkg.offerType,
    Prod_Family__c: pkg.productName,
    Monthly_Packgage_Info__c: isV2Package ? null : `Wholesale`,
    Package_Edition__c: pkg.edition && pkg.edition.name ? pkg.edition.name : ''
  };
  if (!productPackageRequest.RecordTypeId) {
    delete productPackageRequest.RecordTypeId;
  }
  const Id = await upsertProductPackageApex({ pkg: productPackageRequest });
  return { ...productPackageRequest, Id, productCatalogues: [], productCatalogueRules: [] };
}

const upsertPartnerProductPackage = async (pkg, wholesalePkg) => {
  const productPackageRequest = {
    Name: wholesalePkg.displayName,
    CurrencyIsoCode: pkg.currency,
    Description__c: `Wholesale - ${wholesalePkg.displayName}`,
    Brand_Name__c: pkg.labels.Brand && pkg.labels.Brand.length > 0 ? pkg.labels.Brand[0] : '',
    SIGNUP_ECOM__c: pkg.labels.SIGNUP_SFDCVAR && pkg.labels.SIGNUP_SFDCVAR.length > 0 ? pkg.labels.SIGNUP_SFDCVAR[0] === 'Active' : true,
    SIGNUP_SFDC__c: pkg.labels.SIGNUP_SFDC && pkg.labels.SIGNUP_SFDC.length > 0 ? pkg.labels.SIGNUP_SFDC[0] === 'Active' : true,
    Display_Name__c: `${wholesalePkg.displayName} v${wholesalePkg.version}`,
    Ext_Element_Id__c: `${pkg.id}~${pkg.version}~${wholesalePkg.id}~${wholesalePkg.version}`,
    Status__c: wholesalePkg.status,
    Offer_Type__c: pkg.offerType,
    Prod_Family__c: pkg.productName,
    Monthly_Packgage_Info__c: 'Wholesale',
    Package_Edition__c: pkg.edition && pkg.edition.name ? pkg.edition.name : ''
  };
  const Id = await upsertProductPackageApex({ pkg: productPackageRequest });
  return {
    ...productPackageRequest,
    Id,
    Start_Date__c: wholesalePkg.salesStartDate ? wholesalePkg.salesStartDate.replace('[UTC]', '') : null,
    End_Date__c: wholesalePkg.salesEndDate ? wholesalePkg.salesEndDate.replace('[UTC]', '') : null,
    productCatalogues: [], productCatalogueRules: []
  };
}

const upsertProduct2 = async (license) => {
  const product2Request = {
    Name: license.name,
    ProductCode: license.elementID,
    Description: license.name,
    ExtID__c: license.elementID,
    GOA_Group__c: license.labels.GOA && license.labels.GOA.length > 0 ? JSON.parse(license.labels.GOA[0]).contracted : ""
  };
  const Id = await upsertProduct2Apex({ product: product2Request });
  return { ...product2Request, Id };
}

const upsertProductCatalogue = async (license, parentLicense, product2, productPackage, packageExtId, productCatalogueRule, ngbsLicenseSettings, contractDiscounts) => {
  const selectedCategoryItem = (license.category && license.category.name) ? categoryOverrideMapping.filter(x => x.Category.toLowerCase() === license.category.name.toLowerCase()) : null;

  const Category_Name__c = (license.elementID === 'LC_VF_42' || license.elementID === 'LC_T800F_41') ? 'Add-Ons' : ((selectedCategoryItem && selectedCategoryItem.length > 0) ? selectedCategoryItem[0].Category_Name__c : '');
  const Sub_Category_Name__c = (license.elementID === 'LC_VF_42' || license.elementID === 'LC_T800F_41') ? 'Additional Numbers' : ((selectedCategoryItem && selectedCategoryItem.length > 0) ? selectedCategoryItem[0].Sub_Category_Name__c : '');
  const Package_Product_Type__c = (license.elementID === 'LC_VF_42' || license.elementID === 'LC_T800F_41') ? 'Normal' : ((selectedCategoryItem && selectedCategoryItem.length > 0) ? selectedCategoryItem[0].Package_Product_Type__c : '');
  let Active__c = (selectedCategoryItem && selectedCategoryItem.length > 0) ? selectedCategoryItem[0].Active__c : false;
  const Default_Quantity__c = (selectedCategoryItem && selectedCategoryItem.length > 0) ? ((selectedCategoryItem[0].Default_Quantity__c || selectedCategoryItem[0].Default_Quantity__c === null) ? selectedCategoryItem[0].Default_Quantity__c : license.max) : license.max;

  //Check if license should be hidden
  Active__c = ngbsLicenseSettings
    .filter(x => x.IsHidden__c)
    .filter(x => x.LicenseElementId__c)
    .filter(x => x.AffectedPackage__c === undefined || x.AffectedPackage__c === null || x.AffectedPackage__c === 'All' || x.AffectedPackage__c.indexOf(productPackage.Ext_Element_Id__c.split(/\s?(~|\|)\s?/)[0]) > -1)
    .filter(x => x.LicenseElementId__c.indexOf(license.elementID) > -1)
    .length === 0;

  //Disable these two redundant licenses
  if (license.elementID === 'LC_VF_399' || license.elementID === 'LC_T800F_400') {
    Active__c = false;
  }

  //Check activated product whether it's expired or not started yet
  if (Active__c) {
    Active__c = (license.salesEndDate ? new Date(license.salesEndDate.split('[')[0]) > new Date() : true) && (license.salesStartDate ? new Date(license.salesStartDate.split('[')[0]) < new Date() : true);
  }

  let selectedContractDiscount = contractDiscounts
    .filter(x => x.ApplicableTo__c === license.elementID)
    .filter(x => x.Contract__r && x.Contract__r.Available_in_packages__c.indexOf(productPackage.Ext_Element_Id__c.split(/\s?(~|\|)\s?/)[0]) > -1);
  if (selectedContractDiscount.length > 1) {
    console.warn(selectedContractDiscount);
  }
  let Contract_Discount__c = selectedContractDiscount.length > 0 ? selectedContractDiscount[0].Discount__c ?? 0 : 0;

  const productCatalogueRequest = {
    Product__c: product2.Id,
    Parent__c: parentLicense ? parentLicense.Id : null,
    Element_ID__c: license.elementID,
    Product_Package__c: productPackage.Id,
    Type__c: productCatalogueRule ? 'Sub License' : 'License',
    Has_child__c: (license.licenses && license.licenses.length > 0) || (license.cboxes && license.cboxes.length > 0),
    Product_Other_Name__c: license.name,
    Active__c,
    Category_Name__c,
    Sub_Category_Name__c,
    Package_Product_Type__c,
    Default_Quantity__c,
    Contract_Discount__c,
    Discount_Limit__c: (productPackage.Brand_Name__c === 'Avaya Cloud Office') ? 30 : 15,
    Plan__c: license.billingType === 'Recurring' ? 'Monthly' : 'One - Time',
    CBOX_Name__c: productCatalogueRule ? productCatalogueRule.Name : null,
    ExtId__c: `${packageExtId}~${license.elementID}`,
    Product_Catalogue_Rule__c: productCatalogueRule ? productCatalogueRule.Id : null,
    Display_Name__c: license.displayName,
    Row_Order__c: license.order < 100000 ? license.order : Math.round(license.order / 10),
    Output_Sort_Order__c: license.order < 100000 ? license.order : Math.round(license.order / 10)
  };
  const Id = await upsertProductCatalogueApex({ productCatalogue: productCatalogueRequest });
  return { ...productCatalogueRequest, Id, productTierPrices: [] };
}

const upsertProductTierPrice = async (feature, currencyCode, range, licenseElementId, product2, productCatalogue, packageExtId, isCounterBase = false) => {
  const productTierPriceRequest = {
    CurrencyIsoCode: currencyCode,
    Feature_Name__c: feature.name,
    Feature_Type__c: feature.type && feature.type.name ? feature.type.name : '',
    Monthly_Price__c: range.monthlyPrice,
    Yearly_Price__c: range.yearlyPrice,
    Product_Catalogue__c: productCatalogue.Id,
    Display_Order__c: feature.order,
    Product__c: product2.Id,
    Tax_Category__c: feature.taxCategory,
    ExtID__c: `${packageExtId}~${licenseElementId}~${feature.id}~${isCounterBase ? range.from : 1}`,
    Product_Line__c: feature.productLine && feature.productLine.name,
    From_Value__c: isCounterBase ? range.from : 1,
    To_Value__c: isCounterBase ? range.to : 1,
    No_of_Licenses__c: isCounterBase ? range.to : 1,
  }
  const Id = await upsertProductTierPriceApex({ productTierPrice: productTierPriceRequest });
  return { ...productTierPriceRequest, Id };
}

const upsertProductCatalogueRule = async (cbox, currencyCode, productPackage, packageExtId) => {
  const cboxRuleArray = cbox.ruleValues.filter((x) => !(x.type === 'LU' && cbox.elementID === 'CB_30')); //Exclusion rule
  const productCatalogueRuleRequest = {
    Name: cbox.elementID,
    Show_Header__c: true,
    Header_Text__c: cboxOverrideMapping[cbox.elementID] ? (cboxOverrideMapping[cbox.elementID].Title__c ? cboxOverrideMapping[cbox.elementID].Title__c : cbox.name) : cbox.name,
    CurrencyIsoCode: currencyCode,
    Cbox_Value__c: cboxRuleArray.length > 0 ? cboxRuleArray[0].value : '',
    Rule__c: cboxOverrideMapping[cbox.elementID] ? cboxOverrideMapping[cbox.elementID].Rule__c : (cboxRuleArray.length > 0 ? cboxRuleArray[0].type : null),
    Rule_Type__c: cboxOverrideMapping[cbox.elementID] ? cboxOverrideMapping[cbox.elementID].Rule_Type__c : null,
    Title__c: cboxOverrideMapping[cbox.elementID] ? (cboxOverrideMapping[cbox.elementID].Title__c ? cboxOverrideMapping[cbox.elementID].Title__c : cbox.name) : cbox.name,
    ExtID__c: `${packageExtId}~${cbox.elementID}`,
    Sort_Order__c: cbox.order,
    Product_Package__c: productPackage.Id
  };
  const Id = await upsertProductCatalogueRuleApex({ productCatalogueRule: productCatalogueRuleRequest });
  return { ...productCatalogueRuleRequest, Id };
}

const upsertLboxProductCatalogueRule = async (lbox, currencyCode, productPackage, packageExtId) => {
  const productCatalogueRuleRequest = {
    Name: lbox.elementID,
    Show_Header__c: true,
    Header_Text__c: lbox.name,
    CurrencyIsoCode: currencyCode,
    Max_Range__c: lbox.max,
    Min_Range__c: lbox.min,
    Title__c: lbox.name,
    ExtID__c: `${packageExtId}~${lbox.elementID}`,
    Product_Package__c: productPackage.Id
  };
  const Id = await upsertProductCatalogueRuleApex({ productCatalogueRule: productCatalogueRuleRequest });
  return { ...productCatalogueRuleRequest, Id };
}

const upsertWholesalePartnerPackageLink = async (acc, partnerPackage, parentPackageId) => {
  const wholesalePartnerPackageLinkRequest = {
    Wholesale_Partner_Account__c: acc.Id,
    Product_Package__c: partnerPackage.Id,
    Parent_Product_Package__c: parentPackageId,
    ExtID__c: `${acc.NGBS_Partner_ID__c}-${partnerPackage.Ext_Element_Id__c}`,
    Name: `${acc.Name} <-> ${partnerPackage.Display_Name__c}`,
    Start_Date__c: partnerPackage.Start_Date__c ? partnerPackage.Start_Date__c.replace('Z', ':00Z') : null,
    End_Date__c: partnerPackage.End_Date__c ? partnerPackage.End_Date__c.replace('Z', ':00Z') : null,
  };
  const Id = await upsertWholesalePartnerPackageApex({ wholesalePartnerPackage: wholesalePartnerPackageLinkRequest });
  return { ...wholesalePartnerPackageLinkRequest, Id };
}

export {
  upsertProductPackage,
  upsertPartnerProductPackage,
  upsertProduct2,
  upsertProductCatalogue,
  upsertProductTierPrice,
  upsertProductCatalogueRule,
  upsertLboxProductCatalogueRule,
  upsertWholesalePartnerPackageLink
}