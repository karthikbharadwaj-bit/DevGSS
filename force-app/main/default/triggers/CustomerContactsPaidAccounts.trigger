trigger CustomerContactsPaidAccounts on Customer_Contacts_Paid_Accounts__e (after insert) {

    CustomerContactsPaidAccountsHelper.processCustomerContactsPaidAccounts(Trigger.new);
}