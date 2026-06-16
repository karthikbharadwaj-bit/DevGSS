({
    getYourPrice: function (price, discountType, discountNumber) {
        var result = price;

        if (discountNumber) {
            if (discountType === RC.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.PERCENTAGE) {
                result = result * (1 - discountNumber / 100);
            } else {
                result = result - discountNumber;
            }
        }

        return result;
    },

    getTotalPrice: function (quantity, yourPrice) {
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
        var data = component.get('v.data');
        var display = {};
        display.chargeTerm = data.Product2 ? data.Product2.Charge_Term__c : null;
        display.quantity = data.Delivered_Quantity__c + '/' +data.Quantity;
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
        display.chargeTerm = data.Product__r ? data.Product__r.Charge_Term__c : null;
        display.quantity = data.DisplayQuantity__c;
        display.price = data.Price__c;
        display.yourPrice = this.getYourPrice(data.Price__c, data.Discount_Type__c, data.Discount__c);
        display.totalPrice = this.getTotalPrice(data.DisplayQuantity__c, display.yourPrice);
        display.currencyPrecision = this.calcPrecision(data.Price__c);
        display.discount = data.Discount__c;
        display.discountCurrencyCode = this.getDiscountCurrencyCode(data);
        component.set('v.display',display);
    }
});