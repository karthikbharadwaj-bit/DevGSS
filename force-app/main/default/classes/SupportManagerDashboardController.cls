/**
 * @description Controller for the Support Manager Dashboard LWC.
 *              Provides team summary metrics and per-agent workload data
 *              for support managers viewing their direct reports.
 *              AI insights (Negative Sentiment, Likely to Escalate) are handled
 *              client-side via AgentDashboardController.getBatchCasesWithInsights.
 * @author      Naman Shetty
 */
public with sharing class SupportManagerDashboardController {

    // ========== Constants ==========
    private static final String AI_ASSIST_PERMSET = 'Support_Agent_AI_Assist_Access';

    // ========== Access Control ==========

    /**
     * @description Checks whether the running user is allowed to see the Support Manager Dashboard.
     *              Both conditions must be true:
     *              1. The user has Support_Manager_Dashboard_Switch__c enabled in their
     *                 user-level GCP_Feature_Toggle__c custom setting record.
     *              2. The user has the Support_Agent_AI_Assist_Access permission set assigned.
     * @return True only when both conditions are met.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isManagerDashboardEnabled() {
        Id userId = UserInfo.getUserId();
        GCP_Feature_Toggle__c settings = GCP_Feature_Toggle__c.getInstance(userId);

        if (settings == null || settings.Support_Manager_Dashboard_Switch__c != true) {
            return false;
        }

        return ![
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
              AND PermissionSet.Name = :AI_ASSIST_PERMSET
            LIMIT 1
        ].isEmpty();
    }

    // ========== Team Summary Tiles ==========

    /**
     * @description Retrieves aggregate team summary metrics for the given manager.
     *              Returns: totalAgents, teamBacklog, closedCases, slaBreachRisk.
     *              Negative Sentiment and Escalation counts come from GCP AI (client-side).
     * @param managerId The User Id of the logged-in manager.
     * @return Map with tile keys and their integer values.
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getTeamSummary(Id managerId) {
        if (managerId == null) {
            throw new AuraHandledException('Manager ID is required.');
        }

        try {

            // 1. Get all active agents under this manager
            List<User> agents = [
                SELECT Id
                FROM User
                WHERE ManagerId = :managerId
                  AND IsActive = true
                WITH USER_MODE
            ];

            Set<Id> agentIds = new Map<Id, User>(agents).keySet();
            Integer totalAgents = agentIds.size();

            // 2. Team Backlog — open cases currently in queues the agents belong to
            Integer teamBacklog = 0;
            if (!agentIds.isEmpty()) {
                Set<Id> queueIds = new Set<Id>();
                for (GroupMember gm : [
                    SELECT GroupId
                    FROM GroupMember
                    WHERE UserOrGroupId IN :agentIds
                      AND Group.Type = 'Queue'
                    WITH USER_MODE
                ]) {
                    queueIds.add(gm.GroupId);
                }

                if (!queueIds.isEmpty()) {
                    List<AggregateResult> backlogAgg = [
                        SELECT COUNT(Id) cnt
                        FROM Case
                        WHERE OwnerId IN :queueIds
                          AND IsClosed = false
                        WITH USER_MODE
                    ];
                    teamBacklog = backlogAgg.isEmpty() ? 0 : (Integer) backlogAgg[0].get('cnt');
                }
            }

            // 3. Closed cases by the team in last 30 days
            Integer closedCases = 0;
            if (!agentIds.isEmpty()) {
                List<AggregateResult> closedAgg = [
                    SELECT COUNT(Id) cnt
                    FROM Case
                    WHERE OwnerId IN :agentIds
                      AND IsClosed = true
                      AND ClosedDate = LAST_N_DAYS:30
                    WITH USER_MODE
                ];
                closedCases = closedAgg.isEmpty() ? 0 : (Integer) closedAgg[0].get('cnt');
            }

            // 4. SLA Breach Risk — milestones violated on open cases owned by the team
            Integer slaBreachRisk = 0;
            if (!agentIds.isEmpty()) {
                List<AggregateResult> slaAgg = [
                    SELECT COUNT(Id) cnt
                    FROM CaseMilestone
                    WHERE Case.OwnerId IN :agentIds
                      AND Case.IsClosed = false
                      AND IsViolated = true
                    WITH USER_MODE
                ];
                slaBreachRisk = slaAgg.isEmpty() ? 0 : (Integer) slaAgg[0].get('cnt');
            }

            return new Map<String, Object>{
                'totalAgents'   => totalAgents,
                'teamBacklog'   => teamBacklog,
                'closedCases'   => closedCases,
                'slaBreachRisk' => slaBreachRisk
            };

        } catch (Exception e) {
            throw new AuraHandledException('Unable to load team summary. Please try again.');
        }
    }

    // ========== Team Workload Distribution ==========

    /**
     * @description Retrieves per-agent workload data for the manager's direct reports.
     *              Each agent row contains: agentId, agentName, agentPhoto, casesOpen, casesResolved.
     * @param managerId The User Id of the logged-in manager.
     * @return JSON string with { success: true, agents: [ ... ] }.
     */
    @AuraEnabled(cacheable=false)
    public static String getTeamWorkload(Id managerId) {
        if (managerId == null) {
            return JSON.serialize(new Map<String, Object>{
                'success' => false,
                'message' => 'Manager ID is required.'
            });
        }

        try {
            List<User> agents = [
                SELECT Id, Name, SmallPhotoUrl
                FROM User
                WHERE ManagerId = :managerId
                  AND IsActive = true
                WITH USER_MODE
                ORDER BY Name ASC
            ];

            if (agents.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'success' => true,
                    'agents'  => new List<Object>()
                });
            }

            Set<Id> agentIds = new Map<Id, User>(agents).keySet();

            // Bulk: Open cases per agent
            Map<Id, Integer> openCountMap = new Map<Id, Integer>();
            for (AggregateResult ar : [
                SELECT OwnerId, COUNT(Id) cnt
                FROM Case
                WHERE OwnerId IN :agentIds
                  AND IsClosed = false
                WITH USER_MODE
                GROUP BY OwnerId
            ]) {
                openCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('cnt'));
            }

            // Bulk: Cases resolved per agent in last 7 days
            Map<Id, Integer> resolvedCountMap = new Map<Id, Integer>();
            for (AggregateResult ar : [
                SELECT OwnerId, COUNT(Id) cnt
                FROM Case
                WHERE OwnerId IN :agentIds
                  AND IsClosed = true
                  AND ClosedDate = LAST_N_DAYS:7
                WITH USER_MODE
                GROUP BY OwnerId
            ]) {
                resolvedCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('cnt'));
            }

            // Build response rows
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (User u : agents) {
                rows.add(new Map<String, Object>{
                    'agentId'       => u.Id,
                    'agentName'     => u.Name,
                    'agentPhoto'    => u.SmallPhotoUrl,
                    'casesOpen'     => openCountMap.containsKey(u.Id) ? openCountMap.get(u.Id) : 0,
                    'casesResolved' => resolvedCountMap.containsKey(u.Id) ? resolvedCountMap.get(u.Id) : 0
                });
            }

            return JSON.serialize(new Map<String, Object>{
                'success' => true,
                'agents'  => rows
            });

        } catch (Exception e) {
            return JSON.serialize(new Map<String, Object>{
                'success' => false,
                'message' => e.getMessage()
            });
        }
    }
}