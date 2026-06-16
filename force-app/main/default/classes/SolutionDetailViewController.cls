public class SolutionDetailViewController {
    @AuraEnabled
    public static List <Solution> fetchSolution(String CaseId) {                
        Set<Id> solnId = new Set<Id>();
        for(CaseSolution cs: [SELECT Id, SolutionId FROM CaseSolution WHERE CaseId = :CaseId]){
            solnId.add(cs.SolutionId);
        }
        List<Solution> solnList = [SELECT Id, SolutionName, SolutionNote FROM Solution WHERE Id = :solnId];
        return solnList;
    }

    @AuraEnabled
    public static void updateSolution(List<Solution> soln) {
        update soln;
    }
}