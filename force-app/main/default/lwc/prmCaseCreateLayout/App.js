export class App {
    cases = {};

    LABELS = {
        error: 'Error',
        fieldLabels: {
            'AccountId': 'Account Name',
            'OwnerId': 'Case Owner',
            'RecordTypeId': 'Case Record Type',
            'SuppliedEmail': 'Web Email',
            'ContactId': 'Contact Name'
        }
    };

    ERROR_MESSAGES = {
        REQUIRED_FIELD: 'Complete this field.'
    };

    addCaseFieldData(caseGuid, field) {
        this.cases = {
            ...this.cases,
            ...{
                [caseGuid]: {
                    fields: {
                        ...this.cases[caseGuid]?.fields,
                        ...{
                            [field.id]: {
                                name: field.name,
                                label: field.label,
                                isRequired: field.isRequired,
                                isValid: field.isValid
                            }
                        }
                    },
                    sfdcCases: {
                        ...this.cases[caseGuid]?.sfdcCases,
                        ...{[field.name]: field.value}}
                }
            }
        };
    }

    updateField(caseId, fieldId, value) {
        if (caseId && fieldId) {
            const fieldName = this.cases[caseId].fields[fieldId].name;
            this.cases[caseId].sfdcCases[fieldName] = value;
        }
    }

    updateFieldValidity(caseId, fieldId, isValid) {
        if (caseId && fieldId) {
            this.cases[caseId].fields[fieldId].isValid = isValid;
        }
    }

    getCasesInSFDSFormat() {
        let sfdcCases = [];
        Object.values(this.cases).forEach(item => {
            sfdcCases.push(item.sfdcCases);
        });
        return sfdcCases;
    }
}