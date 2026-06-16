/* Individual setup for environment - check values! */
var BUTTON_ID_US_Team_All = "5733400000000jC";

/* General setup - same for every environment */
var IS_FIRST_CALL = 'true'; // go to sales bucket for not first call
window._snapinsSnippetSettingsFile = (function() {

    // test SalesAgentsOffline event	  
    /*document.addEventListener('SalesAgentsOffline', function(event) {
          console.log('SalesAgentsOffline'
              + '; firstname:' + event.detail.firstName
              + '; lastName:' + event.detail.lastName				
              + '; email:' + event.detail.email				
              + '; phone:' + event.detail.phone	
              + '; company:' + event.detail.company
              + '; NumberOfEmployees__c:' + event.detail.NumberOfEmployees__c					
          );             
    }, false);*/

  // reset first call
  document.querySelector('.embeddedServiceHelpButton .flatButton').addEventListener('click', function() {
      IS_FIRST_CALL = 'true';	// reset to first call
  }, false);
  
  embedded_svc.snippetSettingsFile.directToButtonRouting = function (prechatFormData) {
      var chatType = prechatFormData.find(function (d) {
          return d.name === 'Original_SFDC_Source__c';
      }).value;
      var partsArray = chatType.split('-');
      if(IS_FIRST_CALL == 'false' && partsArray[0] == 'sales') { // if not a first sales call - go to sales bucket
          return BUTTON_ID_US_Team_All;
      }
          
      IS_FIRST_CALL = 'false';
      return partsArray[1];	
  };
  
  /* General mappings for the contact */
  embedded_svc.snippetSettingsFile.extraPrechatInfo = [{
      "entityFieldMaps": [{
          "doCreate": true,
          "doFind": false,
          "fieldName": "LastName",
          "label": "Last Name"
      }, {
          "doCreate": true,
          "doFind": false,
          "fieldName": "FirstName",
          "label": "First Name"
      }, {
          "doCreate": true,
          "doFind": false,
          "fieldName": "Phone",
          "label": "Phone"
      }, {
          "doCreate": true,
          "doFind": false,
          "fieldName": "Company__c",
          "label": "Company"
      }, {
          "doCreate": true,
          "doFind": true,
          "fieldName": "Email",
          "isExactMatch": false,
          "label": "Email"
      }],
      "entityName": "Contact",
      "showOnCreate": true,
      "saveToTranscript": "ContactId"
  }];

  /* Extra mappings for the transcript save of the contact fields */
  embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [{
      "label": "First Name",
      "transcriptFields": ["PreChat_Firstname__c"]
  }, {
      "label": "Last Name",
      "transcriptFields": ["PreChat_Lastname__c"]
  }, {
      "label": "Email",
      "transcriptFields": ["PreChat_Email__c"]
  }, {
      "label": "Phone",
      "transcriptFields": ["PreChat_Phone__c"]
  }, {
      "label": "Company",
      "transcriptFields": ["PreChat_Company__c"]
  }, {
      "label": "No. of Employees (Range)",
      "transcriptFields": ["PreChat_Number_of_Employees__c"]
  }, {
      "label": "Logged In Contact Id",
      "transcriptFields": ["Logged_In_Contact_Id__c"]
  }, {
      "label": "Site",
      "transcriptFields": ["Site__c"]
  }];
  
  console.log("Snippet settings file loaded."); // Logs that the snippet settings file was loaded successfully
})();
