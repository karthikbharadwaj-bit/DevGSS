public class HelperUtils {

    public static final String TIME_FORMAT= '{0}:{1}:{2}';
    public static final Boolean isMedallia = BooleanHelper.toBoolean(Medallia_Credentials__c.getInstance('Medallia')?.isMedallia__c);

	public HelperUtils() {

	}

	public static void updateCarrierDataRecordNew(List<Account> accountList) {
       List<Carrier_Data__c> updateCarrData = new List<Carrier_Data__c>();
       Set<string>  setAccMobNumber  = new Set<string>();
       Map<string,Account> MapMobNumAccount = new Map<string,Account>();
       for(Account objAcc :accountList) {
			String originalPhoneNumber = objAcc.Account_Mobile_Number__c;
 			if(!String.isBlank(originalPhoneNumber)) {
 				String formatPhoneWithCode = formatPhoneNumberWithCode(originalPhoneNumber);
 				String formatPhoneWithoutCode = formatPhoneNumberWithoutCode(originalPhoneNumber);
           		setAccMobNumber.add(formatPhoneWithCode.trim());
           		setAccMobNumber.add(formatPhoneWithoutCode.trim());
           		MapMobNumAccount.put(formatPhoneWithCode.trim(),objAcc);
           		MapMobNumAccount.put(formatPhoneWithoutCode.trim(),objAcc);
       		}
       }
       System.Debug('>>22>>'+setAccMobNumber);
       if(!setAccMobNumber.isEmpty()) {
          	List<Carrier_Data__c>  lstCarrData = [SELECT Id,Carrier_Wireless_Phone_Number__c FROM Carrier_Data__c
                                 					WHERE  Carrier_Wireless_Phone_Number__c != NULL AND Carrier_Wireless_Phone_Number__c IN:setAccMobNumber order by lastmodifiedDate];
          	for(Carrier_Data__c objCarrData : lstCarrData) {
          		String originalPhoneNumber = objCarrData.Carrier_Wireless_Phone_Number__c;
          		String formatPhoneWithCode = formatPhoneNumberWithCode(originalPhoneNumber);
 				String formatPhoneWithoutCode = formatPhoneNumberWithoutCode(originalPhoneNumber);

 				Account accountObj = MapMobNumAccount.get(formatPhoneWithCode);
          		if(accountObj != null) {
          			objCarrData.Account__c = accountObj.Id;
          			updateCarrData.add(objCarrData);
          		} else {
          			accountObj = MapMobNumAccount.get(formatPhoneWithoutCode);
          			if(accountObj != null) {
	          			objCarrData.Account__c = accountObj.Id;
	          			updateCarrData.add(objCarrData);
	          		}
          		}
       		}
          	if(!updateCarrData.isEmpty()) {
            	update updateCarrData;
          	}
        }
  	}
    private static String formatPhoneNumberWithCode(String originalPhoneNumber) {
		return (originalPhoneNumber.length() == 10 ? '1' + originalPhoneNumber : originalPhoneNumber);
	}
	private static String formatPhoneNumberWithoutCode(String originalPhoneNumber) {
		return (originalPhoneNumber.length() == 11 ? originalPhoneNumber.substring(1,originalPhoneNumber.length()) : originalPhoneNumber);
	}

    public class BaseValidator {
        private Response result;
        private List<Validator> validators;

        public BaseValidator() {
            this(new List<Validator>());
        }

        public BaseValidator(List<Validator> values) {
            this.result = new Response();
            this.validators = values;
        }

        public BaseValidator setValidators(Validator value) {
            this.validators.add(value);
            return this;
        }

        public BaseValidator setValidators(List<Validator> values) {
            this.validators.addAll(values);
            return this;
        }

        public Response validate(Response res) {
            this.result = res;
            return validate();
        }

        public Response validate() {
            for (Validator validator : this.validators) {
                validator.validate(result);
                if (validator.isActive && validator.isBreakingValidation() && validator.isFailedValidation()) {
                    break;
                }
            }

            return result;
        }
    }

    public static String getTimeBetweenDates(DateTime oldDate, DateTime newDate) {
        if (oldDate == null || newDate == null) {
            return null;
        }

        Long convertedOldDate = oldDate.getTime();
        Long convertedNewDate = newDate.getTime();
        Long milliseconds = convertedNewDate - convertedOldDate;
        Integer hours = Integer.valueOf(Math.floor(Integer.valueOf(milliseconds / 3600000)));
        Integer minutesRemainder = Integer.valueOf(milliseconds - hours * 3600000);
        Integer minutes = Integer.valueOf(Math.floor(minutesRemainder / 60000));
        Integer secondsRemainder = Math.mod(minutesRemainder, 60000);
        Integer seconds = Integer.valueOf(Math.floor(secondsRemainder / 1000));

        return String.format(TIME_FORMAT, new List<String>{
            String.valueOf(hours),
            String.valueOf(minutes),
            String.valueOf(seconds)
        });
    }

    public static Boolean isSObjectInList(SObject targetSObject, List<SObject> sObjects) {
        for (SObject existingSObject : sObjects) {
            if (existingSObject.get('Id') == targetSObject.get('Id')) {
                return true;
            }
        }

        return false;
    }
}