public class GWSignUpWrapper {

	//Error Fields
    public boolean errorExists{get;set;}
    public string errorMsg{get;set;}
    public string description{get;set;}

    //Data Fields
    public boolean isRequestValid{get;set;}
    public boolean requestStatus{get;set;}

    public GWSignUpWrapper() {}

    public GWSignUpWrapper(SalesFunnelStatus__c salesFunnelStatus) {
        this.requestStatus = salesFunnelStatus.IsRequestOpen__c;
        this.description = salesFunnelStatus.IsRequestOpen__c ? 'Valid Request' : 'Request Already Processed';
        this.isRequestValid = true;
        this.errorExists = false;
    }

    public GWSignUpWrapper(String errorMessage) {
        this.errorExists = true;
        this.errorMsg = errorMessage;
        this.description = 'Error Occured';
        this.requestStatus = false;
    }
}