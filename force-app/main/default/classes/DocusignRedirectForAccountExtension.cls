public with sharing class DocusignRedirectForAccountExtension {
    public Id accId {get;set;}
    public String errorMessage {get;set;}

    public DocusignRedirectForAccountExtension(ApexPages.StandardController accountController) {
        accId = ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference redirect() {
        Account acc = (Account) new AccountSelector().selectAccountById(accId)
            .executeQuery()
            .get(0);

        if (AccountHelper.isInvoiceOnBehalfAccount(acc)) {
            errorMessage = 'DocuSign flow is disabled for Invoice On Behalf Accounts';
            return null;
        }
        if (AccountHelper.isWholesaleAccount(acc)) {
            errorMessage = 'DocuSign flow is disabled for Wholesale Accounts';
            return null;
        }

        List<AccountContactRole> roles = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectSignatoryContactRolesByForAccount(new List<Object> {accId})
            .executeQuery();

        String url = '/apex/dsfs__DocuSign_CreateEnvelope?DSEID=0&SourceID=' + accId;
        if (roles.size() > 0) {
            url += '&CRL=';

            for (AccountContactRole role : roles) {
                url += 'Email~' + role.Contact.Email 
                    + ';FirstName~' + role.Contact.FirstName 
                    + ';LastName~' + role.Contact.LastName + ',';
            }
            url = url.substring(0, url.length() - 1);
        }

        PageReference redirect = new PageReference(url);
        redirect.setRedirect(true);
        return redirect;
    }
}