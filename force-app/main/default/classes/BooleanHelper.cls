public class BooleanHelper {

    public static Boolean toBoolean(Object val) {
        if(val == null){
            val = false;
        }
        return Boolean.valueOf(val);
    }

}