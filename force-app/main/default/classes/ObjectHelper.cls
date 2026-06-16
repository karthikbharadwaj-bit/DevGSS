public with sharing class ObjectHelper {
    public static Type getObjectType(Object obj) {

        String result = 'DateTime';
        try{
            DateTime typeCheck = (DateTime)obj;
        }
        catch(System.TypeException te){

            String message = te.getMessage().substringAfter('Invalid conversion from runtime type ');
            result = message.substringBefore(' to Datetime');
        }

        return Type.forName(result);
    }

}