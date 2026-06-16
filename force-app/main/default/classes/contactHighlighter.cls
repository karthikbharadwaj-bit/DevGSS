/* #######################################################################################
Updates:
  By: eugenebasianomutya
  Case: 03428105 - Unsubscribe message in lead/contact banner
  Date: 06192015
######################################################################################## */

public class contactHighlighter {
    static final String strBTBrand = 'BT';
    public static final String imgPath {get {return '/resource/warning';} set;}
    public static final String imgPathRed {get { return '/resource/warningRed';} set;}
    public Contact pageContact {get{return (Contact) controller.getRecord();}}
    public ApexPages.StandardController controller;
    public String leadStatusMessage;
    public Boolean hasDomainType;
    public Boolean shouldRender;
    public Map<String, String> emailMap {get;set;}
    public DomainTypeLeadContact__C myDomainType;
    public ApexPages.Message errorMsg {get;set;}

    public contactHighlighter(ApexPages.StandardController controller){
        this.controller = controller;
        validate();
        addFields();
        emailMap = LeadHighlighter.setEmailString(pageContact.Ok_to_Email__c, pageContact.HasOptedOutOfEmail, pageContact.Account.BillingCountry);
    }

    public void validate(){
        String conId = controller.getId();
        if (String.isBlank(conId)) {
            errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL,
                                 'No contact was found for the current page.');
            Apexpages.addMessage(errorMsg);
        }
    }

    public DomainTypeLeadContact__C getMyDomainType(){
        if(myDomainType == null){
            if (String.isBlank(pageContact.Domain_Type__c)) {
                return null;
            }
            myDomainType = DomainTypeLeadContact__C.getValues(pageContact.Domain_Type__c.toLowerCase());
        }
        return myDomainType;
    }

    private void addFields(){
        if (!Test.isRunningTest()) {
            List<String> fieldsToAdd = new List<String>{'Account.RC_Brand__c', 'Ok_to_Email__c', 'Domain_Type__c',
                                                     'HasOptedOutOfEmail'};
            controller.addFields(fieldsToAdd);
        } else {
            List<Object> bindings = new List<Object>();
            bindings.add(controller.getId());
            Contact con = (Contact) new ContactSelector().selectContactById(bindings).selectField('Account.BillingCountry').executeQuery()[0];
            pageContact.Account = con.Account;
        }
    }

    public boolean getIsBTApproved(){
        return String.isNotBlank(pageContact.Account.RC_Brand__c) &&
               pageContact.Account.RC_Brand__c.trim().containsIgnoreCase(strBTBrand);
    }

    public boolean gethasDomainType(){
        if (getMyDomainType() != null) {
            return getMyDomainType().Contact__c;
        }
        return false;
    }

    public String getleadStatusMessage(){
        if(getMyDomainType() == null) {
            return null;
        }
        String formattedDomainType = ' <' +  pageContact.Domain_Type__c + '>';
        return Label.DomainTypeLeadContact1 + formattedDomainType + ': ' + Label.DomainTypeLeadContact2;
    }

    public Boolean getShouldRender(){
        return getIsBTApproved() || pageContact.HasOptedOutOfEmail || pageContact.Do_Not_Call__c
               || gethasDomainType() || emailMap != null || pageContact.Do_Not_Direct_Mail__c || pageContact.Do_Not_SMS__c 
               || pageContact.Ok_to_Email__c == 'Yes-Single' || pageContact.Ok_to_Email__c == 'Yes-Double' 
               || (pageContact.Ok_to_Email__c != NULL && pageContact.Ok_to_Email__c.contains('Implied'));
    }

}