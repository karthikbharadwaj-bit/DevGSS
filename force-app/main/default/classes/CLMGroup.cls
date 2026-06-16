global with sharing class CLMGroup {
        global string Name { get; set; }

        global string GroupType { get; set; }

        global CLMUserItems GroupMembers { get; set; }

        global string CreatedDate { get; set; }

        global string UpdatedDate { get; set; }

        global string Href { get; set; }
}