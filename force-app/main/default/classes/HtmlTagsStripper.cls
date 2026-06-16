public class HtmlTagsStripper {
	@InvocableMethod(label='Strip Html Tags'
                     description='This method removes html tags from the rich text field values'
                     category='Case Comment')
    public static List<String> stripHtmlTags(List<String> textCollection) {
        String output = '';
        if (textCollection != null && !textCollection.isEmpty()) {
            if (String.isNotBlank(textCollection[0].trim())) {
            	output = textCollection[0].stripHtmlTags();
            }
        }
        return new List<String> {
            output
            };
    }
}