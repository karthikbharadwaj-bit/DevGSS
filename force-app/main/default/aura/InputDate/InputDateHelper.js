/* Some of this library is from here:
 * https://github.com/forcedotcom/aura/blob/master/aura-components/src/main/components/ui/inputDate/inputDateHelper.js
 * Hence the notice below:
 */
/*
 * Copyright (C) 2013 salesforce.com, inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
({
    init: function (component) {
      component.set("v.placeholder", component.get("v.format"));
      this.cacheDefaultValues(component);
    },

    timezone: '',
    format: '',
    locale: '',

    cacheDefaultValues: function (component) {
        this.timezone = component.get("v.timezone") || $A.get("$Locale.timezone");
        this.format = component.get("v.format") || $A.get("$Locale.dateFormat") + ' h:mm a';
    },

    displayValue: function (component) {
        var config = {
            langLocale: this.locale,
            format: this.format,
            timezone: this.timezone,
            validateString: true,
            timeFormat: ' h:mm a',
        };

        var displayValue = function (returnValue) {
            this.setInputValue(component, returnValue.date);
        }.bind(this);

        var value = component.get("v.value");
        var dateTimeLib = component.find("dateTimeLib");
        dateTimeLib.getDisplayValue(value, config, displayValue);

    },

    doUpdate: function (component, event) {
        var value = event.target.value;
        if (!value) {
            return;
        }

        var selectedDate = new Date(value);
        if(selectedDate.toString() === 'Invalid Date') selectedDate = new Date();
            value = Date.UTC(
                selectedDate.getFullYear(),
                selectedDate.getMonth(),
                selectedDate.getDate(),
                selectedDate.getHours(),
                selectedDate.getMinutes(),
                selectedDate.getSeconds()
            );
            value = new Date(value);

            $A.localizationService.WallTimeToUTC(value, this.timezone, function(t) {
                var isoDate = $A.localizationService.toISOString(t);
                //fire event if value different from attribute value
                var currentValue = component.get("v.value");
                if (currentValue !== isoDate){
                  //emit an event!
                  var dataChangeEvent = component.getEvent("dataChangeEvent");
                  dataChangeEvent.setParams({"data": {"date": isoDate} });
                  dataChangeEvent.fire();
                }
                component.set("v.value", isoDate);
            });
    },

    getInputElement: function (component) {
        var inputCmp = component.getConcreteComponent().find("inputText");
        if (inputCmp) {
            return inputCmp.getElement();
        }
        return component.getElement();
    },

    getDateString: function (date) {
        return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
    },

    setInputValue: function (component, displayValue) {
        var inputElement = this.getInputElement(component);
        if (!$A.util.isUndefinedOrNull(inputElement) && inputElement.value !== displayValue) {
            // only update value if display value is different.
            inputElement.value = displayValue ? $A.localizationService.translateToLocalizedDigits(displayValue) : "";
        }
    },

})//