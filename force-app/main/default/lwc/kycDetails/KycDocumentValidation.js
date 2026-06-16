export class KycDocumentValidation {
    constructor(isDocumentNoValid, isDateOfIssueValid, isPlaceOfIssueValid, isIssuingAuthorityValid) {
        this.isDocumentNoValid = isDocumentNoValid;
        this.isDateOfIssueValid = isDateOfIssueValid;
        this.isPlaceOfIssueValid = isPlaceOfIssueValid;
        this.isIssuingAuthorityValid = isIssuingAuthorityValid;
    }
}