/**
 * Created on 07.11.2018
 */
({

    doInit: function doInit(cmp, event, helper) {
        var phone = cmp.get('v.phone');
        const phoneNumber = phone.replace(/\D/g, "");
        cmp.set('v.phoneNumber',phoneNumber);
    }
});