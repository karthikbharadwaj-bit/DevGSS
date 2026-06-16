public class D_B_Credit_CheckObj {

    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    public static final List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    public static final String FINANCEQUEUE = 'Billing_Credit_Check';
    public static final String INVOICETEMPLATENAME = 'Invoice_Group_Request_DNB';
    private static User dnbiUser = null;
    public static User getDnbiUser() {
        if (dnbiUser == null) {
            dnbiUser = [SELECT Id,Name FROM User WHERE Name = :Label.D_B_Credit_Check_User];
        }
        return dnbiUser;
    }

    public string getInvoiceEmailRow (String label, String value) {
        String tableRow = '<tr>'
                            + '<td>'
                                + '<font style="color: rgb(0, 105, 162);">' + (label != null ? label : '') + '</font>'
                            + '</td>'
                            + '<td>' + (value != null ? value : '') + '</td>'
                        + '</tr>';
        return tableRow;
    }

    public void approveDNBStep (D_B_Credit_Check__c dnbRecord, List<ProcessInstanceWorkitem> approvalSteps) {
        if (approvalSteps != null) {
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            for (ProcessInstanceWorkitem workItem : approvalSteps) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (dnbRecord.D_B_Status__c == D_B_Credit_CheckTriggerHandler.DNBI_APPROVED &&
                    workItem.ProcessInstance.TargetObjectId == dnbRecord.Approval__c) {
                   req.setAction('Approve');
                   req.setComments('Approved based on D&B Status.');
                   req.setWorkitemId(workItem.Id);
                   requests.add(req);
                }
            }
            Approval.ProcessResult[] processResults = Approval.process(requests, false);
        }
    }
    public void rejectDNBStep (D_B_Credit_Check__c dnbRecord, List<ProcessInstanceWorkitem> approvalSteps) {
        if (approvalSteps != null) {
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            for (ProcessInstanceWorkitem workItem : approvalSteps) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (dnbRecord.D_B_Status__c == D_B_Credit_CheckTriggerHandler.DNBI_DECLINED &&
                    workItem.ProcessInstance.TargetObjectId == dnbRecord.Approval__c) {
                    req.setAction('Reject');
                    req.setComments('Rejected based on D&B Status.');
                    req.setWorkitemId(workItem.Id);
                    requests.add(req);
                }
            }
            Approval.ProcessResult[] processResults = Approval.process(requests, false);
        }
    }
    public void dnbStatusPendingEmail (List<D_B_Credit_Check__c> dnbCreditChecks) {

        Set<Id> creditCheckApprovalIds = new Set<Id>();
        List<Approval__c> approvalsToUpdate = new List<Approval__c>();

        for (D_B_Credit_Check__c creditCheck : dnbCreditChecks) {
            if (creditCheck.D_B_Status__c != null &&
                creditCheck.D_B_Status__c == D_B_Credit_CheckTriggerHandler.DNBI_FURTHER_REVIEW) {
                creditCheckApprovalIds.add(creditCheck.Approval__c);
            }
        }

        List<Approval__c> relatedApprovalsInfo = getApprovalList(creditCheckApprovalIds);

        for (Approval__c relatedApproval : relatedApprovalsInfo) {
            relatedApproval.DNBIBatchShouldRun__c = true;
            approvalsToUpdate.add(relatedApproval);
        }
        if (!approvalsToUpdate.isEmpty()) {
            Triggers.switchOff();
            update approvalsToUpdate;
            Triggers.switchOn();
        }

        dnbEmailBuilding(relatedApprovalsInfo);

        if (!mails.isEmpty()) {
            try {
                Messaging.sendEmail(mails);
            } catch (EmailException ex) {
                for (D_B_Credit_Check__c creditCheck : dnbCreditChecks) {
                    creditCheck.addError('You can\'t send Emails. Please contact your administrator' + ex);
                }
            }
        }
    }

    public List<Approval__c> getApprovalList(Set<Id> relatedApprovals) {
        List<Approval__c> queryResult = new List<Approval__c>();
        if (relatedApprovals.isEmpty()) {
            return queryResult;
        }
        List<Object> bindings = new List<Object>();
        bindings.add(relatedApprovals);
        ApprovalSelector getApprovalInfo = new ApprovalSelector();
        queryResult.addAll((List<Approval__c>) getApprovalInfo
                                                   .selectApprovalForDNBi(bindings)
                                                   .executeQuery());
        return queryResult;
    }

    public void dnbEmailBuilding(List<Approval__c> approvalList) {
        List<Id> emails = new List<String>();
        List<User> treasuryCreditCheckGroup = ApprovalHelperCls.findQueueUsers(FINANCEQUEUE);
        if (!treasuryCreditCheckGroup.isEmpty()) {
            for (User emailRecipient : treasuryCreditCheckGroup) {
                emails.add(emailRecipient.Id);
            }
        }

        for (Approval__c relatedApproval : approvalList) {
            if(relatedApproval.RecordTypeId == ApprovalHelperCls.RT_ID_INVOICING_REQUEST) {
                dnbEmailForInvoice(emails, relatedApproval);
            }
            if(ApprovalHelper.isApprovalOfPartnerType(relatedApproval)) {
                dnbEmailForPartnerApproval(emails, relatedApproval);
            }
        }
    }

    public void dnbEmailForInvoice(List<Id> emails, Approval__c relatedApproval) {
        EmailTemplate dbPendingMail = ApprovalTriggerHandler.getEmailTemplate('Invoice_Group_Request_DNB');
        ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(emails,
            dbPendingMail.Subject, dbPendingMail.HtmlValue);

        mail.addParameter('Approval__c.Opportunity__r.Name', relatedApproval.Opportunity__r.Name);
        mail.addParameter('Approval__c.OwnerName', relatedApproval.Owner.Name);
        mail.addParameter('Approval__c.AccountLink', BASE_URL + '/' + relatedApproval.Account__c);
        mail.addParameter('Approval__c.Account__c', relatedApproval.Account__r.Name);
        mail.addParameter('Approval__c.OpportunityLink', BASE_URL + '/' + relatedApproval.Opportunity__c);
        mail.addParameter('Approval__c.Opportunity__c', relatedApproval.Opportunity__r.Name);
        mail.addParameter('Approval__c.CurrencyIsoCode', relatedApproval.CurrencyIsoCode);
        mail.addParameter('Approval__c.Sign_Up_Purchase_Limit__c', relatedApproval.Sign_Up_Purchase_Limit__c);
        mail.addParameter('Approval__c.Monthly_Credit_Limit__c', relatedApproval.Monthly_Credit_Limit__c);
        mail.addParameter('Approval__c.Reason_Customer_is_Requesting_Invoicing__c', relatedApproval.Reason_Customer_is_Requesting_Invoicing__c);
        mail.addParameter('Approval__c.Why_RingCentral_Should_Invoice_Customer__c', relatedApproval.Why_RingCentral_Should_Invoice_Customer__c);
        mail.addParameter('Approval__c.Legal_Company_Name_Head_Office__c', relatedApproval.Legal_Company_Name_Head_Office__c);
        mail.addParameter('Approval__c.Legal_Physical_Address_Street__c', relatedApproval.Legal_Physical_Address_Street__c);
        mail.addParameter('Approval__c.Legal_Physical_Address_City__c', relatedApproval.Legal_Physical_Address_City__c);
        mail.addParameter('Approval__c.Legal_Physical_Address_State_Province__c', relatedApproval.Legal_Physical_Address_State_Province__c);
        mail.addParameter('Approval__c.Legal_Physical_Address_Country__c', relatedApproval.Legal_Physical_Address_Country__c);
        mail.addParameter('Approval__c.Legal_Physical_Address_Zip_Code__c', relatedApproval.Legal_Physical_Address_Zip_Code__c);
        mail.addParameter('Approval__c.Billing_Address__c', relatedApproval.Billing_Address__c);
        mail.addParameter('Approval__c.Company_Phone_Number__c', relatedApproval.Company_Phone_Number__c);
        mail.addParameter('Approval__c.Company_DUNS_Number__c', relatedApproval.Company_DUNS_Number__c);
        mail.addParameter('Approval__c.Company_Website__c', relatedApproval.Company_Website__c);
        mail.addParameter('Approval__c.Initial_Number_of_Users__c', relatedApproval.Initial_Number_of_Users__c);
        mail.addParameter('Approval__c.Initial_Number_of_Devices__c', relatedApproval.Initial_Number_of_Devices__c);
        mail.addParameter('Approval__c.Price_per_User__c', relatedApproval.Price_per_User__c != null ? relatedApproval.Price_per_User__c : 0);
        mail.addParameter('Approval__c.Invoice_Terms__c', relatedApproval.Invoice_Terms__c);
        mail.addParameter('Approval__c.Payment_Terms__c', relatedApproval.Payment_Terms__c);
        mail.addParameter('Approval__c.Potential_Users__c', relatedApproval.Potential_Users__c);
        mail.addParameter('ApprovalRequest.External_URL', BASE_URL + '/' + relatedApproval.Id);
        mail.addParameter('Action', 'Approved');

        if (relatedApproval.Account__r.Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE) {
            // getInvoiceEmailRow
            mail.addParameter(
                'ApprovedInvoiceTerms',
                getInvoiceEmailRow('Already Approved Invoice Terms', relatedApproval.Account__r.Invoice_Terms__c)
            );
            mail.addParameter(
                'ApprovedSingUpPurchaseLimit',
                getInvoiceEmailRow(
                    'Already Approved Sign-Up Purchase Limit',
                    relatedApproval.CurrencyIsoCode + ' ' + relatedApproval.Account__r.Sign_up_Purchase_Limit__c
                )
            );
            mail.addParameter(
                'ApprovedPaymentTerms',
                getInvoiceEmailRow('Already Approved Payment Terms', relatedApproval.Account__r.Payment_Terms__c)
            );
            mail.addParameter(
                'ApprovedMonthlyCreditLimit',
                getInvoiceEmailRow(
                    'Already Approved Monthly Credit Limit',
                    relatedApproval.CurrencyIsoCode + ' ' + relatedApproval.Account__r.Monthly_Credit_Limit__c
                )
            );
            mail.addParameter('Requested', 'Requested ');
        } else {
            mail.addParameter('ApprovedInvoiceTerms', '');
            mail.addParameter('ApprovedSingUpPurchaseLimit', '');
            mail.addParameter('ApprovedPaymentTerms', '');
            mail.addParameter('ApprovedMonthlyCreditLimit', '');
            mail.addParameter('Requested', '');
        }
        mails.addAll(mail.getMails());
    }

    public void dnbEmailForPartnerApproval(List<Id> emails, Approval__c relatedApproval) {
        EmailTemplate dbPendingMail = ApprovalHelper.isBillOnBehalfApproval(relatedApproval) ?
                                        ApprovalTriggerHandler.getEmailTemplate('Bill_On_Behalf_DNB') :
                                        ApprovalTriggerHandler.getEmailTemplate('Wholesale_DNB');
        ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(emails,
            dbPendingMail.Subject, dbPendingMail.HtmlValue);

        mail.addParameter('Approval__c.Account__r.Partner_ID__c', relatedApproval.Account__r.Partner_ID__c);
        mail.addParameter('Approval__c.Account__r.Partner_Account_Name__c', relatedApproval.Account__r.Partner_Account_Name__c);
        mail.addParameter('Approval__c.Owner.name', relatedApproval.Owner.name);
        mail.addParameter('Approval__c.Partner_MRR__c', relatedApproval.Partner_MRR__c);
        mail.addParameter('Approval__c.Partner_Type__c', relatedApproval.Partner_Type__c);
        mail.addParameter('Approval__c.Brands_Permitted_to_Sell__c', relatedApproval.Brands_Permitted_to_Sell__c);
        mail.addParameter('Approval__c.VAR_Territory__c', relatedApproval.VAR_Territory__c);
        mail.addParameter('Approval__c.External_URL', BASE_URL + '/' + relatedApproval.Id);
        mails.addAll(mail.getMails());
    }

}