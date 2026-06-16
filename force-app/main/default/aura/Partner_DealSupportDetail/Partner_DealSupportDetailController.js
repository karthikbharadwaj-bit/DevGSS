({
  doInit: function (component, event, helper) {
    var url = new URL(location.href);
    var baseURL = url.href.substring(0, url.href.indexOf("/s"));
    component.set('v.baseURL', baseURL);
    var urlLink = '';
    var PartnerURLLink = baseURL + '/s/partnerdetails?id=';

    component.set('v.PartnerURLLink', PartnerURLLink);
    console.log('baseURL>' + baseURL);

    var CustomerURLLink = baseURL + '/s/partnercustomers?id=';
    component.set('v.CustomerURLLink', CustomerURLLink);

    var QuoteURLLink = baseURL + '/s/quotetool?step=5&id=';
    component.set('v.QuoteURLLink', QuoteURLLink);

    var OpportunityURLLink = baseURL + '/s/partneropportunities?id=';
    component.set('v.OpportunityURLLink', OpportunityURLLink);

    var LeadURLLink = baseURL + '/s/partnerleads?id=';
    component.set('v.LeadURLLink', LeadURLLink);

    var id_str = component.get("v.recordID");
    component.set("v.ShowRecordDetail", true);
    component.set("v.ShowComponentButtons", true);
    var action = component.get("c.getDealSupportRecordList");
    action.setParams({
      "DealSupportRecordId": id_str
    });
    action.setCallback(this, function (result) {
      var resultData = result.getReturnValue();
      component.set("v.isReadOnly", resultData.isReadOnly);
      console.log('read>' + resultData.isReadOnly);
      console.log('resultData.dealSupport>>', resultData.dealSupport);
      component.set("v.DealSupportRecord", resultData.dealSupport);
      component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
      console.log('comm details>' + JSON.stringify(component.get("v.communityDetailsRecord")));
      component.set("v.TypeValueTranslation",resultData.translatedType);
      component.set("v.StatusValueTranslation",resultData.statusValueTranslated);
      //console.log('cloud field>'+component.get(communityDetailsRecord.Portal_Cloud_Specialist__c));
      if (resultData.dealSupport != null) {
        var subStatus = resultData.dealSupport.Sub_Status__c;
        var status = resultData.dealSupport.Status__c;
        if(resultData.dealSupport.Approved_Discount__c > 0 ){
          component.set("v.Discount", resultData.dealSupport.Approved_Discount__c);
        }else if(resultData.dealSupport.Approved_Discount_Amount__c > 0 ){
          component.set("v.Discount", resultData.dealSupport.Approved_Discount_Amount__c);
        }
          //BZS-4698 begins 
        component.set("v.JustificationForRejection", resultData.dealSupport.Justification_for_Rejection__c)
        //BZS-4698 ends 
        
        if (subStatus == 'RC Approved' || subStatus == 'Pending RC Approval') {
          component.set("v.DisableApproval", false);
        } else {
          component.set("v.DisableApproval", true);
        }
        if (status == 'Ready for Signature') {
          component.set("v.UploadDisabled", false);
        } else {
          component.set("v.UploadDisabled", true);
        }
        //Added for PBC-11030
        var oppcountry = resultData.dealSupport.Customer_Account__r.BillingCountry;
        console.log("oppcountry" + oppcountry);
        if (resultData.dealSupport.Customer_Account__r.BillingCountry === 'Switzerland' && resultData.dealSupport.Customer_Account__r.VATNumber__c !== "" && resultData.dealSupport.Customer_Account__r.VATNumber__c !== undefined) {
          component.set("v.isVATNumber", true);
        } else {
          component.set("v.isVATNumber", false);
        }
        console.log("isVATNumber" + component.get("v.isVATNumber"));
      }
      component.set("v.availProServ", resultData.dealSupport.Partner_ProServ__c);
      console.log("fdgdfgd" + component.get("v.availProServ"));
      console.log("fdgdfgd" + resultData.dealSupport.Partner_ProServ__c);
      component.set("v.SalesOverlayQueue", $A.get("$Label.c.Sales_Overlay_Queue"));
      component.set('v.selectedStatusValue', resultData.dealSupport.Status__c);
      component.set("v.ShowConAcc", resultData.isAvaya);
      component.set("v.isPOCQuote", resultData.isPOCQuote);
      component.set("v.ShowOnlyAvaya", resultData.isOnlyAvaya);
      console.log('ShowOnlyAvaya', +resultData.isOnlyAvaya);
      console.log('isAvaya', +resultData.isAvaya);
      component.set("v.partnerCommunity", resultData.partnerCommunityName);
      component.set("v.isSingleLogin", resultData.isSingleLogin);
      var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
      if (resultData.partnerCommunityName.includes('RingCentral')&&masterLabel == 'ignite') {
        component.set("v.ShowOnlyRC", true);
        console.log('RC true');
      }
      if (resultData.partnerCommunityName.includes('Rainbow Office')) {
        component.set("v.ShowOnlyALE", true);
        console.log('Rainbow true');
      }
        //BZS-4698 begins 
        if(resultData.partnerCommunityName.includes('Unify Office'))
        {
            component.set("v.ShowOnlyAtos", true);
            console.log('AtosTrue',"v.ShowOnlyAtos");
        }
        //BZS-4698 ends 
      helper.showAssignToRCButton(component, event, helper);

      if (resultData == undefined || resultData == '' || resultData == null) {
        component.set("v.Message", true);
        component.set('v.ShowSpinnerDeal', false);//Added for ALE safari browser issue
      }
      else {
        component.set("v.Message", false);
      }
      helper.getAttachments(component, event, helper);
      //helper.getuploadedFiles(component, event, helper);//commented for getting files uploaded from SF Lightning - starts
      helper.getAllAttachmentsForDeal(component, event, helper);//Added for getting files uploaded from SF Lightning
      helper.getuploadedFilesForLightning(component, event, helper);//Added for getting files uploaded from SF Lightning 
      helper.getuploadedFilesForLightningFromOpp(component, event, helper);//Added for opp files
      helper.getTranslations(component,event,helper);

    });

    $A.enqueueAction(action);

  },
  //Method to execute to return to list view
  goBackToViewList: function (component, event, helper) {
    component.set("v.ShowRecordDetail", false);
    component.set("v.ShowListView", true);
    component.set("v.ShowNewSection", false);
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      //'url': '/partner/s/dealsupport'
      'url': window.location.pathname
    });
    urlEvent.fire();
  },

  handleUploadFinished: function (component, event, helper) {
    var uploadedFiles = event.getParam("files");
    var documentId = uploadedFiles[0].documentId;
    component.set("v.documentId", documentId);
    var fileName = uploadedFiles[0].name;
    helper.getuploadedFiles(component);
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "type": "success",
      "title": component.get("v.translationsMap.Success")+'!',
      "message": component.get("v.translationsMap.The_file_has_been_uploaded_successfully"),
      "mode": 'dismissible'
    });
    toastEvent.fire();

  },
  previewFile: function (component, event, helper) {
    console.log('inside preview');
    var rec_id = event.currentTarget.id;
    $A.get('e.lightning:openFiles').fire({
      recordIds: [rec_id]
    });
  },

  showEditSectionAres: function (component, event, helper) {
    component.set("v.ShowEditSection", true);
  },

  assignToRC: function (component, event, helper) {
    helper.updateOwnerQueue(component, event, helper);
  },

  editDealSupport: function (component, event, helper) {
    helper.editDealSupport(component, event, helper);
  },

  cancelEditDealSupport: function (component, event, helper) {
    component.set("v.ShowEditSection", false);
  },
  changeQuoteStatus: function (component, event, helper) {
    helper.changeStatus(component, event, helper);

  },
  showSpinner: function (component, event, helper) {
    var spinner = component.find("loadingSpinner");
    $A.util.removeClass(spinner, "slds-hide");
    console.log('loading');
  },
  hideSpinner: function (component, event, helper) {
    var spinner = component.find("loadingSpinner");
    $A.util.addClass(spinner, "slds-hide");
  },
  checkedPOCConversion: function (component, event, helper) {
    helper.updateDealSupport(component, event, helper);
  },

  handleClick: function (component, event, helper) {
    var action = component.get("c.getnwatts");
    action.setParams({

    });
    action.setCallback(this, function (result) {
      var state = result.getState();
      if (state === "SUCCESS") {
        var resultData = result.getReturnValue();
      }
    });
    $A.enqueueAction(action);
  },
  assignToAvayaDealDesk: function (component, event, helper) {
    helper.assignToAvayaDealDesk(component, event, helper);
  },
  onChangeOfStatus: function (component, event, helper) {
    var selectedSupportStatus = event.getSource().get("v.value");
    var discountField = component.find("discount");
    var discountLabel = component.find("discountLabel");
    if (component.get("v.DealSupportRecord").Type__c == "Discount Request") {
      component.set("v.Discount", '');
    }
  },
  //Added meth for Jira fix as part of ACO 4.0
  redirectTOQuoteTool: function (component, event, helper) {
    var rectarget = event.currentTarget;
    var quoteRec = component.get("v.DealSupportRecord.Partner_Quote__c");
    var RecordType = component.get("v.DealSupportRecord.Partner_Quote__r.RecordType.Name");
    //To support redirecting URL for both avaya and atos
    var baseURL = component.get('v.baseURL');
    var urlLink = baseURL + '/s/quotetool?step=5&id=' + quoteRec;

    if (RecordType != 'Change Order Request') {
      var urlEvent = $A.get("e.force:navigateToURL");
      urlEvent.setParams({
        'url': urlLink
      });
      urlEvent.fire();
    }
    else {
      var quoteStatus = component.get("v.DealSupportRecord.Partner_Quote__r.Status__c");
      var oppId = component.get("v.DealSupportRecord.Opportunity__c");
      if (quoteStatus == 'Pending Order') {
        component.set("v.isChangeOrderSubmitted", true);
      } else {
        component.set("v.isChangeOrderSubmitted", false);
      }
      component.set("v.changeOrderId", quoteRec);
      component.set("v.ExistingChangeOrder", true);
      component.set("v.showChangeRequestCMP", true);
      component.set("v.oppID", oppId);
    }
  },
    //BZS-4698 begins
    rejectionJustification: function(component, event, helper) {
        helper.rejectionJustificationBox(component, event, helper);
    },
    
    hideModel: function(component, event, helper) {
        component.set("v.showModal", false);
    },
    //BZS-4698 ends
})