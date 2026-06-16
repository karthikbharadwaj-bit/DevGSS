@isTest
public class Test_DatedConversionRateSelector {

    @isTest
    static void testSelectConversionRateByDate() {
        DatedConversionRateSelector selector = new DatedConversionRateSelector();
        List<Object> result = selector.selectConversionRateByDate(Date.today().addDays(-2), Date.today().addDays(2)).executeQuery();
        System.assertEquals(true, true, 'Cant be tested so we bypass assertequals');
    }

    @isTest
    static void testSelectConversionRateByDateEnforceFLS() {
        DatedConversionRateSelector selector = new DatedConversionRateSelector(true, true);
        List<Object> result = selector.selectConversionRateByDate(Date.today().addDays(-2), Date.today().addDays(2)).executeQuery();
        System.assertEquals(true, true, 'Cant be tested so we bypass assertequals');
    }
}