public without sharing class HardcodedIdsMapper {

    private static final Map<String, String> HARDCODED_IDS_MAP;

    static{
        HARDCODED_IDS_MAP = loadDataFromStaticResource();
    }

    private static Map<String, String> loadDataFromStaticResource() {
        Map<String, String> res = new Map<String, String>();

        try {
            StaticResource mappingResource = [
                SELECT s.Body
                FROM StaticResource s
                WHERE s.Name = 'IdMapping'
                LIMIT 1
            ];

            Blob tempBrands = mappingResource.Body;
            String contentFile = tempBrands.toString();
            List<String> filelines = contentFile.split('\n');

            for (String curVaLine : filelines) {
                try {
                    List<String> fieldValues = curVaLine.split(';');

                    if (fieldValues.size() != 2 || res.containsKey(fieldValues[0])) {
                        continue;
                    }
                    res.put(fieldValues[0].trim(), fieldValues[1].trim());
                } catch (Exception e) {
                    continue;
                }
            }
        } catch(Exception e) {
            return new Map<String, String>();
        }
        return res;
    }

    public static String getMatchedObjectId(String hardcodedValue){
        String res = HARDCODED_IDS_MAP.get(hardcodedValue);
        return String.isBlank(res) ? hardcodedValue: res;
    }

    public static List<String> getMatchedObjectId(List<String> hardcodedValues){
        List<String> resultValues = new List<String>();

        for (String val : hardcodedValues) {
            String value = HARDCODED_IDS_MAP.get(val);
            if (String.isNotBlank(value)) {
                resultValues.add(value);
            } else {
                resultValues.add(val);
            }
        }
        return resultValues;
    }
}