({
  init: function (component, event, helper) {
    try {
      document.title = "RC Partner Registration";
      var urlString = window.location.href;
      var language1 = urlString.split('=');
      component.set("v.selectedLanguageValue", language1[1]);

      helper.getTranslations(component, event, helper);
      helper.getCountryList(component, 'Partner_Request__c', 'Partner_Country__c');

    }
    catch (e) {
      console.error('error - ' + e);
    }
  },

  handleSubmitPR: function (component, event, helper) {
    event.preventDefault();
    var fields = event.getParams("fields");
    var selectedvalue = component.get("v.SelectedYesNoValue");
    fields["Partner_First_Name__c"] = component.get("v.firstname");
    fields["Ready_For_Processing__c"] = true;
    fields["Brand_Name__c"] = 'RingCentral';
    fields["Partner_Country__c"] = component.find("selectedCountry").get("v.value");
    fields["Partner_Last_Name__c"] = component.get("v.lastname");
    fields["Partner_Title__c"] = component.get("v.jobtitle");
    fields["Partner_Email_Address__c"] = component.get("v.email");
    fields["Partner_Phone__c"] = component.get("v.phone");
    fields["Partner_Phone_Accounts_Payable__c"] = component.get("v.phone");
    fields["Partner_Phone_Billing_Support__c"] = component.get("v.phone");
    fields["Partner_Company_Name__c"] = component.get("v.companyname");
    fields["Partner_Address1__c"] = component.get("v.address");
    fields["Partner_City__c"] = component.get("v.city");
    fields["Partner_Zip__c"] = component.get("v.zip");
    fields["Avaya_Partnership_Reg__c"] = true; //PBC-10146
    fields["Are_already_active_in_a_UCC_and_or_CC_br__c"] = selectedvalue;
    var selectedCountry = component.find("selectedCountry").get("v.value");
	var selectedCheckBoxValue = component.find('boxSelect').get("v.value");


    var phoneNumber = component.find("phoneNumber").get("v.value");
    var regex1 = new RegExp("^[0-9 ,+()-]*$");
    var isValidPhone = regex1.test(phoneNumber);
	
	 var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;  
 	var emailFieldValue = component.find("emailAddress").get("v.value");

    if (selectedCountry == "Country" || selectedCountry == "Land" || selectedCountry == "Pays") {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "type": "error",
        "title": "Error! ",
        "message": "Please select the Country"
      });
      toastEvent.fire();
      return false;
    }
      if (component.get("v.firstname") === null || component.get("v.firstname") =='' || component.get("v.lastname") === null || component.get("v.lastname") === '' || component.get("v.jobtitle") === null || component.get("v.jobtitle") ==='' ||  component.get("v.email") === null || component.get("v.email") ==='' || component.get("v.phone") === null || component.get("v.phone") === '' || component.get("v.companyname") === null || component.get("v.companyname") ==='' || component.get("v.address") === null || component.get("v.address") ==='' || component.get("v.city") === null  || component.get("v.city") === '' || selectedvalue == null || !selectedCheckBoxValue) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "type": "error",
        "title": "Error! ",
        "message": "Please Enter all the Fields"
      });
      toastEvent.fire();
      return false;
    }
    if (component.get("v.zip") === null || component.get("v.zip") ==='') {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "type": "error",
        "title": "Error! ",
        "message": "Please Enter the Postal Code"
      });
      toastEvent.fire();
      return false;
    }

	if(!emailFieldValue.match(regExpEmailformat)){
              var toastEvent = $A.get("e.force:showToast");
             toastEvent.setParams({
        "type": "error",
        "title": "Error! ",
        "message": "Please Enter a Valid Email Address",
      });
      toastEvent.fire();
      return false;
         }
    if (phoneNumber.length < 7 || !isValidPhone) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "type": "error",
        "title": "Error! ",
        "message": "Please Enter Only Numeric values and the Value Should be Phone minimum 7 digits"
      });
      toastEvent.fire();
      return false;
    }
    component.find('partnerRegistrationForm').submit(fields);
	 component.set("v.buttonDisbaled", true);
  },

  handleOnSuccess: function (component, event, helper) {
    helper.handleSuccess(component, event, helper);
  },

  handleOnError: function (component, event, helper) {
    const error = JSON.parse(JSON.stringify(event.getParam('error')));
    if (error && error.body && error.body.errorCode === 'NOT_FOUND') {
      //This is normal, check below link for more details
      //https://trailblazer.salesforce.com/issues_view?id=a1p3A000001GN1gQAG&title=community-guest-user-may-see-the-error-the-requested-resource-does-not-exist-while-creating-record-from-community-using-the-lightning-recordeditform
      helper.handleSuccess(component, event, helper);
    }
    else {
      const errorMessage = event.getParam("message");
      const toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "type": "error",
        "title": "Error!",
        "message": errorMessage
      });
      toastEvent.fire();
    }
  },

  onChangeLanguage: function (component, event, helper) {
    var selectedLanguageValue1 = component.find('languagePicklist').get("v.value");
    if (selectedLanguageValue1 == "de") {
      history.pushState('data to be passed', 'Title of the page', 'https://rc-portal.force.com/RCPartnerProgram/s/rcguestpartnerregform?language=de');

    }
    if (selectedLanguageValue1 == "en_US") {
      history.pushState('data to be passed', 'Title of the page', 'https://rc-portal.force.com/RCPartnerProgram/s/rcguestpartnerregform?language=en_US');

    }
    if (selectedLanguageValue1 == "fr") {
      history.pushState('data to be passed', 'Title of the page', 'https://rc-portal.force.com/RCPartnerProgram/s/rcguestpartnerregform?language=fr');
    }
    window.location.reload();
    helper.getTranslations(component, event, helper);
  },

  checkboxSelect: function (component, event, helper) {
    var selectedCheckBoxValue = component.find('boxSelect').get("v.value");
    component.set("v.termsandcondition", selectedCheckBoxValue);
  },

  itemsChange: function (component, event, helper) {
    var fields = event.getParam("fields");
    fields["Partner_First_Name__c"] = component.get("v.firstname");
  },

  showSpinner: function (component, event, helper) {
    component.set("v.Spinner", true);
  },

  hideSpinner: function (component, event, helper) {
    component.set("v.Spinner", false);
  }
})