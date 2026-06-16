/**
 * Records Matcher
 * @author D.Malenko
 * @date 2017
 * @description
 *		Find matches in targetRecords array. sourceRecord contains formula in field from formulaFieldName parameter.
 *		Formula examples:
 *			{Name} equal {Email};{Active}
 *				(Name from targetRecord equal to Email from source record) AND Active field from targetRecord = true
 *			{Name} equal American Express;{Email} notEqual test@gmail.com;{Active}
 *				(Name from targetRecord='American Express' AND Email!=test@gmail.com) AND Active field from targetRecord = true
 *		In each part of formula in first place need be targerRecord field name;
 *		In second place - sourceField name or text value without apostrophes.
 */
public class RecordsMatcher {

    // following variable enables result cache by formulaStr, enable it when search executed for the same array several times
    public static boolean cacheResults = false;
    private static Map<String, List<SObject>> cachedResults = new Map<String, List<SObject>>();
    private static Map<Id, Set<String>> recordFormulas = new Map<Id, Set<String>>();
    /**
     * Find match records in targetRecords array by formula in sourceRecord[formulaDescription] field
     */
    public static List<SObject> match(List<SObject> targetRecords, sObject sourceRecord, String formulaDescription) {
        return match(targetRecords, sourceRecord, formulaDescription, 'field');
    }

    public static List<SObject> match(List<SObject> targetRecords, sObject sourceRecord, String formulaDescription, String formulaSource) {
        List<SObject> resultRecords = new List<SObject>();

        if (targetRecords == null || targetRecords.size() == 0) {
            return resultRecords;
        }

        String formulaStr;
        if (formulaSource == 'field') {
            formulaStr = (String)getFieldValue(sourceRecord,formulaDescription);
        } else if (formulaSource == 'string') {
            formulaStr = formulaDescription;
        }
        if (cacheResults && cachedResults.containsKey(formulaStr)) {
            return cachedResults.get(formulaStr);
        }

        List<String> formulaArray = formulaStr.split('%%');

        // Try to match each record from targetRecords array by each formula part
        if (formulaArray.size() > 0) {
            for (SObject targetRec: targetRecords) {
                if (cacheResults && !recordFormulas.containsKey(targetRec.Id)) {
                    recordFormulas.put(targetRec.Id, new Set<String>());
                }
                Boolean isMatched = true;
                for (String condition: formulaArray) {
                    if (cacheResults && recordFormulas.get(targetRec.Id).contains(condition)) {
                        continue;
                    }
                    if (!checkRecordByCondition(targetRec, sourceRecord, condition)) {
                        isMatched = false;
                        break;
                    }
                    if (cacheResults) {
                        recordFormulas.get(targetRec.Id).add(condition);
                    }
                }
                if (isMatched) {
                    resultRecords.add(targetRec);
                }
            }
        }

        if (cacheResults) {
            cachedResults.put(formulaStr, resultRecords);
        }

        return resultRecords;
    }

    /**
     * Try to match targetRecord by condition and source record values
     */
    private static Boolean checkRecordByCondition (SObject targetRecord, sObject sourceRecord, String condition) {
        // Check condition type
        List<String> conditionParts = new List<String>();
        conditionParts = condition.split(' ',3);
        String targetValue;
        String sourceValue;
        List<String> sourceArray;
        if (conditionParts.size() == 1) { // Boolean condition
            return (Boolean)getFieldValue(targetRecord,conditionParts[0]);
        } else if (conditionParts.size() < 3) { // Bad condition
            return false;
        } else { // Right condition
            targetValue = conditionParts[0];
            sourceValue = conditionParts[2];
            if (conditionParts[0].startsWith('{')) { // Placeholder to field
                targetValue = String.valueOf(getFieldValue(targetRecord,conditionParts[0]));
            }
            if (conditionParts[2].startsWith('{')) {
                sourceValue = String.valueOf(getFieldValue(targetRecord,conditionParts[2]));
            } else if (conditionParts[2].startsWith('[')) {
                sourceValue = conditionParts[2].replace('[', '').replace(']', '');
                // splits by "|" - vertical line, not uppercase i or lowercase L
                sourceArray = sourceValue.split('|');
            }

            if (conditionParts[1].toLowerCase() == 'equal') {
                return targetValue == sourceValue;
            } else if (conditionParts[1].toLowerCase() == 'notequal') {
                return targetValue != sourceValue;
            } else if (conditionParts[1].toLowerCase() == 'contains') {
                return targetValue.contains(sourceValue);
            } else if (conditionParts[1].toLowerCase() == 'notcontains') {
                return !targetValue.contains(sourceValue);
            } else if (conditionParts[1].toLowerCase() == 'startswith') {
                return !targetValue.startsWith(sourceValue);
            } else if (conditionParts[1].toLowerCase() == 'endswith') {
                return !targetValue.endsWith(sourceValue);
            } else if (conditionParts[1].toLowerCase() == 'in') {
                for (String sval : sourceArray) {
                    if (targetValue == sval) {
                        return true;
                    }
                }
            }
        }

        return false; // Target record not matched
    }

    /* ==== UTILS ==== */

    private static Object getFieldValue(SObject targetObject, String placeholder) {
        Object res;
        String clearPlaceholder = placeholder.replace('{','').replace('}','');
        List<String> fieldPath = clearPlaceholder.split('\\.');
        if (fieldPath.size() == 1) {
            res = targetObject.get(clearPlaceholder);
        } else if (fieldPath.size() > 1){
            SObject currSobj = targetObject;
            for (Integer i = 0; i < (fieldPath.size() - 1); i ++) {
                currSobj = currSobj.getSObject(fieldPath[i]);
            }
            res = currSobj.get(fieldPath[fieldPath.size() - 1]);
        }
        return res;
    }
}