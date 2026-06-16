public class CsvBuilder {
    public String createCSV(List<SObject> records, List<String> fieldsToConvert) {
        List<String> firstLine = new List<String>();
        for (String field : fieldsToConvert) {
            firstLine.add(format(field));
        }

        String csv = line(firstLine);

        for (SObject sobj : records) {
            List<String> values = new List<String>();
            for (String field : fieldsToConvert) {
                values.add(format(String.valueOf(getValue(sobj, field))));
            }
            csv += line(values);
        }
        return csv;
    }

    private String line(List<String> cells) {
        return String.join(cells, ',') + '\n';
    }

    private String format(String s) {
        return StringHelper.safeString(s).escapeCsv();
    }

    private Object getValue(SObject sObj, String fieldToRetrieve) {

        if (sObj == null || String.isBlank(fieldToRetrieve)) {
            return '';
        }

        SObject localSObj = sObj;

        List<String> fieldPath = fieldToRetrieve.split('\\.');
        if (fieldPath.size() > 1) {
            localSObj = localSObj.getSObject(fieldPath[0]);
            String nameContinuation = fieldToRetrieve.substring(fieldPath[0].length() + 1);
            return getValue(localSObj, nameContinuation);
        }
        return localSObj.get(fieldToRetrieve);
    }
}