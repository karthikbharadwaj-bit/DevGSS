/**
 * Created on 31.08.2018
 */
({
    updateUser: function(component, user) {
        user = user || (window.app && window.app.User) || null;
        var account = {
            hasAccount: false,
            CSM: {
                Name: null,
                Email: "",
                Photo: "",
            },
            nextBillingDate: "",
            billingCycle: "",
            paymentSchedule: "",
            BillingAddress: "",
        };
        var contact = {
            Name: null,
            Role: "",
            Email: "",
            Phone: "",
            OwnerName: "",
            ServicePlan: "",
            numberOfDigitalLines: "",
        };
        if(user && !user.isEmpty()) {
            component.set("v.isGuest", user.isGuest);
            if(window.app) {
                if(window.app.Account) {
                    account = window.app.Account;
                    account.hasAccount = true;
                }
                if(window.app.Contact) {
                   contact = window.app.Contact;
                }
            }
            component.set("v.contact", contact);
            component.set("v.account", account)
        }
        else {
            component.set("v.show", false);
        }
    },
    updateCases: function(component, cases, isMock) {
        cases = cases || (window.app && window.app.Cases) || null;
        if(cases) {
            component.set("v.cases", cases);
            component.set("v.show", !isMock);
            component.set("v.loading", false);
        }
    },
});