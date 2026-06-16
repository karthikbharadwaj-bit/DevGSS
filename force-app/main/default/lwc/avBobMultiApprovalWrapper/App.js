export class App {
    approvals = {};
    accounts = [];
    accountLimits = [];

    LABELS = {
        error: 'Error'
    };

    ERROR_MESSAGES = {
        REQUIRED_FIELD: 'Complete this field.'
    };

    addAccount(detail) {
        let account = {'Id': detail.defaultFieldValues.Account__c};
        const partnerFields = {
            'id': 'Partner_Account__c',
            'name': 'Partner_Account_Name__c',
            'partnerId': 'Partner_ID__c',
            'partnerType': 'Partner_Type__c',
            'ultimatePartnerName': 'Ultimate_Partner_Name__c',
        };

        Object.keys(partnerFields).forEach(key => {
            account = {
                ...account,
                ...{
                    [partnerFields[key]]: detail.accountPartner && detail.accountPartner[key]
                }
            }
        });

        this.accounts.push(account);
    }

    addApprovalFieldData(approvalGuid, field) {
        this.approvals = {
            ...this.approvals,
            ...{
                [approvalGuid]: {
                    fields: {
                        ...this.approvals[approvalGuid]?.fields,
                        ...{
                            [field.id]: {
                                name: field.name,
                                label: field.label,
                                isRequired: field.isRequired,
                                isValid: field.isValid
                            }
                        }
                    },
                    SFDCApproval: {
                        ...this.approvals[approvalGuid]?.SFDCApproval,
                        ...{[field.name]: field.value}}
                }
            }
        };
    }

    updateField(approvalId, fieldId, value) {
        if (approvalId && fieldId) {
            const fieldName = this.approvals[approvalId].fields[fieldId].name;
            this.approvals[approvalId].SFDCApproval[fieldName] = value;
        }
    }

    updateFieldValidity(approvalId, fieldId, isValid) {
        if (approvalId && fieldId) {
            this.approvals[approvalId].fields[fieldId].isValid = isValid;
        }
    }

    getApprovalsInSFDSFormat() {
        let SFDCApprovals = [];
        Object.values(this.approvals).forEach(item => {
            SFDCApprovals.push(item.SFDCApproval);
        });
        return SFDCApprovals;
    }

    getMonthlyCreditLimitsForAccounts() {
        let accMonthlyCreditLimits = {};
        Object.keys(this.accountLimits).forEach(accId => {
            accMonthlyCreditLimits = {
                ...accMonthlyCreditLimits,
                ...{
                    [accId]: window.app.accountLimits[accId]?.Monthly_Credit_Limit__c
                }
            };
        });
        return accMonthlyCreditLimits;
    }
}