public class ListHelper {

    /**
     * Adds new item at the beginning of the given list
     */
    public static void unshift(List<Object> lst, Object item) {
        if (lst.size() == 0) {
            lst.add(item);
        } else {
            lst.add(0, item);
        }
    }

    /**
    * Splits sObject list into several smaller sObject lists. Those lists' maximum size is provided as a param.
    * @return List<List<sObject>>
    */
    public static List<List<SObject>> splitSObjectList(List<SObject> listToSplit, Integer splitSize) {
        if(listToSplit == null) {
            AquivaHelper.throwAquivaException('List to split can\'t be null');
        }

        if(!(splitSize > 1)) {
            AquivaHelper.throwAquivaException('Split size can\'t be less than 1');
        }

        List<List<SObject>> result = new List<List<SObject>>();
        List<SObject> temp = new List<SObject>();
        for (SObject o : listToSplit) {
            temp.add(o);
            if (temp.size() == splitSize) {
                result.add(temp);
                temp = new List<SObject>();
            }
        }
        if(temp.size() > 0) {
            result.add(temp);
        }

        return result;
    }

    /**
     * Returns new list without null values
     * filterOutNulls(new List<Object> {'foo', null, 0}) => ['foo', 0]
     */
    public static List<SObject> filterOutNulls(List<SObject> lst) {
        List<SObject> result = new List<SObject>();
        if (lst == null) {
            return result;
        }
        for (SObject l : lst) {
            if (l != null) {
                result.add(l);
            }
        }
        return result;
    }

    public static List<Quote> filterOutNulls(List<Quote> lst) {
        return (List<Quote>) filterOutNulls((List<SObject>) lst);
    }

    public static Object first(List<Object> objList) {
        return objList != null && !objList.isEmpty() ? objList.get(0) : null;
    }

    public static String convertToString(Set<String> items) {
        return ListHelper.convertToString(new List<String>(items));
    }

    public static String convertToString(List<String> items) {
        String result = '';
        if (items.isEmpty()) {
            return '()';
        }

        for (String item : items) {
            result += '\'' + item + '\',';
        }
        return '(' + result.substring(0, result.length() - 1) + ')';
    }
}