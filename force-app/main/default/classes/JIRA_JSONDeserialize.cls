/****************************************************************************************** 

UPDATE:
by              eugenebasianomutya
date            4/12/2016
case            04516479
description     
                NEW FIELDS:
                Affects Versions - comma-separated value
                Exists on Productions - Boolean
                Released Fixed - String

                BUG FIXED:
                Salesforce Jira# field not updating when the scheduled job runs

                NEW FEATURE:
                Future call when Case Jira # field is populated/updated
                Remove/Hide Description and Action Taken(comments)

******************************************************************************************/

public class JIRA_JSONDeserialize{

    public String status;
    public cls_data[] data;


    public static JIRA_JSONDeserialize parse(string jSon){
        return (JIRA_JSONDeserialize) System.JSON.deserialize(jSon, JIRA_JSONDeserialize.class);
    }

    public class cls_data {
        public String id;
        public String key;
        public String summary;        
        public String resolutionDate;         
        public String created;
        public String description;
        public String exist_on_production;
        public String release_fixed;

        public cls_assignee assignee;
        public cls_issueType issueType;
        public cls_priority priority;
        public cls_project project;
        public cls_reporter reporter;
        public cls_status status;
        public cls_resolution resolution;
        public cls_comments[] comments;
        public cls_fixVersions[] fixVersions;
        public cls_version[] versions;
        
    }

    public class cls_assignee{
        public String name;
        public String email;
        public String displayName;
        public String active;
    }

    public class cls_issueType{
        public String id;
        public String name;
    }

    public class cls_priority{
        public String id;
        public String name;
    }

    public class cls_project{
        public String id;
        public String key;
        public String name;
    }

    public class cls_reporter{
        public String name;
        public String email;
        public String displayName;
        public String active;
    }

    public class cls_status{
        public String id;
        public String name;
    }

    public class cls_comments{
        public string name;
        public string email;
        public string displayName;
        public string body;
        public string created;
        public string updated;
    }

    public class cls_fixVersions{
        public string id;
        public string name;
        public string description;
        public string archived;
        public string released;
        public String release_date;
    }

    public class cls_version{
        public string id;
        public string name;
        public string description;
        public string archived;
        public string released;
        public String release_date;
    }

    public class cls_resolution{
        public string self;
        public string id;
        public string description;
        public string name;
    }


}