public with sharing class LayoutHelper {
    public static String getLayoutName(Id recordTypeId) {
        String query = 'SELECT Layout.Name FROM ProfileLayout WHERE ProfileId = \''
            + UserInfo.getProfileId()
            + '\' AND RecordType.Id = \''+ recordTypeId +'\'';
        String endPoint = 'callout:Tooling_API/services/data/v50.0/tooling/query?q=' + query.replace(' ', '+');
        HttpRequest req = HTTPHelper.prepareHttpRequest(endPoint, HTTPHelper.METHOD_GET, '', '');
        Http h = new Http();
        HttpResponse resp = h.send(req);

        return resp.getBody().substringBetween('"Name":"', '"');
    }

    public static List<Section> getSections(String objectApiName, String layoutName) {
        Metadata.Layout layoutMetadata = SFDescribeHelper.getLayoutInfo(objectApiName, layoutName);

        List<Section> sections = new List<Section>();
        for (Metadata.LayoutSection section : layoutMetadata?.layoutSections) {
            List<Column> columns = new List<Column>();

            for (Metadata.LayoutColumn column : section?.layoutColumns) {
                if (column.layoutItems == null) {
                    continue;
                }

                List<Item> items = addItems(column?.layoutItems, objectApiName);
                if (!items.isEmpty()) {
                    Column col = new Column(items);
                    columns.add(col);
                }
            }

            Section sec = new Section(section.label, columns);
            sections.add(sec);
        }

        return sections;
    }

    public static List<Item> addItems(List<Metadata.LayoutItem> items, String objectApiName) {
        List<Item> result = new List<Item>();
        for (Metadata.LayoutItem layoutItem : items) {
            if (layoutItem.field != null) {
                result.add(new Item(layoutItem, objectApiName));
            }
        }

        return result;
    }

    public class Section {
        public String sectionName { get; set; }
        public List<Column> columns { get; set; }

        public Section(String sectionName, List<Column> columns) {
            this.columns = columns;
            this.sectionName = sectionName;
        }
    }

    public class Column {
        public List<Item> items { get; set; }

        public Column(List<Item> items) {
            this.items = items;
        }
    }

    public class Item {
        public Boolean isEditable { get; set; }
        public Boolean isReadOnly { get; set; }
        public Boolean isRequired { get; set; }
        public Boolean isShown { get; set; }
        public String fieldName { get; set; }
        public String label { get; set; }
        public String fieldType { get; set; }
        public Integer scale { get; set; }
        public String helpText { get; set; }
        public String sObjectName { get; set; }

        public Item(Metadata.LayoutItem layoutItem, String objectApiName) {
            Boolean isField = layoutItem.field != null;
            if (isField) {
                Schema.DescribeFieldResult fieldDescribe = ((SObject) Type.forName(objectApiName).newInstance())
                        .getSObjectType().getDescribe().fields.getMap().get(layoutItem.field).getDescribe();

                Boolean isReadOnly = layoutItem.behavior == Metadata.UiBehavior.Readonly
                    && UserInfo.getProfileId() != ProfileHelper.PROFILE_ID_SYSADMIN;
                Boolean isShown = fieldDescribe.isAccessible() && !fieldDescribe.isCalculated() && !fieldDescribe.isAutoNumber();

                this.fieldName = layoutItem.field;
                this.label = fieldDescribe.getLabel();
                this.fieldType = String.valueOf(fieldDescribe.getType());
                this.scale = fieldDescribe.getScale();
                this.helpText = fieldDescribe.getInlineHelpText();
                this.sObjectName = !fieldDescribe.getReferenceTo().isEmpty()
                    ? fieldDescribe.getReferenceTo().get(0).getDescribe().getName()
                    : '';

                this.isEditable = isField && isShown && !isReadOnly;
                this.isReadOnly = isField && isShown && isReadOnly;
                this.isRequired = isField && isShown && !isReadOnly && layoutItem.behavior == Metadata.UiBehavior.Required;
                this.isShown = isShown;
            }
        }
    }
}