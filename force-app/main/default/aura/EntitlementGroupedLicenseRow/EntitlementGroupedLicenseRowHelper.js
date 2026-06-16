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

    getDiscountCurrencyCode: function(data){
        return data.Discount_Type__c === RC.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.PERCENTAGE ?
            '%' :
            data.CurrencyIsoCode;
    },

    initializeDisplayData: function(component) {
        var data = component.get('v.data');
        var display = {};

        display.description = data.Product__r ? data.Product__r.Name : data.description;

        // Set charge term display
        display.chargeTerm = data.Product__r ? data.Product__r.Charge_Term__c : data.billingCycleDuration;

        // Set quantity display
        display.quantity = data.DisplayQuantity__c || data.qty || '';

        // Set price display
        display.price = !$A.util.isUndefinedOrNull(data.Price__c) ? data.Price__c
            : !$A.util.isUndefinedOrNull(data.price) ? data.price
            : false;
        display.currencyPrecision = 2;

        // Set discount display
        display.discount = !$A.util.isUndefinedOrNull(data.Discount__c) ? data.Discount__c
            : !$A.util.isUndefinedOrNull(data.discountAmount) ? data.discountAmount
            : false;
        display.discountCurrencyCode = this.getDiscountCurrencyCode(data);

        // Set your price (price after discount)
        if (!$A.util.isUndefinedOrNull(display.price) && display.discount !== false) {
            display.yourPrice = this.getYourPrice(data.Price__c, data.Discount_Type__c, data.Discount__c);
        } else {
            display.yourPrice = false;
        }

        // Set total price
        if (display.yourPrice && display.quantity) {
            display.totalPrice = display.yourPrice * display.quantity;
        } else {
            display.totalPrice = false;
        }

        component.set('v.display', display);
    }
})