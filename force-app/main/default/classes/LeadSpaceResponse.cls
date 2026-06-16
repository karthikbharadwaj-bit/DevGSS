public class LeadSpaceResponse {

    public String status;
    public DataContainer data;
    public String external_id;
    public String serializedResponse;

    public class DataContainer{
        public Person person;
        public Company company;
        public List<Scores> total_scores;
        public List<String> max_positive_total_score_profiles;
        public String enrichment_status;
    }

    public class Scores {
        public String profile_name;
        public Score score;
    }

    public class Score {
        public Decimal value;
    }

    public class AnalyticsScores {
        public String profile_name;
        public AnalyticsScoresScore score;
    }

    public class AnalyticsScoresScore {
        public Decimal value;
    }	

    public class Analytics {
        public List<AnalyticsScores> scores;
        public List<String> technologies;
        public List<String> job_functions;
        public List<String> max_positive_score_profiles;
    }

    public class CompanyAnalytics {
        public List<String> installed_base_technologies;
        public List<String> website_technologies;
    }

    public class PersonAddress {
        public String country;
        public String state;
        public String city;
    }

    public class CompanyAddress {
        public String country;
        public String state;
        public String city;
        public String street;
        public String zipcode;
        public String region;	
    }

    public class CompanyFamilyTreeCompanyAddress{
        public String country;
        public String state;
        public String city;
        public String street;
        public String zipcode;
        public String region;
    }

    public class CompanyFamilyTreeCompanySize{ 
        public String range;
        public Double exact;
    }

    public class CompanyFamilyTreeCompanyRevenue{
        public String range;
        public Double exact;
    }

    public class CompanyFamilyTreeCompany{
        public String type;
        public String name;
        public String ls_id;
        public CompanyFamilyTreeCompanyAddress address;
        public String phone;
        public String website;
        public String sic;
        public String naics;
        public CompanyFamilyTreeCompanySize size;
        public CompanyFamilyTreeCompanyRevenue revenue;
        public String duns;
    }

    public class CompanyFamilyTree {
        public List<CompanyFamilyTreeCompany> companies;
        public Boolean site_is_subsidiary;
    }

    public class Company {
        public String name;
        public String original_name;
        public String ls_id;
        public String description;
        public String ownership;
        public CompanyAddress address;
        public String phone;
        public String industry;
        public String sub_industry;
        public String linkedin_profile;
        public String website;
        public String sic;
        public String naics;
        public CompanySize size;
        public CompanyRevenue revenue;
        public CompanyAnalytics analytics;
        public CompanyFamilyTree family_tree;
        public String client_id;
    }

    public class Person {
        public String first_name;
        public String last_name;
        public String email;
        public String original_email;
        public String original_email_verification_status;
        public String title;
        public String phone;
        public String level;
        public String department;
        public PersonAddress address;
        public String linkedin_profile;
        public String verification_status;
        public String verification_source;
        public Analytics analytics;
    }

    public class CompanySize {
        public String range;
        public Double exact;
    }

    public class CompanyRevenue {
        public String range;
        public Double exact;
    }

    public static LeadSpaceResponse parse(String json) {
        return (LeadSpaceResponse) System.JSON.deserialize(json, LeadSpaceResponse.class);
    }
}