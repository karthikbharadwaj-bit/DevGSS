global with sharing class CLMAttributeGroups {
    
        global string Name { get; set; }

        global boolean IsSystem { get; set; }

        global string Href { get; set; }

        global List<CLMAttributeGroupFields> Attributes { get; set; }
    
}