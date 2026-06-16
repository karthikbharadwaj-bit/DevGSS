const TE_CONSTANTS = {
    APPROVAL: {
        STATUS: {
            APPROVED: 'Approved',
            REJECTED: 'Rejected',
            PENDING_APPROVAL: 'Pending Approval',
            NEW: 'New'
        },
        TAX_EXEMPTION_STATE: {
            CURRENT: 'Current',
            REQUESTED: 'Requested',
            APPROVED: 'Approved',
            REJECTED: 'Rejected'
        }
    },
    MESSAGES: {
        APPROVAL_BLOCKED: 'All Tax Exemptions are already provided',
        APPROVAL_PROCESSING: 'Tax Exemption is processing',
        REFRESH_PAGE: 'Please wait for some time and refresh the page',
        INDIA_REFRESH_PAGE: 'The tax exemption will be approved automatically soon. You may refresh the page to see the changes.'
    },
    BI_ID_AMAZON: '62005',
    NEW_BUSINESS: 'New Business',
}

export {TE_CONSTANTS};