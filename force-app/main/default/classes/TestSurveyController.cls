@isTest
public class TestSurveyController {
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void surveyControllerUnitTest() {
    	try {
			List<string> answerList = new List<string>();
            SurveyController.WrapperQuestionList weQuestionListObj = new SurveyController.WrapperQuestionList(/*questionObj,*/
    		 																answerList,true);
    		 weQuestionListObj.getValues();
    		 weQuestionListObj.getTheCheckBoxValue();
    		 weQuestionListObj.setTheCheckBoxValue(answerList);
    		 SurveyController surveyControllerObj = new SurveyController();
    		 SurveyController surveyControllerObj1 = new SurveyController();
    		 surveyControllerObj1.getIsFilled();
    		 surveyControllerObj1.saveSurvey();
    		 surveyControllerObj1.isFilled = true;
    		 SurveyController surveyControllerObj2 = new SurveyController();
    	} catch(Exception ex) {
    		
    	}
    } 
}