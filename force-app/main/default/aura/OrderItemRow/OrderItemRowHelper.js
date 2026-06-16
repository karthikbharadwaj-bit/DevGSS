({

    getListPrice: function (component) {

        var data = component.get('v.data');
        var result = data.UnitPrice;

        if (data.UnitPriceWithoutDiscount__c) {
            result = data.UnitPriceWithoutDiscount__c;
        }
        else if (data.Discount_Number__c) {
            if (data.Discount_Type__c === RC.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.PERCENTAGE) {
                result = result / (1 - data.Discount_Number__c / 100);
            } else {
                result = result + data.Discount_Number__c;
            }
        }

        return result;
    },

    getYourPrice: function (component, listPrice) {
        var data = component.get('v.data');

        // temp
        var result = listPrice;

        if (data.Discount_Number__c) {
            if (data.Discount_Type__c === RC.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.PERCENTAGE) {
                result = result * (1 - data.Discount_Number__c / 100);
            } else {
                result = result - data.Discount_Number__c;
            }
        }

        return result;
    },

    getTotalPrice: function (component, yourPrice, quantity) {
        return quantity * yourPrice;
    },

    calcPrecision: function (value) {
        try {
            var val = value ? String(value).split('.')[1] : null;
            return val ? val.length : 2;
        } catch (e) {
            console.warn(e);
        }

        return 2;
    },

    getDiscountCurrencyCode: function(data){
        return data.Discount_Type__c === RC.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.PERCENTAGE ?
            '%' :
            data.CurrencyIsoCode;
    },

    setDisplayAssetData: function(component){
        var display = {};
        display.price = false;
        display.yourPrice = false;
        display.totalPrice = false;
        display.currencyPrecision = false;
        display.discount = false;
        display.discountCurrencyCode = false;
        component.set('v.display',display);
    },

    setDisplayEntitlementData: function(component){
        var data = component.get('v.data');
        var display = {};
        display.price = this.getListPrice(component);
        display.yourPrice = this.getYourPrice(component, display.price);
        display.totalPrice = this.getTotalPrice(component, display.yourPrice, data.Qty__c);
        display.currencyPrecision = this.calcPrecision(component);
        display.discount = data.Discount__c;
        display.discountCurrencyCode = this.getDiscountCurrencyCode(data);
        component.set('v.display',display);
    }

});