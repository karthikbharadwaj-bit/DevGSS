//Base class for classes containing custom code for standard and custom objects.
public with sharing class CoreObjectBase {
	public static Boolean isFieldChanged(sObject triggerRecord, sObjectField testField) {
		List<sObjectField> testFields = new List<sObjectField>{testField};
		return isFieldChanged(triggerRecord, testFields);
	}

	//Checks whether the specified fields on the specified record were changed in the current trigger execution.
	public static Boolean isFieldChanged(sObject triggerRecord, List<sObjectField> testFields) {

		if (Trigger.isInsert || Trigger.isDelete || Trigger.isUndelete) {
			return true;
	} else if (Trigger.isUpdate) {
			for (sObjectField testField : testFields) {
				if (triggerRecord.get(testField) != Trigger.oldMap.get(triggerRecord.Id).get(testField)) {
					return true;
				}
			}
			return false;
	} else {
			return false;
		}
	}

	//Checks whether the specified field has just transitioned to a specified value.
	public static Boolean isFieldChangedTo(sObject triggerRecord, sObjectField testField, object toValue) {

		if (Trigger.isInsert || Trigger.isUndelete) {
			return triggerRecord.get(testField) == toValue;
		} else if (Trigger.isDelete) {
			return toValue == null;
		} else if (Trigger.isUpdate) {
			return triggerRecord.get(testField) == toValue && Trigger.oldMap.get(triggerRecord.Id).get(testField) != toValue;			
		}
		else {
			return false;
		}
	}
	
	//Checks whether the specified field has just transitioned to one of a specific set of values.
	public static Boolean isFieldChangedToSet(sObject triggerRecord, sObjectField testField, Set<String> toValues) {

		if (Trigger.isInsert || Trigger.isUndelete) {
			return toValues.contains((String)triggerRecord.get(testField));
		} else if (Trigger.isDelete) {
			return toValues == null || toValues.isEmpty();
		} else if (Trigger.isUpdate) {
			return toValues.contains((String)triggerRecord.get(testField)) && Trigger.oldMap.get(triggerRecord.Id).get(testField) != triggerRecord.get(testField);			
		}
		else {
			return false;
		}
	}

	//Checks whether the specified field has just transitioned from a specified value.
	public static Boolean isFieldChangedFrom(sObject triggerRecord, sObjectField testField, object fromValue) {

		if (Trigger.isInsert || Trigger.isUndelete) {
			return fromValue == null && triggerRecord.get(testField) != null;
		} else if (Trigger.isDelete) {
			return triggerRecord.get(testField) == fromValue;
		} else {
			return Trigger.oldMap.get(triggerRecord.Id).get(testField) == fromValue && triggerRecord.get(testField) != fromValue;			
		}

	}
}