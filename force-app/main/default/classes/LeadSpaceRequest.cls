public class LeadSpaceRequest {
    public String companyCountry {get; set;}
    public String personFirstName {get; set;}
    public String personLastName {get; set;}
    public String personEmail {get; set;}
    public String companyName {get; set;}
    public String externalId {get; set;}
    public String firstLeadSource {
        get{
            if(firstLeadSource == null) {
                firstLeadSource = '';
            }
            return firstLeadSource;
        }
        set;
    }
    
    private String sanitizeJSON(String valueToSanitize){
        if(String.isEmpty(valueToSanitize)){
            return '';   
        }
        String doubleQuoteTarget = '"';
        String doubleQuoteReplacement = '';
        valueToSanitize = valueToSanitize.replace(doubleQuoteTarget, doubleQuoteReplacement);
        return valueToSanitize;
    }

    public String getAPIRequest(){
        String countryFilter = companyCountry != null ? ' ,"address" : { "country" : "' + 
            companyCountry + '" }' : ' ,"address" : { "country" : "United States" }';
        
        String body = '{"external_id":"' + externalId + '", "person": {"first_name": "' + 
                        sanitizeJSON(personFirstName) + '","last_name": "' + 
                        sanitizeJSON(personLastName) + '",' + '"email": "' + personEmail + '"},' +
                        '"company": { "name": "' + sanitizeJSON(companyName) + '" ' + countryFilter + ' }, ' +
                        '"custom_fields": [{"name" : "First Lead Source", "value" : "' + firstLeadSource + '" } ] }';

        return body;
    }
}