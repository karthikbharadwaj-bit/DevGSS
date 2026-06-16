public with sharing class LergeratorUKResponse {
	public Integer code {get;set;} 
	public String message {get;set;} 
	public List<Data> data {get;set;} 

	public LergeratorUKResponse(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'code') {
						code = parser.getIntegerValue();
					} else if (text == 'message') {
						message = parser.getText();
					} else if (text == 'data') {
						data = arrayOfData(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'LergeratorUKResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Data {
		public String tn {get;set;} 
		public String brandId {get;set;} 
		public String loosingProviderIdCode {get;set;} 
		public String type {get;set;} 
		public String rcSupported {get;set;} 
		public String preferredProviderForNonGeo {get;set;} 
		public String preferredProviderForGeo {get;set;} 
		public String preferredProviderForNonGeoFree {get;set;} 
		public String winningProviderContact {get;set;} 
		public String winningProviderAddress {get;set;} 
		public String routingPlanGeo {get;set;} 
		public String routingPlanNonGeo {get;set;} 
		public String routingPlanNonGeoFree {get;set;} 
		public String minDateGeo {get;set;} 
		public String minDateNonGeo {get;set;} 
		public String minDateNonGeoFree {get;set;} 
		public String loosingProviderContact {get;set;} 
		public String loosingProviderName {get;set;} 
		public String loosingProviderAddress {get;set;} 
		public String errorCode {get;set;} 
		public String message {get;set;} 

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'tn') {
							tn = parser.getText();
						} else if (text == 'brandId') {
							brandId = parser.getText();
						} else if (text == 'loosingProviderIdCode') {
							loosingProviderIdCode = parser.getText();
						} else if (text == 'type') {
							type = parser.getText();
						} else if (text == 'rcSupported') {
							rcSupported = parser.getText();
						} else if (text == 'preferredProviderForNonGeo') {
							preferredProviderForNonGeo = parser.getText();
						} else if (text == 'preferredProviderForGeo') {
							preferredProviderForGeo = parser.getText();
						} else if (text == 'preferredProviderForNonGeoFree') {
							preferredProviderForNonGeoFree = parser.getText();
						} else if (text == 'winningProviderContact') {
							winningProviderContact = parser.getText();
						} else if (text == 'winningProviderAddress') {
							winningProviderAddress = parser.getText();
						} else if (text == 'routingPlanGeo') {
							routingPlanGeo = parser.getText();
						} else if (text == 'routingPlanNonGeo') {
							routingPlanNonGeo = parser.getText();
						} else if (text == 'routingPlanNonGeoFree') {
							routingPlanNonGeoFree = parser.getText();
						} else if (text == 'minDateGeo') {
							minDateGeo = parser.getText();
						} else if (text == 'minDateNonGeo') {
							minDateNonGeo = parser.getText();
						} else if (text == 'minDateNonGeoFree') {
							minDateNonGeoFree = parser.getText();
						} else if (text == 'loosingProviderContact') {
							loosingProviderContact = parser.getText();
						} else if (text == 'loosingProviderName') {
							loosingProviderName = parser.getText();
						} else if (text == 'loosingProviderAddress') {
							loosingProviderAddress = parser.getText();
						} else if (text == 'errorCode') {
							errorCode = parser.getText();
						} else if (text == 'message') {
							message = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public static LergeratorUKResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new LergeratorUKResponse(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

    private static List<Data> arrayOfData(System.JSONParser p) {
        List<Data> res = new List<Data>();
        if (p.getCurrentToken() == null) {
			p.nextToken();
		}
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Data(p));
        }
        return res;
    }
}