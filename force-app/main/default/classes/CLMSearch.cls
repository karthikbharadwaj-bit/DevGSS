global with sharing class CLMSearch {
 
    global string Content { get; set; }

    global string Extensions { get; set; }

    global string UpdatedOnOrAfter { get; set; }

    global string UpdatedOnOrBefore { get; set; }

    global string AnyAttributeField { get; set; }

    global List<CLMAttributeGroup> AttributeGroups { get; set; }

    global List<CLMAttributeField> AttributeFields { get; set; }

    global string Status { get; set; }

    global string AllWords { get; set; }

    global string AnyWords { get; set; }

    global string WithoutWords { get; set; }

    global string Phrase { get; set; }

    global CLMFolder InFolder { get; set; }

    global boolean IncludeSubFolders { get; set; }

    global string Title { get; set; }

    global string Description { get; set; }

    global string UpdatedBy { get; set; }

    global CLMDocumentItems Result { get; set; }

    global string Href { get; set; }
     
}