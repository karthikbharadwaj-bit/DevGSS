global with sharing class CLMAccount {
    
        global string Id { get; set; }

        global string Name { get; set; }

        global string Type { get; set; }

        global string DefaultCulture { get; set; }

        global string DefaultTimeZone { get; set; }

        global Map<String, Map<String, CLMAttributeFieldValue>> AttributeGroups { get; set; }

        global string SalesForceOrgId { get; set; }

        global string LogoUrl { get; set; }

        global string BrandingUrl { get; set; }

        global string Href { get; set; }
    
    
}