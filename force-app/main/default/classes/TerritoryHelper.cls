public class TerritoryHelper {
    public static Map<String, String> states;
    public static Map<String, String> countries;
    static {
        countries = new Map<String, String>();
        countries.put('usa', 'United States');
        countries.put('united states', 'United States');
        countries.put('canada', 'Canada');

        states = new Map<String, String>();
        states.put('alabama','Alabama');
        states.put('al','Alabama');
        states.put('alaska','Alaska');
        states.put('ak','Alaska');
        states.put('arizona','Arizona');
        states.put('az','Arizona');
        states.put('arkansas','Arkansas');
        states.put('ar','Arkansas');
        states.put('california','California');
        states.put('ca','California');
        states.put('colorado','Colorado');
        states.put('co','Colorado');
        states.put('connecticut','Connecticut');
        states.put('ct','Connecticut');
        states.put('delaware','Delaware');
        states.put('de','Delaware');
        states.put('district of columbia','District of Columbia');
        states.put('dc','District of Columbia');
        states.put('florida','Florida');
        states.put('fl','Florida');
        states.put('georgia','Georgia');
        states.put('ga','Georgia');
        states.put('hawaii','Hawaii');
        states.put('hi','Hawaii');
        states.put('idaho','Idaho');
        states.put('id','Idaho');
        states.put('illinois','Illinois');
        states.put('il','Illinois');
        states.put('indiana','Indiana');
        states.put('in','Indiana');
        states.put('iowa','Iowa');
        states.put('ia','Iowa');
        states.put('kansas','Kansas');
        states.put('ks','Kansas');
        states.put('kentucky','Kentucky');
        states.put('ky','Kentucky');
        states.put('louisiana','Louisiana');
        states.put('la','Louisiana');
        states.put('maine','Maine');
        states.put('me','Maine');
        states.put('maryland','Maryland');
        states.put('md','Maryland');
        states.put('massachusetts','Massachusetts');
        states.put('ma','Massachusetts');
        states.put('michigan','Michigan');
        states.put('mi','Michigan');
        states.put('minnesota','Minnesota');
        states.put('mn','Minnesota');
        states.put('mississippi','Mississippi');
        states.put('ms','Mississippi');
        states.put('missouri','Missouri');
        states.put('mo','Missouri');
        states.put('montana','Montana');
        states.put('mt','Montana');
        states.put('nebraska','Nebraska');
        states.put('ne','Nebraska');
        states.put('nevada','Nevada');
        states.put('nv','Nevada');
        states.put('new hampshire','New Hampshire');
        states.put('nh','New Hampshire');
        states.put('new jersey','New Jersey');
        states.put('nj','New Jersey');
        states.put('new mexico','New Mexico');
        states.put('nm','New Mexico');
        states.put('new york', 'New York');
        states.put('ny', 'New York');
        states.put('north carolina', 'North Carolina');
        states.put('nc', 'North Carolina');
        states.put('north dakota', 'North Dakota');
        states.put('nd', 'North Dakota');
        states.put('ohio', 'Ohio');
        states.put('oh', 'Ohio');
        states.put('oklahoma', 'Oklahoma');
        states.put('ok', 'Oklahoma');
        states.put('oregon', 'Oregon');
        states.put('or', 'Oregon');
        states.put('pennsylvania', 'Pennsylvania');
        states.put('pa', 'Pennsylvania');
        states.put('puerto rico', 'Puerto Rico');
        states.put('pr', 'Puerto Rico');
        states.put('rhode island', 'Rhode Island');
        states.put('ri', 'Rhode Island');
        states.put('south carolina', 'South Carolina');
        states.put('sc', 'South Carolina');
        states.put('south dakota', 'South Dakota');
        states.put('sd', 'South Dakota');
        states.put('tennessee', 'Tennessee');
        states.put('tn', 'Tennessee');
        states.put('texas', 'Texas');
        states.put('tx', 'Texas');
        states.put('utah', 'Utah');
        states.put('ut', 'Utah');
        states.put('vermont', 'Vermont');
        states.put('vt', 'Vermont');
        states.put('virginia', 'Virginia');
        states.put('va', 'Virginia');
        states.put('washington', 'Washington');
        states.put('wa', 'Washington');
        states.put('west virginia', 'West Virginia');
        states.put('wv', 'West Virginia');
        states.put('wisconsin', 'Wisconsin');
        states.put('wi', 'Wisconsin');
        states.put('wyoming', 'Wyoming');
        states.put('wy', 'Wyoming');
        states.put('alberta', 'Alberta');
        states.put('ab', 'Alberta');
        states.put('alb', 'Alberta');
        states.put('british columbia', 'British Columbia');
        states.put('bc', 'British Columbia');
        states.put('manitoba', 'Manitoba');
        states.put('mb', 'Manitoba');
        states.put('new brunswick', 'New Brunswick');
        states.put('nb', 'New Brunswick');
        states.put('newfoundland and labrador', 'Newfoundland and Labrador');
        states.put('nl', 'Newfoundland and Labrador');
        states.put('newfoundland', 'Newfoundland and Labrador');
        states.put('nova scotia', 'Nova Scotia');
        states.put('ns', 'Nova Scotia');
        states.put('northwest territories', 'Northwest Territories');
        states.put('nt', 'Northwest Territories');
        states.put('nunavut', 'Nunavut');
        states.put('nu', 'Nunavut');
        states.put('ontario', 'Ontario');
        states.put('on', 'Ontario');
        states.put('prince edward island', 'Prince Edward Island');
        states.put('pe', 'Prince Edward Island');
        states.put('quebec', 'Quebec');
        states.put('qc', 'Quebec');
        states.put('saskatchewan', 'Saskatchewan');
        states.put('sk', 'Saskatchewan');
        states.put('yukon', 'Yukon');
        states.put('yt', 'Yukon');
        states.put('virgin islands', 'Virgin Islands');
        states.put('vi', 'Virgin Islands');
    }

    public static String getCountry(String country) {
        return countries.get(getLowerCase(country));
    }
    public static String getState(String state) {
        String stateInMap = states.get(getLowerCase(state));
        if (stateInMap == null) {
            return state;
        }
        return stateInMap;
    }

    private static String getLowerCase(String str) {
        return (str != null ? str.toLowerCase().trim() : null);
    }

    public static List<Territory_Data__c> getListOfSuitableTerritories(List<Account_Hierarchy__c> companies) {
        List<Territory_Data__c> suitableTerritories = new List<Territory_Data__c>();
        Set<String> countries = new Set<String>{AccountHierarchyHelper.CANADA, AccountHierarchyHelper.USA};
        Set<String> states = new Set<String>();
        Set<String> segments = new Set<String>();

        for (Account_Hierarchy__c comp : companies) {
            states.add(TerritoryHelper.getState(comp.State__c));
            segments.add(comp.Effective_No_of_Employees_Range__c);
        }
        states.remove(null);
        if (!countries.isEmpty() && !states.isEmpty() && !segments.isEmpty()) {
            List<Object> bindings = new List<Object>();
            bindings.add(countries);
            bindings.add(states);
            bindings.add(segments);
            suitableTerritories = (List<Territory_Data__c>) new TerritoryDataSelector()
                                                            .selectTerritoryDataByCountryStateSegment(bindings)
                                                            .executeQuery();
        }
        return suitableTerritories;
    }
}