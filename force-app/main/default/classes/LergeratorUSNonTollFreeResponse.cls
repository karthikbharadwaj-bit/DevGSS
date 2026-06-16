public with sharing class LergeratorUSNonTollFreeResponse {
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
	
	public List<Data> data {get;set;} 
	public List<Errors> errors {get;set;} 

	public LergeratorUSNonTollFreeResponse(JSONParser parser) {
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
						System.debug(LoggingLevel.WARN, 'LergeratorUSNonTollFreeResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Data {
		public String TN {get;set;} 
		public String NPA {get;set;} 
		public String NXX {get;set;} 
		public String BLOCK {get;set;} 
		public String LERG_RATE_CENTER {get;set;} // in json: LERG-RATE-CENTER
		public String LERG_LATA {get;set;} // in json: LERG-LATA
		public String LERG_OCN {get;set;} // in json: LERG-OCN
		public String LERG_OCN_NAME {get;set;} // in json: LERG-OCN-NAME
		public String LERG_LIR {get;set;} // in json: LERG-LIR
		public String LERG_STATE {get;set;} // in json: LERG-STATE
		public String STATE_NAME {get;set;} // in json: STATE-NAME
		public String COUNTRY {get;set;} 
		public String RC_WEST_EAST {get;set;} // in json: RC-WEST-EAST
		public String RCLEC_Coverage {get;set;} // in json: RCLEC-Coverage
		public String RCLEC_Tier {get;set;} // in json: RCLEC-Tier
		public String RCLEC_LRN {get;set;} // in json: RCLEC-LRN
		public String RCLEC_Effdate {get;set;} // in json: RCLEC-Effdate
		public String RCLEC_IPES_ServedBy {get;set;} // in json: RCLEC-IPES-ServedBy
		public String Iristel_Coverage_ADD {get;set;} // in json: Iristel-Coverage-ADD
		public String Iristel_Coverage_Port_IN {get;set;} // in json: Iristel-Coverage-Port-IN
		public String Telus_OVW_Coverage_ADD {get;set;} // in json: Telus-OVW-Coverage-ADD
		public String Telus_OVW_Coverage_Port_IN {get;set;} // in json: Telus-OVW-Coverage-Port-IN
		public String Telus_OVW_OCN {get;set;} // in json: Telus-OVW-OCN
		public String Telus_OVW_Tier {get;set;} // in json: Telus-OVW-Tier
		public String Comwave_Coverage_ADD {get;set;} // in json: Comwave-Coverage-ADD
		public String Comwave_Coverage_Port_IN {get;set;} // in json: Comwave-Coverage-Port-IN
		public String Level3_Coverage {get;set;} // in json: Level3-Coverage
		public String Level3_Tier {get;set;} // in json: Level3-Tier
		public String Level3_LRN {get;set;} // in json: Level3-LRN
		public String Bandwidth_POP_Status {get;set;} // in json: Bandwidth-POP-Status
		public String Bandwidth_Tier {get;set;} // in json: Bandwidth-Tier
		public String Bandwidth_Coverage_ADD {get;set;} // in json: Bandwidth-Coverage-ADD
		public String Bandwidth_Coverage_Port_IN {get;set;} // in json: Bandwidth-Coverage-Port-IN
		public String Bandwidth_LRN {get;set;} // in json: Bandwidth-LRN
		public String IQNT_Coverage_ADD {get;set;} // in json: IQNT-Coverage-ADD
		public String IQNT_Coverage_Port_IN {get;set;} // in json: IQNT-Coverage-Port-IN
		public String IQNT_Tier {get;set;} // in json: IQNT-Tier
		public String IQNT_LRN {get;set;} // in json: IQNT-LRN
		public String Brand_Providers {get;set;} // in json: Brand-Providers
		public String Preferred_Provider_For_Ordering {get;set;} // in json: Preferred-Provider-For-Ordering
		public String Preferred_Provider_For_Porting {get;set;} // in json: Preferred-Provider-For-Porting
		public String BrandID {get;set;} 
		public String Note {get;set;} 
        
        public Data() {
            
        }

		public Data(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'TN') {
							TN = parser.getText();
						} else if (text == 'NPA') {
							NPA = parser.getText();
						} else if (text == 'NXX') {
							NXX = parser.getText();
						} else if (text == 'BLOCK') {
							BLOCK = parser.getText();
						} else if (text == 'LERG-RATE-CENTER') {
							LERG_RATE_CENTER = parser.getText();
						} else if (text == 'LERG-LATA') {
							LERG_LATA = parser.getText();
						} else if (text == 'LERG-OCN') {
							LERG_OCN = parser.getText();
						} else if (text == 'LERG-OCN-NAME') {
							LERG_OCN_NAME = parser.getText();
						} else if (text == 'LERG-LIR') {
							LERG_LIR = parser.getText();
						} else if (text == 'LERG-STATE') {
							LERG_STATE = parser.getText();
						} else if (text == 'STATE-NAME') {
							STATE_NAME = parser.getText();
						} else if (text == 'COUNTRY') {
							COUNTRY = parser.getText();
						} else if (text == 'RC-WEST-EAST') {
							RC_WEST_EAST = parser.getText();
						} else if (text == 'RCLEC-Coverage') {
							RCLEC_Coverage = parser.getText();
						} else if (text == 'RCLEC-Tier') {
							RCLEC_Tier = parser.getText();
						} else if (text == 'RCLEC-LRN') {
							RCLEC_LRN = parser.getText();
						} else if (text == 'RCLEC-Effdate') {
							RCLEC_Effdate = parser.getText();
						} else if (text == 'RCLEC-IPES-ServedBy') {
							RCLEC_IPES_ServedBy = parser.getText();
						} else if (text == 'Iristel-Coverage-ADD') {
							Iristel_Coverage_ADD = parser.getText();
						} else if (text == 'Iristel-Coverage-Port-IN') {
							Iristel_Coverage_Port_IN = parser.getText();
						} else if (text == 'Telus-OVW-Coverage-ADD') {
							Telus_OVW_Coverage_ADD = parser.getText();
						} else if (text == 'Telus-OVW-Coverage-Port-IN') {
							Telus_OVW_Coverage_Port_IN = parser.getText();
						} else if (text == 'Telus-OVW-OCN') {
							Telus_OVW_OCN = parser.getText();
						} else if (text == 'Telus-OVW-Tier') {
							Telus_OVW_Tier = parser.getText();
						} else if (text == 'Comwave-Coverage-ADD') {
							Comwave_Coverage_ADD = parser.getText();
						} else if (text == 'Comwave-Coverage-Port-IN') {
							Comwave_Coverage_Port_IN = parser.getText();
						} else if (text == 'Level3-Coverage') {
							Level3_Coverage = parser.getText();
						} else if (text == 'Level3-Tier') {
							Level3_Tier = parser.getText();
						} else if (text == 'Level3-LRN') {
							Level3_LRN = parser.getText();
						} else if (text == 'Bandwidth-POP-Status') {
							Bandwidth_POP_Status = parser.getText();
						} else if (text == 'Bandwidth-Tier') {
							Bandwidth_Tier = parser.getText();
						} else if (text == 'Bandwidth-Coverage-ADD') {
							Bandwidth_Coverage_ADD = parser.getText();
						} else if (text == 'Bandwidth-Coverage-Port-IN') {
							Bandwidth_Coverage_Port_IN = parser.getText();
						} else if (text == 'Bandwidth-LRN') {
							Bandwidth_LRN = parser.getText();
						} else if (text == 'IQNT-Coverage-ADD') {
							IQNT_Coverage_ADD = parser.getText();
						} else if (text == 'IQNT-Coverage-Port-IN') {
							IQNT_Coverage_Port_IN = parser.getText();
						} else if (text == 'IQNT-Tier') {
							IQNT_Tier = parser.getText();
						} else if (text == 'IQNT-LRN') {
							IQNT_LRN = parser.getText();
						} else if (text == 'Brand-Providers') {
							Brand_Providers = parser.getText();
						} else if (text == 'Preferred-Provider-For-Ordering') {
							Preferred_Provider_For_Ordering = parser.getText();
						} else if (text == 'Preferred-Provider-For-Porting') {
							Preferred_Provider_For_Porting = parser.getText();
						} else if (text == 'BrandID') {
							BrandID = parser.getText();
						} else if (text == 'Note') {
							Note = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public static LergeratorUSNonTollFreeResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new LergeratorUSNonTollFreeResponse(parser);
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