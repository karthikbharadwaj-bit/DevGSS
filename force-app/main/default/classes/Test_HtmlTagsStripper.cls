@IsTest
public class Test_HtmlTagsStripper {
    @IsTest
    static void testHtmlTagsRemoverMethod() {
        String testComment = '<p>test resolution case comment</p> ';
        List<String> apexOutput = HtmlTagsStripper.stripHtmlTags(new List<String> {testComment});
        Assert.AreEqual('test resolution case comment', apexOutput[0], 'HTML tag isnt stripped properly');
    }
}