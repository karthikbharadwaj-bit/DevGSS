public with sharing class LergeratorUSTollFreeResponse {
	public class Errors {
		public Integer error_code {get;set;} 
        public String error_message {get;set;}
        public String phone_number {get;set;} 
        
        public Errors() {
            
        }

		public Errors(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'error_code') {
							error_code = parser.getIntegerValue();
						} else if (text == 'error_message') {
                            error_message = parser.getText();
                            phone_number = error_message.replaceAll('^\\D','');
						} else {
							System.debug(LoggingLevel.WARN, 'Errors consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Data {
        public String TN {get;set;} 
		public String Number_Type {get;set;} // in json: Number-Type
		public String Brand_Id {get;set;} // in json: Brand-Id
		public String Brand_Name {get;set;} // in json: Brand-Name
		public String Provider_Id {get;set;} // in json: Provider-Id
		public String Provider_Name {get;set;} // in json: Provider-Name
        
        public Data() {
            
        }

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'TN') {
                            TN = parser.getText();
						} else if (text == 'Number-Type') {
							Number_Type = parser.getText();
						} else if (text == 'Brand-Id') {
							Brand_Id = parser.getText();
						} else if (text == 'Brand-Name') {
							Brand_Name = parser.getText();
						} else if (text == 'Provider-Id') {
							Provider_Id = parser.getText();
						} else if (text == 'Provider-Name') {
							Provider_Name = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public List<Data> data {get;set;} 
	public List<Errors> errors {get;set;} 

	public LergeratorUSTollFreeResponse(JSONParser parser) {
		data = new List<Data>();
		errors = new List<Errors>();
		
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'data') {
						data = arrayOfData(parser);
					} else if (text == 'errors') {
						errors = arrayOfErrors(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'LergeratorUSTollFreeResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	
	public static LergeratorUSTollFreeResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new LergeratorUSTollFreeResponse(parser);
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
	

    private static List<Errors> arrayOfErrors(System.JSONParser p) {
        List<Errors> res = new List<Errors>();
        if (p.getCurrentToken() == null) {
			p.nextToken();
		}
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Errors(p));
        }
        return res;
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